--[[
    FLOQUITAVE
    Version: 2.1.0
    UI / Diagnostic Foundation
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Name = "Floquitave",
    Version = "2.1.0",

    UI = {
        Width = 920,
        Height = 590,

        Background = Color3.fromRGB(14, 15, 20),
        Secondary = Color3.fromRGB(19, 20, 27),
        Card = Color3.fromRGB(24, 25, 33),

        Accent = Color3.fromRGB(120, 80, 255),
        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(155, 157, 170),

        Animations = true,
    },

    Notifications = true,
    UpdateInterval = 0.5,
}

--==================================================
-- STATE
--==================================================

local State = {
    Destroyed = false,
    Minimized = false,

    CurrentPage = "Home",

    FPS = 0,
    Ping = 0,

    Connections = {},
    Toggles = {},

    Pages = {},
    Buttons = {},
}

--==================================================
-- UTILITY
--==================================================

local function Connect(signal, callback)
    local connection = signal:Connect(callback)

    table.insert(State.Connections, connection)

    return connection
end

local function Create(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Corner(object, radius)
    Create("UICorner", {
        Parent = object,
        CornerRadius = UDim.new(0, radius or 8),
    })
end

local function Stroke(object, color, thickness)
    Create("UIStroke", {
        Parent = object,
        Color = color or Color3.fromRGB(45, 46, 58),
        Thickness = thickness or 1,
    })
end

local function Padding(object, value)
    Create("UIPadding", {
        Parent = object,

        PaddingTop = UDim.new(0, value),
        PaddingBottom = UDim.new(0, value),
        PaddingLeft = UDim.new(0, value),
        PaddingRight = UDim.new(0, value),
    })
end

local function Tween(object, properties, duration)
    if not Config.UI.Animations then
        for property, value in pairs(properties) do
            object[property] = value
        end

        return
    end

    return TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    ):Play()
end

--==================================================
-- PLAYER SERVICE
--==================================================

local PlayerService = {}

function PlayerService:GetData()
    local data = LocalPlayer:FindFirstChild("Data")

    return data
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

function PlayerService:GetHealth()
    local character = LocalPlayer.Character

    if not character then
        return 0, 0
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return 0, 0
    end

    return humanoid.Health, humanoid.MaxHealth
end

function PlayerService:GetEnergy()
    local character = LocalPlayer.Character

    if not character then
        return 0, 0
    end

    local humanoid = character:FindFirstChild("Energy")

    if humanoid and humanoid:IsA("NumberValue") then
        return humanoid.Value, 0
    end

    return 0, 0
end

--==================================================
-- WORLD SERVICE
--==================================================

local WorldService = {}

local Worlds = {
    [2753915549] = "First Sea",
    [4442272183] = "Second Sea",
    [7449423635] = "Third Sea",
}

function WorldService:GetSea()
    return Worlds[game.PlaceId] or "Unknown"
end

--==================================================
-- PERFORMANCE SERVICE
--==================================================

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

        local dataPing = serverStats:FindFirstChild("Data Ping")

        if dataPing then
            local value = dataPing:GetValueString()

            local number = tonumber(
                string.match(value, "%d+")
            )

            return number or 0
        end

        return 0
    end)

    if success then
        return result
    end

    return 0
end

--==================================================
-- NOTIFICATION SERVICE
--==================================================

local NotificationService = {}

local NotificationContainer

function NotificationService:Notify(title, message, duration)
    if not Config.Notifications then
        return
    end

    if not NotificationContainer then
        return
    end

    local notification = Create("Frame", {
        Parent = NotificationContainer,

        Size = UDim2.new(0, 300, 0, 75),

        BackgroundColor3 = Config.UI.Card,

        BackgroundTransparency = 0.05,

        BorderSizePixel = 0,
    })

    Corner(notification, 10)
    Stroke(notification)

    local titleLabel = Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 15, 0, 9),

        Size = UDim2.new(1, -30, 0, 22),

        Font = Enum.Font.GothamBold,

        Text = tostring(title),

        TextColor3 = Config.UI.Text,

        TextSize = 14,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local messageLabel = Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 15, 0, 32),

        Size = UDim2.new(1, -30, 0, 32),

        Font = Enum.Font.Gotham,

        Text = tostring(message),

        TextColor3 = Config.UI.SubText,

        TextSize = 12,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextYAlignment = Enum.TextYAlignment.Top,
    })

    notification.Position = UDim2.new(1, 20, 0, 0)

    Tween(
        notification,
        {
            Position = UDim2.new(0, 0, 0, 0)
        },
        0.25
    )

    task.delay(duration or 3, function()
        if notification and notification.Parent then
            Tween(
                notification,
                {
                    Position = UDim2.new(1, 20, 0, 0)
                },
                0.25
            )

            task.wait(0.3)

            if notification then
                notification:Destroy()
            end
        end
    end)
end

--==================================================
-- GUI
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "FloquitaveUI",

    ResetOnSpawn = false,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- MAIN WINDOW
--==================================================

local Main = Create("Frame", {
    Parent = ScreenGui,

    Size = UDim2.new(
        0,
        Config.UI.Width,
        0,
        Config.UI.Height
    ),

    Position = UDim2.new(
        0.5,
        -Config.UI.Width / 2,
        0.5,
        -Config.UI.Height / 2
    ),

    BackgroundColor3 = Config.UI.Background,

    BorderSizePixel = 0,
})

Corner(Main, 12)
Stroke(Main, Color3.fromRGB(42, 43, 55), 1)

--==================================================
-- TOP BAR
--==================================================

local TopBar = Create("Frame", {
    Parent = Main,

    Size = UDim2.new(1, 0, 0, 52),

    BackgroundColor3 = Config.UI.Secondary,

    BorderSizePixel = 0,
})

Corner(TopBar, 12)

local Title = Create("TextLabel", {
    Parent = TopBar,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 20, 0, 7),

    Size = UDim2.new(0, 300, 0, 24),

    Font = Enum.Font.GothamBold,

    Text = Config.Name,

    TextColor3 = Config.UI.Text,

    TextSize = 17,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local Version = Create("TextLabel", {
    Parent = TopBar,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 20, 0, 28),

    Size = UDim2.new(0, 300, 0, 17),

    Font = Enum.Font.Gotham,

    Text = "Version " .. Config.Version,

    TextColor3 = Config.UI.SubText,

    TextSize = 10,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local MinimizeButton = Create("TextButton", {
    Parent = TopBar,

    BackgroundColor3 = Config.UI.Card,

    Position = UDim2.new(1, -75, 0, 11),

    Size = UDim2.new(0, 28, 0, 28),

    Font = Enum.Font.GothamBold,

    Text = "—",

    TextColor3 = Config.UI.Text,

    TextSize = 16,

    AutoButtonColor = false,
})

Corner(MinimizeButton, 7)

local CloseButton = Create("TextButton", {
    Parent = TopBar,

    BackgroundColor3 = Config.UI.Card,

    Position = UDim2.new(1, -40, 0, 11),

    Size = UDim2.new(0, 28, 0, 28),

    Font = Enum.Font.GothamBold,

    Text = "×",

    TextColor3 = Config.UI.Text,

    TextSize = 18,

    AutoButtonColor = false,
})

Corner(CloseButton, 7)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Create("Frame", {
    Parent = Main,

    Position = UDim2.new(0, 0, 0, 52),

    Size = UDim2.new(0, 195, 1, -52),

    BackgroundColor3 = Config.UI.Secondary,

    BorderSizePixel = 0,
})

Padding(Sidebar, 10)

local SearchBox = Create("TextBox", {
    Parent = Sidebar,

    Size = UDim2.new(1, 0, 0, 35),

    BackgroundColor3 = Config.UI.Card,

    PlaceholderText = "Search...",

    PlaceholderColor3 = Config.UI.SubText,

    Text = "",

    TextColor3 = Config.UI.Text,

    Font = Enum.Font.Gotham,

    TextSize = 12,

    ClearTextOnFocus = false,
})

Corner(SearchBox, 8)

local SidebarList = Create("ScrollingFrame", {
    Parent = Sidebar,

    Position = UDim2.new(0, 0, 0, 45),

    Size = UDim2.new(1, 0, 1, -45),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    ScrollBarThickness = 2,

    CanvasSize = UDim2.new(0, 0, 0, 0),
})

local SidebarLayout = Create("UIListLayout", {
    Parent = SidebarList,

    Padding = UDim.new(0, 6),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

--==================================================
-- CONTENT
--==================================================

local Content = Create("Frame", {
    Parent = Main,

    Position = UDim2.new(0, 195, 0, 52),

    Size = UDim2.new(1, -195, 1, -52),

    BackgroundTransparency = 1,
})

--==================================================
-- NOTIFICATIONS
--==================================================

NotificationContainer = Create("Frame", {
    Parent = ScreenGui,

    AnchorPoint = Vector2.new(1, 0),

    Position = UDim2.new(1, -20, 0, 20),

    Size = UDim2.new(0, 300, 1, -40),

    BackgroundTransparency = 1,
})

local NotificationLayout = Create("UIListLayout", {
    Parent = NotificationContainer,

    Padding = UDim.new(0, 8),

    HorizontalAlignment = Enum.HorizontalAlignment.Right,

    SortOrder = Enum.SortOrder.LayoutOrder,
})

--==================================================
-- PAGE SERVICE
--==================================================

local PageService = {}

function PageService:CreatePage(name)
    local page = Create("ScrollingFrame", {
        Parent = Content,

        Size = UDim2.new(1, 0, 1, 0),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 3,

        Visible = false,

        CanvasSize = UDim2.new(0, 0, 0, 0),
    })

    Padding(page, 18)

    local layout = Create("UIListLayout", {
        Parent = page,

        Padding = UDim.new(0, 12),

        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(
            0,
            0,
            0,
            layout.AbsoluteContentSize.Y + 30
        )
    end)

    State.Pages[name] = page

    return page
end

function PageService:Show(name)
    for pageName, page in pairs(State.Pages) do
        page.Visible = pageName == name
    end

    State.CurrentPage = name

    for buttonName, button in pairs(State.Buttons) do
        if buttonName == name then
            button.BackgroundColor3 = Config.UI.Accent
        else
            button.BackgroundColor3 = Config.UI.Card
        end
    end
end

--==================================================
-- COMPONENTS
--==================================================

local Components = {}

function Components:Section(parent, title, description)
    local section = Create("Frame", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, 58),

        BackgroundColor3 = Config.UI.Card,

        BorderSizePixel = 0,
    })

    Corner(section, 9)

    local titleLabel = Create("TextLabel", {
        Parent = section,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 15, 0, 9),

        Size = UDim2.new(1, -30, 0, 20),

        Font = Enum.Font.GothamBold,

        Text = title,

        TextColor3 = Config.UI.Text,

        TextSize = 14,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local descLabel = Create("TextLabel", {
        Parent = section,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 15, 0, 30),

        Size = UDim2.new(1, -30, 0, 18),

        Font = Enum.Font.Gotham,

        Text = description or "",

        TextColor3 = Config.UI.SubText,

        TextSize = 10,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    return section
end

function Components:Card(parent, title, value)
    local card = Create("Frame", {
        Parent = parent,

        BackgroundColor3 = Config.UI.Card,

        BorderSizePixel = 0,
    })

    Corner(card, 9)

    local titleLabel = Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 12, 0, 10),

        Size = UDim2.new(1, -24, 0, 18),

        Font = Enum.Font.Gotham,

        Text = title,

        TextColor3 = Config.UI.SubText,

        TextSize = 10,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 12, 0, 28),

        Size = UDim2.new(1, -24, 0, 27),

        Font = Enum.Font.GothamBold,

        Text = tostring(value),

        TextColor3 = Config.UI.Text,

        TextSize = 17,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    return card, valueLabel
end

function Components:Toggle(parent, name, description, callback)
    local holder = Create("Frame", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, 55),

        BackgroundColor3 = Config.UI.Card,

        BorderSizePixel = 0,
    })

    Corner(holder, 9)

    local label = Create("TextLabel", {
        Parent = holder,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 14, 0, 8),

        Size = UDim2.new(1, -75, 0, 20),

        Font = Enum.Font.GothamBold,

        Text = name,

        TextColor3 = Config.UI.Text,

        TextSize = 12,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local desc = Create("TextLabel", {
        Parent = holder,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 14, 0, 28),

        Size = UDim2.new(1, -75, 0, 17),

        Font = Enum.Font.Gotham,

        Text = description or "",

        TextColor3 = Config.UI.SubText,

        TextSize = 9,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local button = Create("TextButton", {
        Parent = holder,

        Position = UDim2.new(1, -55, 0.5, -12),

        Size = UDim2.new(0, 40, 0, 24),

        BackgroundColor3 = Color3.fromRGB(40, 41, 50),

        Text = "",

        AutoButtonColor = false,
    })

    Corner(button, 12)

    local circle = Create("Frame", {
        Parent = button,

        Position = UDim2.new(0, 3, 0.5, -9),

        Size = UDim2.new(0, 18, 0, 18),

        BackgroundColor3 = Color3.fromRGB(210, 210, 215),

        BorderSizePixel = 0,
    })

    Corner(circle, 20)

    State.Toggles[name] = false

    Connect(button.MouseButton1Click, function()
        State.Toggles[name] = not State.Toggles[name]

        local enabled = State.Toggles[name]

        if enabled then
            Tween(button, {
                BackgroundColor3 = Config.UI.Accent
            })

            Tween(circle, {
                Position = UDim2.new(1, -21, 0.5, -9)
            })
        else
            Tween(button, {
                BackgroundColor3 = Color3.fromRGB(40, 41, 50)
            })

            Tween(circle, {
                Position = UDim2.new(0, 3, 0.5, -9)
            })
        end

        if callback then
            pcall(callback, enabled)
        end
    end)

    return holder
end

--==================================================
-- HOME PAGE
--==================================================

local Home = PageService:CreatePage("Home")

Components:Section(
    Home,
    "Welcome to Floquitave",
    "Interface and local game diagnostics"
)

local StatsGrid = Create("Frame", {
    Parent = Home,

    Size = UDim2.new(1, 0, 0, 150),

    BackgroundTransparency = 1,
})

local Grid = Create("UIGridLayout", {
    Parent = StatsGrid,

    CellSize = UDim2.new(0.25, -9, 0, 68),

    CellPadding = UDim2.new(0, 12, 0, 12),

    FillDirectionMaxCells = 4,
})

local Cards = {}

local function AddCard(name, value)
    local card, valueLabel = Components:Card(
        StatsGrid,
        name,
        value
    )

    Cards[name] = valueLabel

    return card
end

AddCard("LEVEL", "0")
AddCard("BELI", "0")
AddCard("FRAGMENTS", "0")
AddCard("RACE", "Unknown")
AddCard("SEA", "Unknown")
AddCard("FPS", "0")
AddCard("PING", "0 ms")
AddCard("HEALTH", "0")

Components:Section(
    Home,
    "System Status",
    "Current client information"
)

local StatusCard = Create("Frame", {
    Parent = Home,

    Size = UDim2.new(1, 0, 0, 65),

    BackgroundColor3 = Config.UI.Card,

    BorderSizePixel = 0,
})

Corner(StatusCard, 9)

local StatusText = Create("TextLabel", {
    Parent = StatusCard,

    BackgroundTransparency = 1,

    Position = UDim2.new(0, 15, 0, 10),

    Size = UDim2.new(1, -30, 0, 45),

    Font = Enum.Font.Gotham,

    Text = "Status: Online",

    TextColor3 = Config.UI.SubText,

    TextSize = 12,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextYAlignment = Enum.TextYAlignment.Center,
})

--==================================================
-- OTHER PAGES
--==================================================

local Farm = PageService:CreatePage("Main Farm")

Components:Section(
    Farm,
    "Main Farm",
    "Interface prepared for future modules"
)

Components:Toggle(
    Farm,
    "Auto Farm",
    "Test interface only",
    function(enabled)
        NotificationService:Notify(
            "Auto Farm",
            enabled and "Enabled (UI test)" or "Disabled",
            2
        )
    end
)

Components:Toggle(
    Farm,
    "Auto Mastery",
    "Test interface only",
    function(enabled)
        NotificationService:Notify(
            "Auto Mastery",
            enabled and "Enabled (UI test)" or "Disabled",
            2
        )
    end
)

local Quest = PageService:CreatePage("Quest")

Components:Section(
    Quest,
    "Quest",
    "Quest management interface"
)

Components:Toggle(
    Quest,
    "Auto Quest",
    "Test interface only",
    function(enabled)
        NotificationService:Notify(
            "Auto Quest",
            enabled and "Enabled (UI test)" or "Disabled",
            2
        )
    end
)

local Raids = PageService:CreatePage("Raids")

Components:Section(
    Raids,
    "Raids",
    "Raid interface"
)

Components:Toggle(
    Raids,
    "Auto Raid",
    "Test interface only",
    function(enabled)
        NotificationService:Notify(
            "Auto Raid",
            enabled and "Enabled (UI test)" or "Disabled",
            2
        )
    end
)

local Combat = PageService:CreatePage("Combat")

Components:Section(
    Combat,
    "Combat",
    "Combat interface"
)

Components:Toggle(
    Combat,
    "Combat Assist",
    "Test interface only",
    function(enabled)
        NotificationService:Notify(
            "Combat Assist",
            enabled and "Enabled (UI test)" or "Disabled",
            2
        )
    end
)

local Teleport = PageService:CreatePage("Teleport")

Components:Section(
    Teleport,
    "Teleport",
    "Teleport interface"
)

Components:Toggle(
    Teleport,
    "Teleport Menu",
    "Interface placeholder",
    function(enabled)
        NotificationService:Notify(
            "Teleport",
            enabled and "Enabled" or "Disabled",
            2
        )
    end
)

local PlayerPage = PageService:CreatePage("Player")

Components:Section(
    PlayerPage,
    "Player",
    "Local player settings"
)

Components:Toggle(
    PlayerPage,
    "Anti AFK",
    "Local interface option",
    function(enabled)
        NotificationService:Notify(
            "Anti AFK",
            enabled and "Enabled" or "Disabled",
            2
        )
    end
)

local Misc = PageService:CreatePage("Misc")

Components:Section(
    Misc,
    "Miscellaneous",
    "Additional options"
)

Components:Toggle(
    Misc,
    "Notifications",
    "Enable or disable notifications",
    function(enabled)
        Config.Notifications = enabled
    end
)

Components:Toggle(
    Misc,
    "UI Animations",
    "Enable interface animations",
    function(enabled)
        Config.UI.Animations = enabled
    end
)

local Settings = PageService:CreatePage("Settings")

Components:Section(
    Settings,
    "Settings",
    "Floquitave configuration"
)

Components:Toggle(
    Settings,
    "Notifications",
    "Global notification system",
    function(enabled)
        Config.Notifications = enabled
    end
)

Components:Toggle(
    Settings,
    "Animations",
    "Interface animations",
    function(enabled)
        Config.UI.Animations = enabled
    end
)

Components:Section(
    Settings,
    "Information",
    "Current version"
)

local Info = Create("TextLabel", {
    Parent = Settings,

    Size = UDim2.new(1, 0, 0, 60),

    BackgroundColor3 = Config.UI.Card,

    Text = "Floquitave\nVersion " .. Config.Version,

    Font = Enum.Font.GothamBold,

    TextColor3 = Config.UI.Text,

    TextSize = 14,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextYAlignment = Enum.TextYAlignment.Center,
})

Corner(Info, 9)

Padding(Info, 15)

--==================================================
-- SIDEBAR BUTTONS
--==================================================

local PageOrder = {
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

for index, pageName in ipairs(PageOrder) do
    local button = Create("TextButton", {
        Parent = SidebarList,

        Size = UDim2.new(1, 0, 0, 35),

        BackgroundColor3 = Config.UI.Card,

        Text = pageName,

        TextColor3 = Config.UI.Text,

        Font = Enum.Font.GothamMedium,

        TextSize = 11,

        AutoButtonColor = false,

        LayoutOrder = index,
    })

    Corner(button, 7)

    State.Buttons[pageName] = button

    Connect(button.MouseButton1Click, function()
        PageService:Show(pageName)
    end)
end

--==================================================
-- SEARCH
--==================================================

Connect(SearchBox:GetPropertyChangedSignal("Text"), function()
    local search = string.lower(SearchBox.Text)

    for name, button in pairs(State.Buttons) do
        if search == "" then
            button.Visible = true
        else
            button.Visible = string.find(
                string.lower(name),
                search,
                1,
                true
            ) ~= nil
        end
    end
end)

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition

Connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

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
        and input.UserInputType ~= Enum.UserInputType.Touch then
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

Connect(MinimizeButton.MouseButton1Click, function()
    State.Minimized = not State.Minimized

    if State.Minimized then
        Sidebar.Visible = false
        Content.Visible = false

        Tween(Main, {
            Size = UDim2.new(
                0,
                Config.UI.Width,
                0,
                52
            )
        })
    else
        Sidebar.Visible = true
        Content.Visible = true

        Tween(Main, {
            Size = UDim2.new(
                0,
                Config.UI.Width,
                0,
                Config.UI.Height
            )
        })
    end
end)

--==================================================
-- CLEANUP
--==================================================

local function Destroy()
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

    if ScreenGui then
        ScreenGui:Destroy()
    end
end

Connect(CloseButton.MouseButton1Click, function()
    Destroy()
end)

--==================================================
-- FPS
--==================================================

local frames = 0
local fpsTimer = os.clock()

Connect(RunService.RenderStepped, function()
    frames += 1

    local now = os.clock()

    if now - fpsTimer >= 1 then
        State.FPS = frames

        frames = 0
        fpsTimer = now
    end
end)

--==================================================
-- LIVE DATA
--==================================================

task.spawn(function()
    while not State.Destroyed do
        task.wait(Config.UpdateInterval)

        if State.Destroyed then
            break
        end

        local level = PlayerService:GetLevel()
        local beli = PlayerService:GetBeli()
        local fragments = PlayerService:GetFragments()
        local race = PlayerService:GetRace()
        local sea = WorldService:GetSea()

        local health, maxHealth = PlayerService:GetHealth()

        State.Ping = PerformanceService:GetPing()

        if Cards["LEVEL"] then
            Cards["LEVEL"].Text = tostring(level)
        end

        if Cards["BELI"] then
            Cards["BELI"].Text = tostring(beli)
        end

        if Cards["FRAGMENTS"] then
            Cards["FRAGMENTS"].Text = tostring(fragments)
        end

        if Cards["RACE"] then
            Cards["RACE"].Text = tostring(race)
        end

        if Cards["SEA"] then
            Cards["SEA"].Text = tostring(sea)
        end

        if Cards["FPS"] then
            Cards["FPS"].Text = tostring(State.FPS)
        end

        if Cards["PING"] then
            Cards["PING"].Text = tostring(State.Ping) .. " ms"
        end

        if Cards["HEALTH"] then
            if maxHealth > 0 then
                Cards["HEALTH"].Text =
                    math.floor(health) ..
                    " / " ..
                    math.floor(maxHealth)
            else
                Cards["HEALTH"].Text =
                    math.floor(health)
            end
        end

        StatusText.Text =
            "Status: Online  •  " ..
            sea ..
            "  •  " ..
            State.FPS ..
            " FPS  •  " ..
            State.Ping ..
            " ms"
    end
end)

--==================================================
-- INITIALIZE
--==================================================

PageService:Show("Home")

NotificationService:Notify(
    "Floquitave",
    "Interface carregada com sucesso.",
    3
)

print(
    "[Floquitave] " ..
    Config.Version ..
    " loaded successfully."
)
