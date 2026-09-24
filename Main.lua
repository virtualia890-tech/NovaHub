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
