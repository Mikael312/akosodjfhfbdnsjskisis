--[[
    SIMPLE ARCADE UI 🎮 (UPDATED)
    Rounded rectangle, draggable, arcade style
    WITH NEW DEVOURER UI DESIGN (IMPROVED)
    WITH NEW FLY/TP TO BEST FEATURE (FIXED MODULES & LOGIC)
    WITH IMPROVED INFINITE JUMP + LOW GRAVITY (NEW)
    WITH NEW FLY V2 FEATURE
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

-- ==================== FLY V2 VARIABLES ====================
local autoGrappleConnection = nil
local FLYING = false
local vehicleflyspeed = 2.0
local velocityHandlerName = "VelocityHandler"
local alignHandlerName = "AlignHandler"
local attachmentName = "FlyAttachment"
local v3zero = Vector3.new(0, 0, 0)
local v3inf = Vector3.new(9e9, 9e9, 9e9)
local mfly1 = nil
local mfly2 = nil
local stealCheckConnection = nil
local playerModule = nil
local controlModule = nil

pcall(function()
    playerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
    controlModule = playerModule:GetControls()
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

-- ==================== NEW FLY/TP TO BEST FUNCTIONS ====================
-- Load modules
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

-- Unified function to find the best pet
local function findTheAbsoluteBestPet()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local highest = {value = 0}
    
    -- Try using the module-based system
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
                                        value = gen,
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
                                            value = value,
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

-- Find lowest PlotBlock in plot
local function findLowestPlotBlock(plot)
    local purchases = plot:FindFirstChild("Purchases")
    if not purchases then return nil end
    
    local plotBlock = purchases:FindFirstChild("PlotBlock")
    if not plotBlock then return nil end
    
    local lowestMain = nil
    local lowestY = math.huge
    
    local function scanForMain(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Main" and child:IsA("BasePart") then
                local y = child.Position.Y
                if y < lowestY then
                    lowestY = y
                    lowestMain = child
                end
            end
            scanForMain(child)
        end
    end
    
    scanForMain(plotBlock)
    
    return lowestMain
end

-- Get PlotBlock bounds
local function getPlotBlockBounds(plot)
    local main = findLowestPlotBlock(plot)
    if not main then return nil end
    
    local pos = main.Position
    local size = main.Size
    
    local halfSizeX = size.X * 0.5
    local halfSizeY = size.Y * 0.5
    
    return {
        centerX = pos.X,
        centerY = pos.Y,
        centerZ = pos.Z,
        halfSizeX = halfSizeX,
        halfSizeY = halfSizeY,
        minX = pos.X - halfSizeX,
        maxX = pos.X + halfSizeX,
        minY = pos.Y - halfSizeY,
        maxY = pos.Y + halfSizeY,
    }
end

-- Get PlotBlock edge position
local function getPlotBlockEdgePosition(plot, fromPos, petPos)
    local info = getPlotBlockBounds(plot)
    if not info then return nil end
    
    local MARGIN = 39.4
    
    local dirX = fromPos.X - info.centerX
    
    local targetX
    if dirX > 0 then
        targetX = info.maxX + MARGIN
    else
        targetX = info.minX - MARGIN
    end
    
    local targetZ = info.centerZ
    
    local targetY
    local animalY = petPos.Y
    
    if animalY > 10 then
        targetY = 20
    else
        targetY = animalY + 2
    end
    
    return Vector3.new(targetX, targetY, targetZ)
end

-- Stop velocity
local velocityConnection = nil
local isFlyingToBest = false

local function stopVelocity()
    if velocityConnection then
        velocityConnection:Disconnect()
        velocityConnection = nil
    end
    isFlyingToBest = false
end

-- Velocity flight to PlotBlock edge
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
    
    local bestPet = findTheAbsoluteBestPet()
    
    if not bestPet then
        return false
    end
    
    local currentPos = hrp.Position
    local targetPos = bestPet.position
    local plot = bestPet.plot
    
    local finalPos = getPlotBlockEdgePosition(plot, currentPos, targetPos)
    
    if not finalPos then
        local directionToPet = (targetPos - currentPos).Unit
        local approachPos = targetPos - (directionToPet * 7)
        
        local animalY = targetPos.Y
        if animalY > 10 then
            approachPos = Vector3.new(approachPos.X, 20, approachPos.Z)
        else
            approachPos = Vector3.new(approachPos.X, animalY + 2, approachPos.Z)
        end
        finalPos = approachPos
    end
    
    local grappleEquipped = autoEquipGrapple()
    if not grappleEquipped then
        return false
    end
    
    task.wait(0.1)
    
    fireGrapple()
    
    task.wait(0.05)
    
    isFlyingToBest = true
    
    local baseSpeed = 200
    
    velocityConnection = RunService.Heartbeat:Connect(function()
        if not isFlyingToBest then
            if velocityConnection then velocityConnection:Disconnect() end
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
        
        local distanceToTarget = (finalPos - hrp.Position).Magnitude
        
        if distanceToTarget <= 3 then
            stopVelocity()
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

-- Safe teleport to pet
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
    
    local bestPet = findTheAbsoluteBestPet()
    
    if not bestPet then
        return false
    end
    
    local currentPos = hrp.Position
    local targetPos = bestPet.position
    local plot = bestPet.plot
    
    local state = humanoid:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.05)
    end
    
    local targetUpwardSpeed = 179
    local currentUpwardSpeed = 0
    local smoothness = 0.25
    local elapsed = 0
    local maxDuration = 0.1
    
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
    
    local finalPos = getPlotBlockEdgePosition(plot, currentPos, targetPos)
    
    if not finalPos then
        finalPos = targetPos
        local animalY = targetPos.Y
        if animalY > 10 then
            finalPos = Vector3.new(finalPos.X, 20, finalPos.Z)
        else
            finalPos = Vector3.new(finalPos.X, animalY, finalPos.Z)
        end
    end
    
    hrp.CFrame = CFrame.new(finalPos)
    
    task.wait(0.5)
    
    return true
end

-- ==================== SEMI INVISIBLE FUNCTIONS ====================
local connections = {
    SemiInvisible = {}
}
local isInvisible = false
local clone, oldRoot, hip, animTrack, connection, characterConnection

local function removeFolders()
    local playerName = player.Name
    local playerFolder = Workspace:FindFirstChild(playerName)
    if not playerFolder then return end
    
    local doubleRig = playerFolder:FindFirstChild("DoubleRig")
    if doubleRig then doubleRig:Destroy() end
    
    local constraints = playerFolder:FindFirstChild("Constraints")
    if constraints then constraints:Destroy() end
    
    local childAddedConn = playerFolder.ChildAdded:Connect(function(child)
        if child.Name == "DoubleRig" or child.Name == "Constraints" then
            child:Destroy()
        end
    end)
    table.insert(connections.SemiInvisible, childAddedConn)
end

local function doClone()
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        hip = player.Character.Humanoid.HipHeight
        oldRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not oldRoot or not oldRoot.Parent then return false end
        
        local tempParent = Instance.new("Model")
        tempParent.Parent = game
        player.Character.Parent = tempParent
        
        clone = oldRoot:Clone()
        clone.Parent = player.Character
        oldRoot.Parent = game.Workspace.CurrentCamera
        
        clone.CFrame = oldRoot.CFrame
        player.Character.PrimaryPart = clone
        player.Character.Parent = game.Workspace
        
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("Weld") or v:IsA("Motor6D") then
                if v.Part0 == oldRoot then v.Part0 = clone end
                if v.Part1 == oldRoot then v.Part1 = clone end
            end
        end
        
        tempParent:Destroy()
        return true
    end
    return false
end

local function revertClone()
    if not oldRoot or not oldRoot:IsDescendantOf(game.Workspace) or not player.Character or player.Character.Humanoid.Health <= 0 then return false end
    
    local tempParent = Instance.new("Model")
    tempParent.Parent = game
    player.Character.Parent = tempParent
    
    oldRoot.Parent = player.Character
    player.Character.PrimaryPart = oldRoot
    player.Character.Parent = game.Workspace
    oldRoot.CanCollide = true
    
    for _, v in pairs(player.Character:GetDescendants()) do
        if v:IsA("Weld") or v:IsA("Motor6D") then
            if v.Part0 == clone then v.Part0 = oldRoot end
            if v.Part1 == clone then v.Part1 = oldRoot end
        end
    end
    
    if clone then
        local oldPos = clone.CFrame
        clone:Destroy()
        clone = nil
        oldRoot.CFrame = oldPos
    end
    
    oldRoot = nil
    if player.Character and player.Character.Humanoid then
        player.Character.Humanoid.HipHeight = hip
    end
end

local function animationTrickery()
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        local anim = Instance.new("Animation")
        anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
        local humanoid = player.Character.Humanoid
        local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
        
        animTrack = animator:LoadAnimation(anim)
        animTrack.Priority = Enum.AnimationPriority.Action4
        animTrack:Play(0, 1, 0)
        anim:Destroy()
        
        local animStoppedConn = animTrack.Stopped:Connect(function()
            if isInvisible then
                animationTrickery()
            end
        end)
        table.insert(connections.SemiInvisible, animStoppedConn)
        
        task.delay(0, function()
            animTrack.TimePosition = 0.7
            task.delay(1, function()
                animTrack:AdjustSpeed(math.huge)
            end)
        end)
    end
end

local function setupGodmode()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    local oldNI = mt.__newindex
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if self == hum then
            if m == "ChangeState" and select(1, ...) == Enum.HumanoidStateType.Dead then return end
            if m == "SetStateEnabled" then
                local st, en = ...
                if st == Enum.HumanoidStateType.Dead and en == true then return end
            end
            if m == "Destroy" then return end
        end
        if self == char and m == "BreakJoints" then return end
        return oldNC(self, ...)
    end)
    
    mt.__newindex = newcclosure(function(self, k, v)
        if self == hum then
            if k == "Health" and type(v) == "number" and v <= 0 then return end
            if k == "MaxHealth" and type(v) == "number" and v < hum.MaxHealth then return end
            if k == "BreakJointsOnDeath" and v == true then return end
            if k == "Parent" and v == nil then return end
        end
        return oldNI(self, k, v)
    end)
    
    setreadonly(mt, true)
end

local function enableInvisibility()
    if not player.Character or player.Character.Humanoid.Health <= 0 then return false end
    
    removeFolders()
    
    local success = doClone()
    if success then
        task.wait(0.1)
        animationTrickery()
        
        connection = RunService.PreSimulation:Connect(function(dt)
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and oldRoot then
                local root = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local cf = root.CFrame - Vector3.new(0, player.Character.Humanoid.HipHeight + (root.Size.Y / 2) - 1 + 0.3, 0)
                    oldRoot.CFrame = cf * CFrame.Angles(math.rad(210), 0, 0)
                    oldRoot.Velocity = root.Velocity
                    oldRoot.CanCollide = false
                end
            end
        end)
        table.insert(connections.SemiInvisible, connection)
        
        characterConnection = player.CharacterAdded:Connect(function(newChar)
            if isInvisible then
                if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
                if connection then connection:Disconnect() end
                revertClone()
                removeFolders()
                isInvisible = false
                for _, conn in ipairs(connections.SemiInvisible) do if conn then conn:Disconnect() end end
                connections.SemiInvisible = {}
            end
        end)
        table.insert(connections.SemiInvisible, characterConnection)
        
        return true
    end
    return false
end

local function disableInvisibility()
    if animTrack then 
        animTrack:Stop()
        animTrack:Destroy()
        animTrack = nil
    end
    
    if connection then connection:Disconnect() end
    if characterConnection then characterConnection:Disconnect() end
    
    revertClone()
    removeFolders()
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

-- ==================== FLY V2 FUNCTIONS ====================
-- Tambah pembolehubah untuk mengesan status auto grapple
local autoGrappleActive = false

-- Fungsi autoEquipGrapple khusus untuk Fly V2
local function autoEquipGrappleV2()
    local success, result = pcall(function()
        local character = player.Character
        if not character then return false end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health > 0) then return false end
        
        local backpack = player:WaitForChild("Backpack")
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

-- Fungsi fireGrapple khusus untuk Fly V2
local function fireGrappleV2()
    pcall(function()
        local args = {1.9832406361897787}
        UseItemRemote:FireServer(unpack(args))
    end)
end

-- Start Auto Grapple khusus untuk Fly V2
local function startAutoGrapple()
    if autoGrappleConnection then return end
    
    autoGrappleActive = true
    autoGrappleConnection = RunService.Heartbeat:Connect(function()
        -- Hanya jalankan jika Fly V2 masih aktif
        if not FLYING or not autoGrappleActive then
            return
        end
        
        autoEquipGrappleV2()
        task.wait(0.1) -- Tambah sedikit kelewatan
        fireGrappleV2()
    end)
end

-- Stop Auto Grapple
local function stopAutoGrapple()
    autoGrappleActive = false -- Tandakan sebagai tidak aktif
    if autoGrappleConnection then
        autoGrappleConnection:Disconnect()
        autoGrappleConnection = nil
    end
end

-- ========================================
-- VEHICLE FLY FUNCTIONS
-- ========================================
local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function NOFLY()
    if mfly1 then
        mfly1:Disconnect()
        mfly1 = nil
    end
    if mfly2 then
        mfly2:Disconnect()
        mfly2 = nil
    end
    if stealCheckConnection then
        stealCheckConnection:Disconnect()
        stealCheckConnection = nil
    end
    
    local root = getRoot(player.Character)
    if root then
        if root:FindFirstChild(velocityHandlerName) then
            root:FindFirstChild(velocityHandlerName):Destroy()
        end
        if root:FindFirstChild(alignHandlerName) then
            root:FindFirstChild(alignHandlerName):Destroy()
        end
        if root:FindFirstChild(attachmentName) then
            root:FindFirstChild(attachmentName):Destroy()
        end
    end
    
    FLYING = false
    stopAutoGrapple() -- Pastikan ini dipanggil
end

local function startVehicleFly()
    FLYING = true
    local root = getRoot(player.Character)
    local camera = workspace.CurrentCamera
    
    if not root then
        return
    end
    
    mfly1 = player.CharacterAdded:Connect(function()
        local root = getRoot(player.Character)
        
        -- Create Attachment
        local att = Instance.new("Attachment")
        att.Name = attachmentName
        att.Parent = root
        
        -- Create LinearVelocity (ganti BodyVelocity)
        local lv = Instance.new("LinearVelocity")
        lv.Name = velocityHandlerName
        lv.Parent = root
        lv.Attachment0 = att
        lv.MaxForce = 9e9
        lv.VectorVelocity = v3zero
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        
        -- Create AlignOrientation (ganti BodyGyro)
        local ao = Instance.new("AlignOrientation")
        ao.Name = alignHandlerName
        ao.Parent = root
        ao.Attachment0 = att
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.MaxTorque = 9e9
        ao.Responsiveness = 200
        ao.RigidityEnabled = true
    end)
    
    -- Initial setup
    local att = Instance.new("Attachment")
    att.Name = attachmentName
    att.Parent = root
    
    local lv = Instance.new("LinearVelocity")
    lv.Name = velocityHandlerName
    lv.Parent = root
    lv.Attachment0 = att
    lv.MaxForce = 9e9
    lv.VectorVelocity = v3zero
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    
    local ao = Instance.new("AlignOrientation")
    ao.Name = alignHandlerName
    ao.Parent = root
    ao.Attachment0 = att
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.MaxTorque = 9e9
    ao.Responsiveness = 200
    ao.RigidityEnabled = true
    
    mfly2 = RunService.RenderStepped:Connect(function()
        root = getRoot(player.Character)
        camera = workspace.CurrentCamera
        
        if player.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(alignHandlerName) then
            local VelocityHandler = root:FindFirstChild(velocityHandlerName)
            local AlignHandler = root:FindFirstChild(alignHandlerName)
            
            -- Update orientation untuk match camera
            AlignHandler.CFrame = camera.CFrame
            
            -- Reset velocity
            local velocity = Vector3.new(0, 0, 0)
            
            -- Get movement direction
            local direction = controlModule:GetMoveVector()
            
            -- Calculate velocity based on camera direction
            if direction.X ~= 0 then
                velocity = velocity + camera.CFrame.RightVector * (direction.X * vehicleflyspeed * 50)
            end
            if direction.Z ~= 0 then
                velocity = velocity - camera.CFrame.LookVector * (direction.Z * vehicleflyspeed * 50)
            end
            
            -- Q/E untuk naik/turun
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                velocity = velocity + Vector3.new(0, vehicleflyspeed * 50, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                velocity = velocity - Vector3.new(0, vehicleflyspeed * 50, 0)
            end
            
            -- Apply velocity
            VelocityHandler.VectorVelocity = velocity
        end
    end)
    
    -- Auto start grapple
    startAutoGrapple()
    
    -- Check stealing attribute
    stealCheckConnection = RunService.Heartbeat:Connect(function()
        local isStealingNow = player:GetAttribute("Stealing")
        
        if isStealingNow == true then
            NOFLY()
        end
    end)
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
mainFrame.Size = UDim2.new(0, 180, 0, 280) -- DIKURANGKAN KERANA SATU BARIS DIBUANG
mainFrame.Position = UDim2.new(1, -290, 0.5, -140) -- KEDUDUKAN BAHARU UNTUK TENGAH
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

-- <<<< TAMBAHAN ANIMASI GRADIEN
-- UIGradient untuk outline (merah cerah ke merah gelap)
local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),   -- Merah cerah
    ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 0))      -- Merah gelap
}
uiGradient.Parent = mainStroke

-- Tween untuk rotate gradient
local gradientTweenInfo = TweenInfo.new(
    2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut,
    -1,
    false,
    0
)

TweenService:Create(uiGradient, gradientTweenInfo, {Rotation = 360}):Play()
-- >>>> TAMBAHAN ANIMASI GRADIEN TAMAT

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

-- Create TP Sound Object (BAHARU)
local tpSound = Instance.new("Sound")
tpSound.Name = "TPSound"
tpSound.SoundId = "rbxassetid://1412830636"
tpSound.Volume = 1
tpSound.Looped = false
tpSound.Parent = SoundService

-- Toggle Button 1 - Semi Invisible (DIUBAH DARI Perm Desync)
local toggleButton = createToggleButton(mainFrame, "SemiInvisible", "Semi Invisible", UDim2.new(0.5, -80, 0, 20), UDim2.new(0, 160, 0, 32))
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
            Title = "Semi Invisible";
            Text = "Invisibility Activated";
            Duration = 5;
        })
        
        -- Start invisibility
        if enableInvisibility() then
            isInvisible = true
        end
    else
        -- Disable invisibility
        disableInvisibility()
        isInvisible = false
    end
end)

-- Toggle Button 2 - Speed (DIUBAH)
local toggleButton2 = createToggleButton(mainFrame, "SpeedBooster", "Speed", UDim2.new(0, 10, 0, 60), UDim2.new(0, 75, 0, 32))
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

-- Toggle Button 3 - Inf Jump + Low Gravity (NEW) (DIUBAH)
local toggleButton3 = createToggleButton(mainFrame, "InfJump", "Inf Jump", UDim2.new(0, 95, 0, 60), UDim2.new(0, 75, 0, 32))
local isToggled3 = false

toggleButton3.MouseButton1Click:Connect(function()
    isToggled3 = not isToggled3
    setToggleState(toggleButton3, isToggled3)
    toggleInfJump(isToggled3)
end)

-- ==================== NEW DEVOURER UI DESIGN (IMPROVED) ====================
-- Main Button (Fps Devourer) - SEKARANG BUTANG BIASA (DIUBAH KEDUDUKAN)
local devourerButton = Instance.new("TextButton")
devourerButton.Name = "FpsDevourer"
devourerButton.Size = UDim2.new(0, 125, 0, 32) -- DIPANJANGKAN
devourerButton.Position = UDim2.new(0, 10, 0, 100) -- DIALIHKAN KE BAWAH
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
tpButton.Position = UDim2.new(0, 140, 0, 100) -- DIUBAH POSISI
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

-- Main button (DIUBAH KEDUDUKAN)
local toggleButton6 = createToggleButton(mainFrame, "FlyTpBest", "Fly to Best", UDim2.new(0, 10, 0, 140), UDim2.new(0, 125, 0, 32))

-- Switch Button (DIUBAH KEDUDUKAN)
local switchButton6 = createSwitchButton(mainFrame, "SwitchButton", "⇄", UDim2.new(0, 140, 0, 140), UDim2.new(0, 30, 0, 32))

-- Switch button click function (DENGAN LOGIK ANTI-BUG)
switchButton6.MouseButton1Click:Connect(function()
    -- Jika toggle sedang aktif, matikan dulu sebelum tukar mod
    if isToggled6 then
        isToggled6 = false
        setToggleState(toggleButton6, isToggled6)
        stopVelocity() -- Hentikan fungsi yang sedang berjalan
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
            -- Mainkan bunyi TP sebelum teleport
            if tpSound.IsPlaying then
                tpSound:Stop()
            end
            tpSound:Play()
            
            safeTeleportToPet() -- Panggil function anda
        end
    else
        stopVelocity() -- Panggil function berhenti
    end
end)

-- ==================== NEW FLY V2 TOGGLE BUTTON ====================
-- Toggle Button 7 - Fly V2 (DIUBAH KEDUDUKAN)
local toggleButton7 = createToggleButton(mainFrame, "FlyV2", "Fly V2", UDim2.new(0.5, -80, 0, 180), UDim2.new(0, 160, 0, 32))
local isToggled7 = false

toggleButton7.MouseButton1Click:Connect(function()
    isToggled7 = not isToggled7
    setToggleState(toggleButton7, isToggled7)
    
    if isToggled7 then
        startVehicleFly()
    else
        NOFLY()
    end
end)

-- Toggle Button 5 - Steal Floor (DIUBAH KEDUDUKAN)
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

-- Content area (placeholder) - DIUBAH KEDUDUKAN
local contentLabel = Instance.new("TextLabel")
contentLabel.Size = UDim2.new(1, -40, 0, 30)
contentLabel.Position = UDim2.new(0, 20, 0, 250) -- DISESUAIKAN
contentLabel.BackgroundTransparency = 1
contentLabel.Text = ""
contentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
contentLabel.TextSize = 14
contentLabel.Font = Enum.Font.Gotham
contentLabel.TextWrapped = true
contentLabel.TextYAlignment = Enum.TextYAlignment.Top
contentLabel.Parent = mainFrame

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
        stopVelocity()
    end
    
    -- Reset Fly V2 on respawn
    if isToggled7 then
        isToggled7 = false
        setToggleState(toggleButton7, isToggled7)
        NOFLY()
    end
    
    -- Reset Inf Jump + Low Gravity on respawn
    if isToggled3 then
        isToggled3 = false
        setToggleState(toggleButton3, isToggled3)
        toggleInfJump(false)
    end
    
    -- Reset Semi Invisible on respawn
    if isToggled then
        isToggled = false
        setToggleState(toggleButton, isToggled)
        disableInvisibility()
        isInvisible = false
        for _, conn in ipairs(connections.SemiInvisible) do if conn then conn:Disconnect() end end
        connections.SemiInvisible = {}
    end
end)

player.CharacterRemoving:Connect(function()
    -- ESP section removed
end)

-- Initialize Semi Invisible system
player.CharacterAdded:Wait()
task.wait(0.5)

removeFolders()
setupGodmode()

-- Cleanup on respawn
LocalPlayer.CharacterAdded:Connect(function()
    if isInvisible then
        disableInvisibility()
    end
    
    for _, conn in ipairs(connections.SemiInvisible) do 
        if conn then conn:Disconnect() end 
    end
    connections.SemiInvisible = {}
    
    local newChar = player.Character or player.CharacterAdded:Wait()
    newChar:WaitForChild("Humanoid")
    newChar:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    
    removeFolders()
    setupGodmode()
end)

-- ==================== INITIALIZATION ====================
