-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — PHYSICAL DRAG v4
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ANTI-DOUBLE LOAD
-- ==========================================
if getgenv().W424_Running then
    getgenv().W424_Running = false
    task.wait(1)
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
    Mode = "PickUp",
    Active = false,
    Delay = 0.1,           -- Loop cepat untuk smooth follow
    FollowOffset = Vector3.new(0, -2, 2), -- Posisi item relatif ke player
}

-- ==========================================
-- STATE
-- ==========================================
local DraggedItem = nil
local FollowConnection = nil

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

local function getItemsNearStorage()
    local hrp = getHRP()
    if not hrp then return {} end
    local items = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj ~= hrp and not obj:IsDescendantOf(LocalPlayer.Character) then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist <= 18 then
                local n = string.lower(obj.Name)
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
-- DRAG SYSTEM (FISIK)
-- ==========================================
local function startFollowing(item)
    if FollowConnection then FollowConnection:Disconnect() end
    DraggedItem = item
    
    FollowConnection = RunService.Heartbeat:Connect(function()
        if not getgenv().W424_Running then
            FollowConnection:Disconnect()
            return
        end
        if DraggedItem and DraggedItem.Parent then
            local hrp = getHRP()
            if hrp then
                DraggedItem.CFrame = hrp.CFrame + getgenv().W424_Config.FollowOffset
                DraggedItem.AssemblyLinearVelocity = Vector3.zero
                DraggedItem.AssemblyAngularVelocity = Vector3.zero
                DraggedItem.CanCollide = false
            end
        else
            DraggedItem = nil
        end
    end)
end

local function stopFollowing()
    if FollowConnection then
        FollowConnection:Disconnect()
        FollowConnection = nil
    end
    if DraggedItem and DraggedItem.Parent then
        DraggedItem.CanCollide = true
        DraggedItem.AssemblyLinearVelocity = Vector3.zero
    end
    DraggedItem = nil
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Physical Drag v4",
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
local AutoToggle
AutoToggle = Tabs.Main:AddToggle({
    Title = "Start Auto",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then
            stopFollowing()
        end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Auto", state and "Started" or "Stopped", 2)
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
    Title = "🔍 Scan Floating Items",
    Callback = function()
        local items = getFloatingItems()
        notify("Debug", #items .. " floating items found", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🛑 Emergency Stop Drag",
    Callback = function()
        stopFollowing()
        getgenv().W424_Config.Active = false
        pcall(function() AutoToggle:SetValue(false) end)
        notify("Emergency", "Drag stopped!", 2)
    end
})

-- ==========================================
-- MAIN LOOP — PHYSICAL DRAG
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
        -- MODE: PICK UP
        -- ==========================================
        if mode == "PickUp" then
            local ok, err = pcall(function()
                -- Jika sedang drag, lanjutkan ke raft
                if DraggedItem and DraggedItem.Parent then
                    if not getgenv().W424_Config.RaftCF then
                        status("Raft position not set!")
                        getgenv().W424_Config.Active = false
                        stopFollowing()
                        return
                    end
                    
                    status("Moving to raft with item...")
                    hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                    task.wait(0.5)
                    
                    -- Lepas item di raft
                    stopFollowing()
                    task.wait(0.3)
                    status("Item dropped at raft")
                    task.wait(0.5)
                    return
                end
                
                -- Cari item baru
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
                    status("No items in radius")
                    return
                end
                
                status("Grabbing: " .. target.Name)
                
                -- Teleport ke item
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.2)
                
                -- Pick up via touch
                pcall(function()
                    firetouchinterest(hrp, target, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, target, 1)
                end)
                
                task.wait(0.2)
                
                -- Mulai follow (bawa item)
                startFollowing(target)
                status("Dragging " .. target.Name .. " to raft...")
            end)
            
            if not ok then
                warn("[PickUp Error]", err)
                stopFollowing()
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
                        stopFollowing()
                        return
                    end
                    
                    status("Moving to storage...")
                    hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 3, 0)
                    task.wait(0.5)
                    
                    stopFollowing()
                    task.wait(0.3)
                    status("Item stored!")
                    task.wait(0.5)
                    return
                end
                
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
                    status("No items found")
                    return
                end
                
                status("Grabbing: " .. target.Name)
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.2)
                
                pcall(function()
                    firetouchinterest(hrp, target, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, target, 1)
                end)
                
                task.wait(0.2)
                startFollowing(target)
                status("Dragging to storage...")
            end)
            
            if not ok then
                warn("[Store Error]", err)
                stopFollowing()
            end
            
        -- ==========================================
        -- MODE: UNSTORE
        -- ==========================================
        elseif mode == "Unstore" then
            local ok, err = pcall(function()
                if DraggedItem and DraggedItem.Parent then
                    if not getgenv().W424_Config.RaftCF then
                        status("Raft position not set!")
                        stopFollowing()
                        return
                    end
                    
                    status("Moving to raft...")
                    hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                    task.wait(0.5)
                    
                    stopFollowing()
                    task.wait(0.3)
                    status("Item placed at raft")
                    task.wait(0.5)
                    return
                end
                
                if not getgenv().W424_Config.StorageCF then
                    status("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                -- Ke storage
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 5, 0)
                task.wait(0.4)
                
                -- Cari item di sekitar
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
                
                pcall(function()
                    firetouchinterest(hrp, item, 0)
                    task.wait(0.1)
                    firetouchinterest(hrp, item, 1)
                end)
                
                task.wait(0.2)
                startFollowing(item)
                status("Dragging to raft...")
            end)
            
            if not ok then
                warn("[Unstore Error]", err)
                stopFollowing()
            end
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v4", "Physical Drag loaded! No remote needed.", 4)
status("Ready | Mode: PickUp | OFF")
