-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (ORVION LIB EDITION)
-- ==========================================

-- LOAD LIBRARY
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    ESPItems = false,
    ESPCreatures = false,
}

-- BUAT WINDOW
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days At Sea"
})

-- TAMBAH TAB
local Tabs = {
    Combat  = Window:AddTab("Combat"),
    Loot    = Window:AddTab("Looting"),
    Visuals = Window:AddTab("Visuals"),
}

-- ==========================================
-- LOGIC UTAMA (TIDAK DIUBAH)
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- 1. Auto Harpoon / Attack Loop
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            if getgenv().W424_Sea.AutoHarpoon then
                local hrp = getHRP()
                if not hrp then return end

                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name:find("Shark") or obj.Name:find("Creature") or obj.Name:find("Fish") or obj.Name:find("Monster")) then
                        local humanoid = obj:FindFirstChildOfClass("Humanoid")
                        local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        
                        if humanoid and humanoid.Health > 0 and part then
                            if (hrp.Position - part.Position).Magnitude <= getgenv().W424_Sea.HarpoonRadius then
                                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                if tool then
                                    tool:Activate()
                                    pcall(function()
                                        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Attack") or tool:FindFirstChild("Handle")
                                        if remote and remote:IsA("RemoteEvent") then 
                                            remote:FireServer(obj) 
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- 2. Auto Collect Floating Items
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if getgenv().W424_Sea.AutoCollect then
                local hrp = getHRP()
                if not hrp then return end

                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Model") and item ~= LocalPlayer.Character then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part and (item.Name:find("Wood") or item.Name:find("Log") or item.Name:find("Barrel") or item.Name:find("Box") or item.Name:find("Item")) then
                            part.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                            part.Velocity = Vector3.zero
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- MENU / UI ELEMENTS (ORVION LIB)
-- ==========================================

-- TAB COMBAT
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

-- TAB LOOT
Tabs.Loot:AddToggle({
    Title = "Auto Grab Floating Items / Wood",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoCollect = state
    end
})

-- TAB VISUALS
local ESP_Holder = {}
local function toggleESP(state, folderName, tag, color)
    if not ESP_Holder[tag] then ESP_Holder[tag] = {} end
    if state then
        local folder = Workspace:FindFirstChild(folderName) or Workspace
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                pcall(function()
                    local hl = Instance.new("Highlight")
                    hl.FillColor = color
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.FillTransparency = 0.5
                    hl.Adornee = obj
                    hl.Parent = CoreGui
                    table.insert(ESP_Holder[tag], hl)
                end)
            end
        end
    else
        for _, hl in ipairs(ESP_Holder[tag]) do
            pcall(function() hl:Destroy() end)
        end
        ESP_Holder[tag] = {}
    end
end

Tabs.Visuals:AddToggle({
    Title = "Creatures / Sharks ESP",
    Default = false,
    Callback = function(state)
        toggleESP(state, "Workspace", "creatures", Color3.fromRGB(255, 50, 50))
    end
})

Tabs.Visuals:AddToggle({
    Title = "Floating Items ESP",
    Default = false,
    Callback = function(state)
        toggleESP(state, "Workspace", "items", Color3.fromRGB(50, 255, 50))
    end
})

-- NOTIFIKASI BERHASIL LOAD
OrvionLib:Notify("W424 Hub", "Berhasil dimuat menggunakan OrvionLib!", 4)
