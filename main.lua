-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (CLEAN DRAG)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoDebrisEnabled = false

-- Fungsi pencari RemoteFunction otomatis yang aman
local function getRemoteFunction()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteFunction") and obj.Name == "RemoteFunction" then
            return obj
        end
    end
    return nil
end

local function dragAndDropDebris(item)
    if not item then return end
    
    pcall(function()
        local RemoteFunc = getRemoteFunction()
        if not RemoteFunc then return end
        
        -- 1. Attempt Drag
        RemoteFunc:InvokeServer(441520, "AttemptDrag", item)
        task.wait(0.2)
        
        -- 2. Harpoon Grab
        RemoteFunc:InvokeServer(441434, "ToolReplicator", "~sHarpoon", "~sGrab", item, "~v0,0,0")
        task.wait(0.5)
        
        -- 3. Lepaskan (LetGo) agar tidak stuck di kepala
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dropPos = hrp.Position + (hrp.CFrame.LookVector * 4)
            local posString = string.format("~v%.4f,%.4f,%.4f", dropPos.X, dropPos.Y, dropPos.Z)
            RemoteFunc:InvokeServer(441434, "ToolReplicator", "~sHarpoon", "~sLetGo", item, posString, "~f0,0,0:0,0,0Z0", "~b1")
        end
    end)
end

-- Rayfield UI
local Window = Rayfield:CreateWindow({
    Name = "W424 Hub | Stable Drag",
    LoadingTitle = "Memuat...",
    Theme = "DarkBlue",
    KeySystem = false,
})

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
