-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (CUSTOM SETTINGS)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoDebrisEnabled = false
local MaxItemLimit = 5  -- Default limit
local TargetItemName = "Plank" -- Default item

local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | Advanced Collector",
    LoadingTitle = "Memuat W424 Hub...",
    Theme = "DarkBlue",
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)

-- 1. Input untuk Limit Jumlah
MainTab:CreateInput({
    Name = "Limit Jumlah Item",
    PlaceholderText = "Contoh: 5",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then MaxItemLimit = num end
    end,
})

-- 2. Input untuk Nama Item
MainTab:CreateInput({
    Name = "Nama Item (Plank/Wood/Crate)",
    PlaceholderText = "Contoh: Plank",
    Callback = function(Value)
        TargetItemName = Value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Collect Custom",
    CurrentValue = false,
    Callback = function(Value)
        AutoDebrisEnabled = Value
    end,
})

task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            local collectedCount = 0
            local debrisField = Workspace:FindFirstChild("DebrisField")
            
            if debrisField then
                for _, item in ipairs(debrisField:GetChildren()) do
                    if not AutoDebrisEnabled then break end
                    if collectedCount >= MaxItemLimit then 
                        Rayfield:Notify({Title = "Limit Tercapai", Content = "Sudah mengambil " .. MaxItemLimit .. " item."})
                        AutoDebrisEnabled = false -- Berhenti otomatis setelah mencapai limit
                        break 
                    end
                    
                    -- Cek nama item sesuai input
                    if item.Name:lower():find(TargetItemName:lower()) then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            local targetCFrame = hrp.CFrame + (hrp.CFrame.LookVector * 4) + Vector3.new(0, 1, 0)
                            
                            -- Teleport & Unanchor
                            if item:IsA("Model") and item.PrimaryPart then
                                item.PrimaryPart.Anchored = false
                                item:SetPrimaryPartCFrame(targetCFrame)
                            elseif item:IsA("BasePart") then
                                item.Anchored = false
                                item.CFrame = targetCFrame
                            end
                            
                            collectedCount = collectedCount + 1
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)
