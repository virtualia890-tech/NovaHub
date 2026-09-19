--[[
    Floquitave Hub
    Version: 2.4.0

    UI / Diagnostics Foundation
    No automation / bypass functionality included.
]]

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {

    Name = "Floquitave",
    Version = "2.4.0",

    UI = {
        Width = 920,
        Height = 590,

        Animations = true,
        Scale = 1,

        Theme = "Dark",

        Accent = Color3.fromRGB(115, 90, 255),

        Background = Color3.fromRGB(18, 18, 24),
        Secondary = Color3.fromRGB(23, 23, 31),
        Card = Color3.fromRGB(28, 28, 38),
        Sidebar = Color3.fromRGB(21, 21, 29),

        Text = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(155, 155, 170),
    },

    Notifications = {
        Enabled = true,
        Duration = 3,
    },

    Performance = {
        UpdateInterval = 0.5,
    },
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

local StartTime = os.clock()

--==================================================
-- CONNECTION MANAGER
--==================================================

local function Connect(signal, callback)

    local connection = signal:Connect(callback)

    table.insert(State.Connections, connection)

    return connection
end

local function Cleanup()

    State.Destroyed = true

    for _, connection in ipairs(State.Connections) do

        if connection and connection.Connected then
            connection:Disconnect()
        end

    end

    State.Connections = {}

end

--==================================================
-- UTILITIES
--==================================================

local function Tween(
    instance,
    properties,
    duration,
    style,
    direction
)

    if not instance then
        return
    end

    if not Config.UI.Animations then

        for property, value in pairs(properties) do
            instance[property] = value
        end

        return
    end

    local tweenInfo = TweenInfo.new(

        duration or 0.25,

        style or Enum.EasingStyle.Quint,

        direction or Enum.EasingDirection.Out

    )

    local tween = TweenService:Create(
        instance,
        tweenInfo,
        properties
    )

    tween:Play()

    return tween
end

local function Create(className, properties)

    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function Corner(parent, radius)

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(
        0,
        radius or 8
    )

    corner.Parent = parent

    return corner
end

local function Stroke(parent, color, transparency)

    local stroke = Instance.new("UIStroke")

    stroke.Color = color or Config.UI.Accent
    stroke.Transparency = transparency or 0.5
    stroke.Thickness = 1

    stroke.Parent = parent

    return stroke
end

local function Padding(parent, value)

    local padding = Instance.new("UIPadding")

    padding.PaddingTop = UDim.new(0, value)
    padding.PaddingBottom = UDim.new(0, value)
    padding.PaddingLeft = UDim.new(0, value)
    padding.PaddingRight = UDim.new(0, value)

    padding.Parent = parent

    return padding
end

local function FormatNumber(number)

    number = tonumber(number) or 0

    if number >= 1000000000 then
        return string.format("%.1fB", number / 1000000000)

    elseif number >= 1000000 then
        return string.format("%.1fM", number / 1000000)

    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)

    end

    return tostring(math.floor(number))
end

local function FormatTime(seconds)

    seconds = math.max(
        0,
        math.floor(seconds)
    )

    local hours = math.floor(seconds / 3600)

    local minutes = math.floor(
        (seconds % 3600) / 60
    )

    local secs = seconds % 60

    return string.format(
        "%02d:%02d:%02d",
        hours,
        minutes,
        secs
    )
end

--==================================================
-- UI EFFECTS
--==================================================

local function AddHoverEffect(object, scaleAmount)

    if not object then
        return
    end

    local scale = object:FindFirstChild(
        "HoverScale"
    )

    if not scale then

        scale = Instance.new("UIScale")

        scale.Name = "HoverScale"
        scale.Scale = 1
        scale.Parent = object

    end

    scaleAmount = scaleAmount or 1.02

    if object:IsA("GuiButton") then

        Connect(object.MouseEnter, function()

            Tween(
                scale,
                {
                    Scale = scaleAmount
                },
                0.18,
                Enum.EasingStyle.Sine
            )

        end)

        Connect(object.MouseLeave, function()

            Tween(
                scale,
                {
                    Scale = 1
                },
                0.22,
                Enum.EasingStyle.Sine
            )

        end)

        Connect(object.MouseButton1Down, function()

            Tween(
                scale,
                {
                    Scale = 0.97
                },
                0.08,
                Enum.EasingStyle.Sine
            )

        end)

        Connect(object.MouseButton1Up, function()

            Tween(
                scale,
                {
                    Scale = scaleAmount
                },
                0.12,
                Enum.EasingStyle.Sine
            )

        end)

    else

        Connect(object.MouseEnter, function()

            Tween(
                scale,
                {
                    Scale = scaleAmount
                },
                0.18,
                Enum.EasingStyle.Sine
            )

        end)

        Connect(object.MouseLeave, function()

            Tween(
                scale,
                {
                    Scale = 1
                },
                0.22,
                Enum.EasingStyle.Sine
            )

        end)

    end

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

--==================================================
-- PLAYER SERVICE
--==================================================

local PlayerService = {}

function PlayerService:GetData()

    local data = LocalPlayer:FindFirstChild("Data")

    if not data then
        return nil
    end

    return data
end

function PlayerService:GetLevel()

    local data = self:GetData()

    if not data then
        return 0
    end

    local level = data:FindFirstChild("Level")

    return level and level.Value or 0
end

function PlayerService:GetBeli()

    local data = self:GetData()

    if not data then
        return 0
    end

    local beli = data:FindFirstChild("Beli")

    return beli and beli.Value or 0
end

function PlayerService:GetFragments()

    local data = self:GetData()

    if not data then
        return 0
    end

    local fragments = data:FindFirstChild("Fragments")

    return fragments and fragments.Value or 0
end

function PlayerService:GetRace()

    local data = self:GetData()

    if not data then
        return "Unknown"
    end

    local race = data:FindFirstChild("Race")

    return race and tostring(race.Value) or "Unknown"
end

function PlayerService:GetHealth()

    local character = LocalPlayer.Character

    if not character then
        return 0, 0
    end

    local humanoid = character:FindFirstChildOfClass(
        "Humanoid"
    )

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

    local humanoid = character:FindFirstChildOfClass(
        "Humanoid"
    )

    if not humanoid then
        return 0, 0
    end

    return humanoid.Health, humanoid.MaxHealth
end

--==================================================
-- PERFORMANCE SERVICE
--==================================================

local PerformanceService = {}

function PerformanceService:GetPing()

    local success, result = pcall(function()

        local network = Stats.Network

        local serverStats =
            network:FindFirstChild(
                "ServerStatsItem"
            )

        if not serverStats then
            return 0
        end

        local ping =
            serverStats:FindFirstChild(
                "Data Ping"
            )

        if not ping then
            return 0
        end

        return ping:GetValue()

    end)

    if success then
        return math.floor(result or 0)
    end

    return 0
end

--==================================================
-- NOTIFICATION SERVICE
--==================================================

local NotificationService = {}

local NotificationHolder

function NotificationService:Notify(
    title,
    message
)

    if not Config.Notifications.Enabled then
        return
    end

    if not NotificationHolder then
        return
    end

    local notification = Create("Frame", {

        Parent = NotificationHolder,

        Size = UDim2.new(
            1,
            0,
            0,
            70
        ),

        BackgroundColor3 =
            Config.UI.Card,

        BackgroundTransparency = 1,

    })

    Corner(notification, 10)

    local scale = Instance.new("UIScale")

    scale.Scale = 0.92
    scale.Parent = notification

    local titleLabel = Create("TextLabel", {

        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            14,
            0,
            10
        ),

        Size = UDim2.new(
            1,
            -28,
            0,
            18
        ),

        Text = title,

        Font = Enum.Font.GothamBold,

        TextSize = 13,

        TextColor3 =
            Config.UI.Text,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    })

    local messageLabel = Create("TextLabel", {

        Parent = notification,

        BackgroundTransparency = 1,

        Position = UDim2.new(
            0,
            14,
            0,
            32
        ),

        Size = UDim2.new(
            1,
            -28,
            0,
            25
        ),

        Text = message,

        Font = Enum.Font.Gotham,

        TextSize = 11,

        TextColor3 =
            Config.UI.SubText,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    })

    Tween(
        notification,
        {
            BackgroundTransparency = 0
        },
        0.25,
        Enum.EasingStyle.Quint
    )

    Tween(
        scale,
        {
            Scale = 1
        },
        0.35,
        Enum.EasingStyle.Back
    )

    task.delay(
        Config.Notifications.Duration,
        function()

            if not notification.Parent then
                return
            end

            Tween(
                scale,
                {
                    Scale = 0.94
                },
                0.2
            )

            Tween(
                notification,
                {
                    BackgroundTransparency = 1
                },
                0.25
            )

            task.wait(0.3)

            if notification then
                notification:Destroy()
            end

        end
    )
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Create("ScreenGui", {

    Name = "FloquitaveUI",

    ResetOnSpawn = false,

    ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling,

})

pcall(function()

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end

end)

ScreenGui.Parent = CoreGui

--==================================================
-- MAIN CONTAINER
--==================================================

local Main = Create("Frame", {

    Parent = ScreenGui,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.new(
        0.5,
        0,
        0.5,
        0
    ),

    Size = UDim2.new(
        0,
        Config.UI.Width,
        0,
        Config.UI.Height
    ),

    BackgroundColor3 =
        Config.UI.Background,

    BorderSizePixel = 0,

})

Corner(Main, 14)

local MainStroke = Stroke(
    Main,
    Config.UI.Accent,
    0.75
)

local MainScale = Instance.new("UIScale")

MainScale.Scale = 0.94
MainScale.Parent = Main

--==================================================
-- OPEN ANIMATION
--==================================================

task.defer(function()

    Tween(
        MainScale,
        {
            Scale = Config.UI.Scale
        },
        0.45,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

end)

--==================================================
-- TOP BAR
--==================================================

local Topbar = Create("Frame", {

    Parent = Main,

    Size = UDim2.new(
        1,
        0,
        0,
        58
    ),

    BackgroundColor3 =
        Config.UI.Secondary,

    BorderSizePixel = 0,

})

Corner(Topbar, 14)

local TopbarLine = Create("Frame", {

    Parent = Topbar,

    Position = UDim2.new(
        0,
        0,
        1,
        -1
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        1
    ),

    BackgroundColor3 =
        Config.UI.Accent,

    BackgroundTransparency = 0.75,

    BorderSizePixel = 0,

})

--==================================================
-- LOGO
--==================================================

local Logo = Create("TextLabel", {

    Parent = Topbar,

    Position = UDim2.new(
        0,
        18,
        0.5,
        -18
    ),

    Size = UDim2.new(
        0,
        36,
        0,
        36
    ),

    BackgroundColor3 =
        Config.UI.Accent,

    Text = "F",

    Font = Enum.Font.GothamBold,

    TextSize = 20,

    TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        ),

})

Corner(Logo, 10)

--==================================================
-- TITLE
--==================================================

local Title = Create("TextLabel", {

    Parent = Topbar,

    Position = UDim2.new(
        0,
        68,
        0,
        10
    ),

    Size = UDim2.new(
        0,
        300,
        0,
        22
    ),

    BackgroundTransparency = 1,

    Text = Config.Name,

    Font = Enum.Font.GothamBold,

    TextSize = 16,

    TextColor3 =
        Config.UI.Text,

    TextXAlignment =
        Enum.TextXAlignment.Left,

})

local VersionLabel = Create("TextLabel", {

    Parent = Topbar,

    Position = UDim2.new(
        0,
        68,
        0,
        31
    ),

    Size = UDim2.new(
        0,
        200,
        0,
        16
    ),

    BackgroundTransparency = 1,

    Text = "Version " .. Config.Version,

    Font = Enum.Font.Gotham,

    TextSize = 10,

    TextColor3 =
        Config.UI.SubText,

    TextXAlignment =
        Enum.TextXAlignment.Left,

})

--==================================================
-- TOPBAR BUTTONS
--==================================================

local MinimizeButton = Create("TextButton", {

    Parent = Topbar,

    Position = UDim2.new(
        1,
        -92,
        0.5,
        -16
    ),

    Size = UDim2.new(
        0,
        32,
        0,
        32
    ),

    BackgroundColor3 =
        Config.UI.Card,

    Text = "—",

    Font = Enum.Font.GothamBold,

    TextSize = 16,

    TextColor3 =
        Config.UI.Text,

    AutoButtonColor = false,

})

Corner(MinimizeButton, 8)

local CloseButton = Create("TextButton", {

    Parent = Topbar,

    Position = UDim2.new(
        1,
        -52,
        0.5,
        -16
    ),

    Size = UDim2.new(
        0,
        32,
        0,
        32
    ),

    BackgroundColor3 =
        Color3.fromRGB(
            60,
            35,
            45
        ),

    Text = "×",

    Font = Enum.Font.GothamBold,

    TextSize = 18,

    TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        ),

    AutoButtonColor = false,

})

Corner(CloseButton, 8)

AddHoverEffect(
    MinimizeButton,
    1.06
)

AddHoverEffect(
    CloseButton,
    1.06
)

--==================================================
-- BODY
--==================================================

local Body = Create("Frame", {

    Parent = Main,

    Position = UDim2.new(
        0,
        0,
        0,
        58
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        -58
    ),

    BackgroundTransparency = 1,

})

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Create("Frame", {

    Parent = Body,

    Size = UDim2.new(
        0,
        190,
        1,
        0
    ),

    BackgroundColor3 =
        Config.UI.Sidebar,

    BorderSizePixel = 0,

})

local SidebarPadding = Padding(
    Sidebar,
    12
)

--==================================================
-- SEARCH
--==================================================

local SearchBox = Create("TextBox", {

    Parent = Sidebar,

    Size = UDim2.new(
        1,
        0,
        0,
        38
    ),

    BackgroundColor3 =
        Config.UI.Card,

    PlaceholderText =
        "Search pages...",

    PlaceholderColor3 =
        Config.UI.SubText,

    Text = "",

    Font = Enum.Font.Gotham,

    TextSize = 11,

    TextColor3 =
        Config.UI.Text,

    ClearTextOnFocus = false,

})

Corner(SearchBox, 9)

--==================================================
-- PAGE LIST
--==================================================

local PageList = Create("ScrollingFrame", {

    Parent = Sidebar,

    Position = UDim2.new(
        0,
        0,
        0,
        52
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        -52
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    ScrollBarThickness = 2,

    ScrollBarImageColor3 =
        Config.UI.Accent,

    CanvasSize = UDim2.new(
        0,
        0,
        0,
        0
    ),

})

local PageLayout = Instance.new(
    "UIListLayout"
)

PageLayout.Padding = UDim.new(
    0,
    6
)

PageLayout.Parent = PageList

--==================================================
-- CONTENT
--==================================================

local Content = Create("ScrollingFrame", {

    Parent = Body,

    Position = UDim2.new(
        0,
        190,
        0,
        0
    ),

    Size = UDim2.new(
        1,
        -190,
        1,
        0
    ),

    BackgroundColor3 =
        Config.UI.Background,

    BorderSizePixel = 0,

    ScrollBarThickness = 3,

    ScrollBarImageColor3 =
        Config.UI.Accent,

    CanvasSize = UDim2.new(
        0,
        0,
        0,
        0
    ),

})

Padding(Content, 18)

local ContentLayout = Instance.new(
    "UIListLayout"
)

ContentLayout.Padding = UDim.new(
    0,
    12
)

ContentLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

ContentLayout.Parent = Content

--==================================================
-- NOTIFICATION HOLDER
--==================================================

NotificationHolder = Create(
    "Frame",
    {

        Parent = ScreenGui,

        AnchorPoint =
            Vector2.new(1, 0),

        Position = UDim2.new(
            1,
            -18,
            0,
            18
        ),

        Size = UDim2.new(
            0,
            290,
            0,
            0
        ),

        BackgroundTransparency = 1,

    }
)

local NotificationLayout =
    Instance.new("UIListLayout")

NotificationLayout.Padding =
    UDim.new(0, 8)

NotificationLayout.VerticalAlignment =
    Enum.VerticalAlignment.Top

NotificationLayout.Parent =
    NotificationHolder

--==================================================
-- COMPONENTS
--==================================================

local Components = {}

function Components:Section(
    parent,
    title,
    description
)

    local section = Create(
        "Frame",
        {

            Parent = parent,

            Size = UDim2.new(
                1,
                0,
                0,
                44
            ),

            BackgroundTransparency = 1,

        }
    )

    local titleLabel = Create(
        "TextLabel",
        {

            Parent = section,

            Size = UDim2.new(
                1,
                0,
                0,
                22
            ),

            BackgroundTransparency = 1,

            Text = title,

            Font = Enum.Font.GothamBold,

            TextSize = 14,

            TextColor3 =
                Config.UI.Text,

            TextXAlignment =
                Enum.TextXAlignment.Left,

        }
    )

    local descriptionLabel =
        Create(
            "TextLabel",
            {

                Parent = section,

                Position = UDim2.new(
                    0,
                    0,
                    0,
                    22
                ),

                Size = UDim2.new(
                    1,
                    0,
                    0,
                    18
                ),

                BackgroundTransparency = 1,

                Text = description or "",

                Font = Enum.Font.Gotham,

                TextSize = 10,

                TextColor3 =
                    Config.UI.SubText,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

            }
        )

    return section
end

function Components:Card(
    parent,
    title,
    value
)

    local card = Create(
        "Frame",
        {

            Parent = parent,

            BackgroundColor3 =
                Config.UI.Card,

            BorderSizePixel = 0,

        }
    )

    Corner(card, 10)

    AddHoverEffect(
        card,
        1.015
    )

    local titleLabel =
        Create(
            "TextLabel",
            {

                Parent = card,

                Position = UDim2.new(
                    0,
                    12,
                    0,
                    10
                ),

                Size = UDim2.new(
                    1,
                    -24,
                    0,
                    16
                ),

                BackgroundTransparency = 1,

                Text = title,

                Font = Enum.Font.GothamMedium,

                TextSize = 9,

                TextColor3 =
                    Config.UI.SubText,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

            }
        )

    local valueLabel =
        Create(
            "TextLabel",
            {

                Parent = card,

                Position = UDim2.new(
                    0,
                    12,
                    0,
                    30
                ),

                Size = UDim2.new(
                    1,
                    -24,
                    0,
                    28
                ),

                BackgroundTransparency = 1,

                Text = tostring(value),

                Font = Enum.Font.GothamBold,

                TextSize = 17,

                TextColor3 =
                    Config.UI.Text,

                TextXAlignment =
                    Enum.TextXAlignment.Left,

            }
        )

    State.Cards[title] = {
        Frame = card,
        Value = valueLabel,
    }

    return card
end

function Components:Toggle(
    parent,
    title,
    default,
    callback
)

    local holder = Create(
        "Frame",
        {

            Parent = parent,

            Size = UDim2.new(
                1,
                0,
                0,
                48
            ),

            BackgroundColor3 =
                Config.UI.Card,

            BorderSizePixel = 0,

        }
    )

    Corner(holder, 10)

    local label = Create(
        "TextLabel",
        {

            Parent = holder,

            Position = UDim2.new(
                0,
                14,
                0,
                0
            ),

            Size = UDim2.new(
                1,
                -80,
                1,
                0
            ),

            BackgroundTransparency = 1,

            Text = title,

            Font = Enum.Font.GothamMedium,

            TextSize = 11,

            TextColor3 =
                Config.UI.Text,

            TextXAlignment =
                Enum.TextXAlignment.Left,

        }
    )

    local button = Create(
        "TextButton",
        {

            Parent = holder,

            AnchorPoint =
                Vector2.new(1, 0.5),

            Position = UDim2.new(
                1,
                -12,
                0.5,
                0
            ),

            Size = UDim2.new(
                0,
                42,
                0,
                22
            ),

            BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    50,
                    60
                ),

            Text = "",

            AutoButtonColor = false,

        }
    )

    Corner(button, 11)

    local knob = Create(
        "Frame",
        {

            Parent = button,

            Position = UDim2.new(
                0,
                3,
                0.5,
                -8
            ),

            Size = UDim2.new(
                0,
                16,
                0,
                16
            ),

            BackgroundColor3 =
                Color3.fromRGB(
                    230,
                    230,
                    235
                ),

        }
    )

    Corner(knob, 8)

    local enabled = default == true

    local function UpdateToggle(
        animate
    )

        local duration =
            animate and 0.25 or 0

        if enabled then

            Tween(
                button,
                {
                    BackgroundColor3 =
                        Config.UI.Accent
                },
                duration,
                Enum.EasingStyle.Sine
            )

            Tween(
                knob,
                {
                    Position =
                        UDim2.new(
                            1,
                            -19,
                            0.5,
                            -8
                        )
                },
                duration,
                Enum.EasingStyle.Back
            )

        else

            Tween(
                button,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            50,
                            50,
                            60
                        )
                },
                duration,
                Enum.EasingStyle.Sine
            )

            Tween(
                knob,
                {
                    Position =
                        UDim2.new(
                            0,
                            3,
                            0.5,
                            -8
                        )
                },
                duration,
                Enum.EasingStyle.Back
            )

        end

    end

    Connect(
        button.MouseButton1Click,
        function()

            enabled = not enabled

            UpdateToggle(true)

            if callback then
                callback(enabled)
            end

        end
    )

    AddHoverEffect(
        button,
        1.05
    )

    UpdateToggle(false)

    State.Toggles[title] = {
        Get = function()
            return enabled
        end,

        Set = function(value)

            enabled = value == true

            UpdateToggle(true)

            if callback then
                callback(enabled)
            end

        end,
    }

    return holder
end

--==================================================
-- PAGE SERVICE
--==================================================

local PageService = {}

function PageService:Create(
    name
)

    local page = Create(
        "Frame",
        {

            Parent = Content,

            Size = UDim2.new(
                1,
                -4,
                0,
                0
            ),

            AutomaticSize =
                Enum.AutomaticSize.Y,

            BackgroundTransparency = 1,

            Visible = false,

        }
    )

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(0, 12)

    layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    layout.Parent = page

    State.Pages[name] = page

    return page
end

function PageService:Show(name)

    for pageName, page in pairs(
        State.Pages
    ) do

        page.Visible =
            pageName == name

    end

    State.CurrentPage = name

    for _, buttonData in pairs(
        State.Buttons
    ) do

        local button =
            buttonData.Button

        if buttonData.Name == name then

            Tween(
                button,
                {
                    BackgroundColor3 =
                        Config.UI.Accent
                },
                0.22,
                Enum.EasingStyle.Sine
            )

        else

            Tween(
                button,
                {
                    BackgroundColor3 =
                        Config.UI.Card
                },
                0.22,
                Enum.EasingStyle.Sine
            )

        end

    end

    Content.CanvasPosition =
        Vector2.new(0, 0)

end

--==================================================
-- PAGES
--==================================================

local HomePage =
    PageService:Create("Home")

local FarmPage =
    PageService:Create("Main Farm")

local QuestPage =
    PageService:Create("Quest")

local RaidPage =
    PageService:Create("Raids")

local CombatPage =
    PageService:Create("Combat")

local TeleportPage =
    PageService:Create("Teleport")

local PlayerPage =
    PageService:Create("Player")

local MiscPage =
    PageService:Create("Misc")

local SettingsPage =
    PageService:Create("Settings")

--==================================================
-- HOME
--==================================================

Components:Section(
    HomePage,
    "Welcome to Floquitave",
    "Interface and live session information"
)

local Welcome = Create(
    "Frame",
    {

        Parent = HomePage,

        Size = UDim2.new(
            1,
            0,
            0,
            92
        ),

        BackgroundColor3 =
            Config.UI.Secondary,

    }
)

Corner(Welcome, 12)

local WelcomeTitle = Create(
    "TextLabel",
    {

        Parent = Welcome,

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
            24
        ),

        BackgroundTransparency = 1,

        Text = "Welcome back, "
            .. LocalPlayer.DisplayName,

        Font = Enum.Font.GothamBold,

        TextSize = 17,

        TextColor3 =
            Config.UI.Text,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    }
)

local WelcomeSub = Create(
    "TextLabel",
    {

        Parent = Welcome,

        Position = UDim2.new(
            0,
            18,
            0,
            43
        ),

        Size = UDim2.new(
            1,
            -36,
            0,
            32
        ),

        BackgroundTransparency = 1,

        Text =
            "Floquitave is running correctly. "
            .. "Use the sidebar to explore the interface.",

        Font = Enum.Font.Gotham,

        TextSize = 11,

        TextColor3 =
            Config.UI.SubText,

        TextWrapped = true,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    }
)

--==================================================
-- HOME CARDS
--==================================================

local CardsContainer = Create(
    "Frame",
    {

        Parent = HomePage,

        Size = UDim2.new(
            1,
            0,
            0,
            174
        ),

        BackgroundTransparency = 1,

    }
)

local CardsGrid =
    Instance.new("UIGridLayout")

CardsGrid.CellSize =
    UDim2.new(
        0.25,
        -9,
        0,
        78
    )

CardsGrid.CellPadding =
    UDim2.new(
        0,
        10,
        0,
        10
    )

CardsGrid.SortOrder =
    Enum.SortOrder.LayoutOrder

CardsGrid.Parent =
    CardsContainer

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
-- SESSION STATUS
--==================================================

local StatusSection =
    Components:Section(
        HomePage,
        "Session",
        "Current script session status"
    )

local StatusCard = Create(
    "Frame",
    {

        Parent = HomePage,

        Size = UDim2.new(
            1,
            0,
            0,
            64
        ),

        BackgroundColor3 =
            Config.UI.Card,

    }
)

Corner(StatusCard, 10)

local StatusDot = Create(
    "Frame",
    {

        Parent = StatusCard,

        Position = UDim2.new(
            0,
            16,
            0.5,
            -6
        ),

        Size = UDim2.new(
            0,
            12,
            0,
            12
        ),

        BackgroundColor3 =
            Color3.fromRGB(
                90,
                220,
                130
            ),

    }
)

Corner(StatusDot, 6)

local StatusText = Create(
    "TextLabel",
    {

        Parent = StatusCard,

        Position = UDim2.new(
            0,
            38,
            0,
            14
        ),

        Size = UDim2.new(
            1,
            -50,
            0,
            18
        ),

        BackgroundTransparency = 1,

        Text =
            "Floquitave is active",

        Font = Enum.Font.GothamMedium,

        TextSize = 11,

        TextColor3 =
            Config.UI.Text,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    }
)

local StatusSub = Create(
    "TextLabel",
    {

        Parent = StatusCard,

        Position = UDim2.new(
            0,
            38,
            0,
            33
        ),

        Size = UDim2.new(
            1,
            -50,
            0,
            16
        ),

        BackgroundTransparency = 1,

        Text =
            "Live diagnostics are updating.",

        Font = Enum.Font.Gotham,

        TextSize = 9,

        TextColor3 =
            Config.UI.SubText,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    }
)

--==================================================
-- MAIN FARM
--==================================================

Components:Section(
    FarmPage,
    "Main Farm",
    "Interface controls reserved for future modules"
)

Components:Toggle(
    FarmPage,
    "Auto Farm",
    false,
    function(enabled)

        NotificationService:Notify(
            "Auto Farm",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

Components:Toggle(
    FarmPage,
    "Auto Mastery",
    false,
    function(enabled)

        NotificationService:Notify(
            "Auto Mastery",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

--==================================================
-- QUEST
--==================================================

Components:Section(
    QuestPage,
    "Quest",
    "Quest interface foundation"
)

Components:Toggle(
    QuestPage,
    "Auto Quest",
    false,
    function(enabled)

        NotificationService:Notify(
            "Auto Quest",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

--==================================================
-- RAIDS
--==================================================

Components:Section(
    RaidPage,
    "Raids",
    "Raid interface foundation"
)

Components:Toggle(
    RaidPage,
    "Auto Raid",
    false,
    function(enabled)

        NotificationService:Notify(
            "Auto Raid",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

--==================================================
-- COMBAT
--==================================================

Components:Section(
    CombatPage,
    "Combat",
    "Combat interface foundation"
)

Components:Toggle(
    CombatPage,
    "Combat Assist",
    false,
    function(enabled)

        NotificationService:Notify(
            "Combat Assist",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

--==================================================
-- TELEPORT
--==================================================

Components:Section(
    TeleportPage,
    "Teleport",
    "Teleport interface foundation"
)

Components:Toggle(
    TeleportPage,
    "Teleport Interface",
    false,
    function(enabled)

        NotificationService:Notify(
            "Teleport",
            enabled
                and "Interface enabled."
                or "Interface disabled."
        )

    end
)

--==================================================
-- PLAYER
--==================================================

Components:Section(
    PlayerPage,
    "Player",
    "Local player information"
)

local PlayerInfo = Create(
    "Frame",
    {

        Parent = PlayerPage,

        Size = UDim2.new(
            1,
            0,
            0,
            105
        ),

        BackgroundColor3 =
            Config.UI.Card,

    }
)

Corner(PlayerInfo, 10)

local PlayerInfoText = Create(
    "TextLabel",
    {

        Parent = PlayerInfo,

        Position = UDim2.new(
            0,
            15,
            0,
            12
        ),

        Size = UDim2.new(
            1,
            -30,
            1,
            -24
        ),

        BackgroundTransparency = 1,

        Text = "",

        Font = Enum.Font.Gotham,

        TextSize = 11,

        TextColor3 =
            Config.UI.Text,

        TextWrapped = true,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextYAlignment =
            Enum.TextYAlignment.Top,

    }
)

--==================================================
-- MISC
--==================================================

Components:Section(
    MiscPage,
    "Misc",
    "Additional interface options"
)

Components:Toggle(
    MiscPage,
    "Anti AFK",
    false,
    function(enabled)

        NotificationService:Notify(
            "Anti AFK",
            enabled
                and "Test toggle enabled."
                or "Test toggle disabled."
        )

    end
)

Components:Toggle(
    MiscPage,
    "Notifications",
    true,
    function(enabled)

        Config.Notifications.Enabled =
            enabled

    end
)

--==================================================
-- SETTINGS
--==================================================

Components:Section(
    SettingsPage,
    "Interface Settings",
    "Customize the Floquitave interface"
)

Components:Toggle(
    SettingsPage,
    "Animations",
    true,
    function(enabled)

        Config.UI.Animations =
            enabled

        NotificationService:Notify(
            "Animations",
            enabled
                and "Animations enabled."
                or "Animations disabled."
        )

    end
)

Components:Toggle(
    SettingsPage,
    "Notifications",
    true,
    function(enabled)

        Config.Notifications.Enabled =
            enabled

    end
)

Components:Toggle(
    SettingsPage,
    "Dark Theme",
    true,
    function(enabled)

        if enabled then

            Config.UI.Theme = "Dark"

            Config.UI.Background =
                Color3.fromRGB(
                    18,
                    18,
                    24
                )

            Config.UI.Secondary =
                Color3.fromRGB(
                    23,
                    23,
                    31
                )

            Config.UI.Card =
                Color3.fromRGB(
                    28,
                    28,
                    38
                )

            Config.UI.Sidebar =
                Color3.fromRGB(
                    21,
                    21,
                    29
                )

            Config.UI.Text =
                Color3.fromRGB(
                    245,
                    245,
                    250
                )

            Config.UI.SubText =
                Color3.fromRGB(
                    155,
                    155,
                    170
                )

        else

            Config.UI.Theme = "Light"

            Config.UI.Background =
                Color3.fromRGB(
                    235,
                    235,
                    242
                )

            Config.UI.Secondary =
                Color3.fromRGB(
                    245,
                    245,
                    250
                )

            Config.UI.Card =
                Color3.fromRGB(
                    255,
                    255,
                    255
                )

            Config.UI.Sidebar =
                Color3.fromRGB(
                    242,
                    242,
                    248
                )

            Config.UI.Text =
                Color3.fromRGB(
                    30,
                    30,
                    40
                )

            Config.UI.SubText =
                Color3.fromRGB(
                    100,
                    100,
                    115
                )

        end

        Main.BackgroundColor3 =
            Config.UI.Background

        Body.BackgroundColor3 =
            Config.UI.Background

        Sidebar.BackgroundColor3 =
            Config.UI.Sidebar

        Content.BackgroundColor3 =
            Config.UI.Background

    end
)

Components:Section(
    SettingsPage,
    "UI Scale",
    "Adjust the interface size"
)

local ScaleHolder = Create(
    "Frame",
    {

        Parent = SettingsPage,

        Size = UDim2.new(
            1,
            0,
            0,
            52
        ),

        BackgroundColor3 =
            Config.UI.Card,

    }
)

Corner(ScaleHolder, 10)

local ScaleText = Create(
    "TextLabel",
    {

        Parent = ScaleHolder,

        Position = UDim2.new(
            0,
            14,
            0,
            0
        ),

        Size = UDim2.new(
            0,
            180,
            1,
            0
        ),

        BackgroundTransparency = 1,

        Text = "Scale: 100%",

        Font = Enum.Font.GothamMedium,

        TextSize = 11,

        TextColor3 =
            Config.UI.Text,

        TextXAlignment =
            Enum.TextXAlignment.Left,

    }
)

local MinusButton = Create(
    "TextButton",
    {

        Parent = ScaleHolder,

        Position = UDim2.new(
            1,
            -105,
            0.5,
            -15
        ),

        Size = UDim2.new(
            0,
            30,
            0,
            30
        ),

        BackgroundColor3 =
            Config.UI.Secondary,

        Text = "−",

        Font = Enum.Font.GothamBold,

        TextSize = 16,

        TextColor3 =
            Config.UI.Text,

        AutoButtonColor = false,

    }
)

Corner(MinusButton, 8)

local PlusButton = Create(
    "TextButton",
    {

        Parent = ScaleHolder,

        Position = UDim2.new(
            1,
            -45,
            0.5,
            -15
        ),

        Size = UDim2.new(
            0,
            30,
            0,
            30
        ),

        BackgroundColor3 =
            Config.UI.Secondary,

        Text = "+",

        Font = Enum.Font.GothamBold,

        TextSize = 16,

        TextColor3 =
            Config.UI.Text,

        AutoButtonColor = false,

    }
)

Corner(PlusButton, 8)

AddHoverEffect(
    MinusButton,
    1.08
)

AddHoverEffect(
    PlusButton,
    1.08
)

local function UpdateScale()

    Config.UI.Scale =
        math.clamp(
            Config.UI.Scale,
            0.8,
            1.2
        )

    ScaleText.Text =
        string.format(
            "Scale: %d%%",
            math.floor(
                Config.UI.Scale * 100
            )
        )

    Tween(
        MainScale,
        {
            Scale = Config.UI.Scale
        },
        0.3,
        Enum.EasingStyle.Quint
    )

end

Connect(
    MinusButton.MouseButton1Click,
    function()

        Config.UI.Scale =
            Config.UI.Scale - 0.05

        UpdateScale()

    end
)

Connect(
    PlusButton.MouseButton1Click,
    function()

        Config.UI.Scale =
            Config.UI.Scale + 0.05

        UpdateScale()

    end
)

Components:Section(
    SettingsPage,
    "Interface",
    "Restore the default UI configuration"
)

local ResetButton = Create(
    "TextButton",
    {

        Parent = SettingsPage,

        Size = UDim2.new(
            1,
            0,
            0,
            46
        ),

        BackgroundColor3 =
            Config.UI.Card,

        Text = "Reset Interface Settings",

        Font = Enum.Font.GothamMedium,

        TextSize = 11,

        TextColor3 =
            Config.UI.Text,

        AutoButtonColor = false,

    }
)

Corner(ResetButton, 10)

AddHoverEffect(
    ResetButton,
    1.015
)

Connect(
    ResetButton.MouseButton1Click,
    function()

        Config.UI.Scale = 1
        Config.UI.Animations = true
        Config.UI.Theme = "Dark"

        UpdateScale()

        NotificationService:Notify(
            "Settings",
            "Interface settings reset."
        )

    end
)

--==================================================
-- SIDEBAR BUTTONS
--==================================================

local PageNames = {

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

for _, pageName in ipairs(
    PageNames
) do

    local button = Create(
        "TextButton",
        {

            Parent = PageList,

            Size = UDim2.new(
                1,
                0,
                0,
                38
            ),

            BackgroundColor3 =
                Config.UI.Card,

            Text = pageName,

            Font = Enum.Font.GothamMedium,

            TextSize = 11,

            TextColor3 =
                Config.UI.Text,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            AutoButtonColor = false,

        }
    )

    Corner(button, 8)

    local buttonPadding =
        Instance.new("UIPadding")

    buttonPadding.PaddingLeft =
        UDim.new(0, 14)

    buttonPadding.Parent =
        button

    State.Buttons[pageName] = {

        Button = button,
        Name = pageName,

    }

    AddHoverEffect(
        button,
        1.025
    )

    Connect(
        button.MouseButton1Click,
        function()

            PageService:Show(
                pageName
            )

        end
    )

end

--==================================================
-- SEARCH
--==================================================

Connect(
    SearchBox:GetPropertyChangedSignal(
        "Text"
    ),
    function()

        State.SearchText =
            string.lower(
                SearchBox.Text
            )

        for pageName, data in pairs(
            State.Buttons
        ) do

            local visible =
                State.SearchText == ""
                or string.find(
                    string.lower(
                        pageName
                    ),
                    State.SearchText,
                    1,
                    true
                )

            data.Button.Visible =
                visible

        end

    end
)

--==================================================
-- CONTENT CANVAS
--==================================================

Connect(
    ContentLayout:GetPropertyChangedSignal(
        "AbsoluteContentSize"
    ),
    function()

        Content.CanvasSize =
            UDim2.new(
                0,
                0,
                0,
                ContentLayout
                    .AbsoluteContentSize.Y
                + 24
            )

    end
)

Connect(
    PageLayout:GetPropertyChangedSignal(
        "AbsoluteContentSize"
    ),
    function()

        PageList.CanvasSize =
            UDim2.new(
                0,
                0,
                0,
                PageLayout
                    .AbsoluteContentSize.Y
            )

    end
)

--==================================================
-- FLOATING MINIMIZE BUTTON
--==================================================

local FloatingButton = Create(
    "TextButton",
    {

        Parent = ScreenGui,

        AnchorPoint =
            Vector2.new(
                0.5,
                0.5
            ),

        Position = UDim2.new(
            0.5,
            0,
            0.5,
            0
        ),

        Size = UDim2.new(
            0,
            58,
            0,
            58
        ),

        BackgroundColor3 =
            Config.UI.Accent,

        Text = "F",

        Font = Enum.Font.GothamBold,

        TextSize = 21,

        TextColor3 =
            Color3.fromRGB(
                255,
                255,
                255
            ),

        Visible = false,

        AutoButtonColor = false,

    }
)

Corner(
    FloatingButton,
    29
)

local FloatingStroke =
    Stroke(
        FloatingButton,
        Color3.fromRGB(
            255,
            255,
            255
        ),
        0.8
    )

local FloatingScale =
    Instance.new("UIScale")

FloatingScale.Scale = 0.8
FloatingScale.Parent =
    FloatingButton

AddHoverEffect(
    FloatingButton,
    1.08
)

--==================================================
-- MINIMIZE / RESTORE
--==================================================

local function ShowFloatingButton()

    FloatingButton.Visible = true

    FloatingScale.Scale = 0.75

    Tween(
        FloatingScale,
        {
            Scale = 1
        },
        0.38,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )

end

local function HideFloatingButton()

    Tween(
        FloatingScale,
        {
            Scale = 0.75
        },
        0.22,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.In
    )

    task.delay(
        0.22,
        function()

            if not State.Minimized then
                return
            end

            FloatingButton.Visible = false

        end
    )

end

local function MinimizeHub()

    if State.Minimized then
        return
    end

    State.Minimized = true

    Tween(
        MainScale,
        {
            Scale = 0.92
        },
        0.25,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.In
    )

    task.delay(
        0.24,
        function()

            if not State.Minimized then
                return
            end

            Main.Visible = false

            ShowFloatingButton()

        end
    )

end

local function RestoreHub()

    if not State.Minimized then
        return
    end

    State.Minimized = false

    FloatingButton.Visible = false

    Main.Visible = true

    MainScale.Scale = 0.92

    Tween(
        MainScale,
        {
            Scale = Config.UI.Scale
        },
        0.42,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )

end

--==================================================
-- FLOATING BUTTON DRAG
--==================================================

local dragging = false
local dragStart
local startPosition
local moved = false

Connect(
    FloatingButton.InputBegan,
    function(input)

        if
            input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
            Enum.UserInputType.Touch
        then

            dragging = true
            moved = false

            dragStart =
                input.Position

            startPosition =
                FloatingButton.Position

        end

    end
)

Connect(
    UserInputService.InputChanged,
    function(input)

        if not dragging then
            return
        end

        if
            input.UserInputType ~=
            Enum.UserInputType.MouseMovement
            and
            input.UserInputType ~=
            Enum.UserInputType.Touch
        then
            return
        end

        local delta =
            input.Position
            - dragStart

        if delta.Magnitude > 5 then
            moved = true
        end

        FloatingButton.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset
                    + delta.X,

                startPosition.Y.Scale,
                startPosition.Y.Offset
                    + delta.Y
            )

    end
)

Connect(
    UserInputService.InputEnded,
    function(input)

        if
            input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
            Enum.UserInputType.Touch
        then

            if dragging and not moved then
                RestoreHub()
            end

            dragging = false

        end

    end
)

--==================================================
-- MINIMIZE BUTTON
--==================================================

Connect(
    MinimizeButton.MouseButton1Click,
    function()

        MinimizeHub()

    end
)

--==================================================
-- CLOSE
--==================================================

Connect(
    CloseButton.MouseButton1Click,
    function()

        Cleanup()

        Tween(
            MainScale,
            {
                Scale = 0.9
            },
            0.2,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.In
        )

        task.wait(0.2)

        if ScreenGui then
            ScreenGui:Destroy()
        end

    end
)

--==================================================
-- MAIN WINDOW DRAG
--==================================================

local MainDragging = false
local MainDragStart
local MainStartPosition

Connect(
    Topbar.InputBegan,
    function(input)

        if
            input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            MainDragging = true

            MainDragStart =
                input.Position

            MainStartPosition =
                Main.Position

        end

    end
)

Connect(
    UserInputService.InputChanged,
    function(input)

        if not MainDragging then
            return
        end

        if
            input.UserInputType ~=
            Enum.UserInputType.MouseMovement
        then
            return
        end

        local delta =
            input.Position
            - MainDragStart

        Main.Position =
            UDim2.new(
                MainStartPosition.X.Scale,
                MainStartPosition.X.Offset
                    + delta.X,

                MainStartPosition.Y.Scale,
                MainStartPosition.Y.Offset
                    + delta.Y
            )

    end
)

Connect(
    UserInputService.InputEnded,
    function(input)

        if
            input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            MainDragging = false

        end

    end
)

--==================================================
-- FPS TRACKING
--==================================================

local frameCount = 0
local lastFPSUpdate = os.clock()

Connect(
    RunService.RenderStepped,
    function()

        frameCount += 1

        local now = os.clock()

        if now - lastFPSUpdate >= 1 then

            State.FPS =
                frameCount

            frameCount = 0

            lastFPSUpdate = now

        end

    end
)

--==================================================
-- LIVE DATA UPDATE
--==================================================

local lastUpdate = 0

Connect(
    RunService.Heartbeat,
    function()

        if State.Destroyed then
            return
        end

        local now = os.clock()

        if
            now - lastUpdate
            < Config.Performance.UpdateInterval
        then
            return
        end

        lastUpdate = now

        local level =
            PlayerService:GetLevel()

        local beli =
            PlayerService:GetBeli()

        local fragments =
            PlayerService:GetFragments()

        local race =
            PlayerService:GetRace()

        local sea =
            WorldService:GetSea()

        local ping =
            PerformanceService:GetPing()

        local uptime =
            FormatTime(
                now - StartTime
            )

        -- HOME CARDS

        if State.Cards["LEVEL"] then

            State.Cards["LEVEL"]
                .Value.Text =
                FormatNumber(level)

        end

        if State.Cards["BELI"] then

            State.Cards["BELI"]
                .Value.Text =
                FormatNumber(beli)

        end

        if State.Cards["FRAGMENTS"] then

            State.Cards["FRAGMENTS"]
                .Value.Text =
                FormatNumber(fragments)

        end

        if State.Cards["RACE"] then

            State.Cards["RACE"]
                .Value.Text =
                tostring(race)

        end

        if State.Cards["SEA"] then

            State.Cards["SEA"]
                .Value.Text =
                tostring(sea)

        end

        if State.Cards["FPS"] then

            State.Cards["FPS"]
                .Value.Text =
                tostring(State.FPS)

        end

        if State.Cards["PING"] then

            State.Cards["PING"]
                .Value.Text =
                tostring(ping) .. " ms"

        end

        if State.Cards["UPTIME"] then

            State.Cards["UPTIME"]
                .Value.Text =
                uptime

        end

        -- PLAYER PAGE

        local health,
            maxHealth =
            PlayerService:GetHealth()

        PlayerInfoText.Text =
            "Player: "
            .. LocalPlayer.DisplayName
            .. "\n\n"

            .. "Username: "
            .. LocalPlayer.Name
            .. "\n"

            .. "Level: "
            .. tostring(level)
            .. "\n"

            .. "Race: "
            .. tostring(race)
            .. "\n"

            .. "Health: "
            .. string.format(
                "%.0f / %.0f",
                health,
                maxHealth
            )
            .. "\n"

            .. "Sea: "
            .. tostring(sea)

        -- STATUS

        StatusSub.Text =
            "FPS "
            .. tostring(State.FPS)
            .. "  •  Ping "
            .. tostring(ping)
            .. " ms  •  Uptime "
            .. uptime

    end
)

--==================================================
-- INITIAL PAGE
--==================================================

PageService:Show("Home")

--==================================================
-- INITIAL NOTIFICATION
--==================================================

task.delay(
    0.55,
    function()

        NotificationService:Notify(
            "Floquitave",
            "Version "
                .. Config.Version
                .. " loaded successfully."
        )

    end
)

print(
    "[Floquitave] Version "
        .. Config.Version
        .. " loaded."
)
