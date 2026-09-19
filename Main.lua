--// Floquitave
--// Version 2.6.0
--// UI + Teleport structure

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Name = "Floquitave",
    Version = "2.6.0",
    Animations = true,
    Notifications = true,
    Theme = "Dark",
}

--==================================================
-- SERVICES
--==================================================

local State = {
    CurrentPage = "Home",
    Minimized = false,
    Search = "",
    OpenSea = "Sea 1",
}

local Connections = {}

local Themes = {
    Dark = {
        Background = Color3.fromRGB(18,18,24),
        Sidebar = Color3.fromRGB(14,14,19),
        Card = Color3.fromRGB(25,25,33),
        Button = Color3.fromRGB(32,32,42),
        Text = Color3.fromRGB(240,240,245),
        SubText = Color3.fromRGB(150,150,165),
        Accent = Color3.fromRGB(115,90,255),
    },

    Purple = {
        Background = Color3.fromRGB(24,18,30),
        Sidebar = Color3.fromRGB(19,14,25),
        Card = Color3.fromRGB(34,24,43),
        Button = Color3.fromRGB(43,30,54),
        Text = Color3.fromRGB(245,240,250),
        SubText = Color3.fromRGB(165,145,175),
        Accent = Color3.fromRGB(170,90,255),
    },

    Blue = {
        Background = Color3.fromRGB(17,23,32),
        Sidebar = Color3.fromRGB(13,18,26),
        Card = Color3.fromRGB(24,32,44),
        Button = Color3.fromRGB(30,41,55),
        Text = Color3.fromRGB(240,245,250),
        SubText = Color3.fromRGB(145,160,175),
        Accent = Color3.fromRGB(70,145,255),
    },

    Red = {
        Background = Color3.fromRGB(28,18,20),
        Sidebar = Color3.fromRGB(22,13,15),
        Card = Color3.fromRGB(42,24,27),
        Button = Color3.fromRGB(54,30,34),
        Text = Color3.fromRGB(250,240,240),
        SubText = Color3.fromRGB(175,145,150),
        Accent = Color3.fromRGB(255,75,90),
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
        "Fountain City",
    },

    ["Sea 2"] = {
        "Kingdom of Rose",
        "Green Zone",
        "Graveyard",
        "Snow Mountain",
        "Hot and Cold",
        "Cursed Ship",
        "Ice Castle",
        "Forgotten Island",
    },

    ["Sea 3"] = {
        "Port Town",
        "Hydra Island",
        "Great Tree",
        "Floating Turtle",
        "Haunted Castle",
        "Sea of Treats",
        "Tiki Outpost",
    }
}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "Floquitave"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(900,570)
Main.Position = UDim2.new(0.5,-450,0.5,-285)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,12)
Corner.Parent = Main

--==================================================
-- TOP BAR
--==================================================

local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1,0,0,55)
Topbar.BackgroundColor3 = Theme.Card
Topbar.BorderSizePixel = 0
Topbar.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(18,0)
Title.Size = UDim2.fromOffset(200,55)
Title.Font = Enum.Font.GothamBold
Title.Text = "Floquitave"
Title.TextSize = 20
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Topbar

-- Search pequeno, sem cobrir os controles
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.fromOffset(170,34)
SearchBox.Position = UDim2.new(1,-270,0,10)
SearchBox.BackgroundColor3 = Theme.Button
SearchBox.PlaceholderText = "Search..."
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.Text
SearchBox.PlaceholderColor3 = Theme.SubText
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = Topbar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0,8)
SearchCorner.Parent = SearchBox

-- minimizar
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(34,34)
Minimize.Position = UDim2.new(1,-88,0,10)
Minimize.BackgroundColor3 = Theme.Button
Minimize.Text = "—"
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.TextColor3 = Theme.Text
Minimize.Parent = Topbar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0,8)
MinCorner.Parent = Minimize

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34,34)
Close.Position = UDim2.new(1,-46,0,10)
Close.BackgroundColor3 = Theme.Button
Close.Text = "×"
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.TextColor3 = Theme.Text
Close.Parent = Topbar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0,8)
CloseCorner.Parent = Close

--==================================================
-- SIDEBAR
--==================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,180,1,-55)
Sidebar.Position = UDim2.fromOffset(0,55)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local PageList = Instance.new("ScrollingFrame")
PageList.Size = UDim2.new(1,-14,1,-14)
PageList.Position = UDim2.fromOffset(7,7)
PageList.BackgroundTransparency = 1
PageList.BorderSizePixel = 0
PageList.ScrollBarThickness = 2
PageList.Parent = Sidebar

local PageLayout = Instance.new("UIListLayout")
PageLayout.Padding = UDim.new(0,5)
PageLayout.Parent = PageList

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1,-195,1,-70)
Content.Position = UDim2.fromOffset(190,65)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.Parent = Main

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0,10)
ContentLayout.Parent = Content

--==================================================
-- PAGE SYSTEM
--==================================================

local Pages = {}
local PageButtons = {}

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
    State.CurrentPage = name

    for pageName,page in pairs(Pages) do
        page.Visible = pageName == name
    end
end

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
    local page = CreatePage(name)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,0,38)
    button.BackgroundColor3 = Theme.Button
    button.Text = name
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 13
    button.TextColor3 = Theme.Text
    button.BorderSizePixel = 0
    button.Parent = PageList

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = button

    button.MouseButton1Click:Connect(function()
        ShowPage(name)
    end)

    PageButtons[name] = button
end

--==================================================
-- HELPERS
--==================================================

local function Label(parent,text,size)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-10,0,size or 35)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function Action(parent,text,callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,-10,0,42)
    button.BackgroundColor3 = Theme.Card
    button.Text = text
    button.TextColor3 = Theme.Text
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 13
    button.BorderSizePixel = 0
    button.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,8)
    c.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

--==================================================
-- HOME
--==================================================

do
    local page = Pages.Home

    Label(page,"Welcome to Floquitave",40)
    Label(page,"Version "..Config.Version,30)

    Action(page,"Quick Settings",function()
        ShowPage("Settings")
    end)

    Action(page,"Open Player",function()
        ShowPage("Player")
    end)

    Action(page,"Open Teleport",function()
        ShowPage("Teleport")
    end)
end

--==================================================
-- TELEPORT
--==================================================

local TeleportContainer

local function ClearTeleport()
    if TeleportContainer then
        TeleportContainer:Destroy()
    end
end

local function BuildTeleport()
    ClearTeleport()

    TeleportContainer = Instance.new("Frame")
    TeleportContainer.Size = UDim2.new(1,-10,0,0)
    TeleportContainer.AutomaticSize = Enum.AutomaticSize.Y
    TeleportContainer.BackgroundTransparency = 1
    TeleportContainer.Parent = Pages.Teleport

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.Parent = TeleportContainer

    Label(TeleportContainer,"Teleport",40)

    for _,sea in ipairs({"Sea 1","Sea 2","Sea 3"}) do

        local seaButton = Action(TeleportContainer,
            (State.OpenSea == sea and "▼ " or "▶ ")..sea,
            function()

                if State.OpenSea == sea then
                    State.OpenSea = nil
                else
                    State.OpenSea = sea
                end

                BuildTeleport()
            end
        )

        if State.OpenSea == sea then

            for _,location in ipairs(TeleportLocations[sea]) do

                Action(TeleportContainer,location,function()

                    -- Integração segura:
                    -- aqui é onde um jogo próprio pode chamar
                    -- sua função de teleporte.

                    warn("Destino selecionado:",sea,location)

                end)

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

    Label(page,"Player",40)

    local speed = 16
    local jump = 50

    Action(page,"WalkSpeed: "..speed,function()
        speed = speed == 16 and 25 or 16
        page:FindFirstChildOfClass("TextButton").Text = "WalkSpeed: "..speed
    end)

    Action(page,"JumpPower: "..jump,function()
        jump = jump == 50 and 75 or 50
        page:GetChildren()[2].Text = "JumpPower: "..jump
    end)
end

--==================================================
-- SERVER
--==================================================

do
    local page = Pages.Server

    Label(page,"Server",40)

    Action(page,"Job ID: "..game.JobId,function()
        if setclipboard then
            setclipboard(game.JobId)
        end
    end)

    Action(page,"Place ID: "..tostring(game.PlaceId),function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
        end
    end)

    Action(page,"Players: "..#Players:GetPlayers(),function() end)
end

--==================================================
-- SETTINGS
--==================================================

do
    local page = Pages.Settings

    Label(page,"Settings",40)

    Action(page,"Animations: ON",function()
        Config.Animations = not Config.Animations
    end)

    for themeName in pairs(Themes) do
        Action(page,"Theme: "..themeName,function()
            Config.Theme = themeName
            Theme = Themes[themeName]

            Main.BackgroundColor3 = Theme.Background
            Sidebar.BackgroundColor3 = Theme.Sidebar
            Topbar.BackgroundColor3 = Theme.Card

            BuildTeleport()
        end)
    end
end

--==================================================
-- OTHER PAGES
--==================================================

for _,name in ipairs({
    "Main Farm",
    "Quest",
    "Raids",
    "Combat",
    "Misc"
}) do
    Label(Pages[name],name,40)

    Action(Pages[name],"Test Module",function()
        warn(name.." module selected")
    end)
end

do
    Label(Pages.About,"Floquitave",45)
    Label(Pages.About,"Version "..Config.Version,30)
    Label(Pages.About,"UI / modular foundation",30)
end

--==================================================
-- MINIMIZE / FLOATING BUTTON
--==================================================

local Floating = Instance.new("TextButton")
Floating.Name = "FloquitaveMini"
Floating.Size = UDim2.fromOffset(55,55)
Floating.Position = UDim2.new(0,25,0.5,-27)
Floating.BackgroundColor3 = Theme.Accent
Floating.Text = "F"
Floating.TextColor3 = Color3.new(1,1,1)
Floating.Font = Enum.Font.GothamBold
Floating.TextSize = 22
Floating.Visible = false
Floating.Parent = Gui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1,0)
FloatCorner.Parent = Floating

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Floating.Visible = true
end)

Floating.MouseButton1Click:Connect(function()
    Main.Visible = true
    Floating.Visible = false
end)

Close.MouseButton1Click:Connect(function()
    Gui:Destroy()
end)

--==================================================
-- DRAG
--==================================================

local UserInputService = game:GetService("UserInputService")

local function MakeDraggable(object, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        object.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

MakeDraggable(Main,Topbar)
MakeDraggable(Floating,Floating)

--==================================================
-- SEARCH
--==================================================

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    State.Search = string.lower(SearchBox.Text)

    for name,button in pairs(PageButtons) do
        button.Visible =
            State.Search == ""
            or string.find(string.lower(name),State.Search,1,true) ~= nil
    end
end)

--==================================================
-- INITIAL PAGE
--==================================================

ShowPage("Home")

print("Floquitave "..Config.Version.." carregado.")
