-- DevHub GUI — Slightly Transparent + Toggle Animation + Red Toggles + Discord Link
-- Made by flyx, lysy | Big thanks to: fizzler
-- Improved by Grok: Added Credits tab content, example implementations for some toggles, minor fixes.
-- Added: Integration for Stealing Tools GUI as a separate toggle-activated UI.
-- Updated: Inf Jump with velocity-based implementation, Added Slow Falling with very slow descent.
-- Added: Aimbot functionality without separate GUI, integrated into toggle.
-- Added: Auto Destroy Sentry and Speed Boost Steal without GUI, integrated into toggles.
-- Added: ESP Player, ESP Base Timer, updated ESP Best Brainrot, X-Ray Base without GUI, integrated into toggles.
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local GuiService = game:GetService('GuiService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local camera = Workspace.CurrentCamera
-- Device detection
local screenSize = camera.ViewportSize
local deviceType
if screenSize.X <= 900 then
    deviceType = 'Mobile'
elseif screenSize.X <= 1400 then
    deviceType = 'iPad'
else
    deviceType = 'PC'
end
local frameSizes = {
    Mobile = UDim2.new(0, 400, 0, 260),
    iPad = UDim2.new(0, 460, 0, 280),
    PC = UDim2.new(0, 520, 0, 300),
}
local frameSize = frameSizes[deviceType] or frameSizes.PC
local framePos =
    UDim2.new(0.5, -frameSize.X.Offset / 2, 0.5, -frameSize.Y.Offset / 2)
-- Colors
local COLOR_BG = Color3.fromRGB(15, 15, 15)
local COLOR_PANEL_BG = Color3.fromRGB(20, 20, 20) -- slightly transparent background
local COLOR_TAB_ACTIVE = Color3.fromRGB(255, 0, 0)
local COLOR_TAB_INACTIVE = Color3.fromRGB(160, 0, 0)
local COLOR_TOGGLE_OFF = Color3.fromRGB(70, 70, 70)
local COLOR_TEXT = Color3.fromRGB(200, 200, 200)
-- ScreenGui
local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'DevHub_GUI_Final'
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
-- Main Frame
local frame = Instance.new('Frame')
frame.Name = 'DevHubMain'
frame.Size = frameSize
frame.Position = framePos
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = COLOR_BG
frame.BackgroundTransparency = 0.25
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
local mainCorner = Instance.new('UICorner')
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = frame
-- Outline animation
local outline = Instance.new('UIStroke')
outline.Parent = frame
outline.Thickness = 4
outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outline.LineJoinMode = Enum.LineJoinMode.Round
outline.Color = COLOR_TAB_ACTIVE
task.spawn(function()
    local info =
        TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    while true do
        TweenService:Create(outline, info, { Color = Color3.fromRGB(0, 0, 0) })
            :Play()
        task.wait(0.9)
        TweenService:Create(outline, info, { Color = COLOR_TAB_ACTIVE }):Play()
        task.wait(0.9)
    end
end)
-- Header
local header = Instance.new('TextLabel')
header.Parent = frame
header.Size = UDim2.new(0, 120, 0, 30)
header.Position = UDim2.new(0, 10, 0, 8)
header.BackgroundTransparency = 1
header.Font = Enum.Font.GothamBold
header.TextSize = 22
header.Text = 'DevHub'
header.TextColor3 = COLOR_TAB_ACTIVE
-- Tabs
local tabNames = { 'Main', 'ESP', 'Misc', 'Credits' }
local tabButtons = {}
local frameHeight = frame.Size.Y.Offset
local tabHeight, tabGap = 35, 10
local totalTabsHeight = (#tabNames * tabHeight) + ((#tabNames - 1) * tabGap)
local startY = (frameHeight - totalTabsHeight) / 2
for i, name in ipairs(tabNames) do
    local btn = Instance.new('TextButton')
    btn.Name = name .. 'Tab'
    btn.Parent = frame
    btn.Size = UDim2.new(0, 92, 0, tabHeight)
    btn.Position = UDim2.new(0, 19, 0, startY + (i - 1) * (tabHeight + tabGap))
    btn.BackgroundColor3 = COLOR_PANEL_BG
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.Text = name
    btn.TextSize = 18
    btn.TextColor3 = COLOR_TAB_INACTIVE
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    local stroke = Instance.new('UIStroke')
    stroke.Parent = btn
    stroke.Thickness = 2
    stroke.Color = COLOR_TAB_INACTIVE
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    task.spawn(function()
        local info = TweenInfo.new(0.9, Enum.EasingStyle.Linear)
        while true do
            TweenService
                :Create(stroke, info, { Color = Color3.fromRGB(0, 0, 0) })
                :Play()
            task.wait(0.9)
            TweenService:Create(stroke, info, { Color = COLOR_TAB_ACTIVE })
                :Play()
            task.wait(0.9)
        end
    end)
    tabButtons[name] = btn
end
-- Right Content Area
local contentArea = Instance.new('Frame')
contentArea.Parent = frame
contentArea.Size = UDim2.new(1, -140, 1, -20)
contentArea.Position = UDim2.new(0, 130, 0, 10)
contentArea.BackgroundColor3 = COLOR_PANEL_BG
contentArea.BackgroundTransparency = 0.35 -- slightly darker panel
contentArea.BorderSizePixel = 0
local contentCorner = Instance.new('UICorner')
contentCorner.CornerRadius = UDim.new(0, 12)
contentCorner.Parent = contentArea
local pageTitle = Instance.new('TextLabel')
pageTitle.Parent = contentArea
pageTitle.Size = UDim2.new(1, 0, 0, 36)
pageTitle.Position = UDim2.new(0, 0, 0, 6)
pageTitle.BackgroundTransparency = 1
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextSize = 20
pageTitle.TextColor3 = COLOR_TAB_ACTIVE
pageTitle.Text = 'Main'
-- Scroll
local scroll = Instance.new('ScrollingFrame')
scroll.Parent = contentArea
scroll.Position = UDim2.new(0, 10, 0, 46)
scroll.Size = UDim2.new(1, -20, 1, -56)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = COLOR_TAB_ACTIVE
scroll.BackgroundTransparency = 1
local listLayout = Instance.new('UIListLayout')
listLayout.Parent = scroll
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local padding = Instance.new('UIPadding')
padding.Parent = scroll
padding.PaddingTop = UDim.new(0, 6)
listLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    scroll.CanvasSize =
        UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
end)
-- Minimize Button (Circle DH)
local minimizeButton = Instance.new('TextButton')
minimizeButton.Parent = screenGui
minimizeButton.Size = UDim2.new(0, 50, 0, 50)
minimizeButton.Position = UDim2.new(1, -60, 0, 10)
minimizeButton.BackgroundColor3 = COLOR_BG
minimizeButton.BackgroundTransparency = 0.25
minimizeButton.Text = 'DH'
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 20
minimizeButton.TextColor3 = COLOR_TAB_ACTIVE
local minCorner = Instance.new('UICorner')
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = minimizeButton
local minStroke = Instance.new('UIStroke')
minStroke.Parent = minimizeButton
minStroke.Thickness = 2
minStroke.Color = COLOR_TAB_ACTIVE
task.spawn(function()
    local info =
        TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    while true do
        TweenService
            :Create(minStroke, info, { Color = Color3.fromRGB(0, 0, 0) })
            :Play()
        task.wait(0.9)
        TweenService:Create(minStroke, info, { Color = COLOR_TAB_ACTIVE })
            :Play()
        task.wait(0.9)
    end
end)
minimizeButton.Visible = true
local guiVisible = true
frame.Visible = guiVisible
minimizeButton.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    frame.Visible = guiVisible
end)
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    minimizeButton.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

minimizeButton.InputBegan:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging = true
        dragStart = input.Position
        startPos = minimizeButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

minimizeButton.InputChanged:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input == dragInput) then
        update(input)
    end
end)
-- Toggle visuals
local ToggleStates = {}
local function createToggle(labelText, callback)
    local container = Instance.new('Frame')
    container.Size = UDim2.new(0.95, 0, 0, 46)
    container.BackgroundTransparency = 1
    local lbl = Instance.new('TextLabel')
    lbl.Parent = container
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 18
    lbl.TextColor3 = COLOR_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local toggle = Instance.new('Frame')
    toggle.Parent = container
    toggle.Size = UDim2.new(0, 64, 0, 30)
    toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, -10, 0.5, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggle.BorderSizePixel = 0
    local tcorner = Instance.new('UICorner')
    tcorner.CornerRadius = UDim.new(0, 16)
    tcorner.Parent = toggle
    local knob = Instance.new('Frame')
    knob.Parent = toggle
    knob.Size = UDim2.new(0, 26, 0, 26)
    knob.Position = UDim2.new(0, 3, 0.5, -13)
    knob.BackgroundColor3 = COLOR_TOGGLE_OFF
    knob.BorderSizePixel = 0
    local kcorner = Instance.new('UICorner')
    kcorner.CornerRadius = UDim.new(0, 13)
    kcorner.Parent = knob
    ToggleStates[labelText] = ToggleStates[labelText] or false
    local state = ToggleStates[labelText]
    knob.BackgroundColor3 = state and COLOR_TAB_ACTIVE or COLOR_TOGGLE_OFF
    knob.Position = state and UDim2.new(1, -29, 0.5, -13)
        or UDim2.new(0, 3, 0.5, -13)
    local function toggleAnim()
        local state = not ToggleStates[labelText]
        ToggleStates[labelText] = state
        local targetColor = state and COLOR_TAB_ACTIVE or COLOR_TOGGLE_OFF
        local targetPos = state and UDim2.new(1, -29, 0.5, -13)
            or UDim2.new(0, 3, 0.5, -13)
        local info =
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(
            knob,
            info,
            { BackgroundColor3 = targetColor, Position = targetPos }
        ):Play()
        if callback then
            pcall(callback, state)
        end
    end
    container.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            toggleAnim()
        end
    end)
    return container
end
-- ESP Best Brainrot logic
local activeBestBrainrotESPs = {}
local function clearESP(model)
    local esp = activeBestBrainrotESPs[model]
    if esp then
        if esp[4] then
            esp[4]:Disconnect()
        end
        if esp[1] then
            esp[1]:Destroy()
        end
        if esp[2] then
            esp[2]:Destroy()
        end
        activeBestBrainrotESPs[model] = nil
    end
end
-- Implementations for toggles
local infJumpConnection = nil
local function toggleInfJump(state)
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    if state then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = player.Character
            if char and char:FindFirstChild('HumanoidRootPart') then
                char.HumanoidRootPart.Velocity = Vector3.new(
                    char.HumanoidRootPart.Velocity.X,
                    50,
                    char.HumanoidRootPart.Velocity.Z
                )
            end
        end)
    end
end
local slowFallConn = nil
local function toggleSlowFalling(state)
    if slowFallConn then
        slowFallConn:Disconnect()
        slowFallConn = nil
    end
    if state then
        slowFallConn = RunService.RenderStepped:Connect(function()
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild('HumanoidRootPart')
                if hrp and hrp.Velocity.Y < 0 then
                    hrp.Velocity =
                        Vector3.new(hrp.Velocity.X, -10, hrp.Velocity.Z) -- Very slow fall (-10 studs/sec)
                end
            end
        end)
    end
end
local jumpBoostConnection = nil
local jumpBoostCanBoost = true
local function toggleJumpBoost(state)
    if jumpBoostConnection then
        jumpBoostConnection:Disconnect()
        jumpBoostConnection = nil
    end
    if state then
        local function setup()
            local char = player.Character
            if not char then
                return
            end
            local humanoid = char:FindFirstChildOfClass('Humanoid')
            local rootPart = char:FindFirstChild('HumanoidRootPart')
            if not humanoid or not rootPart then
                return
            end
            jumpBoostConnection = humanoid.StateChanged:Connect(
                function(_, newState)
                    if
                        newState == Enum.HumanoidStateType.Jumping
                        and jumpBoostCanBoost
                    then
                        local currentVel = rootPart.AssemblyLinearVelocity
                        rootPart.AssemblyLinearVelocity =
                            Vector3.new(currentVel.X, 100, currentVel.Z)
                        jumpBoostCanBoost = false
                    elseif newState == Enum.HumanoidStateType.Landed then
                        jumpBoostCanBoost = true
                    end
                end
            )
        end
        setup()
        player.CharacterAdded:Connect(setup)
    end
end
-- Aimbot logic
local aimbotConn = nil
local function toggleAimbot(state)
    if aimbotConn then
        aimbotConn:Disconnect()
        aimbotConn = nil
    end
    if state then
        local MAX_DISTANCE = 60
        local COOLDOWN = 0.1
        local OBSTACLE_DISABLE_TIME = 0.5

        local UseItemEvent
        pcall(function()
            UseItemEvent = ReplicatedStorage:WaitForChild('Packages')
                :WaitForChild('Net')
                :WaitForChild('RE/UseItem')
        end)

        local aimbotState = { aimbot = true, autoEnabled = true }

        local function getNearestPlayer()
            local char = player.Character
            if not char or not char:FindFirstChild('HumanoidRootPart') then
                return nil, math.huge
            end
            local myPos = char.HumanoidRootPart.Position
            local closest, closestDist = nil, math.huge
            for _, plr in pairs(Players:GetPlayers()) do
                if
                    plr ~= player
                    and plr.Character
                    and plr.Character:FindFirstChild('HumanoidRootPart')
                then
                    local d = (myPos - plr.Character.HumanoidRootPart.Position).Magnitude
                    if d < closestDist then
                        closest, closestDist = plr, d
                    end
                end
            end
            return closest, closestDist
        end

        local function chooseHitPart(char)
            for _, name in ipairs({
                'Head',
                'UpperTorso',
                'LowerTorso',
                'HumanoidRootPart',
            }) do
                local part = char:FindFirstChild(name)
                if part and part:IsA('BasePart') then
                    return part
                end
            end
            return char:FindFirstChildWhichIsA('BasePart')
        end

        local lastFire = 0
        aimbotConn = RunService.Heartbeat:Connect(function()
            if
                not aimbotState.aimbot
                or not aimbotState.autoEnabled
                or not UseItemEvent
            then
                return
            end
            if tick() - lastFire < COOLDOWN then
                return
            end

            local char = player.Character
            if not char or not char:FindFirstChild('HumanoidRootPart') then
                return
            end
            local tool = char:FindFirstChildOfClass('Tool')
            if not tool then
                return
            end

            local targetPlayer, dist = getNearestPlayer()
            if not targetPlayer or dist > MAX_DISTANCE then
                return
            end

            local hitPart = chooseHitPart(targetPlayer.Character)
            if not hitPart then
                return
            end
            local hitPos = hitPart.Position

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = { player.Character }
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = workspace:Raycast(
                char.HumanoidRootPart.Position,
                (hitPos - char.HumanoidRootPart.Position).Unit * dist,
                raycastParams
            )
            if result and result.Instance and result.Instance.CanCollide then
                result.Instance.CanCollide = false
                task.delay(OBSTACLE_DISABLE_TIME, function()
                    if result.Instance and result.Instance.Parent then
                        result.Instance.CanCollide = true
                    end
                end)
            end

            pcall(function()
                UseItemEvent:FireServer(hitPos, hitPart)
            end)

            lastFire = tick()
        end)
    end
end
-- Auto Destroy Sentry logic
local sentryTeleportConn = nil
local sentryEquipConn = nil
local function toggleAutoDestroySentry(state)
    if sentryTeleportConn then
        sentryTeleportConn:Disconnect()
        sentryTeleportConn = nil
    end
    if sentryEquipConn then
        sentryEquipConn:Disconnect()
        sentryEquipConn = nil
    end
    if state then
        local function teleportSentries()
            local char = player.Character
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            if not char or not hrp then
                return
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA('Part') and obj.Name:lower():find('sentry') then
                    local frontPos = hrp.CFrame * CFrame.new(0, 0, -4)
                    obj.CFrame = CFrame.new(frontPos.Position)
                    obj.CanCollide = false
                end
            end
        end
        local function equipBat()
            local char = player.Character
            if not char then
                return
            end
            local backpack = player:FindFirstChild('Backpack')
            if not backpack then
                return
            end
            local tool = backpack:FindFirstChild('Bat')
                or char:FindFirstChild('Bat')
            if tool then
                -- Equip tool
                if not char:FindFirstChild(tool.Name) then
                    tool.Parent = char
                end
                -- Activate tool
                if tool:IsA('Tool') then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
        sentryEquipConn = RunService.RenderStepped:Connect(equipBat)
        sentryTeleportConn = RunService.Heartbeat:Connect(teleportSentries) -- More efficient than while loop
        -- Handle CharacterAdded
        local charAddedConn
        charAddedConn = player.CharacterAdded:Connect(function(newChar)
            character = newChar
            hrp = newChar:WaitForChild('HumanoidRootPart')
        end)
    end
end
-- Speed Boost Steal logic
local speedBoostConn = nil
local function toggleSpeedBoostSteal(state)
    if speedBoostConn then
        speedBoostConn:Disconnect()
        speedBoostConn = nil
    end
    if state then
        local speedValue = 27 -- Adjusted from 30 to 27
        speedBoostConn = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass('Humanoid')
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            if humanoid and hrp and humanoid.MoveDirection.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = humanoid.MoveDirection.Unit
                        * speedValue
                    + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end)
        -- Handle CharacterAdded
        local charAddedConn
        charAddedConn = player.CharacterAdded:Connect(function(newChar)
            character = newChar
            humanoid = newChar:WaitForChild('Humanoid')
            humanoidRootPart = newChar:WaitForChild('HumanoidRootPart')
        end)
    end
end
-- ESP Player logic
local playerESP = {
    Enabled = false,
    Highlights = {},
    NameTags = {},
}
local function togglePlayerESP(state)
    playerESP.Enabled = state
    if not state then
        for character, _ in pairs(playerESP.Highlights) do
            playerESP:RemoveForCharacter(character)
        end
        playerESP.Highlights = {}
        playerESP.NameTags = {}
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            playerESP:CreateHighlightForCharacter(plr.Character)
            playerESP:CreateNameTag(plr, plr.Character)
        end
    end
    -- Connect to new players
    local playerAddedConn = Players.PlayerAdded:Connect(function(plr)
        if playerESP.Enabled then
            plr.CharacterAdded:Connect(function(char)
                playerESP:CreateHighlightForCharacter(char)
                playerESP:CreateNameTag(plr, char)
            end)
        end
    end)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
        if plr.Character then
            playerESP:RemoveForCharacter(plr.Character)
        end
    end)
    -- Periodic update
    local updateConn = RunService.Heartbeat:Connect(function()
        if playerESP.Enabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    playerESP:CreateHighlightForCharacter(plr.Character)
                    playerESP:CreateNameTag(plr, plr.Character)
                end
            end
        end
    end)
    -- Clean up when off
    if not state then
        playerAddedConn:Disconnect()
        playerRemovingConn:Disconnect()
        updateConn:Disconnect()
    end
end
function playerESP:CreateHighlightForCharacter(character)
    if not character or not character:IsA('Model') then
        return
    end
    if self.Highlights[character] then
        return
    end
    local highlight = Instance.new('Highlight')
    highlight.Name = 'ESPHighlight'
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    self.Highlights[character] = highlight
end
function playerESP:CreateNameTag(plr, character)
    if not plr or not character then
        return
    end
    if self.NameTags[character] then
        return
    end
    local head = character:FindFirstChild('Head')
    if not head then
        return
    end
    local billboard = Instance.new('BillboardGui')
    billboard.Name = 'ESPNameTag'
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    local textLabel = Instance.new('TextLabel')
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = plr.Name
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    self.NameTags[character] = billboard
end
function playerESP:RemoveForCharacter(character)
    if self.Highlights[character] then
        self.Highlights[character]:Destroy()
        self.Highlights[character] = nil
    end
    if self.NameTags[character] then
        self.NameTags[character]:Destroy()
        self.NameTags[character] = nil
    end
end
-- ESP Base Timer logic
local baseTimerConnection = nil
local function toggleBaseTimerESP(state)
    if baseTimerConnection then
        baseTimerConnection:Disconnect()
        baseTimerConnection = nil
        for _, plot in
            pairs(
                Workspace:FindFirstChild('Plots')
                        and Workspace.Plots:GetChildren()
                    or {}
            )
        do
            local purchases = plot:FindFirstChild('Purchases')
            if purchases then
                for _, child in pairs(purchases:GetChildren()) do
                    local main = child:FindFirstChild('Main')
                    if main then
                        local gui = main:FindFirstChild('GlobalTimerGui')
                        if gui then
                            gui:Destroy()
                        end
                    end
                end
            end
        end
        return
    end
    if state then
        local Plots = Workspace:FindFirstChild('Plots')
        local lastValues = {}
        local lastChange = {}
        local function getOrCreateTimerGui(main)
            if not main then
                return nil
            end
            local existing = main:FindFirstChild('GlobalTimerGui')
            if existing and existing:FindFirstChild('Label') then
                return existing.Label
            end
            local gui = Instance.new('BillboardGui')
            gui.Name = 'GlobalTimerGui'
            gui.Size = UDim2.new(0, 120, 0, 60)
            gui.StudsOffset = Vector3.new(0, 5, 0)
            gui.AlwaysOnTop = true
            gui.Parent = main
            local lbl = Instance.new('TextLabel')
            lbl.Name = 'Label'
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(220, 60, 60) -- ciemnoczerwony
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextScaled = true
            lbl.Text = '0'
            lbl.Parent = gui
            return lbl
        end
        local function findLowestFloor(purchases)
            local lowestFloor, lowestY = nil, math.huge
            for _, child in pairs(purchases:GetChildren()) do
                local main = child:FindFirstChild('Main')
                if main then
                    local lowestPart = nil
                    if main:IsA('Model') then
                        for _, part in pairs(main:GetDescendants()) do
                            if
                                part:IsA('BasePart')
                                and (
                                    not lowestPart
                                    or part.Position.Y
                                        < lowestPart.Position.Y
                                )
                            then
                                lowestPart = part
                            end
                        end
                    elseif main:IsA('BasePart') then
                        lowestPart = main
                    end
                    if lowestPart and lowestPart.Position.Y < lowestY then
                        lowestY = lowestPart.Position.Y
                        lowestFloor = child
                    end
                end
            end
            return lowestFloor
        end
        baseTimerConnection = RunService.RenderStepped:Connect(function()
            if not Plots then
                Plots = Workspace:FindFirstChild('Plots')
                if not Plots then
                    return
                end
            end
            local now = tick()
            for _, plot in pairs(Plots:GetChildren()) do
                local purchases = plot:FindFirstChild('Purchases')
                if purchases then
                    local lowestFloor = findLowestFloor(purchases)
                    if lowestFloor then
                        local main = lowestFloor:FindFirstChild('Main')
                        if main then
                            local remainingTime
                            for _, obj in pairs(main:GetDescendants()) do
                                if
                                    obj:IsA('TextLabel')
                                    and obj.Name == 'RemainingTime'
                                then
                                    remainingTime = obj
                                    break
                                end
                            end
                            local timerLabel = getOrCreateTimerGui(main)
                            if remainingTime then
                                local currentText = remainingTime.Text or '0'
                                local key = plot.Name
                                -- wykrywanie zmiany czasu
                                if lastValues[key] ~= currentText then
                                    lastValues[key] = currentText
                                    lastChange[key] = now
                                end
                                -- warunki zmiany tekstu
                                local numeric = tonumber(currentText)
                                local timeSinceChange = now
                                    - (lastChange[key] or 0)
                                if numeric and numeric <= 0 then
                                    timerLabel.Text = 'Unlocked'
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(0, 255, 0)
                                elseif timeSinceChange > 1 then
                                    -- czas się nie zmienia przez 1 sekundę → uznaj za unlocked
                                    timerLabel.Text = 'Unlocked'
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(0, 255, 0)
                                else
                                    -- czas się zmienia normalnie
                                    timerLabel.Text = currentText
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(220, 60, 60)
                                end
                            else
                                timerLabel.Text = 'Unlocked'
                                timerLabel.TextColor3 =
                                    Color3.fromRGB(0, 255, 0)
                            end
                        end
                    end
                end
            end
        end)
    end
end
-- Updated ESP Best Brainrot logic
local function parseNumber(txt)
    local cleaned = txt:gsub(',', ''):gsub('%s+', ''):gsub('%$', '')
    local num, suffix = cleaned:match('(%d+%.?%d*)([kKmMb]?)%/s')
    if not num then
        return nil
    end
    local value = tonumber(num)
    if not value then
        return nil
    end
    suffix = suffix:lower()
    if suffix == 'k' then
        value = value * 1e3
    elseif suffix == 'm' then
        value = value * 1e6
    elseif suffix == 'b' then
        value = value * 1e9
    end
    return value
end
local function getRainbowColor()
    local t = tick() * 2
    local r = math.floor((math.sin(t) * 127 + 128))
    local g = math.floor((math.sin(t + 2) * 127 + 128))
    local b = math.floor((math.sin(t + 4) * 127 + 128))
    return Color3.fromRGB(r, g, b)
end
local function getColorFromModel(model, labelText)
    local modelName = (model.Name or ''):lower()
    local text = (labelText or ''):lower()
    local fullText = modelName .. ' ' .. text
    if fullText:find('gold') then
        return Color3.fromRGB(255, 215, 0)
    elseif fullText:find('diamond') then
        return Color3.fromRGB(0, 170, 255)
    elseif fullText:find('rainbow') then
        return 'rainbow'
    elseif fullText:find('lava') then
        return Color3.fromRGB(255, 69, 0)
    elseif fullText:find('bloodrot') then
        return Color3.fromRGB(139, 0, 0)
    elseif fullText:find('candy') then
        return Color3.fromRGB(255, 105, 180)
    elseif fullText:find('galaxy') then
        return Color3.fromRGB(170, 0, 255)
    elseif fullText:find('yin yang') then
        return Color3.fromRGB(255, 255, 255)
    elseif fullText:find('chocolate') then
        return Color3.fromRGB(139, 69, 19)
    elseif fullText:find('pollinated') then
        return Color3.fromRGB(255, 255, 0)
    elseif fullText:find('frozen') then
        return Color3.fromRGB(173, 216, 230)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end
local function createESP(model, displayText)
    local color = getColorFromModel(model, displayText)
    local highlight = Instance.new('Highlight')
    highlight.Name = 'BrainrotESPHighlight'
    highlight.Adornee = model
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    if color ~= 'rainbow' then
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
    highlight.Parent = Workspace -- Parent to Workspace
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart')
    if not part then
        return highlight, nil, nil
    end
    local tag = Instance.new('BillboardGui')
    tag.Name = 'BrainrotESPTag'
    tag.Size = UDim2.new(0, 200, 0, 50)
    tag.AlwaysOnTop = true
    tag.StudsOffset = Vector3.new(0, 8, 0)
    tag.Adornee = part
    tag.Parent = Workspace -- Parent to Workspace
    local label = Instance.new('TextLabel')
    label.Name = 'NameText'
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = displayText or model.Name
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = (color == 'rainbow') and getRainbowColor() or color
    label.Parent = tag
    return highlight, tag, label
end
local function getBestBrainrots()
    local maxValue = -1
    local bestLabel = nil
    if not Workspace:FindFirstChild('Plots') then
        return {}
    end
    for _, plot in pairs(Workspace.Plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA('TextLabel') then
                local txt = obj.Text or ''
                if txt:find('/') and txt:lower():find('s') then
                    local val = parseNumber(txt)
                    if val and val > maxValue then
                        maxValue = val
                        bestLabel = obj
                    end
                end
            end
        end
    end
    local results = {}
    if bestLabel then
        local model = bestLabel:FindFirstAncestorOfClass('Model')
        if model then
            table.insert(results, { model, bestLabel.Text })
        end
    end
    return results
end
local bestBrainrotConn = nil
local function toggleBestBrainrotESP(state)
    if bestBrainrotConn then
        bestBrainrotConn:Disconnect()
        bestBrainrotConn = nil
    end
    for model in pairs(activeBestBrainrotESPs) do
        clearESP(model)
    end
    activeBestBrainrotESPs = {}
    if state then
        bestBrainrotConn = RunService.Heartbeat:Connect(function()
            local bestModels = getBestBrainrots()
            local newSet = {}
            for _, data in ipairs(bestModels) do
                local model, labelText = data[1], data[2]
                if model and model.Parent then
                    newSet[model] = true
                    if activeBestBrainrotESPs[model] then
                        local esp = activeBestBrainrotESPs[model]
                        local part = model.PrimaryPart
                            or model:FindFirstChildWhichIsA('BasePart')
                        if part and esp[2] then
                            esp[2].Adornee = part
                        end
                        local color = getColorFromModel(model, labelText)
                        if color == 'rainbow' then
                            local rainbow = getRainbowColor()
                            esp[3].TextColor3 = rainbow
                            esp[1].FillColor = rainbow
                            esp[1].OutlineColor = rainbow
                        else
                            esp[3].TextColor3 = color
                            esp[1].FillColor = color
                            esp[1].OutlineColor = color
                        end
                        if esp[3].Text ~= labelText then
                            esp[3].Text = labelText
                        end
                    else
                        local highlight, tag, label =
                            createESP(model, labelText)
                        local conn = RunService.Heartbeat:Connect(function()
                            if not model.Parent then
                                clearESP(model)
                                conn:Disconnect()
                            end
                        end)
                        activeBestBrainrotESPs[model] =
                            { highlight, tag, label, conn }
                    end
                end
            end
            -- Remove old ESPs
            for model in pairs(activeBestBrainrotESPs) do
                if not newSet[model] or not model.Parent then
                    clearESP(model)
                end
            end
        end)
    end
end
-- X-Ray Base logic
local xrayConnection = nil
local originalTrans = {}
local function toggleXRay(state)
    if xrayConnection then
        xrayConnection:Disconnect()
        xrayConnection = nil
    end
    for obj, trans in pairs(originalTrans) do
        if obj and obj.Parent then
            pcall(function()
                obj.Transparency = trans
            end)
        end
    end
    originalTrans = {}
    if state then
        xrayConnection = RunService.Heartbeat:Connect(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if
                    obj:IsA('BasePart')
                    and obj.Parent ~= camera
                    and obj.Parent ~= player.Character
                then
                    if not originalTrans[obj] then
                        originalTrans[obj] = obj.Transparency
                    end
                    if
                        obj.Parent:FindFirstChild('Humanoid')
                        and obj.Parent ~= player.Character
                    then
                        obj.Transparency = 0.3
                    elseif
                        obj.Name:lower():find('wall')
                        or obj.Name:lower():find('base')
                        or obj.Name:lower():find('plot')
                    then
                        obj.Transparency = 0.7
                    end
                end
            end
        end)
    end
end
-- Stealing Tools GUI integration
local stealingToolsGui = nil
local function toggleStealingTools(state)
    if state then
        -- Create and show Stealing Tools GUI
        if playerGui:FindFirstChild('STEALING_TOOLS_UI') then
            playerGui.STEALING_TOOLS_UI:Destroy()
        end
        -- 🕹️ STEALING TOOLS GUI (Pixel Style + Transparent + Draggable + Toggles)
        local function make(class, props)
            local obj = Instance.new(class)
            for k, v in pairs(props) do
                obj[k] = v
            end
            return obj
        end
        local screen = make('ScreenGui', {
            Name = 'STEALING_TOOLS_UI',
            Parent = playerGui,
            ResetOnSpawn = false,
        })
        local main = make('Frame', {
            Parent = screen,
            Size = UDim2.new(0, 260, 0, 380),
            Position = UDim2.new(0.5, -130, 0.5, -190),
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
        })
        make('UICorner', { Parent = main, CornerRadius = UDim.new(0, 14) })
        make('TextLabel', {
            Parent = main,
            Text = 'STEALING TOOLS',
            Font = Enum.Font.Code,
            TextSize = 22,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
        })
        local layout = make('UIListLayout', {
            Parent = main,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        local function makeToggleButton(text, parent)
            local btn = make('TextButton', {
                Parent = parent,
                Size = UDim2.new(0.9, 0, 0, 44),
                Text = text .. ' [OFF]',
                Font = Enum.Font.Code,
                TextSize = 18,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundColor3 = Color3.fromRGB(170, 0, 0),
                BorderSizePixel = 0,
            })
            make('UICorner', { Parent = btn, CornerRadius = UDim.new(0, 6) })
            return btn
        end
        local btnInvisible = makeToggleButton('INVISIBLE', main)
        local btnStealFloor = makeToggleButton('STEAL FLOOR', main)
        local btnFlyToBest = makeToggleButton('FLY TO BEST', main)
        local toggles = {
            INVISIBLE = false,
            STEAL_FLOOR = false,
            FLY_TO_BEST = false,
        }
        local function toggleButton(btn, key, displayName)
            if not toggles[key] then
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                btn.Text = displayName .. ' [ON]'
                toggles[key] = true
            else
                btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                btn.Text = displayName .. ' [OFF]'
                toggles[key] = false
            end
        end
        local function getCharacter()
            return player.Character or player.CharacterAdded:Wait()
        end
        local function freezeCharacter(character)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.Anchored = true
                end
            end
            local humanoid = character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid.PlatformStand = true
            end
        end
        local function unfreezeCharacter(character)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.Anchored = false
                end
            end
            local humanoid = character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
        local function noClipCharacter(character)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.CanCollide = false
                end
            end
        end
        local function resetCollisions(character)
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.CanCollide = true
                end
            end
        end
        local notifyBar = make('Frame', {
            Size = UDim2.new(0, 350, 0, 50),
            Position = UDim2.new(0.5, -175, 0.3, -25),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Visible = false,
            Parent = screen,
        })
        make('UICorner', { Parent = notifyBar, CornerRadius = UDim.new(0, 10) })
        make(
            'UIStroke',
            {
                Parent = notifyBar,
                Thickness = 2,
                Color = Color3.fromRGB(100, 100, 100),
            }
        )
        local notifyText = make('TextLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 20,
            Text = '',
            Parent = notifyBar,
        })
        local function showNotification(text, color)
            notifyText.TextColor3 = color
            notifyText.Text = text
            notifyBar.Visible = true
            TweenService:Create(
                notifyBar,
                TweenInfo.new(0.25),
                { BackgroundTransparency = 0 }
            ):Play()
            task.wait(5)
            TweenService:Create(
                notifyBar,
                TweenInfo.new(0.25),
                { BackgroundTransparency = 1 }
            ):Play()
            task.wait(0.25)
            notifyBar.Visible = false
        end
        local function activateInvisible()
            local character = getCharacter()
            local hrp = character:WaitForChild('HumanoidRootPart')
            local camCFrame = camera.CFrame
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = camCFrame
            unfreezeCharacter(character)
            noClipCharacter(character)
            if hrp then
                character:PivotTo(hrp.CFrame - Vector3.new(0, 70, 0))
            end
            task.wait(0.1)
            freezeCharacter(character)
            showNotification('⚠️Wait⚠️', Color3.fromRGB(255, 255, 0))
            task.wait(0.5) -- Adjusted for 1 second separation
            unfreezeCharacter(character)
            noClipCharacter(character)
            if hrp then
                character:PivotTo(hrp.CFrame - Vector3.new(0, 70, 0))
            end
            task.wait(0.1)
            freezeCharacter(character)
            showNotification(
                '✅ Success! You are Invisible Now',
                Color3.fromRGB(0, 255, 0)
            )
            task.delay(0, function()
                camera.CameraType = Enum.CameraType.Custom
            end)
        end
        local function deactivateInvisible()
            local character = getCharacter()
            unfreezeCharacter(character)
            resetCollisions(character)
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
        local function addHighlight()
            local character = getCharacter()
            local hrp = character:WaitForChild('HumanoidRootPart')
            local highlight = Instance.new('SelectionBox')
            highlight.Adornee = hrp
            highlight.LineThickness = 0.05
            highlight.Color3 = Color3.fromRGB(255, 0, 0)
            highlight.Transparency = 0.5
            highlight.Parent = hrp
        end
        addHighlight()
        local platform
        local followConn
        local stealFloorHRP
        local originalTrans = {}
        local xrayConnection
        local function setupStealFloorCharacter(char)
            stealFloorHRP = char:WaitForChild('HumanoidRootPart')
        end
        local function createPlatform()
            if platform then
                return
            end
            platform = Instance.new('Part')
            platform.Size = Vector3.new(5, 0.6, 5)
            platform.Anchored = true
            platform.CanCollide = true
            platform.Material = Enum.Material.Metal
            platform.Color = Color3.fromRGB(255, 0, 0)
            platform.Name = 'LiftPlatform'
            platform.Parent = Workspace
        end
        local function followPlayer()
            if followConn then
                followConn:Disconnect()
            end
            followConn = RunService.Heartbeat:Connect(function()
                if not platform or not stealFloorHRP then
                    return
                end
                local targetPos = Vector3.new(
                    stealFloorHRP.Position.X,
                    stealFloorHRP.Position.Y - 2.5,
                    stealFloorHRP.Position.Z
                )
                platform.CFrame = CFrame.new(targetPos)
            end)
        end
        local function destroyPlatform()
            if followConn then
                followConn:Disconnect()
                followConn = nil
            end
            if platform then
                platform:Destroy()
                platform = nil
            end
        end
        local function toggleXRay(state)
            if xrayConnection then
                xrayConnection:Disconnect()
                xrayConnection = nil
            end
            for obj, trans in pairs(originalTrans) do
                if obj and obj.Parent then
                    pcall(function()
                        obj.Transparency = trans
                    end)
                end
            end
            originalTrans = {}
            if state then
                xrayConnection = RunService.Heartbeat:Connect(function()
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if
                            obj:IsA('BasePart')
                            and obj.Parent ~= camera
                            and obj.Parent ~= player.Character
                        then
                            if not originalTrans[obj] then
                                originalTrans[obj] = obj.Transparency
                            end
                            if
                                obj.Parent:FindFirstChild('Humanoid')
                                and obj.Parent ~= player.Character
                            then
                                obj.Transparency = 0.3
                            elseif
                                obj.Name:lower():find('wall')
                                or obj.Name:lower():find('base')
                                or obj.Name:lower():find('plot')
                            then
                                obj.Transparency = 0.7
                            end
                        end
                    end
                end)
            end
        end
        if player.Character then
            setupStealFloorCharacter(player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            setupStealFloorCharacter(char)
        end)
        local running = false
        local linearVelocity
        local angularVelocity
        local mainConnection
        local touchConnection
        local STOP_PART_NAME = 'StopZone'
        local FLY_SPEED = 50
        local function getBestBrainrot()
            if not Workspace:FindFirstChild('Plots') then
                return nil
            end
            local bestValue = 0
            local bestPosition = nil
            for _, plot in pairs(Workspace.Plots:GetChildren()) do
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA('TextLabel') and obj.Text then
                        local text = obj.Text
                        if text:find('/s') then
                            local numberText =
                                text:gsub('%$', ''):gsub(',', ''):gsub('/s', '')
                            local numberStr = numberText:match('(%d+%.?%d*)')
                            local suffix = numberText:match('[KM]') or ''
                            local value = tonumber(numberStr) or 0
                            if suffix == 'K' then
                                value = value * 1000
                            elseif suffix == 'M' then
                                value = value * 1e6
                            end
                            if value > bestValue then
                                bestValue = value
                                local model =
                                    obj:FindFirstAncestorOfClass('Model')
                                if model then
                                    local part = model.PrimaryPart
                                        or model:FindFirstChildWhichIsA(
                                            'BasePart'
                                        )
                                    if part then
                                        bestPosition = part.Position
                                            + Vector3.new(0, 3, 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return bestPosition
        end
        local function startFlying(character)
            if not character then
                return
            end
            local humanoid = character:FindFirstChildOfClass('Humanoid')
            local rootPart = character:FindFirstChild('HumanoidRootPart')
            if not humanoid or not rootPart then
                return
            end
            local attachment = Instance.new('Attachment', rootPart)
            attachment.Name = 'FlyAttachment'
            linearVelocity = Instance.new('LinearVelocity', rootPart)
            linearVelocity.Attachment0 = attachment
            linearVelocity.MaxForce = 200000
            linearVelocity.Enabled = true
            angularVelocity = Instance.new('AngularVelocity', rootPart)
            angularVelocity.Attachment0 = attachment
            angularVelocity.MaxTorque = 200000
            angularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
            angularVelocity.Enabled = true
            humanoid.PlatformStand = true
        end
        local function stopFlying(character)
            if character then
                local humanoid = character:FindFirstChildOfClass('Humanoid')
                if humanoid then
                    humanoid.PlatformStand = false
                end
                if linearVelocity then
                    linearVelocity:Destroy()
                    linearVelocity = nil
                end
                if angularVelocity then
                    angularVelocity:Destroy()
                    angularVelocity = nil
                end
                local rootPart = character:FindFirstChild('HumanoidRootPart')
                if rootPart then
                    local attachment = rootPart:FindFirstChild('FlyAttachment')
                    if attachment then
                        attachment:Destroy()
                    end
                end
            end
        end
        local function flyToPosition(targetPosition)
            local character = player.Character
            if not character then
                return true
            end
            local rootPart = character:FindFirstChild('HumanoidRootPart')
            if not rootPart or not targetPosition then
                return true
            end
            local currentPos = rootPart.Position
            local direction = (targetPosition - currentPos)
            local distance = direction.Magnitude
            if distance < 10 then
                return true
            end
            if not linearVelocity then
                startFlying(character)
            end
            direction = direction.Unit
            local velocity = direction * FLY_SPEED
            local heightDiff = (targetPosition.Y - currentPos.Y)
            local verticalForce = math.clamp(heightDiff * 3, -50, 50)
            velocity = velocity + Vector3.new(0, verticalForce, 0)
            if linearVelocity then
                linearVelocity.VectorVelocity = velocity
            end
            local humanoid = character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid:MoveTo(targetPosition)
            end
            return false
        end
        local function useGrapple()
            local character = player.Character
            if character then
                local backpack = player:FindFirstChild('Backpack')
                if backpack then
                    local grapple = backpack:FindFirstChild('Grapple Hook')
                    if
                        grapple and not character:FindFirstChild('Grapple Hook')
                    then
                        grapple.Parent = character
                    end
                end
                local remote = ReplicatedStorage:WaitForChild('Packages')
                    :WaitForChild('Net')
                    :WaitForChild('RE/UseItem')
                local args = { 0 }
                remote:FireServer(unpack(args))
            end
        end
        local function setupTouchStop(character)
            if touchConnection then
                touchConnection:Disconnect()
            end
            local rootPart = character:FindFirstChild('HumanoidRootPart')
            if not rootPart then
                return
            end
            local stopPart = Workspace:FindFirstChild(STOP_PART_NAME)
            if not stopPart then
                warn('STOP PART NOT FOUND: ' .. STOP_PART_NAME)
                return
            end
            touchConnection = rootPart.Touched:Connect(function(hit)
                if hit == stopPart or hit:IsDescendantOf(stopPart) then
                    if toggles.FLY_TO_BEST then
                        print('TOUCHED STOP PART → SYSTEM STOPPED')
                        toggleButton(btnFlyToBest, 'FLY_TO_BEST', 'FLY TO BEST')
                        showNotification(
                            'Status: STOPPED (TOUCH)',
                            Color3.fromRGB(255, 150, 0)
                        )
                    end
                end
            end)
        end
        local function startFlyToBest()
            print(
                'SYSTEM: ACTIVATED - Flying to best Brainrot (SPEED: '
                    .. FLY_SPEED
                    .. ')'
            )
            local character = player.Character or player.CharacterAdded:Wait()
            setupTouchStop(character)
            mainConnection = RunService.Heartbeat:Connect(function()
                local character = player.Character
                if character and toggles.FLY_TO_BEST then
                    local targetPosition = getBestBrainrot()
                    if targetPosition then
                        local reached = flyToPosition(targetPosition)
                        if reached then
                            stopFlying(character)
                            task.wait(1)
                        else
                            useGrapple()
                        end
                    else
                        stopFlying(character)
                    end
                end
            end)
        end
        local function stopFlyToBest()
            if mainConnection then
                mainConnection:Disconnect()
                mainConnection = nil
            end
            if touchConnection then
                touchConnection:Disconnect()
                touchConnection = nil
            end
            stopFlying(player.Character)
            print('SYSTEM: STOPPED')
        end
        player.CharacterAdded:Connect(function(character)
            task.wait(2)
            if toggles.FLY_TO_BEST then
                print('Respawned → Restarting system...')
                stopFlyToBest()
                task.wait(1)
                startFlyToBest()
                setupTouchStop(character)
            end
        end)
        btnInvisible.MouseButton1Click:Connect(function()
            toggleButton(btnInvisible, 'INVISIBLE', 'INVISIBLE')
            if toggles.INVISIBLE then
                activateInvisible()
            else
                deactivateInvisible()
            end
        end)
        btnStealFloor.MouseButton1Click:Connect(function()
            toggleButton(btnStealFloor, 'STEAL_FLOOR', 'STEAL FLOOR')
            if toggles.STEAL_FLOOR then
                createPlatform()
                followPlayer()
                toggleXRay(true)
                showNotification(
                    '✅ Steal Floor Enabled!',
                    Color3.fromRGB(0, 255, 0)
                )
            else
                destroyPlatform()
                toggleXRay(false)
                showNotification(
                    '⚠️ Steal Floor Disabled!',
                    Color3.fromRGB(255, 0, 0)
                )
            end
        end)
        btnFlyToBest.MouseButton1Click:Connect(function()
            toggleButton(btnFlyToBest, 'FLY_TO_BEST', 'FLY TO BEST')
            if toggles.FLY_TO_BEST then
                startFlyToBest()
            else
                stopFlyToBest()
            end
        end)
        local dragging, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
        main.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if
                dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                )
            then
                update(input)
            end
        end)
        stealingToolsGui = screen -- Save reference to the new GUI
    else
        -- Destroy Stealing Tools GUI
        if stealingToolsGui then
            stealingToolsGui:Destroy()
            stealingToolsGui = nil
        elseif playerGui:FindFirstChild('STEALING_TOOLS_UI') then
            playerGui.STEALING_TOOLS_UI:Destroy()
        end
    end
end
-- Misc implementations
-- Ultra Speed
local ultraSpeedGrappleConn = nil
local ultraSpeedBoostConn = nil
local function toggleUltraSpeed(state)
    if ultraSpeedGrappleConn then
        ultraSpeedGrappleConn:Disconnect()
        ultraSpeedGrappleConn = nil
    end
    if ultraSpeedBoostConn then
        ultraSpeedBoostConn:Disconnect()
        ultraSpeedBoostConn = nil
    end
    if state then
        local UseItemEvent = ReplicatedStorage:WaitForChild('Packages')
            :WaitForChild('Net')
            :WaitForChild('RE/UseItem')
        local function keepGrappleHook()
            local char = player.Character
            if not char then
                return
            end
            local humanoid = char:FindFirstChildOfClass('Humanoid')
            local item = player.Backpack:FindFirstChild('Grapple Hook')
                or char:FindFirstChild('Grapple Hook')
            if not item then
                return
            end
            if item.Parent ~= char then
                humanoid:EquipTool(item)
            end
            if item.Parent == char then
                UseItemEvent:FireServer(0)
            end
        end
        ultraSpeedGrappleConn =
            RunService.RenderStepped:Connect(keepGrappleHook)
        local speedValue = 120
        ultraSpeedBoostConn = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass('Humanoid')
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            if humanoid and hrp and humanoid.MoveDirection.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = humanoid.MoveDirection.Unit
                        * speedValue
                    + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end)
        player.CharacterAdded:Connect(function(newChar)
            char = newChar
        end)
    end
end
-- Grapple Fly
local grappleFlyActive = false
local grappleFlySpeed = 110
local grappleFlyGrappleConn = nil
local grappleFlyRenderConn = nil
local function toggleGrappleFly(state)
    grappleFlyActive = state
    if grappleFlyGrappleConn then
        grappleFlyGrappleConn:Disconnect()
        grappleFlyGrappleConn = nil
    end
    if grappleFlyRenderConn then
        grappleFlyRenderConn:Disconnect()
        grappleFlyRenderConn = nil
    end
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass('Humanoid')
    local rootPart = char and char:FindFirstChild('HumanoidRootPart')
    if not state then
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
        return
    end
    if state then
        local UseItemEvent = ReplicatedStorage:WaitForChild('Packages')
            :WaitForChild('Net')
            :WaitForChild('RE/UseItem')
        grappleFlyGrappleConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then
                return
            end
            local humanoid = char:FindFirstChildOfClass('Humanoid')
            local item = player.Backpack:FindFirstChild('Grapple Hook')
                or char:FindFirstChild('Grapple Hook')
            if not item then
                return
            end
            if item.Parent ~= char then
                humanoid:EquipTool(item)
            end
            if item.Parent == char then
                UseItemEvent:FireServer(0)
            end
        end)
        grappleFlyRenderConn = RunService.RenderStepped:Connect(function(delta)
            local char = player.Character
            if not char then
                return
            end
            local humanoid = char:FindFirstChildOfClass('Humanoid')
            local rootPart = char:FindFirstChild('HumanoidRootPart')
            if not humanoid or not rootPart then
                return
            end
            if grappleFlyActive then
                humanoid.PlatformStand = true
                local cam = Workspace.CurrentCamera
                local inputVec = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    inputVec = inputVec + Vector3.new(0, 0, -1)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    inputVec = inputVec + Vector3.new(0, 0, 1)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    inputVec = inputVec + Vector3.new(-1, 0, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    inputVec = inputVec + Vector3.new(1, 0, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    inputVec = inputVec + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    inputVec = inputVec + Vector3.new(0, -1, 0)
                end
                if inputVec.Magnitude > 0 then
                    inputVec = inputVec.Unit * grappleFlySpeed
                    rootPart.Velocity = cam.CFrame:VectorToWorldSpace(inputVec)
                else
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                end
                rootPart.RotVelocity = Vector3.new(0, 0, 0)
                humanoid.AutoRotate = false
            else
                humanoid.PlatformStand = false
                humanoid.AutoRotate = true
            end
        end)
        player.CharacterAdded:Connect(function(newChar)
            humanoid = newChar:WaitForChild('Humanoid')
            rootPart = newChar:WaitForChild('HumanoidRootPart')
        end)
    end
end
-- Rejoin
local function toggleRejoin(state)
    if state then
        local Success, ErrorMessage = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        if ErrorMessage and not Success then
            warn(ErrorMessage)
        end
    end
end
-- Server Hop
local function toggleServerHop(state)
    if state then
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end
end
-- Tabs content
local lists = {
    Main = {
        'Stealing Tools',
        'Inf Jump',
        'Slow Falling',
        'Aimbot',
        'Auto Destroy Sentry',
        'Speed Boost Steal',
    },
    ESP = { 'ESP Player', 'ESP Base Timer', 'ESP Best Brainrot', 'X-Ray Base' },
    Misc = {
        'Jump Boost',
        'Ultra Speed',
        'Grapple Fly',
        'Rejoin',
        'Server Hop',
    },
}
local function populateTab(tab)
    for _, v in ipairs(scroll:GetChildren()) do
        if not v:IsA('UIListLayout') and not v:IsA('UIPadding') then
            v:Destroy()
        end
    end
    if tab == 'Credits' then
        -- Credits content
        local creditsText = Instance.new('TextLabel')
        creditsText.Parent = scroll
        creditsText.Size = UDim2.new(0.95, 0, 0, 120)
        creditsText.BackgroundTransparency = 1
        creditsText.Text =
            'Made by flyx & lysy\nSupporter: fizzler\n\nJoin our Discord for updates!'
        creditsText.Font = Enum.Font.Gotham
        creditsText.TextSize = 16
        creditsText.TextColor3 = COLOR_TEXT
        creditsText.TextWrapped = true
        creditsText.TextXAlignment = Enum.TextXAlignment.Left
        local discordButton = Instance.new('TextButton')
        discordButton.Parent = scroll
        discordButton.Size = UDim2.new(0.95, 0, 0, 40)
        discordButton.BackgroundColor3 = COLOR_PANEL_BG
        discordButton.Text = 'Join Discord'
        discordButton.Font = Enum.Font.GothamBold
        discordButton.TextSize = 18
        discordButton.TextColor3 = COLOR_TAB_ACTIVE
        local btnCorner = Instance.new('UICorner')
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = discordButton
        discordButton.MouseButton1Click:Connect(function()
            -- Replace with your Discord invite link
            local link = 'https://discord.gg/devhubb' -- Dodaj prawdziwy link!
            setclipboard(link) -- Copies to clipboard (requires executor support)
            print('Discord link copied to clipboard: ' .. link)
            local copiedLabel = Instance.new('TextLabel')
            copiedLabel.Parent = scroll
            copiedLabel.Size = UDim2.new(0.95, 0, 0, 30)
            copiedLabel.BackgroundTransparency = 1
            copiedLabel.Text = 'Discord link copied to clipboard'
            copiedLabel.Font = Enum.Font.Gotham
            copiedLabel.TextSize = 18
            copiedLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            copiedLabel.TextXAlignment = Enum.TextXAlignment.Center
            task.delay(3, function()
                copiedLabel:Destroy()
            end)
        end)
        return
    end
    for _, n in ipairs(lists[tab] or {}) do
        local callback
        if n == 'ESP Player' then
            callback = togglePlayerESP
        elseif n == 'ESP Base Timer' then
            callback = toggleBaseTimerESP
        elseif n == 'ESP Best Brainrot' then
            callback = toggleBestBrainrotESP
        elseif n == 'X-Ray Base' then
            callback = toggleXRay
        elseif n == 'Inf Jump' then
            callback = toggleInfJump
        elseif n == 'Slow Falling' then
            callback = toggleSlowFalling
        elseif n == 'Aimbot' then
            callback = toggleAimbot
        elseif n == 'Auto Destroy Sentry' then
            callback = toggleAutoDestroySentry
        elseif n == 'Speed Boost Steal' then
            callback = toggleSpeedBoostSteal
        elseif n == 'Jump Boost' then
            callback = toggleJumpBoost
        elseif n == 'Ultra Speed' then
            callback = toggleUltraSpeed
        elseif n == 'Grapple Fly' then
            callback = toggleGrappleFly
        elseif n == 'Rejoin' then
            callback = toggleRejoin
        elseif n == 'Server Hop' then
            callback = toggleServerHop
        elseif n == 'Stealing Tools' then
            callback = toggleStealingTools
        else
            callback = function(state)
                print(n, 'toggled:', state) -- Placeholder - implement here!
            end
        end
        local t = createToggle(n, callback)
        t.Parent = scroll
    end
end
local function setTab(tab)
    for _, n in ipairs(tabNames) do
        local b = tabButtons[n]
        local active = (n == tab)
        b.TextColor3 = active and COLOR_TAB_ACTIVE or COLOR_TAB_INACTIVE
        local s = b:FindFirstChildOfClass('UIStroke')
        if s then
            s.Color = active and COLOR_TAB_ACTIVE or COLOR_TAB_INACTIVE
        end
    end
    pageTitle.Text = tab
    populateTab(tab)
end
for _, name in ipairs(tabNames) do
    tabButtons[name].MouseButton1Click:Connect(function()
        setTab(name)
    end)
end
setTab('Main')
