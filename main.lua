-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (EXACT REMOTE SPY FIX)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoDropRemote = false,
    CollectRadius = 100,
}

-- ===== BUAT WINDOW UTAMA =====
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days At Sea"
})

-- ===== TOMBOL TOGGLE UI MELAYANG =====
local mainGui = nil
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and (gui.Name:find("Orvion") or gui:FindFirstChild("Main")) then
        mainGui = gui
        break
    end
end

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 60)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Text = "⚡"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 24
toggleButton.BackgroundTransparency = 0.2
toggleButton.BorderSizePixel = 0
toggleButton.Parent = CoreGui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

local uiVisible = true
toggleButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    if mainGui then mainGui.Enabled = uiVisible end
end)

-- ===== TAB MENU =====
local Tabs = {
    Combat  = Window:AddTab("Combat"),
    Loot    = Window:AddTab("Auto Drop Remote"),
}

local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

-- ==========================================
-- 1. AUTO HARPOON
-- ==========================================
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not getgenv().W424_Sea.AutoHarpoon then return end
            local hrp = getHRP()
            if not hrp then return end
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end
            
            local remote = tool:FindFirstChildOfClass("RemoteEvent")
            if not remote then return end

            local radius = getgenv().W424_Sea.HarpoonRadius or 150
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= char then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= radius then
                            remote:FireServer(obj)
                            task.wait(0.1)
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 2. AUTO GIVE UP OWNERSHIP (Berdasarkan Remote Spy Asli)
-- ==========================================
task.spawn(function()
    while task.wait(0.6) do
        pcall(function()
            if not getgenv().W424_Sea.AutoDropRemote then return end
            local hrp = getHRP()
            if not hrp then return end

            local radius = getgenv().W424_Sea.CollectRadius or 100
            local remoteEvent = LocalizationService:FindFirstChild("RemoteEvent")

            for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
                if not getgenv().W424_Sea.AutoDropRemote then break end
                
                local part = nil
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end

                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    -- Pastikan item ada di area laut
                    if dist <= radius and part.Position.Y < 148 then
                        
                        if remoteEvent then
                            -- Format argumen persis seperti hasil Spy manual kamu
                            local args = {
                                407115, -- ID referensi game
                                "GiveUpOwnership",
                                obj,    -- Objek item laut yang terdeteksi
                                "~v-0.0001,-0.0001,0" -- Koordinat default drop
                            }
                            
                            remoteEvent:FireServer(unpack(args))
                        end
                        
                        task.wait(0.4)
                        break
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- UI CONTROLS (ORVION LIB)
-- ==========================================

Tabs.Combat:AddToggle({
    Title = "Auto Harpoon / Kill Creature",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.AutoHarpoon = state end
})

Tabs.Combat:AddInput({
    Title = "Harpoon Radius",
    Default = "150",
    Placeholder = "Masukkan angka...",
    Callback = function(v) 
        local n = tonumber(v)
        if n then getgenv().W424_Sea.HarpoonRadius = n end
    end
})

Tabs.Loot:AddToggle({
    Title = "Auto Remote Drop Items",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.AutoDropRemote = state end
})

Tabs.Loot:AddInput({
    Title = "Detection Radius",
    Default = "100",
    Placeholder = "Jangkauan...",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Sea.CollectRadius = n end
    end
})

OrvionLib:Notify("W424 Hub", "Remote Spy Hook Applied!", 4)
