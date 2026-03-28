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

local FileName = "ZynHubPrivate_v2.json"
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
    EspPlayers = false,
    LockGui = false,
    PlotBeam = false,
    EspTimer = false,
    EspBest = false,
    XrayBase = false,
    CarpetSpeed = false,
    CarpetTool = "Flying Carpet",
    Optimizer = false,
    AnimDisabler = false,
    KickAfterSteal = false,
    DesyncOnStart = false,
    InfJump = false,
    AntiLag = false,
    EspMine = false,
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
    Default = Color3.fromRGB(180, 180, 200),
    Failed  = Color3.fromRGB(220, 40,  40),
    Success = Color3.fromRGB(14, 154, 235),
    White   = Color3.fromRGB(255, 255, 255),
    Blue    = Color3.fromRGB(60,  160, 255),
    Violet  = Color3.fromRGB(70,  70,  180),
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
    local message  = opts.message  or ""
    local subtext  = opts.subtext  or nil
    local color    = opts.color and NotifColors[opts.color] or NotifColors.Default
    local textColor = opts.textColor and NotifColors[opts.textColor] or color  
    local subColor = opts.subColor and NotifColors[opts.subColor] or color    

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

    local notifGui = game:GetService("CoreGui"):FindFirstChild("ZynNotifGui")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "ZynNotifGui"
        notifGui.ResetOnSpawn = false
        notifGui.Parent = game:GetService("CoreGui")
    end

    local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
    local frameHeight = subtext and 57 or NOTIF_HEIGHT

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, frameHeight)
    notif.Position = UDim2.new(0, -260, 0, startYPos)
    notif.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    notif.BorderSizePixel = 0
    notif.Parent = notifGui

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 8)
    nCorner.Parent = notif

    local nStroke = Instance.new("UIStroke")
    nStroke.Thickness = 1
    nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    nStroke.Color = Color3.fromRGB(40, 40, 52)
    nStroke.Parent = notif

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(0, 4, 0, 4)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(100, 100, 115)
    closeButton.TextSize = 11
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notif

    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(220, 220, 235) end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Color3.fromRGB(100, 100, 115) end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -36, 0, subtext and 26 or frameHeight - 6)
    textLabel.Position = UDim2.new(0, 30, 0, subtext and 8 or 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = textColor  -- Custom text color
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
    "Strawberry Elephant",
    "Meowl",
    "Skibidi Toilet",
    "Headless Horseman",
    "Dragon Gingerini",
    "Dragon Cannelloni",
    "Ketupat Bros",
    "Hydra Dragon Cannelloni",
    "La Supreme Combinasion",
    "Love Love Bear",
    "Cerberus",
    "Capitano Moby",
    "Celestial Pegasus",
    "Fortunu and Cashuru",
    "Cloverat Clapat",
    "Griffin",
    "Cooki and Milki",
    "Rosey and Teddy",
    "Popcuru and Fizzuru",
    "Reinito Sleighito",
    "Fragrama and Chocrama",
    "Signore Carapace",
    "La Taco Combinasion"
}

local FAVORITES = {}

if Config.Favorites.Animals and #Config.Favorites.Animals > 0 then
    FAVORITES = Config.Favorites.Animals
else
    
    FAVORITES = {}
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
        if name:lower() == animalName:lower() then
            return true
        end
    end
    return false
end

local function addFavorite(animalName)
    if isFavorite(animalName) then
        return false
    end
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

local function getFavoriteByPriority(allAnimalsCache)
    for _, favName in ipairs(FAVORITES) do
        for _, animal in ipairs(allAnimalsCache) do
            if animal.name:lower() == favName:lower() then
                return animal
            end
        end
    end
    return nil
end

_G.isCloning = false

local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil
local eventConnections = {}

local allAnimalsCache = {}
local scannerConnections = {}
local plotChannels = {}
local lastAnimalData = {}
local highestAnimal = nil

local plotBeam = nil
local plotBeamAtt0 = nil
local plotBeamAtt1 = nil
local plotBeamConn = nil

local timerEspEnabled = false
local timerEspConnections = {}

local fpsBoostEnabled = false
local optimizerThreads = {}
local optimizerConnections = {}
local originalSettings = {}

local animDisablerConnections = {}

local brainrotESPEnabled = false
local brainrotBillboards = {}
local tracerBeam = nil
local tracerAtt0 = nil
local tracerAtt1 = nil

local xrayBaseEnabled = false
local invisibleWallsLoaded = false
local originalTransparency = {}
local xrayBaseConnection = nil

local carpetSpeedEnabled = false
local carpetSpeedConn = nil

local kickAfterStealActive = false

local infiniteJumpEnabled = false
local jumpRequestConnection = nil

local antiLagRunning = false
local antiLagConnections = {}
local cleanedCharacters = {}

local subspaceMineESPData = {}
local subspaceMineESPRunning = false

local function isMyBaseAnimal(animalData)
    if not animalData or not animalData.plot then return false end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return false end

    local channel = S.Synchronizer:Get(plot.Name)
    if channel then
        local owner = channel:Get("Owner")
        if owner then
            if typeof(owner) == "Instance" and owner:IsA("Player") then
                return owner.UserId == player.UserId
            elseif typeof(owner) == "table" and owner.UserId then
                return owner.UserId == player.UserId
            elseif typeof(owner) == "Instance" then
                return owner == player
            end
        end
    end

    return false
end

local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local yourBase = plotSign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return true end
    end
    return false
end

local function getEquippedItem(character)
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then return child.Name end
    end
    return "None"
end

local function removeESP(targetPlayer)
    local rec = espObjects[targetPlayer]
    if not rec then return end
    if rec.highlight then rec.highlight:Destroy() end
    if rec.billboard then rec.billboard:Destroy() end
    espObjects[targetPlayer] = nil
end

local function createESP(targetPlayer)
    if targetPlayer == player then return end
    if not targetPlayer.Character then
        targetPlayer.CharacterAdded:Connect(function()
            if espPlayersEnabled then task.wait(1); createESP(targetPlayer) end
        end)
        return
    end

    local character = targetPlayer.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    removeESP(targetPlayer)

    local rec = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(59, 134, 255)
    highlight.OutlineColor = Color3.fromRGB(70, 70, 180)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    rec.highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPInfo"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    rec.billboard = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(103, 103, 245)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    rec.nameLabel = nameLabel

    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 18)
    itemLabel.Position = UDim2.new(0, 0, 0, 22)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item: None"
    itemLabel.TextColor3 = Color3.fromRGB(183, 50, 250)
    itemLabel.TextStrokeTransparency = 0.5
    itemLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextSize = 12
    itemLabel.Parent = billboard
    rec.itemLabel = itemLabel

    rec.character = character
    espObjects[targetPlayer] = rec

    local respawnConnection
    respawnConnection = targetPlayer.CharacterAdded:Connect(function()
        if espPlayersEnabled then
            task.wait(1)
            createESP(targetPlayer)
        else
            respawnConnection:Disconnect()
        end
    end)
    table.insert(eventConnections, respawnConnection)
end

local function updateESP()
    if not espPlayersEnabled then return end
    for targetPlayer, rec in pairs(espObjects) do
        if targetPlayer and targetPlayer.Parent and rec.character and rec.character.Parent then
            local rootPart = rec.character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local equippedItem = getEquippedItem(rec.character)
                rec.itemLabel.Text = "Item: " .. equippedItem
                rec.itemLabel.TextColor3 = Color3.fromRGB(183, 50, 250)
            else
                removeESP(targetPlayer)
            end
        else
            removeESP(targetPlayer)
        end
    end
end

local function enableESPPlayers()
    if espPlayersEnabled then return end
    espPlayersEnabled = true
    for _, targetPlayer in pairs(S.Players:GetPlayers()) do
        if targetPlayer ~= player then
            task.spawn(function() createESP(targetPlayer) end)
        end
    end
    table.insert(eventConnections, S.Players.PlayerAdded:Connect(function(targetPlayer)
        if espPlayersEnabled then
            task.wait(1)
            createESP(targetPlayer)
        end
    end))
    table.insert(eventConnections, S.Players.PlayerRemoving:Connect(removeESP))
    updateConnection = S.RunService.RenderStepped:Connect(updateESP)
end

local function disableESPPlayers()
    if not espPlayersEnabled then return end
    espPlayersEnabled = false
    if updateConnection then updateConnection:Disconnect(); updateConnection = nil end
    for _, conn in pairs(eventConnections) do if conn then conn:Disconnect() end end
    eventConnections = {}
    for targetPlayer in pairs(espObjects) do removeESP(targetPlayer) end
    espObjects = {}
end

local function instantClone()
    if _G.isCloning then return end
    _G.isCloning = true
    pcall(function()
        local backpack = player:WaitForChild("Backpack")
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local tool = backpack:FindFirstChild("Quantum Cloner") or char:FindFirstChild("Quantum Cloner")
        if not tool then _G.isCloning = false; return end
        if tool.Parent == backpack then
            humanoid:EquipTool(tool)
            task.wait(0.1)
        end
        tool:Activate()
        local clone = S.Workspace:WaitForChild(player.UserId .. "_Clone", 10)
        if clone then
            local teleportBtn = player.PlayerGui
                :WaitForChild("ToolsFrames")
                :WaitForChild("QuantumCloner")
                :WaitForChild("TeleportToClone")
            firesignal(teleportBtn.MouseButton1Up)
        end
    end)
    _G.isCloning = false
end

local function findMyPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        if isPlayerPlot(plot) then
            return plot
        end
    end
    return nil
end

local function createPlotBeam()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myPlot = findMyPlot()
    if not myPlot then return end

    local plotPart = myPlot:FindFirstChildWhichIsA("BasePart")
    if not plotPart then return end

    if plotBeam then pcall(function() plotBeam:Destroy() end) end
    if plotBeamAtt0 then pcall(function() plotBeamAtt0:Destroy() end) end
    if plotBeamAtt1 then pcall(function() plotBeamAtt1:Destroy() end) end

    plotBeamAtt0 = Instance.new("Attachment")
    plotBeamAtt0.Name = "PlotBeamAtt0"
    plotBeamAtt0.Position = Vector3.new(0, 0, 0)
    plotBeamAtt0.Parent = hrp

    plotBeamAtt1 = Instance.new("Attachment")
    plotBeamAtt1.Name = "PlotBeamAtt1"
    plotBeamAtt1.Position = Vector3.new(0, 5, 0)
    plotBeamAtt1.Parent = plotPart

    plotBeam = Instance.new("Beam")
    plotBeam.Name = "PlotBeam"
    plotBeam.Attachment0 = plotBeamAtt0
    plotBeam.Attachment1 = plotBeamAtt1
    plotBeam.FaceCamera = true
    plotBeam.LightEmission = 0
    plotBeam.LightInfluence = 1
    plotBeam.Color = ColorSequence.new(Color3.fromRGB(80, 150, 255))
    plotBeam.Transparency = NumberSequence.new(0)
    plotBeam.Width0 = 0.5
    plotBeam.Width1 = 0.5
    plotBeam.TextureMode = Enum.TextureMode.Wrap
    plotBeam.TextureSpeed = 0
    plotBeam.Parent = hrp
end

local function enablePlotBeam()
    createPlotBeam()

    local counter = 0
    plotBeamConn = S.RunService.Heartbeat:Connect(function()
        if not Config.PlotBeam then return end
        counter += 1
        if counter >= 30 then
            counter = 0
            if not plotBeam or not plotBeam.Parent then
                pcall(createPlotBeam)
            end
        end
    end)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Config.PlotBeam then
            pcall(createPlotBeam)
        end
    end)
end

local function disablePlotBeam()
    if plotBeamConn then plotBeamConn:Disconnect(); plotBeamConn = nil end
    if plotBeam then pcall(function() plotBeam:Destroy() end); plotBeam = nil end
    if plotBeamAtt0 then pcall(function() plotBeamAtt0:Destroy() end); plotBeamAtt0 = nil end
    if plotBeamAtt1 then pcall(function() plotBeamAtt1:Destroy() end); plotBeamAtt1 = nil end
end

if Config.PlotBeam then
    task.spawn(function()
        enablePlotBeam()
    end)
end

local function updateBillboard(mainPart, contentText, shouldShow, isUnlocked)
    local existing = mainPart:FindFirstChild("RemainingTimeGui")
    if shouldShow then
        if not existing then
            local gui = Instance.new("BillboardGui")
            gui.Name = "RemainingTimeGui"
            gui.Adornee = mainPart
            gui.Size = UDim2.new(0, 90, 0, 20)
            gui.StudsOffset = Vector3.new(0, 5, 0)
            gui.AlwaysOnTop = true
            gui.Parent = mainPart
            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            if isUnlocked then
                label.TextScaled = false
                label.TextSize = 14
                label.TextColor3 = Color3.fromRGB(53, 91, 242) -- C.blue2
            else
                label.TextScaled = true
                label.TextColor3 = Color3.fromRGB(2, 90, 222) -- timer color
            end
            label.TextStrokeTransparency = 0.2
            label.Font = Enum.Font.GothamBold
            label.Text = contentText
            label.Parent = gui
        else
            local label = existing:FindFirstChild("Text")
            if label then
                label.Text = contentText
                if isUnlocked then
                    label.TextScaled = false
                    label.TextSize = 14
                    label.TextColor3 = Color3.fromRGB(53, 91, 242) -- C.blue2
                else
                    label.TextScaled = true
                    label.TextColor3 = Color3.fromRGB(2, 90, 222) -- timer color
                end
            end
        end
    else
        if existing then existing:Destroy() end
    end
end

local function findLowestValidRemainingTime(purchases)
    local lowest = nil
    local lowestY = nil
    for _, purchase in pairs(purchases:GetChildren()) do
        local main = purchase:FindFirstChild("Main")
        local gui = main and main:FindFirstChild("BillboardGui")
        local remTime = gui and gui:FindFirstChild("RemainingTime")
        local locked = gui and gui:FindFirstChild("Locked")
        if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") then
            local y = main.Position.Y
            if not lowestY or y < lowestY then
                lowest = {remTime = remTime, locked = locked, main = main}
                lowestY = y
            end
        end
    end
    return lowest
end

local function scanAndConnect()
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if not purchases then continue end
        local selected = findLowestValidRemainingTime(purchases)
        for _, purchase in pairs(purchases:GetChildren()) do
            local main = purchase:FindFirstChild("Main")
            local gui = main and main:FindFirstChild("BillboardGui")
            local remTime = gui and gui:FindFirstChild("RemainingTime")
            local locked = gui and gui:FindFirstChild("Locked")
            if main and remTime and locked and remTime:IsA("TextLabel") and locked:IsA("GuiObject") then
                local isTarget = selected and remTime == selected.remTime
                local isUnlocked = not locked.Visible
                local displayText = isUnlocked and "Unlocked" or remTime.Text
                updateBillboard(main, displayText, isTarget, isUnlocked)
                local key = remTime:GetDebugId()
                if isTarget and not timerEspConnections[key] then
                    local function refresh()
                        local stillTarget = (findLowestValidRemainingTime(purchases) or {}).remTime == remTime
                        local unlocked = not locked.Visible
                        local text = unlocked and "Unlocked" or remTime.Text
                        updateBillboard(main, text, stillTarget, unlocked)
                    end
                    local conn1 = remTime:GetPropertyChangedSignal("Text"):Connect(refresh)
                    local conn2 = locked:GetPropertyChangedSignal("Visible"):Connect(refresh)
                    timerEspConnections[key] = {conn1, conn2}
                end
            end
        end
    end
end

local function toggleTimerESP(state)
    timerEspEnabled = state
    if state then
        task.spawn(function()
            while timerEspEnabled do
                pcall(scanAndConnect)
                task.wait(5)
            end
        end)
    else
        local plots = S.Workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in pairs(plots:GetChildren()) do
                local purchases = plot:FindFirstChild("Purchases")
                if purchases then
                    for _, purchase in pairs(purchases:GetChildren()) do
                        local main = purchase:FindFirstChild("Main")
                        if main then
                            local gui = main:FindFirstChild("RemainingTimeGui")
                            if gui then gui:Destroy() end
                        end
                    end
                end
            end
        end
        for _, connections in pairs(timerEspConnections) do
            for _, conn in ipairs(connections) do conn:Disconnect() end
        end
        timerEspConnections = {}
    end
end

if Config.EspTimer then
    task.spawn(function()
        toggleTimerESP(true)
    end)
end

local function storeOriginalSettings()
    pcall(function()
        originalSettings = {
            qualityLevel = settings().Rendering.QualityLevel,
            globalShadows = Lighting.GlobalShadows,
            brightness = Lighting.Brightness,
            fogEnd = Lighting.FogEnd,
            decoration = S.Workspace.Terrain.Decoration,
        }
    end)
end

local function nukeVisualEffects()
    pcall(function()
        for _, obj in ipairs(S.Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") then obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Trail") then obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow = false; obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
end

local function optimizeCharacter(char)
    if not char then return end
    task.spawn(function()
        task.wait(0.5)
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CastShadow = false; part.Material = Enum.Material.Plastic
                elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then part:Destroy()
                end
            end
        end)
    end)
end

local function toggleOptimizer(state)
    fpsBoostEnabled = state
    getgenv().OPTIMIZER_ACTIVE = state

    if state then
        storeOriginalSettings()

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Technology = Enum.Technology.Legacy
            S.Workspace.Terrain.Decoration = false
        end)

        table.insert(optimizerThreads, task.spawn(function()
            task.wait(1); nukeVisualEffects()
        end))

        table.insert(optimizerConnections, S.Workspace.DescendantAdded:Connect(function(obj)
            if not getgenv().OPTIMIZER_ACTIVE then return end
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow = false
                end
            end)
        end))

        for _, p in ipairs(S.Players:GetPlayers()) do
            if p.Character then optimizeCharacter(p.Character) end
            table.insert(optimizerConnections, p.CharacterAdded:Connect(function(char)
                if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end
            end))
        end

        pcall(function() setfpscap(999) end)
    else
        for _, t in ipairs(optimizerThreads) do pcall(function() task.cancel(t) end) end
        optimizerThreads = {}
        for _, c in ipairs(optimizerConnections) do pcall(function() c:Disconnect() end) end
        optimizerConnections = {}

        pcall(function()
            settings().Rendering.QualityLevel = originalSettings.qualityLevel or Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = originalSettings.globalShadows ~= false
            S.Workspace.Terrain.Decoration = originalSettings.decoration ~= false
        end)
    end
end

if Config.Optimizer then
    task.spawn(function()
        toggleOptimizer(true)
    end)
end

local function disableAnimations()
    pcall(function()
        for _, obj in ipairs(S.Workspace:GetDescendants()) do
            if obj:IsA("Animator") then
                pcall(function()
                    local model = obj:FindFirstAncestorOfClass("Model")
                    local isPlayer = model and S.Players:GetPlayerFromCharacter(model) ~= nil
                    if not isPlayer then
                        for _, track in pairs(obj:GetPlayingAnimationTracks()) do
                            track:Stop(0)
                        end
                        obj.AnimationPlayed:Connect(function(track)
                            track:Stop(0)
                        end)
                    end
                end)
            end
        end
    end)
end

local function enableAnimDisabler()
    disableAnimations()

    table.insert(animDisablerConnections, S.Workspace.DescendantAdded:Connect(function(obj)
        if not Config.AnimDisabler then return end
        if obj:IsA("Animator") then
            pcall(function()
                local model = obj:FindFirstAncestorOfClass("Model")
                local isPlayer = model and S.Players:GetPlayerFromCharacter(model) ~= nil
                if not isPlayer then
                    for _, track in pairs(obj:GetPlayingAnimationTracks()) do
                        track:Stop(0)
                    end
                    obj.AnimationPlayed:Connect(function(track)
                        track:Stop(0)
                    end)
                end
            end)
        end
    end))
end

local function disableAnimDisabler()
    for _, c in ipairs(animDisablerConnections) do
        pcall(function() c:Disconnect() end)
    end
    animDisablerConnections = {}
end

if Config.AnimDisabler then
    task.spawn(function()
        enableAnimDisabler()
    end)
end

local MUT_COLORS = {
    Cursed      = Color3.fromRGB(255, 50, 50),
    Gold        = Color3.fromRGB(255, 215, 0),
    Diamond     = Color3.fromRGB(0, 255, 255),
    YinYang     = Color3.fromRGB(220, 220, 220),
    Rainbow     = Color3.fromRGB(255, 100, 200),
    Lava        = Color3.fromRGB(255, 100, 20),
    Candy       = Color3.fromRGB(255, 105, 180),
    Bloodrot    = Color3.fromRGB(139, 0, 0),
    Radioactive = Color3.fromRGB(0, 255, 0),
    Divine      = Color3.fromRGB(255, 255, 255),
}

local HOLY_LIST = {
    "Strawberry Elephant",
    "Meowl",
    "Skibidi Toilet",
    "Headless Horseman",
}

local function getBadgeText(data)
    if data.isDuelBase then return "[DUEL]", Color3.fromRGB(255, 50, 50) end
    for _, name in ipairs(HOLY_LIST) do
        if data.name and data.name:lower() == name:lower() then
            return "[HOLY SHIT]", Color3.fromRGB(255, 215, 0)
        end
    end
    if isFavorite(data.name) then return "[Favorites]", Color3.fromRGB(241, 196, 15) end
    return nil, nil
end

local function createBrainrotBillboard(data)
    local hasMut = data.mutation and data.mutation ~= "None"
    local mutColor = hasMut and (MUT_COLORS[data.mutation] or Color3.fromRGB(200, 100, 255)) or Color3.fromRGB(54, 52, 207)

    local bb = Instance.new("BillboardGui")
    bb.Name = "BrainrotESP_" .. data.uid
    bb.Size = UDim2.new(0, 160, 0, 50)
    bb.StudsOffset = Vector3.new(0, 1.8, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 3000

    local container = Instance.new("Frame", bb)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    container.BackgroundTransparency = 0.5
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke", container)
    stroke.Color = mutColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    local divider = Instance.new("Frame", container)
    divider.Name = "LeftDivider"
    divider.Size = UDim2.new(0, 2, 1, -6)
    divider.Position = UDim2.new(0, 0, 0, 3)
    divider.BackgroundColor3 = mutColor
    divider.BorderSizePixel = 0
    Instance.new("UICorner", divider).CornerRadius = UDim.new(1, 0)

    local badgeText, badgeColor = getBadgeText(data)
    if badgeText then
        local badge = Instance.new("TextLabel", container)
        badge.Size = UDim2.new(0.5, -3, 0, 12)
        badge.Position = UDim2.new(0.5, 0, 0, 2)
        badge.BackgroundTransparency = 1
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 9
        badge.TextColor3 = badgeColor
        badge.TextStrokeTransparency = 0
        badge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        badge.Text = badgeText
        badge.TextXAlignment = Enum.TextXAlignment.Right
        badge.ZIndex = 2
    end

    if hasMut then
        local mutationLabel = Instance.new("TextLabel", container)
        mutationLabel.Size = UDim2.new(1, -6, 0, 14)
        mutationLabel.Position = UDim2.new(0, 7, 0, 2)
        mutationLabel.BackgroundTransparency = 1
        mutationLabel.Font = Enum.Font.GothamBold
        mutationLabel.TextSize = 10
        mutationLabel.TextColor3 = mutColor
        mutationLabel.TextStrokeTransparency = 0
        mutationLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        mutationLabel.Text = data.mutation
        mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    local nameLabel = Instance.new("TextLabel", container)
    nameLabel.Size = UDim2.new(1, -6, 0, 16)
    nameLabel.Position = UDim2.new(0, 7, 0, hasMut and 16 or 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.fromRGB(22, 105, 240)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = data.name or "???"
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local genLabel = Instance.new("TextLabel", container)
    genLabel.Size = UDim2.new(1, -6, 0, 14)
    genLabel.Position = UDim2.new(0, 7, 0, hasMut and 32 or 20)
    genLabel.BackgroundTransparency = 1
    genLabel.Font = Enum.Font.GothamBold
    genLabel.TextSize = 10
    genLabel.TextColor3 = Color3.fromRGB(0, 186, 31)
    genLabel.TextStrokeTransparency = 0
    genLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    genLabel.Text = data.genText or ""
    genLabel.TextXAlignment = Enum.TextXAlignment.Left

    return bb
end

local function findAdornee(animalData)
    if not animalData then return nil end
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(animalData.plot)
    if not plot then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return nil end
    local podium = podiums:FindFirstChild(animalData.slot)
    if not podium then return nil end
    local base = podium:FindFirstChild("Base")
    if not base then return nil end
    local spawn = base:FindFirstChild("Spawn")
    if spawn then return spawn end
    return base:FindFirstChildWhichIsA("BasePart") or base
end

local function updateTracer(highestAdornee)
    if not brainrotESPEnabled or not highestAdornee then
        if tracerBeam then tracerBeam:Destroy(); tracerBeam = nil end
        if tracerAtt0 then tracerAtt0:Destroy(); tracerAtt0 = nil end
        if tracerAtt1 then tracerAtt1:Destroy(); tracerAtt1 = nil end
        return
    end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not tracerAtt0 or tracerAtt0.Parent ~= hrp then
        if tracerAtt0 then tracerAtt0:Destroy() end
        tracerAtt0 = Instance.new("Attachment", hrp)
    end

    if not tracerAtt1 or tracerAtt1.Parent ~= highestAdornee then
        if tracerAtt1 then tracerAtt1:Destroy() end
        tracerAtt1 = Instance.new("Attachment", highestAdornee)
    end

    if not tracerBeam then
        tracerBeam = Instance.new("Beam", S.Workspace)
        tracerBeam.FaceCamera = true
        tracerBeam.Width0 = 0.5
        tracerBeam.Width1 = 0.5
        tracerBeam.LightEmission = 0        
        tracerBeam.LightInfluence = 1       
        tracerBeam.Transparency = NumberSequence.new(0)
        tracerBeam.TextureMode = Enum.TextureMode.Static
    end

    tracerBeam.Attachment0 = tracerAtt0
    tracerBeam.Attachment1 = tracerAtt1
    tracerBeam.Enabled = true

    local highestAnimalData = allAnimalsCache[1]
    local hasMut = highestAnimalData and highestAnimalData.mutation and highestAnimalData.mutation ~= "None"
    local tracerColor = hasMut and (MUT_COLORS[highestAnimalData.mutation] or Color3.fromRGB(54, 52, 207)) or Color3.fromRGB(54, 52, 207)
    tracerBeam.Color = ColorSequence.new(tracerColor)
end

local function refreshBrainrotESP()
    if not brainrotESPEnabled then
        updateTracer(nil)
        return
    end
    if not allAnimalsCache or #allAnimalsCache == 0 then return end

    local activeUIDs = {}
    local highestUID = allAnimalsCache[1] and allAnimalsCache[1].uid or nil
    local highestAdornee = nil

    for _, animalData in ipairs(allAnimalsCache) do
        local shouldShow = false

        if animalData.uid == highestUID then
            shouldShow = true
        end
        if animalData.genValue >= 50000000 then
            shouldShow = true
        end
        if isFavorite(animalData.name) then
            shouldShow = true
        end

        if shouldShow then
            activeUIDs[animalData.uid] = true
            if not brainrotBillboards[animalData.uid] then
                local adornee = findAdornee(animalData)
                if adornee then
                    local bb = createBrainrotBillboard(animalData)
                    bb.Adornee = adornee
                    bb.Parent = adornee
                    brainrotBillboards[animalData.uid] = bb

                    if animalData.uid == highestUID then
                        highestAdornee = adornee
                    end
                end
            else
                if animalData.uid == highestUID then
                    local bb = brainrotBillboards[animalData.uid]
                    highestAdornee = bb and bb.Adornee or nil
                end
            end
        end
    end

    for uid, bb in pairs(brainrotBillboards) do
        if not activeUIDs[uid] then
            if bb and bb.Parent then bb:Destroy() end
            brainrotBillboards[uid] = nil
        end
    end

    updateTracer(highestAdornee)
end

local function clearBrainrotESP()
    for _, bb in pairs(brainrotBillboards) do
        if bb and bb.Parent then bb:Destroy() end
    end
    brainrotBillboards = {}
end

local function enableBrainrotESP()
    brainrotESPEnabled = true
    task.spawn(function()
        while brainrotESPEnabled do
            pcall(refreshBrainrotESP)
            task.wait(0.3)
        end
    end)
end

local function disableBrainrotESP()
    brainrotESPEnabled = false
    clearBrainrotESP()
    updateTracer(nil)
end

if Config.EspBest then
    task.spawn(function()
        enableBrainrotESP()
    end)
end

local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    local parent = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or parent:find("base")
end

local function tryApplyInvisibleWalls()
    if not xrayBaseEnabled or invisibleWallsLoaded then return end
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots or #plots:GetChildren() == 0 then return end
    for _, plot in pairs(plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and isBaseWall(obj) then
                if not originalTransparency[obj] then
                    originalTransparency[obj] = obj.LocalTransparencyModifier
                    obj.LocalTransparencyModifier = 0.85
                end
            end
        end
    end
    invisibleWallsLoaded = true
end

local function enableXrayBase()
    if xrayBaseEnabled then return end
    xrayBaseEnabled = true
    invisibleWallsLoaded = false
    tryApplyInvisibleWalls()
    xrayBaseConnection = S.Workspace.DescendantAdded:Connect(function(obj)
        if not xrayBaseEnabled then return end
        task.wait(0.1)
        if isBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
            if not originalTransparency[obj] then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
end

local function disableXrayBase()
    if not xrayBaseEnabled then return end
    xrayBaseEnabled = false
    invisibleWallsLoaded = false
    if xrayBaseConnection then xrayBaseConnection:Disconnect(); xrayBaseConnection = nil end
    for obj, value in pairs(originalTransparency) do
        if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = value end) end
    end
    originalTransparency = {}
end

if Config.XrayBase then
    task.spawn(function() 
        enableXrayBase() 
    end)
end

local function enableCarpetSpeed()
    if carpetSpeedConn then carpetSpeedConn:Disconnect(); carpetSpeedConn = nil end
    carpetSpeedConn = S.RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local toolName = Config.CarpetTool or "Flying Carpet"
        local hasTool = char:FindFirstChild(toolName)

        if not hasTool then
            local tb = player.Backpack:FindFirstChild(toolName)
            if tb then hum:EquipTool(tb) end
        end

        if char:FindFirstChild(toolName) then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(md.X * 140, hrp.AssemblyLinearVelocity.Y, md.Z * 140)
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)
end

local function disableCarpetSpeed()
    if carpetSpeedConn then carpetSpeedConn:Disconnect(); carpetSpeedConn = nil end
end

local function toggleCarpetSpeed()
    carpetSpeedEnabled = not carpetSpeedEnabled
    if carpetSpeedEnabled then enableCarpetSpeed() else disableCarpetSpeed() end
end

local function enableKickAfterSteal()
    if kickAfterStealActive then return end
    kickAfterStealActive = true
    task.spawn(function()
        while kickAfterStealActive do
            task.wait(0.5)
            for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
                if txt and string.find(txt, "You stole") then
                    player:Kick("\nZynHub Private")
                    return
                end
            end
        end
    end)
end

local function disableKickAfterSteal()
    kickAfterStealActive = false
end

if Config.KickAfterSteal then
    task.spawn(function()
        enableKickAfterSteal()
    end)
end

local function runDesync()
    pcall(function()
        raknet.desync(true)
    end)
    showNotification({
        message = "Desync Running",
        color = "Success",
        textColor = "White"
    })
end

if Config.DesyncOnStart then
    task.spawn(function()
        runDesync()
    end)
end

local function doJump()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if hum and hum.Health > 0 and rootPart then
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 50, rootPart.Velocity.Z)
    end
end

local function setupJumpRequest()
    if jumpRequestConnection then
        jumpRequestConnection:Disconnect()
        jumpRequestConnection = nil
    end
    jumpRequestConnection = S.UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled then doJump() end
    end)
end

local function initializeJumpForCharacter(char)
    char:WaitForChild("Humanoid")
    setupJumpRequest()
    char.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then setupJumpRequest() end
    end)
end

local function toggleInfJump(enabled)
    infiniteJumpEnabled = enabled
    if enabled then
        local char = player.Character
        if char then initializeJumpForCharacter(char) end
        player.CharacterAdded:Connect(function(char)
            if infiniteJumpEnabled then initializeJumpForCharacter(char) end
        end)
    else
        if jumpRequestConnection then
            jumpRequestConnection:Disconnect()
            jumpRequestConnection = nil
        end
    end
end

if Config.InfJump then
    task.spawn(function()
        toggleInfJump(true)
    end)
end

local function destroyAllEquippableItems(character)
    if not character then return end
    if not antiLagRunning then return end
    pcall(function()
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Hat") then child:Destroy() end
        end
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then child:Destroy() end
        end
        local bodyColors = character:FindFirstChildOfClass("BodyColors")
        if bodyColors then bodyColors:Destroy() end
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("CharacterMesh") then child:Destroy() end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child.ClassName == "LayeredClothing" or child.ClassName == "WrapLayer" then child:Destroy() end
        end
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                local mesh = child:FindFirstChildOfClass("SpecialMesh")
                if mesh then mesh:Destroy() end
            end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then child:Destroy() end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then child:Destroy() end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then child:Destroy() end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Highlight") then child:Destroy() end
        end
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                if not (child.Name == "face" and child.Parent and child.Parent.Name == "Head") then
                    child:Destroy()
                end
            end
        end
    end)
end

local function destroyBackpackTools(plr)
    if not antiLagRunning then return end
    pcall(function()
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, desc in ipairs(tool:GetDescendants()) do
                        if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or
                           desc:IsA("SpecialMesh") or desc:IsA("PointLight") or desc:IsA("SpotLight") or
                           desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                            desc:Destroy()
                        end
                    end
                end
            end
        end
    end)
end

local function destroyEquippedTools(character)
    if not character then return end
    if not antiLagRunning then return end
    pcall(function()
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, desc in ipairs(tool:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or
                       desc:IsA("SpecialMesh") or desc:IsA("PointLight") or desc:IsA("SpotLight") or
                       desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                        desc:Destroy()
                    end
                end
            end
        end
    end)
end

local function antiLagCleanCharacter(char)
    if not char then return end
    destroyAllEquippableItems(char)
    destroyEquippedTools(char)
    cleanedCharacters[char] = true
end

local function antiLagDisconnectAll()
    for _, conn in ipairs(antiLagConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    antiLagConnections = {}
    cleanedCharacters = {}
end

local function enableAntiLag()
    if antiLagRunning then return end
    antiLagRunning = true

    for _, plr in ipairs(S.Players:GetPlayers()) do
        if plr.Character then
            antiLagCleanCharacter(plr.Character)
            destroyBackpackTools(plr)
        end
        if plr.Backpack then
            table.insert(antiLagConnections, plr.Backpack.ChildAdded:Connect(function()
                if antiLagRunning then task.wait(0.1); destroyBackpackTools(plr) end
            end))
        end
    end

    table.insert(antiLagConnections, S.Players.PlayerAdded:Connect(function(plr)
        table.insert(antiLagConnections, plr.CharacterAdded:Connect(function(char)
            if not antiLagRunning then return end
            task.wait(0.5)
            antiLagCleanCharacter(char)
            destroyBackpackTools(plr)
            table.insert(antiLagConnections, char.ChildAdded:Connect(function(child)
                if not antiLagRunning then return end
                task.wait(0.1)
                if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Shirt") or
                   child:IsA("Pants") or child:IsA("ShirtGraphic") then
                    child:Destroy()
                elseif child:IsA("Tool") then
                    destroyEquippedTools(char)
                end
            end))
        end))
        if plr.Character then
            antiLagCleanCharacter(plr.Character)
            destroyBackpackTools(plr)
        end
        if plr.Backpack then
            table.insert(antiLagConnections, plr.Backpack.ChildAdded:Connect(function()
                if antiLagRunning then task.wait(0.1); destroyBackpackTools(plr) end
            end))
        end
    end))

    for _, plr in ipairs(S.Players:GetPlayers()) do
        table.insert(antiLagConnections, plr.CharacterAdded:Connect(function(char)
            if antiLagRunning then
                task.wait(0.5)
                antiLagCleanCharacter(char)
                destroyBackpackTools(plr)
                table.insert(antiLagConnections, char.ChildAdded:Connect(function(child)
                    if not antiLagRunning then return end
                    task.wait(0.1)
                    if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Shirt") or
                       child:IsA("Pants") or child:IsA("ShirtGraphic") then
                        child:Destroy()
                    elseif child:IsA("Tool") then
                        destroyEquippedTools(char)
                    end
                end))
            end
        end))
    end

    task.spawn(function()
        while antiLagRunning do
            task.wait(3)
            for _, plr in ipairs(S.Players:GetPlayers()) do
                if plr.Character and not cleanedCharacters[plr.Character] then
                    antiLagCleanCharacter(plr.Character)
                    destroyBackpackTools(plr)
                end
            end
        end
    end)
end

local function disableAntiLag()
    if not antiLagRunning then return end
    antiLagRunning = false
    antiLagDisconnectAll()
end

if Config.AntiLag then
    task.spawn(function()
        enableAntiLag()
    end)
end

local function createMineESP(mine)
    local ownerName = mine.Name:match("SubspaceTripmine(.+)") or "Unknown"
    local ownerPlayer = S.Players:FindFirstChild(ownerName)
    local displayName = ownerPlayer and ownerPlayer.DisplayName or ownerName

    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Name = "ESP_Hitbox"
    selectionBox.Adornee = mine
    selectionBox.Color3 = Color3.fromRGB(167, 142, 255)
    selectionBox.LineThickness = 0.05
    selectionBox.Parent = mine

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Label"
    billboard.Adornee = mine
    billboard.Size = UDim2.new(0, 250, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent = mine

    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = displayName .. "'s Subspace Mine"
    textLabel.TextColor3 = Color3.fromRGB(167, 142, 255)
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16

    return { selectionBox = selectionBox, billboard = billboard, mine = mine }
end

local function refreshSubspaceMineESP()
    local toolsFolder = S.Workspace:FindFirstChild("ToolsAdds")
    if not toolsFolder then return end

    local currentMines = {}
    for _, obj in pairs(toolsFolder:GetChildren()) do
        if obj.Name:match("^SubspaceTripmine") and obj:IsA("BasePart") then
            currentMines[obj] = true
            if not subspaceMineESPData[obj] then
                subspaceMineESPData[obj] = createMineESP(obj)
            end
        end
    end

    for mineObj, data in pairs(subspaceMineESPData) do
        if not currentMines[mineObj] or not mineObj.Parent then
            if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
            if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
            subspaceMineESPData[mineObj] = nil
        end
    end
end

local function enableSubspaceMineESP()
    if subspaceMineESPRunning then return end
    subspaceMineESPRunning = true
    task.spawn(function()
        while subspaceMineESPRunning do
            pcall(refreshSubspaceMineESP)
            task.wait(0.5)
        end
    end)
end

local function disableSubspaceMineESP()
    subspaceMineESPRunning = false
    for _, data in pairs(subspaceMineESPData) do
        if data.selectionBox and data.selectionBox.Parent then data.selectionBox:Destroy() end
        if data.billboard and data.billboard.Parent then data.billboard:Destroy() end
    end
    subspaceMineESPData = {}
end

if Config.EspMine then
    task.spawn(function()
        enableSubspaceMineESP()
    end)
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
            if allAnimalsCache[i].plot == plot.Name then
                table.remove(allAnimalsCache, i)
            end
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

        table.sort(allAnimalsCache, function(a, b)
            return a.genValue > b.genValue
        end)
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

    local newPlotConnection = plots.ChildAdded:Connect(function(plot)
        task.wait(0.5)
        setupPlotListener(plot)
    end)
    table.insert(scannerConnections, newPlotConnection)

    local removedPlotConnection = plots.ChildRemoved:Connect(function(plot)
        plotChannels[plot.Name] = nil
        lastAnimalData[plot.Name] = nil
        for i = #allAnimalsCache, 1, -1 do
            if allAnimalsCache[i].plot == plot.Name then
                table.remove(allAnimalsCache, i)
            end
        end
        highestAnimal = allAnimalsCache[1]
    end)
    table.insert(scannerConnections, removedPlotConnection)
end

local function cleanupScanner()
    for _, connection in ipairs(scannerConnections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    scannerConnections = {}
    plotChannels = {}
    lastAnimalData = {}
    allAnimalsCache = {}
    highestAnimal = nil
end

S.Players.PlayerRemoving:Connect(function(leavingPlayer)
    for i = #allAnimalsCache, 1, -1 do
        if allAnimalsCache[i].owner == leavingPlayer.Name then
            table.remove(allAnimalsCache, i)
        end
    end
    highestAnimal = allAnimalsCache[1]
end)

initializePlotScanner()

local function setupDuelListener(p)
    p:GetAttributeChangedSignal("__duels_block_steal"):Connect(function()
        local isDuel = p:GetAttribute("__duels_block_steal") == true
        for _, animal in ipairs(allAnimalsCache) do
            if animal.owner == p.Name then
                animal.isDuelBase = isDuel
            end
        end
    end)
end

for _, p in ipairs(S.Players:GetPlayers()) do
    setupDuelListener(p)
end

S.Players.PlayerAdded:Connect(function(p)
    setupDuelListener(p)
end)

local C = {
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),
    blue1 = Color3.fromRGB(2, 142, 217),
    blue2 = Color3.fromRGB(53, 91, 242),
    buttonBlue = Color3.fromRGB(80, 150, 255),
    darkGrey = Color3.fromRGB(22, 22, 41),
    toggleOn = Color3.fromRGB(20, 23, 204),
    subtitleGrey = Color3.fromRGB(150, 160, 180),
    dividerGrey = Color3.fromRGB(60, 60, 70),
    decorBlue = Color3.fromRGB(100, 180, 255),
    tabActive = Color3.fromRGB(80, 150, 255),
    tabInactive = Color3.fromRGB(100, 100, 120),
    green = Color3.fromRGB(46, 204, 113),
    yellow = Color3.fromRGB(241, 196, 15),
    red = Color3.fromRGB(231, 76, 60),
    coolBlue = Color3.fromRGB(5, 52, 153),
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
screenGui.Name = "ZYNPRIVATE"
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
creditFrame.BackgroundColor3 = C.black
creditFrame.BackgroundTransparency = 0.03
creditFrame.BorderSizePixel = 0
creditFrame.Active = true
creditFrame.Draggable = true
creditFrame.Parent = screenGui
trackPosition(creditFrame, "CreditFrame")

local creditFrameCorner = Instance.new("UICorner")
creditFrameCorner.CornerRadius = UDim.new(0, 9)
creditFrameCorner.Parent = creditFrame

local logoFrame = Instance.new("Frame")
logoFrame.Name = "LogoFrame"
logoFrame.Size = UDim2.new(0, 40, 0, 40)
logoFrame.Position = UDim2.new(0, 5, 0.5, -20)
logoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
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
creditTitle.Text = "ZYNHUB PRIVATE"
creditTitle.TextColor3 = C.white
creditTitle.Font = Enum.Font.MontserratBlack
creditTitle.TextSize = 14
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.TextYAlignment = Enum.TextYAlignment.Center
creditTitle.Parent = creditFrame
addTextGradient(creditTitle, C.blue1, C.blue2, 45)

local creditDivider = Instance.new("Frame")
creditDivider.Name = "Divider1"
creditDivider.Size = UDim2.new(0, 1, 0, 15)
creditDivider.Position = UDim2.new(0, 172, 0, 10)
creditDivider.BackgroundColor3 = C.dividerGrey
creditDivider.BorderSizePixel = 0
creditDivider.Parent = creditFrame

local discordLabel = Instance.new("TextLabel")
discordLabel.Name = "DiscordLabel"
discordLabel.Size = UDim2.new(0, 100, 0, 20)
discordLabel.Position = UDim2.new(0, 178, 0, 8)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = ".GG/ZYNHUB"
discordLabel.TextColor3 = C.white
discordLabel.Font = Enum.Font.MontserratBlack
discordLabel.TextSize = 14
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.TextYAlignment = Enum.TextYAlignment.Center
discordLabel.Parent = creditFrame
addTextGradient(discordLabel, C.blue1, C.blue2, 45)

local creditDivider2 = Instance.new("Frame")
creditDivider2.Name = "Divider2"
creditDivider2.Size = UDim2.new(0, 1, 0, 28)
creditDivider2.Position = UDim2.new(0, 268, 0, 9)
creditDivider2.BackgroundColor3 = C.dividerGrey
creditDivider2.BorderSizePixel = 0
creditDivider2.Parent = creditFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FpsLabel"
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
pingLabel.Name = "PingLabel"
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
        local fps = frames
        frames = 0
        last = now
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
creditsLabel.Name = "CreditsLabel"
creditsLabel.Size = UDim2.new(0, 340, 0, 15)
creditsLabel.Position = UDim2.new(0, 55, 1, -22)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "Made By @Zyn, @Ren"
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
mainFrame.BackgroundColor3 = C.black
mainFrame.BackgroundTransparency = 0.03
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
trackPosition(mainFrame, "MainFrame")

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 9)
frameCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 3)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ZYNHUB PRIVATE"
titleLabel.TextColor3 = C.white
titleLabel.Font = Enum.Font.MontserratBlack
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Parent = mainFrame
addTextGradient(titleLabel, C.blue1, C.blue2, 45)

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
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
menuFrame.Size = UDim2.new(0, 290, 0, 320)
local menuPos = Config.Positions.MenuFrame
menuFrame.Position = UDim2.new(menuPos.X, -145, menuPos.Y, -160) 
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
    ColorSequenceKeypoint.new(0.65, C.coolBlue),
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
menuTitleLabel.Name = "MenuTitleLabel"
menuTitleLabel.Size = UDim2.new(0, 180, 0, 25)
menuTitleLabel.Position = UDim2.new(0, 10, 0, 3)
menuTitleLabel.BackgroundTransparency = 1
menuTitleLabel.Text = "ZYNHUB PRIVATE"
menuTitleLabel.TextColor3 = C.white
menuTitleLabel.Font = Enum.Font.MontserratBlack
menuTitleLabel.TextSize = 12
menuTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
menuTitleLabel.TextYAlignment = Enum.TextYAlignment.Center
menuTitleLabel.Parent = menuFrame
addTextGradient(menuTitleLabel, C.blue1, C.blue2, 45)

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
versionBadgeStroke.Color = C.coolBlue
versionBadgeStroke.Transparency = 0.3
versionBadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
versionBadgeStroke.Parent = versionBadge

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, 0, 1, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0"
versionLabel.Font = Enum.Font.MontserratBold
versionLabel.TextSize = 10
versionLabel.TextColor3 = C.blue2
versionLabel.TextXAlignment = Enum.TextXAlignment.Center
versionLabel.TextYAlignment = Enum.TextYAlignment.Center
versionLabel.Parent = versionBadge

local decorCircle = Instance.new("Frame")
decorCircle.Name = "DecorCircle"
decorCircle.Size = UDim2.new(0, 8, 0, 8)
decorCircle.Position = UDim2.new(1, -20, 0, 12)
decorCircle.BackgroundColor3 = C.decorBlue
decorCircle.BorderSizePixel = 0
decorCircle.Parent = menuFrame

local decorCircleCorner = Instance.new("UICorner")
decorCircleCorner.CornerRadius = UDim.new(1, 0)
decorCircleCorner.Parent = decorCircle

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 32)
divider.BackgroundColor3 = C.dividerGrey
divider.BorderSizePixel = 0
divider.Parent = menuFrame

local currentTab = "Favorites"

local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -20, 0, 25)
tabContainer.Position = UDim2.new(0, 10, 0, 40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = menuFrame

local tabs = {"Favorites", "Features", "Utility", "UI", "Keybinds"}
local tabButtons = {}
local tabContents = {}

local function createTabContent(name)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = name .. "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -85)
    contentFrame.Position = UDim2.new(0, 10, 0, 75)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = C.buttonBlue
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Visible = (name == currentTab)
    contentFrame.Parent = menuFrame
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    return contentFrame
end

local function createTabButton(name, index)
    local tabWidth = (257) / 5
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(0, tabWidth - 2, 1, 0)
    tabButton.Position = UDim2.new(0, (index - 1) * (tabWidth + 2), 0, 0)
    tabButton.BackgroundTransparency = 1
    tabButton.Text = name
    tabButton.TextColor3 = currentTab == name and C.tabActive or C.tabInactive
    tabButton.Font = Enum.Font.GothamBold
    tabButton.TextSize = 9
    tabButton.Parent = tabContainer
    return tabButton
end

for i, tabName in ipairs(tabs) do
    local tabBtn = createTabButton(tabName, i)
    tabButtons[tabName] = tabBtn
    local tabContent = createTabContent(tabName)
    tabContents[tabName] = tabContent
    tabBtn.MouseButton1Click:Connect(function()
        for _, content in pairs(tabContents) do content.Visible = false end
        tabContents[tabName].Visible = true
        for name, btn in pairs(tabButtons) do
            btn.TextColor3 = (name == tabName) and C.tabActive or C.tabInactive
        end
        currentTab = tabName
    end)
end

local function createSectionHeader(parent, sectionName)
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = sectionName .. "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 25)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = parent
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "Label"
    headerLabel.Size = UDim2.new(1, 0, 1, 0)
    headerLabel.Position = UDim2.new(0, 5, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = sectionName
    headerLabel.TextColor3 = C.white
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 11
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
    button.BackgroundColor3 = C.darkGrey
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = C.buttonBlue
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.Parent = mainFrame
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
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
    button.BackgroundColor3 = toggleEnabled and C.toggleOn or C.darkGrey
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = C.buttonBlue
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.Parent = mainFrame
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = button
    button.MouseButton1Click:Connect(function()
        toggleEnabled = not toggleEnabled
        button.BackgroundColor3 = toggleEnabled and C.toggleOn or C.darkGrey
        if callback then callback(toggleEnabled, setToggle) end
    end)
    return button
end

local function createTabToggle(parent, name, configKey, callback)
    local function setToggle(state) Config[configKey] = state; SaveConfig() end
    local toggleEnabled = Config[configKey] or false
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = name .. "ToggleFrame"
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    toggleFrame.BackgroundColor3 = C.black
    toggleFrame.BackgroundTransparency = 0.20
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent
    local toggleFrameCorner = Instance.new("UICorner")
    toggleFrameCorner.CornerRadius = UDim.new(0, 6)
    toggleFrameCorner.Parent = toggleFrame
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "Label"
    toggleLabel.Size = UDim2.new(0, 180, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = C.white
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 10
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.TextYAlignment = Enum.TextYAlignment.Center
    toggleLabel.Parent = toggleFrame
    local toggleSwitch = Instance.new("Frame")
    toggleSwitch.Name = "Switch"
    toggleSwitch.Size = UDim2.new(0, 28, 0, 16)
    toggleSwitch.Position = UDim2.new(1, -38, 0.5, -8)
    toggleSwitch.BackgroundColor3 = toggleEnabled and C.buttonBlue or Color3.fromRGB(60, 60, 60)
    toggleSwitch.BorderSizePixel = 0
    toggleSwitch.Parent = toggleFrame
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = toggleSwitch
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Name = "Circle"
    toggleCircle.Size = UDim2.new(0, 12, 0, 12)
    toggleCircle.Position = toggleEnabled and UDim2.new(0, 14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    toggleCircle.BackgroundColor3 = C.white
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleSwitch
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.Position = UDim2.new(0, 0, 0, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = toggleFrame
    clickButton.MouseButton1Click:Connect(function()
        toggleEnabled = not toggleEnabled
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        if toggleEnabled then
            S.TweenService:Create(toggleSwitch, tweenInfo, {BackgroundColor3 = C.buttonBlue}):Play()
            S.TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 14, 0.5, -6)}):Play()
        else
            S.TweenService:Create(toggleSwitch, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
            S.TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        end
        if callback then callback(toggleEnabled, setToggle) end
    end)
    if toggleEnabled and callback then callback(true, setToggle) end
    return toggleFrame
end

local function createTabButton(parent, name, iconId, callback)
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = name .. "ButtonFrame"
    buttonFrame.Size = UDim2.new(1, 0, 0, 30)
    buttonFrame.BackgroundColor3 = C.black
    buttonFrame.BackgroundTransparency = 0.20
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = parent
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = buttonFrame
    
    local buttonLabel = Instance.new("TextLabel")
    buttonLabel.Name = "Label"
    buttonLabel.Size = UDim2.new(0, 180, 1, 0)
    buttonLabel.Position = UDim2.new(0, 10, 0, 0)
    buttonLabel.BackgroundTransparency = 1
    buttonLabel.Text = name
    buttonLabel.TextColor3 = C.white
    buttonLabel.Font = Enum.Font.Gotham
    buttonLabel.TextSize = 10
    buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
    buttonLabel.TextYAlignment = Enum.TextYAlignment.Center
    buttonLabel.Parent = buttonFrame
    
    local iconDecor = Instance.new("ImageLabel")
    iconDecor.Name = "Icon"
    iconDecor.Size = UDim2.new(0, 18, 0, 18)
    iconDecor.Position = UDim2.new(1, -28, 0.5, -9)
    iconDecor.BackgroundTransparency = 1
    iconDecor.Image = iconId or "rbxassetid://97462463002118"
    iconDecor.ImageColor3 = C.blue1
    iconDecor.Parent = buttonFrame
    
    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.Position = UDim2.new(0, 0, 0, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = buttonFrame
    
    clickButton.MouseEnter:Connect(function()
        buttonFrame.BackgroundTransparency = 0.1
        iconDecor.ImageColor3 = C.blue2
    end)
    
    clickButton.MouseLeave:Connect(function()
        buttonFrame.BackgroundTransparency = 0.20
        iconDecor.ImageColor3 = C.blue1
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
    rowFrame.Name = name .. "KeybindRow"
    rowFrame.Size = UDim2.new(1, 0, 0, 30)
    rowFrame.BackgroundColor3 = C.black
    rowFrame.BackgroundTransparency = 0.20
    rowFrame.BorderSizePixel = 0
    rowFrame.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = rowFrame

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(0, 150, 1, 0)
    rowLabel.Position = UDim2.new(0, 10, 0, 0)
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
    keyBtn.Position = UDim2.new(1, -53, 0.5, -9)
    keyBtn.BackgroundColor3 = C.black
    keyBtn.BackgroundTransparency = 0.20
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = Config.Keybinds[configKey]
    keyBtn.TextColor3 = C.buttonBlue
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 9
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = rowFrame

    local keyBtnCorner = Instance.new("UICorner")
    keyBtnCorner.CornerRadius = UDim.new(0, 5)
    keyBtnCorner.Parent = keyBtn

    local keyBtnStroke = Instance.new("UIStroke")
    keyBtnStroke.Thickness = 1
    keyBtnStroke.Color = C.buttonBlue
    keyBtnStroke.Transparency = 0.5
    keyBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    keyBtnStroke.Parent = keyBtn

    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "..."
        keyBtn.TextColor3 = C.blue1
        keyBtnStroke.Transparency = 0
        local con
        con = S.UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Config.Keybinds[configKey] = inp.KeyCode.Name
                keyBtn.Text = inp.KeyCode.Name
                keyBtn.TextColor3 = C.buttonBlue
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
    cardFrame.Size = UDim2.new(1, 0, 0, 100)  
    cardFrame.BackgroundColor3 = C.black
    cardFrame.BackgroundTransparency = 0.15
    cardFrame.BorderSizePixel = 0
    cardFrame.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = cardFrame

    local vpFrame = Instance.new("ViewportFrame")
    vpFrame.Name = "ModelViewport"
    vpFrame.Size = UDim2.new(0, 45, 0, 45)
    vpFrame.Position = UDim2.new(0, 8, 0, 8)
    vpFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    vpFrame.BorderSizePixel = 0
    vpFrame.Ambient = Color3.fromRGB(180, 180, 180)
    vpFrame.LightDirection = Vector3.new(-1, -2, -1)
    vpFrame.Parent = cardFrame

    local vpCorner = Instance.new("UICorner")
    vpCorner.CornerRadius = UDim.new(0, 8)
    vpCorner.Parent = vpFrame

    local vpStroke = Instance.new("UIStroke")
    vpStroke.Thickness = 1.2
    vpStroke.Color = Color3.fromRGB(50, 50, 65)
    vpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    vpStroke.Parent = vpFrame

    pcall(function()
        local animalModels = S.ReplicatedStorage:FindFirstChild("Models")
            and S.ReplicatedStorage.Models:FindFirstChild("Animals")
        if not animalModels then return end

        local animalModel = animalModels:FindFirstChild(animalData.modelName)
        if not animalModel then return end

        local cloned = animalModel:Clone()
        cloned.Parent = vpFrame

        for _, part in ipairs(cloned:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = false
            end
        end

        local rootPart = cloned.PrimaryPart or cloned:FindFirstChildWhichIsA("BasePart")
        if rootPart then rootPart.Anchored = true end

        local cf, size = cloned:GetBoundingBox()

        cloned:PivotTo(CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(125), 0))

        local cf2, size2 = cloned:GetBoundingBox()
        local distance = math.max(size2.X, size2.Y, size2.Z) * 1.5

        local vpCamera = Instance.new("Camera")
        vpCamera.FieldOfView = 50
        vpCamera.CFrame = CFrame.new(
            cf2.Position + Vector3.new(0, size2.Y * 0.1, distance),
            cf2.Position
        )
        vpCamera.Parent = vpFrame
        vpFrame.CurrentCamera = vpCamera
    end)

local badgeColor, strokeColor, iconId
if rank == 1 then
    badgeColor = Color3.fromRGB(219, 154, 2)
    strokeColor = Color3.fromRGB(255, 215, 0)
    iconId = "rbxassetid://75275446742454"
elseif rank == 2 then
    badgeColor = Color3.fromRGB(166, 162, 162)
    strokeColor = Color3.fromRGB(192, 192, 192)
    iconId = "rbxassetid://105421235220109"
elseif rank == 3 then
    badgeColor = Color3.fromRGB(143, 81, 20)
    strokeColor = Color3.fromRGB(205, 127, 50)
    iconId = "rbxassetid://104204204434785"
else
    badgeColor = Color3.fromRGB(60, 60, 75)
    strokeColor = Color3.fromRGB(100, 100, 120)
    iconId = nil
end

local rankBadge = Instance.new("Frame")
rankBadge.Name = "RankBadge"
rankBadge.Size = UDim2.new(0, 32, 0, 18)
rankBadge.Position = UDim2.new(0, 8, 0, 67)  
rankBadge.BackgroundTransparency = 1
rankBadge.BorderSizePixel = 0
rankBadge.Parent = cardFrame

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0.11, 0)
badgeCorner.Parent = rankBadge

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Thickness = 1.5
badgeStroke.Color = strokeColor
badgeStroke.Transparency = 0
badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
badgeStroke.Parent = rankBadge

if iconId then
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "RankIcon"
    iconImage.Size = UDim2.new(0, 10, 0, 10)
    iconImage.Position = UDim2.new(0, 2, 0.5, -5)
    iconImage.BackgroundTransparency = 1
    iconImage.Image = iconId
    iconImage.Parent = rankBadge
end

local rankLabel = Instance.new("TextLabel")
rankLabel.Name = "RankLabel"
rankLabel.Size = UDim2.new(1, iconId and -12 or 0, 1, 0)
rankLabel.Position = UDim2.new(0, iconId and 12 or 0, 0, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.Text = "#" .. tostring(rank)
rankLabel.TextColor3 = strokeColor
rankLabel.Font = Enum.Font.GothamBold
rankLabel.TextSize = 10
rankLabel.TextXAlignment = Enum.TextXAlignment.Center
rankLabel.TextYAlignment = Enum.TextYAlignment.Center
rankLabel.Parent = rankBadge

local isFav = isFavorite(animalData.name)

local favBadge = Instance.new("Frame")
favBadge.Name = "FavoriteBadge"
favBadge.Size = UDim2.new(0, 58, 0, 18)  
favBadge.Position = UDim2.new(0, 44, 0, 67)  
favBadge.BackgroundTransparency = 1
favBadge.BorderSizePixel = 0
favBadge.Visible = isFav
favBadge.Parent = cardFrame

local favBadgeCorner = Instance.new("UICorner")
favBadgeCorner.CornerRadius = UDim.new(0.11, 0)
favBadgeCorner.Parent = favBadge

local favBadgeStroke = Instance.new("UIStroke")
favBadgeStroke.Thickness = 1.5
favBadgeStroke.Color = C.yellow
favBadgeStroke.Transparency = 0
favBadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
favBadgeStroke.Parent = favBadge

local favBadgeIcon = Instance.new("ImageLabel")
favBadgeIcon.Name = "FavIcon"
favBadgeIcon.Size = UDim2.new(0, 10, 0, 10)
favBadgeIcon.Position = UDim2.new(0, 3, 0.5, -5)
favBadgeIcon.BackgroundTransparency = 1
favBadgeIcon.Image = "rbxassetid://113366714224251"
favBadgeIcon.Parent = favBadge

local favBadgeLabel = Instance.new("TextLabel")
favBadgeLabel.Name = "FavLabel"
favBadgeLabel.Size = UDim2.new(1, -14, 1, 0)  
favBadgeLabel.Position = UDim2.new(0, 14, 0, 0)  
favBadgeLabel.BackgroundTransparency = 1
favBadgeLabel.Text = "Favorite"
favBadgeLabel.TextColor3 = C.yellow
favBadgeLabel.Font = Enum.Font.GothamBold
favBadgeLabel.TextSize = 9
favBadgeLabel.TextXAlignment = Enum.TextXAlignment.Center
favBadgeLabel.TextYAlignment = Enum.TextYAlignment.Center
favBadgeLabel.Parent = favBadge

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -145, 0, 18)
    nameLabel.Position = UDim2.new(0, 61, 0, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = animalData.name
    nameLabel.TextColor3 = C.white
    nameLabel.Font = Enum.Font.MontserratBold
    nameLabel.TextSize = 11
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = cardFrame

    local mutationLabel = Instance.new("TextLabel")
    mutationLabel.Name = "MutationLabel"
    mutationLabel.Size = UDim2.new(1, -145, 0, 16)
    mutationLabel.Position = UDim2.new(0, 61, 0, 30)
    mutationLabel.BackgroundTransparency = 1
    mutationLabel.Text = animalData.mutation
    mutationLabel.TextColor3 = C.blue1
    mutationLabel.Font = Enum.Font.GothamBold
    mutationLabel.TextSize = 10
    mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
    mutationLabel.TextYAlignment = Enum.TextYAlignment.Center
    mutationLabel.Parent = cardFrame

    local genLabel = Instance.new("TextLabel")
    genLabel.Name = "GenLabel"
    genLabel.Size = UDim2.new(1, -145, 0, 16)
    genLabel.Position = UDim2.new(0, 61, 0, 46)
    genLabel.BackgroundTransparency = 1
    genLabel.Text = animalData.genText
    genLabel.TextColor3 = C.green
    genLabel.Font = Enum.Font.GothamBold
    genLabel.TextSize = 10
    genLabel.TextXAlignment = Enum.TextXAlignment.Left
    genLabel.TextYAlignment = Enum.TextYAlignment.Center
    genLabel.Parent = cardFrame

    -- Teleport Button
    local tpButton = Instance.new("TextButton")
    tpButton.Name = "TpButton"
    tpButton.Size = UDim2.new(0, 60, 0, 26)
    tpButton.Position = UDim2.new(1, -95, 0.5, -13)
    tpButton.BackgroundColor3 = C.black
    tpButton.BackgroundTransparency = 0.15
    tpButton.BorderSizePixel = 0
    tpButton.Text = "Teleport"
    tpButton.TextColor3 = C.buttonBlue
    tpButton.Font = Enum.Font.GothamBold
    tpButton.TextSize = 9
    tpButton.AutoButtonColor = false
    tpButton.Parent = cardFrame

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpButton

    local tpStroke = Instance.new("UIStroke")
    tpStroke.Thickness = 1
    tpStroke.Color = C.buttonBlue
    tpStroke.Transparency = 0.5
    tpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tpStroke.Parent = tpButton

    tpButton.MouseEnter:Connect(function()
        tpButton.BackgroundColor3 = C.buttonBlue
        tpButton.BackgroundTransparency = 0
        tpButton.TextColor3 = C.white
        tpStroke.Transparency = 0
    end)

    tpButton.MouseLeave:Connect(function()
        tpButton.BackgroundColor3 = C.black
        tpButton.BackgroundTransparency = 0.15
        tpButton.TextColor3 = C.buttonBlue
        tpStroke.Transparency = 0.5
    end)

    tpButton.MouseButton1Click:Connect(function()
        
    end)

    local favButton = Instance.new("TextButton")
    favButton.Name = "FavoriteButton"
    favButton.Size = UDim2.new(0, 26, 0, 26)
    favButton.Position = UDim2.new(1, -32, 0.5, -13)
    favButton.BackgroundColor3 = isFav and C.yellow or C.black
    favButton.BackgroundTransparency = isFav and 0 or 0.15
    favButton.BorderSizePixel = 0
    favButton.Text = "★"
    favButton.TextColor3 = isFav and C.white or Color3.fromRGB(150, 150, 150)
    favButton.Font = Enum.Font.GothamBold
    favButton.TextSize = 14
    favButton.AutoButtonColor = false
    favButton.Parent = cardFrame

    local favCorner = Instance.new("UICorner")
    favCorner.CornerRadius = UDim.new(0, 6)
    favCorner.Parent = favButton

    local favStroke = Instance.new("UIStroke")
    favStroke.Thickness = 1
    favStroke.Color = isFav and C.yellow or Color3.fromRGB(100, 100, 115)
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
            favStroke.Color = Color3.fromRGB(100, 100, 115)
            favStroke.Transparency = 0.5
        end
    end)

    favButton.MouseButton1Click:Connect(function()
        isFavorited = not isFavorited
        
        if isFavorited then
            -- Add to favorites
            addFavorite(animalData.name)
            
            favButton.BackgroundColor3 = C.yellow
            favButton.BackgroundTransparency = 0
            favButton.TextColor3 = C.white
            favStroke.Color = C.yellow
            favStroke.Transparency = 0
            
            favBadge.Visible = true
        else
            
            removeFavorite(animalData.name)
            
            favButton.BackgroundColor3 = C.black
            favButton.BackgroundTransparency = 0.15
            favButton.TextColor3 = Color3.fromRGB(150, 150, 150)
            favStroke.Color = Color3.fromRGB(100, 100, 115)
            favStroke.Transparency = 0.5
            
            favBadge.Visible = false
        end
    end)

    return cardFrame
end

local instantCloneBtn = createButton("Instant Clone", 45, function()
    task.spawn(instantClone)
end)

local tpToBestBtn = createButton("Tp to Best", 80, function() end)

local ragdollSelfBtn = createButton("Ragdoll Self", 115, function() end)

local rejoinBtn = createButton("Rejoin", 150, function()
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
                            found = true
                            break
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

local featuresContent = tabContents["Features"]
if featuresContent then
    createSectionHeader(featuresContent, "Desync")
    createTabToggle(featuresContent, "Desync on Start", "DesyncOnStart", function(ns, set)
        set(ns)
        if ns then runDesync() end
    end)

    createSectionHeader(featuresContent, "Teleport")
    createTabToggle(featuresContent, "Auto Tp on Start", "AutoTponStart", function(ns, set)
        set(ns)
    end)

    createSectionHeader(featuresContent, "Visual")
    createTabToggle(featuresContent, "Esp Players", "EspPlayers", function(ns, set)
        set(ns); if ns then enableESPPlayers() else disableESPPlayers() end
    end)
    createTabToggle(featuresContent, "Esp Timer", "EspTimer", function(ns, set)
        set(ns); toggleTimerESP(ns)
    end)
    createTabToggle(featuresContent, "Esp Mine", "EspMine", function(ns, set)
        set(ns); if ns then enableSubspaceMineESP() else disableSubspaceMineESP() end
    end)
    createTabToggle(featuresContent, "Esp Best", "EspBest", function(ns, set)
        set(ns); if ns then enableBrainrotESP() else disableBrainrotESP() end
    end)
end

local utilityContent = tabContents["Utility"]
if utilityContent then
    createSectionHeader(utilityContent, "Misc")
    createTabToggle(utilityContent, "Plot Beam", "PlotBeam", function(ns, set)
        set(ns); if ns then enablePlotBeam() else disablePlotBeam() end
    end)
    createTabToggle(utilityContent, "Xray Base", "XrayBase", function(ns, set)
        set(ns); if ns then enableXrayBase() else disableXrayBase() end
    end)
    createTabToggle(utilityContent, "Kick After Steal", "KickAfterSteal", function(ns, set)
        set(ns); if ns then enableKickAfterSteal() else disableKickAfterSteal() end
    end)

    createSectionHeader(utilityContent, "Movement")
    createTabToggle(utilityContent, "Carpet Speed", "CarpetSpeed", function(ns, set)
        set(ns); if ns then enableCarpetSpeed() else disableCarpetSpeed() end
    end)
    createTabToggle(utilityContent, "Inf Jump", "InfJump", function(ns, set)
        set(ns); toggleInfJump(ns)
    end)

    createSectionHeader(utilityContent, "Performance")
    createTabToggle(utilityContent, "Optimizer", "Optimizer", function(ns, set)
        set(ns); toggleOptimizer(ns)
    end)
    createTabToggle(utilityContent, "Anti Lag", "AntiLag", function(ns, set)
        set(ns); if ns then enableAntiLag() else disableAntiLag() end
    end)
    createTabToggle(utilityContent, "Animation Disabler", "AnimDisabler", function(ns, set)
        set(ns); if ns then enableAnimDisabler() else disableAnimDisabler() end
    end)
end

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
        Config.Positions.MainFrame = DefaultConfig.Positions.MainFrame
        Config.Positions.MenuFrame = DefaultConfig.Positions.MenuFrame
        SaveConfig()

        local creditPos = Config.Positions.CreditFrame
        creditFrame.Position = UDim2.new(creditPos.X, -170, creditPos.Y, -25)

        local mainPos = Config.Positions.MainFrame
        mainFrame.Position = UDim2.new(mainPos.X, -96.5, mainPos.Y, -142.5)

        local menuPos = Config.Positions.MenuFrame
        menuFrame.Position = UDim2.new(menuPos.X, -145, menuPos.Y, -160)

        showNotification({
            message = "GUI positions reset!",
            color = "Success",
            textColor = "White"
        })
    end)
end

local keybindsContent = tabContents["Keybinds"]
if keybindsContent then
    createSectionHeader(keybindsContent, "Keybinds")
    createTabKeybind(keybindsContent, "Instant Clone", "CloneKey", "V", nil)
    createTabKeybind(keybindsContent, "Carpet Speed", "CarpetSpeedKey", "Q", nil)
end

local favoritesContent = tabContents["Favorites"]
local lastCacheCount = 0
local lastTopUIDs = {}

local function needsUpdate()
    if #allAnimalsCache ~= lastCacheCount then
        return true
    end
    
    for i = 1, math.min(10, #allAnimalsCache) do
        if allAnimalsCache[i].uid ~= lastTopUIDs[i] then
            return true
        end
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

if favoritesContent then
    createSectionHeader(favoritesContent, "Favorites Animal")

    for rank, animalData in ipairs(allAnimalsCache) do
        createAnimalCard(favoritesContent, animalData, rank)
    end
    
    updateLastCache()

    task.spawn(function()
        while true do
            task.wait(3)
            
            if needsUpdate() then
            
                for _, child in ipairs(favoritesContent:GetChildren()) do
                    if child.Name == "AnimalCard" then
                        child:Destroy()
                    end
                end
                
                for rank, animalData in ipairs(allAnimalsCache) do
                    createAnimalCard(favoritesContent, animalData, rank)
                end
                
                updateLastCache()
            end
        end
    end)
end

-- ok
S.UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if S.UserInputService:GetFocusedTextBox() then return end

    if Config.Keybinds.CloneKey and input.KeyCode == Enum.KeyCode[Config.Keybinds.CloneKey] then
        task.spawn(instantClone)
    end

    if Config.Keybinds.CarpetSpeedKey and input.KeyCode == Enum.KeyCode[Config.Keybinds.CarpetSpeedKey] then
        toggleCarpetSpeed()
        Config.CarpetSpeed = carpetSpeedEnabled
        SaveConfig()
    end
end)

showNotification({message = "ZynHub Private", subtext = "Welcome back!", color = "Violet", textColor = "White", subColor = "Violet"})
