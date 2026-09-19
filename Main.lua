--[[
    Nova Hub V2
    UI / diagnostic foundation for Roblox/Luau

    V2 changes:
    - Improved dashboard
    - Level / Beli / Fragments / Race / Sea
    - Health / Energy
    - FPS / Ping
    - Better update intervals
    - Cleaner shutdown
    - Search box
    - Improved sidebar
    - UI state handling
    - Notifications
]]

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--// =========================================================
--// CONFIG
--// =========================================================

local Config = {
    Name = "Nova Hub",
    Version = "2.0.0",

    Theme = {
        Background = Color3.fromRGB(12, 13, 17),
        Secondary = Color3.fromRGB(17, 18, 24),
        Tertiary = Color3.fromRGB(23, 24, 31),

        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(150, 152, 163),

        Accent = Color3.fromRGB(115, 90, 255),
        AccentDark = Color3.fromRGB(82, 62, 190),

        Success = Color3.fromRGB(75, 210, 130),
        Warning = Color3.fromRGB(245, 190, 75),
        Error = Color3.fromRGB(235, 80, 90),

        Border = Color3.fromRGB(40, 41, 50),
    },

    UI = {
        Width = 920,
        Height = 590,

        CornerRadius = 10,
        AnimationSpeed = 0.20,

        Notifications = true,
        Animations = true,

        UpdateInterval = 0.5,
    }
}

--// =========================================================
--// STATE
--// =========================================================

local State = {
    CurrentTab = "Home",
    Minimized = false,
    Destroyed = false,

    FPS = 0,
    Ping = 0,

    Sea = "Unknown",

    Connections = {},
    Pages = {},
    Buttons = {},

    Toggles = {},
}

--// =========================================================
--// UTILITY
--// =========================================================

local Utility = {}

function Utility.Tween(object, properties, duration)
    if not Config.UI.Animations then
        for property, value in pairs(properties) do
            object[property] = value
        end

        return nil
    end

    local info = TweenInfo.new(
        duration or Config.UI.AnimationSpeed,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

    return TweenService:Create(object, info, properties)
end

function Utility.Create(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

function Utility.Corner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Config.UI.CornerRadius)
    corner.Parent = object

    return corner
end

function Utility.Stroke(object, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.2
    stroke.Parent = object

    return stroke
end

function Utility.Padding(object, value)
    local padding = Instance.new("UIPadding")

    padding.PaddingTop = UDim.new(0, value)
    padding.PaddingBottom = UDim.new(0, value)
    padding.PaddingLeft = UDim.new(0, value)
    padding.PaddingRight = UDim.new(0, value)

    padding.Parent = object

    return padding
end

function Utility.SafeDestroy(object)
    if object and object.Parent then
        object:Destroy()
    end
end

--// =========================================================
--// WORLD SERVICE
--// =========================================================

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

function WorldService:Update()
    State.Sea = self:GetSea()
end

WorldService:Update()

--// =========================================================
--// PLAYER SERVICE
--// =========================================================

local PlayerService = {}

function PlayerService:GetData()
    return LocalPlayer:FindFirstChild("Data")
end

function PlayerService:GetValue(name, default)
    local data = self:GetData()

    if not data then
        return default
    end

    local value = data:FindFirstChild(name)

    if value then
        return value.Value
    end

    return default
end

function PlayerService:GetLevel()
    return self:GetValue("Level", 0)
end

function PlayerService:GetBeli()
    return self:GetValue("Beli", 0)
end

function PlayerService:GetFragments()
    return self:GetValue("Fragments", 0)
end

function PlayerService:GetRace()
    return self:GetValue("Race", "Unknown")
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

function PlayerService:GetHealth()
    local humanoid = self:GetHumanoid()

    if not humanoid then
        return 0, 0
    end

    return humanoid.Health, humanoid.MaxHealth
end

function PlayerService:GetEnergy()
    local character = self:GetCharacter()

    if not character then
        return 0
    end

    local energy = character:FindFirstChild("Energy")

    if energy and energy:IsA("NumberValue") then
        return energy.Value
    end

    return 0
end

--// =========================================================
--// PERFORMANCE SERVICE
--// =========================================================

local PerformanceService = {}

function PerformanceService:GetPing()
    local success, result = pcall(function()
        local network = Stats:FindFirstChild("Network")

        if network then
            local serverStats = network:FindFirstChild("ServerStatsItem")

            if serverStats then
                local dataPing = serverStats:FindFirstChild("Data Ping")

                if dataPing then
                    local value = dataPing:GetValueString()
                    return tonumber(string.match(value, "%d+")) or 0
                end
            end
        end

        return 0
    end)

    if success then
        return result
    end

    return 0
end

--// =========================================================
--// NOTIFICATION SERVICE
--// =========================================================

local NotificationService = {
    Container = nil
}

function NotificationService:Init(parent)
    self.Container = Utility.Create("Frame", {
        Name = "Notifications",
        Parent = parent,

        BackgroundTransparency = 1,

        Size = UDim2.new(0, 310, 1, -30),
        Position = UDim2.new(1, -325, 0, 15),

        ZIndex = 100,
    })

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    layout.Parent = self.Container
end

function NotificationService:Notify(title, message, duration)
    if not Config.UI.Notifications then
        return
    end

    if not self.Container then
        return
    end

    duration = duration or 3

    local notification = Utility.Create("Frame", {
        Parent = self.Container,

        BackgroundColor3 = Config.Theme.Secondary,
        BackgroundTransparency = 0.05,

        Size = UDim2.new(0, 290, 0, 75),

        ZIndex = 101,
    })

    Utility.Corner(notification, 8)
    Utility.Stroke(notification, Config.Theme.Border)

    local accent = Utility.Create("Frame", {
        Parent = notification,

        BackgroundColor3 = Config.Theme.Accent,
        BorderSizePixel = 0,

        Size = UDim2.new(0, 3, 1, 0),

        ZIndex = 102,
    })

    Utility.Corner(accent, 4)

    Utility.Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -25, 0, 20),

        Font = Enum.Font.GothamBold,

        Text = title,

        TextColor3 = Config.Theme.Text,
        TextSize = 14,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 103,
    })

    Utility.Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 16, 0, 34),
        Size = UDim2.new(1, -25, 0, 30),

        Font = Enum.Font.Gotham,

        Text = message,

        TextColor3 = Config.Theme.SubText,
        TextSize = 12,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,

        ZIndex = 103,
    })

    notification.Position = UDim2.new(1, 30, 0, 0)

    local tween = Utility.Tween(
        notification,
        {
            Position = UDim2.new(0, 0, 0, 0)
        }
    )

    if tween then
        tween:Play()
    end

    task.delay(duration, function()
        if State.Destroyed then
            return
        end

        if not notification.Parent then
            return
        end

        local exitTween = Utility.Tween(
            notification,
            {
                Position = UDim2.new(1, 30, 0, 0)
            }
        )

        if exitTween then
            exitTween:Play()

            exitTween.Completed:Connect(function()
                Utility.SafeDestroy(notification)
            end)
        else
            Utility.SafeDestroy(notification)
        end
    end)
end

--// =========================================================
--// CLEANUP
--// =========================================================

local function Cleanup()
    if State.Destroyed then
        return
    end

    State.Destroyed = true

    for _, connection in pairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(State.Connections)
    table.clear(State.Pages)
    table.clear(State.Buttons)
    table.clear(State.Toggles)
end

--// =========================================================
--// GUI
--// =========================================================

local ScreenGui = Utility.Create("ScreenGui", {
    Name = "NovaHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

ScreenGui.Parent = game:GetService("CoreGui")

State.Connections.GuiDestroy = ScreenGui.Destroying:Connect(function()
    Cleanup()
end)

--// =========================================================
--// MAIN WINDOW
--// =========================================================

local Main = Utility.Create("Frame", {
    Parent = ScreenGui,

    BackgroundColor3 = Config.Theme.Background,

    Position = UDim2.new(
        0.5,
        -Config.UI.Width / 2,
        0.5,
        -Config.UI.Height / 2
    ),

    Size = UDim2.new(
        0,
        Config.UI.Width,
        0,
        Config.UI.Height
    ),
})

Utility.Corner(Main, 12)
Utility.Stroke(Main, Config.Theme.Border)

--// =========================================================
--// TOPBAR
--// =========================================================

local Topbar = Utility.Create("Frame", {
    Parent = Main,

    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,

    Size = UDim2.new(1, 0, 0, 55),
})

Utility.Corner(Topbar, 12)

Utility.Create("Frame", {
    Parent = Topbar,

    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,

    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
})

local Logo = Utility.Create("Frame", {
    Parent = Topbar,

    BackgroundColor3 = Config.Theme.Accent,

    Position = UDim2.new(0, 15, 0.5, -15),
    Size = UDim2.new(0, 30, 0, 30),
})

Utility.Corner(Logo, 8)

Utility.Create("TextLabel", {
    Parent = Logo,

    BackgroundTransparency = 1,

    Size = UDim2.new(1, 0, 1, 0),

    Font = Enum.Font.GothamBold,

    Text = "N",

    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
})

Utility.Create("TextLabel", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 55, 0, 8),
    Size = UDim2.new(0, 250, 0, 22),

    Font = Enum.Font.GothamBold,

    Text = Config.Name,

    TextColor3 = Config.Theme.Text,
    TextSize = 15,

    TextXAlignment = Enum.TextXAlignment.Left,
})

Utility.Create("TextLabel", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 55, 0, 28),
    Size = UDim2.new(0, 250, 0, 16),

    Font = Enum.Font.Gotham,

    Text = "Version " .. Config.Version,

    TextColor3 = Config.Theme.SubText,
    TextSize = 10,

    TextXAlignment = Enum.TextXAlignment.Left,
})

--// Search

local SearchBox = Utility.Create("TextBox", {
    Parent = Topbar,

    BackgroundColor3 = Config.Theme.Tertiary,

    Position = UDim2.new(1, -330, 0.5, -16),
    Size = UDim2.new(0, 180, 0, 32),

    ClearTextOnFocus = false,

    Font = Enum.Font.Gotham,

    PlaceholderText = "Search...",
    PlaceholderColor3 = Config.Theme.SubText,

    Text = "",
    TextColor3 = Config.Theme.Text,
    TextSize = 11,

    TextXAlignment = Enum.TextXAlignment.Left,
})

Utility.Corner(SearchBox, 7)
Utility.Padding(SearchBox, 10)

--// Window buttons

local Minimize = Utility.Create("TextButton", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(1, -125, 0, 0),
    Size = UDim2.new(0, 40, 1, 0),

    Font = Enum.Font.GothamBold,

    Text = "—",

    TextColor3 = Config.Theme.SubText,
    TextSize = 18,

    AutoButtonColor = false,
})

local Close = Utility.Create("TextButton", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(1, -45, 0, 0),
    Size = UDim2.new(0, 40, 1, 0),

    Font = Enum.Font.GothamBold,

    Text = "×",

    TextColor3 = Config.Theme.SubText,
    TextSize = 20,

    AutoButtonColor = false,
})

Close.MouseButton1Click:Connect(function()
    Cleanup()
    Utility.SafeDestroy(ScreenGui)
end)

--// =========================================================
--// SIDEBAR
--// =========================================================

local Sidebar = Utility.Create("Frame", {
    Parent = Main,

    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,

    Position = UDim2.new(0, 0, 0, 55),

    Size = UDim2.new(0, 195, 1, -55),
})

Utility.Padding(Sidebar, 12)

local SidebarLayout = Utility.Create("UIListLayout", {
    Parent = Sidebar,

    Padding = UDim.new(0, 5),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

Utility.Create("TextLabel", {
    Parent = Sidebar,

    BackgroundTransparency = 1,

    Size = UDim2.new(1, 0, 0, 25),

    Font = Enum.Font.GothamBold,

    Text = "NAVIGATION",

    TextColor3 = Config.Theme.SubText,
    TextSize = 10,

    TextXAlignment = Enum.TextXAlignment.Left,

    LayoutOrder = 0,
})

--// =========================================================
--// CONTENT
--// =========================================================

local Content = Utility.Create("Frame", {
    Parent = Main,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 195, 0, 55),

    Size = UDim2.new(1, -195, 1, -55),
})

local PageContainer = Utility.Create("Frame", {
    Parent = Content,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 20, 0, 15),

    Size = UDim2.new(1, -40, 1, -30),
})

--// =========================================================
--// PAGE SERVICE
--// =========================================================

local PageService = {}

function PageService:Create(name)
    local page = Utility.Create("ScrollingFrame", {
        Parent = PageContainer,

        Name = name,

        BackgroundTransparency = 1,

        Size = UDim2.new(1, 0, 1, 0),

        CanvasSize = UDim2.new(0, 0, 0, 0),

        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        ScrollBarThickness = 3,

        ScrollBarImageColor3 = Config.Theme.Accent,

        Visible = false,

        BorderSizePixel = 0,

        ScrollingDirection = Enum.ScrollingDirection.Y,
    })

    Utility.Padding(page, 2)

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0, 10)

    layout.SortOrder = Enum.SortOrder.LayoutOrder

    layout.Parent = page

    State.Pages[name] = page

    return page
end

function PageService:Show(name)
    if not State.Pages[name] then
        return
    end

    for pageName, page in pairs(State.Pages) do
        page.Visible = pageName == name
    end

    State.CurrentTab = name

    for buttonName, button in pairs(State.Buttons) do
        if buttonName == name then
            button.BackgroundColor3 = Config.Theme.Accent
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = Config.Theme.Secondary
            button.TextColor3 = Config.Theme.SubText
        end
    end
end

--// =========================================================
--// COMPONENTS
--// =========================================================

local Components = {}

function Components.Section(parent, title, description)
    local container = Utility.Create("Frame", {
        Parent = parent,

        BackgroundColor3 = Config.Theme.Secondary,

        Size = UDim2.new(1, -5, 0, description and 65 or 45),
    })

    Utility.Corner(container, 8)
    Utility.Stroke(container, Config.Theme.Border)

    Utility.Create("TextLabel", {
        Parent = container,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 15, 0, 10),

        Size = UDim2.new(1, -30, 0, 20),

        Font = Enum.Font.GothamBold,

        Text = title,

        TextColor3 = Config.Theme.Text,
        TextSize = 14,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if description then
        Utility.Create("TextLabel", {
            Parent = container,

            BackgroundTransparency = 1,

            Position = UDim2.new(0, 15, 0, 32),

            Size = UDim2.new(1, -30, 0, 20),

            Font = Enum.Font.Gotham,

            Text = description,

            TextColor3 = Config.Theme.SubText,
            TextSize = 11,

            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end

    return container
end

function Components.Card(parent, title, value)
    local card = Utility.Create("Frame", {
        Parent = parent,

        BackgroundColor3 = Config.Theme.Secondary,

        Size = UDim2.new(0, 185, 0, 82),
    })

    Utility.Corner(card, 8)
    Utility.Stroke(card, Config.Theme.Border)

    Utility.Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 14, 0, 10),

        Size = UDim2.new(1, -28, 0, 18),

        Font = Enum.Font.Gotham,

        Text = title,

        TextColor3 = Config.Theme.SubText,
        TextSize = 10,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = Utility.Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 14, 0, 32),

        Size = UDim2.new(1, -28, 0, 32),

        Font = Enum.Font.GothamBold,

        Text = tostring(value),

        TextColor3 = Config.Theme.Text,
        TextSize = 18,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    return card, valueLabel
end

function Components.Toggle(parent, title, description, callback)
    local holder = Utility.Create("Frame", {
        Parent = parent,

        BackgroundColor3 = Config.Theme.Tertiary,

        Size = UDim2.new(1, -20, 0, 55),
    })

    Utility.Corner(holder, 7)

    Utility.Create("TextLabel", {
        Parent = holder,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 12, 0, 7),

        Size = UDim2.new(1, -75, 0, 20),

        Font = Enum.Font.GothamMedium,

        Text = title,

        TextColor3 = Config.Theme.Text,
        TextSize = 12,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    Utility.Create("TextLabel", {
        Parent = holder,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 12, 0, 27),

        Size = UDim2.new(1, -75, 0, 18),

        Font = Enum.Font.Gotham,

        Text = description or "",

        TextColor3 = Config.Theme.SubText,
        TextSize = 9,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local button = Utility.Create("TextButton", {
        Parent = holder,

        BackgroundColor3 = Config.Theme.Border,

        Position = UDim2.new(1, -55, 0.5, -12),

        Size = UDim2.new(0, 42, 0, 24),

        Text = "",

        AutoButtonColor = false,
    })

    Utility.Corner(button, 12)

    local indicator = Utility.Create("Frame", {
        Parent = button,

        BackgroundColor3 = Config.Theme.SubText,

        Position = UDim2.new(0, 4, 0.5, -8),

        Size = UDim2.new(0, 16, 0, 16),
    })

    Utility.Corner(indicator, 10)

    local enabled = false

    State.Toggles[title] = false

    button.MouseButton1Click:Connect(function()
        enabled = not enabled

        State.Toggles[title] = enabled

        if enabled then
            local tween = Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Accent
            })

            if tween then
                tween:Play()
            end

            local indicatorTween = Utility.Tween(indicator, {
                Position = UDim2.new(1, -20, 0.5, -8),
                BackgroundColor3 = Color3.new(1, 1, 1)
            })

            if indicatorTween then
                indicatorTween:Play()
            end
        else
            local tween = Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Border
            })

            if tween then
                tween:Play()
            end

            local indicatorTween = Utility.Tween(indicator, {
                Position = UDim2.new(0, 4, 0.5, -8),
                BackgroundColor3 = Config.Theme.SubText
            })

            if indicatorTween then
                indicatorTween:Play()
            end
        end

        if callback then
            pcall(callback, enabled)
        end
    end)

    return holder
end

--// =========================================================
--// PAGES
--// =========================================================

local HomePage = PageService:Create("Home")
local FarmPage = PageService:Create("Main Farm")
local QuestPage = PageService:Create("Quest")
local RaidPage = PageService:Create("Raids")
local CombatPage = PageService:Create("Combat")
local TeleportPage = PageService:Create("Teleport")
local PlayerPage = PageService:Create("Player")
local MiscPage = PageService:Create("Misc")
local SettingsPage = PageService:Create("Settings")

--// =========================================================
--// HOME
--// =========================================================

Components.Section(
    HomePage,
    "Dashboard",
    "Nova Hub V2 • Runtime information"
)

local Cards = Utility.Create("Frame", {
    Parent = HomePage,

    BackgroundTransparency = 1,

    Size = UDim2.new(1, -5, 0, 175),
})

local CardLayout = Instance.new("UIGridLayout")

CardLayout.CellSize = UDim2.new(0, 185, 0, 82)
CardLayout.CellPadding = UDim2.new(0, 10, 0, 10)

CardLayout.Parent = Cards

local LevelCard, LevelValue = Components.Card(
    Cards,
    "LEVEL",
    PlayerService:GetLevel()
)

local BeliCard, BeliValue = Components.Card(
    Cards,
    "BELI",
    PlayerService:GetBeli()
)

local FragmentCard, FragmentValue = Components.Card(
    Cards,
    "FRAGMENTS",
    PlayerService:GetFragments()
)

local RaceCard, RaceValue = Components.Card(
    Cards,
    "RACE",
    PlayerService:GetRace()
)

local SeaCard, SeaValue = Components.Card(
    Cards,
    "SEA",
    State.Sea
)

local FPSCard, FPSValue = Components.Card(
    Cards,
    "FPS",
    State.FPS
)

local PingCard, PingValue = Components.Card(
    Cards,
    "PING",
    "0 ms"
)

local HealthCard, HealthValue = Components.Card(
    Cards,
    "HEALTH",
    "0 / 0"
)

local EnergyCard, EnergyValue = Components.Card(
    Cards,
    "ENERGY",
    "0"
)

--// System status

local Status = Components.Section(
    HomePage,
    "System Status",
    "Current runtime state"
)

Status.Size = UDim2.new(1, -5, 0, 105)

local StatusLabel = Utility.Create("TextLabel", {
    Parent = Status,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 15, 0, 65),

    Size = UDim2.new(1, -30, 0, 30),

    Font = Enum.Font.Gotham,

    Text = "Initializing...",

    TextColor3 = Config.Theme.Success,
    TextSize = 11,

    TextXAlignment = Enum.TextXAlignment.Left,
})

--// =========================================================
--// TEST MODULE PAGES
--// =========================================================

Components.Section(
    FarmPage,
    "Main Farm",
    "Module interface ready for future implementation."
)

Components.Toggle(
    FarmPage,
    "Auto Farm",
    "Test state only",
    function(enabled)
        NotificationService:Notify(
            "Auto Farm",
            enabled and "Enabled" or "Disabled"
        )
    end
)

Components.Toggle(
    FarmPage,
    "Auto Mastery",
    "Test state only",
    function(enabled)
        NotificationService:Notify(
            "Auto Mastery",
            enabled and "Enabled" or "Disabled"
        )
    end
)

Components.Section(
    QuestPage,
    "Quest System",
    "Quest module interface"
)

Components.Toggle(
    QuestPage,
    "Auto Quest",
    "Test state only",
    function(enabled)
        NotificationService:Notify(
            "Quest",
            enabled and "Enabled" or "Disabled"
        )
    end
)

Components.Section(
    RaidPage,
    "Raid System",
    "Raid module interface"
)

Components.Toggle(
    RaidPage,
    "Auto Raid",
    "Test state only",
    function(enabled)
        NotificationService:Notify(
            "Raid",
            enabled and "Enabled" or "Disabled"
        )
    end
)

Components.Section(
    CombatPage,
    "Combat",
    "Combat module interface"
)

Components.Toggle(
    CombatPage,
    "Combat Assist",
    "Test state only",
    function(enabled)
        NotificationService:Notify(
            "Combat",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--// =========================================================
--// TELEPORT PAGE
--// =========================================================

Components.Section(
    TeleportPage,
    "Teleport",
    "Destination interface"
)

Components.Section(
    TeleportPage,
    "First Sea",
    "Destination registry ready."
)

Components.Section(
    TeleportPage,
    "Second Sea",
    "Destination registry ready."
)

Components.Section(
    TeleportPage,
    "Third Sea",
    "Destination registry ready."
)

--// =========================================================
--// PLAYER PAGE
--// =========================================================

Components.Section(
    PlayerPage,
    "Player",
    "Local character information"
)

Components.Toggle(
    PlayerPage,
    "Anti AFK",
    "Interface state only",
    function(enabled)
        NotificationService:Notify(
            "Anti AFK",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--// =========================================================
--// MISC PAGE
--// =========================================================

Components.Section(
    MiscPage,
    "Miscellaneous",
    "Additional interface utilities"
)

Components.Toggle(
    MiscPage,
    "Notifications",
    "Enable or disable notifications",
    function(enabled)
        Config.UI.Notifications = enabled
    end
)

--// =========================================================
--// SETTINGS
--// =========================================================

Components.Section(
    SettingsPage,
    "Interface",
    "Nova Hub interface configuration"
)

Components.Toggle(
    SettingsPage,
    "UI Animations",
    "Enable interface animations",
    function(enabled)
        Config.UI.Animations = enabled

        NotificationService:Notify(
            "Settings",
            enabled and "Animations enabled" or "Animations disabled"
        )
    end
)

Components.Toggle(
    SettingsPage,
    "Notifications",
    "Enable hub notifications",
    function(enabled)
        Config.UI.Notifications = enabled
    end
)

--// =========================================================
--// SIDEBAR
--// =========================================================

local Tabs = {
    "Home",
    "Main Farm",
    "Quest",
    "Raids",
    "Combat",
    "Teleport",
    "Player",
    "Misc",
    "Settings",
}

for index, tabName in ipairs(Tabs) do
    local button = Utility.Create("TextButton", {
        Parent = Sidebar,

        BackgroundColor3 = Config.Theme.Secondary,

        Size = UDim2.new(1, 0, 0, 38),

        AutoButtonColor = false,

        Font = Enum.Font.GothamMedium,

        Text = "  " .. tabName,

        TextColor3 = Config.Theme.SubText,
        TextSize = 11,

        TextXAlignment = Enum.TextXAlignment.Left,

        LayoutOrder = index,
    })

    Utility.Corner(button, 7)

    State.Buttons[tabName] = button

    button.MouseEnter:Connect(function()
        if State.CurrentTab ~= tabName then
            local tween = Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Tertiary
            })

            if tween then
                tween:Play()
            end
        end
    end)

    button.MouseLeave:Connect(function()
        if State.CurrentTab ~= tabName then
            local tween = Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Secondary
            })

            if tween then
                tween:Play()
            end
        end
    end)

    button.MouseButton1Click:Connect(function()
        PageService:Show(tabName)
    end)
end

--// =========================================================
--// SEARCH
--// =========================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(SearchBox.Text)

    for name, button in pairs(State.Buttons) do
        local visible = query == "" or string.find(
            string.lower(name),
            query,
            1,
            true
        ) ~= nil

        button.Visible = visible
    end
end)

--// =========================================================
--// DRAGGING
--// =========================================================

local dragging = false
local dragStart
local startPosition

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true

        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

State.Connections.Drag = UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,

            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

--// =========================================================
--// MINIMIZE
--// =========================================================

Minimize.MouseButton1Click:Connect(function()
    State.Minimized = not State.Minimized

    if State.Minimized then
        local tween = Utility.Tween(Main, {
            Size = UDim2.new(
                0,
                Config.UI.Width,
                0,
                55
            )
        })

        if tween then
            tween:Play()
        end

        Sidebar.Visible = false
        Content.Visible = false
    else
        local tween = Utility.Tween(Main, {
            Size = UDim2.new(
                0,
                Config.UI.Width,
                0,
                Config.UI.Height
            )
        })

        if tween then
            tween:Play()
        end

        task.delay(
            Config.UI.AnimationSpeed,
            function()
                if State.Destroyed then
                    return
                end

                Sidebar.Visible = true
                Content.Visible = true
            end
        )
    end
end)

--// =========================================================
--// FPS
--// =========================================================

local frameCounter = 0
local lastFPSUpdate = os.clock()

State.Connections.FPS = RunService.RenderStepped:Connect(function()
    frameCounter += 1

    local now = os.clock()

    if now - lastFPSUpdate >= 1 then
        State.FPS = frameCounter

        frameCounter = 0
        lastFPSUpdate = now
    end
end)

--// =========================================================
--// DATA UPDATE
--// =========================================================

State.Connections.Data = RunService.Heartbeat:Connect(function()
    if State.Destroyed then
        return
    end

    local now = os.clock()

    State.LastDataUpdate = State.LastDataUpdate or 0

    if now - State.LastDataUpdate < Config.UI.UpdateInterval then
        return
    end

    State.LastDataUpdate = now

    pcall(function()
        WorldService:Update()

        local health, maxHealth = PlayerService:GetHealth()
        local energy = PlayerService:GetEnergy()

        LevelValue.Text = tostring(PlayerService:GetLevel())
        BeliValue.Text = tostring(PlayerService:GetBeli())
        FragmentValue.Text = tostring(PlayerService:GetFragments())
        RaceValue.Text = tostring(PlayerService:GetRace())

        SeaValue.Text = State.Sea

        FPSValue.Text = tostring(State.FPS)

        State.Ping = PerformanceService:GetPing()

        PingValue.Text = tostring(State.Ping) .. " ms"

        HealthValue.Text =
            tostring(math.floor(health)) ..
            " / " ..
            tostring(math.floor(maxHealth))

        EnergyValue.Text = tostring(math.floor(energy))

        StatusLabel.Text =
            "Online • " ..
            State.Sea ..
            " • FPS: " ..
            tostring(State.FPS) ..
            " • Ping: " ..
            tostring(State.Ping) ..
            " ms"
    end)
end)

--// =========================================================
--// INITIALIZATION
--// =========================================================

PageService:Show("Home")

NotificationService:Init(ScreenGui)

task.wait(0.3)

NotificationService:Notify(
    Config.Name,
    "V2 interface initialized successfully.",
    4
)

print(
    "[" ..
    Config.Name ..
    "] V" ..
    Config.Version ..
    " initialized."
)
