if not game:IsLoaded() then game.Loaded:Wait() end
pcall(function() game:GetService("Players").RespawnTime = 0 end)

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    GuiService = game:GetService("GuiService"),
    TeleportService = game:GetService("TeleportService"),
    Stats = game:GetService("Stats"),
}
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local Workspace = Services.Workspace
local Lighting = Services.Lighting
local VirtualInputManager = Services.VirtualInputManager
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local Stats = Services.Stats
local LocalPlayer = Players.LocalPlayer

local FileName = "RenPrivate_v1.json"
local DefaultConfig = {
    Positions = {
        CreditFrame = {X = 0.5, Y = 0.065},
    },
    Favorites = {
        Animals = {},
    },
    Keybinds = {
        CloneKey       = "V",
        CarpetSpeedKey = "Q",
        HopKey         = "H",
        RejoinKey      = "R",
        SettingsKey    = "M",
        KickSelfKey    = "X",
        ResetKey       = "T",
    },
    Settings           = false,
    LockGui            = false,
    RemoveError        = false,
    Nearest            = false,
    HideStealerPanel   = false,
    StealHighest       = false,
    StealPriority      = false,
    AutoKickOnSteal    = false,
    AutoDestroyTurrets = false,
    AutoBuy            = false,
    ESPPlayers         = false,
    PlotBeam           = false,
    Optimizer          = false,
    AnimDisabler       = false,
    InfJump            = false,
    XrayBase           = false,
    CarpetSpeed        = false,
    CarpetSpeedValue   = 140,
    CarpetTool         = "Flying Carpet",
    AntiLag            = false,
    StealSpeed         = false,
    StealSpeedValue    = 28,
    AutoResetOnBalloon = false,
}

local Config = DefaultConfig

if isfile and isfile(FileName) then
    pcall(function()
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(FileName))
        end)
        if not ok then return end
        for k, v in pairs(DefaultConfig) do
            if decoded[k] == nil then
                decoded[k] = v
            elseif type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if decoded[k][k2] == nil then
                        decoded[k][k2] = v2
                    end
                end
            end
        end
        Config = decoded
    end)
end

local function SaveConfig()
    if writefile then
        pcall(function()
            local toSave = {}
            for k, v in pairs(Config) do
                toSave[k] = v
            end
            writefile(FileName, HttpService:JSONEncode(toSave))
        end)
    end
end

local C = {
    white        = Color3.fromRGB(255, 255, 255),
    black        = Color3.fromRGB(0, 0, 0),
    bg           = Color3.fromRGB(5, 8, 18),
    primary      = Color3.fromRGB(80, 170, 255),
    accent       = Color3.fromRGB(180, 150, 255),
    buttonPurple = Color3.fromRGB(100, 185, 255),
    darkPurple   = Color3.fromRGB(10, 18, 45),
    toggleOn     = Color3.fromRGB(80, 170, 255),
    subtitleGrey = Color3.fromRGB(160, 155, 190),
    dividerGrey  = Color3.fromRGB(45, 40, 65),
    tabActive    = Color3.fromRGB(180, 150, 255),
    tabInactive  = Color3.fromRGB(100, 90, 130),
    green        = Color3.fromRGB(46, 204, 113),
    yellow       = Color3.fromRGB(241, 196, 15),
    red          = Color3.fromRGB(231, 76, 60),
    coolPurple   = Color3.fromRGB(60, 100, 200),
    purple       = Color3.fromRGB(144, 31, 237),
    grey         = Color3.fromRGB(38, 38, 36),
    violet       = Color3.fromRGB(80, 80, 180),
    pink         = Color3.fromRGB(250, 67, 192),
    gold         = Color3.fromRGB(245, 126, 22),
}

local function addTextGradient(textElement, color1, color2, rotation)
    rotation = rotation or 45
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation
    gradient.Parent = textElement
    task.spawn(function()
        while textElement.Parent and gradient.Parent do
            for rot = rotation, rotation + 360, 2 do
                if not gradient.Parent then break end
                gradient.Rotation = rot
                task.wait(0.03)
            end
        end
    end)
    return gradient
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "REN"
screenGui.Parent = game.CoreGui
screenGui.ResetOnSpawn = false

local function trackPosition(target, saveKey)
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if saveKey then
                        task.wait()
                        local screenSize = screenGui.AbsoluteSize
                        Config.Positions[saveKey] = {
                            X = (target.AbsolutePosition.X + target.AbsoluteSize.X / 2) / screenSize.X,
                            Y = (target.AbsolutePosition.Y + target.AbsoluteSize.Y / 2) / screenSize.Y,
                        }
                        SaveConfig()
                    end
                end
            end)
        end
    end)
end

local creditFrame = Instance.new("Frame")
creditFrame.Name = "CreditFrame"
creditFrame.Size = UDim2.new(0, 249, 0, 34)
local creditPos = Config.Positions.CreditFrame
creditFrame.Position = UDim2.new(creditPos.X, -127, creditPos.Y, -17)
creditFrame.BackgroundColor3 = C.black
creditFrame.BorderSizePixel = 0
creditFrame.Active = true
creditFrame.Draggable = true
creditFrame.Parent = screenGui
trackPosition(creditFrame, "CreditFrame")

Instance.new("UICorner", creditFrame).CornerRadius = UDim.new(1, 0)

local creditStroke = Instance.new("UIStroke")
creditStroke.Thickness = 1.5
creditStroke.Color = C.coolPurple
creditStroke.Transparency = 0.4
creditStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
creditStroke.Parent = creditFrame

local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 24, 0, 24)
logoFrame.Position = UDim2.new(0, 7, 0.5, -12)
logoFrame.BackgroundColor3 = C.darkPurple
logoFrame.BorderSizePixel = 0
logoFrame.Parent = creditFrame
Instance.new("UICorner", logoFrame).CornerRadius = UDim.new(1, 0)

local logoImage = Instance.new("ImageLabel")
logoImage.Size = UDim2.new(1, 0, 1, 0)
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://134005655420103"
logoImage.Parent = logoFrame
Instance.new("UICorner", logoImage).CornerRadius = UDim.new(1, 0)

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(0, 1, 0, 18)
div1.Position = UDim2.new(0, 38, 0.5, -9)
div1.BackgroundColor3 = C.gold
div1.BorderSizePixel = 0
div1.Parent = creditFrame

local discordLabel = Instance.new("TextLabel")
discordLabel.Size = UDim2.new(0, 120, 1, 0)
discordLabel.Position = UDim2.new(0, 46, 0, 0)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = "DISCORD.GG/RENHUB"
discordLabel.TextColor3 = C.white
discordLabel.Font = Enum.Font.MontserratBlack
discordLabel.TextSize = 11
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.TextYAlignment = Enum.TextYAlignment.Center
discordLabel.Parent = creditFrame
addTextGradient(discordLabel, C.primary, C.accent, 45)

local div2 = Instance.new("Frame")
div2.Size = UDim2.new(0, 1, 0, 18)
div2.Position = UDim2.new(0, 162, 0.5, -9)
div2.BackgroundColor3 = C.gold
div2.BorderSizePixel = 0
div2.Parent = creditFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 50, 1, 0)
fpsLabel.Position = UDim2.new(0, 167, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "60 fps"
fpsLabel.TextColor3 = C.green
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 11
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.TextYAlignment = Enum.TextYAlignment.Center
fpsLabel.Parent = creditFrame

local div3 = Instance.new("Frame")
div3.Size = UDim2.new(0, 1, 0, 18)
div3.Position = UDim2.new(0, 209, 0.5, -9)
div3.BackgroundColor3 = C.gold
div3.BorderSizePixel = 0
div3.Parent = creditFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(0, 50, 1, 0)
pingLabel.Position = UDim2.new(0, 203, 0, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "0ms"
pingLabel.TextColor3 = C.green
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextSize = 11
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.TextYAlignment = Enum.TextYAlignment.Center
pingLabel.Parent = creditFrame

local frames = 0
local last = tick()
RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        local fps = frames; frames = 0; last = now
        local ok, rawPing = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        local ping = ok and math.floor(rawPing + 0.5) or 0
        fpsLabel.Text = fps .. " fps"
        if fps >= 49 then fpsLabel.TextColor3 = C.green
        elseif fps >= 32 then fpsLabel.TextColor3 = C.yellow
        else fpsLabel.TextColor3 = C.red end
        pingLabel.Text = ping .. "ms"
        if ping < 70 then pingLabel.TextColor3 = C.green
        elseif ping < 100 then pingLabel.TextColor3 = C.yellow
        else pingLabel.TextColor3 = C.red end
    end
end)
