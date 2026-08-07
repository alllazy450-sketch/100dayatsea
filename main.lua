-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (AUTO DETECT)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatService = game:GetService("Chat")

local LocalPlayer = Players.LocalPlayer
local AutoDebrisEnabled = false

-- Fungsi untuk mencari remote dengan berbagai kemungkinan
local function findRemote(className, possibleNames)
    for _, name in ipairs(possibleNames) do
        local obj = ChatService:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
        if obj and obj:IsA(className) then
            return obj
        end
    end
    -- Jika tidak ditemukan, cari di seluruh game
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA(className) then
            for _, name in ipairs(possibleNames) do
                if obj.Name:lower():find(name:lower()) then
                    return obj
                end
            end
        end
    end
    return nil
end

local RemoteEvent = findRemote("RemoteEvent", {"RemoteEvent", "GiveUpOwnership", "Event"})
local RemoteFunction = findRemote("RemoteFunction", {"RemoteFunction", "Function"})

if not RemoteEvent or not RemoteFunction then
    Rayfield:Notify({
        Title = "ERROR",
        Content = "Remote tidak ditemukan! Coba cari manual.",
        Duration = 5,
    })
    return
end

-- Fungsi grab & drop (dengan argumen umum)
local function grabAndDropDebris(plankItem)
    if not plankItem then return end
    
    pcall(function()
        -- Coba berbagai kemungkinan argumen
        local success, err = pcall(function()
            RemoteEvent:FireServer("GiveUpOwnership", plankItem, "~v0,0,0")
        end)
        if not success then
            -- Alternatif
            RemoteEvent:FireServer(plankItem, "GiveUpOwnership")
        end
        task.wait(0.1)
        
        -- Coba AttemptDrag
        pcall(function()
            RemoteFunction:InvokeServer("AttemptDrag", plankItem)
        end)
        task.wait(0.1)
        
        -- Harpoon Grab
        pcall(function()
            RemoteFunction:InvokeServer("ToolReplicator", "~sHarpoon", "~sGrab", plankItem, "~v0,0,0")
        end)
        task.wait(0.3)
        
        -- Drop dengan posisi di depan
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local dropPos = hrp.Position + (hrp.CFrame.LookVector * 6) - Vector3.new(0, 3, 0)
            local posString = string.format("~v%.4f,%.4f,%.4f", dropPos.X, dropPos.Y, dropPos.Z)
            
            pcall(function()
                RemoteFunction:InvokeServer("ToolReplicator", "~sHarpoon", "~sLetGo", plankItem, posString, "~f0,0,0:0,0,0Z0", "~b1")
            end)
        end
        
        task.wait(0.1)
        pcall(function()
            RemoteFunction:InvokeServer("ToolReplicator", "~sHarpoon", "~sRetract")
        end)
    end)
end

-- UI Rayfield (sama seperti sebelumnya)
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | 100 Days at Sea",
    LoadingTitle = "Memuat...",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)
local MiscTab = Window:CreateTab("Settings", 4483345998)

MainTab:CreateToggle({
    Name = "Auto Harpoon Debris / Plank",
    CurrentValue = false,
    Flag = "AutoDebrisToggle",
    Callback = function(Value)
        AutoDebrisEnabled = Value
        Rayfield:Notify({
            Title = "Status",
            Content = AutoDebrisEnabled and "Auto Harpoon Diaktifkan" or "Dimatikan",
            Duration = 2,
        })
    end,
})

task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debrisField = Workspace:FindFirstChild("DebrisField")
                if debrisField then
                    for _, item in ipairs(debrisField:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        -- Deteksi item debris (bisa berupa model atau part)
                        if item:IsA("Model") and (item.Name:lower():find("plank") or item:FindFirstChild("Plank")) then
                            grabAndDropDebris(item)
                            task.wait(1.5)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

MiscTab:CreateParagraph({Title = "Info", Content = "Jika masih error, buka konsol (F9) dan kirim pesan error."})
Rayfield:LoadConfiguration()