--[[
    FLOQUITAVE HUB
    Version: 3.1.0
    UI / Player / Teleport Directory / Themes / Server Info
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Name = "Floquitave",
    Version = "3.1.0",
    Width = 920,
    Height = 590,
    Animations = true,
    Notifications = true,
    Theme = "Dark",
    Scale = 1,
    Accent = Color3.fromRGB(115, 90, 255),
    PerformanceInterval = 0.5
}

--==================================================
-- STATE
--==================================================

local State = {
    CurrentPage = "Home",
    Minimized = false,
    Destroyed = false,
    FPS = 0,
    Ping = 0,
    SearchText = "",
    Connections = {},
    Pages = {},
    PageButtons = {},
    Cards = {},
    Toggles = {},
    PlayerSettings = {
        WalkSpeed = 16,
        JumpPower = 50
    }
}

local StartTime = os.clock()

--==================================================
-- THEMES
--==================================================

local Themes = {
    Dark = {
        Background = Color3.fromRGB(12, 12, 18),
        Sidebar = Color3.fromRGB(16, 16, 24),
        Card = Color3.fromRGB(21, 21, 31),
        Secondary = Color3.fromRGB(28, 28, 40),
        Text = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(155, 155, 175),
        Accent = Color3.fromRGB(115, 90, 255)
    },
    Light = {
        Background = Color3.fromRGB(238, 239, 244),
        Sidebar = Color3.fromRGB(248, 248, 252),
        Card = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(225, 226, 233),
        Text = Color3.fromRGB(30, 30, 40),
        SubText = Color3.fromRGB(100, 100, 115),
        Accent = Color3.fromRGB(95, 75, 220)
    }
}

local Theme = Themes[Config.Theme] or Themes.Dark

--==================================================
-- UTILITIES & CONNECTION SYSTEM
--==================================================

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(State.Connections, connection)
    return connection
end

local function Tween(object, properties, duration, style, direction)
    if not Config.Animations then
        for property, value in pairs(properties) do
            object[property] = value
        end
        return
    end

    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )

    TweenService:Create(object, info, properties):Play()
end

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function Corner(object, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function Stroke(object, color, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Secondary,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

local function Padding(object, amount)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, amount),
        PaddingBottom = UDim.new(0, amount),
        PaddingLeft = UDim.new(0, amount),
        PaddingRight = UDim.new(0, amount)
    }, object)
end

local function AddHoverEffect(button)
    local scale = Create("UIScale", { Scale = 1 }, button)

    Connect(button.MouseEnter, function()
        Tween(scale, { Scale = 1.025 }, 0.18, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseLeave, function()
        Tween(scale, { Scale = 1 }, 0.18, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseButton1Down, function()
        Tween(scale, { Scale = 0.97 }, 0.08, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseButton1Up, function()
        Tween(scale, { Scale = 1.025 }, 0.1, Enum.EasingStyle.Sine)
    end)
end

--==================================================
-- SERVICES
--==================================================

local PlayerService = {}

function PlayerService:GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function PlayerService:SetWalkSpeed(value)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = value
        State.PlayerSettings.WalkSpeed = value
        return true
    end
    return false
end

function PlayerService:SetJumpPower(value)
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = value
        State.PlayerSettings.JumpPower = value
        return true
    end
    return false
end

--==================================================
-- GUI INIT (SAFE)
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "Floquitave_3_1",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Proteção de GUI segura e universal para executores modernos
local success, parent = pcall(function()
    return gethui and gethui() or game:GetService("CoreGui")
end)

if success and parent then
    ScreenGui.Parent = parent
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Create("Frame", {
    Size = UDim2.new(0, Config.Width, 0, Config.Height),
    Position = UDim2.new(0.5, -Config.Width / 2, 0.5, -Config.Height / 2),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
}, ScreenGui)

Corner(Main, 16)
Stroke(Main, Theme.Secondary, 0.15)

-- TOPBAR
local Topbar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Main)

Corner(Topbar, 16)

local Logo = Create("TextLabel", {
    Position = UDim2.new(0, 18, 0, 9),
    Size = UDim2.new(0, 40, 0, 40),
    BackgroundColor3 = Theme.Accent,
    Text = "F",
    Font = Enum.Font.GothamBlack,
    TextSize = 21,
    TextColor3 = Color3.new(1, 1, 1)
}, Topbar)

Corner(Logo, 11)

local Title = Create("TextLabel", {
    Position = UDim2.new(0, 70, 0, 10),
    Size = UDim2.new(0, 250, 0, 23),
    BackgroundTransparency = 1,
    Text = Config.Name,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local Close = Create("TextButton", {
    Position = UDim2.new(1, -50, 0, 13),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = Theme.Secondary,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Theme.Text,
    AutoButtonColor = false
}, Topbar)

Corner(Close, 8)
AddHoverEffect(Close)

Connect(Close.MouseButton1Click, function()
    ScreenGui:Destroy()
end)

-- BODY
local Body = Create("Frame", {
    Position = UDim2.new(0, 0, 0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
}, Main)

Corner(Body, 16)

local Sidebar = Create("Frame", {
    Size = UDim2.new(0, 220, 1, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
}, Body)

Corner(Sidebar, 16)

local Content = Create("ScrollingFrame", {
    Position = UDim2.new(0, 232, 0, 10),
    Size = UDim2.new(1, -242, 1, -20),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Body)

-- PAGE SYSTEM
local PageService = {}

function PageService:Create(name)
    local page = Create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y
    }, Content)

    Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    State.Pages[name] = page
    return page
end

function PageService:Show(name)
    for pageName, otherPage in pairs(State.Pages) do
        otherPage.Visible = (pageName == name)
    end
    State.CurrentPage = name
end

-- NAVIGATION BUTTONS
local PageList = Create("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 14),
    Size = UDim2.new(1, -20, 1, -24),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Sidebar)

Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, PageList)

local function AddNavButton(name)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Secondary,
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        AutoButtonColor = false
    }, PageList)

    Corner(btn, 8)
    AddHoverEffect(btn)

    Connect(btn.MouseButton1Click, function()
        PageService:Show(name)
    end)
end

-- PAGES SETUP
local Home = PageService:Create("Home")
local PlayerPage = PageService:Create("Player")
local TeleportPage = PageService:Create("Teleport")

AddNavButton("Home")
AddNavButton("Player")
AddNavButton("Teleport")

-- HOME CONTENT
local HomeLabel = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text = "Bem-vindo ao Floquitave Hub!",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, Home)

-- TELEPORT PAGE HOLDER (FIXED ENDING)
local TeleportHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y
}, TeleportPage)

-- Show default home page
PageService:Show("Home")
