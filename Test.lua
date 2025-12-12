--[[
    NIGHTMARE HUB 🎮 (UPDATED - FIXED)
    Arcade style with tabs + scrolling
    Tabs: Main | Visual | Misc | Discord
    FIXED: Toggle buttons no longer disappear when switching tabs
    FIXED: ESP Players function now works correctly.
    FIXED: "Anti Bee" and "Anti Boogie Bomb" conflict resolved. Combined into "Anti Debuff".
    FIXED: ESP Base Timer function to be more robust.
    UPDATED: Added ESP Players and Aimbot (Laser Cape) functions.
    UPDATED: Added "Esp Best" toggle to the Visual tab.
    UPDATED: Added actual function for "Esp Turret" and "Base Line".
    UPDATED: Replaced Anti Boogie Bomb function with a more robust 3-layer defense system.
    UPDATED: Replaced Anti Bee function with a more robust version.
    UPDATED: Added functional Platform toggle.
    UPDATED: Added Xray Base toggle.
    UPDATED: Changed "Best Line" to "Esp Base Timer".
    UPDATED: Added ESP functionality to "Esp Best" toggle.
    UPDATED: Replaced ESP Best with Brainrot ESP function, then renamed back to Esp Best.
    UPDATED: Removed Best Line function.
    UPDATED: Added Anti Knockback toggle to Misc tab.
    UPDATED: Added Anti Ragdoll toggle to Misc tab.
    UPDATED: Added Invisible V1 toggle to Main tab.
    UPDATED: Added Anti Trap toggle to Misc tab.
    UPDATED: Added Respawn Desync toggle to Main tab.
    UPDATED: Added Websling Kill toggle to Main tab.
]]

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- ==================== VARIABLES ====================
local player = Players.LocalPlayer

-- Platform variables
local platformEnabled = false
local platformPart = nil
local platformConnection = nil

-- Xray Base variables
local xrayBaseEnabled = false
local originalTransparency = {}

-- Esp Best variables
local highestValueESP = nil
local highestValueData = nil
local espBestEnabled = false
local autoUpdateThread = nil

-- ESP Base Timer variables
local espBaseTimerEnabled = false
local espBaseTimerConnection = nil

-- Grapple Speed variables
local grappleSpeedEnabled = false
local grappleSpeedScript = nil

-- Anti Knockback Variables (NEW)
local antiKnockbackEnabled = false
local antiKnockbackConn = nil
local lastSafeVelocity = Vector3.new(0, 0, 0)
local VELOCITY_THRESHOLD = 35
local UPDATE_INTERVAL = 0.016

-- Anti Ragdoll Variables (NEW)
local isAntiRagdollEnabled = false
local antiRagdollConnections = {}
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false

-- Invisible V1 Variables (NEW)
local connections = {
    SemiInvisible = {}
}
local isInvisible = false
local clone, oldRoot, hip, animTrack, connection, characterConnection

-- Anti Trap Variables (NEW)
local antiTrapEnabled = false
local antiTrapLoop1 = nil
local antiTrapLoop2 = nil

-- Auto Kick After Steal Variables (NEW)
local isMonitoring = false
local lastStealCount = 0
local monitoringLoop = nil

-- Instant Grab Variables (NEW)
local instantGrabEnabled = false
local instantGrabThread = nil

-- Touch Fling V2 Variables (NEW)
local touchFlingEnabled = false
local touchFlingConnection = nil

-- Allow Friends Variables (NEW)
local allowFriendsEnabled = false

-- Baselock Reminder Variables (NEW)
local baselockReminderEnabled = false
local baselockAlertGui = nil
local baselockConnection = nil
local bellSoundPlayed = false
local currentBellSound = nil
local BELL_SOUND_ID = "rbxassetid://3302969109"
-- ==================== UI CREATION ====================
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name == "NightmareHubUI" then
        gui:Destroy()
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NightmareHubUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.CoreGui

-- Toggle Button (Draggable)
local toggleButton = Instance.new("ImageButton")
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(0, 20, 0.5, -30)
toggleButton.BackgroundTransparency = 1
toggleButton.Image = "rbxassetid://121996261654076"
toggleButton.Active = true
toggleButton.Draggable = true
toggleButton.Parent = screenGui

-- Main Frame (Wider + Taller for tabs)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false -- START HIDDEN
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 50, 50)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NIGHTMARE HUB"
titleLabel.TextColor3 = Color3.fromRGB(139, 0, 0)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.Arcade
titleLabel.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.Arcade
closeBtn.Parent = mainFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

local closeBtnStroke = Instance.new("UIStroke")
closeBtnStroke.Color = Color3.fromRGB(255, 50, 50)
closeBtnStroke.Thickness = 1
closeBtnStroke.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 0, 35)
tabContainer.Position = UDim2.new(0, 10, 0, 55)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

-- Tab Buttons
local tabs = {"Main", "Visual", "Misc", "Discord"}
local tabButtons = {}
local currentTab = "Main"

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 70, 1, 0)
    tabBtn.Position = UDim2.new(0, (i-1) * 75, 0, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.Arcade
    tabBtn.Parent = tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabBtn
    
    local tabStroke = Instance.new("UIStroke")
    tabStroke.Color = Color3.fromRGB(100, 0, 0)
    tabStroke.Thickness = 1
    tabStroke.Parent = tabBtn
    
    tabButtons[tabName] = {button = tabBtn, stroke = tabStroke}
end

-- Content Frame with ScrollingFrame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -105)
contentFrame.Position = UDim2.new(0, 10, 0, 95)
contentFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentFrame

local contentStroke = Instance.new("UIStroke")
contentStroke.Color = Color3.fromRGB(60, 0, 0)
contentStroke.Thickness = 1
contentStroke.Parent = contentFrame

-- ScrollingFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -10)
scrollFrame.Position = UDim2.new(0, 5, 0, 5)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = contentFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scrollFrame

-- Auto-resize canvas
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10)
end)

-- ==================== HELPER FUNCTIONS ====================

local function createToggleButton(text, callback)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -10, 0, 35)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = text
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 14
    toggleBtn.Font = Enum.Font.Arcade
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 50, 50)
    btnStroke.Thickness = 1
    btnStroke.Parent = toggleBtn
    
    local isToggled = false
    
    toggleBtn.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        
        if isToggled then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        end
        
        if callback then callback(isToggled) end
    end)
    
    return toggleBtn
end

local function createSection(text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = "━━ " .. text .. " ━━"
    section.TextColor3 = Color3.fromRGB(255, 50, 50)
    section.TextSize = 12
    section.Font = Enum.Font.Arcade
    
    return section
end

-- ==================== AUTO KICK AFTER STEAL FUNCTION (NEW) ====================
local function getStealCount()
    local success, result = pcall(function()
        if not player or not player:FindFirstChild("leaderstats") then
            return 0
        end
        
        local stealsObject = player.leaderstats:FindFirstChild("Steals")
        if not stealsObject then
            return 0
        end
        
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
    print("✅ [Monitor] Started. Initial steals:", lastStealCount)
    
    monitoringLoop = RunService.Heartbeat:Connect(function()
        if not isMonitoring then return end
        
        local currentStealCount = getStealCount()
        
        if currentStealCount > lastStealCount then
            print("🚨 [Monitor] Steal detected!", lastStealCount, "→", currentStealCount)
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
    print("⛔ [Monitor] Stopped")
    
    if monitoringLoop then
        monitoringLoop:Disconnect()
        monitoringLoop = nil
    end
end

local function toggleAutoKickAfterSteal(state)
    if state then
        startMonitoring()
        print("✅ Auto Kick After Steal: ON")
    else
        stopMonitoring()
        print("❌ Auto Kick After Steal: OFF")
    end
end

-- ==================== GRAPPLE SPEED FUNCTION ====================
local function loadGrappleSpeed()
    if grappleSpeedEnabled then return end
    
    pcall(function()
        grappleSpeedScript = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/NorthHub/refs/heads/main/GrappleSpeed.lua"))()
        grappleSpeedEnabled = true
        print("✅ Grapple Speed: ON")
    end)
end

local function unloadGrappleSpeed()
    if not grappleSpeedEnabled then return end
    
    -- Since we can't truly "unload" a script, we'll just set the flag to false
    -- The script might still be running in the background, but we can try to disable its effects
    grappleSpeedEnabled = false
    
    -- Try to find and disable any changes made by the script
    pcall(function()
        -- Reset character walk speed if it was modified
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end)
    
    print("❌ Grapple Speed: OFF")
end

local function toggleGrappleSpeed(state)
    if state then
        loadGrappleSpeed()
    else
        unloadGrappleSpeed()
    end
end

-- ==================== PLATFORM FUNCTION ====================
local function createPlatform()
    if platformPart then return end
    
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    platformPart = Instance.new("Part")
    platformPart.Name = "NightmareHubPlatform"
    platformPart.Size = Vector3.new(10, 1, 10)  -- Made platform smaller (from 50x50 to 10x10)
    platformPart.Anchored = true
    platformPart.CanCollide = true
    platformPart.Transparency = 0.5
    platformPart.BrickColor = BrickColor.new("Really red")
    platformPart.Material = Enum.Material.Neon
    platformPart.TopSurface = Enum.SurfaceType.Smooth
    platformPart.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Create a nice glowing effect
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(255, 0, 0)
    glow.Range = 20
    glow.Brightness = 2
    glow.Parent = platformPart
    
    -- Position the platform below the player
    platformPart.Position = Vector3.new(rootPart.Position.X, rootPart.Position.Y - 3, rootPart.Position.Z)
    platformPart.Parent = Workspace
    
    -- Update platform position to follow player
    platformConnection = RunService.Heartbeat:Connect(function()
        if platformPart and platformPart.Parent and character and character.Parent then
            local newRootPart = character:FindFirstChild("HumanoidRootPart")
            if newRootPart then
                platformPart.Position = Vector3.new(newRootPart.Position.X, newRootPart.Position.Y - 3, newRootPart.Position.Z)
            end
        else
            if platformConnection then
                platformConnection:Disconnect()
                platformConnection = nil
            end
        end
    end)
    
    print("✅ Platform Created")
end

local function removePlatform()
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
    
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end
    
    print("❌ Platform Removed")
end

local function togglePlatform(state)
    platformEnabled = state
    
    if platformEnabled then
        createPlatform()
    else
        removePlatform()
    end
end

-- ==================== XRAY BASE FUNCTION ====================
local function saveOriginalTransparency()
    -- Clear table first
    originalTransparency = {}
    
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            for _, part in pairs(plot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    -- Save original transparency
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
                    -- If not saved yet, save it first
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
                    -- Restore to original transparency
                    if originalTransparency[part] ~= nil then
                        part.Transparency = originalTransparency[part]
                    end
                end
            end
        end
    end
end

local function toggleXrayBase(enabled)
    xrayBaseEnabled = enabled
    
    if xrayBaseEnabled then
        -- Save original transparency values first
        saveOriginalTransparency()
        -- Apply transparency
        applyTransparency()
        print("✓ Xray Base: ON")
    else
        -- Restore original transparency
        restoreTransparency()
        print("✗ Xray Base: OFF")
    end
end

-- Monitor for new plots that spawn
local plots = workspace:FindFirstChild("Plots")
if plots then
    plots.ChildAdded:Connect(function(newPlot)
        task.wait(0.5) -- Wait a bit for plot to fully load
        if xrayBaseEnabled then
            -- If toggle is ON, apply transparency to new plot
            for _, part in pairs(newPlot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency
                    part.Transparency = 0.5
                end
            end
        else
            -- If toggle is OFF, just save original
            for _, part in pairs(newPlot:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("base plot") or part.Name:lower():find("base") or part.Name:lower():find("plot")) then
                    originalTransparency[part] = part.Transparency
                end
            end
        end
    end)
end

-- ==================== ESP BEST FUNCTION ====================
local function parsePrice(text)
    if not text then return 0 end
    text = text:match("^%s*(.-)%s*$")
    local number, suffix = text:match("%$?([%d%.]+)%s*([kKmMbB]?)")
    number = tonumber(number) or 0
    if suffix then
        suffix = suffix:lower()
        if suffix == "k" then number = number * 1e3
        elseif suffix == "m" then number = number * 1e6
        elseif suffix == "b" then number = number * 1e9
        end
    end
    return number
end

local function isPlayerPlot(plot)
    -- Check if plot belongs to the player
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
        -- SKIP PLAYER'S OWN PLOT
        if not isPlayerPlot(plot) then
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for i = 1, 30 do
                    pcall(function()
                        local podium = podiums:FindFirstChild(tostring(i))
                        local overhead = podium.Base.Spawn.Attachment.AnimalOverhead
                        local priceLabel = overhead.Generation
                        local nameLabel = overhead.DisplayName
                        
                        if priceLabel.Text ~= "" and priceLabel.Text ~= "N/A" then
                            local value = parsePrice(priceLabel.Text)
                            if value > highest.value then
                                local tpPart = podium.Base.Decorations.Part
                                highest = {
                                    plot = plot,
                                    plotName = plot.Name,
                                    podiumNumber = i,
                                    petName = nameLabel and nameLabel.Text or "Unknown",
                                    price = priceLabel.Text,
                                    priceValue = value,
                                    teleportPart = tpPart,
                                    position = tpPart.Position,
                                    rarity = overhead.Rarity.Text,
                                    mutation = overhead.Mutation.Text,
                                    value = value
                                }
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
    if not brainrotData or not brainrotData.teleportPart then return end
    
    pcall(function()
        -- Remove old ESP
        if highestValueESP then
            if highestValueESP.highlight then highestValueESP.highlight:Destroy() end
            if highestValueESP.nameLabel then highestValueESP.nameLabel:Destroy() end
        end
        
        local espContainer = {}
        local part = brainrotData.teleportPart
        
        -- Highlight
        local highlight = Instance.new("Highlight", part)
        highlight.FillColor = Color3.fromRGB(0, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        espContainer.highlight = highlight
        
        -- Billboard
        local billboard = Instance.new("BillboardGui", part)
        billboard.Size = UDim2.new(0, 200, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 8, 0)
        billboard.AlwaysOnTop = true
        
        local container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        
        local petNameLabel = Instance.new("TextLabel", container)
        petNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = brainrotData.petName or "Unknown"
        petNameLabel.TextColor3 = Color3.fromRGB(255, 150, 255)
        petNameLabel.TextStrokeTransparency = 0
        petNameLabel.TextScaled = true
        petNameLabel.Font = Enum.Font.GothamBold
        
        local priceLabel = Instance.new("TextLabel", container)
        priceLabel.Size = UDim2.new(1, 0, 0.5, 0)
        priceLabel.Position = UDim2.new(0, 0, 0.5, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = brainrotData.price or ""
        priceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        priceLabel.TextStrokeTransparency = 0
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.GothamBold
        
        espContainer.nameLabel = billboard
        
        highestValueESP = espContainer
        highestValueData = brainrotData
    end)
end

local function updateHighestValueESP()
    local newHighest = findHighestBrainrot()
    
    if newHighest then
        -- Always update if we don't have current data OR if new one has higher value
        if not highestValueData or newHighest.priceValue > highestValueData.priceValue then
            createHighestValueESP(newHighest)
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
        end)
        highestValueESP = nil
        highestValueData = nil
    end
end

local function toggleEspBest(enabled)
    espBestEnabled = enabled
    
    if espBestEnabled then
        updateHighestValueESP()
        
        if autoUpdateThread then
            task.cancel(autoUpdateThread)
        end
        
        autoUpdateThread = task.spawn(function()
            while espBestEnabled do
                task.wait(1) -- Scan every 1 second
                
                -- Check if current target pet still exists (player hasn't left)
                if highestValueData then
                    local petStillExists = false
                    
                    pcall(function()
                        local plot = highestValueData.plot
                        if plot and plot.Parent then
                            local podiums = plot:FindFirstChild("AnimalPodiums")
                            if podiums then
                                local podium = podiums:FindFirstChild(tostring(highestValueData.podiumNumber))
                                if podium then
                                    local overhead = podium.Base.Spawn.Attachment.AnimalOverhead
                                    local nameLabel = overhead.DisplayName
                                    
                                    -- Check if pet name still exists (not empty)
                                    if nameLabel and nameLabel.Text ~= "" then
                                        petStillExists = true
                                    end
                                end
                            end
                        end
                    end)
                    
                    -- If pet no longer exists (player left), reset and find new one
                    if not petStillExists then
                        print("⚠️ Current pet removed (player left), searching for new highest value...")
                        removeHighestValueESP()
                        highestValueData = nil
                    end
                end
                
                -- Scan for highest value pet
                updateHighestValueESP()
            end
        end)
        
        print("✅ Esp Best: ON")
    else
        removeHighestValueESP()
        
        if autoUpdateThread then
            task.cancel(autoUpdateThread)
            autoUpdateThread = nil
        end
        
        print("❌ Esp Best: OFF")
    end
end

-- ==================== ESP BASE TIMER FUNCTION (UPDATED) ====================
local function toggleEspBaseTimer(state)
    espBaseTimerEnabled = state

    if espBaseTimerEnabled then
        if espBaseTimerConnection then
            espBaseTimerConnection:Disconnect()
            espBaseTimerConnection = nil
        end
        
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
            gui.Size = UDim2.new(0, 100, 0, 50)
            gui.StudsOffset = Vector3.new(0, 5, 0)
            gui.AlwaysOnTop = true
            gui.Parent = main
            local lbl = Instance.new('TextLabel')
            lbl.Name = 'Label'
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(255, 50, 50) -- Merah cerah
            lbl.Font = Enum.Font.Arcade -- Font Arcade
            lbl.TextScaled = true
            lbl.Text = '0'
            lbl.TextStrokeTransparency = 0.5
            lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
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
        
        espBaseTimerConnection = RunService.RenderStepped:Connect(function()
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
                                -- Detect time change
                                if lastValues[key] ~= currentText then
                                    lastValues[key] = currentText
                                    lastChange[key] = now
                                end
                                -- Conditions for text change
                                local numeric = tonumber(currentText)
                                local timeSinceChange = now
                                    - (lastChange[key] or 0)
                                if numeric and numeric <= 0 then
                                    timerLabel.Text = 'UNLOCKED'
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(0, 255, 0)
                                elseif timeSinceChange > 1 then
                                    timerLabel.Text = 'UNLOCKED'
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(0, 255, 0)
                                else
                                    -- Time is changing normally - Red bright
                                    timerLabel.Text = currentText
                                    timerLabel.TextColor3 =
                                        Color3.fromRGB(255, 50, 50) -- Merah cerah
                                end
                            else
                                timerLabel.Text = 'UNLOCKED'
                                timerLabel.TextColor3 =
                                    Color3.fromRGB(0, 255, 0)
                            end
                        end
                    end
                end
            end
        end)
        
        print("✅ ESP Base Timer: ON")
    else
        if espBaseTimerConnection then
            espBaseTimerConnection:Disconnect()
            espBaseTimerConnection = nil
        end
        
        -- Clean up all GUI elements
        for _, plot in pairs(Workspace:FindFirstChild('Plots') and Workspace.Plots:GetChildren() or {}) do
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
        
        print("❌ ESP Base Timer: OFF")
    end
end

-- ==================== INSTANT GRAB FUNCTION (NEW) ====================
local function getPromptPosition(prompt)
    local parent = prompt.Parent
    
    if parent:IsA("BasePart") then
        return parent.Position
    end
    
    if parent:IsA("Model") then
        local primary = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if primary then
            return primary.Position
        end
    end
    
    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    
    return nil
end

local function findNearestPrompt()
    local character = player.Character
    if not character then return nil, math.huge end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    
    local nearest = nil
    local minDist = math.huge
    local plots = workspace:FindFirstChild("Plots")
    
    if not plots then return nil, math.huge end
    
    for _, obj in pairs(plots:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled and obj.ActionText == "Steal" then
            local pos = getPromptPosition(obj)
            
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                
                if dist <= obj.MaxActivationDistance and dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    
    return nearest, minDist
end

local function activatePrompt(prompt)
    fireproximityprompt(prompt, 20, math.huge)
    prompt:InputHoldBegin()
    prompt:InputHoldEnd()
end

local function startInstantGrab()
    if instantGrabEnabled then return end
    
    instantGrabEnabled = true
    print("✅ Instant Grab: ON")
    
    instantGrabThread = task.spawn(function()
        local currentPrompt = nil
        local currentDistance = math.huge
        local lastUpdate = 0
        
        RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - lastUpdate >= 0.05 then
                currentPrompt, currentDistance = findNearestPrompt()
                lastUpdate = now
            end
        end)
        
        while instantGrabEnabled do
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.WalkSpeed > 25 then
                    if currentPrompt and currentDistance <= currentPrompt.MaxActivationDistance then
                        activatePrompt(currentPrompt)
                        task.wait(1.5)
                    else
                        task.wait(0.1)
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end

local function stopInstantGrab()
    if not instantGrabEnabled then return end
    
    instantGrabEnabled = false
    print("❌ Instant Grab: OFF")
    
    if instantGrabThread then
        task.cancel(instantGrabThread)
        instantGrabThread = nil
    end
end

local function toggleInstantGrab(state)
    if state then
        startInstantGrab()
    else
        stopInstantGrab()
    end
end

-- ==================== ALLOW FRIENDS FUNCTION (NEW) ====================
local function toggleAllowFriends(state)
    allowFriendsEnabled = state
    
    if allowFriendsEnabled then
        -- Fire the remote to enable friends
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/ToggleFriends"):FireServer()
        end)
        print("✅ Allow Friends: ON")
    else
        -- Fire the remote to disable friends
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/ToggleFriends"):FireServer()
        end)
        print("❌ Allow Friends: OFF")
    end
end

-- ==================== TOUCH FLING V2 FUNCTION (NEW) ====================
local function enableTouchFling()
    -- Disable auto jump
    pcall(function()
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.AutoJumpEnabled ~= nil then
                humanoid.AutoJumpEnabled = false
            end
        end
    end)

    -- Create marker if not exists
    if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
        local marker = Instance.new("Decal")
        marker.Name = "juisdfj0i32i0eidsuf0iok"
        marker.Parent = ReplicatedStorage
    end

    -- Start fling connection
    touchFlingConnection = RunService.Heartbeat:Connect(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local v = hrp.Velocity
            hrp.Velocity = v * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = v
            RunService.Stepped:Wait()
            hrp.Velocity = v + Vector3.new(0, 0.1, 0)
        end
    end)

    touchFlingEnabled = true
    print("✅ Touch Fling V2: ON")
end

local function disableTouchFling()
    -- Disconnect fling connection
    if touchFlingConnection then
        touchFlingConnection:Disconnect()
        touchFlingConnection = nil
    end

    -- Remove marker
    local marker = ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok")
    if marker then
        marker:Destroy()
    end

    -- Re-enable auto jump
    pcall(function()
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.AutoJumpEnabled = true
            end
        end
    end)

    touchFlingEnabled = false
    print("❌ Touch Fling V2: OFF")
end

local function toggleTouchFling(state)
    if state then
        enableTouchFling()
    else
        disableTouchFling()
    end
end

-- ==================== BASELOCK REMINDER FUNCTION (NEW) ====================
local function parseTimeToSeconds(timeText)
    if not timeText or timeText == "" then return nil end
    
    local minutes, seconds = timeText:match("(%d+):(%d+)")
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end
    
    local secondsOnly = timeText:match("(%d+)s")
    if secondsOnly then
        return tonumber(secondsOnly)
    end
    
    local minutesOnly = timeText:match("(%d+)m")
    if minutesOnly then
        return tonumber(minutesOnly) * 60
    end
    
    return nil
end

local function playBellSound()
    if bellSoundPlayed then return end
    
    -- Stop previous bell sound if exists
    if currentBellSound then
        currentBellSound:Stop()
        currentBellSound:Destroy()
        currentBellSound = nil
    end
    
    local sound = Instance.new("Sound")
    sound.SoundId = BELL_SOUND_ID
    sound.Volume = 0.7
    sound.Parent = game:GetService("SoundService")
    
    currentBellSound = sound
    sound:Play()
    
    bellSoundPlayed = true
    
    -- Stop after 3 seconds
    task.delay(3, function()
        if sound and sound.Parent then
            sound:Stop()
            sound:Destroy()
        end
        currentBellSound = nil
    end)
end

local function createAlertGui()
    if baselockAlertGui then return end
    
    baselockAlertGui = Instance.new("ScreenGui")
    baselockAlertGui.Name = "BaselockReminderAlert"
    baselockAlertGui.ResetOnSpawn = false
    baselockAlertGui.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 90)
    frame.Position = UDim2.new(0.5, -190, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = baselockAlertGui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 15)
    frameCorner.Parent = frame
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(200, 30, 30)
    frameStroke.Thickness = 3
    frameStroke.Parent = frame
    
    -- Bell Icon
    local bellIcon = Instance.new("TextLabel")
    bellIcon.Size = UDim2.new(0, 60, 0, 60)
    bellIcon.Position = UDim2.new(0, 15, 0.5, -30)
    bellIcon.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
    bellIcon.BorderSizePixel = 0
    bellIcon.Text = "🔔"
    bellIcon.TextSize = 35
    bellIcon.Font = Enum.Font.GothamBold
    bellIcon.Parent = frame
    
    local bellCorner = Instance.new("UICorner")
    bellCorner.CornerRadius = UDim.new(1, 0)
    bellCorner.Parent = bellIcon
    
    -- Bell shake animation
    local shakeTween = TweenService:Create(
        bellIcon,
        TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = 15}
    )
    shakeTween:Play()
    
    -- Reminder Text
    local reminderLabel = Instance.new("TextLabel")
    reminderLabel.Size = UDim2.new(1, -100, 0, 35)
    reminderLabel.Position = UDim2.new(0, 85, 0, 15)
    reminderLabel.BackgroundTransparency = 1
    reminderLabel.Text = "⚠️ Base Lock Reminder!"
    reminderLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    reminderLabel.Font = Enum.Font.GothamBold
    reminderLabel.TextSize = 18
    reminderLabel.TextXAlignment = Enum.TextXAlignment.Left
    reminderLabel.TextStrokeTransparency = 0.3
    reminderLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    reminderLabel.Parent = frame
    
    -- Time Text
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, -100, 0, 35)
    timeLabel.Position = UDim2.new(0, 85, 0, 45)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "Your Base Lock Time: --"
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Font = Enum.Font.GothamBold
    timeLabel.TextSize = 16
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.TextStrokeTransparency = 0.5
    timeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    timeLabel.Parent = frame
    
    -- Border flash animation
    local flashTween = TweenService:Create(
        frameStroke,
        TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = Color3.fromRGB(255, 60, 60)}
    )
    flashTween:Play()
end

local function updateAlertGui(timeText)
    if not baselockAlertGui or not baselockAlertGui.Parent then return end
    
    local timeLabel = baselockAlertGui:FindFirstChild("Frame"):FindFirstChild("TimeLabel")
    if timeLabel then
        timeLabel.Text = "Your Base Lock Time: " .. timeText
    end
end

local function removeAlertGui()
    if baselockAlertGui then
        baselockAlertGui:Destroy()
        baselockAlertGui = nil
    end
    
    -- Stop bell sound when removing alert
    if currentBellSound then
        currentBellSound:Stop()
        currentBellSound:Destroy()
        currentBellSound = nil
    end
    
    bellSoundPlayed = false
end

local function checkMyBaseTimer()
    if not baselockReminderEnabled then return end
    
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    local playerBaseName = player.DisplayName .. "'s Base"
    
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotSignText = ""
            local signPath = plot:FindFirstChild("PlotSign")
            if signPath and signPath:FindFirstChild("SurfaceGui") and signPath.SurfaceGui:FindFirstChild("Frame") and signPath.SurfaceGui.Frame:FindFirstChild("TextLabel") then
                plotSignText = signPath.SurfaceGui.Frame.TextLabel.Text
            end
            
            if plotSignText == playerBaseName then
                local plotTimeText = ""
                local purchasesPath = plot:FindFirstChild("Purchases")
                if purchasesPath and purchasesPath:FindFirstChild("PlotBlock") and purchasesPath.PlotBlock:FindFirstChild("Main") and purchasesPath.PlotBlock.Main:FindFirstChild("BillboardGui") then
                    local billboardGui = purchasesPath.PlotBlock.Main.BillboardGui
                    if billboardGui:FindFirstChild("RemainingTime") then
                        plotTimeText = billboardGui.RemainingTime.Text
                    end
                end

                local remainingSeconds = parseTimeToSeconds(plotTimeText)
                
                if remainingSeconds and remainingSeconds <= 10 and remainingSeconds > 0 then
                    if not baselockAlertGui then
                        createAlertGui()
                        playBellSound()
                    end
                    updateAlertGui(plotTimeText)
                else
                    if baselockAlertGui then
                        removeAlertGui()
                    end
                end
                
                break
            end
        end
    end
end

local function startBaselockReminder()
    if baselockReminderEnabled then return end
    
    baselockReminderEnabled = true
    print("✅ Baselock Reminder: ON")
    
    baselockConnection = RunService.Heartbeat:Connect(function()
        task.wait(0.5)
        pcall(checkMyBaseTimer)
    end)
end

local function stopBaselockReminder()
    if not baselockReminderEnabled then return end
    
    baselockReminderEnabled = false
    print("❌ Baselock Reminder: OFF")
    
    if baselockConnection then
        baselockConnection:Disconnect()
        baselockConnection = nil
    end
    
    removeAlertGui()
end

local function toggleBaselockReminder(state)
    if state then
        startBaselockReminder()
    else
        stopBaselockReminder()
    end
end

-- ==================== ESP PLAYERS FUNCTION (FIXED) ====================
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil

local function getEquippedItem(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return "None"
end

local function createESP(targetPlayer)
    if targetPlayer == player then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
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
    
    espObjects[targetPlayer] = {
        highlight = highlight,
        billboard = billboard,
        itemLabel = itemLabel,
        character = character
    }
end

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

local function updateESP()
    if not espPlayersEnabled then return end
    
    for p, espData in pairs(espObjects) do
        if p and p.Parent and espData.character and espData.character.Parent then
            local character = espData.character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local equippedItem = getEquippedItem(character)
                espData.itemLabel.Text = "Item: " .. equippedItem
                
                if equippedItem ~= "None" then
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                else
                    espData.itemLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                end
            else
                removeESP(p)
            end
        else
            removeESP(p)
        end
    end
end

local function enableESP()
    if espPlayersEnabled then return end
    espPlayersEnabled = true
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            createESP(p)
        end
    end
    
    updateConnection = RunService.RenderStepped:Connect(updateESP)
    
    print("✅ ESP Players Enabled - Cyan outlines active!")
end

local function disableESP()
    if not espPlayersEnabled then return end
    espPlayersEnabled = false
    
    for p, _ in pairs(espObjects) do
        removeESP(p)
    end
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    print("❌ ESP Players Disabled")
end

local function toggleESPPlayers(enabled)
    if enabled then
        enableESP()
    else
        disableESP()
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(character)
        task.wait(1)
        if espPlayersEnabled and p ~= player then
            createESP(p)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
end)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then
        p.CharacterAdded:Connect(function(character)
            task.wait(1)
            if espPlayersEnabled then
                createESP(p)
            end
        end)
    end
end

-- ==================== LASER CAPE (AIMBOT) FUNCTION ====================
local autoLaserEnabled = false
local autoLaserThread = nil

local blacklistNames = {
    "alex4eva", "jkxkelu", "BigTulaH", "xxxdedmoth", "JokiTablet",
    "sleepkola", "Aimbot36022", "Djrjdjdk0", "elsodidudujd", 
    "SENSEIIIlSALT", "yaniecky", "ISAAC_EVO", "7xc_ls", "itz_d1egx"
}
local blacklist = {}
for _, name in ipairs(blacklistNames) do
    blacklist[string.lower(name)] = true
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

local function toggleAutoLaser(enabled)
    autoLaserEnabled = enabled
    
    if autoLaserEnabled then
        if autoLaserThread then
            task.cancel(autoLaserThread)
        end
        autoLaserThread = task.spawn(autoLaserWorker)
        print("✓ Laser Cape (Aimbot): ON")
    else
        if autoLaserThread then
            task.cancel(autoLaserThread)
            autoLaserThread = nil
        end
        print("✗ Laser Cape (Aimbot): OFF")
    end
end

-- ==================== ESP TURRET (SENTRY) FUNCTION ====================
local sentryESPEnabled = false
local trackedSentries = {}
local scanConnection = nil

local function getPlayerNameFromSentry(sentryName)
    local userId = sentryName:match("Sentry_(%d+)")
    if userId then
        for _, p in ipairs(Players:GetPlayers()) do
            if tostring(p.UserId) == userId then
                return p.Name
            end
        end
        return "Player " .. userId
    end
    return "Unknown"
end

local function createSentryESP(sentry)
    if sentry:FindFirstChild("SentryESP_Highlight") then
        sentry.SentryESP_Highlight:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "SentryESP_Highlight"
    highlight.Adornee = sentry
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.Parent = sentry
end

local function removeSentryESP(sentry)
    if sentry:FindFirstChild("SentryESP_Highlight") then
        sentry.SentryESP_Highlight:Destroy()
    end
end

local function scanForSentries()
    local found = {}
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("^Sentry_%d+") then
            found[obj] = true
            
            if not trackedSentries[obj] then
                trackedSentries[obj] = true
                
                local ownerName = getPlayerNameFromSentry(obj.Name)
                print("NEW SENTRY DETECTED:", ownerName)
                
                if sentryESPEnabled then
                    createSentryESP(obj)
                end
            end
        end
    end
    
    for sentry, _ in pairs(trackedSentries) do
        if not sentry.Parent or not found[sentry] then
            trackedSentries[sentry] = nil
            removeSentryESP(sentry)
        end
    end
end

local function enableSentryESP()
    if sentryESPEnabled then return end
    sentryESPEnabled = true
    
    for sentry, _ in pairs(trackedSentries) do
        if sentry.Parent then
            createSentryESP(sentry)
        end
    end
    
    if not scanConnection then
        scanConnection = RunService.Heartbeat:Connect(function()
            if sentryESPEnabled then
                pcall(scanForSentries)
            end
        end)
    end
    
    print("✅ Sentry ESP Enabled")
end

local function disableSentryESP()
    if not sentryESPEnabled then return end
    sentryESPEnabled = false
    
    for sentry, _ in pairs(trackedSentries) do
        removeSentryESP(sentry)
    end
    
    if scanConnection then
        scanConnection:Disconnect()
        scanConnection = nil
    end
    
    print("❌ Sentry ESP Disabled")
end

local function toggleSentryESP(state)
    if state then
        enableSentryESP()
    else
        disableSentryESP()
    end
end

Workspace.ChildAdded:Connect(function(child)
    task.wait(0.1)
    if child.Name:match("^Sentry_%d+") then
        local ownerName = getPlayerNameFromSentry(child.Name)
        print("NEW SENTRY PLACED:", ownerName)
        
        task.wait(0.5)
        
        trackedSentries[child] = true
        
        if sentryESPEnabled then
            createSentryESP(child)
            scanForSentries()
        end
    end
end)

task.wait(1)
scanForSentries()

-- ==================== BASE LINE FUNCTION ====================
local baseLineEnabled = false
local baseLineConnection = nil
local baseBeamPart = nil
local baseTargetPart = nil
local baseBeam = nil

local function findPlayerPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then 
        warn("❌ Plots folder not found!")
        return nil 
    end
    
    local playerBaseName = player.DisplayName .. "'s Base"
    for _, plot in pairs(plots:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign and plotSign:FindFirstChild("SurfaceGui") then
                local surfaceGui = plotSign.SurfaceGui
                if surfaceGui:FindFirstChild("Frame") and surfaceGui.Frame:FindFirstChild("TextLabel") then
                    local plotSignText = surfaceGui.Frame.TextLabel.Text
                    
                    if plotSignText == playerBaseName then
                        print("✅ Found player's plot:", plot.Name)
                        return plot
                    end
                end
            end
        end
    end
    
    warn("❌ Player's base not found!")
    return nil
end

local function findCollectZone(plot)
    if not plot then return nil end
    
    local decorations = plot:FindFirstChild("Decorations")
    if not decorations then
        warn("❌ Decorations not found!")
        return nil
    end
    
    for _, decoration in pairs(decorations:GetChildren()) do
        if decoration.Name:lower():find("collect") or decoration:FindFirstChild("CollectZone") then
            print("✅ Found CollectZone:", decoration.Name)
            return decoration
        end
        
        for _, child in pairs(decorations:GetDescendants()) do
            if child.Name:lower():find("collect") and (child:IsA("Part") or child:IsA("Model")) then
                print("✅ Found CollectZone in:", decoration.Name)
                return child
            end
        end
    end
    
    local children = decorations:GetChildren()
    if #children >= 11 then
        print("✅ Using 11th decoration as CollectZone")
        return children[11]
    end
    
    warn("❌ CollectZone not found!")
    return nil
end

local function createPlotLine()
    local Character = player.Character
    if not Character then return false end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return false end
    
    local playerPlot = findPlayerPlot()
    if not playerPlot then 
        warn("❌ Cannot find your base!")
        return false
    end
    
    local collectZone = findCollectZone(playerPlot)
    if not collectZone then
        warn("❌ Cannot find CollectZone!")
        return false
    end
    
    local targetPosition
    if collectZone:IsA("Model") and collectZone.PrimaryPart then
        targetPosition = collectZone.PrimaryPart.Position
    elseif collectZone:IsA("BasePart") then
        targetPosition = collectZone.Position
    elseif collectZone:FindFirstChildWhichIsA("BasePart") then
        targetPosition = collectZone:FindFirstChildWhichIsA("BasePart").Position
    else
        warn("❌ Cannot get position from CollectZone!")
        return false
    end
    
    print("📍 Creating line to CollectZone at:", targetPosition)
    
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
    
    print("✅ Base line created!")
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
    
    print("🛑 Base line removed")
end

local function toggleBaseLine(state)
    baseLineEnabled = state
    
    if baseLineEnabled then
        pcall(createPlotLine)
    else
        pcall(stopPlotLine)
    end
end

player.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    
    if baseLineEnabled then
        pcall(stopPlotLine)
        task.wait(0.5)
        pcall(createPlotLine)
    end
end)

player.CharacterRemoving:Connect(function()
    pcall(stopPlotLine)
end)

-- ==================== ANTI KNOCKBACK FUNCTION (NEW) ====================
local function startNoKnockback()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    if antiKnockbackConn then antiKnockbackConn:Disconnect() end

    lastSafeVelocity = hrp.Velocity
    local lastCheck = tick()
    local lastPosition = hrp.Position

    antiKnockbackConn = game:GetService("RunService").Heartbeat:Connect(function()
        local now = tick()
        if now - lastCheck < UPDATE_INTERVAL then return end
        lastCheck = now

        local currentVel = hrp.Velocity
        local currentPos = hrp.Position
        local positionChange = (currentPos - lastPosition).Magnitude
        lastPosition = currentPos

        local horizontalSpeed = Vector3.new(currentVel.X, 0, currentVel.Z).Magnitude
        local lastHorizontalSpeed = Vector3.new(lastSafeVelocity.X, 0, lastSafeVelocity.Z).Magnitude
        local isKnockback = false

        if horizontalSpeed > VELOCITY_THRESHOLD and horizontalSpeed > lastHorizontalSpeed * 4 then isKnockback = true end
        if math.abs(currentVel.Y) > 70 then isKnockback = true end
        if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then isKnockback = true end
        if positionChange > 10 and horizontalSpeed > 50 then isKnockback = true end

        if isKnockback then
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new(0, 0, 0)
                    part.RotVelocity = Vector3.new(0, 0, 0)
                    for _, force in ipairs(part:GetChildren()) do
                        if force:IsA("BodyVelocity") or force:IsA("BodyForce") or force:IsA("BodyAngularVelocity") or force:IsA("BodyGyro") then
                            force:Destroy()
                        end
                    end
                end
            end
            hum.PlatformStand = false
            hum.AutoRotate = true
            lastSafeVelocity = Vector3.new(0, 0, 0)
            print("[ANTI-KB] Knockback blocked! Speed: " .. math.floor(horizontalSpeed))
        else
            local stable = hum:GetState() ~= Enum.HumanoidStateType.Freefall and hum:GetState() ~= Enum.HumanoidStateType.FallingDown and hum:GetState() ~= Enum.HumanoidStateType.Ragdoll
            if stable and horizontalSpeed < VELOCITY_THRESHOLD then
                lastSafeVelocity = currentVel
            end
        end
    end)
end

local function stopNoKnockback()
    if antiKnockbackConn then
        antiKnockbackConn:Disconnect()
        antiKnockbackConn = nil
    end
end

local function toggleAntiKnockback(state)
    antiKnockbackEnabled = state
    
    if antiKnockbackEnabled then
        startNoKnockback()
        print("✅ Anti Knockback: ON")
    else
        stopNoKnockback()
        print("❌ Anti Knockback: OFF")
    end
end

-- ==================== ANTI RAGDOLL FUNCTION (NEW) ====================
-- Function to force the character to get up
local function stopRagdoll()
    if not ragdollActive then return end
    ragdollActive = false
    local char, hum, root = player.Character, player.Character:FindFirstChildOfClass("Humanoid"), player.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    hum.PlatformStand = false
    root.CanCollide = true
    if root.Anchored then root.Anchored = false end
    
    -- Remove constraints that might be causing the ragdoll
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then
            for _, c in part:GetChildren() do
                if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then
                    c:Destroy()
                end
            end
            local motor = part:FindFirstChildWhichIsA("Motor6D")
            if motor then motor.Enabled = true end
        end
    end
    
    -- Reset velocity
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
    workspace.CurrentCamera.CameraSubject = hum
end

-- Timer to automatically stop the ragdoll after a short duration
local function startRagdollTimer()
    if ragdollTimer then ragdollTimer:Disconnect() end
    ragdollActive = true
    ragdollTimer = RunService.Heartbeat:Connect(function()
        ragdollTimer:Disconnect()
        ragdollTimer = nil
        stopRagdoll()
    end)
end

-- Watch for changes in the humanoid's state
local function watchHumanoidStates(char)
    local hum = char:WaitForChild("Humanoid")
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() end
    
    humanoidWatchConnection = hum.StateChanged:Connect(function(_, newState)
        if not isAntiRagdollEnabled then return end
        -- If the character enters a ragdoll state
        if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Physics then
            if not ragdollActive then
                hum.PlatformStand = true
                startRagdollTimer()
            end
        -- If the character starts getting up or running
        elseif newState == Enum.HumanoidStateType.GettingUp or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
            hum.PlatformStand = false
            if ragdollActive then stopRagdoll() end
        end
    end)
end

-- Set up anti-ragdoll for a specific character
local function setupAntiRagdollCharacter(char)
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect() ragdollTimer = nil end
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    watchHumanoidStates(char)
end

-- Function to start the anti-ragdoll feature
local function startAntiRagdoll()
    isAntiRagdollEnabled = true
    -- Clean up old connections
    for _, conn in pairs(antiRagdollConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(antiRagdollConnections)
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() humanoidWatchConnection = nil end
    
    -- Set up for the current character
    if player.Character then
        setupAntiRagdollCharacter(player.Character)
    end
    -- Set up for future characters (e.g., after respawn)
    table.insert(antiRagdollConnections, player.CharacterAdded:Connect(setupAntiRagdollCharacter))
end

-- Function to stop the anti-ragdoll feature
local function stopAntiRagdoll()
    isAntiRagdollEnabled = false
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect() ragdollTimer = nil end
    -- Disconnect all connections
    for _, conn in pairs(antiRagdollConnections) do
        if conn then conn:Disconnect() end
    end
    table.clear(antiRagdollConnections)
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect() humanoidWatchConnection = nil end
end

local function toggleAntiRagdoll(state)
    if state then
        startAntiRagdoll()
        print("✅ Anti Ragdoll: ON")
    else
        stopAntiRagdoll()
        print("❌ Anti Ragdoll: OFF")
    end
end

-- ==================== INVISIBLE V1 FUNCTION (NEW) ====================
local function removeFolders()
    local playerName = player.Name
    local playerFolder = Workspace:FindFirstChild(playerName)
    if not playerFolder then
        return
    end
    local doubleRig = playerFolder:FindFirstChild("DoubleRig")
    if doubleRig then
        doubleRig:Destroy()
    end
    local constraints = playerFolder:FindFirstChild("Constraints")
    if constraints then
        constraints:Destroy()
    end
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
        if not oldRoot or not oldRoot.Parent then
            return false
        end
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
                if v.Part0 == oldRoot then
                    v.Part0 = clone
                end
                if v.Part1 == oldRoot then
                    v.Part1 = clone
                end
            end
        end
        tempParent:Destroy()
        return true
    end
    return false
end

local function revertClone()
    if not oldRoot or not oldRoot:IsDescendantOf(game.Workspace) or not player.Character or player.Character.Humanoid.Health <= 0 then
        return false
    end
    local tempParent = Instance.new("Model")
    tempParent.Parent = game
    player.Character.Parent = tempParent
    oldRoot.Parent = player.Character
    player.Character.PrimaryPart = oldRoot
    player.Character.Parent = game.Workspace
    oldRoot.CanCollide = true
    for _, v in pairs(player.Character:GetDescendants()) do
        if v:IsA("Weld") or v:IsA("Motor6D") then
            if v.Part0 == clone then
                v.Part0 = oldRoot
            end
            if v.Part1 == clone then
                v.Part1 = oldRoot
            end
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

local function enableInvisibility()
    if not player.Character or player.Character.Humanoid.Health <= 0 then
        return false
    end
    removeFolders()
    local success = doClone()
    if success then
        task.wait(0.1)
        animationTrickery()
        connection = RunService.PreSimulation:Connect(function(dt)
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and oldRoot then
                local root = player.Character.PrimaryPart or player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local cf = root.CFrame - Vector3.new(0, player.Character.Humanoid.HipHeight + (root.Size.Y / 2) - 1 + 0.09, 0)
                    oldRoot.CFrame = cf * CFrame.Angles(math.rad(180), 0, 0)
                    oldRoot.Velocity = root.Velocity
                    oldRoot.CanCollide = false
                end
            end
        end)
        table.insert(connections.SemiInvisible, connection)
        characterConnection = player.CharacterAdded:Connect(function(newChar)
            if isInvisible then
                if animTrack then
                    animTrack:Stop()
                    animTrack:Destroy()
                    animTrack = nil
                end
                if connection then connection:Disconnect() end
                revertClone()
                removeFolders()
                isInvisible = false
                for _, conn in ipairs(connections.SemiInvisible) do
                    if conn then conn:Disconnect() end
                end
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
            if m == "ChangeState" and select(1, ...) == Enum.HumanoidStateType.Dead then
                return
            end
            if m == "SetStateEnabled" then
                local st, en = ...
                if st == Enum.HumanoidStateType.Dead and en == true then
                    return
                end
            end
            if m == "Destroy" then
                return
            end
        end
        if self == char and m == "BreakJoints" then
            return
        end
        return oldNC(self, ...)
    end)
    mt.__newindex = newcclosure(function(self, k, v)
        if self == hum then
            if k == "Health" and type(v) == "number" and v <= 0 then
                return
            end
            if k == "MaxHealth" and type(v) == "number" and v < hum.MaxHealth then
                return
            end
            if k == "BreakJointsOnDeath" and v == true then
                return
            end
            if k == "Parent" and v == nil then
                return
            end
        end
        return oldNI(self, k, v)
    end)
    setreadonly(mt, true)
end

local function toggleInvisibleV1(state)
    if state then
        if not isInvisible then
            removeFolders()
            setupGodmode()
            if enableInvisibility() then
                isInvisible = true
                print("✅ Semi Invisible: ON")
            end
        end
    else
        if isInvisible then
            disableInvisibility()
            isInvisible = false
            for _, conn in ipairs(connections.SemiInvisible) do
                if conn then conn:Disconnect() end
            end
            connections.SemiInvisible = {}
            print("❌ Semi Invisible: OFF")
        end
    end
end

-- ==================== ANTI TRAP FUNCTION (NEW) ====================
local function startAntiTrap()
    if antiTrapEnabled then return end
    antiTrapEnabled = true
    
    local blacklist = {"trap", "kill", "lava", "spike", "damage", "void", "web", "slinger"}
    
    antiTrapLoop1 = task.spawn(function()
        while antiTrapEnabled do
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    for _, word in ipairs(blacklist) do
                        if v.Name:lower():find(word) then 
                            pcall(function() v:Destroy() end) 
                            break 
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
    
    antiTrapLoop2 = task.spawn(function()
        while antiTrapEnabled do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.Anchored = false
                player.Character.Humanoid.Sit = false
            end
            task.wait(0.5)
        end
    end)
    
    print("✅ Anti Trap: ON")
end

local function stopAntiTrap()
    antiTrapEnabled = false
    
    if antiTrapLoop1 then
        task.cancel(antiTrapLoop1)
        antiTrapLoop1 = nil
    end
    
    if antiTrapLoop2 then
        task.cancel(antiTrapLoop2)
        antiTrapLoop2 = nil
    end
    
    print("❌ Anti Trap: OFF")
end

local function toggleAntiTrap(state)
    if state then
        startAntiTrap()
    else
        stopAntiTrap()
    end
end

-- ==================== UNIFIED ANTI DEBUFF SYSTEM (FIXED) ====================
-- This new system prevents conflicts between Anti Bee and Anti Boogie Bomb.

-- State variables for the toggles
local antiBeeEnabled = false
local antiBoogieEnabled = false

-- Variables for the unified event handler
local isEventHandlerActive = false
local unifiedConnection = nil
local originalConnections = {}

-- Other Anti Boogie variables (these are fine and don't conflict)
local heartbeatConnection = nil
local animationPlayedConnection = nil
local BOOGIE_ANIMATION_ID = "109061983885712"

-- The core function that manages the event hooking
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
            print("Disabling unified event handler...")
            if unifiedConnection then
                unifiedConnection:Disconnect()
                unifiedConnection = nil
            end
            
            for _, conn in pairs(originalConnections) do
                pcall(function() conn:Enable() end)
            end
            originalConnections = {}
            
            isEventHandlerActive = false
        end
        return
    end

    if (antiBeeEnabled or antiBoogieEnabled) and not isEventHandlerActive then
        print("Enabling unified event handler...")
        
        for i, v in pairs(getconnections(Event.OnClientEvent)) do
            table.insert(originalConnections, v)
            pcall(function() v:Disable() end)
        end

        unifiedConnection = Event.OnClientEvent:Connect(function(Action, ...)
            if antiBeeEnabled and Action == "Bee Attack" then
                print("🐝 Blocked Bee Attack!")
                return
            end
            if antiBoogieEnabled and Action == "Boogie" then
                print("🕺 Blocked Boogie Bomb!")
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
    
    if animationPlayedConnection then
        animationPlayedConnection:Disconnect()
    end
    
    animationPlayedConnection = animator.AnimationPlayed:Connect(function(track)
        if track and track.Animation then
            if tostring(track.Animation.AnimationId):gsub("%D", "") == BOOGIE_ANIMATION_ID then
                track:Stop(0)
                track:Destroy()
                print("⚡ INSTANT BLOCK: Boogie animation destroyed!")
            end
        end
    end)
end

local function enableContinuousMonitoring()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
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

-- NEW, SIMPLIFIED TOGGLE FUNCTIONS
local function toggleAntiBee(state)
    antiBeeEnabled = state
    updateUseItemEventHandler()
    if antiBeeEnabled then
        print("✅ Anti Bee Enabled")
    else
        print("❌ Anti Bee Disabled")
    end
end

local function toggleAntiBoogie(state)
    antiBoogieEnabled = state
    
    if antiBoogieEnabled then
        setupInstantAnimationBlocker()
        enableContinuousMonitoring()
        print("✅ Anti Boogie Bomb: ENABLED (3-Layer Defense)")
    else
        if animationPlayedConnection then
            animationPlayedConnection:Disconnect()
            animationPlayedConnection = nil
        end
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
        print("❌ Anti Boogie Bomb: DISABLED")
    end
    
    updateUseItemEventHandler()
end

player.CharacterAdded:Connect(function(newCharacter)
    if antiBoogieEnabled then
        task.wait(0.5)
        setupInstantAnimationBlocker()
        print("🔄 Reloaded animation blocker after respawn")
    end
    
    if antiKnockbackEnabled then
        task.wait(1)
        startNoKnockback()
        print("🔄 Reloaded anti-knockback after respawn")
    end
    
    if isAntiRagdollEnabled then
        task.wait(0.5)
        setupAntiRagdollCharacter(newCharacter)
        print("🔄 Reloaded anti-ragdoll after respawn")
    end
    
    if isInvisible then
        isInvisible = false
        for _, conn in ipairs(connections.SemiInvisible) do
            if conn then conn:Disconnect() end
        end
        connections.SemiInvisible = {}
    end
    
    if antiTrapEnabled then
        task.wait(1)
        startAntiTrap()
        print("🔄 Reloaded anti-trap after respawn")
    end
end)
    if touchFlingEnabled then
        task.wait(1)
        disableTouchFling()
        enableTouchFling()
        print("🔄 Reloaded Touch Fling V2 after respawn")
    end
    if baselockReminderEnabled then
        task.wait(1)
        stopBaselockReminder()
        startBaselockReminder()
        print("🔄 Reloaded Baselock Reminder after respawn")
    end

-- ==================== TAB CONTENT ====================

local tabContent = {}

-- MAIN TAB (7 TOGGLES - Changed Invisible V1 to Semi Invisible, Added Auto Kick After Steal)
tabContent["Main"] = {}
table.insert(tabContent["Main"], createToggleButton("Platform", function(state)
    togglePlatform(state)
end))
table.insert(tabContent["Main"], createToggleButton("Aimbot", function(state)
    toggleAutoLaser(state)
end))
table.insert(tabContent["Main"], createToggleButton("Xray Base", function(state)
    toggleXrayBase(state)
end))
table.insert(tabContent["Main"], createToggleButton("Semi Invisible", function(state)  -- Changed from "Invisible V1"
    toggleInvisibleV1(state)
end))
table.insert(tabContent["Main"], createToggleButton("Auto Kick After Steal", function(state)  -- New toggle
    toggleAutoKickAfterSteal(state)
end))
table.insert(tabContent["Main"], createToggleButton("Respawn Desync", function(state)
    if state then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Respawn.lua"))()
        end)
        print("✅ Respawn Desync: Triggered")
    else
        print("❌ Respawn Desync: OFF")
    end
end))
table.insert(tabContent["Main"], createToggleButton("Websling Kill", function(state)
    if state then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/Webslingkill.lua"))()
        end)
        print("✅ Websling Kill: ON")
    else
        print("❌ Websling Kill: OFF")
    end
end))
table.insert(tabContent["Main"], createToggleButton("Baselock Reminder", function(state)
    toggleBaselockReminder(state)
end))
table.insert(tabContent["Main"], createToggleButton("Websling Control", function(state)
    if state then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Mikael312/StealBrainrot/refs/heads/main/WebslingControl.lua"))()
        end)
        print("✅ Websling Control: ON")
    else
        print("❌ Websling Control: OFF")
    end
end))

-- VISUAL TAB (5 TOGGLES - Renamed Brainrot ESP to Esp Best)
tabContent["Visual"] = {}
table.insert(tabContent["Visual"], createToggleButton("Esp Players", function(state)
    toggleESPPlayers(state)
end))
table.insert(tabContent["Visual"], createToggleButton("Esp Best", function(state)
    toggleEspBest(state)
end))
table.insert(tabContent["Visual"], createToggleButton("Esp Base Timer", function(state)
    toggleEspBaseTimer(state)
end))
table.insert(tabContent["Visual"], createToggleButton("Base Line", function(state)
    toggleBaseLine(state)
end))
table.insert(tabContent["Visual"], createToggleButton("Esp Turret", function(state)
    toggleSentryESP(state)
end))

-- MISC TAB (5 TOGGLES - Added Grapple Speed, Anti Knockback, Anti Ragdoll, and Anti Trap)
tabContent["Misc"] = {}
table.insert(tabContent["Misc"], createToggleButton("Anti Debuff", function(state)
    -- This single toggle now controls both Anti Bee and Anti Boogie Bomb
    toggleAntiBee(state)
    toggleAntiBoogie(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Grapple Speed", function(state)
    toggleGrappleSpeed(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Anti Knockback", function(state)
    toggleAntiKnockback(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Anti Ragdoll", function(state)
    toggleAntiRagdoll(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Anti Trap", function(state)
    toggleAntiTrap(state)
end))
table.insert(tabContent["Main"], createToggleButton("Instant Grab", function(state)
    toggleInstantGrab(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Touch Fling V2", function(state)
    toggleTouchFling(state)
end))
table.insert(tabContent["Misc"], createToggleButton("Allow Friends", function(state)
    toggleAllowFriends(state)
end))

-- DISCORD TAB
tabContent["Discord"] = {}

local discordSection = createSection("SOCIAL")
table.insert(tabContent["Discord"], discordSection)

local tiktokBtn = Instance.new("TextButton")
tiktokBtn.Size = UDim2.new(1, -10, 0, 35)
tiktokBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
tiktokBtn.BorderSizePixel = 0
tiktokBtn.Text = "Tiktok"
tiktokBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tiktokBtn.TextSize = 14
tiktokBtn.Font = Enum.Font.Arcade

local tiktokCorner = Instance.new("UICorner")
tiktokCorner.CornerRadius = UDim.new(0, 8)
tiktokCorner.Parent = tiktokBtn

local tiktokStroke = Instance.new("UIStroke")
tiktokStroke.Color = Color3.fromRGB(255, 50, 50)
tiktokStroke.Thickness = 1
tiktokStroke.Parent = tiktokBtn

tiktokBtn.MouseButton1Click:Connect(function()
    setclipboard("https://www.tiktok.com/@n1ghtmare.gg?_r=1&_t=ZS-91TYDcuhlRQ")
    tiktokBtn.Text = "COPIED!"
    tiktokBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    task.wait(2)
    tiktokBtn.Text = "Tiktok"
    tiktokBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
end)

table.insert(tabContent["Discord"], tiktokBtn)

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(1, -10, 0, 35)
discordBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
discordBtn.BorderSizePixel = 0
discordBtn.Text = "Discord"
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.TextSize = 14
discordBtn.Font = Enum.Font.Arcade

local discordCorner = Instance.new("UICorner")
discordCorner.CornerRadius = UDim.new(0, 8)
discordCorner.Parent = discordBtn

local discordStroke = Instance.new("UIStroke")
discordStroke.Color = Color3.fromRGB(255, 50, 50)
discordStroke.Thickness = 1
discordStroke.Parent = discordBtn

discordBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/Bcdt9nXV")
    discordBtn.Text = "COPIED!"
    discordBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    task.wait(2)
    discordBtn.Text = "Discord"
    discordBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
end)

table.insert(tabContent["Discord"], discordBtn)

-- NEW SECTION ADDED: Server
local serverSection = createSection("Server")
table.insert(tabContent["Discord"], serverSection)

-- ==================== ADD ALL CONTENT TO SCROLLFRAME FIRST ====================
for tabName, items in pairs(tabContent) do
    for _, item in ipairs(items) do
        item.Parent = scrollFrame
        item.Visible = false
    end
end

-- ==================== TAB SWITCHING ====================

local function switchTab(tabName)
    for name, data in pairs(tabButtons) do
        if name == tabName then
            data.button.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
            data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
            data.stroke.Color = Color3.fromRGB(255, 50, 50)
        else
            data.button.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
            data.button.TextColor3 = Color3.fromRGB(150, 150, 150)
            data.stroke.Color = Color3.fromRGB(100, 0, 0)
        end
    end
    
    for _, items in pairs(tabContent) do
        for _, item in ipairs(items) do
            item.Visible = false
        end
    end
    
    if tabContent[tabName] then
        for _, item in ipairs(tabContent[tabName]) do
            item.Visible = true
        end
    end
    
    currentTab = tabName
end

for name, data in pairs(tabButtons) do
    data.button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

switchTab("Main")

-- ==================== TOGGLE BUTTON FUNCTIONALITY ====================
toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- ==================== INITIALIZATION ====================
print("==========================================")
print("🎮 NIGHTMARE HUB LOADED!")
print("🔧 Functions Added: ESP Players (FIXED), Aimbot (Laser Cape), Esp Turret (Sentry), Anti Debuff (Combined Anti Bee & Boogie), Base Line, Platform, Xray Base, Esp Best, Esp Base Timer (FIXED), Grapple Speed, Anti Knockback (NEW), Anti Ragdoll (NEW), Semi Invisible (NEW), Anti Trap (NEW), Respawn Desync (NEW), Websling Kill (NEW), Auto Kick After Steal (NEW)")
print("🆕 Added Toggles: Esp Best, Esp Base Timer, Base Line, Platform, Xray Base, Grapple Speed, Anti Knockback, Anti Ragdoll, Semi Invisible, Anti Trap, Respawn Desync, Websling Kill, Auto Kick After Steal")
print("✅ Renamed 'Brainrot ESP' back to 'Esp Best'.")
print("✅ FIXED: ESP Base Timer function is now more robust.")
print("✅ FIXED: 'Anti Bee' and 'Anti Boogie Bomb' conflict resolved. Now combined into 'Anti Debuff'.")
print("✅ ADDED: Functional Platform toggle (smaller size).")
print("✅ ADDED: Xray Base toggle in Main tab.")
print("✅ CHANGED: 'Invisible V1' renamed to 'Semi Invisible'.")
print("✅ ADDED: Auto Kick After Steal toggle in Main tab.")
