-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (IMPROVED DRAG)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LogService = game:GetService("LogService")
local RemoteFunc = LogService:WaitForChild("RemoteFunction")

local AutoDebrisEnabled = false

-- Fungsi Drag yang sudah di-improve (ditambah LetGo)
local function dragAndDropDebris(item)
    if not item then return end
    
    pcall(function()
        -- 1. Mulai Dragging (Ini metode yang kamu bilang work)
        RemoteFunc:InvokeServer(441520, "AttemptDrag", item)
        task.wait(0.2)
        
        -- 2. Grab (Sesuai metode work kamu)
        RemoteFunc:InvokeServer(441434, "ToolReplicator", "~sHarpoon", "~sGrab", item, "~v0,0,0")
        task.wait(0.5)
        
        -- 3. IMPROVEMENT: Paksa Lepas (LetGo) supaya tidak stuck di kepala
        -- Kita kirim posisi drop tepat di bawah/depan kaki player
        local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dropPos = hrp.Position + (hrp.CFrame.LookVector * 4)
            local posString = string.format("~v%.4f,%.4f,%.4f", dropPos.X, dropPos.Y, dropPos.Z)
            
            -- Remote untuk melepaskan item
            RemoteFunc:InvokeServer(441434, "ToolReplicator", "~sHarpoon", "~sLetGo", item, posString, "~f0,0,0:0,0,0Z0", "~b1")
        end
    end)
end

-- Rayfield UI (Tetap sama)
local Window = Rayfield:CreateWindow({Name = "W424 Hub | Stable Drag", LoadingTitle = "Memuat...", Theme = "DarkBlue", KeySystem = false})
local MainTab = Window:CreateTab("Main Farm", 4483345998)

MainTab:CreateToggle({
    Name = "Auto Drag & Drop Debris",
    CurrentValue = false,
    Callback = function(Value)
        AutoDebrisEnabled = Value
    end,
})

task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debris = Workspace:FindFirstChild("DebrisField")
                if debris then
                    for _, item in ipairs(debris:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        if item.Name == "Plank" then
                            dragAndDropDebris(item)
                            task.wait(1)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)
