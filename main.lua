-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (OPTIMIZED)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 50,      -- radius untuk collect
    ESPEnabled = false,
}

-- ===== BUAT WINDOW =====
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days At Sea"
})

local Tabs = {
    Combat  = Window:AddTab("Combat"),
    Loot    = Window:AddTab("Looting"),
    Visuals = Window:AddTab("Visuals"),
}

-- ===== UTILITY =====
local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getChar()
    return LocalPlayer.Character
end

local function isCreature(model)
    return model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isItem(model)
    return model:IsA("Model") and model ~= LocalPlayer.Character and not isCreature(model)
end

-- ==========================================
-- 1. AUTO HARPOON (Raycast + Remote Event)
-- ==========================================
local harpoonRemote = nil  -- akan diisi otomatis

-- Fungsi untuk mencari remote event pada tool harpoon
local function findHarpoonRemote()
    local char = getChar()
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    -- Coba cari remote yang umum
    local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
    if remote then return remote end
    -- Jika tidak ada, coba cari dengan nama tertentu (bisa ditambah)
    local possibleNames = {"HarpoonEvent", "Attack", "Fire", "Use"}
    for _, name in ipairs(possibleNames) do
        local r = tool:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end
    return nil
end

-- Update remote secara periodik (jika tool berganti)
task.spawn(function()
    while task.wait(1) do
        harpoonRemote = findHarpoonRemote()
    end
end)

-- Loop Auto Harpoon dengan raycast (lebih efisien)
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            if not getgenv().W424_Sea.AutoHarpoon then return end
            local hrp = getHRP()
            if not hrp then return end
            local remote = harpoonRemote
            if not remote then return end

            local radius = getgenv().W424_Sea.HarpoonRadius or 150
            local origin = hrp.Position
            local targets = {}

            -- Scan cepat untuk model dengan Humanoid dalam radius
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - origin).Magnitude <= radius then
                            table.insert(targets, {model = obj, part = part})
                        end
                    end
                end
            end

            -- Pilih target terdekat
            if #targets > 0 then
                table.sort(targets, function(a, b)
                    return (a.part.Position - origin).Magnitude < (b.part.Position - origin).Magnitude
                end)
                local target = targets[1].model
                -- Kirim remote dengan target
                pcall(function()
                    remote:FireServer(target)
                end)
                -- Efek visual sederhana (opsional)
                -- CameraShake? tidak kita panggil karena mungkin tidak ada
            end
        end)
    end
end)

-- ==========================================
-- 2. AUTO COLLECT (Tween + ProxPrompt jika ada)
-- ==========================================
local collectCooldown = {}
local function canCollect(item)
    if collectCooldown[item] and tick() - collectCooldown[item] < 1 then
        return false
    end
    return true
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end
            local char = getChar()
            if not char then return end

            local radius = getgenv().W424_Sea.CollectRadius or 50
            local origin = hrp.Position
            local nearestItem = nil
            local nearestDist = radius

            -- Cari item terdekat (model tanpa Humanoid, bukan player)
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isItem(obj) then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and part:IsA("BasePart") then
                        local dist = (part.Position - origin).Magnitude
                        if dist < nearestDist and canCollect(obj) then
                            nearestItem = obj
                            nearestDist = dist
                        end
                    end
                end
            end

            if nearestItem then
                local part = nearestItem.PrimaryPart or nearestItem:FindFirstChildWhichIsA("BasePart")
                if part then
                    -- Coba cari ProxPrompt (jika ada sistem interaksi)
                    local prompt = nearestItem:FindFirstChildWhichIsA("ProximityPrompt")
                    if prompt then
                        -- Simulasikan interaksi
                        prompt:InputHoldBegin()
                        task.wait(0.1)
                        prompt:InputHoldEnd()
                    else
                        -- Gunakan Tween untuk mendekati item (halus)
                        local targetCF = part.CFrame * CFrame.new(0, 0, 2) -- di depan item
                        local tween = TweenService:Create(hrp, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = targetCF})
                        tween:Play()
                        tween.Completed:Wait()
                        -- Setelah dekat, mungkin item otomatis terkoleksi oleh game, atau kita bisa panggil remote jika ada
                        -- Jika tidak, kita bisa pindahkan item ke player (opsi terakhir)
                        -- Tapi lebih baik biarkan game yang mengoleksi
                        collectCooldown[nearestItem] = tick()
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. ESP (Dynamic + Filter)
-- ==========================================
local ESP_Data = {
    creatures = {enabled = false, highlights = {}},
    items = {enabled = false, highlights = {}}
}

local function createHighlight(adornee, color)
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
    hl.Adornee = adornee
    hl.Parent = CoreGui
    return hl
end

local function updateESP()
    -- Bersihkan semua highlight lama
    for _, data in pairs(ESP_Data) do
        for _, hl in ipairs(data.highlights) do
            pcall(function() hl:Destroy() end)
        end
        data.highlights = {}
    end

    if not ESP_Data.creatures.enabled and not ESP_Data.items.enabled then
        return
    end

    -- Scan semua model di workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hasHumanoid = isCreature(obj)
            if ESP_Data.creatures.enabled and hasHumanoid then
                local hl = createHighlight(obj, Color3.fromRGB(255,50,50))
                table.insert(ESP_Data.creatures.highlights, hl)
            elseif ESP_Data.items.enabled and not hasHumanoid then
                -- hanya item yang memiliki part fisik
                if obj:FindFirstChildWhichIsA("BasePart") then
                    local hl = createHighlight(obj, Color3.fromRGB(50,255,50))
                    table.insert(ESP_Data.items.highlights, hl)
                end
            end
        end
    end
end

-- Fungsi untuk toggle ESP dengan dynamic update
local function toggleESP(tag, state, color)
    ESP_Data[tag].enabled = state
    if state then
        updateESP()
        -- Tambahkan event listener untuk objek baru
        if not ESP_Data._connection then
            ESP_Data._connection = Workspace.DescendantAdded:Connect(function(obj)
                if ESP_Data.creatures.enabled or ESP_Data.items.enabled then
                    -- Update ulang secara periodik atau langsung tambahkan
                    updateESP() -- agak berat, tapi aman
                end
            end)
        end
    else
        -- Hapus highlight tag tersebut
        for _, hl in ipairs(ESP_Data[tag].highlights) do
            pcall(function() hl:Destroy() end)
        end
        ESP_Data[tag].highlights = {}
        -- Jika keduanya mati, matikan koneksi
        if not ESP_Data.creatures.enabled and not ESP_Data.items.enabled then
            if ESP_Data._connection then
                ESP_Data._connection:Disconnect()
                ESP_Data._connection = nil
            end
        end
    end
end

-- ==========================================
-- MENU / UI ELEMENTS (TETAP SAMA)
-- ==========================================

Tabs.Combat:AddToggle({
    Title = "Auto Harpoon / Kill Creature",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoHarpoon = state
    end
})

Tabs.Combat:AddInput({
    Title = "Harpoon Radius",
    Default = "150",
    Placeholder = "Masukkan angka radius...",
    Callback = function(value)
        local num = tonumber(value)
        if num then
            getgenv().W424_Sea.HarpoonRadius = num
        end
    end
})

Tabs.Loot:AddToggle({
    Title = "Auto Grab Floating Items / Wood",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoCollect = state
    end
})

-- Tambahan Input untuk radius collect (opsional)
Tabs.Loot:AddInput({
    Title = "Collect Radius",
    Default = "50",
    Placeholder = "Radius pengambilan item",
    Callback = function(value)
        local num = tonumber(value)
        if num then
            getgenv().W424_Sea.CollectRadius = num
        end
    end
})

Tabs.Visuals:AddToggle({
    Title = "Creatures / Sharks ESP",
    Default = false,
    Callback = function(state)
        toggleESP("creatures", state, Color3.fromRGB(255,50,50))
    end
})

Tabs.Visuals:AddToggle({
    Title = "Floating Items ESP",
    Default = false,
    Callback = function(state)
        toggleESP("items", state, Color3.fromRGB(50,255,50))
    end
})

OrvionLib:Notify("W424 Hub", "Optimized version loaded!", 4)