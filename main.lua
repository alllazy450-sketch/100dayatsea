-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — DEX EDITION
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
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
-- KONFIGURASI
-- ==========================================
getgenv().W424_Config = {
    Mode = "RaftCamp",
    Active = false,
    SearchRadius = 400,
    ShootCooldown = 1.5,
    PullTimeout = 4,
    DropDistance = 12,
    HarpoonName = "Harpoon",
}

-- ==========================================
-- STATE
-- ==========================================
local CurrentTarget = nil
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
    
    local harpoonName = string.lower(getgenv().W424_Config.HarpoonName or "Harpoon")
    
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == harpoonName then
            return v
        end
    end
    
    for _, v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name) == harpoonName then
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

local function unequipTools()
    pcall(function()
        local hum = getHumanoid()
        if hum then hum:UnequipTools() end
    end)
end

-- ==========================================
-- SCAN ITEM (FIXED — DARI DEX INFO)
-- Item adalah Model dengan PrimaryPart (bukan BasePart langsung)
-- ==========================================
local function getItems()
    local items = {}
    local hrp = getHRP()
    if not hrp then return items end
    
    local playerPos = hrp.Position
    local radius = getgenv().W424_Config.SearchRadius or 400
    
    -- DebrisField — HANYA MODEL dengan PrimaryPart
    local debris = Workspace:FindFirstChild("DebrisField")
    if debris then
        for _, folder in ipairs(debris:GetChildren()) do
            if folder:IsA("Folder") or folder:IsA("Model") then
                for _, child in ipairs(folder:GetChildren()) do
                    -- HANYA proses jika child adalah MODEL dengan PrimaryPart
                    if child:IsA("Model") and child.PrimaryPart then
                        local part = child.PrimaryPart
                        local dist = (part.Position - playerPos).Magnitude
                        if dist <= radius and part.Position.Y < 150 then
                            table.insert(items, {Part = part, Model = child, Distance = dist})
                        end
                    end
                end
            end
        end
    end
    
    -- Floating_Object — HANYA MODEL dengan PrimaryPart
    for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
        if obj and obj.Parent then
            if obj:IsA("Model") and obj.PrimaryPart then
                local part = obj.PrimaryPart
                local dist = (part.Position - playerPos).Magnitude
                if dist <= radius and part.Position.Y < 150 then
                    table.insert(items, {Part = part, Model = obj, Distance = dist})
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(items, function(a, b) return a.Distance < b.Distance end)
    
    return items
end

-- Fire harpoon ke MODEL item (bukan part)
local function shootHarpoon(tool, itemModel)
    if not tool or not itemModel or not itemModel.Parent then return false end
    
    local remote = tool:FindFirstChildOfClass("RemoteEvent")
    if not remote then return false end
    
    -- Fire ke MODEL (bukan part), sesuai remote spy asli
    local ok = pcall(function()
        remote:FireServer(itemModel)
    end)
    
    return ok
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Dex Edition",
    Icon = "rbxassetid://0"
})

local Tabs = {
    Main = Window:AddTab("Auto"),
    Settings = Window:AddTab("Settings"),
    Dex = Window:AddTab("Dex Info"),
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
    Values = {"RaftCamp", "StorageCamp", "FreeFire"},
    DefaultValue = getgenv().W424_Config.Mode,
    Callback = function(v)
        getgenv().W424_Config.Mode = v
        status("Mode: " .. v)
    end
})

-- Toggle
Tabs.Main:AddToggle({
    Title = "Start Auto Sniper",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then
            CurrentTarget = nil
            unequipTools()
        end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Harpoon Sniper", state and "Locked and loaded!" or "Stopped", 2)
    end
})

-- ==========================================
-- SETTINGS
-- ==========================================
Tabs.Settings:AddInput({
    Title = "Search Radius",
    Default = tostring(getgenv().W424_Config.SearchRadius),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.SearchRadius = n end
    end
})

Tabs.Settings:AddInput({
    Title = "Shoot Cooldown (sec)",
    Default = tostring(getgenv().W424_Config.ShootCooldown),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.ShootCooldown = n end
    end
})

Tabs.Settings:AddInput({
    Title = "Drop Distance",
    Default = tostring(getgenv().W424_Config.DropDistance),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.DropDistance = n end
    end
})

-- ==========================================
-- DEX INFO TAB (EKSPLORASI DRAGSYSTEM)
-- ==========================================
local DexPara = Tabs.Dex:AddParagraph({
    Title = "Dex Explorer",
    Content = "Click buttons below to explore game systems",
})

Tabs.Dex:AddButton({
    Title = "🔍 Scan DragSystem Module",
    Callback = function()
        local dragSys = ReplicatedStorage:FindFirstChild("Modules")
            and ReplicatedStorage.Modules:FindFirstChild("Systems")
            and ReplicatedStorage.Modules.Systems:FindFirstChild("DragSystem")
        
        if dragSys then
            local info = "DragSystem found!\nClass: " .. dragSys.ClassName .. "\n"
            if dragSys:IsA("ModuleScript") then
                info = info .. "Type: ModuleScript\n"
                -- Coba require (hati-hati)
                local ok, result = pcall(function()
                    return require(dragSys)
                end)
                if ok and result then
                    info = info .. "Loaded successfully!\n"
                    -- List functions/properties
                    for k, v in pairs(result) do
                        info = info .. "- " .. tostring(k) .. " (" .. type(v) .. ")\n"
                    end
                else
                    info = info .. "Load failed: " .. tostring(result) .. "\n"
                end
            elseif dragSys:IsA("RemoteEvent") then
                info = info .. "Type: RemoteEvent\nCan be fired!"
            elseif dragSys:IsA("RemoteFunction") then
                info = info .. "Type: RemoteFunction\nCan be invoked!"
            end
            DexPara:SetDesc(info)
            notify("Dex", "DragSystem scanned", 2)
        else
            DexPara:SetDesc("DragSystem not found in ReplicatedStorage.Modules.Systems")
            notify("Dex", "DragSystem not found", 2)
        end
    end
})

Tabs.Dex:AddButton({
    Title = "🔍 List Floating Item Models",
    Callback = function()
        local assets = ReplicatedStorage:FindFirstChild("Assets")
        local models = assets and assets:FindFirstChild("Floating_Item_Models")
        
        if models then
            local info = "Floating Item Models:\n"
            for _, model in ipairs(models:GetChildren()) do
                local hasPlank = model:FindFirstChild("Plank") and "✓" or "✗"
                info = info .. "- " .. model.Name .. " [Plank:" .. hasPlank .. "]\n"
            end
            DexPara:SetDesc(info)
            notify("Dex", #models:GetChildren() .. " models found", 2)
        else
            DexPara:SetDesc("Path not found: ReplicatedStorage.Assets.Floating_Item_Models")
        end
    end
})

Tabs.Dex:AddButton({
    Title = "🔍 Scan Workspace Items (Fixed)",
    Callback = function()
        local items = getItems()
        local info = "Found " .. #items .. " valid items:\n"
        for i = 1, math.min(8, #items) do
            info = info .. items[i].Model.Name .. " (" .. math.floor(items[i].Distance) .. "m)\n"
        end
        DexPara:SetDesc(info)
        notify("Dex", #items .. " items scanned", 2)
    end
})

Tabs.Dex:AddButton({
    Title = "🧪 Test Shoot Nearest (Model)",
    Callback = function()
        local harpoon = equipHarpoon()
        if not harpoon then
            notify("Error", "Harpoon not found!", 3)
            return
        end
        
        local items = getItems()
        if #items == 0 then
            notify("Error", "No items!", 3)
            return
        end
        
        local target = items[1].Model
        local ok = shootHarpoon(harpoon, target)
        notify("Test", ok and "Shot at " .. target.Name or "Failed!", 3)
    end
})

-- ==========================================
-- MAIN LOOP
-- ==========================================
task.spawn(function()
    while not getgenv().W424_Kill do
        task.wait(0.2)
        
        if not getgenv().W424_Config.Active then
            continue
        end
        
        local hrp = getHRP()
        if not hrp then
            status("No character")
            continue
        end
        
        if tick() - LastShootTime < (getgenv().W424_Config.ShootCooldown or 1.5) then
            continue
        end
        
        -- Equip harpoon
        local harpoon = equipHarpoon()
        if not harpoon then
            status("Harpoon not found!")
            getgenv().W424_Config.Active = false
            continue
        end
        
        -- If pulling item
        if CurrentTarget and CurrentTarget.Parent then
            local dist = (CurrentTarget.Position - hrp.Position).Magnitude
            status("Pulling " .. CurrentTarget.Name .. " (" .. math.floor(dist) .. "m)")
            
            if dist <= (getgenv().W424_Config.DropDistance or 12) then
                unequipTools()
                status("Dropped!")
                CurrentTarget = nil
                task.wait(0.5)
                continue
            end
            
            if tick() - LastShootTime > (getgenv().W424_Config.PullTimeout or 4) then
                unequipTools()
                status("Timeout — skipping")
                CurrentTarget = nil
                task.wait(0.3)
                continue
            end
            
            continue
        end
        
        -- Find & shoot
        local items = getItems()
        if #items == 0 then
            status("No targets in range")
            continue
        end
        
        local targetModel = items[1].Model
        local targetPart = items[1].Part
        local targetDist = items[1].Distance
        
        if targetDist < 5 then
            status("Too close — skipping")
            task.wait(0.5)
            continue
        end
        
        status("Locking: " .. targetModel.Name .. " (" .. math.floor(targetDist) .. "m)")
        
        -- SHOOT KE MODEL (bukan part)
        local fired = shootHarpoon(harpoon, targetModel)
        
        if fired then
            CurrentTarget = targetPart
            LastShootTime = tick()
            status("Fired! Pulling " .. targetModel.Name .. "...")
        else
            status("Shoot failed!")
            task.wait(0.5)
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub | Dex Edition", "Model-based scan loaded!", 4)
status("Ready | Mode: RaftCamp | OFF")
