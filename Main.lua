--[[
    FLOQUITAVE v8.0 - base de diagnostico
    Execute no Third Sea. Cada acao e manual; nada comeca sozinho.
    Esta versao testa carregamento, interface, inventario, NPC, craft e V4.
    Farm automatico, trials e raids ainda nao foram implementados aqui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not player then return warn("[Floquitave] LocalPlayer indisponivel") end

local environment = (type(getgenv) == "function" and getgenv()) or _G
local previous = environment.__FloquitaveDiagnostic
if type(previous) == "table" and type(previous.cleanup) == "function" then
    pcall(previous.cleanup)
end

local session = {alive = true, connections = {}, gui = nil}
environment.__FloquitaveDiagnostic = session
local statusLabel
local historyLabel
local history = {}

local function status(message)
    message = tostring(message)
    print("[Floquitave] " .. message)
    if not session.alive then return end
    table.insert(history, 1, message)
    if #history > 7 then table.remove(history) end
    if statusLabel and statusLabel.Parent then statusLabel.Text = message end
    if historyLabel and historyLabel.Parent then
        historyLabel.Text = table.concat(history, "\n")
    end
end

local function track(connection)
    table.insert(session.connections, connection)
    return connection
end

local function rootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function invokeComm(...)
    local arguments = table.pack(...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("CommF_")
    if not remote or not remote:IsA("RemoteFunction") then
        return false, "Remotes.CommF_ indisponivel"
    end
    return pcall(function()
        return remote:InvokeServer(table.unpack(arguments, 1, arguments.n))
    end)
end

local function invokeNet(name, payload)
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    local remote = net and net:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteFunction") then
        return false, "Modules.Net." .. name .. " indisponivel"
    end
    return pcall(function() return remote:InvokeServer(payload) end)
end

local function inventory()
    local ok, data = invokeComm("getInventory")
    if not ok or type(data) ~= "table" then
        return nil, "Nao foi possivel ler inventario: " .. tostring(data)
    end
    local counts = {scrap = 0, ember = 0, magnet = 0}
    for key, item in pairs(data) do
        local name, count
        if type(item) == "table" then
            name = tostring(item.Name or item.name or key)
            count = tonumber(item.Count or item.count or item.Amount or item.amount or 1) or 0
        elseif type(key) == "string" then
            name = key
            count = tonumber(item) or 0
        end
        if name then
            name = string.lower(name)
            if name == "scrap metal" then counts.scrap = count end
            if name == "blaze ember" then counts.ember = count end
            if name == "volcanic magnet" then counts.magnet = count end
        end
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    if (backpack and backpack:FindFirstChild("Volcanic Magnet"))
        or (character and character:FindFirstChild("Volcanic Magnet")) then
        counts.magnet = math.max(counts.magnet, 1)
    end
    return counts
end

local function showMaterials()
    local counts, err = inventory()
    if not counts then return status(err) end
    status("Scrap " .. counts.scrap .. "/10 | Ember " .. counts.ember
        .. "/15 | Magnet " .. counts.magnet)
    return counts
end

local function moveTo(position, label)
    local root = rootPart()
    if not root then
        status("Personagem ainda nao carregou")
        return false
    end
    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 3))
    task.wait(0.4)
    local current = rootPart()
    local distance = current and (current.Position - position).Magnitude or math.huge
    status(label .. ": distancia final " .. math.floor(distance) .. " studs")
    return distance <= 8
end

local function dojoEntrance()
    local root = rootPart()
    if not root then return false end
    if (root.Position - Vector3.new(5841, 1208, 884)).Magnitude > 450 then
        local ok, answer = invokeComm("requestEntrance", Vector3.new(5661.532, 1013.091, -334.965))
        status("Entrada Dojo: " .. tostring(ok) .. " / " .. tostring(answer))
        if not ok then return false end
    end
    return true
end

local function dojoPosition()
    local npcs = workspace:FindFirstChild("NPCs")
    local npc = npcs and npcs:FindFirstChild("Dojo Trainer", true)
    if npc then
        if npc:IsA("BasePart") then return npc.Position end
        if npc:IsA("Model") then return npc:GetPivot().Position end
        local part = npc:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    status("Dojo Trainer nao carregado; usando coordenada do arquivo")
    return Vector3.new(5855.196, 1208.322, 872.714)
end

local function goDojo()
    if dojoEntrance() then moveTo(dojoPosition(), "Dojo Trainer") end
end

local function requestDojo()
    if not dojoEntrance() then return end
    local position = dojoPosition()
    local root = rootPart()
    if not root or (root.Position - position).Magnitude > 8 then
        if not moveTo(position, "Dojo Trainer") then
            return status("Distancia ao Dojo Trainer maior que 8; quest nao solicitada")
        end
    end
    local ok, answer = invokeNet("RF/InteractDragonQuest", {
        NPC = "Dojo Trainer", Command = "RequestQuest"
    })
    status("Dojo RequestQuest: " .. tostring(ok) .. " / " .. tostring(answer))
end

local function craftMagnet()
    local before = showMaterials()
    if not before then return end
    if before.magnet > 0 then return status("Magnet ja consta no inventario") end
    if before.scrap < 10 or before.ember < 15 then
        return status("Faltam materiais. Esta base ainda nao farma automaticamente.")
    end
    if not dojoEntrance() then return end
    if not moveTo(Vector3.new(5864.864, 1209.551, 812.775), "Dragon Hunter / craft") then
        return status("Distancia de craft nao confirmada; pedido cancelado")
    end
    local ok, answer = invokeComm("CraftItem", "Craft", "Volcanic Magnet")
    if not ok or answer == false then
        return status("Craft recusado: " .. tostring(answer))
    end
    task.wait(1)
    local after, err = inventory()
    if not after then return status("Craft enviado; verificacao falhou: " .. err) end
    status(after.magnet > before.magnet and "Magnet confirmado no inventario"
        or "Craft enviado; magnet ainda nao confirmado. Resposta: " .. tostring(answer))
end

local doors = {
    Human = Vector3.new(29221.822, 14890.976, -205.991),
    Angel = Vector3.new(28960.158, 14919.624, 235.039),
    Shark = Vector3.new(28231.176, 14890.976, -211.642),
    Cyborg = Vector3.new(28502.682, 14895.976, -423.728),
    Ghoul = Vector3.new(28674.244, 14890.677, 445.431),
    Rabbit = Vector3.new(29012.342, 14890.976, -380.149)
}

local temple = Vector3.new(28286.355, 14895.302, 102.625)
local function goTemple()
    local root = rootPart()
    if not root then
        status("Personagem ainda nao carregou")
        return false
    end
    if (root.Position - temple).Magnitude > 1500 then
        local ok, answer = invokeComm("requestEntrance", temple)
        status("Entrada templo: " .. tostring(ok) .. " / " .. tostring(answer))
        if not ok then return false end
    end
    return moveTo(temple, "Temple of Time")
end

local function goRaceDoor()
    local data = player:FindFirstChild("Data")
    local value = data and data:FindFirstChild("Race")
    local race = value and tostring(value.Value) or ""
    local aliases = {Skypiea = "Angel", Fishman = "Shark", Mink = "Rabbit"}
    race = aliases[race] or race
    local position = doors[race]
    if not position then
        return status("Raca sem porta mapeada: " .. (race ~= "" and race or "desconhecida"))
    end
    if goTemple() then
        moveTo(position, "Porta " .. race)
    else
        status("Templo nao confirmado; porta nao acionada")
    end
end

local function scanEvents()
    local map = workspace:FindFirstChild("Map")
    if not map then return status("workspace.Map nao encontrado") end
    local found = {}
    for _, object in ipairs(map:GetDescendants()) do
        local name = string.lower(object.Name)
        if name:find("mirage", 1, true) or name:find("prehistoric", 1, true)
            or name:find("frozen", 1, true) then
            table.insert(found, object.Name)
            if #found >= 5 then break end
        end
    end
    status(#found > 0 and ("Eventos no mapa: " .. table.concat(found, ", "))
        or "Nenhum evento correspondente carregado no mapa")
end

local gui = Instance.new("ScreenGui")
gui.Name = "Floquitave_v8_Diagnostic"
gui.ResetOnSpawn = false
local mounted = pcall(function() gui.Parent = CoreGui end)
if not mounted then gui.Parent = player:WaitForChild("PlayerGui", 10) end
if not gui.Parent then return warn("[Floquitave] Nao foi possivel montar a interface") end
session.gui = gui

local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end

local toggle = make("TextButton", gui, {
    Size = UDim2.fromOffset(115, 36), Position = UDim2.fromOffset(18, 75),
    Text = "Floquitave", BackgroundColor3 = Color3.fromRGB(28, 78, 110),
    TextColor3 = Color3.new(1, 1, 1), TextSize = 16
})
local frame = make("Frame", gui, {
    Size = UDim2.fromOffset(360, 425), Position = UDim2.fromOffset(18, 115),
    BackgroundColor3 = Color3.fromRGB(23, 27, 34), BorderSizePixel = 0
})
make("TextLabel", frame, {
    Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 5),
    BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Floquitave v8 | diagnostico manual", TextColor3 = Color3.new(1, 1, 1), TextSize = 15
})
statusLabel = make("TextLabel", frame, {
    Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 34),
    BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true, Text = "Pronto", TextColor3 = Color3.fromRGB(140, 225, 170), TextSize = 13
})
local scroll = make("ScrollingFrame", frame, {
    Size = UDim2.new(1, -16, 0, 236), Position = UDim2.fromOffset(8, 78),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
    CanvasSize = UDim2.fromOffset(0, 0)
})
local layout = make("UIListLayout", scroll, {
    Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder
})
track(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 6)
end))

local function addButton(label, action)
    local button = make("TextButton", scroll, {
        Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = Color3.fromRGB(48, 58, 70),
        TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Text = label
    })
    track(button.MouseButton1Click:Connect(function()
        if not session.alive then return end
        if session.busy then return status("Aguarde a acao atual terminar") end
        session.busy = true
        task.spawn(function()
            local ok, err = pcall(action)
            if not ok then status("ERRO " .. label .. ": " .. tostring(err)) end
            session.busy = false
        end)
    end))
end

addButton("1. Ver materiais do magnet", showMaterials)
addButton("2. Ir ao Dojo Trainer", goDojo)
addButton("3. Pedir quest ao Dojo Trainer", requestDojo)
addButton("4. Tentar craft (se tiver materiais)", craftMagnet)
addButton("5. Ir ao Temple of Time", goTemple)
addButton("6. Ir a porta da minha raca", goRaceDoor)
addButton("7. Procurar eventos carregados", scanEvents)

historyLabel = make("TextLabel", frame, {
    Size = UDim2.new(1, -16, 0, 100), Position = UDim2.fromOffset(8, 318),
    BackgroundColor3 = Color3.fromRGB(17, 20, 26), TextColor3 = Color3.fromRGB(210, 210, 210),
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true, TextSize = 11, Text = "Historico de resultados aparece aqui"
})
track(toggle.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end))

session.cleanup = function()
    session.alive = false
    for _, connection in ipairs(session.connections) do
        pcall(function() connection:Disconnect() end)
    end
    if session.gui then pcall(function() session.gui:Destroy() end) end
end

status("Interface carregada. Use os botoes para testar uma acao por vez.")
