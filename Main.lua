--[[
    Floquitave Hub
    Version: 2.3.0

    UI / Diagnostics Foundation
    No credential collection
    No cookie/token collection
    No external data logging
]]

--==================================================
-- SERVICES
--==================================================

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
    Version = "2.3.0",

    UI = {
        Width = 920,
        Height = 590,

        MinWidth = 760,
        MinHeight = 500,

        Animations = true,
        Scale = 1,

        Theme = "Dark",

        Accent = Color3.fromRGB(115, 90, 255),

        Background = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(20, 20, 27),
        Card = Color3.fromRGB(25, 25, 34),
        Sidebar = Color3.fromRGB(18, 18, 24),

        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(150, 150, 165),
    },

    Notifications = {
        Enabled = true,
        Duration = 3,
    },

    Performance = {
        UpdateInterval = 0.5,
    }
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

    Connections = {},
    Buttons = {},
    Pages = {},
    Cards = {},
    Toggles = {},

    SearchText = "",

    Dragging = false,
}

--==================================================
-- SESSION
--==================================================

local StartTime = os.clock()

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
-- UTILITY
--==================================================

local function Tween(instance, properties, duration)
    if not instance then
        return
    end

    if not Config.UI.Animations then
        for property, value in pairs(properties) do
            pcall(function()
                instance[property] = value
            end)
        end

        return
    end

    local tween = TweenService:Create(
        instance,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()

    return tween
end

local function Create(className, properties)
    local instance = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            instance[property] = value
        end)
    end

    return instance
end

local function Corner(parent, radius)
    return Create("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 8)
    })
end

local function Stroke(parent, color, thickness)
    return Create("UIStroke", {
        Parent = parent,
        Color = color or Color3.fromRGB(50, 50, 65),
        Thickness = thickness or 1,
        Transparency = 0,
    })
end

local function Padding(parent, left, right, top, bottom)
    return Create("UIPadding", {
        Parent = parent,

        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
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

    return string.format(
        "%02d:%02d:%02d",
        hours,
        minutes,
        secs
    )
end

--==================================================
-- WORLD SERVICE
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

function WorldService:GetPlaceId()
    return tostring(game.PlaceId)
end

--==================================================
-- PLAYER SERVICE
--==================================================

local PlayerService = {}

function PlayerService:GetDataFolder()
    return LocalPlayer:FindFirstChild("Data")
end

function PlayerService:GetValue(name)
    local data = self:GetDataFolder()

    if not data then
        return nil
    end

    local value = data:FindFirstChild(name)

    if value then
        return value.Value
    end

    return nil
end

function PlayerService:GetLevel()
    return tonumber(self:GetValue("Level")) or 0
end

function PlayerService:GetBeli()
    return tonumber(self:GetValue("Beli")) or 0
end

function PlayerService:GetFragments()
    return tonumber(self:GetValue("Fragments")) or 0
end

function PlayerService:GetRace()
    return tostring(self:GetValue("Race") or "Unknown")
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

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return 0, 0
    end

    local energy = character:FindFirstChild("Energy")

    if energy then
        return energy.Value, 100
    end

    return 0, 0
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

        if not dataPing then
            return 0
        end

        local value = dataPing:GetValueString()

        local number = tonumber(
            string.match(value, "%d+")
        )

        return number or 0
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

local NotificationHolder

function NotificationService:Notify(title, message)
    if not Config.Notifications.Enabled then
        return
    end

    if not NotificationHolder then
        return
    end

    local notification = Create("Frame", {
        Parent = NotificationHolder,

        Size = UDim2.new(1, 0, 0, 70),

        BackgroundColor3 = Config.UI.Card,

        BackgroundTransparency = 0.03,
    })

    Corner(notification, 10)

    Stroke(
        notification,
        Config.UI.Accent,
        1
    )

    local accent = Create("Frame", {
        Parent = notification,

        Size = UDim2.new(0, 4, 1, 0),

        BackgroundColor3 = Config.UI.Accent,
    })

    Corner(accent, 5)

    local titleLabel = Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 16, 0, 9),

        Size = UDim2.new(1, -25, 0, 22),

        Font = Enum.Font.GothamBold,

        Text = tostring(title),

        TextColor3 = Config.UI.Text,

        TextSize = 14,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local messageLabel = Create("TextLabel", {
        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(0, 16, 0, 31),

        Size = UDim2.new(1, -25, 0, 28),

        Font = Enum.Font.Gotham,

        Text = tostring(message),

        TextColor3 = Config.UI.SubText,

        TextSize = 12,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextYAlignment = Enum.TextYAlignment.Top,
    })

    notification.Position = UDim2.new(
        1,
        20,
        0,
        0
    )

    Tween(
        notification,
        {
            Position = UDim2.new(
                0,
                0,
                0,
                0
            )
        },
        0.3
    )

    task.delay(Config.Notifications.Duration, function()
        if State.Destroyed then
            return
        end

        if notification and notification.Parent then
            Tween(
                notification,
                {
                    Position = UDim2.new(
                        1,
                        20,
                        0,
                        0
                    )
                },
                0.25
            )

            task.delay(0.3, function()
                pcall(function()
                    notification:Destroy()
                end)
            end)
        end
    end)
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Create("ScreenGui", {
    Name = "FloquitaveUI",

    ResetOnSpawn = false,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

ScreenGui.Parent = game:GetService("CoreGui")

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

Stroke(
    Main,
    Color3.fromRGB(45, 45, 60),
    1
)

--==================================================
-- TOPBAR
--==================================================

local Topbar = Create("Frame", {
    Parent = Main,

    Size = UDim2.new(1, 0, 0, 60),

    BackgroundColor3 = Config.UI.Secondary,

    BorderSizePixel = 0,
})

Corner(Topbar, 12)

local TopbarCover = Create("Frame", {
    Parent = Topbar,

    Position = UDim2.new(0, 0, 0.5, 0),

    Size = UDim2.new(1, 0, 0.5, 0),

    BackgroundColor3 = Config.UI.Secondary,

    BorderSizePixel = 0,
})

--==================================================
-- LOGO
--==================================================

local Logo = Create("Frame", {
    Parent = Topbar,

    Position = UDim2.new(
        0,
        15,
        0.5,
        -18
    ),

    Size = UDim2.new(0, 36, 0, 36),

    BackgroundColor3 = Config.UI.Accent,
})

Corner(Logo, 10)

local LogoText = Create("TextLabel", {
    Parent = Logo,

    BackgroundTransparency = 1,

    Size = UDim2.new(1, 0, 1, 0),

    Text = "F",

    Font = Enum.Font.GothamBold,

    TextSize = 18,

    TextColor3 = Color3.fromRGB(255, 255, 255),
})

--==================================================
-- TITLE
--==================================================

local Title = Create("TextLabel", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        62,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        250,
        0,
        23
    ),

    Text = Config.Name,

    Font = Enum.Font.GothamBold,

    TextSize = 17,

    TextColor3 = Config.UI.Text,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local Version = Create("TextLabel", {
    Parent = Topbar,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        62,
        0,
        32
    ),

    Size = UDim2.new(
        0,
        250,
        0,
        18
    ),

    Text = "Version " .. Config.Version,

    Font = Enum.Font.Gotham,

    TextSize = 11,

    TextColor3 = Config.UI.SubText,

    TextXAlignment = Enum.TextXAlignment.Left,
})

--==================================================
-- TOPBAR BUTTONS
--==================================================

local MinimizeButton = Create("TextButton", {
    Parent = Topbar,

    Position = UDim2.new(
        1,
        -82,
        0.5,
        -17
    ),

    Size = UDim2.new(0, 34, 0, 34),

    BackgroundColor3 = Config.UI.Card,

    Text = "—",

    Font = Enum.Font.GothamBold,

    TextSize = 17,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(MinimizeButton, 8)

local CloseButton = Create("TextButton", {
    Parent = Topbar,

    Position = UDim2.new(
        1,
        -42,
        0.5,
        -17
    ),

    Size = UDim2.new(0, 34, 0, 34),

    BackgroundColor3 = Config.UI.Card,

    Text = "×",

    Font = Enum.Font.GothamBold,

    TextSize = 20,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(CloseButton, 8)

--==================================================
-- DRAG MAIN WINDOW
--==================================================

local draggingMain = false
local dragStart
local startPosition

Connect(Topbar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        draggingMain = true

        dragStart = input.Position

        startPosition = Main.Position
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not draggingMain then
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

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        draggingMain = false
    end
end)

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Create("Frame", {
    Parent = Main,

    Position = UDim2.new(
        0,
        0,
        0,
        60
    ),

    Size = UDim2.new(
        0,
        195,
        1,
        -60
    ),

    BackgroundColor3 = Config.UI.Sidebar,

    BorderSizePixel = 0,
})

--==================================================
-- SEARCH
--==================================================

local SearchBox = Create("TextBox", {
    Parent = Sidebar,

    Position = UDim2.new(
        0,
        12,
        0,
        15
    ),

    Size = UDim2.new(
        1,
        -24,
        0,
        36
    ),

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

Padding(
    SearchBox,
    12,
    8,
    0,
    0
)

--==================================================
-- SIDEBAR SCROLL
--==================================================

local SidebarScroll = Create("ScrollingFrame", {
    Parent = Sidebar,

    Position = UDim2.new(
        0,
        0,
        0,
        65
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        -65
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    ScrollBarThickness = 2,

    ScrollBarImageColor3 = Config.UI.Accent,

    CanvasSize = UDim2.new(0, 0, 0, 0),

    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})

Padding(
    SidebarScroll,
    10,
    10,
    8,
    8
)

local SidebarLayout = Create("UIListLayout", {
    Parent = SidebarScroll,

    Padding = UDim.new(0, 5),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

--==================================================
-- CONTENT
--==================================================

local Content = Create("Frame", {
    Parent = Main,

    Position = UDim2.new(
        0,
        195,
        0,
        60
    ),

    Size = UDim2.new(
        1,
        -195,
        1,
        -60
    ),

    BackgroundTransparency = 1,
})

local ContentScroll = Create("ScrollingFrame", {
    Parent = Content,

    Position = UDim2.new(
        0,
        0,
        0,
        0
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        0
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    ScrollBarThickness = 3,

    ScrollBarImageColor3 = Config.UI.Accent,

    CanvasSize = UDim2.new(0, 0, 0, 0),

    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})

Padding(
    ContentScroll,
    20,
    20,
    18,
    20
)

local ContentLayout = Create("UIListLayout", {
    Parent = ContentScroll,

    Padding = UDim.new(0, 12),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

--==================================================
-- NOTIFICATION HOLDER
--==================================================

NotificationHolder = Create("Frame", {
    Parent = ScreenGui,

    Position = UDim2.new(
        1,
        -320,
        0,
        20
    ),

    Size = UDim2.new(
        0,
        300,
        0,
        400
    ),

    BackgroundTransparency = 1,

    ZIndex = 200,
})

Create("UIListLayout", {
    Parent = NotificationHolder,

    Padding = UDim.new(0, 8),

    VerticalAlignment = Enum.VerticalAlignment.Top,

    HorizontalAlignment = Enum.HorizontalAlignment.Right,
})

--==================================================
-- PAGE SERVICE
--==================================================

local PageService = {}

function PageService:Create(name)
    local page = Create("Frame", {
        Parent = ContentScroll,

        Size = UDim2.new(
            1,
            0,
            0,
            0
        ),

        AutomaticSize = Enum.AutomaticSize.Y,

        BackgroundTransparency = 1,

        Visible = false,
    })

    local layout = Create("UIListLayout", {
        Parent = page,

        Padding = UDim.new(0, 12),

        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    State.Pages[name] = page

    return page
end

function PageService:Show(name)
    if State.Destroyed then
        return
    end

    local page = State.Pages[name]

    if not page then
        return
    end

    State.CurrentPage = name

    for pageName, frame in pairs(State.Pages) do
        frame.Visible = pageName == name
    end

    for pageName, button in pairs(State.Buttons) do
        local active = pageName == name

        if active then
            Tween(button, {
                BackgroundColor3 = Config.UI.Accent,
            }, 0.15)
        else
            Tween(button, {
                BackgroundColor3 = Config.UI.Sidebar,
            }, 0.15)
        end
    end

    ContentScroll.CanvasPosition = Vector2.new(0, 0)
end

--==================================================
-- COMPONENTS
--==================================================

local Components = {}

function Components:Section(parent, title, subtitle)
    local section = Create("Frame", {
        Parent = parent,

        Size = UDim2.new(
            1,
            0,
            0,
            58
        ),

        BackgroundColor3 = Config.UI.Secondary,
    })

    Corner(section, 10)

    Stroke(
        section,
        Color3.fromRGB(40, 40, 55),
        1
    )

    local titleLabel = Create("TextLabel", {
        Parent = section,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            15,
            0,
            9
        ),

        Size = UDim2.new(
            1,
            -30,
            0,
            20
        ),

        Text = title,

        Font = Enum.Font.GothamBold,

        TextSize = 14,

        TextColor3 = Config.UI.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if subtitle then
        Create("TextLabel", {
            Parent = section,

            BackgroundTransparency = 1,

            Position = UDim2.new(
                0,
                15,
                0,
                29
            ),

            Size = UDim2.new(
                1,
                -30,
                0,
                18
            ),

            Text = subtitle,

            Font = Enum.Font.Gotham,

            TextSize = 11,

            TextColor3 = Config.UI.SubText,

            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end

    return section
end

function Components:Card(parent, title, value)
    local card = Create("Frame", {
        Parent = parent,

        Size = UDim2.new(
            0.5,
            -6,
            0,
            85
        ),

        BackgroundColor3 = Config.UI.Card,
    })

    Corner(card, 10)

    Stroke(
        card,
        Color3.fromRGB(42, 42, 57),
        1
    )

    Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            14,
            0,
            12
        ),

        Size = UDim2.new(
            1,
            -28,
            0,
            18
        ),

        Text = title,

        Font = Enum.Font.GothamMedium,

        TextSize = 10,

        TextColor3 = Config.UI.SubText,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = Create("TextLabel", {
        Parent = card,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            14,
            0,
            33
        ),

        Size = UDim2.new(
            1,
            -28,
            0,
            35
        ),

        Text = tostring(value),

        Font = Enum.Font.GothamBold,

        TextSize = 20,

        TextColor3 = Config.UI.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    State.Cards[title] = valueLabel

    return card, valueLabel
end

function Components:Toggle(parent, title, description, default, callback)
    local row = Create("Frame", {
        Parent = parent,

        Size = UDim2.new(
            1,
            0,
            0,
            64
        ),

        BackgroundColor3 = Config.UI.Card,
    })

    Corner(row, 9)

    Stroke(
        row,
        Color3.fromRGB(42, 42, 57),
        1
    )

    local titleLabel = Create("TextLabel", {
        Parent = row,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            14,
            0,
            10
        ),

        Size = UDim2.new(
            1,
            -85,
            0,
            20
        ),

        Text = title,

        Font = Enum.Font.GothamMedium,

        TextSize = 13,

        TextColor3 = Config.UI.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if description then
        Create("TextLabel", {
            Parent = row,

            BackgroundTransparency = 1,

            Position = UDim2.new(
                0,
                14,
                0,
                31
            ),

            Size = UDim2.new(
                1,
                -85,
                0,
                18
            ),

            Text = description,

            Font = Enum.Font.Gotham,

            TextSize = 10,

            TextColor3 = Config.UI.SubText,

            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end

    local button = Create("TextButton", {
        Parent = row,

        Position = UDim2.new(
            1,
            -58,
            0.5,
            -13
        ),

        Size = UDim2.new(
            0,
            44,
            0,
            26
        ),

        BackgroundColor3 = Color3.fromRGB(
            45,
            45,
            55
        ),

        Text = "",

        AutoButtonColor = false,
    })

    Corner(button, 13)

    local knob = Create("Frame", {
        Parent = button,

        Position = UDim2.new(
            0,
            3,
            0.5,
            -9
        ),

        Size = UDim2.new(
            0,
            18,
            0,
            18
        ),

        BackgroundColor3 = Color3.fromRGB(
            190,
            190,
            200
        ),
    })

    Corner(knob, 100)

    local enabled = default == true

    local function Update()
        if enabled then
            Tween(button, {
                BackgroundColor3 = Config.UI.Accent
            }, 0.15)

            Tween(knob, {
                Position = UDim2.new(
                    1,
                    -21,
                    0.5,
                    -9
                )
            }, 0.15)
        else
            Tween(button, {
                BackgroundColor3 = Color3.fromRGB(
                    45,
                    45,
                    55
                )
            }, 0.15)

            Tween(knob, {
                Position = UDim2.new(
                    0,
                    3,
                    0.5,
                    -9
                )
            }, 0.15)
        end
    end

    Connect(button.MouseButton1Click, function()
        enabled = not enabled

        Update()

        if callback then
            callback(enabled)
        end
    end)

    State.Toggles[title] = {
        Get = function()
            return enabled
        end,

        Set = function(value)
            enabled = value == true

            Update()

            if callback then
                callback(enabled)
            end
        end,
    }

    Update()

    return row
end

--==================================================
-- PAGE CREATION
--==================================================

local HomePage = PageService:Create("Home")
local FarmPage = PageService:Create("Main Farm")
local QuestPage = PageService:Create("Quest")
local RaidsPage = PageService:Create("Raids")
local CombatPage = PageService:Create("Combat")
local TeleportPage = PageService:Create("Teleport")
local PlayerPage = PageService:Create("Player")
local MiscPage = PageService:Create("Misc")
local SettingsPage = PageService:Create("Settings")

--==================================================
-- HOME
--==================================================

Components:Section(
    HomePage,
    "Welcome to Floquitave",
    "Control center and session information"
)

local WelcomeCard = Create("Frame", {
    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        110
    ),

    BackgroundColor3 = Config.UI.Secondary,
})

Corner(WelcomeCard, 10)

Stroke(
    WelcomeCard,
    Config.UI.Accent,
    1
)

Create("TextLabel", {
    Parent = WelcomeCard,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        18,
        0,
        15
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        25
    ),

    Text = "Floquitave",

    Font = Enum.Font.GothamBold,

    TextSize = 21,

    TextColor3 = Config.UI.Text,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local WelcomeDescription = Create("TextLabel", {
    Parent = WelcomeCard,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        18,
        0,
        45
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        45
    ),

    Text = "Your session dashboard is ready. Monitor player, server and interface information from one place.",

    Font = Enum.Font.Gotham,

    TextSize = 11,

    TextColor3 = Config.UI.SubText,

    TextWrapped = true,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextYAlignment = Enum.TextYAlignment.Top,
})

--==================================================
-- HOME CARDS
--==================================================

local CardsContainer = Create("Frame", {
    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        184
    ),

    BackgroundTransparency = 1,
})

local CardsGrid = Create("UIGridLayout", {
    Parent = CardsContainer,

    CellSize = UDim2.new(
        0.25,
        -9,
        0,
        85
    ),

    CellPadding = UDim2.new(
        0,
        10,
        0,
        10
    ),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

Components:Card(
    CardsContainer,
    "LEVEL",
    "0"
)

Components:Card(
    CardsContainer,
    "BELI",
    "0"
)

Components:Card(
    CardsContainer,
    "FRAGMENTS",
    "0"
)

Components:Card(
    CardsContainer,
    "RACE",
    "Unknown"
)

Components:Card(
    CardsContainer,
    "SEA",
    "Unknown"
)

Components:Card(
    CardsContainer,
    "FPS",
    "0"
)

Components:Card(
    CardsContainer,
    "PING",
    "0 ms"
)

Components:Card(
    CardsContainer,
    "UPTIME",
    "00:00:00"
)

--==================================================
-- LEVEL PROGRESS
--==================================================

local ProgressSection = Components:Section(
    HomePage,
    "Level Progress",
    "Current character progression"
)

local ProgressContainer = Create("Frame", {
    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        70
    ),

    BackgroundColor3 = Config.UI.Card,
})

Corner(ProgressContainer, 10)

local ProgressBackground = Create("Frame", {
    Parent = ProgressContainer,

    Position = UDim2.new(
        0,
        15,
        0.5,
        -5
    ),

    Size = UDim2.new(
        1,
        -30,
        0,
        10
    ),

    BackgroundColor3 = Color3.fromRGB(
        45,
        45,
        55
    ),
})

Corner(ProgressBackground, 10)

local ProgressBar = Create("Frame", {
    Parent = ProgressBackground,

    Size = UDim2.new(
        0,
        0,
        1,
        0
    ),

    BackgroundColor3 = Config.UI.Accent,
})

Corner(ProgressBar, 10)

local ProgressText = Create("TextLabel", {
    Parent = ProgressContainer,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        15,
        0,
        8
    ),

    Size = UDim2.new(
        1,
        -30,
        0,
        18
    ),

    Text = "Level progress",

    Font = Enum.Font.GothamMedium,

    TextSize = 10,

    TextColor3 = Config.UI.SubText,

    TextXAlignment = Enum.TextXAlignment.Right,
})

--==================================================
-- STATUS
--==================================================

local StatusCard = Create("Frame", {
    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        72
    ),

    BackgroundColor3 = Config.UI.Secondary,
})

Corner(StatusCard, 10)

Stroke(
    StatusCard,
    Color3.fromRGB(42, 42, 57),
    1
)

Create("TextLabel", {
    Parent = StatusCard,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        15,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        100,
        0,
        20
    ),

    Text = "SESSION",

    Font = Enum.Font.GothamBold,

    TextSize = 11,

    TextColor3 = Config.UI.SubText,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local StatusText = Create("TextLabel", {
    Parent = StatusCard,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        15,
        0,
        30
    ),

    Size = UDim2.new(
        1,
        -30,
        0,
        25
    ),

    Text = "Online",

    Font = Enum.Font.GothamMedium,

    TextSize = 12,

    TextColor3 = Config.UI.Text,

    TextXAlignment = Enum.TextXAlignment.Left,
})

--==================================================
-- MAIN FARM PAGE
--==================================================

Components:Section(
    FarmPage,
    "Main Farm",
    "Automation interface foundation"
)

Components:Toggle(
    FarmPage,
    "Auto Farm",
    "Test interface — module not connected.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Auto Farm",
            enabled and "Enabled" or "Disabled"
        )
    end
)

Components:Toggle(
    FarmPage,
    "Auto Mastery",
    "Test interface — module not connected.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Auto Mastery",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--==================================================
-- QUEST PAGE
--==================================================

Components:Section(
    QuestPage,
    "Quest",
    "Quest management interface"
)

Components:Toggle(
    QuestPage,
    "Auto Quest",
    "Test interface — module not connected.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Auto Quest",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--==================================================
-- RAIDS PAGE
--==================================================

Components:Section(
    RaidsPage,
    "Raids",
    "Raid management interface"
)

Components:Toggle(
    RaidsPage,
    "Auto Raid",
    "Test interface — module not connected.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Auto Raid",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--==================================================
-- COMBAT PAGE
--==================================================

Components:Section(
    CombatPage,
    "Combat",
    "Combat interface foundation"
)

Components:Toggle(
    CombatPage,
    "Combat Assist",
    "Test interface — module not connected.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Combat Assist",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--==================================================
-- TELEPORT PAGE
--==================================================

Components:Section(
    TeleportPage,
    "Teleport",
    "Location management interface"
)

Components:Toggle(
    TeleportPage,
    "Teleport Interface",
    "Teleport module foundation.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Teleport",
            enabled and "Interface enabled" or "Interface disabled"
        )
    end
)

--==================================================
-- PLAYER PAGE
--==================================================

Components:Section(
    PlayerPage,
    "Player",
    "Character information and utilities"
)

Components:Toggle(
    PlayerPage,
    "Anti AFK",
    "Keeps the session active.",
    false,
    function(enabled)
        NotificationService:Notify(
            "Anti AFK",
            enabled and "Enabled" or "Disabled"
        )
    end
)

--==================================================
-- MISC PAGE
--==================================================

Components:Section(
    MiscPage,
    "Misc",
    "Additional interface utilities"
)

Components:Toggle(
    MiscPage,
    "Notifications",
    "Enable or disable Floquitave notifications.",
    Config.Notifications.Enabled,
    function(enabled)
        Config.Notifications.Enabled = enabled

        if enabled then
            NotificationService:Notify(
                "Notifications",
                "Notifications enabled."
            )
        end
    end
)

--==================================================
-- SETTINGS PAGE
--==================================================

Components:Section(
    SettingsPage,
    "Interface",
    "Customize the Floquitave interface"
)

Components:Toggle(
    SettingsPage,
    "Animations",
    "Enable interface transitions and animations.",
    Config.UI.Animations,
    function(enabled)
        Config.UI.Animations = enabled

        if enabled then
            NotificationService:Notify(
                "Animations",
                "Animations enabled."
            )
        end
    end
)

Components:Toggle(
    SettingsPage,
    "Notifications",
    "Show Floquitave notification messages.",
    Config.Notifications.Enabled,
    function(enabled)
        Config.Notifications.Enabled = enabled

        if enabled then
            NotificationService:Notify(
                "Notifications",
                "Notifications enabled."
            )
        end
    end
)

--==================================================
-- THEME SELECTOR
--==================================================

local ThemeRow = Create("Frame", {
    Parent = SettingsPage,

    Size = UDim2.new(
        1,
        0,
        0,
        64
    ),

    BackgroundColor3 = Config.UI.Card,
})

Corner(ThemeRow, 9)

Stroke(
    ThemeRow,
    Color3.fromRGB(42, 42, 57),
    1
)

Create("TextLabel", {
    Parent = ThemeRow,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        14,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        200,
        0,
        20
    ),

    Text = "Theme",

    Font = Enum.Font.GothamMedium,

    TextSize = 13,

    TextColor3 = Config.UI.Text,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local ThemeButton = Create("TextButton", {
    Parent = ThemeRow,

    Position = UDim2.new(
        1,
        -150,
        0.5,
        -15
    ),

    Size = UDim2.new(
        0,
        135,
        0,
        30
    ),

    BackgroundColor3 = Config.UI.Secondary,

    Text = "Dark",

    Font = Enum.Font.GothamMedium,

    TextSize = 11,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(ThemeButton, 7)

Connect(ThemeButton.MouseButton1Click, function()
    if Config.UI.Theme == "Dark" then
        Config.UI.Theme = "Light"

        ThemeButton.Text = "Light"

        Config.UI.Background = Color3.fromRGB(
            235,
            235,
            240
        )

        Config.UI.Secondary = Color3.fromRGB(
            245,
            245,
            248
        )

        Config.UI.Card = Color3.fromRGB(
            250,
            250,
            252
        )

        Config.UI.Sidebar = Color3.fromRGB(
            225,
            225,
            232
        )

        Config.UI.Text = Color3.fromRGB(
            25,
            25,
            30
        )

        Config.UI.SubText = Color3.fromRGB(
            90,
            90,
            105
        )

        Main.BackgroundColor3 = Config.UI.Background
        Topbar.BackgroundColor3 = Config.UI.Secondary
        TopbarCover.BackgroundColor3 = Config.UI.Secondary
        Sidebar.BackgroundColor3 = Config.UI.Sidebar

        NotificationService:Notify(
            "Theme",
            "Light theme selected."
        )
    else
        Config.UI.Theme = "Dark"

        ThemeButton.Text = "Dark"

        Config.UI.Background = Color3.fromRGB(
            15,
            15,
            20
        )

        Config.UI.Secondary = Color3.fromRGB(
            20,
            20,
            27
        )

        Config.UI.Card = Color3.fromRGB(
            25,
            25,
            34
        )

        Config.UI.Sidebar = Color3.fromRGB(
            18,
            18,
            24
        )

        Config.UI.Text = Color3.fromRGB(
            240,
            240,
            245
        )

        Config.UI.SubText = Color3.fromRGB(
            150,
            150,
            165
        )

        Main.BackgroundColor3 = Config.UI.Background
        Topbar.BackgroundColor3 = Config.UI.Secondary
        TopbarCover.BackgroundColor3 = Config.UI.Secondary
        Sidebar.BackgroundColor3 = Config.UI.Sidebar

        NotificationService:Notify(
            "Theme",
            "Dark theme selected."
        )
    end
end)

--==================================================
-- UI SCALE
--==================================================

local ScaleRow = Create("Frame", {
    Parent = SettingsPage,

    Size = UDim2.new(
        1,
        0,
        0,
        64
    ),

    BackgroundColor3 = Config.UI.Card,
})

Corner(ScaleRow, 9)

Stroke(
    ScaleRow,
    Color3.fromRGB(42, 42, 57),
    1
)

Create("TextLabel", {
    Parent = ScaleRow,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        0,
        14,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        150,
        0,
        20
    ),

    Text = "UI Scale",

    Font = Enum.Font.GothamMedium,

    TextSize = 13,

    TextColor3 = Config.UI.Text,

    TextXAlignment = Enum.TextXAlignment.Left,
})

local ScaleValue = Create("TextLabel", {
    Parent = ScaleRow,

    BackgroundTransparency = 1,

    Position = UDim2.new(
        1,
        -120,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        100,
        0,
        20
    ),

    Text = "100%",

    Font = Enum.Font.GothamBold,

    TextSize = 12,

    TextColor3 = Config.UI.Accent,

    TextXAlignment = Enum.TextXAlignment.Right,
})

local ScaleMinus = Create("TextButton", {
    Parent = ScaleRow,

    Position = UDim2.new(
        1,
        -110,
        0.5,
        -13
    ),

    Size = UDim2.new(
        0,
        28,
        0,
        26
    ),

    BackgroundColor3 = Config.UI.Secondary,

    Text = "-",

    Font = Enum.Font.GothamBold,

    TextSize = 15,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(ScaleMinus, 6)

local ScalePlus = Create("TextButton", {
    Parent = ScaleRow,

    Position = UDim2.new(
        1,
        -40,
        0.5,
        -13
    ),

    Size = UDim2.new(
        0,
        28,
        0,
        26
    ),

    BackgroundColor3 = Config.UI.Secondary,

    Text = "+",

    Font = Enum.Font.GothamBold,

    TextSize = 15,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(ScalePlus, 6)

local UIScale = Create("UIScale", {
    Parent = Main,

    Scale = Config.UI.Scale,
})

local function UpdateScale()
    Config.UI.Scale = math.clamp(
        Config.UI.Scale,
        0.8,
        1.2
    )

    UIScale.Scale = Config.UI.Scale

    ScaleValue.Text = string.format(
        "%d%%",
        math.floor(Config.UI.Scale * 100)
    )
end

Connect(ScaleMinus.MouseButton1Click, function()
    Config.UI.Scale -= 0.05

    UpdateScale()
end)

Connect(ScalePlus.MouseButton1Click, function()
    Config.UI.Scale += 0.05

    UpdateScale()
end)

--==================================================
-- RESET SETTINGS
--==================================================

local ResetButton = Create("TextButton", {
    Parent = SettingsPage,

    Size = UDim2.new(
        1,
        0,
        0,
        45
    ),

    BackgroundColor3 = Color3.fromRGB(
        45,
        45,
        55
    ),

    Text = "Reset Interface Settings",

    Font = Enum.Font.GothamBold,

    TextSize = 12,

    TextColor3 = Config.UI.Text,

    AutoButtonColor = false,
})

Corner(ResetButton, 8)

Connect(ResetButton.MouseButton1Click, function()
    Config.UI.Theme = "Dark"
    Config.UI.Animations = true
    Config.UI.Scale = 1

    Config.Notifications.Enabled = true

    Config.UI.Background = Color3.fromRGB(
        15,
        15,
        20
    )

    Config.UI.Secondary = Color3.fromRGB(
        20,
        20,
        27
    )

    Config.UI.Card = Color3.fromRGB(
        25,
        25,
        34
    )

    Config.UI.Sidebar = Color3.fromRGB(
        18,
        18,
        24
    )

    Config.UI.Text = Color3.fromRGB(
        240,
        240,
        245
    )

    Config.UI.SubText = Color3.fromRGB(
        150,
        150,
        165
    )

    Main.BackgroundColor3 = Config.UI.Background
    Topbar.BackgroundColor3 = Config.UI.Secondary
    TopbarCover.BackgroundColor3 = Config.UI.Secondary
    Sidebar.BackgroundColor3 = Config.UI.Sidebar

    ThemeButton.Text = "Dark"

    UpdateScale()

    if State.Toggles["Animations"] then
        State.Toggles["Animations"].Set(true)
    end

    NotificationService:Notify(
        "Settings",
        "Interface settings reset."
    )
end)

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

local PageIcons = {
    Home = "⌂",
    ["Main Farm"] = "◆",
    Quest = "◇",
    Raids = "◈",
    Combat = "⚔",
    Teleport = "➜",
    Player = "●",
    Misc = "⚙",
    Settings = "⚙",
}

for index, pageName in ipairs(PageOrder) do
    local button = Create("TextButton", {
        Parent = SidebarScroll,

        Size = UDim2.new(
            1,
            0,
            0,
            38
        ),

        BackgroundColor3 = Config.UI.Sidebar,

        Text = "",

        AutoButtonColor = false,

        LayoutOrder = index,
    })

    Corner(button, 8)

    local icon = Create("TextLabel", {
        Parent = button,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            12,
            0,
            0
        ),

        Size = UDim2.new(
            0,
            24,
            1,
            0
        ),

        Text = PageIcons[pageName] or "•",

        Font = Enum.Font.GothamBold,

        TextSize = 14,

        TextColor3 = Config.UI.SubText,
    })

    local label = Create("TextLabel", {
        Parent = button,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            42,
            0,
            0
        ),

        Size = UDim2.new(
            1,
            -50,
            1,
            0
        ),

        Text = pageName,

        Font = Enum.Font.GothamMedium,

        TextSize = 12,

        TextColor3 = Config.UI.Text,

        TextXAlignment = Enum.TextXAlignment.Left,
    })

    State.Buttons[pageName] = button

    Connect(button.MouseEnter, function()
        if State.CurrentPage ~= pageName then
            Tween(button, {
                BackgroundColor3 = Config.UI.Card
            }, 0.12)
        end
    end)

    Connect(button.MouseLeave, function()
        if State.CurrentPage ~= pageName then
            Tween(button, {
                BackgroundColor3 = Config.UI.Sidebar
            }, 0.12)
        end
    end)

    Connect(button.MouseButton1Click, function()
        PageService:Show(pageName)
    end)
end

--==================================================
-- SEARCH SYSTEM
--==================================================

Connect(SearchBox:GetPropertyChangedSignal("Text"), function()
    local query = string.lower(
        SearchBox.Text or ""
    )

    State.SearchText = query

    for pageName, button in pairs(State.Buttons) do
        local visible = true

        if query ~= "" then
            visible = string.find(
                string.lower(pageName),
                query,
                1,
                true
            ) ~= nil
        end

        button.Visible = visible
    end
end)

--==================================================
-- FLOATING MINIMIZE BUTTON
--==================================================

local FloatingButton = Create("TextButton", {
    Parent = ScreenGui,

    Size = UDim2.new(
        0,
        58,
        0,
        58
    ),

    Position = UDim2.new(
        0,
        25,
        0.5,
        -29
    ),

    BackgroundColor3 = Config.UI.Accent,

    Text = "F",

    TextColor3 = Color3.fromRGB(
        255,
        255,
        255
    ),

    Font = Enum.Font.GothamBold,

    TextSize = 23,

    AutoButtonColor = false,

    Visible = false,

    ZIndex = 100,
})

Corner(FloatingButton, 100)

Stroke(
    FloatingButton,
    Color3.fromRGB(65, 65, 80),
    1
)

--==================================================
-- FLOATING BUTTON DRAG
--==================================================

local floatingDragging = false
local floatingMoved = false
local floatingDragStart
local floatingStartPosition

Connect(FloatingButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        floatingDragging = true
        floatingMoved = false

        floatingDragStart = input.Position
        floatingStartPosition = FloatingButton.Position
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not floatingDragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - floatingDragStart

    if math.abs(delta.X) > 5
        or math.abs(delta.Y) > 5 then

        floatingMoved = true
    end

    FloatingButton.Position = UDim2.new(
        floatingStartPosition.X.Scale,
        floatingStartPosition.X.Offset + delta.X,

        floatingStartPosition.Y.Scale,
        floatingStartPosition.Y.Offset + delta.Y
    )
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        if not floatingDragging then
            return
        end

        floatingDragging = false

        if not floatingMoved then
            State.Minimized = false

            FloatingButton.Visible = false

            Main.Visible = true

            Main.Size = UDim2.new(
                0,
                0,
                0,
                0
            )

            Tween(Main, {
                Size = UDim2.new(
                    0,
                    Config.UI.Width,
                    0,
                    Config.UI.Height
                )
            }, 0.25)
        end
    end
end)

--==================================================
-- MINIMIZE
--==================================================

Connect(MinimizeButton.MouseButton1Click, function()
    if State.Minimized then
        return
    end

    State.Minimized = true

    Tween(Main, {
        Size = UDim2.new(
            0,
            0,
            0,
            0
        )
    }, 0.2)

    task.delay(0.2, function()
        if State.Destroyed then
            return
        end

        Main.Visible = false

        FloatingButton.Visible = true

        FloatingButton.Size = UDim2.new(
            0,
            0,
            0,
            0
        )

        Tween(FloatingButton, {
            Size = UDim2.new(
                0,
                58,
                0,
                58
            )
        }, 0.25)
    end)
end)

--==================================================
-- CLOSE
--==================================================

Connect(CloseButton.MouseButton1Click, function()
    NotificationService:Notify(
        "Floquitave",
        "Closing interface..."
    )

    task.delay(0.15, function()
        Cleanup()

        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
end)

--==================================================
-- FPS TRACKING
--==================================================

local frameCounter = 0
local fpsTimer = os.clock()

Connect(RunService.RenderStepped, function()
    if State.Destroyed then
        return
    end

    frameCounter += 1

    local now = os.clock()

    if now - fpsTimer >= 1 then
        State.FPS = frameCounter

        frameCounter = 0
        fpsTimer = now
    end
end)

--==================================================
-- LIVE DATA
--==================================================

local updateAccumulator = 0

Connect(RunService.Heartbeat, function(deltaTime)
    if State.Destroyed then
        return
    end

    updateAccumulator += deltaTime

    if updateAccumulator < Config.Performance.UpdateInterval then
        return
    end

    updateAccumulator = 0

    -- Player data
    local level = PlayerService:GetLevel()
    local beli = PlayerService:GetBeli()
    local fragments = PlayerService:GetFragments()
    local race = PlayerService:GetRace()

    -- World
    local sea = WorldService:GetSea()

    -- Performance
    local ping = PerformanceService:GetPing()

    -- Uptime
    local elapsed = os.clock() - StartTime

    -- Update cards
    if State.Cards["LEVEL"] then
        State.Cards["LEVEL"].Text = FormatNumber(level)
    end

    if State.Cards["BELI"] then
        State.Cards["BELI"].Text = FormatNumber(beli)
    end

    if State.Cards["FRAGMENTS"] then
        State.Cards["FRAGMENTS"].Text = FormatNumber(fragments)
    end

    if State.Cards["RACE"] then
        State.Cards["RACE"].Text = race
    end

    if State.Cards["SEA"] then
        State.Cards["SEA"].Text = sea
    end

    if State.Cards["FPS"] then
        State.Cards["FPS"].Text = tostring(State.FPS)
    end

    if State.Cards["PING"] then
        State.Cards["PING"].Text = tostring(ping) .. " ms"
    end

    if State.Cards["UPTIME"] then
        State.Cards["UPTIME"].Text = FormatTime(elapsed)
    end

    -- Progress
    local progress = math.clamp(
        (level % 100) / 100,
        0,
        1
    )

    Tween(
        ProgressBar,
        {
            Size = UDim2.new(
                progress,
                0,
                1,
                0
            )
        },
        0.25
    )

    ProgressText.Text = string.format(
        "Level %d  •  %d%%",
        level,
        math.floor(progress * 100)
    )

    -- Session status
    StatusText.Text = string.format(
        "Online  •  %s  •  %d FPS  •  %d ms",
        sea,
        State.FPS,
        ping
    )
end)

--==================================================
-- INITIAL PAGE
--==================================================

PageService:Show("Home")

--==================================================
-- INITIALIZATION
--==================================================

task.defer(function()
    task.wait(0.5)

    if State.Destroyed then
        return
    end

    NotificationService:Notify(
        "Floquitave",
        "Version " .. Config.Version .. " loaded successfully."
    )
end)

print(
    "[Floquitave] " ..
    Config.Name ..
    " v" ..
    Config.Version ..
    " loaded."
)
