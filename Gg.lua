--[[
    NIGHTMARE UI - INTEGRASI ESP PLAYERS, ESP BEST, BASE LINE, ANTI TURRET, AIMBOT, KICK STEAL, UNWALK ANIM, ANTI DEBUFF, ANTI RDOLL, XRAY BASE, FPS BOOST & ESP TIMER
]]

-- ==================== LOAD LIBRARY ====================
local success, Nightmare = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/Nightmare-Ui/refs/heads/main/Nightmare.lua"))()
end)

if not success then
    warn("❌ Failed to load Nightmare library!")
    return
end

-- ==================== SERVICES & VARIABLES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- ==================== ESP PLAYERS VARIABLES ====================
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil

-- ==================== ESP BEST VARIABLES ====================
local highestValueESP = nil
local highestValueData = nil
local espBestEnabled = false
local autoUpdateThread = nil
local tracerAttachment0 = nil
local tracerAttachment1 = nil
local tracerBeam = nil
local tracerConnection = nil
local lastNotifiedPet = nil -- Untuk mengelakkan notifikasi berulang

-- ==================== BASE LINE VARIABLES ====================
local baseLineEnabled = false
local baseLineConnection = nil
local baseBeamPart = nil
local baseTargetPart = nil
local baseBeam = nil

-- ==================== ANTI TURRET VARIABLES ====================
local sentryEnabled = false
local sentryConn = nil
local scanConn = nil
local activeSentries = {}
local processedSentries = {}
local followConnections = {}
local myUserId = tostring(player.UserId)

-- ==================== AIMBOT VARIABLES ====================
local autoLaserEnabled = false
local autoLaserThread = nil
local blacklistNames = {"alex4eva", "jkxkelu", "BigTulaH", "xxxdedmoth", "JokiTablet", "sleepkola", "Aimbot36022", "Djrjdjdk0", "elsodidudujd", "SENSEIIIlSALT", "yaniecky", "ISAAC_EVO", "7xc_ls", "itz_d1egx"}
local blacklist = {}
for _, name in ipairs(blacklistNames) do
    blacklist[string.lower(name)] = true
end

-- ==================== KICK STEAL VARIABLES ====================
local isMonitoring = false
local lastStealCount = 0
local monitoringLoop = nil

-- ==================== UNWALK ANIM VARIABLES ====================
local unwalkAnimEnabled = false
local unwalkAnimConnections = {}

-- ==================== ANTI DEBUFF VARIABLES ====================
local antiBeeEnabled = false
local antiBoogieEnabled = false
local isEventHandlerActive = false
local unifiedConnection = nil
local originalConnections = {}
local heartbeatConnection = nil
local animationPlayedConnection = nil
local BOOGIE_ANIMATION_ID = "109061983885712"

-- ==================== ANTI RAGDOLL VARIABLES (NEW - FIXED) ====================
-- Master switch for the entire anti-ragdoll system
local antiRagdollEnabled = false

-- Method 1 Variables (State-based)
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false -- Local flag to track if Method 1 is currently active

-- Method 2 Variables (Constraint-based)
local ragdollConnections = {}
local cachedCharData = {}
local constraintLoopActive = false

-- ==================== XRAY BASE VARIABLES ====================
local xrayBaseEnabled = false
local invisibleWallsLoaded = false
local originalTransparency = {}
local xrayBaseConnection = nil

-- ==================== FPS BOOST VARIABLES ====================
local fpsBoostEnabled = false
local optimizerThreads = {}
local optimizerConnections = {}
local originalSettings = {}

-- ==================== ESP TIMER VARIABLES ====================
local timerEspEnabled = false
local timerEspConnections = {}

-- ==================== NEAREST VARIABLES ====================
local nearestEnabled = false
local nearestUI = nil
local nearestStealConnection = nil

-- ==================== MODULES FOR ESP BEST ====================
local AnimalsModule, TraitsModule, MutationsModule

pcall(function()
    AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    TraitsModule = require(ReplicatedStorage.Datas.Traits)
    MutationsModule = require(ReplicatedStorage.Datas.Mutations)
end)

-- ==================== ESP PLAYERS FUNCTIONS (FIXED) ====================
-- Fungsi untuk mendapatkan nama item yang dipegang oleh pemain
local function getEquippedItem(character)
    -- Semak jika ada tool di tangan
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    
    -- Semak humanoid untuk tool yang dipegang
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

-- Fungsi untuk mencipta ESP untuk seorang pemain
local function createESP(targetPlayer)
    -- Jangan buat ESP untuk diri sendiri
    if targetPlayer == player then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Cipta Highlight (outline cyan)
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Warna isi cyan
    highlight.OutlineColor = Color3.fromRGB(0, 200, 255) -- Warna garis cyan
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Sentiasa kelihatan melalui objek lain
    highlight.Parent = character
    
    -- Cipta BillboardGui untuk paparkan nama + item
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPInfo"
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 200, 0, 40) -- Saiz dipendekkan kerana tiada jarak
    billboard.StudsOffset = Vector3.new(0, 3, 0) -- Kedudukan di atas kepala
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    
    -- Label untuk nama pemain
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    
    -- Label untuk item
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(1, 0, 0, 18)
    itemLabel.Position = UDim2.new(0, 0, 0, 22)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item: None"
    itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Warna kuning asal
    itemLabel.TextStrokeTransparency = 0.5
    itemLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextSize = 12
    itemLabel.Parent = billboard
    
    -- Simpan semua objek ESP dalam jadual
    espObjects[targetPlayer] = {
        highlight = highlight,
        billboard = billboard,
        itemLabel = itemLabel,
        character = character
    }
end

-- Fungsi untuk membuang ESP untuk seorang pemain
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

-- Fungsi untuk mengemas kini ESP (hanya item, tiada jarak)
local function updateESP()
    if not espPlayersEnabled then return end
    
    for targetPlayer, espData in pairs(espObjects) do
        -- Semak jika pemain dan watak masih wujud
        if targetPlayer and targetPlayer.Parent and espData.character and espData.character.Parent then
            local character = espData.character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                -- Kemas kini item yang dipegang
                local equippedItem = getEquippedItem(character)
                espData.itemLabel.Text = "Item: " .. equippedItem
                
                -- Tukar warna berdasarkan item
                if equippedItem ~= "None" then
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Warna merah jika ada item
                else
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Warna kuning jika tiada item
                end
            else
                -- Jika tiada rootPart, buang ESP
                removeESP(targetPlayer)
            end
        else
            -- Jika pemain telah keluar, buang ESP
            removeESP(targetPlayer)
        end
    end
end

-- Fungsi untuk menghidupkan ESP
local function enableESPPlayers()
    if espPlayersEnabled then return end
    espPlayersEnabled = true
    
    -- Cipta ESP untuk semua pemain yang sedia ada
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            createESP(targetPlayer)
        end
    end
    
    -- Mulakan gelung kemas kini (update loop)
    updateConnection = RunService.RenderStepped:Connect(updateESP)
end

-- Fungsi untuk mematikan ESP
local function disableESPPlayers()
    if not espPlayersEnabled then return end
    espPlayersEnabled = false
    
    -- Buang semua ESP
    for targetPlayer, _ in pairs(espObjects) do
        removeESP(targetPlayer)
    end
    
    -- Hentikan gelung kemas kini
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- ==================== ESP BEST FUNCTIONS ====================
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
    local totalPlotsScanned = 0
    local totalAnimalsFound = 0
    
    for _, plot in pairs(plots:GetChildren()) do
        if not isPlayerPlot(plot) then
            totalPlotsScanned = totalPlotsScanned + 1
            
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("Model") and AnimalsModule and AnimalsModule[obj.Name] then
                    pcall(function()
                        local gen = getFinalGeneration(obj)
                        
                        if gen > 0 then
                            totalAnimalsFound = totalAnimalsFound + 1
                            
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
        
        -- REMOVED: BOX HIGHLIGHT as requested
        
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
        
        -- TAMBAH: Notifikasi untuk ESP Best
        if espBestEnabled then
            local petName = brainrotData.petName or "Unknown"
            local genValue = brainrotData.formattedValue or formatNumber(brainrotData.generation or 0)
            
            -- Hanya beri notifikasi jika ini adalah haiwan yang berbeza dari yang terakhir diberitahu
            if not lastNotifiedPet or lastNotifiedPet ~= petName .. genValue then
                lastNotifiedPet = petName .. genValue
                Nightmare:Notify(petName .. " " .. genValue)
            end
        end
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
            if tracerBeam and tracerBeam.Parent and espBestEnabled then
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

-- TAMBAH: Fungsi baru untuk menyegarkan tracer
local function refreshTracerLine()
    if not espBestEnabled or not highestValueData then
        removeTracerLine()
        return
    end
    
    -- Buang tracer lama
    removeTracerLine()
    
    -- Cipta tracer baru
    createTracerLine()
end

local function updateHighestValueESP()
    if highestValueData and not checkPetExists() then
        if highestValueESP then
            if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
            if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
            if highestValueESP.podiumHighlight then highestValueESP.podiumHighlight:Destroy() end
        end
        highestValueESP = nil
        highestValueData = nil
        removeTracerLine()
        lastNotifiedPet = nil -- Reset notifikasi apabila haiwan hilang
    end
    
    local newHighest = findHighestBrainrot()
    
    if newHighest then
        if not highestValueData or newHighest.value > highestValueData.value then
            createHighestValueESP(newHighest)
            
            if espBestEnabled then
                -- UBAH: Ganti dengan fungsi refreshTracerLine()
                refreshTracerLine()
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
            if highestValueESP.podiumHighlight then highestValueESP.podiumHighlight:Destroy() end
        end)
        highestValueESP = nil
        highestValueData = nil
    end
    
    removeTracerLine()
    lastNotifiedPet = nil -- Reset notifikasi apabila ESP dimatikan
end

local function enableESPBest()
    if espBestEnabled then return end
    espBestEnabled = true
    
    updateHighestValueESP()
    
    if autoUpdateThread then
        task.cancel(autoUpdateThread)
    end
    
    -- UBAH: Tambah thread untuk semakan berkala
    local lastTracerRefresh = 0
    autoUpdateThread = task.spawn(function()
        while espBestEnabled do
            task.wait(1)
            updateHighestValueESP()
            
            -- TAMBAH: Semak dan kemas kini tracer setiap 2 saat
            if tick() - lastTracerRefresh >= 2 then
                refreshTracerLine()
                lastTracerRefresh = tick()
            end
        end
    end)
end

local function disableESPBest()
    if not espBestEnabled then return end
    espBestEnabled = false
    
    removeHighestValueESP()
    
    if autoUpdateThread then
        task.cancel(autoUpdateThread)
        autoUpdateThread = nil
    end
end

-- ==================== BASE LINE FUNCTIONS (UPDATED) ====================
-- REPLACED: The old findPlayerPlot function with the new FindDelivery function
local function FindDelivery()
    local plots = workspace:WaitForChild("Plots", 5) -- Added timeout
    if not plots then
        warn("Plots folder not found in workspace")
        return nil
    end
    
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
    warn("No valid DeliveryHitbox found")
    return nil
end

local function createPlotLine()
    local Character = player.Character
    if not Character then return false end
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end

    -- UPDATED: Now using FindDelivery to get the target
    local deliveryHitbox = FindDelivery()
    if not deliveryHitbox then
        warn("❌ Cannot find your delivery hitbox!")
        return false
    end

    local targetPosition = deliveryHitbox.Position

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

-- ==================== ANTI TURRET FUNCTIONS ====================
local function isSentryPlaced(desc)
    if not desc or not desc.Parent then return false end
    
    local inWorkspace = desc:IsDescendantOf(Workspace)
    if not inWorkspace then return false end
    
    for _, playerObj in pairs(Players:GetPlayers()) do
        if playerObj.Character and desc:IsDescendantOf(playerObj.Character) then
            return false
        end
        
        if playerObj.Backpack and desc:IsDescendantOf(playerObj.Backpack) then
            return false
        end
    end
    
    local isAnchored = false
    pcall(function()
        if desc:IsA("Model") and desc.PrimaryPart then
            isAnchored = desc.PrimaryPart.Anchored
        elseif desc:IsA("BasePart") then
            isAnchored = desc.Anchored
        end
    end)
    
    return isAnchored
end

local function isMySentry(sentryName)
    return string.find(sentryName, myUserId) ~= nil
end

local function isOwnedByPlayer(desc)
    if isMySentry(desc.Name) then
        return true
    end
    return false
end

local function findBat()
    local tool = nil
    pcall(function()
        tool = player.Backpack:FindFirstChild("Bat")
        if not tool and player.Character then
            tool = player.Character:FindFirstChild("Bat")
        end
    end)
    return tool
end

local function equipBat()
    local bat = findBat()
    if bat and bat.Parent == player.Backpack then
        pcall(function()
            player.Character.Humanoid:EquipTool(bat)
        end)
        return true
    end
    return bat and bat.Parent == player.Character
end

local function unequipBat()
    local bat = findBat()
    if bat and bat.Parent == player.Character then
        pcall(function()
            player.Character.Humanoid:UnequipTools()
        end)
    end
end

local function sentryExists(desc)
    if not desc then return false end
    if not desc.Parent then return false end
    
    local stillExists = false
    pcall(function()
        stillExists = desc.Parent ~= nil and desc:IsDescendantOf(Workspace)
    end)
    
    return stillExists
end

local function updateSentryPosition(desc)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local lookDir = hrp.CFrame.LookVector
    local spawnOffset = lookDir * 3.5 + Vector3.new(0, 1.2, 0)
    
    local success = pcall(function()
        if desc:IsA("Model") and desc.PrimaryPart then
            desc:SetPrimaryPartCFrame(hrp.CFrame + spawnOffset)
            
            -- Set CanCollide false for all parts
            for _, part in pairs(desc:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        elseif desc:IsA("BasePart") then
            desc.CFrame = hrp.CFrame + spawnOffset
            desc.CanCollide = false
        end
    end)
    
    return success
end

local function destroySentry(desc)
    if not sentryEnabled then return end
    if activeSentries[desc] then return end
    if processedSentries[desc] then return end
    
    if isOwnedByPlayer(desc) then
        processedSentries[desc] = true
        return
    end
    
    if not isSentryPlaced(desc) then
        return
    end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    activeSentries[desc] = true
    processedSentries[desc] = true

    local bat = findBat()
    if not bat then
        warn("[⚠️] Bat not found!")
        activeSentries[desc] = nil
        return
    end

    local hitCount = 0
    local running = true
    
    -- Monitor sentry destruction
    local destroyConnection
    destroyConnection = desc.AncestryChanged:Connect(function()
        if not sentryExists(desc) then
            running = false
            if destroyConnection then
                destroyConnection:Disconnect()
            end
        end
    end)
    
    -- Thread 1: FOLLOW PLAYER (Update position continuously with RenderStepped)
    local followConnection
    followConnection = RunService.RenderStepped:Connect(function()
        if not running or not sentryEnabled or not sentryExists(desc) then
            if followConnection then
                followConnection:Disconnect()
                followConnections[desc] = nil
            end
            return
        end
        
        -- Update sentry position to follow player (smoother with RenderStepped)
        updateSentryPosition(desc)
    end)
    
    followConnections[desc] = followConnection
    
    -- Thread 2: Spam Equip/Unequip
    task.spawn(function()
        while running and sentryEnabled and sentryExists(desc) do
            equipBat()
            task.wait(0.05)
            if not running or not sentryExists(desc) then break end
            unequipBat()
            task.wait(0.05)
        end
    end)
    
    -- Thread 3: Continuous spam attack
    task.spawn(function()
        task.wait(0.1)
        
        local spamConnection
        spamConnection = RunService.Heartbeat:Connect(function()
            if not sentryEnabled or not sentryExists(desc) then
                running = false
                
                if spamConnection then
                    spamConnection:Disconnect()
                end
                if destroyConnection then
                    destroyConnection:Disconnect()
                end
                if followConnections[desc] then
                    followConnections[desc]:Disconnect()
                    followConnections[desc] = nil
                end
                
                unequipBat()
                activeSentries[desc] = nil
                
                if not sentryExists(desc) then
                else
                end
                return
            end
            
            local currentBat = findBat()
            if currentBat and currentBat.Parent == player.Character then
                for i = 1, 12 do
                    if currentBat.Parent == player.Character and sentryExists(desc) then
                        currentBat:Activate()
                        hitCount = hitCount + 1
                    else
                        break
                    end
                end
            end
        end)
    end)
end

local function scanExistingSentries()
    if not sentryEnabled then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local foundCount = 0
    
    pcall(function()
        for _, desc in pairs(Workspace:GetDescendants()) do
            if sentryEnabled and (desc:IsA("Model") or desc:IsA("BasePart")) then
                if string.find(desc.Name:lower(), "sentry") then
                    if isSentryPlaced(desc) and not processedSentries[desc] and not isOwnedByPlayer(desc) then
                        foundCount = foundCount + 1
                        updateSentryPosition(desc)
                        destroySentry(desc)
                        task.wait(0.1)
                    end
                end
            end
        end
    end)
end

local function startSentryWatch()
    if sentryConn then sentryConn:Disconnect() end
    if scanConn then scanConn:Disconnect() end
    
    sentryConn = Workspace.DescendantAdded:Connect(function(desc)
        if not sentryEnabled then return end
        if not desc:IsA("Model") and not desc:IsA("BasePart") then return end
        if not string.find(desc.Name:lower(), "sentry") then return end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        if isOwnedByPlayer(desc) then
            processedSentries[desc] = true
            return
        end
        
        task.wait(0.5)
        
        if not isSentryPlaced(desc) then
            task.spawn(function()
                local waitTime = 0
                while waitTime < 10 and not isSentryPlaced(desc) and sentryExists(desc) and sentryEnabled do
                    task.wait(0.5)
                    waitTime = waitTime + 0.5
                end
                
                if isSentryPlaced(desc) and sentryExists(desc) and sentryEnabled then
                    updateSentryPosition(desc)
                    destroySentry(desc)
                end
            end)
            
            return
        end
        
        task.wait(4.1)
        
        if not sentryExists(desc) or not sentryEnabled then return end
        
        updateSentryPosition(desc)
        destroySentry(desc)
    end)
    
    scanConn = task.spawn(function()
        while sentryEnabled do
            scanExistingSentries()
            task.wait(5)
        end
    end)
end

local function stopSentryWatch()
    sentryEnabled = false
    
    if sentryConn then
        sentryConn:Disconnect()
        sentryConn = nil
    end
    
    if scanConn then
        task.cancel(scanConn)
        scanConn = nil
    end
    
    -- Disconnect all follow connections
    for _, conn in pairs(followConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    followConnections = {}
    
    activeSentries = {}
    processedSentries = {}
end

local function enableAntiTurret()
    if sentryEnabled then return end
    sentryEnabled = true
    startSentryWatch()
end

local function disableAntiTurret()
    if not sentryEnabled then return end
    sentryEnabled = false
    stopSentryWatch()
end

-- ==================== AIMBOT FUNCTIONS ====================
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

local function isValidTarget(p)
    if not p or not p.Character or p == player then return false end
    
    local name = p.Name and string.lower(p.Name) or ""
    if blacklist[name] then return false end
    
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    
    return true
end

local function findNearestAllowed()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = player.Character.HumanoidRootPart.Position
    local nearest = nil
    local nearestDist = math.huge
    
    for _, pl in ipairs(Players:GetPlayers()) do
        if isValidTarget(pl) then
            local targetHRP = pl.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d = (Vector3.new(targetHRP.Position.X, 0, targetHRP.Position.Z) - Vector3.new(myPos.X, 0, myPos.Z)).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = pl
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
    local args = {
        [1] = targetHRP.Position,
        [2] = targetHRP
    }
    
    if remote and remote.FireServer then
        pcall(function()
            remote:FireServer(unpack(args))
        end)
    end
end

local function autoLaserWorker()
    while autoLaserEnabled do
        local target = findNearestAllowed()
        if target then
            safeFire(target)
        end
        
        local t0 = tick()
        while tick() - t0 < 0.6 do
            if not autoLaserEnabled then break end
            RunService.Heartbeat:Wait()
        end
    end
end

local function enableAimbot()
    if autoLaserEnabled then return end
    autoLaserEnabled = true
    
    if autoLaserThread then task.cancel(autoLaserThread) end
    autoLaserThread = task.spawn(autoLaserWorker)
end

local function disableAimbot()
    if not autoLaserEnabled then return end
    autoLaserEnabled = false
    
    if autoLaserThread then task.cancel(autoLaserThread); autoLaserThread = nil end
end

-- ==================== KICK STEAL FUNCTIONS ====================
local function getStealCount()
    local success, result = pcall(function()
        if not player or not player:FindFirstChild("leaderstats") then return 0 end
        local stealsObject = player.leaderstats:FindFirstChild("Steals")
        if not stealsObject then return 0 end
        
        if stealsObject:IsA("IntValue") or stealsObject:IsA("NumberValue") then
            return stealsObject.Value
        elseif stealsObject:IsA("StringValue") then
            return tonumber(stealsObject.Value) or 0
        else
            return tonumber(tostring(stealsObject.Value)) or 0
        end
    end)
    return success and result or 0
end

local function kickPlayer()
    local success = pcall(function()
        player:Kick("Steal Success!")
    end)
    if not success then
        warn("Failed to kick, attempting shutdown...")
        game:Shutdown()
    end
end

local function startMonitoring()
    if isMonitoring then return end
    
    isMonitoring = true
    lastStealCount = getStealCount()
    
    monitoringLoop = RunService.Heartbeat:Connect(function()
        if not isMonitoring then return end
        
        local currentStealCount = getStealCount()
        
        if currentStealCount > lastStealCount then
            isMonitoring = false
            if monitoringLoop then
                monitoringLoop:Disconnect()
                monitoringLoop = nil
            end
            task.wait(0.1)
            kickPlayer()
        end
        
        lastStealCount = currentStealCount
    end)
end

local function stopMonitoring()
    if not isMonitoring then return end
    
    isMonitoring = false
    
    if monitoringLoop then
        monitoringLoop:Disconnect()
        monitoringLoop = nil
    end
end

local function enableKickSteal()
    if isMonitoring then return end
    startMonitoring()
end

local function disableKickSteal()
    if not isMonitoring then return end
    stopMonitoring()
end

-- ==================== UNWALK ANIM FUNCTIONS ====================
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
    
    -- Hentikan animasi semasa berlari
    local runningConnection = humanoid.Running:Connect(function(speed)
        stopAllAnimations()
    end)
    
    -- Hentikan animasi semasa melompat
    local jumpingConnection = humanoid.Jumping:Connect(function()
        stopAllAnimations()
    end)
    
    -- Hentikan sebarang animasi baru yang cuba dimainkan
    local animationPlayedConnection = animator.AnimationPlayed:Connect(function(animationTrack)
        animationTrack:Stop()
    end)
    
    -- Hentikan animasi secara berterusan pada setiap frame
    local renderSteppedConnection = RunService.RenderStepped:Connect(function()
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
end

local function disableUnwalkAnim()
    if not unwalkAnimEnabled then return end
    unwalkAnimEnabled = false
    
    -- Disconnect all connections
    for _, connection in pairs(unwalkAnimConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    unwalkAnimConnections = {}
end

-- ==================== ANTI DEBUFF FUNCTIONS ====================
local function updateUseItemEventHandler()
    local success, Event = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")):RemoteEvent("UseItem")
    end)
    
    if not success or not Event then
        warn("Could not find UseItem event. Anti-Debuff feature will not work.")
        return
    end
    
    if not antiBeeEnabled and not antiBoogieEnabled then
        if isEventHandlerActive then
            if unifiedConnection then
                unifiedConnection:Disconnect()
                unifiedConnection = nil
            end
            for _, conn in pairs(originalConnections) do
                pcall(function()
                    conn:Enable()
                end)
            end
            originalConnections = {}
            isEventHandlerActive = false
        end
        return
    end
    
    if (antiBeeEnabled or antiBoogieEnabled) and not isEventHandlerActive then
        for i, v in pairs(getconnections(Event.OnClientEvent)) do
            table.insert(originalConnections, v)
            pcall(function()
                v:Disable()
            end)
        end
        
        unifiedConnection = Event.OnClientEvent:Connect(function(Action, ...)
            if antiBeeEnabled and Action == "Bee Attack" then
                return
            end
            if antiBoogieEnabled and Action == "Boogie" then
                return
            end
        end)
        isEventHandlerActive = true
    end
end

local function setupInstantAnimationBlocker()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    if animationPlayedConnection then animationPlayedConnection:Disconnect() end
    
    animationPlayedConnection = animator.AnimationPlayed:Connect(function(track)
        if track and track.Animation then
            if tostring(track.Animation.AnimationId):gsub("%D", "") == BOOGIE_ANIMATION_ID then
                track:Stop(0)
                track:Destroy()
            end
        end
    end)
end

local function enableContinuousMonitoring()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    local lastCheck = 0
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastCheck < 0.03 then return end
        lastCheck = now
        
        pcall(function()
            if Lighting:FindFirstChild("DiscoEffect") then
                Lighting.DiscoEffect:Destroy()
            end
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") then
                    v:Destroy()
                end
            end
            
            local camera = workspace.CurrentCamera
            if camera and camera.FieldOfView > 70 and camera.FieldOfView <= 80 then
                camera.FieldOfView = 70
            end
            
            local boogieScript = player.PlayerScripts:FindFirstChild("Boogie", true)
            if boogieScript then
                local boom = boogieScript:FindFirstChild("BOOM")
                if boom and boom:IsA("Sound") and boom.Playing then
                    boom:Stop()
                end
            end
        end)
    end)
end

local function toggleAntiBee(state)
    antiBeeEnabled = state
    updateUseItemEventHandler()
end

local function toggleAntiBoogie(state)
    antiBoogieEnabled = state
    if antiBoogieEnabled then
        setupInstantAnimationBlocker()
        enableContinuousMonitoring()
    else
        if animationPlayedConnection then
            animationPlayedConnection:Disconnect()
            animationPlayedConnection = nil
        end
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end
    updateUseItemEventHandler()
end

local function toggleAntiDebuff(state)
    toggleAntiBee(state)
    toggleAntiBoogie(state)
end

-- ============================================================
-- ABSOLUTE ANTI RAGDOLL SYSTEM - COMBINED DUAL METHOD (FIXED)
-- ============================================================

-- Method 1 Functions (State-based)
local function stopRagdoll()
    if not ragdollActive then return end
    
    ragdollActive = false
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    
    -- Force standing state
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    hum.PlatformStand = false
    
    -- Fix root part
    root.CanCollide = true
    if root.Anchored then root.Anchored = false end
    
    -- Remove ragdoll constraints
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then
            for _, c in part:GetChildren() do
                if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then
                    c:Destroy()
                end
            end
            
            -- Re-enable motors
            local motor = part:FindFirstChildWhichIsA("Motor6D")
            if motor then
                motor.Enabled = true
            end
        end
    end
    
    -- Reset velocity
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
    
    -- Fix camera
    workspace.CurrentCamera.CameraSubject = hum
end

local function startRagdollTimer()
    if ragdollTimer then ragdollTimer:Disconnect() end
    
    ragdollActive = true
    ragdollTimer = RunService.Heartbeat:Connect(function()
        ragdollTimer:Disconnect()
        ragdollTimer = nil
        stopRagdoll()
    end)
end

local function watchHumanoidStates(char)
    local hum = char:WaitForChild("Humanoid")
    
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() end
    
    humanoidWatchConnection = hum.StateChanged:Connect(function(_, newState)
        if not antiRagdollEnabled then return end -- FIXED: Check master switch
        
        -- Detect ragdoll states
        if newState == Enum.HumanoidStateType.FallingDown or 
           newState == Enum.HumanoidStateType.Ragdoll or 
           newState == Enum.HumanoidStateType.Physics then
            if not ragdollActive then -- Use local flag to prevent re-triggering
                hum.PlatformStand = true
                startRagdollTimer()
            end
        -- Detect recovery states
        elseif newState == Enum.HumanoidStateType.GettingUp or 
               newState == Enum.HumanoidStateType.Running or 
               newState == Enum.HumanoidStateType.RunningNoPhysics then
            hum.PlatformStand = false
            if ragdollActive then
                stopRagdoll()
            end
        end
    end)
end

-- Method 2 Functions (Constraint-based)
local function cacheCharacterData()
    local char = player.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return false end
    
    cachedCharData = {
        character = char,
        humanoid = hum,
        root = root,
    }
    
    return true
end

local function disconnectAll()
    for _, conn in ipairs(ragdollConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    
    local hum = cachedCharData.humanoid
    local state = hum:GetState()
    
    local ragdollStates = {
        [Enum.HumanoidStateType.Physics] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.FallingDown] = true
    }
    
    if ragdollStates[state] then
        return true
    end
    
    -- Check attribute
    local endTime = player:GetAttribute("RagdollEndTime")
    if endTime then
        local now = workspace:GetServerTimeNow()
        if (endTime - now) > 0 then
            return true
        end
    end
    
    return false
end

local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or 
           (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            pcall(function()
                descendant:Destroy()
            end)
        end
    end
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    
    local hum = cachedCharData.humanoid
    local root = cachedCharData.root
    
    -- Clear timer
    pcall(function()
        local now = workspace:GetServerTimeNow()
        player:SetAttribute("RagdollEndTime", now)
    end)
    
    -- Force standing
    if hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    -- Reset physics
    root.Anchored = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    hum.PlatformStand = false
end

local function constraintRemovalLoop()
    while constraintLoopActive and cachedCharData.humanoid do
        task.wait()
        
        if isRagdolled() then
            removeRagdollConstraints()
            forceExitRagdoll()
        end
    end
end

local function setupCameraBinding()
    if not cachedCharData.humanoid then return end
    
    local conn = RunService.RenderStepped:Connect(function()
        if not constraintLoopActive then return end
        
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    
    table.insert(ragdollConnections, conn)
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================

local function setupCharacter(char)
    task.wait(0.5)
    
    if not antiRagdollEnabled then return end -- FIXED: Check master switch
    
    -- Reset Method 1
    ragdollActive = false
    if ragdollTimer then 
        ragdollTimer:Disconnect()
        ragdollTimer = nil 
    end
    
    -- Setup Method 1 (State-based)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    watchHumanoidStates(char)
    
    -- Setup Method 2 (Constraint-based)
    if cacheCharacterData() then
        setupCameraBinding()
        task.spawn(constraintRemovalLoop)
    end
end

-- ============================================================
-- ENABLE/DISABLE FUNCTIONS
-- ============================================================

local function enableAbsoluteAntiRagdoll()
    antiRagdollEnabled = true -- FIXED: Set master switch
    constraintLoopActive = true
    
    local char = player.Character
    if char then
        setupCharacter(char)
    end
    
    -- Setup respawn handler
    local charConn = player.CharacterAdded:Connect(setupCharacter)
    table.insert(ragdollConnections, charConn)
end

local function disableAbsoluteAntiRagdoll()
    antiRagdollEnabled = false -- FIXED: Set master switch
    constraintLoopActive = false
    ragdollActive = false
    
    -- Cleanup Method 1
    if ragdollTimer then
        ragdollTimer:Disconnect()
        ragdollTimer = nil
    end
    
    if humanoidWatchConnection then
        humanoidWatchConnection:Disconnect()
        humanoidWatchConnection = nil
    end
    
    -- Cleanup Method 2
    disconnectAll()
    cachedCharData = {}
end

-- ============================================================
-- PUBLIC API
-- ============================================================

local ANTI_RAGDOLL = {}

function ANTI_RAGDOLL.Enable()
    enableAbsoluteAntiRagdoll()
end

function ANTI_RAGDOLL.Disable()
    disableAbsoluteAntiRagdoll()
end

function ANTI_RAGDOLL.Toggle()
    if antiRagdollEnabled then
        disableAbsoluteAntiRagdoll()
    else
        enableAbsoluteAntiRagdoll()
    end
end

function ANTI_RAGDOLL.IsEnabled()
    return antiRagdollEnabled
end

-- ==================== XRAY BASE FUNCTIONS (FIXED VERSION) ====================
local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    local parent = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or parent:find("base")
end

local function tryApplyInvisibleWalls()
    if not xrayBaseEnabled or invisibleWallsLoaded then return end
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots or #plots:GetChildren() == 0 then 
        return 
    end
    
    local processedCount = 0
    
    -- Hanya proses objek dalam plots untuk performance yang lebih baik
    for _, plot in pairs(plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and isBaseWall(obj) then
                if not originalTransparency[obj] then
                    originalTransparency[obj] = obj.LocalTransparencyModifier
                    obj.LocalTransparencyModifier = 0.85
                    processedCount = processedCount + 1
                end
            end
        end
    end
    
    invisibleWallsLoaded = true
end

local function cleanupRemovedParts()
    -- Cleanup parts yang sudah dihapus dari game
    for obj, _ in pairs(originalTransparency) do
        if not obj or not obj.Parent then
            originalTransparency[obj] = nil
        end
    end
end

local function enableXrayBase()
    if xrayBaseEnabled then 
        return 
    end
    
    xrayBaseEnabled = true
    invisibleWallsLoaded = false
    
    -- Bersihkan dahulu
    cleanupRemovedParts()
    
    -- Apply dengan delay untuk mengelakkan lag
    task.spawn(function()
        task.wait(0.5) -- Beri masa untuk UI dimuatkan
        tryApplyInvisibleWalls()
    end)
    
    -- Setup event handler dengan disconnect yang betul
    if xrayBaseConnection then
        xrayBaseConnection:Disconnect()
    end
    
    xrayBaseConnection = workspace.DescendantAdded:Connect(function(obj)
        if not xrayBaseEnabled then return end
        
        task.wait(0.1) -- Delay kecil untuk stability
        
        if isBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
            if not originalTransparency[obj] then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
    
    -- Cleanup connection untuk parts yang dihapus
    local cleanupConnection
    cleanupConnection = workspace.DescendantRemoving:Connect(function(obj)
        if originalTransparency[obj] then
            originalTransparency[obj] = nil
        end
    end)
end

local function disableXrayBase()
    if not xrayBaseEnabled then 
        return 
    end
    
    xrayBaseEnabled = false
    invisibleWallsLoaded = false
    
    -- Disconnect semua connections
    if xrayBaseConnection then
        xrayBaseConnection:Disconnect()
        xrayBaseConnection = nil
    end
    
    -- Pulihkan transparency untuk semua parts
    local restoredCount = 0
    for obj, value in pairs(originalTransparency) do
        if obj and obj.Parent then
            pcall(function()
                obj.LocalTransparencyModifier = value
                restoredCount = restoredCount + 1
            end)
        end
    end
    
    originalTransparency = {}
end
    
-- ==================== FPS BOOST FUNCTIONS ====================
local function addThread(func)
    local t = task.spawn(func)
    table.insert(optimizerThreads, t)
    return t
end

local function addConnection(conn)
    table.insert(optimizerConnections, conn)
    return conn
end

local function storeOriginalSettings()
    pcall(function()
        originalSettings = {
            streamingEnabled = workspace.StreamingEnabled,
            streamingMinRadius = workspace.StreamingMinRadius,
            streamingTargetRadius = workspace.StreamingTargetRadius,
            qualityLevel = settings().Rendering.QualityLevel,
            meshPartDetailLevel = settings().Rendering.MeshPartDetailLevel,
            globalShadows = game.Lighting.GlobalShadows,
            brightness = game.Lighting.Brightness,
            fogEnd = game.Lighting.FogEnd,
            technology = game.Lighting.Technology,
            environmentDiffuseScale = game.Lighting.EnvironmentDiffuseScale,
            environmentSpecularScale = game.Lighting.EnvironmentSpecularScale,
            decoration = workspace.Terrain.Decoration,
            waterWaveSize = workspace.Terrain.WaterWaveSize,
            waterWaveSpeed = workspace.Terrain.WaterWaveSpeed,
            waterReflectance = workspace.Terrain.WaterReflectance,
            waterTransparency = workspace.Terrain.WaterTransparency,
        }
    end)
end

local PERFORMANCE_FFLAGS = {
    ["DFIntTaskSchedulerTargetFps"] = 999,
    ["FFlagDebugGraphicsPreferVulkan"] = true,
    ["FFlagDebugGraphicsDisableDirect3D11"] = true,
    ["FFlagDebugGraphicsPreferD3D11FL10"] = false,
    ["DFFlagDebugRenderForceTechnologyVoxel"] = true,
    ["FFlagDisablePostFx"] = true,
    ["FIntRenderShadowIntensity"] = 0,
    ["FIntRenderLocalLightUpdatesMax"] = 0,
    ["FIntRenderLocalLightUpdatesMin"] = 0,
    ["DFIntTextureCompositorActiveJobs"] = 1,
    ["DFIntDebugFRMQualityLevelOverride"] = 1,
    ["FFlagFixPlayerCollisionWhenSwimming"] = false,
    ["DFIntMaxInterpolationSubsteps"] = 0,
    ["DFIntS2PhysicsSenderRate"] = 15,
    ["DFIntConnectionMTUSize"] = 1492,
    ["DFIntHttpCurlConnectionCacheSize"] = 134217728,
    ["DFIntCSGLevelOfDetailSwitchingDistance"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL12"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL23"] = 0,
    ["DFIntCSGLevelOfDetailSwitchingDistanceL34"] = 0,
    ["FFlagEnableInGameMenuChromeABTest3"] = false,
    ["FFlagEnableInGameMenuModernization"] = false,
    ["FFlagEnableReportAbuseMenuRoactABTest2"] = false,
    ["FFlagDisableNewIGMinDUA"] = true,
    ["FFlagEnableV3MenuABTest3"] = false,
    ["FIntRobloxGuiBlurIntensity"] = 0,
    ["DFIntTimestepArbiterThresholdCFLThou"] = 10,
    ["DFIntTextureQualityOverride"] = 1,
    ["DFIntPerformanceControlTextureQualityBestUtility"] = 1,
    ["DFIntTexturePoolSizeMB"] = 64,
    ["DFIntMaxFrameBufferSize"] = 1,
    ["FFlagDebugDisableParticleRendering"] = false,
    ["DFIntParticleMaxCount"] = 100,
    ["FFlagEnableWaterReflections"] = false,
    ["DFIntWaterReflectionQuality"] = 0,
}

local function applyFFlags()
    local success = 0
    local failed = 0
    
    for flag, value in pairs(PERFORMANCE_FFLAGS) do
        local ok = pcall(function()
            setfflag(flag, tostring(value))
        end)
        
        if ok then
            success = success + 1
        else
            failed = failed + 1
        end
    end
end

local function nukeVisualEffects()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") then
                    obj.Enabled = false
                    obj.Rate = 0
                    obj:Destroy()
                elseif obj:IsA("Trail") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    obj.Enabled = false
                    obj.Brightness = 0
                    obj:Destroy()
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif obj:IsA("Explosion") then
                    obj:Destroy()
                elseif obj:IsA("SpecialMesh") then
                    obj.TextureId = ""
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if not (obj.Name == "face" and obj.Parent and obj.Parent.Name == "Head") then
                        obj.Transparency = 1
                    end
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                    if obj.Material == Enum.Material.Glass then
                        obj.Reflectance = 0
                    end
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
                pcall(function()
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                        part.Material = Enum.Material.Plastic
                        part.Reflectance = 0
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                        part:Destroy()
                    elseif part:IsA("PointLight") or part:IsA("SpotLight") or part:IsA("SurfaceLight") then
                        part:Destroy()
                    elseif part:IsA("Fire") or part:IsA("Smoke") or part:IsA("Sparkles") then
                        part:Destroy()
                    end
                end)
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
        workspace.StreamingEnabled = true
        workspace.StreamingMinRadius = 64
        workspace.StreamingTargetRadius = 256
        workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.MinimumRadiusPause
    end)
    
    pcall(function()
        local renderSettings = settings().Rendering
        renderSettings.QualityLevel = Enum.QualityLevel.Level01
        renderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        renderSettings.EditQualityLevel = Enum.QualityLevel.Level01
        
        game.Lighting.GlobalShadows = false
        game.Lighting.Brightness = 3
        game.Lighting.FogEnd = 9e9
        game.Lighting.Technology = Enum.Technology.Legacy
        game.Lighting.EnvironmentDiffuseScale = 0
        game.Lighting.EnvironmentSpecularScale = 0
        
        for _, effect in ipairs(game.Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                pcall(function() 
                    effect.Enabled = false 
                    effect:Destroy()
                end)
            end
        end
    end)
    
    pcall(function()
        local physics = settings().Physics
        physics.AllowSleep = true
        physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Skip
        physics.ThrottleAdjustTime = 0
    end)
    
    pcall(function()
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.Decoration = false
    end)
    
    addThread(function()
        task.wait(1)
        nukeVisualEffects()
    end)
    
    addConnection(workspace.DescendantAdded:Connect(function(obj)
        if not getgenv().OPTIMIZER_ACTIVE then return end
        
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or
               obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") or
               obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.Plastic
            end
        end)
    end))
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            optimizeCharacter(p.Character)
        end
        
        addConnection(p.CharacterAdded:Connect(function(char)
            if getgenv().OPTIMIZER_ACTIVE then
                optimizeCharacter(char)
            end
        end))
    end
    
    addConnection(Players.PlayerAdded:Connect(function(p)
        addConnection(p.CharacterAdded:Connect(function(char)
            if getgenv().OPTIMIZER_ACTIVE then
                optimizeCharacter(char)
            end
        end))
    end))
    
    pcall(function()
        setfpscap(999)
    end)
    
    pcall(function()
        local cam = workspace.CurrentCamera
        cam.FieldOfView = 70
    end)
end

local function disableFpsBoost()
    if not fpsBoostEnabled then return end
    fpsBoostEnabled = false
    getgenv().OPTIMIZER_ACTIVE = false
    
    for _, thread in ipairs(optimizerThreads) do
        pcall(function()
            task.cancel(thread)
        end)
    end
    optimizerThreads = {}
    
    for _, conn in ipairs(optimizerConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    optimizerConnections = {}
    
    pcall(function()
        workspace.StreamingEnabled = originalSettings.streamingEnabled or true
        workspace.StreamingMinRadius = originalSettings.streamingMinRadius or 64
        workspace.StreamingTargetRadius = originalSettings.streamingTargetRadius or 1024
        
        settings().Rendering.QualityLevel = originalSettings.qualityLevel or Enum.QualityLevel.Automatic
        settings().Rendering.MeshPartDetailLevel = originalSettings.meshPartDetailLevel or Enum.MeshPartDetailLevel.DistanceBased
        
        game.Lighting.GlobalShadows = originalSettings.globalShadows ~= false
        game.Lighting.Brightness = originalSettings.brightness or 1
        game.Lighting.FogEnd = originalSettings.fogEnd or 100000
        game.Lighting.Technology = originalSettings.technology or Enum.Technology.ShadowMap
        game.Lighting.EnvironmentDiffuseScale = originalSettings.environmentDiffuseScale or 1
        game.Lighting.EnvironmentSpecularScale = originalSettings.environmentSpecularScale or 1
        
        workspace.Terrain.WaterWaveSize = originalSettings.waterWaveSize or 0.15
        workspace.Terrain.WaterWaveSpeed = originalSettings.waterWaveSpeed or 10
        workspace.Terrain.WaterReflectance = originalSettings.waterReflectance or 1
        workspace.Terrain.WaterTransparency = originalSettings.waterTransparency or 0.3
        workspace.Terrain.Decoration = originalSettings.decoration ~= false
    end)
end

-- ==================== ESP TIMER FUNCTIONS ====================
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
    for _, plot in pairs(Workspace:FindFirstChild("Plots"):GetChildren()) do
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
                    
                    -- Check if base is unlocked (Locked.Visible = false)
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
    
    StarterGui:SetCore("SendNotification", {
        Title = "Timer ESP",
        Text = "Timer ESP: ON",
        Duration = 2
    })

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
    
    StarterGui:SetCore("SendNotification", {
        Title = "Timer ESP",
        Text = "Timer ESP: OFF",
        Duration = 2
    })

    for _, plot in pairs(Workspace:FindFirstChild("Plots"):GetChildren()) do
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

-- ==================== NEAREST FUNCTIONS ====================
local function createNearestUI()
    if nearestUI then
        nearestUI:Destroy()
    end
    
    -- Get Packages
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")
    
    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local RaritiesData = require(Datas:WaitForChild("Rarities"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))
    
    -- Variables
    local allAnimalsCache = {}
    local PromptMemoryCache = {}
    local InternalStealCache = {}
    local AUTO_STEAL_PROX_RADIUS = 35
    
    -- MODE: "nearest" or "bestgen"
    local stealMode = "bestgen"
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealBar"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    
    -- Main Frame (280x90 - taller untuk button)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 90)
    mainFrame.Position = UDim2.new(0.5, -140, 0.15, 0)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 18)
    mainCorner.Parent = mainFrame
    
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.fromRGB(220, 50, 50)
    outerStroke.Thickness = 1.0
    outerStroke.Transparency = 0
    outerStroke.Parent = mainFrame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 18)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "WAITING FOR STEAL"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.Arcade
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = mainFrame
    
    -- Stud label
    local studLabel = Instance.new("TextLabel")
    studLabel.Size = UDim2.new(0.35, 0, 0, 16)
    studLabel.Position = UDim2.new(0.65, 0, 0, 7)
    studLabel.BackgroundTransparency = 1
    studLabel.Text = "0.0 studs"
    studLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    studLabel.TextSize = 10
    studLabel.Font = Enum.Font.Arcade
    studLabel.TextXAlignment = Enum.TextXAlignment.Right
    studLabel.TextTruncate = Enum.TextTruncate.AtEnd
    studLabel.Parent = mainFrame
    
    -- Money label
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -20, 0, 15)
    moneyLabel.Position = UDim2.new(0, 10, 0, 24)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "$0.0/s"
    moneyLabel.TextColor3 = Color3.fromRGB(70, 220, 90)
    moneyLabel.TextSize = 11
    moneyLabel.Font = Enum.Font.Arcade
    moneyLabel.TextXAlignment = Enum.TextXAlignment.Center
    moneyLabel.Parent = mainFrame
    
    -- Mode Toggle Button (NEW)
    local modeButton = Instance.new("TextButton")
    modeButton.Size = UDim2.new(1, -20, 0, 20)
    modeButton.Position = UDim2.new(0, 10, 0, 42)
    modeButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    modeButton.BorderSizePixel = 0
    modeButton.Text = "MODE: BEST GEN"
    modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeButton.TextSize = 10
    modeButton.Font = Enum.Font.Arcade
    modeButton.Parent = mainFrame
    
    local modeCorner = Instance.new("UICorner")
    modeCorner.CornerRadius = UDim.new(0, 8)
    modeCorner.Parent = modeButton
    
    local modeStroke = Instance.new("UIStroke")
    modeStroke.Color = Color3.fromRGB(220, 50, 50)
    modeStroke.Thickness = 1.0
    modeStroke.Transparency = 0.3
    modeStroke.Parent = modeButton
    
    -- Progress bar container
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, -20, 0, 12)
    barContainer.Position = UDim2.new(0, 10, 1, -18)
    barContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    barContainer.BorderSizePixel = 0
    barContainer.Parent = mainFrame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 6)
    barCorner.Parent = barContainer
    
    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.fromRGB(40, 40, 40)
    barStroke.Thickness = 1.0
    barStroke.Parent = barContainer
    
    -- Fill bar
    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    fillBar.BorderSizePixel = 0
    fillBar.Parent = barContainer
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fillBar
    
    -- Percent label
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Size = UDim2.new(1, 0, 1, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = ""
    percentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    percentLabel.TextSize = 8
    percentLabel.Font = Enum.Font.Arcade
    percentLabel.ZIndex = 2
    percentLabel.Parent = barContainer
    
    local isAnimating = false
    
    -- Format Number Function
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
    
    local function animateFill()
        if isAnimating then return end 
        isAnimating = true
        
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
        
        tween:Play()
        
        task.spawn(function()
            for i = 0, 100 do
                percentLabel.Text = i .. "%"
                task.wait(0.7 / 100)
            end
        end)
        
        tween.Completed:Wait()
        task.wait(0.14)
        
        fillBar.Size = UDim2.new(0, 0, 1, 0)
        percentLabel.Text = ""
        isAnimating = false
    end
    
    -- Mode Toggle Button Click
    modeButton.MouseButton1Click:Connect(function()
        if stealMode == "bestgen" then
            stealMode = "nearest"
            modeButton.Text = "MODE: NEAREST"
            modeButton.TextColor3 = Color3.fromRGB(180, 180, 190)
            modeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            modeStroke.Color = Color3.fromRGB(80, 80, 90)
        else
            stealMode = "bestgen"
            modeButton.Text = "MODE: BEST GEN"
            modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            modeButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
            modeStroke.Color = Color3.fromRGB(220, 50, 50)
        end
    end)
    
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
    
    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot then return false end
        
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return false end
        
        local plot = plots:FindFirstChild(animalData.plot)
        if not plot then return false end
        
        local channel = Synchronizer:Get(plot.Name)
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
        
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase:IsA("BillboardGui") then
                return yourBase.Enabled == true
            end
        end
        
        return false
    end
    
    local function findProximityPromptForAnimal(animalData)
        if not animalData then return nil end
        
        local cachedPrompt = PromptMemoryCache[animalData.uid]
        if cachedPrompt and cachedPrompt.Parent then
            return cachedPrompt
        end
        
        local plot = workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return nil end
        
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then return nil end
        
        local podium = podiums:FindFirstChild(animalData.slot)
        if not podium then return nil end
        
        local base = podium:FindFirstChild("Base")
        if not base then return nil end
        
        local spawn = base:FindFirstChild("Spawn")
        if not spawn then return nil end
        
        local attach = spawn:FindFirstChild("PromptAttachment")
        if not attach then return nil end
        
        for _, p in ipairs(attach:GetChildren()) do
            if p:IsA("ProximityPrompt") then
                PromptMemoryCache[animalData.uid] = p
                return p
            end
        end
        
        return nil
    end
    
    local function getAnimalPosition(animalData)
        if not animalData or not animalData.plot or not animalData.slot then return nil end
        
        local plot = workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return nil end
        
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then return nil end
        
        local podium = podiums:FindFirstChild(animalData.slot)
        if not podium then return nil end
        
        return podium:GetPivot().Position
    end
    
    -- Get Best Gen Animal
    local function getBestStealableAnimal()
        for _, animal in ipairs(allAnimalsCache) do
            if not isMyBaseAnimal(animal) then
                return animal
            end
        end
        return nil
    end
    
    -- Get Nearest Animal (NEW)
    local function getNearestAnimal()
        local character = player.Character
        if not character then return nil end
        
        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
        if not hrp then return nil end
        
        local nearest = nil
        local minDist = math.huge
        
        for _, animalData in ipairs(allAnimalsCache) do
            if isMyBaseAnimal(animalData) then
                continue
            end
            
            local pos = getAnimalPosition(animalData)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                
                if dist < minDist then
                    minDist = dist
                    nearest = animalData
                end
            end
        end
        
        return nearest
    end
    
    -- Get Target Based on Mode (NEW)
    local function getTargetAnimal()
        if stealMode == "nearest" then
            return getNearestAnimal()
        else
            return getBestStealableAnimal()
        end
    end
    
    local function buildStealCallbacks(prompt)
        if InternalStealCache[prompt] then return end
        
        local data = {
            holdCallbacks = {},
            triggerCallbacks = {},
            ready = true,
        }
        
        local ok1, conns1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
        if ok1 and type(conns1) == "table" then
            for _, conn in ipairs(conns1) do
                if type(conn.Function) == "function" then
                    table.insert(data.holdCallbacks, conn.Function)
                end
            end
        end
        
        local ok2, conns2 = pcall(getconnections, prompt.Triggered)
        if ok2 and type(conns2) == "table" then
            for _, conn in ipairs(conns2) do
                if type(conn.Function) == "function" then
                    table.insert(data.triggerCallbacks, conn.Function)
                end
            end
        end
        
        if (#data.holdCallbacks > 0) or (#data.triggerCallbacks > 0) then
            InternalStealCache[prompt] = data
        end
    end
    
    local function executeInternalStealAsync(prompt)
        local data = InternalStealCache[prompt]
        if not data or not data.ready then return false end
        
        data.ready = false
        
        task.spawn(function()
            if #data.holdCallbacks > 0 then
                for _, fn in ipairs(data.holdCallbacks) do
                    task.spawn(fn)
                end
            end
            
            task.wait(1.3)
            
            if #data.triggerCallbacks > 0 then
                for _, fn in ipairs(data.triggerCallbacks) do
                    task.spawn(fn)
                end
            end
            
            task.wait(0.1)
            data.ready = true
        end)
        
        return true
    end
    
    local function attemptSteal(prompt)
        if not prompt or not prompt.Parent then
            return false
        end
        
        buildStealCallbacks(prompt)
        if not InternalStealCache[prompt] then
            return false
        end
        
        return executeInternalStealAsync(prompt)
    end
    
    local function scanAllPlots()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return {} end
        
        local newCache = {}
        
        for _, plot in ipairs(plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if not channel then continue end
            
            local animalList = channel:Get("AnimalList")
            if not animalList then continue end
            
            local owner = channel:Get("Owner")
            if not owner then continue end
            
            local ownerName = "Unknown"
            if typeof(owner) == "Instance" and owner:IsA("Player") then
                ownerName = owner.Name
            elseif typeof(owner) == "table" and owner.Name then
                ownerName = owner.Name
            end
            
            for slot, animalData in pairs(animalList) do
                if type(animalData) == "table" then
                    local animalName = animalData.Index
                    local animalInfo = AnimalsData[animalName]
                    if not animalInfo then continue end
                    
                    local genValue = AnimalsShared:GetGeneration(animalName, animalData.Mutation, animalData.Traits, nil)
                    
                    table.insert(newCache, {
                        name = animalInfo.DisplayName or animalName,
                        genValue = genValue,
                        plot = plot.Name,
                        slot = tostring(slot),
                        uid = plot.Name .. "_" .. tostring(slot),
                    })
                end
            end
        end
        
        allAnimalsCache = newCache
        
        table.sort(allAnimalsCache, function(a, b)
            return a.genValue > b.genValue
        end)
        
        return #allAnimalsCache
    end
    
    local function startAutoSteal()
        if nearestStealConnection then return end
        
        nearestStealConnection = RunService.Heartbeat:Connect(function()
            local targetAnimal = getTargetAnimal()
            
            if not targetAnimal then
                titleLabel.Text = "WAITING FOR STEAL"
                studLabel.Text = "0.0 studs"
                moneyLabel.Text = "$" .. formatNumber(0)
                return
            end
            
            local character = player.Character
            if not character then return end
            
            local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
            if not hrp then return end
            
            local animalPos = getAnimalPosition(targetAnimal)
            if not animalPos then return end
            
            local dist = (hrp.Position - animalPos).Magnitude
            
            titleLabel.Text = string.upper(targetAnimal.name)
            studLabel.Text = string.format("%.1f studs", dist)
            moneyLabel.Text = "$" .. formatNumber(targetAnimal.genValue)
            
            if dist <= AUTO_STEAL_PROX_RADIUS then
                task.spawn(animateFill)
                
                local prompt = PromptMemoryCache[targetAnimal.uid]
                if not prompt or not prompt.Parent then
                    prompt = findProximityPromptForAnimal(targetAnimal)
                end
                
                if prompt then
                    attemptSteal(prompt)
                end
            end
        end)
    end
    
    local function stopAutoSteal()
        if not nearestStealConnection then return end
        nearestStealConnection:Disconnect()
        nearestStealConnection = nil
    end
    
    task.spawn(function()
        while task.wait(5) do
            scanAllPlots()
        end
    end)
    
    startAutoSteal()
    
    nearestUI = screenGui
end

local function destroyNearestUI()
    if nearestUI then
        nearestUI:Destroy()
        nearestUI = nil
    end
    if nearestStealConnection then
        nearestStealConnection:Disconnect()
        nearestStealConnection = nil
    end
end

local function enableNearest()
    if nearestEnabled then return end
    nearestEnabled = true
    createNearestUI()
end

local function disableNearest()
    if not nearestEnabled then return end
    nearestEnabled = false
    destroyNearestUI()
end

-- ==================== TOGGLE FUNCTIONS FOR UI ====================
local function toggleEspPlayers(state)
    if state then
        enableESPPlayers()
    else
        disableESPPlayers()
    end
end

local function toggleEspBest(state)
    if state then
        enableESPBest()
    else
        disableESPBest()
    end
end

local function toggleBaseLine(state)
    if state then
        enableBaseLine()
    else
        disableBaseLine()
    end
end

local function toggleAntiTurret(state)
    if state then
        enableAntiTurret()
    else
        disableAntiTurret()
    end
end

local function toggleAimbot(state)
    if state then
        enableAimbot()
    else
        disableAimbot()
    end
end

local function toggleKickSteal(state)
    if state then
        enableKickSteal()
    else
        disableKickSteal()
    end
end

local function toggleUnwalkAnim(state)
    if state then
        enableUnwalkAnim()
    else
        disableUnwalkAnim()
    end
end

local function toggleAntiRagdoll(state)
    if state then
        ANTI_RAGDOLL.Enable()
    else
        ANTI_RAGDOLL.Disable()
    end
end

local function toggleXrayBase(state)
    if state then
        enableXrayBase()
    else
        disableXrayBase()
    end
end

local function toggleFpsBoost(state)
    if state then
        enableFpsBoost()
    else
        disableFpsBoost()
    end
end

local function toggleEspTimer(state)
    if state then
        enableTimerESP()
    else
        disableTimerESP()
    end
end

local function toggleNearest(state)
    if state then
        enableNearest()
    else
        disableNearest()
    end
end

-- ==================== PLAYER EVENT HANDLERS ====================
-- Apabila pemain baru masuk
Players.PlayerAdded:Connect(function(targetPlayer)
    targetPlayer.CharacterAdded:Connect(function(character)
        task.wait(1) -- Tunggu sebentar untuk watak dimuatkan sepenuhnya
        if espPlayersEnabled and targetPlayer ~= player then
            createESP(targetPlayer)
        end
    end)
end)

-- Apabila pemain keluar
Players.PlayerRemoving:Connect(function(targetPlayer)
    removeESP(targetPlayer)
end)

-- Semak pemain yang sedia ada dalam server
for _, targetPlayer in pairs(Players:GetPlayers()) do
    if targetPlayer ~= player then
        targetPlayer.CharacterAdded:Connect(function(character)
            task.wait(1)
            if espPlayersEnabled then
                createESP(targetPlayer)
            end
        end)
    end
end

-- Sambungan event untuk memuat semula garis jika watak respawn
player.CharacterAdded:Connect(function(newCharacter)
    task.wait(1)
    -- ESP Players is now handled by the new event handlers, no need to re-create here.
    
    if espBestEnabled then
        updateHighestValueESP()
        -- TAMBAH: Cipta semula tracer line selepas respawn
        if highestValueData then
            createTracerLine()
        end
    end
    
    if baseLineEnabled then
        pcall(stopPlotLine)
        task.wait(0.5)
        pcall(createPlotLine)
    end
    
    if sentryEnabled then
        stopSentryWatch()
        sentryEnabled = false
        task.wait(0.5)
        sentryEnabled = true
        startSentryWatch()
    end
    
    if autoLaserEnabled then
        autoLaserEnabled = false
        task.wait(0.5)
        autoLaserEnabled = true
        if autoLaserThread then task.cancel(autoLaserThread) end
        autoLaserThread = task.spawn(autoLaserWorker)
    end
    
    if isMonitoring then
        stopMonitoring()
        task.wait(0.5)
        startMonitoring()
    end
    
    if unwalkAnimEnabled then
        setupNoWalkAnimation(newCharacter)
    end
    
    if antiBoogieEnabled then
        setupInstantAnimationBlocker()
    end
    
    -- Anti-Ragdoll V2 handles its own respawn logic
    
    if xrayBaseEnabled then
        invisibleWallsLoaded = false
        tryApplyInvisibleWalls()
    end
    
    if fpsBoostEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                optimizeCharacter(p.Character)
            end
        end
    end
end)

player.CharacterRemoving:Connect(function()
    pcall(stopPlotLine)
end)

-- ==================== CREATE UI AND ADD TOGGLES ====================
Nightmare:CreateUI()

-- LANGKAH 2: Sekarang barulah boleh gunakan fungsi-fungsi lain dengan selamat
-- Notifikasi apabila UI dimuatkan
Nightmare:Notify("Nightmare Hub")

-- LANGKAH 3: Tambah semua toggle
Nightmare:AddToggleRow("Esp Players", toggleEspPlayers, "Esp Best", toggleEspBest)
Nightmare:AddToggleRow("Base Line", toggleBaseLine, "Anti Turret", toggleAntiTurret)
Nightmare:AddToggleRow("Aimbot", toggleAimbot, "Kick Steal", toggleKickSteal)
Nightmare:AddToggleRow("Unwalk Anim", toggleUnwalkAnim, "Anti Debuff", toggleAntiDebuff)
Nightmare:AddToggleRow("Anti Rdoll", toggleAntiRagdoll, "Xray Base", toggleXrayBase)
Nightmare:AddToggleRow("Fps Boost", toggleFpsBoost, "Esp Timer", toggleEspTimer)
Nightmare:AddToggleRow("Nearest", toggleNearest, "", nil)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Sabstealtoolsv1.lua"))()
