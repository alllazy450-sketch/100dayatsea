-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (ULTIMATE EDITION)
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Global Configurations
getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    AutoCook = false,
    ESPItems = false,
    ESPCreatures = false,
}

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = Fluent:CreateWindow({
    Title = "W424 Hub",
    SubTitle = "100 Days At Sea - Ultimate",
    Theme = "Dark",
    Acrylic = false,
    Resize = true,
    Size = UDim2.fromOffset(700, 500),
    TabWidth = 160,
    MinimizeKey = Enum.KeyCode.RightControl,
})

-- Tabs Setup
local Tabs = {
    Main = Window:CreateTab({ Title = "Main / Combat", Icon = "phosphor-sword-bold" }),
    Loot = Window:CreateTab({ Title = "Looting", Icon = "phosphor-package-bold" }),
    Visuals = Window:CreateTab({ Title = "Visuals (ESP)", Icon = "phosphor-eye-bold" }),
}

-- Helper: Get Character RootPart
local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ==========================================
-- 1. AUTO HARPOON / COMBAT LOOP (Creatures)
-- ==========================================
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            if getgenv().W424_Sea.AutoHarpoon then
                local hrp = getHRP()
                if not hrp then return end

                -- Mencari folder Creatures / Enemies / Sharks di Workspace
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name:find("Shark") or obj.Name:find("Creature") or obj.Name:find("Fish")) then
                        local humanoid = obj:FindFirstChildOfClass("Humanoid")
                        local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        
                        if humanoid and humanoid.Health > 0 and part then
                            if (hrp.Position - part.Position).Magnitude <= getgenv().W424_Sea.HarpoonRadius then
                                -- Simulasi klik / serangan harpoon atau remote damage
                                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                if tool then
                                    tool:Activate()
                                    pcall(function()
                                        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Attack")
                                        if remote then remote:FireServer(obj) end
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

-- ==========================================
-- 2. AUTO COLLECT FLOATING ITEMS (Puing/Kayu Laut)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if getgenv().W424_Sea.AutoCollect then
                local hrp = getHRP()
                if not hrp then return end

                local itemsFolder = Workspace:FindFirstChild("Items") or Workspace:FindFirstChild("Collectibles") or Workspace
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item ~= LocalPlayer.Character then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part then
                            -- Tarik item mengapung ke dekat player/rakit
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
-- 3. ESP SYSTEM
-- ==========================================
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

-- ==========================================
-- UI CONTROLS (FLUENT)
-- ==========================================

-- MAIN TAB
Tabs.Main:CreateSection("Combat & Harpoon")
Tabs.Main:CreateToggle("AutoHarpoonTog", {
    Title = "Auto Harpoon / Kill Creature",
    Default = false,
    Callback = function(v) getgenv().W424_Sea.AutoHarpoon = v end,
})
Tabs.Main:CreateSlider("HarpoonRad", {
    Title = "Harpoon Radius",
    Min = 20, Max = 500, Default = 150,
    Callback = function(v) getgenv().W424_Sea.HarpoonRadius = v end,
})

-- LOOT TAB
Tabs.Loot:CreateSection("Sea Farming")
Tabs.Loot:CreateToggle("AutoCollectTog", {
    Title = "Auto Grab Floating Items / Wood",
    Default = false,
    Callback = function(v) getgenv().W424_Sea.AutoCollect = v end,
})

-- VISUALS TAB
Tabs.Visuals:CreateSection("ESP Options")
Tabs.Visuals:CreateToggle("CreatureESP", {
    Title = "Creatures / Sharks ESP",
    Default = false,
    Callback = function(v) toggleESP(v, "Workspace", "creatures", Color3.fromRGB(255, 50, 50)) end,
})
Tabs.Visuals:CreateToggle("ItemESP", {
    Title = "Floating Items ESP",
    Default = false,
    Callback = function(v) toggleESP(v, "Workspace", "items", Color3.fromRGB(50, 255, 50)) end,
})

-- Notification Ready
Window:SelectTab(1)
Fluent:Notify({
    Title = "W424 Sea Edition Loaded!",
    Content = "Skrip 100 Days At Sea siap digunakan.",
    Duration = 5,
})
