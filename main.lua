-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — LOCALIZATION REMOTE v6
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- REMOTE REFERENCES (DARI REMOTE SPY!)
-- ==========================================
local RemoteEvent = LocalizationService:WaitForChild("RemoteEvent")
local RemoteFunction = LocalizationService:WaitForChild("RemoteFunction")

-- ==========================================
-- KONFIGURASI
-- ==========================================
getgenv().W424_Config = {
    -- ID dari remote spy (UPDATE jika berubah!)
    AttemptDragId = 315265,
    GiveUpId = 316175,
    
    Mode = "PickUp",
    Active = false,
    SearchRadius = 400,
    ShootCooldown = 1.5,
    PullTimeout = 5,
    DropDistance = 12,
    HarpoonName = "Harpoon",
}

-- ==========================================
-- STATE
-- ==========================================
local CurrentItem = nil
local LastShootTime = 0

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
    
    local name = string.lower(getgenv().W424_Config.HarpoonName or "Harpoon")
    
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == name then return v end
    end
    
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == name then
            local hum = getHumanoid()
            if hum then hum:EquipTool(v); task.wait(0.4); return v end
        end
    end
    return nil
end

local function unequipTools()
    pcall(function()
        local hum = getHumanoid()
        if hum then hum:UnequipTools() end
    end)
end

-- Scan item (Model dengan PrimaryPart)
local function getItems()
    local items = {}
    local hrp = getHRP()
    if not hrp then return items end
    
    local pos = hrp.Position
    local radius = getgenv().W424_Config.SearchRadius or 400
    
    local debris = Workspace:FindFirstChild("DebrisField")
    if debris then
        for _, folder in ipairs(debris:GetChildren()) do
            if folder:IsA("Folder") or folder:IsA("Model") then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Model") and child.PrimaryPart then
                        local part = child.PrimaryPart
                        local dist = (part.Position - pos).Magnitude
                        if dist <= radius and part.Position.Y < 150 then
                            table.insert(items, {Model = child, Part = part, Distance = dist})
                        end
                    end
                end
            end
        end
    end
    
    for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
        if obj and obj.Parent and obj:IsA("Model") and obj.PrimaryPart then
            local part = obj.PrimaryPart
            local dist = (part.Position - pos).Magnitude
            if dist <= radius and part.Position.Y < 150 then
                table.insert(items, {Model = obj, Part = part, Distance = dist})
            end
        end
    end
    
    table.sort(items, function(a, b) return a.Distance < b.Distance end)
    return items
end

-- ==========================================
-- REMOTE FUNCTIONS (VIA LOCALIZATIONSERVICE!)
-- ==========================================
local function attemptDrag(itemModel)
    if not itemModel or not itemModel.Parent then return false end
    local ok = pcall(function()
        RemoteFunction:InvokeServer(
            getgenv().W424_Config.AttemptDragId,
            "AttemptDrag",
            itemModel
        )
    end)
    return ok
end

local function giveUpOwnership(itemModel)
    if not itemModel or not itemModel.Parent then return false end
    local ok = pcall(function()
        RemoteEvent:FireServer(
            getgenv().W424_Config.GiveUpId,
            "GiveUpOwnership",
            itemModel,
            "~v0,0,0"
        )
    end)
    return ok
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Localization Remote v6",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Main = Window:AddTab("Auto"),
    Settings = Window:AddTab("Settings"),
    Debug = Window:AddTab("Debug"),
}

local StatusPara = Tabs.Main:AddParagraph({
    Title = "Status",
    Content = "Ready | OFF",
})

local function status(txt)
    pcall(function() StatusPara:SetDesc(txt) end)
end

-- Mode
Tabs.Main:AddDropdown({
    Title = "Mode",
    Values = {"PickUp", "Store"},
    DefaultValue = getgenv().W424_Config.Mode,
    Callback = function(v)
        getgenv().W424_Config.Mode = v
        status("Mode: " .. v)
    end
})

-- Toggle
Tabs.Main:AddToggle({
    Title = "Start Auto Farm",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then CurrentItem = nil; unequipTools() end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Auto", state and "Started!" or "Stopped", 2)
    end
})

-- ==========================================
-- SETTINGS
-- ==========================================
Tabs.Settings:AddInput({
    Title = "AttemptDrag ID",
    Default = tostring(getgenv().W424_Config.AttemptDragId),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.AttemptDragId = n end
    end
})

Tabs.Settings:AddInput({
    Title = "GiveUpOwnership ID",
    Default = tostring(getgenv().W424_Config.GiveUpId),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.GiveUpId = n end
    end
})

Tabs.Settings:AddInput({
    Title = "Search Radius",
    Default = tostring(getgenv().W424_Config.SearchRadius),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.SearchRadius = n end
    end
})

-- ==========================================
-- DEBUG TAB
-- ==========================================
Tabs.Debug:AddButton({
    Title = "🔍 Scan Items",
    Callback = function()
        local items = getItems()
        local msg = "Found " .. #items .. " items:\n"
        for i = 1, math.min(6, #items) do
            msg = msg .. items[i].Model.Name .. " (" .. math.floor(items[i].Distance) .. "m)\n"
        end
        status(msg)
        notify("Debug", #items .. " items", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Equip Harpoon",
    Callback = function()
        local tool = equipHarpoon()
        notify("Debug", tool and "Equipped!" or "Not found!", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Drag Nearest (Remote)",
    Callback = function()
        local items = getItems()
        if #items == 0 then notify("Error", "No items!", 3); return end
        
        local target = items[1].Model
        local ok = attemptDrag(target)
        notify("Test", ok and "Drag sent to " .. target.Name or "Failed!", 3)
        if ok then CurrentItem = target end
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Drop Current (Remote)",
    Callback = function()
        if not CurrentItem then notify("Error", "No item dragged!", 3); return end
        local ok = giveUpOwnership(CurrentItem)
        notify("Test", ok and "Dropped!" or "Failed!", 3)
        if ok then CurrentItem = nil; unequipTools() end
    end
})

Tabs.Debug:AddButton({
    Title = "🔍 Get IDs from DragSystem",
    Callback = function()
        local ok, DragSystem = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Systems"):WaitForChild("DragSystem"))
        end)
        
        if not ok or not DragSystem then
            notify("Error", "DragSystem not loaded!", 3)
            return
        end
        
        local info = "DragSystem loaded!\n"
        
        if DragSystem.Network then
            info = info .. "\nNetwork table:\n"
            for k, v in pairs(DragSystem.Network) do
                info = info .. "- " .. tostring(k) .. " (" .. type(v) .. ")\n"
            end
        end
        
        status(info)
        notify("Debug", "Check Status for details", 3)
    end
})

-- ==========================================
-- MAIN LOOP
-- ==========================================
task.spawn(function()
    while not getgenv().W424_Kill do
        task.wait(0.2)
        
        if not getgenv().W424_Config.Active then continue end
        
        local hrp = getHRP()
        if not hrp then status("No character"); continue end
        
        if tick() - LastShootTime < (getgenv().W424_Config.ShootCooldown or 1.5) then continue end
        
        -- Equip harpoon (visual only)
        local harpoon = equipHarpoon()
        if not harpoon then status("Harpoon not found!"); getgenv().W424_Config.Active = false; continue end
        
        -- If dragging item
        if CurrentItem and CurrentItem.Parent then
            local dist = (CurrentItem.PrimaryPart.Position - hrp.Position).Magnitude
            status("Pulling " .. CurrentItem.Name .. " (" .. math.floor(dist) .. "m)")
            
            if dist <= (getgenv().W424_Config.DropDistance or 12) then
                giveUpOwnership(CurrentItem)
                unequipTools()
                status("Dropped " .. CurrentItem.Name .. "!")
                CurrentItem = nil
                task.wait(0.6)
                continue
            end
            
            if tick() - LastShootTime > (getgenv().W424_Config.PullTimeout or 5) then
                giveUpOwnership(CurrentItem)
                unequipTools()
                status("Timeout — dropping")
                CurrentItem = nil
                task.wait(0.3)
                continue
            end
            
            continue
        end
        
        -- Find new target
        local items = getItems()
        if #items == 0 then status("No items in range"); continue end
        
        local target = items[1]
        if target.Distance < 5 then status("Too close"); task.wait(0.5); continue end
        
        status("Targeting: " .. target.Model.Name .. " (" .. math.floor(target.Distance) .. "m)")
        
        -- FIRE REMOTE DRAG!
        local fired = attemptDrag(target.Model)
        
        if fired then
            CurrentItem = target.Model
            LastShootTime = tick()
            status("Dragged " .. target.Model.Name .. "!")
        else
            status("Drag failed!")
            task.wait(0.5)
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v6", "LocalizationService Remote loaded!", 4)
status("Ready | Mode: PickUp | OFF")
