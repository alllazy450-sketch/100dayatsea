-- ==========================================
-- W424 HUB | 100 DAYS AT SEA — HARPOON SILENT AIM v8
-- Pendekatan A: CFrame Aimbot + Tool Activate
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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
    Mode = "PickUp",          -- "PickUp" (ke raft) | "Store" (ke storage)
    Active = false,
    SearchRadius = 500,
    ShootCooldown = 2,
    PullTimeout = 6,
    DropDistance = 15,
    HarpoonName = "Harpoon",
    AutoAim = true,           -- Arahkan CFrame ke item
    AutoActivate = true,      -- Trigger tool:Activate()
    SmoothAim = false,        -- true = smooth rotate, false = instant snap
    AimSpeed = 0.3,           -- Speed smooth aim (0-1)
}

-- ==========================================
-- STATE
-- ==========================================
local CurrentItem = nil
local LastShootTime = 0
local AimConnection = nil

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

local function getCamera()
    return Workspace.CurrentCamera
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
    local radius = getgenv().W424_Config.SearchRadius or 500

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
-- AIMBOT SYSTEM
-- ==========================================
local function aimAtItem(itemPart)
    if not itemPart or not itemPart.Parent then return false end

    local hrp = getHRP()
    if not hrp then return false end

    local targetPos = itemPart.Position
    local hrpPos = hrp.Position

    -- Buat CFrame yang menghadap ke item (tapi jaga posisi Y agar tidak nunduk/nengad)
    local lookCFrame = CFrame.new(hrpPos, Vector3.new(targetPos.X, hrpPos.Y, targetPos.Z))

    if getgenv().W424_Config.SmoothAim then
        -- Smooth rotate
        local speed = getgenv().W424_Config.AimSpeed or 0.3
        hrp.CFrame = hrp.CFrame:Lerp(lookCFrame, speed)
    else
        -- Instant snap
        hrp.CFrame = lookCFrame
    end

    -- Juga arahkan kamera ke item (penting untuk raycast harpoon)
    local cam = getCamera()
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
    end

    return true
end

-- ==========================================
-- SHOOT SYSTEM
-- ==========================================
local function shootHarpoon(harpoonTool, itemModel)
    if not harpoonTool or not itemModel then return false end

    -- Method 1: Tool Activate (paling umum)
    if getgenv().W424_Config.AutoActivate then
        local ok = pcall(function()
            harpoonTool:Activate()
        end)
        if ok then return true end
    end

    -- Method 2: Fire equipped tool remote
    local ok = pcall(function()
        local remote = harpoonTool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            remote:FireServer(itemModel)
        end
    end)
    if ok then return true end

    -- Method 3: Coba cari BindableEvent/Function
    local ok = pcall(function()
        for _, v in ipairs(harpoonTool:GetDescendants()) do
            if v:IsA("BindableEvent") then
                v:Fire(itemModel)
            elseif v:IsA("BindableFunction") then
                v:Invoke(itemModel)
            end
        end
    end)

    return ok
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | Silent Aim v8",
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
    Title = "Start Silent Aim",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.Active = state
        if not state then
            CurrentItem = nil
            if AimConnection then AimConnection:Disconnect(); AimConnection = nil end
            unequipTools()
        end
        status("Mode: " .. getgenv().W424_Config.Mode .. " | " .. (state and "ON" or "OFF"))
        notify("Silent Aim", state and "Activated!" or "Stopped", 2)
    end
})

-- ==========================================
-- SETTINGS
-- ==========================================
Tabs.Settings:AddToggle({
    Title = "Auto Aim (Snap to target)",
    Default = true,
    Callback = function(state)
        getgenv().W424_Config.AutoAim = state
    end
})

Tabs.Settings:AddToggle({
    Title = "Auto Activate Tool",
    Default = true,
    Callback = function(state)
        getgenv().W424_Config.AutoActivate = state
    end
})

Tabs.Settings:AddToggle({
    Title = "Smooth Aim",
    Default = false,
    Callback = function(state)
        getgenv().W424_Config.SmoothAim = state
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

Tabs.Settings:AddInput({
    Title = "Shoot Cooldown",
    Default = tostring(getgenv().W424_Config.ShootCooldown),
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424_Config.ShootCooldown = n end
    end
})

-- ==========================================
-- DEBUG TAB
-- ==========================================
Tabs.Debug:AddButton({
    Title = "🔍 Scan Items",
    Callback = function()
        local items = getItems()
        local msg = "Found " .. #items .. " items:
"
        for i = 1, math.min(6, #items) do
            msg = msg .. items[i].Model.Name .. " (" .. math.floor(items[i].Distance) .. "m)
"
        end
        status(msg)
        notify("Debug", #items .. " items found", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Equip Harpoon",
    Callback = function()
        local tool = equipHarpoon()
        notify("Debug", tool and "Equipped: " .. tool.Name or "Not found!", 2)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Aim at Nearest",
    Callback = function()
        local items = getItems()
        if #items == 0 then notify("Error", "No items!", 3); return end

        local ok = aimAtItem(items[1].Part)
        notify("Test", ok and "Aimed at " .. items[1].Model.Name or "Failed!", 3)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Shoot (Activate Tool)",
    Callback = function()
        local harpoon = equipHarpoon()
        if not harpoon then notify("Error", "No harpoon!", 3); return end

        local ok = pcall(function() harpoon:Activate() end)
        notify("Test", ok and "Activated!" or "Activate failed!", 3)
    end
})

Tabs.Debug:AddButton({
    Title = "🧪 Full Test (Aim + Shoot)",
    Callback = function()
        local items = getItems()
        if #items == 0 then notify("Error", "No items!", 3); return end

        local harpoon = equipHarpoon()
        if not harpoon then notify("Error", "No harpoon!", 3); return end

        -- Aim
        aimAtItem(items[1].Part)
        task.wait(0.2)

        -- Shoot
        local ok = shootHarpoon(harpoon, items[1].Model)
        notify("Test", ok and "Fired at " .. items[1].Model.Name or "Failed!", 3)
    end
})

Tabs.Debug:AddButton({
    Title = "🔍 Inspect Harpoon Tool",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end

        local harpoon = nil
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and string.lower(v.Name) == string.lower(getgenv().W424_Config.HarpoonName) then
                harpoon = v
                break
            end
        end

        if not harpoon then
            notify("Error", "Equip harpoon first!", 3)
            return
        end

        local info = "Harpoon: " .. harpoon.Name .. "
"
        info = info .. "Class: " .. harpoon.ClassName .. "
"
        info = info .. "Children:
"

        for _, v in ipairs(harpoon:GetDescendants()) do
            info = info .. "- " .. v.Name .. " [" .. v.ClassName .. "]
"
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
        task.wait(0.15)

        if not getgenv().W424_Config.Active then continue end

        local hrp = getHRP()
        if not hrp then status("No character"); continue end

        if tick() - LastShootTime < (getgenv().W424_Config.ShootCooldown or 2) then continue end

        -- Equip harpoon
        local harpoon = equipHarpoon()
        if not harpoon then status("Harpoon not found!"); getgenv().W424_Config.Active = false; continue end

        -- ==========================================
        -- STATE: PULLING ITEM
        -- ==========================================
        if CurrentItem and CurrentItem.Parent then
            local dist = (CurrentItem.PrimaryPart.Position - hrp.Position).Magnitude
            status("Pulling " .. CurrentItem.Name .. " (" .. math.floor(dist) .. "m)")

            -- Keep aiming at item while pulling
            if getgenv().W424_Config.AutoAim then
                aimAtItem(CurrentItem.PrimaryPart)
            end

            -- Check if close enough to drop
            if dist <= (getgenv().W424_Config.DropDistance or 15) then
                unequipTools()
                status("Dropped " .. CurrentItem.Name .. "!")
                CurrentItem = nil
                task.wait(0.8)
                continue
            end

            -- Timeout
            if tick() - LastShootTime > (getgenv().W424_Config.PullTimeout or 6) then
                unequipTools()
                status("Timeout — dropping")
                CurrentItem = nil
                task.wait(0.4)
                continue
            end

            continue
        end

        -- ==========================================
        -- STATE: FIND & SHOOT NEW TARGET
        -- ==========================================
        local items = getItems()
        if #items == 0 then status("No items in range"); continue end

        local target = items[1]
        if target.Distance < 5 then status("Too close"); task.wait(0.5); continue end

        status("Locking: " .. target.Model.Name .. " (" .. math.floor(target.Distance) .. "m)")

        -- AIM
        if getgenv().W424_Config.AutoAim then
            aimAtItem(target.Part)
            task.wait(0.1)
        end

        -- SHOOT
        local fired = shootHarpoon(harpoon, target.Model)

        if fired then
            CurrentItem = target.Model
            LastShootTime = tick()
            status("Fired! Pulling " .. target.Model.Name .. "...")
        else
            status("Shoot failed!")
            task.wait(0.5)
        end
    end
end)

-- ==========================================
-- INIT
-- ==========================================
notify("W424 Hub v8", "Silent Aim loaded!", 4)
status("Ready | Mode: PickUp | OFF")
