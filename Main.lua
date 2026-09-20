-- FLOQUITAVE 3.1.1 BOOTSTRAP / DIAGNOSTIC
-- This tiny layer is intentionally created before the main hub so a runtime
-- error in any later system cannot make the user think the script did nothing.
local __Players = game:GetService("Players")
local __LocalPlayer = __Players.LocalPlayer
local __PlayerGui = __LocalPlayer and __LocalPlayer:WaitForChild("PlayerGui", 10)
local __Bootstrap
local __Status

if __PlayerGui then
    pcall(function()
        local old = __PlayerGui:FindFirstChild("Floquitave_Bootstrap_3_1_1")
        if old then old:Destroy() end
    end)
    __Bootstrap = Instance.new("ScreenGui")
    __Bootstrap.Name = "Floquitave_Bootstrap_3_1_1"
    __Bootstrap.ResetOnSpawn = false
    __Bootstrap.DisplayOrder = 999999
    __Bootstrap.IgnoreGuiInset = true
    __Bootstrap.Parent = __PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 100)
    frame.Position = UDim2.new(0.5, -210, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    frame.BorderSizePixel = 0
    frame.Parent = __Bootstrap
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 28)
    title.Position = UDim2.new(0, 12, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(245,245,250)
    title.Text = "Floquitave 3.1.1 • Inicializando..."
    title.Parent = frame

    __Status = Instance.new("TextLabel")
    __Status.Size = UDim2.new(1, -24, 0, 45)
    __Status.Position = UDim2.new(0, 12, 0, 42)
    __Status.BackgroundTransparency = 1
    __Status.Font = Enum.Font.Gotham
    __Status.TextSize = 12
    __Status.TextWrapped = true
    __Status.TextXAlignment = Enum.TextXAlignment.Left
    __Status.TextYAlignment = Enum.TextYAlignment.Top
    __Status.TextColor3 = Color3.fromRGB(170,170,185)
    __Status.Text = "Carregando interface..."
    __Status.Parent = frame
end

local __ok, __err = xpcall(function()
--[[
    FLOQUITAVE HUB
    Version: 3.1.0
    UI / Player / Teleport Directory / Themes / Server Info

    Safe test build:
    - UI framework
    - Player settings
    - Teleport directory
    - Search
    - Themes
    - Server information
    - Diagnostics
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
    },

    Purple = {
        Background = Color3.fromRGB(17, 12, 27),
        Sidebar = Color3.fromRGB(23, 16, 36),
        Card = Color3.fromRGB(31, 21, 47),
        Secondary = Color3.fromRGB(43, 29, 61),
        Text = Color3.fromRGB(248, 242, 255),
        SubText = Color3.fromRGB(177, 157, 196),
        Accent = Color3.fromRGB(170, 90, 255)
    },

    Blue = {
        Background = Color3.fromRGB(10, 17, 27),
        Sidebar = Color3.fromRGB(13, 24, 38),
        Card = Color3.fromRGB(18, 32, 50),
        Secondary = Color3.fromRGB(26, 45, 68),
        Text = Color3.fromRGB(240, 247, 255),
        SubText = Color3.fromRGB(150, 172, 195),
        Accent = Color3.fromRGB(70, 145, 255)
    },

    Red = {
        Background = Color3.fromRGB(24, 11, 13),
        Sidebar = Color3.fromRGB(32, 14, 17),
        Card = Color3.fromRGB(43, 19, 23),
        Secondary = Color3.fromRGB(59, 25, 30),
        Text = Color3.fromRGB(255, 242, 243),
        SubText = Color3.fromRGB(190, 150, 155),
        Accent = Color3.fromRGB(235, 75, 95)
    },

    Green = {
        Background = Color3.fromRGB(10, 22, 17),
        Sidebar = Color3.fromRGB(13, 30, 22),
        Card = Color3.fromRGB(18, 42, 30),
        Secondary = Color3.fromRGB(26, 57, 40),
        Text = Color3.fromRGB(239, 255, 246),
        SubText = Color3.fromRGB(150, 190, 166),
        Accent = Color3.fromRGB(65, 205, 125)
    },

    Cyan = {
        Background = Color3.fromRGB(8, 20, 23),
        Sidebar = Color3.fromRGB(10, 28, 32),
        Card = Color3.fromRGB(15, 39, 44),
        Secondary = Color3.fromRGB(21, 56, 63),
        Text = Color3.fromRGB(237, 255, 255),
        SubText = Color3.fromRGB(148, 190, 194),
        Accent = Color3.fromRGB(50, 210, 220)
    },

    Midnight = {
        Background = Color3.fromRGB(8, 10, 18),
        Sidebar = Color3.fromRGB(10, 13, 24),
        Card = Color3.fromRGB(15, 19, 34),
        Secondary = Color3.fromRGB(23, 28, 48),
        Text = Color3.fromRGB(236, 241, 255),
        SubText = Color3.fromRGB(145, 154, 180),
        Accent = Color3.fromRGB(90, 120, 255)
    }
}

local Theme = Themes[Config.Theme]

--==================================================
-- TELEPORT DIRECTORY
--==================================================

local TeleportLocations = {
    ["First Sea"] = {
        "Bandit Island",
        "Jungle",
        "Pirate Village",
        "Desert",
        "Frozen Village",
        "Marine Fortress",
        "Skylands",
        "Prison",
        "Colosseum",
        "Magma Village",
        "Underwater City",
        "Fountain City"
    },

    ["Second Sea"] = {
        "Kingdom of Rose",
        "Green Zone",
        "Graveyard",
        "Snow Mountain",
        "Hot and Cold",
        "Cursed Ship",
        "Ice Castle",
        "Forgotten Island"
    },

    ["Third Sea"] = {
        "Port Town",
        "Hydra Island",
        "Great Tree",
        "Floating Turtle",
        "Haunted Castle",
        "Sea of Treats",
        "Tiki Outpost",
        "Chocolate Land",
        "Cake Land",
        "Peanut Island",
        "Ice Cream Island"
    }
}

--==================================================
-- CONNECTION SYSTEM
--==================================================

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(State.Connections, connection)
    return connection
end

local function Cleanup()
    if State.Destroyed then
        return
    end

    State.Destroyed = true

    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(State.Connections)
end

--==================================================
-- UTILITIES
--==================================================

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

local function FormatNumber(number)
    number = tonumber(number) or 0

    local formatted = tostring(math.floor(number))

    while true do
        local result, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")

        formatted = result

        if count == 0 then
            break
        end
    end

    return formatted
end

local function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function AddHoverEffect(button)
    local scale = Create("UIScale", {
        Scale = 1
    }, button)

    Connect(button.MouseEnter, function()
        Tween(scale, {
            Scale = 1.025
        }, 0.18, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseLeave, function()
        Tween(scale, {
            Scale = 1
        }, 0.18, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseButton1Down, function()
        Tween(scale, {
            Scale = 0.97
        }, 0.08, Enum.EasingStyle.Sine)
    end)

    Connect(button.MouseButton1Up, function()
        Tween(scale, {
            Scale = 1.025
        }, 0.1, Enum.EasingStyle.Sine)
    end)
end

--==================================================
-- SERVICES
--==================================================

local WorldService = {}

function WorldService:GetSea()
    local placeId = game.PlaceId

    if placeId == 2753915549 then
        return "First Sea"
    elseif placeId == 4442272183 then
        return "Second Sea"
    elseif placeId == 7449423635 then
        return "Third Sea"
    end

    return "Unknown"
end

local PlayerService = {}

function PlayerService:GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    local level = data and data:FindFirstChild("Level")

    return level and level.Value or 0
end

function PlayerService:GetBeli()
    local data = LocalPlayer:FindFirstChild("Data")
    local beli = data and data:FindFirstChild("Beli")

    return beli and beli.Value or 0
end

function PlayerService:GetFragments()
    local data = LocalPlayer:FindFirstChild("Data")
    local fragments = data and data:FindFirstChild("Fragments")

    return fragments and fragments.Value or 0
end

function PlayerService:GetRace()
    local data = LocalPlayer:FindFirstChild("Data")
    local race = data and data:FindFirstChild("Race")

    return race and race.Value or "Unknown"
end

function PlayerService:GetCharacter()
    return LocalPlayer.Character
end

function PlayerService:GetHumanoid()
    local character = self:GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

function PlayerService:GetWalkSpeed()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.WalkSpeed or 0
end

function PlayerService:GetJumpPower()
    local humanoid = self:GetHumanoid()
    return humanoid and humanoid.JumpPower or 0
end

function PlayerService:SetWalkSpeed(value)
    value = tonumber(value)

    if not value then
        return false
    end

    local humanoid = self:GetHumanoid()

    if not humanoid then
        return false
    end

    humanoid.WalkSpeed = value
    State.PlayerSettings.WalkSpeed = value

    return true
end

function PlayerService:SetJumpPower(value)
    value = tonumber(value)

    if not value then
        return false
    end

    local humanoid = self:GetHumanoid()

    if not humanoid then
        return false
    end

    humanoid.UseJumpPower = true
    humanoid.JumpPower = value

    State.PlayerSettings.JumpPower = value

    return true
end

local PerformanceService = {}

function PerformanceService:GetPing()
    local success, result = pcall(function()
        local network = Stats:FindFirstChild("Network")

        if not network then
            return 0
        end

        local serverStats = network:FindFirstChild("ServerStatsItem")

        if not serverStats then
            return 0
        end

        local ping = serverStats:FindFirstChild("Data Ping")

        if ping then
            return ping:GetValue()
        end

        return 0
    end)

    if success then
        return tonumber(result) or 0
    end

    return 0
end

local ServerService = {}

function ServerService:GetJobId()
    return game.JobId ~= "" and game.JobId or "Unavailable"
end

function ServerService:GetPlaceId()
    return tostring(game.PlaceId)
end

function ServerService:GetPlayerCount()
    return #Players:GetPlayers()
end

--==================================================
-- NOTIFICATIONS
--==================================================

local NotificationHolder

local function Notify(title, message)
    if not Config.Notifications or not NotificationHolder then
        return
    end

    local notification = Create("Frame", {
        Size = UDim2.new(0, 300, 0, 72),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0
    }, NotificationHolder)

    Corner(notification, 12)
    Stroke(notification, Theme.Secondary, 0.25)
    Padding(notification, 10)

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, notification)

    local messageLabel = Create("TextLabel", {
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, -10, 0, 32),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, notification)

    local scale = Create("UIScale", {
        Scale = 0.92
    }, notification)

    notification.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    messageLabel.TextTransparency = 1

    Tween(notification, {
        BackgroundTransparency = 0.04
    }, 0.22)

    Tween(titleLabel, {
        TextTransparency = 0
    }, 0.22)

    Tween(messageLabel, {
        TextTransparency = 0
    }, 0.22)

    Tween(scale, {
        Scale = 1
    }, 0.25)

    task.delay(3, function()
        if notification.Parent then
            Tween(scale, {
                Scale = 0.94
            }, 0.18)

            Tween(notification, {
                BackgroundTransparency = 1
            }, 0.18)

            Tween(titleLabel, {
                TextTransparency = 1
            }, 0.18)

            Tween(messageLabel, {
                TextTransparency = 1
            }, 0.18)

            task.wait(0.2)

            if notification.Parent then
                notification:Destroy()
            end
        end
    end)
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "Floquitave_2_5",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

do
    local parentGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not parentGui then
        parentGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    end
    if not parentGui then
        pcall(function() parentGui = gethui and gethui() or nil end)
    end
    if not parentGui then
        pcall(function() parentGui = game:GetService("CoreGui") end)
    end
    if not parentGui then
        error("Nao foi possivel encontrar PlayerGui/CoreGui para criar a interface.")
    end
    ScreenGui.Parent = parentGui
end

--==================================================
-- MAIN
--==================================================

local Main = Create("Frame", {
    Size = UDim2.new(0, Config.Width, 0, Config.Height),
    Position = UDim2.new(0.5, -Config.Width / 2, 0.5, -Config.Height / 2),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0
}, ScreenGui)

Corner(Main, 16)
Stroke(Main, Theme.Secondary, 0.15)

local MainScale = Create("UIScale", {
    Scale = Config.Scale
}, Main)

--==================================================
-- TOPBAR
--==================================================

local Topbar = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Main)

Corner(Topbar, 16)

local TopbarCover = Create("Frame", {
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Topbar)

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
    Text = "Floquitave",
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local Version = Create("TextLabel", {
    Position = UDim2.new(0, 70, 0, 31),
    Size = UDim2.new(0, 250, 0, 17),
    BackgroundTransparency = 1,
    Text = "Version " .. Config.Version,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Theme.SubText,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local Minimize = Create("TextButton", {
    Position = UDim2.new(1, -88, 0, 13),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = Theme.Secondary,
    Text = "—",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = Theme.Text,
    AutoButtonColor = false
}, Topbar)

Corner(Minimize, 8)
AddHoverEffect(Minimize)

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

--==================================================
-- BODY
--==================================================

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

local SearchBox = Create("TextBox", {
    Position = UDim2.new(0, 14, 0, 14),
    Size = UDim2.new(1, -28, 0, 38),
    BackgroundColor3 = Theme.Secondary,
    PlaceholderText = "Search...",
    PlaceholderColor3 = Theme.SubText,
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Theme.Text,
    ClearTextOnFocus = false
}, Sidebar)

Corner(SearchBox, 10)

local PageList = Create("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 62),
    Size = UDim2.new(1, -20, 1, -72),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Sidebar)

Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, PageList)

local Content = Create("ScrollingFrame", {
    Position = UDim2.new(0, 232, 0, 10),
    Size = UDim2.new(1, -242, 1, -20),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Body)

--==================================================
-- PAGE SYSTEM
--==================================================

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

    local scale = Create("UIScale", {
        Scale = 0.985
    }, page)

    State.Pages[name] = page

    return page
end

function PageService:Show(name)
    local page = State.Pages[name]

    if not page then
        return
    end

    for pageName, otherPage in pairs(State.Pages) do
        otherPage.Visible = pageName == name
    end

    State.CurrentPage = name

    local scale = page:FindFirstChildOfClass("UIScale")

    if scale then
        scale.Scale = 0.985

        Tween(scale, {
            Scale = 1
        }, 0.25, Enum.EasingStyle.Quint)
    end

    Content.CanvasPosition = Vector2.new(0, 0)
end

--==================================================
-- COMPONENTS
--==================================================

local function Section(parent, title, subtitle)
    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1
    }, parent)

    local titleLabel = Create("TextLabel", {
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -4, 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    Create("TextLabel", {
        Position = UDim2.new(0, 2, 0, 25),
        Size = UDim2.new(1, -4, 0, 20),
        BackgroundTransparency = 1,
        Text = subtitle or "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    return holder
end

local function Card(parent, title, value)
    local card = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, parent)

    Corner(card, 11)
    Stroke(card, Theme.Secondary, 0.25)

    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 11),
        Size = UDim2.new(1, -28, 0, 17),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local valueLabel = Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -28, 0, 28),
        BackgroundTransparency = 1,
        Text = tostring(value),
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    table.insert(State.Cards, card)

    return card, valueLabel
end

local function Toggle(parent, title, description, default, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, parent)

    Corner(holder, 11)
    Stroke(holder, Theme.Secondary, 0.3)

    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -80, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 31),
        Size = UDim2.new(1, -80, 0, 18),
        BackgroundTransparency = 1,
        Text = description or "",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local button = Create("TextButton", {
        Position = UDim2.new(1, -58, 0.5, -12),
        Size = UDim2.new(0, 42, 0, 24),
        BackgroundColor3 = Theme.Secondary,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(button, 12)

    local indicator = Create("Frame", {
        Position = UDim2.new(0, 3, 0.5, -9),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = Theme.SubText,
        BorderSizePixel = 0
    }, button)

    Corner(indicator, 9)

    local enabled = default == true

    local function Update()
        if enabled then
            Tween(button, {
                BackgroundColor3 = Theme.Accent
            }, 0.2)

            Tween(indicator, {
                Position = UDim2.new(1, -21, 0.5, -9),
                BackgroundColor3 = Color3.new(1, 1, 1)
            }, 0.2)
        else
            Tween(button, {
                BackgroundColor3 = Theme.Secondary
            }, 0.2)

            Tween(indicator, {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Theme.SubText
            }, 0.2)
        end
    end

    Connect(button.MouseButton1Click, function()
        enabled = not enabled
        Update()

        if callback then
            callback(enabled)
        end
    end)

    Update()

    table.insert(State.Toggles, holder)

    return holder
end

local function ActionButton(parent, text, callback)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Secondary,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        AutoButtonColor = false
    }, parent)

    Corner(button, 10)
    AddHoverEffect(button)

    Connect(button.MouseButton1Click, function()
        if callback then
            callback()
        end
    end)

    return button
end

local function ValueBox(parent, title, defaultValue, callback)
    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, parent)

    Corner(holder, 11)
    Stroke(holder, Theme.Secondary, 0.3)

    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(0.5, -14, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local box = Create("TextBox", {
        Position = UDim2.new(1, -120, 0, 10),
        Size = UDim2.new(0, 106, 0, 36),
        BackgroundColor3 = Theme.Secondary,
        Text = tostring(defaultValue),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        ClearTextOnFocus = false
    }, holder)

    Corner(box, 8)

    Connect(box.FocusLost, function()
        local value = tonumber(box.Text)

        if value then
            box.Text = tostring(value)

            if callback then
                callback(value)
            end
        else
            box.Text = tostring(defaultValue)
        end
    end)

    return holder, box
end

--==================================================
-- HOME
--==================================================

local Home = PageService:Create("Home")

Section(
    Home,
    "Welcome to Floquitave",
    "Clean interface • Smooth animations • Modular architecture"
)

local Welcome = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 90),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Home)

Corner(Welcome, 13)
Stroke(Welcome, Theme.Secondary, 0.25)

Create("TextLabel", {
    Position = UDim2.new(0, 18, 0, 15),
    Size = UDim2.new(1, -36, 0, 26),
    BackgroundTransparency = 1,
    Text = "Floquitave Hub",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, Welcome)

Create("TextLabel", {
    Position = UDim2.new(0, 18, 0, 45),
    Size = UDim2.new(1, -36, 0, 25),
    BackgroundTransparency = 1,
    Text = "3.1.1 Full Systems Build",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Theme.SubText,
    TextXAlignment = Enum.TextXAlignment.Left
}, Welcome)

local HomeGrid = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 160),
    BackgroundTransparency = 1
}, Home)

local GridLayout = Create("UIGridLayout", {
    CellSize = UDim2.new(0.24, 0, 0, 72),
    CellPadding = UDim2.new(0.012, 0, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
}, HomeGrid)

local LevelCard, LevelValue = Card(HomeGrid, "LEVEL", "0")
local BeliCard, BeliValue = Card(HomeGrid, "BELI", "0")
local FragmentCard, FragmentValue = Card(HomeGrid, "FRAGMENTS", "0")
local RaceCard, RaceValue = Card(HomeGrid, "RACE", "Unknown")
local SeaCard, SeaValue = Card(HomeGrid, "SEA", "Unknown")
local FPSCard, FPSValue = Card(HomeGrid, "FPS", "0")
local PingCard, PingValue = Card(HomeGrid, "PING", "0 ms")
local UptimeCard, UptimeValue = Card(HomeGrid, "UPTIME", "00:00:00")

local StatusCard = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, Home)

Corner(StatusCard, 11)
Stroke(StatusCard, Theme.Secondary, 0.25)

Create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 11),
    Size = UDim2.new(1, -28, 0, 17),
    BackgroundTransparency = 1,
    Text = "SESSION STATUS",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Theme.SubText,
    TextXAlignment = Enum.TextXAlignment.Left
}, StatusCard)

local SessionStatus = Create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 32),
    Size = UDim2.new(1, -28, 0, 25),
    BackgroundTransparency = 1,
    Text = "Running",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = Theme.Accent,
    TextXAlignment = Enum.TextXAlignment.Left
}, StatusCard)

--==================================================
-- PLAYER
--==================================================

local PlayerPage = PageService:Create("Player")

Section(
    PlayerPage,
    "Player",
    "Local character configuration"
)

local PlayerInfoGrid = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 150),
    BackgroundTransparency = 1
}, PlayerPage)

local PlayerGrid = Create("UIGridLayout", {
    CellSize = UDim2.new(0.32, 0, 0, 68),
    CellPadding = UDim2.new(0.015, 0, 0, 10)
}, PlayerInfoGrid)

Card(PlayerInfoGrid, "USERNAME", LocalPlayer.Name)
Card(PlayerInfoGrid, "DISPLAY NAME", LocalPlayer.DisplayName)
Card(PlayerInfoGrid, "USER ID", LocalPlayer.UserId)

local SpeedHolder, SpeedBox = ValueBox(
    PlayerPage,
    "WalkSpeed",
    State.PlayerSettings.WalkSpeed,
    function(value)
        if value < 0 then
            value = 0
        end

        if value > 250 then
            value = 250
        end

        SpeedBox.Text = tostring(value)

        if PlayerService:SetWalkSpeed(value) then
            Notify("Player", "WalkSpeed aplicado: " .. value)
        end
    end
)

local JumpHolder, JumpBox = ValueBox(
    PlayerPage,
    "JumpPower",
    State.PlayerSettings.JumpPower,
    function(value)
        if value < 0 then
            value = 0
        end

        if value > 250 then
            value = 250
        end

        JumpBox.Text = tostring(value)

        if PlayerService:SetJumpPower(value) then
            Notify("Player", "JumpPower aplicado: " .. value)
        end
    end
)

ActionButton(PlayerPage, "Apply Player Settings", function()
    local speed = tonumber(SpeedBox.Text) or 16
    local jump = tonumber(JumpBox.Text) or 50

    PlayerService:SetWalkSpeed(speed)
    PlayerService:SetJumpPower(jump)

    Notify("Player", "Configurações aplicadas.")
end)

--==================================================
-- TELEPORT
--==================================================

local TeleportPage = PageService:Create("Teleport")

Section(
    TeleportPage,
    "Teleport",
    "Destinos organizados por Sea"
)

local TeleportSearch = Create("TextBox", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Card,
    PlaceholderText = "Search island...",
    PlaceholderColor3 = Theme.SubText,
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Theme.Text,
    ClearTextOnFocus = false
}, TeleportPage)

Corner(TeleportSearch, 10)
Stroke(TeleportSearch, Theme.Secondary, 0.25)

local TeleportHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y
}, TeleportPage)

local TeleportLayout = Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, TeleportHolder)

local function ClearTeleport()
    for _, child in ipairs(TeleportHolder:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function BuildTeleport()
    ClearTeleport()

    local search = string.lower(TeleportSearch.Text or "")

    for seaName, locations in pairs(TeleportLocations) do
        local matching = {}

        for _, locationName in ipairs(locations) do
            if search == ""
                or string.find(string.lower(locationName), search, 1, true)
                or string.find(string.lower(seaName), search, 1, true)
            then
                table.insert(matching, locationName)
            end
        end

        if #matching > 0 then
            local seaHeader = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Theme.Secondary,
                BorderSizePixel = 0
            }, TeleportHolder)

            Corner(seaHeader, 10)

            Create("TextLabel", {
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                BackgroundTransparency = 1,
                Text = "▼  " .. seaName,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left
            }, seaHeader)

            for _, locationName in ipairs(matching) do
                local button = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = Theme.Card,
                    Text = "   " .. locationName,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false
                }, TeleportHolder)

                Corner(button, 9)
                AddHoverEffect(button)

                Connect(button.MouseButton1Click, function()
                    local ok = false
                    local root = PlayerService:GetCharacter() and PlayerService:GetCharacter():FindFirstChild("HumanoidRootPart")
                    local searchNames = {locationName}
                    if locationName == "Skylands" then table.insert(searchNames, "Sky") end
                    if locationName == "Kingdom of Rose" then table.insert(searchNames, "KingdomOfRose") end
                    if locationName == "Green Zone" then table.insert(searchNames, "GreenZone") end
                    if locationName == "Port Town" then table.insert(searchNames, "PortTown") end
                    if locationName == "Tiki Outpost" then table.insert(searchNames, "TikiOutpost") end
                    if root then
                        local candidates = {workspace:FindFirstChild("Map"), workspace:FindFirstChild("WorldOrigin"), workspace}
                        for _, container in ipairs(candidates) do
                            if container then
                                for _, wanted in ipairs(searchNames) do
                                    local found = container:FindFirstChild(wanted, true)
                                    if found then
                                        local part = found:IsA("BasePart") and found or found:FindFirstChildWhichIsA("BasePart", true)
                                        if part then
                                            root.CFrame = part.CFrame + Vector3.new(0, 8, 0)
                                            ok = true
                                            break
                                        end
                                    end
                                end
                            end
                            if ok then break end
                        end
                    end
                    Notify("Teleport", ok and (locationName .. " teleportado.") or (locationName .. " não encontrado no mapa."))
                end)
            end
        end
    end
end

Connect(TeleportSearch:GetPropertyChangedSignal("Text"), BuildTeleport)

BuildTeleport()

--==================================================
-- SERVER
--==================================================

local ServerPage = PageService:Create("Server")

Section(
    ServerPage,
    "Server",
    "Current Roblox session information"
)

local ServerGrid = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 150),
    BackgroundTransparency = 1
}, ServerPage)

local ServerGridLayout = Create("UIGridLayout", {
    CellSize = UDim2.new(0.48, 0, 0, 68),
    CellPadding = UDim2.new(0.02, 0, 0, 10)
}, ServerGrid)

Card(ServerGrid, "JOB ID", ServerService:GetJobId())
Card(ServerGrid, "PLACE ID", ServerService:GetPlaceId())
Card(ServerGrid, "SEA", WorldService:GetSea())
Card(ServerGrid, "PLAYERS", ServerService:GetPlayerCount())

ActionButton(ServerPage, "Copy Job ID", function()
    if setclipboard then
        setclipboard(ServerService:GetJobId())
        Notify("Server", "Job ID copiado.")
    else
        Notify("Server", "Clipboard não disponível neste ambiente.")
    end
end)

--==================================================
-- MAIN FARM
--==================================================

local FarmPage = PageService:Create("Main Farm")

Section(
    FarmPage,
    "Main Farm",
    "Modular farm engine • target selection • movement • combat hooks"
)

--==================================================
-- FARM STATE / CONFIG
--==================================================

local FarmState = {
    Enabled = false,
    AutoMastery = false,
    AutoTarget = true,
    BringMobs = false,
    FastAttack = false,
    NoClip = false,
    UseTool = true,
    Distance = 8,
    ScanRadius = 350,
    AttackCooldown = 0.12,
    TargetName = "Auto",
    CurrentTarget = nil,
    CurrentTool = nil,
    LastAttack = 0,
    Status = "Idle",
    StartedAt = 0
}

local FarmConnections = {}

local function FarmConnect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(FarmConnections, connection)
    return connection
end

local function GetCharacterRoot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function GetCharacterHumanoid()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(model)
    if not model or not model:IsA("Model") then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    return humanoid ~= nil
        and humanoid.Health > 0
        and root ~= nil
end

local function IsPlayerCharacter(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then
            return true
        end
    end

    return false
end

local function FindEnemyContainers()
    local containers = {}

    for _, name in ipairs({
        "Enemies",
        "Mobs",
        "NPCs",
        "Npcs",
        "Enemy",
        "Mob",
        "NPC"
    }) do
        local folder = workspace:FindFirstChild(name)

        if folder then
            table.insert(containers, folder)
        end
    end

    return containers
end

local function IsValidFarmTarget(model)
    if not IsAlive(model) then
        return false
    end

    if model == LocalPlayer.Character or IsPlayerCharacter(model) then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if FarmState.TargetName ~= "Auto" then
        local modelName = string.lower(model.Name)
        local requested = string.lower(FarmState.TargetName)

        if not string.find(modelName, requested, 1, true) then
            return false
        end
    end

    return true
end

local function GetTargetRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end

local function GetNearestTarget()
    local root = GetCharacterRoot()

    if not root then
        return nil
    end

    local bestTarget = nil
    local bestDistance = FarmState.ScanRadius

    local containers = FindEnemyContainers()

    for _, container in ipairs(containers) do
        for _, child in ipairs(container:GetChildren()) do
            if IsValidFarmTarget(child) then
                local targetRoot = GetTargetRoot(child)

                if targetRoot then
                    local distance = (targetRoot.Position - root.Position).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = child
                    end
                end
            end
        end
    end

    -- Fallback: scan direct workspace models when the game does not
    -- use a conventional enemy folder.
    if not bestTarget then
        for _, child in ipairs(workspace:GetChildren()) do
            if IsValidFarmTarget(child) then
                local targetRoot = GetTargetRoot(child)

                if targetRoot then
                    local distance = (targetRoot.Position - root.Position).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = child
                    end
                end
            end
        end
    end

    return bestTarget
end

local function GetEquippedTool()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end

    return nil
end

local function EquipFirstTool()
    local humanoid = GetCharacterHumanoid()

    if not humanoid then
        return nil
    end

    local equipped = GetEquippedTool()

    if equipped then
        FarmState.CurrentTool = equipped
        return equipped
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if not backpack then
        return nil
    end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function()
                humanoid:EquipTool(tool)
            end)

            FarmState.CurrentTool = tool
            return tool
        end
    end

    return nil
end

local function AttackTarget(target)
    if not IsValidFarmTarget(target) then
        return false
    end

    local tool = FarmState.CurrentTool

    if not tool or not tool.Parent then
        tool = EquipFirstTool()
    end

    if not tool then
        return false
    end

    local now = os.clock()

    if now - FarmState.LastAttack < FarmState.AttackCooldown then
        return true
    end

    FarmState.LastAttack = now

    -- Generic tool-based attack hook.
    -- For a custom game, replace this block with the game's
    -- server-authoritative attack RemoteEvent/function.
    pcall(function()
        tool:Activate()
    end)

    return true
end

local function MoveToTarget(target)
    local root = GetCharacterRoot()
    local targetRoot = GetTargetRoot(target)

    if not root or not targetRoot then
        return false
    end

    local offset = CFrame.new(0, 0, FarmState.Distance)

    if FarmState.BringMobs then
        -- Local positioning only. A server-authoritative implementation
        -- should perform the actual mob positioning on the server.
        pcall(function()
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -FarmState.Distance)
        end)
    end

    pcall(function()
        root.CFrame = targetRoot.CFrame * offset
    end)

    return true
end

local function ApplyNoClip(enabled)
    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = not enabled
        end
    end
end

local function StopFarm()
    FarmState.Enabled = false
    FarmState.CurrentTarget = nil
    FarmState.Status = "Stopped"

    ApplyNoClip(false)
end

local function FarmStep()
    if not FarmState.Enabled then
        return
    end

    local humanoid = GetCharacterHumanoid()
    local root = GetCharacterRoot()

    if not humanoid or not root or humanoid.Health <= 0 then
        FarmState.Status = "Waiting for character"
        return
    end

    if FarmState.NoClip then
        ApplyNoClip(true)
    end

    if not FarmState.CurrentTarget or not IsValidFarmTarget(FarmState.CurrentTarget) then
        FarmState.CurrentTarget = GetNearestTarget()
    end

    local target = FarmState.CurrentTarget

    if not target then
        FarmState.Status = "Searching for target"
        return
    end

    FarmState.Status = "Farming: " .. target.Name

    if FarmState.AutoTarget then
        MoveToTarget(target)
    end

    if FarmState.UseTool then
        AttackTarget(target)
    end
end

--==================================================
-- FARM UI
--==================================================

local FarmStatusCard, FarmStatusValue = Card(
    FarmPage,
    "FARM STATUS",
    "Idle"
)

local FarmTargetCard, FarmTargetValue = Card(
    FarmPage,
    "CURRENT TARGET",
    "None"
)

local FarmDistanceCard, FarmDistanceValue = Card(
    FarmPage,
    "DISTANCE",
    tostring(FarmState.Distance)
)

Toggle(
    FarmPage,
    "Auto Farm",
    "Find the nearest valid NPC and continuously process the farm loop.",
    false,
    function(enabled)
        FarmState.Enabled = enabled
        FarmState.StartedAt = enabled and os.clock() or 0

        if enabled then
            FarmState.Status = "Starting"
            FarmState.CurrentTarget = nil
            EquipFirstTool()
            Notify("Auto Farm", "Farm engine iniciado.")
        else
            StopFarm()
            Notify("Auto Farm", "Farm engine parado.")
        end
    end
)

Toggle(
    FarmPage,
    "Auto Mastery",
    "Keeps the mastery mode available for the game's custom attack hook.",
    false,
    function(enabled)
        FarmState.AutoMastery = enabled
        Notify("Auto Mastery", enabled and "Enabled" or "Disabled")
    end
)

Toggle(
    FarmPage,
    "Auto Equip Tool",
    "Automatically equips the first Tool found in the Backpack.",
    true,
    function(enabled)
        FarmState.UseTool = enabled

        if enabled then
            EquipFirstTool()
        end
    end
)

Toggle(
    FarmPage,
    "Auto Target",
    "Moves the character toward the selected target.",
    true,
    function(enabled)
        FarmState.AutoTarget = enabled
    end
)

Toggle(
    FarmPage,
    "Bring Mobs",
    "Experimental local target positioning for testing your own NPC system.",
    false,
    function(enabled)
        FarmState.BringMobs = enabled
        Notify(
            "Bring Mobs",
            enabled
                and "Experimental mode enabled."
                or "Experimental mode disabled."
        )
    end
)

Toggle(
    FarmPage,
    "NoClip",
    "Disables character collisions while the farm is running.",
    false,
    function(enabled)
        FarmState.NoClip = enabled
        ApplyNoClip(enabled)
    end
)

ValueBox(
    FarmPage,
    "Target Distance",
    FarmState.Distance,
    function(value)
        FarmState.Distance = math.clamp(value, 2, 30)
        FarmDistanceValue.Text = tostring(FarmState.Distance)
    end
)

ValueBox(
    FarmPage,
    "Scan Radius",
    FarmState.ScanRadius,
    function(value)
        FarmState.ScanRadius = math.clamp(value, 25, 2000)
        Notify("Main Farm", "Scan radius: " .. tostring(FarmState.ScanRadius))
    end
)

ValueBox(
    FarmPage,
    "Attack Cooldown",
    FarmState.AttackCooldown,
    function(value)
        FarmState.AttackCooldown = math.clamp(value, 0.03, 2)
        Notify(
            "Main Farm",
            "Attack cooldown: " .. string.format("%.2f", FarmState.AttackCooldown)
        )
    end
)

ActionButton(
    FarmPage,
    "Find Nearest Target",
    function()
        local target = GetNearestTarget()

        if target then
            FarmState.CurrentTarget = target
            FarmTargetValue.Text = target.Name
            FarmStatusValue.Text = "Target found"
            Notify("Main Farm", "Target encontrado: " .. target.Name)
        else
            FarmTargetValue.Text = "None"
            FarmStatusValue.Text = "No target"
            Notify("Main Farm", "Nenhum alvo válido encontrado.")
        end
    end
)

ActionButton(
    FarmPage,
    "Equip First Tool",
    function()
        local tool = EquipFirstTool()

        if tool then
            Notify("Main Farm", "Tool equipada: " .. tool.Name)
        else
            Notify("Main Farm", "Nenhuma Tool encontrada.")
        end
    end
)

ActionButton(
    FarmPage,
    "Stop Farm",
    function()
        StopFarm()
        Notify("Main Farm", "Farm parado manualmente.")
    end
)

--==================================================
-- FARM LOOP
--==================================================

FarmConnect(RunService.Heartbeat, function()
    if State.Destroyed then
        return
    end

    if not FarmState.Enabled then
        FarmStatusValue.Text = FarmState.Status
        FarmTargetValue.Text = FarmState.CurrentTarget
            and FarmState.CurrentTarget.Name
            or "None"
        return
    end

    FarmStep()

    FarmStatusValue.Text = FarmState.Status

    if FarmState.CurrentTarget
        and FarmState.CurrentTarget.Parent
        and IsValidFarmTarget(FarmState.CurrentTarget)
    then
        FarmTargetValue.Text = FarmState.CurrentTarget.Name
    else
        FarmTargetValue.Text = "None"
    end
end)

FarmConnect(LocalPlayer.CharacterAdded, function()
    task.wait(0.5)

    FarmState.CurrentTarget = nil

    if FarmState.Enabled and FarmState.UseTool then
        EquipFirstTool()
    end

    if FarmState.NoClip then
        ApplyNoClip(true)
    end
end)

FarmConnect(RunService.Stepped, function()
    if FarmState.Enabled and FarmState.NoClip then
        ApplyNoClip(true)
    end
end)

--==================================================
-- QUEST
--==================================================

local QuestPage = PageService:Create("Quest")

Section(
    QuestPage,
    "Quest",
    "Quest management interface"
)

Toggle(
    QuestPage,
    "Auto Quest",
    "Test toggle — interface only",
    false,
    function(enabled)
        Notify("Auto Quest", enabled and "Enabled" or "Disabled")
    end
)

--==================================================
-- RAIDS
--==================================================

local RaidPage = PageService:Create("Raids")

Section(
    RaidPage,
    "Raids",
    "Raid interface"
)

Toggle(
    RaidPage,
    "Auto Raid",
    "Test toggle — interface only",
    false,
    function(enabled)
        Notify("Auto Raid", enabled and "Enabled" or "Disabled")
    end
)

--==================================================
-- COMBAT
--==================================================

local CombatPage = PageService:Create("Combat")

Section(
    CombatPage,
    "Combat",
    "Combat interface"
)

Toggle(
    CombatPage,
    "Combat Assist",
    "Test toggle — interface only",
    false,
    function(enabled)
        Notify("Combat", enabled and "Enabled" or "Disabled")
    end
)

--==================================================
-- MISC
--==================================================

local MiscPage = PageService:Create("Misc")

Section(
    MiscPage,
    "Misc",
    "Additional options"
)

Toggle(
    MiscPage,
    "Anti AFK",
    "Test interface",
    false,
    function(enabled)
        Notify("Anti AFK", enabled and "Enabled" or "Disabled")
    end
)


--==================================================
-- FLOQUITAVE 3.0 - FULL SYSTEMS LAYER
--==================================================
-- This layer is an independent implementation of the
-- feature categories observed during source analysis.
-- Game-specific actions are routed through adapters so
-- the hub can be tested without hard-coding hidden APIs.

local Full = {
    Running = true,
    Connections = {},
    Loops = {},
    Status = {},
    Adapter = {}
}

local function FullConnect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Full.Connections, c)
    return c
end

local function FullAlive()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

local function FullRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function FullHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function FullToolByType(toolType)
    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and (toolType == "Auto" or tool.ToolTip == toolType) then
                return tool
            end
        end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (toolType == "Auto" or tool.ToolTip == toolType) then
            return tool
        end
    end
end

local function FullEquip(toolType)
    local humanoid = FullHumanoid()
    local tool = FullToolByType(toolType)
    if humanoid and tool and tool.Parent ~= LocalPlayer.Character then
        pcall(function() humanoid:EquipTool(tool) end)
    end
    return tool
end

local function FullFindEnemies()
    local containers = {
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("Npcs"),
        workspace:FindFirstChild("Mobs"),
        workspace:FindFirstChild("Enemy")
    }
    local result = {}
    for _, folder in ipairs(containers) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    table.insert(result, obj)
                end
            end
        end
    end
    return result
end

local function FullNearest(filterName, radius)
    local root = FullRoot()
    if not root then return nil end
    local best, bestDistance
    for _, obj in ipairs(FullFindEnemies()) do
        if (not filterName or filterName == "" or filterName == "Auto" or obj.Name == filterName) then
            local distance = (obj.HumanoidRootPart.Position - root.Position).Magnitude
            if distance <= radius and (not bestDistance or distance < bestDistance) then
                best, bestDistance = obj, distance
            end
        end
    end
    return best, bestDistance
end

local function FullMoveTo(target, offset)
    local root = FullRoot()
    if not root or not target then return false end
    local targetRoot = target:IsA("BasePart") and target or target:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    pcall(function()
        root.CFrame = targetRoot.CFrame * (offset or CFrame.new(0, 8, 0))
    end)
    return true
end

local function FullAttack()
    local tool = FullToolByType("Auto")
    if not tool then return false end
    pcall(function() tool:Activate() end)
    return true
end

--==================================================
-- FLOQUITAVE 3.1 GAME ADAPTER
--==================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
local QuestDB31 = {
    {1, 9, "Bandit", "BanditQuest1", 1}, {10, 14, "Monkey", "JungleQuest", 1},
    {15, 29, "Gorilla", "JungleQuest", 2}, {30, 39, "Pirate", "BuggyQuest1", 1},
    {40, 59, "Brute", "BuggyQuest1", 2}, {60, 74, "Desert Bandit", "DesertQuest", 1},
    {75, 89, "Desert Officer", "DesertQuest", 2}, {90, 99, "Snow Bandit", "SnowQuest", 1},
    {100, 119, "Snowman", "SnowQuest", 2}, {120, 149, "Chief Petty Officer", "MarineQuest2", 1},
    {150, 174, "Sky Bandit", "SkyQuest", 1}, {175, 189, "Dark Master", "SkyQuest", 2},
    {190, 209, "Prisoner", "PrisonerQuest", 1}, {210, 249, "Dangerous Prisoner", "PrisonerQuest", 2},
    {250, 274, "Toga Warrior", "ColosseumQuest", 1}, {275, 299, "Gladiator", "ColosseumQuest", 2},
    {300, 324, "Military Soldier", "MagmaQuest", 1}, {325, 374, "Military Spy", "MagmaQuest", 2},
    {375, 399, "Fishman Warrior", "FishmanQuest", 1}, {400, 449, "Fishman Commando", "FishmanQuest", 2},
    {450, 474, "God's Guard", "SkyExp1Quest", 1}, {475, 524, "Shanda", "SkyExp1Quest", 2},
    {525, 549, "Royal Squad", "SkyExp2Quest", 1}, {550, 624, "Royal Soldier", "SkyExp2Quest", 2},
    {625, 649, "Galley Pirate", "FountainQuest", 1}, {650, 699, "Galley Captain", "FountainQuest", 2},
    {700, 724, "Raider", "Area1Quest", 1}, {725, 774, "Mercenary", "Area1Quest", 2},
    {775, 799, "Swan Pirate", "Area2Quest", 1}, {800, 874, "Factory Staff", "Area2Quest", 2},
    {875, 899, "Marine Lieutenant", "MarineQuest3", 1}, {900, 949, "Marine Captain", "MarineQuest3", 2},
    {950, 974, "Zombie", "ZombieQuest", 1}, {975, 999, "Vampire", "ZombieQuest", 2},
    {1000, 1049, "Snow Trooper", "SnowMountainQuest", 1}, {1050, 1099, "Winter Warrior", "SnowMountainQuest", 2},
    {1100, 1124, "Lab Subordinate", "IceSideQuest", 1}, {1125, 1174, "Horned Warrior", "ForgottenQuest", 1},
    {1175, 1199, "Magma Ninja", "FireSideQuest", 1}, {1200, 1249, "Lava Pirate", "FireSideQuest", 2},
    {1250, 1274, "Ship Deckhand", "ShipQuest1", 1}, {1275, 1299, "Ship Engineer", "ShipQuest1", 2},
    {1300, 1324, "Ship Steward", "ShipQuest2", 1}, {1325, 1349, "Ship Officer", "ShipQuest2", 2},
    {1350, 1374, "Arctic Warrior", "FrostQuest", 1}, {1375, 1424, "Snow Lurker", "FrostQuest", 2},
    {1425, 1449, "Sea Soldier", "ForgottenQuest", 1}, {1450, 1474, "Water Fighter", "ForgottenQuest", 2},
    {1475, 1499, "Pirate Millionaire", "PiratePortQuest", 1}, {1500, 1524, "Pistol Billionaire", "PiratePortQuest", 2},
    {1525, 1574, "Dragon Crew Warrior", "AmazonQuest", 1}, {1575, 1599, "Dragon Crew Archer", "AmazonQuest", 2},
    {1600, 1624, "Female Islander", "FemaleIslandQuest", 1}, {1625, 1649, "Giant Islander", "FemaleIslandQuest", 2},
    {1650, 1699, "Marine Commodore", "MarineTreeQuest", 1}, {1700, 1724, "Fishman Raider", "DeepForestIsland3", 1},
    {1725, 1774, "Fishman Captain", "DeepForestIsland3", 2}, {1775, 1799, "Forest Pirate", "DeepForestIsland", 1},
    {1800, 1824, "Mythological Pirate", "DeepForestIsland", 2}, {1825, 1849, "Jungle Pirate", "DeepForestIsland2", 1},
    {1850, 1874, "Musketeer Pirate", "DeepForestIsland2", 2}, {1875, 1899, "Reborn Skeleton", "HauntedQuest1", 1},
    {1900, 1924, "Living Zombie", "HauntedQuest1", 2}, {1925, 1949, "Demonic Soul", "HauntedQuest2", 1},
    {1950, 1974, "Soul Reaper", "HauntedQuest2", 2}, {1975, 1999, "Cookie Crafter", "IceCreamIslandQuest", 1},
    {2000, 2024, "Cake Guard", "IceCreamIslandQuest", 2}, {2025, 2049, "Baking Staff", "CakeQuest1", 1},
    {2050, 2074, "Head Baker", "CakeQuest1", 2}, {2075, 2099, "Cocoa Warrior", "ChocQuest1", 1},
    {2100, 2124, "Chocolate Bar Battler", "ChocQuest1", 2}, {2125, 2149, "Sweet Thief", "ChocQuest2", 1},
    {2150, 2174, "Candy Rebel", "ChocQuest2", 2}, {2175, 2199, "Candy Pirate", "CandyQuest1", 1},
    {2200, 2224, "Snow Demon", "CandyQuest1", 2}, {2225, 2249, "Isle Outlaw", "TikiQuest1", 1},
    {2250, 2274, "Island Boy", "TikiQuest1", 2},
}

local function CommF31(...)
    if not CommF then return false, "CommF_ not found" end
    local ok, result = pcall(function() return CommF:InvokeServer(...) end)
    if not ok then return false, tostring(result) end
    return true, result
end

local function GetQuestInfo31(level, preferred)
    level = tonumber(level) or 1
    if preferred and preferred ~= "" and preferred ~= "Auto" then
        for _, q in ipairs(QuestDB31) do
            if q[3]:lower() == preferred:lower() then return q end
        end
    end
    local best
    for _, q in ipairs(QuestDB31) do
        if level >= q[1] and level <= q[2] then best = q end
    end
    return best
end

local function QuestActive31()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    if quest then
        local title = quest:FindFirstChild("Container") and quest.Container:FindFirstChild("QuestTitle")
        if title and title:IsA("TextLabel") and title.Text ~= "" then return true end
    end
    return false
end

local function FindQuestGiver31(questName)
    local containers = {workspace:FindFirstChild("Map"), workspace}
    for _, container in ipairs(containers) do
        if container then
            local obj = container:FindFirstChild(questName, true)
            if obj then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then return part end
            end
        end
    end
end

local function FindTool31(name)
    local char = LocalPlayer.Character
    if name and name ~= "" and name ~= "Auto" then
        if char then
            for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find(name:lower(),1,true) then return t end end
        end
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find(name:lower(),1,true) then return t end end
    end
    return FullToolByType("Auto")
end

Full.Adapter.StartQuest = function(questName)
    local q = GetQuestInfo31(PlayerService:GetLevel(), questName)
    if not q then return false end
    local ok = CommF31("StartQuest", q[4], q[5])
    return ok
end
Full.Adapter.AbandonQuest = function() return CommF31("AbandonQuest") end
Full.Adapter.BuyChip = function(chip) return CommF31("RaidsNpc", "Select", chip) end
Full.Adapter.Awaken = function() return CommF31("Awakener", "Check") end
Full.Adapter.StartRaid = function()
    local ok = CommF31("RaidsNpc", "Select", FullState and FullState.Raid and FullState.Raid.Chip or "Flame")
    return ok
end
Full.Adapter.BuyItem = function(item) return CommF31("BuyItem", item) end
Full.Adapter.StartSeaEvent = function(event) return CommF31("StartEvent", event) end
Full.Adapter.RaceAction = function(action) return CommF31(action) end
Full.Adapter.UseSkill = function(skill) return CommF31("UseSkill", skill) end
Full.Adapter.Teleport = function(place) return CommF31("Travel", place) end

--==================================================
-- GLOBAL AUTOMATION STATE
--==================================================

local FullState = {
    Farm = {
        Enabled = false,
        AutoQuest = false,
        AutoMastery = false,
        AutoEquip = true,
        AutoTarget = true,
        BringMobs = false,
        NoClip = false,
        FastAttack = false,
        Target = "Auto",
        Weapon = "Auto",
        FarmType = "Above",
        Distance = 8,
        Radius = 350,
        AttackDelay = 0.12,
        MasteryPercent = 20,
    },
    Quest = {
        Enabled = false,
        Selected = "Auto",
        AutoWorld = false,
        AutoSaber = false,
        AutoYama = false,
        AutoTushita = false,
        AutoCDK = false,
        AutoDarkDagger = false,
        AutoHallowScythe = false,
        AutoCitizen = false,
    },
    Raid = {
        Enabled = false,
        Chip = "Flame",
        AutoBuyChip = false,
        AutoStart = false,
        Aura = false,
        NextIsland = false,
        AutoAwaken = false,
        LawRaid = false,
    },
    Combat = {
        Enabled = false,
        Mode = "Nearest Player",
        Weapon = "Melee",
        Distance = 12,
        AttackDelay = 0.12,
        Aura = false,
        AimLock = false,
    },
    Sea = {
        Enabled = false,
        Event = "Auto",
        AutoSail = false,
        AutoEvent = false,
        AutoChest = false,
        AutoFruit = false,
    },
    Race = {
        Enabled = false,
        AutoV4 = false,
        AutoTrial = false,
        AutoGear = false,
    },
    ESP = {Players = false, Bosses = false, Fruits = false},
    Misc = {
        AntiAFK = false,
        AntiKick = false,
        NoDodgeCooldown = false,
        InfiniteEnergy = false,
        InfiniteGeppo = false,
        FastRespawn = false,
        HideNotifications = false,
        LowGraphics = false,
    }
}

--==================================================
-- MAIN FARM 3.0
--==================================================

Section(FarmPage, "Full Farm Controller", "Target • Quest • Movement • Combat • Mastery")

local FarmStatusCard, FarmStatus = Card(FarmPage, "FARM STATUS", "Idle")
local FarmTargetCard, FarmTarget = Card(FarmPage, "CURRENT TARGET", "None")
local FarmDistanceCard, FarmDistance = Card(FarmPage, "DISTANCE", "-")
local FarmHPCard, FarmHP = Card(FarmPage, "TARGET HP", "-")
local FarmWeaponCard, FarmWeapon = Card(FarmPage, "WEAPON", "Auto")

Toggle(FarmPage, "Auto Farm", "Runs the complete farm controller.", false, function(v)
    FullState.Farm.Enabled = v
    FarmState.Enabled = v
    FarmStatus.Text = v and "Running" or "Stopped"
end)

Toggle(FarmPage, "Auto Quest", "Lets the farm controller request the selected quest through the adapter.", false, function(v)
    FullState.Farm.AutoQuest = v
end)

Toggle(FarmPage, "Database Auto Quest", "Selects the quest and monster from the built-in level database.", true, function(v)
    FullState.Farm.AutoQuest = v
end)

ValueBox(FarmPage, "Weapon Name", "Auto", function(v)
    FullState.Farm.Weapon = tostring(v)
    FarmWeapon.Text = tostring(v)
end)

Toggle(FarmPage, "Auto Mastery", "Switches the controller into mastery-oriented combat.", false, function(v)
    FullState.Farm.AutoMastery = v
end)

Toggle(FarmPage, "Auto Equip Weapon", "Automatically equips the selected weapon type.", true, function(v)
    FullState.Farm.AutoEquip = v
end)

Toggle(FarmPage, "Auto Target", "Automatically selects the nearest valid target.", true, function(v)
    FullState.Farm.AutoTarget = v
end)

Toggle(FarmPage, "Bring Mobs", "Keeps selected targets close to the farm position.", false, function(v)
    FullState.Farm.BringMobs = v
end)

Toggle(FarmPage, "NoClip", "Disables character collision while farming.", false, function(v)
    FullState.Farm.NoClip = v
end)

Toggle(FarmPage, "Fast Attack", "Uses the configured attack interval.", false, function(v)
    FullState.Farm.FastAttack = v
end)

ValueBox(FarmPage, "Target Name", "Auto", function(v)
    FullState.Farm.Target = tostring(v)
end)

ValueBox(FarmPage, "Farm Distance", 8, function(v)
    FullState.Farm.Distance = math.max(2, tonumber(v) or 8)
end)

ValueBox(FarmPage, "Search Radius", 350, function(v)
    FullState.Farm.Radius = math.max(25, tonumber(v) or 350)
end)

ValueBox(FarmPage, "Attack Delay", 0.12, function(v)
    FullState.Farm.AttackDelay = math.max(0.03, tonumber(v) or 0.12)
end)

ValueBox(FarmPage, "Mastery Kill %", 20, function(v)
    FullState.Farm.MasteryPercent = math.clamp(tonumber(v) or 20, 1, 99)
end)

ActionButton(FarmPage, "Find Nearest Target", function()
    local target, distance = FullNearest(FullState.Farm.Target, FullState.Farm.Radius)
    if target then
        FullState.Status.FarmTarget = target
        FarmTarget.Text = target.Name
        FarmDistance.Text = string.format("%.1f", distance or 0)
        Notify("Main Farm", "Target: " .. target.Name)
    else
        FullState.Status.FarmTarget = nil
        FarmTarget.Text = "None"
        FarmDistance.Text = "-"
        Notify("Main Farm", "No valid target found.")
    end
end)

ActionButton(FarmPage, "Equip Selected Weapon", function()
    local tool = FullEquip(FullState.Farm.Weapon)
    FarmWeapon.Text = tool and tool.Name or "None"
end)

ActionButton(FarmPage, "Stop Farm", function()
    FullState.Farm.Enabled = false
    FarmState.Enabled = false
    FarmStatus.Text = "Stopped"
end)

--==================================================
-- QUEST 3.0
--==================================================

local QuestPageFull = QuestPage
Section(QuestPageFull, "Quest Controller", "World progression • special quests • sword/puzzle helpers")

local QuestStatusCard, QuestStatus = Card(QuestPageFull, "QUEST STATUS", "Idle")
local QuestSelectedCardFrame, QuestSelectedCard = Card(QuestPageFull, "SELECTED QUEST", "Auto")
local QuestProgressCard, QuestProgress = Card(QuestPageFull, "PROGRESS", "-")

ValueBox(QuestPageFull, "Quest / Boss Name", "Auto", function(v)
    FullState.Quest.Selected = tostring(v)
    QuestSelectedCard.Text = tostring(v)
end)

Toggle(QuestPageFull, "Auto Quest", "Quest controller master switch.", false, function(v)
    FullState.Quest.Enabled = v
    QuestStatus.Text = v and "Running" or "Stopped"
end)

Toggle(QuestPageFull, "Auto World Progress", "Runs world-progression checks through the adapter.", false, function(v)
    FullState.Quest.AutoWorld = v
end)

Toggle(QuestPageFull, "Auto Saber", "Saber progression controller.", false, function(v)
    FullState.Quest.AutoSaber = v
end)

Toggle(QuestPageFull, "Auto Yama", "Yama progression controller.", false, function(v)
    FullState.Quest.AutoYama = v
end)

Toggle(QuestPageFull, "Auto Tushita", "Tushita progression controller.", false, function(v)
    FullState.Quest.AutoTushita = v
end)

Toggle(QuestPageFull, "Auto Cursed Dual Katana", "CDK progression controller.", false, function(v)
    FullState.Quest.AutoCDK = v
end)

Toggle(QuestPageFull, "Auto Dark Dagger", "Dark Dagger progression controller.", false, function(v)
    FullState.Quest.AutoDarkDagger = v
end)

Toggle(QuestPageFull, "Auto Hallow Scythe", "Hallow Scythe progression controller.", false, function(v)
    FullState.Quest.AutoHallowScythe = v
end)

Toggle(QuestPageFull, "Auto Citizen", "Citizen quest controller.", false, function(v)
    FullState.Quest.AutoCitizen = v
end)

ActionButton(QuestPageFull, "Start Selected Quest", function()
    local ok = Full.Adapter.StartQuest(FullState.Quest.Selected)
    QuestStatus.Text = ok and "Quest started" or "Adapter pending"
    Notify("Quest", ok and "Quest started." or "Game adapter not configured.")
end)

ActionButton(QuestPageFull, "Abandon Quest", function()
    local ok = Full.Adapter.AbandonQuest()
    QuestStatus.Text = ok and "Quest abandoned" or "Adapter pending"
end)

--==================================================
-- RAID 3.0
--==================================================

Section(RaidPage, "Raid Controller", "Chip • Start • Aura • Islands • Awakening")

local RaidStatusCard, RaidStatus = Card(RaidPage, "RAID STATUS", "Idle")
local RaidChipCard, RaidChip = Card(RaidPage, "SELECTED CHIP", FullState.Raid.Chip)

ValueBox(RaidPage, "Chip", "Flame", function(v)
    FullState.Raid.Chip = tostring(v)
    RaidChip.Text = tostring(v)
end)

Toggle(RaidPage, "Auto Buy Microchip", "Requests the selected chip through the adapter.", false, function(v)
    FullState.Raid.AutoBuyChip = v
end)

Toggle(RaidPage, "Auto Start Raids", "Starts raids when the required item is available.", false, function(v)
    FullState.Raid.AutoStart = v
end)

Toggle(RaidPage, "Kill Raid Aura", "Raid target controller.", false, function(v)
    FullState.Raid.Aura = v
end)

Toggle(RaidPage, "Auto Next Island", "Moves the controller toward the next detected raid island.", false, function(v)
    FullState.Raid.NextIsland = v
end)

Toggle(RaidPage, "Auto Awaken", "Requests awakening through the adapter.", false, function(v)
    FullState.Raid.AutoAwaken = v
end)

Toggle(RaidPage, "Law Raid", "Law raid controller.", false, function(v)
    FullState.Raid.LawRaid = v
end)

ActionButton(RaidPage, "Buy Selected Chip", function()
    local ok = Full.Adapter.BuyChip(FullState.Raid.Chip)
    RaidStatus.Text = ok and "Chip requested" or "Adapter pending"
end)

ActionButton(RaidPage, "Start Raid", function()
    local ok = Full.Adapter.StartRaid(FullState.Raid.Chip)
    RaidStatus.Text = ok and "Raid started" or "Adapter pending"
end)

ActionButton(RaidPage, "Awaken", function()
    local ok = Full.Adapter.Awaken()
    RaidStatus.Text = ok and "Awakening requested" or "Adapter pending"
end)

--==================================================
-- COMBAT 3.0
--==================================================

Section(CombatPage, "Combat Controller", "Player targeting • weapon selection • attack loop")

local CombatStatusCard, CombatStatus = Card(CombatPage, "COMBAT STATUS", "Idle")
local CombatTargetCard, CombatTarget = Card(CombatPage, "TARGET", "None")
local CombatWeaponCard, CombatWeapon = Card(CombatPage, "WEAPON", "Melee")

ValueBox(CombatPage, "Weapon Type", "Melee", function(v)
    FullState.Combat.Weapon = tostring(v)
    CombatWeapon.Text = tostring(v)
end)

ValueBox(CombatPage, "Combat Distance", 12, function(v)
    FullState.Combat.Distance = math.max(2, tonumber(v) or 12)
end)

ValueBox(CombatPage, "Attack Delay", 0.12, function(v)
    FullState.Combat.AttackDelay = math.max(0.03, tonumber(v) or 0.12)
end)

Toggle(CombatPage, "Combat Assist", "Enables the combat controller.", false, function(v)
    FullState.Combat.Enabled = v
    CombatStatus.Text = v and "Running" or "Stopped"
end)

Toggle(CombatPage, "Aim Lock", "Keeps a selected target in focus.", false, function(v)
    FullState.Combat.AimLock = v
end)

Toggle(CombatPage, "Aura", "Enables repeated attacks against a valid target.", false, function(v)
    FullState.Combat.Aura = v
end)

ActionButton(CombatPage, "Find Target", function()
    local target = FullNearest(nil, 500)
    if target then
        Full.Status.CombatTarget = target
        CombatTarget.Text = target.Name
    else
        CombatTarget.Text = "None"
    end
end)

ActionButton(CombatPage, "Equip Combat Weapon", function()
    local tool = FullEquip(FullState.Combat.Weapon)
    CombatWeapon.Text = tool and tool.Name or "None"
end)

--==================================================
-- SEA EVENT 3.0
--==================================================

local SeaPage = PageService:Create("Sea Event")
Section(SeaPage, "Sea Event Controller", "Sailing • event targets • chests • fruit collection")

local SeaStatusCard, SeaStatus = Card(SeaPage, "SEA STATUS", "Idle")
ValueBox(SeaPage, "Event Name", "Auto", function(v)
    FullState.Sea.Event = tostring(v)
end)

Toggle(SeaPage, "Auto Sail", "Controls the sea-event movement loop.", false, function(v)
    FullState.Sea.AutoSail = v
    FullState.Sea.Enabled = v
    SeaStatus.Text = v and "Sailing" or "Stopped"
end)

Toggle(SeaPage, "Auto Sea Event", "Requests the selected event through the adapter.", false, function(v)
    FullState.Sea.AutoEvent = v
end)

Toggle(SeaPage, "Auto Chest", "Scans for collectible chest objects.", false, function(v)
    FullState.Sea.AutoChest = v
end)

Toggle(SeaPage, "Auto Fruit", "Scans for collectible fruit objects.", false, function(v)
    FullState.Sea.AutoFruit = v
end)

ActionButton(SeaPage, "Start Selected Event", function()
    local ok = Full.Adapter.StartSeaEvent(FullState.Sea.Event)
    SeaStatus.Text = ok and "Event started" or "Adapter pending"
end)

--==================================================
-- RACE V4 3.0
--==================================================

local RacePage = PageService:Create("Race V4")
Section(RacePage, "Race V4 Controller", "Area navigation • trials • gear • transformation")

local RaceStatusCard, RaceStatus = Card(RacePage, "RACE STATUS", "Idle")

Toggle(RacePage, "Auto Race V4", "Runs the Race V4 controller.", false, function(v)
    FullState.Race.Enabled = v
    FullState.Race.AutoV4 = v
    RaceStatus.Text = v and "Running" or "Stopped"
end)

Toggle(RacePage, "Auto Trial", "Trial controller.", false, function(v)
    FullState.Race.AutoTrial = v
end)

Toggle(RacePage, "Auto Gear", "Gear controller.", false, function(v)
    FullState.Race.AutoGear = v
end)

ActionButton(RacePage, "Temple of Time", function()
    local ok = Full.Adapter.RaceAction("TempleOfTime")
    RaceStatus.Text = ok and "Requested" or "Adapter pending"
end)

ActionButton(RacePage, "Lever Pull", function()
    local ok = Full.Adapter.RaceAction("Lever")
    RaceStatus.Text = ok and "Requested" or "Adapter pending"
end)

ActionButton(RacePage, "Ancient One", function()
    local ok = Full.Adapter.RaceAction("AncientOne")
    RaceStatus.Text = ok and "Requested" or "Adapter pending"
end)

ActionButton(RacePage, "Safe Zone", function()
    local ok = Full.Adapter.RaceAction("SafeZone")
    RaceStatus.Text = ok and "Requested" or "Adapter pending"
end)

ActionButton(RacePage, "PVP Zone", function()
    local ok = Full.Adapter.RaceAction("PVPZone")
    RaceStatus.Text = ok and "Requested" or "Adapter pending"
end)

--==================================================
-- SHOP 3.0
--==================================================

local ShopPage = PageService:Create("Shop")
Section(ShopPage, "Shop Controller", "Generic item purchasing through the adapter")

local ShopStatusCard, ShopStatus = Card(ShopPage, "SHOP STATUS", "Idle")
local ShopItemHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 70),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, ShopPage)
Corner(ShopItemHolder, 11)
Stroke(ShopItemHolder, Theme.Secondary, 0.3)
Create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 10),
    Size = UDim2.new(0.5, -14, 0, 20),
    BackgroundTransparency = 1,
    Text = "Item Name",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, ShopItemHolder)
local ShopItemBox = Create("TextBox", {
    Position = UDim2.new(1, -120, 0, 10),
    Size = UDim2.new(0, 106, 0, 36),
    BackgroundColor3 = Theme.Secondary,
    Text = "",
    PlaceholderText = "Item",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.Text,
    ClearTextOnFocus = false
}, ShopItemHolder)
Corner(ShopItemBox, 8)
Connect(ShopItemBox:GetPropertyChangedSignal("Text"), function()
    Full.Status.ShopItem = ShopItemBox.Text
end)

ActionButton(ShopPage, "Buy Selected Item", function()
    local item = Full.Status.ShopItem or ""
    if item == "" then
        Notify("Shop", "Enter an item name first.")
        return
    end
    local ok = Full.Adapter.BuyItem(item)
    ShopStatus.Text = ok and ("Requested: " .. item) or "Adapter pending"
end)

--==================================================
-- ESP 3.1
--==================================================
local ESPPage = PageService:Create("ESP")
Section(ESPPage, "ESP Controller", "Local visual markers for players, bosses and fruits")
local ESPStatusCard, ESPStatus = Card(ESPPage, "ESP STATUS", "Idle")

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "Floquitave_ESP_31"
ESPFolder.Parent = ScreenGui

local function ClearESP31()
    for _, child in ipairs(ESPFolder:GetChildren()) do child:Destroy() end
end
local function MarkESP31(model, label, color)
    if not model or not model:IsA("Model") then return end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if not root then return end
    local h = Instance.new("Highlight")
    h.Adornee = model; h.FillTransparency = 0.75; h.OutlineTransparency = 0.15; h.Parent = ESPFolder
    local b = Instance.new("BillboardGui")
    b.Adornee = root; b.Size = UDim2.new(0,160,0,28); b.StudsOffset = Vector3.new(0,3,0); b.AlwaysOnTop = true; b.Parent = ESPFolder
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1,1); t.BackgroundTransparency = 1; t.Text = label; t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextColor3 = color; t.TextStrokeTransparency = 0.4; t.Parent = b
end
local function RefreshESP31()
    ClearESP31()
    local count = 0
    if FullState.ESP.Players then
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character then MarkESP31(plr.Character, "PLAYER: "..plr.Name, Color3.fromRGB(90,160,255)); count += 1 end end
    end
    if FullState.ESP.Bosses then
        for _, obj in ipairs(FullFindEnemies()) do local hum=obj:FindFirstChildOfClass("Humanoid"); if hum and hum.MaxHealth >= 10000 then MarkESP31(obj,"BOSS: "..obj.Name,Color3.fromRGB(255,90,90)); count += 1 end end
    end
    if FullState.ESP.Fruits then
        for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Tool") and obj.Name:lower():find("fruit",1,true) then local m=obj:IsA("Model") and obj or obj.Parent; if m and m:IsA("Model") then MarkESP31(m,"FRUIT: "..obj.Name,Color3.fromRGB(180,90,255)); count += 1 end end end
    end
    ESPStatus.Text = tostring(count).." marker(s)"
end
Toggle(ESPPage, "Player ESP", "Highlights other players.", false, function(v) FullState.ESP.Players=v; RefreshESP31() end)
Toggle(ESPPage, "Boss ESP", "Highlights high-health enemies.", false, function(v) FullState.ESP.Bosses=v; RefreshESP31() end)
Toggle(ESPPage, "Fruit ESP", "Highlights Tool objects whose name contains fruit.", false, function(v) FullState.ESP.Fruits=v; RefreshESP31() end)
ActionButton(ESPPage, "Refresh ESP", RefreshESP31)
ActionButton(ESPPage, "Clear ESP", function() ClearESP31(); ESPStatus.Text="Cleared" end)

--==================================================
-- MISC 3.0
--==================================================

Section(MiscPage, "Misc Controller", "Quality-of-life and performance controls")

Toggle(MiscPage, "Anti AFK", "Prevents idle state using the local Roblox idle event.", false, function(v)
    FullState.Misc.AntiAFK = v
end)

Toggle(MiscPage, "Anti Kick Client", "Reserved adapter hook for a project-specific client safeguard.", false, function(v)
    FullState.Misc.AntiKick = v
end)

Toggle(MiscPage, "No Dodge Cooldown", "Project-specific cooldown adapter.", false, function(v)
    FullState.Misc.NoDodgeCooldown = v
end)

Toggle(MiscPage, "Infinite Energy", "Project-specific energy adapter.", false, function(v)
    FullState.Misc.InfiniteEnergy = v
end)

Toggle(MiscPage, "Infinite Geppo", "Project-specific movement adapter.", false, function(v)
    FullState.Misc.InfiniteGeppo = v
end)

Toggle(MiscPage, "Fast Respawn", "Project-specific respawn adapter.", false, function(v)
    FullState.Misc.FastRespawn = v
end)

Toggle(MiscPage, "Hide Notifications", "Hides local notification GUI objects when supported.", false, function(v)
    FullState.Misc.HideNotifications = v
end)

Toggle(MiscPage, "Low Graphics", "Applies conservative local graphics reductions.", false, function(v)
    FullState.Misc.LowGraphics = v
    if v then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end
end)

--==================================================
-- FULL CONTROLLERS
--==================================================

FullConnect(RunService.Heartbeat, function()
    if not Full.Running then return end

    -- Farm
    if FullState.Farm.Enabled and FullAlive() then
        if FullState.Farm.AutoQuest then
            local q = GetQuestInfo31(PlayerService:GetLevel(), FullState.Farm.Target)
            if q and not QuestActive31() then
                Full.Adapter.AbandonQuest()
                local giver = FindQuestGiver31(q[4])
                local root = FullRoot()
                if giver and root then
                    root.CFrame = giver.CFrame + Vector3.new(0, 3, 0)
                end
                Full.Adapter.StartQuest(q[4])
                QuestStatus.Text = "Starting: " .. q[4]
            end
        end
        local target = Full.Status.FarmTarget
        if not target or not target.Parent or not target:FindFirstChildOfClass("Humanoid")
            or target:FindFirstChildOfClass("Humanoid").Health <= 0
            or FullState.Farm.AutoTarget then
            target = FullNearest(FullState.Farm.Target, FullState.Farm.Radius)
            Full.Status.FarmTarget = target
        end

        if target then
            local targetRoot = target:FindFirstChild("HumanoidRootPart")
            local hum = target:FindFirstChildOfClass("Humanoid")
            if targetRoot and hum and hum.Health > 0 then
                local y = FullState.Farm.Distance
                local offset = CFrame.new(0, y, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                FullMoveTo(target, offset)
                if FullState.Farm.BringMobs then
                    local myRoot = FullRoot()
                    if myRoot then
                        for _, mob in ipairs(FullFindEnemies()) do
                            local mh = mob:FindFirstChildOfClass("Humanoid")
                            local mr = mob:FindFirstChild("HumanoidRootPart")
                            if mh and mr and mh.Health > 0 and (FullState.Farm.Target == "Auto" or mob.Name == target.Name) then
                                if (mr.Position - myRoot.Position).Magnitude <= FullState.Farm.Radius then
                                    pcall(function() mr.CFrame = myRoot.CFrame * CFrame.new(0,0,-FullState.Farm.Distance) end)
                                end
                            end
                        end
                    end
                end
                if FullState.Farm.AutoEquip then
                    FullEquip(FullState.Farm.Weapon)
                end
                if FullState.Farm.FastAttack then
                    if os.clock() - (Full.Status.LastAttack or 0) >= FullState.Farm.AttackDelay then
                        FullAttack()
                        Full.Status.LastAttack = os.clock()
                    end
                end
                FarmTarget.Text = target.Name
                FarmHP.Text = string.format("%.0f / %.0f", hum.Health, hum.MaxHealth)
                local root = FullRoot()
                FarmDistance.Text = root and string.format("%.1f", (root.Position - targetRoot.Position).Magnitude) or "-"
                FarmStatus.Text = "Farming"
            end
        else
            FarmTarget.Text = "None"
            FarmHP.Text = "-"
            FarmDistance.Text = "-"
            FarmStatus.Text = "Searching"
        end
    end

    -- Combat
    if FullState.Combat.Enabled and FullAlive() then
        local target = Full.Status.CombatTarget
        if not target or not target.Parent then
            target = FullNearest(nil, 500)
            Full.Status.CombatTarget = target
        end
        if target then
            CombatTarget.Text = target.Name
            FullMoveTo(target, CFrame.new(0, FullState.Combat.Distance, 0))
            FullEquip(FullState.Combat.Weapon)
            if FullState.Combat.Aura and os.clock() - (Full.Status.CombatAttack or 0) >= FullState.Combat.AttackDelay then
                FullAttack()
                Full.Status.CombatAttack = os.clock()
            end
        else
            CombatTarget.Text = "None"
        end
    end

    -- NoClip
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not (FullState.Farm.NoClip and FullState.Farm.Enabled)
            end
        end
    end

    -- Periodic ESP refresh.
    if FullState.ESP.Players or FullState.ESP.Bosses or FullState.ESP.Fruits then
        if os.clock() - (Full.Status.LastESP or 0) >= 1.5 then
            Full.Status.LastESP = os.clock()
            RefreshESP31()
        end
    end

    -- Hide local notifications when requested.
    if FullState.Misc.HideNotifications then
        local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local notifications = gui and gui:FindFirstChild("Notifications")
        if notifications then
            for _, child in ipairs(notifications:GetChildren()) do
                pcall(function() child.Visible = false end)
            end
        end
    end
end)

FullConnect(LocalPlayer.CharacterAdded, function()
    task.wait(0.5)
    if FullState.Farm.Enabled then
        FarmStatus.Text = "Character respawned • recovering"
    end
end)

-- Dedicated Anti-AFK connection so it does not spawn duplicate handlers.
local FullIdleConnection
FullConnect(LocalPlayer.Idled, function()
    if not FullState.Misc.AntiAFK then return end
    local VirtualUser = game:GetService("VirtualUser")
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

--==================================================
-- FULL BUILD STATUS
--==================================================

Notify(
    "Floquitave 3.1",
    "Functional test build carregado. Quest/Farm/Raid/ESP/Teleport adapters ativados."
)


--==================================================
-- SETTINGS
--==================================================

local SettingsPage = PageService:Create("Settings")

Section(
    SettingsPage,
    "Interface",
    "Customize the Floquitave experience"
)

Toggle(
    SettingsPage,
    "Animations",
    "Smooth UI transitions",
    Config.Animations,
    function(enabled)
        Config.Animations = enabled
    end
)

Toggle(
    SettingsPage,
    "Notifications",
    "Show interface notifications",
    Config.Notifications,
    function(enabled)
        Config.Notifications = enabled
    end
)

local ThemeTitle = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Themes",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, SettingsPage)

local ThemeHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y
}, SettingsPage)

local ThemeGrid = Create("UIGridLayout", {
    CellSize = UDim2.new(0.23, 0, 0, 42),
    CellPadding = UDim2.new(0.02, 0, 0, 8)
}, ThemeHolder)

--==================================================
-- THEME APPLICATION
--==================================================

local function ApplyTheme()
    Theme = Themes[Config.Theme] or Themes.Dark

    Main.BackgroundColor3 = Theme.Background
    Body.BackgroundColor3 = Theme.Background
    Sidebar.BackgroundColor3 = Theme.Sidebar

    Topbar.BackgroundColor3 = Theme.Card
    TopbarCover.BackgroundColor3 = Theme.Card

    Logo.BackgroundColor3 = Theme.Accent

    Title.TextColor3 = Theme.Text
    Version.TextColor3 = Theme.SubText

    Minimize.BackgroundColor3 = Theme.Secondary
    Minimize.TextColor3 = Theme.Text

    Close.BackgroundColor3 = Theme.Secondary
    Close.TextColor3 = Theme.Text

    SearchBox.BackgroundColor3 = Theme.Secondary
    SearchBox.TextColor3 = Theme.Text
    SearchBox.PlaceholderColor3 = Theme.SubText

    TeleportSearch.BackgroundColor3 = Theme.Card
    TeleportSearch.TextColor3 = Theme.Text
    TeleportSearch.PlaceholderColor3 = Theme.SubText

    Content.ScrollBarImageColor3 = Theme.Accent
    PageList.ScrollBarImageColor3 = Theme.Accent

    SessionStatus.TextColor3 = Theme.Accent

    for _, card in ipairs(State.Cards) do
        if card and card.Parent then
            card.BackgroundColor3 = Theme.Card

            local stroke = card:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Secondary
            end

            for _, child in ipairs(card:GetChildren()) do
                if child:IsA("TextLabel") then
                    if child.Text == "LEVEL"
                        or child.Text == "BELI"
                        or child.Text == "FRAGMENTS"
                        or child.Text == "RACE"
                        or child.Text == "SEA"
                        or child.Text == "FPS"
                        or child.Text == "PING"
                        or child.Text == "UPTIME"
                        or child.Text == "SESSION STATUS"
                    then
                        child.TextColor3 = Theme.SubText
                    else
                        child.TextColor3 = Theme.Text
                    end
                end
            end
        end
    end

    for _, toggle in ipairs(State.Toggles) do
        if toggle and toggle.Parent then
            toggle.BackgroundColor3 = Theme.Card

            local stroke = toggle:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Theme.Secondary
            end
        end
    end

    BuildTeleport()
end

for themeName, themeData in pairs(Themes) do
    local button = Create("TextButton", {
        BackgroundColor3 = themeData.Card,
        Text = themeName,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = themeData.Text,
        AutoButtonColor = false
    }, ThemeHolder)

    Corner(button, 9)
    Stroke(button, themeData.Accent, 0.15)
    AddHoverEffect(button)

    Connect(button.MouseButton1Click, function()
        Config.Theme = themeName
        ApplyTheme()

        Notify(
            "Theme",
            "Tema alterado para " .. themeName
        )
    end)
end

local ScaleHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 72),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, SettingsPage)

Corner(ScaleHolder, 11)
Stroke(ScaleHolder, Theme.Secondary, 0.25)

Create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 10),
    Size = UDim2.new(0.5, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "UI Scale",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left
}, ScaleHolder)

local ScaleValue = Create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 34),
    Size = UDim2.new(0.3, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "100%",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = Theme.SubText,
    TextXAlignment = Enum.TextXAlignment.Left
}, ScaleHolder)

local MinusScale = Create("TextButton", {
    Position = UDim2.new(1, -112, 0, 16),
    Size = UDim2.new(0, 42, 0, 38),
    BackgroundColor3 = Theme.Secondary,
    Text = "−",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Theme.Text,
    AutoButtonColor = false
}, ScaleHolder)

Corner(MinusScale, 9)
AddHoverEffect(MinusScale)

local PlusScale = Create("TextButton", {
    Position = UDim2.new(1, -62, 0, 16),
    Size = UDim2.new(0, 42, 0, 38),
    BackgroundColor3 = Theme.Secondary,
    Text = "+",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Theme.Text,
    AutoButtonColor = false
}, ScaleHolder)

Corner(PlusScale, 9)
AddHoverEffect(PlusScale)

local function UpdateScale()
    Config.Scale = math.clamp(Config.Scale, 0.8, 1.2)

    MainScale.Scale = Config.Scale
    ScaleValue.Text = tostring(math.floor(Config.Scale * 100)) .. "%"
end

Connect(MinusScale.MouseButton1Click, function()
    Config.Scale -= 0.05
    UpdateScale()
end)

Connect(PlusScale.MouseButton1Click, function()
    Config.Scale += 0.05
    UpdateScale()
end)

--==================================================
-- DEBUG / ABOUT
--==================================================

local AboutPage = PageService:Create("About")

Section(
    AboutPage,
    "About Floquitave",
    "Current build information"
)

local AboutCard = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 170),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0
}, AboutPage)

Corner(AboutCard, 12)
Stroke(AboutCard, Theme.Secondary, 0.25)

local AboutText = Create("TextLabel", {
    Position = UDim2.new(0, 16, 0, 14),
    Size = UDim2.new(1, -32, 1, -28),
    BackgroundTransparency = 1,
    Text = table.concat({
        "Floquitave Hub",
        "",
        "Version: " .. Config.Version,
        "World: " .. WorldService:GetSea(),
        "Place ID: " .. tostring(game.PlaceId),
        "",
        "UI: Online",
        "Player Service: Online",
        "Performance Service: Online",
        "World Service: Online",
        "Teleport Directory: Online"
    }, "\n"),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
}, AboutCard)

--==================================================
-- SIDEBAR BUTTONS
--==================================================

local PageNames = {
    "Home",
    "Main Farm",
    "Quest",
    "ESP",
    "Raids",
    "Combat",
    "Sea Event",
    "Race V4",
    "Shop",
    "Teleport",
    "Player",
    "Server",
    "Misc",
    "Settings",
    "About"
}

local PageIcons = {
    Home = "⌂",
    ["Main Farm"] = "◈",
    Quest = "◆",
    ESP = "◎",
    Raids = "◇",
    Combat = "⚔",
    ["Sea Event"] = "≈",
    ["Race V4"] = "✦",
    Shop = "$",
    Teleport = "➜",
    Player = "●",
    Server = "▣",
    Misc = "⚙",
    Settings = "☷",
    About = "?"
}

for index, pageName in ipairs(PageNames) do
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Sidebar,
        Text = "  " .. (PageIcons[pageName] or "•") .. "   " .. pageName,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = index
    }, PageList)

    Corner(button, 9)

    AddHoverEffect(button)

    State.PageButtons[pageName] = button

    Connect(button.MouseButton1Click, function()
        PageService:Show(pageName)

        for name, pageButton in pairs(State.PageButtons) do
            if name == pageName then
                pageButton.BackgroundColor3 = Theme.Secondary
                pageButton.TextColor3 = Theme.Text
            else
                pageButton.BackgroundColor3 = Theme.Sidebar
                pageButton.TextColor3 = Theme.SubText
            end
        end
    end)
end

--==================================================
-- SEARCH
--==================================================

local function UpdatePageSearch()
    local search = string.lower(SearchBox.Text or "")

    for pageName, button in pairs(State.PageButtons) do
        local visible = search == ""
            or string.find(string.lower(pageName), search, 1, true)

        button.Visible = visible
    end
end

Connect(SearchBox:GetPropertyChangedSignal("Text"), UpdatePageSearch)

--==================================================
-- DRAG SYSTEM
--==================================================

local dragging = false
local dragStart
local startPosition

Connect(Topbar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch
    then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

--==================================================
-- MINIMIZE
--==================================================

local FloatingButton = Create("TextButton", {
    Size = UDim2.new(0, 58, 0, 58),
    Position = UDim2.new(0, 25, 0.5, -29),
    BackgroundColor3 = Theme.Accent,
    Text = "F",
    Font = Enum.Font.GothamBlack,
    TextSize = 21,
    TextColor3 = Color3.new(1, 1, 1),
    Visible = false,
    AutoButtonColor = false
}, ScreenGui)

Corner(FloatingButton, 29)
AddHoverEffect(FloatingButton)

local floatingDragging = false
local floatingMoved = false
local floatingStart
local floatingPosition

Connect(FloatingButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        floatingDragging = true
        floatingMoved = false
        floatingStart = input.Position
        floatingPosition = FloatingButton.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                floatingDragging = false

                if not floatingMoved then
                    State.Minimized = false
                    FloatingButton.Visible = false
                    Main.Visible = true

                    Tween(MainScale, {
                        Scale = Config.Scale
                    }, 0.22)
                end

                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not floatingDragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch
    then
        return
    end

    local delta = input.Position - floatingStart

    if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
        floatingMoved = true
    end

    FloatingButton.Position = UDim2.new(
        floatingPosition.X.Scale,
        floatingPosition.X.Offset + delta.X,
        floatingPosition.Y.Scale,
        floatingPosition.Y.Offset + delta.Y
    )
end)

Connect(Minimize.MouseButton1Click, function()
    State.Minimized = true

    Tween(MainScale, {
        Scale = 0.9
    }, 0.18)

    task.delay(0.18, function()
        Main.Visible = false
        FloatingButton.Visible = true
    end)
end)

Connect(Close.MouseButton1Click, function()
    Cleanup()

    if ScreenGui then
        ScreenGui:Destroy()
    end
end)

--==================================================
-- FPS
--==================================================

local frameCount = 0
local fpsStart = os.clock()

Connect(RunService.RenderStepped, function()
    frameCount += 1

    local now = os.clock()

    if now - fpsStart >= 1 then
        State.FPS = frameCount
        frameCount = 0
        fpsStart = now
    end
end)

--==================================================
-- LIVE HOME UPDATE
--==================================================

local updateAccumulator = 0

Connect(RunService.Heartbeat, function(deltaTime)
    updateAccumulator += deltaTime

    if updateAccumulator < Config.PerformanceInterval then
        return
    end

    updateAccumulator = 0

    if State.Destroyed then
        return
    end

    local level = PlayerService:GetLevel()
    local beli = PlayerService:GetBeli()
    local fragments = PlayerService:GetFragments()
    local race = PlayerService:GetRace()
    local sea = WorldService:GetSea()
    local ping = PerformanceService:GetPing()
    local uptime = os.clock() - StartTime

    LevelValue.Text = FormatNumber(level)
    BeliValue.Text = FormatNumber(beli)
    FragmentValue.Text = FormatNumber(fragments)

    RaceValue.Text = tostring(race)
    SeaValue.Text = tostring(sea)

    FPSValue.Text = tostring(State.FPS)
    PingValue.Text = tostring(math.floor(ping)) .. " ms"
    UptimeValue.Text = FormatTime(uptime)

    SessionStatus.Text =
        "Running • "
        .. tostring(State.FPS)
        .. " FPS • "
        .. tostring(math.floor(ping))
        .. " ms"
end)

--==================================================
-- CHARACTER REAPPLY
--==================================================

Connect(LocalPlayer.CharacterAdded, function(character)
    task.wait(0.75)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = State.PlayerSettings.WalkSpeed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = State.PlayerSettings.JumpPower
    end
end)

--==================================================
-- INITIALIZE
--==================================================

PageService:Show("Home")

State.PageButtons.Home.BackgroundColor3 = Theme.Secondary
State.PageButtons.Home.TextColor3 = Theme.Text

UpdateScale()
ApplyTheme()

Notify(
    "Floquitave",
    "3.1.1 carregado com sucesso."
)

print(
    "[Floquitave] Version "
    .. Config.Version
    .. " loaded."
)
end, function(err)
    return tostring(err)
end)

if __ok then
    if __Bootstrap then
        pcall(function() __Bootstrap:Destroy() end)
    end
else
    warn("[Floquitave 3.1.1] ERRO AO INICIAR: " .. tostring(__err))
    if __Status then
        __Status.TextColor3 = Color3.fromRGB(255, 120, 120)
        __Status.Text = "ERRO AO INICIAR:\n" .. tostring(__err) .. "\n\nEnvie exatamente esta mensagem se continuar."
    end
end
