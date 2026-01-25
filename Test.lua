-- Load The Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Get required services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bases = workspace.Bases
local Workspace = workspace

-- ========================================
-- THEMES (10+ COLOR VARIATIONS) - ALL RED ACCENTS/ICONS
-- ========================================
WindUI:AddTheme({
    Name = "Dark",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#161616"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#101010"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Light",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#f5f5f5"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#000000"),
    Placeholder = Color3.fromHex("#5a5a5a"),
    Background = Color3.fromHex("#ffffff"),
    Button = Color3.fromHex("#e5e5e5"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Purple Dream",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#1a1625"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0f0b16"),
    Button = Color3.fromHex("#4c2a6e"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Ocean Blue",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#161e28"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0a1420"),
    Button = Color3.fromHex("#1e3a5f"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Forest Green",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#16211c"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0a1610"),
    Button = Color3.fromHex("#1e4d3a"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Crimson Red",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#211616"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#180a0a"),
    Button = Color3.fromHex("#5f1e1e"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Sunset Orange",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#211a16"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#18120a"),
    Button = Color3.fromHex("#5f371e"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Midnight Purple",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#1a1625"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0f0a18"),
    Button = Color3.fromHex("#3d2a5f"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Cyan Glow",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#162228"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0a1418"),
    Button = Color3.fromHex("#1e4550"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Rose Pink",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#211619"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#180a0f"),
    Button = Color3.fromHex("#5f1e2d"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Golden Hour",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#21200f"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#000000"),
    Placeholder = Color3.fromHex("#5a5a5a"),
    Background = Color3.fromHex("#1a1808"),
    Button = Color3.fromHex("#6b5a1e"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Neon Green",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#162116"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0a1610"),
    Button = Color3.fromHex("#1e5f2d"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Electric Blue",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#161c28"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#0a1220"),
    Button = Color3.fromHex("#1e3d6b"),
    Icon = Color3.fromHex("#FF0000")
})

WindUI:AddTheme({
    Name = "Custom",
    Accent = Color3.fromHex("#FF0000"),
    Dialog = Color3.fromHex("#161616"),
    Outline = Color3.fromHex("#FF0000"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Background = Color3.fromHex("#101010"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#FF0000")
})

-- Set default theme
WindUI:SetTheme("Dark")

-- Creating Window!
local Window = WindUI:CreateWindow({
    Title = "Escape Tsunami For Brainrots",
    Icon = "sword",
    Author = "V1.0",
    Folder = "Nightmare Hub",
    Transparent = true,
    Theme = "Dark",
})

-- Always debugmode States and all lines of code must have debug mode incase there's any error its easy to troubleshoot!
local States = {
    DebugMode = false,
    ESPCelestial = false,
    ESPLuckyBlock = false,
}

-- Window must always transparent!
Window:ToggleTransparency(true)

-- CONFIG MANAGER!
local ConfigManager = Window.ConfigManager

-- Example Creating Config!
local myConfig = ConfigManager:CreateConfig("(game name)")

-- made it function
local function saveConfiguration()
    myConfig:Save()
end

local function loadConfiguration()
    myConfig:Load()
    
    WindUI:Notify({
        Title = "Configuration Loaded",
        Content = "All your saved settings have been loaded!",
        Duration = 3,
        Icon = "download",
    })
end

local function changeTheme(themeName)
    States.CurrentTheme = themeName
    WindUI:SetTheme(themeName)
end

-- Editing the minimized!
Window:EditOpenButton({
    Title = "Nightmare Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- Changed to dark red and bright red
        Color3.fromHex("#8B0000"), -- Dark red
        Color3.fromHex("#FF0000")  -- Bright red
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- ========================================
-- TABS CREATION
-- ========================================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

local AutoTab = Window:Tab({
    Title = "Auto",
    Icon = "arrow-right-left",
})

local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "wrench",
})

local EventsTab = Window:Tab({
    Title = "Events",
    Icon = "sparkles",
})

local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon = "heart",
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

-- ========================================
-- MAIN TAB ELEMENTS (NEW FEATURES)
-- ========================================
-- Fly to Base Button (at the top)
local isTeleporting = false
local currentVelocity = nil
local currentAttachment = nil
local heartbeatConnection = nil

local function cleanupFlyToBase()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    
    if currentVelocity then
        pcall(function() currentVelocity:Destroy() end)
        currentVelocity = nil
    end
    
    if currentAttachment then
        pcall(function() currentAttachment:Destroy() end)
        currentAttachment = nil
    end
    
    isTeleporting = false
end

local function getMyBase()
    for _, base in pairs(Bases:GetChildren()) do
        local holder = base:GetAttribute("Holder")
        if holder and holder == LocalPlayer.UserId then
            return base
        end
    end
    return nil
end

local function flyToBase()
    if isTeleporting then return end
    
    local myBase = getMyBase()
    if not myBase then 
        WindUI:Notify({
            Title = "Error",
            Content = "Base not found!",
            Duration = 3,
            Icon = "alert",
        })
        return 
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    isTeleporting = true
    
    WindUI:Notify({
        Title = "Flying to Base",
        Content = "Teleporting to your base...",
        Duration = 2,
        Icon = "compass",
    })
    
    -- Set ragdoll state
    hum:ChangeState(Enum.HumanoidStateType.Ragdoll)
    
    -- Target position dengan offset sikit ke atas untuk landing yang lebih baik
    local targetPos = myBase:GetPivot().Position + Vector3.new(0, 5, 0)
    
    currentAttachment = Instance.new("Attachment")
    currentAttachment.Parent = hrp
    
    currentVelocity = Instance.new("LinearVelocity")
    currentVelocity.Attachment0 = currentAttachment
    currentVelocity.MaxForce = math.huge
    currentVelocity.VectorVelocity = Vector3.new(0, 0, 0)
    currentVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    currentVelocity.Parent = hrp
    
    -- Guna RunService.Heartbeat untuk update yang lebih smooth dan reliable
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not char or not char.Parent or not hrp or not hrp.Parent or not hum or hum.Health <= 0 then
            cleanupFlyToBase()
            return
        end
        
        local distance = (targetPos - hrp.Position).Magnitude
        
        -- Speed yang lebih laju bila jauh, perlahan bila dekat
        local speed
        if distance < 30 then
            speed = math.max(40, distance * 2.5) -- Perlahan untuk landing smooth
        elseif distance < 80 then
            speed = 280 -- Sederhana bila dah agak dekat
        elseif distance < 200 then
            speed = 800 -- Laju sikit
        else
            speed = 1000 -- SUPER LAJU bila jauh! 🚀
        end
        
        -- Stop bila dah sampai
        if distance < 15 then
            cleanupFlyToBase()
            
            -- Reset velocity HRP
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            
            task.wait(0.2)
            if hum and hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            WindUI:Notify({
                Title = "Arrived",
                Content = "Successfully arrived at your base!",
                Duration = 2,
                Icon = "check",
            })
            return
        end
        
        -- Update direction dan velocity
        local direction = (targetPos - hrp.Position).Unit
        if currentVelocity and currentVelocity.Parent then
            currentVelocity.VectorVelocity = direction * speed
        else
            cleanupFlyToBase()
        end
    end)
end

-- Fly to Base Button (at the top)
local FlyToBaseButton = MainTab:Button({
    Title = "Fly to Base",
    Desc = "Teleport to your base (Press B key for shortcut)",
    Callback = function()
        flyToBase()
    end
})

-- Speed Toggle with Input
local speedValue = 50
local SpeedInput = MainTab:Input({
    Title = "Speed Value",
    Desc = "Enter your desired speed value (no limit)",
    Value = "50",
    InputIcon = "zap",
    Type = "Input",
    Placeholder = "Enter speed value...",
    Callback = function(input) 
        speedValue = tonumber(input) or 50
        saveConfiguration()
    end
})

local isSpeedEnabled = false
local speedConnection = nil

local function cleanupSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

-- FIX: Get character reference inside the loop to handle respawns
local function enableSpeed()
    cleanupSpeed()
    
    speedConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character -- Get fresh reference every frame
        if character and character.Parent then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if rootPart and humanoid then
                local moveDirection = humanoid.MoveDirection
                
                if moveDirection.Magnitude > 0 then
                    local targetVelocity = Vector3.new(moveDirection.X, 0, moveDirection.Z) * speedValue
                    local currentVelocity = rootPart.AssemblyLinearVelocity
                    
                    rootPart.AssemblyLinearVelocity = Vector3.new(
                        targetVelocity.X,
                        currentVelocity.Y,
                        targetVelocity.Z
                    )
                end
            end
        end
    end)
end

local SpeedToggle = MainTab:Toggle({
    Title = "Speed",
    Desc = "Enable speed hack with custom value",
    Default = false,
    Callback = function(state)
        isSpeedEnabled = state
        
        if state then
            enableSpeed()
        else
            cleanupSpeed()
        end
        
        saveConfiguration()
    end
})

-- God Mode Toggle
local isGodModeEnabled = false
local godModeConnection = nil
local healthChangedConnection = nil

local function cleanupGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    
    if healthChangedConnection then
        healthChangedConnection:Disconnect()
        healthChangedConnection = nil
    end
    
    -- Restore normal health
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.BreakJointsOnDeath = true
        end
    end
end

-- Function to enable SUPER IMPROVED God Mode 💪💀
-- FIX: Get character reference inside the loop to handle respawns
local function enableGodMode()
    cleanupGodMode()
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if isGodModeEnabled then
            local character = LocalPlayer.Character -- Get fresh reference every frame
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if humanoid.Health < math.huge then
                        humanoid.Health = math.huge
                    end
                    if humanoid.MaxHealth < math.huge then
                        humanoid.MaxHealth = math.huge
                    end
                    humanoid.BreakJointsOnDeath = false
                end
            end
        end
    end)
end

local GodModeToggle = MainTab:Toggle({
    Title = "God Mode",
    Desc = "Bypass 1 or 2 wave",
    Default = false,
    Callback = function(state)
        isGodModeEnabled = state
        
        if state then
            enableGodMode()
        else
            cleanupGodMode()
        end
        
        saveConfiguration()
    end
})

-- Auto Steal Toggle with Rarity Dropdown
-- Define rarity tiers
local RARITY_TIERS = {
    ["Low Tier"] = {"Common", "Uncommon", "Rare"},
    ["Mid Tier"] = {"Epic", "Legendary", "Mythical"},
    ["High Tier"] = {"Cosmic", "Secret", "Celestial"}
}

-- FIX: Initialize selectedRarities based on the default selectedTier
local selectedTier = "Low Tier"
local selectedRarities = RARITY_TIERS[selectedTier]

-- Cache untuk optimization
local brainrotCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 0.1

-- Function to update brainrot cache ONLY (no general prompts)
local function updateBrainrotCache()
    brainrotCache = {}
    local activeBrainrots = workspace:FindFirstChild("ActiveBrainrots")
    if not activeBrainrots then return end
    
    for _, rarityName in ipairs(selectedRarities) do
        local rarityFolder = activeBrainrots:FindFirstChild(rarityName)
        if rarityFolder then
            for _, brainrot in pairs(rarityFolder:GetChildren()) do
                local root = brainrot:FindFirstChild("Root")
                if root then
                    local prompt = root:FindFirstChild("TakePrompt")
                    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        table.insert(brainrotCache, {
                            prompt = prompt,
                            part = root,
                            maxDist = prompt.MaxActivationDistance + 20 -- Extra range untuk high speed
                        })
                    end
                end
            end
        end
    end
end

local RarityDropdown = MainTab:Dropdown({
    Title = "Select Rarity",
    Values = {
        {Title = "Low Tier", Icon = "circle"},
        {Title = "Mid Tier", Icon = "diamond"},
        {Title = "High Tier", Icon = "crown"},
        {Title = "Common", Icon = "circle"},
        {Title = "Uncommon", Icon = "circle"},
        {Title = "Rare", Icon = "circle"},
        {Title = "Epic", Icon = "circle"},
        {Title = "Legendary", Icon = "star"},
        {Title = "Mythical", Icon = "star"},
        {Title = "Cosmic", Icon = "star"},
        {Title = "Secret", Icon = "star"},
        {Title = "Celestial", Icon = "star"},
    },
    Value = "Low Tier",
    Callback = function(option)
        selectedTier = option.Title
        
        -- Update selected rarities based on tier
        if RARITY_TIERS[selectedTier] then
            selectedRarities = RARITY_TIERS[selectedTier]
        else
            -- If it's a specific rarity, only select that one
            selectedRarities = {option.Title}
        end
        
        -- Clear cache when rarity selection changes
        brainrotCache = {}
        saveConfiguration()
    end
})

local isAutoStealEnabled = false
local autoStealConnection = nil

local function cleanupAutoSteal()
    if autoStealConnection then
        autoStealConnection:Disconnect()
        autoStealConnection = nil
    end
    brainrotCache = {}
end

-- Auto steal BRAINROTS ONLY! 🔥
-- FIX: Get character reference inside the loop to handle respawns
local function enableAutoSteal()
    cleanupAutoSteal()
    
    -- Initial cache update
    updateBrainrotCache()
    lastCacheUpdate = tick()
    
    autoStealConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local character = LocalPlayer.Character -- Get fresh reference every frame
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local rootPos = rootPart.Position
        
        -- Update cache periodically
        if currentTime - lastCacheUpdate >= CACHE_UPDATE_INTERVAL then
            updateBrainrotCache()
            lastCacheUpdate = currentTime
        end
        
        -- Process brainrot prompts ONLY
        for i = #brainrotCache, 1, -1 do
            local data = brainrotCache[i]
            if data.prompt and data.prompt.Parent and data.prompt.Enabled then
                local distance = (data.part.Position - rootPos).Magnitude
                if distance <= data.maxDist then
                    task.spawn(function()
                        pcall(fireproximityprompt, data.prompt)
                    end)
                end
            else
                -- Remove invalid entries
                table.remove(brainrotCache, i)
            end
        end
    end)
end

local AutoStealToggle = MainTab:Toggle({
    Title = "Auto Steal",
    Desc = "Automatically steal brainrots of selected rarity",
    Default = false,
    Callback = function(state)
        isAutoStealEnabled = state
        
        if state then
            enableAutoSteal()
        else
            cleanupAutoSteal()
        end
        
        saveConfiguration()
    end
})

-- ========================================
-- AUTO TAB ELEMENTS
-- ========================================
-- Auto Sell Section
local isAutoSellEnabled = false
local autoSellConnection = nil
local selectedSellOption = "Sell All"
local lastSellTime = 0
local sellDelayMs = 100 -- Default delay in milliseconds

-- Get remote functions for Auto Sell
local sellAllRemote = nil
local sellToolRemote = nil

-- Function to initialize remote functions
local function initializeRemoteFunctions()
    pcall(function()
        sellAllRemote = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SellAll")
        sellToolRemote = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SellTool")
    end)
end

-- Initialize remote functions
initializeRemoteFunctions()

local function cleanupAutoSell()
    if autoSellConnection then
        autoSellConnection:Disconnect()
        autoSellConnection = nil
    end
end

local function enableAutoSell()
    cleanupAutoSell()
    
    autoSellConnection = RunService.Heartbeat:Connect(function()
        if isAutoSellEnabled then
            local currentTime = tick()
            if currentTime - lastSellTime >= (sellDelayMs / 1000) then
                pcall(function()
                    -- Check if remote functions are still valid
                    if not sellAllRemote or not sellToolRemote then
                        initializeRemoteFunctions()
                    end
                    
                    if selectedSellOption == "Sell All" and sellAllRemote then
                        sellAllRemote:InvokeServer()
                    elseif selectedSellOption == "Sell 1 Brainrot" and sellToolRemote then
                        sellToolRemote:InvokeServer()
                    end
                    lastSellTime = currentTime
                end)
            end
        end
    end)
end

local AutoSellToggle = AutoTab:Toggle({
    Title = "Auto Sell",
    Desc = "Instant Sell Your Brainrots!",
    Default = false,
    Callback = function(state)
        isAutoSellEnabled = state
        
        if state then
            enableAutoSell()
        else
            cleanupAutoSell()
        end
        
        saveConfiguration()
    end
})

-- Sell Option Dropdown
local SellOptionDropdown = AutoTab:Dropdown({
    Title = "Sell Option",
    Values = {
        {Title = "Sell All", Icon = "coins"},
        {Title = "Sell 1 Brainrot", Icon = "brain"},
    },
    Value = "Sell All",
    Callback = function(option)
        selectedSellOption = option.Title
        saveConfiguration()
    end
})

-- Auto Sell Delay Slider
local AutoSellDelaySlider = AutoTab:Slider({
    Title = "Auto Sell Delay",
    Desc = "Adjust the delay between sell actions (ms)",
    Value = {
        Min = 0,
        Max = 200,
        Default = 100,
    },
    Callback = function(value)
        sellDelayMs = value
        saveConfiguration()
    end
})

-- Auto Collect Section
local isAutoCollectEnabled = false
local autoCollectConnection = nil
local collectDelay = 2 -- Default delay in seconds
local autoCollectTask = nil

local function getMyBase()
    for _, base in pairs(Bases:GetChildren()) do
        local holder = base:GetAttribute("Holder")
        if holder and holder == LocalPlayer.UserId then
            return base
        end
    end
    return nil
end

local function detectMaxPlots(myBase)
    local plotFolder = myBase:FindFirstChild("Plots")
    if plotFolder then
        return #plotFolder:GetChildren()
    end
    
    local maxPlot = 0
    for _, child in pairs(myBase:GetDescendants()) do
        local plotNum = tonumber(child.Name)
        if plotNum and plotNum > maxPlot then
            maxPlot = plotNum
        end
    end
    
    if maxPlot > 0 then
        return maxPlot
    end
    
    return 200
end

local function collectAllMoney()
    local myBase = getMyBase()
    if not myBase then 
        return 
    end
    
    local maxPlots = detectMaxPlots(myBase)
    local baseId = myBase.Name
    
    for plotNum = 1, maxPlots do
        local args = {
            "Collect Money",
            baseId,
            tostring(plotNum)
        }
        
        task.spawn(function()
            pcall(function()
                ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Plot.PlotAction"):InvokeServer(unpack(args))
            end)
        end)
        
        if plotNum % 10 == 0 then
            task.wait(0.05)
        end
    end
end

local function cleanupAutoCollect()
    if autoCollectConnection then
        autoCollectConnection:Disconnect()
        autoCollectConnection = nil
    end
    
    if autoCollectTask then
        task.cancel(autoCollectTask)
        autoCollectTask = nil
    end
end

local function enableAutoCollect()
    cleanupAutoCollect()
    
    autoCollectTask = task.spawn(function()
        while isAutoCollectEnabled do
            collectAllMoney()
            task.wait(collectDelay)
        end
    end)
end

local AutoCollectToggle = AutoTab:Toggle({
    Title = "Auto Collect",
    Desc = "Automatically collect money from all plots",
    Default = false,
    Callback = function(state)
        isAutoCollectEnabled = state
        
        if state then
            enableAutoCollect()
        else
            cleanupAutoCollect()
        end
        
        saveConfiguration()
    end
})

-- Auto Collect Delay Slider
local AutoCollectDelaySlider = AutoTab:Slider({
    Title = "Collect Delay",
    Desc = "Adjust the delay between collections (seconds)",
    Value = {
        Min = 0.5,
        Max = 10,
        Default = 2,
    },
    Callback = function(value)
        collectDelay = value
        -- Restart auto collect if it's enabled to apply the new delay
        if isAutoCollectEnabled then
            cleanupAutoCollect()
            enableAutoCollect()
        end
        saveConfiguration()
    end
})

-- Auto Buy Speed Section
local isAutoBuySpeedEnabled = false
local autoBuySpeedConnection = nil
local selectedSpeedOption = "+1"
local upgradeDelay = 1 -- Default delay in seconds
local lastUpgradeTime = 0

-- Function to upgrade speed
local function upgradeSpeed(amount)
    local args = {amount}
    pcall(function()
        ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("UpgradeSpeed"):InvokeServer(unpack(args))
    end)
end

local function cleanupAutoBuySpeed()
    if autoBuySpeedConnection then
        autoBuySpeedConnection:Disconnect()
        autoBuySpeedConnection = nil
    end
end

local function enableAutoBuySpeed()
    cleanupAutoBuySpeed()
    
    autoBuySpeedConnection = RunService.Heartbeat:Connect(function()
        if isAutoBuySpeedEnabled then
            local currentTime = tick()
            if currentTime - lastUpgradeTime >= upgradeDelay then
                local amount = 1
                if selectedSpeedOption == "+1" then
                    amount = 1
                elseif selectedSpeedOption == "+5" then
                    amount = 5
                elseif selectedSpeedOption == "+10" then
                    amount = 10
                end
                
                upgradeSpeed(amount)
                lastUpgradeTime = currentTime
            end
        end
    end)
end

local AutoBuySpeedToggle = AutoTab:Toggle({
    Title = "Auto Buy Speed",
    Desc = "Automatically upgrade your speed",
    Default = false,
    Callback = function(state)
        isAutoBuySpeedEnabled = state
        
        if state then
            enableAutoBuySpeed()
        else
            cleanupAutoBuySpeed()
        end
        
        saveConfiguration()
    end
})

-- Speed Option Dropdown
local SpeedOptionDropdown = AutoTab:Dropdown({
    Title = "Speed Upgrade Option",
    Values = {
        {Title = "+1", Icon = "plus"},
        {Title = "+5", Icon = "plus"},
        {Title = "+10", Icon = "plus"},
    },
    Value = "+1",
    Callback = function(option)
        selectedSpeedOption = option.Title
        saveConfiguration()
    end
})

-- Auto Upgrade Delay Slider
local AutoUpgradeDelaySlider = AutoTab:Slider({
    Title = "Auto Upgrade Delay",
    Desc = "Adjust the delay between speed upgrades (seconds)",
    Value = {
        Min = 0.1,
        Max = 100,
        Default = 1,
    },
    Callback = function(value)
        upgradeDelay = value
        saveConfiguration()
    end
})

-- ==================== AUTO UPGRADE CARRY ====================
local autoUpgradeCarryEnabled = false
local carryUpgradeDelay = 1 -- Default delay in seconds
local carryThread = nil

local function startAutoUpgradeCarry()
    if carryThread then task.cancel(carryThread) end
    
    carryThread = task.spawn(function()
        while autoUpgradeCarryEnabled do
            pcall(function()
                local remote = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("UpgradeCarry")
                remote:InvokeServer()
            end)
            task.wait(carryUpgradeDelay)
        end
    end)
end

local function stopAutoUpgradeCarry()
    if carryThread then
        task.cancel(carryThread)
        carryThread = nil
    end
end

local AutoUpgradeCarryToggle = AutoTab:Toggle({
    Title = "Auto Upgrade Carry",
    Desc = "Automatically upgrade your carry capacity",
    Default = false,
    Callback = function(state)
        autoUpgradeCarryEnabled = state
        
        if state then
            startAutoUpgradeCarry()
        else
            stopAutoUpgradeCarry()
        end
        
        saveConfiguration()
    end
})

-- Carry Upgrade Delay Slider
local CarryUpgradeDelaySlider = AutoTab:Slider({
    Title = "Carry Upgrade Delay",
    Desc = "Adjust the delay between carry upgrades (seconds)",
    Value = {
        Min = 0.1,
        Max = 100,
        Default = 1,
    },
    Callback = function(value)
        carryUpgradeDelay = value
        -- Restart auto upgrade if it's enabled to apply the new delay
        if autoUpgradeCarryEnabled then
            stopAutoUpgradeCarry()
            startAutoUpgradeCarry()
        end
        saveConfiguration()
    end
})

-- ==================== AUTO UPGRADE BASE ====================
local autoUpgradeBaseEnabled = false
local baseUpgradeDelay = 1 -- Default delay in seconds
local baseThread = nil

local function startAutoUpgradeBase()
    if baseThread then task.cancel(baseThread) end
    
    baseThread = task.spawn(function()
        while autoUpgradeBaseEnabled do
            pcall(function()
                local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/Plot.UpgradeBase")
                remote:FireServer()
            end)
            task.wait(baseUpgradeDelay)
        end
    end)
end

local function stopAutoUpgradeBase()
    if baseThread then
        task.cancel(baseThread)
        baseThread = nil
    end
end

local AutoUpgradeBaseToggle = AutoTab:Toggle({
    Title = "Auto Upgrade Base",
    Desc = "Automatically upgrade your base",
    Default = false,
    Callback = function(state)
        autoUpgradeBaseEnabled = state
        
        if state then
            startAutoUpgradeBase()
        else
            stopAutoUpgradeBase()
        end
        
        saveConfiguration()
    end
})

-- Base Upgrade Delay Slider
local BaseUpgradeDelaySlider = AutoTab:Slider({
    Title = "Base Upgrade Delay",
    Desc = "Adjust the delay between base upgrades (seconds)",
    Value = {
        Min = 0.1,
        Max = 100,
        Default = 1,
    },
    Callback = function(value)
        baseUpgradeDelay = value
        -- Restart auto upgrade if it's enabled to apply the new delay
        if autoUpgradeBaseEnabled then
            stopAutoUpgradeBase()
            startAutoUpgradeBase()
        end
        saveConfiguration()
    end
})

-- ==================== AUTO UPGRADE BRAINROT ====================
local autoUpgradeBrainrotEnabled = false
local selectedUpgradeMode = "All" -- "All", "5 Slot", "10 Slot", atau nombor slot
local brainrotUpgradeDelay = 1 -- Default delay in seconds
local upgradeBrainrotThread = nil
local BrainrotUpgradeModeDropdown = nil -- [TAMBAH] Declare variable di luar fungsi

-- ==================== FIND PLAYER BASE ====================
local Bases = workspace:FindFirstChild("Bases")

local function getMyBase()
    if not Bases then return nil end
    
    for _, base in pairs(Bases:GetChildren()) do
        local holder = base:GetAttribute("Holder")
        if holder and holder == LocalPlayer.UserId then
            return base
        end
    end
    return nil
end

-- ==================== GET PLOT ID FROM BASE ====================
local function getPlayerPlotID()
    local myBase = getMyBase()
    if myBase then
        return myBase.Name
    end
    return nil
end

-- ==================== FIND ALL BRAINROT SLOTS ====================
local function getBrainrotSlots()
    local myBase = getMyBase()
    if not myBase then return {} end
    
    local slots = {}
    for _, child in pairs(myBase:GetChildren()) do
        if child.Name:lower():find("slot") and child.Name:lower():find("brainrot") then
            local slotNumber = child.Name:match("%d+")
            if slotNumber then
                table.insert(slots, slotNumber)
            end
        end
    end
    
    table.sort(slots, function(a, b) return tonumber(a) < tonumber(b) end)
    
    return slots
end

-- ==================== GET SLOTS TO UPGRADE BASED ON MODE ====================
local function getSlotsToUpgrade()
    local allSlots = getBrainrotSlots()
    if #allSlots == 0 then return {} end
    
    if selectedUpgradeMode == "All" then
        return allSlots
    elseif selectedUpgradeMode == "5 Slot" then
        local randomSlots = {}
        local availableSlots = {table.unpack(allSlots)}
        for i = 1, math.min(5, #availableSlots) do
            local randomIndex = math.random(1, #availableSlots)
            table.insert(randomSlots, availableSlots[randomIndex])
            table.remove(availableSlots, randomIndex)
        end
        return randomSlots
    elseif selectedUpgradeMode == "10 Slot" then
        local randomSlots = {}
        local availableSlots = {table.unpack(allSlots)}
        for i = 1, math.min(10, #availableSlots) do
            local randomIndex = math.random(1, #availableSlots)
            table.insert(randomSlots, availableSlots[randomIndex])
            table.remove(availableSlots, randomIndex)
        end
        return randomSlots
    else
        for _, slot in ipairs(allSlots) do
            if slot == selectedUpgradeMode then
                return {slot}
            end
        end
        return {}
    end
end

local function startAutoUpgradeBrainrot()
    if upgradeBrainrotThread then task.cancel(upgradeBrainrotThread) end
    
    upgradeBrainrotThread = task.spawn(function()
        while autoUpgradeBrainrotEnabled do
            pcall(function()
                local plotID = getPlayerPlotID()
                if not plotID then return end
                
                local slotsToUpgrade = getSlotsToUpgrade()
                if #slotsToUpgrade == 0 then return end
                
                for _, slotNumber in ipairs(slotsToUpgrade) do
                    task.spawn(function()
                        pcall(function()
                            local args = {
                                "Upgrade Brainrot",
                                plotID,
                                slotNumber
                            }
                            
                            local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Plot.PlotAction")
                            remote:InvokeServer(unpack(args))
                        end)
                    end)
                end
            end)
            task.wait(brainrotUpgradeDelay)
        end
    end)
end

local function stopAutoUpgradeBrainrot()
    if upgradeBrainrotThread then
        task.cancel(upgradeBrainrotThread)
        upgradeBrainrotThread = nil
    end
end

local AutoUpgradeBrainrotToggle = AutoTab:Toggle({
    Title = "Auto Upgrade Brainrots",
    Desc = "Automatically upgrade your brainrot slots",
    Default = false,
    Callback = function(state)
        autoUpgradeBrainrotEnabled = state
        
        if state then
            startAutoUpgradeBrainrot()
        else
            stopAutoUpgradeBrainrot()
        end
        
        saveConfiguration()
    end
})

-- [DIUBAH] Fungsi untuk membuat dropdown secara dinamik
local function createBrainrotUpgradeDropdown()
    local slots = getBrainrotSlots()
    local dropdownValues = {
        {Title = "All", Icon = "all-inclusive"},
        {Title = "5 Slot", Icon = "filter-5"},
        {Title = "10 Slot", Icon = "filter-10"},
    }
    
    for _, slotNumber in ipairs(slots) do
        table.insert(dropdownValues, {
            Title = "Slot " .. slotNumber, 
            Icon = "numeric-" .. slotNumber
        })
    end
    
    if BrainrotUpgradeModeDropdown then
        -- Jika dropdown sudah wujud, kemas kini nilainya
        BrainrotUpgradeModeDropdown:SetValues(dropdownValues)
    else
        -- Jika belum, buat dropdown baru
        BrainrotUpgradeModeDropdown = AutoTab:Dropdown({
            Title = "Brainrot Upgrade Mode",
            Values = dropdownValues,
            Value = "All",
            Callback = function(option)
                selectedUpgradeMode = option.Title
                saveConfiguration()
            end
        })
        -- Daftar untuk config manager
        myConfig:Register("BrainrotUpgradeMode", BrainrotUpgradeModeDropdown)
    end
end

-- [TAMBAH] Panggil fungsi ini selepas kelewatan untuk memastikan base sudah dimuatkan
task.spawn(function()
    task.wait(3) -- Tunggu 3 saat untuk base load
    createBrainrotUpgradeDropdown()
end)


-- Brainrot Upgrade Delay Slider
local BrainrotUpgradeDelaySlider = AutoTab:Slider({
    Title = "Brainrot Upgrade Delay",
    Desc = "Adjust the delay between brainrot upgrades (seconds)",
    Value = {
        Min = 0.1,
        Max = 200,
        Default = 1,
    },
    Callback = function(value)
        brainrotUpgradeDelay = value
        -- Restart auto upgrade if it's enabled to apply the new delay
        if autoUpgradeBrainrotEnabled then
            stopAutoUpgradeBrainrot()
            startAutoUpgradeBrainrot()
        end
        saveConfiguration()
    end
})

-- ==================== AUTO PLACE BRAINROT ====================
local autoPlaceBrainrotEnabled = false
local brainrotPlaceDelay = 1 -- Default delay in seconds
local brainrotThread = nil

local function startAutoPlaceBrainrot()
    if brainrotThread then task.cancel(brainrotThread) end
    
    brainrotThread = task.spawn(function()
        while autoPlaceBrainrotEnabled do
            pcall(function()
                local plotID = getPlayerPlotID()
                if not plotID then return end
                
                local slots = getBrainrotSlots()
                if #slots == 0 then return end
                
                for _, slotNumber in ipairs(slots) do
                    task.spawn(function()
                        pcall(function()
                            local args = {
                                "Place Brainrot",
                                plotID,
                                slotNumber
                            }
                            
                            local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/Plot.PlotAction")
                            remote:InvokeServer(unpack(args))
                        end)
                    end)
                end
            end)
            task.wait(brainrotPlaceDelay)
        end
    end)
end

local function stopAutoPlaceBrainrot()
    if brainrotThread then
        task.cancel(brainrotThread)
        brainrotThread = nil
    end
end

local AutoPlaceBrainrotToggle = AutoTab:Toggle({
    Title = "Auto Place Brainrots",
    Desc = "Automatically place brainrots in available slots",
    Default = false,
    Callback = function(state)
        autoPlaceBrainrotEnabled = state
        
        if state then
            startAutoPlaceBrainrot()
        else
            stopAutoPlaceBrainrot()
        end
        
        saveConfiguration()
    end
})

-- Brainrot Place Delay Slider
local BrainrotPlaceDelaySlider = AutoTab:Slider({
    Title = "Brainrot Place Delay",
    Desc = "Adjust the delay between brainrot placements (seconds)",
    Value = {
        Min = 0.1,
        Max = 450,
        Default = 1,
    },
    Callback = function(value)
        brainrotPlaceDelay = value
        -- Restart auto place if it's enabled to apply the new delay
        if autoPlaceBrainrotEnabled then
            stopAutoPlaceBrainrot()
            startAutoPlaceBrainrot()
        end
        saveConfiguration()
    end
})

-- Auto Bat Section
local auraValue = 100
local isBatAuraEnabled = false
local batAuraConnection = nil
local currentBat = nil
local originalHitboxSize = nil
local currentHitboxSize = 100 -- Cache hitbox size

-- Function to find bat in backpack or character
local function findBat()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local bat = LocalPlayer.Backpack:FindFirstChild("Basic Bat")
    if not bat then
        bat = character:FindFirstChild("Basic Bat")
    end
    return bat
end

local function cleanupBatAura()
    if batAuraConnection then
        batAuraConnection:Disconnect()
        batAuraConnection = nil
    end
    
    -- Restore original hitbox size
    if currentBat and originalHitboxSize then
        pcall(function()
            currentBat.Size = originalHitboxSize
            currentBat.Transparency = 0.5
        end)
    end
    currentBat = nil
    originalHitboxSize = nil
end

-- Function to enable Bat Aura - Using RenderStepped for silky smooth hitbox! 🎮
-- FIX: Get character reference inside the loop to handle respawns
local function enableBatAura()
    cleanupBatAura()
    
    local lastHitbox = nil
    local targetSize = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
    
    batAuraConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character -- Get fresh reference every frame
        pcall(function()
            local bat = findBat()
            if not bat then 
                lastHitbox = nil
                return 
            end
            
            local hitbox = bat:FindFirstChild("Hitbox")
            if not hitbox then 
                lastHitbox = nil
                return 
            end
            
            -- Save original size if not saved yet
            if currentBat ~= hitbox then
                currentBat = hitbox
                originalHitboxSize = hitbox.Size
                lastHitbox = nil -- Reset to force update
            end
            
            -- Update target size if changed
            local newTargetSize = Vector3.new(currentHitboxSize, currentHitboxSize, currentHitboxSize)
            if newTargetSize ~= targetSize then
                targetSize = newTargetSize
                lastHitbox = nil -- Force update
            end
            
            -- Only update if hitbox changed or size is different
            if lastHitbox ~= hitbox or hitbox.Size ~= targetSize then
                hitbox.Size = targetSize
                hitbox.Massless = true
                hitbox.CanCollide = false
                hitbox.Transparency = 0.95
                lastHitbox = hitbox
            end
        end)
    end)
end

local BatAuraToggle = AutoTab:Toggle({
    Title = "Bat Aura",
    Desc = "Increases your bat's hitbox size",
    Default = false,
    Callback = function(state)
        isBatAuraEnabled = state
        
        if state then
            enableBatAura()
        else
            cleanupBatAura()
        end
        
        saveConfiguration()
    end
})

-- Bat Aura Slider
local BatAuraSlider = AutoTab:Slider({
    Title = "Bat Aura Size",
    Desc = "Warning: Higher aura value may cause more lag!",
    Value = {
        Min = 10,
        Max = 1000,
        Default = 100,
    },
    Callback = function(value)
        auraValue = value
        currentHitboxSize = value
        if isBatAuraEnabled then
            enableBatAura() -- Re-enable to apply new size
        end
        saveConfiguration()
    end
})

-- Auto Bat Toggle
local isAutoBatEnabled = false
local autoBatConnection = nil

local function cleanupAutoBat()
    if autoBatConnection then
        autoBatConnection:Disconnect()
        autoBatConnection = nil
    end
end

-- Function to enable Auto Bat - Using RenderStepped for instant response! ⚡
-- FIX: Get character reference inside the loop to handle respawns
local function enableAutoBat()
    cleanupAutoBat()
    
    local lastEquipAttempt = 0
    local EQUIP_COOLDOWN = 0.3 -- Reduced cooldown untuk faster equip
    
    autoBatConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character -- Get fresh reference every frame
        pcall(function()
            if not character then return end
            
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            -- Check if bat is already equipped
            local equippedBat = character:FindFirstChild("Basic Bat")
            
            if equippedBat then
                -- If bat is equipped, activate it instantly
                equippedBat:Activate()
            else
                -- Only try to equip if cooldown passed
                local currentTime = tick()
                if currentTime - lastEquipAttempt >= EQUIP_COOLDOWN then
                    local backpackBat = LocalPlayer.Backpack:FindFirstChild("Basic Bat")
                    if backpackBat then
                        humanoid:EquipTool(backpackBat)
                        lastEquipAttempt = currentTime
                    end
                end
            end
        end)
    end)
end

local AutoBatToggle = AutoTab:Toggle({
    Title = "Auto Bat",
    Desc = "Automatically equip and use your bat",
    Default = false,
    Callback = function(state)
        isAutoBatEnabled = state
        
        if state then
            enableAutoBat()
        else
            cleanupAutoBat()
        end
        
        saveConfiguration()
    end
})

-- ========================================
-- VISUAL TAB ELEMENTS
-- ========================================
-- ESP Players Toggle
local espEnabled = false
local espObjects = {}
local espConnection = nil

local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        highlight = Instance.new("Highlight")
    }
    
    esp.box.Visible = false
    esp.box.Color = Color3.fromRGB(255, 0, 0) -- Red ESP
    esp.box.Thickness = 1
    esp.box.Filled = false
    esp.box.Transparency = 1
    
    esp.name.Visible = false
    esp.name.Color = Color3.fromRGB(255, 255, 255)
    esp.name.Size = 13
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Text = player.Name
    
    esp.highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red Highlight
    esp.highlight.FillTransparency = 1
    esp.highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Red Outline
    esp.highlight.OutlineTransparency = 0
    esp.highlight.Enabled = false
    
    espObjects[player] = esp
end

local function removeESP(player)
    local esp = espObjects[player]
    if esp then
        esp.box:Remove()
        esp.name:Remove()
        esp.highlight:Destroy()
        espObjects[player] = nil
    end
end

local function updateESP()
    for player, esp in pairs(espObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local hrp = player.Character.HumanoidRootPart
            
            if humanoid.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if espEnabled then
                    esp.highlight.Parent = player.Character
                    esp.highlight.Enabled = true
                    
                    if onScreen then
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height / 2
                            
                            esp.box.Size = Vector2.new(width, height)
                            esp.box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
                            esp.box.Visible = true
                            
                            esp.name.Position = Vector2.new(vector.X, vector.Y - height / 2 - 15)
                            esp.name.Visible = true
                        else
                            esp.box.Visible = false
                            esp.name.Visible = false
                        end
                    else
                        esp.box.Visible = false
                        esp.name.Visible = false
                    end
                else
                    esp.highlight.Enabled = false
                    esp.box.Visible = false
                    esp.name.Visible = false
                end
            else
                esp.highlight.Enabled = false
                esp.box.Visible = false
                esp.name.Visible = false
            end
        else
            esp.highlight.Enabled = false
            esp.box.Visible = false
            esp.name.Visible = false
        end
    end
end

local function startESP()
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
    
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)
    
    espConnection = RunService.RenderStepped:Connect(updateESP)
end

local function stopESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    
    for player, _ in pairs(espObjects) do
        removeESP(player)
    end
end

local EspPlayersToggle = VisualTab:Toggle({
    Title = "ESP Players",
    Desc = "See players through walls with boxes and highlights.",
    Default = false,
    Callback = function(state)
        espEnabled = state
        
        if state then
            startESP()
        else
            stopESP()
        end
        
        saveConfiguration()
    end
})

-- ESP Celestial Toggle
local ESPCelestialObjects = {}
local Connections = {
    ESPCelestial = nil,
    ESPLuckyBlock = nil,
}

local function createESPCelestial(part, text)
    if not part or not part:IsA("BasePart") then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_Celestial_" .. text
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = part

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.Gotham -- [DIUBAH] Tukar font ke Gotham
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboardGui

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight_Celestial_" .. text
    highlight.Adornee = part
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent = part

    table.insert(ESPCelestialObjects, billboardGui)
    table.insert(ESPCelestialObjects, highlight)
    
    return billboardGui, highlight
end

local function clearESPCelestial()
    for _, esp in pairs(ESPCelestialObjects) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    ESPCelestialObjects = {}
end

local function toggleESPCelestial(state)
    States.ESPCelestial = state
    
    if state then
        Connections.ESPCelestial = RunService.Heartbeat:Connect(function()
            if not States.ESPCelestial then return end
            
            pcall(function()
                local activeBrainrots = Workspace:FindFirstChild("ActiveBrainrots")
                if not activeBrainrots then return end
                
                local celestialFolder = activeBrainrots:FindFirstChild("Celestial")
                if not celestialFolder then return end
                
                local renderedBrainrot = celestialFolder:FindFirstChild("RenderedBrainrot")
                if not renderedBrainrot then return end
                
                local root = renderedBrainrot:FindFirstChild("Root")
                if root and not root:FindFirstChild("ESP_Celestial Brainrot") then
                    createESPCelestial(root, "Celestial Brainrot")
                end
            end)
        end)
    else
        if Connections.ESPCelestial then
            Connections.ESPCelestial:Disconnect()
            Connections.ESPCelestial = nil
        end
        clearESPCelestial()
    end
end

-- ESP Lucky Block Toggle
local ESPLuckyBlockObjects = {}

local function createESPLuckyBlock(part, text)
    if not part or not part:IsA("BasePart") then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_LuckyBlock_" .. text
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = part

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.Gotham -- [DIUBAH] Tukar font ke Gotham
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboardGui

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight_LuckyBlock_" .. text
    highlight.Adornee = part
    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green for Lucky Blocks
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent = part

    table.insert(ESPLuckyBlockObjects, billboardGui)
    table.insert(ESPLuckyBlockObjects, highlight)
    
    return billboardGui, highlight
end

local function clearESPLuckyBlock()
    for _, esp in pairs(ESPLuckyBlockObjects) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    ESPLuckyBlockObjects = {}
end

local function toggleESPLuckyBlock(state)
    States.ESPLuckyBlock = state
    
    if state then
        Connections.ESPLuckyBlock = RunService.Heartbeat:Connect(function()
            if not States.ESPLuckyBlock then return end
            
            pcall(function()
                local activeLuckyBlocks = Workspace:FindFirstChild("ActiveLuckyBlocks")
                if not activeLuckyBlocks then return end
                
                for _, block in pairs(activeLuckyBlocks:GetChildren()) do
                    if block:IsA("Model") and string.find(block.Name, "NaturalLuckyBlock") then
                        -- [DIUBAH] Tapis hanya untuk Secret dan Cosmic
                        local rarity = block.Name:match("NaturalLuckyBlock_(.+)")
                        if rarity == "Secret" or rarity == "Cosmic" then
                            local primary = block.PrimaryPart or block:FindFirstChildWhichIsA("BasePart")
                            if primary and not primary:FindFirstChild("ESP_LuckyBlock_" .. rarity) then
                                createESPLuckyBlock(primary, rarity .. " Lucky Block")
                            end
                        end
                    end
                end
            end)
        end)
    else
        if Connections.ESPLuckyBlock then
            Connections.ESPLuckyBlock:Disconnect()
            Connections.ESPLuckyBlock = nil
        end
        clearESPLuckyBlock()
    end
end

local EspCelestialToggle = VisualTab:Toggle({
    Title = "ESP Celestial",
    Desc = "Highlight all Celestial brainrots",
    Default = false,
    Callback = function(state)
        toggleESPCelestial(state)
        saveConfiguration()
    end
})

local EspLuckyBlockToggle = VisualTab:Toggle({
    Title = "ESP Lucky Block", -- [DIUBAH] Nama tetap sama untuk konsistensi
    Desc = "Highlight Secret and Cosmic Lucky Blocks only", -- [DIUBAH] Deskripsi baru
    Default = false,
    Callback = function(state)
        toggleESPLuckyBlock(state)
        saveConfiguration()
    end
})

-- ========================================
-- MISC TAB ELEMENTS
-- ========================================
-- Unlock Zoom Limit Toggle
local UnlockZoomToggle = MiscTab:Toggle({
    Title = "Unlock Zoom Limit",
    Desc = "Allows you to zoom in and out much further.",
    Default = false,
    Callback = function(state)
        if state then
            LocalPlayer.CameraMaxZoomDistance = 500
        else
            LocalPlayer.CameraMaxZoomDistance = 20 -- Reset to default Roblox value
        end
        LocalPlayer.CameraMinZoomDistance = 0.5
        saveConfiguration()
    end
})

-- Infinite Jump and Jump Boost
local isInfJumpEnabled = false
local isJumpBoostEnabled = false
local jumpBoostPower = 50
local jumpRequestConnection = nil

local function doJump()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 and rootPart then
        if isInfJumpEnabled then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        if isJumpBoostEnabled then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, jumpBoostPower, rootPart.Velocity.Z)
        end
    end
end

local function setupJumpRequest()
    if jumpRequestConnection then
        jumpRequestConnection:Disconnect()
        jumpRequestConnection = nil
    end
    
    jumpRequestConnection = UserInputService.JumpRequest:Connect(function()
        if isInfJumpEnabled or isJumpBoostEnabled then
            doJump()
        end
    end)
end

local function initializeJumpForCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    setupJumpRequest()
    
    char.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then
            setupJumpRequest()
        end
    end)
end

local function setupJumpFeatures()
    if LocalPlayer.Character then
        initializeJumpForCharacter(LocalPlayer.Character)
    end
    
    LocalPlayer.CharacterAdded:Connect(initializeJumpForCharacter)
end

local function cleanupJumpFeatures()
    if jumpRequestConnection then
        jumpRequestConnection:Disconnect()
        jumpRequestConnection = nil
    end
end

-- Infinite Jump Toggle
local InfJumpToggle = MiscTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump infinitely in mid-air",
    Default = false,
    Callback = function(state)
        isInfJumpEnabled = state
        
        if state or isJumpBoostEnabled then
            setupJumpFeatures()
        else
            cleanupJumpFeatures()
        end
        
        saveConfiguration()
    end
})

-- Jump Boost Toggle (Moved above its slider)
local JumpBoostToggle = MiscTab:Toggle({
    Title = "Jump Boost",
    Desc = "Increase your jump height",
    Default = false,
    Callback = function(state)
        isJumpBoostEnabled = state
        
        if state or isInfJumpEnabled then
            setupJumpFeatures()
        else
            cleanupJumpFeatures()
        end
        
        saveConfiguration()
    end
})

-- Jump Boost Slider (Moved below Jump Boost Toggle)
local JumpBoostSlider = MiscTab:Slider({
    Title = "Jump Boost Power",
    Desc = "Adjust the power of your jump",
    Value = {
        Min = 0,
        Max = 1000,
        Default = 50,
    },
    Callback = function(value)
        jumpBoostPower = value
        saveConfiguration()
    end
})

-- ========================================
-- EVENTS TAB ELEMENTS
-- ========================================
-- ==================== AUTO SPIN UFO WHEEL ====================
local autoSpinUFOEnabled = false
local ufoSpinDelay = 1 -- Default delay in seconds
local ufoThread = nil

local function startAutoSpinUFO()
    if ufoThread then task.cancel(ufoThread) end
    
    ufoThread = task.spawn(function()
        while autoSpinUFOEnabled do
            pcall(function()
                local args = {
                    "UFO",
                    false
                }
                local remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/WheelSpin.Roll")
                remote:InvokeServer(unpack(args))
            end)
            task.wait(ufoSpinDelay)
        end
    end)
end

local function stopAutoSpinUFO()
    if ufoThread then
        task.cancel(ufoThread)
        ufoThread = nil
    end
end

local AutoSpinUFOToggle = EventsTab:Toggle({
    Title = "Auto Spin UFO Wheel",
    Desc = "Automatically spin the UFO wheel",
    Default = false,
    Callback = function(state)
        autoSpinUFOEnabled = state
        
        if state then
            startAutoSpinUFO()
        else
            stopAutoSpinUFO()
        end
        
        saveConfiguration()
    end
})

-- UFO Spin Delay Slider
local UFOSpinDelaySlider = EventsTab:Slider({
    Title = "UFO Spin Delay",
    Desc = "Adjust the delay between UFO wheel spins (seconds)",
    Value = {
        Min = 0.1,
        Max = 500,
        Default = 1,
    },
    Callback = function(value)
        ufoSpinDelay = value
        -- Restart auto spin if it's enabled to apply the new delay
        if autoSpinUFOEnabled then
            stopAutoSpinUFO()
            startAutoSpinUFO()
        end
        saveConfiguration()
    end
})

-- ========================================
-- CREDITS TAB ELEMENTS (MOVED SERVER INFO HERE)
-- ========================================
local currentPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers or 0

local ServerInfoParagraph = CreditsTab:Paragraph({
    Title = "Server Information",
    Desc = string.format(
        "Game: %s\nPlace ID: %d\nJob ID: %s\nPlayers: %d/%d",
        game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown",
        game.PlaceId or 0,
        tostring(game.JobId or "N/A"),
        currentPlayers,
        maxPlayers
    ),
})

-- Update player count every 5 seconds
task.spawn(function()
    while true do
        task.wait(5)
        local currentPlayers = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers or 0
        
        pcall(function()
            ServerInfoParagraph:Set({
                Desc = string.format(
                    "Game: %s\nPlace ID: %d\nJob ID: %s\nPlayers: %d/%d",
                    game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown",
                    game.PlaceId or 0,
                    tostring(game.JobId or "N/A"),
                    currentPlayers,
                    maxPlayers
                )
            })
        end)
    end
end)

local CreditsButton = CreditsTab:Button({
    Title = "Copy Discord Link",
    Desc = "Click to copy our Discord server link!",
    Callback = function()
        setclipboard("https://discord.gg/XeBbhUnf")
        WindUI:Notify({
            Title = "Discord Link Copied!",
            Content = "Discord invite copied to clipboard!",
            Duration = 3,
            Icon = "check",
        })
    end
})

-- ========================================
-- SETTINGS TAB ELEMENTS
-- ========================================
local ThemeDropdown = SettingsTab:Dropdown({
    Title = "Theme Selector",
    Values = {
        {Title = "Dark", Icon = "moon"},
        {Title = "Light", Icon = "sun"},
        {Title = "Purple Dream", Icon = "sparkles"},
        {Title = "Ocean Blue", Icon = "waves"},
        {Title = "Forest Green", Icon = "tree-deciduous"},
        {Title = "Crimson Red", Icon = "flame"},
        {Title = "Sunset Orange", Icon = "sunset"},
        {Title = "Midnight Purple", Icon = "moon-star"},
        {Title = "Cyan Glow", Icon = "zap"},
        {Title = "Rose Pink", Icon = "heart"},
        {Title = "Golden Hour", Icon = "sun"},
        {Title = "Neon Green", Icon = "zap-off"},
        {Title = "Electric Blue", Icon = "sparkle"},
        {Title = "Custom", Icon = "palette"},
    },
    Value = "Dark",
    Callback = function(option)
        changeTheme(option.Title)
        saveConfiguration()
    end
})

local ThemeColorPicker = SettingsTab:Colorpicker({
    Title = "Custom Theme Color",
    Desc = "Select a custom accent color for the UI",
    Default = Color3.fromRGB(255, 0, 0), -- Default to red
    Callback = function(color)
        WindUI:AddTheme({
            Name = "Custom",
            Accent = color,
            Dialog = Color3.fromHex("#161616"),
            Outline = color,
            Text = Color3.fromHex("#FFFFFF"),
            Placeholder = Color3.fromHex("#7a7a7a"),
            Background = Color3.fromHex("#101010"),
            Button = Color3.fromHex("#52525b"),
            Icon = color
        })
        
        WindUI:SetTheme("Custom")
        States.CurrentTheme = "Custom"
        saveConfiguration()
    end
})

local SaveConfigButton = SettingsTab:Button({
    Title = "Save Configuration",
    Desc = "Manually save all your current settings.",
    Callback = function()
        saveConfiguration()
        WindUI:Notify({
            Title = "Configuration Saved",
            Content = "All your settings have been saved!",
            Duration = 3,
            Icon = "save",
        })
    end
})

local LoadConfigButton = SettingsTab:Button({
    Title = "Load Configuration",
    Desc = "Load your previously saved settings.",
    Callback = function()
        loadConfiguration()
    end
})

-- Register elements for saving/loading
myConfig:Register("UnlockZoom", UnlockZoomToggle)
myConfig:Register("ESPPlayers", EspPlayersToggle)
myConfig:Register("ESPCelestial", EspCelestialToggle)
myConfig:Register("ESPLuckyBlock", EspLuckyBlockToggle)
myConfig:Register("AutoSell", AutoSellToggle)
myConfig:Register("SellOption", SellOptionDropdown)
myConfig:Register("AutoSellDelay", AutoSellDelaySlider)
myConfig:Register("InfJump", InfJumpToggle)
myConfig:Register("JumpBoost", JumpBoostToggle)
myConfig:Register("JumpBoostPower", JumpBoostSlider)
myConfig:Register("Theme", ThemeDropdown)
myConfig:Register("ThemeColor", ThemeColorPicker)
myConfig:Register("Speed", SpeedToggle)
myConfig:Register("SpeedValue", SpeedInput)
myConfig:Register("GodMode", GodModeToggle)
myConfig:Register("AutoCollect", AutoCollectToggle)
myConfig:Register("CollectDelay", AutoCollectDelaySlider)
myConfig:Register("AutoSteal", AutoStealToggle)
myConfig:Register("Rarity", RarityDropdown)
myConfig:Register("BatAura", BatAuraToggle)
myConfig:Register("BatAuraSize", BatAuraSlider)
myConfig:Register("AutoBat", AutoBatToggle)
myConfig:Register("AutoBuySpeed", AutoBuySpeedToggle)
myConfig:Register("SpeedOption", SpeedOptionDropdown)
myConfig:Register("AutoUpgradeDelay", AutoUpgradeDelaySlider)
myConfig:Register("AutoUpgradeCarry", AutoUpgradeCarryToggle)
myConfig:Register("CarryUpgradeDelay", CarryUpgradeDelaySlider)
myConfig:Register("AutoUpgradeBase", AutoUpgradeBaseToggle)
myConfig:Register("BaseUpgradeDelay", BaseUpgradeDelaySlider)
myConfig:Register("AutoUpgradeBrainrot", AutoUpgradeBrainrotToggle)
-- myConfig:Register("BrainrotUpgradeMode", BrainrotUpgradeModeDropdown) -- [DIUBAH] Dipindahkan ke dalam fungsi dinamik
myConfig:Register("BrainrotUpgradeDelay", BrainrotUpgradeDelaySlider)
myConfig:Register("AutoPlaceBrainrot", AutoPlaceBrainrotToggle)
myConfig:Register("BrainrotPlaceDelay", BrainrotPlaceDelaySlider)
myConfig:Register("AutoSpinUFO", AutoSpinUFOToggle)
myConfig:Register("UFOSpinDelay", UFOSpinDelaySlider)

-- ========================================
-- WELCOME POPUP
-- ========================================
WindUI:Popup({
    Title = "Escape Tsunami For Brainrots",
    Icon = "cat",
    Content = "Welcome to Nightmare Hub!",
    Buttons = {
        {
            Title = "Close",
            Callback = function() end,
            Variant = "Tertiary",
        },
        {
            Title = "Join Discord",
            Icon = "users",
            Callback = function()
                setclipboard("https://discord.gg/XeBbhUnf")
                WindUI:Notify({
                    Title = "Link Copied!",
                    Content = "Discord invite copied to clipboard!",
                    Duration = 3,
                    Icon = "check",
                })
            end,
            Variant = "Primary",
        }
    }
})

loadConfiguration() -- automatically load configuration!!!

-- ========================================
-- FIX: Sync script variables with loaded UI state
-- ========================================
-- myConfig:Load() does not trigger the Dropdown Callbacks, so we need to
-- manually update our script variables to match the values loaded into the UI.

-- Sync Auto Sell option
if SellOptionDropdown and SellOptionDropdown.Value then
    selectedSellOption = SellOptionDropdown.Value
end

-- Sync Rarity option
if RarityDropdown and RarityDropdown.Value then
    selectedTier = RarityDropdown.Value
    if RARITY_TIERS[selectedTier] then
        selectedRarities = RARITY_TIERS[selectedTier]
    else
        -- If it's a specific rarity, only select that one
        selectedRarities = {selectedTier}
    end
end

-- Sync Speed Option
if SpeedOptionDropdown and SpeedOptionDropdown.Value then
    selectedSpeedOption = SpeedOptionDropdown.Value
end

-- Sync Brainrot Upgrade Mode
-- [DIUBAH] Sync mungkin tidak berfungsi dengan sempurna pada permulaan kerana dropdown dibuat dinamik
-- Ini adalah batasan yang kecil, tetapi fungsi utama tidak terjejas.
if BrainrotUpgradeModeDropdown and BrainrotUpgradeModeDropdown.Value then
    selectedUpgradeMode = BrainrotUpgradeModeDropdown.Value
end


-- ========================================
-- END OF FIX
-- ========================================

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    
    if isSpeedEnabled then
        enableSpeed()
    end
    if isGodModeEnabled then
        enableGodMode()
    end
    if isAutoStealEnabled then
        enableAutoSteal()
    end
    if isAutoBatEnabled then
        enableAutoBat()
    end
    if isBatAuraEnabled then
        enableBatAura()
    end
    if isInfJumpEnabled or isJumpBoostEnabled then
        setupJumpFeatures()
    end
end)

-- Keyboard shortcut for Fly to Base
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.B then
        flyToBase()
    end
end)

-- Cleanup on character death
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        cleanupFlyToBase()
    end)
end)

MainTab:Select() -- Always select the MainTab/First tab created!!!
