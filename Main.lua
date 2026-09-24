--[[
    FLOQUITAVE HUB
    Version: 2.7.6b
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
    Version = "2.7.6b",

    Width = 920,
    Height = 590,

    Animations = true,
    Notifications = true,

    Theme = "Dark",
    Scale = (UserInputService.TouchEnabled and 0.50 or 0.85),

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
