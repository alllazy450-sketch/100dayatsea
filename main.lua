-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (TOOLPROCESSOR FIX)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local AutoDebrisEnabled = false

-- Fungsi Auto Farm menggunakan _G.ToolProcessor bawaan game
local function autoFarmDebris()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        -- Mencari tool Harpoon / Riptide yang sedang dipegang player
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("harpoon") or tool.Name:lower():find("riptide")) then
            local debrisField = Workspace:FindFirstChild("DebrisField")
            if debrisField then
                for _, item in ipairs(debrisField:GetChildren()) do
                    if not AutoDebrisEnabled then break end
                    
                    local targetPart = item:FindFirstChild("Plank") or (item:IsA("Model") and item.PrimaryPart) or item
                    if targetPart then
                        pcall(function()
                            -- Tembak / Fire harpoon ke arah item
                            if _G.ToolProcessor then
                                _G.ToolProcessor(tool.Name, "Fire", tool.Harpoon1.Position, targetPart.Position)
                                task.wait(0.4)
                                -- Tarik kembali (Retract)
                                _G.ToolProcessor(tool.Name, "Retract")
                            end
                        end)
                        task.wait(1)
                    end
                end
            end
        end
    end)
end

-- Rayfield UI Setup
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | 100 Days at Sea",
    LoadingTitle = "Memuat W424 Hub...",
    LoadingSubtitle = "by W424",
    Theme = "DarkBlue",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "W424Hub",
        FileName = "100DaysConfig"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)
local MiscTab = Window:CreateTab("Settings", 4483345998)

MainTab:CreateSection("Auto Loot & Debris")

MainTab:CreateToggle({
    Name = "Auto Harpoon Debris / Plank",
    CurrentValue = false,
    Flag = "AutoDebrisToggle",
    Callback = function(Value)
        AutoDebrisEnabled = Value
        Rayfield:Notify({
            Title = "Status",
            Content = AutoDebrisEnabled and "Auto Harpoon Diaktifkan" or "Auto Harpoon Dimatikan",
            Duration = 2,
        })
    end,
})

-- Loop Background Auto Farm
task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            autoFarmDebris()
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "Menggunakan _G.ToolProcessor asli game 100 Days at Sea."})
