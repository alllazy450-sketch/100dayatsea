-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (NATIVE UI & DRAG TARGET)
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

getgenv().W424_Sea = {
    AutoHarpoon = false,
    HarpoonRadius = 150,
    AutoCollect = false,
    CollectRadius = 80,
    TargetDestination = "Crafting", -- "Crafting" atau "Campfire"
}

-- ==========================================
-- 1. NATIVE UI SYSTEM (ANTI-ERROR 404)
-- ==========================================
if CoreGui:FindFirstChild("W424_NativeHub") then
    CoreGui.W424_NativeHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424_NativeHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Tombol Melayang
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0, 60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 200)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "⚡"
ToggleBtn.TextSize = 24
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- Panel Utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 200)
MainFrame.Position = UDim2.new(0, 70, 0, 60)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "W424 Hub | Loot & Drag"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Fungsi Pembuat Tombol UI
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
Title.LayoutOrder = 1

local function CreateToggle(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name .. ": OFF"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.LayoutOrder = order
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = name .. (state and ": ON" or ": OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
        callback(state)
    end)
end

local function CreateButton(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(170, 85, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.LayoutOrder = order
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- UI Toggles
CreateToggle("Auto Harpoon", 2, function(v) getgenv().W424_Sea.AutoHarpoon = v end)
CreateToggle("Auto Drag to Target", 3, function(v) getgenv().W424_Sea.AutoCollect = v end)

local TargetBtn = CreateButton("Target: Crafting", 4, function()
    if getgenv().W424_Sea.TargetDestination == "Crafting" then
        getgenv().W424_Sea.TargetDestination = "Campfire"
    else
        getgenv().W424_Sea.TargetDestination = "Crafting"
    end
end)
TargetBtn.MouseButton1Click:Connect(function()
    TargetBtn.Text = "Target: " .. getgenv().W424_Sea.TargetDestination
end)

-- Dragging UI Logic
local dragging, dragStart, startPos = false, nil, nil
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
ToggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- 2. LOGIC GAME (HARPOON & DRAG TARGET)
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

-- AUTO HARPOON
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if not getgenv().W424_Sea.AutoHarpoon then return end
            local hrp = getHRP()
            if not hrp then return end
            
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if not tool then return end
            
            local remote = tool:FindFirstChildOfClass("RemoteEvent")
            if not remote then return end

            local radius = getgenv().W424_Sea.HarpoonRadius or 150
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= char then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= radius then
                            remote:FireServer(obj)
                            task.wait(0.1)
                        end
                    end
                end
            end
        end)
    end
end)

-- AUTO COLLECT & DRAG
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not getgenv().W424_Sea.AutoCollect then return end
            local hrp = getHRP()
            if not hrp then return end

            local startPos = hrp.CFrame
            local radius = getgenv().W424_Sea.CollectRadius or 80

            for _, obj in ipairs(CollectionService:GetTagged("Floating_Object")) do
                if not getgenv().W424_Sea.AutoCollect then break end
                
                local part = nil
                if obj:IsA("BasePart") then
                    part = obj
                elseif obj:IsA("Model") then
                    part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                end

                if part then
                    local dist = (part.Position - startPos.Position).Magnitude
                    if dist <= radius and part.Position.Y < 148 then
                        
                        -- Tentukan titik akhir tujuan
                        local destinationCF = startPos + Vector3.new(0, 3, 0)
                        if getgenv().W424_Sea.TargetDestination == "Crafting" then
                            destinationCF = startPos + Vector3.new(-3, 3, 0)
                        elseif getgenv().W424_Sea.TargetDestination == "Campfire" then
                            destinationCF = startPos + Vector3.new(3, 3, 0)
                        end

                        -- Teleport ke item
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.2)
                        
                        -- Sentuh item (Drag Mode)
                        firetouchinterest(hrp, part, 0)
                        firetouchinterest(hrp, part, 1)
                        task.wait(0.1)
                        
                        -- Tween bawa item ke titik tujuan
                        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = destinationCF})
                        local partTween = TweenService:Create(part, tweenInfo, {CFrame = destinationCF + Vector3.new(0, 0, -2)})
                        
                        tween:Play()
                        partTween:Play()
                        partTween.Completed:Wait()
                        
                        -- Drop item
                        firetouchinterest(hrp, part, 1)
                        task.wait(0.2)
                        
                        break 
                    end
                end
            end
        end)
    end
end)
