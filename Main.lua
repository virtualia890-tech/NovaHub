--[[
    FLOQUITAVE 1.0
    UI Hub / Modular Foundation

    Mantido:
    - Home
    - Main Farm
    - Quest
    - Raids
    - Combat
    - Teleport
    - Player
    - Server
    - Misc
    - Settings
    - About
    - FPS / Ping / Uptime
    - WalkSpeed / JumpPower
    - Themes
    - UI Scale
    - Search
    - Minimize / Floating Button

    Teleport:
    - Sea 1
    - Sea 2
    - Sea 3
    - Mapas expansíveis
    - Sem duplicação de páginas
]]

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Name = "Floquitave",
    Version = "1.0",

    Animations = true,
    Notifications = true,

    Theme = "Dark",
    Scale = 1,

    WalkSpeed = 16,
    JumpPower = 50
}

--==================================================
-- STATE
--==================================================

local State = {
    CurrentPage = "Home",
    Minimized = false,
    Destroyed = false,

    SearchText = "",

    OpenSea = nil,

    FPS = 0,
    Ping = 0,

    SessionStart = os.clock()
}

local Connections = {}
local Pages = {}
local PageButtons = {}

--==================================================
-- THEMES
--==================================================

local Themes = {

    Dark = {
        Background = Color3.fromRGB(17,17,23),
        Sidebar = Color3.fromRGB(13,13,18),
        Topbar = Color3.fromRGB(23,23,31),
        Card = Color3.fromRGB(25,25,34),
        Button = Color3.fromRGB(32,32,43),

        Text = Color3.fromRGB(240,240,245),
        SubText = Color3.fromRGB(150,150,165),

        Accent = Color3.fromRGB(115,90,255)
    },

    Light = {
        Background = Color3.fromRGB(235,235,240),
        Sidebar = Color3.fromRGB(220,220,228),
        Topbar = Color3.fromRGB(245,245,248),
        Card = Color3.fromRGB(250,250,252),
        Button = Color3.fromRGB(225,225,232),

        Text = Color3.fromRGB(30,30,35),
        SubText = Color3.fromRGB(100,100,110),

        Accent = Color3.fromRGB(100,75,220)
    },

    Purple = {
        Background = Color3.fromRGB(23,18,30),
        Sidebar = Color3.fromRGB(17,13,23),
        Topbar = Color3.fromRGB(31,23,40),
        Card = Color3.fromRGB(36,26,47),
        Button = Color3.fromRGB(46,32,59),

        Text = Color3.fromRGB(245,240,250),
        SubText = Color3.fromRGB(165,145,175),

        Accent = Color3.fromRGB(170,90,255)
    },

    Blue = {
        Background = Color3.fromRGB(17,22,31),
        Sidebar = Color3.fromRGB(12,17,25),
        Topbar = Color3.fromRGB(23,30,41),
        Card = Color3.fromRGB(25,34,46),
        Button = Color3.fromRGB(31,42,57),

        Text = Color3.fromRGB(240,245,250),
        SubText = Color3.fromRGB(145,160,175),

        Accent = Color3.fromRGB(70,145,255)
    },

    Red = {
        Background = Color3.fromRGB(28,18,21),
        Sidebar = Color3.fromRGB(21,13,16),
        Topbar = Color3.fromRGB(38,23,27),
        Card = Color3.fromRGB(43,25,29),
        Button = Color3.fromRGB(55,31,36),

        Text = Color3.fromRGB(250,240,240),
        SubText = Color3.fromRGB(175,145,150),

        Accent = Color3.fromRGB(255,75,90)
    },

    Green = {
        Background = Color3.fromRGB(17,25,20),
        Sidebar = Color3.fromRGB(12,19,15),
        Topbar = Color3.fromRGB(22,34,26),
        Card = Color3.fromRGB(25,39,30),
        Button = Color3.fromRGB(31,49,38),

        Text = Color3.fromRGB(240,250,242),
        SubText = Color3.fromRGB(145,170,150),

        Accent = Color3.fromRGB(65,200,120)
    },

    Cyan = {
        Background = Color3.fromRGB(15,24,27),
        Sidebar = Color3.fromRGB(11,18,21),
        Topbar = Color3.fromRGB(20,34,38),
        Card = Color3.fromRGB(23,40,44),
        Button = Color3.fromRGB(29,49,54),

        Text = Color3.fromRGB(238,250,250),
        SubText = Color3.fromRGB(145,175,178),

        Accent = Color3.fromRGB(55,205,220)
    },

    Midnight = {
        Background = Color3.fromRGB(9,12,22),
        Sidebar = Color3.fromRGB(6,9,17),
        Topbar = Color3.fromRGB(13,18,31),
        Card = Color3.fromRGB(17,23,39),
        Button = Color3.fromRGB(23,31,51),

        Text = Color3.fromRGB(235,240,255),
        SubText = Color3.fromRGB(135,150,175),

        Accent = Color3.fromRGB(85,125,255)
    }
}

local Theme = Themes[Config.Theme]

--==================================================
-- TELEPORT DATA
--==================================================

local TeleportLocations = {

    ["Sea 1"] = {
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
-- HELPERS
--==================================================

local function AddConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local character = GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function GetLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local level = leaderstats:FindFirstChild("Level")

        if level then
            return level.Value
        end
    end

    return "N/A"
end

local function GetBeli()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local beli = leaderstats:FindFirstChild("Beli")

        if beli then
            return beli.Value
        end
    end

    return "N/A"
end

local function GetFragments()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")

    if leaderstats then
        local fragments = leaderstats:FindFirstChild("Fragments")

        if fragments then
            return fragments.Value
        end
    end

    return "N/A"
end

local function GetRace()
    local character = GetCharacter()

    if character then
        local race = character:FindFirstChild("Race")

        if race then
            return tostring(race.Value)
        end
    end

    return "N/A"
end

local function GetSea()
    local placeId = game.PlaceId

    if placeId == 2753915549 then
        return "Sea 1"
    elseif placeId == 4442272183 then
        return "Sea 2"
    elseif placeId == 7449423635 then
        return "Sea 3"
    end

    return "Unknown"
end

local function GetPing()
    local success, result = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)

    if success then
        return math.floor(result)
    end

    return 0
end

local function FormatTime(seconds)
    seconds = math.floor(seconds)

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")

Gui.Name = "Floquitave"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    Gui.Parent = game:GetService("CoreGui")
end)

if not Gui.Parent then
    Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- MAIN
--==================================================

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.Size = UDim2.fromOffset(920,590)
Main.Position = UDim2.new(0.5,-460,0.5,-295)

Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0

Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,12)
MainCorner.Parent = Main

--==================================================
-- TOPBAR
--==================================================

local Topbar = Instance.new("Frame")

Topbar.Size = UDim2.new(1,0,0,58)

Topbar.BackgroundColor3 = Theme.Topbar
Topbar.BorderSizePixel = 0

Topbar.Parent = Main

local Title = Instance.new("TextLabel")

Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(18,0)
Title.Size = UDim2.fromOffset(180,58)

Title.Text = Config.Name
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Theme.Text

Title.TextXAlignment = Enum.TextXAlignment.Left

Title.Parent = Topbar

local Version = Instance.new("TextLabel")

Version.BackgroundTransparency = 1
Version.Position = UDim2.fromOffset(110,1)
Version.Size = UDim2.fromOffset(80,56)

Version.Text = "1.0"
Version.Font = Enum.Font.Gotham
Version.TextSize = 11
Version.TextColor3 = Theme.SubText

Version.TextXAlignment = Enum.TextXAlignment.Left

Version.Parent = Topbar

--==================================================
-- SEARCH
--==================================================

local SearchBox = Instance.new("TextBox")

SearchBox.Name = "Search"

SearchBox.Size = UDim2.fromOffset(165,34)
SearchBox.Position = UDim2.new(1,-285,0,12)

SearchBox.BackgroundColor3 = Theme.Button
SearchBox.BorderSizePixel = 0

SearchBox.PlaceholderText = "Search..."
SearchBox.PlaceholderColor3 = Theme.SubText

SearchBox.Text = ""
SearchBox.TextColor3 = Theme.Text

SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12

SearchBox.ClearTextOnFocus = false

SearchBox.Parent = Topbar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0,8)
SearchCorner.Parent = SearchBox

--==================================================
-- MINIMIZE
--==================================================

local Minimize = Instance.new("TextButton")

Minimize.Size = UDim2.fromOffset(34,34)
Minimize.Position = UDim2.new(1,-110,0,12)

Minimize.BackgroundColor3 = Theme.Button
Minimize.BorderSizePixel = 0

Minimize.Text = "—"
Minimize.TextColor3 = Theme.Text
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold

Minimize.Parent = Topbar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0,8)
MinimizeCorner.Parent = Minimize

--==================================================
-- CLOSE
--==================================================

local Close = Instance.new("TextButton")

Close.Size = UDim2.fromOffset(34,34)
Close.Position = UDim2.new(1,-68,0,12)

Close.BackgroundColor3 = Theme.Button
Close.BorderSizePixel = 0

Close.Text = "×"
Close.TextColor3 = Theme.Text
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold

Close.Parent = Topbar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0,8)
CloseCorner.Parent = Close

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")

Sidebar.Size = UDim2.new(0,180,1,-58)
Sidebar.Position = UDim2.fromOffset(0,58)

Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0

Sidebar.Parent = Main

local PageList = Instance.new("ScrollingFrame")

PageList.Size = UDim2.new(1,-12,1,-12)
PageList.Position = UDim2.fromOffset(6,6)

PageList.BackgroundTransparency = 1
PageList.BorderSizePixel = 0

PageList.ScrollBarThickness = 2

PageList.CanvasSize = UDim2.new()

PageList.Parent = Sidebar

local PageLayout = Instance.new("UIListLayout")

PageLayout.Padding = UDim.new(0,5)

PageLayout.Parent = PageList

PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

    PageList.CanvasSize = UDim2.fromOffset(
        0,
        PageLayout.AbsoluteContentSize.Y + 10
    )

end)

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")

Content.Size = UDim2.new(1,-195,1,-72)
Content.Position = UDim2.fromOffset(190,65)

Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

Content.ScrollBarThickness = 3

Content.CanvasSize = UDim2.new()

Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")

ContentLayout.Padding = UDim.new(0,10)

ContentLayout.Parent = Content

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

    Content.CanvasSize = UDim2.fromOffset(
        0,
        ContentLayout.AbsoluteContentSize.Y + 15
    )

end)

--==================================================
-- PAGE CREATION
--==================================================

local function CreatePage(name)

    local page = Instance.new("Frame")

    page.Name = name

    page.Size = UDim2.new(1,-10,0,0)
    page.AutomaticSize = Enum.AutomaticSize.Y

    page.BackgroundTransparency = 1

    page.Visible = false

    page.Parent = Content

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0,10)

    layout.Parent = page

    Pages[name] = page

    return page
end

local function ShowPage(name)

    if not Pages[name] then
        return
    end

    State.CurrentPage = name

    for pageName,page in pairs(Pages) do
        page.Visible = pageName == name
    end

end

--==================================================
-- PAGE BUTTONS
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

for _,name in ipairs(PageNames) do

    CreatePage(name)

    local button = Instance.new("TextButton")

    button.Name = name

    button.Size = UDim2.new(1,0,0,38)

    button.BackgroundColor3 = Theme.Button
    button.BorderSizePixel = 0

    button.Text = name

    button.Font = Enum.Font.GothamMedium
    button.TextSize = 13

    button.TextColor3 = Theme.Text

    button.Parent = PageList

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0,7)

    corner.Parent = button

    button.MouseButton1Click:Connect(function()

        ShowPage(name)

    end)

    PageButtons[name] = button

end

--==================================================
-- UI HELPERS
--==================================================

local function AddTitle(parent,text)

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1,-10,0,40)

    label.BackgroundTransparency = 1

    label.Text = text

    label.TextColor3 = Theme.Text

    label.Font = Enum.Font.GothamBold

    label.TextSize = 20

    label.TextXAlignment = Enum.TextXAlignment.Left

    label.Parent = parent

    return label
end

local function AddDescription(parent,text)

    local label = Instance.new("TextLabel")

    label.Size = UDim2.new(1,-10,0,30)

    label.BackgroundTransparency = 1

    label.Text = text

    label.TextColor3 = Theme.SubText

    label.Font = Enum.Font.Gotham

    label.TextSize = 12

    label.TextWrapped = true

    label.TextXAlignment = Enum.TextXAlignment.Left

    label.Parent = parent

    return label
end

local function AddCard(parent,title,value)

    local card = Instance.new("Frame")

    card.Size = UDim2.new(1,-10,0,70)

    card.BackgroundColor3 = Theme.Card

    card.BorderSizePixel = 0

    card.Parent = parent

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0,9)

    corner.Parent = card

    local titleLabel = Instance.new("TextLabel")

    titleLabel.BackgroundTransparency = 1

    titleLabel.Position = UDim2.fromOffset(14,8)

    titleLabel.Size = UDim2.new(1,-28,0,22)

    titleLabel.Text = title

    titleLabel.TextColor3 = Theme.SubText

    titleLabel.Font = Enum.Font.Gotham

    titleLabel.TextSize = 11

    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    titleLabel.Parent = card

    local valueLabel = Instance.new("TextLabel")

    valueLabel.BackgroundTransparency = 1

    valueLabel.Position = UDim2.fromOffset(14,29)

    valueLabel.Size = UDim2.new(1,-28,0,30)

    valueLabel.Text = tostring(value)

    valueLabel.TextColor3 = Theme.Text

    valueLabel.Font = Enum.Font.GothamBold

    valueLabel.TextSize = 16

    valueLabel.TextXAlignment = Enum.TextXAlignment.Left

    valueLabel.Parent = card

    return card,valueLabel
end

local function AddButton(parent,text,callback)

    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1,-10,0,42)

    button.BackgroundColor3 = Theme.Card

    button.BorderSizePixel = 0

    button.Text = text

    button.TextColor3 = Theme.Text

    button.Font = Enum.Font.GothamMedium

    button.TextSize = 13

    button.Parent = parent

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0,8)

    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

--==================================================
-- HOME
--==================================================

do

    local page = Pages.Home

    AddTitle(page,"Welcome to Floquitave")

    AddDescription(
        page,
        "Hub modular • Interface 1.0"
    )

    AddCard(page,"Level",GetLevel())

    AddCard(page,"Beli",GetBeli())

    AddCard(page,"Fragments",GetFragments())

    AddCard(page,"Race",GetRace())

    AddCard(page,"Sea",GetSea())

    AddCard(page,"FPS","0")

    AddCard(page,"Ping","0 ms")

    AddCard(page,"Uptime","00:00:00")

end

--==================================================
-- MAIN FARM
--==================================================

do

    local page = Pages["Main Farm"]

    AddTitle(page,"Main Farm")

    AddDescription(
        page,
        "Módulos preparados para futuras integrações."
    )

    AddButton(page,"Auto Farm • TEST",function()

        warn("[Floquitave] Auto Farm test selected.")

    end)

    AddButton(page,"Auto Mastery • TEST",function()

        warn("[Floquitave] Auto Mastery test selected.")

    end)

end

--==================================================
-- QUEST
--==================================================

do

    local page = Pages.Quest

    AddTitle(page,"Quest")

    AddDescription(
        page,
        "Gerenciamento de módulos de quest."
    )

    AddButton(page,"Auto Quest • TEST",function()

        warn("[Floquitave] Auto Quest test selected.")

    end)

    AddButton(page,"Quest Selector • TEST",function()

        warn("[Floquitave] Quest selector selected.")

    end)

end

--==================================================
-- RAIDS
--==================================================

do

    local page = Pages.Raids

    AddTitle(page,"Raids")

    AddDescription(
        page,
        "Painel de configuração de raids."
    )

    AddButton(page,"Auto Raid • TEST",function()

        warn("[Floquitave] Auto Raid test selected.")

    end)

    AddButton(page,"Raid Selector • TEST",function()

        warn("[Floquitave] Raid selector selected.")

    end)

end

--==================================================
-- COMBAT
--==================================================

do

    local page = Pages.Combat

    AddTitle(page,"Combat")

    AddDescription(
        page,
        "Módulos de combate preparados para testes."
    )

    AddButton(page,"Combat Assist • TEST",function()

        warn("[Floquitave] Combat Assist test selected.")

    end)

    AddButton(page,"Target Selector • TEST",function()

        warn("[Floquitave] Target selector selected.")

    end)

end

--==================================================
-- TELEPORT
--==================================================

local TeleportPage = Pages.Teleport
local TeleportContainer

local function BuildTeleport()

    if TeleportContainer then
        TeleportContainer:Destroy()
        TeleportContainer = nil
    end

    TeleportContainer = Instance.new("Frame")

    TeleportContainer.Name = "TeleportContainer"

    TeleportContainer.Size = UDim2.new(1,-10,0,0)

    TeleportContainer.AutomaticSize = Enum.AutomaticSize.Y

    TeleportContainer.BackgroundTransparency = 1

    TeleportContainer.Parent = TeleportPage

    local layout = Instance.new("UIListLayout")

    layout.Padding = UDim.new(0,8)

    layout.Parent = TeleportContainer

    AddTitle(TeleportContainer,"Teleport")

    AddDescription(
        TeleportContainer,
        "Selecione um Sea para visualizar os mapas."
    )

    for _,seaName in ipairs({
        "Sea 1",
        "Sea 2",
        "Sea 3"
    }) do

        local isOpen = State.OpenSea == seaName

        AddButton(
            TeleportContainer,
            (isOpen and "▼ " or "▶ ")..seaName,
            function()

                if State.OpenSea == seaName then
                    State.OpenSea = nil
                else
                    State.OpenSea = seaName
                end

                BuildTeleport()

            end
        )

        if isOpen then

            for _,locationName in ipairs(
                TeleportLocations[seaName]
            ) do

                AddButton(
                    TeleportContainer,
                    "   "..locationName,
                    function()

                        warn(
                            "[Floquitave] Destination selected:",
                            seaName,
                            locationName
                        )

                    end
                )

            end

        end

    end

end

BuildTeleport()

--==================================================
-- PLAYER
--==================================================

do

    local page = Pages.Player

    AddTitle(page,"Player")

    AddDescription(
        page,
        "Configurações locais do personagem."
    )

    local speedButton

    speedButton = AddButton(
        page,
        "WalkSpeed: "..Config.WalkSpeed,
        function()

            Config.WalkSpeed = Config.WalkSpeed + 5

            if Config.WalkSpeed > 100 then
                Config.WalkSpeed = 16
            end

            speedButton.Text =
                "WalkSpeed: "..Config.WalkSpeed

            local humanoid = GetHumanoid()

            if humanoid then
                humanoid.WalkSpeed = Config.WalkSpeed
            end

        end
    )

    local jumpButton

    jumpButton = AddButton(
        page,
        "JumpPower: "..Config.JumpPower,
        function()

            Config.JumpPower = Config.JumpPower + 10

            if Config.JumpPower > 150 then
                Config.JumpPower = 50
            end

            jumpButton.Text =
                "JumpPower: "..Config.JumpPower

            local humanoid = GetHumanoid()

            if humanoid then

                humanoid.UseJumpPower = true

                humanoid.JumpPower =
                    Config.JumpPower

            end

        end
    )

    AddButton(
        page,
        "Reset Player Settings",
        function()

            Config.WalkSpeed = 16
            Config.JumpPower = 50

            local humanoid = GetHumanoid()

            if humanoid then

                humanoid.WalkSpeed = 16

                humanoid.UseJumpPower = true

                humanoid.JumpPower = 50

            end

            speedButton.Text = "WalkSpeed: 16"
            jumpButton.Text = "JumpPower: 50"

        end
    )

end

--==================================================
-- SERVER
--==================================================

do

    local page = Pages.Server

    AddTitle(page,"Server")

    AddCard(page,"Job ID",game.JobId)

    AddCard(page,"Place ID",game.PlaceId)

    AddCard(page,"Sea",GetSea())

    AddCard(
        page,
        "Players",
        #Players:GetPlayers()
    )

    AddButton(
        page,
        "Copy Job ID",
        function()

            if setclipboard then
                setclipboard(game.JobId)
            else
                warn("setclipboard não disponível.")
            end

        end
    )

end

--==================================================
-- MISC
--==================================================

do

    local page = Pages.Misc

    AddTitle(page,"Misc")

    AddDescription(
        page,
        "Ferramentas auxiliares."
    )

    AddButton(
        page,
        "Notifications Test",
        function()

            print("[Floquitave] Notification test.")

        end
    )

    AddButton(
        page,
        "Recheck Character",
        function()

            local character = GetCharacter()

            print(
                "[Floquitave] Character:",
                character
            )

        end
    )

end

--==================================================
-- SETTINGS
--==================================================

do

    local page = Pages.Settings

    AddTitle(page,"Settings")

    local animationButton

    animationButton = AddButton(
        page,
        "Animations: ON",
        function()

            Config.Animations =
                not Config.Animations

            animationButton.Text =
                "Animations: "
                ..(Config.Animations and "ON" or "OFF")

        end
    )

    local notificationButton

    notificationButton = AddButton(
        page,
        "Notifications: ON",
        function()

            Config.Notifications =
                not Config.Notifications

            notificationButton.Text =
                "Notifications: "
                ..(Config.Notifications and "ON" or "OFF")

        end
    )

    AddDescription(
        page,
        "Themes"
    )

    for themeName in pairs(Themes) do

        AddButton(
            page,
            "Theme: "..themeName,
            function()

                Config.Theme = themeName

                Theme = Themes[themeName]

                Main.BackgroundColor3 =
                    Theme.Background

                Sidebar.BackgroundColor3 =
                    Theme.Sidebar

                Topbar.BackgroundColor3 =
                    Theme.Topbar

                SearchBox.BackgroundColor3 =
                    Theme.Button

                Minimize.BackgroundColor3 =
                    Theme.Button

                Close.BackgroundColor3 =
                    Theme.Button

                for _,button in pairs(PageButtons) do
                    button.BackgroundColor3 =
                        Theme.Button
                    button.TextColor3 =
                        Theme.Text
                end

                BuildTeleport()

            end
        )

    end

end

--==================================================
-- ABOUT
--==================================================

do

    local page = Pages.About

    AddTitle(page,"Floquitave")

    AddDescription(
        page,
        "Version 1.0"
    )

    AddDescription(
        page,
        "Modular UI foundation."
    )

    AddDescription(
        page,
        "Session: "..FormatTime(
            os.clock()-State.SessionStart
        )
    )

end

--==================================================
-- FLOATING MINIMIZE BUTTON
--==================================================

local Floating = Instance.new("TextButton")

Floating.Name = "FloquitaveFloating"

Floating.Size = UDim2.fromOffset(56,56)

Floating.Position = UDim2.new(
    0,
    25,
    0.5,
    -28
)

Floating.BackgroundColor3 = Theme.Accent

Floating.BorderSizePixel = 0

Floating.Text = "F"

Floating.TextColor3 =
    Color3.fromRGB(255,255,255)

Floating.Font = Enum.Font.GothamBold

Floating.TextSize = 22

Floating.Visible = false

Floating.Parent = Gui

local FloatingCorner = Instance.new("UICorner")

FloatingCorner.CornerRadius = UDim.new(1,0)

FloatingCorner.Parent = Floating

--==================================================
-- DRAG FUNCTION
--==================================================

local function MakeDraggable(object,handle)

    local dragging = false

    local dragStart
    local startPosition

    AddConnection(
        handle.InputBegan:Connect(
            function(input)

                if input.UserInputType ==
                    Enum.UserInputType.MouseButton1
                    or input.UserInputType ==
                    Enum.UserInputType.Touch then

                    dragging = true

                    dragStart =
                        input.Position

                    startPosition =
                        object.Position

                    local changed

                    changed =
                        input.Changed:Connect(
                            function()

                                if input.UserInputState ==
                                    Enum.UserInputState.End then

                                    dragging = false

                                    if changed then
                                        changed:Disconnect()
                                    end

                                end

                            end
                        )

                end

            end
        )
    )

    AddConnection(
        UserInputService.InputChanged:Connect(
            function(input)

                if not dragging then
                    return
                end

                if input.UserInputType ~=
                    Enum.UserInputType.MouseMovement
                    and input.UserInputType ~=
                    Enum.UserInputType.Touch then
                    return
                end

                local delta =
                    input.Position - dragStart

                object.Position =
                    UDim2.new(
                        startPosition.X.Scale,
                        startPosition.X.Offset + delta.X,

                        startPosition.Y.Scale,
                        startPosition.Y.Offset + delta.Y
                    )

            end
        )
    )

end

MakeDraggable(Main,Topbar)
MakeDraggable(Floating,Floating)

--==================================================
-- MINIMIZE
--==================================================

Minimize.MouseButton1Click:Connect(function()

    State.Minimized = true

    Main.Visible = false

    Floating.Visible = true

end)

Floating.MouseButton1Click:Connect(function()

    State.Minimized = false

    Main.Visible = true

    Floating.Visible = false

end)

--==================================================
-- CLOSE
--==================================================

Close.MouseButton1Click:Connect(function()

    State.Destroyed = true

    for _,connection in ipairs(Connections) do

        pcall(function()
            connection:Disconnect()
        end)

    end

    Gui:Destroy()

end)

--==================================================
-- SEARCH
--==================================================

AddConnection(
    SearchBox:GetPropertyChangedSignal("Text"):Connect(
        function()

            State.SearchText =
                string.lower(
                    SearchBox.Text
                )

            for name,button in pairs(PageButtons) do

                if State.SearchText == "" then

                    button.Visible = true

                else

                    button.Visible =
                        string.find(
                            string.lower(name),
                            State.SearchText,
                            1,
                            true
                        ) ~= nil

                end

            end

        end
    )
)

--==================================================
-- FPS
--==================================================

local frameCounter = 0
local fpsTimer = os.clock()

AddConnection(
    RunService.RenderStepped:Connect(
        function()

            frameCounter += 1

            local now = os.clock()

            if now - fpsTimer >= 1 then

                State.FPS =
                    math.floor(
                        frameCounter /
                        (now-fpsTimer)
                    )

                frameCounter = 0
                fpsTimer = now

            end

        end
    )
)

--==================================================
-- LIVE UPDATES
--==================================================

AddConnection(
    RunService.Heartbeat:Connect(
        function()

            if State.Destroyed then
                return
            end

            State.Ping = GetPing()

        end
    )
)

--==================================================
-- RESPAWN
--==================================================

AddConnection(
    LocalPlayer.CharacterAdded:Connect(
        function(character)

            task.wait(1)

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if humanoid then

                humanoid.WalkSpeed =
                    Config.WalkSpeed

                humanoid.UseJumpPower = true

                humanoid.JumpPower =
                    Config.JumpPower

            end

        end
    )
)

--==================================================
-- INITIALIZE
--==================================================

ShowPage("Home")

print(
    "[Floquitave] "..Config.Name..
    " "..Config.Version..
    " carregado."
)
