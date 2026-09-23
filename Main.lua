--[[
    FLOQUITAVE HUB
    Version: 2.7.4a
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Name = "Floquitave",
    Version = "2.7.4a",

    Width = 920,
    Height = 590,

    Animations = true,
    Notifications = true,

    Theme = "Dark",
    Scale = 1,

    Accent = Color3.fromRGB(151, 92, 255),

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
        Background = Color3.fromRGB(7, 7, 10),
        Sidebar = Color3.fromRGB(10, 10, 15),
        Card = Color3.fromRGB(15, 15, 22),
        Secondary = Color3.fromRGB(23, 23, 33),
        Text = Color3.fromRGB(245, 245, 248),
        SubText = Color3.fromRGB(143, 143, 158),
        Accent = Color3.fromRGB(151, 92, 255)
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
-- MOVEMENT SERVICE 2.6.5
-- Slower travel + safe cruise height
--==================================================

local MovementService = {
    Active = false,
    Target = nil,
    Tween = nil,
    Speed = 200,
    SafeHeight = 120,
    Status = "Idle",
    DestinationName = "None"
}

function MovementService:GetRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

function MovementService:GetHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

function MovementService:Stop()
    self.Active = false
    self.Target = nil
    self.Status = "Stopped"

    if self.Tween then
        pcall(function()
            self.Tween:Cancel()
        end)
        self.Tween = nil
    end
end

function MovementService:SetCollision(enabled)
    local character = LocalPlayer.Character
    if not character then return end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            pcall(function()
                object.CanCollide = enabled
            end)
        end
    end
end

function MovementService:TweenRoot(root, destination)
    if not root or not root.Parent then return false end

    local distance = (root.Position - destination.Position).Magnitude
    if distance <= 4 then
        root.CFrame = destination
        return true
    end

    local duration = math.clamp(distance / self.Speed, 0.12, 60)
    local tween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = destination}
    )

    self.Tween = tween
    local ok = pcall(function()
        tween:Play()
        tween.Completed:Wait()
    end)

    if self.Tween == tween then
        self.Tween = nil
    end

    return ok and self.Active
end

function MovementService:GoTo(targetCFrame, yOffset, destinationName)
    local root = self:GetRoot()
    local humanoid = self:GetHumanoid()

    if not root or not targetCFrame then
        self.Status = "Character unavailable"
        return false
    end

    -- Do not restart the same route every farm tick. Repeated GoTo calls
    -- were cancelling the cruise while the character was still rising.
    local requestedName = destinationName or "Target"
    if self.Active then
        if self.DestinationName == requestedName then
            return false
        end
        self:Stop()
    end

    self.Active = true
    self.Target = targetCFrame
    self.DestinationName = requestedName
    self.Status = "Moving"

    if humanoid then
        humanoid.Sit = false
    end

    pcall(function()
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    local destination = targetCFrame * CFrame.new(0, yOffset or 3, 0)
    local totalDistance = (root.Position - destination.Position).Magnitude

    -- Farm/short movement stays direct. Long island travel rises first,
    -- crosses at a fixed safe altitude, then descends at the destination.
    if totalDistance <= 260 then
        self:SetCollision(false)
        local ok = self:TweenRoot(root, destination)
        self:SetCollision(true)
        self.Active = false
        self.Status = ok and "Arrived" or "Failed"
        return ok
    end

    self:SetCollision(false)

    local cruiseY = math.max(root.Position.Y, destination.Position.Y) + self.SafeHeight
    local rise = CFrame.new(root.Position.X, cruiseY, root.Position.Z)
    local cruise = CFrame.new(destination.Position.X, cruiseY, destination.Position.Z)

    self.Status = "Rising"
    local ok = self:TweenRoot(root, rise)

    if ok then
        root = self:GetRoot()
        self.Status = "Cruising"
        ok = self:TweenRoot(root, cruise)
    end

    if ok then
        root = self:GetRoot()
        self.Status = "Descending"
        ok = self:TweenRoot(root, destination)
    end

    self:SetCollision(true)
    self.Active = false

    root = self:GetRoot()
    if not ok or not root then
        self.Status = "Failed"
        return false
    end

    local remaining = (root.Position - destination.Position).Magnitude
    self.Status = remaining <= 60 and "Arrived" or ("Failed (" .. math.floor(remaining) .. " studs)")
    return remaining <= 60
end

--==================================================
-- WATER WALK 2.6.5
--==================================================

local WaterWalkService = {
    Enabled = false,
    Platform = nil
}

function WaterWalkService:SetEnabled(enabled)
    self.Enabled = enabled

    if not enabled and self.Platform then
        self.Platform:Destroy()
        self.Platform = nil
    end
end

function WaterWalkService:Update()
    if not self.Enabled then return end

    local root = MovementService:GetRoot()
    if not root then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.IgnoreWater = false

    local result = workspace:Raycast(
        root.Position + Vector3.new(0, 8, 0),
        Vector3.new(0, -18, 0),
        rayParams
    )

    local overWater = result and result.Material == Enum.Material.Water

    if overWater then
        if not self.Platform or not self.Platform.Parent then
            self.Platform = Instance.new("Part")
            self.Platform.Name = "Floquitave_WaterWalk"
            self.Platform.Size = Vector3.new(7, 0.5, 7)
            self.Platform.Anchored = true
            self.Platform.CanCollide = true
            self.Platform.Transparency = 1
            self.Platform.Parent = workspace
        end

        self.Platform.CFrame = CFrame.new(
            root.Position.X,
            result.Position.Y + 1.7,
            root.Position.Z
        )
    elseif self.Platform then
        self.Platform:Destroy()
        self.Platform = nil
    end
end

RunService.Heartbeat:Connect(function()
    WaterWalkService:Update()
end)

--==================================================
-- TELEPORT DIRECTORY
--==================================================

local IslandCFrames = {
    ["Sea 1"] = {
        ["Bandit Island"] = CFrame.new(1060, 16, 1547),
        ["Jungle"] = CFrame.new(-1602, 37, 153),
        ["Pirate Village"] = CFrame.new(-1140, 5, 3828),
        ["Desert"] = CFrame.new(896, 6, 4390),
        ["Frozen Village"] = CFrame.new(1389, 87, -1298),
        ["Marine Fortress"] = CFrame.new(-5035, 29, 4325),
        ["Skylands"] = CFrame.new(-4842, 718, -2623),
        ["Prison"] = CFrame.new(5308, 2, 475),
        ["Colosseum"] = CFrame.new(-1577, 7, -2984),
        ["Magma Village"] = CFrame.new(-5316, 12, 8517),
        ["Underwater City"] = CFrame.new(61122, 18, 1569),
        ["Fountain City"] = CFrame.new(5259, 39, 4050)
    },
    ["Sea 2"] = {
        ["Kingdom of Rose"] = CFrame.new(-425, 73, 1836),
        ["Green Zone"] = CFrame.new(-2448, 73, -3210),
        ["Graveyard"] = CFrame.new(-5494, 49, -794),
        ["Snow Mountain"] = CFrame.new(561, 402, -5297),
        ["Hot and Cold"] = CFrame.new(-6026, 15, -5071),
        ["Cursed Ship"] = CFrame.new(923, 126, 32852),
        ["Ice Castle"] = CFrame.new(5400, 28, -6236),
        ["Forgotten Island"] = CFrame.new(-3052, 237, -10148)
    },
    ["Sea 3"] = {
        ["Port Town"] = CFrame.new(-290, 44, 5454),
        ["Hydra Island"] = CFrame.new(5228, 604, 345),
        ["Great Tree"] = CFrame.new(2276, 25, -6493),
        ["Floating Turtle"] = CFrame.new(-13274, 332, -7621),
        ["Haunted Castle"] = CFrame.new(-9515, 142, 5537),
        ["Sea of Treats"] = CFrame.new(-2062, 38, -12032),
        ["Tiki Outpost"] = CFrame.new(-16224, 9, 439),
        ["Chocolate Land"] = CFrame.new(100, 25, -12300),
        ["Cake Land"] = CFrame.new(-1900, 20, -11600),
        ["Peanut Island"] = CFrame.new(-2100, 50, -10100),
        ["Ice Cream Island"] = CFrame.new(-900, 65, -10900)
    }
}

local TeleportLocations = {
    ["Sea 1"] = {
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

    ["Sea 2"] = {
        "Kingdom of Rose",
        "Green Zone",
        "Graveyard",
        "Snow Mountain",
        "Hot and Cold",
        "Cursed Ship",
        "Ice Castle",
        "Forgotten Island"
    },

    ["Sea 3"] = {
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
    local parented = false

    if typeof(gethui) == "function" then
        parented = pcall(function()
            ScreenGui.Parent = gethui()
        end)
    end

    if not parented then
        parented = pcall(function()
            ScreenGui.Parent = game:GetService("CoreGui")
        end)
    end

    if not parented then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            or LocalPlayer:WaitForChild("PlayerGui", 5)

        if playerGui then
            ScreenGui.Parent = playerGui
            parented = true
        end
    end

    if not parented then
        return
    end
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
    BackgroundColor3 = Theme.Secondary,
    Text = "F",
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextColor3 = Theme.Accent
}, Topbar)

Corner(Logo, 12)
Stroke(Logo, Theme.Accent, 0.16)

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
    "Simple • Functional • Lightweight"
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
    Text = "Floquitave 2.7.4",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = Theme.SubText,
    TextXAlignment = Enum.TextXAlignment.Left
}, Welcome)

local HomeGrid = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 160),
    BackgroundTransparency = 1
}, Home)

Create("UIGridLayout", {
    CellSize = UDim2.new(0.24, 0, 0, 72),
    CellPadding = UDim2.new(0.012, 0, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
}, HomeGrid)

local LevelValue = select(2, Card(HomeGrid, "LEVEL", "0"))
local BeliValue = select(2, Card(HomeGrid, "BELI", "0"))
local FragmentValue = select(2, Card(HomeGrid, "FRAGMENTS", "0"))
local RaceValue = select(2, Card(HomeGrid, "RACE", "Unknown"))
local SeaValue = select(2, Card(HomeGrid, "SEA", "Unknown"))
local FPSValue = select(2, Card(HomeGrid, "FPS", "0"))
local PingValue = select(2, Card(HomeGrid, "PING", "0 ms"))
local UptimeValue = select(2, Card(HomeGrid, "UPTIME", "00:00:00"))

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

Create("UIGridLayout", {
    CellSize = UDim2.new(0.32, 0, 0, 68),
    CellPadding = UDim2.new(0.015, 0, 0, 10)
}, PlayerInfoGrid)

Card(PlayerInfoGrid, "USERNAME", LocalPlayer.Name)
Card(PlayerInfoGrid, "DISPLAY NAME", LocalPlayer.DisplayName)
Card(PlayerInfoGrid, "USER ID", LocalPlayer.UserId)

local _, SpeedBox = ValueBox(
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

local _, JumpBox = ValueBox(
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
    "Sea 1 / Sea 2 / Sea 3 — selecione o mapa e depois a ilha"
)

local TeleportStatusCard, TeleportStatusValue = Card(
    TeleportPage,
    "STATUS",
    "Idle"
)

local TeleportDestinationCard, TeleportDestinationValue = Card(
    TeleportPage,
    "DESTINO",
    "None"
)

local SelectedSea = "Sea 1"

local SeaHolder = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundTransparency = 1
}, TeleportPage)

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, SeaHolder)

local TeleportSearch = Create("TextBox", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Theme.Card,
    PlaceholderText = "Pesquisar ilha...",
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

Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, TeleportHolder)

local BuildTeleport

local function ClearTeleport()
    for _, child in ipairs(TeleportHolder:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function SetTeleportStatus(status, destination)
    TeleportStatusValue.Text = status or MovementService.Status
    if destination then
        TeleportDestinationValue.Text = destination
    end
end

local function TeleportToIsland(seaName, locationName)
    local destination = IslandCFrames[seaName]
        and IslandCFrames[seaName][locationName]

    if not destination then
        SetTeleportStatus("Destino não configurado", locationName)
        Notify("Teleport", "Destino não configurado: " .. locationName)
        return
    end

    SetTeleportStatus("Teleportando...", locationName)

    task.spawn(function()
        -- Teleport Directory experimental route:
        -- 1 subida única -> 2 percurso em pequenos trechos com Y fixo -> 3 descida única.
        -- Não altera Farm/Boss nem o GoTo global.
        local root = MovementService:GetRoot()
        local humanoid = MovementService:GetHumanoid()

        if not root then
            SetTeleportStatus("Character unavailable", locationName)
            return
        end

        MovementService:Stop()
        MovementService.Active = true
        MovementService.Target = destination
        MovementService.DestinationName = locationName

        if humanoid then
            humanoid.Sit = false
        end

        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        local finalTarget = destination * CFrame.new(0, 5, 0)
        local fixedY = math.max(root.Position.Y, finalTarget.Position.Y) + 70
        local ok = true

        MovementService:SetCollision(false)

        -- Fase 1: sobe apenas uma vez.
        MovementService.Status = "Rising"
        SetTeleportStatus("Subindo...", locationName)

        local riseTarget = CFrame.new(root.Position.X, fixedY, root.Position.Z)
        ok = MovementService:TweenRoot(root, riseTarget)

        -- Fase 2: deslocamento horizontal segmentado.
        if ok then
            MovementService.Status = "Cruising"
            SetTeleportStatus("Indo para " .. locationName .. "...", locationName)

            root = MovementService:GetRoot()

            if root then
                local startPosition = root.Position
                local horizontalTarget = Vector3.new(
                    finalTarget.Position.X,
                    fixedY,
                    finalTarget.Position.Z
                )

                local delta = horizontalTarget - startPosition
                local distance = delta.Magnitude

                if distance > 1 then
                    local direction = delta.Unit
                    local segmentLength = 28
                    local travelled = 0

                    while travelled < distance and MovementService.Active do
                        root = MovementService:GetRoot()
                        if not root then
                            ok = false
                            break
                        end

                        travelled = math.min(travelled + segmentLength, distance)

                        local nextPosition
                        if travelled >= distance then
                            nextPosition = horizontalTarget
                        else
                            nextPosition = startPosition + direction * travelled
                            nextPosition = Vector3.new(
                                nextPosition.X,
                                fixedY,
                                nextPosition.Z
                            )
                        end

                        pcall(function()
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end)

                        ok = MovementService:TweenRoot(
                            root,
                            CFrame.new(nextPosition.X, fixedY, nextPosition.Z)
                        )

                        if not ok then
                            break
                        end
                    end
                end
            else
                ok = false
            end
        end

        -- Fase 3: só desce depois de concluir o percurso horizontal.
        if ok and MovementService.Active then
            root = MovementService:GetRoot()

            if root then
                MovementService.Status = "Descending"
                SetTeleportStatus("Descendo...", locationName)
                ok = MovementService:TweenRoot(root, finalTarget)
            else
                ok = false
            end
        end

        MovementService:SetCollision(true)
        MovementService.Active = false
        MovementService.Tween = nil

        root = MovementService:GetRoot()

        if ok and root then
            local remaining = (root.Position - finalTarget.Position).Magnitude
            ok = remaining <= 60
        else
            ok = false
        end

        MovementService.Status = ok and "Arrived" or "Failed"
        SetTeleportStatus(MovementService.Status, locationName)

        if ok then
            Notify("Teleport", "Chegou em " .. locationName .. ".")
        else
            Notify("Teleport", "Falha ao chegar em " .. locationName .. ".")
        end
    end)
end

BuildTeleport = function()
    ClearTeleport()

    local locations = TeleportLocations[SelectedSea] or {}
    local search = string.lower(TeleportSearch.Text or "")

    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0
    }, TeleportHolder)

    Corner(header, 10)

    Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = SelectedSea .. " — " .. tostring(#locations) .. " destinos",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, header)

    for _, locationName in ipairs(locations) do
        if search == "" or string.find(string.lower(locationName), search, 1, true) then
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
                TeleportToIsland(SelectedSea, locationName)
            end)
        end
    end
end

for index, seaName in ipairs({"Sea 1", "Sea 2", "Sea 3"}) do
    local seaButton = Create("TextButton", {
        Size = UDim2.new(0.32, -4, 1, 0),
        BackgroundColor3 = seaName == SelectedSea and Theme.Accent or Theme.Card,
        Text = seaName,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
        LayoutOrder = index
    }, SeaHolder)

    Corner(seaButton, 9)
    AddHoverEffect(seaButton)

    Connect(seaButton.MouseButton1Click, function()
        SelectedSea = seaName

        for _, child in ipairs(SeaHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 =
                    child == seaButton and Theme.Accent or Theme.Card
            end
        end

        BuildTeleport()
    end)
end

ActionButton(
    TeleportPage,
    "STOP TELEPORT",
    function()
        MovementService:Stop()
        SetTeleportStatus("Stopped")
        Notify("Teleport", "Movimento interrompido.")
    end
)

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
    AutoCakePrince = false,
    AutoBone = false,
    SpecialStatus = "Idle",
    SpecialTarget = "None",
    CakeStatus = "Checking...",
    BoneCount = "Checking...",
    BoneRotation = 1,
    QuestOwnedByHub = false,
    QuestSeenVisible = false,
    QuestRoutePending = false,
    QuestStartLevel = 0,
    QuestStartedAt = 0,

    Enabled = false,
    AutoMastery = false,
    AutoTarget = true,
    BringMobs = false,
    FastAttack = false,
    NoClip = false,
    UseTool = true,
    Distance = 8,
    ScanRadius = 500,
    AttackCooldown = 0.12,
    TargetName = "Auto",
    AutoQuest = true,
    QuestStatus = "Idle",
    QuestMob = nil,
    QuestName = nil,
    QuestLevel = nil,
    QuestPosition = nil,
    MobPosition = nil,
    CurrentSea = nil,
    LastQuestMove = 0,
    LastMobMove = 0,
    FarmAnchor = nil,
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


--==================================================
-- LEVEL FARM / QUEST 2.6.4
-- Separate QuestPos and MobPos, selected by Sea + current level
--==================================================

local QuestData = {
    {Sea=1, Min=1, Max=9, Mob="Bandit", Quest="BanditQuest1", Level=1, QuestPos=CFrame.new(1059.37195,15.449507,1550.4231), MobPos=CFrame.new(1045.962646,27.002508,1560.820312)},
    {Sea=1, Min=10, Max=14, Mob="Monkey", Quest="JungleQuest", Level=1, QuestPos=CFrame.new(-1598.08911,35.550117,153.377838), MobPos=CFrame.new(-1448.518066,67.853012,11.465796)},
    {Sea=1, Min=15, Max=29, Mob="Gorilla", Quest="JungleQuest", Level=2, QuestPos=CFrame.new(-1598.08911,35.550117,153.377838), MobPos=CFrame.new(-1129.883667,40.463547,-525.423706)},
    {Sea=1, Min=30, Max=39, Mob="Pirate", Quest="BuggyQuest1", Level=1, QuestPos=CFrame.new(-1141.07483,4.100018,3831.5498), MobPos=CFrame.new(-1103.513428,13.752052,3896.091064)},
    {Sea=1, Min=40, Max=59, Mob="Brute", Quest="BuggyQuest1", Level=2, QuestPos=CFrame.new(-1141.07483,4.100018,3831.5498), MobPos=CFrame.new(-1140.08374,14.809885,4322.921387)},
    {Sea=1, Min=60, Max=74, Mob="Desert Bandit", Quest="DesertQuest", Level=1, QuestPos=CFrame.new(894.488647,5.140007,4392.43359), MobPos=CFrame.new(924.799805,6.448675,4481.585938)},
    {Sea=1, Min=75, Max=89, Mob="Desert Officer", Quest="DesertQuest", Level=2, QuestPos=CFrame.new(894.488647,5.140007,4392.43359), MobPos=CFrame.new(1608.282227,8.614224,4371.007324)},
    {Sea=1, Min=90, Max=99, Mob="Snow Bandit", Quest="SnowQuest", Level=1, QuestPos=CFrame.new(1389.74451,88.151932,-1298.90796), MobPos=CFrame.new(1354.3479,87.272774,-1393.946533)},
    {Sea=1, Min=100, Max=119, Mob="Snowman", Quest="SnowQuest", Level=2, QuestPos=CFrame.new(1389.74451,88.151932,-1298.90796), MobPos=CFrame.new(1201.641235,144.57959,-1550.067017)},
    {Sea=1, Min=120, Max=149, Mob="Chief Petty Officer", Quest="MarineQuest2", Level=1, QuestPos=CFrame.new(-5039.58643,27.350039,4324.68018), MobPos=CFrame.new(-4881.230957,22.652044,4273.752441)},
    {Sea=1, Min=150, Max=174, Mob="Sky Bandit", Quest="SkyQuest", Level=1, QuestPos=CFrame.new(-4839.53027,716.368591,-2619.44165), MobPos=CFrame.new(-4953.207031,295.744202,-2899.229004)},
    {Sea=1, Min=175, Max=189, Mob="Dark Master", Quest="SkyQuest", Level=2, QuestPos=CFrame.new(-4839.53027,716.368591,-2619.44165), MobPos=CFrame.new(-5259.844727,391.397675,-2229.0354)},
    {Sea=1, Min=190, Max=209, Mob="Prisoner", Quest="PrisonerQuest", Level=1, QuestPos=CFrame.new(5308.93115,1.655175,475.120514), MobPos=CFrame.new(5098.973633,-0.320406,474.237335)},
    {Sea=1, Min=210, Max=249, Mob="Dangerous Prisoner", Quest="PrisonerQuest", Level=2, QuestPos=CFrame.new(5308.93115,1.655175,475.120514), MobPos=CFrame.new(5654.563477,15.633402,866.299194)},
    {Sea=1, Min=250, Max=274, Mob="Toga Warrior", Quest="ColosseumQuest", Level=1, QuestPos=CFrame.new(-1580.04663,6.350003,-2986.47534), MobPos=CFrame.new(-1820.214844,51.683857,-2740.665039)},
    {Sea=1, Min=275, Max=299, Mob="Gladiator", Quest="ColosseumQuest", Level=2, QuestPos=CFrame.new(-1580.04663,6.350003,-2986.47534), MobPos=CFrame.new(-1292.838135,56.380882,-3339.031494)},
    {Sea=1, Min=300, Max=324, Mob="Military Soldier", Quest="MagmaQuest", Level=1, QuestPos=CFrame.new(-5313.37012,10.950008,8515.29395), MobPos=CFrame.new(-5411.164551,11.081554,8454.292969)},
    {Sea=1, Min=325, Max=374, Mob="Military Spy", Quest="MagmaQuest", Level=2, QuestPos=CFrame.new(-5313.37012,10.950008,8515.29395), MobPos=CFrame.new(-5802.868164,86.262413,8828.859375)},
    {Sea=1, Min=375, Max=399, Mob="Fishman Warrior", Quest="FishmanQuest", Level=1, QuestPos=CFrame.new(61122.652344,18.497442,1569.39978), MobPos=CFrame.new(60878.300781,18.48283,1543.757446)},
    {Sea=1, Min=400, Max=449, Mob="Fishman Commando", Quest="FishmanQuest", Level=2, QuestPos=CFrame.new(61122.652344,18.497442,1569.39978), MobPos=CFrame.new(61922.632812,18.48283,1493.934326)},
    {Sea=1, Min=450, Max=474, Mob="God's Guard", Quest="SkyExp1Quest", Level=1, QuestPos=CFrame.new(-4721.88867,843.874695,-1949.96643), MobPos=CFrame.new(-4710.042969,845.276978,-1927.307983)},
    {Sea=1, Min=475, Max=524, Mob="Shanda", Quest="SkyExp1Quest", Level=2, QuestPos=CFrame.new(-7859.09814,5544.19043,-381.476196), MobPos=CFrame.new(-7678.489746,5566.403809,-497.215607)},
    {Sea=1, Min=525, Max=549, Mob="Royal Squad", Quest="SkyExp2Quest", Level=1, QuestPos=CFrame.new(-7906.81592,5634.6626,-1411.99194), MobPos=CFrame.new(-7624.252441,5658.133301,-1467.354248)},
    {Sea=1, Min=550, Max=624, Mob="Royal Soldier", Quest="SkyExp2Quest", Level=2, QuestPos=CFrame.new(-7906.81592,5634.6626,-1411.99194), MobPos=CFrame.new(-7836.753418,5645.664062,-1790.623657)},
    {Sea=1, Min=625, Max=649, Mob="Galley Pirate", Quest="FountainQuest", Level=1, QuestPos=CFrame.new(5259.81982,37.350017,4050.0293), MobPos=CFrame.new(5551.021973,78.901352,3930.412842)},
    {Sea=1, Min=650, Max=699, Mob="Galley Captain", Quest="FountainQuest", Level=2, QuestPos=CFrame.new(5259.81982,37.350017,4050.0293), MobPos=CFrame.new(5441.95166,42.50206,4950.09375)},
    {Sea=2, Min=700, Max=724, Mob="Raider", Quest="Area1Quest", Level=1, QuestPos=CFrame.new(-429.543518,71.769997,1836.18188), MobPos=CFrame.new(-728.326721,52.77932,2345.770508)},
    {Sea=2, Min=725, Max=774, Mob="Mercenary", Quest="Area1Quest", Level=2, QuestPos=CFrame.new(-429.543518,71.769997,1836.18188), MobPos=CFrame.new(-1004.324402,80.158867,1424.619385)},
    {Sea=2, Min=775, Max=799, Mob="Swan Pirate", Quest="Area2Quest", Level=1, QuestPos=CFrame.new(638.43811,71.769989,918.282898), MobPos=CFrame.new(1068.664307,137.614288,1322.106079)},
    {Sea=2, Min=800, Max=874, Mob="Factory Staff", Quest="Area2Quest", Level=2, QuestPos=CFrame.new(632.698608,73.105591,918.666321), MobPos=CFrame.new(73.078674,81.863441,-27.470673)},
    {Sea=2, Min=875, Max=899, Mob="Marine Lieutenant", Quest="MarineQuest3", Level=1, QuestPos=CFrame.new(-2440.79639,71.714073,-3216.06812), MobPos=CFrame.new(-2821.372314,75.897278,-3070.089111)},
    {Sea=2, Min=900, Max=949, Mob="Marine Captain", Quest="MarineQuest3", Level=2, QuestPos=CFrame.new(-2440.79639,71.714073,-3216.06812), MobPos=CFrame.new(-1861.231079,80.176582,-3254.69751)},
    {Sea=2, Min=950, Max=974, Mob="Zombie", Quest="ZombieQuest", Level=1, QuestPos=CFrame.new(-5497.06152,47.5923,-795.237061), MobPos=CFrame.new(-5657.776855,78.969734,-928.687012)},
    {Sea=2, Min=975, Max=999, Mob="Vampire", Quest="ZombieQuest", Level=2, QuestPos=CFrame.new(-5497.06152,47.5923,-795.237061), MobPos=CFrame.new(-6037.667969,32.184639,-1340.65979)},
    {Sea=2, Min=1000, Max=1049, Mob="Snow Trooper", Quest="SnowMountainQuest", Level=1, QuestPos=CFrame.new(609.858826,400.119904,-5372.25928), MobPos=CFrame.new(549.147339,427.387054,-5563.69873)},
    {Sea=2, Min=1050, Max=1099, Mob="Winter Warrior", Quest="SnowMountainQuest", Level=2, QuestPos=CFrame.new(609.858826,400.119904,-5372.25928), MobPos=CFrame.new(1142.745117,475.639801,-5199.416504)},
    {Sea=2, Min=1100, Max=1124, Mob="Lab Subordinate", Quest="IceSideQuest", Level=1, QuestPos=CFrame.new(-6064.06885,15.242286,-4902.97852), MobPos=CFrame.new(-5707.47168,15.95171,-4513.39209)},
    {Sea=2, Min=1125, Max=1174, Mob="Horned Warrior", Quest="IceSideQuest", Level=2, QuestPos=CFrame.new(-6064.06885,15.242286,-4902.97852), MobPos=CFrame.new(-6341.366699,15.951771,-5723.162109)},
    {Sea=2, Min=1175, Max=1199, Mob="Magma Ninja", Quest="FireSideQuest", Level=1, QuestPos=CFrame.new(-5428.03174,15.062292,-5299.43457), MobPos=CFrame.new(-5449.672852,76.658745,-5808.200684)},
    {Sea=2, Min=1200, Max=1249, Mob="Lava Pirate", Quest="FireSideQuest", Level=2, QuestPos=CFrame.new(-5428.03174,15.062292,-5299.43457), MobPos=CFrame.new(-5213.331543,49.737881,-4701.451172)},
    {Sea=2, Min=1250, Max=1274, Mob="Ship Deckhand", Quest="ShipQuest1", Level=1, QuestPos=CFrame.new(1037.80127,125.092171,32911.6016), MobPos=CFrame.new(1212.011108,150.792053,33059.246094)},
    {Sea=2, Min=1275, Max=1299, Mob="Ship Engineer", Quest="ShipQuest1", Level=2, QuestPos=CFrame.new(1037.80127,125.092171,32911.6016), MobPos=CFrame.new(919.478638,43.544014,32779.96875)},
    {Sea=2, Min=1300, Max=1324, Mob="Ship Steward", Quest="ShipQuest2", Level=1, QuestPos=CFrame.new(968.80957,125.092171,33244.125), MobPos=CFrame.new(919.438538,129.556,33436.035156)},
    {Sea=2, Min=1325, Max=1349, Mob="Ship Officer", Quest="ShipQuest2", Level=2, QuestPos=CFrame.new(968.80957,125.092171,33244.125), MobPos=CFrame.new(1036.017944,181.439041,33315.726562)},
    {Sea=2, Min=1350, Max=1374, Mob="Arctic Warrior", Quest="FrostQuest", Level=1, QuestPos=CFrame.new(5667.6582,26.799782,-6486.08984), MobPos=CFrame.new(5966.246094,62.97002,-6179.382812)},
    {Sea=2, Min=1375, Max=1424, Mob="Snow Lurker", Quest="FrostQuest", Level=2, QuestPos=CFrame.new(5667.6582,26.799782,-6486.08984), MobPos=CFrame.new(5407.07373,69.194374,-6880.880371)},
    {Sea=2, Min=1425, Max=1449, Mob="Sea Soldier", Quest="ForgottenQuest", Level=1, QuestPos=CFrame.new(-3054.44458,235.544281,-10142.8193), MobPos=CFrame.new(-3028.223633,64.674515,-9775.426758)},
    {Sea=2, Min=1450, Max=1499, Mob="Water Fighter", Quest="ForgottenQuest", Level=2, QuestPos=CFrame.new(-3054.44458,235.544281,-10142.8193), MobPos=CFrame.new(-3352.901367,285.015564,-10534.841797)},
    {Sea=3, Min=1500, Max=1524, Mob="Pirate Millionaire", Quest="PiratePortQuest", Level=1, QuestPos=CFrame.new(-450.104645,107.681458,5950.72607), MobPos=CFrame.new(-245.996384,47.306152,5584.100586)},
    {Sea=3, Min=1525, Max=1574, Mob="Pistol Billionaire", Quest="PiratePortQuest", Level=2, QuestPos=CFrame.new(-450.104645,107.681458,5950.72607), MobPos=CFrame.new(-54.811035,83.769875,5947.84082)},
    {Sea=3, Min=1575, Max=1599, Mob="Dragon Crew Warrior", Quest="DragonCrewQuest", Level=1, QuestPos=CFrame.new(6750.493164,127.449165,-711.030884), MobPos=CFrame.new(6709.76367,52.344299,-1139.02966)},
    {Sea=3, Min=1600, Max=1624, Mob="Dragon Crew Archer", Quest="DragonCrewQuest", Level=2, QuestPos=CFrame.new(6750.493164,127.449165,-711.030884), MobPos=CFrame.new(6668.76172,481.376923,329.12207)},
    {Sea=3, Min=1625, Max=1649, Mob="Hydra Enforcer", Quest="VenomCrewQuest", Level=1, QuestPos=CFrame.new(5206.401855,1004.10498,748.350464), MobPos=CFrame.new(4547.11523,1003.10217,334.194824)},
    {Sea=3, Min=1650, Max=1699, Mob="Venomous Assailant", Quest="VenomCrewQuest", Level=2, QuestPos=CFrame.new(5206.401855,1004.10498,748.350464), MobPos=CFrame.new(4674.92676,1134.82654,996.308838)},
    {Sea=3, Min=1700, Max=1724, Mob="Marine Commodore", Quest="MarineTreeIsland", Level=1, QuestPos=CFrame.new(2481.092285,74.270493,-6779.640625), MobPos=CFrame.new(2577.25391,75.610001,-7739.87207)},
    {Sea=3, Min=1725, Max=1774, Mob="Marine Rear Admiral", Quest="MarineTreeIsland", Level=2, QuestPos=CFrame.new(2481.092285,74.270493,-6779.640625), MobPos=CFrame.new(3761.81006,123.912003,-6823.52197)},
    {Sea=3, Min=1775, Max=1799, Mob="Fishman Raider", Quest="DeepForestIsland3", Level=1, QuestPos=CFrame.new(-10581.6563,330.872955,-8761.18652), MobPos=CFrame.new(-10407.526367,331.762634,-8368.516602)},
    {Sea=3, Min=1800, Max=1824, Mob="Fishman Captain", Quest="DeepForestIsland3", Level=2, QuestPos=CFrame.new(-10581.6563,330.872955,-8761.18652), MobPos=CFrame.new(-10994.701172,352.381409,-9002.110352)},
    {Sea=3, Min=1825, Max=1849, Mob="Forest Pirate", Quest="DeepForestIsland", Level=1, QuestPos=CFrame.new(-13234.04,331.488495,-7625.40137), MobPos=CFrame.new(-13274.478516,332.378143,-7769.580566)},
    {Sea=3, Min=1850, Max=1899, Mob="Mythological Pirate", Quest="DeepForestIsland", Level=2, QuestPos=CFrame.new(-13234.04,331.488495,-7625.40137), MobPos=CFrame.new(-13680.607422,501.081543,-6991.189453)},
    {Sea=3, Min=1900, Max=1924, Mob="Jungle Pirate", Quest="DeepForestIsland2", Level=1, QuestPos=CFrame.new(-12680.3818,389.971039,-9902.01953), MobPos=CFrame.new(-12256.160156,331.738281,-10485.836914)},
    {Sea=3, Min=1925, Max=1974, Mob="Musketeer Pirate", Quest="DeepForestIsland2", Level=2, QuestPos=CFrame.new(-12680.3818,389.971039,-9902.01953), MobPos=CFrame.new(-13457.904297,391.545654,-9859.177734)},
    {Sea=3, Min=1975, Max=1999, Mob="Reborn Skeleton", Quest="HauntedQuest1", Level=1, QuestPos=CFrame.new(-9479.2168,141.215088,5566.09277), MobPos=CFrame.new(-8763.723633,165.722992,6159.861816)},
    {Sea=3, Min=2000, Max=2024, Mob="Living Zombie", Quest="HauntedQuest1", Level=2, QuestPos=CFrame.new(-9479.2168,141.215088,5566.09277), MobPos=CFrame.new(-10144.131836,138.626678,5838.088867)},
    {Sea=3, Min=2025, Max=2049, Mob="Demonic Soul", Quest="HauntedQuest2", Level=1, QuestPos=CFrame.new(-9516.99316,172.017181,6078.46533), MobPos=CFrame.new(-9505.87207,172.104828,6158.993164)},
    {Sea=3, Min=2050, Max=2074, Mob="Posessed Mummy", Quest="HauntedQuest2", Level=2, QuestPos=CFrame.new(-9516.99316,172.017181,6078.46533), MobPos=CFrame.new(-9582.022461,6.251527,6205.478516)},
    {Sea=3, Min=2075, Max=2099, Mob="Peanut Scout", Quest="NutsIslandQuest", Level=1, QuestPos=CFrame.new(-2104.390869,38.104168,-10194.21875), MobPos=CFrame.new(-2143.241943,47.721985,-10029.995117)},
    {Sea=3, Min=2100, Max=2124, Mob="Peanut President", Quest="NutsIslandQuest", Level=2, QuestPos=CFrame.new(-2104.390869,38.104168,-10194.21875), MobPos=CFrame.new(-1859.354004,38.103168,-10422.429688)},
    {Sea=3, Min=2125, Max=2149, Mob="Ice Cream Chef", Quest="IceCreamIslandQuest", Level=1, QuestPos=CFrame.new(-820.648254,65.819527,-10965.795898), MobPos=CFrame.new(-872.246582,65.819572,-10919.957031)},
    {Sea=3, Min=2150, Max=2199, Mob="Ice Cream Commander", Quest="IceCreamIslandQuest", Level=2, QuestPos=CFrame.new(-820.648254,65.819527,-10965.795898), MobPos=CFrame.new(-558.061035,112.048958,-11290.774414)},
    {Sea=3, Min=2200, Max=2224, Mob="Cookie Crafter", Quest="CakeQuest1", Level=1, QuestPos=CFrame.new(-2021.32007,37.798225,-12028.7295), MobPos=CFrame.new(-2374.136719,37.798264,-12125.308594)},
    {Sea=3, Min=2225, Max=2249, Mob="Cake Guard", Quest="CakeQuest1", Level=2, QuestPos=CFrame.new(-2021.32007,37.798225,-12028.7295), MobPos=CFrame.new(-1598.307007,43.773197,-12244.581055)},
    {Sea=3, Min=2250, Max=2274, Mob="Baking Staff", Quest="CakeQuest2", Level=1, QuestPos=CFrame.new(-1927.91602,37.798134,-12842.5391), MobPos=CFrame.new(-1887.809937,77.618507,-12998.350586)},
    {Sea=3, Min=2275, Max=2299, Mob="Head Baker", Quest="CakeQuest2", Level=2, QuestPos=CFrame.new(-1927.91602,37.798134,-12842.5391), MobPos=CFrame.new(-2216.188232,82.884521,-12869.293945)},
    {Sea=3, Min=2300, Max=2324, Mob="Cocoa Warrior", Quest="ChocQuest1", Level=1, QuestPos=CFrame.new(233.228363,29.876001,-12201.233398), MobPos=CFrame.new(-21.553284,80.574997,-12352.387695)},
    {Sea=3, Min=2325, Max=2349, Mob="Chocolate Bar Battler", Quest="ChocQuest1", Level=2, QuestPos=CFrame.new(233.228363,29.876001,-12201.233398), MobPos=CFrame.new(582.590576,77.188095,-12463.162109)},
    {Sea=3, Min=2350, Max=2374, Mob="Sweet Thief", Quest="ChocQuest2", Level=1, QuestPos=CFrame.new(150.506638,30.693693,-12774.50293), MobPos=CFrame.new(165.188477,76.058853,-12600.836914)},
    {Sea=3, Min=2375, Max=2399, Mob="Candy Rebel", Quest="ChocQuest2", Level=2, QuestPos=CFrame.new(150.506638,30.693693,-12774.50293), MobPos=CFrame.new(134.865631,77.247681,-12876.547852)},
    {Sea=3, Min=2400, Max=2424, Mob="Candy Pirate", Quest="CandyQuest1", Level=1, QuestPos=CFrame.new(-1150.040039,20.378935,-14446.334961), MobPos=CFrame.new(-1310.500366,26.016523,-14562.404297)},
    {Sea=3, Min=2425, Max=2449, Mob="Snow Demon", Quest="CandyQuest1", Level=2, QuestPos=CFrame.new(-1150.040039,20.378935,-14446.334961), MobPos=CFrame.new(-880.200623,71.247765,-14538.609375)},
    {Sea=3, Min=2450, Max=2474, Mob="Isle Outlaw", Quest="TikiQuest1", Level=1, QuestPos=CFrame.new(-16547.748047,61.135334,-173.413605), MobPos=CFrame.new(-16442.814453,116.139,-264.463776)},
    {Sea=3, Min=2475, Max=2524, Mob="Island Boy", Quest="TikiQuest1", Level=2, QuestPos=CFrame.new(-16547.748047,61.135334,-173.413605), MobPos=CFrame.new(-16901.261719,84.067566,-192.889069)},
    {Sea=3, Min=2525, Max=2550, Mob="Isle Champion", Quest="TikiQuest2", Level=2, QuestPos=CFrame.new(-16539.078125,55.686329,1051.573853), MobPos=CFrame.new(-16641.679688,235.782547,1031.282959)},
    {Sea=3, Min=2550, Max=2574, Mob="Serpent Hunter", Quest="TikiQuest3", Level=1, QuestPos=CFrame.new(-16665.1914,104.596405,1579.69434), MobPos=CFrame.new(-16521.0625,106.09285,1488.78467)},
    {Sea=3, Min=2575, Max=9999, Mob="Skull Slayer", Quest="TikiQuest3", Level=2, QuestPos=CFrame.new(-16665.1914,104.596405,1579.69434), MobPos=CFrame.new(-16855.043,122.457253,1478.15308)},
}

local function GetCurrentSeaNumber()
    if game.PlaceId == 2753915549 then return 1 end
    if game.PlaceId == 4442272183 then return 2 end
    if game.PlaceId == 7449423635 then return 3 end

    -- Fallback for custom/test places: infer from current level.
    local level = PlayerService:GetLevel()
    if level < 700 then return 1 end
    if level < 1500 then return 2 end
    return 3
end

local function GetLevelFarmQuest()
    local level = PlayerService:GetLevel()
    local sea = GetCurrentSeaNumber()

    local best = nil
    for _, q in ipairs(QuestData) do
        if q.Sea == sea and level >= q.Min and level <= q.Max then
            best = q
            break
        end
    end

    -- If the reference table has a small gap, use the newest quest already
    -- unlocked in the current Sea instead of jumping to another Sea.
    if not best then
        for _, q in ipairs(QuestData) do
            if q.Sea == sea and q.Min <= level then
                if not best or q.Min > best.Min then
                    best = q
                end
            end
        end
    end

    return best
end

local function GetQuestRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommF_")
end

local function GetQuestFrame()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end

    local main = gui:FindFirstChild("Main")
    local direct = main and main:FindFirstChild("Quest")
    if direct and direct:IsA("GuiObject") then
        return direct
    end

    if main then
        local recursive = main:FindFirstChild("Quest", true)
        if recursive and recursive:IsA("GuiObject") then
            return recursive
        end
    end

    for _,obj in ipairs(gui:GetDescendants()) do
        if obj.Name == "Quest" and obj:IsA("GuiObject") then
            return obj
        end
    end

    return nil
end

local function QuestVisible()
    local quest = GetQuestFrame()
    return quest ~= nil and quest.Visible == true
end

local function GetQuestText()
    local quest = GetQuestFrame()
    if not quest then return "" end

    local parts = {}
    for _, obj in ipairs(quest:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Text ~= "" then
            table.insert(parts, obj.Text)
        end
    end

    return string.lower(table.concat(parts, " "))
end

local function QuestMatches(q)
    if not q or not QuestVisible() then return false end

    local text = GetQuestText()
    if text == "" then
        -- Some custom UIs expose only visibility. Do not loop-abandon them.
        return true
    end

    local mob = string.lower(q.Mob)
    local simplified = mob:gsub("%s*%[.*%]", "")
    return string.find(text, mob, 1, true) ~= nil
        or string.find(text, simplified, 1, true) ~= nil
end

local function AbandonCurrentQuest()
    local remote = GetQuestRemote()
    if not remote then return false end

    return pcall(function()
        remote:InvokeServer("AbandonQuest")
    end)
end

local function StartLevelQuest(q)
    if not q then return false end

    local remote = GetQuestRemote()
    local root = GetCharacterRoot()
    if not remote or not root then
        FarmState.QuestStatus = "Quest remote/root unavailable"
        return false
    end

    FarmState.QuestMob = q.Mob
    FarmState.QuestName = q.Quest
    FarmState.QuestLevel = q.Level
    FarmState.QuestPosition = q.QuestPos
    FarmState.MobPosition = q.MobPos
    FarmState.CurrentSea = q.Sea
    FarmState.TargetName = q.Mob

    if QuestVisible() and QuestMatches(q) then
        FarmState.QuestStatus = "Correct quest active"
        return true
    end

    if QuestVisible() and not QuestMatches(q) then
        FarmState.QuestStatus = "Replacing wrong quest"
        AbandonCurrentQuest()
        task.wait(0.25)
    end

    FarmState.QuestStatus = "Going to quest NPC"
    local arrived = MovementService:GoTo(q.QuestPos, 3, "Quest NPC")

    if not arrived then
        FarmState.QuestStatus = "Could not reach quest NPC"
        return false
    end

    task.wait(0.35)

    local rootAfterMove = GetCharacterRoot()
    if not rootAfterMove or (rootAfterMove.Position - q.QuestPos.Position).Magnitude > 90 then
        FarmState.QuestStatus = "Quest NPC too far"
        return false
    end

    local ok = pcall(function()
        remote:InvokeServer("StartQuest", q.Quest, q.Level)
    end)

    if ok then
        FarmState.QuestOwnedByHub = true
        FarmState.QuestSeenVisible = QuestVisible()
        FarmState.QuestRoutePending = true
        FarmState.QuestStartLevel = PlayerService:GetLevel()
        FarmState.QuestStartedAt = os.clock()
        FarmState.QuestStatus = "Quest accepted - going to mobs"
    else
        FarmState.QuestStatus = "Quest request failed"
    end

    task.wait(0.35)
    return ok
end

local function MoveToQuestMobArea(q)
    if not q or not q.MobPos then return false end
    if MovementService.Active then return false end

    FarmState.Status = "Going to mob area: " .. q.Mob
    FarmState.LastMobMove = os.clock()
    return MovementService:GoTo(q.MobPos, 18, "Mob Area")
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

local function IsLikelyFightingStyle(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool.ToolTip == "Melee" then return true end

    local n = string.lower(tool.Name)
    local names = {
        "combat","dark step","electric","water kung fu","dragon breath",
        "superhuman","death step","sharkman karate","electric claw",
        "dragon talon","godhuman","sanguine art"
    }
    for _, name in ipairs(names) do
        if string.find(n, name, 1, true) then return true end
    end
    return false
end

local function EquipFirstTool()
    local humanoid = GetCharacterHumanoid()
    if not humanoid then return nil end

    local equipped = GetEquippedTool()
    if equipped and IsLikelyFightingStyle(equipped) then
        FarmState.CurrentTool = equipped
        return equipped
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end

    local fallback = nil
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            fallback = fallback or tool
            if IsLikelyFightingStyle(tool) then
                pcall(function() humanoid:EquipTool(tool) end)
                FarmState.CurrentTool = tool
                return tool
            end
        end
    end

    -- Do not equip a random inventory item in this test build.
    FarmState.CurrentTool = nil
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

    -- Primary tool activation.
    pcall(function()
        tool:Activate()
    end)

    -- Input fallback for combat systems that listen to mouse input
    -- instead of Tool:Activate alone.
    pcall(function()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local input = game:GetService("VirtualInputManager")
        local x = math.floor(viewport.X / 2)
        local y = math.floor(viewport.Y / 2)

        input:SendMouseButtonEvent(x, y, 0, true, game, 0)
        input:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    pcall(function()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local point = Vector2.new(
            math.floor(viewport.X / 2),
            math.floor(viewport.Y / 2)
        )
        local virtualUser = game:GetService("VirtualUser")

        virtualUser:CaptureController()
        virtualUser:Button1Down(point, camera and camera.CFrame or CFrame.new())
        virtualUser:Button1Up(point, camera and camera.CFrame or CFrame.new())
    end)

    return true
end

local function MoveToTarget(target)
    local root = GetCharacterRoot()
    local targetRoot = GetTargetRoot(target)
    if not root or not targetRoot then return false end

    if not FarmState.FarmAnchor then
        FarmState.FarmAnchor = targetRoot.CFrame
    end

    -- Stay above the mob instead of orbiting around it.
    local desired = targetRoot.CFrame * CFrame.new(0, FarmState.Distance, 0)
    MovementService:GoTo(CFrame.new(desired.Position, targetRoot.Position), 0, "Farm Target")

    -- Bring Mob is anchored to the farm location, never to the player.
    if FarmState.BringMobs and FarmState.FarmAnchor then
        local anchor = FarmState.FarmAnchor
        for _, container in ipairs(FindEnemyContainers()) do
            for _, mob in ipairs(container:GetChildren()) do
                if IsValidFarmTarget(mob) then
                    local mr = GetTargetRoot(mob)
                    if mr and string.find(string.lower(mob.Name), string.lower(FarmState.TargetName), 1, true) then
                        pcall(function()
                            mr.CFrame = anchor
                            mr.AssemblyLinearVelocity = Vector3.zero
                            mr.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end
        end
    end

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
    FarmState.FarmAnchor = nil
    FarmState.Status = "Stopped"
    MovementService:Stop()

    ApplyNoClip(false)
end


--==================================================
-- SPECIAL FARMS 2.7.1
-- Built directly on the tested 2.6.5 base.
-- These modes DO NOT use quest farming.
--==================================================

local CakeSpecial = {
    BossNames = {"Cake Prince", "Cake Prince [Lv. 2300] [Raid Boss]"},
    MobNames = {"Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker"},
    BossPos = CFrame.new(-2103, 70, -12165),
    MobPoints = {
        CFrame.new(-2212.88965, 37.00510, -11969.2568),
        CFrame.new(-1693.98047, 35.21882, -12436.8438),
        CFrame.new(-1980.43750, 34.66531, -12983.8408),
        CFrame.new(-2151.37793, 51.00957, -13033.3975)
    },
    PointIndex = 1,
    LastCheck = 0
}

local BoneSpecial = {
    MobNames = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"},
    -- Rotation through the four Haunted Castle mob areas.
    Points = {
        CFrame.new(-8763.72363, 165.72299, 6159.86182),   -- Reborn Skeleton
        CFrame.new(-10144.13184, 138.62668, 5838.08887), -- Living Zombie
        CFrame.new(-9505.87207, 172.10483, 6158.99316),  -- Demonic Soul
        CFrame.new(-9582.02246, 16.25153, 6205.47852)    -- Posessed Mummy
    },
    LastCheck = 0
}

local function SpecialNameMatch(name, wantedNames)
    local n = string.lower(tostring(name or ""))
    for _, wanted in ipairs(wantedNames) do
        local w = string.lower(wanted)
        if n == w or string.find(n, w, 1, true) then
            return true
        end
    end
    return false
end

local function GetSpecialEnemy(wantedNames)
    local root = GetCharacterRoot()
    local best, bestDist = nil, math.huge

    for _, container in ipairs(FindEnemyContainers()) do
        for _, enemy in ipairs(container:GetChildren()) do
            if SpecialNameMatch(enemy.Name, wantedNames) and IsValidFarmTarget(enemy) then
                local enemyRoot = GetTargetRoot(enemy)
                if enemyRoot then
                    local d = root and (enemyRoot.Position - root.Position).Magnitude or 0
                    if d < bestDist then
                        best = enemy
                        bestDist = d
                    end
                end
            end
        end
    end

    return best
end

local function SpecialEquipAndAttack(enemy)
    if not enemy or not IsValidFarmTarget(enemy) then
        return false
    end

    FarmState.SpecialTarget = enemy.Name

    if FarmState.UseTool then
        EquipFirstTool()
    end

    MoveToTarget(enemy)
    AttackTarget(enemy)
    return true
end

local function GetCakeSpawnerText()
    local remote = GetQuestRemote()
    if not remote then
        return nil
    end

    local ok, result = pcall(function()
        return remote:InvokeServer("CakePrinceSpawner")
    end)

    if ok then
        return tostring(result or "")
    end
    return nil
end

local function ParseCakeProgress(text)
    if not text or text == "" then
        return nil, "Checking..."
    end

    local lower = string.lower(text)
    if string.find(lower, "open the portal", 1, true) then
        return 500, "500 / 500 - portal ready"
    end

    local best = nil
    for digits in string.gmatch(text, "%d+") do
        local n = tonumber(digits)
        if n and n >= 0 and n <= 500 then
            if not best or n > best then
                best = n
            end
        end
    end

    if best then
        return best, tostring(best) .. " / 500"
    end

    return nil, text
end

local function CheckBoneCount()
    local remote = GetQuestRemote()
    if not remote then return end

    local ok, result = pcall(function()
        return remote:InvokeServer("Bones", "Check")
    end)

    if ok then
        FarmState.BoneCount = tostring(result)
    end
end

local function DisableNormalQuestFarmForSpecial()
    FarmState.Enabled = false
    FarmState.AutoQuest = false
    FarmState.CurrentTarget = nil
    FarmState.FarmAnchor = nil
    MovementService:Stop()

    pcall(function()
        local remote = GetQuestRemote()
        if remote and QuestVisible() then
            remote:InvokeServer("AbandonQuest")
        end
    end)
end

local function StopSpecialFarms()
    FarmState.AutoCakePrince = false
    FarmState.AutoBone = false
    FarmState.SpecialStatus = "Idle"
    FarmState.SpecialTarget = "None"
    MovementService:Stop()
end

local function CakePrinceSpecialStep()
    if not FarmState.AutoCakePrince then return end

    local boss = GetSpecialEnemy(CakeSpecial.BossNames)
    if boss then
        FarmState.SpecialStatus = "Cake Prince spawned - attacking"
        FarmState.CakeStatus = "Boss spawned"
        SpecialEquipAndAttack(boss)
        return
    end

    -- A stored boss model means the boss exists/is about to enter Workspace.
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if SpecialNameMatch(obj.Name, CakeSpecial.BossNames) then
            FarmState.SpecialStatus = "Cake Prince detected - moving to boss"
            MovementService:GoTo(CakeSpecial.BossPos, 18, "Cake Prince")
            return
        end
    end

    if os.clock() - CakeSpecial.LastCheck >= 2 then
        CakeSpecial.LastCheck = os.clock()
        local text = GetCakeSpawnerText()
        local progress, display = ParseCakeProgress(text)
        FarmState.CakeStatus = display or "Checking..."

        if progress and progress >= 500 then
            local remote = GetQuestRemote()
            if remote then
                pcall(function()
                    remote:InvokeServer("CakePrinceSpawner")
                end)
            end
        end
    end

    local mob = GetSpecialEnemy(CakeSpecial.MobNames)
    if mob then
        FarmState.SpecialStatus = "Killing Cake mobs"
        SpecialEquipAndAttack(mob)
        return
    end

    if not MovementService.Active then
        local point = CakeSpecial.MobPoints[CakeSpecial.PointIndex]
        FarmState.SpecialStatus = "Cake mob rotation " .. CakeSpecial.PointIndex .. "/4"
        MovementService:GoTo(point, 18, "Cake mobs")
        CakeSpecial.PointIndex = (CakeSpecial.PointIndex % #CakeSpecial.MobPoints) + 1
    end
end

local function BoneSpecialStep()
    if not FarmState.AutoBone then return end

    if os.clock() - BoneSpecial.LastCheck >= 3 then
        BoneSpecial.LastCheck = os.clock()
        CheckBoneCount()
    end

    local mob = GetSpecialEnemy(BoneSpecial.MobNames)
    if mob then
        FarmState.SpecialStatus = "Haunted Castle rotation"
        SpecialEquipAndAttack(mob)
        return
    end

    if not MovementService.Active then
        local i = math.clamp(FarmState.BoneRotation, 1, #BoneSpecial.Points)
        FarmState.SpecialStatus = "Bone rotation " .. i .. "/" .. #BoneSpecial.Points
        MovementService:GoTo(BoneSpecial.Points[i], 18, "Bone farm")
        FarmState.BoneRotation = (i % #BoneSpecial.Points) + 1
    end
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

    -- A route must finish before the farm state machine advances.
    -- This prevents Quest NPC travel from being restarted every update.
    if MovementService.Active then
        FarmState.Status = MovementService.Status .. ": " .. tostring(MovementService.DestinationName)
        return
    end

    local q = nil

    if FarmState.AutoQuest then
        q = GetLevelFarmQuest()

        if not q then
            FarmState.QuestStatus = "No quest for current Sea/level"
            FarmState.Status = "Quest data unavailable"
            return
        end

        FarmState.TargetName = q.Mob
        FarmState.QuestMob = q.Mob
        FarmState.MobPosition = q.MobPos

        local visible = QuestVisible()

        -- Reference-style quest cycle:
        -- no visible quest -> go back to NPC and request it again.
        if not visible then
            if FarmState.QuestStartedAt > 0 and os.clock() - FarmState.QuestStartedAt < 2.50 then
                FarmState.QuestOwnedByHub = true
                FarmState.QuestRoutePending = false
                FarmState.QuestStatus = "Quest accepted - travelling to mobs"
                MoveToQuestMobArea(q)
                return
            end

            FarmState.QuestOwnedByHub = false
            FarmState.QuestSeenVisible = false
            FarmState.QuestRoutePending = false
            FarmState.QuestStartedAt = 0
            FarmState.CurrentTarget = nil
            FarmState.FarmAnchor = nil
            FarmState.QuestStatus = "No active quest - returning to NPC"
            StartLevelQuest(q)
            return
        end

        -- A visible but wrong quest is replaced immediately.
        if not QuestMatches(q) then
            FarmState.QuestStatus = "Wrong quest - replacing"
            AbandonCurrentQuest()
            FarmState.QuestStartedAt = 0
            FarmState.CurrentTarget = nil
            FarmState.FarmAnchor = nil
            task.wait(0.20)
            return
        end

        -- The correct quest is active. From this point the mob farm runs until
        -- the quest UI disappears; next FarmStep then returns to the NPC.
        FarmState.QuestOwnedByHub = true
        FarmState.QuestSeenVisible = true
        FarmState.QuestRoutePending = false
        FarmState.QuestStatus = "Quest active: " .. q.Mob
    end

    if not FarmState.CurrentTarget or not IsValidFarmTarget(FarmState.CurrentTarget) then
        FarmState.FarmAnchor = nil
        FarmState.CurrentTarget = GetNearestTarget()
    end

    local target = FarmState.CurrentTarget

    if not target then
        if q and q.MobPos then
            local distanceToMobArea = (root.Position - q.MobPos.Position).Magnitude

            if distanceToMobArea > math.max(FarmState.ScanRadius * 0.55, 180) then
                MoveToQuestMobArea(q)
                task.wait(0.2)
                FarmState.CurrentTarget = GetNearestTarget()
                return
            end
        end

        FarmState.Status = "At mob area - waiting for " .. tostring(FarmState.TargetName)
        return
    end

    FarmState.Status = "Farming: " .. target.Name

    if FarmState.AutoTarget then
        MoveToTarget(target)
    end

    if FarmState.UseTool then
        AttackTarget(target)
    end

    -- Quest completion watchdog:
    -- once the quest UI was observed, disappearance means the mission ended.
    -- Release ownership immediately so the next FarmStep returns to the NPC.
    if FarmState.AutoQuest and FarmState.QuestOwnedByHub and FarmState.QuestSeenVisible then
        if not QuestVisible() then
            FarmState.QuestOwnedByHub = false
            FarmState.QuestSeenVisible = false
            FarmState.QuestRoutePending = false
            FarmState.CurrentTarget = nil
            FarmState.FarmAnchor = nil
            FarmState.QuestStatus = "Quest complete - requesting next quest"
            FarmState.Status = "Quest complete"
        end
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

Section(
    FarmPage,
    "2.7.1 SPECIAL FARMS",
    "NOVO: Cake Prince + Bones ficam no topo desta página"
)

Section(
    FarmPage,
    "Special Farms",
    "Sem quests • modos separados do Auto Farm Level"
)

local SpecialFarmCard, SpecialFarmValue = Card(FarmPage, "SPECIAL STATUS", "Idle")
local CakeFarmCard, CakeFarmValue = Card(FarmPage, "CAKE PRINCE", "Checking...")
local BoneFarmCard, BoneFarmValue = Card(FarmPage, "BONES", "Checking...")

Toggle(
    FarmPage,
    "Auto Cake Prince",
    "Mata os 4 mobs da Cake Land, acompanha o spawn e ataca Cake Prince. Não usa quests.",
    false,
    function(enabled)
        if enabled then
            StopSpecialFarms()
            DisableNormalQuestFarmForSpecial()
            FarmState.AutoCakePrince = true
            FarmState.SpecialStatus = "Starting Cake Prince cycle"
            Notify("Auto Cake Prince", "Enabled - No Quest")
        else
            FarmState.AutoCakePrince = false
            MovementService:Stop()
            FarmState.SpecialStatus = "Idle"
            FarmState.SpecialTarget = "None"
            Notify("Auto Cake Prince", "Disabled")
        end
    end
)

Toggle(
    FarmPage,
    "Auto Farm Bone",
    "Rotação Haunted Castle: Reborn Skeleton, Living Zombie, Demonic Soul e Posessed Mummy. Não usa quests.",
    false,
    function(enabled)
        if enabled then
            StopSpecialFarms()
            DisableNormalQuestFarmForSpecial()
            FarmState.AutoBone = true
            FarmState.BoneRotation = 1
            FarmState.SpecialStatus = "Starting Bone rotation"
            Notify("Auto Farm Bone", "Enabled - No Quest")
        else
            FarmState.AutoBone = false
            MovementService:Stop()
            FarmState.SpecialStatus = "Idle"
            FarmState.SpecialTarget = "None"
            Notify("Auto Farm Bone", "Disabled")
        end
    end
)


Toggle(
    FarmPage,
    "Auto Farm",
    "Find the nearest valid NPC and continuously process the farm loop.",
    false,
    function(enabled)
        if enabled and (FarmState.AutoCakePrince or FarmState.AutoBone) then
            StopSpecialFarms()
        end

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
        StopSpecialFarms()
        Notify("Main Farm", "Farm parado manualmente.")
    end
)

--==================================================
-- SPECIAL FARM LOOP 2.7.1
--==================================================

FarmConnect(RunService.Heartbeat, function()
    if State.Destroyed then return end
    if not FarmState.AutoCakePrince and not FarmState.AutoBone then return end

    if not MovementService.Active then
        if FarmState.AutoCakePrince then
            CakePrinceSpecialStep()
        elseif FarmState.AutoBone then
            BoneSpecialStep()
        end
    end

    SpecialFarmValue.Text = FarmState.SpecialStatus .. " • " .. FarmState.SpecialTarget
    CakeFarmValue.Text = FarmState.CakeStatus
    BoneFarmValue.Text = FarmState.BoneCount
end)

--==================================================
-- MASTERY FARM 2.7.3w
-- Basic implementation:
-- 1) use the already-working Teleport Directory once to reach Haunted Castle;
-- 2) scan only the four Bone mobs;
-- 3) move directly to the current mob (no rise/cruise loop);
-- 4) attack until that exact mob dies, then pick the next one.
-- The structure follows the common pattern found across the reference sources,
-- but this is an independent implementation.
--==================================================

task.spawn(function()
    local M = {
        Enabled = false,
        Type = "Blox Fruit",
        KillPercent = 40,
        Status = "Idle",
        Target = nil,
        BoneIndex = 1,
        LastAttack = 0,
        LastSkill = 0,
        SkillIndex = 1,
        LastCastleTeleport = 0,
        Moving = false,
        AttackCooldown = 0.14,
        SkillCooldown = 0.60,
        CombatHeight = 11,
        CombatDistance = 8
    }

    local function toolMatches(tool, wanted)
        if not tool or not tool:IsA("Tool") then
            return false
        end

        local tip = string.lower(tostring(tool.ToolTip or ""))
        local name = string.lower(tostring(tool.Name or ""))

        if wanted == "Melee" then
            return IsLikelyFightingStyle(tool)
        elseif wanted == "Sword" then
            return tip == "sword"
                or string.find(tip, "sword", 1, true) ~= nil
        elseif wanted == "Gun" then
            return tip == "gun"
                or string.find(tip, "gun", 1, true) ~= nil
                or tool:FindFirstChild("RemoteFunctionShoot") ~= nil
        elseif wanted == "Blox Fruit" then
            return string.find(tip, "fruit", 1, true) ~= nil
                or (
                    string.find(name, "-", 1, true) ~= nil
                    and tool:FindFirstChild("Level") ~= nil
                )
        end

        return false
    end

    local function findTool(wanted)
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        if wanted == "Blox Fruit" then
            local data = LocalPlayer:FindFirstChild("Data")
            local fruitValue = data and data:FindFirstChild("DevilFruit")

            if fruitValue and tostring(fruitValue.Value) ~= "" then
                local fruitName = tostring(fruitValue.Value)

                if character then
                    local direct = character:FindFirstChild(fruitName)
                    if direct and direct:IsA("Tool") then
                        return direct
                    end
                end

                if backpack then
                    local direct = backpack:FindFirstChild(fruitName)
                    if direct and direct:IsA("Tool") then
                        return direct
                    end
                end
            end
        end

        if character then
            for _, tool in ipairs(character:GetChildren()) do
                if toolMatches(tool, wanted) then
                    return tool
                end
            end
        end

        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if toolMatches(tool, wanted) then
                    return tool
                end
            end
        end

        return nil
    end

    local function equip(tool)
        if not tool then
            return nil
        end

        local humanoid = GetCharacterHumanoid()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        if humanoid and backpack and tool.Parent == backpack then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
        end

        return tool
    end

    local function findBone()
        local root = GetCharacterRoot()
        local best = nil
        local bestDistance = math.huge

        for _, container in ipairs(FindEnemyContainers()) do
            for _, enemy in ipairs(container:GetChildren()) do
                if IsAlive(enemy)
                    and SpecialNameMatch(enemy.Name, BoneSpecial.MobNames)
                then
                    local enemyRoot = GetTargetRoot(enemy)

                    if enemyRoot then
                        local distance = root
                            and (enemyRoot.Position - root.Position).Magnitude
                            or 0

                        if distance < bestDistance then
                            best = enemy
                            bestDistance = distance
                        end
                    end
                end
            end
        end

        return best
    end

    local function directMove(targetCFrame, yOffset, name)
        if M.Moving or not M.Enabled then
            return false
        end

        local root = GetCharacterRoot()
        if not root or not targetCFrame then
            return false
        end

        M.Moving = true

        MovementService:Stop()
        MovementService.Active = true
        MovementService.Target = targetCFrame
        MovementService.DestinationName = name or "Mastery"
        MovementService:SetCollision(false)

        local destination = targetCFrame * CFrame.new(0, yOffset or 10, 0)

        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        -- IMPORTANT: one direct tween only.
        -- No "Rising", no fixed-altitude loop, no repeated upward movement.
        local ok = MovementService:TweenRoot(root, destination)

        MovementService:SetCollision(true)
        MovementService.Active = false
        MovementService.Tween = nil
        M.Moving = false

        return ok
    end

    local function m1(tool)
        if not tool then
            return
        end

        pcall(function()
            tool:Activate()
        end)

        pcall(function()
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local x = math.floor(viewport.X / 2)
            local y = math.floor(viewport.Y / 2)
            local input = game:GetService("VirtualInputManager")

            input:SendMouseButtonEvent(x, y, 0, true, game, 0)
            input:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end

    local function skill(tool, targetRoot)
        if not tool or not targetRoot then
            return false
        end

        if os.clock() - M.LastSkill < M.SkillCooldown then
            return false
        end

        pcall(function()
            local mousePos = tool:FindFirstChild("MousePos")
            if mousePos then
                mousePos.Value = targetRoot.Position
            end
        end)

        local order = {
            {Enum.KeyCode.Z, "Z"},
            {Enum.KeyCode.X, "X"},
            {Enum.KeyCode.C, "C"},
            {Enum.KeyCode.V, "V"}
        }

        local selected = order[((M.SkillIndex - 1) % #order) + 1]
        M.SkillIndex = M.SkillIndex + 1
        M.LastSkill = os.clock()

        pcall(function()
            local input = game:GetService("VirtualInputManager")
            input:SendKeyEvent(true, selected[1], false, game)
            task.wait(0.08)
            input:SendKeyEvent(false, selected[1], false, game)
        end)

        return true
    end

    local function attack(target)
        if not target or not IsAlive(target) then
            return false
        end

        local targetRoot = GetTargetRoot(target)
        local humanoid = target:FindFirstChildOfClass("Humanoid")
        local root = GetCharacterRoot()

        if not targetRoot or not humanoid or not root then
            return false
        end

        local desiredCFrame =
            targetRoot.CFrame
            * CFrame.new(0, M.CombatHeight, M.CombatDistance)

        local distance = (root.Position - desiredCFrame.Position).Magnitude

        -- Stay slightly above and a little away from the NPC,
        -- instead of standing on top of it.
        if distance > 20 then
            M.Status = "Going to " .. target.Name
            directMove(desiredCFrame, 0, "Mastery Mob")
            return true
        end

        -- If we are too close, re-position to the safe attack offset.
        if distance < 6 and not M.Moving then
            M.Status = "Adjusting position"
            directMove(desiredCFrame, 0, "Mastery Adjust")
            return true
        end

        -- Soft position lock while attacking:
        -- keep the character hovering above / slightly away from the mob.
        pcall(function()
            root.CFrame = desiredCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        local wanted = M.Type
        local threshold = humanoid.MaxHealth * (M.KillPercent / 100)

        -- Sword/Gun/Fruit: weaken with Melee, then finish with selected type.
        if M.Type ~= "Melee" and humanoid.Health > threshold then
            wanted = "Melee"
            M.Status = "Weakening " .. target.Name
        else
            M.Status = "Attacking " .. target.Name .. " with " .. M.Type
        end

        local tool = findTool(wanted)

        if not tool then
            M.Status = "No " .. wanted .. " tool found"
            return true
        end

        tool = equip(tool)

        -- Gun direct shot fallback when available.
        if wanted == "Gun" then
            pcall(function()
                local shoot = tool:FindFirstChild("RemoteFunctionShoot")
                if shoot and shoot:IsA("RemoteFunction") then
                    shoot:InvokeServer(targetRoot.Position, targetRoot)
                end
            end)
        end

        if os.clock() - M.LastAttack >= M.AttackCooldown then
            M.LastAttack = os.clock()
            m1(tool)
        end

        if wanted == M.Type and M.Type ~= "Melee" then
            skill(tool, targetRoot)
        end

        return true
    end

    -- Simple UI requested by the user.
    Section(
        FarmPage,
        "Mastery Farm",
        "Bones / Haunted Castle"
    )

    local masteryStatusCard, masteryStatusValue =
        Card(FarmPage, "MASTERY STATUS", "Idle")

    local methodHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, FarmPage)

    Corner(methodHolder, 11)
    Stroke(methodHolder, Theme.Secondary, 0.30)

    local methodButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, methodHolder)

    local methodLabel = Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -56, 1, 0),
        BackgroundTransparency = 1,
        Text = "Select Method Farm Mastery: Blox Fruit",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    }, methodHolder)

    local methodArrow = Create("TextLabel", {
        Position = UDim2.new(1, -34, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        BackgroundTransparency = 1,
        Text = "›",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Theme.Text
    }, methodHolder)

    local methodList = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Visible = false
    }, FarmPage)

    Corner(methodList, 11)
    Stroke(methodList, Theme.Secondary, 0.30)

    Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, methodList)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    }, methodList)

    local methodOpen = false

    Connect(methodButton.MouseButton1Click, function()
        methodOpen = not methodOpen
        methodList.Visible = methodOpen
        methodArrow.Text = methodOpen and "⌄" or "›"
    end)

    for _, option in ipairs({"Blox Fruit", "Gun", "Sword", "Melee"}) do
        local item = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Secondary,
            BorderSizePixel = 0,
            Text = option,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Theme.Text,
            AutoButtonColor = false
        }, methodList)

        Corner(item, 8)
        AddHoverEffect(item)

        Connect(item.MouseButton1Click, function()
            M.Type = option
            M.Target = nil
            M.SkillIndex = 1
            M.LastSkill = 0
            methodOpen = false
            methodList.Visible = false
            methodArrow.Text = "›"
            methodLabel.Text = "Select Method Farm Mastery: " .. option
            Notify("Mastery", "Method: " .. option)
        end)
    end

    ValueBox(
        FarmPage,
        "Health %",
        M.KillPercent,
        function(value)
            M.KillPercent = math.clamp(value, 5, 90)
        end
    )

    ValueBox(
        FarmPage,
        "Combat Height",
        M.CombatHeight,
        function(value)
            M.CombatHeight = math.clamp(value, 6, 20)
        end
    )

    ValueBox(
        FarmPage,
        "Combat Distance",
        M.CombatDistance,
        function(value)
            M.CombatDistance = math.clamp(value, 4, 16)
        end
    )

    Toggle(
        FarmPage,
        "Farm Mastery",
        "Go to Haunted Castle Bones and attack the mobs.",
        false,
        function(enabled)
            M.Enabled = enabled
            M.Target = nil
            M.BoneIndex = 1
            M.LastCastleTeleport = 0
            M.Moving = false

            if enabled then
                FarmState.Enabled = false
                FarmState.AutoCakePrince = false
                FarmState.AutoBone = false
                FarmState.CurrentTarget = nil
                FarmState.FarmAnchor = nil
                MovementService:Stop()
                M.Status = "Starting mastery"
            else
                MovementService:Stop()
                M.Status = "Idle"
            end
        end
    )

    -- Sequential worker: one movement/attack decision at a time.
    -- This avoids Heartbeat repeatedly restarting movement.
    while not State.Destroyed do
        task.wait(0.15)

        masteryStatusValue.Text = M.Status

        if M.Enabled and not M.Moving then
            local root = GetCharacterRoot()

            if root then
                local castle = IslandCFrames["Sea 3"]["Haunted Castle"]
                local castleDistance = (root.Position - castle.Position).Magnitude

                -- Use the exact Teleport Directory routine the user already confirmed works.
                if castleDistance > 1800 then
                    if not MovementService.Active
                        and os.clock() - M.LastCastleTeleport > 6
                    then
                        M.LastCastleTeleport = os.clock()
                        M.Status = "Going to Haunted Castle"
                        TeleportToIsland("Sea 3", "Haunted Castle")
                    end
                elseif not MovementService.Active then
                    if M.Target
                        and (
                            not M.Target.Parent
                            or not IsAlive(M.Target)
                            or not SpecialNameMatch(
                                M.Target.Name,
                                BoneSpecial.MobNames
                            )
                        )
                    then
                        M.Target = nil
                    end

                    if not M.Target then
                        M.Target = findBone()
                    end

                    if M.Target then
                        attack(M.Target)
                    else
                        -- No live Bone mob currently found:
                        -- move directly to the next known Bone spawn point.
                        local point = BoneSpecial.Points[M.BoneIndex]
                        M.Status =
                            "Searching Bones " ..
                            tostring(M.BoneIndex) ..
                            "/" ..
                            tostring(#BoneSpecial.Points)

                        directMove(point, 12, "Bone Spawn")

                        M.BoneIndex =
                            (M.BoneIndex % #BoneSpecial.Points) + 1
                    end
                end
            else
                M.Status = "Waiting for character"
            end
        end
    end
end)

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
    if QuestStatusValue then QuestStatusValue.Text = FarmState.QuestStatus or "Idle" end
    if QuestMobValue then QuestMobValue.Text = FarmState.QuestMob or "Auto by level"
        QuestSeaValue.Text = FarmState.CurrentSea and ("Sea " .. tostring(FarmState.CurrentSea)) or "Auto" end

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

local QuestStatusCard, QuestStatusValue = Card(QuestPage, "QUEST STATUS", "Idle")
local QuestMobCard, QuestMobValue = Card(QuestPage, "QUEST MOB", "Auto by level")
local QuestSeaCard, QuestSeaValue = Card(QuestPage, "SEA", "Auto")
local QuestRouteCard, QuestRouteValue = Card(QuestPage, "ROUTE", "Quest NPC -> Mob Spawn")


Toggle(
    QuestPage,
    "Auto Quest",
    "Usa o nível atual para selecionar e iniciar a quest do Level Farm.",
    true,
    function(enabled)
        FarmState.AutoQuest = enabled
        FarmState.CurrentTarget = nil
        FarmState.FarmAnchor = nil
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
    "Auto Boss",
    "Refresh the server, select a live boss, then enable Auto Farm Boss."
)

--==================================================
-- MISC
--==================================================

local MiscPage = PageService:Create("Misc")

Section(
    MiscPage,
    "Movement Utilities",
    "Utilidades gerais de movimentação"
)

Toggle(
    MiscPage,
    "Water Walk",
    "Permite andar sobre a água sem afundar.",
    false,
    function(enabled)
        WaterWalkService:SetEnabled(enabled)
        Notify("Water Walk", enabled and "Enabled" or "Disabled")
    end
)


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

    Logo.BackgroundColor3 = Theme.Secondary
    Logo.TextColor3 = Theme.Accent

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
    "Raids",
    "Combat",
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
    Raids = "◇",
    Combat = "⚔",
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
    Size = UDim2.new(0, 60, 0, 60),
    Position = UDim2.new(0, 25, 0.5, -30),
    BackgroundColor3 = Theme.Card,
    Text = "F",
    Font = Enum.Font.GothamBlack,
    TextSize = 25,
    TextColor3 = Theme.Accent,
    Visible = false,
    AutoButtonColor = false
}, ScreenGui)

Corner(FloatingButton, 30)
Stroke(FloatingButton, Theme.Accent, 0.08)
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
    "2.5.0 carregado com sucesso."
)

print(
    "[Floquitave] Version "
    .. Config.Version
    .. " loaded."
)

-- ============================================================
-- FLOQUITAVE 2.7.3x - MASTERY COMBAT OFFSET
-- Only LIVE bosses are shown in the dropdown.
-- Encapsulated to protect the main chunk register limit.
-- ============================================================
task.spawn(function()
    local S = {
        Enabled = false,
        KillAll = false,
        Selected = nil,
        Alive = {},
        Open = false,
        Status = "Press Refresh Boss"
    }

    local KNOWN = {
        "The Gorilla King","Bobby","The Saw","Yeti","Mob Leader","Vice Admiral","Warden",
        "Chief Warden","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God",
        "Cyborg","Saber Expert","Ice Admiral","Greybeard",
        "Diamond","Jeremy","Fajita","Don Swan","Smoke Admiral","Cursed Captain",
        "Darkbeard","Order","Awakened Ice Admiral","Tide Keeper",
        "Stone","Island Empress","Kilo Admiral","Captain Elephant","Beautiful Pirate",
        "rip_indra True Form","Longma","Soul Reaper","Cake Queen","Cake Prince","Dough King"
    }

    -- Spawn routes taken from the supplied boss reference.
    -- Unknown/custom bosses still fall back to their ReplicatedStorage model.
    local BOSS_ROUTE = {
        ["The Gorilla King"] = CFrame.new(-1088.75977,8.13463783,-488.559906),
        ["Bobby"] = CFrame.new(-1087.37610,46.94941,4040.14624),
        ["The Saw"] = CFrame.new(-784.89716,72.42738,1603.58228),
        ["Yeti"] = CFrame.new(1218.79565,138.01184,-1488.02625),
        ["Mob Leader"] = CFrame.new(-2844.73071,7.41805,5356.67236),
        ["Vice Admiral"] = CFrame.new(-5006.54541,88.03208,4353.16211),
        ["Saber Expert"] = CFrame.new(-1458.89502,29.88703,-50.63356),
        ["Warden"] = CFrame.new(5278.04932,2.15167,944.10193),
        ["Chief Warden"] = CFrame.new(5206.92578,0.99775,814.97675),
        ["Swan"] = CFrame.new(5325.09619,7.03907,719.57068),
        ["Magma Admiral"] = CFrame.new(-5765.89697,82.92065,8718.30469),
        ["Fishman Lord"] = CFrame.new(61260.15234,30.95088,1193.43298),
        ["Wysper"] = CFrame.new(-7866.13330,5576.43115,-546.74817),
        ["Thunder God"] = CFrame.new(-7994.98438,5761.02539,-2088.64795),
        ["Cyborg"] = CFrame.new(6094.02490,73.77005,3825.73486),
        ["Ice Admiral"] = CFrame.new(1266.08948,26.17579,-1399.57678),
        ["Greybeard"] = CFrame.new(-5081.34521,85.22164,4257.35889),

        ["Cursed Captain"] = CFrame.new(916.92859,181.09277,33422),
        ["Darkbeard"] = CFrame.new(3677.08203,62.75194,-3144.83325),
        ["Order"] = CFrame.new(-6217.20215,28.04765,-5053.13574),

        ["Stone"] = CFrame.new(-1027.65125,92.40417,6578.85303),
        ["Island Empress"] = CFrame.new(5543.86328,668.97400,199.03418),
        ["Kilo Admiral"] = CFrame.new(2764.22339,432.46155,-7144.45801),
        ["Captain Elephant"] = CFrame.new(-13376.75781,433.28690,-8071.39258),
        ["Longma"] = CFrame.new(-10171.70510,406.98200,-9552.31738),
        ["Soul Reaper"] = CFrame.new(-9524.78906,315.80429,6655.71924),
        ["rip_indra True Form"] = CFrame.new(-5415.39209,505.74133,-2814.01660),
        ["Cake Prince"] = CFrame.new(-2103,70,-12165)
    }

    local function valid(model)
        if not model or not model:IsA("Model") then return false end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        return hum ~= nil and root ~= nil and hum.Health > 0
    end

    local function enemies()
        return workspace:FindFirstChild("Enemies")
    end

    local RS = game:GetService("ReplicatedStorage")

    local function normalizeBossName(raw)
        -- Keep the exact replicated model name for selection/farming.
        return tostring(raw or "")
    end

    local function looksLikeBoss(model)
        if not model or not model:IsA("Model") then return false end

        local n = string.lower(model.Name)
        if string.find(n, "boss", 1, true) then return true end

        -- Some boss templates use short names without "[Boss]" in the model name.
        for _,base in ipairs(KNOWN) do
            if model.Name == base or string.sub(model.Name, 1, #base) == base then
                return true
            end
        end
        return false
    end

    local function liveModel(model)
        if not model or not model:IsA("Model") then return false end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        return hum ~= nil and root ~= nil and hum.Health > 0
    end

    local function bossBaseMatches(modelName, selectedName)
        if modelName == selectedName then return true end

        -- Allows a UI selection such as "Stone [Lv. 1550] [Boss]"
        -- to still match a model named "Stone", and vice versa.
        for _,base in ipairs(KNOWN) do
            local a = string.sub(modelName, 1, #base) == base
            local b = string.sub(selectedName, 1, #base) == base
            if a and b then return true end
        end
        return false
    end

    local function findBoss(name)
        local folder = enemies()
        if not folder or not name then return nil end

        for _,model in ipairs(folder:GetDescendants()) do
            if model:IsA("Model") and bossBaseMatches(model.Name, name) and liveModel(model) then
                return model
            end
        end
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and bossBaseMatches(model.Name, name) and liveModel(model) then
                return model
            end
        end
        return nil
    end

    local function addUnique(list, seen, name)
        name = normalizeBossName(name)
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end

    local function scan()
        table.clear(S.Alive)
        local seen = {}

        -- Reference-compatible detection:
        -- 1) active bosses currently in Workspace.Enemies
        local folder = enemies()
        if folder then
            for _,model in ipairs(folder:GetDescendants()) do
                if looksLikeBoss(model) and liveModel(model) then
                    addUnique(S.Alive, seen, model.Name)
                end
            end
            for _,model in ipairs(folder:GetChildren()) do
                if looksLikeBoss(model) and liveModel(model) then
                    addUnique(S.Alive, seen, model.Name)
                end
            end
        end

        -- 2) replicated boss models. The reference hubs supplied by the user
        -- also build/refresh their boss selector from ReplicatedStorage.
        -- This catches bosses that the server exposes there even when the
        -- Workspace copy is not currently streamed to this client.
        for _,model in ipairs(RS:GetChildren()) do
            if looksLikeBoss(model) then
                addUnique(S.Alive, seen, model.Name)
            end
        end

        table.sort(S.Alive)
    end

    local _, statusValue = Card(CombatPage, "BOSS STATUS", "Press Refresh Boss")

    -- Select Boss row, visually similar to the reference.
    local selectorHolder = Create("Frame", {
        Size = UDim2.new(1,0,0,48),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0
    }, CombatPage)
    Corner(selectorHolder, 10)
    Stroke(selectorHolder, Theme.Secondary, 0.3)

    local selector = Create("TextButton", {
        Position = UDim2.new(0,10,0,7),
        Size = UDim2.new(1,-20,0,34),
        BackgroundColor3 = Theme.Secondary,
        Text = "Select Boss:   ▼",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    }, selectorHolder)
    Corner(selector, 7)

    -- Expandable list directly below the selector.
    local menu = Create("Frame", {
        Size = UDim2.new(1,0,0,0),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false
    }, CombatPage)
    Corner(menu, 10)
    Stroke(menu, Theme.Secondary, 0.3)

    local scroll = Create("ScrollingFrame", {
        Position = UDim2.new(0,8,0,8),
        Size = UDim2.new(1,-16,1,-16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0,0,0,0)
    }, menu)

    local layout = Create("UIListLayout", {
        Padding = UDim.new(0,3),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, scroll)

    local function closeMenu()
        S.Open = false
        menu.Visible = false
        menu.Size = UDim2.new(1,0,0,0)
        selector.Text = "Select Boss: " .. (S.Selected or "") .. "   ▼"
    end

    local function rebuildMenu()
        for _,child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        if #S.Alive == 0 then
            Create("TextLabel", {
                Size = UDim2.new(1,-4,0,30),
                BackgroundTransparency = 1,
                Text = "No live boss found",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left
            }, scroll)
        else
            for _,bossName in ipairs(S.Alive) do
                local name = bossName
                local option = Create("TextButton", {
                    Size = UDim2.new(1,-4,0,30),
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Text = name,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false
                }, scroll)
                Corner(option, 5)
                AddHoverEffect(option)

                Connect(option.MouseButton1Click, function()
                    S.Selected = name
                    S.Status = "Selected: " .. name
                    statusValue.Text = S.Status
                    closeMenu()
                end)
            end
        end

        task.defer(function()
            scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 8)
        end)
    end

    Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 8)
    end)

    Connect(selector.MouseButton1Click, function()
        if S.Open then
            closeMenu()
            return
        end

        rebuildMenu()
        S.Open = true
        menu.Visible = true
        local wantedHeight = math.clamp((#S.Alive * 33) + 16, 50, 210)
        menu.Size = UDim2.new(1,0,0,wantedHeight)
        selector.Text = "Select Boss: " .. (S.Selected or "") .. "   ▲"
    end)

    ActionButton(CombatPage, "Refresh Boss", function()
        scan()

        rebuildMenu()
        if #S.Alive > 0 then
            S.Status = "Found " .. tostring(#S.Alive) .. " boss(es)"
        elseif not enemies() then
            S.Status = "Workspace.Enemies not found"
        else
            S.Status = "No boss found"
        end

        statusValue.Text = S.Status
        selector.Text = "Select Boss: " .. (S.Selected or "") .. "   ▼"
        Notify("Boss Farm", S.Status)
    end)

    Toggle(
        CombatPage,
        "Auto Farm Boss",
        "Automatically attack the selected live boss",
        false,
        function(enabled)
            S.Enabled = enabled

            if enabled then
                S.KillAll = false
                FarmState.Enabled = false
                FarmState.AutoCakePrince = false
                FarmState.AutoBone = false
                FarmState.CurrentTarget = nil
                FarmState.FarmAnchor = nil
                MovementService:Stop()
                if S.Selected then
                    S.Status = "Auto Farm ON: " .. S.Selected
                else
                    S.Status = "Select a live boss first"
                end
            else
                S.Status = "Auto Farm Boss OFF"
                MovementService:Stop()
            end

            statusValue.Text = S.Status
        end
    )

    Toggle(
        CombatPage,
        "Kill All Boss",
        "Kill detected active bosses one by one",
        false,
        function(enabled)
            S.KillAll = enabled
            if enabled then
                S.Enabled = false
                FarmState.Enabled = false
                FarmState.AutoCakePrince = false
                FarmState.AutoBone = false
                FarmState.CurrentTarget = nil
                FarmState.FarmAnchor = nil
                MovementService:Stop()
                scan()
                S.Status = "Kill All Boss ON"
            else
                S.Status = "Kill All Boss OFF"
                MovementService:Stop()
            end
            statusValue.Text = S.Status
        end
    )

    -- Boss combat intentionally does NOT use AttackTarget().
    -- AttackTarget() validates against FarmState.TargetName, which belongs to
    -- the normal level farm and can reject a perfectly valid boss.
    local function bossRoot(target)
        return target and (
            target:FindFirstChild("HumanoidRootPart")
            or target:FindFirstChild("UpperTorso")
            or target:FindFirstChild("Torso")
        )
    end

    local function bossAlive(target)
        if not target or not target.Parent then return false end
        local hum = target:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0 and bossRoot(target) ~= nil
    end

    local function storedBoss(name)
        if not name then return nil end
        for _,model in ipairs(RS:GetChildren()) do
            if model:IsA("Model") and bossBaseMatches(model.Name, name) then
                local root = bossRoot(model)
                if root then return model, root end
            end
        end
        return nil
    end

    local function bossDirectTravel(destination, label)
        local me = GetCharacterRoot()
        if not me or not destination then return false end
        if MovementService.TeleportPriority then return false end

        MovementService:Stop()
        MovementService.Active = true
        MovementService.DestinationName = label or "Boss"
        MovementService.Status = "Boss travel"
        MovementService:SetCollision(false)

        local target = destination * CFrame.new(0, 12, 0)
        local ok = MovementService:TweenRoot(me, target)

        MovementService:SetCollision(true)
        MovementService.Active = false
        MovementService.Status = ok and "Arrived" or "Failed"
        return ok
    end

    local function travelToStoredBoss(name)
        local destination = nil

        for base,cf in pairs(BOSS_ROUTE) do
            if bossBaseMatches(base, name) then
                destination = cf
                break
            end
        end

        if not destination then
            local model, root = storedBoss(name)
            destination = root and root.CFrame or nil
        end

        if not destination then return false end

        S.Status = "Travelling to boss: " .. name
        statusValue.Text = S.Status
        return bossDirectTravel(destination, "Boss Spawn:" .. name)
    end

    local function bossAttack(target)
        if not bossAlive(target) then return false end

        local tool = GetEquippedTool()
        if not tool or not IsLikelyFightingStyle(tool) then
            tool = EquipFirstTool()
        end
        if not tool then
            S.Status = "Boss found - no fighting style equipped"
            statusValue.Text = S.Status
            return false
        end

        pcall(function()
            tool:Activate()
        end)
        return true
    end

    local function bossMoveAndFight(target)
        if not bossAlive(target) then return false end

        local me = GetCharacterRoot()
        local tr = bossRoot(target)
        if not me or not tr then return false end

        local distance = (me.Position - tr.Position).Magnitude

        if distance > 42 then
            local destination = CFrame.new(
                (tr.CFrame * CFrame.new(0, FarmState.Distance, 0)).Position,
                tr.Position
            )
            bossDirectTravel(destination, "Boss Target:" .. target.Name)
            return true
        end

        if MovementService.TeleportPriority then return false end
            MovementService:Stop()

        -- Keep the player in the same above-target position used by the working
        -- normal/special farms, but without normal-farm target validation.
        pcall(function()
            me.CFrame = CFrame.new(
                (tr.CFrame * CFrame.new(0, FarmState.Distance, 0)).Position,
                tr.Position
            )
        end)

        bossAttack(target)
        return true
    end

    -- Initial scan so opening Select Boss already has useful data.
    scan()
    rebuildMenu()

    -- Low-frequency worker: avoids doing boss scans/movement every rendered frame.
    task.spawn(function()
        local currentAll = nil
        local currentAllName = nil
        local allIndex = 1

        while not State.Destroyed do
            task.wait(0.20)

            if S.Enabled and S.Selected then
                local target = findBoss(S.Selected)

                if target then
                    S.Status = "Farming: " .. S.Selected
                    statusValue.Text = S.Status

                    -- MoveToTarget is blocking while travelling. Calling it here,
                    -- instead of every Heartbeat, lets the tween actually finish.
                    bossMoveAndFight(target)
                else
                    if not travelToStoredBoss(S.Selected) then
                        S.Status = "Waiting for active boss: " .. S.Selected
                        statusValue.Text = S.Status
                    end
                end

            elseif S.KillAll then
                if currentAll and not bossAlive(currentAll) then
                    currentAll = nil
                    currentAllName = nil
                    allIndex += 1
                end

                if not currentAllName then
                    scan()
                    if #S.Alive > 0 then
                        if allIndex > #S.Alive then allIndex = 1 end
                        currentAllName = S.Alive[allIndex]
                    end
                end

                if currentAllName and not currentAll then
                    currentAll = findBoss(currentAllName)
                end

                if currentAll then
                    S.Status = "Kill All: " .. currentAllName
                    statusValue.Text = S.Status
                    bossMoveAndFight(currentAll)
                elseif currentAllName then
                    if not travelToStoredBoss(currentAllName) then
                        S.Status = "Kill All: waiting for " .. currentAllName
                        statusValue.Text = S.Status
                        currentAllName = nil
                        allIndex += 1
                    end
                else
                    S.Status = "Kill All: waiting for active boss"
                    statusValue.Text = S.Status
                    task.wait(0.85)
                end
            end
        end
    end)
end)
