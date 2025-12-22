--[[
    SIMPLE ARCADE UI 🎮 (UPDATED)
    Rounded rectangle, draggable, arcade style
    WITH SWITCH BUTTON FOR FLY/WALK TO BASE (FIXED)
    WITH NEW SWITCH TOGGLE FOR FLY/TP TO BEST (NEW)
    WITH NEW RESPAWN DESYNC + SERVER POSITION ESP
    WITH AUTO-ENABLED NO WALK ANIMATION
]]

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui") -- Service for notifications
local SoundService = game:GetService("SoundService") -- Service for sounds

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ==================== STEAL FLOOR VARIABLES ====================
local allFeaturesEnabled = false

-- Floor Grab
local floorGrabPart = nil
local floorGrabConnection = nil
local humanoidRootPart = nil

-- X-Ray Base
local originalTransparency = {}

-- Auto Laser
local autoLaserThread = nil
local laserCapeEquipped = false

-- ==================== DESYNC ESP VARIABLES ====================
local ESPFolder = nil
local fakePosESP = nil
local serverPosition = nil
local respawnDesyncEnabled = false

-- ==================== NO WALK ANIMATION VARIABLES ====================
local noWalkAnimationEnabled = true

-- ==================== NO WALK ANIMATION FUNCTIONS ====================
local function setupNoWalkAnimation(character)
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
    
    -- Initial stop
    stopAllAnimations()
    
    -- Stop animations when running
    humanoid.Running:Connect(function(speed)
        stopAllAnimations()
    end)
    
    -- Stop animations when jumping
    humanoid.Jumping:Connect(function()
        stopAllAnimations()
    end)
    
    -- Stop any new animations that try to play
    animator.AnimationPlayed:Connect(function(animationTrack)
        animationTrack:Stop()
    end)
    
    -- Continuous stop on RenderStepped
    RunService.RenderStepped:Connect(function()
        stopAllAnimations()
    end)
    
    print("🚫 No Walk Animation: ACTIVE")
end

-- ==================== STEAL FLOOR FUNCTIONS ====================
-- ========================================
-- UPDATE HUMANOID ROOT PART
-- ========================================
local function updateHumanoidRootPart()
    local character = LocalPlayer.Character
    if character then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateHumanoidRootPart()
    
    -- Auto-enable No Walk Animation on character respawn
    if noWalkAnimationEnabled then
        setupNoWalkAnimation(LocalPlayer.Character)
    end
end)

updateHumanoidRootPart()

-- ========================================
-- FLOOR GRAB FUNCTIONS
-- ========================================
local function startFloorGrab()
    if floorGrabPart then return end
    
    floorGrabPart = Instance.new("Part")
    floorGrabPart.Size = Vector3.new(6, 0.5, 6)
    floorGrabPart.Anchored = true
    floorGrabPart.CanCollide = true
    floorGrabPart.Transparency = 0
    floorGrabPart.Material = Enum.Material.Plastic
    floorGrabPart.Color = Color3.fromRGB(255, 200, 0)
    floorGrabPart.Parent = workspace
    
    floorGrabConnection = RunService.Heartbeat:Connect(function()
        if humanoidRootPart then
            local position = humanoidRootPart.Position
            local yOffset = (humanoidRootPart.Size.Y / 2) + 0.25
            floorGrabPart.Position = Vector3.new(position.X, position.Y - yOffset, position.Z)
        end
    end)
    
    print("✅ Floor Grab: ON")
end

local function stopFloorGrab()
    if floorGrabConnection then
        floorGrabConnection:Disconnect()
        floorGrabConnection = nil
    end
    
    if floorGrabPart then
        floorGrabPart:Destroy()
        floorGrabPart = nil
    end
    
    print("❌ Floor Grab: OFF")
end

-- ========================================
-- X-RAY BASE FUNCTIONS
-- ========================================
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
                    if originalTransparency[part] == nil then
                        originalTransparency[part] = part.Transparency
                    end
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
                    if originalTransparency[part] ~= nil then
                        part.Transparency = originalTransparency[part]
                    end
                end
            end
        end
    end
end

local function startXrayBase()
    saveOriginalTransparency()
    applyTransparency()
    print("✅ X-Ray Base: ON")
end

local function stopXrayBase()
    restoreTransparency()
    print("❌ X-Ray Base: OFF")
end

-- Monitor new plots
local plots = workspace:FindFirstChild("Plots")
if plots then
    plots.ChildAdded:Connect(function(newPlot)
        task.wait(0.5)
        if allFeaturesEnabled then
            for _, part in pairs(newPlot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency
                    part.Transparency = 0.5
                end
            end
        end
    end)
end

-- ========================================
-- AUTO LASER FUNCTIONS
-- ========================================
local function autoEquipLaserCape()
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Check if already equipped
    local currentTool = character:FindFirstChild("Laser Cape")
    if currentTool then
        laserCapeEquipped = true
        return true
    end
    
    -- Find in backpack
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local laserCape = backpack:FindFirstChild("Laser Cape")
    
    if laserCape then
        -- Equip the Laser Cape
        humanoid:EquipTool(laserCape)
        task.wait(0.3)
        laserCapeEquipped = true
        print("✅ Laser Cape Equipped!")
        return true
    else
        print("⚠️ Laser Cape not found in backpack!")
        return false
    end
end

local function getLaserRemote()
    local remote = nil
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") then
            remote = ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem") or ReplicatedStorage.Packages.Net:FindFirstChild("RE"):FindFirstChild("UseItem")
        end
        if not remote then
            remote = ReplicatedStorage:FindFirstChild("RE/UseItem") or ReplicatedStorage:FindFirstChild("UseItem")
        end
    end)
    return remote
end

local function isValidTarget(player)
    if not player or not player.Character or player == LocalPlayer then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    return true
end

local function findNearestPlayer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local nearest = nil
    local nearestDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local distance = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
                if distance < nearestDist then
                    nearestDist = distance
                    nearest = player
                end
            end
        end
    end
    
    return nearest
end

local function safeFire(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local remote = getLaserRemote()
    if remote and remote.FireServer then
        pcall(function()
            local args = {
                [1] = targetHRP.Position,
                [2] = targetHRP
            }
            remote:FireServer(unpack(args))
        end)
    end
end

local function autoLaserWorker()
    while allFeaturesEnabled do
        local target = findNearestPlayer()
        if target then
            safeFire(target)
        end
        
        local startTime = tick()
        while tick() - startTime < 0.6 do
            if not allFeaturesEnabled then break end
            RunService.Heartbeat:Wait()
        end
    end
end

local function startAutoLaser()
    -- Auto-equip Laser Cape first
    if not autoEquipLaserCape() then
        print("❌ Failed to equip Laser Cape! Cannot start Auto Laser.")
        return
    end
    
    if autoLaserThread then
        task.cancel(autoLaserThread)
    end
    autoLaserThread = task.spawn(autoLaserWorker)
    print("✅ Auto Laser: ON")
end

local function stopAutoLaser()
    if autoLaserThread then
        task.cancel(autoLaserThread)
        autoLaserThread = nil
    end
    
    laserCapeEquipped = false
    
    -- Unequip Laser Cape
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:UnequipTools()
        end
    end
    
    print("❌ Auto Laser: OFF")
end

-- ========================================
-- MASTER TOGGLE FUNCTION
-- ========================================
local function toggleAllFeatures(enabled)
    allFeaturesEnabled = enabled
    
    if allFeaturesEnabled then
        print("═══════════════════════════════")
        print("🚀 ACTIVATING ALL FEATURES...")
        print("═══════════════════════════════")
        
        -- Start all features
        startFloorGrab()
        startXrayBase()
        startAutoLaser()
        
        print("═══════════════════════════════")
        print("✅ ALL FEATURES ACTIVATED!")
        print("═══════════════════════════════")
    else
        print("═══════════════════════════════")
        print("🛑 DEACTIVATING ALL FEATURES...")
        print("═══════════════════════════════")
        
        -- Stop all features
        stopFloorGrab()
        stopXrayBase()
        stopAutoLaser()
        
        print("═══════════════════════════════")
        print("❌ ALL FEATURES DEACTIVATED!")
        print("═══════════════════════════════")
    end
end

-- SPEED BOOSTER SYSTEM
local speedConn
local baseSpeed = 27
local speedEnabled = false

local function GetCharacter()
    local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
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
    speedConn = RunService.Heartbeat:Connect(function()
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
    if speedEnabled then
        startSpeedControl()
        print("✅ Speed Booster aktif!")
    else
        stopSpeedControl()
        print("❌ Speed Booster nonaktif!")
    end
end

-- ==================== IMPROVED INFINITE JUMP + AUTO GOD MODE ====================
local infJumpEnabled = false
local gravityConnection = nil
local healthConnection = nil
local stateConnection = nil
local initialMaxHealth = 100 -- Untuk simpan nyawa asal

local function toggleInfJump(enabled)
    infJumpEnabled = enabled
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if enabled then
        print("🔴 Infinite Jump: ON")
        print("✅ God Mode: Auto-Enabled")

        -- --- Infinite Jump Logic ---
        if gravityConnection then gravityConnection:Disconnect() end
        gravityConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local velocity = hrp.AssemblyLinearVelocity
                if velocity.Y < 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y * 0.85, velocity.Z)
                end
            end
        end)

        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 70
            initialMaxHealth = humanoid.MaxHealth -- Simpan nyawa asal
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end

        -- --- God Mode Logic ---
        if healthConnection then healthConnection:Disconnect() end
        healthConnection = humanoid.HealthChanged:Connect(function(health)
            if health < math.huge then
                humanoid.Health = math.huge
            end
        end)

        if stateConnection then stateConnection:Disconnect() end
        stateConnection = humanoid.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                humanoid.Health = math.huge
            end
        end)

    else
        print("⚫ Infinite Jump: OFF")
        print("❌ God Mode: Auto-Disabled")

        -- --- Cleanup ---
        if gravityConnection then
            gravityConnection:Disconnect()
            gravityConnection = nil
        end
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        if stateConnection then
            stateConnection:Disconnect()
            stateConnection = nil
        end

        if humanoid then
            humanoid.JumpPower = 50 -- Reset ke default
            humanoid.MaxHealth = initialMaxHealth
            humanoid.Health = initialMaxHealth
        end
    end
end

-- Infinite Jump functionality (sentiasa aktif, tetapi hanya berfungsi jika dihidupkan)
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Jika respawn, aktifkan semula jika toggle masih ON
LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5) -- Tunggu karakter load
    if infJumpEnabled then
        toggleInfJump(true)
    end
end)

-- ==================== FLY / WALK TO BASE (FIXED ORDER) ====================
-- PERUBAHAN: Susunan fungsi telah diperbetulkan untuk mengelakkan ralat 'calling nil'.
local isTraveling = false
local floatConnection = nil
local walkThread = nil

-- Settings
local FLOAT_SPEED = 17
local FLOAT_UP_SPEED = 1.5
local FLOAT_HEIGHT_OFFSET = 5
local STOP_DISTANCE = 8

local function stopAllTravel()
    isTraveling = false
    
    -- Stop Flying
    if floatConnection then
        floatConnection:Disconnect()
        floatConnection = nil
    end
    
    -- Stop Walking
    if walkThread then
        task.cancel(walkThread)
        walkThread = nil
    end
    
    -- Stop character movement
    local Character = player.Character
    if Character then
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if RootPart then
            RootPart.Velocity = Vector3.new(0, 0, 0)
            RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        if Humanoid then
            Humanoid:MoveTo(RootPart.Position)
        end
    end
    
    print("🛑 All travel stopped")
end

--- WALK TO BASE FUNCTIONS (DIPINDAHKAN KE ATAS) ---
local function FindDelivery()
    local plots = workspace:WaitForChild("Plots", 5)
    if not plots then
        warn("❌ Plots folder not found in workspace")
        return nil
    end
    
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase.Enabled then
                local hitbox = plot:FindFirstChild("DeliveryHitbox")
                if hitbox then 
                    print("✅ Found DeliveryHitbox in:", plot.Name)
                    return hitbox 
                end
            end
        end
    end
    warn("❌ No valid DeliveryHitbox found")
    return nil
end

local function WalkTo(target)
    if not target or not target:IsA("BasePart") then 
        warn("❌ Invalid target for WalkTo")
        return false
    end

    local character = player.Character
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then
        warn("❌ Character components missing")
        return false
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 8,
        AgentMaxSlope = 45
    })

    local success, errorMessage = pcall(function()
        path:ComputeAsync(hrp.Position, target.Position)
    end)

    if not success then
        warn("❌ Path computation failed:", errorMessage)
        return false
    end

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        print("🚶 Walking to DeliveryHitbox... (" .. #waypoints .. " waypoints)")
        
        for i, waypoint in ipairs(waypoints) do
            if not isTraveling then
                print("⚠️ Walk cancelled by user")
                return false
            end
            
            if not humanoid or not hrp or not humanoid.Parent then
                warn("❌ Character components missing during pathfinding")
                return false
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local moveFinished = false
            local timeoutThread = task.delay(2, function()
                if not moveFinished then
                    humanoid:MoveTo(hrp.Position)
                end
            end)
            
            humanoid.MoveToFinished:Wait()
            moveFinished = true
            task.cancel(timeoutThread)
            
            local distance = (hrp.Position - target.Position).Magnitude
            if distance < 5 then
                print("✅ Reached DeliveryHitbox!")
                return true
            end
        end
        
        print("✅ Finished walking path")
        return true
    else
        warn("❌ Path not found! Status:", path.Status)
        return false
    end
end

local function doWalkToBase()
    local delivery = FindDelivery()
    if not delivery then
        warn("❌ Failed to find DeliveryHitbox")
        return false
    end
    
    local success = WalkTo(delivery)
    
    if success then
        print("✅ Successfully reached delivery!")
    else
        print("⚠️ Walk to delivery failed or was cancelled")
    end
    
    return true
end

-- --- FLY TO BASE FUNCTIONS (DIPINDAHKAN KE BAWAH) ---
local function doFlyToBase()
    local Character = player.Character
    if not Character then return false end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end
    
    -- PERUBAHAN: Guna fungsi FindDelivery() yang sama dengan fungsi jalan kaki.
    local deliveryHitbox = FindDelivery()
    if not deliveryHitbox then
        warn("❌ Cannot find DeliveryHitbox!")
        return false
    end
    
    local targetPosition = deliveryHitbox.Position + Vector3.new(0, FLOAT_HEIGHT_OFFSET, 0)
    print("🎈 Flying to DeliveryHitbox at:", targetPosition)
    
    floatConnection = RunService.Heartbeat:Connect(function()
        if not isTraveling then
            stopAllTravel()
            return
        end
        
        if not Character or not Character.Parent or not RootPart or not RootPart.Parent then
            stopAllTravel()
            return
        end
        
        local currentPos = RootPart.Position
        local hitboxPos = deliveryHitbox.Position
        
        local horizontalDistance = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(hitboxPos.X, 0, hitboxPos.Z)).Magnitude
        
        if horizontalDistance <= STOP_DISTANCE then
            print("✅ Arrived at DeliveryHitbox!")
            stopAllTravel()
            return
        end
        
        local direction = (targetPosition - currentPos).Unit
        local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
        
        RootPart.Velocity = Vector3.new(
            horizontalDir.X * FLOAT_SPEED,
            FLOAT_UP_SPEED,
            horizontalDir.Z * FLOAT_SPEED
        )
    end)
    
    return true
end

-- ==================== DESYNC ESP FUNCTIONS ====================
-- Initialize ESP Folder
local function initializeESPFolder()
    -- Clean up any existing ESP folders
    for _, existing in ipairs(Workspace:GetChildren()) do
        if existing.Name == "DesyncESP" then
            existing:Destroy()
        end
    end
    
    -- Create new ESP folder
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "DesyncESP"
    ESPFolder.Parent = Workspace
end

-- Create ESP part for server position
local function createESPPart(name, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(2, 5, 2)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.3
    part.Parent = ESPFolder
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = part
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = name
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard
    
    return part
end

-- Update ESP position
local function updateESP()
    if fakePosESP and serverPosition then
        fakePosESP.CFrame = CFrame.new(serverPosition)
    end
end

-- Initialize ESP system
local function initializeESP()
    if not ESPFolder then
        initializeESPFolder()
    else
        ESPFolder:ClearAllChildren()
    end
    
    fakePosESP = createESPPart("Server Position", Color3.fromRGB(255, 0, 0))
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            serverPosition = hrp.Position
            fakePosESP.CFrame = CFrame.new(serverPosition)
            
            hrp:GetPropertyChangedSignal("CFrame"):Connect(function()
                task.wait(0.2)
                serverPosition = hrp.Position
            end)
        end
    end
end

-- Deactivate ESP system
local function deactivateESP()
    if ESPFolder then
        ESPFolder:ClearAllChildren()
    end
    fakePosESP = nil
    serverPosition = nil
end

-- Stop all animations
local function stopAllAnimations(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
    end
end

-- Apply network settings for desync
local function applyNetworkSettings()
    local fenv = getfenv()
    
    pcall(function() fenv.setfflag("GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000") end)
    pcall(function() fenv.setfflag("LargeReplicatorWrite5", "true") end)
    pcall(function() fenv.setfflag("LargeReplicatorEnabled9", "true") end)
    pcall(function() fenv.setfflag("AngularVelociryLimit", "360") end)
    pcall(function() fenv.setfflag("TimestepArbiterVelocityCriteriaThresholdTwoDt", "2147483646") end)
    pcall(function() fenv.setfflag("S2PhysicsSenderRate", "15000") end)
    pcall(function() fenv.setfflag("DisableDPIScale", "true") end)
    pcall(function() fenv.setfflag("MaxDataPacketPerSend", "2147483647") end)
    pcall(function() fenv.setfflag("ServerMaxBandwith", "52") end)
    pcall(function() fenv.setfflag("PhysicsSenderMaxBandwidthBps", "20000") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierBuoyancy", "2147483647") end)
    pcall(function() fenv.setfflag("SimOwnedNOUCountThresholdMillionth", "2147483647") end)
    pcall(function() fenv.setfflag("MaxMissedWorldStepsRemembered", "-2147483648") end)
    pcall(function() fenv.setfflag("CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth", "1") end)
    pcall(function() fenv.setfflag("StreamJobNOUVolumeLengthCap", "2147483647") end)
    pcall(function() fenv.setfflag("DebugSendDistInSteps", "-2147483648") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierAcceleration", "2147483647") end)
    pcall(function() fenv.setfflag("LargeReplicatorRead5", "true") end)
    pcall(function() fenv.setfflag("SimExplicitlyCappedTimestepMultiplier", "2147483646") end)
    pcall(function() fenv.setfflag("GameNetDontSendRedundantNumTimes", "1") end)
    pcall(function() fenv.setfflag("CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent", "1") end)
    pcall(function() fenv.setfflag("CheckPVCachedRotVelThresholdPercent", "10") end)
    pcall(function() fenv.setfflag("LargeReplicatorSerializeRead3", "true") end)
    pcall(function() fenv.setfflag("ReplicationFocusNouExtentsSizeCutoffForPauseStuds", "2147483647") end)
    pcall(function() fenv.setfflag("NextGenReplicatorEnabledWrite4", "true") end)
    pcall(function() fenv.setfflag("CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth", "1") end)
    pcall(function() fenv.setfflag("GameNetDontSendRedundantDeltaPositionMillionth", "1") end)
    pcall(function() fenv.setfflag("InterpolationFrameVelocityThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("StreamJobNOUVolumeCap", "2147483647") end)
    pcall(function() fenv.setfflag("InterpolationFrameRotVelocityThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("WorldStepMax", "30") end)
    pcall(function() fenv.setfflag("TimestepArbiterHumanoidLinearVelThreshold", "1") end)
    pcall(function() fenv.setfflag("InterpolationFramePositionThresholdMillionth", "5") end)
    pcall(function() fenv.setfflag("TimestepArbiterHumanoidTurningVelThreshold", "1") end)
    pcall(function() fenv.setfflag("MaxTimestepMultiplierContstraint", "2147483647") end)
    pcall(function() fenv.setfflag("GameNetPVHeaderLinearVelocityZeroCutoffExponent", "-5000") end)
    pcall(function() fenv.setfflag("CheckPVCachedVelThresholdPercent", "10") end)
    pcall(function() fenv.setfflag("TimestepArbiterOmegaThou", "1073741823") end)
    pcall(function() fenv.setfflag("MaxAcceptableUpdateDelay", "1") end)
    pcall(function() fenv.setfflag("LargeReplicatorSerializeWrite4", "true") end)
end

-- Main respawn desync function
local function respawnDesync()
    local character = LocalPlayer.Character
    if not character then return end
    
    stopAllAnimations(character)
    applyNetworkSettings()
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        character:ClearAllChildren()
        
        local tempModel = Instance.new("Model")
        tempModel.Parent = workspace
        LocalPlayer.Character = tempModel
        
        task.wait(0.1)
        
        LocalPlayer.Character = character
        tempModel:Destroy()
        
        task.wait(0.05)
        if character and character.Parent then
            local newHumanoid = character:FindFirstChildWhichIsA("Humanoid")
            if newHumanoid then
                newHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    
    -- Initialize ESP after desync
    task.wait(0.5)
    initializeESP()
end

-- ==================== UI CREATION ====================
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name == "SimpleArcadeUI" then
        gui:Destroy()
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleArcadeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.CoreGui

-- Main Frame (Rounded Rectangle - Vertical Block) - DIUBAH SAIZ
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 320) -- DARI 280 JADI 320
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -160) -- DARI -140 JADI -160
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Rounded corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

-- Border stroke
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 50, 50) -- Bright red
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Title Label (Dark Red, Arcade Font)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 3)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NIGHTMARE HUB"
titleLabel.TextColor3 = Color3.fromRGB(139, 0, 0) -- Dark red
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.Arcade
titleLabel.Parent = mainFrame

-- Toggle Button 1 - Perm Desync
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 160, 0, 32)
toggleButton.Position = UDim2.new(0.5, -80, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Dark red (OFF state)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "Perm Desync"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.Arcade
toggleButton.Parent = mainFrame

-- Toggle button corner
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleButton

-- Toggle button stroke
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 50, 50)
toggleStroke.Thickness = 1
toggleStroke.Parent = toggleButton

-- Toggle state
local isToggled = false

-- TweenInfo for animations
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Create Sound Object
local desyncSound = Instance.new("Sound")
desyncSound.Name = "DesyncSound"
desyncSound.SoundId = "rbxassetid://144686873"
desyncSound.Volume = 1 -- Set volume to maximum as requested
desyncSound.Looped = false
desyncSound.Parent = SoundService

-- Toggle function
toggleButton.MouseButton1Click:Connect(function()
    isToggled = not isToggled
    
    if isToggled then
        -- ON state - Brighter red
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        print("✅ Perm Desync: ON (Server Position ESP Active)")
        
        -- Play the sound
        if desyncSound.IsPlaying then
            desyncSound:Stop()
        end
        desyncSound:Play()
        
        -- Send the notification
        StarterGui:SetCore("SendNotification", {
            Title = "Desync";
            Text = "Desync Successfull";
            Duration = 5;
        })
        
        -- Initialize ESP folder if needed
        if not ESPFolder then
            initializeESPFolder()
        end
        
        -- Start respawn desync
        respawnDesync()
        
        -- Start ESP update loop
        if not respawnDesyncConnection then
            respawnDesyncConnection = RunService.RenderStepped:Connect(function()
                if respawnDesyncEnabled then
                    updateESP()
                end
            end)
        end
        
        respawnDesyncEnabled = true
    else
        -- OFF state - Dark red
        toggleButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        print("❌ Perm Desync: OFF (ESP Disabled)")
        
        -- Deactivate ESP
        deactivateESP()
        respawnDesyncEnabled = false
    end
end)

-- Toggle Button 2 - Speed Booster
local toggleButton2 = Instance.new("TextButton")
toggleButton2.Size = UDim2.new(0, 160, 0, 32)
toggleButton2.Position = UDim2.new(0.5, -80, 0, 90)
toggleButton2.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton2.BorderSizePixel = 0
toggleButton2.Text = "Speed Booster"
toggleButton2.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton2.TextSize = 16
toggleButton2.Font = Enum.Font.Arcade
toggleButton2.Parent = mainFrame

local toggleCorner2 = Instance.new("UICorner")
toggleCorner2.CornerRadius = UDim.new(0, 10)
toggleCorner2.Parent = toggleButton2

local toggleStroke2 = Instance.new("UIStroke")
toggleStroke2.Color = Color3.fromRGB(255, 50, 50)
toggleStroke2.Thickness = 1
toggleStroke2.Parent = toggleButton2

local isToggled2 = false

toggleButton2.MouseButton1Click:Connect(function()
    isToggled2 = not isToggled2
    
    if isToggled2 then
        toggleButton2.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        print("🔴 Speed Booster: ON")
        toggleSpeed(true)
    else
        toggleButton2.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        print("⚫ Speed Booster: OFF")
        toggleSpeed(false)
    end
end)

-- Toggle Button 3 - Inf Jump
local toggleButton3 = Instance.new("TextButton")
toggleButton3.Size = UDim2.new(0, 160, 0, 32)
toggleButton3.Position = UDim2.new(0.5, -80, 0, 130)
toggleButton3.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton3.BorderSizePixel = 0
toggleButton3.Text = "Inf Jump"
toggleButton3.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton3.TextSize = 16
toggleButton3.Font = Enum.Font.Arcade
toggleButton3.Parent = mainFrame

local toggleCorner3 = Instance.new("UICorner")
toggleCorner3.CornerRadius = UDim.new(0, 10)
toggleCorner3.Parent = toggleButton3

local toggleStroke3 = Instance.new("UIStroke")
toggleStroke3.Color = Color3.fromRGB(255, 50, 50)
toggleStroke3.Thickness = 1
toggleStroke3.Parent = toggleButton3

local isToggled3 = false

toggleButton3.MouseButton1Click:Connect(function()
    isToggled3 = not isToggled3
    toggleInfJump(isToggled3) -- Panggil fungsi yang telah diperbaiki
    
    if isToggled3 then
        toggleButton3.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    else
        toggleButton3.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    end
end)

-- ========== TOGGLE BUTTON 4 WITH SWITCH - Fly/Walk to Base (FIXED) ==========
-- Main button (smaller width to make space for switch)
local toggleButton4 = Instance.new("TextButton")
toggleButton4.Size = UDim2.new(0, 125, 0, 32) -- Reduced width from 160 to 125
toggleButton4.Position = UDim2.new(0, 20, 0, 170)
toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton4.BorderSizePixel = 0
toggleButton4.Text = "Fly to Base"
toggleButton4.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton4.TextSize = 15
toggleButton4.Font = Enum.Font.Arcade
toggleButton4.Parent = mainFrame

local toggleCorner4 = Instance.new("UICorner")
toggleCorner4.CornerRadius = UDim.new(0, 10)
toggleCorner4.Parent = toggleButton4

local toggleStroke4 = Instance.new("UIStroke")
toggleStroke4.Color = Color3.fromRGB(255, 50, 50)
toggleStroke4.Thickness = 1
toggleStroke4.Parent = toggleButton4

local isToggled4 = false
local isFlyMode = true -- true = Fly, false = Walk

-- Switch Button (Toggle between Fly/Walk)
local switchButton = Instance.new("TextButton")
switchButton.Size = UDim2.new(0, 30, 0, 32)
switchButton.Position = UDim2.new(0, 153, 0, 170) -- Position next to main button
switchButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
switchButton.BorderSizePixel = 0
switchButton.Text = "⇄"
switchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton.TextSize = 18
switchButton.Font = Enum.Font.GothamBold
switchButton.Parent = mainFrame

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 10)
switchCorner.Parent = switchButton

local switchStroke = Instance.new("UIStroke")
switchStroke.Color = Color3.fromRGB(255, 50, 50)
switchStroke.Thickness = 1
switchStroke.Parent = switchButton

-- Switch button click function
switchButton.MouseButton1Click:Connect(function()
    -- Stop any ongoing travel when switching mode
    if isTraveling then
        stopAllTravel()
        isToggled4 = false
        toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    end

    isFlyMode = not isFlyMode
    
    if isFlyMode then
        toggleButton4.Text = "Fly to Base"
        print("✈️ Mode: FLY TO BASE")
    else
        toggleButton4.Text = "Walk to Base"
        print("🚶 Mode: WALK TO BASE")
    end
end)

-- Main toggle function (FIXED)
toggleButton4.MouseButton1Click:Connect(function()
    -- If we are currently traveling, stop everything.
    if isTraveling then
        isToggled4 = false
        toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        stopAllTravel()
        print("⚫ Travel stopped by user.")
        return -- Exit the function
    end

    -- If we are not traveling, start traveling.
    isToggled4 = true
    toggleButton4.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    isTraveling = true -- Set the global flag

    local success = false
    if isFlyMode then
        print("🔴 Fly to Base: ON")
        success = doFlyToBase() -- Call the new simplified function
    else
        print("🔴 Walk to Base: ON")
        walkThread = task.spawn(doWalkToBase) -- Run walk function in a new thread
        success = true -- Assume success for now, the function itself handles failure
    end

    -- If the start function failed, reset everything.
    if not success then
        isToggled4 = false
        toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        isTraveling = false
        warn("❌ Failed to start travel!")
    end
end)

-- Function to reset the UI button after travel is complete
local function resetTravelButton()
    isToggled4 = false
    toggleButton4.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
end

-- Modify the completion logic inside doFlyToBase to reset the UI
local originalDoFlyToBase = doFlyToBase
doFlyToBase = function(...)
    local success = originalDoFlyToBase(...)
    if success then
        -- The loop will handle stopping and resetting, but we need to ensure UI resets if it stops for other reasons
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            if not isTraveling then
                resetTravelButton()
                if connection then connection:Disconnect() end
            end
        end)
    end
    return success
end

-- Modify the completion logic inside doWalkToBase to reset the UI
local originalDoWalkToBase = doWalkToBase
doWalkToBase = function(...)
    local success = originalDoWalkToBase(...)
    -- This function runs in a thread, so we can reset the UI directly after it finishes
    resetTravelButton()
    return success
end

-- ==================== PLACEHOLDER FUNCTIONS UNTUK FLY/TP TO BEST ====================
-- GANTIKAN PRINT INI DENGAN FUNCTION ANDA
local function flyToBest()
    print("🚀 Function 'flyToBest' is running...")
    -- GUNAKAN FUNCTION AWAK SINI
end

local function tpToBest()
    print("✨ Function 'tpToBest' is running...")
    -- GUNAKAN FUNCTION AWAK SINI
end

local function stopFlyOrTpBest()
    print("🛑 Stopping Fly/Tp to Best functions.")
    -- GUNAKAN FUNCTION AWAK SINI UNTUK HENTIKAN PROSES
end

-- ==================== TOGGLE BUTTON 6 WITH SWITCH - Fly/Tp to Best (NEW) ====================
local isToggled6 = false
local isFlyBestMode = true -- true = Fly, false = Tp

-- Main button
local toggleButton6 = Instance.new("TextButton")
toggleButton6.Size = UDim2.new(0, 125, 0, 32)
toggleButton6.Position = UDim2.new(0, 20, 0, 210) -- Di bawah toggle 4
toggleButton6.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton6.BorderSizePixel = 0
toggleButton6.Text = "Fly to Best" -- Default text
toggleButton6.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton6.TextSize = 15
toggleButton6.Font = Enum.Font.Arcade
toggleButton6.Parent = mainFrame

local toggleCorner6 = Instance.new("UICorner")
toggleCorner6.CornerRadius = UDim.new(0, 10)
toggleCorner6.Parent = toggleButton6

local toggleStroke6 = Instance.new("UIStroke")
toggleStroke6.Color = Color3.fromRGB(255, 50, 50)
toggleStroke6.Thickness = 1
toggleStroke6.Parent = toggleButton6

-- Switch Button
local switchButton6 = Instance.new("TextButton")
switchButton6.Size = UDim2.new(0, 30, 0, 32)
switchButton6.Position = UDim2.new(0, 153, 0, 210)
switchButton6.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
switchButton6.BorderSizePixel = 0
switchButton6.Text = "⇄"
switchButton6.TextColor3 = Color3.fromRGB(255, 255, 255)
switchButton6.TextSize = 18
switchButton6.Font = Enum.Font.GothamBold
switchButton6.Parent = mainFrame

local switchCorner6 = Instance.new("UICorner")
switchCorner6.CornerRadius = UDim.new(0, 10)
switchCorner6.Parent = switchButton6

local switchStroke6 = Instance.new("UIStroke")
switchStroke6.Color = Color3.fromRGB(255, 50, 50)
switchStroke6.Thickness = 1
switchStroke6.Parent = switchButton6

-- Switch button click function (DENGAN LOGIK ANTI-BUG)
switchButton6.MouseButton1Click:Connect(function()
    -- Jika toggle sedang aktif, matikan dulu sebelum tukar mod
    if isToggled6 then
        isToggled6 = false
        toggleButton6.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        stopFlyOrTpBest() -- Hentikan fungsi yang sedang berjalan
        print("⚫ Feature stopped due to mode switch.")
    end

    -- Tukar mod
    isFlyBestMode = not isFlyBestMode
    
    if isFlyBestMode then
        toggleButton6.Text = "Fly to Best"
        print("✈️ Mode changed to: Fly to Best")
    else
        toggleButton6.Text = "Tp to Best"
        print("✨ Mode changed to: Tp to Best")
    end
end)

-- Main toggle function
toggleButton6.MouseButton1Click:Connect(function()
    isToggled6 = not isToggled6
    
    if isToggled6 then
        toggleButton6.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        if isFlyBestMode then
            print("🔴 Fly to Best: ON")
            flyToBest() -- Panggil function anda
        else
            print("🔴 Tp to Best: ON")
            tpToBest() -- Panggil function anda
        end
    else
        toggleButton6.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        print("⚫ Fly/Tp to Best: OFF")
        stopFlyOrTpBest() -- Panggil function berhenti
    end
end)


-- Toggle Button 5 - Steal Floor (DIALIHKAN KE BAWAH)
local toggleButton5 = Instance.new("TextButton")
toggleButton5.Size = UDim2.new(0, 160, 0, 32)
toggleButton5.Position = UDim2.new(0.5, -80, 0, 250) -- DARI 210 JADI 250
toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
toggleButton5.BorderSizePixel = 0
toggleButton5.Text = "Steal Floor"
toggleButton5.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton5.TextSize = 16
toggleButton5.Font = Enum.Font.Arcade
toggleButton5.Parent = mainFrame

local toggleCorner5 = Instance.new("UICorner")
toggleCorner5.CornerRadius = UDim.new(0, 10)
toggleCorner5.Parent = toggleButton5

local toggleStroke5 = Instance.new("UIStroke")
toggleStroke5.Color = Color3.fromRGB(255, 50, 50)
toggleStroke5.Thickness = 1
toggleStroke5.Parent = toggleButton5

local isToggled5 = false

toggleButton5.MouseButton1Click:Connect(function()
    isToggled5 = not isToggled5
    
    if isToggled5 then
        toggleButton5.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        print("🔴 Steal Floor: ON")
        toggleAllFeatures(true)
    else
        toggleButton5.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        print("⚫ Steal Floor: OFF")
        toggleAllFeatures(false)
    end
end)

-- Content area (placeholder) - DIALIHKAN KE BAWAH
local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(1, -40, 1, -295) -- DARI -255 JADI -295
contentLabel.Position = UDim2.new(0, 20, 0, 290) -- DARI 250 JADI 290
contentLabel.BackgroundTransparency = 1
contentLabel.Text = ""
contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
contentLabel.TextSize = 14
contentLabel.Font = Enum.Font.Gotham
contentLabel.TextWrapped = true
contentLabel.TextYAlignment = Enum.TextYAlignment.Top
contentLabel.Parent = mainFrame

-- ESP update loop
local respawnDesyncConnection = nil

-- Cleanup on character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateHumanoidRootPart()
    
    if allFeaturesEnabled then
        -- Restart floor grab after respawn
        if floorGrabPart then
            floorGrabPart:Destroy()
            floorGrabPart = nil
        end
        if floorGrabConnection then
            floorGrabConnection:Disconnect()
            floorGrabConnection = nil
        end
        startFloorGrab()
        
        -- Re-equip Laser Cape after respawn
        task.wait(0.5)
        autoEquipLaserCape()
    end
    
    -- Stop travel on respawn
    if isTraveling then
        stopAllTravel()
        resetTravelButton()
        warn("⚠️ Character respawned - Travel stopped")
    end
    
    -- Reset new toggle on respawn
    if isToggled6 then
        isToggled6 = false
        toggleButton6.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        stopFlyOrTpBest()
        warn("⚠️ Character respawned - Fly/Tp to Best stopped")
    end
    
    -- Reinitialize ESP if needed
    if respawnDesyncEnabled then
        task.wait(1)
        initializeESP()
    end
end)

player.CharacterRemoving:Connect(function()
    stopAllTravel()
    if respawnDesyncEnabled then
        deactivateESP()
    end
end)

-- ==================== INITIALIZATION ====================
-- Auto-enable No Walk Animation for current character
if LocalPlayer.Character then
    setupNoWalkAnimation(LocalPlayer.Character)
end

print("==========================================")
print("🎮 NIGHTMARE HUB LOADED!")
print("==========================================")
print("📐 Size: 200x320 (Vertical block, extended)")
print("🎨 Style: Rounded rectangle")
print("🖱️ Draggable: YES")
print("🎮 Font: Arcade")
print("🔴 Title: NIGHTMARE HUB")
print("🔆 Transparency: 0.1 (More visible)")
print("🔘 Toggles: Perm Desync, Speed Booster, Inf Jump, Steal Floor")
print("✈️ Special: Fly/Walk to Base with Switch (FIXED)")
print("📍 New: Fly/Tp to Best with Switch (NEW)")
print("📍 New: Server Position ESP with Perm Desync")
print("🚫 Auto-Enabled: No Walk Animation")
print("==========================================")
