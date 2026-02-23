-- LOAD LIBRARY DARI GITHUB
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/N1ghtmare.gg/refs/heads/main/NightmareHub.lua"))()

-- INITIALIZE QUICK PANEL & MAIN HUB
local QuickPanel = Library.QuickPanel:New()
local MainHub = Library.MainHub:New()

-- ==================== SERVICES ====================
local S = {
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService")
}
local player = S.Players.LocalPlayer

-- ==================== MODULES ====================
local AnimalsModule, TraitsModule, MutationsModule

pcall(function()
    AnimalsModule = require(S.ReplicatedStorage.Datas.Animals)
    TraitsModule = require(S.ReplicatedStorage.Datas.Traits)
    MutationsModule = require(S.ReplicatedStorage.Datas.Mutations)
end)

-- ==================== VARIABLES ====================
local infiniteJumpEnabled = false
local lowGravityEnabled = false
local jumpRequestConnection = nil
local bodyForce = nil
local lowGravityForce = 50
local defaultGravity = S.Workspace.Gravity

-- Speed variables
local speedConn
local baseSpeed = 28
local speedEnabled = false
local stealSpeedConn = nil

-- ESP variables
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil
local eventConnections = {}

-- Timer ESP variables
local timerEspEnabled = false
local timerEspConnections = {}

-- Anti Ragdoll variables
local antiRagdollEnabled = false
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false
local ragdollConnections = {}
local cachedCharData = {}
local constraintLoopActive = false

-- Xray Base variables
local xrayBaseEnabled = false
local invisibleWallsLoaded = false
local originalTransparency = {}
local xrayBaseConnection = nil

-- Optimizer variables
local fpsBoostEnabled = false
local optimizerThreads = {}
local optimizerConnections = {}
local originalSettings = {}

local PERFORMANCE_FFLAGS = {
    ["DFIntTaskSchedulerTargetFps"] = 999, ["FFlagDebugGraphicsPreferVulkan"] = true,
    ["FFlagDebugGraphicsDisableDirect3D11"] = true, ["DFFlagDebugRenderForceTechnologyVoxel"] = true,
    ["FFlagDisablePostFx"] = true, ["FIntRenderShadowIntensity"] = 0,
    ["DFIntDebugFRMQualityLevelOverride"] = 1, ["DFIntTextureQualityOverride"] = 1,
    ["DFIntTexturePoolSizeMB"] = 64, ["FFlagDebugDisableParticleRendering"] = false,
    ["DFIntParticleMaxCount"] = 100
}

-- Anti Lag variables
local antiLagRunning = false
local antiLagConnections = {}
local cleanedCharacters = {}

-- Anti Debuff V2 variables
local antiDebuffEnabled = false
local animationPlayedConnection = nil
local BOOGIE_ANIMATION_ID = "109061983885712"
local antiBeeDiscoConnections = {}
local originalMoveFunction = nil
local controlsProtected = false
local BAD_LIGHTING_NAMES = {
    Blue = true,
    DiscoEffect = true,
    BeeBlur = true,
    ColorCorrection = true,
}

local FOV_MANAGER = {
    activeCount = 0,
    conn = nil,
    forcedFOV = 70,
}

-- No Anim During Steal variables
local unwalkAnimEnabled = false
local unwalkAnimConnections = {}

-- Steal Floor variables
local stealFloorEnabled = false
local floatPlatform = nil
local stealFloorUpdateConn = nil
local stealFloorInvisibleWallsLoaded = false
local stealFloorOriginalTransparency = {}
local stealFloorXrayConnection = nil
local stealFloorStealingMonitor = nil

-- Auto Medusa variables
local autoMedusaEnabled = false
local autoMedusaThread = nil
local detectionRange = 15
local medusaItemName = "Medusa's Head"
local MEDUSA_COOLDOWN = 25
local lastMedusaActivate = 0
local serverTimeOffset = 0

-- Carpet Speed variables
local carpetSpeedEnabled = false
local carpetSpeed = 260
local carpetConn = nil

-- Esp Best variables
local espBestEnabled = false
local espBestConnection = nil
local highestValueESP = nil
local highestValueData = nil

-- High Value Notify variables
local highValueNotifyEnabled = false
local notifySound = nil
local lastNotifiedModel = nil

-- ==================== INF JUMP FUNCTIONS ====================
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
        if infiniteJumpEnabled then
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

local function updateGravity()
    if lowGravityEnabled then
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            if bodyForce then
                bodyForce:Destroy()
            end
            bodyForce = Instance.new("BodyForce")
            bodyForce.Name = "LowGravityForce"
            bodyForce.Parent = character.HumanoidRootPart
            local force = (defaultGravity - lowGravityForce) * character.HumanoidRootPart:GetMass()
            bodyForce.Force = Vector3.new(0, force, 0)
        end
    else
        if bodyForce then
            bodyForce:Destroy()
            bodyForce = nil
        end
    end
end

local function toggleInfJump(enabled)
    infiniteJumpEnabled = enabled
    lowGravityEnabled = enabled
    
    if enabled then
        local char = player.Character
        if char then
            initializeJumpForCharacter(char)
        end
        updateGravity()
    else
        if jumpRequestConnection then
            jumpRequestConnection:Disconnect()
            jumpRequestConnection = nil
        end
        updateGravity()
    end
end

local function startStealSpeed()
    if stealSpeedConn then return end

    stealSpeedConn = S.RunService.Heartbeat:Connect(function()
        if not speedEnabled then return end
        if not player:GetAttribute("Stealing") then return end

        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local move = hum.MoveDirection
        if move.Magnitude > 0 then
            hrp.AssemblyLinearVelocity = Vector3.new(
                move.X * baseSpeed,
                hrp.AssemblyLinearVelocity.Y,
                move.Z * baseSpeed
            )
        end
    end)
end

local function stopStealSpeed()
    if stealSpeedConn then
        stealSpeedConn:Disconnect()
        stealSpeedConn = nil
    end
end

local function toggleSpeed(enabled)
    speedEnabled = enabled
    if enabled then
        player:GetAttributeChangedSignal("Stealing"):Connect(function()
            if player:GetAttribute("Stealing") then
                startStealSpeed()
            else
                stopStealSpeed()
            end
        end)
        
        if player:GetAttribute("Stealing") then
            startStealSpeed()
        end
    else
        stopStealSpeed()
    end
end

-- ==================== ESP FUNCTIONS ====================
local function getEquippedItem(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then
                return child.Name
            end
        end
    end
    
    return "None"
end

local function createESP(targetPlayer)
    if targetPlayer == player then return end
    
    if not targetPlayer.Character then
        targetPlayer.CharacterAdded:Connect(function()
            if espPlayersEnabled then
                task.wait(1)
                createESP(targetPlayer)
            end
        end)
        return
    end
    
    local character = targetPlayer.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(200, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPInfo"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 18)
    itemLabel.Position = UDim2.new(0, 0, 0, 22)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item: None"
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    itemLabel.TextStrokeTransparency = 0.5
    itemLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextSize = 12
    itemLabel.Parent = billboard
    
    espObjects[targetPlayer] = {
        highlight = highlight,
        billboard = billboard,
        itemLabel = itemLabel,
        character = character
    }
end

local function removeESP(targetPlayer)
    if espObjects[targetPlayer] then
        if espObjects[targetPlayer].highlight then
            espObjects[targetPlayer].highlight:Destroy()
        end
        if espObjects[targetPlayer].billboard then
            espObjects[targetPlayer].billboard:Destroy()
        end
        espObjects[targetPlayer] = nil
    end
end

local function updateESP()
    if not espPlayersEnabled then return end
    
    for targetPlayer, espData in pairs(espObjects) do
        if targetPlayer and targetPlayer.Parent and espData.character and espData.character.Parent then
            local character = espData.character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local equippedItem = getEquippedItem(character)
                espData.itemLabel.Text = "Item: " .. equippedItem
                
                if equippedItem ~= "None" then
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                else
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                end
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
    
    local addedConn = S.Players.PlayerAdded:Connect(function(targetPlayer)
        if espPlayersEnabled then
            createESP(targetPlayer)
        end
    end)
    table.insert(eventConnections, addedConn)
    
    local removingConn = S.Players.PlayerRemoving:Connect(function(targetPlayer)
        removeESP(targetPlayer)
    end)
    table.insert(eventConnections, removingConn)
    
    updateConnection = S.RunService.RenderStepped:Connect(updateESP)
end

local function disableESPPlayers()
    if not espPlayersEnabled then return end
    espPlayersEnabled = false
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    for _, conn in pairs(eventConnections) do
        if conn then conn:Disconnect() end
    end
    eventConnections = {}
    
    for targetPlayer, _ in pairs(espObjects) do
        removeESP(targetPlayer)
    end
    espObjects = {}
end

local function toggleEspPlayers(state)
    if state then
        enableESPPlayers()
    else
        disableESPPlayers()
    end
end

-- ==================== TIMER ESP FUNCTIONS ====================
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
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                label.TextScaled = true
                label.TextColor3 = Color3.fromRGB(255, 255, 0)
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
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    label.TextScaled = true
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                end
            end
        end
    else
        if existing then
            existing:Destroy()
        end
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
    for _, plot in pairs(S.Workspace:FindFirstChild("Plots"):GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if purchases then
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
                            local isUnlocked = not locked.Visible
                            local displayText = isUnlocked and "Unlocked" or remTime.Text
                            updateBillboard(main, displayText, stillTarget, isUnlocked)
                        end

                        local conn1 = remTime:GetPropertyChangedSignal("Text"):Connect(refresh)
                        local conn2 = locked:GetPropertyChangedSignal("Visible"):Connect(refresh)
                        timerEspConnections[key] = {conn1, conn2}
                    end
                end
            end
        end
    end
end

local function enableTimerESP()
    if timerEspEnabled then return end
    timerEspEnabled = true

    task.spawn(function()
        while timerEspEnabled do
            pcall(scanAndConnect)
            task.wait(5)
        end
    end)
end

local function disableTimerESP()
    if not timerEspEnabled then return end
    timerEspEnabled = false

    for _, plot in pairs(S.Workspace:FindFirstChild("Plots"):GetChildren()) do
        local purchases = plot:FindFirstChild("Purchases")
        if purchases then
            for _, purchase in pairs(purchases:GetChildren()) do
                local main = purchase:FindFirstChild("Main")
                if main then
                    local gui = main:FindFirstChild("RemainingTimeGui")
                    if gui then
                        gui:Destroy()
                    end
                end
            end
        end
    end

    for _, connections in pairs(timerEspConnections) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    timerEspConnections = {}
end

local function toggleTimerESP(state)
    if state then
        enableTimerESP()
    else
        disableTimerESP()
    end
end

-- ==================== ANTI RAGDOLL FUNCTIONS ====================
local function stopRagdoll()
    if not ragdollActive then return end
    ragdollActive = false
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    hum.PlatformStand = false
    root.CanCollide = true
    if root.Anchored then root.Anchored = false end
    
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then
            for _, c in part:GetChildren() do
                if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then c:Destroy() end
            end
            local motor = part:FindFirstChildWhichIsA("Motor6D")
            if motor then motor.Enabled = true end
        end
    end
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
    S.Workspace.CurrentCamera.CameraSubject = hum
end

local function startRagdollTimer()
    if ragdollTimer then ragdollTimer:Disconnect() end
    ragdollActive = true
    ragdollTimer = S.RunService.Heartbeat:Connect(function()
        ragdollTimer:Disconnect(); ragdollTimer = nil
        stopRagdoll()
    end)
end

local function watchHumanoidStates(char)
    local hum = char:WaitForChild("Humanoid")
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() end
    humanoidWatchConnection = hum.StateChanged:Connect(function(_, newState)
        if not antiRagdollEnabled then return end
        if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Physics then
            if not ragdollActive then hum.PlatformStand = true; startRagdollTimer() end
        elseif newState == Enum.HumanoidStateType.GettingUp or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
            hum.PlatformStand = false
            if ragdollActive then stopRagdoll() end
        end
    end)
end

local function cacheCharacterData()
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = { character = char, humanoid = hum, root = root }
    return true
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then return true end
    local endTime = player:GetAttribute("RagdollEndTime")
    if endTime and (endTime - S.Workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    for _, d in ipairs(cachedCharData.character:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function() player:SetAttribute("RagdollEndTime", S.Workspace:GetServerTimeNow()) end)
    if cachedCharData.humanoid.Health > 0 then cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running) end
    cachedCharData.root.Anchored = false
    cachedCharData.root.AssemblyLinearVelocity = Vector3.zero
    cachedCharData.root.AssemblyAngularVelocity = Vector3.zero
    cachedCharData.humanoid.PlatformStand = false
end

local function constraintRemovalLoop()
    while constraintLoopActive and cachedCharData.humanoid do
        task.wait()
        if isRagdolled() then removeRagdollConstraints(); forceExitRagdoll() end
    end
end

local function setupCameraBinding()
    if not cachedCharData.humanoid then return end
    local conn = S.RunService.RenderStepped:Connect(function()
        if not constraintLoopActive then return end
        local cam = S.Workspace.CurrentCamera
        if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    table.insert(ragdollConnections, conn)
end

local function setupCharacter(char)
    task.wait(0.5)
    if not antiRagdollEnabled then return end
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    watchHumanoidStates(char)
    if cacheCharacterData() then setupCameraBinding(); task.spawn(constraintRemovalLoop) end
end

local function enableAntiRagdoll()
    antiRagdollEnabled = true
    constraintLoopActive = true
    if player.Character then setupCharacter(player.Character) end
    local charConn = player.CharacterAdded:Connect(setupCharacter)
    table.insert(ragdollConnections, charConn)
end

local function disableAntiRagdoll()
    antiRagdollEnabled = false
    constraintLoopActive = false
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect(); humanoidWatchConnection = nil end
    for _, conn in ipairs(ragdollConnections) do pcall(function() conn:Disconnect() end) end
    ragdollConnections = {}
    cachedCharData = {}
end

local function toggleAntiRagdoll(state)
    if state then
        enableAntiRagdoll()
    else
        disableAntiRagdoll()
    end
end

-- ==================== XRAY BASE FUNCTIONS ====================
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

local function toggleXrayBase(state)
    if state then
        enableXrayBase()
    else
        disableXrayBase()
    end
end

-- ==================== OPTIMIZER FUNCTIONS ====================
local function storeOriginalSettings()
    pcall(function()
        originalSettings = {
            qualityLevel = settings().Rendering.QualityLevel,
            globalShadows = S.Lighting.GlobalShadows,
            brightness = S.Lighting.Brightness,
            fogEnd = S.Lighting.FogEnd,
            decoration = S.Workspace.Terrain.Decoration,
            waterWaveSize = S.Workspace.Terrain.WaterWaveSize,
        }
    end)
end

local function applyFFlags()
    for flag, value in pairs(PERFORMANCE_FFLAGS) do
        pcall(function() setfflag(flag, tostring(value)) end)
    end
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

local function enableFpsBoost()
    if fpsBoostEnabled then return end
    fpsBoostEnabled = true
    getgenv().OPTIMIZER_ACTIVE = true
    storeOriginalSettings()
    
    pcall(applyFFlags)
    
    pcall(function()
        S.Workspace.StreamingEnabled = true
        S.Workspace.StreamingMinRadius = 64
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        S.Lighting.GlobalShadows = false
        S.Lighting.FogEnd = 9e9
        S.Lighting.Technology = Enum.Technology.Legacy
        S.Workspace.Terrain.Decoration = false
    end)
    
    table.insert(optimizerThreads, task.spawn(function() task.wait(1); nukeVisualEffects() end))
    
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
        table.insert(optimizerConnections, p.CharacterAdded:Connect(function(char) if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end end))
    end
    
    pcall(function() setfpscap(999) end)
end

local function disableFpsBoost()
    if not fpsBoostEnabled then return end
    fpsBoostEnabled = false
    getgenv().OPTIMIZER_ACTIVE = false
    
    for _, t in ipairs(optimizerThreads) do pcall(function() task.cancel(t) end) end
    optimizerThreads = {}
    for _, c in ipairs(optimizerConnections) do pcall(function() c:Disconnect() end) end
    optimizerConnections = {}
    
    pcall(function()
        settings().Rendering.QualityLevel = originalSettings.qualityLevel or Enum.QualityLevel.Automatic
        S.Lighting.GlobalShadows = originalSettings.globalShadows ~= false
        S.Workspace.Terrain.Decoration = originalSettings.decoration ~= false
    end)
end

local function toggleOptimizer(state)
    if state then
        enableFpsBoost()
    else
        disableFpsBoost()
    end
end

-- ==================== ANTI LAG FUNCTIONS ====================
local function destroyAllEquippableItems(character)
    if not character then return end
    if not antiLagRunning then return end
    
    pcall(function()
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Hat") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
                child:Destroy()
            end
        end
        
        local bodyColors = character:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors:Destroy()
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("CharacterMesh") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child.ClassName == "LayeredClothing" or child.ClassName == "WrapLayer" then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                local mesh = child:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh:Destroy()
                end
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Highlight") then
                child:Destroy()
            end
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
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
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
                if antiLagRunning then
                    task.wait(0.1)
                    destroyBackpackTools(plr)
                end
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
                if antiLagRunning then
                    task.wait(0.1)
                    destroyBackpackTools(plr)
                end
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
    
    table.insert(antiLagConnections, task.spawn(function()
        while antiLagRunning do
            task.wait(3)
            
            for _, plr in ipairs(S.Players:GetPlayers()) do
                if plr.Character and not cleanedCharacters[plr.Character] then
                    antiLagCleanCharacter(plr.Character)
                    destroyBackpackTools(plr)
                end
            end
        end
    end))
end

local function disableAntiLag()
    if not antiLagRunning then return end
    antiLagRunning = false
    antiLagDisconnectAll()
end

local function toggleAntiLag(state)
    if state then
        enableAntiLag()
    else
        disableAntiLag()
    end
end

-- ==================== ANTI DEBUFF V2 FUNCTIONS ====================
function FOV_MANAGER:Start()
    if self.conn then return end
    
    self.conn = S.RunService.RenderStepped:Connect(function()
        local cam = S.Workspace.CurrentCamera
        if cam and cam.FieldOfView ~= self.forcedFOV then
            cam.FieldOfView = self.forcedFOV
        end
    end)
end

function FOV_MANAGER:Stop()
    if self.conn then
        self.conn:Disconnect()
        self.conn = nil
    end
end

function FOV_MANAGER:Push()
    self.activeCount += 1
    self:Start()
end

function FOV_MANAGER:Pop()
    if self.activeCount > 0 then
        self.activeCount -= 1
    end
    if self.activeCount == 0 then
        self:Stop()
    end
end

local function setupInstantAnimationBlocker()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    if animationPlayedConnection then 
        animationPlayedConnection:Disconnect() 
    end
    
    animationPlayedConnection = animator.AnimationPlayed:Connect(function(track)
        if not antiDebuffEnabled then return end
        if track and track.Animation then
            if tostring(track.Animation.AnimationId):gsub("%D", "") == BOOGIE_ANIMATION_ID then
                track:Stop(0)
                track:Destroy()
            end
        end
    end)
end

local function antiBeeDiscoNuke(obj)
    if not obj or not obj.Parent then return end
    if not antiDebuffEnabled then return end
    if BAD_LIGHTING_NAMES[obj.Name] then
        pcall(function()
            obj:Destroy()
        end)
    end
end

local function antiBeeDiscoDisconnectAll()
    for _, conn in ipairs(antiBeeDiscoConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    antiBeeDiscoConnections = {}
end

local function protectControls()
    if controlsProtected then return end
    
    pcall(function()
        local PlayerScripts = player.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        
        local Controls = require(PlayerModule):GetControls()
        if not Controls then return end
        
        if not originalMoveFunction then
            originalMoveFunction = Controls.moveFunction
        end
        
        local function protectedMoveFunction(self, moveVector, relativeToCamera)
            if originalMoveFunction then
                originalMoveFunction(self, moveVector, relativeToCamera)
            end
        end
        
        local controlCheckConn = S.RunService.Heartbeat:Connect(function()
            if not antiDebuffEnabled then return end
            
            if Controls.moveFunction ~= protectedMoveFunction then
                Controls.moveFunction = protectedMoveFunction
            end
        end)
        
        table.insert(antiBeeDiscoConnections, controlCheckConn)
        
        Controls.moveFunction = protectedMoveFunction
        controlsProtected = true
    end)
end

local function blockBuzzingSound()
    if not antiDebuffEnabled then return end
    pcall(function()
        local PlayerScripts = player.PlayerScripts
        local beeScript = PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then
                buzzing:Stop()
                buzzing.Volume = 0
            end
        end
    end)
end

local function enableAntiDebuff()
    if antiDebuffEnabled then return end
    antiDebuffEnabled = true
    
    setupInstantAnimationBlocker()
    
    for _, inst in ipairs(S.Lighting:GetDescendants()) do
        antiBeeDiscoNuke(inst)
    end
    
    table.insert(antiBeeDiscoConnections, S.Lighting.DescendantAdded:Connect(function(obj)
        antiBeeDiscoNuke(obj)
    end))
    
    protectControls()
    
    table.insert(antiBeeDiscoConnections, S.RunService.Heartbeat:Connect(function()
        blockBuzzingSound()
    end))
    
    FOV_MANAGER:Push()
end

local function disableAntiDebuff()
    if not antiDebuffEnabled then return end
    antiDebuffEnabled = false
    
    if animationPlayedConnection then
        animationPlayedConnection:Disconnect()
        animationPlayedConnection = nil
    end
    
    antiBeeDiscoDisconnectAll()
    controlsProtected = false
    originalMoveFunction = nil
    
    FOV_MANAGER:Pop()
end

local function toggleAntiDebuff(state)
    if state then
        enableAntiDebuff()
    else
        disableAntiDebuff()
    end
end

-- ==================== NO ANIM DURING STEAL FUNCTIONS ====================
local function setupNoWalkAnimation(character)
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
    
    local runningConnection = humanoid.Running:Connect(function(speed)
        stopAllAnimations()
    end)
    
    local jumpingConnection = humanoid.Jumping:Connect(function()
        stopAllAnimations()
    end)
    
    local animationPlayedConnection = animator.AnimationPlayed:Connect(function(animationTrack)
        animationTrack:Stop()
    end)
    
    local renderSteppedConnection = S.RunService.RenderStepped:Connect(function()
        stopAllAnimations()
    end)
    
    table.insert(unwalkAnimConnections, runningConnection)
    table.insert(unwalkAnimConnections, jumpingConnection)
    table.insert(unwalkAnimConnections, animationPlayedConnection)
    table.insert(unwalkAnimConnections, renderSteppedConnection)
end

local function enableUnwalkAnim()
    if unwalkAnimEnabled then return end
    unwalkAnimEnabled = true
    
    if player.Character then
        setupNoWalkAnimation(player.Character)
    end
    
    local charConn = player.CharacterAdded:Connect(setupNoWalkAnimation)
    table.insert(unwalkAnimConnections, charConn)
end

local function disableUnwalkAnim()
    if not unwalkAnimEnabled then return end
    unwalkAnimEnabled = false
    
    for _, connection in pairs(unwalkAnimConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    unwalkAnimConnections = {}
end

local stealingMonitorConn = nil

local function enableNoAnimDuringSteal()
    if stealingMonitorConn then return end
    
    stealingMonitorConn = player:GetAttributeChangedSignal("Stealing"):Connect(function()
        local isStealing = player:GetAttribute("Stealing")
        
        if isStealing then
            enableUnwalkAnim()
        else
            disableUnwalkAnim()
        end
    end)
    
    if player:GetAttribute("Stealing") then
        enableUnwalkAnim()
    end
end

local function disableNoAnimDuringSteal()
    if stealingMonitorConn then
        stealingMonitorConn:Disconnect()
        stealingMonitorConn = nil
    end
    
    disableUnwalkAnim()
end

local function toggleNoAnimDuringSteal(state)
    if state then
        enableNoAnimDuringSteal()
    else
        disableNoAnimDuringSteal()
    end
end

-- ==================== STEAL FLOOR FUNCTIONS ====================
local function getHRP()
    local c = player.Character
    if not c then return end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function startFloorSteal()
    if floatPlatform then floatPlatform:Destroy() end
    
    floatPlatform = Instance.new("Part")
    floatPlatform.Size = Vector3.new(6, 1, 6)
    floatPlatform.Anchored = true
    floatPlatform.CanCollide = true
    floatPlatform.Transparency = 1
    floatPlatform.Parent = S.Workspace
    
    stealFloorUpdateConn = task.spawn(function()
        while stealFloorEnabled and floatPlatform do
            local hrp = getHRP()
            if hrp then
                floatPlatform.Position = hrp.Position - Vector3.new(0, 3, 0)
            end
            task.wait(0.05)
        end
    end)
end

local function stopFloorSteal()
    if floatPlatform then
        floatPlatform:Destroy()
        floatPlatform = nil
    end
    if stealFloorUpdateConn then
        task.cancel(stealFloorUpdateConn)
        stealFloorUpdateConn = nil
    end
end

local function isStealFloorBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    local parent = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or parent:find("base")
end

local function tryApplyStealFloorInvisibleWalls()
    if not stealFloorEnabled or stealFloorInvisibleWallsLoaded then return end
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots or #plots:GetChildren() == 0 then return end
    
    for _, plot in pairs(plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and isStealFloorBaseWall(obj) then
                if not stealFloorOriginalTransparency[obj] then
                    stealFloorOriginalTransparency[obj] = obj.LocalTransparencyModifier
                    obj.LocalTransparencyModifier = 0.85
                end
            end
        end
    end
    stealFloorInvisibleWallsLoaded = true
end

local function enableStealFloorXray()
    if stealFloorInvisibleWallsLoaded then return end
    stealFloorInvisibleWallsLoaded = false
    
    tryApplyStealFloorInvisibleWalls()
    
    stealFloorXrayConnection = S.Workspace.DescendantAdded:Connect(function(obj)
        if not stealFloorEnabled then return end
        task.wait(0.1)
        if isStealFloorBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
            if not stealFloorOriginalTransparency[obj] then
                stealFloorOriginalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
end

local function disableStealFloorXray()
    stealFloorInvisibleWallsLoaded = false
    
    if stealFloorXrayConnection then 
        stealFloorXrayConnection:Disconnect()
        stealFloorXrayConnection = nil 
    end
    
    for obj, value in pairs(stealFloorOriginalTransparency) do
        if obj and obj.Parent then 
            pcall(function() obj.LocalTransparencyModifier = value end) 
        end
    end
    stealFloorOriginalTransparency = {}
end

local function enableStealFloor()
    if stealFloorEnabled then return end
    stealFloorEnabled = true
    
    startFloorSteal()
    enableStealFloorXray()
end

local function disableStealFloor()
    if not stealFloorEnabled then return end
    stealFloorEnabled = false
    
    stopFloorSteal()
    disableStealFloorXray()
    
    if stealFloorStealingMonitor then
        stealFloorStealingMonitor:Disconnect()
        stealFloorStealingMonitor = nil
    end
end

local function toggleStealFloor(state)
    if state then
        enableStealFloor()
    else
        disableStealFloor()
    end
end

-- ==================== AUTO MEDUSA FUNCTIONS ====================
local function syncServerTime()
    local sendTime = os.clock()
    local ping = 0
    pcall(function()
        local serverTime = S.Workspace:GetServerTimeNow()
        local receiveTime = os.clock()
        ping = (receiveTime - sendTime) / 2
        serverTimeOffset = serverTime - os.clock() - ping
    end)
end

local function getServerTime()
    return os.clock() + serverTimeOffset
end

local function isMedusaOnCooldown()
    local currentTime = getServerTime()
    local timeSinceLast = currentTime - lastMedusaActivate
    return timeSinceLast < MEDUSA_COOLDOWN, math.max(0, MEDUSA_COOLDOWN - timeSinceLast)
end

local function findMedusaTool()
    local tool = nil
    pcall(function()
        tool = player.Backpack:FindFirstChild(medusaItemName)
        if not tool and player.Character then
            tool = player.Character:FindFirstChild(medusaItemName)
        end
    end)
    return tool
end

local function equipMedusa()
    local medusaTool = findMedusaTool()
    if medusaTool and medusaTool.Parent == player.Backpack then
        pcall(function()
            player.Character.Humanoid:EquipTool(medusaTool)
        end)
        task.wait(0.1)
        return player.Character:FindFirstChild(medusaItemName) ~= nil
    end
    if medusaTool and medusaTool.Parent == player.Character then
        return true
    end
    return false
end

local function isValidTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or targetPlayer == player then return false end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function findNearestPlayer()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = player.Character.HumanoidRootPart.Position
    local nearest = nil
    local nearestDist = math.huge
    pcall(function()
        for _, targetPlayer in ipairs(S.Players:GetPlayers()) do
            if isValidTarget(targetPlayer) then
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    local distance = (targetHRP.Position - myPos).Magnitude
                    if distance <= detectionRange and distance < nearestDist then
                        nearestDist = distance
                        nearest = targetPlayer
                    end
                end
            end
        end
    end)
    return nearest, nearestDist
end

local function activateMedusa()
    pcall(function()
        local tool = player.Character and player.Character:FindFirstChild(medusaItemName)
        if tool then
            tool:Activate()
            lastMedusaActivate = getServerTime()
        end
    end)
end

local function autoMedusaWorker()
    syncServerTime()

    while autoMedusaEnabled do
        pcall(function()
            local onCooldown, remaining = isMedusaOnCooldown()

            if onCooldown then
                task.wait(remaining)
                return
            end

            local target, distance = findNearestPlayer()
            if target then
                if equipMedusa() then
                    activateMedusa()
                    task.wait(MEDUSA_COOLDOWN)
                end
            end
        end)
        task.wait(0.1)
    end
end

local function enableAutoMedusa()
    if autoMedusaEnabled then return end
    autoMedusaEnabled = true
    
    if autoMedusaThread then
        task.cancel(autoMedusaThread)
    end
    
    autoMedusaThread = task.spawn(autoMedusaWorker)
end

local function disableAutoMedusa()
    if not autoMedusaEnabled then return end
    autoMedusaEnabled = false
    
    if autoMedusaThread then
        task.cancel(autoMedusaThread)
        autoMedusaThread = nil
    end
end

local function toggleAutoMedusa(state)
    if state then
        enableAutoMedusa()
    else
        disableAutoMedusa()
    end
end

-- ==================== CARPET SPEED FUNCTIONS ====================
local function equipFlyingCarpet()
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character

    if not character then return false end

    local carpetNames = {"Flying Carpet", "FlyingCarpet", "flying carpet", "flyingcarpet"}

    for _, name in ipairs(carpetNames) do
        if character:FindFirstChild(name) then
            return true
        end
    end

    local carpetTool = nil
    for _, name in ipairs(carpetNames) do
        carpetTool = backpack:FindFirstChild(name)
        if carpetTool then break end
    end

    if carpetTool then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(carpetTool)
            task.wait(0.3)
            return true
        end
    end

    return false
end

local function startCarpet()
    if carpetConn then return end
    carpetConn = S.RunService.Heartbeat:Connect(function()
        if not carpetSpeedEnabled then return end
        
        local Char = player.Character
        if not Char then return end

        local carpetTool = nil
        local carpetNames = {"Flying Carpet", "FlyingCarpet", "flying carpet", "flyingcarpet"}
        for _, name in ipairs(carpetNames) do
            carpetTool = Char:FindFirstChild(name)
            if carpetTool then break end
        end

        if not carpetTool then return end

        local carpetPart = carpetTool:FindFirstChild("Handle") or
                           carpetTool:FindFirstChildWhichIsA("BasePart")

        if not carpetPart then return end

        local Hum = Char:FindFirstChildOfClass("Humanoid")
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        if not Hum or not HRP then return end

        local moveDir = Hum.MoveDirection

        if moveDir.Magnitude < 0.1 then
            local currentVel = carpetPart.AssemblyLinearVelocity
            carpetPart.AssemblyLinearVelocity = Vector3.new(0, currentVel.Y, 0)
            return
        end

        carpetPart.AssemblyLinearVelocity = Vector3.new(
            moveDir.X * carpetSpeed,
            carpetPart.AssemblyLinearVelocity.Y,
            moveDir.Z * carpetSpeed
        )
    end)
end

local function stopCarpet()
    if carpetConn then
        carpetConn:Disconnect()
        carpetConn = nil
    end
end

local function enableCarpetSpeed()
    if carpetSpeedEnabled then return end
    carpetSpeedEnabled = true
    
    if equipFlyingCarpet() then
        startCarpet()
    end
end

local function disableCarpetSpeed()
    if not carpetSpeedEnabled then return end
    carpetSpeedEnabled = false
    stopCarpet()
end

local function toggleCarpetSpeed(state)
    if state then
        enableCarpetSpeed()
    else
        disableCarpetSpeed()
    end
end

-- ==================== ESP BEST FUNCTIONS ====================
local function getTraitMultiplier(model)
    if not TraitsModule then return 0 end
    
    local traitJson = model:GetAttribute("Traits")
    if not traitJson or traitJson == "" then return 0 end

    local traits = {}
    local ok, decoded = pcall(function()
        return S.HttpService:JSONDecode(traitJson)
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
    
    local rounded = math.floor(value * 10 + 0.5) / 10
    if rounded == math.floor(rounded) then
        return string.format("%.0f%s", rounded, suffix)
    else
        return string.format("%.1f%s", rounded, suffix)
    end
end

local function getPlotOwner(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
        if surfaceGui then
            local frame = surfaceGui:FindFirstChild("Frame")
            if frame then
                local textLabel = frame:FindFirstChild("TextLabel")
                if textLabel then return textLabel.Text end
            end
        end
    end
    return "Unknown"
end

local function calculateDistance(part1, part2)
    if not part1 or not part2 then return 0 end
    return math.floor((part1.Position - part2.Position).Magnitude)
end

local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local yourBase = plotSign:FindFirstChild("YourBase")
        if yourBase and yourBase.Enabled then return true end
    end
    return false
end

local function findHighestBrainrot()
    local plots = S.Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local highest = {value = 0}
    
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("Model") and AnimalsModule and AnimalsModule[obj.Name] then
                    pcall(function()
                        local gen = getFinalGeneration(obj)
                        if gen > 0 and gen > highest.value then
                            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                            if root then
                                highest = {
                                    plot = plot,
                                    plotName = plot.Name,
                                    plotOwner = getPlotOwner(plot),
                                    petName = obj.Name,
                                    generation = gen,
                                    formattedValue = formatNumber(gen),
                                    model = obj,
                                    value = gen
                                }
                            end
                        end
                    end)
                end
            end
        end
    end
    
    return highest.value > 0 and highest or nil
end

local function clearHighestValueESP()
    if highestValueESP then
        if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
        if highestValueESP.billboard then highestValueESP.billboard:Destroy() end
        if highestValueESP.updateConnection then highestValueESP.updateConnection:Disconnect() end
        if highestValueESP.beamUpdateConnection then highestValueESP.beamUpdateConnection:Disconnect() end
        if highestValueESP.beam then highestValueESP.beam:Destroy() end
        if highestValueESP.attachment0 then highestValueESP.attachment0:Destroy() end
        if highestValueESP.attachment1 then highestValueESP.attachment1:Destroy() end
        highestValueESP = nil
    end
    highestValueData = nil
end

local function createHighestValueESP(brainrotData)
    if not brainrotData or not brainrotData.model then return end
    
    pcall(function()
        clearHighestValueESP()
        
        local espContainer = {}
        local model = brainrotData.model
        local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA('BasePart')
        
        if not part then return end

        -- Highlight
        local highlight = Instance.new("Highlight", model)
        highlight.Name = "BrainrotESPHighlight"
        highlight.Adornee = model
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espContainer.highlight = highlight

        -- Tracer Beam
        local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = playerRoot or S.Workspace.Terrain

        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = part

        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0))
        beam.Width0 = 0.05
        beam.Width1 = 0.05
        beam.FaceCamera = true
        beam.Segments = 1
        beam.Transparency = NumberSequence.new(0)
        beam.LightEmission = 0.5
        beam.Parent = part

        espContainer.beam = beam
        espContainer.attachment0 = attachment0
        espContainer.attachment1 = attachment1

        local beamUpdateConnection = S.RunService.Heartbeat:Connect(function()
            if not player.Character then return end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and attachment0.Parent ~= root then
                attachment0.Parent = root
            end
        end)
        espContainer.beamUpdateConnection = beamUpdateConnection

        -- Billboard GUI
        local bb = Instance.new("BillboardGui")
        bb.Name = "BrainrotESP"
        bb.Adornee = part
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 200, 0, 65)
        bb.StudsOffset = Vector3.new(0, 5, 0)
        bb.Parent = part
        
        local bgFrame = Instance.new("Frame")
        bgFrame.Size = UDim2.new(1, 0, 1, 0)
        bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bgFrame.BackgroundTransparency = 0.5
        bgFrame.BorderSizePixel = 0
        bgFrame.Parent = bb
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = bgFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 0, 0)
        stroke.Thickness = 3
        stroke.Transparency = 0
        stroke.Parent = bgFrame
        
        local bestBadge = Instance.new("Frame")
        bestBadge.Size = UDim2.new(0, 50, 0, 16)
        bestBadge.Position = UDim2.new(1, -53, 0, 4)
        bestBadge.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
        bestBadge.BorderSizePixel = 0
        bestBadge.Parent = bgFrame
        
        local bestCorner = Instance.new("UICorner")
        bestCorner.CornerRadius = UDim.new(0, 5)
        bestCorner.Parent = bestBadge
        
        local bestLabel = Instance.new("TextLabel")
        bestLabel.Size = UDim2.new(1, -8, 1, 0)
        bestLabel.Position = UDim2.new(0, 7, 0, 0)
        bestLabel.BackgroundTransparency = 1
        bestLabel.Text = "★ BEST"
        bestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        bestLabel.TextSize = 9
        bestLabel.Font = Enum.Font.FredokaOne
        bestLabel.TextXAlignment = Enum.TextXAlignment.Left
        bestLabel.Parent = bestBadge
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -65, 0, 16)
        nameLabel.Position = UDim2.new(0, 8, 0, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = brainrotData.petName or "Unknown"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextScaled = true
        nameLabel.Parent = bgFrame
        
        local nameStroke = Instance.new("UIStroke")
        nameStroke.Color = Color3.fromRGB(0, 0, 0)
        nameStroke.Thickness = 1
        nameStroke.Transparency = 0
        nameStroke.Parent = nameLabel
        
        local nameGradient = Instance.new("UIGradient")
        nameGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        })
        nameGradient.Rotation = 0
        nameGradient.Parent = nameLabel
        
        local ownerLabel = Instance.new("TextLabel")
        ownerLabel.Size = UDim2.new(1, -65, 0, 13)
        ownerLabel.Position = UDim2.new(0, 8, 0, 22)
        ownerLabel.BackgroundTransparency = 1
        ownerLabel.Text = "@ " .. (brainrotData.plotOwner or "Unknown")
        ownerLabel.TextColor3 = Color3.fromRGB(255, 253, 208)
        ownerLabel.TextSize = 11
        ownerLabel.Font = Enum.Font.Gotham
        ownerLabel.TextStrokeTransparency = 1
        ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
        ownerLabel.TextYAlignment = Enum.TextYAlignment.Center
        ownerLabel.TextScaled = true
        ownerLabel.Parent = bgFrame
        
        local ownerStroke = Instance.new("UIStroke")
        ownerStroke.Color = Color3.fromRGB(0, 0, 0)
        ownerStroke.Thickness = 1
        ownerStroke.Transparency = 0
        ownerStroke.Parent = ownerLabel
        
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, -16, 0, 1)
        divider.Position = UDim2.new(0, 8, 0, 40)
        divider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        divider.BorderSizePixel = 0
        divider.Parent = bgFrame
        
        local genLabel = Instance.new("TextLabel")
        genLabel.Size = UDim2.new(0.6, 0, 0, 16)
        genLabel.Position = UDim2.new(0, 8, 1, -19)
        genLabel.BackgroundTransparency = 1
        genLabel.Text = brainrotData.formattedValue or formatNumber(brainrotData.generation or 0)
        genLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        genLabel.TextSize = 14
        genLabel.Font = Enum.Font.GothamBold
        genLabel.TextStrokeTransparency = 1
        genLabel.TextXAlignment = Enum.TextXAlignment.Left
        genLabel.TextYAlignment = Enum.TextYAlignment.Center
        genLabel.TextScaled = true
        genLabel.Parent = bgFrame
        
        local genStroke = Instance.new("UIStroke")
        genStroke.Color = Color3.fromRGB(0, 0, 0)
        genStroke.Thickness = 1
        genStroke.Transparency = 0
        genStroke.Parent = genLabel
        
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Size = UDim2.new(0.35, 0, 0, 16)
        distanceLabel.Position = UDim2.new(1, -78, 1, -19)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextColor3 = Color3.fromHex("#D2B48C")
        distanceLabel.TextSize = 12
        distanceLabel.Font = Enum.Font.GothamBold
        distanceLabel.TextStrokeTransparency = 1
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
        distanceLabel.TextYAlignment = Enum.TextYAlignment.Center
        distanceLabel.TextScaled = true
        distanceLabel.Parent = bgFrame
        
        local distanceStroke = Instance.new("UIStroke")
        distanceStroke.Color = Color3.fromRGB(0, 0, 0)
        distanceStroke.Thickness = 1
        distanceStroke.Transparency = 0
        distanceStroke.Parent = distanceLabel
        
        local updateConnection = S.RunService.Heartbeat:Connect(function()
            if not distanceLabel.Parent or not player.Character then
                return
            end
            local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot and part and part.Parent then
                local distance = calculateDistance(playerRoot, part)
                distanceLabel.Text = distance .. "m"
            end
        end)
        
        espContainer.billboard = bb
        espContainer.updateConnection = updateConnection
        highestValueESP = espContainer
        highestValueData = brainrotData
    end)
end

local function checkPetExists()
    if not highestValueData then return false end
    local exists = false
    pcall(function()
        if highestValueData.model and highestValueData.model.Parent then
            exists = true
        end
    end)
    return exists
end

local function updateHighestValueESP()
    if highestValueData and not checkPetExists() then
        clearHighestValueESP()
    end
    
    local newHighest = findHighestBrainrot()
    
    if newHighest then
        if not highestValueData or newHighest.value > highestValueData.value then
            createHighestValueESP(newHighest)
            
            -- Trigger notify kalau high value notify on dan model berbeza
            if highValueNotifyEnabled and lastNotifiedModel ~= newHighest.model then
                lastNotifiedModel = newHighest.model
                playNotifySound()
            end
        end
    end
end

local function enableEspBest()
    if espBestEnabled then return end
    espBestEnabled = true
    
    updateHighestValueESP()
    
    espBestConnection = task.spawn(function()
        while espBestEnabled do
            task.wait(1)
            updateHighestValueESP()
        end
    end)
end

local function disableEspBest()
    if not espBestEnabled then return end
    espBestEnabled = false
    
    if espBestConnection then
        task.cancel(espBestConnection)
        espBestConnection = nil
    end
    
    clearHighestValueESP()
end

local function toggleEspBest(state)
    if state then
        enableEspBest()
    else
        disableEspBest()
    end
end

-- ==================== HIGH VALUE NOTIFY FUNCTIONS ====================
local function playNotifySound()
    if notifySound and notifySound.Parent then
        notifySound:Stop()
        notifySound:Destroy()
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://138118203571469"
    sound.Volume = 1.5
    sound.Parent = S.Workspace
    sound:Play()
    notifySound = sound
    
    task.delay(5, function()
        if sound and sound.Parent then
            sound:Stop()
            sound:Destroy()
        end
    end)
end

local function enableHighValueNotify()
    highValueNotifyEnabled = true
end

local function disableHighValueNotify()
    highValueNotifyEnabled = false
    lastNotifiedModel = nil
    if notifySound and notifySound.Parent then
        notifySound:Stop()
        notifySound:Destroy()
        notifySound = nil
    end
end

local function toggleHighValueNotify(state)
    if state then
        enableHighValueNotify()
    else
        disableHighValueNotify()
    end
end

-- ========== QUICK PANEL ==========

-- Inf Jump Toggle
local infJumpToggle
local infJumpRespawnConn

infJumpToggle = QuickPanel:AddToggle({
    Title = "Inf Jump",
    Default = false,
    Callback = function(value)
        toggleInfJump(value)
        QuickPanel:Notify("Inf Jump: " .. (value and "On" or "Off"))
        
        if value then
            if infJumpRespawnConn then
                infJumpRespawnConn:Disconnect()
            end
            
            infJumpRespawnConn = player.CharacterAdded:Connect(function()
                if infiniteJumpEnabled then
                    toggleInfJump(false)
                    task.wait(0.5)
                    toggleInfJump(true)
                end
            end)
        else
            if infJumpRespawnConn then
                infJumpRespawnConn:Disconnect()
                infJumpRespawnConn = nil
            end
        end
    end
})

-- Speed Toggle
QuickPanel:AddToggle({
    Title = "Speed",
    Default = false,
    Callback = function(value)
        toggleSpeed(value)
        QuickPanel:Notify("Speed: " .. (value and "On" or "Off"))
    end
})

-- Tp to Best Button
QuickPanel:AddButton({
    Title = "Tp to Best",
    Callback = function()
        QuickPanel:Notify("Tp to Best")
        -- Function akan ditambah nanti
    end
})

-- Declare dulu
local stealFloorToggle

-- Assign tanpa 'local'
stealFloorToggle = QuickPanel:AddToggle({
    Title = "Steal Floor",
    Default = false,
    Callback = function(value)
        toggleStealFloor(value)
        QuickPanel:Notify("Steal Floor: " .. (value and "On" or "Off"))
        
        if value then
            stealFloorStealingMonitor = player:GetAttributeChangedSignal("Stealing"):Connect(function()
                local isStealing = player:GetAttribute("Stealing")
                if isStealing then
                    stealFloorToggle.SetState(false)
                end
            end)
        else
            if stealFloorStealingMonitor then
                stealFloorStealingMonitor:Disconnect()
                stealFloorStealingMonitor = nil
            end
        end
    end
})

-- ========== MAIN HUB ==========

-- ESP Players Toggle di Tab Visual
MainHub:AddToggle({
    Tab = "Visual",
    Title = "ESP Players",
    Default = false,
    Callback = function(value)
        toggleEspPlayers(value)
        MainHub:Notify("ESP Players: " .. (value and "On" or "Off"))
    end
})

-- Timer ESP Toggle di Tab Visual
MainHub:AddToggle({
    Tab = "Visual",
    Title = "Timer Esp",
    Default = false,
    Callback = function(value)
        toggleTimerESP(value)
        MainHub:Notify("Timer Esp: " .. (value and "On" or "Off"))
    end
})

-- Esp Best Toggle di Tab Visual
MainHub:AddToggle({
    Tab = "Visual",
    Title = "Esp Best",
    Default = false,
    Callback = function(value)
        toggleEspBest(value)
        MainHub:Notify("Esp Best: " .. (value and "On" or "Off"))
    end
})

-- High Value Notify Toggle di Tab Visual
MainHub:AddToggle({
    Tab = "Visual",
    Title = "High Value Notify",
    Default = false,
    Callback = function(value)
        toggleHighValueNotify(value)
        MainHub:Notify("High Value Notify: " .. (value and "On" or "Off"))
    end
})

-- Anti Ragdoll Toggle di Tab Misc
MainHub:AddToggle({
    Tab = "Misc",
    Title = "Anti Ragdoll",
    Default = false,
    Callback = function(value)
        toggleAntiRagdoll(value)
        MainHub:Notify("Anti Ragdoll: " .. (value and "On" or "Off"))
    end
})

-- Xray Base Toggle di Tab Misc
MainHub:AddToggle({
    Tab = "Misc",
    Title = "Xray Base",
    Default = false,
    Callback = function(value)
        toggleXrayBase(value)
        MainHub:Notify("Xray Base: " .. (value and "On" or "Off"))
    end
})

-- Optimizer Toggle di Tab Misc
MainHub:AddToggle({
    Tab = "Misc",
    Title = "Optimizer",
    Default = false,
    Callback = function(value)
        toggleOptimizer(value)
        MainHub:Notify("Optimizer: " .. (value and "On" or "Off"))
    end
})

-- Anti Lag Toggle di Tab Misc
MainHub:AddToggle({
    Tab = "Misc",
    Title = "Anti Lag",
    Default = false,
    Callback = function(value)
        toggleAntiLag(value)
        MainHub:Notify("Anti Lag: " .. (value and "On" or "Off"))
    end
})

-- Anti Debuff V2 Toggle di Tab Misc
MainHub:AddToggle({
    Tab = "Misc",
    Title = "Anti Debuff V2",
    Default = false,
    Callback = function(value)
        toggleAntiDebuff(value)
        MainHub:Notify("Anti Debuff V2: " .. (value and "On" or "Off"))
    end
})

-- No Anim During Steal Toggle di Tab Stealer
MainHub:AddToggle({
    Tab = "Stealer",
    Title = "No Anim During Steal",
    Default = false,
    Callback = function(value)
        toggleNoAnimDuringSteal(value)
        MainHub:Notify("No Anim During Steal: " .. (value and "On" or "Off"))
    end
})

-- Auto Medusa Toggle di Tab Stealer
MainHub:AddToggle({
    Tab = "Stealer",
    Title = "Auto Medusa",
    Default = false,
    Callback = function(value)
        toggleAutoMedusa(value)
        MainHub:Notify("Auto Medusa: " .. (value and "On" or "Off"))
    end
})

-- Carpet Speed Toggle di Tab Stealer
MainHub:AddToggle({
    Tab = "Stealer",
    Title = "Carpet Speed",
    Default = false,
    Callback = function(value)
        toggleCarpetSpeed(value)
        MainHub:Notify("Carpet Speed: " .. (value and "On" or "Off"))
    end
})
