-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — HARPOON FARMER
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ANTI-DOUBLE LOAD
-- ==========================================
if getgenv().W424_Running then
    getgenv().W424_Running = false
    task.wait(1.2)
end
getgenv().W424_Running = true

-- ==========================================
-- LOAD ORVION LIBRARY
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ==========================================
-- KONFIGURASI
-- ==========================================
getgenv().W424_Config = {
    RaftCF = nil,
    StorageCF = nil,
    ItemSearchRadius = 300,
    Mode = "PickUp",      -- "PickUp" (ke raft) | "Store" (ke storage)
    Active = false,
    Delay = 0.5,
    HarpoonName = "Harpoon",
}

-- ==========================================
-- STATE
-- ==========================================
local IsHarpooning = false

-- ==========================================
-- UTILITAS
-- ==========================================
local function notify(title, msg, dur)
    pcall(function() OrvionLib:Notify(title, msg, dur or 3) end)
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function equipHarpoon()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return nil end
    
    -- Cek sudah equipped
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == string.lower(getgenv().W424_Config.HarpoonName) then
            return v
        end
    end
    
    -- Cari di backpack
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == string.lower(getgenv().W424_Config.HarpoonName) then
            local hum = getHumanoid()
            if hum then
                hum:EquipTool(v)
                task.wait(0.4)
                return v
            end
        end
    end
    
    return nil
end

-- Cari item di laut (DebrisField + Floating_Object)
local function getItems()
    local items = {}
    
    -- DebrisField (dari remote spy)
    local debris = Workspace:FindFirstChild("DebrisField")
    if debris then
        for _, folder in ipairs(debris:GetChildren()) do
            for _, child in ipairs(folder:GetChildren()) do
                local part = child:IsA("BasePart") and child or (child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart"))
                if part and part.Parent then
                    table.insert(items, part)
                end
            end
        end
    end
    
    -- Floating_Object (CollectionService)
    for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
        if obj and obj.Parent then
            local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if part and part.Parent then
                table.insert(items, part)
            end
        end
    end
    
    return items
end

-- Fire harpoon ke item
local function fireHarpoon(tool, item)
    if not tool or not item or not item.Parent then return false end
    
    local remote = tool:FindFirstChildOfClass("RemoteEvent")
    if not remote then return false end
    
    local ok = pcall(function()
        remote:FireServer(item)
    end)
    
    return ok
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Harpoon Farmer",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Main = Window:AddTab("Auto"),
    Teleport = Window:AddTab("Teleport"),
    Debug = Window:AddTab("Debug"),
}

local StatusPara = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Ready | OFF",
})

local function status(txt)
    StatusPara:SetDesc(txt)
end

-- Mode
Tabs.Main:AddDropdown({
    Title = "Mode",
    Values = {"PickUp", "Store"},
    DefaultValue = getgenv().W424_Config.Mode,
    Callback = function(v)
        getgenv().W424_Config.Mode = v
        status("Mode: " .. v .. " | " .. (getgenv().W424_Config.Active and "ON" or "OFF"))
    end
})

-- Toggle
Tabs.Main:AddToggle({
    Title = "Start Harpoon Farm",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then IsHarpooning = false end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Harpoon Farm", state and "Started" or "Stopped", 2)
    end
})

-- Radius
Tabs.Main:AddInput({
    Title = "Search Radius",
    Default = tostring(getgenv().W424_Config.ItemSearchRadius),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.ItemSearchRadius = n end
    end
})

-- ==========================================
-- TELEPORT TAB
-- ==========================================
Tabs.Teleport:AddButton({
    Title = "📍 Set Raft Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Config.RaftCF = hrp.CFrame
            notify("Saved", "Raft position set!", 3)
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "📍 Set Storage Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Config.StorageCF = hrp.CFrame
            notify("Saved", "Storage position set!", 3)
        end
    end
})

Tabs.Teleport:AddButtonGrid(
    {
        Title = "TP to Raft",
        Callback = function()
            if getgenv().W424_Config.RaftCF then
                local hrp = getHRP()
                if hrp then hrp.CFrame = getgenv().W424_Config.RaftCF end
            else
                notify("Error", "Raft not set!", 3)
            end
        end
    },
    {
        Title = "TP to Storage",
        Callback = function()
            if getgenv().W424_Config.StorageCF then
                local hrp = getHRP()
                if hrp then hrp.CFrame = getgenv().W424_Config.StorageCF end
            else
                notify("Error", "Storage not set!", 3)
            end
        end
    }
)

-- ==========================================
-- DEBUG TAB
-- ==========================================
Tabs.Debug:AddButton({
    Title = "🔍 Scan Items",
    Callback = function()
        local items = getItems()
        local msg = "Found " .. #items .. " items\n"
        for i = 1, math.min(5, #items) do
            msg = msg .. items[i].Name .. "\n"
        end
        status(msg)
        notify("Debug", #items .. " items found", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Equip Harpoon",
    Callback = function()
        local tool = equipHarpoon()
        notify("Debug", tool and "Harpoon equipped!" or "Harpoon not found!", 3)
    end
})

-- ==========================================
-- MAIN LOOP — HARPOON FARM
-- ==========================================
task.spawn(function()
    while getgenv().W424_Running do
        task.wait(getgenv().W424_Config.Delay)
        
        if not getgenv().W424_Config.Active then
            continue
        end
        
        local hrp = getHRP()
        if not hrp then
            status("No character")
            continue
        end
        
        local mode = getgenv().W424_Config.Mode
        
        -- ==========================================
        -- STEP 1: EQUIP HARPOON
        -- ==========================================
        local harpoon = equipHarpoon()
        if not harpoon then
            status("Harpoon not found!")
            getgenv().W424_Config.Active = false
            continue
        end
        
        -- ==========================================
        -- STEP 2: JIKA SEDANG HARPOONING → BAWA KE TUJUAN
        -- ==========================================
        if IsHarpooning then
            local targetCF = (mode == "Store") and getgenv().W424_Config.StorageCF or getgenv().W424_Config.RaftCF
            
            if not targetCF then
                status("Position not set!")
                getgenv().W424_Config.Active = false
                IsHarpooning = false
                continue
            end
            
            status("Moving to " .. mode .. "...")
            
            -- Teleport bertahap agar item ikut (harpoon line masih aktif)
            for i = 1, 8 do
                if not getgenv().W424_Config.Active then break end
                local t = targetCF:Lerp(hrp.CFrame, i/8)
                hrp.CFrame = t
                task.wait(0.05)
            end
            
            hrp.CFrame = targetCF + Vector3.new(0, 5, 0)
            task.wait(0.3)
            
            -- Lepas harpoon (LetGo) — unequip atau fire remote
            pcall(function()
                -- Coba fire LetGo via remote di tool
                local remote = harpoon:FindFirstChildOfClass("RemoteEvent")
                if remote then
                    remote:FireServer(nil) -- atau parameter let go
                end
            end)
            
            -- Backup: unequip tool
            pcall(function()
                local hum = getHumanoid()
                if hum then hum:UnequipTools() end
            end)
            
            IsHarpooning = false
            status("Item delivered!")
            task.wait(0.8)
            continue
        end
        
        -- ==========================================
        -- STEP 3: CARI ITEM BARU
        -- ==========================================
        local items = getItems()
        local target = nil
        local minDist = math.huge
        
        for _, part in ipairs(items) do
            local dist = (part.Position - hrp.Position).Magnitude
            if dist <= getgenv().W424_Config.ItemSearchRadius and part.Position.Y < 150 then
                if dist < minDist then
                    minDist = dist
                    target = part
                end
            end
        end
        
        if not target then
            status("No items in radius")
            continue
        end
        
        -- ==========================================
        -- STEP 4: HARPOON ITEM
        -- ==========================================
        status("Harpooning: " .. target.Name)
        
        -- Arahkan ke item (optional: teleport dekat untuk jaminan kena)
        if minDist > 50 then
            hrp.CFrame = target.CFrame + Vector3.new(0, 10, 0)
            task.wait(0.2)
        end
        
        -- FIRE HARPOON!
        local fired = fireHarpoon(harpoon, target)
        
        if fired then
            IsHarpooning = true
            status("Hit! Bringing " .. target.Name .. "...")
            task.wait(0.3)
        else
            status("Harpoon failed on " .. target.Name)
            task.wait(0.5)
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub | Harpoon", "Equip your Harpoon and press Start!", 4)
status("Ready | Mode: PickUp | OFF")
