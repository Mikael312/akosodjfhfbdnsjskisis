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
    Lighting = game:GetService("Lighting")
}
local player = S.Players.LocalPlayer

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

-- ESP variables
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil
local eventConnections = {}

-- Timer ESP variables
local timerEspEnabled = false
local timerEspConnections = {}

-- Esp Base Line variables
local baseLineEnabled = false
local baseLineConnection = nil
local baseBeamPart = nil
local baseTargetPart = nil
local baseBeam = nil

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
local noAnimDuringStealEnabled = false
local animDisableConn = nil
local originalAnimIds = {}
local animateScript = nil

local ANIM_TYPES = {
    "walk", "run", "jump", "fall"
}
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

-- ==================== SPEED FUNCTIONS ====================
local function GetCharacter()
    local Char = player.Character or player.CharacterAdded:Wait()
    local HRP = Char:WaitForChild("HumanoidRootPart")
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    return Char, HRP, Hum
end

local function getMovementInput()
    local Char, HRP, Hum = GetCharacter()
    if not Char or not HRP or not Hum then return Vector3.new(0,0,0) end
    local moveVector = Hum.MoveDirection
    if moveVector.Magnitude > 0.1 then
        return Vector3.new(moveVector.X, 0, moveVector.Z).Unit
    end
    return Vector3.new(0,0,0)
end

local function startSpeedControl()
    if speedConn then return end
    speedConn = S.RunService.Heartbeat:Connect(function()
        local Char, HRP, Hum = GetCharacter()
        if not Char or not HRP or not Hum then return end
        
        local inputDirection = getMovementInput()
        
        if inputDirection.Magnitude > 0 then
            HRP.AssemblyLinearVelocity = Vector3.new(
                inputDirection.X * baseSpeed,
                HRP.AssemblyLinearVelocity.Y,
                inputDirection.Z * baseSpeed
            )
        else
            HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
        end
    end)
end

local function stopSpeedControl()
    if speedConn then 
        speedConn:Disconnect() 
        speedConn = nil 
    end
    local _, HRP = GetCharacter()
    if HRP then 
        HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) 
    end
end

local function toggleSpeed(enabled)
    speedEnabled = enabled
    if enabled then
        startSpeedControl()
    else
        stopSpeedControl()
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
            gui.Size = UDim2.new(0, 110, 0, 25)
            gui.StudsOffset = Vector3.new(0, 5, 0)
            gui.AlwaysOnTop = true
            gui.Parent = mainPart

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.TextColor3 = isUnlocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0.2
            label.Font = Enum.Font.GothamBold
            label.Text = contentText
            label.Parent = gui
        else
            local label = existing:FindFirstChild("Text")
            if label then
                label.Text = contentText
                label.TextColor3 = isUnlocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
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

-- ==================== ESP BASE LINE FUNCTIONS ====================
local function FindDelivery()
    local plots = S.Workspace:WaitForChild("Plots", 5)
    if not plots then return nil end
    
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase.Enabled then
                local hitbox = plot:FindFirstChild("DeliveryHitbox")
                if hitbox then 
                    return hitbox 
                end
            end
        end
    end
    return nil
end

local function createPlotLine()
    local Character = player.Character
    if not Character then return false end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end

    local deliveryHitbox = FindDelivery()
    if not deliveryHitbox then return false end

    local targetPosition = deliveryHitbox.Position

    baseTargetPart = Instance.new("Part")
    baseTargetPart.Name = "PlotLineTarget"
    baseTargetPart.Size = Vector3.new(0.1, 0.1, 0.1)
    baseTargetPart.Position = targetPosition
    baseTargetPart.Anchored = true
    baseTargetPart.CanCollide = false
    baseTargetPart.Transparency = 1
    baseTargetPart.Parent = S.Workspace

    baseBeamPart = Instance.new("Part")
    baseBeamPart.Name = "PlotLineBeam"
    baseBeamPart.Size = Vector3.new(0.1, 0.1, 0.1)
    baseBeamPart.Transparency = 1
    baseBeamPart.CanCollide = false
    baseBeamPart.Parent = S.Workspace

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
    animateConnection = S.RunService.Heartbeat:Connect(function(dt)
        if baseBeam and baseBeam.Parent then
            pulseTime = pulseTime + dt
            local pulse = (math.sin(pulseTime * 2) + 1) / 2
            local r = 100 + (155 * pulse)
            baseBeam.Color = ColorSequence.new(Color3.fromRGB(r, 0, 0))
        else
            if animateConnection then animateConnection:Disconnect() end
        end
    end)

    baseLineConnection = S.RunService.Heartbeat:Connect(function()
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

    return true
end

local function stopPlotLine()
    if baseLineConnection then baseLineConnection:Disconnect(); baseLineConnection = nil end
    if baseBeamPart then baseBeamPart:Destroy(); baseBeamPart = nil end
    if baseTargetPart then baseTargetPart:Destroy(); baseTargetPart = nil end
    if baseBeam then baseBeam:Destroy(); baseBeam = nil end
end

local function enableBaseLine()
    if baseLineEnabled then return end
    baseLineEnabled = true
    pcall(createPlotLine)
end

local function disableBaseLine()
    if not baseLineEnabled then return end
    baseLineEnabled = false
    pcall(stopPlotLine)
end

local function toggleBaseLine(state)
    if state then
        enableBaseLine()
    else
        disableBaseLine()
    end
end

-- [Skip Anti Ragdoll, Xray Base, Optimizer, Anti Lag, Anti Debuff functions - sama seperti sebelum ni]

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
    
    task.spawn(function() task.wait(0.5); tryApplyInvisibleWalls() end)
    
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
local function cacheOriginalAnimations()
    local char = player.Character
    if not char then return false end
    
    animateScript = char:FindFirstChild("Animate")
    if not animateScript then return false end
    
    originalAnimIds = {}
    
    for _, animType in ipairs(ANIM_TYPES) do
        local animFolder = animateScript:FindFirstChild(animType)
        if animFolder then
            originalAnimIds[animType] = {}
            for _, anim in ipairs(animFolder:GetChildren()) do
                if anim:IsA("Animation") then
                    originalAnimIds[animType][anim.Name] = anim.AnimationId
                end
            end
        end
    end
    
    return true
end

local function disableAnimations()
    if not animateScript then return end
    
    for _, animType in ipairs(ANIM_TYPES) do
        local animFolder = animateScript:FindFirstChild(animType)
        if animFolder then
            for _, anim in ipairs(animFolder:GetChildren()) do
                if anim:IsA("Animation") then
                    anim.AnimationId = ""
                end
            end
        end
    end
    
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end
    end
end

local function restoreAnimations()
    if not animateScript or not originalAnimIds then return end
    
    for animType, anims in pairs(originalAnimIds) do
        local animFolder = animateScript:FindFirstChild(animType)
        if animFolder then
            for animName, animId in pairs(anims) do
                local anim = animFolder:FindFirstChild(animName)
                if anim and anim:IsA("Animation") then
                    anim.AnimationId = animId
                end
            end
        end
    end
end

local function startAnimDisable()
    if animDisableConn then return end
    
    if not next(originalAnimIds) then
        if not cacheOriginalAnimations() then
            warn("[Anim Disable] Failed to cache animations")
            return
        end
    end

    animDisableConn = S.RunService.Heartbeat:Connect(function()
        if not noAnimDuringStealEnabled then return end
        if not player:GetAttribute("Stealing") then return end

        disableAnimations()
    end)
end

local function stopAnimDisable()
    if animDisableConn then
        animDisableConn:Disconnect()
        animDisableConn = nil
    end
    restoreAnimations()
end

local stealingChangedConn = nil
local charAddedConn = nil

local function enableNoAnimDuringSteal()
    if noAnimDuringStealEnabled then return end
    noAnimDuringStealEnabled = true
    
    stealingChangedConn = player:GetAttributeChangedSignal("Stealing"):Connect(function()
        if player:GetAttribute("Stealing") then
            if noAnimDuringStealEnabled then
                startAnimDisable()
            end
        else
            stopAnimDisable()
        end
    end)
    
    charAddedConn = player.CharacterAdded:Connect(function()
        task.wait(1)
        originalAnimIds = {}
        animateScript = nil
        cacheOriginalAnimations()
    end)
end

local function disableNoAnimDuringSteal()
    if not noAnimDuringStealEnabled then return end
    noAnimDuringStealEnabled = false
    
    stopAnimDisable()
    
    if stealingChangedConn then
        stealingChangedConn:Disconnect()
        stealingChangedConn = nil
    end
    
    if charAddedConn then
        charAddedConn:Disconnect()
        charAddedConn = nil
    end
end

local function toggleNoAnimDuringSteal(state)
    if state then
        enableNoAnimDuringSteal()
    else
        disableNoAnimDuringSteal()
    end
end

-- ========== QUICK PANEL ==========

-- Inf Jump Toggle
QuickPanel:AddToggle({
    Title = "Inf Jump",
    Default = false,
    Callback = function(value)
        toggleInfJump(value)
        QuickPanel:Notify("Inf Jump: " .. (value and "On" or "Off"))
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

-- Esp Base Line Toggle di Tab Visual
MainHub:AddToggle({
    Tab = "Visual",
    Title = "Esp Base Line",
    Default = false,
    Callback = function(value)
        toggleBaseLine(value)
        MainHub:Notify("Esp Base Line: " .. (value and "On" or "Off"))
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
