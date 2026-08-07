-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (AUTO TP ITEM + LIMIT)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local AutoLootEnabled = false
local MaxItemsLimit = 5 -- Default limit item yang diambil

-- Fungsi Teleport Item ke Depan Player
local function teleportWoodItems()
    pcall(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = character.HumanoidRootPart
        
        local debrisField = Workspace:FindFirstChild("DebrisField")
        if debrisField then
            local collectedCount = 0
            
            for _, item in ipairs(debrisField:GetChildren()) do
                if not AutoLootEnabled then break end
                if collectedCount >= MaxItemsLimit then break end
                
                -- Mencari objek yang berupa Plank atau Wood/Crate
                if item:FindFirstChild("Plank") or item.Name:lower():find("plank") or item.Name:lower():find("wood") then
                    pcall(function()
                        local targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            -- Posisikan item tepat di depan player
                            local targetPos = hrp.Position + (hrp.CFrame.LookVector * 4) + Vector3.new(0, 1, 0)
                            
                            if item:IsA("Model") and item.PrimaryPart then
                                item:SetPrimaryPartCFrame(CFrame.new(targetPos))
                            elseif item:IsA("BasePart") then
                                item.CFrame = CFrame.new(targetPos)
                            end
                            
                            collectedCount = collectedCount + 1
                            task.wait(0.2)
                        end
                    end)
                end
            end
        end
    end)
end

-- Rayfield UI Setup
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | Custom Item Collector",
    LoadingTitle = "Memuat W424 Hub...",
    LoadingSubtitle = "by W424",
    Theme = "DarkBlue",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "W424Hub",
        FileName = "ItemConfig"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Auto Loot", 4483345998)
local MiscTab = Window:CreateTab("Settings", 4483345998)

MainTab:CreateSection("Custom Item Teleporter")

-- Slider untuk mengatur jumlah item yang mau diambil
MainTab:CreateSlider({
    Name = "Limit Jumlah Item (Wood/Plank)",
    Range = {1, 20},
    Increment = 1,
    Suffix = " Item",
    CurrentValue = 5,
    Flag = "ItemLimitSlider",
    Callback = function(Value)
        MaxItemsLimit = Value
    end,
})

-- Toggle untuk mengaktifkan fitur
MainTab:CreateToggle({
    Name = "Auto TP Wood ke Depan Kamu",
    CurrentValue = false,
    Flag = "AutoLootToggle",
    Callback = function(Value)
        AutoLootEnabled = Value
        Rayfield:Notify({
            Title = "Status Collector",
            Content = AutoLootEnabled and "Auto TP Item Aktif" | "Auto TP Item Dimatikan",
            Duration = 2,
        })
    end,
})

-- Loop Background Auto Collect
task.spawn(function()
    while true do
        if AutoLootEnabled then
            teleportWoodItems()
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "Fitur teleport item manual dengan batasan jumlah (limit) agar bisa diatur."})

Rayfield:LoadConfiguration()
