-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — REMOTE DRAG SYSTEM v3
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
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
-- REMOTE REFERENCES (DARI REMOTE SPY)
-- ==========================================
local ChatService = game:GetService("Chat")
local RemoteEvent = ChatService:WaitForChild("RemoteEvent")
local RemoteFunction = ChatService:WaitForChild("RemoteFunction")

-- ==========================================
-- KONFIGURASI
-- ==========================================
getgenv().W424_Config = {
    RaftCF = nil,
    StorageCF = nil,
    ItemSearchRadius = 300,
    Mode = "PickUp",      -- "PickUp" | "Store" | "Unstore"
    Active = false,
    Delay = 0.8,
    
    -- Remote Args (dari Cobalt Spy)
    AttemptDragId = 339152,
    StoreId = 339351,
    DropId = 339183,
}

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
        if obj:IsA("BasePart") and obj ~= hrp then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist <= 20 then
                local n = string.lower(obj.Name)
                -- Hindari part environment & player
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
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Remote Drag v3",
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

local DebugPara = Tabs.Debug:AddParagraph({
    Title = "Debug",
    Content = "Idle",
})

local function status(txt)
    StatusPara:SetDesc(txt)
end

local function debug(txt)
    DebugPara:SetDesc(txt)
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
        local msg = "Found " .. #items .. " items:\n"
        for i = 1, math.min(5, #items) do
            msg = msg .. items[i].Name .. "\n"
        end
        debug(msg)
        notify("Debug", #items .. " items found", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🔍 Test Remote Connection",
    Callback = function()
        local ok1 = pcall(function() ChatService:WaitForChild("RemoteEvent", 2) end)
        local ok2 = pcall(function() ChatService:WaitForChild("RemoteFunction", 2) end)
        debug("RemoteEvent: " .. (ok1 and "OK" or "FAIL") .. "\nRemoteFunction: " .. (ok2 and "OK" or "FAIL"))
        notify("Debug", "Remote check done", 2)
    end
})

-- ==========================================
-- MAIN LOOP — REMOTE DRAG SYSTEM
-- ==========================================
task.spawn(function()
    while true do
        if getgenv().W424_Kill then break end
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
        -- MODE: PICK UP (Drag item → Raft → Drop)
        -- ==========================================
        if mode == "PickUp" then
            local ok, err = pcall(function()
                -- 1. Cari item terdekat
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
                
                status("Dragging: " .. target.Name)
                
                -- 2. Teleport ke item
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                
                -- 3. REMOTE DRAG — AttemptDrag ke INSTANCE ITEM
                local dragSuccess = pcall(function()
                    RemoteFunction:InvokeServer(
                        getgenv().W424_Config.AttemptDragId,
                        "AttemptDrag",
                        target
                    )
                end)
                
                if not dragSuccess then
                    status("Drag failed — trying touch...")
                    -- Fallback: coba touch
                    pcall(function()
                        firetouchinterest(hrp, target, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, target, 1)
                    end)
                end
                
                task.wait(0.3)
                
                -- 4. Bawa item ke Raft (set CFrame item ikut player)
                if not getgenv().W424_Config.RaftCF then
                    status("Raft position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                status("Moving to raft...")
                
                -- Teleport bertahap sambil bawa item
                for i = 1, 5 do
                    if not getgenv().W424_Config.Active then break end
                    local t = getgenv().W424_Config.RaftCF:Lerp(hrp.CFrame, i/5)
                    hrp.CFrame = t
                    pcall(function()
                        if target and target.Parent then
                            target.CFrame = hrp.CFrame - Vector3.new(0, 2, 0)
                            target.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                    task.wait(0.05)
                end
                
                hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                task.wait(0.2)
                
                -- 5. DROP ITEM — pakai remote DropItem
                pcall(function()
                    RemoteEvent:FireServer(getgenv().W424_Config.DropId, "DropItem")
                end)
                
                -- Backup: GiveUpOwnership jika DropItem tidak cukup
                pcall(function()
                    if target and target.Parent then
                        RemoteEvent:FireServer(
                            getgenv().W424_Config.StoreId,
                            "GiveUpOwnership",
                            target,
                            "~v0,0,0"
                        )
                    end
                end)
                
                status("Item dropped at raft")
                task.wait(0.6)
            end)
            
            if not ok then
                warn("[PickUp Error]", err)
                status("Error: " .. tostring(err))
            end
            
        -- ==========================================
        -- MODE: STORE (Drag item → Storage → Store)
        -- ==========================================
        elseif mode == "Store" then
            local ok, err = pcall(function()
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
                
                status("Dragging: " .. target.Name)
                
                -- Teleport ke item
                hrp.CFrame = target.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.3)
                
                -- AttemptDrag
                pcall(function()
                    RemoteFunction:InvokeServer(
                        getgenv().W424_Config.AttemptDragId,
                        "AttemptDrag",
                        target
                    )
                end)
                
                task.wait(0.3)
                
                -- Ke Storage
                if not getgenv().W424_Config.StorageCF then
                    status("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                status("Moving to storage...")
                
                for i = 1, 5 do
                    if not getgenv().W424_Config.Active then break end
                    local t = getgenv().W424_Config.StorageCF:Lerp(hrp.CFrame, i/5)
                    hrp.CFrame = t
                    pcall(function()
                        if target and target.Parent then
                            target.CFrame = hrp.CFrame - Vector3.new(0, 2, 0)
                            target.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                    task.wait(0.05)
                end
                
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 3, 0)
                task.wait(0.3)
                
                -- STORE — pakai remote StoreItem
                pcall(function()
                    if target and target.Parent then
                        RemoteEvent:FireServer(
                            getgenv().W424_Config.StoreId,
                            "StoreItem",
                            target
                        )
                        task.wait(0.2)
                        RemoteEvent:FireServer(
                            getgenv().W424_Config.StoreId,
                            "GiveUpOwnership",
                            target,
                            "~v0,0,0"
                        )
                    end
                end)
                
                status("Item stored!")
                task.wait(0.6)
            end)
            
            if not ok then
                warn("[Store Error]", err)
                status("Error: " .. tostring(err))
            end
            
        -- ==========================================
        -- MODE: UNSTORE (Ambil dari storage → Raft)
        -- ==========================================
        elseif mode == "Unstore" then
            local ok, err = pcall(function()
                if not getgenv().W424_Config.StorageCF then
                    status("Storage position not set!")
                    getgenv().W424_Config.Active = false
                    return
                end
                
                status("Going to storage...")
                hrp.CFrame = getgenv().W424_Config.StorageCF + Vector3.new(0, 5, 0)
                task.wait(0.5)
                
                -- Cari item di sekitar storage
                local nearby = getItemsNearStorage()
                
                if #nearby == 0 then
                    status("No items at storage")
                    task.wait(1.5)
                    return
                end
                
                local item = nearby[1]
                status("Taking: " .. item.Name)
                
                -- AttemptDrag dari storage
                pcall(function()
                    RemoteFunction:InvokeServer(
                        getgenv().W424_Config.AttemptDragId,
                        "AttemptDrag",
                        item
                    )
                end)
                
                task.wait(0.3)
                
                -- Ke Raft
                if not getgenv().W424_Config.RaftCF then
                    status("Raft position not set!")
                    return
                end
                
                status("Moving to raft...")
                
                for i = 1, 5 do
                    if not getgenv().W424_Config.Active then break end
                    local t = getgenv().W424_Config.RaftCF:Lerp(hrp.CFrame, i/5)
                    hrp.CFrame = t
                    pcall(function()
                        if item and item.Parent then
                            item.CFrame = hrp.CFrame - Vector3.new(0, 2, 0)
                            item.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)
                    task.wait(0.05)
                end
                
                hrp.CFrame = getgenv().W424_Config.RaftCF + Vector3.new(0, 5, 0)
                task.wait(0.2)
                
                -- Drop
                pcall(function()
                    RemoteEvent:FireServer(getgenv().W424_Config.DropId, "DropItem")
                end)
                
                pcall(function()
                    if item and item.Parent then
                        RemoteEvent:FireServer(
                            getgenv().W424_Config.StoreId,
                            "GiveUpOwnership",
                            item,
                            "~v0,0,0"
                        )
                    end
                end)
                
                status("Item placed at raft")
                task.wait(0.6)
            end)
            
            if not ok then
                warn("[Unstore Error]", err)
                status("Error: " .. tostring(err))
            end
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v3", "Remote Drag System loaded!", 4)
status("Ready | Mode: PickUp | OFF")
debug("Click 'Test Remote Connection' to verify.")
