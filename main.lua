-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (ORVION EDITION)
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- LOAD ORVION LIBRARY
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ==========================================
-- KONFIGURASI GLOBAL
-- ==========================================
getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 100,
    TargetDestination = "Bonfire",
    BonfireCF = nil,
    CraftingCF = nil,
}

-- ==========================================
-- FUNGSI UTILITAS
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function notify(title, message, duration)
    duration = duration or 3
    pcall(function()
        OrvionLib:Notify(title, message, duration)
    end)
end

local function formatStatus()
    local b = getgenv().W424_Sea.BonfireCF and "✅" or "❌"
    local c = getgenv().W424_Sea.CraftingCF and "✅" or "❌"
    return string.format("Bonfire: %s | Crafting: %s | Target: %s", 
        b, c, getgenv().W424_Sea.TargetDestination)
end

-- ==========================================
-- BUAT WINDOW
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 100 Days at Sea",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Teleport = Window:AddTab("Teleport"),
    Settings = Window:AddTab("Settings"),
}

-- ==========================================
-- TAB: MAIN
-- ==========================================
local StatusPara = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = formatStatus(),
})

local function refreshStatus()
    StatusPara:SetDesc(formatStatus())
end

-- Toggle: Auto Harpoon
Tabs.Main:AddToggle({
    Title = "Auto Harpoon",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoHarpoon = state
        notify("Auto Harpoon", state and "Activated" or "Deactivated", 2)
    end
})

-- Input: Harpoon Radius
Tabs.Main:AddInput({
    Title = "Harpoon Radius",
    Default = tostring(getgenv().W424_Sea.HarpoonRadius),
    Placeholder = "Enter radius...",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            getgenv().W424_Sea.HarpoonRadius = num
        end
    end
})

-- Toggle: Auto Collect & Drag
local AutoCollectToggle
AutoCollectToggle = Tabs.Main:AddToggle({
    Title = "Auto Collect & Drag",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoCollect = state
        notify("Auto Collect", state and "Activated" or "Deactivated", 2)
    end
})

-- Input: Collect Radius
Tabs.Main:AddInput({
    Title = "Collect Radius",
    Default = tostring(getgenv().W424_Sea.CollectRadius),
    Placeholder = "Enter radius...",
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            getgenv().W424_Sea.CollectRadius = num
        end
    end
})

-- Dropdown: Target Destination
Tabs.Main:AddDropdown({
    Title = "Target Destination",
    Values = {"Bonfire", "Crafting"},
    DefaultValue = getgenv().W424_Sea.TargetDestination,
    Callback = function(value)
        getgenv().W424_Sea.TargetDestination = value
        refreshStatus()
        notify("Target Set", "Destination: " .. value, 2)
    end
})

-- ==========================================
-- TAB: TELEPORT (Set Posisi)
-- ==========================================
Tabs.Teleport:AddButton({
    Title = "📍 Set Bonfire Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Sea.BonfireCF = hrp.CFrame
            refreshStatus()
            notify("Position Set", "Bonfire position saved!", 3)
        else
            notify("Error", "Character not found!", 3)
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "📍 Set Crafting Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Sea.CraftingCF = hrp.CFrame
            refreshStatus()
            notify("Position Set", "Crafting position saved!", 3)
        else
            notify("Error", "Character not found!", 3)
        end
    end
})

Tabs.Teleport:AddButtonGrid(
    {
        Title = "Teleport to Bonfire",
        Callback = function()
            if getgenv().W424_Sea.BonfireCF then
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = getgenv().W424_Sea.BonfireCF
                    notify("Teleported", "Moved to Bonfire", 2)
                end
            else
                notify("Error", "Bonfire position not set!", 3)
            end
        end
    },
    {
        Title = "Teleport to Crafting",
        Callback = function()
            if getgenv().W424_Sea.CraftingCF then
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = getgenv().W424_Sea.CraftingCF
                    notify("Teleported", "Moved to Crafting", 2)
                end
            else
                notify("Error", "Crafting position not set!", 3)
            end
        end
    }
)

-- ==========================================
-- TAB: SETTINGS
-- ==========================================
Tabs.Settings:AddButton({
    Title = "Reset All Positions",
    Callback = function()
        getgenv().W424_Sea.BonfireCF = nil
        getgenv().W424_Sea.CraftingCF = nil
        refreshStatus()
        notify("Reset", "All positions cleared!", 3)
    end
})

-- ==========================================
-- LOGIC: AUTO HARPOON (OPTIMIZED)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        local success, err = pcall(function()
            if not getgenv().W424_Sea.AutoHarpoon then return end
            
            local hrp = getHRP()
            if not hrp then return end
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end
            
            local remote = tool:FindFirstChildOfClass("RemoteEvent")
            if not remote then return end

            local radius = getgenv().W424_Sea.HarpoonRadius or 150
            
            -- Optimasi: scan workspace dengan pengecekan cepat
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not getgenv().W424_Sea.AutoHarpoon then break end
                
                if obj:IsA("Model") and obj ~= char then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= radius then
                            remote:FireServer(obj)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end)
        
        if not success and err then
            warn("[AutoHarpoon Error]", tostring(err))
        end
    end
end)

-- ==========================================
-- LOGIC: AUTO COLLECT & DRAG (FIXED)
-- ==========================================
task.spawn(function()
    while task.wait(0.8) do
        local success, err = pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            
            local hrp = getHRP()
            if not hrp then return end

            -- Tentukan target koordinat
            local targetCF
            if getgenv().W424_Sea.TargetDestination == "Bonfire" then
                targetCF = getgenv().W424_Sea.BonfireCF
            else
                targetCF = getgenv().W424_Sea.CraftingCF
            end

            -- Jika belum set koordinat, matikan otomatis & beri tahu user
            if not targetCF then
                getgenv().W424_Sea.AutoCollect = false
                pcall(function() AutoCollectToggle:SetValue(false) end)
                notify("Warning", "Target position not set! Go to Teleport tab to set it.", 4)
                return
            end

            local radius = getgenv().W424_Sea.CollectRadius or 100
            local floatingObjects = CollectionService:GetTagged("Floating_Object")
            
            for _, obj in ipairs(floatingObjects) do
                if not getgenv().W424_Sea.AutoCollect then break end
                
                -- Skip jika obj sudah di-destroy
                if not obj or not obj.Parent then continue end
                
                local part
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end

                -- Cek ulang validitas part
                if part and part.Parent then
                    local dist = (part.Position - hrp.Position).Magnitude
                    
                    -- Hanya ambil item di bawah ketinggian 148 (laut)
                    if dist <= radius and part.Position.Y < 148 then
                        
                        -- 1. Teleport ke item (dengan offset agar tidak nge-bug)
                        hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.25)
                        
                        -- 2. Sentuh item (Touch Began + Ended) — LENGKAP
                        pcall(function()
                            firetouchinterest(hrp, part, 0) -- Began
                            task.wait(0.05)
                            firetouchinterest(hrp, part, 1) -- Ended
                        end)
                        task.wait(0.15)
                        
                        -- 3. Bawa player & item ke target
                        -- FIX: Gunakan CFrame langsung, bukan TweenService (lebih reliable untuk HRP)
                        hrp.CFrame = targetCF
                        
                        -- Bawa item ikut ke target (reset velocity biar tidak nyangkut)
                        pcall(function()
                            if part and part.Parent then
                                part.CFrame = targetCF
                                part.AssemblyLinearVelocity = Vector3.zero
                                part.AssemblyAngularVelocity = Vector3.zero
                            end
                        end)
                        
                        task.wait(0.2)
                        
                        -- 4. Lepas item di dalam mesin (Touch Began + Ended) — LENGKAP
                        pcall(function()
                            if part and part.Parent then
                                firetouchinterest(hrp, part, 0) -- Began
                                task.wait(0.05)
                                firetouchinterest(hrp, part, 1) -- Ended
                            end
                        end)
                        
                        task.wait(0.3)
                        break 
                    end
                end
            end
        end)
        
        if not success and err then
            warn("[AutoCollect Error]", tostring(err))
        end
    end
end)

-- Status awal
refreshStatus()
notify("W424 Hub", "Script loaded successfully!", 4)
