

--// Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

--// Configuration
local PREFIX = ":" -- Prefix that identifies a message as a command
local COOLDOWN_TIME = 10 -- Time in seconds before a command can be used again
local WEBHOOK_URL = "" -- Replace with a valid webhook URL if needed
local GROUP_ID = 3838582 -- Group ID used to grant higher income rewards

--// Admin List
local Admins = {
	["SUP_GAMERYT1"] = true -- Add admin usernames here
}

--// Remote Events
local Events = ReplicatedStorage:WaitForChild("SupEngine_Events")
local NotifSound = Events:WaitForChild("NotifSoundHandler") -- Used to trigger notification sound
local AdminHelpFE = Events:WaitForChild("AdminHelpFE") -- Fires client UI

--// DataStore Reference
local LeaderData = DataStoreService:GetDataStore("SaveLeaderstats")

--// State Management
local isCooldown = false -- Used to prevent spamming of commands

--// Commands Table
local Commands = {} -- Table to register admin commands

--// Admin Check Function
local function IsAdmin(player)
	-- Return true if the player is listed in Admins table
	return Admins[player.Name] == true
end

--// Notification System
local function SendNotification(player, text, color)
	local gui = player:FindFirstChild("PlayerGui") -- GUI holder for player
	if not gui then return end

	local notifGui = gui:FindFirstChild("NotificationHandler") -- GUI folder where notification label exists
	if not notifGui then return end

	local label = notifGui:FindFirstChild("TextLabel") -- Template label to clone for each notification
	if not label then return end

	local clone = label:Clone() -- Clone so original isn't modified
	clone.Text = text -- Assign message
	clone.BackgroundColor3 = color -- Assign background color
	clone.Parent = notifGui -- Parent to GUI folder
	clone.Visible = true -- Make it appear

	NotifSound:FireClient(player) -- Fire a sound effect remotely

	task.delay(3, function()
		clone:Destroy() -- Remove after 3 seconds
	end)
end

--// Webhook Announcement System
local function SendWebhook(player, eventType)
	local data = {
		content = "https://www.roblox.com/games/8780919502/Kyrenia-Storage-Facility", -- Game link
		embeds = {
			{
				title = ":scroll: TRAINING ANNOUNCEMENT :scroll:",
				description = ":small_orange_diamond: | A Training is being hosted by  " .. player.Name,
				color = 9961235,
				fields = {
					{name = "-", value = "** **"},
					{name = "Event Type:", value = "**" .. eventType .. "**"},
					{name = "Rules", value = "Follow the rules to avoid punishment."},
					{name = "Abusing", value = "Trolling is not funny for others."}
				},
				image = {
					url = "https://tr.rbxcdn.com/2b79ec333ed66c6b16a4c92e3df2c615/768/432/Image/Png"
				}
			}
		}
	}

	local success, err = pcall(function()
		HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data)) -- Convert data to JSON and post
	end)
	if not success then warn("[Webhook Error]", err) end
end

--// Command Definitions
Commands.host = function(player)
	if isCooldown then return end -- Skip if cooldown active

	player.TeamColor = BrickColor.new("Black") -- Assign team color
	isCooldown = true -- Start cooldown
	SendNotification(player, ":mega: Hosting started.", Color3.fromRGB(255, 200, 0))
	task.delay(COOLDOWN_TIME, function()
		isCooldown = false -- Reset cooldown
	end)
end

Commands.unhost = function(player)
	if isCooldown then return end
	isCooldown = true
	SendNotification(player, ":octagonal_sign: Hosting ended.", Color3.fromRGB(170, 170, 170))
	task.delay(COOLDOWN_TIME, function()
		isCooldown = false
	end)
end

Commands.hosthelp = function(player)
	AdminHelpFE:FireClient(player) -- Trigger help GUI
end

--// Leaderstats Setup
local function SetupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats
end

--// Extra Info Stats Setup
local function SetupInfoStats(player)
	local info = Instance.new("Folder")
	info.Name = "Other_Info"
	info.Parent = player

	local wl = Instance.new("IntValue")
	wl.Name = "W_Level"
	wl.Value = 0
	wl.Parent = info

	local rt = Instance.new("IntValue")
	rt.Name = "WantedRT"
	rt.Value = 0
	rt.Parent = info
end

--// Load Stats from DataStore
local function LoadStats(player)
	local success, data = pcall(function()
		return LeaderData:GetAsync(tostring(player.UserId))
	end)
	if success and data then
		local stats = player:WaitForChild("leaderstats")
		for name, val in pairs(data) do
			if stats:FindFirstChild(name) then
				stats[name].Value = val -- Restore each saved stat
			end
		end
	end
end

--// Save Stats to DataStore
local function SaveStats(player)
	local stats = {}
	for _, stat in ipairs(player:WaitForChild("leaderstats"):GetChildren()) do
		stats[stat.Name] = stat.Value
	end
	local success, err = pcall(function()
		LeaderData:SetAsync(tostring(player.UserId), stats)
	end)
	if not success then warn("[Save Error]", err) end
end

--// Income Generator
local function StartIncome(player)
	task.spawn(function()
		while player and player.Parent do
			task.wait(30)
			local income = player:IsInGroup(GROUP_ID) and math.random(1000, 5000) or math.random(500, 1000)
			player.leaderstats.Money.Value += income
			SendNotification(player, "🏦 Bank: You received $"..income, Color3.fromRGB(100, 255, 100))
		end
	end)
end

--// Player Added Handler
Players.PlayerAdded:Connect(function(player)
	SetupLeaderstats(player)
	SetupInfoStats(player)
	LoadStats(player)
	StartIncome(player)

	player.Chatted:Connect(function(msg)
		if not IsAdmin(player) then return end -- Not admin, ignore
		if msg:sub(1,1) ~= PREFIX then return end -- Doesn't match prefix

		local args = msg:split(" ")
		local command = args[1]:sub(2):lower()
		table.remove(args, 1)

		if Commands[command] then
			Commands[command](player, unpack(args)) -- Execute valid command
		end
	end)
end)

--// Player Removed Handler
Players.PlayerRemoving:Connect(SaveStats)

--// Game Shutdown Save All
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		SaveStats(player)
		print('All Data Saved to:'..player.Name)
	end
end)
