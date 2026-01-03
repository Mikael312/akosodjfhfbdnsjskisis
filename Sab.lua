--[[
    NIGHTMARE UI - ESP PLAYERS ONLY
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
local player = Players.LocalPlayer

-- ==================== ESP PLAYERS VARIABLES ====================
local espPlayersEnabled = false
local espObjects = {}
local updateConnection = nil

-- ==================== ESP PLAYERS FUNCTIONS ====================
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
    
    print("✅ ESP Players Diaktifkan")
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
    
    print("❌ ESP Players Dimatikan")
end

-- ==================== TOGGLE FUNCTIONS FOR UI ====================
local function toggleEspPlayers(state)
    if state then
        enableESPPlayers()
    else
        disableESPPlayers()
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

-- ==================== CREATE UI AND ADD TOGGLES ====================
Nightmare:CreateUI()

-- Notifikasi apabila UI dimuatkan
Nightmare:Notify("ESP Players Only")

-- Tambah toggle untuk ESP Players
Nightmare:AddToggle("Esp Players", toggleEspPlayers)

print("🎮 ESP Players Only Loaded Successfully!")
