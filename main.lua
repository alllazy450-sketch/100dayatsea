-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (FIXED)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local AutoDebrisEnabled = false

-- Rayfield Window Setup
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | 100 Days at Sea",
    LoadingTitle = "Memuat W424 Hub...",
    LoadingSubtitle = "by W424",
    Theme = "Dark",
    
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "W424Hub",
        FileName = "100DaysConfig"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)
local MiscTab = Window:CreateTab("Settings", 4483345998)

MainTab:CreateSection("Auto Loot & Debris")

MainTab:CreateToggle({
    Name = "Auto Grab Floating Debris / Plank",
    CurrentValue = false,
    Flag = "AutoDebrisToggle",
    Callback = function(Value)
        AutoDebrisEnabled = Value
        Rayfield:Notify({
            Title = "Status",
            Content = AutoDebrisEnabled ? "Auto Debris Diaktifkan" : "Auto Debris Dimatikan",
            Duration = 2,
        })
    end,
})

-- Loop Aman Tanpa Error RemoteFunction
task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debrisField = Workspace:FindFirstChild("DebrisField")
                if debrisField then
                    for _, item in ipairs(debrisField:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        if item:FindFirstChild("Plank") or item.Name == "Plank" then
                            -- Teleport item langsung ke player sebagai alternatif aman
                            if item:IsA("Model") and item.PrimaryPart then
                                item:SetPrimaryPartCFrame(LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
                            elseif item:IsA("BasePart") then
                                item.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                            end
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "UI diperbaiki agar tidak infinite yield."})

Rayfield:LoadConfiguration()
