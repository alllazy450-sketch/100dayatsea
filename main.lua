-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (EXACT GAME LOGIC)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local AutoDebrisEnabled = false

-- Fungsi Auto Farm meniru persis HarpoonScript asli game
local function executeAutoHarpoon()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        -- Cek apakah player sedang memegang tool Harpoon atau Riptide
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name == "Harpoon" or tool.Name == "Riptide") then
            local debrisField = Workspace:FindFirstChild("DebrisField")
            if debrisField then
                for _, item in ipairs(debrisField:GetChildren()) do
                    if not AutoDebrisEnabled then break end
                    
                    local targetPart = item:FindFirstChild("Plank") or (item:IsA("Model") and item.PrimaryPart) or item
                    local harpoonPart = tool:FindFirstChild("Harpoon1")
                    
                    if targetPart and harpoonPart and _G.ToolProcessor then
                        pcall(function()
                            -- 1. Tembak peluru/kail harpoon ke arah item
                            _G.ToolProcessor(tool.Name, "Fire", harpoonPart.Position, targetPart.Position)
                            task.wait(0.3)
                            
                            -- 2. Tarik/Grab item secara instan lewat ToolProcessor game
                            _G.ToolProcessor(tool.Name, "Grab", item, Vector3.new(0,0,0))
                            task.wait(0.2)
                            
                            -- 3. Lepaskan (LetGo) dan Retract agar item jatuh bersih ke dek/air
                            local dropVel = character.PrimaryPart and character.PrimaryPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                            _G.ToolProcessor(tool.Name, "LetGo", item, dropVel, item:GetPivot(), true)
                            
                            task.wait(0.1)
                            _G.ToolProcessor(tool.Name, "Retract")
                        end)
                        task.wait(1.5)
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
            executeAutoHarpoon()
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "Menggunakan logika ToolProcessor asli dari source code game."})

Rayfield:LoadConfiguration()
