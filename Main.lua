-- Needle Finder 0.2 | Search For The Needle (Garage Games)
-- Cole este TXT inteiro no executor. Nenhum codigo externo e baixado.
-- Busca apenas objetos presentes no cliente; nao revela dados mantidos no servidor.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local PLACE = 77108422251420
local UNIVERSE = 10756011174

local global = (type(getgenv) == "function" and getgenv()) or _G
if global.__NeedleFinder and type(global.__NeedleFinder.close) == "function" then
    pcall(global.__NeedleFinder.close)
end

local S = {
    alive = true, monitoring = true, esp = true, scanning = false,
    scanId = 0, target = nil, part = nil, candidates = {},
    lastScan = 0, scanned = 0, truncated = false, excluded = 0,
    groundY = nil, staged = nil,
    connections = {}, highlight = nil, marker = nil,
}
global.__NeedleFinder = S

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(S.connections, c)
    return c
end

local function shortPath(obj)
    local ok, path = pcall(function() return obj:GetFullName() end)
    return ok and tostring(path):sub(1, 180) or tostring(obj.Name)
end

local function validPart(part)
    return part and part:IsA("BasePart") and part:IsDescendantOf(workspace)
end

local function getRoot()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function groundHeight()
    local root = getRoot()
    if not root then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}
    local hit = workspace:Raycast(root.Position + Vector3.new(0, 3, 0),
        Vector3.new(0, -120, 0), params)
    return hit and hit.Position.Y or root.Position.Y - 3
end

local function partOf(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Attachment") and validPart(obj.Parent) then return obj.Parent end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    if obj:IsA("Tool") then return obj:FindFirstChild("Handle") end
    return nil
end

local function isCharacterObject(obj)
    local parent = obj
    while parent and parent ~= workspace do
        if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then return true end
        parent = parent.Parent
    end
    return false
end

local function isCandidate(obj)
    local name = string.lower(obj.Name)
    if not name:find("needle", 1, true) then return false end
    if obj:IsA("Folder") or obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
        or obj:IsA("Script") or obj:IsA("LocalScript") then return false end
    if not (obj:IsA("BasePart") or obj:IsA("Model")
        or obj:IsA("Tool") or obj:IsA("Attachment")) then return false end
    if isCharacterObject(obj) then return false end
    return validPart(partOf(obj)) == true
end

local function rank(obj, part)
    local name = string.lower(obj.Name)
    local score = name == "needle" and 100 or (name == "hiddenneedle" and 90 or 55)
    local p = obj.Parent
    while p and p ~= workspace do
        local n = string.lower(p.Name)
        if n:find("hiddenneedle", 1, true) then score = score + 35 end
        if n:find("haystackclient", 1, true) then score = score + 10 end
        if n:find("template", 1, true) or n:find("storage", 1, true) then
            score = score - 35
        end
        p = p.Parent
    end
    if part.Transparency < 0.98 then score = score + 12 end
    if part.Size.Magnitude > 80 then score = score - 20 end
    return score
end

local ui, statusLabel, detailLabel, scanButton, monitorButton, espButton
local function status(message, detail)
    if not S.alive then return end
    S.message = tostring(message)
    if statusLabel then statusLabel.Text = S.message end
    if detail and detailLabel then detailLabel.Text = tostring(detail) end
end

local function clearESP()
    if S.highlight then S.highlight:Destroy(); S.highlight = nil end
    if S.marker then S.marker:Destroy(); S.marker = nil end
end

local function updateESP()
    clearESP()
    if not S.esp or not S.target or not validPart(S.part) then return end
    local h = Instance.new("Highlight")
    h.Name = "NeedleFinderHighlight"
    h.FillColor = Color3.fromRGB(255, 220, 50)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.45
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = S.target:IsA("Model") and S.target or S.part
    h.Parent = ui
    S.highlight = h

    local b = Instance.new("BillboardGui")
    b.Name = "NeedleFinderMarker"
    b.Adornee = S.part
    b.Size = UDim2.fromOffset(150, 38)
    b.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    b.AlwaysOnTop = true
    b.Parent = ui
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(25, 22, 35)
    text.BackgroundTransparency = 0.18
    text.Text = "AGULHA?  " .. S.target.Name
    text.TextColor3 = Color3.fromRGB(255, 228, 80)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = b
    S.marker = b
end

local function consider(obj, list, seen)
    if not isCandidate(obj) or seen[obj] then return end
    local part = partOf(obj)
    if not validPart(part) then return end
    seen[obj] = true
    table.insert(list, {obj = obj, part = part, score = rank(obj, part)})
end

local function choose(list)
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return shortPath(a.obj) < shortPath(b.obj)
    end)
    S.candidates = list
    S.groundY = groundHeight()
    S.excluded, S.staged = 0, nil
    local best
    for _, item in ipairs(list) do
        -- A mesh kept well below the floor is usually a staging copy. It can
        -- have the exact name Needle, but teleporting there cannot collect it.
        local y = item.part.Position.Y
        item.reason = nil
        if S.groundY and y < S.groundY - 35 then
            item.reason = string.format("abaixo do piso (%.1f < %.1f)", y, S.groundY)
            S.staged = S.staged or item
            S.excluded = S.excluded + 1
        elseif item.part.Transparency >= 0.99 and not item.part.CanTouch
            and not item.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            and not item.obj:FindFirstChildWhichIsA("ClickDetector", true) then
            item.reason = "invisivel, sem toque nem interacao"
            S.staged = S.staged or item
            S.excluded = S.excluded + 1
        end
        if not best and not item.reason then best = item end
    end
    S.target, S.part = best and best.obj or nil, best and best.part or nil
    updateESP()
    if best then
        status("Possivel agulha acessivel: " .. best.obj.Name,
            string.format("%s  |  %d candidato(s) descartado(s)",
                shortPath(best.obj), S.excluded))
    elseif S.staged then
        status("Agulha sob o mapa: ignorada",
            shortPath(S.staged.obj) .. " | " .. S.staged.reason
                .. ". Monitorando a agulha da rodada.")
    else
        status("Agulha ainda nao exposta no cliente",
            "Varredura: " .. S.scanned .. " objetos"
                .. (S.truncated and " (limite atingido)" or "")
                .. ". Entre na rodada ou continue limpando o feno.")
    end
end

local function scan()
    if not S.alive or S.scanning then return end
    S.scanning = true
    S.scanId = S.scanId + 1
    local id = S.scanId
    if scanButton then scanButton.Text = "Varrendo..." end
    status("Procurando objetos carregados...", "Limite de 18.000 objetos por varredura.")
    task.spawn(function()
        local queue, cursor = {workspace}, 1
        local list, seen = {}, {}
        local count, limit = 0, 18000
        while S.alive and id == S.scanId and cursor <= #queue and count < limit do
            local stop = math.min(cursor + 139, #queue)
            while cursor <= stop and count < limit do
                local obj = queue[cursor]
                queue[cursor] = false
                cursor = cursor + 1
                count = count + 1
                if obj and obj.Parent then
                    consider(obj, list, seen)
                    -- Scan only Workspace descendants. Instances outside a live round
                    -- may be templates and are intentionally ignored.
                    local ok, children = pcall(function() return obj:GetChildren() end)
                    if ok then
                        for _, child in ipairs(children) do
                            table.insert(queue, child)
                        end
                    end
                end
            end
            task.wait(0.02)
        end
        if not S.alive or id ~= S.scanId then return end
        S.scanned, S.truncated = count, count >= limit and cursor <= #queue
        S.lastScan, S.scanning = os.clock(), false
        if scanButton then scanButton.Text = "Buscar agora" end
        choose(list)
    end)
end

local function teleport()
    if not validPart(S.part) or not S.target or not S.target.Parent then
        status("Sem destino carregado", "Use Buscar agora e entre numa rodada.")
        return
    end
    local root = getRoot()
    if not root then status("Personagem nao carregado"); return end
    local targetPart = S.part
    local destination = targetPart.Position + Vector3.new(0, 3, 4)
    local ok, err = pcall(function() root.CFrame = CFrame.new(destination) end)
    if not ok then status("Falha no teleporte", tostring(err)); return end
    task.delay(0.4, function()
        if not S.alive then return end
        local current = getRoot()
        local distance = current and (current.Position - targetPart.Position).Magnitude
        status(distance and distance <= 20 and "Perto do objeto candidato" or "Servidor reposicionou o personagem",
            shortPath(S.target) .. " | distancia: " .. (distance and math.floor(distance) or "?"))
    end)
end

local function interact()
    if not validPart(S.part) or not S.target or not S.target.Parent then
        status("Nenhum objeto para interagir"); return
    end
    local root = getRoot()
    if not root or (root.Position - S.part.Position).Magnitude > 18 then
        status("Chegue perto do objeto primeiro"); return
    end
    local obj = S.target
    local prompt = obj:IsA("ProximityPrompt") and obj
        or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    local click = obj:FindFirstChildWhichIsA("ClickDetector", true)
    local ok, method = false, "nenhuma interacao acessivel"
    if prompt and type(fireproximityprompt) == "function" then
        ok = pcall(fireproximityprompt, prompt)
        method = "ProximityPrompt"
    elseif click and type(fireclickdetector) == "function" then
        ok = pcall(fireclickdetector, click)
        method = "ClickDetector"
    elseif type(firetouchinterest) == "function" then
        ok = pcall(function()
            firetouchinterest(root, S.part, 0)
            firetouchinterest(root, S.part, 1)
        end)
        method = "TouchInterest"
    end
    status(ok and "Interacao solicitada" or "Interacao indisponivel",
        method .. "; confirme o resultado no jogo.")
end

local function report()
    local lines = {
        "Needle Finder 0.2 | " .. os.date("!%Y-%m-%d %H:%M UTC"),
        "PlaceId=" .. tostring(game.PlaceId) .. " | GameId=" .. tostring(game.GameId),
        "Status=" .. tostring(S.message or ""),
        "Varredura=" .. tostring(S.scanned) .. " | limite=" .. tostring(S.truncated),
        "PisoY=" .. tostring(S.groundY) .. " | altura jogador="
            .. tostring(getRoot() and getRoot().Position.Y),
        "Candidatos=" .. tostring(#S.candidates) .. " | descartados=" .. tostring(S.excluded),
    }
    for i, item in ipairs(S.candidates) do
        if i > 25 then break end
        table.insert(lines, string.format("%d. %s | %s | score=%d | %.1f, %.1f, %.1f | transparencia=%.2f | toque=%s | %s",
            i, shortPath(item.obj), item.obj.ClassName, item.score,
            item.part.Position.X, item.part.Position.Y, item.part.Position.Z,
            item.part.Transparency, tostring(item.part.CanTouch), item.reason or "candidato ativo"))
    end
    for _, name in ipairs({"HiddenNeedleClient", "HaystackClient", "Haystack"}) do
        local folder = workspace:FindFirstChild(name)
        if folder then table.insert(lines, name .. "=" .. folder.ClassName
            .. " | filhos=" .. #folder:GetChildren()) end
    end
    return table.concat(lines, "\n")
end

local function new(class, properties, parent)
    local obj = Instance.new(class)
    for property, value in pairs(properties) do obj[property] = value end
    obj.Parent = parent
    return obj
end

local parent = (type(gethui) == "function" and gethui()) or CoreGui
ui = new("ScreenGui", {Name="NeedleFinder_0_2", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, parent)
local frame = new("Frame", {Name="Panel", Size=UDim2.fromOffset(380, 330),
    Position=UDim2.new(0.5,-190,0.5,-165), BackgroundColor3=Color3.fromRGB(24,22,32),
    BorderSizePixel=0, Active=true}, ui)
new("UICorner", {CornerRadius=UDim.new(0,12)}, frame)
new("UIStroke", {Color=Color3.fromRGB(136,98,199), Thickness=1.3}, frame)
local title = new("TextLabel", {Text="NEEDLE FINDER  0.2", Size=UDim2.new(1,-55,0,38),
    Position=UDim2.fromOffset(14,3), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(225,208,255), TextSize=17,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left},frame)
local minimize = new("TextButton", {Text="−", Size=UDim2.fromOffset(33,29),
    Position=UDim2.new(1,-40,0,7), BackgroundColor3=Color3.fromRGB(59,47,79),
    TextColor3=Color3.new(1,1,1), TextSize=22, BorderSizePixel=0},frame)
new("UICorner", {CornerRadius=UDim.new(0,7)}, minimize)
statusLabel = new("TextLabel", {Text="Iniciando...", Size=UDim2.new(1,-26,0,27),
    Position=UDim2.fromOffset(13,46), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(240,219,120), TextSize=13,
    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold},frame)
detailLabel = new("TextLabel", {Text="", Size=UDim2.new(1,-26,0,54),
    Position=UDim2.fromOffset(13,74), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(200,196,210), TextSize=12,
    TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top, Font=Enum.Font.Gotham},frame)

local function button(text, x, y, w, fn)
    local b = new("TextButton", {Text=text, Size=UDim2.fromOffset(w,36),
        Position=UDim2.fromOffset(x,y), BackgroundColor3=Color3.fromRGB(68,53,101),
        TextColor3=Color3.new(1,1,1), TextSize=12, BorderSizePixel=0,
        Font=Enum.Font.GothamBold},frame)
    new("UICorner", {CornerRadius=UDim.new(0,8)}, b)
    connect(b.MouseButton1Click, fn)
    return b
end

scanButton = button("Buscar agora",13,133,171,scan)
monitorButton = button("Monitor: ON",195,133,171,function()
    S.monitoring = not S.monitoring
    monitorButton.Text = S.monitoring and "Monitor: ON" or "Monitor: OFF"
    if S.monitoring then scan() end
end)
espButton = button("ESP: ON",13,177,171,function()
    S.esp = not S.esp
    espButton.Text = S.esp and "ESP: ON" or "ESP: OFF"
    updateESP()
end)
button("Ir ate agulha",195,177,171,teleport)
button("Tentar coletar",13,221,171,interact)
button("Copiar diagnostico",195,221,171,function()
    local clip = (type(setclipboard)=="function" and setclipboard)
        or (type(toclipboard)=="function" and toclipboard)
    if not clip then status("Clipboard indisponivel", "O executor nao oferece setclipboard."); return end
    local ok = pcall(clip, report())
    status(ok and "Diagnostico copiado" or "Falha ao copiar")
end)
button("Encerrar script",13,265,353,function() S.close() end)

local floating = new("TextButton", {Text="N", Size=UDim2.fromOffset(44,44),
    Position=UDim2.fromOffset(18,180), Visible=false,
    BackgroundColor3=Color3.fromRGB(68,53,101),
    TextColor3=Color3.new(1,1,1), TextSize=20, BorderSizePixel=0,
    Font=Enum.Font.GothamBlack},ui)
new("UICorner", {CornerRadius=UDim.new(1,0)}, floating)
local function show(value)
    frame.Visible = value
    floating.Visible = not value
end
connect(minimize.MouseButton1Click,function() show(false) end)
connect(floating.MouseButton1Click,function() show(true) end)
connect(UserInputService.InputBegan,function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then show(not frame.Visible) end
end)

-- Drag the top area with mouse or touch.
local dragging, dragStart, startPos, dragInput = false, nil, nil, nil
connect(title.InputBegan,function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos, dragInput = true, input.Position, frame.Position, input
    end
end)
connect(UserInputService.InputChanged,function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= dragInput then return end
    local d = input.Position-dragStart
    frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
        startPos.Y.Scale,startPos.Y.Offset+d.Y)
end)
connect(UserInputService.InputEnded,function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == dragInput then
        dragging = false
    end
end)

S.close = function()
    if not S.alive then return end
    S.alive, S.monitoring = false, false
    S.scanId = S.scanId + 1
    clearESP()
    for _, c in ipairs(S.connections) do pcall(function() c:Disconnect() end) end
    if ui then ui:Destroy() end
    if global.__NeedleFinder == S then global.__NeedleFinder = nil end
end

if game.PlaceId ~= PLACE and game.GameId ~= UNIVERSE then
    status("Jogo diferente detectado", "PlaceId " .. tostring(game.PlaceId)
        .. ". Este hub foi feito para Search For The Needle.")
else
    scan()
end

connect(workspace.DescendantAdded, function(obj)
    if S.monitoring and not S.scanning
        and string.lower(obj.Name):find("needle", 1, true) then
        task.delay(0.3, function()
            if S.alive and S.monitoring and not S.scanning then scan() end
        end)
    end
end)

task.spawn(function()
    while S.alive do
        if S.monitoring and not S.scanning and os.clock()-S.lastScan >= 7 then scan() end
        if S.esp and S.part and not validPart(S.part) then
            S.target, S.part = nil, nil
            updateESP()
            status("Objeto desapareceu", "Aguardando a proxima varredura.")
        end
        task.wait(1)
    end
end)

print("[Needle Finder] 0.2 carregado | PlaceId=" .. tostring(game.PlaceId))
