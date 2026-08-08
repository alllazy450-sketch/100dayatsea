-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — FIXED v2
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ANTI-DOUBLE LOAD (HENTIKAN SCRIPT LAMA)
-- ==========================================
if getgenv().W424_KillSwitch then
    getgenv().W424_KillSwitch = true
    task.wait(1)
end
getgenv().W424_KillSwitch = false

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
    ItemSearchRadius = 250,
    Mode = "PickUp",
    Active = false,
    BagName = "Old Sack",
    AutoEquipBag = false,
    Delay = 0.6,
}

-- ==========================================
-- UTILITAS
-- ==========================================
local function notify(title, msg, dur)
    pcall(function() OrvionLib:Notify(title, msg, dur or 3) end)
end

local function getChar()
    return LocalPlayer.Character
end

local function getHRP()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- CASE-INSENSITIVE: Cek nama tool
local function isBag(tool)
    if not tool or not tool:IsA("Tool") then return false end
    return string.lower(tool.Name) == string.lower(getgenv().W424_Config.BagName)
end

local function equipBag()
    if not getgenv().W424_Config.AutoEquipBag then return true end
    
    local char = getChar()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return false end
    
    -- Cek sudah equipped?
    for _, v in ipairs(char:GetChildren()) do
        if isBag(v) then return true end
    end
    
    -- Cari di backpack
    for _, v in ipairs(backpack:GetChildren()) do
        if isBag(v) then
            local hum = getHum()
            if hum then
                hum:EquipTool(v)
                task.wait(0.4)
                return true
            end
        end
    end
    
    return false
end

-- Ambil item di laut (Floating_Object)
local function getFloatingItems()
    local items = {}
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

-- Ambil TOOL di inventory (KECUALI BAG!)
local function getInventoryItems()
    local items = {}
    local char = getChar()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and not isBag(tool) then
                table.insert(items, tool)
            end
        end
    end
    
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and not isBag(tool) then
                table.insert(items, tool)
            end
        end
    end
    
    return items
end

-- Cari part storage/bonfire terdekat
local function getNearbyStorage()
    local hrp = getHRP()
    if not hrp then return nil end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if n:match("storage") or n:match("bonfire") or n:match("chest") or n:match("sack") or n:match("bag") then
                if (obj.Position - hrp.Position).Magnitude <= 25 then
                    return obj
                end
            end
        end
    end
    return nil
end

-- Touch aman
local function safeTouch(toucher, touched)
    if not toucher or not toucher.Parent then return end
    if not touched or not touched.Parent then return end
    pcall(function()
        firetouchinterest(toucher, touched, 0)
        task.wait(0.08)
        firetouchinterest(toucher, touched, 1)
    end)
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Fixed v2",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Teleport = Window:AddTab("Teleport"),
    Debug = Window:AddTab("Debug"),
}

-- Status
local StatusPara = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Ready | Mode: PickUp | OFF",
})

local DebugPara = Tabs.Debug:AddParagraph({
    Title = "Debug Info",
    Content = "Waiting...",
})

local function setStatus(txt)
    StatusPara:SetDesc(txt)
end

local function setDebug(txt)
    DebugPara:SetDesc(txt)
end

-- Mode
Tabs.Main:AddDropdown({
    Title = "Mode",
    Values = {"PickUp", "Store", "Unstore"},
    DefaultValue = getgenv().W424_Config.Mode,
    Callback = function(v)
        getgenv().W424_Config.Mode = v
        setStatus("Mode: " .. v .. " | " .. (getgenv().W424_Config.Active and "ON" or "OFF"))
    end
})

-- Toggle UTAMA (1 toggle untuk semua)
Tabs.Main:AddToggle({
    Title = "Start Auto",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        setStatus("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Auto " .. getgenv().W424_Config.Mode, state and "Started" or "Stopped", 2)
    end
})

-- Auto Equip
Tabs.Main:AddToggle({
    Title = "Auto Equip Old Sack",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.AutoEquipBag = state
    end
})

-- Input Radius
Tabs.Main:AddInput({
    Title = "Search Radius",
    Default = tostring(getgenv().W424_Config.ItemSearchRadius),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.ItemSearchRadius = n end
    end
})

-- ==========================================
-- TAB TELEPORT
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
                notify("Error", "Raft position not set!", 3)
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
                notify("Error", "Storage position not set!", 3)
            end
        end
    }
)

-- ==========================================
-- TAB DEBUG
-- ==========================================
Tabs.Debug:AddButton({
    Title = "🔍 Scan Inventory",
    Callback = function()
        local char = getChar()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local msg = "Backpack:\n"
        
        if bp then
            for _, v in ipairs(bp:GetChildren()) do
                msg = msg .. "- " .. v.Name .. (isBag(v) and " [BAG]" or "") .. "\n"
            end
        end
        
        msg = msg .. "\nCharacter:\n"
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then
                    msg = msg .. "- " .. v.Name .. (isBag(v) and " [BAG]" or "") .. "\n"
                end
            end
        end
        
        setDebug(msg)
        notify("Debug", "Inventory scanned", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🔍 Scan Floating Items",
    Callback = function()
        local items = getFloatingItems()
        local msg = "Found " .. #items .. " items:\n"
        for i = 1, math.min(5, #items) do
            msg = msg .. "- " .. items[i].Name .. " (" .. math.floor((items[i].Position - (getHRP() and getHRP().Position or Vector3.zero)).Magnitude) .. "m)\n"
        end
        setDebug(msg)
        notify("Debug", #items .. " floating items found", 2)
    end
})

-- ==========================================
-- MAIN LOOP (ANTI-SPAM: HANYA 1 LOOP!)
-- ==========================================
task.spawn(function()
    while true do
        if getgenv().W424_KillSwitch then break end
        task.wait(getgenv().W424_Config.Delay)
        
        if not getgenv().W424_Config.Active then
            continue
        end
        
        local hrp = getHRP()
        if not hrp then
            setStatus("Character not found")
            continue
        end
        
        local mode = getgenv().W424_Config.Mode
        
        -- ==========================================
        -- MODE: PICK UP
        -- ==========================================
        if mode == "PickUp" then
            pcall(function()
                -- Equip bag
                if getgenv().W424_Config.AutoEquipBag then
                    if not equipBag() then
                        setStatus("Old Sack not found!")
                        return
                    end
                end
                
                -- Cari item terdekat
                local items = getFloatingItems()
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
                    setStatus("No items in radius")
                    return
                end
                
                setStatus("Moving to: " .. target.Name)
                
                -- Teleport ke item (offset tinggi biar tidak nyangkut)
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                
                -- Pick up via touch
                safeTouch(hrp, target)
                task.wait(0.3)
                
                -- Cek apakah item masih ada di workspace (jika hilang = berhasil pick up)
                if target and target.Parent then
                    -- Item masih ada, coba sekali lagi
                    safeTouch(hrp, target)
                    task.wait(0.2)
                end
                
                -- Kembali ke raft
                if not getgenv().W424_Config.RaftCF then
                    setStatus("Raft position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                setStatus("Returning to raft...")
                hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                task.wait(0.4)
                
                -- Drop SEMUA item inventory (KECUALI BAG!) di raft
                local inv = getInventoryItems()
                for _, tool in ipairs(inv) do
                    pcall(function()
                        tool.Parent = Workspace
                    end)
                end
                
                setStatus("Dropped " .. #inv .. " item(s) at raft")
                task.wait(0.5)
            end)
            
        -- ==========================================
        -- MODE: STORE
        -- ==========================================
        elseif mode == "Store" then
            pcall(function()
                if getgenv().W424_Config.AutoEquipBag then
                    if not equipBag() then
                        setStatus("Old Sack not found!")
                        return
                    end
                end
                
                -- Cari item
                local items = getFloatingItems()
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
                    setStatus("No items found")
                    return
                end
                
                setStatus("Grabbing: " .. target.Name)
                
                -- Ambil item
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                safeTouch(hrp, target)
                task.wait(0.3)
                
                -- Bawa ke storage
                if not getgenv().W424_Config.StorageCF then
                    setStatus("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                setStatus("Moving to storage...")
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 4, 0)
                task.wait(0.5)
                
                -- Cari storage part terdekat dan sentuh
                local storage = getNearbyStorage()
                if storage then
                    safeTouch(hrp, storage)
                    setStatus("Touched storage: " .. storage.Name)
                else
                    setStatus("Storage part not found nearby")
                end
                
                -- Drop inventory item di dekat storage (KECUALI BAG!)
                local inv = getInventoryItems()
                for _, tool in ipairs(inv) do
                    pcall(function()
                        tool.Parent = Workspace
                    end)
                end
                
                task.wait(0.5)
            end)
            
        -- ==========================================
        -- MODE: UNSTORE
        -- ==========================================
        elseif mode == "Unstore" then
            pcall(function()
                -- Ke storage dulu
                if not getgenv().W424_Config.StorageCF then
                    setStatus("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                setStatus("Going to storage...")
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 5, 0)
                task.wait(0.5)
                
                -- Cari item di sekitar storage (bukan storage part sendiri)
                local nearby = {}
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj ~= hrp then
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist <= 15 then
                            local n = string.lower(obj.Name)
                            -- Hindari part environment dan storage
                            if not n:match("baseplate") and not n:match("water") 
                               and not n:match("storage") and not n:match("bonfire")
                               and not n:match("raft") and not n:match("floor") then
                                table.insert(nearby, obj)
                            end
                        end
                    end
                end
                
                if #nearby == 0 then
                    setStatus("No items at storage")
                    task.wait(1.5)
                    return
                end
                
                -- Ambil item pertama
                local item = nearby[1]
                setStatus("Taking: " .. item.Name)
                
                hrp.CFrame = item.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)
                safeTouch(hrp, item)
                task.wait(0.2)
                
                -- Bawa ke raft
                if not getgenv().W424_Config.RaftCF then
                    setStatus("Raft position not set!")
                    return
                end
                
                setStatus("Moving to raft...")
                hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                task.wait(0.4)
                
                -- Drop item (KECUALI BAG!)
                local inv = getInventoryItems()
                for _, tool in ipairs(inv) do
                    pcall(function()
                        tool.Parent = Workspace
                    end)
                end
                
                setStatus("Unstored to raft")
                task.wait(0.5)
            end)
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v2", "Script loaded! Use Debug tab to scan items.", 4)
setStatus("Ready | Mode: PickUp | OFF")
setDebug("Click 'Scan Inventory' or 'Scan Floating Items' to debug.")
