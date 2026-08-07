-- ==========================================
-- W424 HUB | 100 DAYS AT SEA
-- RAYFIELD UI + FLOATING BUBBLE TOGGLE
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LogService = game:GetService("LogService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local RemoteFunc = LogService:WaitForChild("RemoteFunction")

-- State Variables
local AutoDebrisEnabled = false

-- ==========================================
-- CORE METHODS (100 DAYS AT SEA)
-- ==========================================
local function grabDebris(plankObject)
    if not plankObject then return end
    
    -- 1. Attempt Drag
    pcall(function()
        RemoteFunc:InvokeServer(441520, "AttemptDrag", plankObject)
    end)
    
    -- 2. Harpoon Grab Execution
    pcall(function()
        RemoteFunc:InvokeServer(441434, "ToolReplicator", "~sHarpoon", "~sGrab", plankObject, "~v0,0,0")
    end)
end

-- ==========================================
-- RAYFIELD WINDOW SETUP
-- ==========================================
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

-- ==========================================
-- TABS
-- ==========================================
local MainTab = Window:CreateTab("Main Farm", 4483345998)
local MiscTab = Window:CreateTab("Settings", 4483345998)

-- ==========================================
-- MAIN TAB CONTENT
-- ==========================================
MainTab:CreateSection("Auto Loot & Debris")

MainTab:CreateToggle({
    Name = "Auto Grab Floating Debris / Plank",
    CurrentValue = false,
    Flag = "AutoDebrisToggle",
    Callback = function(Value)
        AutoDebrisEnabled = Value
        
        if AutoDebrisEnabled then
            Rayfield:Notify({
                Title = "Auto Debris Active",
                Content = "Mulai menarik sampah/kayu di sekitar laut secara otomatis!",
                Duration = 3,
                Image = 4483345998,
            })
        end
    end,
})

-- Loop Auto Debris
task.spawn(function()
    while true do
        if AutoDebrisEnabled then
            pcall(function()
                local debrisField = Workspace:FindFirstChild("DebrisField")
                if debrisField then
                    for _, item in ipairs(debrisField:GetChildren()) do
                        if not AutoDebrisEnabled then break end
                        if item:FindFirstChild("Plank") or item.Name == "Plank" then
                            grabDebris(item)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- MISC TAB CONTENT
-- ==========================================
MiscTab:CreateSection("Information")

MiscTab:CreateParagraph({
    Title = "W424 Hub Info", 
    Content = "Script khusus game 100 Days at Sea menggunakan metode RemoteFunction LogService & Harpoon Replicator."
})

MiscTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/FcF8ghneh4")
            Rayfield:Notify({
                Title = "Success",
                Content = "Link Discord berhasil disalin ke clipboard!",
                Duration = 3,
                Image = 4483345998,
            })
        end
    end,
})

-- ==========================================
-- FLOATING BUBBLE TOGGLE BUTTON (MOBILE FRIENDLY)
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("W424FloatingBubble") then
        CoreGui.W424FloatingBubble:Destroy()
    end
end)

local BubbleGui = Instance.new("ScreenGui")
BubbleGui.Name = "W424FloatingBubble"
BubbleGui.Parent = CoreGui
BubbleGui.ResetOnSpawn = false

local BubbleBtn = Instance.new("TextButton")
BubbleBtn.Size = UDim2.new(0, 50, 0, 50)
BubbleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
BubbleBtn.BackgroundColor3 = Color3.fromRGB(20, 35, 60)
BubbleBtn.Text = "W"
BubbleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BubbleBtn.TextSize = 22
BubbleBtn.Font = Enum.Font.GothamBold
BubbleBtn.Draggable = true
BubbleBtn.Parent = BubbleGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0) -- Membuat tombolnya jadi bulat sempurna (bubble)
UICorner.Parent = BubbleBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 150, 255)
UIStroke.Thickness = 2
UIStroke.Parent = BubbleBtn

-- Logika Buka/Tutup UI saat Bubble ditekan
local UIHidden = false
BubbleBtn.MouseButton1Click:Connect(function()
    UIHidden = not UIHidden
    -- Rayfield menggunakan CoreGui atau nama parent tersendiri, kita toggle transparansi/visibility dari window utamanya
    pcall(function()
        local mainUI = CoreGui:FindFirstChild("Rayfield") or CoreGui:FindFirstChild("RayfieldWindow")
        if mainUI then
            mainUI.Enabled = not UIHidden
        else
            -- Alternatif pencarian frame Rayfield
            for _, child in ipairs(CoreGui:GetChildren()) do
                if child:IsA("ScreenGui") and child:FindFirstChild("Main") then
                    child.Enabled = not UIHidden
                end
            end
        end
    end)
    
    -- Efek visual kecil saat ditekan
    BubbleBtn.BackgroundColor3 = UIHidden and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(20, 35, 60)
end)

-- Inisialisasi Rayfield
Rayfield:LoadConfiguration()
