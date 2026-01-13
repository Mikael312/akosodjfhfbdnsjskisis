--[[
    SIMPLE ARCADE UI 🎮 (UPDATED)
    Rounded rectangle, draggable, arcade style
    WITH NEW DEVOURER UI DESIGN (IMPROVED)
    WITH NEW RESPAWN DESYNC + SERVER POSITION ESP
    WITH NEW FLY/TP TO BEST FEATURE (FIXED MODULES & LOGIC)
    WITH IMPROVED INFINITE JUMP + LOW GRAVITY (NEW)
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
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local UserSettings = game:GetService("UserSettings")
local CoreGui = game:GetService("CoreGui")

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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

-- ==================== FLY/TP TO BEST VARIABLES ====================
local isFlyingToBest = false
local velocityConnection = nil

-- ==================== INFINITE JUMP + LOW GRAVITY VARIABLES (NEW) ====================
local infiniteJumpEnabled = false
local lowGravityEnabled = false
local jumpRequestConnection = nil
local bodyForce = nil
local lowGravityForce = 50
local defaultGravity = workspace.Gravity

-- ==================== GRAPPLE FLY VARIABLES ====================
local IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local grappleFlyActive = false
local grappleFlySpeed = 160 -- LOCKED SPEED - CANNOT BE CHANGED
local grappleFlyGrappleConn = nil
local grappleFlyRenderConn = nil
local BodyVelocity = nil
local BodyGyro = nil

-- Get ControlModule for mobile joystick
local ControlModule = nil
pcall(function()
    ControlModule = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)

-- ==================== MODULE DATA FOR BEST PET DETECTION (CORRECTED) ====================
local AnimalsModule, TraitsModule, MutationsModule

pcall(function()
    AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    TraitsModule = require(ReplicatedStorage.Datas.Traits)
    MutationsModule = require(ReplicatedStorage.Datas.Mutations)
end)

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
end

local function stopXrayBase()
    restoreTransparency()
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
        return true
    else
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
    if humanoid.Health <=0 then return false end
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
        return
    end
    
    if autoLaserThread then
        task.cancel(autoLaserThread)
    end
    autoLaserThread = task.spawn(autoLaserWorker)
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
end

-- ========================================
-- MASTER TOGGLE FUNCTION
-- ========================================
local function toggleAllFeatures(enabled)
    allFeaturesEnabled = enabled
    
    if allFeaturesEnabled then
        -- Start all features
        startFloorGrab()
        startXrayBase()
        startAutoLaser()
    else
        -- Stop all features
        stopFloorGrab()
        stopXrayBase()
        stopAutoLaser()
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
    else
        stopSpeedControl()
    end
end

-- ==================== IMPROVED INFINITE JUMP + LOW GRAVITY (NEW) ====================
-- ========================================
-- Infinite Jump Function (NEW)
-- ========================================

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
    
    jumpRequestConnection = UserInputService.JumpRequest:Connect(function()
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

-- ========================================
-- Low Gravity Function (NEW)
-- ========================================

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

-- ========================================
-- Toggle Logic (NEW)
-- ========================================

local function toggleInfJump(enabled)
    infiniteJumpEnabled = enabled
    lowGravityEnabled = enabled
    
    if enabled then
        -- Enable
        -- Setup inf jump
        local char = player.Character
        if char then
            initializeJumpForCharacter(char)
        end
        
        -- Setup low gravity
        updateGravity()
    else
        -- Disable
        -- Disconnect jump
        if jumpRequestConnection then
            jumpRequestConnection:Disconnect()
            jumpRequestConnection = nil
        end
        
        -- Remove gravity
        updateGravity()
    end
end

-- ==================== FLY/TP TO BEST FUNCTIONS (UNIFIED & OPTIMIZED) ====================
-- BAHARU: Fungsi pencarian telah disatukan untuk mengelakkan imbasan berganda dan ralat.

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

-- Helper function to get final generation
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

-- Check if plot is player's plot
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

-- BAHARU: Fungsi pencarian disatukan
local function findTheAbsoluteBestPet()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local highest = {value = 0}
    
    -- First try using the new module-based system
    if AnimalsModule then
        for _, plot in pairs(plots:GetChildren()) do
            if not isPlayerPlot(plot) then
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("Model") and AnimalsModule[obj.Name] then
                        pcall(function()
                            local gen = getFinalGeneration(obj)
                            
                            if gen > 0 and gen > highest.value then
                                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                
                                if root then
                                    highest = {
                                        plot = plot,
                                        plotName = plot.Name,
                                        petName = obj.Name,
                                        generation = gen,
                                        model = obj,
                                        value = gen, -- This is the raw numerical value
                                        position = root.Position,
                                        cframe = root.CFrame
                                    }
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        if highest.value > 0 then
            return highest
        end
    end
    
    -- Fallback to old text-based system
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    local txt = obj.Text or ""
                    
                    if txt:find("/") and txt:lower():find("s") then
                        pcall(function()
                            local nameLabel = nil
                            local parent = obj.Parent
                            
                            if parent then
                                nameLabel = parent:FindFirstChild("DisplayName")
                                
                                if not nameLabel and parent.Parent then
                                    nameLabel = parent.Parent:FindFirstChild("DisplayName")
                                end
                            end
                            
                            if not nameLabel or nameLabel.Text == "" or txt == "" or txt == "N/A" then
                                return
                            end
                            
                            local petName = nameLabel.Text
                            local genText = txt
                            
                            -- Try to parse the value
                            local value = nil
                            if genText:find("T/s") then
                                value = tonumber(genText:match("(%d+%.?%d*)T/s")) * 1e12
                            elseif genText:find("B/s") then
                                value = tonumber(genText:match("(%d+%.?%d*)B/s")) * 1e9
                            elseif genText:find("M/s") then
                                value = tonumber(genText:match("(%d+%.?%d*)M/s")) * 1e6
                            elseif genText:find("K/s") then
                                value = tonumber(genText:match("(%d+%.?%d*)K/s")) * 1e3
                            else
                                value = tonumber(genText:match("(%d+%.?%d*)/s")) or 0
                            end
                            
                            if value and value > 0 and value > highest.value then
                                local model = obj:FindFirstAncestorOfClass('Model')
                                
                                if model then
                                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart')
                                    
                                    if part then
                                        highest = {
                                            plot = plot,
                                            plotName = plot.Name,
                                            petName = petName,
                                            generation = value,
                                            model = model,
                                            value = value, -- This is the raw numerical value
                                            position = part.Position,
                                            cframe = part.CFrame
                                        }
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
    
    return highest.value > 0 and highest or nil
end

-- Auto-equip Grapple Hook
local function autoEquipGrapple()
    local success, result = pcall(function()
        local character = LocalPlayer.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health > 0) then return false end
        
        humanoid:UnequipTools()
        
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local grapple = backpack:FindFirstChild("Grapple Hook")
        
        if grapple then
            grapple.Parent = character
            humanoid:EquipTool(grapple)
            return true
        end
        
        return false
    end)
    
    return success and result
end

-- Fire Grapple Hook
local UseItemRemote = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("Net")
    :WaitForChild("RE/UseItem")

local function fireGrapple()
    pcall(function()
        local args = {1.9832406361897787}
        UseItemRemote:FireServer(unpack(args))
    end)
end

-- Get side bounds
local function getSideBounds(sideFolder)
    if not sideFolder then return nil end
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local found = false
    
    local function scan(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                found = true
                local p = child.Position
                minX = math.min(minX, p.X)
                minY = math.min(minY, p.Y)
                minZ = math.min(minZ, p.Z)
                maxX = math.max(maxX, p.X)
                maxY = math.max(maxY, p.Y)
                maxZ = math.max(maxZ, p.Z)
            else
                scan(child)
            end
        end
    end
    
    scan(sideFolder)
    if not found then return nil end
    
    local center = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
    local halfSize = Vector3.new((maxX - minX) * 0.5, (maxY - minY) * 0.5, (maxZ - minZ) * 0.5)
    
    return {
        center = center,
        halfSize = halfSize,
        minX = minX,
        maxX = maxX,
        minZ = minZ,
        maxZ = maxZ,
    }
end

-- Get safe outside decoration position
local function getSafeOutsideDecorPos(plot, targetPos, fromPos)
    local decorations = plot:FindFirstChild("Decorations")
    if not decorations then return targetPos end
    
    local side3Folder = decorations:FindFirstChild("Side 3")
    if not side3Folder then return targetPos end
    
    local info = getSideBounds(side3Folder)
    if not info then return targetPos end
    
    local center = info.center
    local halfSize = info.halfSize
    local MARGIN = 3.2
    
    local localTarget = targetPos - center
    local insideX = math.abs(localTarget.X) <= halfSize.X + MARGIN
    local insideZ = math.abs(localTarget.Z) <= halfSize.Z + MARGIN
    
    if not (insideX and insideZ) then
        return targetPos
    end
    
    local src = fromPos and (fromPos - center) or localTarget
    local dir = Vector3.new(src.X, 0, src.Z)
    
    if dir.Magnitude < halfSize.X * 0.5 then
        local distToEdges = {
            {axis = "X", sign = 1, dist = halfSize.X - localTarget.X},
            {axis = "X", sign = -1, dist = halfSize.X + localTarget.X},
            {axis = "Z", sign = 1, dist = halfSize.Z - localTarget.Z},
            {axis = "Z", sign = -1, dist = halfSize.Z + localTarget.Z}
        }
        
        table.sort(distToEdges, function(a, b) return a.dist < b.dist end)
        
        local nearest = distToEdges[1]
        if nearest.axis == "X" then
            dir = Vector3.new(nearest.sign, 0, 0)
        else
            dir = Vector3.new(0, 0, nearest.sign)
        end
    end
    
    local dirUnit = dir.Unit
    
    local tx, tz = math.huge, math.huge
    
    if dirUnit.X ~= 0 then
        local boundX = (dirUnit.X > 0) and halfSize.X or -halfSize.X
        tx = boundX / dirUnit.X
    end
    
    if dirUnit.Z ~= 0 then
        local boundZ = (dirUnit.Z > 0) and halfSize.Z or -halfSize.Z
        tz = boundZ / dirUnit.Z
    end
    
    local tHit = math.min(tx, tz)
    if tHit == math.huge then return targetPos end
    
    local boundaryLocal = dirUnit * (tHit + MARGIN)
    local worldPos = center + boundaryLocal
    
    return Vector3.new(worldPos.X, targetPos.Y, worldPos.Z)
end

-- Stop velocity flight
local function stopVelocityFlight()
    if velocityConnection then
        velocityConnection:Disconnect()
        velocityConnection = nil
    end
    isFlyingToBest = false
end

-- Fly to Best function (now uses the unified finder)
local function velocityFlightToPet()
    local character = LocalPlayer.Character
    if not character then 
        return false
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not hrp or not humanoid then 
        return false
    end
    
    -- Use the unified finder function
    local bestPet = findTheAbsoluteBestPet()
    
    if not bestPet then
        return false
    end
    
    local currentPos = hrp.Position
    local targetPos = bestPet.position
    local plot = bestPet.plot
    
    local directionToPet = (targetPos - currentPos).Unit
    local approachPos = targetPos - (directionToPet * 7)
    
    local animalY = targetPos.Y
    if animalY > 10 then
        approachPos = Vector3.new(approachPos.X, 20, approachPos.Z)
    else
        approachPos = Vector3.new(approachPos.X, animalY + 2, approachPos.Z)
    end
    
    local finalPos = getSafeOutsideDecorPos(plot, approachPos, currentPos)
    
    local grappleEquipped = autoEquipGrapple()
    if not grappleEquipped then
        return false
    end
    
    task.wait(0.1)
    
    -- TAMBAH SEMULA: Panggilan fireGrapple() yang hilang
    fireGrapple()
    
    task.wait(0.05)
    
    isFlyingToBest = true
    
    local direction = (finalPos - hrp.Position).Unit
    local distance = (finalPos - hrp.Position).Magnitude
    
    local baseSpeed = 180
    
    velocityConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToBest then
            if velocityConnection then velocityConnection:Disconnect() end
            return
        end
        
        local character = LocalPlayer.Character
        if not character then
            stopVelocityFlight()
            return
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            stopVelocityFlight()
            return
        end
        
        local distanceToTarget = (finalPos - hrp.Position).Magnitude
        
        if distanceToTarget <= 3 then
            stopVelocityFlight()
            hrp.CFrame = CFrame.new(finalPos)
            return
        end
        
        local currentSpeed = baseSpeed
        if distanceToTarget <= 20 then
            local slowdownFactor = distanceToTarget / 20
            currentSpeed = math.max(50, baseSpeed * slowdownFactor)
        end
        
        local currentDirection = (finalPos - hrp.Position).Unit
        local velocityVector = currentDirection * currentSpeed
        
        hrp.Velocity = velocityVector
    end)
    
    return true
end

-- Format number for display (TP version uses $)
local function formatNumberTP(num)
    if num >= 1e12 then
        return string.format("$%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("$%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("$%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("$%.1fK", num / 1e3)
    else
        return string.format("$%.0f", num)
    end
end

-- Format number for display (Fly version uses /s)
local function formatNumberFly(num)
    if num >= 1e12 then
        return string.format("%.1fT/s", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB/s", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM/s", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK/s", num / 1e3)
    else
        return string.format("%.0f/s", num)
    end
end

-- Equip Flying Carpet
local function equipFlyingCarpet()
    local success, result = pcall(function()
        local character = LocalPlayer.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health > 0) then return false end
        
        humanoid:UnequipTools()
        
        local backpack = LocalPlayer:WaitForChild("Backpack")
        local carpet = backpack:FindFirstChild("Flying Carpet") or 
                      backpack:FindFirstChild("FlyingCarpet") or
                      backpack:FindFirstChild("flying carpet") or
                      backpack:FindFirstChild("flyingcarpet")
        
        if carpet then
            carpet.Parent = character
            humanoid:EquipTool(carpet)
            return true
        end
        
        local equippedCarpet = character:FindFirstChild("Flying Carpet") or 
                               character:FindFirstChild("FlyingCarpet") or
                               character:FindFirstChild("flying carpet") or
                               character:FindFirstChild("flyingcarpet")
        
        if equippedCarpet and equippedCarpet:IsA("Tool") then
            humanoid:EquipTool(equippedCarpet)
            return true
        end
        
        return false
    end)
    
    return success and result
end

-- Stop velocity
local function stopVelocity()
    if velocityConnection then
        velocityConnection:Disconnect()
        velocityConnection = nil
    end
end

 -- Safe teleport to pet (now uses unified finder and side bounce logic)
local function safeTeleportToPet()
    local character = LocalPlayer.Character
    if not character then 
        return false
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not hrp or not humanoid then 
        return false
    end
    
    -- Use the unified finder function
    local bestPet = findTheAbsoluteBestPet()
    
    if not bestPet then
        return false
    end
    
    local currentPos = hrp.Position
    local targetPos = bestPet.position
    local plot = bestPet.plot
    
    -- FIX: Calculate approachPos first, just like in flyToBest
    local directionToPet = (targetPos - currentPos).Unit
    local approachPos = targetPos - (directionToPet * 7)
    
    local animalY = targetPos.Y
    if animalY > 10 then
        approachPos = Vector3.new(approachPos.X, 20, approachPos.Z)
    else
        approachPos = Vector3.new(approachPos.X, animalY + 2, approachPos.Z)
    end
    
    local state = humanoid:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.05)
    end
    
    local targetUpwardSpeed = 120
    local currentUpwardSpeed = 0
    local smoothness = 0.25
    local elapsed = 0
    local maxDuration = 0.3
    
    velocityConnection = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        
        if elapsed >= maxDuration then
            stopVelocity()
            return
        end
        
        local character = LocalPlayer.Character
        if not character then
            stopVelocity()
            return
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            stopVelocity()
            return
        end
        
        currentUpwardSpeed = currentUpwardSpeed + (targetUpwardSpeed - currentUpwardSpeed) * smoothness
        hrp.Velocity = Vector3.new(hrp.Velocity.X, currentUpwardSpeed, hrp.Velocity.Z)
    end)
    
    task.wait(0.3)
    stopVelocity()
    
    local grappleEquipped = autoEquipGrapple()
    
    if grappleEquipped then
        fireGrapple()
    end
    
    task.wait(0.05)
    
    local carpetEquipped = equipFlyingCarpet()
    
    task.wait(0.1)
    
    -- FIX: Use the calculated approachPos for the side bounce logic
    local finalPos = getSafeOutsideDecorPos(plot, approachPos, currentPos)
    
    -- The rest of the logic for adjusting Y position seems fine, but the initial position is now correct.
    local animalY = finalPos.Y -- Use Y from the potentially adjusted finalPos
    if animalY > 10 then
        finalPos = Vector3.new(finalPos.X, 20, finalPos.Z)
    else
        finalPos = Vector3.new(finalPos.X, animalY, finalPos.Z)
    end
    
    hrp.CFrame = CFrame.new(finalPos)
    
    task.wait(0.5)
    
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

-- ==================== NEW FUNCTIONS ====================
-- Quantum Desync Function
local function performQuantumDesync()
    pcall(function()
        local backpack = player:WaitForChild("Backpack")
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local packages = ReplicatedStorage:WaitForChild("Packages")
        local netFolder = packages:WaitForChild("Net")
        local useItemRemote = netFolder:WaitForChild("RE/UseItem")
        local teleportRemote = netFolder:WaitForChild("RE/QuantumCloner/OnTeleport")

        local toolNames = {"Quantum Cloner","Brainrot","brainrot"}
        local tool
        for _, name in ipairs(toolNames) do
            tool = backpack:FindFirstChild(name) or char:FindFirstChild(name)
            if tool then break end
        end
        if not tool then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then tool=item break end
            end
        end
        if tool and tool.Parent==backpack then humanoid:EquipTool(tool) end

        useItemRemote:FireServer()
        teleportRemote:FireServer()
    end)
end

-- FPS Devourer Function (IMPROVED SPEED)
local function fpsDevourer()
    -- Note: Initial loops may cause a temporary lag spike as they scan the entire workspace.

    local LocalPlayer = Players.LocalPlayer
    local Backpack = LocalPlayer:WaitForChild("Backpack")

    -- Imposta qualitÃ  grafica al minimo
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    pcall(function()
        local gameSettings = UserSettings().GameSettings
        gameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        gameSettings.GraphicsQualityLevel = 1
    end)

    -- Disabilita effetti di illuminazione
    Lighting.GlobalShadows = false
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- Disabilita PostEffects
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end

    -- Disabilita ParticleEmitters
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v.Enabled = false
        end
    end

    -- Funzione per rimuovere accessori
    local function removeAccessories(parent)
        if not parent then return end
        
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Accessory") then
                child:Destroy()
            end
        end
        
        parent.ChildAdded:Connect(function(child)
            if child:IsA("Accessory") then
                child:Destroy()
            end
        end)
    end

    -- Rimuovi accessori dagli Humanoid esistenti
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") then
            removeAccessories(v.Parent)
        end
    end

    -- Rimuovi accessori dai nuovi Humanoid
    workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Humanoid") then
            removeAccessories(descendant.Parent)
        end
    end)

    -- EQUIP AND ACTIVATE QUANTUM CLONER (The action part)
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end
    
    local QuantumCloner = Backpack:FindFirstChild("Quantum Cloner")
    if not QuantumCloner then return end
    
    Humanoid:EquipTool(QuantumCloner)
    task.wait()
    
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = Character
        end
    end
    
    task.wait()
    QuantumCloner:Activate()
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
mainFrame.Size = UDim2.new(0, 180, 0, 290) -- DIKECILKAN LEBAR DARI 200 JADI 180
mainFrame.Position = UDim2.new(0.5, -90, 0.5, -145) -- DISESUAIKAN UNTUK CENTERING BARU (180/2 = 90)
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

-- ====================================================--
--  FUNGSI UNTUK MENCipta BUTANG TOGGLE (REKA BENTUK BAHARU)
-- ====================================================--
local function createToggleButton(parent, name, text, position, size)
    -- Mencipta TextButton utama
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 160, 0, 32) -- Saiz default disesuaikan
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.Font = Enum.Font.Arcade -- DITUKAR BALIK KE ARCADE
    button.AutoButtonColor = false -- Mematikan kesan butang default
    button.Parent = parent
    
    -- Mencipta bucu bulat (Rounded Corners)
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    -- Mencipta garis luar (Outline)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana)
    btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Parent = button
    
    return button
end

-- ====================================================--
--  FUNGSI UNTUK MENGUBAH KEADAAN (ON/OFF)
-- ====================================================--
local function setToggleState(button, enabled)
    local btnStroke = button:FindFirstChildOfClass("UIStroke")
    
    if enabled then
        -- --- KEADAAN "ON" --- --
        button.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Warna latar belakang ON (Merah Cerah)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(255, 60, 60) -- Warna garis luar ON (Merah Terang)
            btnStroke.Thickness = 1.0 -- Ketebalan garis luar ON (Lebih Tebal)
        end
    else
        -- --- KEADAAN "OFF" --- --
        button.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana)
            btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF (Nipis)
        end
    end
end

-- ====================================================--
--  FUNGSI UNTUK MENCipta BUTANG SWITCH (REKA BENTUK BAHARU)
-- ====================================================--
local function createSwitchButton(parent, name, text, position, size)
    -- Mencipta TextButton utama
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.new(0, 30, 0, 32)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 55) -- Warna latar belakang OFF (Kelabu Gelap)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 18
    button.Font = Enum.Font.Arcade -- DITUKAR BALIK KE ARCADE
    button.AutoButtonColor = false -- Mematikan kesan butang default
    button.Parent = parent
    
    -- Mencipta bucu bulat (Rounded Corners)
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    -- Mencipta garis luar (Outline)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(80, 80, 80) -- Warna garis luar OFF (Kelabu)
    btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Parent = button
    
    return button
end

-- ====================================================--
--  FUNGSI UNTUK MENGUBAH KEADAAN SWITCH (ON/OFF)
-- ====================================================--
local function setSwitchState(button, enabled)
    local btnStroke = button:FindFirstChildOfClass("UIStroke")
    
    if enabled then
        -- --- KEADAAN "ON" --- --
        button.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Warna latar belakang ON (Merah Cerah)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(255, 60, 60) -- Warna garis luar ON (Merah Terang)
            btnStroke.Thickness = 1.0 -- Ketebalan garis luar ON (Lebih Tebal)
        end
    else
        -- --- KEADAAN "OFF" --- --
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 55) -- Warna latar belakang OFF (Kelabu Gelap)
        if btnStroke then
            btnStroke.Color = Color3.fromRGB(80, 80, 80) -- Warna garis luar OFF (Kelabu)
            btnStroke.Thickness = 0.5 -- Ketebalan garis luar OFF (Nipis)
        end
    end
end

-- Create Sound Object
local desyncSound = Instance.new("Sound")
desyncSound.Name = "DesyncSound"
desyncSound.SoundId = "rbxassetid://144686873"
desyncSound.Volume = 1 -- Set volume to maximum as requested
desyncSound.Looped = false
desyncSound.Parent = SoundService

-- Toggle Button 1 - Perm Desync
local toggleButton = createToggleButton(mainFrame, "PermDesync", "Perm Desync", UDim2.new(0.5, -80, 0, 20), UDim2.new(0, 160, 0, 32))
local isToggled = false

toggleButton.MouseButton1Click:Connect(function()
    isToggled = not isToggled
    setToggleState(toggleButton, isToggled)
    
    if isToggled then
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
        -- Deactivate ESP
        deactivateESP()
        respawnDesyncEnabled = false
    end
end)

-- Toggle Button 2 - Speed Booster
local toggleButton2 = createToggleButton(mainFrame, "SpeedBooster", "Speed Booster", UDim2.new(0.5, -80, 0, 60), UDim2.new(0, 160, 0, 32))
local isToggled2 = false

toggleButton2.MouseButton1Click:Connect(function()
    isToggled2 = not isToggled2
    setToggleState(toggleButton2, isToggled2)
    
    if isToggled2 then
        toggleSpeed(true)
    else
        toggleSpeed(false)
    end
end)

-- Toggle Button 3 - Inf Jump + Low Gravity (NEW)
local toggleButton3 = createToggleButton(mainFrame, "InfJump", "Inf Jump", UDim2.new(0.5, -80, 0, 100), UDim2.new(0, 160, 0, 32))
local isToggled3 = false

toggleButton3.MouseButton1Click:Connect(function()
    isToggled3 = not isToggled3
    setToggleState(toggleButton3, isToggled3)
    toggleInfJump(isToggled3)
end)

-- ==================== NEW DEVOURER UI DESIGN (IMPROVED) ====================
-- Main Button (Fps Devourer) - SEKARANG BUTANG BIASA
local devourerButton = Instance.new("TextButton")
devourerButton.Name = "FpsDevourer"
devourerButton.Size = UDim2.new(0, 125, 0, 32) -- DIPANJANGKAN
devourerButton.Position = UDim2.new(0, 10, 0, 140) -- DIALIHKAN KE KIRI
devourerButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap)
devourerButton.BorderSizePixel = 0
devourerButton.Text = "Fps Devourer"
devourerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
devourerButton.TextSize = 13
devourerButton.Font = Enum.Font.Arcade
devourerButton.AutoButtonColor = false
devourerButton.Parent = mainFrame

-- Mencipta bucu bulat
local devourerCorner = Instance.new("UICorner")
devourerCorner.CornerRadius = UDim.new(0, 6)
devourerCorner.Parent = devourerButton

-- Mencipta garis luar
local devourerStroke = Instance.new("UIStroke")
devourerStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana)
devourerStroke.Thickness = 0.5
devourerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
devourerStroke.Parent = devourerButton

-- Small TP Button (WARNA TOGGLE OFF)
local tpButton = Instance.new("TextButton") -- Dicipta secara langsung untuk warna khas
tpButton.Name = "TPButton"
tpButton.Size = UDim2.new(0, 30, 0, 32)
tpButton.Position = UDim2.new(0, 140, 0, 140) -- DIUBAH POSISI
tpButton.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Warna latar belakang OFF (Merah Gelap) - SAMA DENGAN TOGGLE OFF
tpButton.BorderSizePixel = 0
tpButton.Text = "TP"
tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tpButton.TextSize = 18
tpButton.Font = Enum.Font.Arcade
tpButton.AutoButtonColor = false
tpButton.Parent = mainFrame

-- Mencipta bucu bulat untuk TP button
local tpCorner = Instance.new("UICorner")
tpCorner.CornerRadius = UDim.new(0, 6)
tpCorner.Parent = tpButton

-- Mencipta garis luar untuk TP button (WARNA TOGGLE OFF)
local tpStroke = Instance.new("UIStroke")
tpStroke.Color = Color3.fromRGB(150, 0, 0) -- Warna garis luar OFF (Merah Sederhana) - SAMA DENGAN TOGGLE OFF
tpStroke.Thickness = 0.5 -- Ketebalan garis luar OFF
tpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tpStroke.Parent = tpButton

-- Fps Devourer Button Function (NORMAL BUTTON)
devourerButton.MouseButton1Click:Connect(function()
    fpsDevourer() -- Panggil fungsi terus
end)

-- TP Button Function
tpButton.MouseButton1Click:Connect(function()
    performQuantumDesync()
end)

-- ==================== TOGGLE BUTTON 6 WITH SWITCH - Fly/Tp to Best (NEW) ====================
local isToggled6 = false
local isFlyBestMode = true -- true = Fly, false = Tp

-- Main button (DIPANJANGKAN DAN DIALIHKAN KE KIRI)
local toggleButton6 = createToggleButton(mainFrame, "FlyTpBest", "Fly to Best", UDim2.new(0, 10, 0, 180), UDim2.new(0, 125, 0, 32)) -- DIPANJANGKAN DARI 115 JADI 125, DIALIHKAN KE KIRI

-- Switch Button (DIKEKALKAN DI KANAN)
local switchButton6 = createSwitchButton(mainFrame, "SwitchButton", "⇄", UDim2.new(0, 140, 0, 180), UDim2.new(0, 30, 0, 32)) -- Posisi disesuaikan sedikit ke kanan

-- Switch button click function (DENGAN LOGIK ANTI-BUG)
switchButton6.MouseButton1Click:Connect(function()
    -- Jika toggle sedang aktif, matikan dulu sebelum tukar mod
    if isToggled6 then
        isToggled6 = false
        setToggleState(toggleButton6, isToggled6)
        stopVelocityFlight() -- Hentikan fungsi yang sedang berjalan
        stopVelocity()
    end

    -- Tukar mod
    isFlyBestMode = not isFlyBestMode
    
    if isFlyBestMode then
        toggleButton6.Text = "Fly to Best"
    else
        toggleButton6.Text = "Tp to Best"
    end
end)

-- Main toggle function
toggleButton6.MouseButton1Click:Connect(function()
    isToggled6 = not isToggled6
    setToggleState(toggleButton6, isToggled6)
    
    if isToggled6 then
        if isFlyBestMode then
            velocityFlightToPet() -- Panggil function anda
        else
            safeTeleportToPet() -- Panggil function anda
        end
    else
        stopVelocityFlight() -- Panggil function berhenti
        stopVelocity()
    end
end)

-- Toggle Button 5 - Steal Floor
local toggleButton5 = createToggleButton(mainFrame, "StealFloor", "Steal Floor", UDim2.new(0.5, -80, 0, 220), UDim2.new(0, 160, 0, 32))
local isToggled5 = false

toggleButton5.MouseButton1Click:Connect(function()
    isToggled5 = not isToggled5
    setToggleState(toggleButton5, isToggled5)
    
    if isToggled5 then
        toggleAllFeatures(true)
    else
        toggleAllFeatures(false)
    end
end)

-- Content area (placeholder) - DISESUAIKAN
local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(1, -40, 0, 30) -- DISESUAIKAN
contentLabel.Position = UDim2.new(0, 20, 0, 260) -- DISESUAIKAN
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
    
    -- Reset new toggle on respawn
    if isToggled6 then
        isToggled6 = false
        setToggleState(toggleButton6, isToggled6)
        stopVelocityFlight()
        stopVelocity()
    end
    
    -- Reset Inf Jump + Low Gravity on respawn
    if isToggled3 then
        isToggled3 = false
        setToggleState(toggleButton3, isToggled3)
        toggleInfJump(false)
    end
    
    -- Reinitialize ESP if needed
    if respawnDesyncEnabled then
        task.wait(1)
        initializeESP()
    end
end)

player.CharacterRemoving:Connect(function()
    if respawnDesyncEnabled then
        deactivateESP()
    end
    if grappleFlyActive then
        toggleGrappleFly(false)
    end
end)

-- ==================== INITIALIZATION ====================
