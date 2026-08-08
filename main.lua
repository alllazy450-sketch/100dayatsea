-- ==========================================
-- W424 HUB | 100 DAYS AS SEA (REMOTE HOOK EDITION)
-- ==========================================

local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local SocialService = game:GetService("SocialService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoSubmit = false,
    SubmitTarget = "Crafting", -- "Crafting" atau "Campfire"
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
    Loot    = Window:AddTab("Auto Submit"),
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
-- 2. AUTO SUBMIT (Kirim Item Laut via RemoteEvent ke Crafting/Campfire)
-- ==========================================
task.spawn(function()
    while task.wait(0.6) do
        pcall(function()
            if not getgenv().W424_Sea.AutoSubmit then return end
            local hrp = getHRP()
            if not hrp then return end

            local radius = getgenv().W424_Sea.CollectRadius or 100
            local remoteEvent = SocialService:WaitForChild("RemoteEvent")

            for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
                if not getgenv().W424_Sea.AutoSubmit then break end
                
                local part = nil
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end

                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist <= radius and part.Position.Y < 148 then
                        
                        -- Tentukan koordinat tujuan berdasarkan pilihan menu
                        -- (Kamu bisa sesuaikan string koordinat target berdasarkan hasil spy masing-masing mesin)
                        local targetCoord = "~v8.662,-4.5933,-0.1604" -- Default Crafting/Mesin Kayu
                        if getgenv().W424_Sea.SubmitTarget == "Campfire" then
                            targetCoord = "~v5.123,-4.1200,1.4500" -- Contoh koordinat Campfire (bisa diganti dari spy campfire)
                        end

                        -- Bungkus argumen sesuai hasil Remote Spy asli game
                        local args = {
                            math.random(100000, 999999), -- ID unik acak agar tidak stuck
                            "GiveUpOwnership",
                            obj, -- Kirim objek item lautnya langsung
                            targetCoord
                        }

                        -- Tembak langsung ke server game!
                        remoteEvent:FireServer(unpack(args))
                        
                        task.wait(0.3) -- Jeda antar pengiriman item
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
    Title = "Auto Send Floating Items to Target",
    Default = false,
    Callback = function(state) getgenv().W424_Sea.AutoSubmit = state end
})

Tabs.Loot:AddDropdown({
    Title = "Pilih Tujuan Kirim Item",
    Values = {"Crafting", "Campfire"},
    DefaultValue = "Crafting",
    Callback = function(value)
        getgenv().W424_Sea.SubmitTarget = value
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

OrvionLib:Notify("W424 Hub", "Remote Spy Hook Loaded!", 4)
