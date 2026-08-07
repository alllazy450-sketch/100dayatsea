-- ==========================================
-- W424 HUB | 100 DAYS AS SEA (INDEX SELECTOR FIX)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoDebrisEnabled = false
local MaxItemLimit = 5  
local SelectedIndex = 1

-- Daftar pilihan item berdasarkan Index
local ItemOptions = {
    [1] = "wood plank",
    [2] = "crate",
    [3] = "log"
}

local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | Index Selector",
    LoadingTitle = "Memuat W424 Hub...",
    Theme = "DarkBlue",
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)

-- Input untuk Limit Jumlah
MainTab:CreateInput({
    Name = "Limit Jumlah Item",
    PlaceholderText = "Contoh: 5",
    CurrentValue = "5",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then MaxItemLimit = num end
    end,
})

-- Dropdown / Pilihan Item menggunakan Index (1, 2, 3)
MainTab:CreateDropdown({
    Name = "Pilih Jenis Item (Index)",
    Options = {"1. wood plank", "2. crate", "3. log"},
    CurrentOption = "1. wood plank",
    Flag = "ItemIndexDropdown",
    Callback = function(Option)
        -- Mengambil angka index dari string pilihan (misal "1. wood plank" -> index 1)
        local index = tonumber(string.match(Option, "^(%d+)"))
        if index then
            SelectedIndex = index
        end
    end,
})

-- Toggle dengan perbaikan agar state on/off benar-benar akurat
MainTab:CreateToggle({
    Name = "Auto Collect Custom",
    CurrentValue = false,
    Flag = "AutoCollectToggle",
    Callback = function(Value)
        AutoDebrisEnabled = Value
        Rayfield:Notify({
            Title = "Status Auto Collect",
            Content = AutoDebrisEnabled and "Fitur Benar-Benar AKTIF" or "Fitur DIMATIKAN",
            Duration = 2,
        })
    end,
})

task.spawn(function()
    while true do
        -- Memastikan loop hanya berjalan jika toggle bernilai true
        if AutoDebrisEnabled == true then
            local collectedCount = 0
            local debrisField = Workspace:FindFirstChild("DebrisField")
            local targetName = ItemOptions[SelectedIndex] or "wood plank"
            
            if debrisField then
                for _, item in ipairs(debrisField:GetChildren()) do
                    -- Double check status toggle di dalam loop
                    if AutoDebrisEnabled == false then break end
                    
                    if collectedCount >= MaxItemLimit then 
                        Rayfield:Notify({Title = "Limit Tercapai", Content = "Sudah mengambil " .. MaxItemLimit .. " item."})
                        AutoDebrisEnabled = false
                        break 
                    end
                    
                    if item.Name:lower():find(targetName:lower()) then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            local targetCFrame = hrp.CFrame + (hrp.CFrame.LookVector * 4) + Vector3.new(0, 1, 0)
                            
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
