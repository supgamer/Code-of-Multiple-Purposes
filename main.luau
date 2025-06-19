--[[

_____                 _____                _              
/  ___|               |  ___|              (_)             
\ `--.  _   _  _ __   | |__   _ __    __ _  _  _ __    ___ 
 `--. \| | | || '_ \  |  __| | '_ \  / _` || || '_ \  / _ \
/\__/ /| |_| || |_) | | |___ | | | || (_| || || | | ||  __/
\____/  \__,_|| .__/  \____/ |_| |_| \__, ||_||_| |_| \___|
              | |                     __/ |               
              |_|                    |___/                

Made by: SUP_GAMERYT1 (Refactored for exam standards)
]]

--// Services Setup
-- We use these services to access key Roblox features like players, storage, datastore and HTTP calls
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

--// Configuration
local PREFIX = ":" -- All admin commands start with this character
local COOLDOWN_DURATION = 10 -- Prevents command spamming by adding a cooldown
local admins = {"SUP_GAMERYT1"} -- Only users in this list are allowed to run commands
local webhookUrl = "" -- Webhook used for external notifications (e.g., Discord)

--// State
local cooldown = false -- Track if a command is in cooldown
local commands = {} -- Holds all defined commands and their functions

--// Utility Functions
--- Check if the player is in the admin list
local function isAdmin(player)
	for _, admin in ipairs(admins) do
		if player.Name == admin then return true end
	end
	return false -- Not found in the list
end

--- Sends a formatted webhook message externally (Discord, etc.)
local function sendWebhook(player, eventType)
	local data = {
		content = "https://www.roblox.com/games/8780919502/Kyrenia-Storage-Facility", -- Game link
		embeds = {{
			title = ":scroll: TRAINING ANNOUNCEMENT :scroll:",
			description = ":small_orange_diamond: | A Training is being hosted by  " .. player.Name,
			color = 9961235, -- Orange-yellow highlight
			fields = {
				{name = "-", value = "** **"}, -- Spacer
				{name = "Event Type:", value = "**" .. eventType .. "**"},
				{name = "Rules", value = "Follow the rules to avoid punishment."},
				{name = "Abusing", value = "Trolling is not funny for others."}
			},
			image = {
				url = "https://tr.rbxcdn.com/2b79ec333ed66c6b16a4c92e3df2c615/768/432/Image/Png"
			}
		}}
	}
	local payload = HttpService:JSONEncode(data) -- Convert table to JSON
	HttpService:PostAsync(webhookUrl, payload) -- Send to webhook URL
end

--- Sends an on-screen notification to the player using GUI
local function sendNotification(player, message, color)
	local gui = player:WaitForChild("PlayerGui")
	local notifGui = gui:FindFirstChild("NotificationHandler")
	if notifGui then
		local label = notifGui.TextLabel:Clone() -- Clone to avoid interfering with template
		label.Text = message -- Set the notification message
		label.BackgroundColor3 = color -- Highlight color
		label.Parent = notifGui -- Parent to GUI
		label.Visible = true -- Show the notification
		ReplicatedStorage.SupEngine_Events.NotifSoundHandler:FireClient(player) -- Trigger sound
		task.delay(3, function()
			label:Destroy() -- Auto remove after 3 seconds
		end)
	end
end

--// Command Functions
-- Change the host's team to black and notify others
commands.host = function(player)
	if cooldown then return end
	player.TeamColor = BrickColor.new("Black") -- Team used for host
	cooldown = true
	sendNotification(player, ":mega: You have started hosting.", Color3.fromRGB(255, 170, 0))
	task.delay(COOLDOWN_DURATION, function()
		cooldown = false -- Re-enable command use
	end)
end

-- Reset hosting state (could be used for clarity or events ending)
commands.unhost = function(player)
	if cooldown then return end
	cooldown = true
	sendNotification(player, ":octagonal_sign: You have ended the hosting.", Color3.fromRGB(200, 200, 200))
	task.delay(COOLDOWN_DURATION, function()
		cooldown = false
	end)
end

-- Sends help UI to client
commands.hosthelp = function(player)
	ReplicatedStorage.SupEngine_Events.AdminHelpFE:FireClient(player)
end

--// Player Setup
-- Initializes leaderstats and wanted system for each player
local function setupPlayer(player)
	-- Leaderstats Setup (money stat visible on leaderboard)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats

	-- Extra Info Folder
	local info = Instance.new("Folder")
	info.Name = "Other_Info"
	info.Parent = player

	local wLevel = Instance.new("IntValue")
	wLevel.Name = "W_Level"
	wLevel.Value = 0
	wLevel.Parent = info

	local wantedRT = Instance.new("IntValue")
	wantedRT.Name = "WantedRT"
	wantedRT.Value = 0
	wantedRT.Parent = info

	-- Passive money gain system
	task.spawn(function()
		while player and player.Parent do
			task.wait(30)
			local gain = player:IsInGroup(3838582) and math.random(1000, 5000) or math.random(500, 1000)
			money.Value += gain
			sendNotification(player, "🏦 Bank: You received $"..gain, Color3.fromRGB(100, 255, 100))
		end
	end)
end

--// Chat Command Listener
-- Trigger admin commands by typing chat starting with :
Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)

	player.Chatted:Connect(function(msg)
		if not isAdmin(player) then return end
		if not msg:sub(1,1) == PREFIX then return end
		local args = msg:split(" ")
		local command = args[1]:sub(2):lower()
		table.remove(args, 1)
		if commands[command] then
			commands[command](player, unpack(args)) -- Execute command if found
		end
	end)
end)

--// Save Player Data on Leave
-- Persists player data when they leave or server shuts down
local datastore = DataStoreService:GetDataStore("SaveLeaderstats")

local function savePlayerData(player)
	local stats = {}
	for _, val in ipairs(player:WaitForChild("leaderstats"):GetChildren()) do
		stats[val.Name] = val.Value -- Store name and value of each stat
	end
	local success, err = pcall(function()
		datastore:SetAsync(tostring(player.UserId), stats)
	end)
	if not success then warn("[DataSave Failed]", err) end
end

-- Save on leave
Players.PlayerRemoving:Connect(savePlayerData)
-- Save on shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end) -- Final line
