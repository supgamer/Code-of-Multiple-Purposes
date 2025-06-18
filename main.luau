--[[

_____                 _____                _              
/  ___|               |  ___|              (_)             
\ `--.  _   _  _ __   | |__   _ __    __ _  _  _ __    ___ 
 `--. \| | | || '_ \  |  __| | '_ \  / _` || || '_ \  / _ \
/\__/ /| |_| || |_) | | |___ | | | || (_| || || | | ||  __/
\____/  \__,_|| .__/  \____/ |_| |_| \__, ||_||_| |_| \___|
              | |                     __/ |               
              |_|                    |___/                

Made by: SUP_GAMERYT1
--]]

--[[ Setup Services ]]--
local Players = game:GetService("Players")
local ReplStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HTTP = game:GetService("HttpService")

--[[ Admin and Command Config ]]--
local prefix = ":"
local cooldown = false
local admins = { "SUP_GAMERYT1" }
local commands = {}

--[[ Webhook Settings ]]--
local webhookurl = ""

--[[ Helper Functions ]]--
local function isAdmin(player)
    for _, admin in ipairs(admins) do
        if admin == player.Name then
            return true
        end
    end
    return false
end

local function sendWebhook(player, eventType)
    local data = {
        content = "https://www.roblox.com/games/8780919502/Kyrenia-Storage-Facility",
        embeds = {
            {
                title = ":scroll: TRAINING ANNOUNCEMENT :scroll:",
                description = ":small_orange_diamond: | A Training is being hosted by  " .. player.Name,
                color = 9961235,
                fields = {
                    { name = "-", value = "** **" },
                    { name = "Event Type:", value = "**" .. eventType .. "**" },
                    { name = "Rules", value = "Follow the rules to avoid punishment." },
                    { name = "Abusing", value = "Trolling is not funny for others." }
                },
                image = {
                    url = "https://tr.rbxcdn.com/2b79ec333ed66c6b16a4c92e3df2c615/768/432/Image/Png"
                }
            }
        }
    }
    local finaldata = HTTP:JSONEncode(data)
    HTTP:PostAsync(webhookurl, finaldata)
end

local function sendNotification(player, message, color)
    local notif = player.PlayerGui.NotificationHandler.TextLabel:Clone()
    notif.Text = message
    notif.Visible = true
    notif.BackgroundColor3 = color
    notif.Parent = player.PlayerGui.NotificationHandler
    ReplStorage.SupEngine_Events.NotifSoundHandler:FireClient(player)
    task.delay(3, function()
        notif:Destroy()
    end)
end

--[[ Player Setup ]]--
local function setupPlayer(player)
    local leaderstats = Instance.new("Folder", player)
    leaderstats.Name = "leaderstats"

    local info = Instance.new("Folder", player)
    info.Name = "Other_Info"

    local wantedLevel = Instance.new("IntValue", info)
    wantedLevel.Name = "W_Level"

    local wantedTimer = Instance.new("IntValue", info)
    wantedTimer.Name = "WantedRT"

    local money = Instance.new("IntValue", leaderstats)
    money.Name = "Money"

    player.CharacterAdded:Connect(function(char)
        local overhead = script.Rank:Clone()
        overhead.Parent = char:WaitForChild("Head")
        overhead.Enabled = true
        overhead.Frame.Name1.Text = player.Name
        overhead.Frame.Rank.Text = player:IsInGroup(3838582) and player:GetRoleInGroup(3838582) or "New Visitor"
        if player.Name == "SUP_GAMERYT1" then
            overhead["Owner Badge"].Transparency = 0
        end
    end)

    wantedTimer.Changed:Connect(function()
        if wantedTimer.Value == 0 then
            wantedLevel.Value = 0
            for _, star in ipairs(player.PlayerGui.WantedLevels.StarsHandler:GetChildren()) do
                if star:IsA("ImageLabel") then
                    star.Visible = false
                end
            end
        end
    end)

    task.spawn(function()
        while player and player.Parent do
            task.wait(30)
            local amount = player:IsInGroup(3838582) and math.random(1000, 5000) or math.random(500, 1000)
            money.Value += amount
            sendNotification(player, "🏦 Office of [NAME] Bank\nYou received $" .. amount, Color3.fromRGB(88, 255, 17))
        end
    end)
end

--[[ Command Registration ]]--
commands.host = function(player)
    if not cooldown then
        player.TeamColor = BrickColor.new("Black")
        cooldown = true
        task.delay(10, function()
            cooldown = false
        end)
    end
end

commands.unhost = function()
    if not cooldown then
        cooldown = true
        task.delay(10, function()
            cooldown = false
        end)
    end
end

commands.hosthelp = function(player)
    ReplStorage.SupEngine_Events.AdminHelpFE:FireClient(player)
end

--[[ Chat Parser ]]--
Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)

    player.Chatted:Connect(function(message)
        local args = message:split(" ")
        local commandName = args[1]:sub(2):lower()
        table.remove(args, 1)

        if message:sub(1, 1) == prefix and commands[commandName] then
            commands[commandName](player, args)
        end
    end)
end)

--[[ Wanted Trigger System ]]--
workspace:WaitForChild("WLH"):WaitForChild("Wanted_Handler").Triggered:Connect(function(plr)
    if plr.Team == game.Teams.Police then
        plr.Team = game.Teams.Civilian
        plr:LoadCharacter()
    end

    local level = plr.Other_Info.W_Level
    if level.Value < 6 then
        level.Value += 1
    end

    local star = plr.PlayerGui.WantedLevels.StarsHandler:FindFirstChild("star_" .. level.Value)
    if star then star.Visible = true end

    sendNotification(plr, "Wanted\nYou are wanted. Level: " .. level.Value, Color3.fromRGB(255, 0, 4))

    local timer = plr.Other_Info.WantedRT
    local active = true
    timer.Value += 15

    task.delay(1, function()
        active = false
    end)

    task.spawn(function()
        while not active do
            task.wait(1)
            if timer.Value > 0 then
                timer.Value -= 1
            end
        end
    end)
end)

--[[ DataStore Save System ]]--
local Saver = DataStoreService:GetDataStore("SaveLeaderstats")

local function saveData(player)
    local data = {}
    for _, stat in ipairs(player:WaitForChild("leaderstats"):GetChildren()) do
        data[stat.Name] = stat.Value
    end

    local success, err = pcall(function()
        Saver:SetAsync(tostring(player.UserId), data)
    end)

    if not success then warn(err) end
end

Players.PlayerAdded:Connect(function(player)
    local data
    local success, err = pcall(function()
        data = Saver:GetAsync(tostring(player.UserId))
    end)

    if success and data then
        for name, value in pairs(data) do
            local stat = player:WaitForChild("leaderstats"):FindFirstChild(name)
            if stat then stat.Value = value end
        end
    elseif not success then
        warn(err)
    end
end)

Players.PlayerRemoving:Connect(saveData)
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveData(player)
    end
end)
