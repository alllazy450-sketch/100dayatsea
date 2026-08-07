-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (GLOBAL API FIX)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Mengakses GlobalAPI yang terekam di Remote Spy
local GlobalAPI = ReplicatedStorage:WaitForChild("GlobalAPI", 10)

local AutoDebrisEnabled = false

local function grabAndDropDebris(plankItem)
    if not plankItem or not GlobalAPI then return end
    
    pcall(function()
        -- 1. Berikan Ownership lewat GlobalAPI
        GlobalAPI:FireServer(452963, "GiveUpOwnership", plankItem, "~v0,0,0")
        task.wait(0.1)
        
        -- 2. Attempt Drag & Harpoon Grab
        GlobalAPI:InvokeServer(6244486, "AttemptDrag", plankItem)
        GlobalAPI:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sGrab", plankItem, "~v0,0,0")
        task.wait(0.3)
        
        -- 3. Lepaskan Item di depan player agar tidak nyangkut di kepala
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local dropPos = hrp.Position + (hrp.CFrame.LookVector * 6) - Vector3.new(0, 2, 0)
            local posString = string.format("~v%.4f,%.4f,%.4f", dropPos.X, dropPos.Y, dropPos.Z)
            
            GlobalAPI:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sLetGo", plankItem, posString, "~f0,0,0:0,0,0Z0", "~b1")
        end
        
        -- 4. Retract Harpoon
        task.wait(0.1)
        GlobalAPI:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sRetract")
    end)
end

-- Rayfield UI Setup
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | 100 Days at Sea",
    LoadingTitle = "Memuat W424 Hub...",
    LoadingSubtitle = "by W424",
    Theme = "DarkBlue",
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

-- Loop Auto Farm
task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debrisField = Workspace:FindFirstChild("DebrisField")
                if debrisField then
                    for _, item in ipairs(debrisField:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        if item:FindFirstChild("Plank") or item.Name == "Plank" then
                            grabAndDropDebris(item)
                            task.wait(1.2)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "Menggunakan GlobalAPI ReplicatedStorage sesuai data SimpleSpy."})

Rayfield:LoadConfiguration()
