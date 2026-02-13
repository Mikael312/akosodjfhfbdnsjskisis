local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ========== CONFIG SYSTEM ==========
local ConfigSystem = {}

ConfigSystem.ConfigFile = "NightmareV1_Config.json"

-- Default config
ConfigSystem.DefaultConfig = {
	InvisPanel = false,
	-- Quick Panel Toggles
	InfJump = false,
	Speed = false,
	StealFloor = false,
	InstaFloor = false,
	-- Misc Tab Toggles
	AntiLag = false,
	AntiDebuff = false,     -- ADD
	AntiRagdoll = false,    -- ADD
	XrayBase = false,       -- ADD
	Optimizer = false       -- ADD
}

-- Load config dari file
function ConfigSystem:Load()
	if isfile and isfile(self.ConfigFile) then
		local success, result = pcall(function()
			local fileContent = readfile(self.ConfigFile)
			local decoded = HttpService:JSONDecode(fileContent)
			return decoded
		end)
		
		if success and result then
			return result
		else
			warn("Failed to load config, using defaults")
			return self.DefaultConfig
		end
	else
		return self.DefaultConfig
	end
end

-- Save config ke file
function ConfigSystem:Save(config)
	if not writefile then
		warn("writefile not available")
		return false
	end
	
	local success, error = pcall(function()
		local encoded = HttpService:JSONEncode(config)
		writefile(self.ConfigFile, encoded)
	end)
	
	if success then
		return true
	else
		warn("Failed to save config:", error)
		return false
	end
end

-- Update satu setting sahaja
function ConfigSystem:UpdateSetting(config, key, value)
	config[key] = value
	self:Save(config)
end

-- Load config masa startup
local currentConfig = ConfigSystem:Load()

-- ========== NOTIFICATION SYSTEM ==========
local activeNotifications = {} -- Track semua active notifs
local NOTIF_HEIGHT = 60
local NOTIF_SPACING = 10
local MAX_NOTIFS = 3

function updateNotificationPositions()
	-- Update position semua notifs
	for i, notifData in ipairs(activeNotifications) do
		local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
		local moveTween = TweenService:Create(notifData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -260, 0, newYPos)
		})
		moveTween:Play()
	end
end

function removeNotification(notifData)
	-- Remove dari active list
	for i, data in ipairs(activeNotifications) do
		if data == notifData then
			table.remove(activeNotifications, i)
			break
		end
	end
	updateNotificationPositions()
end

function showNotification(message)
	-- Kalau dah ada MAX_NOTIFS, remove yang paling lama (index 1)
	if #activeNotifications >= MAX_NOTIFS then
		local oldestNotif = activeNotifications[1]
		
		-- Remove dari list DULU
		table.remove(activeNotifications, 1)
		
		-- Update position notifs yang tinggal (naik ke atas)
		updateNotificationPositions()
		
		-- LEPAS TU baru tween keluar yang lama
		local tweenOut = TweenService:Create(oldestNotif.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 10, 0, oldestNotif.frame.Position.Y.Offset)
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			oldestNotif.frame:Destroy()
		end)
	end
	
	-- Buat notification GUI
	local screenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NotificationGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NotificationGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	-- Calculate position untuk notif baru (di bawah semua notif yang ada)
	local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
	
	-- Buat notification frame
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 250, 0, NOTIF_HEIGHT)
	notif.Position = UDim2.new(1, 10, 0, startYPos) -- Start dari luar screen
	notif.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	notif.BackgroundTransparency = 0.15
	notif.BorderSizePixel = 0
	notif.Parent = screenGui
	
	-- Rounded corners 8 pixel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif
	
	-- Close button X (hujung kanan atas)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 5)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = notif
	
	-- Text label untuk message
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -50, 1, -10)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.TextWrapped = true
	textLabel.Parent = notif
	
	-- Container untuk progress bar
	local barContainer = Instance.new("Frame")
	barContainer.Size = UDim2.new(1, 0, 0, 3)
	barContainer.Position = UDim2.new(0, 0, 1, -3)
	barContainer.BackgroundTransparency = 1
	barContainer.ClipsDescendants = true
	barContainer.Parent = notif
	
	-- Progress bar dengan gradient
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = barContainer
	
	-- Rounded corners untuk bar
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = progressBar
	
	-- Gradient untuk bar
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 60))
	}
	gradient.Parent = progressBar
	
	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://102467889710186"
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	-- Store notif data
	local notifData = {
		frame = notif,
		progressBar = progressBar,
		barTween = nil
	}
	table.insert(activeNotifications, notifData)
	
	-- Tween masuk
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -260, 0, startYPos)
	})
	tweenIn:Play()
	
	-- Bar drain dari KANAN ke KIRI (3 saat)
	local barTween = TweenService:Create(progressBar, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 0, 1, 0)
	})
	notifData.barTween = barTween
	barTween:Play()
	
	-- Close button function
	closeButton.MouseButton1Click:Connect(function()
		-- Stop bar tween
		if notifData.barTween then
			notifData.barTween:Cancel()
		end
		
		-- Tween keluar
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 10, 0, notif.Position.Y.Offset)
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notif:Destroy()
		end)
		
		removeNotification(notifData)
	end)
	
	-- Tunggu 3 saat, then tween keluar
	task.spawn(function()
		task.wait(3)
		
		-- Check kalau notif masih exist (mungkin user dah close manual)
		if notif.Parent then
			local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 10, 0, notif.Position.Y.Offset)
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				notif:Destroy()
			end)
			
			removeNotification(notifData)
		end
	end)
end

-- ========== ANTI LAG SYSTEM ==========
local CONFIG = {
	ANTI_LAG_ENABLED = false
}

local ANTI_LAG = {}
local antiLagRunning = false
local antiLagConnections = {}
local cleanedCharacters = {}

local function destroyAllEquippableItems(character)
    if not character then return end
    if not CONFIG.ANTI_LAG_ENABLED then return end
    
    pcall(function()
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Hat") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
                child:Destroy()
            end
        end
        
        local bodyColors = character:FindFirstChildOfClass("BodyColors")
        if bodyColors then
            bodyColors:Destroy()
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("CharacterMesh") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child.ClassName == "LayeredClothing" or child.ClassName == "WrapLayer" then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("BasePart") then
                local mesh = child:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh:Destroy()
                end
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Highlight") then
                child:Destroy()
            end
        end
        
        for _, child in ipairs(character:GetDescendants()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                if not (child.Name == "face" and child.Parent and child.Parent.Name == "Head") then
                    child:Destroy()
                end
            end
        end
    end)
end

local function destroyBackpackTools(player)
    if not CONFIG.ANTI_LAG_ENABLED then return end
    
    pcall(function()
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, desc in ipairs(tool:GetDescendants()) do
                        if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or
                           desc:IsA("SpecialMesh") or desc:IsA("PointLight") or desc:IsA("SpotLight") or
                           desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                            desc:Destroy()
                        end
                    end
                end
            end
        end
    end)
end

local function destroyEquippedTools(character)
    if not character then return end
    if not CONFIG.ANTI_LAG_ENABLED then return end
    
    pcall(function()
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, desc in ipairs(tool:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or
                       desc:IsA("SpecialMesh") or desc:IsA("PointLight") or desc:IsA("SpotLight") or
                       desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                        desc:Destroy()
                    end
                end
            end
        end
    end)
end

local function antiLagCleanCharacter(char)
    if not char then return end
    
    destroyAllEquippableItems(char)
    destroyEquippedTools(char)
    cleanedCharacters[char] = true
end

local function antiLagDisconnectAll()
    for _, conn in ipairs(antiLagConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    antiLagConnections = {}
    cleanedCharacters = {}
end

function ANTI_LAG.Enable()
    if antiLagRunning then return end
    antiLagRunning = true
    CONFIG.ANTI_LAG_ENABLED = true
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            antiLagCleanCharacter(plr.Character)
            destroyBackpackTools(plr)
        end
        
        if plr.Backpack then
            table.insert(antiLagConnections, plr.Backpack.ChildAdded:Connect(function()
                if antiLagRunning and CONFIG.ANTI_LAG_ENABLED then
                    task.wait(0.1)
                    destroyBackpackTools(plr)
                end
            end))
        end
    end
    
    table.insert(antiLagConnections, Players.PlayerAdded:Connect(function(plr)
        table.insert(antiLagConnections, plr.CharacterAdded:Connect(function(char)
            if not antiLagRunning then return end
            task.wait(0.5)
            antiLagCleanCharacter(char)
            destroyBackpackTools(plr)
            
            table.insert(antiLagConnections, char.ChildAdded:Connect(function(child)
                if not antiLagRunning or not CONFIG.ANTI_LAG_ENABLED then return end
                task.wait(0.1)
                
                if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Shirt") or 
                   child:IsA("Pants") or child:IsA("ShirtGraphic") then
                    child:Destroy()
                elseif child:IsA("Tool") then
                    destroyEquippedTools(char)
                end
            end))
        end))
        
        if plr.Character then
            antiLagCleanCharacter(plr.Character)
            destroyBackpackTools(plr)
        end
        
        if plr.Backpack then
            table.insert(antiLagConnections, plr.Backpack.ChildAdded:Connect(function()
                if antiLagRunning and CONFIG.ANTI_LAG_ENABLED then
                    task.wait(0.1)
                    destroyBackpackTools(plr)
                end
            end))
        end
    end))
    
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(antiLagConnections, plr.CharacterAdded:Connect(function(char)
            if antiLagRunning and CONFIG.ANTI_LAG_ENABLED then
                task.wait(0.5)
                antiLagCleanCharacter(char)
                destroyBackpackTools(plr)
                
                table.insert(antiLagConnections, char.ChildAdded:Connect(function(child)
                    if not antiLagRunning or not CONFIG.ANTI_LAG_ENABLED then return end
                    task.wait(0.1)
                    
                    if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Shirt") or 
                       child:IsA("Pants") or child:IsA("ShirtGraphic") then
                        child:Destroy()
                    elseif child:IsA("Tool") then
                        destroyEquippedTools(char)
                    end
                end))
            end
        end))
    end
    
    table.insert(antiLagConnections, task.spawn(function()
        while antiLagRunning and CONFIG.ANTI_LAG_ENABLED do
            task.wait(3)
            
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and not cleanedCharacters[plr.Character] then
                    antiLagCleanCharacter(plr.Character)
                    destroyBackpackTools(plr)
                end
            end
        end
    end))
    
    showNotification("Anti Lag: Enabled")
end

function ANTI_LAG.Disable()
    if not antiLagRunning then return end
    antiLagRunning = false
    CONFIG.ANTI_LAG_ENABLED = false
    antiLagDisconnectAll()
    showNotification("Anti Lag: Disabled")
end

-- ========== INF JUMP SYSTEM ==========
local infiniteJumpEnabled = false
local lowGravityEnabled = false
local jumpRequestConnection = nil
local bodyForce = nil
local lowGravityForce = 50
local defaultGravity = workspace.Gravity

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
    
    jumpRequestConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
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

local function toggleInfJump(enabled)
    infiniteJumpEnabled = enabled
    lowGravityEnabled = enabled
    
    if enabled then
        local char = player.Character
        if char then
            initializeJumpForCharacter(char)
        end
        updateGravity()
    else
        if jumpRequestConnection then
            jumpRequestConnection:Disconnect()
            jumpRequestConnection = nil
        end
        updateGravity()
    end
end

-- ========== SPEED SYSTEM ==========
local speedConn
local baseSpeed = 28
local speedEnabled = false

local function GetCharacter()
    local Char = player.Character or player.CharacterAdded:Wait()
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

-- ========== ANTI DEBUFF SYSTEM ==========
local antiBeeEnabled = false
local antiBoogieEnabled = false
local isEventHandlerActive = false
local unifiedConnection = nil
local originalConnections = {}
local heartbeatConnection = nil
local animationPlayedConnection = nil
local BOOGIE_ANIMATION_ID = "109061983885712"

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

-- ========== ANTI RAGDOLL SYSTEM ==========
local antiRagdollEnabled = false
local humanoidWatchConnection, ragdollTimer
local ragdollActive = false
local ragdollConnections = {}
local cachedCharData = {}
local constraintLoopActive = false

local function stopRagdoll()
    if not ragdollActive then return end
    
    ragdollActive = false
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return end
    
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    hum.PlatformStand = false
    
    root.CanCollide = true
    if root.Anchored then root.Anchored = false end
    
    for _, part in char:GetChildren() do
        if part:IsA("BasePart") then
            for _, c in part:GetChildren() do
                if c:IsA("BallSocketConstraint") or c:IsA("HingeConstraint") then
                    c:Destroy()
                end
            end
            local motor = part:FindFirstChildWhichIsA("Motor6D")
            if motor then
                motor.Enabled = true
            end
        end
    end
    
    root.Velocity = Vector3.new(0, math.min(root.Velocity.Y, 0), 0)
    root.RotVelocity = Vector3.new(0, 0, 0)
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
        if not antiRagdollEnabled then return end
        
        if newState == Enum.HumanoidStateType.FallingDown or 
           newState == Enum.HumanoidStateType.Ragdoll or 
           newState == Enum.HumanoidStateType.Physics then
            if not ragdollActive then
                hum.PlatformStand = true
                startRagdollTimer()
            end
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

local function disconnectAllRagdollConnections()
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
    
    if ragdollStates[state] then return true end
    
    local endTime = player:GetAttribute("RagdollEndTime")
    if endTime then
        local now = workspace:GetServerTimeNow()
        if (endTime - now) > 0 then return true end
    end
    return false
end

local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or 
           (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            pcall(function() descendant:Destroy() end)
        end
    end
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    local hum = cachedCharData.humanoid
    local root = cachedCharData.root
    
    pcall(function()
        local now = workspace:GetServerTimeNow()
        player:SetAttribute("RagdollEndTime", now)
    end)
    
    if hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    
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

local function setupCharacter(char)
    task.wait(0.5)
    if not antiRagdollEnabled then return end
    
    ragdollActive = false
    if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    watchHumanoidStates(char)
    
    if cacheCharacterData() then
        setupCameraBinding()
        task.spawn(constraintRemovalLoop)
    end
end

local function enableAntiRagdoll()
    antiRagdollEnabled = true
    constraintLoopActive = true
    
    if player.Character then setupCharacter(player.Character) end
    
    local charConn = player.CharacterAdded:Connect(setupCharacter)
    table.insert(ragdollConnections, charConn)
end

local function disableAntiRagdoll()
    antiRagdollEnabled = false
    constraintLoopActive = false
    ragdollActive = false
    
    if ragdollTimer then ragdollTimer:Disconnect(); ragdollTimer = nil end
    if humanoidWatchConnection then humanoidWatchConnection:Disconnect(); humanoidWatchConnection = nil end
    
    disconnectAllRagdollConnections()
    cachedCharData = {}
end

-- ========== XRAY BASE SYSTEM ==========
local xrayBaseEnabled = false
local invisibleWallsLoaded = false
local originalTransparency = {}
local xrayBaseConnection = nil

local function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    local parent = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or parent:find("base")
end

local function tryApplyInvisibleWalls()
    if not xrayBaseEnabled or invisibleWallsLoaded then return end
    local plots = workspace:FindFirstChild("Plots")
    if not plots or #plots:GetChildren() == 0 then return end
    
    for _, plot in pairs(plots:GetChildren()) do
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and obj.CanCollide and isBaseWall(obj) then
                if not originalTransparency[obj] then
                    originalTransparency[obj] = obj.LocalTransparencyModifier
                    obj.LocalTransparencyModifier = 0.85
                end
            end
        end
    end
    invisibleWallsLoaded = true
end

local function enableXrayBase()
    if xrayBaseEnabled then return end
    xrayBaseEnabled = true
    invisibleWallsLoaded = false
    
    task.spawn(function()
        task.wait(0.5)
        tryApplyInvisibleWalls()
    end)
    
    xrayBaseConnection = workspace.DescendantAdded:Connect(function(obj)
        if not xrayBaseEnabled then return end
        task.wait(0.1)
        if isBaseWall(obj) and obj:IsA("BasePart") and obj.Anchored and obj.CanCollide then
            if not originalTransparency[obj] then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
end

local function disableXrayBase()
    if not xrayBaseEnabled then return end
    xrayBaseEnabled = false
    invisibleWallsLoaded = false
    
    if xrayBaseConnection then xrayBaseConnection:Disconnect(); xrayBaseConnection = nil end
    
    for obj, value in pairs(originalTransparency) do
        if obj and obj.Parent then
            pcall(function() obj.LocalTransparencyModifier = value end)
        end
    end
    originalTransparency = {}
end

-- ========== FPS BOOST / OPTIMIZER SYSTEM ==========
local fpsBoostEnabled = false
local optimizerThreads = {}
local optimizerConnections = {}
local originalSettings = {}

local PERFORMANCE_FFLAGS = {
    ["DFIntTaskSchedulerTargetFps"] = 999,
    ["FFlagDebugGraphicsPreferVulkan"] = true,
    ["FFlagDebugGraphicsDisableDirect3D11"] = true,
    ["DFFlagDebugRenderForceTechnologyVoxel"] = true,
    ["FFlagDisablePostFx"] = true,
    ["FIntRenderShadowIntensity"] = 0,
    ["DFIntTextureCompositorActiveJobs"] = 1,
    ["DFIntDebugFRMQualityLevelOverride"] = 1,
}

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
            globalShadows = Lighting.GlobalShadows,
            brightness = Lighting.Brightness,
            fogEnd = Lighting.FogEnd,
            technology = Lighting.Technology,
            decoration = workspace.Terrain.Decoration,
            waterWaveSize = workspace.Terrain.WaterWaveSize,
            waterWaveSpeed = workspace.Terrain.WaterWaveSpeed,
            waterReflectance = workspace.Terrain.WaterReflectance,
            waterTransparency = workspace.Terrain.WaterTransparency,
        }
    end)
end

local function applyFFlags()
    for flag, value in pairs(PERFORMANCE_FFLAGS) do
        pcall(function()
            setfflag(flag, tostring(value))
        end)
    end
end

local function nukeVisualEffects()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Trail") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
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
    end)
    
    pcall(function()
        local renderSettings = settings().Rendering
        renderSettings.QualityLevel = Enum.QualityLevel.Level01
        renderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.FogEnd = 9e9
        Lighting.Technology = Enum.Technology.Legacy
        
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                pcall(function() effect.Enabled = false; effect:Destroy() end)
            end
        end
    end)
    
    pcall(function()
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.Decoration = false
    end)
    
    addThread(function() task.wait(1); nukeVisualEffects() end)
    
    addConnection(workspace.DescendantAdded:Connect(function(obj)
        if not getgenv().OPTIMIZER_ACTIVE then return end
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or
               obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") or
               obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.Plastic
            end
        end)
    end))
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then optimizeCharacter(p.Character) end
        addConnection(p.CharacterAdded:Connect(function(char)
            if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end
        end))
    end
    
    addConnection(Players.PlayerAdded:Connect(function(p)
        addConnection(p.CharacterAdded:Connect(function(char)
            if getgenv().OPTIMIZER_ACTIVE then optimizeCharacter(char) end
        end))
    end))
    
    pcall(function() setfpscap(999) end)
end

local function disableFpsBoost()
    if not fpsBoostEnabled then return end
    fpsBoostEnabled = false
    getgenv().OPTIMIZER_ACTIVE = false
    
    for _, thread in ipairs(optimizerThreads) do pcall(function() task.cancel(thread) end) end
    optimizerThreads = {}
    
    for _, conn in ipairs(optimizerConnections) do pcall(function() conn:Disconnect() end) end
    optimizerConnections = {}
    
    pcall(function()
        workspace.StreamingEnabled = originalSettings.streamingEnabled or true
        workspace.StreamingMinRadius = originalSettings.streamingMinRadius or 64
        workspace.StreamingTargetRadius = originalSettings.streamingTargetRadius or 1024
        
        settings().Rendering.QualityLevel = originalSettings.qualityLevel or Enum.QualityLevel.Automatic
        settings().Rendering.MeshPartDetailLevel = originalSettings.meshPartDetailLevel or Enum.MeshPartDetailLevel.DistanceBased
        
        Lighting.GlobalShadows = originalSettings.globalShadows ~= false
        Lighting.Brightness = originalSettings.brightness or 1
        Lighting.FogEnd = originalSettings.fogEnd or 100000
        Lighting.Technology = originalSettings.technology or Enum.Technology.ShadowMap
        
        workspace.Terrain.WaterWaveSize = originalSettings.waterWaveSize or 0.15
        workspace.Terrain.WaterWaveSpeed = originalSettings.waterWaveSpeed or 10
        workspace.Terrain.WaterReflectance = originalSettings.waterReflectance or 1
        workspace.Terrain.WaterTransparency = originalSettings.waterTransparency or 0.3
        workspace.Terrain.Decoration = originalSettings.decoration ~= false
    end)
end

-- Fungsi untuk melindungi GUI dari sync/detection
local function protectGui(gui)
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = CoreGui
    elseif CoreGui then
        gui.Parent = CoreGui
    end
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NightmareHubV1"
screenGui.ResetOnSpawn = false

-- Destroy existing GUI if ada (SELEPAS CIPTA SCREENGUI)
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name == "NightmareHubV1" and gui ~= screenGui then
        gui:Destroy()
    end
end

-- Buat Toggle Button (sebelum main frame)
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -30)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://121996261654076"
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = screenGui

-- Buat Frame (rectangle) - Lebar 450 pixel
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Rectangle"
mainFrame.Size = UDim2.new(0, 450, 0, 310)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -155)
mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
mainFrame.BackgroundTransparency = 0.12
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false  -- Hidden masa mula execute
mainFrame.Parent = screenGui

-- Save original position untuk reset
local originalPosition = mainFrame.Position

-- Buat UICorner untuk rounded corners
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 5)
uiCorner.Parent = mainFrame

-- Buat UIStroke (outline)
local frameStroke = Instance.new("UIStroke")
frameStroke.Name = "Outline"
frameStroke.Color = Color3.fromRGB(180, 0, 0)
frameStroke.Thickness = 1.5
frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameStroke.Parent = mainFrame

-- Buat UIGradient untuk stroke (Merah Pekat ke Hitam)
local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),   -- Merah Pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))      -- Hitam
}
uiGradient.Parent = frameStroke

-- Gradient Animation (rotating)
local gradientTweenInfo = TweenInfo.new(
    2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut,
    -1,
    false,
    0
)

TweenService:Create(uiGradient, gradientTweenInfo, {Rotation = 360}):Play()

-- ========== LOGO/IMAGE DI HUJUNG KIRI ATAS ==========
local logoImage = Instance.new("ImageLabel")
logoImage.Name = "LogoImage"
logoImage.Size = UDim2.new(0, 65, 0, 65)
logoImage.Position = UDim2.new(0, 10, 0, -3)
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://107226954986307"
logoImage.ScaleType = Enum.ScaleType.Fit
logoImage.Parent = mainFrame

-- Buat Divider Kecil di Sebelah Kanan Logo
local logoDivider = Instance.new("Frame")
logoDivider.Name = "LogoDivider"
logoDivider.Size = UDim2.new(0, 1, 0, 25)
logoDivider.Position = UDim2.new(0, 95, 0, 8)
logoDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Kelabu
logoDivider.BackgroundTransparency = 0.5  -- Nipis
logoDivider.BorderSizePixel = 0
logoDivider.Parent = mainFrame

-- Buat Title "Nightmare Hub"
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0, 200, 0, 30)
titleLabel.Position = UDim2.new(0, 115, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Nightmare Hub"
titleLabel.TextColor3 = Color3.fromRGB(180, 0, 0)  -- Merah pekat
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Buat Subtitle
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(0, 300, 0, 15)
subtitleLabel.Position = UDim2.new(0, 115, 0, 30)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Version: 1.0 | https://discord.gg/Y7FEf44YH"
subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)  -- Kelabu
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 10  -- Kecil
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = mainFrame

-- Buat Divider Horizontal di Bawah Subtitle
local subtitleDivider = Instance.new("Frame")
subtitleDivider.Name = "SubtitleDivider"
subtitleDivider.Size = UDim2.new(1, -20, 0, 1)  -- Full width minus 20px padding, height 1px
subtitleDivider.Position = UDim2.new(0, 10, 0, 47)  -- X=10 (padding), Y=47 (bawah subtitle)
subtitleDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Kelabu
subtitleDivider.BackgroundTransparency = 0.5  -- Nipis
subtitleDivider.BorderSizePixel = 0
subtitleDivider.Parent = mainFrame

-- Buat Reset UI Button
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(0, 70, 0, 20)  -- 70x20 pixel
resetButton.Position = UDim2.new(1, -80, 0, 8)  -- Hujung kanan atas, di atas fps label
resetButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Hitam
resetButton.BackgroundTransparency = 0.75
resetButton.BorderSizePixel = 0
resetButton.Text = "Reset UI"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Putih
resetButton.Font = Enum.Font.Gotham
resetButton.TextSize = 10
resetButton.Parent = mainFrame

-- Buat UICorner untuk Reset Button
local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 5)
resetCorner.Parent = resetButton

-- Buat UIStroke untuk Reset Button
local resetStroke = Instance.new("UIStroke")
resetStroke.Color = Color3.fromRGB(180, 0, 0)  -- Merah
resetStroke.Thickness = 1.0
resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
resetStroke.Parent = resetButton

-- Reset Button Functionality
resetButton.MouseButton1Click:Connect(function()
    -- Tween mainFrame balik ke original position
    local resetTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = originalPosition
    })
    resetTween:Play()
end)

-- Buat FPS & Ping Counter
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FpsLabel"
fpsLabel.Size = UDim2.new(0, 150, 0, 15)
fpsLabel.Position = UDim2.new(1, -160, 0, 30)  -- Y=30 (bawah reset button)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Fps: 0, Ping: 0"
fpsLabel.TextColor3 = Color3.fromRGB(180, 0, 0)  -- Merah pekat
fpsLabel.Font = Enum.Font.GothamMedium
fpsLabel.TextSize = 10
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = mainFrame

-- FPS & Ping Counter Logic
local frames = 0
local last = tick()

RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        local fps = frames
        frames = 0
        last = now
        
        local rawPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local ping = math.floor(rawPing + 0.5)
        
        fpsLabel.Text = "Fps: " .. fps .. ", Ping: " .. ping
    end
end)

-- ========== SIDEBAR TAB SECTION ==========

-- Buat Side Tab Container (Invisible Background)
local sideTabContainer = Instance.new("Frame")
sideTabContainer.Name = "SideTabContainer"
sideTabContainer.Size = UDim2.new(0, 80, 0, 200)
sideTabContainer.Position = UDim2.new(0, 10, 0, 48)
sideTabContainer.BackgroundTransparency = 1
sideTabContainer.BorderSizePixel = 0
sideTabContainer.Parent = mainFrame

-- Buat Divider (Vertical Line) - ADJUSTED: Position turun 4px
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(0, 1, 0, 247)  -- Height kurang 3px dari 250
divider.Position = UDim2.new(0, 95, 0, 49)  -- Y dari 45 ke 49 (turun 4px)
divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Kelabu
divider.BackgroundTransparency = 0.5  -- Nipis
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- Tab Names (TUKAR "Keybind" ke "Priority")
local tabNames = {"Stealer", "Duel", "Misc", "Server", "Priority"}
local tabButtons = {}
local tabFrames = {}
local tabIndicators = {}
local currentTab = "Stealer"  -- Default tab
local activeTweens = {}  -- Track active tweens

-- Buat Tab Buttons dengan ・ dan Indicator
for i, tabName in ipairs(tabNames) do
    -- Buat Tab Indicator (Rounded Rectangle)
    local tabIndicator = Instance.new("Frame")
    tabIndicator.Name = tabName .. "Indicator"
    tabIndicator.Size = UDim2.new(0, 78, 0, 30)
    tabIndicator.Position = UDim2.new(0, -1, 0, (i-1) * 45 + 5)
    tabIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)  -- Kelabu cair
    tabIndicator.BackgroundTransparency = 0.85
    tabIndicator.BorderSizePixel = 0
    tabIndicator.Visible = (tabName == "Stealer")  -- Show only for Stealer (default)
    tabIndicator.Parent = sideTabContainer
    
    -- Rounded Corner untuk Indicator
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 5)
    indicatorCorner.Parent = tabIndicator
    
    table.insert(tabIndicators, tabIndicator)
    
    -- Buat Tab Button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName .. "Tab"
    tabButton.Size = UDim2.new(1, 0, 0, 40)
    tabButton.Position = UDim2.new(0, 0, 0, (i-1) * 45)
    tabButton.BackgroundTransparency = 1
    tabButton.Text = "・" .. tabName
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = 14
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.ZIndex = 2  -- Supaya button di atas indicator
    tabButton.Parent = sideTabContainer
    
    table.insert(tabButtons, {button = tabButton, name = tabName, indicator = tabIndicator})
end

-- Function untuk buat Content Frame untuk setiap tab - ADJUSTED: Kekiri sikit
local function createContentFrame(tabName)
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = tabName .. "Content"
    contentFrame.Size = UDim2.new(0, 310, 0, 245)  -- Lebar 310px
    contentFrame.Position = UDim2.new(0, 120, 0, 58)  -- X dari 130 ke 120 (kekiri 10px)
    contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contentFrame.BackgroundTransparency = 0.78
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    contentFrame.ScrollBarImageTransparency = 0.5
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
    contentFrame.Visible = (tabName == "Stealer")  -- Show only Stealer content by default
    contentFrame.ClipsDescendants = true  -- FIXED: Prevent overflow
    contentFrame.Parent = mainFrame
    
    -- Rounded Corner
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 14)
    contentCorner.Parent = contentFrame
    
    -- UIListLayout
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = contentFrame
    
    -- UIPadding
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 10)
    contentPadding.PaddingRight = UDim.new(0, 10)
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = contentFrame
    
    -- Update CanvasSize based on AbsoluteCanvasSize
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    return contentFrame
end

-- Buat Content Frames untuk setiap tab
for _, tabName in ipairs(tabNames) do
    local frame = createContentFrame(tabName)
    tabFrames[tabName] = frame
end

-- ========== PRIORITY TAB CONTENT (KECILKAN TINGGI) ==========
-- State untuk selection
local isSelected = false

-- Buat Priority Item Frame (HEIGHT DARI 60 KE 50)
local priorityItem = Instance.new("Frame")
priorityItem.Name = "PriorityItem"
priorityItem.Size = UDim2.new(1, -20, 0, 50)  -- Height 50px (dari 60px)
priorityItem.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
priorityItem.BackgroundTransparency = 0.85
priorityItem.BorderSizePixel = 0
priorityItem.Parent = tabFrames["Priority"]

-- Rounded Corner 6px
local priorityCorner = Instance.new("UICorner")
priorityCorner.CornerRadius = UDim.new(0, 6)
priorityCorner.Parent = priorityItem

-- Outline Gradient (Merah Pekat ke Merah Gelap, TIADA ANIMATION)
local priorityStroke = Instance.new("UIStroke")
priorityStroke.Color = Color3.fromRGB(180, 0, 0)
priorityStroke.Thickness = 1.5
priorityStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
priorityStroke.Parent = priorityItem

-- Gradient untuk Stroke
local priorityGradient = Instance.new("UIGradient")
priorityGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),   -- Kiri: Merah Pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))     -- Kanan: Merah Gelap
}
priorityGradient.Rotation = 0
priorityGradient.Parent = priorityStroke

-- Text Label "La Secrest Combinasion" (GothamBold, Putih dengan Stroke Hitam) - Y POSITION 7
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(0, 200, 0, 20)
titleText.Position = UDim2.new(0, 10, 0, 7)
titleText.BackgroundTransparency = 1
titleText.Text = "La Secrest Combinasion"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Putih
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.TextYAlignment = Enum.TextYAlignment.Top
titleText.Parent = priorityItem

-- Text Stroke (Hitam)
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 0, 0)  -- Hitam
titleStroke.Thickness = 1.5
titleStroke.Parent = titleText

-- Text Label "125M/s" (Gotham, Hijau dengan Stroke Hitam)
local speedText = Instance.new("TextLabel")
speedText.Name = "SpeedText"
speedText.Size = UDim2.new(0, 200, 0, 20)
speedText.Position = UDim2.new(0, 10, 0, 27)
speedText.BackgroundTransparency = 1
speedText.Text = "125M/s"
speedText.TextColor3 = Color3.fromRGB(0, 255, 0)  -- Hijau
speedText.Font = Enum.Font.Gotham
speedText.TextSize = 12
speedText.TextXAlignment = Enum.TextXAlignment.Left
speedText.TextYAlignment = Enum.TextYAlignment.Top
speedText.Parent = priorityItem

-- Text Stroke (Hitam)
local speedStroke = Instance.new("UIStroke")
speedStroke.Color = Color3.fromRGB(0, 0, 0)  -- Hitam
speedStroke.Thickness = 1.5
speedStroke.Parent = speedText

-- Select Button (Hujung Kanan) - KECILKAN SIKIT
local selectButton = Instance.new("TextButton")
selectButton.Name = "SelectButton"
selectButton.Size = UDim2.new(0, 65, 0, 26)
selectButton.Position = UDim2.new(1, -75, 0.5, -13)
selectButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
selectButton.BackgroundTransparency = 0.71
selectButton.BorderSizePixel = 0
selectButton.Text = "Select"
selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
selectButton.Font = Enum.Font.GothamMedium
selectButton.TextSize = 11
selectButton.Parent = priorityItem

-- Rounded Corner 7px
local selectCorner = Instance.new("UICorner")
selectCorner.CornerRadius = UDim.new(0, 7)
selectCorner.Parent = selectButton

-- Outline Merah Pekat
local selectStroke = Instance.new("UIStroke")
selectStroke.Color = Color3.fromRGB(180, 0, 0)  -- Merah Pekat
selectStroke.Thickness = 1.5
selectStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
selectStroke.Parent = selectButton

-- Select Button Functionality
selectButton.MouseButton1Click:Connect(function()
    isSelected = not isSelected
    
    if isSelected then
        selectButton.Text = "Selected"
        showNotification("La Secrest Combinasion: Selected")
    else
        selectButton.Text = "Select"
        showNotification("La Secrest Combinasion: Deselected")
    end
end)

-- ========== INVIS PANEL TOGGLE UNTUK STEALER TAB (KECIL) ==========
-- Buat Toggle Frame untuk Stealer Tab
local invisToggleFrame = Instance.new("Frame")
invisToggleFrame.Name = "InvisPanelToggle"
invisToggleFrame.Size = UDim2.new(1, -20, 0, 35)  -- Full width minus padding, height 35px
invisToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Hitam
invisToggleFrame.BackgroundTransparency = 0.25
invisToggleFrame.BorderSizePixel = 0
invisToggleFrame.ClipsDescendants = false  -- Biar toggle nampak
invisToggleFrame.Parent = tabFrames["Stealer"]

-- Rounded Corner 5px
local invisCorner = Instance.new("UICorner")
invisCorner.CornerRadius = UDim.new(0, 5)
invisCorner.Parent = invisToggleFrame

-- Outline Gradient (Merah Pekat ke Merah Gelap, TIADA ANIMATION)
local invisStroke = Instance.new("UIStroke")
invisStroke.Color = Color3.fromRGB(180, 0, 0)  -- Default merah pekat
invisStroke.Thickness = 1.5
invisStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
invisStroke.Parent = invisToggleFrame

-- Gradient untuk Stroke (Kiri Merah Pekat, Kanan Merah Gelap)
local invisGradient = Instance.new("UIGradient")
invisGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),   -- Kiri: Merah Pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))     -- Kanan: Merah Gelap
}
invisGradient.Rotation = 0  -- Horizontal (kiri ke kanan)
invisGradient.Parent = invisStroke

-- Text Label "Invis Panel" di hujung kiri
local invisLabel = Instance.new("TextLabel")
invisLabel.Name = "InvisLabel"
invisLabel.Size = UDim2.new(0, 100, 1, 0)  -- Width 100px, full height
invisLabel.Position = UDim2.new(0, 10, 0, 0)  -- 10px padding dari kiri
invisLabel.BackgroundTransparency = 1
invisLabel.Text = "Invis Panel"
invisLabel.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Putih kelabu
invisLabel.Font = Enum.Font.GothamMedium
invisLabel.TextSize = 12
invisLabel.TextXAlignment = Enum.TextXAlignment.Left
invisLabel.TextTruncate = Enum.TextTruncate.AtEnd
invisLabel.Parent = invisToggleFrame

-- Toggle Background (Rounded Rectangle di hujung kanan) - KECIL
local toggleBg = Instance.new("Frame")
toggleBg.Name = "ToggleBg"
toggleBg.Size = UDim2.new(0, 35, 0, 18)  -- Width 35px (dari 45), height 18px (dari 22)
toggleBg.Position = UDim2.new(1, -45, 0.5, -9)  -- 10px dari kanan, centered vertically
toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  -- Hitam cerah
toggleBg.BorderSizePixel = 0
toggleBg.Parent = invisToggleFrame

-- Rounded Corner untuk Toggle Background
local toggleBgCorner = Instance.new("UICorner")
toggleBgCorner.CornerRadius = UDim.new(1, 0)  -- Fully rounded (circle ends)
toggleBgCorner.Parent = toggleBg

-- Gradient untuk Toggle Background (Kiri Hitam Cerah, Kanan Merah Gelap)
local toggleBgGradient = Instance.new("UIGradient")
toggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),   -- Kiri: Hitam Cerah
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))      -- Kanan: Merah Gelap
}
toggleBgGradient.Rotation = 0  -- Horizontal
toggleBgGradient.Parent = toggleBg

-- Toggle Circle (Merah Cerah) - KECIL
local toggleCircle = Instance.new("Frame")
toggleCircle.Name = "ToggleCircle"
toggleCircle.Size = UDim2.new(0, 14, 0, 14)  -- 14x14 pixel circle (dari 18x18)
toggleCircle.Position = UDim2.new(0, 2, 0.5, -7)  -- Start position (OFF state)
toggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)  -- Merah Cerah
toggleCircle.BorderSizePixel = 0
toggleCircle.Parent = toggleBg

-- Rounded Corner untuk Circle
local toggleCircleCorner = Instance.new("UICorner")
toggleCircleCorner.CornerRadius = UDim.new(1, 0)  -- Fully rounded (circle)
toggleCircleCorner.Parent = toggleCircle

-- Toggle Button (Invisible, covers entire frame)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = ""
toggleButton.Parent = invisToggleFrame

-- Load config dan set toggle state
local invisPanelEnabled = currentConfig.InvisPanel or false

-- Update visual berdasarkan saved config
if invisPanelEnabled then
	toggleCircle.Position = UDim2.new(1, -16, 0.5, -7)  -- ON position
else
	toggleCircle.Position = UDim2.new(0, 2, 0.5, -7)  -- OFF position
end

-- Toggle Functionality dengan CONFIG SAVE
toggleButton.MouseButton1Click:Connect(function()
	invisPanelEnabled = not invisPanelEnabled
	
	-- Animate circle position
	local targetPos
	if invisPanelEnabled then
		targetPos = UDim2.new(1, -16, 0.5, -7)  -- Move to right (ON state)
		showNotification("Invis Panel: Enabled")
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)  -- Move to left (OFF state)
		showNotification("Invis Panel: Disabled")
	end
	
	-- Tween circle movement
	local circleTween = TweenService:Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	-- SAVE TO CONFIG
	ConfigSystem:UpdateSetting(currentConfig, "InvisPanel", invisPanelEnabled)
	
	-- TODO: Add actual Invis Panel functionality here
	-- Example: mainFrame.Visible = not invisPanelEnabled
end)

-- ========== INPUT BUTTON UNTUK SERVER TAB ==========
-- Buat Input Button untuk Server Tab
local inputButton = Instance.new("Frame")
inputButton.Name = "InputJobID"
inputButton.Size = UDim2.new(1, -20, 0, 35)  -- Full width minus padding, height 35px
inputButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Hitam
inputButton.BackgroundTransparency = 0.25
inputButton.BorderSizePixel = 0
inputButton.ClipsDescendants = true  -- FIXED: Prevent text overflow
inputButton.Parent = tabFrames["Server"]

-- Rounded Corner 5px
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = inputButton

-- Outline Gradient (Merah Pekat ke Merah Gelap, TIADA ANIMATION)
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(180, 0, 0)  -- Default merah pekat
inputStroke.Thickness = 1.5
inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputStroke.Parent = inputButton

-- Gradient untuk Stroke (Kiri Merah Pekat, Kanan Merah Gelap)
local inputGradient = Instance.new("UIGradient")
inputGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),   -- Kiri: Merah Pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))     -- Kanan: Merah Gelap
}
inputGradient.Rotation = 0  -- Horizontal (kiri ke kanan)
inputGradient.Parent = inputStroke

-- Text Label "Input Job ID" di hujung kiri
local inputLabel = Instance.new("TextLabel")
inputLabel.Name = "InputLabel"
inputLabel.Size = UDim2.new(0, 100, 1, 0)  -- Width 100px, full height
inputLabel.Position = UDim2.new(0, 10, 0, 0)  -- 10px padding dari kiri
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "Input Job ID"
inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Putih kelabu
inputLabel.Font = Enum.Font.GothamMedium
inputLabel.TextSize = 12
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.TextTruncate = Enum.TextTruncate.AtEnd  -- FIXED: Truncate if too long
inputLabel.Parent = inputButton

-- TextBox (Placeholder) di hujung kanan
local inputBox = Instance.new("TextBox")
inputBox.Name = "InputBox"
inputBox.Size = UDim2.new(0, 150, 1, -10)  -- Width 150px, height minus 10px untuk padding
inputBox.Position = UDim2.new(1, -160, 0, 5)  -- 10px dari kanan, 5px dari atas
inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Hitam
inputBox.BackgroundTransparency = 0.65
inputBox.BorderSizePixel = 0
inputBox.Text = ""
inputBox.PlaceholderText = "Enter Job ID..."
inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)  -- Kelabu
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Putih
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 11
inputBox.TextXAlignment = Enum.TextXAlignment.Center
inputBox.ClearTextOnFocus = false
inputBox.TextTruncate = Enum.TextTruncate.AtEnd  -- FIXED: Truncate if too long
inputBox.Parent = inputButton

-- Rounded Corner untuk TextBox
local inputBoxCorner = Instance.new("UICorner")
inputBoxCorner.CornerRadius = UDim.new(0, 4)
inputBoxCorner.Parent = inputBox

-- ========== JOIN SERVER BUTTON UNTUK SERVER TAB ==========
-- Buat Join Server Button untuk Server Tab
local joinButton = Instance.new("TextButton")
joinButton.Name = "JoinServerButton"
joinButton.Size = UDim2.new(1, -20, 0, 35)  -- Full width minus padding, height 35px
joinButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Hitam
joinButton.BackgroundTransparency = 0.25
joinButton.BorderSizePixel = 0
joinButton.Text = ""  -- Kosong sebab kita guna label
joinButton.ClipsDescendants = true  -- FIXED: Prevent overflow
joinButton.Parent = tabFrames["Server"]

-- Rounded Corner 5px
local joinCorner = Instance.new("UICorner")
joinCorner.CornerRadius = UDim.new(0, 5)
joinCorner.Parent = joinButton

-- Outline Gradient (Merah Pekat ke Merah Gelap, TIADA ANIMATION)
local joinStroke = Instance.new("UIStroke")
joinStroke.Color = Color3.fromRGB(180, 0, 0)  -- Default merah pekat
joinStroke.Thickness = 1.5
joinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
joinStroke.Parent = joinButton

-- Gradient untuk Stroke (Kiri Merah Pekat, Kanan Merah Gelap)
local joinGradient = Instance.new("UIGradient")
joinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),   -- Kiri: Merah Pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))     -- Kanan: Merah Gelap
}
joinGradient.Rotation = 0  -- Horizontal (kiri ke kanan)
joinGradient.Parent = joinStroke

-- Text Label "Join Server" di hujung kiri
local joinLabel = Instance.new("TextLabel")
joinLabel.Name = "JoinLabel"
joinLabel.Size = UDim2.new(0, 100, 1, 0)  -- Width 100px, full height
joinLabel.Position = UDim2.new(0, 10, 0, 0)  -- 10px padding dari kiri
joinLabel.BackgroundTransparency = 1
joinLabel.Text = "Join Server"
joinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)  -- Putih kelabu
joinLabel.Font = Enum.Font.GothamMedium
joinLabel.TextSize = 12
joinLabel.TextXAlignment = Enum.TextXAlignment.Left
joinLabel.TextTruncate = Enum.TextTruncate.AtEnd  -- FIXED: Truncate if too long
joinLabel.Parent = joinButton

-- Icon di hujung kanan
local joinIcon = Instance.new("ImageLabel")
joinIcon.Name = "JoinIcon"
joinIcon.Size = UDim2.new(0, 20, 0, 20)  -- 20x20 pixel
joinIcon.Position = UDim2.new(1, -30, 0.5, -10)  -- 10px dari kanan, centered vertically
joinIcon.BackgroundTransparency = 1
joinIcon.Image = "rbxassetid://97462463002118"
joinIcon.ScaleType = Enum.ScaleType.Fit
joinIcon.Parent = joinButton

-- Join Server Functionality
joinButton.MouseButton1Click:Connect(function()
    local jobId = inputBox.Text
    
    if jobId == "" then
        -- Kalau kosong, bagi warning via notification
        showNotification("Please enter a Job ID first!")
        return
    end
    
    -- Show notification sedang join
    showNotification("Joining server: " .. jobId)
    
    -- Teleport ke server dengan Job ID
    local TeleportService = game:GetService("TeleportService")
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    
    if not success then
        warn("Failed to join server:", errorMessage)
        showNotification("Failed to join! Invalid Job ID.")
    end
end)

-- ========== COPY JOB ID BUTTON ==========
local copyJobButton = Instance.new("TextButton")
copyJobButton.Name = "CopyJobIDButton"
copyJobButton.Size = UDim2.new(1, -20, 0, 35)
copyJobButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
copyJobButton.BackgroundTransparency = 0.25
copyJobButton.BorderSizePixel = 0
copyJobButton.Text = ""
copyJobButton.ClipsDescendants = true
copyJobButton.Parent = tabFrames["Server"]

-- Rounded Corner 5px
local copyJobCorner = Instance.new("UICorner")
copyJobCorner.CornerRadius = UDim.new(0, 5)
copyJobCorner.Parent = copyJobButton

-- Outline Gradient
local copyJobStroke = Instance.new("UIStroke")
copyJobStroke.Color = Color3.fromRGB(180, 0, 0)
copyJobStroke.Thickness = 1.5
copyJobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
copyJobStroke.Parent = copyJobButton

-- Gradient untuk Stroke
local copyJobGradient = Instance.new("UIGradient")
copyJobGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
copyJobGradient.Rotation = 0
copyJobGradient.Parent = copyJobStroke

-- Text Label "Copy Job ID" di hujung kiri
local copyJobLabel = Instance.new("TextLabel")
copyJobLabel.Name = "CopyJobLabel"
copyJobLabel.Size = UDim2.new(0, 100, 1, 0)
copyJobLabel.Position = UDim2.new(0, 10, 0, 0)
copyJobLabel.BackgroundTransparency = 1
copyJobLabel.Text = "Copy Job ID"
copyJobLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
copyJobLabel.Font = Enum.Font.GothamMedium
copyJobLabel.TextSize = 12
copyJobLabel.TextXAlignment = Enum.TextXAlignment.Left
copyJobLabel.TextTruncate = Enum.TextTruncate.AtEnd
copyJobLabel.Parent = copyJobButton

-- Icon di hujung kanan
local copyJobIcon = Instance.new("ImageLabel")
copyJobIcon.Name = "CopyJobIcon"
copyJobIcon.Size = UDim2.new(0, 20, 0, 20)
copyJobIcon.Position = UDim2.new(1, -30, 0.5, -10)
copyJobIcon.BackgroundTransparency = 1
copyJobIcon.Image = "rbxassetid://97462463002118"
copyJobIcon.ScaleType = Enum.ScaleType.Fit
copyJobIcon.Parent = copyJobButton

-- Copy Job ID Functionality
copyJobButton.MouseButton1Click:Connect(function()
    local currentJobId = game.JobId
    
    -- Copy to clipboard
    if setclipboard then
        setclipboard(currentJobId)
        showNotification("Job ID copied: " .. currentJobId)
    else
        showNotification("Clipboard not supported!")
    end
end)

-- ========== HOP SERVER BUTTON (DESIGN SAMA SEPERTI JOIN SERVER) ==========
local hopButton = Instance.new("TextButton")
hopButton.Name = "HopServerButton"
hopButton.Size = UDim2.new(1, -20, 0, 35)
hopButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hopButton.BackgroundTransparency = 0.25
hopButton.BorderSizePixel = 0
hopButton.Text = ""
hopButton.ClipsDescendants = true
hopButton.Parent = tabFrames["Server"]

-- Rounded Corner 5px
local hopCorner = Instance.new("UICorner")
hopCorner.CornerRadius = UDim.new(0, 5)
hopCorner.Parent = hopButton

-- Outline Gradient
local hopStroke = Instance.new("UIStroke")
hopStroke.Color = Color3.fromRGB(180, 0, 0)
hopStroke.Thickness = 1.5
hopStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hopStroke.Parent = hopButton

-- Gradient untuk Stroke
local hopGradient = Instance.new("UIGradient")
hopGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
hopGradient.Rotation = 0
hopGradient.Parent = hopStroke

-- Text Label "Hop Server" di hujung kiri
local hopLabel = Instance.new("TextLabel")
hopLabel.Name = "HopLabel"
hopLabel.Size = UDim2.new(0, 100, 1, 0)
hopLabel.Position = UDim2.new(0, 10, 0, 0)
hopLabel.BackgroundTransparency = 1
hopLabel.Text = "Hop Server"
hopLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hopLabel.Font = Enum.Font.GothamMedium
hopLabel.TextSize = 12
hopLabel.TextXAlignment = Enum.TextXAlignment.Left
hopLabel.TextTruncate = Enum.TextTruncate.AtEnd
hopLabel.Parent = hopButton

-- Icon di hujung kanan (sama seperti Join Server)
local hopIcon = Instance.new("ImageLabel")
hopIcon.Name = "HopIcon"
hopIcon.Size = UDim2.new(0, 20, 0, 20)
hopIcon.Position = UDim2.new(1, -30, 0.5, -10)
hopIcon.BackgroundTransparency = 1
hopIcon.Image = "rbxassetid://97462463002118"
hopIcon.ScaleType = Enum.ScaleType.Fit
hopIcon.Parent = hopButton

-- Hop Server Functionality
hopButton.MouseButton1Click:Connect(function()
    showNotification("Server hopping...")
    
    local TeleportService = game:GetService("TeleportService")
    
    local success, result = pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        
        for _, server in pairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                return
            end
        end
        
        showNotification("No available servers found!")
    end)
    
    if not success then
        warn("Failed to hop server:", result)
        showNotification("Failed to hop server!")
    end
end)

-- ========== REJOIN SERVER BUTTON (DESIGN SAMA SEPERTI JOIN SERVER) ==========
local rejoinButton = Instance.new("TextButton")
rejoinButton.Name = "RejoinServerButton"
rejoinButton.Size = UDim2.new(1, -20, 0, 35)
rejoinButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rejoinButton.BackgroundTransparency = 0.25
rejoinButton.BorderSizePixel = 0
rejoinButton.Text = ""
rejoinButton.ClipsDescendants = true
rejoinButton.Parent = tabFrames["Server"]

-- Rounded Corner 5px
local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 5)
rejoinCorner.Parent = rejoinButton

-- Outline Gradient
local rejoinStroke = Instance.new("UIStroke")
rejoinStroke.Color = Color3.fromRGB(180, 0, 0)
rejoinStroke.Thickness = 1.5
rejoinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rejoinStroke.Parent = rejoinButton

-- Gradient untuk Stroke
local rejoinGradient = Instance.new("UIGradient")
rejoinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
rejoinGradient.Rotation = 0
rejoinGradient.Parent = rejoinStroke

-- Text Label "Rejoin Server" di hujung kiri
local rejoinLabel = Instance.new("TextLabel")
rejoinLabel.Name = "RejoinLabel"
rejoinLabel.Size = UDim2.new(0, 100, 1, 0)
rejoinLabel.Position = UDim2.new(0, 10, 0, 0)
rejoinLabel.BackgroundTransparency = 1
rejoinLabel.Text = "Rejoin Server"
rejoinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rejoinLabel.Font = Enum.Font.GothamMedium
rejoinLabel.TextSize = 12
rejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
rejoinLabel.TextTruncate = Enum.TextTruncate.AtEnd
rejoinLabel.Parent = rejoinButton

-- Icon di hujung kanan (sama seperti Join Server)
local rejoinIcon = Instance.new("ImageLabel")
rejoinIcon.Name = "RejoinIcon"
rejoinIcon.Size = UDim2.new(0, 20, 0, 20)
rejoinIcon.Position = UDim2.new(1, -30, 0.5, -10)
rejoinIcon.BackgroundTransparency = 1
rejoinIcon.Image = "rbxassetid://97462463002118"
rejoinIcon.ScaleType = Enum.ScaleType.Fit
rejoinIcon.Parent = rejoinButton

-- Rejoin Server Functionality
rejoinButton.MouseButton1Click:Connect(function()
    showNotification("Rejoining server...")
    
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, player)
end)

-- ========== ANTI LAG TOGGLE UNTUK MISC TAB ==========
-- Buat Toggle Frame untuk Misc Tab
local antiLagToggleFrame = Instance.new("Frame")
antiLagToggleFrame.Name = "AntiLagToggle"
antiLagToggleFrame.Size = UDim2.new(1, -20, 0, 35)
antiLagToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
antiLagToggleFrame.BackgroundTransparency = 0.25
antiLagToggleFrame.BorderSizePixel = 0
antiLagToggleFrame.ClipsDescendants = false
antiLagToggleFrame.Parent = tabFrames["Misc"]

-- Rounded Corner 5px
local antiLagCorner = Instance.new("UICorner")
antiLagCorner.CornerRadius = UDim.new(0, 5)
antiLagCorner.Parent = antiLagToggleFrame

-- Outline Gradient
local antiLagStroke = Instance.new("UIStroke")
antiLagStroke.Color = Color3.fromRGB(180, 0, 0)
antiLagStroke.Thickness = 1.5
antiLagStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
antiLagStroke.Parent = antiLagToggleFrame

-- Gradient untuk Stroke
local antiLagGradient = Instance.new("UIGradient")
antiLagGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiLagGradient.Rotation = 0
antiLagGradient.Parent = antiLagStroke

-- Text Label "Anti Lag"
local antiLagLabel = Instance.new("TextLabel")
antiLagLabel.Name = "AntiLagLabel"
antiLagLabel.Size = UDim2.new(0, 100, 1, 0)
antiLagLabel.Position = UDim2.new(0, 10, 0, 0)
antiLagLabel.BackgroundTransparency = 1
antiLagLabel.Text = "Anti Lag"
antiLagLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
antiLagLabel.Font = Enum.Font.GothamMedium
antiLagLabel.TextSize = 12
antiLagLabel.TextXAlignment = Enum.TextXAlignment.Left
antiLagLabel.TextTruncate = Enum.TextTruncate.AtEnd
antiLagLabel.Parent = antiLagToggleFrame

-- Toggle Background
local antiLagToggleBg = Instance.new("Frame")
antiLagToggleBg.Name = "ToggleBg"
antiLagToggleBg.Size = UDim2.new(0, 35, 0, 18)
antiLagToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
antiLagToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
antiLagToggleBg.BorderSizePixel = 0
antiLagToggleBg.Parent = antiLagToggleFrame

local antiLagToggleBgCorner = Instance.new("UICorner")
antiLagToggleBgCorner.CornerRadius = UDim.new(1, 0)
antiLagToggleBgCorner.Parent = antiLagToggleBg

local antiLagToggleBgGradient = Instance.new("UIGradient")
antiLagToggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiLagToggleBgGradient.Rotation = 0
antiLagToggleBgGradient.Parent = antiLagToggleBg

-- Toggle Circle
local antiLagToggleCircle = Instance.new("Frame")
antiLagToggleCircle.Name = "ToggleCircle"
antiLagToggleCircle.Size = UDim2.new(0, 14, 0, 14)
antiLagToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
antiLagToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
antiLagToggleCircle.BorderSizePixel = 0
antiLagToggleCircle.Parent = antiLagToggleBg

local antiLagToggleCircleCorner = Instance.new("UICorner")
antiLagToggleCircleCorner.CornerRadius = UDim.new(1, 0)
antiLagToggleCircleCorner.Parent = antiLagToggleCircle

-- Toggle Button
local antiLagToggleButton = Instance.new("TextButton")
antiLagToggleButton.Name = "ToggleButton"
antiLagToggleButton.Size = UDim2.new(1, 0, 1, 0)
antiLagToggleButton.Position = UDim2.new(0, 0, 0, 0)
antiLagToggleButton.BackgroundTransparency = 1
antiLagToggleButton.Text = ""
antiLagToggleButton.Parent = antiLagToggleFrame

-- Load config dan set toggle state
local antiLagEnabled = currentConfig.AntiLag or false

-- Update visual berdasarkan saved config
if antiLagEnabled then
	antiLagToggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	ANTI_LAG.Enable()
end

-- Toggle Functionality dengan CONFIG SAVE
antiLagToggleButton.MouseButton1Click:Connect(function()
	antiLagEnabled = not antiLagEnabled
	
	local targetPos
	if antiLagEnabled then
		targetPos = UDim2.new(1, -16, 0.5, -7)
		ANTI_LAG.Enable()
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)
		ANTI_LAG.Disable()
	end
	
	-- Tween circle movement
	local circleTween = TweenService:Create(antiLagToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	-- SAVE TO CONFIG
	ConfigSystem:UpdateSetting(currentConfig, "AntiLag", antiLagEnabled)
end)

-- ========== ANTI DEBUFF TOGGLE ==========
local antiDebuffToggleFrame = Instance.new("Frame")
antiDebuffToggleFrame.Name = "AntiDebuffToggle"
antiDebuffToggleFrame.Size = UDim2.new(1, -20, 0, 35)
antiDebuffToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
antiDebuffToggleFrame.BackgroundTransparency = 0.25
antiDebuffToggleFrame.BorderSizePixel = 0
antiDebuffToggleFrame.ClipsDescendants = false
antiDebuffToggleFrame.Parent = tabFrames["Misc"]

local antiDebuffCorner = Instance.new("UICorner")
antiDebuffCorner.CornerRadius = UDim.new(0, 5)
antiDebuffCorner.Parent = antiDebuffToggleFrame

local antiDebuffStroke = Instance.new("UIStroke")
antiDebuffStroke.Color = Color3.fromRGB(180, 0, 0)
antiDebuffStroke.Thickness = 1.5
antiDebuffStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
antiDebuffStroke.Parent = antiDebuffToggleFrame

local antiDebuffGradient = Instance.new("UIGradient")
antiDebuffGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiDebuffGradient.Rotation = 0
antiDebuffGradient.Parent = antiDebuffStroke

local antiDebuffLabel = Instance.new("TextLabel")
antiDebuffLabel.Size = UDim2.new(0, 100, 1, 0)
antiDebuffLabel.Position = UDim2.new(0, 10, 0, 0)
antiDebuffLabel.BackgroundTransparency = 1
antiDebuffLabel.Text = "Anti Debuff"
antiDebuffLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
antiDebuffLabel.Font = Enum.Font.GothamMedium
antiDebuffLabel.TextSize = 12
antiDebuffLabel.TextXAlignment = Enum.TextXAlignment.Left
antiDebuffLabel.TextTruncate = Enum.TextTruncate.AtEnd
antiDebuffLabel.Parent = antiDebuffToggleFrame

local antiDebuffToggleBg = Instance.new("Frame")
antiDebuffToggleBg.Size = UDim2.new(0, 35, 0, 18)
antiDebuffToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
antiDebuffToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
antiDebuffToggleBg.BorderSizePixel = 0
antiDebuffToggleBg.Parent = antiDebuffToggleFrame

local antiDebuffToggleBgCorner = Instance.new("UICorner")
antiDebuffToggleBgCorner.CornerRadius = UDim.new(1, 0)
antiDebuffToggleBgCorner.Parent = antiDebuffToggleBg

local antiDebuffToggleBgGradient = Instance.new("UIGradient")
antiDebuffToggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiDebuffToggleBgGradient.Rotation = 0
antiDebuffToggleBgGradient.Parent = antiDebuffToggleBg

local antiDebuffToggleCircle = Instance.new("Frame")
antiDebuffToggleCircle.Size = UDim2.new(0, 14, 0, 14)
antiDebuffToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
antiDebuffToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
antiDebuffToggleCircle.BorderSizePixel = 0
antiDebuffToggleCircle.Parent = antiDebuffToggleBg

local antiDebuffToggleCircleCorner = Instance.new("UICorner")
antiDebuffToggleCircleCorner.CornerRadius = UDim.new(1, 0)
antiDebuffToggleCircleCorner.Parent = antiDebuffToggleCircle

local antiDebuffToggleButton = Instance.new("TextButton")
antiDebuffToggleButton.Size = UDim2.new(1, 0, 1, 0)
antiDebuffToggleButton.Position = UDim2.new(0, 0, 0, 0)
antiDebuffToggleButton.BackgroundTransparency = 1
antiDebuffToggleButton.Text = ""
antiDebuffToggleButton.Parent = antiDebuffToggleFrame

local antiDebuffEnabled = currentConfig.AntiDebuff or false

if antiDebuffEnabled then
	antiDebuffToggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	toggleAntiDebuff(true)
end

antiDebuffToggleButton.MouseButton1Click:Connect(function()
	antiDebuffEnabled = not antiDebuffEnabled
	
	local targetPos
	if antiDebuffEnabled then
		targetPos = UDim2.new(1, -16, 0.5, -7)
		toggleAntiDebuff(true)
		showNotification("Anti Debuff: Enabled")
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)
		toggleAntiDebuff(false)
		showNotification("Anti Debuff: Disabled")
	end
	
	local circleTween = TweenService:Create(antiDebuffToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	ConfigSystem:UpdateSetting(currentConfig, "AntiDebuff", antiDebuffEnabled)
end)

-- ========== ANTI RAGDOLL TOGGLE ==========
local antiRagdollToggleFrame = Instance.new("Frame")
antiRagdollToggleFrame.Name = "AntiRagdollToggle"
antiRagdollToggleFrame.Size = UDim2.new(1, -20, 0, 35)
antiRagdollToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
antiRagdollToggleFrame.BackgroundTransparency = 0.25
antiRagdollToggleFrame.BorderSizePixel = 0
antiRagdollToggleFrame.ClipsDescendants = false
antiRagdollToggleFrame.Parent = tabFrames["Misc"]

local antiRagdollCorner = Instance.new("UICorner")
antiRagdollCorner.CornerRadius = UDim.new(0, 5)
antiRagdollCorner.Parent = antiRagdollToggleFrame

local antiRagdollStroke = Instance.new("UIStroke")
antiRagdollStroke.Color = Color3.fromRGB(180, 0, 0)
antiRagdollStroke.Thickness = 1.5
antiRagdollStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
antiRagdollStroke.Parent = antiRagdollToggleFrame

local antiRagdollGradient = Instance.new("UIGradient")
antiRagdollGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiRagdollGradient.Rotation = 0
antiRagdollGradient.Parent = antiRagdollStroke

local antiRagdollLabel = Instance.new("TextLabel")
antiRagdollLabel.Size = UDim2.new(0, 100, 1, 0)
antiRagdollLabel.Position = UDim2.new(0, 10, 0, 0)
antiRagdollLabel.BackgroundTransparency = 1
antiRagdollLabel.Text = "Anti Ragdoll"
antiRagdollLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
antiRagdollLabel.Font = Enum.Font.GothamMedium
antiRagdollLabel.TextSize = 12
antiRagdollLabel.TextXAlignment = Enum.TextXAlignment.Left
antiRagdollLabel.TextTruncate = Enum.TextTruncate.AtEnd
antiRagdollLabel.Parent = antiRagdollToggleFrame

local antiRagdollToggleBg = Instance.new("Frame")
antiRagdollToggleBg.Size = UDim2.new(0, 35, 0, 18)
antiRagdollToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
antiRagdollToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
antiRagdollToggleBg.BorderSizePixel = 0
antiRagdollToggleBg.Parent = antiRagdollToggleFrame

local antiRagdollToggleBgCorner = Instance.new("UICorner")
antiRagdollToggleBgCorner.CornerRadius = UDim.new(1, 0)
antiRagdollToggleBgCorner.Parent = antiRagdollToggleBg

local antiRagdollToggleBgGradient = Instance.new("UIGradient")
antiRagdollToggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
antiRagdollToggleBgGradient.Rotation = 0
antiRagdollToggleBgGradient.Parent = antiRagdollToggleBg

local antiRagdollToggleCircle = Instance.new("Frame")
antiRagdollToggleCircle.Size = UDim2.new(0, 14, 0, 14)
antiRagdollToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
antiRagdollToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
antiRagdollToggleCircle.BorderSizePixel = 0
antiRagdollToggleCircle.Parent = antiRagdollToggleBg

local antiRagdollToggleCircleCorner = Instance.new("UICorner")
antiRagdollToggleCircleCorner.CornerRadius = UDim.new(1, 0)
antiRagdollToggleCircleCorner.Parent = antiRagdollToggleCircle

local antiRagdollToggleButton = Instance.new("TextButton")
antiRagdollToggleButton.Size = UDim2.new(1, 0, 1, 0)
antiRagdollToggleButton.Position = UDim2.new(0, 0, 0, 0)
antiRagdollToggleButton.BackgroundTransparency = 1
antiRagdollToggleButton.Text = ""
antiRagdollToggleButton.Parent = antiRagdollToggleFrame

local antiRagdollEnabledState = currentConfig.AntiRagdoll or false

if antiRagdollEnabledState then
	antiRagdollToggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	enableAntiRagdoll()
end

antiRagdollToggleButton.MouseButton1Click:Connect(function()
	antiRagdollEnabledState = not antiRagdollEnabledState
	
	local targetPos
	if antiRagdollEnabledState then
		targetPos = UDim2.new(1, -16, 0.5, -7)
		enableAntiRagdoll()
		showNotification("Anti Ragdoll: Enabled")
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)
		disableAntiRagdoll()
		showNotification("Anti Ragdoll: Disabled")
	end
	
	local circleTween = TweenService:Create(antiRagdollToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	ConfigSystem:UpdateSetting(currentConfig, "AntiRagdoll", antiRagdollEnabledState)
end)

-- ========== XRAY BASE TOGGLE ==========
local xrayBaseToggleFrame = Instance.new("Frame")
xrayBaseToggleFrame.Name = "XrayBaseToggle"
xrayBaseToggleFrame.Size = UDim2.new(1, -20, 0, 35)
xrayBaseToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
xrayBaseToggleFrame.BackgroundTransparency = 0.25
xrayBaseToggleFrame.BorderSizePixel = 0
xrayBaseToggleFrame.ClipsDescendants = false
xrayBaseToggleFrame.Parent = tabFrames["Misc"]

local xrayBaseCorner = Instance.new("UICorner")
xrayBaseCorner.CornerRadius = UDim.new(0, 5)
xrayBaseCorner.Parent = xrayBaseToggleFrame

local xrayBaseStroke = Instance.new("UIStroke")
xrayBaseStroke.Color = Color3.fromRGB(180, 0, 0)
xrayBaseStroke.Thickness = 1.5
xrayBaseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
xrayBaseStroke.Parent = xrayBaseToggleFrame

local xrayBaseGradient = Instance.new("UIGradient")
xrayBaseGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
xrayBaseGradient.Rotation = 0
xrayBaseGradient.Parent = xrayBaseStroke

local xrayBaseLabel = Instance.new("TextLabel")
xrayBaseLabel.Size = UDim2.new(0, 100, 1, 0)
xrayBaseLabel.Position = UDim2.new(0, 10, 0, 0)
xrayBaseLabel.BackgroundTransparency = 1
xrayBaseLabel.Text = "Xray Base"
xrayBaseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
xrayBaseLabel.Font = Enum.Font.GothamMedium
xrayBaseLabel.TextSize = 12
xrayBaseLabel.TextXAlignment = Enum.TextXAlignment.Left
xrayBaseLabel.TextTruncate = Enum.TextTruncate.AtEnd
xrayBaseLabel.Parent = xrayBaseToggleFrame

local xrayBaseToggleBg = Instance.new("Frame")
xrayBaseToggleBg.Size = UDim2.new(0, 35, 0, 18)
xrayBaseToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
xrayBaseToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xrayBaseToggleBg.BorderSizePixel = 0
xrayBaseToggleBg.Parent = xrayBaseToggleFrame

local xrayBaseToggleBgCorner = Instance.new("UICorner")
xrayBaseToggleBgCorner.CornerRadius = UDim.new(1, 0)
xrayBaseToggleBgCorner.Parent = xrayBaseToggleBg

local xrayBaseToggleBgGradient = Instance.new("UIGradient")
xrayBaseToggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
xrayBaseToggleBgGradient.Rotation = 0
xrayBaseToggleBgGradient.Parent = xrayBaseToggleBg

local xrayBaseToggleCircle = Instance.new("Frame")
xrayBaseToggleCircle.Size = UDim2.new(0, 14, 0, 14)
xrayBaseToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
xrayBaseToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
xrayBaseToggleCircle.BorderSizePixel = 0
xrayBaseToggleCircle.Parent = xrayBaseToggleBg

local xrayBaseToggleCircleCorner = Instance.new("UICorner")
xrayBaseToggleCircleCorner.CornerRadius = UDim.new(1, 0)
xrayBaseToggleCircleCorner.Parent = xrayBaseToggleCircle

local xrayBaseToggleButton = Instance.new("TextButton")
xrayBaseToggleButton.Size = UDim2.new(1, 0, 1, 0)
xrayBaseToggleButton.Position = UDim2.new(0, 0, 0, 0)
xrayBaseToggleButton.BackgroundTransparency = 1
xrayBaseToggleButton.Text = ""
xrayBaseToggleButton.Parent = xrayBaseToggleFrame

local xrayBaseEnabledState = currentConfig.XrayBase or false

if xrayBaseEnabledState then
	xrayBaseToggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	enableXrayBase()
end

xrayBaseToggleButton.MouseButton1Click:Connect(function()
	xrayBaseEnabledState = not xrayBaseEnabledState
	
	local targetPos
	if xrayBaseEnabledState then
		targetPos = UDim2.new(1, -16, 0.5, -7)
		enableXrayBase()
		showNotification("Xray Base: Enabled")
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)
		disableXrayBase()
		showNotification("Xray Base: Disabled")
	end
	
	local circleTween = TweenService:Create(xrayBaseToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	ConfigSystem:UpdateSetting(currentConfig, "XrayBase", xrayBaseEnabledState)
end)

-- ========== OPTIMIZER TOGGLE ==========
local optimizerToggleFrame = Instance.new("Frame")
optimizerToggleFrame.Name = "OptimizerToggle"
optimizerToggleFrame.Size = UDim2.new(1, -20, 0, 35)
optimizerToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
optimizerToggleFrame.BackgroundTransparency = 0.25
optimizerToggleFrame.BorderSizePixel = 0
optimizerToggleFrame.ClipsDescendants = false
optimizerToggleFrame.Parent = tabFrames["Misc"]

local optimizerCorner = Instance.new("UICorner")
optimizerCorner.CornerRadius = UDim.new(0, 5)
optimizerCorner.Parent = optimizerToggleFrame

local optimizerStroke = Instance.new("UIStroke")
optimizerStroke.Color = Color3.fromRGB(180, 0, 0)
optimizerStroke.Thickness = 1.5
optimizerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
optimizerStroke.Parent = optimizerToggleFrame

local optimizerGradient = Instance.new("UIGradient")
optimizerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
optimizerGradient.Rotation = 0
optimizerGradient.Parent = optimizerStroke

local optimizerLabel = Instance.new("TextLabel")
optimizerLabel.Size = UDim2.new(0, 100, 1, 0)
optimizerLabel.Position = UDim2.new(0, 10, 0, 0)
optimizerLabel.BackgroundTransparency = 1
optimizerLabel.Text = "Optimizer"
optimizerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
optimizerLabel.Font = Enum.Font.GothamMedium
optimizerLabel.TextSize = 12
optimizerLabel.TextXAlignment = Enum.TextXAlignment.Left
optimizerLabel.TextTruncate = Enum.TextTruncate.AtEnd
optimizerLabel.Parent = optimizerToggleFrame

local optimizerToggleBg = Instance.new("Frame")
optimizerToggleBg.Size = UDim2.new(0, 35, 0, 18)
optimizerToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
optimizerToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
optimizerToggleBg.BorderSizePixel = 0
optimizerToggleBg.Parent = optimizerToggleFrame

local optimizerToggleBgCorner = Instance.new("UICorner")
optimizerToggleBgCorner.CornerRadius = UDim.new(1, 0)
optimizerToggleBgCorner.Parent = optimizerToggleBg

local optimizerToggleBgGradient = Instance.new("UIGradient")
optimizerToggleBgGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
}
optimizerToggleBgGradient.Rotation = 0
optimizerToggleBgGradient.Parent = optimizerToggleBg

local optimizerToggleCircle = Instance.new("Frame")
optimizerToggleCircle.Size = UDim2.new(0, 14, 0, 14)
optimizerToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
optimizerToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
optimizerToggleCircle.BorderSizePixel = 0
optimizerToggleCircle.Parent = optimizerToggleBg

local optimizerToggleCircleCorner = Instance.new("UICorner")
optimizerToggleCircleCorner.CornerRadius = UDim.new(1, 0)
optimizerToggleCircleCorner.Parent = optimizerToggleCircle

local optimizerToggleButton = Instance.new("TextButton")
optimizerToggleButton.Size = UDim2.new(1, 0, 1, 0)
optimizerToggleButton.Position = UDim2.new(0, 0, 0, 0)
optimizerToggleButton.BackgroundTransparency = 1
optimizerToggleButton.Text = ""
optimizerToggleButton.Parent = optimizerToggleFrame

local optimizerEnabledState = currentConfig.Optimizer or false

if optimizerEnabledState then
	optimizerToggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	enableFpsBoost()
end

optimizerToggleButton.MouseButton1Click:Connect(function()
	optimizerEnabledState = not optimizerEnabledState
	
	local targetPos
	if optimizerEnabledState then
		targetPos = UDim2.new(1, -16, 0.5, -7)
		enableFpsBoost()
		showNotification("Optimizer: Enabled")
	else
		targetPos = UDim2.new(0, 2, 0.5, -7)
		disableFpsBoost()
		showNotification("Optimizer: Disabled")
	end
	
	local circleTween = TweenService:Create(optimizerToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	circleTween:Play()
	
	ConfigSystem:UpdateSetting(currentConfig, "Optimizer", optimizerEnabledState)
end)

-- Function untuk switch tab dengan animation
local function switchTab(tabName)
    if currentTab == tabName then return end
    
    -- Cancel any active tweens
    if activeTweens[currentTab] then
        activeTweens[currentTab]:Cancel()
    end
    if activeTweens[tabName] then
        activeTweens[tabName]:Cancel()
    end
    
    local tweenInfo = TweenInfo.new(
        0.25,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
    
    -- Hide all indicators and content frames first
    for _, tabData in ipairs(tabButtons) do
        if tabData.name ~= tabName then
            tabData.indicator.Visible = false
            tabData.indicator.BackgroundTransparency = 1
        end
        if tabFrames[tabData.name] then
            tabFrames[tabData.name].Visible = false
        end
    end
    
    -- Show and animate new tab indicator
    for _, tabData in ipairs(tabButtons) do
        if tabData.name == tabName then
            tabData.indicator.Visible = true
            tabData.indicator.BackgroundTransparency = 1
            
            local tween = TweenService:Create(tabData.indicator, tweenInfo, {
                BackgroundTransparency = 0.85
            })
            activeTweens[tabName] = tween
            tween:Play()
            
            -- Show content frame
            if tabFrames[tabName] then
                tabFrames[tabName].Visible = true
            end
            break
        end
    end
    
    currentTab = tabName
end

-- Connect click events untuk tab buttons
for _, tabData in ipairs(tabButtons) do
    tabData.button.MouseButton1Click:Connect(function()
        switchTab(tabData.name)
    end)
end

-- ========== TWEEN ANIMATION SECTION (FIXED) ==========

-- Tween Animation Setup
local isOpen = false
local isAnimating = false  -- Prevent spam clicking
local currentTween = nil  -- Track current tween

-- Tween Info untuk Wind UI style
local openTweenInfo = TweenInfo.new(
    0.4, -- Duration agak slow sikit
    Enum.EasingStyle.Quint, -- Smooth sangat
    Enum.EasingDirection.Out
)

local closeTweenInfo = TweenInfo.new(
    0.3,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.In
)

function OpenWindow()
    if isOpen or isAnimating then return end
    isAnimating = true
    isOpen = true
    
    -- Cancel any existing tween
    if currentTween then
        currentTween:Cancel()
    end
    
    mainFrame.Visible = true
    
    -- Get current position (biar user boleh drag)
    local currentPos = mainFrame.Position
    
    -- Set initial state (kecil + transparent) - MAINTAIN current position
    mainFrame.Size = UDim2.new(0, 315, 0, 217)
    mainFrame.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset - 67.5, currentPos.Y.Scale, currentPos.Y.Offset - 46.5)
    mainFrame.BackgroundTransparency = 1
    
    -- Tween ke normal (besar + visible) - BACK to current position
    currentTween = TweenService:Create(mainFrame, openTweenInfo, {
        Size = UDim2.new(0, 450, 0, 310),
        Position = currentPos,
        BackgroundTransparency = 0.12
    })
    
    currentTween:Play()
    currentTween.Completed:Connect(function()
        isAnimating = false
        currentTween = nil
    end)
end

function CloseWindow()
    if not isOpen or isAnimating then return end
    isAnimating = true
    isOpen = false
    
    -- Cancel any existing tween
    if currentTween then
        currentTween:Cancel()
    end
    
    -- Get current position
    local currentPos = mainFrame.Position
    
    -- Tween balik ke kecil + transparent - MAINTAIN position
    currentTween = TweenService:Create(mainFrame, closeTweenInfo, {
        Size = UDim2.new(0, 315, 0, 217),
        Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset - 67.5, currentPos.Y.Scale, currentPos.Y.Offset - 46.5),
        BackgroundTransparency = 1
    })
    
    currentTween:Play()
    
    currentTween.Completed:Connect(function()
        mainFrame.Visible = false
        -- Reset position back to original untuk next open
        mainFrame.Position = currentPos
        isAnimating = false
        currentTween = nil
    end)
end

-- Toggle functionality dengan Tween (SPAM-PROOF)
ToggleButton.MouseButton1Click:Connect(function()
    if isAnimating then return end  -- Ignore clicks bila tengah animate
    
    if isOpen then
        CloseWindow()
    else
        OpenWindow()
    end
end)

-- Protect GUI
protectGui(screenGui)

-- ========== WATERMARK GUI (ALWAYS VISIBLE) ==========
-- Buat ScreenGui kedua untuk watermark (separate dari main GUI)
local watermarkGui = Instance.new("ScreenGui")
watermarkGui.Name = "NightmareWatermark"
watermarkGui.ResetOnSpawn = false

-- Destroy existing watermark GUI if ada
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name == "NightmareWatermark" and gui ~= watermarkGui then
        gui:Destroy()
    end
end

local watermarkFrame = Instance.new("Frame")
watermarkFrame.Name = "MainFrame"
watermarkFrame.Size = UDim2.new(0, 280, 0, 98)
watermarkFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
watermarkFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
watermarkFrame.BackgroundTransparency = 0.13
watermarkFrame.BorderSizePixel = 0
watermarkFrame.Active = true
watermarkFrame.Draggable = true
watermarkFrame.Parent = watermarkGui

local watermarkOriginalPosition = watermarkFrame.Position

local watermarkCorner = Instance.new("UICorner")
watermarkCorner.CornerRadius = UDim.new(0, 12)
watermarkCorner.Parent = watermarkFrame

local watermarkStroke = Instance.new("UIStroke")
watermarkStroke.Color = Color3.fromRGB(255, 255, 255)
watermarkStroke.Thickness = 1.5
watermarkStroke.Parent = watermarkFrame

local watermarkGradient = Instance.new("UIGradient")
watermarkGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
}
watermarkGradient.Parent = watermarkStroke

local watermarkGradientTween = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0)
TweenService:Create(watermarkGradient, watermarkGradientTween, {Rotation = 360}):Play()

local watermarkStats = Instance.new("TextLabel")
watermarkStats.Name = "StatsLabel"
watermarkStats.Size = UDim2.new(0, 120, 0, 20)
watermarkStats.Position = UDim2.new(0, 8, 0, 5)
watermarkStats.BackgroundTransparency = 1
watermarkStats.Text = "FPS: 0 | Ping: 0ms"
watermarkStats.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkStats.TextSize = 11
watermarkStats.Font = Enum.Font.GothamMedium
watermarkStats.TextXAlignment = Enum.TextXAlignment.Left
watermarkStats.Parent = watermarkFrame

local watermarkTitle = Instance.new("TextLabel")
watermarkTitle.Name = "NightmareLabel"
watermarkTitle.Size = UDim2.new(1, 0, 0, 25)
watermarkTitle.Position = UDim2.new(0, 0, 0, 27)
watermarkTitle.BackgroundTransparency = 1
watermarkTitle.Text = "Nightmare Hub"
watermarkTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
watermarkTitle.TextSize = 19
watermarkTitle.Font = Enum.Font.GothamBold
watermarkTitle.TextXAlignment = Enum.TextXAlignment.Center
watermarkTitle.Parent = watermarkFrame

local watermarkCredit = Instance.new("TextLabel")
watermarkCredit.Name = "CreditLabel"
watermarkCredit.Size = UDim2.new(1, 0, 0, 15)
watermarkCredit.Position = UDim2.new(0, 0, 0, 50)
watermarkCredit.BackgroundTransparency = 1
watermarkCredit.Text = "@Michal718 | Dc : discord.gg/Y7FEf44YH"
watermarkCredit.TextColor3 = Color3.fromRGB(80, 80, 80)
watermarkCredit.TextSize = 10
watermarkCredit.Font = Enum.Font.Gotham
watermarkCredit.TextXAlignment = Enum.TextXAlignment.Center
watermarkCredit.Parent = watermarkFrame

local watermarkColorTween = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)
local watermarkColorAnim = TweenService:Create(watermarkTitle, watermarkColorTween, {TextColor3 = Color3.fromRGB(139, 0, 0)})
watermarkColorAnim:Play()

-- ==================== RESET BUTTON ====================
local watermarkResetButton = Instance.new("TextButton")
watermarkResetButton.Name = "ResetButton"
watermarkResetButton.Size = UDim2.new(0, 55, 0, 18)
watermarkResetButton.Position = UDim2.new(1, -60, 0, 5)
watermarkResetButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
watermarkResetButton.BackgroundTransparency = 0.65
watermarkResetButton.BorderSizePixel = 0
watermarkResetButton.Text = "Reset UI"
watermarkResetButton.TextColor3 = Color3.fromRGB(200, 200, 200)
watermarkResetButton.TextSize = 9
watermarkResetButton.Font = Enum.Font.GothamMedium
watermarkResetButton.Parent = watermarkFrame

local watermarkResetCorner = Instance.new("UICorner")
watermarkResetCorner.CornerRadius = UDim.new(0, 5)
watermarkResetCorner.Parent = watermarkResetButton

local watermarkResetStroke = Instance.new("UIStroke")
watermarkResetStroke.Thickness = 1
watermarkResetStroke.Parent = watermarkResetButton

local watermarkResetGradient = Instance.new("UIGradient")
watermarkResetGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),  -- Kiri: Merah pekat
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))    -- Kanan: Merah gelap
}
watermarkResetGradient.Parent = watermarkResetStroke

watermarkResetButton.MouseButton1Click:Connect(function()
    local resetTween = TweenService:Create(watermarkFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = watermarkOriginalPosition
    })
    resetTween:Play()
end)

-- ==================== MUSIC PLAYER ====================
-- Create Sound Instance
local watermarkSound = Instance.new("Sound")
watermarkSound.SoundId = "rbxassetid://140414471659678"
watermarkSound.Volume = 0.5
watermarkSound.Looped = true
watermarkSound.Parent = workspace

local watermarkIsPlaying = false

-- Play/Pause Button
local watermarkMusicButton = Instance.new("ImageButton")
watermarkMusicButton.Name = "MusicButton"
watermarkMusicButton.Size = UDim2.new(0, 16, 0, 16)
watermarkMusicButton.Position = UDim2.new(0, 48, 1, -26)
watermarkMusicButton.BackgroundTransparency = 1
watermarkMusicButton.Image = "rbxassetid://105515769385827"
watermarkMusicButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
watermarkMusicButton.Parent = watermarkFrame

-- Song Title Label
local watermarkSongTitle = Instance.new("TextLabel")
watermarkSongTitle.Name = "SongTitle"
watermarkSongTitle.Size = UDim2.new(0, 115, 0, 16)
watermarkSongTitle.Position = UDim2.new(0, 75, 1, -26)
watermarkSongTitle.BackgroundTransparency = 1
watermarkSongTitle.Text = "Lofi Chill | By@DistrokidOfficial"
watermarkSongTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkSongTitle.TextSize = 8
watermarkSongTitle.Font = Enum.Font.Gotham
watermarkSongTitle.TextXAlignment = Enum.TextXAlignment.Left
watermarkSongTitle.TextYAlignment = Enum.TextYAlignment.Center
watermarkSongTitle.Parent = watermarkFrame

-- Volume Input Container
local watermarkVolumeContainer = Instance.new("Frame")
watermarkVolumeContainer.Name = "VolumeContainer"
watermarkVolumeContainer.Size = UDim2.new(0, 43, 0, 16)
watermarkVolumeContainer.Position = UDim2.new(0, 193, 1, -26)
watermarkVolumeContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
watermarkVolumeContainer.BackgroundTransparency = 0.65
watermarkVolumeContainer.BorderSizePixel = 0
watermarkVolumeContainer.Parent = watermarkFrame

local watermarkVolumeCorner = Instance.new("UICorner")
watermarkVolumeCorner.CornerRadius = UDim.new(0, 4)
watermarkVolumeCorner.Parent = watermarkVolumeContainer

local watermarkVolumeStroke = Instance.new("UIStroke")
watermarkVolumeStroke.Color = Color3.fromRGB(80, 0, 0)
watermarkVolumeStroke.Thickness = 1
watermarkVolumeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
watermarkVolumeStroke.Parent = watermarkVolumeContainer

-- Volume TextBox
local watermarkVolumeInput = Instance.new("TextBox")
watermarkVolumeInput.Name = "VolumeInput"
watermarkVolumeInput.Size = UDim2.new(1, -8, 1, -4)
watermarkVolumeInput.Position = UDim2.new(0, 4, 0, 2)
watermarkVolumeInput.BackgroundTransparency = 1
watermarkVolumeInput.Text = "0.5"
watermarkVolumeInput.PlaceholderText = "Vol"
watermarkVolumeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkVolumeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
watermarkVolumeInput.TextSize = 8
watermarkVolumeInput.Font = Enum.Font.Gotham
watermarkVolumeInput.TextXAlignment = Enum.TextXAlignment.Center
watermarkVolumeInput.ClearTextOnFocus = false
watermarkVolumeInput.Parent = watermarkVolumeContainer

-- Volume Input Logic
watermarkVolumeInput.FocusLost:Connect(function(enterPressed)
    local inputValue = tonumber(watermarkVolumeInput.Text)
    
    if inputValue then
        inputValue = math.clamp(inputValue, 0, 10)
        watermarkVolumeInput.Text = tostring(inputValue)
        watermarkSound.Volume = inputValue
    else
        watermarkVolumeInput.Text = tostring(watermarkSound.Volume)
    end
end)

-- Music Button Logic
watermarkMusicButton.MouseButton1Click:Connect(function()
    watermarkIsPlaying = not watermarkIsPlaying
    
    if watermarkIsPlaying then
        watermarkMusicButton.Image = "rbxassetid://74634547754086"
        watermarkSound:Play()
    else
        watermarkMusicButton.Image = "rbxassetid://105515769385827"
        watermarkSound:Stop()
    end
end)

-- ==================== FPS & PING UPDATE ====================
local watermarkFrames = 0
local watermarkLast = tick()

RunService.RenderStepped:Connect(function()
    watermarkFrames += 1
    local now = tick()
    if now - watermarkLast >= 1 then
        local fps = watermarkFrames
        watermarkFrames = 0
        watermarkLast = now
        
        local rawPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local ping = math.floor(rawPing + 0.5)
        
        watermarkStats.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
    end
end)

-- Protect Watermark GUI
protectGui(watermarkGui)

-- ========== QUICK PANEL GUI (ALWAYS VISIBLE) ==========
-- Buat ScreenGui ketiga untuk quick panel (separate dari main GUI dan watermark)
local quickPanelGui = Instance.new("ScreenGui")
quickPanelGui.Name = "NightmareMiniGui"
quickPanelGui.ResetOnSpawn = false

-- Destroy existing quick panel GUI if ada
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name == "NightmareMiniGui" and gui ~= quickPanelGui then
        gui:Destroy()
    end
end

-- Buat Frame (Rounded Rectangle) - LEBAR DITAMBAH SEDIKIT
local quickPanelFrame = Instance.new("Frame")
quickPanelFrame.Size = UDim2.new(0, 295, 0, 320)  -- LEBAR dari 280 jadi 295
quickPanelFrame.Position = UDim2.new(0.5, 236, 0.5, -203)
quickPanelFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
quickPanelFrame.BackgroundTransparency = 0.15
quickPanelFrame.BorderSizePixel = 0
quickPanelFrame.Active = true
quickPanelFrame.Draggable = true
quickPanelFrame.Parent = quickPanelGui

-- Buat Rounded Corner (6 pixels)
local quickPanelCorner = Instance.new("UICorner")
quickPanelCorner.CornerRadius = UDim.new(0, 6)
quickPanelCorner.Parent = quickPanelFrame

-- Buat Outline (Stroke) merah cerah dan hitam
local quickPanelStroke = Instance.new("UIStroke")
quickPanelStroke.Color = Color3.fromRGB(255, 0, 0)
quickPanelStroke.Thickness = 1.0
quickPanelStroke.Parent = quickPanelFrame

-- Buat UIGradient untuk stroke (MERAH CERAH DAN HITAM)
local quickPanelGradient = Instance.new("UIGradient")
quickPanelGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
}
quickPanelGradient.Parent = quickPanelStroke

-- Gradient Animation untuk stroke (rotating)
local quickPanelGradientTween = TweenInfo.new(
    2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut,
    -1,
    false,
    0
)

TweenService:Create(quickPanelGradient, quickPanelGradientTween, {Rotation = 360}):Play()

-- BUAT TITLE
local quickPanelTitle = Instance.new("TextLabel")
quickPanelTitle.Size = UDim2.new(1, -40, 0, 35)
quickPanelTitle.Position = UDim2.new(0, 10, 0, 0)
quickPanelTitle.BackgroundTransparency = 1
quickPanelTitle.Text = "Nightmare Quick Panel :3"
quickPanelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
quickPanelTitle.TextSize = 16
quickPanelTitle.Font = Enum.Font.GothamBold
quickPanelTitle.TextStrokeTransparency = 0.5
quickPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
quickPanelTitle.Parent = quickPanelFrame

-- Buat UIGradient untuk Title (MERAH PEKAT KE MERAH CERAH)
local quickPanelTitleGradient = Instance.new("UIGradient")
quickPanelTitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
}
quickPanelTitleGradient.Parent = quickPanelTitle

-- Gradient Animation untuk Title (rotating)
local quickPanelTitleGradientTween = TweenInfo.new(
    2,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.InOut,
    -1,
    false,
    0
)

TweenService:Create(quickPanelTitleGradient, quickPanelTitleGradientTween, {Rotation = 360}):Play()

-- BUAT DIVIDER MERAH GELAP BAWAH TITLE
local quickPanelDivider = Instance.new("Frame")
quickPanelDivider.Size = UDim2.new(0.92, 0, 0, 1)
quickPanelDivider.Position = UDim2.new(0.04, 0, 0, 35)
quickPanelDivider.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
quickPanelDivider.BackgroundTransparency = 0.45
quickPanelDivider.BorderSizePixel = 0
quickPanelDivider.Parent = quickPanelFrame

-- BUAT BUTTON MINIMIZE
local quickPanelMinimize = Instance.new("TextButton")
quickPanelMinimize.Size = UDim2.new(0, 35, 0, 35)
quickPanelMinimize.Position = UDim2.new(1, -35, 0, 0)
quickPanelMinimize.BackgroundTransparency = 1
quickPanelMinimize.Text = "–"
quickPanelMinimize.TextColor3 = Color3.fromRGB(255, 255, 255)
quickPanelMinimize.TextSize = 26
quickPanelMinimize.Font = Enum.Font.Gotham
quickPanelMinimize.Parent = quickPanelFrame

-- CONTAINER UNTUK CONTENT
local quickPanelContent = Instance.new("Frame")
quickPanelContent.Size = UDim2.new(1, 0, 1, -45)
quickPanelContent.Position = UDim2.new(0, 0, 0, 45)
quickPanelContent.BackgroundTransparency = 1
quickPanelContent.Parent = quickPanelFrame

-- DIVIDER VERTIKAL DI TENGAH GUI
local quickPanelCenterDivider = Instance.new("Frame")
quickPanelCenterDivider.Size = UDim2.new(0, 1, 1, -52)
quickPanelCenterDivider.Position = UDim2.new(0.5, 0, 0, 42)
quickPanelCenterDivider.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
quickPanelCenterDivider.BackgroundTransparency = 0.45
quickPanelCenterDivider.BorderSizePixel = 0
quickPanelCenterDivider.Parent = quickPanelFrame

-- FUNGSI UNTUK MEMBUAT TOGGLE (LEBAR DITAMBAH) DENGAN CONFIG SAVE DAN CALLBACKS
local function createQuickToggle(name, configKey, yPosition, onToggle)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, 133, 0, 30)
    toggleFrame.Position = UDim2.new(0, 11, 0, yPosition)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    toggleFrame.BackgroundTransparency = 0.45
    toggleFrame.BorderSizePixel = 0
    toggleFrame.ClipsDescendants = false
    toggleFrame.Parent = quickPanelContent

    local toggleFrameCorner = Instance.new("UICorner")
    toggleFrameCorner.CornerRadius = UDim.new(0, 6)
    toggleFrameCorner.Parent = toggleFrame

    local toggleFrameStroke = Instance.new("UIStroke")
    toggleFrameStroke.Color = Color3.fromRGB(139, 0, 0)
    toggleFrameStroke.Thickness = 1.0
    toggleFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    toggleFrameStroke.Parent = toggleFrame

    local toggleGradient = Instance.new("UIGradient")
    toggleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    toggleGradient.Rotation = 0
    toggleGradient.Parent = toggleFrameStroke

    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(0, 80, 1, 0)
    toggleText.Position = UDim2.new(0, 8, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = name
    toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleText.TextSize = 12
    toggleText.Font = Enum.Font.Gotham
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Parent = toggleFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 34, 0, 16)
    toggleButton.Position = UDim2.new(1, -42, 0.5, -8)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.Parent = toggleFrame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 12, 0, 12)
    toggleCircle.Position = UDim2.new(0, 2, 0.5, -6)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleButton

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    -- Load saved state from config
    local toggleEnabled = currentConfig[configKey] or false
    
    -- Set initial visual state
    if toggleEnabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        toggleCircle.Position = UDim2.new(0, 20, 0.5, -6)
        -- Call the function on startup if enabled
        if onToggle then
            onToggle(true)
        end
    end

    toggleButton.MouseButton1Click:Connect(function()
        toggleEnabled = not toggleEnabled
        
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        if toggleEnabled then
            TweenService:Create(toggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 0, 0)}):Play()
            TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 20, 0.5, -6)}):Play()
            showNotification(name .. ": Enabled")
        else
            TweenService:Create(toggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
            TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
            showNotification(name .. ": Disabled")
        end
        
        -- Call the callback function
        if onToggle then
            onToggle(toggleEnabled)
        end
        
        -- SAVE TO CONFIG
        ConfigSystem:UpdateSetting(currentConfig, configKey, toggleEnabled)
    end)
    
    return toggleFrame
end

-- BUAT SEMUA TOGGLE (SPACING DITAMBAH) DENGAN CONFIG KEYS DAN CALLBACKS
createQuickToggle("Inf Jump", "InfJump", 10, function(enabled)
    toggleInfJump(enabled)
end)

createQuickToggle("Speed", "Speed", 48, function(enabled)
    toggleSpeed(enabled)
end)

createQuickToggle("Steal Floor", "StealFloor", 86, function(enabled)
    -- TODO: Add Steal Floor functionality
end)

createQuickToggle("Insta Floor", "InstaFloor", 124, function(enabled)
    -- TODO: Add Insta Floor functionality
end)

-- BUAT BUTTON "TP TO BEST" DI SEBELAH KANAN DIVIDER TENGAH (LEBAR DITAMBAH)
local quickPanelActionButton = Instance.new("TextButton")
quickPanelActionButton.Size = UDim2.new(0, 133, 0, 30)  -- LEBAR dari 125 jadi 133
quickPanelActionButton.Position = UDim2.new(0.5, 7, 0, 10)
quickPanelActionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
quickPanelActionButton.BackgroundTransparency = 0.45
quickPanelActionButton.BorderSizePixel = 0
quickPanelActionButton.Text = "Tp to Best"
quickPanelActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
quickPanelActionButton.TextSize = 12
quickPanelActionButton.Font = Enum.Font.Gotham
quickPanelActionButton.Parent = quickPanelContent

local quickPanelActionCorner = Instance.new("UICorner")
quickPanelActionCorner.CornerRadius = UDim.new(0, 6)
quickPanelActionCorner.Parent = quickPanelActionButton

local quickPanelActionStroke = Instance.new("UIStroke")
quickPanelActionStroke.Color = Color3.fromRGB(139, 0, 0)
quickPanelActionStroke.Thickness = 1.0
quickPanelActionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
quickPanelActionStroke.Parent = quickPanelActionButton

quickPanelActionButton.MouseButton1Click:Connect(function()
    showNotification("Tp to Best")
end)

-- BUAT BUTTON "TP TO PRIORITY" DI SEBELAH KANAN (BAWAH TP TO BEST)
local quickPanelPriorityButton = Instance.new("TextButton")
quickPanelPriorityButton.Size = UDim2.new(0, 133, 0, 30)
quickPanelPriorityButton.Position = UDim2.new(0.5, 7, 0, 48)  -- Y position 48 (bawah Tp to Best)
quickPanelPriorityButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
quickPanelPriorityButton.BackgroundTransparency = 0.45
quickPanelPriorityButton.BorderSizePixel = 0
quickPanelPriorityButton.Text = "Tp to Priority"
quickPanelPriorityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
quickPanelPriorityButton.TextSize = 12
quickPanelPriorityButton.Font = Enum.Font.Gotham
quickPanelPriorityButton.Parent = quickPanelContent

local quickPanelPriorityCorner = Instance.new("UICorner")
quickPanelPriorityCorner.CornerRadius = UDim.new(0, 6)
quickPanelPriorityCorner.Parent = quickPanelPriorityButton

local quickPanelPriorityStroke = Instance.new("UIStroke")
quickPanelPriorityStroke.Color = Color3.fromRGB(139, 0, 0)
quickPanelPriorityStroke.Thickness = 1.0
quickPanelPriorityStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
quickPanelPriorityStroke.Parent = quickPanelPriorityButton

quickPanelPriorityButton.MouseButton1Click:Connect(function()
    showNotification("Tp to Priority")
end)

-- Variable untuk track status minimize
local quickPanelMinimized = false
local quickPanelOriginalSize = quickPanelFrame.Size

-- Fungsi Minimize/Maximize
quickPanelMinimize.MouseButton1Click:Connect(function()
    if not quickPanelMinimized then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = TweenService:Create(quickPanelFrame, tweenInfo, {Size = UDim2.new(0, 295, 0, 35)})  -- Size disesuaikan
        tween:Play()
        quickPanelMinimize.Text = "+"
        quickPanelDivider.Visible = false
        quickPanelContent.Visible = false
        quickPanelCenterDivider.Visible = false
        quickPanelMinimized = true
    else
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = TweenService:Create(quickPanelFrame, tweenInfo, {Size = quickPanelOriginalSize})
        tween:Play()
        quickPanelMinimize.Text = "–"
        quickPanelDivider.Visible = true
        quickPanelContent.Visible = true
        quickPanelCenterDivider.Visible = true
        quickPanelMinimized = false
    end
end)

-- Protect Quick Panel GUI
protectGui(quickPanelGui)

-- TEST: Show notification bila hub loaded
showNotification("Nightmare Hub loaded successfully!")
