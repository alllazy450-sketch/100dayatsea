-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (FIX FINAL)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ChatService = game:GetService("Chat")

local LocalPlayer = Players.LocalPlayer
local RemoteFunc = ChatService:FindFirstChild("RemoteFunction")
local RemoteEv = ChatService:FindFirstChild("RemoteEvent")

-- Cek apakah remote ditemukan
if not RemoteFunc or not RemoteEv then
    Rayfield:Notify({
        Title = "ERROR",
        Content = "Remote tidak ditemukan! Script tidak akan berfungsi.",
        Duration = 5,
    })
    return
end

local AutoDebrisEnabled = false

-- Fungsi grab & drop dengan posisi aman
local function grabAndDropDebris(plankItem)
    if not plankItem then return end
    
    pcall(function()
        -- 1. Give up ownership (agar bisa diambil)
        RemoteEv:FireServer(452963, "GiveUpOwnership", plankItem, "~v0,0,0")
        task.wait(0.1)
        
        -- 2. Tarik item (AttemptDrag)
        RemoteFunc:InvokeServer(6244486, "AttemptDrag", plankItem)
        task.wait(0.1)
        
        -- 3. Harpoon Grab
        RemoteFunc:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sGrab", plankItem, "~v0,0,0")
        task.wait(0.3)
        
        -- 4. LetGo dengan posisi di depan player (turun ke tanah)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            -- Turunkan 3 stud agar pasti di tanah (karena HRP Y sekitar 2-3)
            local dropPos = hrp.Position + (hrp.CFrame.LookVector * 6) - Vector3.new(0, 3, 0)
            local posString = string.format("~v%.4f,%.4f,%.4f", dropPos.X, dropPos.Y, dropPos.Z)
            
            RemoteFunc:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sLetGo", plankItem, posString, "~f0,0,0:0,0,0Z0", "~b1")
        end
        
        -- 5. Retract harpoon
        task.wait(0.1)
        RemoteFunc:InvokeServer(6244486, "ToolReplicator", "~sHarpoon", "~sRetract")
    end)
end

-- Setup UI Rayfield
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | 100 Days at Sea",
    LoadingTitle = "Memuat W424 Hub...",
    LoadingSubtitle = "by W424",
    Theme = "DarkBlue",
    ConfigurationSaving = {
        Enabled = false, -- Nonaktif agar tidak auto-on
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

-- Loop utama auto farm
task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debrisField = Workspace:FindFirstChild("DebrisField")
                if debrisField then
                    for _, item in ipairs(debrisField:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        -- Cek apakah item adalah plank (bisa nama "Plank" atau ada child "Plank")
                        if item:FindFirstChild("Plank") or item.Name == "Plank" then
                            grabAndDropDebris(item)
                            task.wait(1.2) -- jeda agar tidak overheat
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

MiscTab:CreateSection("Information")
MiscTab:CreateParagraph({Title = "W424 Hub", Content = "Auto harpoon dengan posisi drop fix di tanah."})

Rayfield:LoadConfiguration()