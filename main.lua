-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (FIXED)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 50,
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

local function isCreature(model)
    return model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isItem(model)
    return model:IsA("Model") and model ~= LocalPlayer.Character and not isCreature(model)
end

-- ==========================================
-- 1. AUTO HARPOON (Remote Event)
-- ==========================================
local harpoonRemote = nil

local function findHarpoonRemote()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
    if remote then return remote end
    -- Coba nama umum
    local possibleNames = {"HarpoonEvent", "Attack", "Fire", "Use"}
    for _, name in ipairs(possibleNames) do
        local r = tool:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(1) do
        harpoonRemote = findHarpoonRemote()
    end
end)

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

            if #targets > 0 then
                table.sort(targets, function(a, b)
                    return (a.part.Position - origin).Magnitude < (b.part.Position - origin).Magnitude
                end)
                local target = targets[1].model
                pcall(function()
                    remote:FireServer(target)
                end)
            end
        end)
    end
end)

-- ==========================================
-- 2. AUTO COLLECT (BRING ITEM LOOP)
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do  -- loop cepat untuk bring item
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end

            local radius = getgenv().W424_Sea.CollectRadius or 50
            local origin = hrp.Position
            local targetPos = hrp.CFrame * CFrame.new(0, 2, 0)  -- sedikit di atas player

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isItem(obj) then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and part:IsA("BasePart") then
                        local dist = (part.Position - origin).Magnitude
                        if dist <= radius then
                            -- Bring item ke player
                            part.CFrame = targetPos
                            part.Velocity = Vector3.zero
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. ESP (DUAL TOGGLE, INDEPENDENT)
-- ==========================================
local ESP = {
    creatures = { enabled = false, highlights = {} },
    items     = { enabled = false, highlights = {} },
    connection = nil,
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

-- Tambahkan highlight untuk satu kategori (tanpa menghapus yang lain)
local function addESP(tag, color)
    if not ESP[tag] then return end
    local enabled = ESP[tag].enabled
    if not enabled then return end

    -- Cari semua objek yang sesuai
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hasHumanoid = isCreature(obj)
            if tag == "creatures" and hasHumanoid then
                local hl = createHighlight(obj, color)
                table.insert(ESP[tag].highlights, hl)
            elseif tag == "items" and not hasHumanoid then
                if obj:FindFirstChildWhichIsA("BasePart") then
                    local hl = createHighlight(obj, color)
                    table.insert(ESP[tag].highlights, hl)
                end
            end
        end
    end
end

-- Hapus semua highlight untuk satu kategori
local function removeESP(tag)
    if not ESP[tag] then return end
    for _, hl in ipairs(ESP[tag].highlights) do
        pcall(function() hl:Destroy() end)
    end
    ESP[tag].highlights = {}
end

-- Event untuk objek baru yang muncul
local function setupESPConnection()
    if ESP.connection then return end
    ESP.connection = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hasHumanoid = isCreature(obj)
            if ESP.creatures.enabled and hasHumanoid then
                local hl = createHighlight(obj, Color3.fromRGB(255,50,50))
                table.insert(ESP.creatures.highlights, hl)
            elseif ESP.items.enabled and not hasHumanoid and obj:FindFirstChildWhichIsA("BasePart") then
                local hl = createHighlight(obj, Color3.fromRGB(50,255,50))
                table.insert(ESP.items.highlights, hl)
            end
        end
    end)
end

-- Fungsi toggle untuk UI
local function toggleESP(tag, state, color)
    if state then
        ESP[tag].enabled = true
        addESP(tag, color)
        setupESPConnection()
    else
        ESP[tag].enabled = false
        removeESP(tag)
        -- Jika keduanya mati, putuskan koneksi
        if not ESP.creatures.enabled and not ESP.items.enabled then
            if ESP.connection then
                ESP.connection:Disconnect()
                ESP.connection = nil
            end
        end
    end
end

-- ==========================================
-- MENU UI (TETAP SAMA)
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

OrvionLib:Notify("W424 Hub", "Fixed version loaded!", 4)