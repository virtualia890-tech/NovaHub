--[[
    FLOQUITAVE
    Version: 2.5.1
    UI / Core Test Build

    Included:
    - Home dashboard
    - Sea accordion teleport browser
    - Teleport search
    - Teleport categories
    - Selected destination
    - Player WalkSpeed / JumpPower
    - Server information
    - Job ID copy
    - Themes
    - UI scale
    - Quick Actions
    - FPS / Ping / Uptime
    - Minimize circle
    - Smooth animations
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--//==================================================
--// CONFIG
--//==================================================

local Config = {
    Name = "Floquitave",
    Version = "2.5.1",

    UIWidth = 920,
    UIHeight = 590,

    Animations = true,
    Notifications = true,

    Theme = "Dark",
    Scale = 1
}

--//==================================================
--// STATE
--//==================================================

local State = {
    CurrentPage = "Home",
    Minimized = false,
    Destroyed = false,

    SearchText = "",

    FPS = 0,
    Ping = 0,

    SessionStart = os.clock(),

    SelectedDestination = "None",

    TeleportFilter = "All",

    SeaOpen = {
        ["First Sea"] = false,
        ["Second Sea"] = false,
        ["Third Sea"] = false
    },

    PlayerSettings = {
        WalkSpeed = 16,
        JumpPower = 50
    }
}

--//==================================================
--// CONNECTIONS
--//==================================================

local Connections = {}

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function Cleanup()
    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    Connections = {}
end

--//==================================================
--// THEMES
--//==================================================

local Themes = {
    Dark = {
        Background = Color3.fromRGB(15, 16, 22),
        Sidebar = Color3.fromRGB(19, 20, 28),
        Topbar = Color3.fromRGB(20, 21, 30),
        Card = Color3.fromRGB(24, 25, 34),
        Card2 = Color3.fromRGB(28, 29, 40),

        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(155, 157, 170),

        Stroke = Color3.fromRGB(45, 46, 58),
        Accent = Color3.fromRGB(115, 90, 255),

        Button = Color3.fromRGB(31, 32, 44),
        ButtonHover = Color3.fromRGB(39, 40, 54)
    },

    Light = {
        Background = Color3.fromRGB(238, 239, 244),
        Sidebar = Color3.fromRGB(248, 248, 251),
        Topbar = Color3.fromRGB(250, 250, 252),
        Card = Color3.fromRGB(255, 255, 255),
        Card2 = Color3.fromRGB(245, 246, 250),

        Text = Color3.fromRGB(30, 31, 38),
        SubText = Color3.fromRGB(100, 102, 112),

        Stroke = Color3.fromRGB(215, 216, 224),
        Accent = Color3.fromRGB(95, 75, 220),

        Button = Color3.fromRGB(230, 231, 237),
        ButtonHover = Color3.fromRGB(220, 221, 230)
    },

    Purple = {
        Background = Color3.fromRGB(17, 13, 24),
        Sidebar = Color3.fromRGB(24, 17, 34),
        Topbar = Color3.fromRGB(27, 19, 38),
        Card = Color3.fromRGB(34, 23, 47),
        Card2 = Color3.fromRGB(41, 28, 56),

        Text = Color3.fromRGB(245, 240, 250),
        SubText = Color3.fromRGB(170, 150, 185),

        Stroke = Color3.fromRGB(64, 42, 78),
        Accent = Color3.fromRGB(180, 80, 255),

        Button = Color3.fromRGB(43, 28, 57),
        ButtonHover = Color3.fromRGB(55, 36, 72)
    },

    Blue = {
        Background = Color3.fromRGB(11, 17, 25),
        Sidebar = Color3.fromRGB(14, 23, 34),
        Topbar = Color3.fromRGB(16, 27, 40),
        Card = Color3.fromRGB(20, 33, 48),
        Card2 = Color3.fromRGB(25, 41, 59),

        Text = Color3.fromRGB(235, 245, 255),
        SubText = Color3.fromRGB(145, 170, 195),

        Stroke = Color3.fromRGB(39, 64, 88),
        Accent = Color3.fromRGB(70, 150, 255),

        Button = Color3.fromRGB(24, 42, 61),
        ButtonHover = Color3.fromRGB(31, 54, 77)
    },

    Red = {
        Background = Color3.fromRGB(22, 13, 14),
        Sidebar = Color3.fromRGB(31, 16, 18),
        Topbar = Color3.fromRGB(34, 18, 20),
        Card = Color3.fromRGB(44, 23, 26),
        Card2 = Color3.fromRGB(54, 27, 31),

        Text = Color3.fromRGB(250, 238, 239),
        SubText = Color3.fromRGB(190, 150, 153),

        Stroke = Color3.fromRGB(78, 39, 43),
        Accent = Color3.fromRGB(240, 70, 85),

        Button = Color3.fromRGB(54, 27, 31),
        ButtonHover = Color3.fromRGB(70, 33, 38)
    },

    Green = {
        Background = Color3.fromRGB(12, 20, 16),
        Sidebar = Color3.fromRGB(16, 28, 21),
        Topbar = Color3.fromRGB(18, 32, 24),
        Card = Color3.fromRGB(23, 42, 30),
        Card2 = Color3.fromRGB(28, 52, 36),

        Text = Color3.fromRGB(235, 248, 239),
        SubText = Color3.fromRGB(145, 180, 155),

        Stroke = Color3.fromRGB(39, 70, 48),
        Accent = Color3.fromRGB(65, 205, 120),

        Button = Color3.fromRGB(27, 52, 36),
        ButtonHover = Color3.fromRGB(35, 67, 45)
    },

    Cyan = {
        Background = Color3.fromRGB(10, 19, 21),
        Sidebar = Color3.fromRGB(13, 28, 31),
        Topbar = Color3.fromRGB(15, 33, 37),
        Card = Color3.fromRGB(19, 42, 46),
        Card2 = Color3.fromRGB(24, 52, 57),

        Text = Color3.fromRGB(232, 250, 250),
        SubText = Color3.fromRGB(145, 180, 182),

        Stroke = Color3.fromRGB(36, 72, 77),
        Accent = Color3.fromRGB(45, 210, 220),

        Button = Color3.fromRGB(22, 49, 53),
        ButtonHover = Color3.fromRGB(28, 63, 67)
    },

    Midnight = {
        Background = Color3.fromRGB(8, 10, 18),
        Sidebar = Color3.fromRGB(11, 14, 25),
        Topbar = Color3.fromRGB(13, 16, 29),
        Card = Color3.fromRGB(17, 21, 37),
        Card2 = Color3.fromRGB(21, 26, 45),

        Text = Color3.fromRGB(235, 238, 250),
        SubText = Color3.fromRGB(135, 145, 170),

        Stroke = Color3.fromRGB(32, 40, 65),
        Accent = Color3.fromRGB(90, 120, 255),

        Button = Color3.fromRGB(20, 26, 45),
        ButtonHover = Color3.fromRGB(28, 36, 62)
    }
}

local Theme = Themes[Config.Theme]

--//==================================================
--// WORLD DATA
--//==================================================

local WorldService = {}

WorldService.Seas = {
    ["First Sea"] = {
        PlaceId = 2753915549
    },

    ["Second Sea"] = {
        PlaceId = 4442272183
    },

    ["Third Sea"] = {
        PlaceId = 7449423635
    }
}

function WorldService:GetSea()
    local placeId = game.PlaceId

    for seaName, data in pairs(self.Seas) do
        if data.PlaceId == placeId then
            return seaName
        end
    end

    return "Unknown"
end

--//==================================================
--// TELEPORT DATA
--//==================================================

local TeleportLocations = {

    ["First Sea"] = {
        {Name = "Bandit Island", Category = "Island"},
        {Name = "Jungle", Category = "Island"},
        {Name = "Pirate Village", Category = "Island"},
        {Name = "Desert", Category = "Island"},
        {Name = "Frozen Village", Category = "Island"},
        {Name = "Marine Fortress", Category = "Island"},
        {Name = "Skylands", Category = "Island"},
        {Name = "Prison", Category = "Special"},
        {Name = "Colosseum", Category = "Island"},
        {Name = "Magma Village", Category = "Island"},
        {Name = "Underwater City", Category = "Island"},
        {Name = "Fountain City", Category = "Island"},

        {Name = "Middle Town", Category = "Special"},
        {Name = "Upper Skylands", Category = "Special"},
        {Name = "Lower Skylands", Category = "Special"},
        {Name = "Marine Starter", Category = "Special"}
    },

    ["Second Sea"] = {
        {Name = "Kingdom of Rose", Category = "Island"},
        {Name = "Green Zone", Category = "Island"},
        {Name = "Graveyard", Category = "Island"},
        {Name = "Snow Mountain", Category = "Island"},
        {Name = "Hot and Cold", Category = "Island"},
        {Name = "Cursed Ship", Category = "Special"},
        {Name = "Ice Castle", Category = "Island"},
        {Name = "Forgotten Island", Category = "Island"},

        {Name = "Cafe", Category = "Special"},
        {Name = "Dark Arena", Category = "Special"},
        {Name = "Factory", Category = "Special"},
        {Name = "Mansion", Category = "Special"}
    },

    ["Third Sea"] = {
        {Name = "Port Town", Category = "Island"},
        {Name = "Hydra Island", Category = "Island"},
        {Name = "Great Tree", Category = "Island"},
        {Name = "Floating Turtle", Category = "Island"},
        {Name = "Haunted Castle", Category = "Island"},
        {Name = "Sea of Treats", Category = "Island"},
        {Name = "Tiki Outpost", Category = "Island"},
        {Name = "Chocolate Land", Category = "Island"},
        {Name = "Cake Land", Category = "Island"},
        {Name = "Peanut Island", Category = "Island"},
        {Name = "Ice Cream Island", Category = "Island"},

        {Name = "Castle on the Sea", Category = "Special"},
        {Name = "Beautiful Pirate Domain", Category = "Special"},
        {Name = "Floating Turtle Mansion", Category = "Special"}
    }
}

local TeleportCategories = {
    "All",
    "Island",
    "Special"
}

--//==================================================
--// PLAYER SERVICE
--//==================================================

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
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local level = leaderstats:FindFirstChild("Level")

        if level then
            return level.Value
        end
    end

    return 0
end

function PlayerService:GetBeli()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local beli = leaderstats:FindFirstChild("Beli")

        if beli then
            return beli.Value
        end
    end

    return 0
end

function PlayerService:GetFragments()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local fragments = leaderstats:FindFirstChild("Fragments")

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
            return tostring(race.Value)
        end
    end

    return "Unknown"
end

function PlayerService:GetWalkSpeed()
    local humanoid = self:GetHumanoid()

    return humanoid and humanoid.WalkSpeed or 16
end

function PlayerService:GetJumpPower()
    local humanoid = self:GetHumanoid()

    return humanoid and humanoid.JumpPower or 50
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

--//==================================================
--// PERFORMANCE SERVICE
--//==================================================

local PerformanceService = {}

function PerformanceService:GetPing()
    local success, result = pcall(function()
        return math.floor(
            Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        )
    end)

    if success then
        return result
    end

    return 0
end

--//==================================================
--// SERVER SERVICE
--//==================================================

local ServerService = {}

function ServerService:GetJobId()
    return game.JobId
end

function ServerService:GetPlaceId()
    return game.PlaceId
end

function ServerService:GetPlayers()
    return #Players:GetPlayers()
end

--//==================================================
--// NOTIFICATION
--//==================================================

local function Notify(title, message)
    if not Config.Notifications then
        return
    end

    pcall(function()
        game:GetService("StarterGui"):SetCore(
            "SendNotification",
            {
                Title = title,
                Text = message,
                Duration = 3
            }
        )
    end)
end

--//==================================================
--// GUI
--//==================================================

local ExistingGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Floquitave")

if ExistingGui then
    ExistingGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Floquitave"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--//==================================================
--// HELPERS
--//==================================================

local function Create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function Corner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function Stroke(parent, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Stroke
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local function Padding(parent, left, right, top, bottom)
    local padding = Instance.new("UIPadding")

    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)

    padding.Parent = parent

    return padding
end

local function Tween(object, properties, duration)
    if not Config.Animations then
        for property, value in pairs(properties) do
            object[property] = value
        end

        return
    end

    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.18,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()

    return tween
end

local function FormatNumber(number)
    local formatted = tostring(number)

    while true do
        local changed

        formatted, changed = formatted:gsub(
            "^(-?%d+)(%d%d%d)",
            "%1,%2"
        )

        if changed == 0 then
            break
        end
    end

    return formatted
end

local function FormatUptime()
    local seconds = math.floor(os.clock() - State.SessionStart)

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

--//==================================================
--// MAIN WINDOW
--//==================================================

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(Config.UIWidth, Config.UIHeight),
    Position = UDim2.new(0.5, -Config.UIWidth / 2, 0.5, -Config.UIHeight / 2),

    BackgroundColor3 = Theme.Background,

    BorderSizePixel = 0,
    ClipsDescendants = true
}, ScreenGui)

Corner(Main, 12)
Stroke(Main)

--//==================================================
--// TOPBAR
--//==================================================

local Topbar = Create("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = Theme.Topbar,
    BorderSizePixel = 0
}, Main)

local Logo = Create("TextLabel", {
    Size = UDim2.fromOffset(220, 56),
    Position = UDim2.fromOffset(20, 0),

    BackgroundTransparency = 1,

    Text = "FLOQUITAVE",
    TextColor3 = Theme.Text,
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local Version = Create("TextLabel", {
    Size = UDim2.fromOffset(100, 56),
    Position = UDim2.fromOffset(155, 0),

    BackgroundTransparency = 1,

    Text = "2.5.1",
    TextColor3 = Theme.SubText,
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, Topbar)

local Minimize = Create("TextButton", {
    Size = UDim2.fromOffset(42, 32),
    Position = UDim2.new(1, -94, 0, 12),

    BackgroundColor3 = Theme.Button,

    Text = "—",
    TextColor3 = Theme.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,

    AutoButtonColor = false
}, Topbar)

Corner(Minimize, 8)

local Close = Create("TextButton", {
    Size = UDim2.fromOffset(42, 32),
    Position = UDim2.new(1, -48, 0, 12),

    BackgroundColor3 = Theme.Button,

    Text = "×",
    TextColor3 = Theme.Text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,

    AutoButtonColor = false
}, Topbar)

Corner(Close, 8)

--//==================================================
--// SIDEBAR
--//==================================================

local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 190, 1, -56),

    Position = UDim2.fromOffset(0, 56),

    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0
}, Main)

local SidebarTitle = Create("TextLabel", {
    Size = UDim2.new(1, -28, 0, 30),
    Position = UDim2.fromOffset(14, 14),

    BackgroundTransparency = 1,

    Text = "NAVIGATION",
    TextColor3 = Theme.SubText,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Sidebar)

local PageList = Create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -58),
    Position = UDim2.fromOffset(10, 50),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,

    CanvasSize = UDim2.new(0, 0, 0, 0),

    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Sidebar)

Create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, PageList)

--//==================================================
--// CONTENT
--//==================================================

local Content = Create("Frame", {
    Name = "Content",

    Size = UDim2.new(1, -190, 1, -56),
    Position = UDim2.fromOffset(190, 56),

    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,

    ClipsDescendants = true
}, Main)

local SearchBox = Create("TextBox", {
    Size = UDim2.fromOffset(240, 34),
    Position = UDim2.new(1, -255, 0, 11),

    BackgroundColor3 = Theme.Card,

    PlaceholderText = "Search...",
    PlaceholderColor3 = Theme.SubText,

    Text = "",
    TextColor3 = Theme.Text,

    TextSize = 12,
    Font = Enum.Font.GothamMedium,

    ClearTextOnFocus = false,

    BorderSizePixel = 0
}, Topbar)

Corner(SearchBox, 8)
Stroke(SearchBox)

local Pages = {}
local PageButtons = {}

--//==================================================
--// PAGE SERVICE
--//==================================================

local PageService = {}

function PageService:CreatePage(name)
    local page = Create("ScrollingFrame", {
        Name = name,

        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromOffset(12, 12),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,

        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        Visible = false
    }, Content)

    Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    Pages[name] = page

    return page
end

function PageService:Show(name)
    if not Pages[name] then
        return
    end

    State.CurrentPage = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for pageName, button in pairs(PageButtons) do
        if pageName == name then
            button.BackgroundColor3 = Theme.Accent
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = Theme.Button
            button.TextColor3 = Theme.SubText
        end
    end

    SearchBox.Text = ""
    State.SearchText = ""

    if name == "Teleport" then
        task.defer(function()
            BuildTeleport()
        end)
    end
end

--//==================================================
--// SIDEBAR BUTTON
--//==================================================

local PageOrder = {
    "Home",
    "Main Farm",
    "Quest",
    "Raids",
    "Combat",
    "Teleport",
    "Player",
    "Server",
    "Misc",
    "Settings",
    "About"
}

for index, pageName in ipairs(PageOrder) do
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),

        BackgroundColor3 = Theme.Button,

        Text = "  " .. pageName,
        TextColor3 = Theme.SubText,

        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left,

        AutoButtonColor = false,

        LayoutOrder = index
    }, PageList)

    Corner(button, 8)

    PageButtons[pageName] = button

    Connect(button.MouseButton1Click, function()
        PageService:Show(pageName)
    end)
end

--//==================================================
--// COMPONENTS
--//==================================================

local function Section(parent, title, subtitle)
    local section = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, parent)

    Corner(section, 10)
    Stroke(section)

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 24),
        Position = UDim2.fromOffset(14, 9),

        BackgroundTransparency = 1,

        Text = title,
        TextColor3 = Theme.Text,

        TextSize = 14,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, section)

    local subtitleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.fromOffset(14, 32),

        BackgroundTransparency = 1,

        Text = subtitle or "",
        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, section)

    return section
end

local function Card(parent, title, value)
    local card = Create("Frame", {
        Size = UDim2.new(0.5, -6, 0, 82),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, parent)

    Corner(card, 10)
    Stroke(card)

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.fromOffset(12, 10),

        BackgroundTransparency = 1,

        Text = title,
        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    local valueLabel = Create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 32),
        Position = UDim2.fromOffset(12, 32),

        BackgroundTransparency = 1,

        Text = tostring(value),

        TextColor3 = Theme.Text,

        TextSize = 17,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    return card, valueLabel
end

local function ActionButton(parent, text, callback)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),

        BackgroundColor3 = Theme.Button,

        Text = text,

        TextColor3 = Theme.Text,

        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        AutoButtonColor = false
    }, parent)

    Corner(button, 8)
    Stroke(button)

    Connect(button.MouseEnter, function()
        Tween(button, {
            BackgroundColor3 = Theme.ButtonHover
        }, 0.12)
    end)

    Connect(button.MouseLeave, function()
        Tween(button, {
            BackgroundColor3 = Theme.Button
        }, 0.12)
    end)

    Connect(button.MouseButton1Click, function()
        if callback then
            callback()
        end
    end)

    return button
end

local function ValueBox(parent, title, defaultValue)
    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, parent)

    Corner(holder, 8)
    Stroke(holder)

    local label = Create("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.fromOffset(12, 0),

        BackgroundTransparency = 1,

        Text = title,
        TextColor3 = Theme.Text,

        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local box = Create("TextBox", {
        Size = UDim2.new(0.42, 0, 0, 34),
        Position = UDim2.new(0.55, 0, 0, 10),

        BackgroundColor3 = Theme.Button,

        Text = tostring(defaultValue),

        TextColor3 = Theme.Text,

        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        ClearTextOnFocus = false,

        BorderSizePixel = 0
    }, holder)

    Corner(box, 7)

    return holder, box
end

local function Toggle(parent, title, description, defaultValue, callback)
    local state = defaultValue or false

    local holder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 58),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, parent)

    Corner(holder, 8)
    Stroke(holder)

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(12, 8),

        BackgroundTransparency = 1,

        Text = title,
        TextColor3 = Theme.Text,

        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local descLabel = Create("TextLabel", {
        Size = UDim2.new(1, -80, 0, 17),
        Position = UDim2.fromOffset(12, 29),

        BackgroundTransparency = 1,

        Text = description or "",
        TextColor3 = Theme.SubText,

        TextSize = 10,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local button = Create("TextButton", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -56, 0.5, -12),

        BackgroundColor3 = Theme.Button,

        Text = "",

        AutoButtonColor = false
    }, holder)

    Corner(button, 12)

    local dot = Create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(3, 3),

        BackgroundColor3 = Theme.SubText,

        BorderSizePixel = 0
    }, button)

    Corner(dot, 10)

    local function Render()
        if state then
            button.BackgroundColor3 = Theme.Accent
            dot.Position = UDim2.new(1, -21, 0, 3)
            dot.BackgroundColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = Theme.Button
            dot.Position = UDim2.fromOffset(3, 3)
            dot.BackgroundColor3 = Theme.SubText
        end
    end

    Render()

    Connect(button.MouseButton1Click, function()
        state = not state
        Render()

        if callback then
            callback(state)
        end
    end)

    return holder
end

--//==================================================
--// CREATE PAGES
--//==================================================

for _, pageName in ipairs(PageOrder) do
    PageService:CreatePage(pageName)
end

--//==================================================
--// HOME
--//==================================================

do
    local page = Pages["Home"]

    Section(
        page,
        "Welcome to Floquitave",
        "2.5.1 • Modular UI / Test Build"
    )

    local grid = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 180),

        BackgroundTransparency = 1
    }, page)

    local gridLayout = Create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 82),
        CellPadding = UDim2.fromOffset(12, 12)
    }, grid)

    local _, LevelValue = Card(grid, "LEVEL", "0")
    local _, BeliValue = Card(grid, "BELI", "0")
    local _, FragmentsValue = Card(grid, "FRAGMENTS", "0")
    local _, RaceValue = Card(grid, "RACE", "Unknown")

    local _, SeaValue = Card(grid, "SEA", "Unknown")
    local _, FPSValue = Card(grid, "FPS", "0")
    local _, PingValue = Card(grid, "PING", "0 ms")
    local _, UptimeValue = Card(grid, "UPTIME", "00:00:00")

    local status = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 66),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, page)

    Corner(status, 10)
    Stroke(status)

    local statusTitle = Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 22),
        Position = UDim2.fromOffset(14, 10),

        BackgroundTransparency = 1,

        Text = "SESSION STATUS",
        TextColor3 = Theme.Text,

        TextSize = 12,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, status)

    local statusText = Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.fromOffset(14, 32),

        BackgroundTransparency = 1,

        Text = "Floquitave is running locally.",
        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, status)

    Connect(RunService.RenderStepped, function(delta)
        if State.Destroyed then
            return
        end

        if delta > 0 then
            State.FPS = math.floor(1 / delta)
        end

        State.Ping = PerformanceService:GetPing()

        LevelValue.Text = FormatNumber(PlayerService:GetLevel())
        BeliValue.Text = FormatNumber(PlayerService:GetBeli())
        FragmentsValue.Text = FormatNumber(PlayerService:GetFragments())
        RaceValue.Text = PlayerService:GetRace()

        SeaValue.Text = WorldService:GetSea()
        FPSValue.Text = tostring(State.FPS)
        PingValue.Text = tostring(State.Ping) .. " ms"
        UptimeValue.Text = FormatUptime()
    end)
end

--//==================================================
--// PLAYER
--//==================================================

do
    local page = Pages["Player"]

    Section(
        page,
        "Player",
        "Local character settings"
    )

    local info = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 90),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, page)

    Corner(info, 10)
    Stroke(info)

    Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 22),
        Position = UDim2.fromOffset(14, 10),

        BackgroundTransparency = 1,

        Text = "@" .. LocalPlayer.Name,
        TextColor3 = Theme.Text,

        TextSize = 14,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, info)

    Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.fromOffset(14, 34),

        BackgroundTransparency = 1,

        Text = "Display: " .. LocalPlayer.DisplayName,
        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, info)

    Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.fromOffset(14, 56),

        BackgroundTransparency = 1,

        Text = "UserId: " .. tostring(LocalPlayer.UserId),
        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, info)

    local settings = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 124),

        BackgroundTransparency = 1
    }, page)

    Create("UIListLayout", {
        Padding = UDim.new(0, 8)
    }, settings)

    local _, WalkBox = ValueBox(
        settings,
        "WalkSpeed",
        State.PlayerSettings.WalkSpeed
    )

    local _, JumpBox = ValueBox(
        settings,
        "JumpPower",
        State.PlayerSettings.JumpPower
    )

    ActionButton(page, "Apply Player Settings", function()
        local speed = tonumber(WalkBox.Text)
        local jump = tonumber(JumpBox.Text)

        if speed then
            PlayerService:SetWalkSpeed(speed)
        end

        if jump then
            PlayerService:SetJumpPower(jump)
        end

        Notify(
            Config.Name,
            "Player settings applied."
        )
    end)

    ActionButton(page, "Reset Player Settings", function()
        WalkBox.Text = "16"
        JumpBox.Text = "50"

        PlayerService:SetWalkSpeed(16)
        PlayerService:SetJumpPower(50)

        Notify(
            Config.Name,
            "Player settings reset."
        )
    end)
end

--//==================================================
--// TELEPORT PAGE
--//==================================================

local TeleportContainer
local TeleportSearch
local SelectedLabel
local CategoryButtons = {}
local TeleportRefreshToken = 0

function BuildTeleport()
    TeleportRefreshToken += 1

    local myToken = TeleportRefreshToken

    if TeleportContainer then
        TeleportContainer:Destroy()
    end

    local page = Pages["Teleport"]

    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, page)

    Corner(header, 10)
    Stroke(header)

    Create("TextLabel", {
        Size = UDim2.new(0.5, -20, 0, 24),
        Position = UDim2.fromOffset(14, 10),

        BackgroundTransparency = 1,

        Text = "Teleport Browser",
        TextColor3 = Theme.Text,

        TextSize = 15,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, header)

    Create("TextLabel", {
        Size = UDim2.new(0.5, -20, 0, 20),
        Position = UDim2.fromOffset(14, 36),

        BackgroundTransparency = 1,

        Text = "Select a Sea to display its locations.",
        TextColor3 = Theme.SubText,

        TextSize = 10,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left
    }, header)

    SelectedLabel = Create("TextLabel", {
        Size = UDim2.new(0.5, -28, 0, 20),
        Position = UDim2.new(0.5, 0, 0, 28),

        BackgroundTransparency = 1,

        Text = "Selected: " .. State.SelectedDestination,
        TextColor3 = Theme.Accent,

        TextSize = 11,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Right
    }, header)

    local filterFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),

        BackgroundTransparency = 1
    }, page)

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 7)
    }, filterFrame)

    CategoryButtons = {}

    for _, category in ipairs(TeleportCategories) do
        local button = Create("TextButton", {
            Size = UDim2.fromOffset(90, 34),

            BackgroundColor3 =
                State.TeleportFilter == category
                and Theme.Accent
                or Theme.Button,

            Text = category,

            TextColor3 =
                State.TeleportFilter == category
                and Color3.new(1, 1, 1)
                or Theme.SubText,

            TextSize = 11,
            Font = Enum.Font.GothamMedium,

            AutoButtonColor = false
        }, filterFrame)

        Corner(button, 7)

        CategoryButtons[category] = button

        Connect(button.MouseButton1Click, function()
            State.TeleportFilter = category
            BuildTeleport()
        end)
    end

    TeleportContainer = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),

        BackgroundTransparency = 1,

        AutomaticSize = Enum.AutomaticSize.Y
    }, page)

    Create("UIListLayout", {
        Padding = UDim.new(0, 8)
    }, TeleportContainer)

    local currentSearch = State.SearchText:lower()

    for _, seaName in ipairs({"First Sea", "Second Sea", "Third Sea"}) do

        local seaData = TeleportLocations[seaName]

        local visibleLocations = {}

        for _, location in ipairs(seaData) do
            local categoryMatch =
                State.TeleportFilter == "All"
                or location.Category == State.TeleportFilter

            local searchMatch =
                currentSearch == ""
                or location.Name:lower():find(currentSearch, 1, true)

            if categoryMatch and searchMatch then
                table.insert(visibleLocations, location)
            end
        end

        local seaButton = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 44),

            BackgroundColor3 = Theme.Card,

            Text = "",

            AutoButtonColor = false
        }, TeleportContainer)

        Corner(seaButton, 8)
        Stroke(seaButton)

        local arrow = State.SeaOpen[seaName] and "▼" or "▶"

        Create("TextLabel", {
            Size = UDim2.fromOffset(30, 44),
            Position = UDim2.fromOffset(12, 0),

            BackgroundTransparency = 1,

            Text = arrow,

            TextColor3 = Theme.Accent,

            TextSize = 12,
            Font = Enum.Font.GothamBold
        }, seaButton)

        Create("TextLabel", {
            Size = UDim2.new(1, -60, 0, 44),
            Position = UDim2.fromOffset(42, 0),

            BackgroundTransparency = 1,

            Text = seaName,

            TextColor3 = Theme.Text,

            TextSize = 12,
            Font = Enum.Font.GothamBold,

            TextXAlignment = Enum.TextXAlignment.Left
        }, seaButton)

        Create("TextLabel", {
            Size = UDim2.fromOffset(100, 44),
            Position = UDim2.new(1, -115, 0, 0),

            BackgroundTransparency = 1,

            Text = #visibleLocations .. " locations",

            TextColor3 = Theme.SubText,

            TextSize = 10,
            Font = Enum.Font.GothamMedium,

            TextXAlignment = Enum.TextXAlignment.Right
        }, seaButton)

        Connect(seaButton.MouseButton1Click, function()
            State.SeaOpen[seaName] = not State.SeaOpen[seaName]
            BuildTeleport()
        end)

        if State.SeaOpen[seaName] then

            for _, location in ipairs(visibleLocations) do

                local locationButton = Create("TextButton", {
                    Size = UDim2.new(1, -20, 0, 38),

                    BackgroundColor3 = Theme.Button,

                    Text = "    " .. location.Name,

                    TextColor3 = Theme.Text,

                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,

                    TextXAlignment = Enum.TextXAlignment.Left,

                    AutoButtonColor = false
                }, TeleportContainer)

                Corner(locationButton, 7)
                Stroke(locationButton)

                local categoryLabel = Create("TextLabel", {
                    Size = UDim2.fromOffset(90, 38),
                    Position = UDim2.new(1, -105, 0, 0),

                    BackgroundTransparency = 1,

                    Text = location.Category,

                    TextColor3 = Theme.SubText,

                    TextSize = 9,
                    Font = Enum.Font.GothamMedium,

                    TextXAlignment = Enum.TextXAlignment.Right
                }, locationButton)

                Connect(locationButton.MouseEnter, function()
                    Tween(locationButton, {
                        BackgroundColor3 = Theme.ButtonHover
                    }, 0.1)
                end)

                Connect(locationButton.MouseLeave, function()
                    Tween(locationButton, {
                        BackgroundColor3 = Theme.Button
                    }, 0.1)
                end)

                Connect(locationButton.MouseButton1Click, function()
                    State.SelectedDestination =
                        seaName .. " • " .. location.Name

                    if SelectedLabel then
                        SelectedLabel.Text =
                            "Selected: " .. State.SelectedDestination
                    end

                    Notify(
                        "Floquitave",
                        "Selected: " .. location.Name
                    )
                end)
            end
        end

        if myToken ~= TeleportRefreshToken then
            break
        end
    end
end

--//==================================================
--// TELEPORT SEARCH
--//==================================================

Connect(SearchBox:GetPropertyChangedSignal("Text"), function()
    local text = SearchBox.Text

    State.SearchText = text

    if State.CurrentPage == "Teleport" then
        BuildTeleport()
    else
        for pageName, button in pairs(PageButtons) do
            local visible =
                text == ""
                or pageName:lower():find(text:lower(), 1, true)

            button.Visible = visible
        end
    end
end)

--//==================================================
--// SERVER
--//==================================================

do
    local page = Pages["Server"]

    Section(
        page,
        "Server",
        "Current server information"
    )

    local grid = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 180),

        BackgroundTransparency = 1
    }, page)

    Create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 82),
        CellPadding = UDim2.fromOffset(12, 12)
    }, grid)

    Card(grid, "PLACE ID", tostring(ServerService:GetPlaceId()))
    Card(grid, "SEA", WorldService:GetSea())
    Card(grid, "PLAYERS", tostring(ServerService:GetPlayers()))
    Card(grid, "PING", tostring(State.Ping) .. " ms")

    ActionButton(page, "Copy Job ID", function()
        local jobId = ServerService:GetJobId()

        if setclipboard then
            setclipboard(jobId)

            Notify(
                Config.Name,
                "Job ID copied."
            )
        else
            Notify(
                Config.Name,
                "Clipboard is not available."
            )
        end
    end)

    ActionButton(page, "Refresh Server Info", function()
        Notify(
            Config.Name,
            "Server: " ..
            tostring(ServerService:GetPlayers()) ..
            " players"
        )
    end)
end

--//==================================================
--// QUICK ACTIONS / MISC
--//==================================================

do
    local page = Pages["Misc"]

    Section(
        page,
        "Quick Actions",
        "Small utilities for the current session"
    )

    ActionButton(page, "Refresh Floquitave UI", function()
        PageService:Show(State.CurrentPage)

        Notify(
            Config.Name,
            "UI refreshed."
        )
    end)

    ActionButton(page, "Reapply Player Settings", function()
        PlayerService:SetWalkSpeed(
            State.PlayerSettings.WalkSpeed
        )

        PlayerService:SetJumpPower(
            State.PlayerSettings.JumpPower
        )

        Notify(
            Config.Name,
            "Player settings reapplied."
        )
    end)

    Section(
        page,
        "Test Modules",
        "UI-only placeholders for future modules"
    )

    Toggle(
        page,
        "Auto Farm",
        "Test switch only.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                "Auto Farm test: " ..
                (enabled and "ON" or "OFF")
            )
        end
    )

    Toggle(
        page,
        "Auto Mastery",
        "Test switch only.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                "Auto Mastery test: " ..
                (enabled and "ON" or "OFF")
            )
        end
    )

    Toggle(
        page,
        "Auto Quest",
        "Test switch only.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                "Auto Quest test: " ..
                (enabled and "ON" or "OFF")
            )
        end
    )

    Toggle(
        page,
        "Auto Raid",
        "Test switch only.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                "Auto Raid test: " ..
                (enabled and "ON" or "OFF")
            )
        end
    )

    Toggle(
        page,
        "Combat Assist",
        "Test switch only.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                "Combat Assist test: " ..
                (enabled and "ON" or "OFF")
            )
        end
    )
end

--//==================================================
--// OTHER TEST PAGES
--//==================================================

for _, pageName in ipairs({
    "Main Farm",
    "Quest",
    "Raids",
    "Combat"
}) do

    local page = Pages[pageName]

    Section(
        page,
        pageName,
        "Module structure ready for future development"
    )

    Toggle(
        page,
        pageName .. " Module",
        "Interface test toggle.",
        false,
        function(enabled)
            Notify(
                Config.Name,
                pageName ..
                ": " ..
                (enabled and "ON" or "OFF")
            )
        end
    )

    ActionButton(page, "Module Status", function()
        Notify(
            Config.Name,
            pageName .. " is currently a test module."
        )
    end)
end

--//==================================================
--// SETTINGS
--//==================================================

local function ApplyTheme()
    Theme = Themes[Config.Theme] or Themes.Dark

    Main.BackgroundColor3 = Theme.Background

    Topbar.BackgroundColor3 = Theme.Topbar
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Content.BackgroundColor3 = Theme.Background

    Logo.TextColor3 = Theme.Text
    Version.TextColor3 = Theme.SubText
    SidebarTitle.TextColor3 = Theme.SubText

    SearchBox.BackgroundColor3 = Theme.Card
    SearchBox.TextColor3 = Theme.Text
    SearchBox.PlaceholderColor3 = Theme.SubText

    Minimize.BackgroundColor3 = Theme.Button
    Minimize.TextColor3 = Theme.Text

    Close.BackgroundColor3 = Theme.Button
    Close.TextColor3 = Theme.Text

    for _, button in pairs(PageButtons) do
        if State.CurrentPage == button.Name then
            button.BackgroundColor3 = Theme.Accent
            button.TextColor3 = Color3.new(1, 1, 1)
        else
            button.BackgroundColor3 = Theme.Button
            button.TextColor3 = Theme.SubText
        end
    end

    if State.CurrentPage == "Teleport" then
        BuildTeleport()
    end
end

do
    local page = Pages["Settings"]

    Section(
        page,
        "Interface",
        "Customize the Floquitave appearance"
    )

    Toggle(
        page,
        "Animations",
        "Enable smooth UI transitions.",
        Config.Animations,
        function(enabled)
            Config.Animations = enabled
        end
    )

    Toggle(
        page,
        "Notifications",
        "Enable Floquitave notifications.",
        Config.Notifications,
        function(enabled)
            Config.Notifications = enabled
        end
    )

    Section(
        page,
        "Themes",
        "Choose the interface accent"
    )

    local themeHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 150),

        BackgroundTransparency = 1
    }, page)

    Create("UIGridLayout", {
        CellSize = UDim2.new(0.25, -6, 0, 40),
        CellPadding = UDim2.fromOffset(8, 8)
    }, themeHolder)

    for themeName in pairs(Themes) do
        local button = Create("TextButton", {
            BackgroundColor3 =
                themeName == Config.Theme
                and Theme.Accent
                or Theme.Button,

            Text = themeName,

            TextColor3 = Theme.Text,

            TextSize = 11,
            Font = Enum.Font.GothamMedium,

            AutoButtonColor = false
        }, themeHolder)

        Corner(button, 8)

        Connect(button.MouseButton1Click, function()
            Config.Theme = themeName

            ApplyTheme()

            Notify(
                Config.Name,
                "Theme: " .. themeName
            )
        end)
    end

    Section(
        page,
        "UI Scale",
        "Adjust the size of the main window"
    )

    local scaleHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),

        BackgroundTransparency = 1
    }, page)

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8)
    }, scaleHolder)

    for _, scale in ipairs({0.8, 0.9, 1, 1.1, 1.2}) do
        local button = Create("TextButton", {
            Size = UDim2.fromOffset(75, 36),

            BackgroundColor3 = Theme.Button,

            Text = tostring(scale) .. "x",

            TextColor3 = Theme.Text,

            TextSize = 11,
            Font = Enum.Font.GothamMedium,

            AutoButtonColor = false
        }, scaleHolder)

        Corner(button, 7)

        Connect(button.MouseButton1Click, function()
            Config.Scale = scale

            Main.Size = UDim2.fromOffset(
                Config.UIWidth * scale,
                Config.UIHeight * scale
            )

            Main.Position = UDim2.new(
                0.5,
                -(Config.UIWidth * scale) / 2,
                0.5,
                -(Config.UIHeight * scale) / 2
            )

            Notify(
                Config.Name,
                "UI scale: " .. tostring(scale) .. "x"
            )
        end)
    end
end

--//==================================================
--// ABOUT
--//==================================================

do
    local page = Pages["About"]

    Section(
        page,
        "Floquitave",
        "Current build information"
    )

    local about = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 170),

        BackgroundColor3 = Theme.Card,

        BorderSizePixel = 0
    }, page)

    Corner(about, 10)
    Stroke(about)

    Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 28),
        Position = UDim2.fromOffset(14, 14),

        BackgroundTransparency = 1,

        Text = "Floquitave " .. Config.Version,

        TextColor3 = Theme.Text,

        TextSize = 17,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left
    }, about)

    Create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 100),
        Position = UDim2.fromOffset(14, 48),

        BackgroundTransparency = 1,

        Text =
            "Modular UI foundation.\n\n" ..
            "Current build includes:\n" ..
            "• Home dashboard\n" ..
            "• Player settings\n" ..
            "• Sea-based location browser\n" ..
            "• Search and categories\n" ..
            "• Server information\n" ..
            "• Themes and UI scale\n" ..
            "• Session performance information",

        TextColor3 = Theme.SubText,

        TextSize = 11,
        Font = Enum.Font.GothamMedium,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, about)
end

--//==================================================
--// MINIMIZE CIRCLE
--//==================================================

local FloatingButton = Create("TextButton", {
    Name = "FloatingButton",

    Size = UDim2.fromOffset(52, 52),

    Position = UDim2.new(0.5, -26, 0.5, -26),

    BackgroundColor3 = Theme.Accent,

    Text = "F",

    TextColor3 = Color3.new(1, 1, 1),

    TextSize = 20,
    Font = Enum.Font.GothamBold,

    Visible = false,

    AutoButtonColor = false
}, ScreenGui)

Corner(FloatingButton, 30)
Stroke(FloatingButton, Color3.new(1, 1, 1), 0.85)

--//==================================================
--// DRAG FUNCTION
--//==================================================

local function MakeDraggable(object)
    local dragging = false
    local dragStart
    local startPosition
    local dragMoved = false

    Connect(object.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragMoved = false

            dragStart = input.Position
            startPosition = object.Position

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

        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            dragMoved = true
        end

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,

            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    return function()
        return dragMoved
    end
end

MakeDraggable(Main)

local FloatingMoved

FloatingMoved = MakeDraggable(FloatingButton)

--//==================================================
--// MINIMIZE
--//==================================================

Connect(Minimize.MouseButton1Click, function()
    State.Minimized = true

    Main.Visible = false
    FloatingButton.Visible = true

    FloatingButton.Position =
        UDim2.new(
            0.5,
            -26,
            0.5,
            -26
        )
end)

Connect(FloatingButton.MouseButton1Click, function()
    if FloatingMoved and FloatingMoved() then
        return
    end

    State.Minimized = false

    FloatingButton.Visible = false
    Main.Visible = true
end)

--//==================================================
--// CLOSE
--//==================================================

Connect(Close.MouseButton1Click, function()
    State.Destroyed = true

    Cleanup()

    ScreenGui:Destroy()
end)

--//==================================================
--// CHARACTER SETTINGS REAPPLY
--//==================================================

Connect(LocalPlayer.CharacterAdded, function()
    task.wait(1)

    if State.Destroyed then
        return
    end

    PlayerService:SetWalkSpeed(
        State.PlayerSettings.WalkSpeed
    )

    PlayerService:SetJumpPower(
        State.PlayerSettings.JumpPower
    )
end)

--//==================================================
--// INITIALIZATION
--//==================================================

PageService:Show("Home")

ApplyTheme()

Notify(
    Config.Name,
    "Floquitave " .. Config.Version .. " loaded."
)

print(
    "[Floquitave] " ..
    Config.Name ..
    " " ..
    Config.Version ..
    " loaded successfully."
)
