-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (FLURIORE UI)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))() -- Tetap pakai Rayfield sebagai cadangan stabil
local Fluriore = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mc4121ban/Fluriore-UI/main/Library.lua"))()

-- Jika Fluriore ternyata tidak compatible, sistem akan otomatis jatuh ke Rayfield (Safety net)
local UI = Fluriore or Rayfield

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

getgenv().W424 = {
    AutoHarpoon = false,
    HarpoonRad = 150,
    AutoCollect = false,
    ESP = false
}

local Window = UI:CreateWindow("W424 Hub | 100 Days At Sea", "by W424")

local TabMain = Window:CreateTab("Combat & Farming")
local TabVisual = Window:CreateTab("Visuals")

-- ==========================================
-- LOGIC HARPOON & COLLECT (FIXED)
-- ==========================================
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- 1. Auto Harpoon
            if getgenv().W424.AutoHarpoon then
                for _, mob in ipairs(Workspace:GetDescendants()) do
                    if mob:IsA("Model") and (mob.Name:find("Shark") or mob.Name:find("Creature")) then
                        local part = mob:FindFirstChildWhichIsA("BasePart")
                        if part and (hrp.Position - part.Position).Magnitude <= getgenv().W424.HarpoonRad then
                            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool then
                                tool:Activate()
                                -- Remote trigger
                                local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Attack")
                                if remote then remote:FireServer(mob) end
                            end
                        end
                    end
                end
            end

            -- 2. Auto Collect
            if getgenv().W424.AutoCollect then
                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Model") and (item.Name:find("Log") or item.Name:find("Barrel") or item.Name:find("Item")) then
                        local part = item:FindFirstChildWhichIsA("BasePart")
                        if part then
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
-- UI ELEMENTS
-- ==========================================
TabMain:CreateToggle("Auto Harpoon", function(state)
    getgenv().W424.AutoHarpoon = state
end)

TabMain:CreateSlider("Harpoon Radius", 20, 500, function(val)
    getgenv().W424.HarpoonRad = val
end)

TabMain:CreateToggle("Auto Collect Items", function(state)
    getgenv().W424.AutoCollect = state
end)

TabVisual:CreateLabel("ESP akan aktif otomatis jika mode Farming dinyalakan.")

print("W424 Fluriore Edition Loaded!")
