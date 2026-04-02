local ALLOWED_PLACE_IDS = {
    [109983668079237] = true,
    [96342491571673] = true,
}

if not ALLOWED_PLACE_IDS[game.PlaceId] then
    print("Wrong game boii")
    return
end

do
    local oldInfo
    oldInfo = hookfunction(debug.info, function(...)
        local src = oldInfo(1, "s")
        if src and src:find("Packages.Synchronizer") then
            return nil
        end
        return oldInfo(...)
    end)
end

local S = {
    Players = game:GetService("Players"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
    RunService = game:GetService("RunService"),
    Stats = game:GetService("Stats"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    UserInputService = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting"),
}

local player = S.Players.LocalPlayer

local Packages = S.ReplicatedStorage:WaitForChild("Packages")
local Datas = S.ReplicatedStorage:WaitForChild("Datas")
local Shared = S.ReplicatedStorage:WaitForChild("Shared")
local Utils = S.ReplicatedStorage:WaitForChild("Utils")

S.Synchronizer = require(Packages:WaitForChild("Synchronizer"))
S.AnimalsData = require(Datas:WaitForChild("Animals"))
S.AnimalsShared = require(Shared:WaitForChild("Animals"))
S.NumberUtils = require(Utils:WaitForChild("NumberUtils"))
S.RaritiesData = require(Datas:WaitForChild("Rarities"))

local FileName = "RenHubPrivate_v1.json"
local DefaultConfig = {
    Positions = {
        CreditFrame = {X = 0.5, Y = 0.065},
        MainFrame = {X = 0.65, Y = 0.5},
        MenuFrame = {X = 0.35, Y = 0.5},
    },
    Favorites = {
        Animals = {},
    },
    Keybinds = {
        CloneKey = "V",
        CarpetSpeedKey = "Q",
    },
    Settings = false,
    LockGui = false,
}

local Config = DefaultConfig

if isfile and isfile(FileName) then
    pcall(function()
        local ok, decoded = pcall(function()
            return S.HttpService:JSONDecode(readfile(FileName))
        end)
        if not ok then return end
        for k, v in pairs(DefaultConfig) do
            if decoded[k] == nil then
                decoded[k] = v
            elseif type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if decoded[k][k2] == nil then
                        decoded[k][k2] = v2
                    end
                end
            end
        end
        Config = decoded
    end)
end

local function SaveConfig()
    if writefile then
        pcall(function()
            local toSave = {}
            for k, v in pairs(Config) do
                toSave[k] = v
            end
            writefile(FileName, S.HttpService:JSONEncode(toSave))
        end)
    end
end

local activeNotifications = {}
local NOTIF_HEIGHT = 56
local NOTIF_SPACING = 10
local MAX_NOTIFS = 3

local NotifColors = {
    Default = Color3.fromRGB(180, 140, 255),
    Failed  = Color3.fromRGB(220, 40,  40),
    Success = Color3.fromRGB(120, 40, 220),
    White   = Color3.fromRGB(255, 255, 255),
    Purple  = Color3.fromRGB(150, 80, 240),
    Violet  = Color3.fromRGB(120, 40, 220),
}

local function updateNotificationPositions()
    for i, notifData in ipairs(activeNotifications) do
        local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
        S.TweenService:Create(notifData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, newYPos)
        }):Play()
    end
end

local function removeNotification(notifData)
    for i, data in ipairs(activeNotifications) do
        if data == notifData then table.remove(activeNotifications, i) break end
    end
    updateNotificationPositions()
end

local function showNotification(opts)
    opts = opts or {}
    local message   = opts.message  or ""
    local subtext   = opts.subtext  or nil
    local color     = opts.color and NotifColors[opts.color] or NotifColors.Default
    local textColor = opts.textColor and NotifColors[opts.textColor] or color
    local subColor  = opts.subColor and NotifColors[opts.subColor] or color

    if #activeNotifications >= MAX_NOTIFS then
        local oldest = activeNotifications[1]
        if oldest.barTween then oldest.barTween:Cancel() end
        table.remove(activeNotifications, 1)
        updateNotificationPositions()
        S.TweenService:Create(oldest.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -260, 0, oldest.frame.Position.Y.Offset)
        }):Play()
        task.delay(0.3, function() oldest.frame:Destroy() end)
    end

    local notifGui = game:GetService("CoreGui"):FindFirstChild("RenNotifGui")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "RenNotifGui"
        notifGui.ResetOnSpawn = false
        notifGui.Parent = game:GetService("CoreGui")
    end

    local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
    local frameHeight = subtext and 57 or NOTIF_HEIGHT

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, frameHeight)
    notif.Position = UDim2.new(0, -260, 0, startYPos)
    notif.BackgroundColor3 = Color3.fromRGB(8, 5, 18)
    notif.BorderSizePixel = 0
    notif.Parent = notifGui

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 8)
    nCorner.Parent = notif

    local nStroke = Instance.new("UIStroke")
    nStroke.Thickness = 1
    nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    nStroke.Color = Color3.fromRGB(80, 40, 120)
    nStroke.Parent = notif

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(0, 4, 0, 4)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(120, 80, 160)
    closeButton.TextSize = 11
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notif

    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(200, 150, 255) end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Color3.fromRGB(120, 80, 160) end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -36, 0, subtext and 26 or frameHeight - 6)
    textLabel.Position = UDim2.new(0, 30, 0, subtext and 8 or 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = textColor
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true
    textLabel.Parent = notif

    if subtext then
        local subLabel = Instance.new("TextLabel")
        subLabel.Size = UDim2.new(1, -36, 0, 18)
        subLabel.Position = UDim2.new(0, 30, 0, 28)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = subtext
        subLabel.TextColor3 = subColor
        subLabel.TextSize = 10
        subLabel.Font = Enum.Font.Gotham
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.TextYAlignment = Enum.TextYAlignment.Center
        subLabel.TextWrapped = true
        subLabel.Parent = notif
    end

    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, 0, 0, 3)
    barContainer.Position = UDim2.new(0, 0, 1, -3)
    barContainer.BackgroundTransparency = 1
    barContainer.ClipsDescendants = true
    barContainer.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = barContainer

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = progressBar

    local notifData = { frame = notif, progressBar = progressBar, barTween = nil }
    table.insert(activeNotifications, notifData)

    S.TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 10, 0, startYPos)
    }):Play()

    local barTween = S.TweenService:Create(progressBar, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    notifData.barTween = barTween
    barTween:Play()

    local function dismiss()
        if notifData.barTween then notifData.barTween:Cancel() end
        if notif.Parent then
            S.TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -260, 0, notif.Position.Y.Offset)
            }):Play()
            task.delay(0.3, function() if notif.Parent then notif:Destroy() end end)
            removeNotification(notifData)
        end
    end

    closeButton.MouseButton1Click:Connect(dismiss)
    task.delay(2, dismiss)
end

local FAVORITES_LIST = {
    "Strawberry Elephant", "Meowl", "Skibidi Toilet", "Headless Horseman",
    "Dragon Gingerini", "Dragon Cannelloni", "Ketupat Bros", "Hydra Dragon Cannelloni",
    "La Supreme Combinasion", "Love Love Bear", "Cerberus", "Capitano Moby",
    "Celestial Pegasus", "Fortunu and Cashuru", "Cloverat Clapat", "Griffin",
    "Cooki and Milki", "Rosey and Teddy", "Popcuru and Fizzuru", "Reinito Sleighito",
    "Fragrama and Chocrama", "Signore Carapace", "La Taco Combinasion"
}

local FAVORITES = {}

if Config.Favorites.Animals and #Config.Favorites.Animals > 0 then
    FAVORITES = Config.Favorites.Animals
else
    for _, name in ipairs(FAVORITES_LIST) do
        table.insert(FAVORITES, name)
    end
    Config.Favorites.Animals = FAVORITES
    SaveConfig()
end

local function saveFavorites()
    Config.Favorites.Animals = FAVORITES
    SaveConfig()
end

local function isFavorite(animalName)
    for _, name in ipairs(FAVORITES) do
        if name:lower() == animalName:lower() then return true end
    end
    return false
end

local function addFavorite(animalName)
    if isFavorite(animalName) then return false end
    table.insert(FAVORITES, animalName)
    saveFavorites()
    showNotification({message = "Favorited: " .. animalName, color = "Success", textColor = "White"})
    return true
end

local function removeFavorite(animalName)
    for i, name in ipairs(FAVORITES) do
        if name:lower() == animalName:lower() then
            table.remove(FAVORITES, i)
            saveFavorites()
            showNotification({message = "Removed: " .. animalName, color = "Failed", textColor = "White"})
            return true
        end
    end
    return false
end

local function moveFavoriteUp(index)
    if index > 1 and index <= #FAVORITES then
        FAVORITES[index], FAVORITES[index - 1] = FAVORITES[index - 1], FAVORITES[index]
        saveFavorites()
        return true
    end
    return false
end

local function moveFavoriteDown(index)
    if index >= 1 and index < #FAVORITES then
        FAVORITES[index], FAVORITES[index + 1] = FAVORITES[index + 1], FAVORITES[index]
        saveFavorites()
        return true
    end
    return false
end

local function getFavoriteByPriority(cache)
    for _, favName in ipairs(FAVORITES) do
        for _, animal in ipairs(cache) do
            if animal.name:lower() == favName:lower() then return animal end
        end
    end
    return nil
end

local allAnimalsCache = {}
local scannerConnections = {}
local plotChannels = {}
local lastAnimalData = {}
local highestAnimal = nil

local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local yourBase = plotSign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return true end
    end
    return false
end

local function getAnimalHash(animalList)
    if not animalList then return "" end
    local hash = ""
    for slot, data in pairs(animalList) do
        if type(data) == "table" then
            hash = hash .. tostring(slot) .. tostring(data.Index) .. tostring(data.Mutation)
        end
    end
    return hash
end

local function scanSinglePlot(plot)
    pcall(function()
        if isPlayerPlot(plot) then return end
        local plotUID = plot.Name
        local channel = S.Synchronizer:Get(plotUID)
        if not channel then return end
        local animalList = channel:Get("AnimalList")
        local currentHash = getAnimalHash(animalList)
        if lastAnimalData[plotUID] == currentHash then return end
        lastAnimalData[plotUID] = currentHash
        for i = #allAnimalsCache, 1, -1 do
            if allAnimalsCache[i].plot == plot.Name then table.remove(allAnimalsCache, i) end
        end
        local owner = channel:Get("Owner")
        if not owner or not S.Players:FindFirstChild(owner.Name) then return end
        local ownerName = owner and owner.Name or "Unknown"
        local ownerPlayer = S.Players:FindFirstChild(ownerName)
        local isDuelBase = ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true or false
        if not animalList then return end
        for slot, animalData in pairs(animalList) do
            if type(animalData) == "table" then
                local animalName = animalData.Index
                local animalInfo = S.AnimalsData[animalName]
                if not animalInfo then continue end
                local rarity = animalInfo.Rarity
                local rarityColor = (S.RaritiesData[rarity] and S.RaritiesData[rarity].Color) or Color3.fromRGB(255, 255, 255)
                local mutation = animalData.Mutation or "None"
                local traits = (animalData.Traits and #animalData.Traits > 0) and table.concat(animalData.Traits, ", ") or "None"
                local genValue = S.AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
                local genText = "$" .. S.NumberUtils:ToString(genValue) .. "/s"
                table.insert(allAnimalsCache, {
                    name        = animalInfo.DisplayName or animalName,
                    genText     = genText,
                    genValue    = genValue,
                    rarity      = rarity,
                    rarityColor = rarityColor,
                    mutation    = mutation,
                    traits      = traits,
                    owner       = ownerName,
                    plot        = plot.Name,
                    slot        = tostring(slot),
                    uid         = plot.Name .. "_" .. tostring(slot),
                    modelName   = animalName,
                    isDuelBase  = isDuelBase,
                })
            end
        end
        table.sort(allAnimalsCache, function(a, b) return a.genValue > b.genValue end)
        highestAnimal = allAnimalsCache[1]
    end)
end

local function setupPlotListener(plot)
    if plotChannels[plot.Name] then return end
    local channel
    local retries = 0
    while not channel and retries < 10 do
        local ok, result = pcall(function() return S.Synchronizer:Get(plot.Name) end)
        if ok and result then channel = result; break
        else retries += 1; if retries < 10 then task.wait(0.5) end end
    end
    if not channel then return end
    plotChannels[plot.Name] = true
    scanSinglePlot(plot)
    local c1 = plot.DescendantAdded:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
    local c2 = plot.DescendantRemoving:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
    table.insert(scannerConnections, c1)
    table.insert(scannerConnections, c2)
    task.spawn(function()
        while plot.Parent and plotChannels[plot.Name] do
            task.wait(5); scanSinglePlot(plot)
        end
    end)
end

local function initializePlotScanner()
    local plots = workspace:WaitForChild("Plots", 8)
    if not plots then warn("Plots folder not found!") return end
    for _, plot in ipairs(plots:GetChildren()) do
        task.spawn(function() setupPlotListener(plot) end)
    end
    local newPlotConn = plots.ChildAdded:Connect(function(plot)
        task.wait(0.5); setupPlotListener(plot)
    end)
    table.insert(scannerConnections, newPlotConn)
    local removedPlotConn = plots.ChildRemoved:Connect(function(plot)
        plotChannels[plot.Name] = nil
        lastAnimalData[plot.Name] = nil
        for i = #allAnimalsCache, 1, -1 do
            if allAnimalsCache[i].plot == plot.Name then table.remove(allAnimalsCache, i) end
        end
        highestAnimal = allAnimalsCache[1]
    end)
    table.insert(scannerConnections, removedPlotConn)
end

S.Players.PlayerRemoving:Connect(function(leavingPlayer)
    for i = #allAnimalsCache, 1, -1 do
        if allAnimalsCache[i].owner == leavingPlayer.Name then table.remove(allAnimalsCache, i) end
    end
    highestAnimal = allAnimalsCache[1]
end)

initializePlotScanner()

local function setupDuelListener(p)
    p:GetAttributeChangedSignal("__duels_block_steal"):Connect(function()
        local isDuel = p:GetAttribute("__duels_block_steal") == true
        for _, animal in ipairs(allAnimalsCache) do
            if animal.owner == p.Name then animal.isDuelBase = isDuel end
        end
    end)
end

for _, p in ipairs(S.Players:GetPlayers()) do setupDuelListener(p) end
S.Players.PlayerAdded:Connect(function(p) setupDuelListener(p) end)

local C = {
    white        = Color3.fromRGB(255, 255, 255),
    black        = Color3.fromRGB(0, 0, 0),
    bg           = Color3.fromRGB(8, 8, 15),
    primary      = Color3.fromRGB(120, 40, 220),
    accent       = Color3.fromRGB(180, 120, 255),
    buttonPurple = Color3.fromRGB(150, 80, 240),
    darkPurple   = Color3.fromRGB(30, 15, 60),
    toggleOn     = Color3.fromRGB(120, 40, 220),
    subtitleGrey = Color3.fromRGB(150, 140, 180),
    dividerGrey  = Color3.fromRGB(50, 40, 70),
    decorPurple  = Color3.fromRGB(160, 100, 255),
    tabActive    = Color3.fromRGB(180, 120, 255),
    tabInactive  = Color3.fromRGB(100, 80, 130),
    green        = Color3.fromRGB(46, 204, 113),
    yellow       = Color3.fromRGB(241, 196, 15),
    red          = Color3.fromRGB(231, 76, 60),
    coolPurple   = Color3.fromRGB(80, 20, 180),
}

local function addTextGradient(textElement, color1, color2, rotation)
    rotation = rotation or 45
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation
    gradient.Parent = textElement
    task.spawn(function()
        while textElement.Parent and gradient.Parent do
            for rot = rotation, rotation + 360, 2 do
                if not gradient.Parent then break end
                gradient.Rotation = rot
                task.wait(0.03)
            end
        end
    end)
    return gradient
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RENHUB"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

local function trackPosition(target, saveKey)
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if saveKey then
                        task.wait()
                        local screenSize = screenGui.AbsoluteSize
                        Config.Positions[saveKey] = {
                            X = (target.AbsolutePosition.X + target.AbsoluteSize.X / 2) / screenSize.X,
                            Y = (target.AbsolutePosition.Y + target.AbsoluteSize.Y / 2) / screenSize.Y,
                        }
                        SaveConfig()
                    end
                end
            end)
        end
    end)
end

local creditFrame = Instance.new("Frame")
creditFrame.Name = "CreditFrame"
creditFrame.Size = UDim2.new(0, 340, 0, 50)
local creditPos = Config.Positions.CreditFrame
creditFrame.Position = UDim2.new(creditPos.X, -170, creditPos.Y, -25)
creditFrame.BackgroundColor3 = C.bg
creditFrame.BackgroundTransparency = 0.03
creditFrame.BorderSizePixel = 0
creditFrame.Active = true
creditFrame.Draggable = true
creditFrame.Parent = screenGui
trackPosition(creditFrame, "CreditFrame")

local creditFrameCorner = Instance.new("UICorner")
creditFrameCorner.CornerRadius = UDim.new(0, 9)
creditFrameCorner.Parent = creditFrame

local creditFrameStroke = Instance.new("UIStroke")
creditFrameStroke.Thickness = 1
creditFrameStroke.Color = C.coolPurple
creditFrameStroke.Transparency = 0.5
creditFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
creditFrameStroke.Parent = creditFrame

local logoFrame = Instance.new("Frame")
logoFrame.Name = "LogoFrame"
logoFrame.Size = UDim2.new(0, 40, 0, 40)
logoFrame.Position = UDim2.new(0, 5, 0.5, -20)
logoFrame.BackgroundColor3 = C.darkPurple
logoFrame.BorderSizePixel = 0
logoFrame.Parent = creditFrame

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 6)
logoCorner.Parent = logoFrame

local logoImage = Instance.new("ImageLabel")
logoImage.Size = UDim2.new(1, 0, 1, 0)
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://83799989511542"
logoImage.Parent = logoFrame

local logoImageCorner = Instance.new("UICorner")
logoImageCorner.CornerRadius = UDim.new(0, 6)
logoImageCorner.Parent = logoImage

local creditTitle = Instance.new("TextLabel")
creditTitle.Name = "CreditTitle"
creditTitle.Size = UDim2.new(0, 120, 0, 20)
creditTitle.Position = UDim2.new(0, 55, 0, 8)
creditTitle.BackgroundTransparency = 1
creditTitle.Text = "RENHUB PRIVATE"
creditTitle.TextColor3 = C.white
creditTitle.Font = Enum.Font.MontserratBlack
creditTitle.TextSize = 14
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.TextYAlignment = Enum.TextYAlignment.Center
creditTitle.Parent = creditFrame
addTextGradient(creditTitle, C.primary, C.accent, 45)

local creditDivider = Instance.new("Frame")
creditDivider.Size = UDim2.new(0, 1, 0, 15)
creditDivider.Position = UDim2.new(0, 172, 0, 10)
creditDivider.BackgroundColor3 = C.dividerGrey
creditDivider.BorderSizePixel = 0
creditDivider.Parent = creditFrame

local discordLabel = Instance.new("TextLabel")
discordLabel.Size = UDim2.new(0, 100, 0, 20)
discordLabel.Position = UDim2.new(0, 178, 0, 8)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = ".GG/RENHUB"
discordLabel.TextColor3 = C.white
discordLabel.Font = Enum.Font.MontserratBlack
discordLabel.TextSize = 14
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.TextYAlignment = Enum.TextYAlignment.Center
discordLabel.Parent = creditFrame
addTextGradient(discordLabel, C.primary, C.accent, 45)

local creditDivider2 = Instance.new("Frame")
creditDivider2.Size = UDim2.new(0, 1, 0, 28)
creditDivider2.Position = UDim2.new(0, 268, 0, 9)
creditDivider2.BackgroundColor3 = C.dividerGrey
creditDivider2.BorderSizePixel = 0
creditDivider2.Parent = creditFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 60, 0, 12)
fpsLabel.Position = UDim2.new(0, 278, 0, 8)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 60"
fpsLabel.TextColor3 = C.green
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 10
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.TextYAlignment = Enum.TextYAlignment.Center
fpsLabel.Parent = creditFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(0, 80, 0, 12)
pingLabel.Position = UDim2.new(0, 278, 0, 24)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "PING: 0ms"
pingLabel.TextColor3 = C.green
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextSize = 10
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.TextYAlignment = Enum.TextYAlignment.Center
pingLabel.Parent = creditFrame

local frames = 0
local last = tick()
S.RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        local fps = frames; frames = 0; last = now
        local ok, rawPing = pcall(function()
            return S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        local ping = ok and math.floor(rawPing + 0.5) or 0
        fpsLabel.Text = "FPS: " .. fps
        if fps >= 49 then fpsLabel.TextColor3 = C.green
        elseif fps >= 32 then fpsLabel.TextColor3 = C.yellow
        else fpsLabel.TextColor3 = C.red end
        pingLabel.Text = "PING: " .. ping .. "ms"
        if ping < 70 then pingLabel.TextColor3 = C.green
        elseif ping < 100 then pingLabel.TextColor3 = C.yellow
        else pingLabel.TextColor3 = C.red end
    end
end)

local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.new(0, 340, 0, 15)
creditsLabel.Position = UDim2.new(0, 55, 1, -22)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "Made By @Ren"
creditsLabel.TextColor3 = C.subtitleGrey
creditsLabel.Font = Enum.Font.GothamMedium
creditsLabel.TextSize = 9
creditsLabel.TextXAlignment = Enum.TextXAlignment.Left
creditsLabel.TextYAlignment = Enum.TextYAlignment.Center
creditsLabel.Parent = creditFrame

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 193, 0, 277)
local mainPos = Config.Positions.MainFrame
mainFrame.Position = UDim2.new(mainPos.X, -96.5, mainPos.Y, -142.5)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BackgroundTransparency = 0.03
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
trackPosition(mainFrame, "MainFrame")

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 9)
frameCorner.Parent = mainFrame

local mainFrameStroke = Instance.new("UIStroke")
mainFrameStroke.Thickness = 1
mainFrameStroke.Color = C.coolPurple
mainFrameStroke.Transparency = 0.5
mainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainFrameStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 3)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "RENHUB PRIVATE"
titleLabel.TextColor3 = C.white
titleLabel.Font = Enum.Font.MontserratBlack
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Parent = mainFrame
addTextGradient(titleLabel, C.primary, C.accent, 45)

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
subtitleLabel.Position = UDim2.new(0, 0, 0, 21)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Actions"
subtitleLabel.TextColor3 = C.subtitleGrey
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextSize = 9
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
subtitleLabel.Parent = mainFrame

local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 360, 0, 360)
local menuPos = Config.Positions.MenuFrame
menuFrame.Position = UDim2.new(menuPos.X, -180, menuPos.Y, -180)
menuFrame.BackgroundColor3 = C.white
menuFrame.BackgroundTransparency = 0.03
menuFrame.BorderSizePixel = 0
menuFrame.Active = true
menuFrame.Draggable = true
menuFrame.Visible = Config.Settings
menuFrame.Parent = screenGui
trackPosition(menuFrame, "MenuFrame")

local menuFrameCorner = Instance.new("UICorner")
menuFrameCorner.CornerRadius = UDim.new(0, 9)
menuFrameCorner.Parent = menuFrame

local menuFrameGradient = Instance.new("UIGradient")
menuFrameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    C.black),
    ColorSequenceKeypoint.new(0.35, C.black),
    ColorSequenceKeypoint.new(0.65, C.coolPurple),
    ColorSequenceKeypoint.new(1,    C.black),
})
menuFrameGradient.Rotation = 135
menuFrameGradient.Parent = menuFrame

if Config.LockGui then
    creditFrame.Draggable = false
    mainFrame.Draggable = false
    menuFrame.Draggable = false
end

local menuTitleLabel = Instance.new("TextLabel")
menuTitleLabel.Size = UDim2.new(0, 180, 0, 25)
menuTitleLabel.Position = UDim2.new(0, 10, 0, 3)
menuTitleLabel.BackgroundTransparency = 1
menuTitleLabel.Text = "RENHUB PRIVATE"
menuTitleLabel.TextColor3 = C.white
menuTitleLabel.Font = Enum.Font.MontserratBlack
menuTitleLabel.TextSize = 12
menuTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
menuTitleLabel.TextYAlignment = Enum.TextYAlignment.Center
menuTitleLabel.Parent = menuFrame
addTextGradient(menuTitleLabel, C.primary, C.accent, 45)

local versionBadge = Instance.new("Frame")
versionBadge.Size = UDim2.new(0, 45, 0, 18)
versionBadge.Position = UDim2.new(0, 125, 0, 7)
versionBadge.BackgroundColor3 = C.black
versionBadge.BorderSizePixel = 0
versionBadge.Parent = menuFrame

local versionBadgeCorner = Instance.new("UICorner")
versionBadgeCorner.CornerRadius = UDim.new(1, 0)
versionBadgeCorner.Parent = versionBadge

local versionBadgeStroke = Instance.new("UIStroke")
versionBadgeStroke.Thickness = 1.5
versionBadgeStroke.Color = C.coolPurple
versionBadgeStroke.Transparency = 0.3
versionBadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
versionBadgeStroke.Parent = versionBadge

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, 0, 1, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0"
versionLabel.Font = Enum.Font.MontserratBold
versionLabel.TextSize = 10
versionLabel.TextColor3 = C.accent
versionLabel.TextXAlignment = Enum.TextXAlignment.Center
versionLabel.TextYAlignment = Enum.TextYAlignment.Center
versionLabel.Parent = versionBadge

local decorCircle = Instance.new("Frame")
decorCircle.Size = UDim2.new(0, 8, 0, 8)
decorCircle.Position = UDim2.new(1, -20, 0, 12)
decorCircle.BackgroundColor3 = C.decorPurple
decorCircle.BorderSizePixel = 0
decorCircle.Parent = menuFrame
Instance.new("UICorner", decorCircle).CornerRadius = UDim.new(1, 0)

local headerDivider = Instance.new("Frame")
headerDivider.Size = UDim2.new(1, -20, 0, 1)
headerDivider.Position = UDim2.new(0, 10, 0, 32)
headerDivider.BackgroundColor3 = C.dividerGrey
headerDivider.BorderSizePixel = 0
headerDivider.Parent = menuFrame

local currentTab = "Brainrot"
local tabs = {"Brainrot", "Features", "Utility", "UI", "Keybinds", "Priority"}
local tabButtons = {}
local tabIndicators = {}
local tabContents = {}

local sidebarContainer = Instance.new("Frame")
sidebarContainer.Name = "Sidebar"
sidebarContainer.Size = UDim2.new(0, 70, 1, -42)
sidebarContainer.Position = UDim2.new(0, 0, 0, 42)
sidebarContainer.BackgroundTransparency = 1
sidebarContainer.BorderSizePixel = 0
sidebarContainer.Parent = menuFrame

local sidebarDivider = Instance.new("Frame")
sidebarDivider.Size = UDim2.new(0, 1, 1, -50)
sidebarDivider.Position = UDim2.new(0, 70, 0, 45)
sidebarDivider.BackgroundColor3 = C.dividerGrey
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = menuFrame

local function createTabContent(name)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = name .. "Content"
    contentFrame.Size = UDim2.new(1, -80, 1, -50)
    contentFrame.Position = UDim2.new(0, 75, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 3
    contentFrame.ScrollBarImageColor3 = C.accent
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Visible = (name == currentTab)
    contentFrame.Parent = menuFrame
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = contentFrame
    return contentFrame
end

for i, tabName in ipairs(tabs) do
    local indicator = Instance.new("Frame")
    indicator.Name = tabName .. "Indicator"
    indicator.Size = UDim2.new(1, -8, 0, 26)
    indicator.Position = UDim2.new(0, 4, 0, (i-1) * 38 + 4)
    indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    indicator.BackgroundTransparency = currentTab == tabName and 0.6 or 1
    indicator.BorderSizePixel = 0
    indicator.Parent = sidebarContainer
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 5)
    tabIndicators[tabName] = indicator

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "Tab"
    tabBtn.Size = UDim2.new(1, 0, 0, 38)
    tabBtn.Position = UDim2.new(0, 0, 0, (i-1) * 38)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = tabName
    tabBtn.TextColor3 = currentTab == tabName and C.accent or C.subtitleGrey
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 8
    tabBtn.TextWrapped = true
    tabBtn.ZIndex = 2
    tabBtn.Parent = sidebarContainer
    tabButtons[tabName] = tabBtn

    local tabContent = createTabContent(tabName)
    tabContents[tabName] = tabContent

    tabBtn.MouseButton1Click:Connect(function()
        -- Hide all
        for _, content in pairs(tabContents) do content.Visible = false end
        for name, ind in pairs(tabIndicators) do
            ind.BackgroundTransparency = 1
            tabButtons[name].TextColor3 = C.subtitleGrey
        end
        -- Show selected
        tabContent.Visible = true
        indicator.BackgroundTransparency = 0.6
        tabBtn.TextColor3 = C.accent
        currentTab = tabName
    end)
end

local function createSectionHeader(parent, sectionName)
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 22)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = parent
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, 0, 1, 0)
    headerLabel.Position = UDim2.new(0, 3, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = sectionName
    headerLabel.TextColor3 = C.accent
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 10
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextYAlignment = Enum.TextYAlignment.Center
    headerLabel.Parent = headerFrame
    return headerFrame
end

local function createButton(name, yPosition, callback)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(0, 167, 0, 28)
    button.Position = UDim2.new(0.5, -83.5, 0, yPosition)
    button.BackgroundColor3 = C.darkPurple
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = C.accent
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.Parent = mainFrame
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Thickness = 1
    buttonStroke.Color = C.primary
    buttonStroke.Transparency = 0.5
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Parent = button
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return button
end

local function createToggle(name, yPosition, configKey, callback)
    local function setToggle(state) Config[configKey] = state; SaveConfig() end
    local toggleEnabled = Config[configKey] or false
    local button = Instance.new("TextButton")
    button.Name = name .. "Toggle"
    button.Size = UDim2.new(0, 167, 0, 28)
    button.Position = UDim2.new(0.5, -83.5, 0, yPosition)
    button.BackgroundColor3 = toggleEnabled and C.toggleOn or C.darkPurple
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = C.accent
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.Parent = mainFrame
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Thickness = 1
    buttonStroke.Color = C.primary
    buttonStroke.Transparency = 0.5
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Parent = button
    button.MouseButton1Click:Connect(function()
        toggleEnabled = not toggleEnabled
        button.BackgroundColor3 = toggleEnabled and C.toggleOn or C.darkPurple
        if callback then callback(toggleEnabled, setToggle) end
    end)
    return button
end

local function createTabToggle(parent, name, configKey, callback)
    local function setToggle(state) Config[configKey] = state; SaveConfig() end
    local toggleEnabled = Config[configKey] or false
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 28)
    toggleFrame.BackgroundColor3 = C.black
    toggleFrame.BackgroundTransparency = 0.20
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent
    Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0, 160, 1, 0)
    toggleLabel.Position = UDim2.new(0, 8, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = C.white
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 10
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.TextYAlignment = Enum.TextYAlignment.Center
    toggleLabel.Parent = toggleFrame
    local toggleSwitch = Instance.new("Frame")
    toggleSwitch.Size = UDim2.new(0, 28, 0, 16)
    toggleSwitch.Position = UDim2.new(1, -36, 0.5, -8)
    toggleSwitch.BackgroundColor3 = toggleEnabled and C.accent or Color3.fromRGB(40, 30, 60)
    toggleSwitch.BorderSizePixel = 0
    toggleSwitch.Parent = toggleFrame
    Instance.new("UICorner", toggleSwitch).CornerRadius = UDim.new(1, 0)
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 12, 0, 12)
    toggleCircle.Position = toggleEnabled and UDim2.new(0, 14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    toggleCircle.BackgroundColor3 = C.white
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleSwitch
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = toggleFrame
    clickButton.MouseButton1Click:Connect(function()
        toggleEnabled = not toggleEnabled
        local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if toggleEnabled then
            S.TweenService:Create(toggleSwitch, ti, {BackgroundColor3 = C.accent}):Play()
            S.TweenService:Create(toggleCircle, ti, {Position = UDim2.new(0, 14, 0.5, -6)}):Play()
        else
            S.TweenService:Create(toggleSwitch, ti, {BackgroundColor3 = Color3.fromRGB(40, 30, 60)}):Play()
            S.TweenService:Create(toggleCircle, ti, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        end
        if callback then callback(toggleEnabled, setToggle) end
    end)
    if toggleEnabled and callback then callback(true, setToggle) end
    return toggleFrame
end

local function createTabButton(parent, name, iconId, callback)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, 0, 0, 28)
    buttonFrame.BackgroundColor3 = C.black
    buttonFrame.BackgroundTransparency = 0.20
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = parent
    Instance.new("UICorner", buttonFrame).CornerRadius = UDim.new(0, 6)
    local buttonLabel = Instance.new("TextLabel")
    buttonLabel.Size = UDim2.new(0, 160, 1, 0)
    buttonLabel.Position = UDim2.new(0, 8, 0, 0)
    buttonLabel.BackgroundTransparency = 1
    buttonLabel.Text = name
    buttonLabel.TextColor3 = C.white
    buttonLabel.Font = Enum.Font.Gotham
    buttonLabel.TextSize = 10
    buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
    buttonLabel.TextYAlignment = Enum.TextYAlignment.Center
    buttonLabel.Parent = buttonFrame
    local iconDecor = Instance.new("ImageLabel")
    iconDecor.Size = UDim2.new(0, 16, 0, 16)
    iconDecor.Position = UDim2.new(1, -24, 0.5, -8)
    iconDecor.BackgroundTransparency = 1
    iconDecor.Image = iconId or "rbxassetid://97462463002118"
    iconDecor.ImageColor3 = C.primary
    iconDecor.Parent = buttonFrame
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = buttonFrame
    clickButton.MouseEnter:Connect(function()
        buttonFrame.BackgroundTransparency = 0.1
        iconDecor.ImageColor3 = C.accent
    end)
    clickButton.MouseLeave:Connect(function()
        buttonFrame.BackgroundTransparency = 0.20
        iconDecor.ImageColor3 = C.primary
    end)
    clickButton.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return buttonFrame
end

local function createTabKeybind(parent, name, configKey, default, onChanged)
    if Config.Keybinds[configKey] == nil then
        Config.Keybinds[configKey] = default
        SaveConfig()
    end
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, 0, 0, 28)
    rowFrame.BackgroundColor3 = C.black
    rowFrame.BackgroundTransparency = 0.20
    rowFrame.BorderSizePixel = 0
    rowFrame.Parent = parent
    Instance.new("UICorner", rowFrame).CornerRadius = UDim.new(0, 6)
    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(0, 130, 1, 0)
    rowLabel.Position = UDim2.new(0, 8, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = name
    rowLabel.TextColor3 = C.white
    rowLabel.Font = Enum.Font.Gotham
    rowLabel.TextSize = 10
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextYAlignment = Enum.TextYAlignment.Center
    rowLabel.Parent = rowFrame
    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 45, 0, 18)
    keyBtn.Position = UDim2.new(1, -50, 0.5, -9)
    keyBtn.BackgroundColor3 = C.darkPurple
    keyBtn.BackgroundTransparency = 0
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = Config.Keybinds[configKey]
    keyBtn.TextColor3 = C.accent
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 9
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = rowFrame
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 5)
    local keyBtnStroke = Instance.new("UIStroke")
    keyBtnStroke.Thickness = 1
    keyBtnStroke.Color = C.accent
    keyBtnStroke.Transparency = 0.5
    keyBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    keyBtnStroke.Parent = keyBtn
    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "..."
        keyBtn.TextColor3 = C.primary
        keyBtnStroke.Transparency = 0
        local con
        con = S.UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Config.Keybinds[configKey] = inp.KeyCode.Name
                keyBtn.Text = inp.KeyCode.Name
                keyBtn.TextColor3 = C.accent
                keyBtnStroke.Transparency = 0.5
                SaveConfig()
                con:Disconnect()
                if onChanged then onChanged(inp.KeyCode) end
            end
        end)
    end)
    return rowFrame
end

local function createAnimalCard(parent, animalData, rank)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "AnimalCard"
    cardFrame.Size = UDim2.new(1, 0, 0, 95)
    cardFrame.BackgroundColor3 = C.bg
    cardFrame.BackgroundTransparency = 0.15
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = parent

    Instance.new("UICorner", cardFrame).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Thickness = 1
    cardStroke.Color = C.coolPurple
    cardStroke.Transparency = 0.7
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Parent = cardFrame

    local vpFrame = Instance.new("ViewportFrame")
    vpFrame.Size = UDim2.new(0, 42, 0, 42)
    vpFrame.Position = UDim2.new(0, 6, 0, 6)
    vpFrame.BackgroundColor3 = C.darkPurple
    vpFrame.BorderSizePixel = 0
    vpFrame.Ambient = Color3.fromRGB(180, 180, 180)
    vpFrame.LightDirection = Vector3.new(-1, -2, -1)
    vpFrame.Parent = cardFrame
    Instance.new("UICorner", vpFrame).CornerRadius = UDim.new(0, 6)

    local vpStroke = Instance.new("UIStroke")
    vpStroke.Thickness = 1
    vpStroke.Color = C.dividerGrey
    vpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    vpStroke.Parent = vpFrame

    pcall(function()
        local modelsFolder = S.ReplicatedStorage:FindFirstChild("Models")
        if not modelsFolder then return end
        local animalModels = modelsFolder:FindFirstChild("Animals")
        if not animalModels then return end
        local animalModel = animalModels:FindFirstChild(animalData.modelName)
        if not animalModel then return end
        local cloned = animalModel:Clone()
        cloned.Parent = vpFrame
        for _, part in ipairs(cloned:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = false; part.CanCollide = false end
        end
        local rootPart = cloned.PrimaryPart or cloned:FindFirstChildWhichIsA("BasePart")
        if rootPart then rootPart.Anchored = true end
        local cf, _ = cloned:GetBoundingBox()
        cloned:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(125), 0))
        local cf2, size2 = cloned:GetBoundingBox()
        local distance = math.max(size2.X, size2.Y, size2.Z) * 1.5
        local vpCamera = Instance.new("Camera")
        vpCamera.FieldOfView = 50
        vpCamera.CFrame = CFrame.new(cf2.Position + Vector3.new(0, size2.Y * 0.1, distance), cf2.Position)
        vpCamera.Parent = vpFrame
        vpFrame.CurrentCamera = vpCamera
    end)

    local strokeColor, iconId
    if rank == 1 then strokeColor = Color3.fromRGB(255, 215, 0); iconId = "rbxassetid://75275446742454"
    elseif rank == 2 then strokeColor = Color3.fromRGB(192, 192, 192); iconId = "rbxassetid://105421235220109"
    elseif rank == 3 then strokeColor = Color3.fromRGB(205, 127, 50); iconId = "rbxassetid://104204204434785"
    else strokeColor = Color3.fromRGB(100, 100, 120); iconId = nil end

    local rankBadge = Instance.new("Frame")
    rankBadge.Size = UDim2.new(0, 32, 0, 16)
    rankBadge.Position = UDim2.new(0, 6, 0, 68)
    rankBadge.BackgroundTransparency = 1
    rankBadge.BorderSizePixel = 0
    rankBadge.Parent = cardFrame
    Instance.new("UICorner", rankBadge).CornerRadius = UDim.new(0.11, 0)

    local badgeStroke = Instance.new("UIStroke")
    badgeStroke.Thickness = 1.5
    badgeStroke.Color = strokeColor
    badgeStroke.Transparency = 0
    badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    badgeStroke.Parent = rankBadge

    if iconId then
        local iconImage = Instance.new("ImageLabel")
        iconImage.Size = UDim2.new(0, 9, 0, 9)
        iconImage.Position = UDim2.new(0, 2, 0.5, -4)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = iconId
        iconImage.Parent = rankBadge
    end

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Size = UDim2.new(1, iconId and -11 or 0, 1, 0)
    rankLabel.Position = UDim2.new(0, iconId and 11 or 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = "#" .. tostring(rank)
    rankLabel.TextColor3 = strokeColor
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextSize = 9
    rankLabel.TextXAlignment = Enum.TextXAlignment.Center
    rankLabel.TextYAlignment = Enum.TextYAlignment.Center
    rankLabel.Parent = rankBadge

    local isFav = isFavorite(animalData.name)

    local favBadge = Instance.new("Frame")
    favBadge.Size = UDim2.new(0, 55, 0, 16)
    favBadge.Position = UDim2.new(0, 42, 0, 68)
    favBadge.BackgroundTransparency = 1
    favBadge.BorderSizePixel = 0
    favBadge.Visible = isFav
    favBadge.Parent = cardFrame
    Instance.new("UICorner", favBadge).CornerRadius = UDim.new(0.11, 0)

    local favBadgeStroke = Instance.new("UIStroke")
    favBadgeStroke.Thickness = 1.5
    favBadgeStroke.Color = C.yellow
    favBadgeStroke.Transparency = 0
    favBadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    favBadgeStroke.Parent = favBadge

    local favBadgeIcon = Instance.new("ImageLabel")
    favBadgeIcon.Size = UDim2.new(0, 9, 0, 9)
    favBadgeIcon.Position = UDim2.new(0, 3, 0.5, -4)
    favBadgeIcon.BackgroundTransparency = 1
    favBadgeIcon.Image = "rbxassetid://113366714224251"
    favBadgeIcon.Parent = favBadge

    local favBadgeLabel = Instance.new("TextLabel")
    favBadgeLabel.Size = UDim2.new(1, -13, 1, 0)
    favBadgeLabel.Position = UDim2.new(0, 13, 0, 0)
    favBadgeLabel.BackgroundTransparency = 1
    favBadgeLabel.Text = "Favorite"
    favBadgeLabel.TextColor3 = C.yellow
    favBadgeLabel.Font = Enum.Font.GothamBold
    favBadgeLabel.TextSize = 8
    favBadgeLabel.TextXAlignment = Enum.TextXAlignment.Center
    favBadgeLabel.TextYAlignment = Enum.TextYAlignment.Center
    favBadgeLabel.Parent = favBadge

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -130, 0, 16)
    nameLabel.Position = UDim2.new(0, 54, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = animalData.name
    nameLabel.TextColor3 = C.white
    nameLabel.Font = Enum.Font.MontserratBold
    nameLabel.TextSize = 10
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = cardFrame

    local mutationLabel = Instance.new("TextLabel")
    mutationLabel.Size = UDim2.new(1, -130, 0, 14)
    mutationLabel.Position = UDim2.new(0, 54, 0, 24)
    mutationLabel.BackgroundTransparency = 1
    mutationLabel.Text = animalData.mutation
    mutationLabel.TextColor3 = C.accent
    mutationLabel.Font = Enum.Font.GothamBold
    mutationLabel.TextSize = 9
    mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
    mutationLabel.TextYAlignment = Enum.TextYAlignment.Center
    mutationLabel.Parent = cardFrame

    local genLabel = Instance.new("TextLabel")
    genLabel.Size = UDim2.new(1, -130, 0, 14)
    genLabel.Position = UDim2.new(0, 54, 0, 38)
    genLabel.BackgroundTransparency = 1
    genLabel.Text = animalData.genText
    genLabel.TextColor3 = C.green
    genLabel.Font = Enum.Font.GothamBold
    genLabel.TextSize = 9
    genLabel.TextXAlignment = Enum.TextXAlignment.Left
    genLabel.TextYAlignment = Enum.TextYAlignment.Center
    genLabel.Parent = cardFrame

    local tpButton = Instance.new("TextButton")
    tpButton.Size = UDim2.new(0, 55, 0, 24)
    tpButton.Position = UDim2.new(1, -88, 0.5, -12)
    tpButton.BackgroundColor3 = C.darkPurple
    tpButton.BackgroundTransparency = 0.15
    tpButton.BorderSizePixel = 0
    tpButton.Text = "Teleport"
    tpButton.TextColor3 = C.accent
    tpButton.Font = Enum.Font.GothamBold
    tpButton.TextSize = 8
    tpButton.AutoButtonColor = false
    tpButton.Parent = cardFrame
    Instance.new("UICorner", tpButton).CornerRadius = UDim.new(0, 5)

    local tpStroke = Instance.new("UIStroke")
    tpStroke.Thickness = 1
    tpStroke.Color = C.accent
    tpStroke.Transparency = 0.5
    tpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tpStroke.Parent = tpButton

    tpButton.MouseEnter:Connect(function()
        tpButton.BackgroundColor3 = C.buttonPurple
        tpButton.BackgroundTransparency = 0
        tpButton.TextColor3 = C.white
        tpStroke.Transparency = 0
    end)
    tpButton.MouseLeave:Connect(function()
        tpButton.BackgroundColor3 = C.darkPurple
        tpButton.BackgroundTransparency = 0.15
        tpButton.TextColor3 = C.accent
        tpStroke.Transparency = 0.5
    end)
    tpButton.MouseButton1Click:Connect(function() end)

    local favButton = Instance.new("TextButton")
    favButton.Size = UDim2.new(0, 24, 0, 24)
    favButton.Position = UDim2.new(1, -30, 0.5, -12)
    favButton.BackgroundColor3 = isFav and C.yellow or C.darkPurple
    favButton.BackgroundTransparency = isFav and 0 or 0.15
    favButton.BorderSizePixel = 0
    favButton.Text = "★"
    favButton.TextColor3 = isFav and C.white or Color3.fromRGB(150, 150, 150)
    favButton.Font = Enum.Font.GothamBold
    favButton.TextSize = 13
    favButton.AutoButtonColor = false
    favButton.Parent = cardFrame
    Instance.new("UICorner", favButton).CornerRadius = UDim.new(0, 5)

    local favStroke = Instance.new("UIStroke")
    favStroke.Thickness = 1
    favStroke.Color = isFav and C.yellow or Color3.fromRGB(100, 80, 130)
    favStroke.Transparency = isFav and 0 or 0.5
    favStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    favStroke.Parent = favButton

    local isFavorited = isFav

    favButton.MouseEnter:Connect(function()
        if not isFavorited then
            favButton.TextColor3 = C.yellow
            favStroke.Color = C.yellow
            favStroke.Transparency = 0.3
        end
    end)
    favButton.MouseLeave:Connect(function()
        if not isFavorited then
            favButton.TextColor3 = Color3.fromRGB(150, 150, 150)
            favStroke.Color = Color3.fromRGB(100, 80, 130)
            favStroke.Transparency = 0.5
        end
    end)
    favButton.MouseButton1Click:Connect(function()
        isFavorited = not isFavorited
        if isFavorited then
            addFavorite(animalData.name)
            favButton.BackgroundColor3 = C.yellow
            favButton.BackgroundTransparency = 0
            favButton.TextColor3 = C.white
            favStroke.Color = C.yellow
            favStroke.Transparency = 0
            favBadge.Visible = true
        else
            removeFavorite(animalData.name)
            favButton.BackgroundColor3 = C.darkPurple
            favButton.BackgroundTransparency = 0.15
            favButton.TextColor3 = Color3.fromRGB(150, 150, 150)
            favStroke.Color = Color3.fromRGB(100, 80, 130)
            favStroke.Transparency = 0.5
            favBadge.Visible = false
        end
    end)

    return cardFrame
end

local instantCloneBtn = createButton("Instant Clone", 45, function() end)
local tpToBestBtn     = createButton("Tp to Best", 80, function() end)
local ragdollSelfBtn  = createButton("Ragdoll Self", 115, function() end)
local rejoinBtn       = createButton("Rejoin", 150, function()
    S.TeleportService:Teleport(game.PlaceId, player)
end)

local hopActive = false
local hopServerBtn = createToggle("Hop Server", 185, "HopServer", function(ns, set)
    set(ns)
    hopActive = ns
    if ns then
        task.spawn(function()
            while hopActive do
                local placeId = game.PlaceId
                local ok, result = pcall(function()
                    return S.HttpService:JSONDecode(
                        game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
                    )
                end)
                if ok and result and result.data then
                    local found = false
                    for _, server in ipairs(result.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            pcall(function()
                                S.TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                            end)
                            found = true; break
                        end
                    end
                    if not found then task.wait(3) end
                else
                    task.wait(3)
                end
            end
        end)
    end
end)

local settingsBtn = createToggle("Settings", 220, "Settings", function(ns, set)
    set(ns)
    menuFrame.Visible = ns
end)

task.wait(0.1)

local uiContent = tabContents["UI"]
if uiContent then
    createSectionHeader(uiContent, "UI Panel")
    createTabToggle(uiContent, "Lock Gui", "LockGui", function(ns, set)
        set(ns)
        creditFrame.Draggable = not ns
        mainFrame.Draggable = not ns
        menuFrame.Draggable = not ns
    end)
    createTabButton(uiContent, "Reset Position", "rbxassetid://97462463002118", function()
        Config.Positions.CreditFrame = DefaultConfig.Positions.CreditFrame
        Config.Positions.MainFrame   = DefaultConfig.Positions.MainFrame
        Config.Positions.MenuFrame   = DefaultConfig.Positions.MenuFrame
        SaveConfig()
        local cp = Config.Positions.CreditFrame
        creditFrame.Position = UDim2.new(cp.X, -170, cp.Y, -25)
        local mp = Config.Positions.MainFrame
        mainFrame.Position = UDim2.new(mp.X, -96.5, mp.Y, -142.5)
        local mep = Config.Positions.MenuFrame
        menuFrame.Position = UDim2.new(mep.X, -160, mep.Y, -170)
        showNotification({message = "GUI positions reset!", color = "Success", textColor = "White"})
    end)
end

local keybindsContent = tabContents["Keybinds"]
if keybindsContent then
    createSectionHeader(keybindsContent, "Keybinds")
    createTabKeybind(keybindsContent, "Instant Clone", "CloneKey", "V", nil)
    createTabKeybind(keybindsContent, "Carpet Speed", "CarpetSpeedKey", "Q", nil)
end

local priorityContent = tabContents["Priority"]
if priorityContent then
    createSectionHeader(priorityContent, "Priority List")
end

local brainrotContent = tabContents["Brainrot"]
local lastCacheCount = 0
local lastTopUIDs = {}

local function needsUpdate()
    if #allAnimalsCache ~= lastCacheCount then return true end
    for i = 1, math.min(10, #allAnimalsCache) do
        if allAnimalsCache[i].uid ~= lastTopUIDs[i] then return true end
    end
    return false
end

local function updateLastCache()
    lastCacheCount = #allAnimalsCache
    lastTopUIDs = {}
    for i = 1, math.min(10, #allAnimalsCache) do
        lastTopUIDs[i] = allAnimalsCache[i].uid
    end
end

if brainrotContent then
    local brainrotHeaderRow = Instance.new("Frame")
    brainrotHeaderRow.Name = "BrainrotHeaderRow"
    brainrotHeaderRow.Size = UDim2.new(1, 0, 0, 22)
    brainrotHeaderRow.BackgroundTransparency = 1
    brainrotHeaderRow.Parent = brainrotContent

    local brainrotSectionLabel = Instance.new("TextLabel")
    brainrotSectionLabel.Size = UDim2.new(0.6, 0, 1, 0)
    brainrotSectionLabel.Position = UDim2.new(0, 3, 0, 0)
    brainrotSectionLabel.BackgroundTransparency = 1
    brainrotSectionLabel.Text = "Brainrot List"
    brainrotSectionLabel.TextColor3 = C.accent
    brainrotSectionLabel.Font = Enum.Font.GothamBold
    brainrotSectionLabel.TextSize = 10
    brainrotSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    brainrotSectionLabel.TextYAlignment = Enum.TextYAlignment.Center
    brainrotSectionLabel.Parent = brainrotHeaderRow

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 52, 0, 17)
    refreshBtn.Position = UDim2.new(1, -55, 0.5, -8)
    refreshBtn.BackgroundColor3 = C.darkPurple
    refreshBtn.BackgroundTransparency = 0.2
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "Refresh"
    refreshBtn.TextColor3 = C.accent
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 8
    refreshBtn.AutoButtonColor = false
    refreshBtn.Parent = brainrotHeaderRow
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

    local refreshStroke = Instance.new("UIStroke")
    refreshStroke.Thickness = 1
    refreshStroke.Color = C.accent
    refreshStroke.Transparency = 0.5
    refreshStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    refreshStroke.Parent = refreshBtn

    local normalView = Instance.new("Frame")
    normalView.Name = "NormalView"
    normalView.Size = UDim2.new(1, 0, 0, 0)
    normalView.AutomaticSize = Enum.AutomaticSize.Y
    normalView.BackgroundTransparency = 1
    normalView.Parent = brainrotContent

    local normalLayout = Instance.new("UIListLayout")
    normalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    normalLayout.Padding = UDim.new(0, 5)
    normalLayout.Parent = normalView

    refreshBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(normalView:GetChildren()) do
            if child.Name == "AnimalCard" then child:Destroy() end
        end
        for rank, animalData in ipairs(allAnimalsCache) do
            createAnimalCard(normalView, animalData, rank)
        end
        showNotification({message = "Refreshed!", color = "Success", textColor = "White"})
    end)

    for rank, animalData in ipairs(allAnimalsCache) do
        createAnimalCard(normalView, animalData, rank)
    end

    updateLastCache()

    task.spawn(function()
        while true do
            task.wait(3)
            if needsUpdate() then
                for _, child in ipairs(normalView:GetChildren()) do
                    if child.Name == "AnimalCard" then child:Destroy() end
                end
                for rank, animalData in ipairs(allAnimalsCache) do
                    createAnimalCard(normalView, animalData, rank)
                end
                updateLastCache()
            end
        end
    end)
end

S.UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if S.UserInputService:GetFocusedTextBox() then return end
    if Config.Keybinds.CloneKey and Config.Keybinds.CloneKey ~= "" then
        if input.KeyCode == Enum.KeyCode[Config.Keybinds.CloneKey] then
        end
    end
end)

showNotification({message = "RenHub Private", subtext = "Welcome back!", color = "Violet", textColor = "White", subColor = "Violet"})
