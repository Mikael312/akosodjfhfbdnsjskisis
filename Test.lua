local Services = {
    Tween = game:GetService("TweenService"),
    Teleport = game:GetService("TeleportService"),
    Players = game:GetService("Players"),
    Input = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    Lighting = game:GetService("Lighting"),
    Stats = game:GetService("Stats"),
    Http = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer

local gui = game.CoreGui:FindFirstChild("ZynHub")
if gui then gui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZynHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local toggleTriggers = {}
local boundKeys = {}
local listeningPill = nil

-- =====================
-- CONFIG SYSTEM
-- =====================
local ConfigSystem = {}
ConfigSystem.ConfigFile = "ZynHub_Config.json"
ConfigSystem.DefaultConfig = {}

function ConfigSystem:Load()
    if isfile and isfile(self.ConfigFile) then
        local ok, result = pcall(function()
            return Services.Http:JSONDecode(readfile(self.ConfigFile))
        end)
        if ok and result then return result end
    end
    return self.DefaultConfig
end

function ConfigSystem:Save(config)
    if not writefile then return false end
    pcall(function()
        writefile(self.ConfigFile, Services.Http:JSONEncode(config))
    end)
end

function ConfigSystem:UpdateSetting(config, key, value)
    config[key] = value
    self:Save(config)
end

ConfigSystem.CurrentConfig = ConfigSystem:Load()

if ConfigSystem.CurrentConfig.keybinds then
    for actionName, keyName in pairs(ConfigSystem.CurrentConfig.keybinds) do
        local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
        if ok and kc then boundKeys[actionName] = kc end
    end
end

if not ConfigSystem.CurrentConfig.toggles then
    ConfigSystem.CurrentConfig.toggles = {}
end

-- =====================
-- GUI SCALE CONSTANTS
-- =====================
local GUI_SCALE_MIN     = 10
local GUI_SCALE_MAX     = 25
local GUI_SCALE_DEFAULT = 15
local MAIN_BASE_W, MAIN_BASE_H = 185, 290
local MENU_BASE_W, MENU_BASE_H = 225, 320

local currentScale = ConfigSystem.CurrentConfig.guiScale or GUI_SCALE_DEFAULT

local MAIN_DEFAULT_POS   = UDim2.new(0.75, -92,  0.5, -145)
local MENU_DEFAULT_POS   = UDim2.new(0,    85,   0,    115)
local CREDIT_DEFAULT_POS = UDim2.new(0.5, -140,  0.5, -240)

local saveGuiPos = ConfigSystem.CurrentConfig.toggles["Save Gui Position"] == true

-- =====================
-- DRAG SYSTEM
-- =====================
local function setupDrag(frame, posKey)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    local function onRelease(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
            -- Save position guna AbsolutePosition
            if saveGuiPos and posKey then
                local pos = frame.AbsolutePosition
                if not ConfigSystem.CurrentConfig.guiPositions then
                    ConfigSystem.CurrentConfig.guiPositions = {}
                end
                ConfigSystem.CurrentConfig.guiPositions[posKey] = { x = pos.X, y = pos.Y }
                ConfigSystem:Save(ConfigSystem.CurrentConfig)
            end
        end
    end

    frame.InputEnded:Connect(onRelease)
    Services.Input.InputEnded:Connect(onRelease)

    Services.Input.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =====================
-- LOAD GUI POSITIONS
-- =====================
local function loadGuiPositions(mainFrame, menuFrame, creditFrame)
    local pos = ConfigSystem.CurrentConfig.guiPositions
    if not pos then return end

    if pos.main then
        mainFrame.Position = UDim2.new(0, pos.main.x, 0, pos.main.y)
    end
    if pos.menu then
        menuFrame.Position = UDim2.new(0, pos.menu.x, 0, pos.menu.y)
    end
    if pos.credit then
        creditFrame.Position = UDim2.new(0, pos.credit.x, 0, pos.credit.y)
    end
end

-- =====================
-- NOTIFICATION SYSTEM
-- =====================
local activeNotifications = {}
local NOTIF_HEIGHT = 56
local NOTIF_SPACING = 10
local MAX_NOTIFS = 3

local NotifColors = {
    Bar = {
        Default = Color3.fromRGB(180, 180, 200),
        Failed  = Color3.fromRGB(220, 40,  40),
        Success = Color3.fromRGB(40,  200, 100),
        White   = Color3.fromRGB(255, 255, 255),
        Blue    = Color3.fromRGB(60,  160, 255),
        Violet  = Color3.fromRGB(70,  70,  180),
    },
    Text = {
        Default = Color3.fromRGB(255, 255, 255),
        Failed  = Color3.fromRGB(255, 80,  80),
        Success = Color3.fromRGB(80,  220, 120),
        Violet  = Color3.fromRGB(70,  70,  180),
    },
}

local function updateNotificationPositions()
    for i, notifData in ipairs(activeNotifications) do
        local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
        Services.Tween:Create(notifData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, newYPos)
        }):Play()
    end
end

local function removeNotification(notifData)
    for i, data in ipairs(activeNotifications) do
        if data == notifData then table.remove(activeNotifications, i) break end
    end
    updateNotificationPositions()
end

local function showNotification(opts)
    opts = opts or {}
    local message  = opts.message      or ""
    local subtext  = opts.subtext      or nil
    local barColor = NotifColors.Bar[opts.barColor      or "Default"] or NotifColors.Bar.Default
    local txtColor = NotifColors.Text[opts.textColor    or "Default"] or NotifColors.Text.Default
    local subColor = NotifColors.Text[opts.subtextColor or "Default"] or NotifColors.Text.Default

    if #activeNotifications >= MAX_NOTIFS then
        local oldest = activeNotifications[1]
        if oldest.barTween then oldest.barTween:Cancel() end
        table.remove(activeNotifications, 1)
        updateNotificationPositions()
        Services.Tween:Create(oldest.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -260, 0, oldest.frame.Position.Y.Offset)
        }):Play()
        task.delay(0.3, function() oldest.frame:Destroy() end)
    end

    local notifGui = game:GetService("CoreGui"):FindFirstChild("ZynNotifGui")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "ZynNotifGui"
        notifGui.ResetOnSpawn = false
        notifGui.Parent = game:GetService("CoreGui")
    end

    local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
    local frameHeight = subtext and 57 or NOTIF_HEIGHT

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, frameHeight)
    notif.Position = UDim2.new(0, -260, 0, startYPos)
    notif.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    notif.BorderSizePixel = 0
    notif.Parent = notifGui

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 8)
    nCorner.Parent = notif

    local nStroke = Instance.new("UIStroke")
    nStroke.Thickness = 1
    nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    nStroke.Color = Color3.fromRGB(40, 40, 52)
    nStroke.Parent = notif

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(0, 4, 0, 4)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(100, 100, 115)
    closeButton.TextSize = 11
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notif

    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(220, 220, 235) end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Color3.fromRGB(100, 100, 115) end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -36, 0, subtext and 26 or frameHeight - 6)
    textLabel.Position = UDim2.new(0, 30, 0, subtext and 8 or 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = txtColor
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true
    textLabel.Parent = notif

    if subtext then
        local subLabel = Instance.new("TextLabel")
        subLabel.Size = UDim2.new(1, -36, 0, 18)
        subLabel.Position = UDim2.new(0, 30, 0, 28)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = subtext
        subLabel.TextColor3 = subColor
        subLabel.TextSize = 10
        subLabel.Font = Enum.Font.Gotham
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.TextYAlignment = Enum.TextYAlignment.Center
        subLabel.TextWrapped = true
        subLabel.Parent = notif
    end

    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, 0, 0, 3)
    barContainer.Position = UDim2.new(0, 0, 1, -3)
    barContainer.BackgroundTransparency = 1
    barContainer.ClipsDescendants = true
    barContainer.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = barColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = barContainer

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = progressBar

    local notifData = { frame = notif, progressBar = progressBar, barTween = nil }
    table.insert(activeNotifications, notifData)

    Services.Tween:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 10, 0, startYPos)
    }):Play()

    local barTween = Services.Tween:Create(progressBar, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    notifData.barTween = barTween
    barTween:Play()

    local function dismiss()
        if notifData.barTween then notifData.barTween:Cancel() end
        if notif.Parent then
            Services.Tween:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -260, 0, notif.Position.Y.Offset)
            }):Play()
            task.delay(0.3, function() if notif.Parent then notif:Destroy() end end)
            removeNotification(notifData)
        end
    end

    closeButton.MouseButton1Click:Connect(dismiss)
    task.delay(2, dismiss)
end

-- =====================
-- CREDIT FRAME
-- =====================
local creditFrame = Instance.new("Frame")
creditFrame.Size = UDim2.new(0, 280, 0, 52)
creditFrame.Position = CREDIT_DEFAULT_POS
creditFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
creditFrame.BorderSizePixel = 0
creditFrame.Active = true
creditFrame.Parent = screenGui

local creditCorner = Instance.new("UICorner")
creditCorner.CornerRadius = UDim.new(0, 8)
creditCorner.Parent = creditFrame

local creditStroke = Instance.new("UIStroke")
creditStroke.Thickness = 1
creditStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
creditStroke.Color = Color3.fromRGB(255, 255, 255)
creditStroke.Parent = creditFrame

local creditStrokeGrad = Instance.new("UIGradient")
creditStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
creditStrokeGrad.Parent = creditStroke
Services.Tween:Create(creditStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local resetScaleCredit = Instance.new("TextButton")
resetScaleCredit.Size = UDim2.new(0, 52, 0, 16)
resetScaleCredit.Position = UDim2.new(1, -57, 0, 5)
resetScaleCredit.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
resetScaleCredit.BorderSizePixel = 0
resetScaleCredit.Text = "Rst Scale"
resetScaleCredit.TextColor3 = Color3.fromRGB(150, 150, 165)
resetScaleCredit.TextStrokeTransparency = 1
resetScaleCredit.TextSize = 8
resetScaleCredit.Font = Enum.Font.GothamBold
resetScaleCredit.ZIndex = 3
resetScaleCredit.Parent = creditFrame

local resetScaleCreditCorner = Instance.new("UICorner")
resetScaleCreditCorner.CornerRadius = UDim.new(0, 6)
resetScaleCreditCorner.Parent = resetScaleCredit

local resetScaleCreditStroke = Instance.new("UIStroke")
resetScaleCreditStroke.Thickness = 1
resetScaleCreditStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
resetScaleCreditStroke.Color = Color3.fromRGB(70, 70, 85)
resetScaleCreditStroke.Parent = resetScaleCredit

local creditLogo = Instance.new("ImageLabel")
creditLogo.Size = UDim2.new(0, 36, 0, 36)
creditLogo.Position = UDim2.new(0, 8, 0.5, -18)
creditLogo.BackgroundTransparency = 1
creditLogo.Image = "rbxassetid://98023595162924"
creditLogo.ImageColor3 = Color3.fromRGB(210, 210, 220)
creditLogo.Parent = creditFrame

local creditTitle = Instance.new("TextLabel")
creditTitle.Size = UDim2.new(1, -58, 0, 26)
creditTitle.Position = UDim2.new(0, 52, 0, 8)
creditTitle.BackgroundTransparency = 1
creditTitle.Text = "ZYN HUB | .GG/ZYNHUB"
creditTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
creditTitle.TextStrokeTransparency = 1
creditTitle.TextSize = 15
creditTitle.Font = Enum.Font.GothamBold
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.Parent = creditFrame

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(140, 140, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70,  70,  180)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 140, 255))
}
titleGrad.Rotation = 90
titleGrad.Parent = creditTitle

local creditSub = Instance.new("TextLabel")
creditSub.Size = UDim2.new(1, -58, 0, 16)
creditSub.Position = UDim2.new(0, 52, 0, 30)
creditSub.BackgroundTransparency = 1
creditSub.Text = "Made By: Michal, Shadow"
creditSub.TextColor3 = Color3.fromRGB(80, 80, 90)
creditSub.TextStrokeTransparency = 1
creditSub.TextSize = 9
creditSub.Font = Enum.Font.Gotham
creditSub.TextXAlignment = Enum.TextXAlignment.Left
creditSub.Parent = creditFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 16)
fpsLabel.Position = UDim2.new(1, -105, 1, -20)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Fps: 0, Ping: 0"
fpsLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
fpsLabel.TextStrokeTransparency = 1
fpsLabel.TextSize = 9
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = creditFrame

local frames = 0
local last = tick()
Services.RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        local fps = frames
        frames = 0
        last = now
        local ok, rawPing = pcall(function()
            return Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        local ping = ok and math.floor(rawPing + 0.5) or 0
        fpsLabel.Text = "Fps: " .. fps .. ", Ping: " .. ping
    end
end)

-- =====================
-- MAIN FRAME
-- =====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, MAIN_BASE_W, 0, MAIN_BASE_H)
mainFrame.Position = MAIN_DEFAULT_POS
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 9)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Parent = mainFrame

local mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
mainStrokeGrad.Parent = mainStroke
Services.Tween:Create(mainStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1, -20, 0, 32)
mainTitle.Position = UDim2.new(0, 10, 0, 5)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "Quick Panel"
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.TextStrokeTransparency = 1
mainTitle.TextSize = 14
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = mainFrame

local mainTitleGrad = Instance.new("UIGradient")
mainTitleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(140, 140, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70,  70,  180)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 140, 255))
}
mainTitleGrad.Rotation = 90
mainTitleGrad.Parent = mainTitle

local menuToggle = Instance.new("TextButton")
menuToggle.Size = UDim2.new(0, 44, 0, 18)
menuToggle.Position = UDim2.new(1, -52, 0, 10)
menuToggle.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
menuToggle.BorderSizePixel = 0
menuToggle.Text = "Menu"
menuToggle.TextColor3 = Color3.fromRGB(150, 150, 165)
menuToggle.TextStrokeTransparency = 1
menuToggle.TextSize = 9
menuToggle.Font = Enum.Font.GothamBold
menuToggle.ZIndex = 3
menuToggle.Parent = mainFrame

local menuToggleCorner = Instance.new("UICorner")
menuToggleCorner.CornerRadius = UDim.new(0, 10)
menuToggleCorner.Parent = menuToggle

local menuToggleStroke = Instance.new("UIStroke")
menuToggleStroke.Thickness = 1
menuToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuToggleStroke.Color = Color3.fromRGB(70, 70, 85)
menuToggleStroke.Parent = menuToggle

local mainDivider = Instance.new("Frame")
mainDivider.Size = UDim2.new(1, -20, 0, 1)
mainDivider.Position = UDim2.new(0, 10, 0, 37)
mainDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
mainDivider.BorderSizePixel = 0
mainDivider.Parent = mainFrame

local mainSubtitle = Instance.new("TextLabel")
mainSubtitle.Size = UDim2.new(1, -20, 0, 18)
mainSubtitle.Position = UDim2.new(0, 10, 0, 43)
mainSubtitle.BackgroundTransparency = 1
mainSubtitle.Text = "Actions"
mainSubtitle.TextColor3 = Color3.fromRGB(80, 80, 90)
mainSubtitle.TextStrokeTransparency = 1
mainSubtitle.TextSize = 10
mainSubtitle.Font = Enum.Font.GothamBold
mainSubtitle.TextXAlignment = Enum.TextXAlignment.Left
mainSubtitle.Parent = mainFrame

-- =====================
-- MENU POPUP FRAME
-- =====================
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, MENU_BASE_W, 0, MENU_BASE_H)
menuFrame.Position = MENU_DEFAULT_POS
menuFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Active = true
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 9)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Thickness = 1.0
menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuStroke.Color = Color3.fromRGB(255, 255, 255)
menuStroke.Parent = menuFrame

local menuStrokeGrad = Instance.new("UIGradient")
menuStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
menuStrokeGrad.Parent = menuStroke
Services.Tween:Create(menuStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local menuTitle = Instance.new("TextLabel")
menuTitle.Size = UDim2.new(1, 0, 0, 26)
menuTitle.Position = UDim2.new(0, 0, 0, 4)
menuTitle.BackgroundTransparency = 1
menuTitle.Text = "Zyn Hub"
menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
menuTitle.TextStrokeTransparency = 1
menuTitle.TextSize = 14
menuTitle.Font = Enum.Font.GothamBold
menuTitle.TextXAlignment = Enum.TextXAlignment.Center
menuTitle.Parent = menuFrame

local menuTitleGrad = Instance.new("UIGradient")
menuTitleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(140, 140, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70,  70,  180)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 140, 255))
}
menuTitleGrad.Rotation = 90
menuTitleGrad.Parent = menuTitle

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 2)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(100, 100, 115)
closeBtn.TextStrokeTransparency = 1
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.Gotham
closeBtn.ZIndex = 3
closeBtn.Parent = menuFrame

closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(220, 220, 235) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(100, 100, 115) end)

local menuDivider = Instance.new("Frame")
menuDivider.Size = UDim2.new(1, -20, 0, 1)
menuDivider.Position = UDim2.new(0, 10, 0, 30)
menuDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
menuDivider.BorderSizePixel = 0
menuDivider.Parent = menuFrame

-- =====================
-- GUI SCALE FUNCTION
-- =====================
local function applyGuiScale(scale, silent)
    currentScale = math.clamp(scale, GUI_SCALE_MIN, GUI_SCALE_MAX)
    local ratio = currentScale / GUI_SCALE_DEFAULT

    local newMainW = math.floor(MAIN_BASE_W * ratio)
    local newMainH = math.floor(MAIN_BASE_H * ratio)
    local newMenuW = math.floor(MENU_BASE_W * ratio)
    local newMenuH = math.floor(MENU_BASE_H * ratio)

    local mainCX = mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2
    local mainCY = mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y / 2
    local menuCX = menuFrame.AbsolutePosition.X + menuFrame.AbsoluteSize.X / 2
    local menuCY = menuFrame.AbsolutePosition.Y + menuFrame.AbsoluteSize.Y / 2

    Services.Tween:Create(mainFrame, TweenInfo.new(0.05), {
        Size     = UDim2.new(0, newMainW, 0, newMainH),
        Position = UDim2.new(0, mainCX - newMainW / 2, 0, mainCY - newMainH / 2)
    }):Play()
    Services.Tween:Create(menuFrame, TweenInfo.new(0.05), {
        Size     = UDim2.new(0, newMenuW, 0, newMenuH),
        Position = UDim2.new(0, menuCX - newMenuW / 2, 0, menuCY - newMenuH / 2)
    }):Play()

    if not silent then
        ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "guiScale", currentScale)
    end
end

-- =====================
-- TABS
-- =====================
local tabNames = {"Features", "Misc", "Keybind", "Server", "Credits"}
local tabBtns = {}
local activeTab = "Features"
local tabContents = {}

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 26)
tabBar.Position = UDim2.new(0, 10, 0, 36)
tabBar.BackgroundTransparency = 1
tabBar.Parent = menuFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabBar

local function setActiveTab(name)
    activeTab = name
    for _, t in pairs(tabBtns) do
        if t.name == name then
            t.btn.TextColor3 = Color3.fromRGB(220, 220, 235)
            t.stroke.Color = Color3.fromRGB(150, 150, 170)
            Services.Tween:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 38)}):Play()
        else
            t.btn.TextColor3 = Color3.fromRGB(90, 90, 105)
            t.stroke.Color = Color3.fromRGB(35, 35, 42)
            Services.Tween:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
        end
    end
    for n, f in pairs(tabContents) do
        f.Visible = (n == name)
    end
end

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 36, 0, 26)
    tabBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(90, 90, 105)
    tabBtn.TextStrokeTransparency = 1
    tabBtn.TextSize = 8
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.LayoutOrder = i
    tabBtn.ZIndex = 3
    tabBtn.Parent = tabBar

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn

    local tabStroke = Instance.new("UIStroke")
    tabStroke.Thickness = 1
    tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tabStroke.Color = Color3.fromRGB(35, 35, 42)
    tabStroke.Parent = tabBtn

    tabBtns[i] = {name = name, btn = tabBtn, stroke = tabStroke}

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size = UDim2.new(1, 0, 1, -70)
    contentScroll.Position = UDim2.new(0, 0, 0, 70)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 2
    contentScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95)
    contentScroll.ScrollBarImageTransparency = 0
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.Visible = false
    contentScroll.ZIndex = 3
    contentScroll.Parent = menuFrame

    local cPadding = Instance.new("UIPadding")
    cPadding.PaddingLeft = UDim.new(0, 10)
    cPadding.PaddingRight = UDim.new(0, 14)
    cPadding.PaddingTop = UDim.new(0, 8)
    cPadding.PaddingBottom = UDim.new(0, 8)
    cPadding.Parent = contentScroll

    local cLayout = Instance.new("UIListLayout")
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Padding = UDim.new(0, 8)
    cLayout.Parent = contentScroll

    tabContents[name] = contentScroll
    tabBtn.MouseButton1Click:Connect(function() setActiveTab(name) end)
end

-- =====================
-- SHARED FACTORIES
-- =====================
local function makeSectionLabel(text, parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextStrokeTransparency = 1
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = parent
end

local function makeIosToggle(labelText, parent, order, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Color = Color3.fromRGB(30, 30, 38)
    rowStroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    lbl.TextStrokeTransparency = 1
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 34, 0, 18)
    track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, 3, 0.5, -6)
    circle.BackgroundColor3 = Color3.fromRGB(130, 130, 145)
    circle.BorderSizePixel = 0
    circle.Parent = track

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = row

    local isOn = false

    local function applyState(state, silent)
        isOn = state
        if isOn then
            Services.Tween:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 200, 220)}):Play()
            Services.Tween:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 19, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
        else
            Services.Tween:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
            Services.Tween:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Color3.fromRGB(130, 130, 145)}):Play()
            lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        end
        if not silent and labelText ~= "Hop Server" then
            ConfigSystem.CurrentConfig.toggles[labelText] = isOn
            ConfigSystem:Save(ConfigSystem.CurrentConfig)
        end
        if onToggle and not silent then onToggle(isOn) end
    end

    local savedState = ConfigSystem.CurrentConfig.toggles[labelText]
    if savedState ~= nil then
        applyState(savedState, true)
        if onToggle then onToggle(isOn) end
    end

    btn.MouseButton1Click:Connect(function() applyState(not isOn, false) end)
    return { applyState = applyState }
end

local function makeCardBtn(labelText, iconId, parent, order, onClick, useGotham)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 34)
    card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    card.BackgroundTransparency = 0.17
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = card

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(50, 50, 62)
    cs.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    lbl.TextStrokeTransparency = 1
    lbl.TextSize = 11
    lbl.Font = useGotham and Enum.Font.Gotham or Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(1, -28, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. tostring(iconId)
    icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    icon.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = card

    btn.MouseEnter:Connect(function()
        Services.Tween:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 120, 140)}):Play()
        lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
        icon.ImageColor3 = Color3.fromRGB(220, 220, 235)
    end)
    btn.MouseLeave:Connect(function()
        Services.Tween:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 62)}):Play()
        lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    end)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
end

-- =====================
-- KEYBIND SYSTEM
-- =====================
local function keyName(kc)
    local names = {
        LeftBracket = "[", RightBracket = "]",
        Semicolon = ";", Quote = "'",
        Comma = ",", Period = ".", Slash = "/",
        BackSlash = "\\", Minus = "-", Equals = "=",
        BackQuote = "`"
    }
    return names[kc.Name] or kc.Name
end

Services.Input.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if listeningPill then
        local data = listeningPill
        listeningPill = nil
        if input.KeyCode == Enum.KeyCode.Escape then
            boundKeys[data.actionName] = nil
            data.pill.Text = "None"
            data.pill.TextColor3 = Color3.fromRGB(90, 90, 105)
        else
            boundKeys[data.actionName] = input.KeyCode
            data.pill.Text = keyName(input.KeyCode)
            data.pill.TextColor3 = Color3.fromRGB(200, 200, 215)
        end
        local keybindsToSave = {}
        for action, kc in pairs(boundKeys) do keybindsToSave[action] = kc.Name end
        ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "keybinds", keybindsToSave)
        Services.Tween:Create(data.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
        Services.Tween:Create(data.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
        Services.Tween:Create(data.rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
        return
    end

    for actionName, kc in pairs(boundKeys) do
        if kc and input.KeyCode == kc then
            if toggleTriggers[actionName] then toggleTriggers[actionName]() end
        end
    end
end)

local function makeKeybindRow(actionName, parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    row.BackgroundTransparency = 0.17
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Color = Color3.fromRGB(40, 40, 52)
    rowStroke.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 1, 0)
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = actionName
    nameLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    nameLabel.TextStrokeTransparency = 1
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local keyPill = Instance.new("TextButton")
    keyPill.Size = UDim2.new(0, 60, 0, 22)
    keyPill.Position = UDim2.new(1, -66, 0.5, -11)
    keyPill.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    keyPill.BorderSizePixel = 0
    keyPill.Text = "None"
    keyPill.TextColor3 = Color3.fromRGB(90, 90, 105)
    keyPill.TextStrokeTransparency = 1
    keyPill.TextSize = 9
    keyPill.Font = Enum.Font.GothamBold
    keyPill.ZIndex = 4
    keyPill.Parent = row

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 6)
    pillCorner.Parent = keyPill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Thickness = 1
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Color = Color3.fromRGB(45, 45, 58)
    pillStroke.Parent = keyPill

    if boundKeys[actionName] then
        keyPill.Text = keyName(boundKeys[actionName])
        keyPill.TextColor3 = Color3.fromRGB(200, 200, 215)
    end

    keyPill.MouseButton1Click:Connect(function()
        if listeningPill and listeningPill.pill == keyPill then
            listeningPill = nil
            keyPill.Text = boundKeys[actionName] and keyName(boundKeys[actionName]) or "None"
            keyPill.TextColor3 = boundKeys[actionName] and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(90, 90, 105)
            Services.Tween:Create(keyPill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
            Services.Tween:Create(pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
            Services.Tween:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
            return
        end
        if listeningPill then
            local prev = listeningPill
            listeningPill = nil
            prev.pill.Text = boundKeys[prev.actionName] and keyName(boundKeys[prev.actionName]) or "None"
            prev.pill.TextColor3 = boundKeys[prev.actionName] and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(90, 90, 105)
            Services.Tween:Create(prev.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
            Services.Tween:Create(prev.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
            Services.Tween:Create(prev.rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
        end
        listeningPill = { pill = keyPill, pillStroke = pillStroke, rowStroke = rowStroke, actionName = actionName }
        keyPill.Text = "..."
        keyPill.TextColor3 = Color3.fromRGB(210, 210, 225)
        Services.Tween:Create(keyPill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
        Services.Tween:Create(pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(150, 150, 170)}):Play()
        Services.Tween:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(120, 120, 140)}):Play()
    end)
end

-- =====================
-- MAIN SCROLL FRAME
-- =====================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -65)
scrollFrame.Position = UDim2.new(0, 0, 0, 65)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 0
scrollFrame.ScrollBarImageTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 10)
scrollPadding.PaddingRight = UDim.new(0, 10)
scrollPadding.PaddingTop = UDim.new(0, 4)
scrollPadding.PaddingBottom = UDim.new(0, 8)
scrollPadding.Parent = scrollFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 6)
scrollLayout.Parent = scrollFrame

-- =====================
-- MAIN FRAME: Button & Toggle
-- =====================
local function makeButton(labelText, order, onClick)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = scrollFrame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 7)
    cc.Parent = container

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(35, 35, 42)
    cs.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(160, 160, 175)
    label.TextStrokeTransparency = 1
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(1, -28, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://77565720409665"
    icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    icon.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = container

    btn.MouseEnter:Connect(function()
        Services.Tween:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 120)}):Play()
        label.TextColor3 = Color3.fromRGB(220, 220, 235)
        icon.ImageColor3 = Color3.fromRGB(220, 220, 235)
    end)
    btn.MouseLeave:Connect(function()
        Services.Tween:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(35, 35, 42)}):Play()
        label.TextColor3 = Color3.fromRGB(160, 160, 175)
        icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    end)

    local function fire() if onClick then onClick() end end
    btn.MouseButton1Click:Connect(fire)
    toggleTriggers[labelText] = fire
end

local function makeToggle(labelText, order, onToggle)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = scrollFrame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 7)
    cc.Parent = container

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(35, 35, 42)
    cs.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(160, 160, 175)
    label.TextStrokeTransparency = 1
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 48, 0, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    pill.BorderSizePixel = 0
    pill.Text = "OFF"
    pill.TextColor3 = Color3.fromRGB(90, 90, 100)
    pill.TextStrokeTransparency = 1
    pill.TextSize = 10
    pill.Font = Enum.Font.GothamBold
    pill.ZIndex = 2
    pill.Parent = container

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Thickness = 1
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Color = Color3.fromRGB(50, 50, 60)
    pillStroke.Parent = pill

    local isOn = false

    local function applyState(state, silent)
        isOn = state
        if isOn then
            Services.Tween:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 240, 250)}):Play()
            pill.TextColor3 = Color3.fromRGB(10, 10, 12)
            pill.Text = "ON"
            pillStroke.Color = Color3.fromRGB(200, 200, 215)
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 120, 140)}):Play()
        else
            Services.Tween:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
            pill.TextColor3 = Color3.fromRGB(90, 90, 100)
            pill.Text = "OFF"
            pillStroke.Color = Color3.fromRGB(50, 50, 60)
            label.TextColor3 = Color3.fromRGB(160, 160, 175)
            Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(35, 35, 42)}):Play()
        end
        if not silent and labelText ~= "Hop Server" then
            ConfigSystem.CurrentConfig.toggles[labelText] = isOn
            ConfigSystem:Save(ConfigSystem.CurrentConfig)
        end
        if onToggle and not silent then onToggle(isOn) end
    end

    local savedState = ConfigSystem.CurrentConfig.toggles[labelText]
    if savedState ~= nil then
        applyState(savedState, true)
        if onToggle then onToggle(isOn) end
    end

    pill.MouseButton1Click:Connect(function() applyState(not isOn, false) end)
    toggleTriggers[labelText] = function() applyState(not isOn, false) end
end

-- =====================
-- QUICK PANEL ITEMS
-- =====================
makeButton("Tp to Best", 1, function() end)
makeToggle("Steal Nearest", 2, function(state)
    if state then
        showNotification({ message = "Steal Nearest", barColor = "White", textColor = "Default", subtext = "Enabled" })
    else
        showNotification({ message = "Steal Nearest", barColor = "Default", textColor = "Default", subtext = "Disabled" })
    end
end)
makeToggle("Highest",   3)
makeToggle("Priority",  4)
makeToggle("Auto Kick", 5)
makeToggle("Fly",       6)

-- =====================
-- FEATURES TAB
-- =====================
local featScroll = tabContents["Features"]
makeSectionLabel("Player", featScroll, 1)
makeIosToggle("Inf Jump", featScroll, 2, function(state) end)

-- =====================
-- KEYBIND TAB
-- =====================
local kbScroll = tabContents["Keybind"]

local kbHeaderRow = Instance.new("Frame")
kbHeaderRow.Size = UDim2.new(1, 0, 0, 18)
kbHeaderRow.BackgroundTransparency = 1
kbHeaderRow.LayoutOrder = 1
kbHeaderRow.Parent = kbScroll

local kbSectionLbl = Instance.new("TextLabel")
kbSectionLbl.Size = UDim2.new(1, -60, 1, 0)
kbSectionLbl.BackgroundTransparency = 1
kbSectionLbl.Text = "Quick Panel"
kbSectionLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
kbSectionLbl.TextStrokeTransparency = 1
kbSectionLbl.TextSize = 10
kbSectionLbl.Font = Enum.Font.GothamBold
kbSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
kbSectionLbl.Parent = kbHeaderRow

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 44, 0, 16)
resetBtn.Position = UDim2.new(1, -44, 0.5, -8)
resetBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
resetBtn.BorderSizePixel = 0
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.fromRGB(150, 150, 165)
resetBtn.TextStrokeTransparency = 1
resetBtn.TextSize = 9
resetBtn.Font = Enum.Font.GothamBold
resetBtn.ZIndex = 4
resetBtn.Parent = kbHeaderRow

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetBtn

local resetStroke = Instance.new("UIStroke")
resetStroke.Thickness = 1
resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
resetStroke.Color = Color3.fromRGB(50, 50, 62)
resetStroke.Parent = resetBtn

local kbPills = {}

resetBtn.MouseButton1Click:Connect(function()
    boundKeys = {}
    ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "keybinds", {})
    for _, pillData in ipairs(kbPills) do
        pillData.pill.Text = "None"
        pillData.pill.TextColor3 = Color3.fromRGB(90, 90, 105)
        Services.Tween:Create(pillData.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
        Services.Tween:Create(pillData.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
    end
    showNotification({ message = "Keybinds Reset", barColor = "Default", textColor = "Default" })
end)

local function makeKeybindRowTracked(actionName, parent, order)
    makeKeybindRow(actionName, parent, order)
    local children = parent:GetChildren()
    local row = children[#children]
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextButton") then
            local pillStroke = child:FindFirstChildOfClass("UIStroke")
            table.insert(kbPills, { pill = child, pillStroke = pillStroke })
            break
        end
    end
end
makeKeybindRowTracked("Tp to Best",    kbScroll, 2)
makeKeybindRowTracked("Steal Nearest", kbScroll, 3)

-- =====================
-- SERVER TAB
-- =====================
local srvScroll = tabContents["Server"]

local hopActive = false
makeIosToggle("Hop Server", srvScroll, 1, function(state)
    hopActive = state
    if state then
        task.spawn(function()
            while hopActive do
                local placeId = game.PlaceId
                local ok, result = pcall(function()
                    return Services.Http:JSONDecode(
                        game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
                    )
                end)
                if ok and result and result.data then
                    local found = false
                    for _, server in ipairs(result.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            pcall(function()
                                Services.Teleport:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                            end)
                            found = true
                            break
                        end
                    end
                    if not found then task.wait(3) end
                else
                    task.wait(3)
                end
            end
        end)
    end
end)

makeCardBtn("Rejoin", "97462463002118", srvScroll, 2, function()
    pcall(function() Services.Teleport:Teleport(game.PlaceId, LocalPlayer) end)
end, true)

makeCardBtn("Copy Job ID", "97462463002118", srvScroll, 3, function()
    pcall(function() setclipboard(game.JobId) end)
    showNotification({ message = "Job ID Copied!", barColor = "Default", textColor = "Default" })
end, true)

local inputCard = Instance.new("Frame")
inputCard.Size = UDim2.new(1, 0, 0, 34)
inputCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inputCard.BackgroundTransparency = 0.17
inputCard.BorderSizePixel = 0
inputCard.LayoutOrder = 4
inputCard.Parent = srvScroll

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputCard

local inputStroke = Instance.new("UIStroke")
inputStroke.Thickness = 1
inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputStroke.Color = Color3.fromRGB(50, 50, 62)
inputStroke.Parent = inputCard

local jobInput = Instance.new("TextBox")
jobInput.Size = UDim2.new(1, -16, 1, -8)
jobInput.Position = UDim2.new(0, 8, 0, 4)
jobInput.BackgroundTransparency = 1
jobInput.Text = ""
jobInput.PlaceholderText = "Input Job ID"
jobInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 85)
jobInput.TextColor3 = Color3.fromRGB(180, 180, 195)
jobInput.TextStrokeTransparency = 1
jobInput.TextSize = 10
jobInput.Font = Enum.Font.Gotham
jobInput.TextXAlignment = Enum.TextXAlignment.Left
jobInput.ClearTextOnFocus = false
jobInput.ZIndex = 4
jobInput.Parent = inputCard

jobInput.Focused:Connect(function()
    Services.Tween:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(150, 150, 170)}):Play()
end)
jobInput.FocusLost:Connect(function()
    Services.Tween:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 62)}):Play()
end)

makeCardBtn("Join Server", "97462463002118", srvScroll, 5, function()
    local jobId = jobInput.Text
    if jobId ~= "" then
        local ok = pcall(function()
            Services.Teleport:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)
        if not ok then
            jobInput.Text = ""
            jobInput.PlaceholderText = "Invalid Job ID"
        end
    end
end, false)

-- =====================
-- CREDITS TAB
-- =====================
local credScroll = tabContents["Credits"]
makeSectionLabel("Credits", credScroll, 1)

local versionCard = Instance.new("Frame")
versionCard.Size = UDim2.new(1, 0, 0, 48)
versionCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
versionCard.BackgroundTransparency = 0.17
versionCard.BorderSizePixel = 0
versionCard.LayoutOrder = 2
versionCard.Parent = credScroll

local vcCorner = Instance.new("UICorner")
vcCorner.CornerRadius = UDim.new(0, 6)
vcCorner.Parent = versionCard

local vcStroke = Instance.new("UIStroke")
vcStroke.Thickness = 1
vcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
vcStroke.Color = Color3.fromRGB(50, 50, 62)
vcStroke.Parent = versionCard

local vcTitle = Instance.new("TextLabel")
vcTitle.Size = UDim2.new(1, 0, 0, 24)
vcTitle.Position = UDim2.new(0, 0, 0, 6)
vcTitle.BackgroundTransparency = 1
vcTitle.Text = "Version 1.0"
vcTitle.TextColor3 = Color3.fromRGB(210, 210, 220)
vcTitle.TextStrokeTransparency = 1
vcTitle.TextSize = 13
vcTitle.Font = Enum.Font.GothamBold
vcTitle.TextXAlignment = Enum.TextXAlignment.Center
vcTitle.Parent = versionCard

local vcSub = Instance.new("TextLabel")
vcSub.Size = UDim2.new(1, -16, 0, 16)
vcSub.Position = UDim2.new(0, 10, 0, 28)
vcSub.BackgroundTransparency = 1
vcSub.Text = "Version 1.0 • Upcoming 1.1"
vcSub.TextColor3 = Color3.fromRGB(80, 80, 95)
vcSub.TextStrokeTransparency = 1
vcSub.TextSize = 9
vcSub.Font = Enum.Font.Gotham
vcSub.TextXAlignment = Enum.TextXAlignment.Left
vcSub.Parent = versionCard

local madeCard = Instance.new("Frame")
madeCard.Size = UDim2.new(1, 0, 0, 48)
madeCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
madeCard.BackgroundTransparency = 0.17
madeCard.BorderSizePixel = 0
madeCard.LayoutOrder = 3
madeCard.Parent = credScroll

local madeCorner = Instance.new("UICorner")
madeCorner.CornerRadius = UDim.new(0, 6)
madeCorner.Parent = madeCard

local madeStroke = Instance.new("UIStroke")
madeStroke.Thickness = 1
madeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
madeStroke.Color = Color3.fromRGB(50, 50, 62)
madeStroke.Parent = madeCard

local madeTitle = Instance.new("TextLabel")
madeTitle.Size = UDim2.new(1, 0, 0, 22)
madeTitle.Position = UDim2.new(0, 0, 0, 6)
madeTitle.BackgroundTransparency = 1
madeTitle.Text = "Made By @michal @sh4dow"
madeTitle.TextColor3 = Color3.fromRGB(210, 210, 220)
madeTitle.TextStrokeTransparency = 1
madeTitle.TextSize = 11
madeTitle.Font = Enum.Font.GothamBold
madeTitle.TextXAlignment = Enum.TextXAlignment.Center
madeTitle.Parent = madeCard

local madeSubRow = Instance.new("Frame")
madeSubRow.Size = UDim2.new(1, -16, 0, 16)
madeSubRow.Position = UDim2.new(0, 10, 0, 28)
madeSubRow.BackgroundTransparency = 1
madeSubRow.Parent = madeCard

local madeSubText = Instance.new("TextLabel")
madeSubText.Size = UDim2.new(1, -20, 1, 0)
madeSubText.BackgroundTransparency = 1
madeSubText.Text = "Thank you for using our hub"
madeSubText.TextColor3 = Color3.fromRGB(80, 80, 95)
madeSubText.TextStrokeTransparency = 1
madeSubText.TextSize = 9
madeSubText.Font = Enum.Font.Gotham
madeSubText.TextXAlignment = Enum.TextXAlignment.Left
madeSubText.Parent = madeSubRow

local madeSubIcon = Instance.new("ImageLabel")
madeSubIcon.Size = UDim2.new(0, 14, 0, 14)
madeSubIcon.Position = UDim2.new(1, -14, 0.5, -7)
madeSubIcon.BackgroundTransparency = 1
madeSubIcon.Image = "rbxassetid://100961616085482"
madeSubIcon.ImageColor3 = Color3.fromRGB(160, 160, 175)
madeSubIcon.Parent = madeSubRow

makeCardBtn("Join our Community!", "97462463002118", credScroll, 4, function()
    setclipboard("https://discord.gg/cSGgvrS78")
    showNotification({ message = "Discord Copied!", barColor = "Blue", textColor = "Default" })
end, true)

-- =====================
-- SETTINGS SECTION
-- =====================
makeSectionLabel("Settings", credScroll, 5)

makeIosToggle("Lock Gui", credScroll, 6, function(state)
    -- Lock/unlock drag — handled via guiLocked flag in setupDrag
    ConfigSystem.CurrentConfig.toggles["Lock Gui"] = state
    ConfigSystem:Save(ConfigSystem.CurrentConfig)
end)

local guiLocked = ConfigSystem.CurrentConfig.toggles["Lock Gui"] == true

-- Save Gui Position toggle
makeIosToggle("Save Gui Position", credScroll, 7, function(state)
    saveGuiPos = state
    if state then
        -- Terus save semasa positions bila toggle on
        if not ConfigSystem.CurrentConfig.guiPositions then
            ConfigSystem.CurrentConfig.guiPositions = {}
        end
        local mp = mainFrame.AbsolutePosition
        local mnp = menuFrame.AbsolutePosition
        local cp = creditFrame.AbsolutePosition
        ConfigSystem.CurrentConfig.guiPositions.main   = { x = mp.X,  y = mp.Y  }
        ConfigSystem.CurrentConfig.guiPositions.menu   = { x = mnp.X, y = mnp.Y }
        ConfigSystem.CurrentConfig.guiPositions.credit = { x = cp.X,  y = cp.Y  }
        ConfigSystem:Save(ConfigSystem.CurrentConfig)
    end
end)

-- Reset Gui Position button
makeCardBtn("Reset Gui Position", "97462463002118", credScroll, 8, function()
    mainFrame.Position   = MAIN_DEFAULT_POS
    menuFrame.Position   = MENU_DEFAULT_POS
    creditFrame.Position = CREDIT_DEFAULT_POS
    ConfigSystem.CurrentConfig.guiPositions = nil
    ConfigSystem:Save(ConfigSystem.CurrentConfig)
    showNotification({ message = "Gui Position Reset", barColor = "Default", textColor = "Default" })
end, true)

-- Gui Scale row
local scaleRow = Instance.new("Frame")
scaleRow.Size = UDim2.new(1, 0, 0, 28)
scaleRow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scaleRow.BackgroundTransparency = 0.17
scaleRow.BorderSizePixel = 0
scaleRow.LayoutOrder = 9
scaleRow.Parent = credScroll

local scaleRowCorner = Instance.new("UICorner")
scaleRowCorner.CornerRadius = UDim.new(0, 6)
scaleRowCorner.Parent = scaleRow

local scaleRowStroke = Instance.new("UIStroke")
scaleRowStroke.Thickness = 1
scaleRowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
scaleRowStroke.Color = Color3.fromRGB(40, 40, 52)
scaleRowStroke.Parent = scaleRow

local scaleLbl = Instance.new("TextLabel")
scaleLbl.Size = UDim2.new(0, 55, 1, 0)
scaleLbl.Position = UDim2.new(0, 8, 0, 0)
scaleLbl.BackgroundTransparency = 1
scaleLbl.Text = "Gui Scale"
scaleLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
scaleLbl.TextStrokeTransparency = 1
scaleLbl.TextSize = 10
scaleLbl.Font = Enum.Font.Gotham
scaleLbl.TextXAlignment = Enum.TextXAlignment.Left
scaleLbl.Parent = scaleRow

local initPct = math.floor(((currentScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)) * 100 + 0.5)

local scaleValLbl = Instance.new("TextLabel")
scaleValLbl.Size = UDim2.new(0, 30, 1, 0)
scaleValLbl.Position = UDim2.new(1, -34, 0, 0)
scaleValLbl.BackgroundTransparency = 1
scaleValLbl.Text = initPct .. "%"
scaleValLbl.TextColor3 = Color3.fromRGB(140, 140, 255)
scaleValLbl.TextStrokeTransparency = 1
scaleValLbl.TextSize = 10
scaleValLbl.Font = Enum.Font.GothamBold
scaleValLbl.TextXAlignment = Enum.TextXAlignment.Right
scaleValLbl.Parent = scaleRow

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -106, 0, 5)
sliderBg.Position = UDim2.new(0, 68, 0.5, -2)
sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = scaleRow

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(1, 0)
sliderBgCorner.Parent = sliderBg

local initDelta = (currentScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(initDelta, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

local sliderThumb = Instance.new("Frame")
sliderThumb.Size = UDim2.new(0, 11, 0, 11)
sliderThumb.Position = UDim2.new(initDelta, -5.5, 0.5, -5.5)
sliderThumb.BackgroundColor3 = Color3.fromRGB(180, 180, 255)
sliderThumb.BorderSizePixel = 0
sliderThumb.ZIndex = 2
sliderThumb.Parent = sliderBg

local sliderThumbCorner = Instance.new("UICorner")
sliderThumbCorner.CornerRadius = UDim.new(1, 0)
sliderThumbCorner.Parent = sliderThumb

local sliderClickDetector = Instance.new("TextButton")
sliderClickDetector.Size = UDim2.new(1, 0, 1, 0)
sliderClickDetector.BackgroundTransparency = 1
sliderClickDetector.Text = ""
sliderClickDetector.ZIndex = 5
sliderClickDetector.Parent = scaleRow

local scaleDragging = false
local scaleMoveConn, scaleReleaseConn

sliderClickDetector.InputBegan:Connect(function(input)
    if scaleDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local isTouch = (input.UserInputType == Enum.UserInputType.Touch)
        scaleDragging = true

        local function updateScale()
            local inputPos = isTouch and input.Position.X or Services.Input:GetMouseLocation().X
            local delta = math.clamp((inputPos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newScale = math.floor(GUI_SCALE_MIN + delta * (GUI_SCALE_MAX - GUI_SCALE_MIN) + 0.5)
            local snappedDelta = (newScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
            local pct = math.floor(snappedDelta * 100 + 0.5)
            Services.Tween:Create(sliderFill, TweenInfo.new(0.05), {Size = UDim2.new(snappedDelta, 0, 1, 0)}):Play()
            Services.Tween:Create(sliderThumb, TweenInfo.new(0.05), {Position = UDim2.new(snappedDelta, -5.5, 0.5, -5.5)}):Play()
            scaleValLbl.Text = pct .. "%"
            applyGuiScale(newScale)
        end

        updateScale()
        scaleMoveConn = Services.RunService.RenderStepped:Connect(updateScale)
        scaleReleaseConn = Services.Input.InputEnded:Connect(function(endInput)
            if endInput == input then
                if scaleMoveConn then scaleMoveConn:Disconnect() end
                if scaleReleaseConn then scaleReleaseConn:Disconnect() end
                scaleDragging = false
            end
        end)
    end
end)

local function doResetScale()
    local defDelta = (GUI_SCALE_DEFAULT - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
    local defPct = math.floor(defDelta * 100 + 0.5)
    Services.Tween:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(defDelta, 0, 1, 0)}):Play()
    Services.Tween:Create(sliderThumb, TweenInfo.new(0.15), {Position = UDim2.new(defDelta, -5.5, 0.5, -5.5)}):Play()
    scaleValLbl.Text = defPct .. "%"
    applyGuiScale(GUI_SCALE_DEFAULT)
end

resetScaleCredit.MouseButton1Click:Connect(doResetScale)

-- =====================
-- SET DEFAULT TAB + STARTUP
-- =====================
setActiveTab("Features")

task.defer(function()
    -- Load saved scale
    if ConfigSystem.CurrentConfig.guiScale then
        applyGuiScale(ConfigSystem.CurrentConfig.guiScale, true)
        local savedDelta = (ConfigSystem.CurrentConfig.guiScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
        sliderFill.Size = UDim2.new(savedDelta, 0, 1, 0)
        sliderThumb.Position = UDim2.new(savedDelta, -5.5, 0.5, -5.5)
        scaleValLbl.Text = math.floor(savedDelta * 100 + 0.5) .. "%"
    end

    -- Load saved positions (guna AbsolutePosition method)
    loadGuiPositions(mainFrame, menuFrame, creditFrame)

    -- Setup custom drag SELEPAS positions loaded
    -- Pakai flag guiLocked untuk check Lock Gui state
    setupDrag(mainFrame,   "main")
    setupDrag(menuFrame,   "menu")
    setupDrag(creditFrame, "credit")
end)

-- =====================
-- MENU TOGGLE LOGIC
-- =====================
local menuOpen = false

closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
    menuOpen = false
    menuToggle.TextColor3 = Color3.fromRGB(150, 150, 165)
    menuToggleStroke.Color = Color3.fromRGB(70, 70, 85)
    Services.Tween:Create(menuToggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
end)

menuToggle.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        menuFrame.Visible = true
        menuToggle.TextColor3 = Color3.fromRGB(220, 220, 235)
        menuToggleStroke.Color = Color3.fromRGB(150, 150, 165)
        Services.Tween:Create(menuToggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    else
        menuFrame.Visible = false
        menuToggle.TextColor3 = Color3.fromRGB(150, 150, 165)
        menuToggleStroke.Color = Color3.fromRGB(70, 70, 85)
        Services.Tween:Create(menuToggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
    end
end)
