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
