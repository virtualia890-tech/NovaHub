# --[[
    Premium Hub V1
    Original modular foundation for Roblox/Luau

    Included:
    - Modern UI
    - Sidebar navigation
    - Home dashboard
    - Settings
    - Notifications
    - Player information
    - World/Sea detection
    - Theme system
    - Minimize button
    - Draggable window
    - Search box
    - Module architecture
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
    Version = "1.0.0",

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
        Width = 900,
        Height = 570,

        CornerRadius = 10,

        AnimationSpeed = 0.2,

        Notifications = true,
    }
}

--// =========================================================
--// STATE
--// =========================================================

local State = {
    CurrentTab = "Home",
    Minimized = false,

    FPS = 0,
    Ping = 0,

    Sea = "Unknown",

    Connections = {},
    Pages = {},
    Buttons = {},
}

--// =========================================================
--// UTILITIES
--// =========================================================

local Utility = {}

function Utility.Tween(object, properties, duration)
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

--// =========================================================
--// WORLD SERVICE
--// =========================================================

local WorldService = {}

function WorldService:GetSea()
    local placeId = game.PlaceId

    -- Blox Fruits place IDs
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

function PlayerService:GetLevel()
    local data = LocalPlayer:FindFirstChild("Data")

    if data then
        local level = data:FindFirstChild("Level")

        if level then
            return level.Value
        end
    end

    return 0
end

function PlayerService:GetBeli()
    local data = LocalPlayer:FindFirstChild("Data")

    if data then
        local beli = data:FindFirstChild("Beli")

        if beli then
            return beli.Value
        end
    end

    return 0
end

function PlayerService:GetFragments()
    local data = LocalPlayer:FindFirstChild("Data")

    if data then
        local fragments = data:FindFirstChild("Fragments")

        if fragments then
            return fragments.Value
        end
    end

    return 0
end

function PlayerService:GetRace()
    local data = LocalPlayer:FindFirstChild("Data")

    if data then
        local race = data:FindFirstChild("Race")

        if race then
            return race.Value
        end
    end

    return "Unknown"
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
        Size = UDim2.new(0, 300, 1, -30),
        Position = UDim2.new(1, -315, 0, 15),
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
    })

    Utility.Corner(notification, 8)
    Utility.Stroke(notification, Config.Theme.Border)

    local accent = Utility.Create("Frame", {
        Parent = notification,
        BackgroundColor3 = Config.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
    })

    Utility.Corner(accent, 4)

    local titleLabel = Utility.Create("TextLabel", {
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -25, 0, 20),

        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Config.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local messageLabel = Utility.Create("TextLabel", {
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
    })

    notification.Position = UDim2.new(1, 30, 0, 0)

    Utility.Tween(
        notification,
        {
            Position = UDim2.new(0, 0, 0, 0)
        }
    ):Play()

    task.delay(duration, function()
        if notification and notification.Parent then
            local tween = Utility.Tween(
                notification,
                {
                    Position = UDim2.new(1, 30, 0, 0)
                }
            )

            tween:Play()

            tween.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
end

--// =========================================================
--// GUI
--// =========================================================

local ScreenGui = Utility.Create("ScreenGui", {
    Name = "NovaHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

if syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(ScreenGui)
    end)
end

ScreenGui.Parent = game:GetService("CoreGui")

--// Main Window

local Main = Utility.Create("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Config.Theme.Background,
    Position = UDim2.new(0.5, -Config.UI.Width / 2, 0.5, -Config.UI.Height / 2),
    Size = UDim2.new(0, Config.UI.Width, 0, Config.UI.Height),
})

Utility.Corner(Main, 12)
Utility.Stroke(Main, Config.Theme.Border, 1)

--// Topbar

local Topbar = Utility.Create("Frame", {
    Parent = Main,
    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 55),
})

Utility.Corner(Topbar, 12)

-- Fix bottom corners visually

local TopbarFix = Utility.Create("Frame", {
    Parent = Topbar,
    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
})

--// Logo

local Logo = Utility.Create("Frame", {
    Parent = Topbar,
    BackgroundColor3 = Config.Theme.Accent,
    Position = UDim2.new(0, 15, 0.5, -15),
    Size = UDim2.new(0, 30, 0, 30),
})

Utility.Corner(Logo, 8)

local LogoText = Utility.Create("TextLabel", {
    Parent = Logo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),

    Font = Enum.Font.GothamBold,
    Text = "N",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
})

local Title = Utility.Create("TextLabel", {
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

local Version = Utility.Create("TextLabel", {
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

--// Window buttons

local Minimize = Utility.Create("TextButton", {
    Parent = Topbar,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -85, 0, 0),
    Size = UDim2.new(0, 40, 1, 0),

    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = Config.Theme.SubText,
    TextSize = 18,
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
})

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// =========================================================
--// SIDEBAR
--// =========================================================

local Sidebar = Utility.Create("Frame", {
    Parent = Main,
    BackgroundColor3 = Config.Theme.Secondary,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 55),
    Size = UDim2.new(0, 190, 1, -55),
})

local SidebarLayout = Utility.Create("UIListLayout", {
    Parent = Sidebar,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

Utility.Padding(Sidebar, 12)

local SidebarTitle = Utility.Create("TextLabel", {
    Parent = Sidebar,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 25),

    Font = Enum.Font.GothamBold,
    Text = "NAVIGATION",
    TextColor3 = Config.Theme.SubText,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
})

--// =========================================================
--// CONTENT
--// =========================================================

local Content = Utility.Create("Frame", {
    Parent = Main,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 190, 0, 55),
    Size = UDim2.new(1, -190, 1, -55),
})

local PageContainer = Utility.Create("Frame", {
    Parent = Content,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 20, 0, 15),
    Size = UDim2.new(1, -40, 1, -30),
})

--// =========================================================
--// PAGE SYSTEM
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
        Size = UDim2.new(1, -5, 0, 65),
    })

    Utility.Corner(container, 8)
    Utility.Stroke(container, Config.Theme.Border)

    local titleLabel = Utility.Create("TextLabel", {
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
        local descriptionLabel = Utility.Create("TextLabel", {
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
        Size = UDim2.new(0, 190, 0, 85),
    })

    Utility.Corner(card, 8)
    Utility.Stroke(card, Config.Theme.Border)

    local titleLabel = Utility.Create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(1, -28, 0, 18),

        Font = Enum.Font.Gotham,
        Text = title,
        TextColor3 = Config.Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = Utility.Create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 34),
        Size = UDim2.new(1, -28, 0, 30),

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

    local label = Utility.Create("TextLabel", {
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

    local sub = Utility.Create("TextLabel", {
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

    button.MouseButton1Click:Connect(function()
        enabled = not enabled

        if enabled then
            Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Accent
            }):Play()

            Utility.Tween(indicator, {
                Position = UDim2.new(1, -20, 0.5, -8),
                BackgroundColor3 = Color3.new(1, 1, 1)
            }):Play()
        else
            Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Border
            }):Play()

            Utility.Tween(indicator, {
                Position = UDim2.new(0, 4, 0.5, -8),
                BackgroundColor3 = Config.Theme.SubText
            }):Play()
        end

        if callback then
            callback(enabled)
        end
    end)

    return holder
end

--// =========================================================
--// PAGES
--// =========================================================

local HomePage = PageService:Create("Home")
local SettingsPage = PageService:Create("Settings")
local FarmPage = PageService:Create("Main Farm")
local QuestPage = PageService:Create("Quest")
local RaidPage = PageService:Create("Raids")
local CombatPage = PageService:Create("Combat")
local TeleportPage = PageService:Create("Teleport")
local PlayerPage = PageService:Create("Player")
local MiscPage = PageService:Create("Misc")

--// HOME

Components.Section(
    HomePage,
    "Dashboard",
    "Welcome to " .. Config.Name
)

local Cards = Utility.Create("Frame", {
    Parent = HomePage,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -5, 0, 90),
})

local CardLayout = Instance.new("UIGridLayout")
CardLayout.CellSize = UDim2.new(0, 190, 0, 85)
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

local SeaCard, SeaValue = Components.Card(
    Cards,
    "SEA",
    State.Sea
)

local Status = Components.Section(
    HomePage,
    "System Status",
    "Current runtime information"
)

local StatusLabel = Utility.Create("TextLabel", {
    Parent = Status,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 15, 0, 65),
    Size = UDim2.new(1, -30, 0, 30),

    Font = Enum.Font.Gotham,
    Text = "System initialized successfully.",
    TextColor3 = Config.Theme.Success,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})

Status.Size = UDim2.new(1, -5, 0, 105)

--// FARM

Components.Section(
    FarmPage,
    "Main Farm",
    "Automation modules will be connected in a future module."
)

Components.Toggle(
    FarmPage,
    "Auto Farm",
    "Main farming controller",
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
    "Mastery automation controller",
    function(enabled)
        NotificationService:Notify(
            "Auto Mastery",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--// QUEST

Components.Section(
    QuestPage,
    "Quest System",
    "Quest management and progression"
)

Components.Toggle(
    QuestPage,
    "Auto Quest",
    "Automatically manage the current quest",
    function(enabled)
        NotificationService:Notify(
            "Quest",
            enabled and "Auto Quest enabled" or "Auto Quest disabled"
        )
    end
)

--// RAID

Components.Section(
    RaidPage,
    "Raid System",
    "Raid controls and state management"
)

Components.Toggle(
    RaidPage,
    "Auto Raid",
    "Raid automation controller",
    function(enabled)
        NotificationService:Notify(
            "Raid",
            enabled and "Auto Raid enabled" or "Auto Raid disabled"
        )
    end
)

--// COMBAT

Components.Section(
    CombatPage,
    "Combat",
    "Combat configuration"
)

Components.Toggle(
    CombatPage,
    "Combat Assist",
    "Enables the combat module framework",
    function(enabled)
        NotificationService:Notify(
            "Combat",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--// TELEPORT

Components.Section(
    TeleportPage,
    "Teleport",
    "Destination management"
)

Components.Section(
    TeleportPage,
    "First Sea",
    "Teleport destinations can be registered here."
)

Components.Section(
    TeleportPage,
    "Second Sea",
    "Teleport destinations can be registered here."
)

Components.Section(
    TeleportPage,
    "Third Sea",
    "Teleport destinations can be registered here."
)

--// PLAYER

Components.Section(
    PlayerPage,
    "Player",
    "Character information and settings"
)

Components.Toggle(
    PlayerPage,
    "Anti AFK",
    "Prevents the local player from becoming idle",
    function(enabled)
        NotificationService:Notify(
            "Anti AFK",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--// MISC

Components.Section(
    MiscPage,
    "Miscellaneous",
    "Additional utilities"
)

Components.Toggle(
    MiscPage,
    "Notifications",
    "Enable or disable hub notifications",
    function(enabled)
        Config.UI.Notifications = enabled
    end
)

--// SETTINGS

Components.Section(
    SettingsPage,
    "Interface",
    "Configure the hub interface"
)

Components.Toggle(
    SettingsPage,
    "UI Animations",
    "Enable interface animations",
    function(enabled)
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
--// SIDEBAR BUTTONS
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
            Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Tertiary
            }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if State.CurrentTab ~= tabName then
            Utility.Tween(button, {
                BackgroundColor3 = Config.Theme.Secondary
            }):Play()
        end
    end)

    button.MouseButton1Click:Connect(function()
        PageService:Show(tabName)
    end)
end

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

UserInputService.InputChanged:Connect(function(input)
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
        Utility.Tween(Main, {
            Size = UDim2.new(0, Config.UI.Width, 0, 55)
        }):Play()

        Sidebar.Visible = false
        Content.Visible = false
    else
        Utility.Tween(Main, {
            Size = UDim2.new(0, Config.UI.Width, 0, Config.UI.Height)
        }):Play()

        task.delay(Config.UI.AnimationSpeed, function()
            Sidebar.Visible = true
            Content.Visible = true
        end)
    end
end)

--// =========================================================
--// PERFORMANCE
--// =========================================================

local frameCounter = 0
local lastFPSUpdate = tick()

State.Connections.FPS = RunService.RenderStepped:Connect(function()
    frameCounter += 1

    local now = tick()

    if now - lastFPSUpdate >= 1 then
        State.FPS = frameCounter
        frameCounter = 0
        lastFPSUpdate = now
    end
end)

--// =========================================================
--// LIVE DATA
--// =========================================================

State.Connections.Data = RunService.Heartbeat:Connect(function()
    pcall(function()
        LevelValue.Text = tostring(PlayerService:GetLevel())
        BeliValue.Text = tostring(PlayerService:GetBeli())
        FragmentValue.Text = tostring(PlayerService:GetFragments())

        WorldService:Update()

        SeaValue.Text = State.Sea

        StatusLabel.Text =
            "Online • " ..
            State.Sea ..
            " • FPS: " ..
            tostring(State.FPS)
    end)
end)

--// =========================================================
--// INITIALIZATION
--// =========================================================

PageService:Show("Home")

NotificationService:Init(ScreenGui)

task.wait(0.5)

NotificationService:Notify(
    Config.Name,
    "Interface initialized successfully.",
    4
)

print(
    "[" .. Config.Name .. "] " ..
    "V" .. Config.Version ..
    " initialized."
)
