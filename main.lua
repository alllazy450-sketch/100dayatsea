-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — REMOTE DRAG v5
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ANTI-DOUBLE LOAD
-- ==========================================
if getgenv().W424_Kill then
    getgenv().W424_Kill = true
    task.wait(1.2)
end
getgenv().W424_Kill = false

-- ==========================================
-- LOAD ORVION LIBRARY
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ==========================================
-- REMOTE REFERENCES (DARI REMOTE SPY TERBARU!)
-- ==========================================
local RemoteEvent = LocalizationService:WaitForChild("RemoteEvent")
local RemoteFunction = LocalizationService:WaitForChild("RemoteFunction")

-- ==========================================
-- KONFIGURASI (UPDATE JIKA ID BERUBAH!)
-- ==========================================
getgenv().W424_Config = {
    -- ID Remote (dari spy terbaru — bisa berubah tiap sesi!)
    AttemptDragId = 315265,
    GiveUpId = 316175,
    
    -- Posisi
    RaftCF = nil,
    StorageCF = nil,
    ItemSearchRadius = 300,
    
    -- Mode
    Mode = "PickUp",      -- "PickUp" | "Store" | "Unstore"
    Active = false,
    Delay = 0.6,
}

-- ==========================================
-- STATE
-- ==========================================
local DraggedItem = nil

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

-- Cari item di DebrisField + Floating_Object
local function getItems()
    local items = {}
    
    -- Cari di CollectionService (Floating_Object)
    for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
        if obj and obj.Parent then
            local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if part and part.Parent then
                table.insert(items, part)
            end
        end
    end
    
    -- Cari di DebrisField (dari remote spy: workspace.DebrisField.[ID].Plank)
    local debris = Workspace:FindFirstChild("DebrisField")
    if debris then
        for _, folder in ipairs(debris:GetChildren()) do
            if folder:IsA("Model") or folder:IsA("Folder") then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("BasePart") then
                        table.insert(items, child)
                    elseif child:IsA("Model") then
                        local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                        if part then
                            table.insert(items, part)
                        end
                    end
                end
            end
        end
    end
    
    return items
end

-- Cari item di sekitar storage (untuk unstore)
local function getItemsNearStorage()
    local hrp = getHRP()
    if not hrp then return {} end
    
    local items = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp and not obj:IsDescendantOf(LocalPlayer.Character) then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist <= 20 then
                local n = string.lower(obj.Name)
                -- Hindari part environment
                if not n:match("baseplate") and not n:match("water") 
                   and not n:match("terrain") and not n:match("raft") 
                   and not n:match("floor") and not n:match("wood") then
                    table.insert(items, obj)
                end
            end
        end
    end
    return items
end

-- ==========================================
-- REMOTE FUNCTIONS
-- ==========================================
local function attemptDrag(item)
    if not item or not item.Parent then return false end
    local ok = pcall(function()
        RemoteFunction:InvokeServer(
            getgenv().W424_Config.AttemptDragId,
            "AttemptDrag",
            item
        )
    end)
    return ok
end

local function giveUpOwnership(item)
    if not item or not item.Parent then return false end
    local ok = pcall(function()
        RemoteEvent:FireServer(
            getgenv().W424_Config.GiveUpId,
            "GiveUpOwnership",
            item,
            "~v0,0,0"
        )
    end)
    return ok
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Remote Drag v5",
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
    Values = {"PickUp", "Store", "Unstore"},
    DefaultValue = getgenv().W424_Config.Mode,
    Callback = function(v)
        getgenv().W424_Config.Mode = v
        status("Mode: " .. v .. " | " .. (getgenv().W424_Config.Active and "ON" or "OFF"))
    end
})

-- Toggle
Tabs.Main:AddToggle({
    Title = "Start Auto",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then DraggedItem = nil end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Auto", state and "Started" or "Stopped", 2)
    end
})

-- Input: AttemptDrag ID
Tabs.Main:AddInput({
    Title = "AttemptDrag ID",
    Default = tostring(getgenv().W424_Config.AttemptDragId),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.AttemptDragId = n end
    end
})

-- Input: GiveUp ID
Tabs.Main:AddInput({
    Title = "GiveUpOwnership ID",
    Default = tostring(getgenv().W424_Config.GiveUpId),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.GiveUpId = n end
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
    Title = "🔍 Scan Items (DebrisField)",
    Callback = function()
        local items = getItems()
        local msg = "Found " .. #items .. " items:\n"
        for i = 1, math.min(8, #items) do
            local parentName = items[i].Parent and items[i].Parent.Name or "nil"
            msg = msg .. items[i].Name .. " [" .. parentName .. "]\n"
        end
        notify("Debug", #items .. " items found", 2)
        status(msg)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Test Remote Connection",
    Callback = function()
        local ok1 = pcall(function() LocalizationService:WaitForChild("RemoteEvent", 2) end)
        local ok2 = pcall(function() LocalizationService:WaitForChild("RemoteFunction", 2) end)
        notify("Debug", "Event: " .. (ok1 and "OK" or "FAIL") .. " | Function: " .. (ok2 and "OK" or "FAIL"), 3)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Test Drag Nearest Item",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        
        local items = getItems()
        local nearest = nil
        local minDist = math.huge
        
        for _, part in ipairs(items) do
            local dist = (part.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = part
            end
        end
        
        if nearest then
            hrp.CFrame = nearest.CFrame + Vector3.new(0, 4, 0)
            task.wait(0.2)
            local ok = attemptDrag(nearest)
            notify("Test", ok and "Drag sent to " .. nearest.Name or "Drag failed!", 3)
            DraggedItem = ok and nearest or nil
        else
            notify("Test", "No items found!", 3)
        end
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Test Drop Current Item",
    Callback = function()
        if DraggedItem then
            local ok = giveUpOwnership(DraggedItem)
            notify("Test", ok and "Dropped!" or "Drop failed!", 3)
            DraggedItem = nil
        else
            notify("Test", "No item being dragged!", 3)
        end
    end
})

-- ==========================================
-- MAIN LOOP
-- ==========================================
task.spawn(function()
    while not getgenv().W424_Kill do
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
        -- MODE: PICK UP
        -- ==========================================
        if mode == "PickUp" then
            local ok, err = pcall(function()
                -- Jika sedang drag item, bawa ke raft lalu drop
                if DraggedItem and DraggedItem.Parent then
                    if not getgenv().W424_Config.RaftCF then
                        status("Raft position not set!")
                        getgenv().W424_Config.Active = false
                        return
                    end
                    
                    status("Moving to raft with " .. DraggedItem.Name .. "...")
                    hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                    task.wait(0.4)
                    
                    -- Drop item
                    giveUpOwnership(DraggedItem)
                    DraggedItem = nil
                    status("Item dropped at raft!")
                    task.wait(0.6)
                    return
                end
                
                -- Cari item baru
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
                    return
                end
                
                status("Going to: " .. target.Name)
                
                -- Teleport ke item
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                
                -- Remote Drag!
                local dragged = attemptDrag(target)
                if dragged then
                    DraggedItem = target
                    status("Dragging " .. target.Name .. "!")
                else
                    status("Drag failed on " .. target.Name)
                end
                
                task.wait(0.3)
            end)
            
            if not ok then
                warn("[PickUp Error]", err)
                DraggedItem = nil
            end
            
        -- ==========================================
        -- MODE: STORE
        -- ==========================================
        elseif mode == "Store" then
            local ok, err = pcall(function()
                if DraggedItem and DraggedItem.Parent then
                    if not getgenv().W424_Config.StorageCF then
                        status("Storage position not set!")
                        getgenv().W424_Config.Active = false
                        return
                    end
                    
                    status("Moving to storage...")
                    hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 4, 0)
                    task.wait(0.4)
                    
                    giveUpOwnership(DraggedItem)
                    DraggedItem = nil
                    status("Item stored!")
                    task.wait(0.6)
                    return
                end
                
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
                    status("No items found")
                    return
                end
                
                status("Going to: " .. target.Name)
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                
                local dragged = attemptDrag(target)
                if dragged then
                    DraggedItem = target
                    status("Dragging to storage!")
                else
                    status("Drag failed")
                end
                
                task.wait(0.3)
            end)
            
            if not ok then
                warn("[Store Error]", err)
                DraggedItem = nil
            end
            
        -- ==========================================
        -- MODE: UNSTORE
        -- ==========================================
        elseif mode == "Unstore" then
            local ok, err = pcall(function()
                if DraggedItem and DraggedItem.Parent then
                    if not getgenv().W424_Config.RaftCF then
                        status("Raft position not set!")
                        DraggedItem = nil
                        return
                    end
                    
                    status("Moving to raft...")
                    hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                    task.wait(0.4)
                    
                    giveUpOwnership(DraggedItem)
                    DraggedItem = nil
                    status("Item placed at raft!")
                    task.wait(0.6)
                    return
                end
                
                if not getgenv().W424_Config.StorageCF then
                    status("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 5, 0)
                task.wait(0.4)
                
                local nearby = getItemsNearStorage()
                if #nearby == 0 then
                    status("No items at storage")
                    task.wait(1.5)
                    return
                end
                
                local item = nearby[1]
                status("Taking: " .. item.Name)
                
                hrp.CFrame = item.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)
                
                local dragged = attemptDrag(item)
                if dragged then
                    DraggedItem = item
                    status("Dragging to raft!")
                else
                    status("Drag failed")
                end
                
                task.wait(0.3)
            end)
            
            if not ok then
                warn("[Unstore Error]", err)
                DraggedItem = nil
            end
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v5", "LocalizationService Remote loaded!", 4)
status("Ready | Mode: PickUp | OFF")
