-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (STEALTH MODE)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoLootEnabled = false

local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | Stealth Collector",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Stealth Mode",
    Theme = "DarkBlue",
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)

MainTab:CreateToggle({
    Name = "Auto Collect Plank (Safe Mode)",
    CurrentValue = false,
    Callback = function(Value)
        AutoLootEnabled = Value
    end,
})

-- Loop yang lebih aman, tidak menyentuh folder DebrisField secara langsung
task.spawn(function()
    while true do
        if AutoLootEnabled then
            pcall(function()
                -- Mencari semua item yang memiliki atribut 'Plank' di seluruh Workspace
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name == "Plank" and obj:IsA("BasePart") then
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            -- Tarik item ke arah player secara visual halus
                            obj.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(0, 0, -5)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

Rayfield:LoadConfiguration()
