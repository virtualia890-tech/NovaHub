-- Anime Dice | Hub básico 1.1 | 09/10/2026
-- Execute dentro de Anime Dice. A lista abaixo é fixa nesta versão;
-- códigos podem expirar ou surgir depois da publicação.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CODES = {
    "50KCCU", "sorry4delay", "UPDATE7", "UPDATE6", "400KLIKES",
    "UPDATE5", "250KLIKES", "100KLIKES", "40KCCU", "30KCCU",
    "UPDATE4", "20KCCU", "10KCCU", "5KCCU", "1KCCU",
    "UPDATE3", "UPDATE2", "UPDATE1", "RELEASE"
}

local env = (type(getgenv) == "function" and getgenv()) or _G
if type(env.AnimeDiceBasicoFechar) == "function" then
    pcall(env.AnimeDiceBasicoFechar)
end

local connections = {}
local gui
local antiAfkConnection
local busy = false
local cancelled = false

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function closeHub()
    cancelled = true
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    if gui then gui:Destroy() end
    if env.AnimeDiceBasicoFechar == closeHub then
        env.AnimeDiceBasicoFechar = nil
    end
end
env.AnimeDiceBasicoFechar = closeHub

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do object[property] = value end
    object.Parent = parent
    return object
end

gui = make("ScreenGui", {
    Name = "AnimeDiceBasicoHub", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)
local frame = make("Frame", {
    Size = UDim2.fromOffset(350, 238),
    Position = UDim2.new(0.5, -175, 0.5, -119),
    BackgroundColor3 = Color3.fromRGB(23, 24, 35),
    BorderSizePixel = 0, Active = true
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, frame)
local title = make("TextLabel", {
    Size = UDim2.new(1, -56, 0, 40), Position = UDim2.fromOffset(15, 4),
    BackgroundTransparency = 1, Text = "Anime Dice  •  Básico",
    TextColor3 = Color3.fromRGB(245, 245, 250),
    TextSize = 18, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)
local close = make("TextButton", {
    Size = UDim2.fromOffset(30, 28), Position = UDim2.new(1, -39, 0, 10),
    Text = "×", TextSize = 20, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(110, 50, 62), BorderSizePixel = 0
}, frame)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, close)
local minimize = make("TextButton", {
    Size = UDim2.fromOffset(30, 28), Position = UDim2.new(1, -76, 0, 10),
    Text = "−", TextSize = 22, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(63, 74, 105), BorderSizePixel = 0
}, frame)
make("UICorner", {CornerRadius = UDim.new(0, 7)}, minimize)
local opener = make("TextButton", {
    Size = UDim2.fromOffset(112, 36), Position = UDim2.fromOffset(12, 112),
    Text = "Anime Dice  +", TextSize = 13, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(58, 109, 88), BorderSizePixel = 0,
    Visible = false, Active = true, ZIndex = 10
}, gui)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, opener)

local function button(textValue, y, color)
    local result = make("TextButton", {
        Size = UDim2.new(1, -30, 0, 39), Position = UDim2.fromOffset(15, y),
        Text = textValue, TextSize = 14, Font = Enum.Font.GothamSemibold,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = color, BorderSizePixel = 0,
        AutoButtonColor = true
    }, frame)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, result)
    return result
end

local antiAfkButton = button("Anti AFK: desligado", 50, Color3.fromRGB(63, 74, 105))
local redeemButton = button("Resgatar os 19 códigos", 96, Color3.fromRGB(58, 109, 88))
local copyButton = button("Copiar lista de códigos", 142, Color3.fromRGB(63, 74, 105))
local status = make("TextLabel", {
    Size = UDim2.new(1, -30, 0, 41), Position = UDim2.fromOffset(15, 188),
    BackgroundTransparency = 1, Text = "Pronto. Códigos verificados em 09/10/2026.",
    TextColor3 = Color3.fromRGB(202, 205, 220),
    TextSize = 12, TextWrapped = true, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)
local function setStatus(value)
    if status.Parent then status.Text = value end
end

connect(close.MouseButton1Click, closeHub)
connect(minimize.MouseButton1Click, function()
    frame.Visible = false
    opener.Visible = true
end)
connect(opener.MouseButton1Click, function()
    frame.Visible = true
    opener.Visible = false
end)
connect(antiAfkButton.MouseButton1Click, function()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
        antiAfkButton.Text = "Anti AFK: desligado"
        setStatus("Anti AFK desligado.")
        return
    end
    antiAfkConnection = player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.15)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end)
    antiAfkButton.Text = "Anti AFK: ligado"
    setStatus("Anti AFK ligado; age somente ao detectar inatividade.")
end)

connect(copyButton.MouseButton1Click, function()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, table.concat(CODES, "\n"))
        setStatus(ok and "Lista copiada para a área de transferência." or "Não foi possível copiar neste executor.")
    else
        setStatus("Este executor não oferece setclipboard.")
    end
end)

-- Arrastar a janela pelo título.
local dragging, dragStart, frameStart = false, nil, nil
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, frameStart = true, input.Position, frame.Position
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and dragStart and frameStart and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X,
            frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

local function labelOf(object)
    local parts = {object.Name}
    if object:IsA("TextButton") or object:IsA("TextLabel") or object:IsA("TextBox") then
        table.insert(parts, object.Text)
    end
    if object:IsA("TextBox") then table.insert(parts, object.PlaceholderText) end
    if object:IsA("GuiButton") then
        for _, child in ipairs(object:GetChildren()) do
            if child:IsA("TextLabel") then table.insert(parts, child.Text) end
        end
    end
    return string.lower(table.concat(parts, " "))
end

local function visible(object)
    local current = object
    while current and current ~= playerGui do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return current == playerGui
end

local function findButton(pattern, scope)
    for _, object in ipairs(scope:GetDescendants()) do
        if object:IsA("GuiButton") and visible(object)
            and string.find(labelOf(object), pattern) then
            return object
        end
    end
end

local function findCodeBox()
    local best, bestScore
    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("TextBox") and visible(object)
            and not object:IsDescendantOf(gui) then
            local description = labelOf(object)
            local score = 0
            if string.find(description, "code") then score = score + 10 end
            if string.find(description, "redeem") then score = score + 5 end
            local ancestor = object.Parent
            for _ = 1, 4 do
                if not ancestor or ancestor == playerGui then break end
                if string.find(string.lower(ancestor.Name), "code") then
                    score = score + 3
                end
                ancestor = ancestor.Parent
            end
            if score > 0 and (not bestScore or score > bestScore) then
                best, bestScore = object, score
            end
        end
    end
    return best
end

local function findRedeemButton(box)
    local scope = box.Parent
    for _ = 1, 5 do
        if not scope or scope == playerGui then break end
        local result = findButton("redeem", scope)
        if result and not result:IsDescendantOf(gui) then return result end
        scope = scope.Parent
    end
end

-- O comando explícito do jogo é a primeira opção; clique na interface é reserva.
local function findCodeRemote()
    local best, score = nil, 0
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = string.lower(remote.Name)
            local points = 0
            if name == "redeemcode" or name == "redeemcodes" then
                points = 100
            elseif string.find(name, "redeem") and string.find(name, "code") then
                points = 80
            elseif name == "coderedeem" or name == "claimcode" then
                points = 70
            end
            if points > score then best, score = remote, points end
        end
    end
    return best
end

local function clickGameButton(buttonObject)
    if not buttonObject or not buttonObject.Parent or not visible(buttonObject) then
        return false
    end
    local size = buttonObject.AbsoluteSize
    if size.X < 2 or size.Y < 2 then return false end
    local pos = buttonObject.AbsolutePosition
    local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2
    local ok = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.06)
        vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
    if not ok and type(firesignal) == "function" then
        ok = pcall(firesignal, buttonObject.MouseButton1Click)
    end
    if not ok and type(getconnections) == "function" then
        for _, signal in ipairs({buttonObject.MouseButton1Click, buttonObject.Activated}) do
            local got, list = pcall(getconnections, signal)
            if got and type(list) == "table" then
                for _, connection in ipairs(list) do
                    if type(connection.Fire) == "function" then
                        local fired = pcall(function() connection:Fire() end)
                        if fired then ok = true end
                    end
                end
            end
            if ok then break end
        end
    end
    return ok
end

local function revealInScroll(box)
    local current = box.Parent
    while current and current ~= playerGui do
        if current:IsA("ScrollingFrame") then
            local limit = math.max(0, current.AbsoluteCanvasSize.Y - current.AbsoluteWindowSize.Y)
            current.CanvasPosition = Vector2.new(current.CanvasPosition.X, limit)
        end
        current = current.Parent
    end
    task.wait(0.15)
end

local function locateRedemption()
    local box = findCodeBox()
    if not box then
        local shop = findButton("shop", playerGui)
        if shop and not shop:IsDescendantOf(gui) then
            clickGameButton(shop)
            task.wait(0.5)
        end
        box = findCodeBox()
    end
    if not box then return nil, nil, "Abra Shop > Codes no jogo e tente novamente." end
    revealInScroll(box)
    local submit = findRedeemButton(box)
    if not submit then return nil, nil, "Não achei o botão Redeem; abra a área de códigos." end
    return box, submit
end

connect(redeemButton.MouseButton1Click, function()
    if busy then return end
    busy = true
    redeemButton.Text = "Resgatando..."
    task.spawn(function()
        local wasOpen = frame.Visible
        frame.Visible = false -- deixa Shop e Redeem livres durante os cliques
        opener.Visible = false
        local ok, failure = pcall(function()
            local remote = findCodeRemote()
            local box, submit, err
            if not remote then
                box, submit, err = locateRedemption()
                if not box then error(err) end
            end
            for index, code in ipairs(CODES) do
                if cancelled then return end
                if remote then
                    local sent, response = pcall(function()
                        if remote:IsA("RemoteFunction") then
                            return remote:InvokeServer(code)
                        end
                        remote:FireServer(code)
                    end)
                    if not sent then
                        error("O comando de códigos falhou: " .. tostring(response))
                    end
                else
                    if not box.Parent or not submit.Parent then
                        error("A área de códigos fechou. Abra Shop novamente.")
                    end
                    revealInScroll(box)
                    box:CaptureFocus()
                    box.Text = code
                    box:ReleaseFocus(false)
                    task.wait(0.1)
                    if not clickGameButton(submit) then
                        error("Clique virtual indisponível neste executor.")
                    end
                    -- Se o jogo não limpar/alterar o campo, não dispare os outros 18.
                    if index == 1 then
                        task.wait(0.8)
                        if box.Text == code then
                            error("O jogo não reagiu ao 1º código. Abra Shop > Codes e tente de novo.")
                        end
                    end
                end
                setStatus(string.format("Enviado: %d/%d — %s", index, #CODES, code))
                task.wait(0.8)
            end
            if not cancelled then setStatus("Códigos enviados. Veja o resultado no jogo.") end
        end)
        if not cancelled then
            if not ok then setStatus("Resgate parou: " .. tostring(failure)) end
            frame.Visible = wasOpen
            opener.Visible = not wasOpen
            redeemButton.Text = "Resgatar os 19 códigos"
            busy = false
        end
    end)
end)

if game.PlaceId ~= 113290951185459 then
    setStatus("Aviso: PlaceId diferente. Use este hub em Anime Dice.")
end
