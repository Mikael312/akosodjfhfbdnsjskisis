--[[
    ARCADE UI - INTEGRASI ESP PLAYERS, ESP BEST, BASE LINE, ANTI TURRET, AIMBOT, KICK STEAL, UNWALK ANIM, AUTO STEAL, ANTI DEBUFF, ANTI RDOLL, XRAY BASE, FPS BOOST & ESP TIMER
    STRUCTURE: G. (Global/Shared) & S. (Specific/Modules)
    FIXED: Full logic restored, Toggles visible, Loadstring protected.
]]

-- ==================== ROOT ENVIRONMENT ====================
local Script = {
    G = {}, -- Global (Shared utilities, services, libraries)
    S = {}  -- Specific (Features: ESP, Aimbot, etc.)
}

-- ==================== LOAD LIBRARY (G) ====================
Script.G.Success, Script.G.ArcadeUILib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/Nightmare-Ui/refs/heads/main/ArcadeUiLib.lua"))()
end)

if not Script.G.Success then
    warn("❌ Failed to load ArcadeUI library!")
    return
end

-- Assign global for compatibility if library needs it
ArcadeUILib = Script.G.ArcadeUILib

-- ==================== G. SERVICES & VARIABLES ====================
Script.G.Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    StarterGui = game:GetService("StarterGui")
}

Script.G.Player = Script.G.Services.Players.LocalPlayer

-- ==================== G. MODULES (Shared Data) ====================
Script.G.Modules = {}

pcall(function()
    Script.G.Modules.Animals = require(Script.G.Services.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
    Script.G.Modules.Traits = require(Script.G.Services.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Traits"))
    Script.G.Modules.Mutations = require(Script.G.Services.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Mutations"))
    Script.G.Modules.Rarities = require(Script.G.Services.ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Rarities"))
    Script.G.Modules.Shared = require(Script.G.Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
    Script.G.Modules.Utils = require(Script.G.Services.ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))
    Script.G.Modules.Synchronizer = require(Script.G.Services.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
    Script.G.Modules.Net = require(Script.G.Services.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
end)

-- ==================== G. HELPER FUNCTIONS ====================
Script.G.FormatNumber = function(num)
    local value, suffix
    if num >= 1e12 then value, suffix = num / 1e12, "T/s"
    elseif num >= 1e9 then value, suffix = num / 1e9, "B/s"
    elseif num >= 1e6 then value, suffix = num / 1e6, "M/s"
    elseif num >= 1e3 then value, suffix = num / 1e3, "K/s"
    else return string.format("%.0f/s", num) end
    
    if value == math.floor(value) then return string.format("%.0f%s", value, suffix)
    else return string.format("%.1f%s", value, suffix) end
end

-- ==================== S. ESP PLAYERS ====================
Script.S.EspPlayers = {
    Enabled = false,
    Objects = {},
    Connection = nil,

    GetEquippedItem = function(character)
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then return child.Name end
        end
        return "None"
    end,

    Create = function(targetPlayer)
        if targetPlayer == Script.G.Player then return end
        local character = targetPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerESP"
        highlight.Adornee = character
        highlight.FillColor = Color3.fromRGB(0, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
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
        nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
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

        Script.S.EspPlayers.Objects[targetPlayer] = { highlight = highlight, billboard = billboard, itemLabel = itemLabel, character = character }
    end,

    Remove = function(targetPlayer)
        local data = Script.S.EspPlayers.Objects[targetPlayer]
        if data then
            if data.highlight then data.highlight:Destroy() end
            if data.billboard then data.billboard:Destroy() end
            Script.S.EspPlayers.Objects[targetPlayer] = nil
        end
    end,

    Update = function()
        if not Script.S.EspPlayers.Enabled then return end
        for targetPlayer, espData in pairs(Script.S.EspPlayers.Objects) do
            if targetPlayer and targetPlayer.Parent and espData.character and espData.character.Parent then
                local rootPart = espData.character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local item = Script.S.EspPlayers.GetEquippedItem(espData.character)
                    espData.itemLabel.Text = "Item: " .. item
                    espData.itemLabel.TextColor3 = (item ~= "None") and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 100)
                else Script.S.EspPlayers.Remove(targetPlayer) end
            else Script.S.EspPlayers.Remove(targetPlayer) end
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.EspPlayers.Enabled then return end
            Script.S.EspPlayers.Enabled = true
            for _, p in pairs(Script.G.Services.Players:GetPlayers()) do if p ~= Script.G.Player and p.Character then Script.S.EspPlayers.Create(p) end end
            Script.S.EspPlayers.Connection = Script.G.Services.RunService.RenderStepped:Connect(Script.S.EspPlayers.Update)
            print("✅ ESP Players ON")
        else
            if not Script.S.EspPlayers.Enabled then return end
            Script.S.EspPlayers.Enabled = false
            for p, _ in pairs(Script.S.EspPlayers.Objects) do Script.S.EspPlayers.Remove(p) end
            if Script.S.EspPlayers.Connection then Script.S.EspPlayers.Connection:Disconnect() end
            print("❌ ESP Players OFF")
        end
    end
}

-- ==================== S. ESP BEST ====================
Script.S.EspBest = {
    Enabled = false,
    Data = nil,
    Objects = { highlight = nil, nameLabel = nil, box = nil, podium = nil },
    Tracer = { conn = nil, beam = nil, att0 = nil, att1 = nil },
    Thread = nil,
    LastNotified = nil,

    GetTraitMultiplier = function(model)
        local module = Script.G.Modules.Traits
        if not module then return 0 end
        local traitJson = model:GetAttribute("Traits")
        if not traitJson or traitJson == "" then return 0 end
        local traits = typeof(pcall(function() return Script.G.Services.HttpService:JSONDecode(traitJson) end)) == "table" and Script.G.Services.HttpService:JSONDecode(traitJson) or {}
        local mult = 0
        for _, entry in pairs(traits) do
            local name = typeof(entry) == "table" and entry.Name or tostring(entry)
            name = name:gsub("^_Trait%.", "")
            local trait = module[name]
            if trait and trait.MultiplierModifier then mult += tonumber(trait.MultiplierModifier) or 0 end
        end
        return mult
    end,

    GetFinalGeneration = function(model)
        local module = Script.G.Modules.Animals
        if not module then return 0 end
        local data = module[model.Name]
        if not data then return 0 end
        local baseGen = tonumber(data.Generation) or tonumber(data.Price or 0)
        local traitMult = Script.S.EspBest.GetTraitMultiplier(model)
        local mutationMult = 0
        local mutation = model:GetAttribute("Mutation")
        if mutation and Script.G.Modules.Mutations[mutation] then mutationMult = tonumber(Script.G.Modules.Mutations[mutation].Modifier or 0) end
        return math.max(1, math.round(baseGen * (1 + traitMult + mutationMult)))
    end,

    FindHighest = function()
        local plots = Script.G.Services.Workspace:FindFirstChild("Plots")
        if not plots then return nil end
        local highest = { value = 0 }
        
        for _, plot in pairs(plots:GetChildren()) do
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("YourBase") and not plotSign.YourBase.Enabled then -- Not my base
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("Model") and Script.G.Modules.Animals and Script.G.Modules.Animals[obj.Name] then
                        pcall(function()
                            local gen = Script.S.EspBest.GetFinalGeneration(obj)
                            if gen > 0 and gen > highest.value then
                                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                                if root then
                                    highest = { plot = plot, plotName = plot.Name, petName = obj.Name, generation = gen, formattedValue = Script.G.FormatNumber(gen), model = obj, value = gen }
                                end
                            end
                        end)
                    end
                end
            end
        end
        return highest.value > 0 and highest or nil
    end,

    CreateESP = function(data)
        local model = data.model
        local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA('BasePart')
        if not part then return end

        pcall(function()
            -- Cleanup old
            if Script.S.EspBest.Objects.highlight then Script.S.EspBest.Objects.highlight:Destroy() end
            if Script.S.EspBest.Objects.nameLabel then Script.S.EspBest.Objects.nameLabel:Destroy() end
            if Script.S.EspBest.Objects.box then Script.S.EspBest.Objects.box:Destroy() end
            if Script.S.EspBest.Objects.podium then Script.S.EspBest.Objects.podium:Destroy() end

            -- Highlight
            local highlight = Instance.new("Highlight", model)
            highlight.Name = "BrainrotESPHighlight"
            highlight.Adornee = model
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.6
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            Script.S.EspBest.Objects.highlight = highlight

            -- Box
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "BrainrotBoxHighlight"
            box.Adornee = part
            box.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
            box.Color3 = Color3.fromRGB(255, 0, 0)
            box.Transparency = 0.7
            box.AlwaysOnTop = true
            box.ZIndex = 1
            box.Parent = part
            Script.S.EspBest.Objects.box = box

            -- Billboard
            local billboard = Instance.new("BillboardGui", part)
            billboard.Size = UDim2.new(0, 220, 0, 80)
            billboard.StudsOffset = Vector3.new(0, 8, 0)
            billboard.AlwaysOnTop = true
            
            local container = Instance.new("Frame", billboard)
            container.Size = UDim2.new(1, 0, 1, 0)
            container.BackgroundTransparency = 1

            local nameLabel = Instance.new("TextLabel", container)
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = data.petName
            nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.Arcade
            nameLabel.TextXAlignment = Enum.TextXAlignment.Center
            nameLabel.TextYAlignment = Enum.TextYAlignment.Center

            local genLabel = Instance.new("TextLabel", container)
            genLabel.Size = UDim2.new(1, 0, 0.5, 0)
            genLabel.Position = UDim2.new(0, 0, 0.5, 0)
            genLabel.BackgroundTransparency = 1
            genLabel.Text = data.formattedValue
            genLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            genLabel.TextStrokeTransparency = 0
            genLabel.TextScaled = true
            genLabel.Font = Enum.Font.Arcade
            genLabel.TextXAlignment = Enum.TextXAlignment.Center
            genLabel.TextYAlignment = Enum.TextYAlignment.Center

            Script.S.EspBest.Objects.nameLabel = billboard
            Script.S.EspBest.Data = data

            -- Notification
            if Script.S.EspBest.Enabled then
                local uid = data.petName .. data.formattedValue
                if Script.S.EspBest.LastNotified ~= uid then
                    Script.S.EspBest.LastNotified = uid
                    Script.G.ArcadeUILib:Notify(data.petName .. " " .. data.formattedValue)
                end
            end
        end)
    end,

    RefreshTracer = function()
        if not Script.S.EspBest.Data then return end
        if Script.S.EspBest.Tracer.conn then Script.S.EspBest.Tracer.conn:Disconnect() end
        if Script.S.EspBest.Tracer.beam then Script.S.EspBest.Tracer.beam:Destroy() end
        if Script.S.EspBest.Tracer.att0 then Script.S.EspBest.Tracer.att0:Destroy() end
        if Script.S.EspBest.Tracer.att1 then Script.S.EspBest.Tracer.att1:Destroy() end

        local char = Script.G.Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetPart = Script.S.EspBest.Data.model.PrimaryPart or Script.S.EspBest.Data.model:FindFirstChild("HumanoidRootPart")
        
        if not root or not targetPart then return end

        pcall(function()
            local att0 = Instance.new("Attachment", root)
            local att1 = Instance.new("Attachment", targetPart)
            local beam = Instance.new("Beam")
            beam.Attachment0 = att0
            beam.Attachment1 = att1
            beam.FaceCamera = true
            beam.Width0 = 0.3
            beam.Width1 = 0.3
            beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
            beam.Transparency = NumberSequence.new(0)
            beam.LightEmission = 1
            beam.Parent = root

            local pulseTime = 0
            Script.S.EspBest.Tracer.conn = Script.G.Services.RunService.Heartbeat:Connect(function(dt)
                if Script.S.EspBest.Enabled and beam.Parent then
                    pulseTime += dt
                    local pulse = (math.sin(pulseTime * 3) + 1) / 2
                    beam.Color = ColorSequence.new(Color3.fromRGB(230 + (25*pulse), 0, 0))
                    beam.Width0 = 0.25 + (0.15 * pulse)
                    beam.Width1 = 0.25 + (0.15 * pulse)
                    if targetPart.Parent then att1.Parent = targetPart else Script.S.EspBest.RemoveESP() end
                end
            end)
            Script.S.EspBest.Tracer.beam = beam
            Script.S.EspBest.Tracer.att0 = att0
            Script.S.EspBest.Tracer.att1 = att1
        end)
    end,

    RemoveESP = function()
        if Script.S.EspBest.Objects.highlight then Script.S.EspBest.Objects.highlight:Destroy() end
        if Script.S.EspBest.Objects.nameLabel then Script.S.EspBest.Objects.nameLabel:Destroy() end
        if Script.S.EspBest.Objects.box then Script.S.EspBest.Objects.box:Destroy() end
        if Script.S.EspBest.Objects.podium then Script.S.EspBest.Objects.podium:Destroy() end
        Script.S.EspBest.Objects = {}
        Script.S.EspBest.Data = nil
        if Script.S.EspBest.Tracer.conn then Script.S.EspBest.Tracer.conn:Disconnect() end
        if Script.S.EspBest.Tracer.beam then Script.S.EspBest.Tracer.beam:Destroy() end
        Script.S.EspBest.Tracer = { conn = nil, beam = nil, att0 = nil, att1 = nil }
        Script.S.EspBest.LastNotified = nil
    end,

    Loop = function()
        local lastRefresh = 0
        while Script.S.EspBest.Enabled do
            task.wait(1)
            local newHighest = Script.S.EspBest.FindHighest()
            
            local exists = false
            if Script.S.EspBest.Data and Script.S.EspBest.Data.model and Script.S.EspBest.Data.model.Parent then exists = true end
            
            if not exists then Script.S.EspBest.RemoveESP() end
            
            if newHighest then
                if not Script.S.EspBest.Data or newHighest.value > (Script.S.EspBest.Data.value or 0) then
                    Script.S.EspBest.CreateESP(newHighest)
                    Script.S.EspBest.RefreshTracer()
                end
            end
            
            if tick() - lastRefresh >= 2 then
                Script.S.EspBest.RefreshTracer()
                lastRefresh = tick()
            end
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.EspBest.Enabled then return end
            Script.S.EspBest.Enabled = true
            Script.S.EspBest.Thread = task.spawn(Script.S.EspBest.Loop)
            print("✅ ESP Best ON")
        else
            if not Script.S.EspBest.Enabled then return end
            Script.S.EspBest.Enabled = false
            if Script.S.EspBest.Thread then task.cancel(Script.S.EspBest.Thread) end
            Script.S.EspBest.RemoveESP()
            print("❌ ESP Best OFF")
        end
    end
}

-- ==================== S. BASE LINE ====================
Script.S.BaseLine = {
    Enabled = false,
    Connection = nil,
    BeamPart = nil,
    TargetPart = nil,
    Beam = nil,

    FindPlayerPlot = function()
        local plots = Script.G.Services.Workspace:FindFirstChild("Plots")
        if not plots then return nil, nil end
        local playerBaseName = Script.G.Player.DisplayName .. "'s Base"
        for _, plot in pairs(plots:GetChildren()) do
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("SurfaceGui") then
                local sg = plotSign.SurfaceGui
                if sg.Frame and sg.Frame.TextLabel and sg.Frame.TextLabel.Text == playerBaseName then
                    return plot, plotSign
                end
            end
        end
        return nil, nil
    end,

    CreateLine = function()
        local char = Script.G.Player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local plot, plotSign = Script.S.BaseLine.FindPlayerPlot()
        if not plot or not plotSign then return end

        Script.S.BaseLine.TargetPart = Instance.new("Part")
        Script.S.BaseLine.TargetPart.Name = "PlotLineTarget"
        Script.S.BaseLine.TargetPart.Size = Vector3.new(0.1, 0.1, 0.1)
        Script.S.BaseLine.TargetPart.Position = plotSign.Position
        Script.S.BaseLine.TargetPart.Anchored = true
        Script.S.BaseLine.TargetPart.CanCollide = false
        Script.S.BaseLine.TargetPart.Transparency = 1
        Script.S.BaseLine.TargetPart.Parent = Script.G.Services.Workspace

        Script.S.BaseLine.BeamPart = Instance.new("Part")
        Script.S.BaseLine.BeamPart.Name = "PlotLineBeam"
        Script.S.BaseLine.BeamPart.Size = Vector3.new(0.1, 0.1, 0.1)
        Script.S.BaseLine.BeamPart.Transparency = 1
        Script.S.BaseLine.BeamPart.CanCollide = false
        Script.S.BaseLine.BeamPart.Parent = Script.G.Services.Workspace

        local att0 = Instance.new("Attachment", Script.S.BaseLine.BeamPart)
        local att1 = Instance.new("Attachment", Script.S.BaseLine.TargetPart)

        Script.S.BaseLine.Beam = Instance.new("Beam")
        Script.S.BaseLine.Beam.Attachment0 = att0
        Script.S.BaseLine.Beam.Attachment1 = att1
        Script.S.BaseLine.Beam.FaceCamera = true
        Script.S.BaseLine.Beam.Width0 = 0.3
        Script.S.BaseLine.Beam.Width1 = 0.3
        Script.S.BaseLine.Beam.Color = ColorSequence.new(Color3.fromRGB(100, 0, 0))
        Script.S.BaseLine.Beam.Transparency = NumberSequence.new(0)
        Script.S.BaseLine.Beam.LightEmission = 0.5
        Script.S.BaseLine.Beam.Parent = Script.S.BaseLine.BeamPart

        local pulseTime = 0
        local animConn = Script.G.Services.RunService.Heartbeat:Connect(function(dt)
            if Script.S.BaseLine.Beam and Script.S.BaseLine.Beam.Parent then
                pulseTime += dt
                local pulse = (math.sin(pulseTime * 2) + 1) / 2
                Script.S.BaseLine.Beam.Color = ColorSequence.new(Color3.fromRGB(100 + (155*pulse), 0, 0))
            else animConn:Disconnect() end
        end)

        Script.S.BaseLine.Connection = Script.G.Services.RunService.Heartbeat:Connect(function()
            local c = Script.G.Player.Character
            if c and c:FindFirstChild("HumanoidRootPart") and Script.S.BaseLine.BeamPart then
                Script.S.BaseLine.BeamPart.CFrame = c.HumanoidRootPart.CFrame
            else Script.S.BaseLine.Toggle(false) end
        end)
    end,

    StopLine = function()
        if Script.S.BaseLine.Connection then Script.S.BaseLine.Connection:Disconnect() Script.S.BaseLine.Connection = nil end
        if Script.S.BaseLine.BeamPart then Script.S.BaseLine.BeamPart:Destroy() Script.S.BaseLine.BeamPart = nil end
        if Script.S.BaseLine.TargetPart then Script.S.BaseLine.TargetPart:Destroy() Script.S.BaseLine.TargetPart = nil end
        if Script.S.BaseLine.Beam then Script.S.BaseLine.Beam:Destroy() Script.S.BaseLine.Beam = nil end
    end,

    Toggle = function(state)
        if state then
            if Script.S.BaseLine.Enabled then return end
            Script.S.BaseLine.Enabled = true
            pcall(Script.S.BaseLine.CreateLine)
            print("✅ Base Line ON")
        else
            if not Script.S.BaseLine.Enabled then return end
            Script.S.BaseLine.Enabled = false
            pcall(Script.S.BaseLine.StopLine)
            print("❌ Base Line OFF")
        end
    end
}

-- ==================== S. ANTI TURRET ====================
Script.S.AntiTurret = {
    Enabled = false,
    SentryConn = nil,
    ScanLoop = nil,
    Active = {},
    Processed = {},
    FollowConns = {},
    MyUserId = tostring(Script.G.Player.UserId),

    IsSentryPlaced = function(desc)
        if not desc or not desc.Parent then return false end
        if not desc:IsDescendantOf(Script.G.Services.Workspace) then return false end
        for _, p in pairs(Script.G.Services.Players:GetPlayers()) do
            if p.Character and desc:IsDescendantOf(p.Character) then return false end
        end
        local isAnchored = false
        pcall(function()
            if desc:IsA("Model") and desc.PrimaryPart then isAnchored = desc.PrimaryPart.Anchored
            elseif desc:IsA("BasePart") then isAnchored = desc.Anchored end
        end)
        return isAnchored
    end,

    FindBat = function()
        local tool = Script.G.Player.Backpack:FindFirstChild("Bat")
        if not tool and Script.G.Player.Character then tool = Script.G.Player.Character:FindFirstChild("Bat") end
        return tool
    end,

    UpdateSentryPos = function(desc)
        local char = Script.G.Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local spawnOffset = hrp.CFrame.LookVector * 3.5 + Vector3.new(0, 1.2, 0)
        pcall(function()
            if desc:IsA("Model") and desc.PrimaryPart then desc:SetPrimaryPartCFrame(hrp.CFrame + spawnOffset)
            elseif desc:IsA("BasePart") then desc.CFrame = hrp.CFrame + spawnOffset end
            for _, part in pairs(desc:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
        end)
    end,

    AttackSentry = function(desc)
        if not Script.S.AntiTurret.Enabled then return end
        if Script.S.AntiTurret.Active[desc] or Script.S.AntiTurret.Processed[desc] then return end
        if desc.Name:find(Script.S.AntiTurret.MyUserId) then Script.S.AntiTurret.Processed[desc] = true return end
        
        Script.S.AntiTurret.Active[desc] = true
        Script.S.AntiTurret.Processed[desc] = true

        local running = true
        local followConn

        local function stopAttack()
            running = false
            if followConn then followConn:Disconnect() Script.S.AntiTurret.FollowConns[desc] = nil end
            Script.S.AntiTurret.Active[desc] = nil
            Script.S.AntiTurret.FindBat().Parent = Script.G.Player.Backpack -- Unequip
        end

        local destroyConn = desc.AncestryChanged:Connect(function()
            if not desc.Parent then stopAttack() end
        end)

        followConn = Script.G.Services.RunService.RenderStepped:Connect(function()
            if not running or not desc.Parent then stopAttack() return end
            Script.S.AntiTurret.UpdateSentryPos(desc)
        end)
        Script.S.AntiTurret.FollowConns[desc] = followConn

        task.spawn(function()
            while running and Script.S.AntiTurret.Enabled and desc.Parent do
                local bat = Script.S.AntiTurret.FindBat()
                if bat then
                    if bat.Parent ~= Script.G.Player.Character then Script.G.Player.Character.Humanoid:EquipTool(bat) end
                    for i=1, 12 do if desc.Parent and bat.Parent == Script.G.Player.Character then bat:Activate() else break end end
                end
                task.wait(0.05)
            end
            stopAttack()
        end)
    end,

    Scan = function()
        if not Script.S.AntiTurret.Enabled then return end
        for _, desc in pairs(Script.G.Services.Workspace:GetDescendants()) do
            if desc.Name:lower():find("sentry") and Script.S.AntiTurret.IsSentryPlaced(desc) and not Script.S.AntiTurret.Processed[desc] and not desc.Name:find(Script.S.AntiTurret.MyUserId) then
                Script.S.AntiTurret.UpdateSentryPos(desc)
                Script.S.AntiTurret.AttackSentry(desc)
            end
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.AntiTurret.Enabled then return end
            Script.S.AntiTurret.Enabled = true
            
            Script.S.AntiTurret.SentryConn = Script.G.Services.Workspace.DescendantAdded:Connect(function(desc)
                if not Script.S.AntiTurret.Enabled then return end
                if desc.Name:lower():find("sentry") and not desc.Name:find(Script.S.AntiTurret.MyUserId) then
                    task.wait(0.5)
                    if Script.S.AntiTurret.IsSentryPlaced(desc) and not Script.S.AntiTurret.Processed[desc] then
                        Script.S.AntiTurret.UpdateSentryPos(desc)
                        Script.S.AntiTurret.AttackSentry(desc)
                    end
                end
            end)

            Script.S.AntiTurret.ScanLoop = task.spawn(function()
                while Script.S.AntiTurret.Enabled do
                    Script.S.AntiTurret.Scan()
                    task.wait(5)
                end
            end)
            print("✅ Anti Turret ON")
        else
            if not Script.S.AntiTurret.Enabled then return end
            Script.S.AntiTurret.Enabled = false
            if Script.S.AntiTurret.SentryConn then Script.S.AntiTurret.SentryConn:Disconnect() end
            if Script.S.AntiTurret.ScanLoop then task.cancel(Script.S.AntiTurret.ScanLoop) end
            for _, c in pairs(Script.S.AntiTurret.FollowConns) do if c then c:Disconnect() end end
            Script.S.AntiTurret.FollowConns = {}
            Script.S.AntiTurret.Active = {}
            Script.S.AntiTurret.Processed = {}
            print("❌ Anti Turret OFF")
        end
    end
}

-- ==================== S. AIMBOT ====================
Script.S.Aimbot = {
    Enabled = false,
    Thread = nil,
    Blacklist = { ["alex4eva"]=true, ["jkxkelu"]=true, ["BigTulaH"]=true, ["xxxdedmoth"]=true, ["JokiTablet"]=true, ["sleepkola"]=true, ["Aimbot36022"]=true, ["Djrjdjdk0"]=true, ["elsodidudujd"]=true, ["SENSEIIIlSALT"]=true, ["yaniecky"]=true, ["ISAAC_EVO"]=true, ["7xc_ls"]=true, ["itz_d1egx"]=true },

    GetNearest = function()
        if not Script.G.Player.Character then return nil end
        local myRoot = Script.G.Player.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        
        local nearest, dist = nil, math.huge
        for _, p in pairs(Script.G.Services.Players:GetPlayers()) do
            if p ~= Script.G.Player and p.Character and not Script.S.Aimbot.Blacklist[p.Name:lower()] then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (Vector3.new(hrp.Position.X,0,hrp.Position.Z) - Vector3.new(myRoot.Position.X,0,myRoot.Position.Z)).Magnitude
                    if d < dist then dist = d nearest = p end
                end
            end
        end
        return nearest
    end,

    Worker = function()
        while Script.S.Aimbot.Enabled do
            local target = Script.S.Aimbot.GetNearest()
            if target and target.Character then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local remote = Script.G.Services.ReplicatedStorage:FindFirstChild("Packages"):FindFirstChild("Net"):FindFirstChild("RE/UseItem") or Script.G.Services.ReplicatedStorage:FindFirstChild("RE/UseItem")
                    if remote then remote:FireServer(hrp.Position, hrp) end
                end
            end
            task.wait(0.6)
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.Aimbot.Enabled then return end
            Script.S.Aimbot.Enabled = true
            Script.S.Aimbot.Thread = task.spawn(Script.S.Aimbot.Worker)
            print("✅ Aimbot ON")
        else
            if not Script.S.Aimbot.Enabled then return end
            Script.S.Aimbot.Enabled = false
            if Script.S.Aimbot.Thread then task.cancel(Script.S.Aimbot.Thread) end
            print("❌ Aimbot OFF")
        end
    end
}

-- ==================== S. KICK STEAL ====================
Script.S.KickSteal = {
    Enabled = false,
    Connection = nil,
    LastCount = 0,

    GetCount = function()
        local res = pcall(function()
            local ls = Script.G.Player:FindFirstChild("leaderstats")
            local s = ls and ls:FindFirstChild("Steals")
            return s and (typeof(s.Value) == "number" and s.Value or tonumber(s.Value)) or 0
        end)
        return res or 0
    end,

    Loop = function()
        while Script.S.KickSteal.Enabled do
            local curr = Script.S.KickSteal.GetCount()
            if curr > Script.S.KickSteal.LastCount then
                Script.G.Player:Kick("Steal Success!")
            end
            Script.S.KickSteal.LastCount = curr
            task.wait(0.5)
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.KickSteal.Enabled then return end
            Script.S.KickSteal.Enabled = true
            Script.S.KickSteal.LastCount = Script.S.KickSteal.GetCount()
            Script.S.KickSteal.Connection = task.spawn(Script.S.KickSteal.Loop)
            print("✅ Kick Steal ON")
        else
            if not Script.S.KickSteal.Enabled then return end
            Script.S.KickSteal.Enabled = false
            if Script.S.KickSteal.Connection then task.cancel(Script.S.KickSteal.Connection) end
            print("❌ Kick Steal OFF")
        end
    end
}

-- ==================== S. UNWALK ANIM ====================
Script.S.UnwalkAnim = {
    Enabled = false,
    Connections = {},

    Setup = function(char)
        local hum = char:WaitForChild("Humanoid")
        local anim = hum:WaitForChild("Animator")
        local function stop()
            for _, t in pairs(anim:GetPlayingAnimationTracks()) do t:Stop() end
        end
        
        table.insert(Script.S.UnwalkAnim.Connections, hum.Running:Connect(stop))
        table.insert(Script.S.UnwalkAnim.Connections, hum.Jumping:Connect(stop))
        table.insert(Script.S.UnwalkAnim.Connections, anim.AnimationPlayed:Connect(function(t) t:Stop() end))
        table.insert(Script.S.UnwalkAnim.Connections, Script.G.Services.RunService.RenderStepped:Connect(stop))
    end,

    Toggle = function(state)
        if state then
            if Script.S.UnwalkAnim.Enabled then return end
            Script.S.UnwalkAnim.Enabled = true
            if Script.G.Player.Character then Script.S.UnwalkAnim.Setup(Script.G.Player.Character) end
            print("✅ Unwalk Anim ON")
        else
            if not Script.S.UnwalkAnim.Enabled then return end
            Script.S.UnwalkAnim.Enabled = false
            for _, c in pairs(Script.S.UnwalkAnim.Connections) do if c then c:Disconnect() end end
            Script.S.UnwalkAnim.Connections = {}
            print("❌ Unwalk Anim OFF")
        end
    end
}

-- ==================== S. AUTO STEAL ====================
Script.S.AutoSteal = {
    Enabled = false,
    Connection = nil,
    Cache = {},
    Prompts = {},
    Internal = {},
    Radius = 20,

    IsMyBase = function(animalData)
        if not animalData.plot then return false end
        local plot = Script.G.Services.Workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return false end
        local channel = Script.G.Modules.Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == Script.G.Player.UserId end
        end
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yb = sign:FindFirstChild("YourBase")
            if yb and yb:IsA("BillboardGui") then return yb.Enabled end
        end
        return false
    end,

    FindPrompt = function(animalData)
        local plot = Script.G.Services.Workspace.Plots:FindFirstChild(animalData.plot)
        if not plot then return nil end
        local p = plot:FindFirstChild("AnimalPodiums")
        if not p then return nil end
        local pod = p:FindFirstChild(animalData.slot)
        if not pod then return nil end
        local base = pod:FindFirstChild("Base")
        if not base then return nil end
        local spawn = base:FindFirstChild("Spawn")
        if not spawn then return nil end
        local attach = spawn:FindFirstChild("PromptAttachment")
        if not attach then return nil end
        
        for _, v in ipairs(attach:GetChildren()) do
            if v:IsA("ProximityPrompt") then
                Script.S.AutoSteal.Prompts[animalData.uid] = v
                return v
            end
        end
        return nil
    end,

    GetNearest = function()
        local char = Script.G.Player.Character
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local nearest, dist = nil, math.huge
        
        for _, d in ipairs(Script.S.AutoSteal.Cache) do
            if not Script.S.AutoSteal.IsMyBase(d) then
                local plot = Script.G.Services.Workspace.Plots:FindFirstChild(d.plot)
                local pod = plot and plot:FindFirstChild("AnimalPodiums"):FindFirstChild(d.slot)
                if pod then
                    local pDist = (hrp.Position - pod:GetPivot().Position).Magnitude
                    if pDist < dist then dist = pDist nearest = d end
                end
            end
        end
        return nearest
    end,

    ScanPlots = function()
        local plots = Script.G.Services.Workspace:FindFirstChild("Plots")
        if not plots then return end
        local newCache = {}
        
        for _, plot in ipairs(plots:GetChildren()) do
            local channel = Script.G.Modules.Synchronizer:Get(plot.Name)
            if not channel then continue end
            local animalList = channel:Get("AnimalList")
            local owner = channel:Get("Owner")
            
            for slot, data in pairs(animalList) do
                if type(data) == "table" then
                    local animalName = data.Index
                    local gen = Script.G.Modules.Shared:GetGeneration(animalName, data.Mutation, data.Traits, nil)
                    
                    table.insert(newCache, {
                        name = animalName,
                        genValue = gen,
                        plot = plot.Name,
                        slot = tostring(slot),
                        uid = plot.Name.."_"..tostring(slot)
                    })
                end
            end
        end
        Script.S.AutoSteal.Cache = newCache
        table.sort(Script.S.AutoSteal.Cache, function(a,b) return a.genValue > b.genValue end)
    end,

    ExecuteSteal = function(prompt)
        if not prompt or not prompt.Parent then return false end
        local data = Script.S.AutoSteal.Internal[prompt]
        if not data then
            data = { hold = {}, trigger = {}, ready = true }
            local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
            if ok1 then for _, c in ipairs(c1) do if type(c.Function)=="function" then table.insert(data.hold, c.Function) end end end
            local ok2, c2 = pcall(getconnections, prompt.Triggered)
            if ok2 then for _, c in ipairs(c2) do if type(c.Function)=="function" then table.insert(data.trigger, c.Function) end end end
            Script.S.AutoSteal.Internal[prompt] = data
        end
        
        if not data.ready then return true end
        data.ready = false
        task.spawn(function()
            for _, f in ipairs(data.hold) do task.spawn(f) end
            task.wait(1.3)
            for _, f in ipairs(data.trigger) do task.spawn(f) end
            task.wait(0.1)
            data.ready = true
        end)
        return true
    end,

    Loop = function()
        while Script.S.AutoSteal.Enabled do
            local target = Script.S.AutoSteal.GetNearest()
            if target then
                local hrp = Script.G.Player.Character:FindFirstChild("HumanoidRootPart")
                local plot = Script.G.Services.Workspace.Plots:FindFirstChild(target.plot)
                local pod = plot and plot:FindFirstChild("AnimalPodiums"):FindFirstChild(target.slot)
                if hrp and pod then
                    local dist = (hrp.Position - pod:GetPivot().Position).Magnitude
                    if dist <= Script.S.AutoSteal.Radius then
                        local prompt = Script.S.AutoSteal.Prompts[target.uid] or Script.S.AutoSteal.FindPrompt(target)
                        if prompt then Script.S.AutoSteal.ExecuteSteal(prompt) end
                    end
                end
            end
            task.wait(0.2)
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.AutoSteal.Enabled then return end
            Script.S.AutoSteal.Enabled = true
            Script.S.AutoSteal.Connection = task.spawn(Script.S.AutoSteal.Loop)
            print("✅ Auto Steal ON")
        else
            if not Script.S.AutoSteal.Enabled then return end
            Script.S.AutoSteal.Enabled = false
            if Script.S.AutoSteal.Connection then task.cancel(Script.S.AutoSteal.Connection) end
            print("❌ Auto Steal OFF")
        end
    end
}

-- ==================== S. ANTI DEBUFF ====================
Script.S.AntiDebuff = {
    Bee = false, Boogie = false,
    HandlerActive = false,
    UnifiedConn = nil,
    Conns = {},
    AnimConn = nil,
    HbConn = nil,
    BoogieID = "109061983885712",

    UpdateHandler = function()
        local remote = pcall(function() return Script.G.Modules.Net:RemoteEvent("UseItem") end)
        if not remote then return end

        if not Script.S.AntiDebuff.Bee and not Script.S.AntiDebuff.Boogie then
            if Script.S.AntiDebuff.HandlerActive then
                if Script.S.AntiDebuff.UnifiedConn then Script.S.AntiDebuff.UnifiedConn:Disconnect() end
                for _, c in pairs(Script.S.AntiDebuff.Conns) do pcall(function() c:Enable() end) end
                Script.S.AntiDebuff.HandlerActive = false
            end
            return
        end

        if (Script.S.AntiDebuff.Bee or Script.S.AntiDebuff.Boogie) and not Script.S.AntiDebuff.HandlerActive then
            for i, v in pairs(getconnections(remote.OnClientEvent)) do table.insert(Script.S.AntiDebuff.Conns, v) pcall(function() v:Disable() end) end
            Script.S.AntiDebuff.UnifiedConn = remote.OnClientEvent:Connect(function(action, ...)
                if Script.S.AntiDebuff.Bee and action == "Bee Attack" then return end
                if Script.S.AntiDebuff.Boogie and action == "Boogie" then return end
            end)
            Script.S.AntiDebuff.HandlerActive = true
        end
    end,

    Monitor = function()
        while Script.S.AntiDebuff.Bee or Script.S.AntiDebuff.Boogie do
            if Script.G.Services.Lighting:FindFirstChild("DiscoEffect") then Script.G.Services.Lighting:FindFirstChild("DiscoEffect"):Destroy() end
            for _, v in pairs(Script.G.Services.Lighting:GetChildren()) do if v:IsA("BlurEffect") then v:Destroy() end end
            task.wait(0.1)
        end
    end,

    Toggle = function(state)
        if state then
            Script.S.AntiDebuff.Bee = true
            Script.S.AntiDebuff.Boogie = true
            
            if Script.S.AntiDebuff.HbConn then Script.S.AntiDebuff.HbConn:Disconnect() end
            Script.S.AntiDebuff.HbConn = task.spawn(Script.S.AntiDebuff.Monitor)

            local anim = Script.G.Player.Character and Script.G.Player.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
            if anim then
                Script.S.AntiDebuff.AnimConn = anim.AnimationPlayed:Connect(function(t)
                    if tostring(t.Animation.AnimationId):gsub("%D","") == Script.S.AntiDebuff.BoogieID then t:Stop() t:Destroy() end
                end)
            end
            
            Script.S.AntiDebuff.UpdateHandler()
            print("✅ Anti Debuff ON")
        else
            Script.S.AntiDebuff.Bee = false
            Script.S.AntiDebuff.Boogie = false
            if Script.S.AntiDebuff.UnifiedConn then Script.S.AntiDebuff.UnifiedConn:Disconnect() end
            if Script.S.AntiDebuff.AnimConn then Script.S.AntiDebuff.AnimConn:Disconnect() end
            if Script.S.AntiDebuff.HbConn then task.cancel(Script.S.AntiDebuff.HbConn) end
            Script.S.AntiDebuff.UpdateHandler()
            print("❌ Anti Debuff OFF")
        end
    end
}

-- ==================== S. ANTI RAGDOLL ====================
Script.S.AntiRagdoll = {
    Enabled = false,
    Connections = {},
    Cached = {},

    CacheChar = function()
        local char = Script.G.Player.Character
        if not char then return false end
        Script.S.AntiRagdoll.Cached = {
            char = char,
            hum = char:FindFirstChildOfClass("Humanoid"),
            root = char:FindFirstChild("HumanoidRootPart")
        }
        return true
    end,

    IsRagdolled = function()
        if not Script.S.AntiRagdoll.Cached.hum then return false end
        local state = Script.S.AntiRagdoll.Cached.hum:GetState()
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then return true end
        local endTime = Script.G.Player:GetAttribute("RagdollEndTime")
        if endTime and (endTime - Script.G.Services.Workspace:GetServerTimeNow()) > 0 then return true end
        return false
    end,

    RemoveRagdoll = function()
        local c = Script.S.AntiRagdoll.Cached.char
        if not c then return end
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BallSocketConstraint") or (v:IsA("Attachment") and v.Name:find("RagdollAttachment")) then
                pcall(function() v:Destroy() end)
            end
        end
    end,

    ForceExit = function()
        local hum = Script.S.AntiRagdoll.Cached.hum
        local root = Script.S.AntiRagdoll.Cached.root
        if not hum or not root then return end
        Script.G.Player:SetAttribute("RagdollEndTime", 0)
        if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
    end,

    Loop = function()
        while Script.S.AntiRagdoll.Enabled do
            task.wait()
            if Script.S.AntiRagdoll.IsRagdolled() then
                Script.S.AntiRagdoll.RemoveRagdoll()
                Script.S.AntiRagdoll.ForceExit()
            end
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.AntiRagdoll.Enabled then return end
            Script.S.AntiRagdoll.Enabled = true
            Script.S.AntiRagdoll.CacheChar()
            table.insert(Script.S.AntiRagdoll.Connections, Script.G.Services.RunService.RenderStepped:Connect(function()
                if not Script.S.AntiRagdoll.Enabled then return end
                local cam = Script.G.Services.Workspace.CurrentCamera
                if cam and Script.S.AntiRagdoll.Cached.hum and cam.CameraSubject ~= Script.S.AntiRagdoll.Cached.hum then
                    cam.CameraSubject = Script.S.AntiRagdoll.Cached.hum
                end
            end))
            table.insert(Script.S.AntiRagdoll.Connections, Script.G.Player.CharacterAdded:Connect(function(c)
                task.wait(0.5) Script.S.AntiRagdoll.CacheChar() task.spawn(Script.S.AntiRagdoll.Loop) end))
            task.spawn(Script.S.AntiRagdoll.Loop)
            print("✅ Anti Ragdoll ON")
        else
            if not Script.S.AntiRagdoll.Enabled then return end
            Script.S.AntiRagdoll.Enabled = false
            for _, c in pairs(Script.S.AntiRagdoll.Connections) do pcall(function() c:Disconnect() end) end
            Script.S.AntiRagdoll.Connections = {}
            print("❌ Anti Ragdoll OFF")
        end
    end
}

-- ==================== S. XRAY BASE ====================
Script.S.XrayBase = {
    Enabled = false,
    Loaded = false,
    Original = {},
    Conn = nil,

    IsBaseWall = function(obj)
        if not obj:IsA("BasePart") then return false end
        return obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))
    end,

    Apply = function()
        local plots = Script.G.Services.Workspace:FindFirstChild("Plots")
        if not plots then return end
        for _, plot in pairs(plots:GetChildren()) do
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and Script.S.XrayBase.IsBaseWall(obj) then
                    if not Script.S.XrayBase.Original[obj] then
                        Script.S.XrayBase.Original[obj] = obj.LocalTransparencyModifier
                        obj.LocalTransparencyModifier = 0.85
                    end
                end
            end
        end
        Script.S.XrayBase.Loaded = true
    end,

    Restore = function()
        for obj, val in pairs(Script.S.XrayBase.Original) do
            if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = val end) end
        end
        Script.S.XrayBase.Original = {}
        Script.S.XrayBase.Loaded = false
    end,

    Toggle = function(state)
        if state then
            if Script.S.XrayBase.Enabled then return end
            Script.S.XrayBase.Enabled = true
            Script.S.XrayBase.Apply()
            Script.S.XrayBase.Conn = Script.G.Services.Workspace.DescendantAdded:Connect(function(obj)
                if not Script.S.XrayBase.Enabled then return end
                task.wait(0.1)
                if Script.S.XrayBase.IsBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
                    if not Script.S.XrayBase.Original[obj] then
                        Script.S.XrayBase.Original[obj] = obj.LocalTransparencyModifier
                        obj.LocalTransparencyModifier = 0.85
                    end
                end
            end)
            print("✅ Xray Base ON")
        else
            if not Script.S.XrayBase.Enabled then return end
            Script.S.XrayBase.Enabled = false
            if Script.S.XrayBase.Conn then Script.S.XrayBase.Conn:Disconnect() end
            Script.S.XrayBase.Restore()
            print("❌ Xray Base OFF")
        end
    end
}

-- ==================== S. FPS BOOST (FULL LOGIC) ====================
Script.S.FpsBoost = {
    Enabled = false,
    Threads = {},
    Conns = {},
    Original = {},

    PERFORMANCE_FFLAGS = {
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
    },

    NukeVisuals = function()
        pcall(function()
            for _, obj in ipairs(Script.G.Services.Workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") then obj.Rate = 0 obj:Destroy()
                    elseif obj:IsA("Trail") then obj:Destroy()
                    elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then obj:Destroy()
                    elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then obj:Destroy()
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        if not (obj.Name == "face" and obj.Parent and obj.Parent.Name == "Head") then obj.Transparency = 1 end
                    elseif obj:IsA("BasePart") then obj.CastShadow = false obj.Material = Enum.Material.Plastic end
                end)
            end
        end)
    end,

    OptimizeChar = function(char)
        if not char then return end
        task.spawn(function()
            task.wait(0.5)
            pcall(function()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CastShadow = false part.Material = Enum.Material.Plastic
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("PointLight") or part:IsA("Fire") then part:Destroy() end
                end
            end)
        end)
    end,

    Toggle = function(state)
        if state then
            if Script.S.FpsBoost.Enabled then return end
            Script.S.FpsBoost.Enabled = true
            getgenv().OPTIMIZER_ACTIVE = true
            
            -- Store Settings
            pcall(function()
                Script.S.FpsBoost.Original = {
                    streamingEnabled = Script.G.Services.Workspace.StreamingEnabled,
                    qualityLevel = settings().Rendering.QualityLevel,
                    shadows = Script.G.Services.Lighting.GlobalShadows,
                    tech = Script.G.Services.Lighting.Technology,
                    brightness = Script.G.Services.Lighting.Brightness,
                    waterWave = Script.G.Services.Workspace.Terrain.WaterWaveSize,
                    decoration = Script.G.Services.Workspace.Terrain.Decoration
                }
            end)

            -- Apply FFlags
            for flag, val in pairs(Script.S.FpsBoost.PERFORMANCE_FFLAGS) do pcall(function() setfflag(flag, tostring(val)) end) end

            -- Apply Settings
            pcall(function()
                Script.G.Services.Workspace.StreamingEnabled = true
                Script.G.Services.Workspace.StreamingMinRadius = 64
                Script.G.Services.Workspace.StreamingTargetRadius = 256
                settings().Rendering.QualityLevel = 1
                Script.G.Services.Lighting.GlobalShadows = false
                Script.G.Services.Lighting.Technology = Enum.Technology.Legacy
                Script.G.Services.Lighting.Brightness = 3
                Script.G.Services.Lighting.FogEnd = 9e9
                Script.G.Services.Workspace.Terrain.WaterWaveSize = 0
                Script.G.Services.Workspace.Terrain.Decoration = false
                setfpscap(999)
            end)

            -- Threads
            table.insert(Script.S.FpsBoost.Threads, task.spawn(Script.S.FpsBoost.NukeVisuals))
            table.insert(Script.S.FpsBoost.Conns, Script.G.Services.Workspace.DescendantAdded:Connect(function(obj)
                if not getgenv().OPTIMIZER_ACTIVE then return end
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Explosion") then obj:Destroy()
                    elseif obj:IsA("BasePart") then obj.CastShadow = false end
                end)
            end))
            
            for _, p in ipairs(Script.G.Services.Players:GetPlayers()) do
                if p.Character then Script.S.FpsBoost.OptimizeChar(p.Character) end
                table.insert(Script.S.FpsBoost.Conns, p.CharacterAdded:Connect(function(c) Script.S.FpsBoost.OptimizeChar(c) end))
            end
            table.insert(Script.S.FpsBoost.Conns, Script.G.Services.Players.PlayerAdded:Connect(function(p)
                table.insert(Script.S.FpsBoost.Conns, p.CharacterAdded:Connect(function(c) Script.S.FpsBoost.OptimizeChar(c) end))
            end))

            print("✅ Fps Boost ON")
        else
            if not Script.S.FpsBoost.Enabled then return end
            Script.S.FpsBoost.Enabled = false
            getgenv().OPTIMIZER_ACTIVE = false
            
            for _, t in ipairs(Script.S.FpsBoost.Threads) do pcall(function() task.cancel(t) end) end
            for _, c in ipairs(Script.S.FpsBoost.Conns) do pcall(function() c:Disconnect() end) end
            
            pcall(function()
                Script.G.Services.Workspace.StreamingEnabled = Script.S.FpsBoost.Original.streamingEnabled
                settings().Rendering.QualityLevel = Script.S.FpsBoost.Original.qualityLevel
                Script.G.Services.Lighting.GlobalShadows = Script.S.FpsBoost.Original.shadows
                Script.G.Services.Lighting.Technology = Script.S.FpsBoost.Original.tech
                Script.G.Services.Lighting.Brightness = Script.S.FpsBoost.Original.brightness
                Script.G.Services.Workspace.Terrain.WaterWaveSize = Script.S.FpsBoost.Original.waterWave
                Script.G.Services.Workspace.Terrain.Decoration = Script.S.FpsBoost.Original.decoration
            end)
            print("❌ Fps Boost OFF")
        end
    end
}

-- ==================== S. ESP TIMER ====================
Script.S.EspTimer = {
    Enabled = false,
    Connections = {},

    UpdateBillboard = function(part, txt, show, isUnlocked)
        local gui = part:FindFirstChild("RemainingTimeGui")
        if show then
            if not gui then
                gui = Instance.new("BillboardGui", part)
                gui.Name = "RemainingTimeGui"
                gui.Size = UDim2.new(0, 110, 0, 25)
                gui.StudsOffset = Vector3.new(0, 5, 0)
                gui.AlwaysOnTop = true
                local lbl = Instance.new("TextLabel", gui)
                lbl.Name = "Text"
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextScaled = true
                lbl.Font = Enum.Font.GothamBold
            end
            gui.Text.Text = txt
            gui.Text.TextColor3 = isUnlocked and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
        else
            if gui then gui:Destroy() end
        end
    end,

    Scan = function()
        for _, plot in pairs(Script.G.Services.Workspace.Plots:GetChildren()) do
            local purchases = plot:FindFirstChild("Purchases")
            if purchases then
                local lowest = nil
                local lowestY = nil
                for _, p in pairs(purchases:GetChildren()) do
                    local main = p:FindFirstChild("Main")
                    local gui = main and main:FindFirstChild("BillboardGui")
                    local rem = gui and gui:FindFirstChild("RemainingTime")
                    local locked = gui and gui:FindFirstChild("Locked")
                    if main and rem and locked then
                        if not lowestY or main.Position.Y < lowestY then lowest = {rem=rem, locked=locked, main=main} lowestY = main.Position.Y end
                    end
                end
                for _, p in pairs(purchases:GetChildren()) do
                    local main = p:FindFirstChild("Main")
                    local gui = main and main:FindFirstChild("BillboardGui")
                    local rem = gui and gui:FindFirstChild("RemainingTime")
                    local locked = gui and gui:FindFirstChild("Locked")
                    if main and rem and locked then
                        local isTarget = (lowest and rem == lowest.rem)
                        local isUnlocked = not locked.Visible
                        Script.S.EspTimer.UpdateBillboard(main, isUnlocked and "Unlocked" or rem.Text, isTarget, isUnlocked)
                    end
                end
            end
        end
    end,

    Toggle = function(state)
        if state then
            if Script.S.EspTimer.Enabled then return end
            Script.S.EspTimer.Enabled = true
            Script.S.EspTimer.Connections.loop = task.spawn(function()
                while Script.S.EspTimer.Enabled do Script.S.EspTimer.Scan() task.wait(5) end
            end)
            print("✅ Esp Timer ON")
        else
            if not Script.S.EspTimer.Enabled then return end
            Script.S.EspTimer.Enabled = false
            -- Cleanup guis
            for _, plot in pairs(Script.G.Services.Workspace.Plots:GetChildren()) do
                local pur = plot:FindFirstChild("Purchases")
                if pur then
                    for _, p in pairs(pur:GetChildren()) do
                        local m = p:FindFirstChild("Main")
                        if m then
                            local g = m:FindFirstChild("RemainingTimeGui")
                            if g then g:Destroy() end
                        end
                    end
                end
            end
            if Script.S.EspTimer.Connections.loop then task.cancel(Script.S.EspTimer.Connections.loop) end
            print("❌ Esp Timer OFF")
        end
    end
}

-- ==================== GLOBAL EVENT HANDLERS ====================
Script.G.Services.Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        task.wait(1)
        if Script.S.EspPlayers.Enabled then Script.S.EspPlayers.Create(p) end
    end)
end)

Script.G.Services.Players.PlayerRemoving:Connect(function(p)
    Script.S.EspPlayers.Remove(p)
end)

Script.G.Player.CharacterAdded:Connect(function(c)
    task.wait(1)
    if Script.S.EspPlayers.Enabled then for _, p in pairs(Script.G.Services.Players:GetPlayers()) do if p ~= Script.G.Player then Script.S.EspPlayers.Create(p) end end end
    if Script.S.BaseLine.Enabled then pcall(function() Script.S.BaseLine.StopLine() Script.S.BaseLine.CreateLine() end) end
    if Script.S.AntiTurret.Enabled then Script.S.AntiTurret.Toggle(false) task.wait(0.5) Script.S.AntiTurret.Toggle(true) end
    if Script.S.Aimbot.Enabled then Script.S.Aimbot.Toggle(false) task.wait(0.5) Script.S.Aimbot.Toggle(true) end
    if Script.S.UnwalkAnim.Enabled then Script.S.UnwalkAnim.Setup(c) end
    if Script.S.AntiDebuff.Boogie then
        local anim = c:WaitForChild("Humanoid"):WaitForChild("Animator")
        Script.S.AntiDebuff.AnimConn = anim.AnimationPlayed:Connect(function(t)
            if tostring(t.Animation.AnimationId):gsub("%D","") == Script.S.AntiDebuff.BoogieID then t:Stop() t:Destroy() end
        end)
    end
    if Script.S.AntiRagdoll.Enabled then Script.S.AntiRagdoll.CacheChar() end
    if Script.S.XrayBase.Enabled then Script.S.XrayBase.Apply() end
    if Script.S.FpsBoost.Enabled then
        for _, p in ipairs(Script.G.Services.Players:GetPlayers()) do if p.Character then Script.S.FpsBoost.OptimizeChar(p.Character) end end
    end
end)

Script.G.Player.CharacterRemoving:Connect(function()
    if Script.S.BaseLine.Enabled then Script.S.BaseLine.StopLine() end
end)

task.spawn(function()
    while task.wait(5) do Script.S.AutoSteal.ScanPlots() end
end)

-- ==================== UI SETUP ====================
Script.G.ArcadeUILib:CreateUI()
Script.G.ArcadeUILib:Notify("Modular Hub Loaded")

Script.G.ArcadeUILib:AddToggleRow("Esp Players", function(s) Script.S.EspPlayers.Toggle(s) end, "Esp Best", function(s) Script.S.EspBest.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Base Line", function(s) Script.S.BaseLine.Toggle(s) end, "Anti Turret", function(s) Script.S.AntiTurret.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Aimbot", function(s) Script.S.Aimbot.Toggle(s) end, "Kick Steal", function(s) Script.S.KickSteal.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Unwalk Anim", function(s) Script.S.UnwalkAnim.Toggle(s) end, "Auto Steal", function(s) Script.S.AutoSteal.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Anti Debuff", function(s) Script.S.AntiDebuff.Toggle(s) end, "Anti Rdoll", function(s) Script.S.AntiRagdoll.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Xray Base", function(s) Script.S.XrayBase.Toggle(s) end, "Fps Boost", function(s) Script.S.FpsBoost.Toggle(s) end)
Script.G.ArcadeUILib:AddToggleRow("Esp Timer", function(s) Script.S.EspTimer.Toggle(s) end, "", nil)

print("🎮 Full Modular Code Loaded (G. & S. Pattern) - FIXED")

-- ==================== EXTERNAL LOADER (PROTECTED) ====================
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Sabstealtoolsv1.lua"))()
end)
