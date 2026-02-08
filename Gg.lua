local Library = {}
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

function Library:CreateWindow(config)
    local windowTitle = config.Title or "Cursed Hub"
    local discordLink = config.Discord or "https://discord.gg/XjxuvBnpN"
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CursedHubGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -50, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = mainFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(0, 255, 255)
    frameStroke.Thickness = 1.0
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Parent = mainFrame

    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
    }
    uiGradient.Parent = frameStroke

    local gradientTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0)
    TweenService:Create(uiGradient, gradientTweenInfo, {Rotation = 360}):Play()

    local discordButton = Instance.new("TextButton")
    discordButton.Size = UDim2.new(0, 65, 0, 20)
    discordButton.Position = UDim2.new(0, 10, 0, 15)
    discordButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    discordButton.BackgroundTransparency = 0.65
    discordButton.BorderSizePixel = 0
    discordButton.Text = "Copy Discord"
    discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordButton.Font = Enum.Font.Gotham
    discordButton.TextSize = 7
    discordButton.Parent = mainFrame

    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 5)
    discordCorner.Parent = discordButton

    local discordStroke = Instance.new("UIStroke")
    discordStroke.Thickness = 1.0
    discordStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    discordStroke.Color = Color3.fromRGB(255, 255, 255)
    discordStroke.Parent = discordButton

    local discordGradient = Instance.new("UIGradient")
    discordGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
    }
    discordGradient.Rotation = 0
    discordGradient.Parent = discordStroke

    discordButton.MouseButton1Click:Connect(function()
        setclipboard(discordLink)
        local originalText = discordButton.Text
        discordButton.Text = "Copied!"
        task.wait(2)
        discordButton.Text = originalText
    end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 180, 0, 40)
    titleLabel.Position = UDim2.new(0.5, -75, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = windowTitle
    titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = mainFrame

    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 35, 0, 35)
    minimizeButton.Position = UDim2.new(1, -45, 0, 7.5)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Text = "-"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.Font = Enum.Font.Gotham
    minimizeButton.TextSize = 24
    minimizeButton.Parent = mainFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = minimizeButton

    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -60)
    contentFrame.Position = UDim2.new(0, 10, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = contentFrame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.Parent = contentFrame

    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        if not isMinimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 250, 0, 50)
            }):Play()
            minimizeButton.Text = "+"
            isMinimized = true
            contentFrame.Visible = false
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 250, 0, 400)
            }):Play()
            minimizeButton.Text = "-"
            isMinimized = false
            contentFrame.Visible = true
        end
    end)

    local Window = {}
    
    function Window:CreateButton(config)
        local buttonText = config.Name or "Button"
        local callback = config.Callback or function() end
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        button.BackgroundTransparency = 0.65
        button.BorderSizePixel = 0
        button.Text = buttonText
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextSize = 12
        button.Parent = contentFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.0
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Parent = button
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
        }
        gradient.Rotation = 0
        gradient.Parent = stroke
        
        button.MouseButton1Click:Connect(callback)
        
        return button
    end
    
    function Window:CreateToggle(config)
        local toggleText = config.Name or "Toggle"
        local default = config.Default or false
        local callback = config.Callback or function() end
        
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(1, 0, 0, 35)
        toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        toggle.BackgroundTransparency = 0.65
        toggle.BorderSizePixel = 0
        toggle.Text = toggleText
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.Font = Enum.Font.Gotham
        toggle.TextSize = 12
        toggle.Parent = contentFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = toggle
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.0
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Parent = toggle
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
        }
        gradient.Rotation = 0
        gradient.Parent = stroke
        
        local isToggled = default
        
        if isToggled then
            toggle.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
            toggle.BackgroundTransparency = 0.3
        end
        
        toggle.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            
            if isToggled then
                TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Color3.fromRGB(0, 100, 100),
                    BackgroundTransparency = 0.3
                }):Play()
            else
                TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 0.65
                }):Play()
            end
            
            callback(isToggled)
        end)
        
        return toggle
    end
    
    function Window:CreateInput(config)
        local labelText = config.Name or "Input"
        local placeholderText = config.Placeholder or ""
        local callback = config.Callback or function() end
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 35)
        container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        container.BackgroundTransparency = 0.65
        container.BorderSizePixel = 0
        container.Parent = contentFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = container
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.0
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Parent = container
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
        }
        gradient.Rotation = 0
        gradient.Parent = stroke
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = container
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.5, -20, 1, 0)
        input.Position = UDim2.new(0.5, 5, 0, 0)
        input.BackgroundTransparency = 1
        input.Text = ""
        input.PlaceholderText = placeholderText
        input.PlaceholderColor3 = Color3.fromRGB(191, 191, 191)
        input.TextColor3 = Color3.fromRGB(255, 255, 255)
        input.Font = Enum.Font.Gotham
        input.TextSize = 12
        input.TextXAlignment = Enum.TextXAlignment.Right
        input.TextTruncate = Enum.TextTruncate.AtEnd
        input.ClearTextOnFocus = false
        input.ClipsDescendants = true
        input.Parent = container
        
        input.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                callback(input.Text)
            end
        end)
        
        return input
    end
    
    return Window
end

return Library
