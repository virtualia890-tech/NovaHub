
-- NEEDLE KAITUN 1.0 | Search For The Needle
-- Cole todo este TXT no executor dentro do lobby ou de um dos mapas.
-- O script comeca automaticamente. Use Pausar/Continuar, Mapa e Dificuldade no painel.
-- Ao usar Encerrar, a copia local da continuidade e desativada.
-- Nenhuma compra com Robux e realizada.

local source = [====[
-- Needle Kaitun 1.0 | Search For The Needle | Garage Games
-- Este arquivo e iniciado pelo TXT distribuido junto com ele.
-- Apenas moeda do jogo; nenhuma compra de gamepass/Robux.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
while not player do task.wait(0.1); player = Players.LocalPlayer end
if game.GameId ~= 10756011174 then
    warn("[Needle Kaitun] Este jogo nao e Search For The Needle")
    return
end

local global = (type(getgenv) == "function" and getgenv()) or _G
if global.__NeedleKaitunSession and type(global.__NeedleKaitunSession.stop) == "function" then
    pcall(global.__NeedleKaitunSession.stop, false)
end
if global.__NeedleFinder and type(global.__NeedleFinder.stop) == "function" then
    pcall(global.__NeedleFinder.stop)
end

local S = {
    alive = true, auto = true, phase = "iniciando", detail = "", started = os.clock(),
    picks = 0, sells = 0, upgrades = 0, gems = 0, wins = 0, rounds = 0,
    lastPick = 0, lastFork = 0, lastVacuum = 0, lastTnt = 0,
    lastBuy = 0, lastGemBuy = 0, lastHandIn = 0, lastRoundAction = 0,
    lastState = 0, lastCache = 0, hay = {}, cursor = 1, recent = {},
    lastObjectiveScan = 0, objectiveCache = nil, roundHandled = false,
    needleId = nil, needlePos = nil, needleAnchor = nil,
    lastNeedleLookup = 0, tntLit = false,
    connections = {}, events = {}, maxEvents = 120,
}
global.__NeedleKaitunSession = S

local settings = {
    map = "FARMHOUSE", difficulty = "NORMAL", sellPercent = 100,
    buyTools = true, buyUpgrades = true, buyGemUpgrades = true,
    useFork = true, useVacuum = true, useTnt = true,
    collectGems = true, antiAfk = true,
}
local settingsPath = "NeedleKaitun_settings.json"
if type(readfile) == "function" then
    pcall(function()
        local saved = HttpService:JSONDecode(readfile(settingsPath))
        if type(saved) == "table" then
            for key, value in pairs(settings) do
                if type(saved[key]) == type(value) then settings[key] = saved[key] end
            end
        end
    end)
end
local function saveSettings()
    if type(writefile) == "function" then
        pcall(writefile, settingsPath, HttpService:JSONEncode(settings))
    end
end
local isLobby = game.PlaceId == 77108422251420
local NH = RS:FindFirstChild("NeedleHaystack")
if not isLobby and not NH then NH = RS:WaitForChild("NeedleHaystack", 15) end
local Config = {}
if NH then
    local module = NH:WaitForChild("Config", 10)
    if module then
        local ok, result = pcall(require, module)
        if ok and type(result) == "table" then Config = result end
    end
end

local function attr(name, fallback)
    local value = player:GetAttribute(name)
    if value == nil then return fallback end
    return value
end
local function num(name, fallback)
    return tonumber(attr(name, fallback)) or fallback or 0
end
local function root()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function cash()
    local stats = player:FindFirstChild("leaderstats")
    local value = stats and stats:FindFirstChild("Cash")
    return value and tonumber(value.Value) or 0
end
local function wins()
    local stats = player:FindFirstChild("leaderstats")
    local value = stats and stats:FindFirstChild("Wins")
    return value and tonumber(value.Value) or 0
end
local function log(message)
    S.detail = tostring(message):sub(1, 220)
    table.insert(S.events, string.format("+%.1fs %s", os.clock() - S.started, S.detail))
    if #S.events > S.maxEvents then table.remove(S.events, 1) end
end
local function phase(name, detail)
    S.phase = name
    if detail and S.detail ~= detail then log(detail) end
end
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(S.connections, c)
    return c
end
local function remote(name)
    return NH and NH:FindFirstChild(name)
end
local function fire(name, ...)
    local r = remote(name)
    if not r or not r:IsA("RemoteEvent") then
        log("Remote ausente: " .. name)
        return false
    end
    local args = table.pack(...)
    local ok, err = pcall(function() r:FireServer(table.unpack(args, 1, args.n)) end)
    if not ok then log(name .. ": " .. tostring(err)) end
    return ok
end

local function hold(cframe, seconds)
    local r = root()
    if not r or not S.alive or not S.auto then return false end
    local limit = os.clock() + math.max(0.04, seconds or 0.12)
    repeat
        if not S.alive or not S.auto or r ~= root() then return false end
        r.CFrame = cframe
        pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
        RunService.Heartbeat:Wait()
    until os.clock() >= limit
    return true
end
local function moveNear(pos, distance)
    local r = root()
    if not r then return false end
    if (r.Position - pos).Magnitude <= (distance or 16) then return true end
    local stand = pos + Vector3.new(0, 4, 3)
    return hold(CFrame.lookAt(stand, Vector3.new(pos.X, stand.Y, pos.Z)), 0.28)
end

local path = "NeedleKaitun_AutoLoad.lua"
do
    local q = queue_on_teleport or (syn and syn.queue_on_teleport)
    local source = global.__NeedleKaitunSource
    local hasFile = type(readfile) == "function"
        and (type(isfile) ~= "function" or isfile(path))
    local possible = type(q) == "function" and (hasFile or type(source) == "string")
    S.canContinue = possible
    if possible then
        local loadCode = hasFile
            and "local ok,s=pcall(readfile,'NeedleKaitun_AutoLoad.lua'); if not ok then s=nil end"
            or "local s=" .. string.format("%q", source)
        local code = "if not game:IsLoaded() then game.Loaded:Wait() end "
            .. "if game.GameId == 10756011174 then " .. loadCode
            .. "; if s then local f=loadstring(s); if f then f() end end end"
        local ok, err = pcall(q, code)
        if not ok then S.canContinue = false; log("Fila de teleporte: " .. tostring(err)) end
    else
        log("Sem queue_on_teleport: reexecute o TXT depois do teleporte")
    end
end

local hotbar
pcall(function()
    local scripts = player:WaitForChild("PlayerScripts", 10)
    local module = scripts and scripts:WaitForChild("HotbarSlots", 10)
    if module then hotbar = require(module) end
end)
local function equip(slot)
    if not hotbar or type(hotbar.select) ~= "function" then return false end
    if type(hotbar.getEquipped) == "function" then
        local ok, current = pcall(hotbar.getEquipped)
        if ok and current == slot then return true end
    end
    local ok = pcall(hotbar.select, slot)
    if not ok then return false end
    if type(hotbar.getEquipped) ~= "function" then return true end
    local confirmed, current = pcall(hotbar.getEquipped)
    return confirmed and current == slot
end

local function refreshHay(force)
    if not NH then return end
    if not force and #S.hay > 0 and os.clock() - S.lastCache < 8 then return end
    local folder = workspace:FindFirstChild("HaystackClient")
    S.hay = folder and folder:GetChildren() or {}
    if S.cursor > #S.hay then S.cursor = 1 end
    S.lastCache = os.clock()
end
local function objective()
    refreshHay(false)
    if S.objectiveCache and S.objectiveCache.Parent
        and S.objectiveCache:GetAttribute("IsNeedleObjective") then
        return S.objectiveCache
    end
    if os.clock() - S.lastObjectiveScan < (S.needleId and 2 or 6) then return nil end
    S.lastObjectiveScan = os.clock()
    for _, part in ipairs(S.hay) do
        if part.Parent and part:GetAttribute("IsNeedleObjective") then
            S.objectiveCache = part
            return part
        end
    end
    S.objectiveCache = nil
    return nil
end
local function pieceById(id)
    if not id then return nil end
    refreshHay(false)
    for _, part in ipairs(S.hay) do
        if part.Parent and part:GetAttribute("HayId") == id then return part end
    end
    return nil
end
local function chooseHay(focus, radius)
    refreshHay(false)
    local r = root()
    local n = #S.hay
    if not r or n == 0 then return nil end
    local chosen, score
    local budget = math.min(n, focus and 1800 or 750)
    for _ = 1, budget do
        if S.cursor > n then S.cursor = 1 end
        local part = S.hay[S.cursor]
        S.cursor = S.cursor + 1
        if part and part.Parent and part:IsA("BasePart") then
            local id = part:GetAttribute("HayId")
            local recent = id and S.recent[id]
            local nearby = not focus or (part.Position - focus).Magnitude <= radius
            if id and nearby and (not recent or os.clock() - recent >= 2.5) then
                local d = (r.Position - part.Position).Magnitude
                local value = d + (d > 17 and 40 or 0)
                local mutation = tostring(part:GetAttribute("HayMutation") or "")
                if mutation ~= "" and mutation ~= "Normal" then value = value - 12 end
                if not score or value < score then chosen, score = part, value end
            end
        end
    end
    return chosen
end
local function grabNeighbors(piece)
    local count = math.max(1, math.floor(num("HayGrabCount", 1)))
    local radius = num("HayGrabRadius", 0)
    if count <= 1 or radius <= 0 then return {} end
    local folder = workspace:FindFirstChild("HaystackClient")
    if not folder then return {} end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {folder}
    params.MaxParts = math.min(60, count * 6)
    local ok, found = pcall(function()
        return workspace:GetPartBoundsInRadius(piece.Position, radius, params)
    end)
    if not ok then return {} end
    local ids, used = {}, {[piece:GetAttribute("HayId")] = true}
    for _, part in ipairs(found) do
        local id = part:GetAttribute("HayId")
        if id and not used[id] then
            used[id] = true
            ids[#ids + 1] = id
            if #ids >= count - 1 then break end
        end
    end
    return ids
end

local handAt, forkAt, vacAt, tntAt = 0, 0, 0, 0
local function pick(part)
    if not part or not part.Parent then return false end
    local id = part:GetAttribute("HayId")
    if not id then return false end
    if not moveNear(part.Position, math.max(7, (tonumber(Config.INTERACT_DISTANCE) or 20) - 3)) then return false end
    S.recent[id] = os.clock()
    local ok = fire("PickHay", id, grabNeighbors(part))
    if ok then S.picks = S.picks + 1 end
    handAt = os.clock() + math.max(0.16, num("HayPickCooldown", tonumber(Config.PICK_COOLDOWN) or 0.55)) + 0.04
    return ok
end
local function fork(part)
    if not settings.useFork or not attr("PitchforkOwned", false)
        or os.clock() < forkAt or not part then return end
    local r = root()
    if not r or (r.Position-part.Position).Magnitude > (tonumber(Config.INTERACT_DISTANCE) or 20)-2 then return end
    equip(tonumber(Config.PITCHFORK_SLOT_INDEX) or 3)
    local id = part:GetAttribute("HayId")
    if id and fire("PitchforkDig", id) then
        S.recent[id] = os.clock()
        forkAt = os.clock() + num("PitchforkCooldown", tonumber(Config.PITCHFORK_COOLDOWN) or 0.85) + 0.05
    end
end
local function vacuum(part)
    if not settings.useVacuum or not attr("VacuumOwned", false)
        or attr("VacuumState", "Ready") == "Overheated"
        or attr("VacuumOverheated", false) or os.clock() < vacAt then return false end
    local r = root()
    if not r or (r.Position - part.Position).Magnitude > (tonumber(Config.VACUUM_RANGE) or 11) - 1 then
        return false
    end
    equip(tonumber(Config.VACUUM_SLOT_INDEX) or 5)
    if not fire("VacuumAction", "Start") then return false end
    RunService.Heartbeat:Wait()
    local ids, seen = {}, {}
    local folder = workspace:FindFirstChild("HaystackClient")
    if folder then
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {folder}
        params.MaxParts = 36
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInRadius(part.Position, 3.5, params)
        end)
        if ok then
            for _, hay in ipairs(parts) do
                local id = hay:GetAttribute("HayId")
                if id and not seen[id] then
                    ids[#ids + 1], seen[id] = id, true
                    S.recent[id] = os.clock()
                    if #ids >= (tonumber(Config.VACUUM_GRAB_COUNT) or 5) then break end
                end
            end
        end
    end
    if #ids > 0 then fire("VacuumAction", "Tick", part.Position, r.Position, ids) end
    fire("VacuumAction", "Stop")
    vacAt = os.clock() + math.max(0.12, tonumber(Config.VACUUM_TICK) or 0.16)
    return true
end
local function tnt(part)
    if not settings.useTnt or not attr("TntOwned", false)
        or os.clock() < tntAt or not remote("TntAction") or not hotbar or not part then return false end
    local pos = part.Position + Vector3.new(0, 14, 7)
    local face = CFrame.lookAt(pos, part.Position)
    if not hold(face, 0.15) then return false end
    if not equip(tonumber(Config.TNT_SLOT_INDEX) or 2) then return false end
    S.tntLit = false
    tntAt = os.clock() + 3
    fire("TntAction", "light")
    local deadline = os.clock() + 1.3
    while S.alive and S.auto and not S.tntLit and os.clock() < deadline do
        hold(face, 0.05)
    end
    if not S.tntLit then return false end
    hold(face, (tonumber(Config.TNT_LIGHT_TIME) or 0.48) + 0.07)
    local velocity = (part.Position - pos).Unit * 22
    fire("TntAction", "throw", face * CFrame.new(0, 1, -1), velocity)
    tntAt = os.clock() + num("TntCooldown", tonumber(Config.TNT_COOLDOWN) or 20) + 0.2
    log("TNT lancado")
    return true
end

local function sellPart()
    local model = workspace:FindFirstChild("SellModel")
    local part = model and model:FindFirstChild("SellPart")
    if part and part:IsA("BasePart") then return part end
    for _, tagged in ipairs(CollectionService:GetTagged(Config.SELL_PART_NAME or "SellPart")) do
        if tagged:IsA("BasePart") and tagged:IsDescendantOf(workspace) then return tagged end
    end
    return nil
end
local function sell()
    local before = num("HayHeld", 0)
    if before <= 0 then return true end
    local part = sellPart()
    if not part then phase("venda", "SellPart nao carregado"); return false end
    phase("venda")
    for _ = 1, 3 do
        if not hold(CFrame.new(part.Position + Vector3.new(0, 3, 0)), 0.4) then return false end
        fire("SellHay")
        local deadline = os.clock() + 1.3
        while S.alive and S.auto and num("HayHeld", 0) >= before and os.clock() < deadline do
            hold(CFrame.new(part.Position + Vector3.new(0, 3, 0)), 0.12)
        end
        if num("HayHeld", 0) < before then
            S.sells = S.sells + 1
            log("venda confirmada: " .. before .. " -> " .. num("HayHeld", 0))
            return true
        end
    end
    log("venda nao confirmada; mochila=" .. num("HayHeld", 0))
    return false
end

local toolOrder = {
    {name="Pitchfork", attr="PitchforkOwned", cost=8},
    {name="Tnt", attr="TntOwned", cost=25},
    {name="Vacuum", attr="VacuumOwned", cost=69.99},
}
local baseTracks = {"Speed", "Grab", "Capacity", "Value"}
local toolTracks = {
    PitchforkOwned={"Pitchfork", "PitchforkCooldown", "PitchforkHold"},
    TntOwned={"TntCooldown", "TntPower", "TntLuck"},
    VacuumOwned={"VacuumPower", "VacuumCooling", "VacuumRuntime"},
    DroneOwned={"DroneSpeed", "DroneGrab", "DroneCapacity"},
}
local function costOf(track)
    local config = type(Config.UPGRADE_TRACKS) == "table" and Config.UPGRADE_TRACKS[track]
    local levels = config and config.Levels
    local nextLevel = levels and levels[num("HayUpgrade" .. track, 1) + 1]
    return nextLevel and (tonumber(nextLevel.Cost) or math.huge)
        * (tonumber(Config.UPGRADE_COST_MULTIPLIER) or 1) or nil
end
local function shop()
    if not NH or os.clock() - S.lastBuy < 6 then return end
    S.lastBuy = os.clock()
    local pending
    if settings.buyTools then
        for _, tool in ipairs(toolOrder) do
            if not attr(tool.attr, false) then pending = tool; break end
        end
        if pending and cash() >= pending.cost then
            local before = attr(pending.attr, false)
            fire("BuyShopItem", pending.name)
            task.wait(0.4)
            if not before and attr(pending.attr, false) then
                log("comprou " .. pending.name)
                pending = nil
            end
        end
        if not attr("DroneOwned", false) and num("Gems", 0) >= 40 then
            fire("BuyShopItem", "Drone")
        end
        if attr("DroneOwned", false) and not attr("DroneDeployed", false) then
            fire("DeployDrone")
        end
    end
    if not settings.buyUpgrades or not remote("BuyUpgrade") then return end
    local tracks = {}
    for _, name in ipairs(baseTracks) do tracks[#tracks + 1] = name end
    for flag, names in pairs(toolTracks) do
        if attr(flag, false) then
            for _, name in ipairs(names) do tracks[#tracks + 1] = name end
        end
    end
    local blocked = {}
    for _ = 1, 12 do
        if not S.alive or not S.auto then return end
        local selected, price
        for _, name in ipairs(tracks) do
            local cost = not blocked[name] and costOf(name)
            local reserve = pending and name ~= "Speed" and name ~= "Grab"
                and name ~= "Capacity" and pending.cost or 0
            if cost and cost + reserve <= cash()
                and (not price or cost < price) then selected, price = name, cost end
        end
        if not selected then return end
        local key = "HayUpgrade" .. selected
        local level = num(key, 1)
        fire("BuyUpgrade", selected)
        local deadline = os.clock() + 1
        while S.alive and num(key, 1) <= level and os.clock() < deadline do task.wait(0.06) end
        if num(key, 1) > level then
            S.upgrades = S.upgrades + 1
            log("melhoria " .. selected .. " " .. num(key, 1))
        else
            blocked[selected] = true
        end
    end
end

local function collectGem()
    if not settings.collectGems or not remote("CollectGem") then return false end
    local folder = workspace:FindFirstChild("GemsClient")
    if not folder then return false end
    for _, gem in ipairs(folder:GetChildren()) do
        local part = gem:IsA("BasePart") and gem or gem:FindFirstChildWhichIsA("BasePart", true)
        local id = part and (part:GetAttribute("GemId") or gem:GetAttribute("GemId"))
        if id and not S.recent["g" .. tostring(id)] then
            S.recent["g" .. tostring(id)] = os.clock()
            if hold(CFrame.new(part.Position + Vector3.new(0, 3, 0)), 0.15)
                and fire("CollectGem", id) then S.gems = S.gems + 1 end
            return true
        end
    end
    return false
end

local function claimNeedle()
    local obj = objective()
    if obj then
        phase("coletando agulha")
        if hold(CFrame.new(obj.Position + Vector3.new(0, 4, 2)), 0.2) then
            fire("PickHay", "Objective")
            task.wait(0.5)
        end
        return true
    end
    local anchor = S.needleAnchor
    if (not anchor or not anchor.Parent) and os.clock() - S.lastNeedleLookup >= 8 then
        S.lastNeedleLookup = os.clock()
        anchor = pieceById(S.needleId)
        S.needleAnchor = anchor
    end
    if anchor then S.needlePos = anchor.Position end
    if not S.needlePos then return false end
    phase("escavando em torno da agulha")
    local part = chooseHay(S.needlePos, tonumber(Config.NEEDLE_DIG_RADIUS) or 5.5)
    if part then return pick(part) end
    return false
end
local function handIn()
    if os.clock() - S.lastHandIn < 2 then return end
    S.lastHandIn = os.clock()
    local npc = workspace:FindFirstChild("NPC")
    local farmer = npc and npc:FindFirstChild("Farmer_NPC")
    if not farmer then phase("entrega", "Farmer_NPC nao carregado"); return end
    phase("entregando agulha")
    equip(tonumber(Config.NEEDLE_SLOT_INDEX) or 4)
    local pos = farmer:GetPivot().Position
    if hold(CFrame.lookAt(pos + farmer:GetPivot().LookVector * 5 + Vector3.new(0, 2, 0), pos), 0.35) then
        fire("NeedleHandIn")
        task.wait(0.7)
        if not attr("NeedleOwned", false) then log("agulha entregue; aguardando fim da rodada") end
    end
end
local function afterWin()
    phase("rodada concluida")
    if not S.roundHandled then
        S.roundHandled = true
        S.completedAt = os.clock()
        S.wins = S.wins + 1
        log("vitoria confirmada")
    end
    if os.clock() - S.completedAt < 4 then return end
    if os.clock() - S.lastRoundAction < 12 then return end
    S.lastRoundAction = os.clock()
    -- O pedido e voltar ao lobby, comprar melhorias permanentes e iniciar outra.
    if fire("ReturnToLobby") then log("volta ao lobby solicitada") end
end

local function mapStep()
    if not NH then phase("aguardando", "NeedleHaystack nao carregado"); return 2 end
    if attr("NeedleRoundComplete", false) then afterWin(); return 1 end
    if attr("NeedleInputLocked", false) then phase("cutscene"); return 0.6 end
    if attr("NeedleOwned", false) then handIn(); return 0.5 end
    local held = num("HayHeld", 0)
    local capacity = attr("InfiniteBagOwned", false) and 200 or num("HayCapacity", 25)
    if held >= math.max(1, math.floor(capacity * settings.sellPercent / 100)) then
        if sell() then shop() end
        return 0.4
    end
    if S.needleId or objective() then
        if claimNeedle() then return 0.55 end
    end
    if collectGem() then return 0.1 end
    shop()
    local part = chooseHay()
    if not part then phase("aguardando feno", "HaystackClient sem objetos carregados"); return 1 end
    phase("coletando feno")
    local vacReady = settings.useVacuum and attr("VacuumOwned",false)
        and not attr("VacuumOverheated",false)
        and attr("VacuumState","Ready") ~= "Overheated"
    local reach = vacReady and math.max(5, (tonumber(Config.VACUUM_RANGE) or 11)-3)
        or math.max(7, (tonumber(Config.INTERACT_DISTANCE) or 20)-3)
    if not moveNear(part.Position, reach) then return 0.4 end
    if settings.useTnt and os.clock() >= tntAt and tnt(part) then return 0.35 end
    if os.clock() >= handAt then pick(part) end
    local toolTarget = chooseHay(part.Position, 5) or chooseHay()
    if toolTarget and not vacuum(toolTarget) then fork(toolTarget) end
    return math.clamp(handAt - os.clock(), 0.12, 0.7)
end

local function lobbyRemote(service, class)
    local packages = RS:FindFirstChild("Packages")
    local networker = packages and packages:FindFirstChild("Networker")
    local services = networker and networker:FindFirstChild("_remotes")
    local folder = services and services:FindFirstChild(service)
    local value = folder and folder:FindFirstChild(class)
    return value
end
local function gemUpgrades()
    if not settings.buyGemUpgrades or os.clock() - S.lastGemBuy < 12 then return end
    S.lastGemBuy = os.clock()
    local shopRemote = lobbyRemote("ShopUI", "RemoteFunction")
    local shared = RS:FindFirstChild("Shared")
    local configs = shared and shared:FindFirstChild("Configs")
    local module = configs and configs:FindFirstChild("UpgradeConfig")
    if not shopRemote or not module then log("loja de Gems indisponivel"); return end
    local ok, data = pcall(require, module)
    if not ok or type(data) ~= "table" or type(data.Upgrades) ~= "table" then return end
    for _ = 1, 20 do
        if not S.alive or not S.auto then return end
        local best, cost, key
        for _, upgrade in ipairs(data.Upgrades) do
            local attribute = "Upgrade" .. tostring(upgrade.DataKey or upgrade.Id)
            local level = num(attribute, 0)
            local price = upgrade.Prices and tonumber(upgrade.Prices[level + 1])
            if price and price <= num("Gems", 0)
                and (not cost or price < cost) then
                best, cost, key = upgrade, price, attribute
            end
        end
        if not best then return end
        local before = num(key, 0)
        local invoked, response = pcall(function()
            return shopRemote:InvokeServer("BuyUpgrade", best.Id)
        end)
        local deadline = os.clock() + 1
        while S.alive and num(key, 0) <= before and os.clock() < deadline do task.wait(0.06) end
        if num(key, 0) > before then
            S.upgrades = S.upgrades + 1
            log("melhoria permanente " .. tostring(best.Name or best.Id))
        else
            log("compra de Gems recusada: " .. tostring(invoked and response or "erro"))
            return
        end
    end
end

local function startRun()
    local event = lobbyRemote("PartyService", "RemoteEvent")
    local r = root()
    if not event or not r then phase("lobby", "PartyService/personagem indisponivel"); return end
    local pad, distance
    for _, model in ipairs(workspace:GetChildren()) do
        if model.Name == "Teleporter" and model:GetAttribute("PartyStatus") == "Idle" then
            local ok, pivot = pcall(function() return model:GetPivot().Position end)
            if ok then
                local d = (pivot-r.Position).Magnitude
                if not distance or d < distance then pad, distance = model, d end
            end
        end
    end
    if not pad then phase("lobby", "aguardando teleporter livre"); return end
    local pos = pad:GetPivot().Position
    phase("lobby", "entrando no teleporter")
    local deadline = os.clock() + 9
    while S.alive and S.auto and os.clock() < deadline
        and pad:GetAttribute("PartyStatus") ~= "Setup" do
        hold(CFrame.new(pos + Vector3.new(0, 3, 0)), 0.12)
    end
    if pad:GetAttribute("PartyStatus") ~= "Setup" then log("teleporter nao abriu Setup"); return end
    task.wait(0.7)
    local selected = settings.map
    if (selected == "BASEMENT" and wins() < 1)
        or (selected == "RANCH" and wins() < 2) then selected = "FARMHOUSE" end
    local difficulty = settings.difficulty
    local minHardWins = ({FARMHOUSE=1, BASEMENT=2, RANCH=3, GRAVEYARD=1})[selected] or 1
    if difficulty == "HARD" and wins() < minHardWins then difficulty = "NORMAL" end
    local ok, err = pcall(function()
        event:FireServer("CreateParty", selected, 1, difficulty)
    end)
    if not ok then log("CreateParty: " .. tostring(err)); return end
    S.rounds = S.rounds + 1
    phase("lobby", "partida " .. selected .. " solicitada")
    local untilTime = os.clock() + 20
    while S.alive and S.auto and os.clock() < untilTime do
        if pad.Parent == nil then break end
        hold(CFrame.new(pos + Vector3.new(0, 3, 0)), 0.2)
    end
end
local function lobbyStep()
    gemUpgrades()
    startRun()
    return 2
end

if NH then
    local changed = remote("NeedleTargetChanged")
    if changed and changed:IsA("RemoteEvent") then
        connect(changed.OnClientEvent, function(...)
            for _, value in ipairs({...}) do
                if type(value) == "number" and value % 1 == 0 then
                    S.needleId = value
                    local anchor = pieceById(value)
                    S.needleAnchor = anchor
                    S.lastNeedleLookup = os.clock()
                    S.needlePos = anchor and anchor.Position or nil
                    log("alvo da agulha revelado: " .. value)
                    break
                end
            end
        end)
    end
    local tntEvent = remote("TntAction")
    if tntEvent and tntEvent:IsA("RemoteEvent") then
        connect(tntEvent.OnClientEvent, function(state, delay)
            if state == "lit" then S.tntLit = true
            elseif state == "denied" then
                tntAt = os.clock() + (tonumber(delay) or 3) + 0.3
            end
        end)
    end
end

connect(player.Idled, function()
    if not S.alive or not settings.antiAfk then return end
    pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
end)

local guiParent = CoreGui
pcall(function() if type(gethui) == "function" then guiParent = gethui() end end)
local function create(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local gui = create("ScreenGui", {Name="NeedleKaitun_1", ResetOnSpawn=false}, guiParent)
local panel = create("Frame", {Size=UDim2.fromOffset(370, 358),
    Position=UDim2.new(0.5,-185,0.5,-179), BackgroundColor3=Color3.fromRGB(24,22,33),
    Active=true, BorderSizePixel=0}, gui)
create("UICorner", {CornerRadius=UDim.new(0,12)}, panel)
create("UIStroke", {Color=Color3.fromRGB(152,111,222), Thickness=1.2}, panel)
local title = create("TextLabel", {Text="NEEDLE KAITUN  1.0", Size=UDim2.new(1,-60,0,35),
    Position=UDim2.fromOffset(12,4), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(236,220,255), TextSize=17,
    TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.GothamBold}, panel)
local phaseText = create("TextLabel", {Text="Iniciando", Size=UDim2.new(1,-24,0,29),
    Position=UDim2.fromOffset(12,48), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(250,220,113), TextSize=14,
    TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.GothamBold}, panel)
local info = create("TextLabel", {Text="", Size=UDim2.new(1,-24,0,114),
    Position=UDim2.fromOffset(12,80), BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(220,214,230), TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=true, Font=Enum.Font.Code}, panel)
local function button(label, x, y, w, callback)
    local b = create("TextButton", {Text=label, Size=UDim2.fromOffset(w,36),
        Position=UDim2.fromOffset(x,y), BackgroundColor3=Color3.fromRGB(78,55,116),
        TextColor3=Color3.new(1,1,1), TextSize=12,
        Font=Enum.Font.GothamBold, BorderSizePixel=0}, panel)
    create("UICorner", {CornerRadius=UDim.new(0,7)}, b)
    connect(b.MouseButton1Click, callback)
    return b
end
local toggle
local maps = {"FARMHOUSE", "BASEMENT", "RANCH", "GRAVEYARD"}
local mapButton, diffButton
mapButton = button("Mapa: " .. settings.map, 12,198,169,function()
    local index = table.find(maps, settings.map) or 1
    settings.map = maps[index % #maps + 1]
    mapButton.Text = "Mapa: " .. settings.map
    saveSettings()
end)
diffButton = button("Dificuldade: " .. settings.difficulty, 190,198,169,function()
    settings.difficulty = settings.difficulty == "NORMAL" and "HARD" or "NORMAL"
    diffButton.Text = "Dificuldade: " .. settings.difficulty
    saveSettings()
end)
toggle = button("Pausar kaitun", 12,244,169,function()
    S.auto = not S.auto
    toggle.Text = S.auto and "Pausar kaitun" or "Continuar kaitun"
    log(S.auto and "kaitun retomado" or "kaitun pausado")
end)
button("Copiar relatorio", 190,244,169,function()
    local lines = {
        "Needle Kaitun 1.0 | PlaceId=" .. game.PlaceId .. " | GameId=" .. game.GameId,
        "Fase=" .. S.phase .. " | detalhe=" .. S.detail,
        "Ativo=" .. tostring(S.auto) .. " | continuidade=" .. tostring(S.canContinue),
        "Feno=" .. num("HayHeld",0) .. "/" .. num("HayCapacity",25)
            .. " | Cash=" .. cash() .. " | Gems=" .. num("Gems",0),
        "Agulha=" .. tostring(attr("NeedleOwned",false)) .. " | alvo=" .. tostring(S.needleId)
            .. " | rodada concluida=" .. tostring(attr("NeedleRoundComplete",false)),
        "Coletas=" .. S.picks .. " | vendas=" .. S.sells .. " | melhorias=" .. S.upgrades
            .. " | vitorias=" .. S.wins .. " | partidas=" .. S.rounds,
        "Remotes=" .. tostring(NH and NH:GetFullName() or "ausente"), "Historico:",
    }
    for _, entry in ipairs(S.events) do lines[#lines + 1] = entry end
    local clip = (type(setclipboard)=="function" and setclipboard)
        or (type(toclipboard)=="function" and toclipboard)
    if clip then
        local ok = pcall(clip, table.concat(lines,"\n"))
        log(ok and "relatorio copiado" or "falha ao copiar")
    else log("executor sem clipboard") end
end)
button("Encerrar", 12,294,347,function() S.stop(true) end)
local minimize = button("−", 327,5,31,function() panel.Visible=false end)
minimize.Size = UDim2.fromOffset(31,29)
local floating = create("TextButton", {Text="N", Size=UDim2.fromOffset(46,46),
    Position=UDim2.fromOffset(17,165), Visible=false,
    BackgroundColor3=Color3.fromRGB(78,55,116),
    TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBlack,
    TextSize=20, BorderSizePixel=0}, gui)
create("UICorner", {CornerRadius=UDim.new(1,0)}, floating)
connect(floating.MouseButton1Click,function() panel.Visible=true end)
connect(panel:GetPropertyChangedSignal("Visible"),function() floating.Visible=not panel.Visible end)
connect(UserInputService.InputBegan,function(input, processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightControl then
        panel.Visible=not panel.Visible
    end
end)
local dragging, dragStart, startPos = false, nil, nil
connect(title.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
        dragging, dragStart, startPos=true,input.Position,panel.Position
    end
end)
connect(UserInputService.InputChanged,function(input)
    if not dragging or (input.UserInputType~=Enum.UserInputType.MouseMovement
        and input.UserInputType~=Enum.UserInputType.Touch) then return end
    local offset=input.Position-dragStart
    panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+offset.X,
        startPos.Y.Scale,startPos.Y.Offset+offset.Y)
end)
connect(UserInputService.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)

S.stop = function(disableQueue)
    if not S.alive then return end
    S.alive, S.auto = false, false
    if disableQueue and type(writefile) == "function" then pcall(writefile, path, "return") end
    pcall(function() if NH and NH:FindFirstChild("VacuumAction") then NH.VacuumAction:FireServer("Stop") end end)
    for _, connection in ipairs(S.connections) do pcall(function() connection:Disconnect() end) end
    gui:Destroy()
    if global.__NeedleKaitunSession==S then global.__NeedleKaitunSession=nil end
end

task.spawn(function()
    while S.alive do
        phaseText.Text = (S.auto and "▶  " or "Ⅱ  ") .. S.phase
        info.Text = "Local: " .. (isLobby and "Lobby" or "Mapa")
            .. "  |  Feno: " .. num("HayHeld",0) .. "/" .. num("HayCapacity",25)
            .. "\nCash: " .. cash() .. "  |  Gems: " .. num("Gems",0)
            .. "  |  Vitorias: " .. wins()
            .. "\nColetas: " .. S.picks .. "  Vendas: " .. S.sells
            .. "  Melhorias: " .. S.upgrades
            .. "\nAgulha: " .. (attr("NeedleOwned",false) and "na mochila"
                or (S.needleId and "revelada" or "ainda escondida"))
            .. "\n" .. S.detail:sub(1,105)
        task.wait(0.5)
    end
end)

task.spawn(function()
    task.wait(2)
    while S.alive do
        if not S.auto then
            phase("pausado")
            task.wait(0.5)
        else
            local ok, delayOrError = pcall(isLobby and lobbyStep or mapStep)
            if not ok then
                log("ERRO " .. tostring(delayOrError):sub(1,160))
                task.wait(1)
            else
                task.wait(math.max(0.05, tonumber(delayOrError) or 0.5))
            end
        end
    end
end)

log("Kaitun iniciado. Mapa padrao: FARMHOUSE NORMAL; ao vencer, retorna ao lobby.")
print("[Needle Kaitun] 1.0 carregado | PlaceId=" .. game.PlaceId)

]====]
local env = (type(getgenv) == "function" and getgenv()) or _G
env.__NeedleKaitunSource = source
if type(writefile) == "function" then
    pcall(writefile, "NeedleKaitun_AutoLoad.lua", source)
end
local chunk, err = loadstring(source)
if not chunk then
    warn("[Needle Kaitun] Erro ao compilar: " .. tostring(err))
else
    local ok, problem = pcall(chunk)
    if not ok then warn("[Needle Kaitun] Erro ao iniciar: " .. tostring(problem)) end
end
