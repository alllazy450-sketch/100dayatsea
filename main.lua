-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (ULTIMATE FIX)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 40,
    WalkSpeed = 16,
    Noclip = false,
}

-- ===== BUAT WINDOW UTAMA =====
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days At Sea"
})

-- ===== TOMBOL TOGGLE UI MELAYANG (MOBILE FRIENDLY) =====
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

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleButton

local uiVisible = true
toggleButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    if mainGui then
        mainGui.Enabled = uiVisible
    end
end)

-- Geser-geser tombol melayang
local dragging, dragStart, startPos = false, nil, nil
toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, toggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
toggleButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ===== TAB MENU =====
local Tabs = {
    Combat    = Window:AddTab("Combat"),
    Loot      = Window:AddTab("Looting"),
    Movement  = Window:AddTab("Movement"),
    Visuals   = Window:AddTab("Visuals"),
}

local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function getHum()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
    return nil
end

-- ==========================================
-- 1. AUTO HARPOON (Combat)
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
-- 2. AUTO COLLECT (Teleport Player ke Plank/Item)
-- ==========================================
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end

            local radius = getgenv().W424_Sea.CollectRadius or 40
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not getgenv().W424_Sea.AutoCollect then break end
                if obj:IsA("Model") and obj ~= LocalPlayer.Character and not obj:FindFirstChildOfClass("Humanoid") then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local name = obj.Name:lower()
                        -- Target item mengapung/kayu/plank
                        if name:find("plank") or name:find("wood") or name:find("log") or name:find("barrel") or name:find("box") then
                            local dist = (part.Position - hrp.Position).Magnitude
                            if dist <= radius and part.Position.Y > -5 then
                                -- Teleport karakter sebentar ke item lalu kembali/ambil
                                local oldPos = hrp.CFrame
                                hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. MOVEMENT (Noclip & WalkSpeed)
-- ==========================================
RunService.Stepped:Connect(function()
    if getgenv().W424_Sea.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ==========================================
-- UI CONTROLS (ORVION LIB)
-- ==========================================

-- Combat Tab
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

-- Looting Tab
Tabs.Loot:AddToggle({
    Title = "Auto Grab Plank / Wood (Teleport)",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.AutoCollect = state end
})
Tabs.Loot:AddInput({
    Title = "Collect Radius",
    Default = "40",
    Placeholder = "Jangkauan ambil...",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Sea.CollectRadius = n end
    end
})

-- Movement Tab
Tabs.Movement:AddToggle({
    Title = "Noclip (Tembus Tembok/Rakit)",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.Noclip = state end
})
Tabs.Movement:AddInput({
    Title = "WalkSpeed",
    Default = "16",
    Placeholder = "Kecepatan...",
    Callback = function(v)
        local n = tonumber(v)
        local hum = getHum()
        if n and hum then hum.WalkSpeed = n end
    end
})

-- Visuals Tab (ESP Sederhana)
local espEnabled = false
local espHighlights = {}
Tabs.Visuals:AddToggle({
    Title = "Plank / Wood ESP",
    Default = false,
    Callback = function(state)
        espEnabled = state
        if not state then
            for _, hl in ipairs(espHighlights) do pcall(function() hl:Destroy() end) end
            espHighlights = {}
        else
            task.spawn(function()
                while espEnabled do
                    task.wait(1)
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj ~= LocalPlayer.Character and not obj:FindFirstChildOfClass("Humanoid") then
                            local name = obj.Name:lower()
                            if name:find("plank") or name:find("wood") or name:find("log") then
                                local already = false
                                for _, h in ipairs(espHighlights) do if h.Adornee == obj then already = true end end
                                if not already then
                                    local hl = Instance.new("Highlight")
                                    hl.FillColor = Color3.fromRGB(50, 255, 50)
                                    hl.Adornee = obj
                                    hl.Parent = CoreGui
                                    table.insert(espHighlights, hl)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

OrvionLib:Notify("W424 Hub", "Ultimate Sea Edition Loaded!", 4)
