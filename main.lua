-- ==========================================
-- W424 HUB | 100 DAYS AT SEA (PURE MOBILE UI)
-- ==========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().W424 = {
    AutoHarpoon = false,
    HarpoonRad = 150,
    AutoCollect = false
}

-- Hapus UI lama jika ada
if CoreGui:FindFirstChild("W424_MobileUI") then
    CoreGui.W424_MobileUI:Destroy()
end

-- Buat ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424_MobileUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Tombol Mengapung untuk Buka/Tutup Menu
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 110, 0, 40)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 200)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "W424 Menu"
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

-- Main Frame Menu
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 220)
MainFrame.Position = UDim2.new(0, 20, 0, 150)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Judul Menu
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "W424 Hub | Sea Edition"
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- Tombol Buka/Tutup
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Fungsi Bikin Toggle Button di Dalam Menu
local function createButton(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name .. ": OFF"
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            btn.Text = name .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.Text = name .. ": OFF"
        end
        callback(state)
    end)
end

-- Tambah Fitur ke Menu
createButton("Auto Harpoon / Shark", 45, function(v)
    getgenv().W424.AutoHarpoon = v
end)

createButton("Auto Collect Items", 90, function(v)
    getgenv().W424.AutoCollect = v
end)

-- ==========================================
-- LOGIC UTAMA (HARPOON & COLLECT)
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end

            -- 1. Auto Harpoon
            if getgenv().W424.AutoHarpoon then
                for _, mob in ipairs(Workspace:GetDescendants()) do
                    if mob:IsA("Model") and (mob.Name:find("Shark") or mob.Name:find("Creature") or mob.Name:find("Fish")) then
                        local part = mob:FindFirstChildWhichIsA("BasePart")
                        if part and (hrp.Position - part.Position).Magnitude <= getgenv().W424.HarpoonRad then
                            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool then
                                tool:Activate()
                                local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Attack")
                                if remote then remote:FireServer(mob) end
                            end
                        end
                    end
                end
            end

            -- 2. Auto Collect
            if getgenv().W424.AutoCollect then
                for _, item in ipairs(Workspace:GetChildren()) do
                    if item:IsA("Model") and (item.Name:find("Log") or item.Name:find("Wood") or item.Name:find("Barrel") or item.Name:find("Box")) then
                        local part = item:FindFirstChildWhichIsA("BasePart")
                        if part then
                            part.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                            part.Velocity = Vector3.zero
                        end
                    end
                end
            end
        end)
    end
end)

print("W424 Pure Mobile UI Loaded Successfully!")
