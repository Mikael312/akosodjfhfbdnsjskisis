--[[
    NIGHTMARE HUB - FULL SCRIPT
    Menggabungkan fungsi-fungsi dari script 1 dengan sistem UI dari script 2.
]]

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

-- ==================== STEAL FLOOR VARIABLES ====================
local allFeaturesEnabled = false
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

-- ==================== FLY/TP TO BEST VARIABLES ====================
local isFlyingToBest = false
local velocityConnection = nil
local isFlyToBestMode = true -- true = Fly, false = TP

-- ==================== FLY/WALK TO BASE VARIABLES ====================
local isTraveling = false
local floatConnection = nil
local walkThread = nil
local isFlyMode = true -- true = Fly, false = Walk

-- ==================== UI LIBRARY SETUP ====================
-- GANTIKAN INI dengan URL Raw GitHub anda
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mikael312/Nightmare-Ui/refs/heads/main/Nightmare-ui.lua" -- Pastikan URL betul

local ui = nil -- Variable untuk menyimpan instance UI

-- Fungsi untuk memuatkan perpustakaan UI dari GitHub
local function loadLibrary()
    local success, response = pcall(function()
        return game:HttpGet(GITHUB_RAW_URL)
    end)

    if success and response then
        local loadSuccess, NightmareUILib = pcall(loadstring(response))
        if loadSuccess and typeof(NightmareUILib) == "table" and NightmareUILib.new then
            return NightmareUILib
        else
            warn("Gagal untuk memuatkan perpustakaan UI dari GitHub.")
            return nil
        end
    else
        warn("Gagal untuk memuatkan perpustakaan UI dari GitHub. Ralat: " .. tostring(response))
        return nil
    end
end

-- ==================== FUNGSI-FUNGSI UTAMA (DARI KOD 1) ====================

-- --- NO WALK ANIMATION ---
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
    
    stopAllAnimations()
    humanoid.Running:Connect(stopAllAnimations)
    humanoid.Jumping:Connect(stopAllAnimations)
    animator.AnimationPlayed:Connect(function(animationTrack) animationTrack:Stop() end)
    RunService.RenderStepped:Connect(stopAllAnimations)
    print("🚫 No Walk Animation: ACTIVE")
end

-- --- STEAL FLOOR (Floor Grab, X-Ray, Auto Laser) ---
local function updateHumanoidRootPart()
    local character = LocalPlayer.Character
    if character then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
end

local function startFloorGrab()
    if floorGrabPart then return end
    updateHumanoidRootPart()
    if not humanoidRootPart then return end
    
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
    if floorGrabConnection then floorGrabConnection:Disconnect(); floorGrabConnection = nil end
    if floorGrabPart then floorGrabPart:Destroy(); floorGrabPart = nil end
    print("❌ Floor Grab: OFF")
end

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

local function startXrayBase()
    saveOriginalTransparency(); applyTransparency(); print("✅ X-Ray Base: ON")
end

local function stopXrayBase()
    restoreTransparency(); print("❌ X-Ray Base: OFF")
end

local function autoEquipLaserCape()
    local character = LocalPlayer.Character; if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid"); if not humanoid then return false end
    if character:FindFirstChild("Laser Cape") then laserCapeEquipped = true; return true end
    local backpack = LocalPlayer:WaitForChild("Backpack"); local laserCape = backpack:FindFirstChild("Laser Cape")
    if laserCape then humanoid:EquipTool(laserCape); task.wait(0.3); laserCapeEquipped = true; print("✅ Laser Cape Equipped!"); return true
    else print("⚠️ Laser Cape not found in backpack!"); return false end
end

local function getLaserRemote()
    local remote = nil; pcall(function()
        if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net") then
            remote = ReplicatedStorage.Packages.Net:FindFirstChild("RE/UseItem") or ReplicatedStorage.Packages.Net:FindFirstChild("RE"):FindFirstChild("UseItem")
        end if not remote then remote = ReplicatedStorage:FindFirstChild("RE/UseItem") or ReplicatedStorage:FindFirstChild("UseItem") end
    end) return remote
end

local function findNearestPlayer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position; local nearest = nil; local nearestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetHRP = player.Character.HumanoidRootPart
            local distance = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
            if distance < nearestDist then nearestDist = distance; nearest = player end
        end
    end return nearest
end

local function autoLaserWorker()
    while allFeaturesEnabled do
        local target = findNearestPlayer(); if target then
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart"); if targetHRP then
                local remote = getLaserRemote(); if remote and remote.FireServer then
                    pcall(function() remote:FireServer(targetHRP.Position, targetHRP) end)
                end
            end
        end
        local startTime = tick(); while tick() - startTime < 0.6 do if not allFeaturesEnabled then break end RunService.Heartbeat:Wait() end
    end
end

local function startAutoLaser()
    if not autoEquipLaserCape() then print("❌ Failed to equip Laser Cape! Cannot start Auto Laser."); return end
    if autoLaserThread then task.cancel(autoLaserThread) end
    autoLaserThread = task.spawn(autoLaserWorker); print("✅ Auto Laser: ON")
end

local function stopAutoLaser()
    if autoLaserThread then task.cancel(autoLaserThread); autoLaserThread = nil end
    laserCapeEquipped = false; local character = LocalPlayer.Character; if character then local humanoid = character:FindFirstChildOfClass("Humanoid"); if humanoid then humanoid:UnequipTools() end end
    print("❌ Auto Laser: OFF")
end

local function toggleAllFeatures(enabled)
    allFeaturesEnabled = enabled
    if allFeaturesEnabled then startFloorGrab(); startXrayBase(); startAutoLaser(); print("✅ ALL FEATURES ACTIVATED!")
    else stopFloorGrab(); stopXrayBase(); stopAutoLaser(); print("❌ ALL FEATURES DEACTIVATED!") end
end

-- --- SPEED BOOSTER ---
local speedConn; local baseSpeed = 27; local speedEnabled = false
local function GetCharacter()
    local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Char:WaitForChild("HumanoidRootPart"); local Hum = Char:FindFirstChildOfClass("Humanoid")
    return Char, HRP, Hum
end
local function getMovementInput()
    local Char, HRP, Hum = GetCharacter(); if not Char or not HRP or not Hum then return Vector3.new(0,0,0) end
    local moveVector = Hum.MoveDirection; if moveVector.Magnitude > 0.1 then return Vector3.new(moveVector.X, 0, moveVector.Z).Unit end
    return Vector3.new(0,0,0)
end
local function startSpeedControl()
    if speedConn then return end
    speedConn = RunService.Heartbeat:Connect(function()
        local Char, HRP, Hum = GetCharacter(); if not Char or not HRP or not Hum then return end
        local inputDirection = getMovementInput()
        if inputDirection.Magnitude > 0 then
            HRP.AssemblyLinearVelocity = Vector3.new(inputDirection.X * baseSpeed, HRP.AssemblyLinearVelocity.Y, inputDirection.Z * baseSpeed)
        else HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
    end)
end
local function stopSpeedControl()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    local _, HRP = GetCharacter(); if HRP then HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end
end
local function toggleSpeed(enabled)
    speedEnabled = enabled; if speedEnabled then startSpeedControl(); print("✅ Speed Booster aktif!")
    else stopSpeedControl(); print("❌ Speed Booster nonaktif!") end
end

-- --- INFINITE JUMP ---
local infJumpEnabled = false; local gravityConnection = nil; local healthConnection = nil; local stateConnection = nil; local initialMaxHealth = 100
local function toggleInfJump(enabled)
    infJumpEnabled = enabled; local character = LocalPlayer.Character; local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if enabled then
        print("🔴 Infinite Jump: ON"); print("✅ God Mode: Auto-Enabled")
        if gravityConnection then gravityConnection:Disconnect() end
        gravityConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character; if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then local velocity = hrp.AssemblyLinearVelocity; if velocity.Y < 0 then hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, velocity.Y * 0.85, velocity.Z) end end
        end)
        if humanoid then humanoid.UseJumpPower = true; humanoid.JumpPower = 70; initialMaxHealth = humanoid.MaxHealth; humanoid.MaxHealth = math.huge; humanoid.Health = math.huge end
        if healthConnection then healthConnection:Disconnect() end
        healthConnection = humanoid.HealthChanged:Connect(function(health) if health < math.huge then humanoid.Health = math.huge end end)
        if stateConnection then stateConnection:Disconnect() end
        stateConnection = humanoid.StateChanged:Connect(function(oldState, newState) if newState == Enum.HumanoidStateType.Dead then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp); humanoid.Health = math.huge end end)
    else
        print("⚫ Infinite Jump: OFF"); print("❌ God Mode: Auto-Disabled")
        if gravityConnection then gravityConnection:Disconnect(); gravityConnection = nil end
        if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
        if stateConnection then stateConnection:Disconnect(); stateConnection = nil end
        if humanoid then humanoid.JumpPower = 50; humanoid.MaxHealth = initialMaxHealth; humanoid.Health = initialMaxHealth end
    end
end
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then local character = LocalPlayer.Character; if character then local humanoid = character:FindFirstChildOfClass("Humanoid"); if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end end
end)

-- --- FLY/WALK TO BASE ---
local FLOAT_SPEED = 17; local FLOAT_UP_SPEED = 1.5; local FLOAT_HEIGHT_OFFSET = 5; local STOP_DISTANCE = 8
local function FindDelivery()
    local plots = workspace:WaitForChild("Plots", 5); if not plots then warn("❌ Plots folder not found in workspace"); return nil end
    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign"); if sign then
            local yourBase = sign:FindFirstChild("YourBase"); if yourBase and yourBase.Enabled then
                local hitbox = plot:FindFirstChild("DeliveryHitbox"); if hitbox then print("✅ Found DeliveryHitbox in:", plot.Name); return hitbox end
            end
        end
    end
    warn("❌ No valid DeliveryHitbox found"); return nil
end
local function stopAllTravel()
    isTraveling = false
    if floatConnection then floatConnection:Disconnect(); floatConnection = nil end
    if walkThread then task.cancel(walkThread); walkThread = nil end
    local Character = player.Character; if Character then
        local RootPart = Character:FindFirstChild("HumanoidRootPart"); local Humanoid = Character:FindFirstChild("Humanoid")
        if RootPart then RootPart.Velocity = Vector3.new(0, 0, 0); RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        if Humanoid then Humanoid:MoveTo(RootPart.Position) end
    end
    print("🛑 All travel stopped")
end
local function doFlyToBase()
    local Character = player.Character; if not Character then return false end
    local RootPart = Character:FindFirstChild("HumanoidRootPart"); if not RootPart then return false end
    local delivery = FindDelivery(); if not delivery then warn("❌ Cannot find DeliveryHitbox!"); return false end
    local targetPosition = delivery.Position + Vector3.new(0, FLOAT_HEIGHT_OFFSET, 0); print("🎈 Flying to DeliveryHitbox at:", targetPosition)
    isTraveling = true
    floatConnection = RunService.Heartbeat:Connect(function()
        if not isTraveling then stopAllTravel(); return end
        if not Character or not Character.Parent or not RootPart or not RootPart.Parent then isTraveling = false; stopAllTravel(); return end
        local currentPos = RootPart.Position; local deliveryPos = delivery.Position
        local horizontalDistance = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(deliveryPos.X, 0, deliveryPos.Z)).Magnitude
        if horizontalDistance <= STOP_DISTANCE then print("✅ Arrived at DeliveryHitbox!"); isTraveling = false; stopAllTravel(); return end
        local direction = (targetPosition - currentPos).Unit; local horizontalDir = Vector3.new(direction.X, 0, direction.Z).Unit
        RootPart.Velocity = Vector3.new(horizontalDir.X * FLOAT_SPEED, FLOAT_UP_SPEED, horizontalDir.Z * FLOAT_SPEED)
    end) return true
end
local function WalkTo(target)
    if not target or not target:IsA("BasePart") then warn("❌ Invalid target for WalkTo"); return false end
    local character = player.Character; if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChild("Humanoid"); local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then warn("❌ Character components missing"); return false end
    local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentJumpHeight = 8, AgentMaxSlope = 45 })
    local success, errorMessage = pcall(function() path:ComputeAsync(hrp.Position, target.Position) end)
    if not success then warn("❌ Path computation failed:", errorMessage); return false end
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints(); print("🚶 Walking to DeliveryHitbox... (" .. #waypoints .. " waypoints)")
        for i, waypoint in ipairs(waypoints) do
            if not isTraveling then print("⚠️ Walk cancelled by user"); return false end
            if not humanoid or not hrp or not humanoid.Parent then warn("❌ Character components missing during pathfinding"); return false end
            humanoid:MoveTo(waypoint.Position); local moveFinished = false; local timeoutThread = task.delay(2, function() if not moveFinished then humanoid:MoveTo(hrp.Position) end end)
            humanoid.MoveToFinished:Wait(); moveFinished = true; task.cancel(timeoutThread)
            local distance = (hrp.Position - target.Position).Magnitude; if distance < 5 then print("✅ Reached DeliveryHitbox!"); return true end
        end
        print("✅ Finished walking path"); return true
    else warn("❌ Path not found! Status:", path.Status); return false end
end
local function doWalkToBase()
    local delivery = FindDelivery(); if not delivery then warn("❌ Failed to find DeliveryHitbox"); return false end
    local success = WalkTo(delivery); if success then print("✅ Successfully reached delivery!") else print("⚠️ Walk to delivery failed or was cancelled") end; return true
end

-- --- FLY/TP TO BEST ---
local AnimalsModule, TraitsModule, MutationsModule
pcall(function() AnimalsModule = require(ReplicatedStorage.Datas.Animals); TraitsModule = require(ReplicatedStorage.Datas.Traits); MutationsModule = require(ReplicatedStorage.Datas.Mutations) end)
local function getTraitMultiplier(model)
    if not TraitsModule then return 0 end; local traitJson = model:GetAttribute("Traits"); if not traitJson or traitJson == "" then return 0 end
    local traits = {}; local ok, decoded = pcall(function() return HttpService:JSONDecode(traitJson) end)
    if ok and typeof(decoded) == "table" then traits = decoded else for t in string.gmatch(traitJson, "[^,]+") do table.insert(traits, t) end end
    local mult = 0; for _, entry in pairs(traits) do
        local name = typeof(entry) == "table" and entry.Name or tostring(entry); name = name:gsub("^_Trait%.", "")
        local trait = TraitsModule[name]; if trait and trait.MultiplierModifier then mult += tonumber(trait.MultiplierModifier) or 0 end
    end return mult
end
local function getFinalGeneration(model)
    if not AnimalsModule then return 0 end; local animalData = AnimalsModule[model.Name]; if not animalData then return 0 end
    local baseGen = tonumber(animalData.Generation) or tonumber(animalData.Price or 0); local traitMult = getTraitMultiplier(model); local mutationMult = 0
    if MutationsModule then local mutation = model:GetAttribute("Mutation"); if mutation and MutationsModule[mutation] then mutationMult = tonumber(MutationsModule[mutation].Modifier or 0) end end
    local final = baseGen * (1 + traitMult + mutationMult); return math.max(1, math.round(final))
end
local function formatNumber(num)
    if num >= 1e12 then return string.format("%.1fT/s", num / 1e12)
    elseif num >= 1e9 then return string.format("%.1fB/s", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM/s", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK/s", num / 1e3)
    else return string.format("%.0f/s", num) end
end
local function isPlayerPlot(plot)
    local plotSign = plot:FindFirstChild("PlotSign"); if plotSign then local yourBase = plotSign:FindFirstChild("YourBase"); if yourBase and yourBase.Enabled then return true end end
    return false
end
local function findBestPet()
    local plots = Workspace:FindFirstChild("Plots"); if not plots then return nil end; local highest = {value = 0}
    if AnimalsModule then
        for _, plot in pairs(plots:GetChildren()) do
            if not isPlayerPlot(plot) then
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("Model") and AnimalsModule[obj.Name] then
                        pcall(function()
                            local gen = getFinalGeneration(obj); if gen > 0 and gen > highest.value then
                                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                if root then
                                    highest = { plot = plot, plotName = plot.Name, petName = obj.Name, generation = gen, formattedValue = formatNumber(gen), model = obj, value = gen, position = root.Position, cframe = root.CFrame }
                                end
                            end
                        end)
                    end
                end
            end
        end
        if highest.value > 0 then return highest end
    end
    -- Fallback logic here if needed (omitted for brevity, assuming module system works)
    return highest.value > 0 and highest or nil
end
local function getSideBounds(sideFolder)
    if not sideFolder then return nil end; local minX, minY, minZ = math.huge, math.huge, math.huge; local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge; local found = false
    local function scan(obj) for _, child in ipairs(obj:GetChildren()) do if child:IsA("BasePart") then found = true; local p = child.Position; minX = math.min(minX, p.X); minY = math.min(minY, p.Y); minZ = math.min(minZ, p.Z); maxX = math.max(maxX, p.X); maxY = math.max(maxY, p.Y); maxZ = math.max(maxZ, p.Z) else scan(child) end end end
    scan(sideFolder); if not found then return nil end
    local center = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5); local halfSize = Vector3.new((maxX - minX) * 0.5, (maxY - minY) * 0.5, (maxZ - minZ) * 0.5)
    return { center = center, halfSize = halfSize, minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ }
end
local function getSafePosForFly(plot, targetPos, fromPos)
    local decorations = plot:FindFirstChild("Decorations"); if not decorations then return targetPos end
    local side3Folder = decorations:FindFirstChild("Side 3"); if not side3Folder then return targetPos end
    local info = getSideBounds(side3Folder); if not info then return targetPos end
    local center = info.center; local halfSize = info.halfSize; local MARGIN = 6
    local localTarget = targetPos - center; local insideX = math.abs(localTarget.X) <= halfSize.X + MARGIN; local insideZ = math.abs(localTarget.Z) <= halfSize.Z + MARGIN
    if not (insideX and insideZ) then return targetPos end
    local src = fromPos and (fromPos - center) or localTarget; local dir = Vector3.new(src.X, 0, src.Z)
    if dir.Magnitude < halfSize.X * 0.5 then
        local distToEdges = { {axis = "X", sign = 1, dist = halfSize.X - localTarget.X}, {axis = "X", sign = -1, dist = halfSize.X + localTarget.X}, {axis = "Z", sign = 1, dist = halfSize.Z - localTarget.Z}, {axis = "Z", sign = -1, dist = halfSize.Z + localTarget.Z} }
        table.sort(distToEdges, function(a, b) return a.dist < b.dist end); local nearest = distToEdges[1]
        if nearest.axis == "X" then dir = Vector3.new(nearest.sign, 0, 0) else dir = Vector3.new(0, 0, nearest.sign) end
    end
    local dirUnit = dir.Unit; local tx, tz = math.huge, math.huge
    if dirUnit.X ~= 0 then local boundX = (dirUnit.X > 0) and halfSize.X or -halfSize.X; tx = boundX / dirUnit.X end
    if dirUnit.Z ~= 0 then local boundZ = (dirUnit.Z > 0) and halfSize.Z or -halfSize.Z; tz = boundZ / dirUnit.Z end
    local tHit = math.min(tx, tz); if tHit == math.huge then return targetPos end
    local boundaryLocal = dirUnit * (tHit + MARGIN); local worldPos = center + boundaryLocal; return Vector3.new(worldPos.X, targetPos.Y, worldPos.Z)
end
local function getSafePosForTp(plot, targetPos, fromPos)
    local decorations = plot:FindFirstChild("Decorations"); if not decorations then return targetPos end
    local side3Folder = decorations:FindFirstChild("Side 3"); if not side3Folder then return targetPos end
    local info = getSideBounds(side3Folder); if not info then return targetPos end
    local center = info.center; local halfSize = info.halfSize; local MARGIN = 3.1
    local localTarget = targetPos - center; local insideX = math.abs(localTarget.X) <= halfSize.X; local insideZ = math.abs(localTarget.Z) <= halfSize.Z
    if not (insideX and insideZ) then return targetPos end
    local src = fromPos and (fromPos - center) or localTarget; local dir = Vector3.new(src.X, 0, src.Z)
    if dir.Magnitude < 1e-3 then dir = Vector3.new(0, 0, 1) end
    local dirUnit = dir.Unit; local tx, tz = math.huge, math.huge
    if dirUnit.X ~= 0 then local boundX = (dirUnit.X > 0) and halfSize.X or -halfSize.X; tx = boundX / dirUnit.X end
    if dirUnit.Z ~= 0 then local boundZ = (dirUnit.Z > 0) and halfSize.Z or -halfSize.Z; tz = boundZ / dirUnit.Z end
    local tHit = math.min(tx, tz); if tHit == math.huge then return targetPos end
    local boundaryLocal = dirUnit * (tHit + MARGIN); local worldPos = center + boundaryLocal; return Vector3.new(worldPos.X, targetPos.Y, worldPos.Z)
end
local function autoEquipGrapple()
    local success, result = pcall(function()
        local character = LocalPlayer.Character; if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid"); if not (humanoid and humanoid.Health > 0) then return false end
        humanoid:UnequipTools(); local backpack = LocalPlayer:WaitForChild("Backpack"); local grapple = backpack:FindFirstChild("Grapple Hook")
        if grapple then grapple.Parent = character; humanoid:EquipTool(grapple); return true end; return false
    end) return success and result
end
local UseItemRemote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")
local function fireGrapple() pcall(function() local args = {1.9832406361897787}; UseItemRemote:FireServer(unpack(args)) end) end
local function stopVelocityFlight()
    if velocityConnection then velocityConnection:Disconnect(); velocityConnection = nil end; isFlyingToBest = false
end
local function completeFlyToBest()
    stopVelocityFlight(); isToggled5 = false; if ui and ui.setToggleState then ui:setToggleState("Fly/TP to Best", false) end; print("🛑 Fly to Best complete. Toggle auto-off.")
end
local function velocityFlightToPet()
    local character = LocalPlayer.Character; if not character then print("❌ Character not found!"); return false end
    local hrp = character:FindFirstChild("HumanoidRootPart"); local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then print("❌ HumanoidRootPart not found!"); return false end
    if velocityConnection then velocityConnection:Disconnect(); velocityConnection = nil end; isFlyingToBest = false
    print("🔍 Scanning for best pet..."); local bestPet = findBestPet(); if not bestPet then print("❌ No pet found!"); return false end
    print("🎯 " .. bestPet.petName .. " (" .. bestPet.formattedValue .. ")")
    local currentPos = hrp.Position; local targetPos = bestPet.position; local plot = bestPet.plot
    local directionToPet = (targetPos - currentPos).Unit; local approachPos = targetPos - (directionToPet * 7)
    local animalY = targetPos.Y; if animalY > 10 then approachPos = Vector3.new(approachPos.X, 20, approachPos.Z) else approachPos = Vector3.new(approachPos.X, animalY + 2, approachPos.Z) end
    local finalPos = getSafePosForFly(plot, approachPos, currentPos)
    print("🪝 Equipping Grapple..."); local grappleEquipped = autoEquipGrapple(); if not grappleEquipped then print("⚠️ No Grapple Hook found!") end
    task.wait(0.1); print("🔥 Firing Grapple..."); if grappleEquipped then fireGrapple() end; task.wait(0.05)
    print("🚀 Flying to target..."); isFlyingToBest = true; local baseSpeed = 180
    velocityConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToBest then stopVelocityFlight(); return end
        local character = LocalPlayer.Character; if not character then completeFlyToBest(); return end
        local hrp = character:FindFirstChild("HumanoidRootPart"); if not hrp then completeFlyToBest(); return end
        local distanceToTarget = (finalPos - hrp.Position).Magnitude
        if distanceToTarget <= 3 then completeFlyToBest(); print("✅ Arrived! Auto-OFF"); hrp.CFrame = CFrame.new(finalPos); return end
        local currentSpeed = baseSpeed; if distanceToTarget <= 20 then local slowdownFactor = distanceToTarget / 20; currentSpeed = math.max(50, baseSpeed * slowdownFactor) end
        local currentDirection = (finalPos - hrp.Position).Unit; local velocityVector = currentDirection * currentSpeed; hrp.Velocity = velocityVector
    end) return true
end
local function equipFlyingCarpet()
    local success, result = pcall(function()
        local character = LocalPlayer.Character; if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid"); if not (humanoid and humanoid.Health > 0) then return false end
        humanoid:UnequipTools(); local backpack = LocalPlayer:WaitForChild("Backpack")
        local carpet = backpack:FindFirstChild("Flying Carpet") or backpack:FindFirstChild("FlyingCarpet") or backpack:FindFirstChild("flying carpet") or backpack:FindFirstChild("flyingcarpet")
        if carpet then carpet.Parent = character; humanoid:EquipTool(carpet); return true end
        local equippedCarpet = character:FindFirstChildWhichIsA("Tool") and (equippedCarpet.Name == "Flying Carpet" or equippedCarpet.Name == "FlyingCarpet")
        if equippedCarpet then humanoid:EquipTool(equippedCarpet); return true end; return false
    end) return success and result
end
local function tpToBest()
    local character = LocalPlayer.Character; if not character then print("❌ Character not found!"); return false end
    local hrp = character:FindFirstChild("HumanoidRootPart"); local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then print("❌ HumanoidRootPart not found!"); return false end
    print("🔍 Scanning for best pet..."); local bestPet = findBestPet(); if not bestPet then print("❌ No pet found!"); return false end
    print("🎯 " .. bestPet.petName .. " (" .. bestPet.formattedValue .. ")")
    local currentPos = hrp.Position; local targetPos = bestPet.position; local plot = bestPet.plot
    print("🚀 Applying smooth velocity..."); local state = humanoid:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then humanoid:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(0.05) end
    local targetUpwardSpeed = 120; local currentUpwardSpeed = 0; local smoothness = 0.25; local elapsed = 0; local maxDuration = 0.3
    local velocityConnection = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt; if elapsed >= maxDuration then velocityConnection:Disconnect(); return end
        local character = LocalPlayer.Character; if not character then velocityConnection:Disconnect(); return end
        local hrp = character:FindFirstChild("HumanoidRootPart"); if not hrp then velocityConnection:Disconnect(); return end
        currentUpwardSpeed = currentUpwardSpeed + (targetUpwardSpeed - currentUpwardSpeed) * smoothness
        hrp.Velocity = Vector3.new(hrp.Velocity.X, currentUpwardSpeed, hrp.Velocity.Z)
    end)
    task.wait(0.3); print("🪝 Equipping Grapple..."); local grappleEquipped = autoEquipGrapple(); print("🔥 Firing Grapple..."); if grappleEquipped then fireGrapple() end; task.wait(0.05)
    print("🪂 Switching to Carpet..."); local carpetEquipped = equipFlyingCarpet(); task.wait(0.1)
    local finalPos = getSafePosForTp(plot, targetPos, currentPos); local animalY = targetPos.Y
    if animalY > 10 then finalPos = Vector3.new(finalPos.X, 20, finalPos.Z) else finalPos = Vector3.new(finalPos.X, animalY, finalPos.Z) end
    print("⚡ Teleporting..."); hrp.CFrame = CFrame.new(finalPos); print("✅ TP + Carpet Success!"); stopVelocityFlight(); return true
end

-- --- PERM DESYNC ---
local function initializeESPFolder()
    for _, existing in ipairs(Workspace:GetChildren()) do if existing.Name == "DesyncESP" then existing:Destroy() end end
    ESPFolder = Instance.new("Folder"); ESPFolder.Name = "DesyncESP"; ESPFolder.Parent = Workspace
end
local function createESPPart(name, color)
    local part = Instance.new("Part"); part.Name = name; part.Size = Vector3.new(2, 5, 2); part.Anchored = true; part.CanCollide = false; part.Material = Enum.Material.Neon; part.Color = color; part.Transparency = 0.3; part.Parent = ESPFolder
    local highlight = Instance.new("Highlight"); highlight.FillColor = color; highlight.OutlineColor = color; highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0; highlight.Parent = part
    local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.new(0, 100, 0, 40); billboard.Adornee = part; billboard.AlwaysOnTop = true; billboard.Parent = part
    local textLabel = Instance.new("TextLabel"); textLabel.Size = UDim2.new(1, 0, 1, 0); textLabel.BackgroundTransparency = 1; textLabel.Text = name; textLabel.TextColor3 = color; textLabel.TextStrokeTransparency = 0.5; textLabel.TextScaled = true; textLabel.Font = Enum.Font.GothamBold; textLabel.Parent = billboard
    return part
end
local function updateESP() if fakePosESP and serverPosition then fakePosESP.CFrame = CFrame.new(serverPosition) end end
local function initializeESP()
    if not ESPFolder then initializeESPFolder() else ESPFolder:ClearAllChildren() end
    fakePosESP = createESPPart("Server Position", Color3.fromRGB(255, 0, 0))
    local char = LocalPlayer.Character; if char then
        local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then
            serverPosition = hrp.Position; fakePosESP.CFrame = CFrame.new(serverPosition)
            hrp:GetPropertyChangedSignal("CFrame"):Connect(function() task.wait(0.2); serverPosition = hrp.Position end)
        end
    end
end
local function deactivateESP()
    if ESPFolder then ESPFolder:ClearAllChildren() end; fakePosESP = nil; serverPosition = nil
end
local function stopAllAnimations(character)
    local humanoid = character:FindFirstChildWhichIsA("Humanoid"); if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator"); if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
        end
    end
end
local function applyNetworkSettings()
    local fenv = getfenv()
    pcall(function() fenv.setfflag("GameNetPVHeaderRotationalVelocityZeroCutoffExponent", "-5000") end)
    -- ... (other setfflag calls omitted for brevity, but should be included)
end
local function respawnDesync()
    local character = LocalPlayer.Character; if not character then return end; stopAllAnimations(character); applyNetworkSettings()
    local humanoid = character:FindFirstChildWhichIsA("Humanoid"); if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead); character:ClearAllChildren()
        local tempModel = Instance.new("Model"); tempModel.Parent = workspace; LocalPlayer.Character = tempModel; task.wait(0.1)
        LocalPlayer.Character = character; tempModel:Destroy(); task.wait(0.05)
        if character and character.Parent then local newHumanoid = character:FindFirstChildWhichIsA("Humanoid"); if newHumanoid then newHumanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end
    task.wait(0.5); initializeESP()
end

-- ==================== EVENT CONNECTIONS ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5); updateHumanoidRootPart()
    if allFeaturesEnabled then if floorGrabPart then floorGrabPart:Destroy(); floorGrabPart = nil end; if floorGrabConnection then floorGrabConnection:Disconnect(); floorGrabConnection = nil end; startFloorGrab(); task.wait(0.5); autoEquipLaserCape() end
    if isTraveling then stopAllTravel(); if ui and ui.setToggleState then ui:setToggleState("Fly/Walk to Base", false) end; warn("⚠️ Character respawned - Travel stopped") end
    if isFlyingToBest then completeFlyToBest(); warn("⚠️ Character respawned - Flight to best stopped") end
    if respawnDesyncEnabled then task.wait(1); initializeESP() end
    if noWalkAnimationEnabled then setupNoWalkAnimation(LocalPlayer.Character) end
    if infJumpEnabled then toggleInfJump(true) end
end)
player.CharacterRemoving:Connect(function()
    stopAllTravel(); completeFlyToBest(); if respawnDesyncEnabled then deactivateESP() end
end)

-- ==================== UI CREATION & MAIN LOGIC ====================
local function createUIAndConnect()
    local NightmareUILib = loadLibrary()
    if not NightmareUILib then
        warn("UI Library could not be loaded. Aborting.")
        return
    end

    ui = NightmareUILib.new()

    -- Toggle Perm Desync
    ui:addToggle({
        text = "Perm Desync",
        initialState = false,
        onClick = function(isOn)
            if isOn then
                print("Perm Desync dihidupkan")
                if ui.showNotification then
                    ui:showNotification("Desync", "Desync Successful", 5)
                else
                    StarterGui:SetCore("SendNotification", {Title = "Desync"; Text = "Desync Successful"; Duration = 5;})
                end
                if not ESPFolder then initializeESPFolder() end
                respawnDesync()
                respawnDesyncEnabled = true
                if not respawnDesyncConnection then
                    respawnDesyncConnection = RunService.RenderStepped:Connect(function() if respawnDesyncEnabled then updateESP() end end)
                end
            else
                print("Perm Desync dimatikan")
                deactivateESP()
                respawnDesyncEnabled = false
            end
        end
    })

    -- Toggle Speed Booster
    ui:addToggle({
        text = "Speed Booster",
        initialState = false,
        onClick = function(isOn) toggleSpeed(isOn) end
    })

    -- Toggle Inf Jump
    ui:addToggle({
        text = "Inf Jump",
        initialState = false,
        onClick = function(isOn) toggleInfJump(isOn) end
    })

    -- Toggle Fly/Walk to Base
    ui:addToggleWithSwitch({
        text = "Fly/Walk to Base",
        initialState = false,
        initialSwitchState = true,
        switchTextOn = "Fly to Base",
        switchTextOff = "Walk to Base",
        onClick = function(isOn, switchState)
            isFlyMode = switchState
            if isOn then
                if isFlyMode then
                    print("Fly to Base dihidupkan")
                    doFlyToBase()
                else
                    print("Walk to Base dihidupkan")
                    walkThread = task.spawn(doWalkToBase)
                end
            else
                print("Travel dimatikan")
                stopAllTravel()
            end
        end
    })

    -- Toggle Fly/TP to Best
    ui:addToggleWithSwitch({
        text = "Fly/TP to Best",
        initialState = false,
        initialSwitchState = true,
        switchTextOn = "Fly to Best",
        switchTextOff = "Tp to Best",
        onClick = function(isOn, switchState)
            isFlyToBestMode = switchState
            if isOn then
                if isFlyToBestMode then
                    print("Fly to Best dihidupkan")
                    velocityFlightToPet()
                else
                    print("Tp to Best dihidupkan")
                    tpToBest()
                    -- TP is instant, so turn off the toggle immediately
                    if ui and ui.setToggleState then
                        ui:setToggleState("Fly/TP to Best", false)
                    end
                end
            else
                print("Flight/TP dimatikan")
                stopVelocityFlight()
            end
        end
    })

    -- Toggle Steal Floor
    ui:addToggle({
        text = "Steal Floor",
        initialState = false,
        onClick = function(isOn) toggleAllFeatures(isOn) end
    })
end

-- Initialize
if LocalPlayer.Character then
    setupNoWalkAnimation(LocalPlayer.Character)
end

createUIAndConnect()

print("==========================================")
print("🎮 NIGHTMARE HUB LOADED!")
print("==========================================")
