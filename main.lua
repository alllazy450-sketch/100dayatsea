-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (RAYFIELD EDITION)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
}

local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 100 Days At Sea",
   LoadingTitle = "Memuat Fitur Laut...",
   LoadingSubtitle = "by W424",
   Theme = "DarkBlue",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Combat & Harpoon", 4483362458)
local TabLoot = Window:CreateTab("Sea Farming", 4483362458)
local TabVisual = Window:CreateTab("Visuals (ESP)", 4483362458)

local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ==========================================
-- 1. AUTO HARPOON / ATTACK LOOP
-- ==========================================
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

-- ==========================================
-- 2. AUTO COLLECT FLOATING ITEMS
-- ==========================================
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
-- UI ELEMENTS (RAYFIELD - STABLE & NO ERROR)
-- ==========================================

TabMain:CreateSection("Harpoon Automation")
TabMain:CreateToggle({
   Name = "Auto Harpoon / Kill Creature",
   CurrentValue = getgenv().W424_Sea.AutoHarpoon,
   Flag = "HarpoonTog",
   Callback = function(Value) getgenv().W424_Sea.AutoHarpoon = Value end,
})

TabMain:CreateSlider({
   Name = "Harpoon Radius",
   Range = {20, 500},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424_Sea.HarpoonRadius,
   Flag = "HarpoonRad",
   Callback = function(Value) getgenv().W424_Sea.HarpoonRadius = Value end,
})

TabLoot:CreateSection("Looting & Collectibles")
TabLoot:CreateToggle({
   Name = "Auto Grab Floating Items / Wood",
   CurrentValue = getgenv().W424_Sea.AutoCollect,
   Flag = "CollectTog",
   Callback = function(Value) getgenv().W424_Sea.AutoCollect = Value end,
})

TabVisual:CreateSection("Information")
TabVisual:CreateLabel("Gunakan fitur ESP dari menu game/executor jika diperlukan.")

Rayfield:Notify({
   Title = "W424 Sea Edition Loaded!",
   Content = "Menggunakan Rayfield UI agar stabil dan tidak error.",
   Duration = 5,
   Image = 4483362458
})
