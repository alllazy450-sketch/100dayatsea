-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — SMART BAG SYSTEM
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
    -- Posisi
    RaftCF = nil,
    StorageCF = nil,
    ItemSearchRadius = 200,
    
    -- Mode
    AutoMode = "PickUp",
    
    -- Toggle
    AutoPickUp = false,
    AutoStore = false,
    AutoUnstore = false,
    
    -- Bag (DEFAULT: Old Sack)
    BagToolName = "Old Sack",
    AutoEquipBag = false,
    
    -- Delay
    PickUpDelay = 0.3,
    StoreDelay = 0.5,
}

-- ==========================================
-- FUNGSI UTILITAS
-- ==========================================
local function notify(title, message, duration)
    duration = duration or 3
    pcall(function()
        OrvionLib:Notify(title, message, duration)
    end)
end

local function getHRP()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function equipBag()
    if not getgenv().W424_Sea.AutoEquipBag then return true end
    
    local char = LocalPlayer.Character
    if not char then return false end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    
    local bag = backpack:FindFirstChild(getgenv().W424_Sea.BagToolName)
    if bag then
        local hum = getHumanoid()
        if hum then
            hum:EquipTool(bag)
            task.wait(0.3)
            return true
        end
    end
    
    if char:FindFirstChild(getgenv().W424_Sea.BagToolName) then
        return true
    end
    
    return false
end

local function getFloatingItems()
    local items = {}
    for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
        if obj and obj.Parent then
            local part
            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") then
                part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            if part then
                table.insert(items, part)
            end
        end
    end
    return items
end

local function getStoredItems()
    local items = {}
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= getgenv().W424_Sea.BagToolName then
                table.insert(items, tool)
            end
        end
    end
    
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= getgenv().W424_Sea.BagToolName then
                table.insert(items, tool)
            end
        end
    end
    
    return items
end

local function safeTouch(part, touchPart)
    if not part or not part.Parent then return end
    if not touchPart or not touchPart.Parent then return end
    
    pcall(function()
        firetouchinterest(part, touchPart, 0)
        task.wait(0.05)
        firetouchinterest(part, touchPart, 1)
    end)
end

local function teleportTo(cf)
    local hrp = getHRP()
    if hrp and cf then
        hrp.CFrame = cf
        return true
    end
    return false
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Smart Bag System",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Auto = Window:AddTab("Auto"),
    Teleport = Window:AddTab("Teleport"),
    Settings = Window:AddTab("Settings"),
}

-- ==========================================
-- TAB: AUTO (MAIN CONTROLS)
-- ==========================================
local StatusPara = Tabs.Auto:AddParagraph({
    Title = "System Status",
    Content = "Idle | Mode: PickUp",
})

local function updateStatus(text)
    StatusPara:SetDesc(text or "Idle")
end

-- Mode Selector
Tabs.Auto:AddDropdown({
    Title = "Auto Mode",
    Values = {"PickUp", "Store", "Unstore"},
    DefaultValue = getgenv().W424_Sea.AutoMode,
    Callback = function(value)
        getgenv().W424_Sea.AutoMode = value
        updateStatus("Mode changed to: " .. value)
    end
})

-- Toggle: Start Auto (Universal)
local AutoToggle
AutoToggle = Tabs.Auto:AddToggle({
    Title = "Start Auto Loop",
    Default = false,
    Callback = function(state)
        if getgenv().W424_Sea.AutoMode == "PickUp" then
            getgenv().W424_Sea.AutoPickUp = state
        elseif getgenv().W424_Sea.AutoMode == "Store" then
            getgenv().W424_Sea.AutoStore = state
        else
            getgenv().W424_Sea.AutoUnstore = state
        end
        
        notify("Auto " .. getgenv().W424_Sea.AutoMode, state and "Started" or "Stopped", 2)
    end
})

-- Toggle: Auto Equip Bag
Tabs.Auto:AddToggle({
    Title = "Auto Equip Old Sack",
    Default = false,
    Callback = function(state)
        getgenv().W424_Sea.AutoEquipBag = state
    end
})

-- Input: Bag Tool Name (Sudah default Old Sack)
Tabs.Auto:AddInput({
    Title = "Bag Tool Name",
    Default = getgenv().W424_Sea.BagToolName,
    Placeholder = "e.g. Old Sack, Bag...",
    Callback = function(value)
        getgenv().W424_Sea.BagToolName = value
    end
})

-- Input: Search Radius
Tabs.Auto:AddInput({
    Title = "Item Search Radius",
    Default = tostring(getgenv().W424_Sea.ItemSearchRadius),
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            getgenv().W424_Sea.ItemSearchRadius = num
        end
    end
})

-- ==========================================
-- TAB: TELEPORT (SET POSITIONS)
-- ==========================================
Tabs.Teleport:AddButton({
    Title = "📍 Set Raft Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Sea.RaftCF = hrp.CFrame
            notify("Position Set", "Raft position saved!", 3)
        else
            notify("Error", "Character not found!", 3)
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "📍 Set Storage Position",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            getgenv().W424_Sea.StorageCF = hrp.CFrame
            notify("Position Set", "Storage position saved!", 3)
        else
            notify("Error", "Character not found!", 3)
        end
    end
})

Tabs.Teleport:AddButtonGrid(
    {
        Title = "TP to Raft",
        Callback = function()
            if getgenv().W424_Sea.RaftCF then
                teleportTo(getgenv().W424_Sea.RaftCF)
                notify("Teleported", "Moved to Raft", 2)
            else
                notify("Error", "Raft position not set!", 3)
            end
        end
    },
    {
        Title = "TP to Storage",
        Callback = function()
            if getgenv().W424_Sea.StorageCF then
                teleportTo(getgenv().W424_Sea.StorageCF)
                notify("Teleported", "Moved to Storage", 2)
            else
                notify("Error", "Storage position not set!", 3)
            end
        end
    }
)

Tabs.Teleport:AddButton({
    Title = "Reset All Positions",
    Callback = function()
        getgenv().W424_Sea.RaftCF = nil
        getgenv().W424_Sea.StorageCF = nil
        notify("Reset", "All positions cleared!", 3)
    end
})

-- ==========================================
-- TAB: SETTINGS
-- ==========================================
Tabs.Settings:AddInput({
    Title = "Pick Up Delay",
    Default = tostring(getgenv().W424_Sea.PickUpDelay),
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0 then
            getgenv().W424_Sea.PickUpDelay = num
        end
    end
})

Tabs.Settings:AddInput({
    Title = "Store Delay",
    Default = tostring(getgenv().W424_Sea.StoreDelay),
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 0 then
            getgenv().W424_Sea.StoreDelay = num
        end
    end
})

-- ==========================================
-- LOGIC: AUTO PICK UP
-- ==========================================
task.spawn(function()
    while task.wait(0.8) do
        local success, err = pcall(function()
            if not getgenv().W424_Sea.AutoPickUp then return end
            
            local hrp = getHRP()
            if not hrp then return end
            
            if getgenv().W424_Sea.AutoEquipBag then
                if not equipBag() then
                    updateStatus("Old Sack not found!")
                    return
                end
            end
            
            local items = getFloatingItems()
            local targetItem = nil
            local minDist = math.huge
            
            for _, part in ipairs(items) do
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= getgenv().W424_Sea.ItemSearchRadius and part.Position.Y < 148 then
                    if dist < minDist then
                        minDist = dist
                        targetItem = part
                    end
                end
            end
            
            if not targetItem then
                updateStatus("No items found in radius")
                return
            end
            
            updateStatus("Picking up item...")
            
            teleportTo(targetItem.CFrame + Vector3.new(0, 3, 0))
            task.wait(getgenv().W424_Sea.PickUpDelay)
            
            safeTouch(hrp, targetItem)
            task.wait(0.2)
            
            if not getgenv().W424_Sea.RaftCF then
                updateStatus("Raft position not set!")
                getgenv().W424_Sea.AutoPickUp = false
                pcall(function() AutoToggle:SetValue(false) end)
                return
            end
            
            updateStatus("Returning to raft...")
            teleportTo(getgenv().W424_Sea.RaftCF + Vector3.new(0, 5, 0))
            task.wait(0.3)
            
            local stored = getStoredItems()
            for _, tool in ipairs(stored) do
                pcall(function()
                    if tool.Parent == LocalPlayer.Character then
                        tool.Parent = Workspace
                    end
                end)
            end
            
            updateStatus("Item dropped at raft")
            task.wait(0.5)
        end)
        
        if not success and err then
            warn("[AutoPickUp Error]", tostring(err))
            updateStatus("Error: " .. tostring(err))
        end
    end
end)

-- ==========================================
-- LOGIC: AUTO STORE
-- ==========================================
task.spawn(function()
    while task.wait(0.8) do
        local success, err = pcall(function()
            if not getgenv().W424_Sea.AutoStore then return end
            
            local hrp = getHRP()
            if not hrp then return end
            
            if getgenv().W424_Sea.AutoEquipBag then
                if not equipBag() then
                    updateStatus("Old Sack not found!")
                    return
                end
            end
            
            local items = getFloatingItems()
            local targetItem = nil
            local minDist = math.huge
            
            for _, part in ipairs(items) do
                local dist = (part.Position - hrp.Position).Magnitude
                if dist <= getgenv().W424_Sea.ItemSearchRadius and part.Position.Y < 148 then
                    if dist < minDist then
                        minDist = dist
                        targetItem = part
                    end
                end
            end
            
            if not targetItem then
                updateStatus("No items found")
                return
            end
            
            updateStatus("Going to item...")
            
            teleportTo(targetItem.CFrame + Vector3.new(0, 3, 0))
            task.wait(getgenv().W424_Sea.PickUpDelay)
            safeTouch(hrp, targetItem)
            task.wait(0.2)
            
            if not getgenv().W424_Sea.StorageCF then
                updateStatus("Storage position not set!")
                getgenv().W424_Sea.AutoStore = false
                pcall(function() AutoToggle:SetValue(false) end)
                return
            end
            
            updateStatus("Storing item...")
            teleportTo(getgenv().W424_Sea.StorageCF + Vector3.new(0, 3, 0))
            task.wait(getgenv().W424_Sea.StoreDelay)
            
            local storagePart = nil
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name:lower()
                    if name:match("storage") or name:match("bag") or name:match("bonfire") or name:match("sack") then
                        if (obj.Position - hrp.Position).Magnitude <= 20 then
                            storagePart = obj
                            break
                        end
                    end
                end
            end
            
            if storagePart then
                safeTouch(hrp, storagePart)
            end
            
            local stored = getStoredItems()
            for _, tool in ipairs(stored) do
                pcall(function()
                    if tool.Parent == LocalPlayer.Character then
                        local chatRemote = game:GetService("Chat"):FindFirstChild("RemoteEvent")
                        if chatRemote then
                            chatRemote:FireServer(339183, "DropItem")
                        end
                        task.wait(0.1)
                        tool.Parent = Workspace
                    end
                end)
            end
            
            updateStatus("Item stored")
            task.wait(0.5)
        end)
        
        if not success and err then
            warn("[AutoStore Error]", tostring(err))
        end
    end
end)

-- ==========================================
-- LOGIC: AUTO UNSTORE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        local success, err = pcall(function()
            if not getgenv().W424_Sea.AutoUnstore then return end
            
            local hrp = getHRP()
            if not hrp then return end
            
            if not getgenv().W424_Sea.StorageCF then
                updateStatus("Storage position not set!")
                getgenv().W424_Sea.AutoUnstore = false
                pcall(function() AutoToggle:SetValue(false) end)
                return
            end
            
            updateStatus("Going to storage...")
            teleportTo(getgenv().W424_Sea.StorageCF + Vector3.new(0, 5, 0))
            task.wait(0.5)
            
            local nearbyItems = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                    if part then
                        local dist = (part.Position - hrp.Position).Magnitude
                        if dist <= 15 and obj ~= LocalPlayer.Character then
                            local name = obj.Name:lower()
                            if not name:match("storage") and not name:match("bag") and not name:match("bonfire") and not name:match("sack") then
                                table.insert(nearbyItems, part)
                            end
                        end
                    end
                end
            end
            
            if #nearbyItems == 0 then
                updateStatus("No items at storage")
                task.wait(2)
                return
            end
            
            local item = nearbyItems[1]
            updateStatus("Unstoring item...")
            
            teleportTo(item.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.2)
            safeTouch(hrp, item)
            task.wait(0.2)
            
            if not getgenv().W424_Sea.RaftCF then
                updateStatus("Raft position not set!")
                return
            end
            
            updateStatus("Moving to raft...")
            teleportTo(getgenv().W424_Sea.RaftCF + Vector3.new(0, 5, 0))
            task.wait(0.3)
            
            pcall(function()
                if item and item.Parent then
                    item.CFrame = getgenv().W424_Sea.RaftCF
                    item.AssemblyLinearVelocity = Vector3.zero
                end
            end)
            
            local stored = getStoredItems()
            for _, tool in ipairs(stored) do
                pcall(function()
                    if tool.Parent == LocalPlayer.Character then
                        tool.Parent = Workspace
                    end
                end)
            end
            
            updateStatus("Item placed at raft")
            task.wait(0.5)
        end)
        
        if not success and err then
            warn("[AutoUnstore Error]", tostring(err))
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
updateStatus("Ready | Old Sack detected | Select mode and press Start")
notify("W424 Hub", "Smart Bag System loaded! Bag: Old Sack", 4)
