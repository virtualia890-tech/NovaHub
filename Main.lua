-- ====================================================================
--                      FLOQUITAVE HUB (v3.1.0)
-- ====================================================================

-- [SERVICES]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [CONFIGURATIONS & STATE]
local HubConfig = {
    AutoFarm = false,
    AutoQuest = false,
    FastAttack = true,
    BringMobs = false,
    NoClip = false,
    SelectedWeapon = "Melee",
    TargetMob = nil,
    FarmDistance = 5,
    Theme = "Dark"
}

local Themes = {
    Dark = { Background = Color3.fromRGB(25, 25, 25), Secondary = Color3.fromRGB(35, 35, 35), Accent = Color3.fromRGB(0, 170, 255), Text = Color3.fromRGB(255, 255, 255) },
    Purple = { Background = Color3.fromRGB(20, 15, 30), Secondary = Color3.fromRGB(30, 25, 45), Accent = Color3.fromRGB(150, 50, 250), Text = Color3.fromRGB(255, 255, 255) },
    Red = { Background = Color3.fromRGB(25, 15, 15), Secondary = Color3.fromRGB(40, 20, 20), Accent = Color3.fromRGB(255, 50, 50), Text = Color3.fromRGB(255, 255, 255) },
    Cyan = { Background = Color3.fromRGB(15, 25, 30), Secondary = Color3.fromRGB(20, 35, 45), Accent = Color3.fromRGB(0, 230, 230), Text = Color3.fromRGB(255, 255, 255) }
}

-- [INTERFACE CREATION]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FloquitaveHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 380)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
MainFrame.BackgroundColor3 = Themes[HubConfig.Theme].Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Themes[HubConfig.Theme].Secondary
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "Floquitave Hub <font color='#00AAFF'>v3.1.0</font>"
Title.RichText = true
Title.TextColor3 = Themes[HubConfig.Theme].Text
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar

-- Navigation Container
local Navigation = Instance.new("Frame")
Navigation.Name = "Navigation"
Navigation.Size = UDim2.new(0, 130, 1, -40)
Navigation.Position = UDim2.new(0, 0, 0, 40)
Navigation.BackgroundColor3 = Themes[HubConfig.Theme].Secondary
Navigation.BorderSizePixel = 0
Navigation.Parent = MainFrame

local UIListLayoutNav = Instance.new("UIListLayout")
UIListLayoutNav.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayoutNav.Padding = UDim.new(0, 5)
UIListLayoutNav.Parent = Navigation

-- Content Container
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -140, 1, -50)
ContentFrame.Position = UDim2.new(0, 135, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- [CORE FUNCTIONS]

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- NoClip System
RunService.Stepped:Connect(function()
    if HubConfig.NoClip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Helper: Fast Attack
local function PerformFastAttack()
    if not HubConfig.FastAttack then return end
    pcall(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

-- Teleport Function
local function TeleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end
end

-- Auto Farm Loop
task.spawn(function()
    while task.wait() do
        if HubConfig.AutoFarm then
            pcall(function()
                -- Lógica principal do Auto Farm / Target
                if HubConfig.TargetMob and HubConfig.TargetMob:FindFirstChild("HumanoidRootPart") then
                    local targetCFrame = HubConfig.TargetMob.HumanoidRootPart.CFrame
                    TeleportTo(targetCFrame * CFrame.new(0, HubConfig.FarmDistance, 0))
                    PerformFastAttack()
                end
            end)
        end
    end
end)

-- [UI BUILDER HELPERS]
local Tabs = {}

local function CreateTab(name)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(1, -10, 0, 35)
    TabButton.Position = UDim2.new(0, 5, 0, 0)
    TabButton.BackgroundColor3 = Themes[HubConfig.Theme].Background
    TabButton.Text = name
    TabButton.TextColor3 = Themes[HubConfig.Theme].Text
    TabButton.Font = Enum.Font.Gotham
    TabButton.TextSize = 14
    TabButton.BorderSizePixel = 0
    TabButton.Parent = Navigation
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabButton

    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 4
    Page.Parent = ContentFrame
    
    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = Page

    TabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Page.Visible = false
            tab.Button.BackgroundColor3 = Themes[HubConfig.Theme].Background
        end
        Page.Visible = true
        TabButton.BackgroundColor3 = Themes[HubConfig.Theme].Accent
    end)

    Tabs[name] = { Button = TabButton, Page = Page }
    
    -- Seleciona a primeira aba criada por padrão
    if #Navigation:GetChildren() == 2 then
        Page.Visible = true
        TabButton.BackgroundColor3 = Themes[HubConfig.Theme].Accent
    end

    return Page
end

-- [POPULATING TABS]
local FarmPage     = CreateTab("Main Farm")
local TeleportPage = CreateTab("Teleports")
local RaidsPage    = CreateTab("Raids/Sea")
local MiscPage     = CreateTab("Misc/Settings")

print("Floquitave Hub v3.1.0 carregado com sucesso!")
