-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (FINAL FIX)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 50,
    CollectFilter = "wood",
    Debug = false,
}

-- ===== BUAT WINDOW UTAMA =====
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days At Sea"
})

-- Simpan referensi GUI utama
local mainGui = nil
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "OrvionLib" then
        mainGui = gui
        break
    end
end
if not mainGui then
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui:FindFirstChild("Main") then
            mainGui = gui
            break
        end
    end
end

-- ===== TOMBOL TOGGLE UI (BUBBLE) =====
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 60)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Text = "⚡"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 24
toggleButton.BackgroundTransparency = 0.2
toggleButton.BorderSizePixel = 0
toggleButton.Parent = CoreGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleButton

local uiVisible = true
toggleButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    if mainGui then
        mainGui.Enabled = uiVisible
    else
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:find("Orvion") then
                gui.Enabled = uiVisible
                mainGui = gui
                break
            end
        end
    end
end)

local dragging = false
local dragInput, dragStart, startPos
toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
toggleButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ===== TAB =====
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

local function isIsland(model)
    local name = model.Name:lower()
    if string.find(name, "island") or string.find(name, "spawn") or string.find(name, "terrain") then
        return true
    end
    if model:GetAttribute("Island") or model:GetAttribute("Terrain") then
        return true
    end
    local maxSize = 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local size = part.Size.Magnitude
            if size > maxSize then maxSize = size end
        end
    end
    if maxSize > 50 then
        return true
    end
    return false
end

-- Fungsi untuk mengecek apakah objek adalah bagian dari raft/floor/base
local function isRaftPart(model)
    if not model then return false end
    local name = model.Name:lower()
    if string.find(name, "raft") or string.find(name, "floor") or string.find(name, "base") or string.find(name, "platform") then
        return true
    end
    -- Cek parent hingga ke workspace
    local parent = model.Parent
    while parent do
        if parent:IsA("Model") then
            local pname = parent.Name:lower()
            if string.find(pname, "raft") or string.find(pname, "floor") or string.find(pname, "base") or string.find(pname, "platform") then
                return true
            end
            if parent:GetAttribute("Raft") or parent:GetAttribute("Base") then
                return true
            end
        end
        parent = parent.Parent
    end
    return false
end

-- Fungsi untuk mengecek apakah part berada di bawah permukaan air (bukan item terapung)
local function isUnderwater(part)
    -- Asumsi permukaan air Y=0, item yang valid biasanya di atas atau sedikit di bawah
    if part and part:IsA("BasePart") then
        return part.Position.Y < -5
    end
    return false
end

-- ==========================================
-- 1. AUTO HARPOON
-- ==========================================
local harpoonRemote = nil

local function findHarpoonRemote()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
    if remote then return remote end
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
-- 2. AUTO COLLECT (DENGAN FILTER KETAT)
-- ==========================================
local collectedParts = {}

task.spawn(function()
    while task.wait(0.15) do
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end
            local filter = getgenv().W424_Sea.CollectFilter or ""
            local radius = getgenv().W424_Sea.CollectRadius or 50
            local origin = hrp.Position
            local targetPos = hrp.CFrame * CFrame.new(0, 2, 0)

            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide and part ~= hrp and part.Parent ~= LocalPlayer.Character then
                    local parent = part.Parent
                    local isValid = false
                    local itemName = ""

                    -- Kriteria validasi:
                    -- 1. Parent adalah Model tanpa Humanoid dan bukan Island/Raft
                    if parent and parent:IsA("Model") and not isCreature(parent) and not isIsland(parent) and not isRaftPart(parent) then
                        isValid = true
                        itemName = parent.Name:lower()
                    -- 2. Part langsung memiliki atribut Item/Resource
                    elseif part:GetAttribute("Item") or part:GetAttribute("Resource") then
                        isValid = true
                        itemName = part.Name:lower()
                    -- 3. Parent adalah Model dan memiliki atribut Item
                    elseif parent and parent:IsA("Model") and parent:GetAttribute("Item") then
                        isValid = true
                        itemName = parent.Name:lower()
                    end

                    -- Tambahan: jangan ambil part yang berada di bawah air (bukan item terapung)
                    if isValid and isUnderwater(part) then
                        isValid = false
                    end

                    -- Tambahan: jangan ambil part yang terlalu besar (kemungkinan bagian struktur)
                    if isValid then
                        local size = part.Size.Magnitude
                        if size > 8 then -- item biasanya < 5 studs
                            isValid = false
                        end
                    end

                    local filterMatch = (filter == "" or string.find(itemName, filter:lower()))
                    if isValid and filterMatch then
                        local dist = (part.Position - origin).Magnitude
                        if dist <= radius then
                            if collectedParts[part] and tick() - collectedParts[part] < 1 then
                                -- cooldown
                            else
                                -- Coba pindahkan part ke player
                                local success = pcall(function()
                                    part.CFrame = targetPos
                                    part.Velocity = Vector3.zero
                                end)
                                if success then
                                    collectedParts[part] = tick()
                                    if getgenv().W424_Sea.Debug then
                                        print("Collected:", part.Name, "from", parent and parent.Name or "nil")
                                    end
                                else
                                    -- fallback: pindahkan player ke part (tapi hati-hati jangan ke bawah air)
                                    if not isUnderwater(part) then
                                        local tween = TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = part.CFrame * CFrame.new(0,0,2)})
                                        tween:Play()
                                        tween.Completed:Wait()
                                        collectedParts[part] = tick()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. ESP (DUAL TOGGLE + FILTER PULAU & RAFT)
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

local function addESP(tag, color)
    if not ESP[tag] then return end
    local enabled = ESP[tag].enabled
    if not enabled then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hasHumanoid = isCreature(obj)
            if tag == "creatures" and hasHumanoid then
                local hl = createHighlight(obj, color)
                table.insert(ESP[tag].highlights, hl)
            elseif tag == "items" and not hasHumanoid then
                if not isIsland(obj) and not isRaftPart(obj) and obj:FindFirstChildWhichIsA("BasePart") then
                    local hl = createHighlight(obj, color)
                    table.insert(ESP[tag].highlights, hl)
                end
            end
        end
    end
end

local function removeESP(tag)
    if not ESP[tag] then return end
    for _, hl in ipairs(ESP[tag].highlights) do
        pcall(function() hl:Destroy() end)
    end
    ESP[tag].highlights = {}
end

local function setupESPConnection()
    if ESP.connection then return end
    ESP.connection = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hasHumanoid = isCreature(obj)
            if ESP.creatures.enabled and hasHumanoid then
                local hl = createHighlight(obj, Color3.fromRGB(255,50,50))
                table.insert(ESP.creatures.highlights, hl)
            elseif ESP.items.enabled and not hasHumanoid and not isIsland(obj) and not isRaftPart(obj) and obj:FindFirstChildWhichIsA("BasePart") then
                local hl = createHighlight(obj, Color3.fromRGB(50,255,50))
                table.insert(ESP.items.highlights, hl)
            end
        end
    end)
end

local function toggleESP(tag, state, color)
    if state then
        ESP[tag].enabled = true
        addESP(tag, color)
        setupESPConnection()
    else
        ESP[tag].enabled = false
        removeESP(tag)
        if not ESP.creatures.enabled and not ESP.items.enabled then
            if ESP.connection then
                ESP.connection:Disconnect()
                ESP.connection = nil
            end
        end
    end
end

-- ==========================================
-- MENU UI
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

Tabs.Loot:AddInput({
    Title = "Item Filter (nama item)",
    Default = "wood",
    Placeholder = "Kata kunci (kosongkan untuk semua)",
    Callback = function(value)
        getgenv().W424_Sea.CollectFilter = value or ""
    end
})

Tabs.Loot:AddToggle({
    Title = "Debug Output (Konsol)",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.Debug = state
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

OrvionLib:Notify("W424 Hub", "Final Fix loaded!", 4)