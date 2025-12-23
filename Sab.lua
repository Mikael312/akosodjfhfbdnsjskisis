--[[
    NIGHTMARE HUB 🎮 (Library Version - Updated)
    All functions from the original script, now integrated with NightmareLib.
    - "Respawn Desync" changed to "Use Cloner"
    - "Unwalk Animation" changed to "Admin Panel Spammer"
    - Added "Silent Hit" to Misc tab
    - Replaced "Esp Best" with "Brainrot ESP V3" (Module-Based Calculation)
    - "Instant Grab" function updated to "Instant Pickup" logic for better range and reliability.
    - "Anti Trap" feature has been removed.
    - Added "Unlock Floor" to Main tab.
    - [FIXED] ESP Base Timer flickering issue.
    - [FIXED] Instant Grab performance drop (FPS).
    - [UPDATED] Base Line now targets the "PlotSign" in the player's plot.
    - [ADDED] "Unwalk Anim" toggle to the Misc tab.
    - [ADDED] "God Mode" toggle to the Misc tab.
    - [ADDED] "Auto Destroy Sentry" (External Load) to Main tab.
]]

-- ==================== LOAD LIBRARY ====================
local success, NightmareHub = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/Nightmare-Library/refs/heads/main/NightmareLib.lua"))()
end)

if not success then
    warn("❌ Failed to load NightmareHub library!")
    return
end

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService") -- Added for Brainrot ESP V3

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer

-- Platform variables
local platformEnabled = false
local platformPart = nil
local platformConnection = nil

-- Xray Base variables
local xrayBaseEnabled = false
local originalTransparency = {}

-- Brainrot ESP V3 variables (NEW - REPLACING Esp Best)
local highestValueESP = nil
local highestValueData = nil
local espEnabled = false
local autoUpdateThread = nil
local tracerAttachment0 = nil
local tracerAttachment1 = nil
local tracerBeam = nil
local tracerConnection = nil

-- ESP Base Timer variables
local espBaseTimerEnabled = false
local espBaseTimerConnection = nil

-- Grapple Speed variables
local grappleSpeedEnabled = false
local grappleSpeedScript = nil

-- Anti Knockback Variables
local antiKnockbackEnabled = false
local antiKnockbackConn = nil
local lastSafeVelocity = Vector3.new(0, 0, 0)
local VELOCITY_THRESHOLD = 35
local UPDATE_INTERVAL = 0.016

-- Anti Ragdoll Variables
local isAntiRagdollEnabled = false
local antiRagdollConnections = {}
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false

-- Invisible V1 Variables
local connections = {
    SemiInvisible = {}
}
local isInvisible = false
local clone, oldRoot, hip, animTrack, connection, characterConnection

-- Auto Kick After Steal Variables
local isMonitoring = false
local lastStealCount = 0
local monitoringLoop = nil

-- Instant Grab Variables
local instantGrabEnabled = false
local instantGrabThread = nil

-- Touch Fling V2 Variables
local touchFlingEnabled = false
local touchFlingConnection = nil

-- Allow Friends Variables
local allowFriendsEnabled = false

-- Baselock Reminder Variables
local baselockReminderEnabled = false
local baselockAlertGui = nil
local baselockConnection = nil
local bellSoundPlayed = false
local currentBellSound = nil
local BELL_SOUND_ID = "rbxassetid://3302969109"

-- ESP Players Variables
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil

-- Laser Cape (Aimbot) Variables
local autoLaserEnabled = false
local autoLaserThread = nil

-- ESP Turret Variables
local sentryESPEnabled = false
local trackedSentries = {}
local scanConnection = nil

-- Base Line Variables
local baseLineEnabled = false
local baseLineConnection = nil
local baseBeamPart = nil
local baseTargetPart = nil
local baseBeam = nil

-- Anti Debuff Variables
local antiBeeEnabled = false
local antiBoogieEnabled = false
local isEventHandlerActive = false
local unifiedConnection = nil
local originalConnections = {}
local heartbeatConnection = nil
local animationPlayedConnection = nil
local BOOGIE_ANIMATION_ID = "109061983885712"

-- Unwalk Anim Variables (NEW)
local unwalkAnimEnabled = false

-- God Mode Variables (NEW)
local godModeEnabled = false
local healthConnection = nil
local stateConnection = nil
local initialMaxHealth = 100

-- ==================== ALL FEATURE FUNCTIONS ====================

-- ==================== PLATFORM FUNCTION ====================
local function createPlatform()
    if platformPart then return end
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    platformPart = Instance.new("Part")
    platformPart.Name = "NightmareHubPlatform"
    platformPart.Size = Vector3.new(10, 1, 10)
    platformPart.Anchored = true
    platformPart.CanCollide = true
    platformPart.Transparency = 0.5
    platformPart.BrickColor = BrickColor.new("Really red")
    platformPart.Material = Enum.Material.Neon
    platformPart.TopSurface = Enum.SurfaceType.Smooth
    platformPart.BottomSurface = Enum.SurfaceType.Smooth
    
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(255, 0, 0)
    glow.Range = 20
    glow.Brightness = 2
    glow.Parent = platformPart
    
    platformPart.Position = Vector3.new(rootPart.Position.X, rootPart.Position.Y - 3, rootPart.Position.Z)
    platformPart.Parent = Workspace
    
    platformConnection = RunService.Heartbeat:Connect(function()
        if platformPart and platformPart.Parent and character and character.Parent then
            local newRootPart = character:FindFirstChild("HumanoidRootPart")
            if newRootPart then
                platformPart.Position = Vector3.new(newRootPart.Position.X, newRootPart.Position.Y - 3, newRootPart.Position.Z)
            end
        else
            if platformConnection then platformConnection:Disconnect(); platformConnection = nil end
        end
    end)
    print("✅ Platform Created")
end

local function removePlatform()
    if platformPart then platformPart:Destroy(); platformPart = nil end
    if platformConnection then platformConnection:Disconnect(); platformConnection = nil end
    print("❌ Platform Removed")
end

local function togglePlatform(state)
    platformEnabled = state
    if platformEnabled then createPlatform() else removePlatform() end
end

-- ==================== XRAY BASE FUNCTION ====================
local function saveOriginalTransparency()
    originalTransparency = {}
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            for _, part in pairs(plot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency
                end
            end
        end
    end
end

local function applyTransparency()
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            for _, part in pairs(plot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    if originalTransparency[part] == nil then originalTransparency[part] = part.Transparency end
                    part.Transparency = 0.5
                end
            end
        end
    end
end

local function restoreTransparency()
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            for _, part in pairs(plot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    if originalTransparency[part] ~= nil then part.Transparency = originalTransparency[part] end
                end
            end
        end
    end
end

local function toggleXrayBase(enabled)
    xrayBaseEnabled = enabled
    if xrayBaseEnabled then saveOriginalTransparency(); applyTransparency(); print("✓ Xray Base: ON")
    else restoreTransparency(); print("✗ Xray Base: OFF") end
end

-- Monitor for new plots
local plots = workspace:FindFirstChild("Plots")
if plots then
    plots.ChildAdded:Connect(function(newPlot)
        task.wait(0.5)
        if xrayBaseEnabled then
            for _, part in pairs(newPlot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency; part.Transparency = 0.5
                end
            end
        else
            for _, part in pairs(newPlot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency
                end
            end
        end
    end)
end

-- ==================== BRAINROT ESP V3 FUNCTION (NEW - REPLACING Esp Best) ====================
-- Module loading
local AnimalsModule, TraitsModule, MutationsModule

pcall(function()
    AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    TraitsModule = require(ReplicatedStorage.Datas.Traits)
    MutationsModule = require(ReplicatedStorage.Datas.Mutations)
end)

-- Helper function to get trait multiplier
local function getTraitMultiplier(model)
    if not TraitsModule then return 0 end
    
    local traitJson = model:GetAttribute("Traits")
    if not traitJson or traitJson == "" then
        return 0
    end

    local traits = {}
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(traitJson)
    end)

    if ok and typeof(decoded) == "table" then
        traits = decoded
    else
        for t in string.gmatch(traitJson, "[^,]+") do
            table.insert(traits, t)
        end
    end

    local mult = 0
    for _, entry in pairs(traits) do
        local name = typeof(entry) == "table" and entry.Name or tostring(entry)
        name = name:gsub("^_Trait%.", "")

        local trait = TraitsModule[name]
        if trait and trait.MultiplierModifier then
            mult += tonumber(trait.MultiplierModifier) or 0
        end
    end

    return mult
end

-- Helper function to calculate final generation
local function getFinalGeneration(model)
    if not AnimalsModule then return 0 end
    
    local animalData = AnimalsModule[model.Name]
    if not animalData then return 0 end

    local baseGen = tonumber(animalData.Generation) or tonumber(animalData.Price or 0)

    local traitMult = getTraitMultiplier(model)

    local mutationMult = 0
    if MutationsModule then
        local mutation = model:GetAttribute("Mutation")
        if mutation and MutationsModule[mutation] then
            mutationMult = tonumber(MutationsModule[mutation].Modifier or 0)
        end
    end

    local final = baseGen * (1 + traitMult + mutationMult)
    return math.max(1, math.round(final))
end

-- Format number jadi readable (34M/s, 1.2B/s, etc)
local function formatNumber(num)
    local value, suffix
    
    if num >= 1e12 then
        value = num / 1e12
        suffix = "T/s"
    elseif num >= 1e9 then
        value = num / 1e9
        suffix = "B/s"
    elseif num >= 1e6 then
        value = num / 1e6
        suffix = "M/s"
    elseif num >= 1e3 then
        value = num / 1e3
        suffix = "K/s"
    else
        return string.format("%.0f/s", num)
    end
    
    -- Check kalau whole number
    if value == math.floor(value) then
        return string.format("%.0f%s", value, suffix)
    else
        return string.format("%.1f%s", value, suffix)
    end
end

-- Check if plot belongs to player
local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local yourBase = plotSign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then
            return true
        end
    end
    return false
end

-- Find the highest value brainrot
local function findHighestBrainrot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local highest = {value = 0}
    local totalPlotsScanned = 0
    local totalAnimalsFound = 0
    
    print("========== SCANNING ALL PLOTS (NEW SYSTEM) ==========")
    
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            totalPlotsScanned = totalPlotsScanned + 1
            
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("Model") and AnimalsModule and AnimalsModule[obj.Name] then
                    pcall(function()
                        local gen = getFinalGeneration(obj)
                        
                        if gen > 0 then
                            totalAnimalsFound = totalAnimalsFound + 1
                            
                            print(string.format("🔍 Plot: %s | Animal: %s | Value: %s", 
                                plot.Name, obj.Name, formatNumber(gen)))
                            
                            if gen > highest.value then
                                print(string.format("   ✅ NEW HIGHEST! (%d > %d)", gen, highest.value))
                                
                                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                
                                if root then
                                    highest = {
                                        plot = plot,
                                        plotName = plot.Name,
                                        petName = obj.Name,
                                        generation = gen,
                                        formattedValue = formatNumber(gen),
                                        model = obj,
                                        value = gen
                                    }
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
    
    print(string.format("📊 SCAN STATS: Plots: %d | Animals: %d", 
        totalPlotsScanned, totalAnimalsFound))
    
    if highest.value > 0 then
        print(string.format("========== FINAL: %s at Plot %s (Value: %s) ==========", 
            highest.petName, highest.plotName, formatNumber(highest.value)))
    else
        print("========== NO ANIMALS FOUND ==========")
    end
    
    return highest.value > 0 and highest or nil
end

-- Create ESP with box highlight + red podium outline
local function createHighestValueESP(brainrotData)
    if not brainrotData or not brainrotData.model then return end
    
    pcall(function()
        if highestValueESP then
            if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
            if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
            if highestValueESP.boxAdornment then highestValueESP.boxAdornment:Destroy() end
            if highestValueESP.podiumHighlight then highestValueESP.podiumHighlight:Destroy() end
        end
        
        local espContainer = {}
        local model = brainrotData.model
        local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA('BasePart')
        
        if not part then return end
        
        -- Highlight (RED)
        local highlight = Instance.new("Highlight", model)
        highlight.Name = "BrainrotESPHighlight"
        highlight.Adornee = model
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espContainer.highlight = highlight
        
        -- BOX HIGHLIGHT
        local boxAdornment = Instance.new("BoxHandleAdornment")
        boxAdornment.Name = "BrainrotBoxHighlight"
        boxAdornment.Adornee = part
        boxAdornment.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
        boxAdornment.Color3 = Color3.fromRGB(255, 0, 0)
        boxAdornment.Transparency = 0.7
        boxAdornment.AlwaysOnTop = true
        boxAdornment.ZIndex = 1
        boxAdornment.Parent = part
        espContainer.boxAdornment = boxAdornment
        
        -- RED OUTLINE untuk PODIUM
        local plot = brainrotData.plot
        if plot then
            local podium = plot:FindFirstChild("Podium") or plot:FindFirstChild("Platform") or plot:FindFirstChild("Base")
            if podium and podium:IsA("BasePart") then
                local podiumHighlight = Instance.new("Highlight")
                podiumHighlight.Name = "PodiumOutline"
                podiumHighlight.Adornee = podium
                podiumHighlight.FillColor = Color3.fromRGB(255, 0, 0)
                podiumHighlight.FillTransparency = 0.9
                podiumHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                podiumHighlight.OutlineTransparency = 0
                podiumHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                podiumHighlight.Parent = podium
                espContainer.podiumHighlight = podiumHighlight
            end
        end
        
        -- Billboard with CENTERED text
        local billboard = Instance.new("BillboardGui", part)
        billboard.Size = UDim2.new(0, 220, 0, 80)
        billboard.StudsOffset = Vector3.new(0, 8, 0)
        billboard.AlwaysOnTop = true
        
        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        
        -- Pet Name Label (CENTERED)
        local petNameLabel = Instance.new("TextLabel", container)
        petNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = brainrotData.petName or "Unknown"
        petNameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        petNameLabel.TextStrokeTransparency = 0
        petNameLabel.TextScaled = true
        petNameLabel.Font = Enum.Font.Arcade
        petNameLabel.TextXAlignment = Enum.TextXAlignment.Center
        petNameLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        -- Generation Label (CENTERED) - Format jadi M/s, B/s
        local genLabel = Instance.new("TextLabel", container)
        genLabel.Size = UDim2.new(1, 0, 0.5, 0)
        genLabel.Position = UDim2.new(0, 0, 0.5, 0)
        genLabel.BackgroundTransparency = 1
        genLabel.Text = brainrotData.formattedValue or formatNumber(brainrotData.generation or 0)
        genLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        genLabel.TextStrokeTransparency = 0
        genLabel.TextScaled = true
        genLabel.Font = Enum.Font.Arcade
        genLabel.TextXAlignment = Enum.TextXAlignment.Center
        genLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        espContainer.nameLabel = billboard
        
        highestValueESP = espContainer
        highestValueData = brainrotData
    end)
end

-- Check if pet still exists
local function checkPetExists()
    if not highestValueData then return false end
    
    local exists = false
    pcall(function()
        local model = highestValueData.model
        if model and model.Parent then
            exists = true
        end
    end)
    
    return exists
end

-- TRACER LINE
local function createTracerLine()
    if not highestValueData or not highestValueData.model then return false end
    
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local targetPart = highestValueData.model.PrimaryPart or highestValueData.model:FindFirstChild("HumanoidRootPart") or highestValueData.model:FindFirstChildWhichIsA('BasePart')
    if not targetPart then return false end
    
    pcall(function()
        if tracerConnection then tracerConnection:Disconnect() end
        if tracerBeam then tracerBeam:Destroy() end
        if tracerAttachment0 then tracerAttachment0:Destroy() end
        if tracerAttachment1 then tracerAttachment1:Destroy() end
        
        tracerAttachment0 = Instance.new("Attachment")
        tracerAttachment0.Name = "Att0"
        tracerAttachment0.Parent = rootPart
        
        tracerAttachment1 = Instance.new("Attachment")
        tracerAttachment1.Name = "Att1"
        tracerAttachment1.Parent = targetPart
        
        tracerBeam = Instance.new("Beam")
        tracerBeam.Name = "TracerBeam"
        tracerBeam.Attachment0 = tracerAttachment0
        tracerBeam.Attachment1 = tracerAttachment1
        tracerBeam.FaceCamera = true
        tracerBeam.Width0 = 0.3
        tracerBeam.Width1 = 0.3
        tracerBeam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
        tracerBeam.Transparency = NumberSequence.new(0)
        tracerBeam.LightEmission = 1
        tracerBeam.LightInfluence = 0
        tracerBeam.Brightness = 3
        tracerBeam.Parent = rootPart
        
        local pulseTime = 0
        tracerConnection = RunService.Heartbeat:Connect(function(dt)
            if tracerBeam and tracerBeam.Parent and espEnabled then
                pulseTime = pulseTime + dt
                
                local pulse = (math.sin(pulseTime * 3) + 1) / 2
                local r = 230 + (25 * pulse)
                tracerBeam.Color = ColorSequence.new(Color3.fromRGB(r, 0, 0))
                
                local width = 0.25 + (0.15 * pulse)
                tracerBeam.Width0 = width
                tracerBeam.Width1 = width
                
                if targetPart and targetPart.Parent and tracerAttachment1 then
                    tracerAttachment1.Parent = targetPart
                end
            else
                if tracerConnection then
                    tracerConnection:Disconnect()
                end
            end
        end)
        
        print("✅ Tracer line created!")
    end)
    
    return true
end

local function removeTracerLine()
    if tracerConnection then tracerConnection:Disconnect(); tracerConnection = nil end
    if tracerBeam then tracerBeam:Destroy(); tracerBeam = nil end
    if tracerAttachment0 then tracerAttachment0:Destroy(); tracerAttachment0 = nil end
    if tracerAttachment1 then tracerAttachment1:Destroy(); tracerAttachment1 = nil end
end

-- Update the highest value ESP
local function updateHighestValueESP()
    if highestValueData and not checkPetExists() then
        print("⚠️ Current pet removed, searching for new highest value...")
        if highestValueESP then
            if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
            if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
            if highestValueESP.boxAdornment then highestValueESP.boxAdornment:Destroy() end
            if highestValueESP.podiumHighlight then highestValueESP.podiumHighlight:Destroy() end
        end
        highestValueESP = nil
        highestValueData = nil
        removeTracerLine()
    end
    
    local newHighest = findHighestBrainrot()
    
    if newHighest then
        if not highestValueData or newHighest.value > highestValueData.value then
            createHighestValueESP(newHighest)
            
            if espEnabled then
                createTracerLine()
            end
            
            return newHighest
        end
    end
    
    return highestValueData
end

-- Remove the highest value ESP
local function removeHighestValueESP()
    if highestValueESP then
        pcall(function()
            if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
            if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
            if highestValueESP.boxAdornment then highestValueESP.boxAdornment:Destroy() end
            if highestValueESP.podiumHighlight then highestValueESP.podiumHighlight:Destroy() end
        end)
        highestValueESP = nil
        highestValueData = nil
    end
    
    removeTracerLine()
end

-- Toggle the Brainrot ESP V3
local function toggleEspBest(enabled)
    espEnabled = enabled
    
    if espEnabled then
        updateHighestValueESP()
        
        if autoUpdateThread then
            task.cancel(autoUpdateThread)
        end
        
        autoUpdateThread = task.spawn(function()
            while espEnabled do
                task.wait(1)
                updateHighestValueESP()
            end
        end)
        
        print("✅ Brainrot ESP V3: ON")
    else
        removeHighestValueESP()
        
        if autoUpdateThread then
            task.cancel(autoUpdateThread)
            autoUpdateThread = nil
        end
        
        print("❌ Brainrot ESP V3: OFF")
    end
end

-- ==================== ESP BASE TIMER FUNCTION (FIXED) ====================
local function toggleEspBaseTimer(state)
    espBaseTimerEnabled = state
    if espBaseTimerEnabled then
        if espBaseTimerConnection then espBaseTimerConnection:Disconnect(); espBaseTimerConnection = nil end
        local Plots = Workspace:FindFirstChild('Plots')
        local function getOrCreateTimerGui(main)
            if not main then return nil end
            local existing = main:FindFirstChild('GlobalTimerGui')
            if existing and existing:FindFirstChild('Label') then return existing.Label end
            local gui = Instance.new('BillboardGui'); gui.Name = 'GlobalTimerGui'; gui.Size = UDim2.new(0, 100, 0, 50)
            gui.StudsOffset = Vector3.new(0, 5, 0); gui.AlwaysOnTop = true; gui.Parent = main
            local lbl = Instance.new('TextLabel'); lbl.Name = 'Label'; lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(255, 50, 50); lbl.Font = Enum.Font.Arcade; lbl.TextScaled = true; lbl.Text = '0'
            lbl.TextStrokeTransparency = 0.5; lbl.TextStrokeColor3 = Color3.new(0, 0, 0); lbl.Parent = gui; return lbl
        end
        local function findLowestFloor(purchases)
            local lowestFloor, lowestY = nil, math.huge
            for _, child in pairs(purchases:GetChildren()) do
                local main = child:FindFirstChild('Main')
                if main then
                    local lowestPart = nil
                    if main:IsA('Model') then for _, part in pairs(main:GetDescendants()) do if part:IsA('BasePart') and (not lowestPart or part.Position.Y < lowestPart.Position.Y) then lowestPart = part end end
                    elseif main:IsA('BasePart') then lowestPart = main end
                    if lowestPart and lowestPart.Position.Y < lowestY then lowestY = lowestPart.Position.Y; lowestFloor = child end
                end
            end
            return lowestFloor
        end
        espBaseTimerConnection = RunService.RenderStepped:Connect(function()
            if not Plots then Plots = Workspace:FindFirstChild('Plots'); if not Plots then return end end
            for _, plot in pairs(Plots:GetChildren()) do
                local purchases = plot:FindFirstChild('Purchases')
                if purchases then
                    local lowestFloor = findLowestFloor(purchases)
                    if lowestFloor then
                        local main = lowestFloor:FindFirstChild('Main')
                        if main then
                            local remainingTime
                            for _, obj in pairs(main:GetDescendants()) do if obj:IsA('TextLabel') and obj.Name == 'RemainingTime' then remainingTime = obj; break end end
                            local timerLabel = getOrCreateTimerGui(main)
                            if remainingTime then
                                local currentText = remainingTime.Text or '0'
                                local numeric = tonumber(currentText)
                                -- *** FIX: Simplified logic to prevent flickering ***
                                if numeric and numeric <= 0 then
                                    timerLabel.Text = 'UNLOCKED'
                                    timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                else
                                    timerLabel.Text = currentText
                                    timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                                end
                            else
                                timerLabel.Text = 'UNLOCKED'
                                timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            end
                        end
                    end
                end
            end
        end)
        print("✅ ESP Base Timer: ON")
    else
        if espBaseTimerConnection then espBaseTimerConnection:Disconnect(); espBaseTimerConnection = nil end
        for _, plot in pairs(Workspace:FindFirstChild('Plots') and Workspace.Plots:GetChildren() or {}) do
            local purchases = plot:FindFirstChild('Purchases')
            if purchases then for _, child in pairs(purchases:GetChildren()) do local main = child:FindFirstChild('Main'); if main then local gui = main:FindFirstChild('GlobalTimerGui'); if gui then gui:Destroy() end end end end
        end
        print("❌ ESP Base Timer: OFF")
    end
end

-- ==================== GRAPPLE SPEED FUNCTION ====================
local function loadGrappleSpeed()
    if grappleSpeedEnabled then return end
    pcall(function()
        grappleSpeedScript = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/NorthHub/refs/heads/main/GrappleSpeed.lua"))()
        grappleSpeedEnabled = true; print("✅ Grapple Speed: ON")
    end)
end

local function unloadGrappleSpeed()
    if not grappleSpeedEnabled then return end
    grappleSpeedEnabled = false
    pcall(function() if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end end)
    print("❌ Grapple Speed: OFF")
end

local function toggleGrappleSpeed(state)
    if state then loadGrappleSpeed() else unloadGrappleSpeed() end
end

-- ==================== ANTI KNOCKBACK FUNCTION ====================
local function startNoKnockback()
    local char = player.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    if antiKnockbackConn then antiKnockbackConn:Disconnect() end
    lastSafeVelocity = hrp.Velocity; local lastCheck = tick(); local lastPosition = hrp.Position
    antiKnockbackConn = game:GetService("RunService").Heartbeat:Connect(function()
        local now = tick(); if now - lastCheck < UPDATE_INTERVAL then return end; lastCheck = now
        local currentVel = hrp.Velocity; local currentPos = hrp.Position; local positionChange = (currentPos - lastPosition).Magnitude; lastPosition = currentPos
        local horizontalSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
        local lastHorizontalSpeed = Vector3.new(lastSafeVelocity.X, 0, lastSafeVelocity.Z).Magnitude; local isKnockback = false
        if horizontalSpeed > VELOCITY_THRESHOLD and horizontalSpeed > lastHorizontalSpeed * 4 then isKnockback = true end
        if math.abs(currentVel.Y) > 70 then isKnockback = true end
        if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then isKnockback = true end
        if positionChange > 10 and horizontalSpeed > 50 then isKnockback = true end
        if isKnockback then
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.GettingUp); task.wait(0.1) end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new(0, 0, 0); part.RotVelocity = Vector3.new(0, 0, 0)
                    for _, force in ipairs(part:GetChildren()) do if force:IsA("BodyVelocity") or force:IsA("BodyForce") or force:IsA("BodyAngularVelocity") or force:IsA("BodyGyro") then force:Destroy() end end
                end
            end
            hum.PlatformStand = false; hum.AutoRotate = true; lastSafeVelocity = Vector3.new(0, 0, 0); print("[ANTI-KB] Knockback blocked! Speed: " .. math.floor(horizontalSpeed))
        else
            local stable = hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.FallingDown and hum:GetState() ~= Enum.HumanoidStateType.Ragdoll
            if stable and horizontalSpeed < VELOCITY_THRESHOLD then lastSafeVelocity = currentVel end
        end
    end)
end

local function stopNoKnockback()
    if antiKnockbackConn then antiKnockbackConn:Disconnect(); antiKnockbackConn = nil end
end

local function toggleAntiKnockback(state)
    antiKnockbackEnabled = state
    if antiKnockbackEnabled then startNoKnockback(); print("✅ Anti Knockback: ON") else stopNoKnockback(); print("❌ Anti Knockback: OFF") end
end

player.CharacterAdded:Connect(function(newCharacter) if antiKnockbackEnabled then task.wait(1); startNoKnockback(); print("🔄 Reloaded anti-knockback after respawn") end end)

-- ==================== ANTI RAGDOLL FUNCTION ====================
local function stopRagdoll()
    if not ragdollActive then return end
    ragdollActive = false; local char, hum, root = player.Character, player.Character:FindFirstChildOfClass("Humanoid"), player.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    hum:ChangeState(Enum.HumanoidStateType.GettingUp); hum.PlatformStand = false; root.CanCollide = true; if root.Anchored then root.Anchored = false end
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then for _, c in part:GetChildren() do if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then c:Destroy() end end; local motor = part:FindFirstChildWhichIsA("Motor6D"); if motor then motor.Enabled = true end
        end
    end
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0); root.RotVelocity = Vector3.new(0, 0, 0); workspace.CurrentCamera.CameraSubject = hum
end

local function startRagdollTimer()
    if ragdollTimer then ragdollTimer:Disconnect() end
    ragdollActive = true; ragdollTimer = RunService.Heartbeat:Connect(function() ragdollTimer:Disconnect(); ragdollTimer = nil; stopRagdoll() end)
end

local function watchHumanoidStates(char)
    local hum = char:WaitForChild("Humanoid")
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() end
    humanoidWatchConnection = hum.StateChanged:Connect(function(_, newState)
        if not isAntiRagdollEnabled then return end
        if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Physics then
            if not ragdollActive then hum.PlatformStand = true; startRagdollTimer() end
        elseif newState == Enum.HumanoidStateType.GettingUp or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
            hum.PlatformStand = false; if ragdollActive then stopRagdoll() end
        end
    end)
end

local function setupAntiRagdollCharacter(char)
    ragdollActive = false; if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    char:WaitForChild("Humanoid"); char:WaitForChild("HumanoidRootPart"); watchHumanoidStates(char)
end

local function startAntiRagdoll()
    isAntiRagdollEnabled = true
    for _, conn in pairs(antiRagdollConnections) do if conn then conn:Disconnect() end end; table.clear(antiRagdollConnections)
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect(); humanoidWatchConnection = nil end
    if player.Character then setupAntiRagdollCharacter(player.Character) end
    table.insert(antiRagdollConnections, player.CharacterAdded:Connect(setupAntiRagdollCharacter))
end

local function stopAntiRagdoll()
    isAntiRagdollEnabled = false; ragdollActive = false; if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    for _, conn in pairs(antiRagdollConnections) do if conn then conn:Disconnect() end end; table.clear(antiRagdollConnections)
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect(); humanoidWatchConnection = nil end
end

local function toggleAntiRagdoll(state)
    if state then startAntiRagdoll(); print("✅ Anti Ragdoll: ON") else stopAntiRagdoll(); print("❌ Anti Ragdoll: OFF") end
end

player.CharacterAdded:Connect(function(newCharacter) if isAntiRagdollEnabled then task.wait(0.5); setupAntiRagdollCharacter(newCharacter); print("🔄 Reloaded anti-ragdoll after respawn") end end)

-- ==================== INVISIBLE V1 FUNCTION ====================
local function removeFolders()
    local playerName = player.Name; local playerFolder = Workspace:FindFirstChild(playerName)
    if not playerFolder then return end
    local doubleRig = playerFolder:FindFirstChild("DoubleRig"); if doubleRig then doubleRig:Destroy() end
    local constraints = playerFolder:FindFirstChild("Constraints"); if constraints then constraints:Destroy() end
    local childAddedConn = playerFolder.ChildAdded:Connect(function(child) if child.Name == "DoubleRig" or child.Name == "Constraints" then child:Destroy() end end)
    table.insert(connections.SemiInvisible, childAddedConn)
end

local function doClone()
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        hip = player.Character.Humanoid.HipHeight; oldRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not oldRoot or not oldRoot.Parent then return false end
        local tempParent = Instance.new("Model"); tempParent.Parent = game; player.Character.Parent = tempParent
        clone = oldRoot:Clone(); clone.Parent = player.Character; oldRoot.Parent = game.Workspace.CurrentCamera
        clone.CFrame = oldRoot.CFrame; player.Character.PrimaryPart = clone; player.Character.Parent = game.Workspace
        for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("Weld") or v:IsA("Motor6D") then if v.Part0 == oldRoot then v.Part0 = clone end; if v.Part1 == oldRoot then v.Part1 = clone end end end
        tempParent:Destroy(); return true
    end
    return false
end

local function revertClone()
    if not oldRoot or not oldRoot:IsDescendantOf(game.Workspace) or not player.Character or player.Character.Humanoid.Health <= 0 then return false end
    local tempParent = Instance.new("Model"); tempParent.Parent = game; player.Character.Parent = tempParent; oldRoot.Parent = player.Character
    player.Character.PrimaryPart = oldRoot; player.Character.Parent = game.Workspace; oldRoot.CanCollide = true
    for _, v in pairs(player.Character:GetDescendants()) do if v:IsA("Weld") or v:IsA("Motor6D") then if v.Part0 == clone then v.Part0 = oldRoot end; if v.Part1 == clone then v.Part1 = oldRoot end end end
    if clone then local oldPos = clone.CFrame; clone:Destroy(); clone = nil; oldRoot.CFrame = oldPos end
    oldRoot = nil; if player.Character and player.Character.Humanoid then player.Character.Humanoid.HipHeight = hip end
end

local function animationTrickery()
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        local anim = Instance.new("Animation"); anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
        local humanoid = player.Character.Humanoid; local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
        animTrack = animator:LoadAnimation(anim); animTrack.Priority = Enum.AnimationPriority.Action4; animTrack:Play(0, 1, 0); anim:Destroy()
        local animStoppedConn = animTrack.Stopped:Connect(function() if isInvisible then animationTrickery() end end)
        table.insert(connections.SemiInvisible, animStoppedConn)
        task.delay(0, function() animTrack.TimePosition = 0.7; task.delay(1, function() animTrack:AdjustSpeed(math.huge) end) end)
    end
end

local function enableInvisibility()
    if not player.Character or player.Character.Humanoid.Health <= 0 then return false end
    removeFolders(); local success = doClone()
    if success then
        task.wait(0.1); animationTrickery()
        connection = RunService.PreSimulation:Connect(function(dt)
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and oldRoot then
                local root = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
                if root then local cf = root.CFrame - Vector3.new(0, player.Character.Humanoid.HipHeight + (root.Size.Y / 2) - 1 + 0.09, 0); oldRoot.CFrame = cf * CFrame.Angles(math.rad(180), 0, 0); oldRoot.Velocity = root.Velocity; oldRoot.CanCollide = false end
            end
        end)
        table.insert(connections.SemiInvisible, connection)
        characterConnection = player.CharacterAdded:Connect(function(newChar)
            if isInvisible then if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end; if connection then connection:Disconnect() end; revertClone(); removeFolders(); isInvisible = false; for _, conn in ipairs(connections.SemiInvisible) do if conn then conn:Disconnect() end end; connections.SemiInvisible = {} end
        end)
        table.insert(connections.SemiInvisible, characterConnection); return true
    end
    return false
end

local function disableInvisibility()
    if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
    if connection then connection:Disconnect() end; if characterConnection then characterConnection:Disconnect() end; revertClone(); removeFolders()
end

local function setupGodmode()
    local char = player.Character or player.CharacterAdded:Wait(); local hum = char:WaitForChild("Humanoid")
    local mt = getrawmetatable(game); local oldNC = mt.__namecall; local oldNI = mt.__newindex; setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if self == hum then if m == "ChangeState" and select(1, ...) == Enum.HumanoidStateType.Dead then return end; if m == "SetStateEnabled" then local st, en = ...; if st == Enum.HumanoidStateType.Dead and en == true then return end end; if m == "Destroy" then return end end
        if self == char and m == "BreakJoints" then return end
        return oldNC(self, ...)
    end)
    mt.__newindex = newcclosure(function(self, k, v)
        if self == hum then if k == "Health" and type(v) == "number" and v <= 0 then return end; if k == "MaxHealth" and type(v) == "number" and v < hum.MaxHealth then return end; if k == "BreakJointsOnDeath" and v == true then return end; if k == "Parent" and v == nil then return end end
        return oldNI(self, k, v)
    end)
    setreadonly(mt, true)
end

local function toggleInvisibleV1(state)
    if state then
        if not isInvisible then removeFolders(); setupGodmode(); if enableInvisibility() then isInvisible = true; print("✅ Semi Invisible: ON") end
    end
    else if isInvisible then disableInvisibility(); isInvisible = false; for _, conn in ipairs(connections.SemiInvisible) do if conn then conn:Disconnect() end end; connections.SemiInvisible = {}; print("❌ Semi Invisible: OFF") end end
end

-- ==================== AUTO KICK AFTER STEAL FUNCTION ====================
local function getStealCount()
    local success, result = pcall(function()
        if not player or not player:FindFirstChild("leaderstats") then return 0 end
        local stealsObject = player.leaderstats:FindFirstChild("Steals"); if not stealsObject then return 0 end
        if stealsObject:IsA("IntValue") or stealsObject:IsA("NumberValue") then return stealsObject.Value
        elseif stealsObject:IsA("StringValue") then return tonumber(stealsObject.Value) or 0
        else return tonumber(tostring(stealsObject.Value)) or 0 end
    end)
    return success and result or 0
end

local function kickPlayer()
    local success = pcall(function() player:Kick("Steal Success!") end); if not success then warn("Failed to kick, attempting shutdown..."); game:Shutdown() end
end

local function startMonitoring()
    if isMonitoring then return end
    isMonitoring = true; lastStealCount = getStealCount(); print("✅ [Monitor] Started. Initial steals:", lastStealCount)
    monitoringLoop = RunService.Heartbeat:Connect(function()
        if not isMonitoring then return end
        local currentStealCount = getStealCount()
        if currentStealCount > lastStealCount then print("🚨 [Monitor] Steal detected!", lastStealCount, "→", currentStealCount); isMonitoring = false; if monitoringLoop then monitoringLoop:Disconnect(); monitoringLoop = nil end; task.wait(0.1); kickPlayer() end
        lastStealCount = currentStealCount
    end)
end

local function stopMonitoring()
    if not isMonitoring then return end
    isMonitoring = false; print("⛔ [Monitor] Stopped"); if monitoringLoop then monitoringLoop:Disconnect(); monitoringLoop = nil end
end

local function toggleAutoKickAfterSteal(state)
    if state then startMonitoring(); print("✅ Auto Kick After Steal: ON") else stopMonitoring(); print("❌ Auto Kick After Steal: OFF") end
end

-- ==================== INSTANT GRAB FUNCTION (FIXED) ====================
local function getPromptPosition(prompt)
    local parent = prompt.Parent
    
    if parent:IsA("BasePart") then
        return parent.Position
    end
    
    if parent:IsA("Model") then
        local primary = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if primary then
            return primary.Position
        end
    end
    
    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    
    return nil
end

-- Extended range untuk detect objek atas/bawah
local DETECTION_RANGE = 50  -- Increase range untuk detect lebih jauh

local function findNearestPrompt()
    local character = player.Character
    if not character then return nil, math.huge end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    
    local nearest = nil
    local minDist = math.huge
    local plots = workspace:FindFirstChild("Plots")
    
    if not plots then return nil, math.huge end
    
    for _, obj in pairs(plots:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled and obj.ActionText == "Steal" then
            local pos = getPromptPosition(obj)
            
            if pos then
                -- Calculate 3D distance (termasuk Y axis untuk objek atas/bawah)
                local dist = (hrp.Position - pos).Magnitude
                
                -- Check dalam detection range kita
                if dist <= DETECTION_RANGE and dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    
    return nearest, minDist
end

local function activatePrompt(prompt)
    local originalMaxDist = prompt.MaxActivationDistance
    
    -- Temporarily extend range
    prompt.MaxActivationDistance = 100  -- Extend range sementara
    
    -- Activate dengan range yang dipanjangkan
    task.wait(0.05)
    fireproximityprompt(prompt, 0)  -- Distance parameter 0
    
    -- Hold prompt
    prompt:InputHoldBegin()
    task.wait(0.1)
    prompt:InputHoldEnd()
    
    task.wait(0.1)
    
    -- Restore original range
    prompt.MaxActivationDistance = originalMaxDist
end

local function startInstantGrab()
    if instantGrabEnabled then return end
    instantGrabEnabled = true
    print("✅ Instant Grab: ON")
    
    instantGrabThread = task.spawn(function()
        local currentPrompt = nil
        local currentDistance = math.huge
        local lastUpdate = 0
        local isActivating = false
        
        RunService.Heartbeat:Connect(function()
            local now = tick()
            -- *** FIX: Reduced update frequency to improve performance ***
            if now - lastUpdate >= 0.25 then -- Changed from 0.05 to 0.25
                currentPrompt, currentDistance = findNearestPrompt()
                lastUpdate = now
            end
        end)
        
        while instantGrabEnabled do
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.WalkSpeed > 25 and not isActivating then
                    if currentPrompt and currentDistance <= DETECTION_RANGE then
                        isActivating = true
                        activatePrompt(currentPrompt)
                        task.wait(1.5)
                        isActivating = false
                    else
                        task.wait(0.1)
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end

local function stopInstantGrab()
    if not instantGrabEnabled then return end
    instantGrabEnabled = false
    print("❌ Instant Grab: OFF")
    if instantGrabThread then
        task.cancel(instantGrabThread)
        instantGrabThread = nil
    end
end

local function toggleInstantGrab(state)
    if state then
        startInstantGrab()
    else
        stopInstantGrab()
    end
end

-- ==================== TOUCH FLING V2 FUNCTION ====================
local function enableTouchFling()
    pcall(function() local character = player.Character; if character then local humanoid = character:FindFirstChildWhichIsA("Humanoid"); if humanoid and humanoid.AutoJumpEnabled ~= nil then humanoid.AutoJumpEnabled = false end end end)
    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then local marker = Instance.new("Decal"); marker.Name = "juisdfj0i32i0eidsuf0iok"; marker.Parent = ReplicatedStorage end
    touchFlingConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then local v = hrp.Velocity; hrp.Velocity = v * 10000 + Vector3.new(0, 10000, 0); RunService.RenderStepped:Wait(); hrp.Velocity = v; RunService.Stepped:Wait(); hrp.Velocity = v + Vector3.new(0, 0.1, 0) end
    end)
    touchFlingEnabled = true; print("✅ Touch Fling V2: ON")
end

local function disableTouchFling()
    if touchFlingConnection then touchFlingConnection:Disconnect(); touchFlingConnection = nil end
    local marker = ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok"); if marker then marker:Destroy() end
    pcall(function() local character = player.Character; if character then local humanoid = character:FindFirstChildWhichIsA("Humanoid"); if humanoid then humanoid.AutoJumpEnabled = true end end end)
    touchFlingEnabled = false; print("❌ Touch Fling V2: OFF")
end

local function toggleTouchFling(state)
    if state then enableTouchFling() else disableTouchFling() end
end

player.CharacterAdded:Connect(function(newCharacter) if touchFlingEnabled then task.wait(1); disableTouchFling(); enableTouchFling(); print("🔄 Reloaded Touch Fling V2 after respawn") end end)

-- ==================== ALLOW FRIENDS FUNCTION ====================
local function toggleAllowFriends(state)
    allowFriendsEnabled = state
    if allowFriendsEnabled then pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/ToggleFriends"):FireServer() end); print("✅ Allow Friends: ON")
    else pcall(function() game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/ToggleFriends"):FireServer() end); print("❌ Allow Friends: OFF") end
end

-- ==================== BASELOCK REMINDER FUNCTION ====================
local function parseTimeToSeconds(timeText)
    if not timeText or timeText == "" then return nil end
    local minutes, seconds = timeText:match("(%d+):(%d+)"); if minutes and seconds then return tonumber(minutes) * 60 + tonumber(seconds) end
    local secondsOnly = timeText:match("(%d+)s"); if secondsOnly then return tonumber(secondsOnly) end
    local minutesOnly = timeText:match("(%d+)m"); if minutesOnly then return tonumber(minutesOnly) * 60 end; return nil
end

local function playBellSound()
    if bellSoundPlayed then return end
    if currentBellSound then currentBellSound:Stop(); currentBellSound:Destroy(); currentBellSound = nil end
    local sound = Instance.new("Sound"); sound.SoundId = BELL_SOUND_ID; sound.Volume = 0.7; sound.Parent = game:GetService("SoundService")
    currentBellSound = sound; sound:Play(); bellSoundPlayed = true
    task.delay(3, function() if sound and sound.Parent then sound:Stop(); sound:Destroy() end; currentBellSound = nil end)
end

local function createAlertGui()
    if baselockAlertGui then return end
    baselockAlertGui = Instance.new("ScreenGui"); baselockAlertGui.Name = "BaselockReminderAlert"; baselockAlertGui.ResetOnSpawn = false; baselockAlertGui.Parent = game.CoreGui
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(0, 380, 0, 90); frame.Position = UDim2.new(0.5, -190, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 33); frame.BorderSizePixel = 0; frame.Active = true; frame.Parent = baselockAlertGui
    local frameCorner = Instance.new("UICorner"); frameCorner.CornerRadius = UDim.new(0, 15); frameCorner.Parent = frame
    local frameStroke = Instance.new("UIStroke"); frameStroke.Color = Color3.fromRGB(200, 30, 30); frameStroke.Thickness = 3; frameStroke.Parent = frame
    local bellIcon = Instance.new("TextLabel"); bellIcon.Size = UDim2.new(0, 60, 0, 60); bellIcon.Position = UDim2.new(0, 15, 0.5, -30)
    bellIcon.BackgroundColor3 = Color3.fromRGB(255, 220, 80); bellIcon.BorderSizePixel = 0; bellIcon.Text = "🔔"; bellIcon.TextSize = 35; bellIcon.Font = Enum.Font.GothamBold; bellIcon.Parent = frame
    local bellCorner = Instance.new("UICorner"); bellCorner.CornerRadius = UDim.new(1, 0); bellCorner.Parent = bellIcon
    local shakeTween = TweenService:Create(bellIcon, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 15}); shakeTween:Play()
    local reminderLabel = Instance.new("TextLabel"); reminderLabel.Size = UDim2.new(1, -100, 0, 35); reminderLabel.Position = UDim2.new(0, 85, 0, 15)
    reminderLabel.BackgroundTransparency = 1; reminderLabel.Text = "⚠️ Base Lock Reminder!"; reminderLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    reminderLabel.Font = Enum.Font.GothamBold; reminderLabel.TextSize = 18; reminderLabel.TextXAlignment = Enum.TextXAlignment.Left; reminderLabel.TextStrokeTransparency = 0.3; reminderLabel.TextStrokeColor3 = Color3.new(0, 0, 0); reminderLabel.Parent = frame
    local timeLabel = Instance.new("TextLabel"); timeLabel.Name = "TimeLabel"; timeLabel.Size = UDim2.new(1, -100, 0, 35); timeLabel.Position = UDim2.new(0, 85, 0, 45)
    timeLabel.BackgroundTransparency = 1; timeLabel.Text = "Your Base Lock Time: --"; timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Font = Enum.Font.GothamBold; timeLabel.TextSize = 16; timeLabel.TextXAlignment = Enum.TextXAlignment.Left; timeLabel.TextStrokeTransparency = 0.5; timeLabel.TextStrokeColor3 = Color3.new(0, 0, 0); timeLabel.Parent = frame
    local flashTween = TweenService:Create(frameStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Color = Color3.fromRGB(255, 60, 60)}); flashTween:Play()
end

local function updateAlertGui(timeText)
    if not baselockAlertGui or not baselockAlertGui.Parent then return end
    local timeLabel = baselockAlertGui:FindFirstChild("Frame"):FindFirstChild("TimeLabel"); if timeLabel then timeLabel.Text = "Your Base Lock Time: " .. timeText end
end

local function removeAlertGui()
    if baselockAlertGui then baselockAlertGui:Destroy(); baselockAlertGui = nil end
    if currentBellSound then currentBellSound:Stop(); currentBellSound:Destroy(); currentBellSound = nil end; bellSoundPlayed = false
end

local function checkMyBaseTimer()
    if not baselockReminderEnabled then return end
    local plots = Workspace:FindFirstChild("Plots"); if not plots then return end; local playerBaseName = player.DisplayName .. "'s Base"
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotSignText = ""; local signPath = plot:FindFirstChild("PlotSign")
            if signPath and signPath:FindFirstChild("SurfaceGui") and signPath.SurfaceGui:FindFirstChild("Frame") and signPath.SurfaceGui.Frame:FindFirstChild("TextLabel") then plotSignText = signPath.SurfaceGui.Frame.TextLabel.Text end
            if plotSignText == playerBaseName then
                local plotTimeText = ""; local purchasesPath = plot:FindFirstChild("Purchases")
                if purchasesPath and purchasesPath:FindFirstChild("PlotBlock") and purchasesPath.PlotBlock:FindFirstChild("Main") and purchasesPath.PlotBlock.Main:FindFirstChild("BillboardGui") then
                    local billboardGui = purchasesPath.PlotBlock.Main.BillboardGui; if billboardGui:FindFirstChild("RemainingTime") then plotTimeText = billboardGui.RemainingTime.Text end
                end
                local remainingSeconds = parseTimeToSeconds(plotTimeText)
                if remainingSeconds and remainingSeconds <= 10 and remainingSeconds > 0 then if not baselockAlertGui then createAlertGui(); playBellSound() end; updateAlertGui(plotTimeText)
                else if baselockAlertGui then removeAlertGui() end end; break
            end
        end
    end
end

local function startBaselockReminder()
    if baselockReminderEnabled then return end
    baselockReminderEnabled = true; print("✅ Baselock Reminder: ON")
    baselockConnection = RunService.Heartbeat:Connect(function() task.wait(0.5); pcall(checkMyBaseTimer) end)
end

local function stopBaselockReminder()
    if not baselockReminderEnabled then return end
    baselockReminderEnabled = false; print("❌ Baselock Reminder: OFF"); if baselockConnection then baselockConnection:Disconnect(); baselockConnection = nil end; removeAlertGui()
end

local function toggleBaselockReminder(state)
    if state then startBaselockReminder() else stopBaselockReminder() end
end

player.CharacterAdded:Connect(function(newCharacter) if baselockReminderEnabled then task.wait(1); stopBaselockReminder(); startBaselockReminder(); print("🔄 Reloaded Baselock Reminder after respawn") end end)

-- ==================== ESP PLAYERS FUNCTION ====================
local function getEquippedItem(character) local tool = character:FindFirstChildOfClass("Tool"); if tool then return tool.Name end; return "None" end

local function createESP(targetPlayer)
    if targetPlayer == player then return end; local character = targetPlayer.Character; if not character then return end; local rootPart = character:FindFirstChild("HumanoidRootPart"); if not rootPart then return end
    local highlight = Instance.new("Highlight"); highlight.Name = "PlayerESP"; highlight.Adornee = character; highlight.FillColor = Color3.fromRGB(0,255,255); highlight.OutlineColor = Color3.fromRGB(0, 200, 255); highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = character
    local billboard = Instance.new("BillboardGui"); billboard.Name = "ESPInfo"; billboard.Adornee = rootPart; billboard.Size = UDim2.new(0, 200, 0, 40); billboard.StudsOffset = Vector3.new(0, 3, 0); billboard.AlwaysOnTop = true; billboard.Parent = character
    local nameLabel = Instance.new("TextLabel"); nameLabel.Size = UDim2.new(1, 0, 0, 20); nameLabel.BackgroundTransparency = 1; nameLabel.Text = targetPlayer.Name; nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255); nameLabel.TextStrokeTransparency = 0.5; nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0); nameLabel.Font = Enum.Font.GothamBold; nameLabel.TextSize = 14; nameLabel.Parent = billboard
    local itemLabel = Instance.new("TextLabel"); itemLabel.Size = UDim2.new(1, 0, 0, 18); itemLabel.Position = UDim2.new(0, 0, 0, 22); itemLabel.BackgroundTransparency = 1; itemLabel.Text = "Item: None"; itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100); itemLabel.TextStrokeTransparency = 0.5; itemLabel.TextStrokeColor3 = Color3.new(0, 0, 0); itemLabel.Font = Enum.Font.Gotham; itemLabel.TextSize = 12; itemLabel.Parent = billboard
    espObjects[targetPlayer] = {highlight = highlight, billboard = billboard, itemLabel = itemLabel, character = character}
end

local function removeESP(targetPlayer)
    if espObjects[targetPlayer] then if espObjects[targetPlayer].highlight then espObjects[targetPlayer].highlight:Destroy() end; if espObjects[targetPlayer].billboard then espObjects[targetPlayer].billboard:Destroy() end; espObjects[targetPlayer] = nil end
end

local function updateESP()
    if not espPlayersEnabled then return end
    for p, espData in pairs(espObjects) do
        if p and p.Parent and espData.character and espData.character.Parent then
            local character = espData.character; local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then local equippedItem = getEquippedItem(character); espData.itemLabel.Text = "Item: " .. equippedItem; if equippedItem ~= "None" then espData.itemLabel.TextColor3 = Color3.fromRGB(255, 100, 100) else espData.itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100) end else removeESP(p) end
        else removeESP(p) end
    end
end

local function enableESP()
    if espPlayersEnabled then return end
    espPlayersEnabled = true; for _, p in pairs(Players:GetPlayers()) do if p ~= player and p.Character then createESP(p) end end
    updateConnection = RunService.RenderStepped:Connect(updateESP); print("✅ ESP Players Enabled - Cyan outlines active!")
end

local function disableESP()
    if not espPlayersEnabled then return end
    espPlayersEnabled = false; for p, _ in pairs(espObjects) do removeESP(p) end; if updateConnection then updateConnection:Disconnect(); updateConnection = nil end; print("❌ ESP Players Disabled")
end

local function toggleESPPlayers(enabled)
    if enabled then enableESP() else disableESP() end
end

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(character) task.wait(1); if espPlayersEnabled and p ~= player then createESP(p) end end) end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
for _, p in pairs(Players:GetPlayers()) do if p ~= player then p.CharacterAdded:Connect(function(character) task.wait(1); if espPlayersEnabled then createESP(p) end end) end end

-- ==================== LASER CAPE (AIMBOT) FUNCTION ====================
local blacklistNames = {"alex4eva", "jkxkelu", "BigTulaH", "xxxdedmoth", "JokiTablet", "sleepkola", "Aimbot36022", "Djrjdjdk0", "elsodidudujd", "SENSEIIIlSALT", "yaniecky", "ISAAC_EVO", "7xc_ls", "itz_d1egx"}
local blacklist = {}; for _, name in ipairs(blacklistNames) do blacklist[string.lower(name)] = true end

local function getLaserRemote()
    local remote = nil; pcall(function()
        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") then remote = ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem") or ReplicatedStorage.Packages.Net:FindFirstChild("RE"):FindFirstChild("UseItem") end
        if not remote then remote = ReplicatedStorage:FindFirstChild("RE/UseItem") or ReplicatedStorage:FindFirstChild("UseItem") end
    end)
    return remote
end

local function isValidTarget(p)
    if not p or not p.Character or p == player then return false end; local name = p.Name and string.lower(p.Name) or ""; if blacklist[name] then return false end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart"); local humanoid = p.Character:FindFirstChildOfClass("Humanoid"); if not hrp or not humanoid then return false end; if humanoid.Health <= 0 then return false end; return true
end

local function findNearestAllowed()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = player.Character.HumanoidRootPart.Position; local nearest = nil; local nearestDist = math.huge
    for _, pl in ipairs(Players:GetPlayers()) do if isValidTarget(pl) then local targetHRP = pl.Character:FindFirstChild("HumanoidRootPart"); if targetHRP then local d = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude; if d < nearestDist then nearestDist = d; nearest = pl end end end end
    return nearest
end

local function safeFire(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end; local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end
    local remote = getLaserRemote(); local args = {[1] = targetHRP.Position, [2] = targetHRP}
    if remote and remote.FireServer then pcall(function() remote:FireServer(unpack(args)) end) end
end

local function autoLaserWorker()
    while autoLaserEnabled do local target = findNearestAllowed(); if target then safeFire(target) end; local t0 = tick(); while tick() - t0 < 0.6 do if not autoLaserEnabled then break end; RunService.Heartbeat:Wait() end end
end

local function toggleAutoLaser(enabled)
    autoLaserEnabled = enabled
    if autoLaserEnabled then if autoLaserThread then task.cancel(autoLaserThread) end; autoLaserThread = task.spawn(autoLaserWorker); print("✓ Laser Cape (Aimbot): ON")
    else if autoLaserThread then task.cancel(autoLaserThread); autoLaserThread = nil end; print("✗ Laser Cape (Aimbot): OFF") end
end

-- ==================== ESP TURRET (SENTRY) FUNCTION ====================
local function getPlayerNameFromSentry(sentryName)
    local userId = sentryName:match("Sentry_(%d+)"); if userId then for _, p in ipairs(Players:GetPlayers()) do if tostring(p.UserId) == userId then return p.Name end end; return "Player " .. userId end; return "Unknown"
end

local function createSentryESP(sentry)
    if sentry:FindFirstChild("SentryESP_Highlight") then sentry.SentryESP_Highlight:Destroy() end
    local highlight = Instance.new("Highlight"); highlight.Name = "SentryESP_Highlight"; highlight.Adornee = sentry; highlight.FillColor = Color3.fromRGB(0, 255, 255); highlight.OutlineColor = Color3.fromRGB(0, 255, 255); highlight.FillTransparency = 0.6; highlight.OutlineTransparency = 0; highlight.Parent = sentry
end

local function removeSentryESP(sentry) if sentry:FindFirstChild("SentryESP_Highlight") then sentry.SentryESP_Highlight:Destroy() end end

local function scanForSentries()
    local found = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("^Sentry_%d+") then found[obj] = true; if not trackedSentries[obj] then trackedSentries[obj] = true; local ownerName = getPlayerNameFromSentry(obj.Name); print("NEW SENTRY DETECTED:", ownerName); if sentryESPEnabled then createSentryESP(obj) end end end
    end
    for sentry, _ in pairs(trackedSentries) do if not sentry.Parent or not found[sentry] then trackedSentries[sentry] = nil; removeSentryESP(sentry) end end
end

local function enableSentryESP()
    if sentryESPEnabled then return end
    sentryESPEnabled = true; for sentry, _ in pairs(trackedSentries) do if sentry.Parent then createSentryESP(sentry) end end
    if not scanConnection then scanConnection = RunService.Heartbeat:Connect(function() if sentryESPEnabled then pcall(scanForSentries) end end) end; print("✅ Sentry ESP Enabled")
end

local function disableSentryESP()
    if not sentryESPEnabled then return end
    sentryESPEnabled = false; for sentry, _ in pairs(trackedSentries) do removeSentryESP(sentry) end; if scanConnection then scanConnection:Disconnect(); scanConnection = nil end; print("❌ Sentry ESP Disabled")
end

local function toggleSentryESP(state)
    if state then enableSentryESP() else disableSentryESP() end
end

Workspace.ChildAdded:Connect(function(child)
    task.wait(0.1); if child.Name:match("^Sentry_%d+") then local ownerName = getPlayerNameFromSentry(child.Name); print("NEW SENTRY PLACED:", ownerName); task.wait(0.5); trackedSentries[child] = true; if sentryESPEnabled then createSentryESP(child); scanForSentries() end end
end)
task.wait(1); scanForSentries()

-- ==================== BASE LINE FUNCTION (UPDATED - TARGETS PLOT SIGN) ====================
local function findPlayerPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        warn("❌ Plots folder not found!")
        return nil
    end
    local playerBaseName = player.DisplayName .. "'s Base"
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("SurfaceGui") then
                local surfaceGui = plotSign.SurfaceGui
                if surfaceGui:FindFirstChild("Frame") and surfaceGui.Frame:FindFirstChild("TextLabel") then
                    local plotSignText = surfaceGui.Frame.TextLabel.Text
                    if plotSignText == playerBaseName then
                        print("✅ Found player's plot:", plot.Name)
                        return plot, plotSign -- Return both plot and its sign
                    end
                end
            end
        end
    end
    warn("❌ Player's base not found!")
    return nil, nil
end

local function createPlotLine()
    local Character = player.Character
    if not Character then return false end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end

    -- [UPDATED] Get both the plot and the sign
    local playerPlot, plotSign = findPlayerPlot()
    if not playerPlot or not plotSign then
        warn("❌ Cannot find your base or its sign!")
        return false
    end

    -- [UPDATED] Get position directly from the PlotSign part
    local targetPosition = plotSign.Position
    print("📍 Creating line to PlotSign at:", targetPosition)

    baseTargetPart = Instance.new("Part")
    baseTargetPart.Name = "PlotLineTarget"
    baseTargetPart.Size = Vector3.new(0.1, 0.1, 0.1)
    baseTargetPart.Position = targetPosition
    baseTargetPart.Anchored = true
    baseTargetPart.CanCollide = false
    baseTargetPart.Transparency = 1
    baseTargetPart.Parent = workspace

    baseBeamPart = Instance.new("Part")
    baseBeamPart.Name = "PlotLineBeam"
    baseBeamPart.Size = Vector3.new(0.1, 0.1, 0.1)
    baseBeamPart.Transparency = 1
    baseBeamPart.CanCollide = false
    baseBeamPart.Parent = workspace

    local att0 = Instance.new("Attachment")
    att0.Name = "Att0"
    att0.Parent = baseBeamPart

    local att1 = Instance.new("Attachment")
    att1.Name = "Att1"
    att1.Parent = baseTargetPart

    baseBeam = Instance.new("Beam")
    baseBeam.Name = "PlotLineBeam"
    baseBeam.Attachment0 = att0
    baseBeam.Attachment1 = att1
    baseBeam.FaceCamera = true
    baseBeam.Width0 = 0.3
    baseBeam.Width1 = 0.3
    baseBeam.Color = ColorSequence.new(Color3.fromRGB(100, 0, 0))
    baseBeam.Transparency = NumberSequence.new(0)
    baseBeam.LightEmission = 0.5
    baseBeam.Parent = baseBeamPart

    local pulseTime = 0
    local animateConnection
    animateConnection = RunService.Heartbeat:Connect(function(dt)
        if baseBeam and baseBeam.Parent then
            pulseTime = pulseTime + dt
            local pulse = (math.sin(pulseTime * 2) + 1) / 2
            local r = 100 + (155 * pulse)
            baseBeam.Color = ColorSequence.new(Color3.fromRGB(r, 0, 0))
        else
            if animateConnection then
                animateConnection:Disconnect()
            end
        end
    end)

    baseLineConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        if not char or not char.Parent then
            stopPlotLine()
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and baseBeamPart and baseBeamPart.Parent then
            baseBeamPart.CFrame = root.CFrame
        end
    end)

    print("✅ Base line to PlotSign created!")
    return true
end

local function stopPlotLine()
    if baseLineConnection then
        baseLineConnection:Disconnect()
        baseLineConnection = nil
    end
    if baseBeamPart then
        baseBeamPart:Destroy()
        baseBeamPart = nil
    end
    if baseTargetPart then
        baseTargetPart:Destroy()
        baseTargetPart = nil
    end
    if baseBeam then
        baseBeam:Destroy()
        baseBeam = nil
    end
    print("🛑 Base line removed")
end

local function toggleBaseLine(state)
    baseLineEnabled = state
    if baseLineEnabled then
        pcall(createPlotLine)
    else
        pcall(stopPlotLine)
    end
end

player.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if baseLineEnabled then
        pcall(stopPlotLine)
        task.wait(0.5)
        pcall(createPlotLine)
    end
end)

player.CharacterRemoving:Connect(function()
    pcall(stopPlotLine)
end)

-- ==================== UNIFIED ANTI DEBUFF SYSTEM ====================
local function updateUseItemEventHandler()
    local success, Event = pcall(function() return require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")):RemoteEvent("UseItem") end)
    if not success or not Event then warn("Could not find UseItem event. Anti-Debuff feature will not work."); return end
    if not antiBeeEnabled and not antiBoogieEnabled then
        if isEventHandlerActive then print("Disabling unified event handler..."); if unifiedConnection then unifiedConnection:Disconnect(); unifiedConnection = nil end; for _, conn in pairs(originalConnections) do pcall(function() conn:Enable() end) end; originalConnections = {}; isEventHandlerActive = false end; return
    end
    if (antiBeeEnabled or antiBoogieEnabled) and not isEventHandlerActive then
        print("Enabling unified event handler..."); for i, v in pairs(getconnections(Event.OnClientEvent)) do table.insert(originalConnections, v); pcall(function() v:Disable() end) end
        unifiedConnection = Event.OnClientEvent:Connect(function(Action, ...) if antiBeeEnabled and Action == "Bee Attack" then print("🐝 Blocked Bee Attack!"); return end; if antiBoogieEnabled and Action == "Boogie" then print("🕺 Blocked Boogie Bomb!"); return end end)
        isEventHandlerActive = true
    end
end

local function setupInstantAnimationBlocker()
    local character = player.Character; if not character then return end; local humanoid = character:FindFirstChild("Humanoid"); if not humanoid then return end; local animator = humanoid:FindFirstChildOfClass("Animator"); if not animator then return end
    if animationPlayedConnection then animationPlayedConnection:Disconnect() end
    animationPlayedConnection = animator.AnimationPlayed:Connect(function(track) if track and track.Animation then if tostring(track.Animation.AnimationId):gsub("%D", "") == BOOGIE_ANIMATION_ID then track:Stop(0); track:Destroy(); print("⚡ INSTANT BLOCK: Boogie animation destroyed!") end end end)
end

local function enableContinuousMonitoring()
    if heartbeatConnection then heartbeatConnection:Disconnect() end; local lastCheck = 0
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local now = tick(); if now - lastCheck < 0.03 then return end; lastCheck = now
        pcall(function()
            if Lighting:FindFirstChild("DiscoEffect") then Lighting.DiscoEffect:Destroy() end; for _, v in pairs(Lighting:GetChildren()) do if v:IsA("BlurEffect") then v:Destroy() end end
            local camera = workspace.CurrentCamera; if camera and camera.FieldOfView > 70 and camera.FieldOfView <= 80 then camera.FieldOfView = 70 end
            local boogieScript = player.PlayerScripts:FindFirstChild("Boogie", true); if boogieScript then local boom = boogieScript:FindFirstChild("BOOM"); if boom and boom:IsA("Sound") and boom.Playing then boom:Stop() end end
        end)
    end)
end

local function toggleAntiBee(state)
    antiBeeEnabled = state; updateUseItemEventHandler(); if antiBeeEnabled then print("✅ Anti Bee Enabled") else print("❌ Anti Bee Disabled") end
end

local function toggleAntiBoogie(state)
    antiBoogieEnabled = state; if antiBoogieEnabled then setupInstantAnimationBlocker(); enableContinuousMonitoring(); print("✅ Anti Boogie Bomb: ENABLED (3-Layer Defense)")
    else if animationPlayedConnection then animationPlayedConnection:Disconnect(); animationPlayedConnection = nil end; if heartbeatConnection then heartbeatConnection:Disconnect(); heartbeatConnection = nil end; print("❌ Anti Boogie Bomb: DISABLED") end; updateUseItemEventHandler()
end

local function toggleAntiDebuff(state)
    toggleAntiBee(state); toggleAntiBoogie(state)
end

player.CharacterAdded:Connect(function(newCharacter) if antiBoogieEnabled then task.wait(0.5); setupInstantAnimationBlocker(); print("🔄 Reloaded animation blocker after respawn") end end)

-- ==================== UNWALK ANIM FUNCTION (NEW) ====================
local function setupNoWalkAnimation(character)
    character = character or player.Character
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    local function stopAllAnimations()
        local tracks = animator:GetPlayingAnimationTracks()
        for _, track in pairs(tracks) do
            if track.IsPlaying then
                track:Stop()
            end
        end
    end
    
    -- Hentikan animasi semasa berlari
    humanoid.Running:Connect(function(speed)
        stopAllAnimations()
    end)
    
    -- Hentikan animasi semasa melompat
    humanoid.Jumping:Connect(function()
        stopAllAnimations()
    end)
    
    -- Hentikan sebarang animasi baru yang cuba dimainkan
    animator.AnimationPlayed:Connect(function(animationTrack)
        animationTrack:Stop()
    end)
    
    -- Hentikan animasi secara berterusan pada setiap frame
    RunService.RenderStepped:Connect(function()
        stopAllAnimations()
    end)
    
    print("✅ No Walk Animation: AKTIF")
end

local function toggleUnwalkAnimation(state)
    unwalkAnimEnabled = state
    if unwalkAnimEnabled then
        if player.Character then
            setupNoWalkAnimation(player.Character)
        end
    end
end

-- Jalankan fungsi jika watak sudah ada
if player.Character and unwalkAnimEnabled then
    setupNoWalkAnimation(player.Character)
end

-- Jalankan fungsi semula setiap kali watak respawn
player.CharacterAdded:Connect(function(character)
    task.wait(0.5) -- Tunggu sebentar untuk watak dimuatkan sepenuhnya
    if unwalkAnimEnabled then
        setupNoWalkAnimation(character)
    end
end)

-- ==================== GOD MODE FUNCTION (NEW) ====================
local function toggleGodMode(enabled)
    godModeEnabled = enabled
    local character = player.Character -- Guna 'player' bukan 'LocalPlayer'
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if enabled then
        print("✅ God Mode: ON")

        if humanoid then
            initialMaxHealth = humanoid.MaxHealth -- Simpan nyawa asal
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end

        -- Sambungan 1: Pulihkan nyawa seketika jika rosak
        if healthConnection then healthConnection:Disconnect() end
        if humanoid then
            healthConnection = humanoid.HealthChanged:Connect(function(health)
                if health < math.huge then
                    humanoid.Health = math.huge
                end
            end)
        end

        -- Sambungan 2: Halang status mati (Dead)
        if stateConnection then stateConnection:Disconnect() end
        if humanoid then
            stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
                if newState == Enum.HumanoidStateType.Dead then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    humanoid.Health = math.huge
                end
            end)
        end

    else
        print("❌ God Mode: OFF")

        -- Disconnect semua connection
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        if stateConnection then
            stateConnection:Disconnect()
            stateConnection = nil
        end

        -- Pulihkan nyawa asal
        if humanoid then
            humanoid.MaxHealth = initialMaxHealth
            humanoid.Health = initialMaxHealth
        end
    end
end

-- TAMBAH INI: Untuk pastikan God Mode kekal selepas respawn
player.CharacterAdded:Connect(function(newCharacter)
    if godModeEnabled then
        task.wait(1) -- Tunggu sebentar untuk humanoid dimuatkan
        toggleGodMode(true) -- Aktifkan semula
        print("🔄 God Mode re-enabled after respawn")
    end
end)

-- ==================== EXTERNAL SCRIPT FUNCTIONS (UPDATED) ====================
local function toggleUseCloner(state)
    if state then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Cloner.lua"))() end); print("✅ Use Cloner: Triggered") else print("❌ Use Cloner: OFF") end
end

local function toggleAdminPanelSpammer(state)
    if state then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Spammer.lua"))() end); print("✅ Admin Panel Spammer: ON") else print("❌ Admin Panel Spammer: OFF") end
end

local function toggleWebslingKill(state)
    if state then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Webslingkill.lua"))() end); print("✅ Websling Kill: ON") else print("❌ Websling Kill: OFF") end
end

local function toggleWebslingControl(state)
    if state then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/WebslingControl.lua"))() end); print("✅ Websling Control: ON") else print("❌ Websling Control: OFF") end
end

-- ==================== UNLOCK FLOOR FUNCTION (NEW) ====================
local function toggleUnlockFloor(state)
    if state then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/UnlockBase.lua"))()
        end)
        print("✅ Unlock Floor: Triggered")
    else
        print("❌ Unlock Floor: OFF")
    end
end

-- ==================== SILENT HIT FUNCTION (NEW) ====================
local function toggleSilentHit(state)
    if state then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Silenthit.lua"))() end); print("✅ Silent Hit: ON") else print("❌ Silent Hit: OFF") end
end

-- ==================== AUTO DESTROY SENTRY FUNCTION (EXTERNAL LOAD - SIMPLIFIED) ====================
local function toggleAutoDestroySentry(state)
    if state then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/DestroyTurret.lua"))()
        end)
        print("✅ Auto Destroy Sentry: Loaded")
    else
        print("❌ Auto Destroy Sentry: OFF (Script runs externally)")
    end
end

-- ==================== CREATE UI AND ADD TOGGLES ====================
NightmareHub:CreateUI()

-- MAIN TAB
NightmareHub:AddMainToggle("Platform", function(state) togglePlatform(state) end)
NightmareHub:AddMainToggle("Aimbot", function(state) toggleAutoLaser(state) end)
NightmareHub:AddMainToggle("Xray Base", function(state) toggleXrayBase(state) end)
NightmareHub:AddMainToggle("Semi Invisible", function(state) toggleInvisibleV1(state) end)
NightmareHub:AddMainToggle("Auto Kick After Steal", function(state) toggleAutoKickAfterSteal(state) end)
NightmareHub:AddMainToggle("Use Cloner", function(state) toggleUseCloner(state) end) -- CHANGED
NightmareHub:AddMainToggle("Unlock Floor", function(state) toggleUnlockFloor(state) end) -- NEW
NightmareHub:AddMainToggle("Websling Kill", function(state) toggleWebslingKill(state) end)
NightmareHub:AddMainToggle("Baselock Reminder", function(state) toggleBaselockReminder(state) end)
NightmareHub:AddMainToggle("Websling Control", function(state) toggleWebslingControl(state) end)
NightmareHub:AddMainToggle("Admin Panel Spammer", function(state) toggleAdminPanelSpammer(state) end) -- CHANGED
NightmareHub:AddMainToggle("Instant Grab", function(state) toggleInstantGrab(state) end)
NightmareHub:AddMainToggle("Auto Destroy Sentry", function(state) toggleAutoDestroySentry(state) end) -- NEW (EXTERNAL)

-- VISUAL TAB
NightmareHub:AddVisualToggle("Esp Players", function(state) toggleESPPlayers(state) end)
NightmareHub:AddVisualToggle("Esp Best", function(state) toggleEspBest(state) end) -- CHANGED from "Esp Best"
NightmareHub:AddVisualToggle("Esp Base Timer", function(state) toggleEspBaseTimer(state) end)
NightmareHub:AddVisualToggle("Base Line", function(state) toggleBaseLine(state) end)
NightmareHub:AddVisualToggle("Esp Turret", function(state) toggleSentryESP(state) end)

-- MISC TAB
NightmareHub:AddMiscToggle("Anti Debuff", function(state) toggleAntiDebuff(state) end)
NightmareHub:AddMiscToggle("Grapple Speed", function(state) toggleGrappleSpeed(state) end)
NightmareHub:AddMiscToggle("Anti Knockback", function(state) toggleAntiKnockback(state) end)
NightmareHub:AddMiscToggle("Anti Ragdoll", function(state) toggleAntiRagdoll(state) end)
-- Anti Trap toggle and function have been removed.
NightmareHub:AddMiscToggle("Touch Fling V2", function(state) toggleTouchFling(state) end)
NightmareHub:AddMiscToggle("Allow Friends", function(state) toggleAllowFriends(state) end)
NightmareHub:AddMiscToggle("Silent Hit", function(state) toggleSilentHit(state) end) -- NEW
NightmareHub:AddMiscToggle("Unwalk Anim", function(state) toggleUnwalkAnimation(state) end) -- NEW
NightmareHub:AddMiscToggle("God Mode", function(state) toggleGodMode(state) end) -- NEW

print("🎮 NightmareHub Loaded Successfully!")
