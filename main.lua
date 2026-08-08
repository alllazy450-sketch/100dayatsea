-- ==========================================
-- W424 HUB | 100 DAYS AS SEA (TELEPORT TARGET CHANGER)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 100,
    TargetDestination = "Crafting", -- "Crafting" atau "Campfire"
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
    Loot    = Window:AddTab("Auto Teleport Loot"),
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
-- 2. AUTO COLLECT & TELEPORT TO TARGET (Crafting / Campfire)
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end

            local radius = getgenv().W424_Sea.CollectRadius or 100
            local startPos = hrp.CFrame

            for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
                if not getgenv().W424_Sea.AutoCollect then break end
                
                local part = nil
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end

                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist <= radius and part.Position.Y < 148 then
                        
                        -- Titik tujuan di atas rakit (bisa diubah posisinya sesuai lokasi mesin craft/campfire kamu)
                        -- Contoh: Kita pakai posisi relatif di sekitar player saat tombol dinyalakan
                        local targetPos = startPos + Vector3.new(0, 3, 0) -- Default dekat player
                        
                        -- Jika ingin menentukan titik spesifik Crafting atau Campfire:
                        -- (Kamu bisa berdiri di depan mesinnya, lalu sesuaikan koordinat CFrame-nya di sini jika mau fix)

                        -- LANGKAH 1: Teleport karakter ke item di laut
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.2)
                        
                        -- LANGKAH 2: Sentuh item agar ter-trigger / terpegang
                        firetouchinterest(hrp, part, 0)
                        firetouchinterest(hrp, part, 1)
                        task.wait(0.2)

                        -- LANGKAH 3: Bawa itemnya langsung teleport ke tujuan (Crafting / Campfire)
                        if getgenv().W424_Sea.TargetDestination == "Crafting" then
                            -- Pindahkan player & item ke area Mesin Crafting (Contoh posisi di atas rakit)
                            hrp.CFrame = startPos + Vector3.new(-3, 3, 0) 
                        else
                            -- Pindahkan player & item ke area Campfire
                            hrp.CFrame = startPos + Vector3.new(3, 3, 0)
                        end
                        
                        part.CFrame = hrp.CFrame + Vector3.new(0, 0, -2)
                        task.wait(0.2)
                        
                        -- LANGKAH 4: Lepas sentuhan / Drop item
                        firetouchinterest(hrp, part, 1)
                        task.wait(0.3)
                        
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
    Title = "Auto Teleport Loot to Target",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.AutoCollect = state end
})

Tabs.Loot:AddDropdown({
    Title = "Pilih Tujuan Teleport Item",
    Values = {"Crafting", "Campfire"},
    DefaultValue = "Crafting",
    Callback = function(value)
        getgenv().W424_Sea.TargetDestination = value
    end
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

OrvionLib:Notify("W424 Hub", "Teleport Target Switcher Loaded!", 4)
