-- ==================== LOAD LIBRARY ====================
local success, Nightmare = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/Nightmare-Ui/refs/heads/main/Nightmare.lua"))()
end)

if not success then
    warn("❌ Failed to load Nightmare library!")
    return
end

-- ==================== SETUP SERVICES ====================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ==================== ESP VARIABLES ====================
local highestValueESP = nil
local highestValueData = nil
local espEnabled = false
local autoUpdateThread = nil
local tracerAttachment0 = nil
local tracerAttachment1 = nil
local tracerBeam = nil
local tracerConnection = nil

-- ==================== MODULE DATA ====================
local AnimalsModule, TraitsModule, MutationsModule

pcall(function()
    AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    TraitsModule = require(ReplicatedStorage.Datas.Traits)
    MutationsModule = require(ReplicatedStorage.Datas.Mutations)
end)

-- ==================== ESP FUNCTIONS ====================
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
    
    if value == math.floor(value) then
        return string.format("%.0f%s", value, suffix)
    else
        return string.format("%.1f%s", value, suffix)
    end
end

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

local function findHighestBrainrot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    
    local highest = {value = 0}
    
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("Model") and AnimalsModule and AnimalsModule[obj.Name] then
                    pcall(function()
                        local gen = getFinalGeneration(obj)
                        
                        if gen > 0 then
                            if gen > highest.value then
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
    
    return highest.value > 0 and highest or nil
end

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
        
        -- Generation Label (CENTERED)
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
    end)
    
    return true
end

local function removeTracerLine()
    if tracerConnection then tracerConnection:Disconnect() tracerConnection = nil end
    if tracerBeam then tracerBeam:Destroy() tracerBeam = nil end
    if tracerAttachment0 then tracerAttachment0:Destroy() tracerAttachment0 = nil end
    if tracerAttachment1 then tracerAttachment1:Destroy() tracerAttachment1 = nil end
end

local function updateHighestValueESP()
    if highestValueData and not checkPetExists() then
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

-- ==================== ESP TOGGLE FUNCTION ====================
local function toggleESP(state)
    espEnabled = state
    
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
        
        print("✅ ESP Best: ON")
        Nightmare:Notify("ESP Best: ON")
    else
        removeHighestValueESP()
        
        if autoUpdateThread then
            task.cancel(autoUpdateThread)
            autoUpdateThread = nil
        end
        
        print("❌ ESP Best: OFF")
        Nightmare:Notify("ESP Best: OFF")
    end
end

-- ==================== CREATE UI AND ADD TOGGLES ====================
Nightmare:CreateUI()

-- Notifikasi apabila UI dimuatkan
Nightmare:Notify("Brainrot ESP with Nightmare UI Loaded!")

-- Tambah toggle untuk ESP Best
Nightmare:AddToggleRow("Esp Best", function(state)
    toggleESP(state)
end)

print("🎮 Brainrot ESP with Nightmare UI Loaded Successfully!")
