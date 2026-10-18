-- FLOQUITAVE | Race V4 Kaitun 1.3 | Blox Fruits / Third Sea
-- Script independente: somente etapas diretamente ligadas a Race V4.
-- O painel inicia em modo automatico. Botao Pausar interrompe movimento e acoes.
-- O jogo precisa estar aberto no Third Sea (PlaceId 7449423635).

local function main()
print("[Floquitave V4 1.3] Iniciando | PlaceId="..tostring(game.PlaceId))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UIS=game:GetService("UserInputService")
local vimOk,VIM=pcall(function() return game:GetService("VirtualInputManager") end)
if not vimOk then VIM=nil end
local vuOk,VirtualUser=pcall(function() return game:GetService("VirtualUser") end)
if not vuOk then VirtualUser=nil end

local player = Players.LocalPlayer
local playerDeadline=os.clock()+25
while not player and os.clock()<playerDeadline do task.wait(0.2); player=Players.LocalPlayer end
assert(player,"LocalPlayer não carregou após 25 segundos")
local IS_THIRD_SEA=game.PlaceId==7449423635

local env=_G
if type(getgenv)=="function" then
    local ok,result=pcall(getgenv)
    if ok and type(result)=="table" then env=result end
end
if env.__FloquitaveV4 and type(env.__FloquitaveV4.stop) == "function" then
    pcall(env.__FloquitaveV4.stop)
end
local S = {
    alive=true, auto=IS_THIRD_SEA, phase="Iniciando", detail="", started=os.clock(),
    history={}, connections={}, nonce=0, busy=false,
    cache={}, cacheAt={}, lastAction={},
    trialSeen=false, trialStarted=0, trialEndedAt=0, trialRace=nil,
    gearTouched=false, v3At=0, attackAt=0, skillAt=0, hopAt=0,
    sailDirection=-1, sailLastPos=nil, sailLastAt=0, sailStalls=0,
    boatKeys={}, race=nil, objective=nil, objectiveAt=0,
    attempts={enter=0,quest=0,mirage=0,lever=0,trial=0,pvp=0,gear=0,train=0,buy=0},
    path="Alpha", reportMax=150, remoteStates={},
}
env.__FloquitaveV4 = S

local POS = {
    temple=Vector3.new(28286.355,14895.302,102.625),
    lever=Vector3.new(28575.182,14936.628,72.316),
    clock=Vector3.new(29553.781,15066.613,-88.275),
    ancient=Vector3.new(28981.553,14888.427,-120.246),
    arena=Vector3.new(28766.682,14967.146,-164.133),
    tiki=Vector3.new(-16927.451,9.086,433.864),
    bones=Vector3.new(-9515.372,164.006,5786.061),
    dojo=Vector3.new(5657.886,1013.079,-335.5),
    cyborgSafe=Vector3.new(28654,14898.783,-30),
}
local DOOR = {
    Human=Vector3.new(29221.822,14890.976,-205.991),
    Angel=Vector3.new(28960.158,14919.624,235.039),
    Shark=Vector3.new(28231.176,14890.976,-211.642),
    Cyborg=Vector3.new(28502.682,14895.976,-423.728),
    Ghoul=Vector3.new(28674.244,14890.677,445.431),
    Rabbit=Vector3.new(29012.342,14890.976,-380.149),
}

local function log(message)
    S.detail=tostring(message):sub(1,230)
    S.history[#S.history+1]=string.format("+%.1fs %s",os.clock()-S.started,S.detail)
    if #S.history>S.reportMax then table.remove(S.history,1) end
end
local function status(name, message)
    S.phase=name
    if message and S.detail~=message then log(message) end
end
local function once(key, seconds)
    local now=os.clock()
    if now-(S.lastAction[key] or -math.huge)<seconds then return false end
    S.lastAction[key]=now
    return true
end
local function root()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function humanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end
local function raceName(ofPlayer)
    local data=ofPlayer and ofPlayer:FindFirstChild("Data")
    local value=data and data:FindFirstChild("Race")
    local name=value and tostring(value.Value) or ""
    return ({Skypiea="Angel",Fishman="Shark",Mink="Rabbit"})[name] or name
end
local function part(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Attachment") then return part(obj.Parent) end
    local primary=obj:IsA("Model") and obj.PrimaryPart or nil
    return obj:FindFirstChild("HumanoidRootPart") or primary
        or obj:FindFirstChildWhichIsA("BasePart",true)
end
local function invoke(...)
    local folder=RS:FindFirstChild("Remotes")
    local remote=folder and folder:FindFirstChild("CommF_")
    if not remote then return false,"CommF_ ausente" end
    local args=table.pack(...)
    local key={}
    for i=1,args.n do key[i]=tostring(args[i]) end
    key=table.concat(key,"|")
    local slot=S.remoteStates[key]
    if not slot then
        slot={done=false,started=os.clock()}
        S.remoteStates[key]=slot
        task.spawn(function()
            slot.result=table.pack(pcall(function()
                return remote:InvokeServer(table.unpack(args,1,args.n))
            end))
            slot.done=true
        end)
    end
    local deadline=os.clock()+4
    while S.alive and not slot.done and os.clock()<deadline do task.wait(0.05) end
    if not slot.done then
        if once("timeout:"..key,12) then log("Sem resposta do servidor: "..key) end
        return false,"Sem resposta do servidor: "..key
    end
    S.remoteStates[key]=nil
    return table.unpack(slot.result,1,slot.result.n)
end
local function sendAbility()
    local folder=RS:FindFirstChild("Remotes")
    local event=folder and folder:FindFirstChild("CommE")
    if event and event:IsA("RemoteEvent") then
        return pcall(function() event:FireServer("ActivateAbility") end)
    end
    return false
end
local function cached(key, seconds, fn)
    if S.cacheAt[key] and os.clock()-S.cacheAt[key]<seconds then return S.cache[key] end
    local ok,result=pcall(fn)
    if ok then S.cache[key]=result;S.cacheAt[key]=os.clock();return result end
    if once("cacheErr:"..key,15) then log(key..": "..tostring(result)) end
    return nil
end
local function inventory()
    return cached("inventory",15,function()
        local ok,result=invoke("getInventory")
        return ok and type(result)=="table" and result or {}
    end)
end
local function hasItem(name)
    local low=name:lower()
    local char=player.Character
    local backpack=player:FindFirstChildOfClass("Backpack")
    if (char and char:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name)) then return true end
    for _,item in pairs(inventory() or {}) do
        if type(item)=="table" and tostring(item.Name or ""):lower()==low
            and (tonumber(item.Count) or 1)>0 then return true end
    end
    return false
end
local function raceV3()
    if player.Character and player.Character:FindFirstChild("RaceTransformed") then return true end
    return cached("v3",20,function()
        local ok,result=invoke("Wenlocktoad","info")
        return ok and result==-2
    end)==true
end
local function leverOpen()
    return cached("lever",8,function()
        local ok,result=invoke("CheckTempleDoor")
        return ok and (result==true or result==1)
    end)==true
end
local function clockState(force)
    if force then S.cacheAt.clock=nil end
    return cached("clock",5,function()
        local ok,result=invoke("TempleClock","Check")
        return ok and type(result)=="table" and result or nil
    end)
end
local function upgradeState(force)
    if force then S.cacheAt.upgrade=nil end
    return cached("upgrade",7,function()
        local ok,a,b,c=invoke("UpgradeRace","Check")
        return ok and {code=a,level=b,cost=c} or nil
    end)
end
local function trialTimer()
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local main=gui and gui:FindFirstChild("Main")
    local timer=main and main:FindFirstChild("Timer")
    return timer and timer.Visible==true or false
end
local function fullMoon()
    local sky=Lighting:FindFirstChildOfClass("Sky")
    local id=sky and tostring(sky.MoonTextureId or "") or ""
    return id:find("9709149431",1,true)~=nil
end
local function night()
    return Lighting.ClockTime>=18 or Lighting.ClockTime<=5
end
local function templeTeam()
    local names={}
    local count=0
    for _,candidate in ipairs(Players:GetPlayers()) do
        local rp=candidate.Character and candidate.Character:FindFirstChild("HumanoidRootPart")
        local race=raceName(candidate)
        if rp and (rp.Position-POS.temple).Magnitude<1350 and race~=""
            and not names[race] then
            count=count+1;names[race]=true
        end
    end
    return count
end

-- Movimento unico, com controle de cancelamento e restauracao da colisao.
local activeTween
local function stopMove()
    S.nonce=S.nonce+1
    if activeTween then pcall(function() activeTween:Cancel() end);activeTween=nil end
end
local function go(position,label,reach)
    local rp=root()
    local hum=humanoid()
    if not rp or not hum or hum.Health<=0 or not S.alive
        or (not S.auto and not S.manual) then
        status("Movimento bloqueado","Personagem ausente, morto ou kaitun pausado")
        return false
    end
    local distance=(rp.Position-position).Magnitude
    if distance<=(reach or 10) then return true end
    status("Movimento",label.." | faltam "..math.floor(distance).." studs")
    local startPosition=rp.Position
    S.nonce=S.nonce+1
    local nonce=S.nonce
    hum.Sit=false
    local target=position+Vector3.new(0,3,2)
    local delta=target-rp.Position
    local limited=delta.Magnitude>4200 and rp.Position+delta.Unit*4200 or target
    local duration=math.clamp((limited-rp.Position).Magnitude/325,0.1,15)
    local original={}
    for _,obj in ipairs(player.Character:GetDescendants()) do
        if obj:IsA("BasePart") then original[obj]=obj.CanCollide;obj.CanCollide=false end
    end
    local collision=RunService.Stepped:Connect(function()
        for obj in pairs(original) do if obj.Parent then obj.CanCollide=false end end
    end)
    local okTween,tween=pcall(function()
        return TweenService:Create(rp,TweenInfo.new(duration,Enum.EasingStyle.Linear),
            {CFrame=CFrame.new(limited)})
    end)
    if not okTween then
        collision:Disconnect()
        for obj,value in pairs(original) do
            if obj.Parent then pcall(function() obj.CanCollide=value end) end
        end
        status("Movimento bloqueado","Tween indisponível: "..tostring(tween))
        return false
    end
    activeTween=tween
    tween:Play()
    local deadline=os.clock()+duration+2
    while S.alive and (S.auto or S.manual) and nonce==S.nonce and rp==root()
        and os.clock()<deadline and tween.PlaybackState==Enum.PlaybackState.Playing do
        pcall(function() rp.AssemblyLinearVelocity=Vector3.zero end)
        task.wait(0.05)
    end
    local success=nonce==S.nonce and rp==root()
    if tween.PlaybackState==Enum.PlaybackState.Playing then pcall(function() tween:Cancel() end) end
    collision:Disconnect()
    for obj,value in pairs(original) do if obj.Parent then pcall(function() obj.CanCollide=value end) end end
    if activeTween==tween then activeTween=nil end
    local now=root()
    local travelled=now and (now.Position-startPosition).Magnitude or 0
    local left=now and (now.Position-position).Magnitude or distance
    S.lastMove=string.format("%s | antes=%.0f | andou=%.0f | falta=%.0f",
        label,distance,travelled,left)
    if travelled<3 and distance>20 and success then
        status("Movimento bloqueado",S.lastMove)
    end
    return success and now and left<=(reach or 10)
end
local function touch(target)
    local rp=root()
    if not rp or not target or not target.Parent then return false end
    if (rp.Position-target.Position).Magnitude>12 then return false end
    if type(firetouchinterest)=="function" then
        local okDown=pcall(firetouchinterest,rp,target,0)
        local okUp=pcall(firetouchinterest,rp,target,1)
        return okDown and okUp
    end
    return pcall(function()
        rp.CFrame=CFrame.new(target.Position)
    end)
end
local function promptNear(center,radius,nameFilter)
    local rp=root()
    if not rp or (rp.Position-center).Magnitude>(radius or 20) then return false end
    local best,dist
    local map=workspace:FindFirstChild("Map")
    local temple=(map and (map:FindFirstChild("Temple of Time")
        or map:FindFirstChild("TempleOfTime")))
        or workspace:FindFirstChild("Temple of Time")
    if not temple then return false end
    local parent=temple
    for _,obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local holder=part(obj.Parent)
            if holder and (not nameFilter
                or tostring(obj.Parent.Name):lower():find(nameFilter,1,true)) then
                local d=(holder.Position-center).Magnitude
                if d<35 and (not dist or d<dist) then best,dist=obj,d end
            end
        end
    end
    if best and type(fireproximityprompt)=="function" then
        return pcall(fireproximityprompt,best)
    end
    return false
end
local function interactNear(center,radius)
    if promptNear(center,radius) then return true end
    local rp=root()
    if not rp or (rp.Position-center).Magnitude>(radius or 20) then return false end
    local map=workspace:FindFirstChild("Map")
    local temple=(map and (map:FindFirstChild("Temple of Time")
        or map:FindFirstChild("TempleOfTime")))
        or workspace:FindFirstChild("Temple of Time")
    if not temple then return false end
    if type(fireclickdetector)=="function" then
        for _,obj in ipairs(temple:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                local holder=part(obj.Parent)
                if holder and (holder.Position-center).Magnitude<28 then
                    local ok=pcall(fireclickdetector,obj)
                    if ok then return true end
                end
            end
        end
    end
    return false
end

local function enterTemple()
    local rp=root()
    if not rp then status("Templo","Aguardando personagem");return false end
    if not S.alive or (not S.auto and not S.manual) then return false end
    if (rp.Position-POS.temple).Magnitude<1600 then return true end
    if once("entrance",7) then
        S.attempts.enter=S.attempts.enter+1
        local ok,response=invoke("requestEntrance",POS.temple)
        log("Entrada no Templo: "..tostring(response).." | remoto="..tostring(ok))
    end
    task.wait(0.5)
    if not S.alive or (not S.auto and not S.manual) then return false end
    rp=root()
    if rp and (rp.Position-POS.temple).Magnitude<1600 then
        S.lastMove="Entrada remota confirmada | posição="..tostring(rp.Position)
        log("Entrada no Templo confirmada pela posição")
        return true
    end
    if rp and once("templeDirect",15) then
        local before=rp.Position
        local ok=pcall(function() rp.CFrame=CFrame.new(POS.temple+Vector3.new(0,4,0)) end)
        task.wait(0.5)
        rp=root()
        if rp and (rp.Position-POS.temple).Magnitude<1600 then
            S.lastMove="Teleporte direto confirmado | posição="..tostring(rp.Position)
            log("Entrada no Templo confirmada após teleporte direto")
            return true
        end
        log("Teleporte direto "..(ok and "recusado pelo jogo" or "falhou")
            .." | origem="..math.floor((before-POS.temple).Magnitude))
    end
    return go(POS.temple,"Indo ao Templo do Tempo",50)
end
local function progressQuest()
    local stage=cached("progress",10,function()
        local ok,result=invoke("RaceV4Progress","Check")
        return ok and result or nil
    end)
    if type(stage)~="number" then return false end
    if stage==1 and once("begin",15) then
        S.attempts.quest=S.attempts.quest+1
        local ok,response=invoke("RaceV4Progress","Begin")
        log("Sealed King: Begin="..tostring(ok and response))
        S.cacheAt.progress=nil
        return true
    elseif stage==2 then
        if enterTemple() and once("questTemple",15) then
            S.attempts.quest=S.attempts.quest+1
            local ok,response=invoke("RaceV4Progress","TeleportBack")
            log("Visita ao Templo: "..tostring(ok and response))
            S.cacheAt.progress=nil
        end
        return true
    elseif stage==3 and once("continue",15) then
        S.attempts.quest=S.attempts.quest+1
        local ok,response=invoke("RaceV4Progress","Continue")
        log("Sealed King: Continue="..tostring(ok and response))
        S.cacheAt.progress=nil
        return true
    end
    return stage==1 or stage==2 or stage==3
end

local function mirage()
    local map=workspace:FindFirstChild("Map")
    return map and (map:FindFirstChild("MysticIsland")
        or map:FindFirstChild("Mirage Island") or map:FindFirstChild("MirageIsland"))
end
local function blueGear(island)
    if not island then return nil end
    for _,obj in ipairs(island:GetDescendants()) do
        if obj:IsA("MeshPart") and
            (tostring(obj.MeshId):find("10153114969",1,true)
                or obj.Name:lower():find("bluegear",1,true)) then return obj end
    end
    return nil
end
local function highestPoint(island)
    local selected,highest
    for _,obj in ipairs(island:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide and obj.Size.X>=4 then
            local y=obj.Position.Y+obj.Size.Y/2
            if not highest or y>highest then selected,highest=obj,y end
        end
    end
    return selected and selected.Position+Vector3.new(0,selected.Size.Y/2+4,0)
end

local function sendKey(down,key)
    if VIM then
        local ok=pcall(function() VIM:SendKeyEvent(down,key,false,game) end)
        if ok then return true end
    end
    local fallback=down and keypress or keyrelease
    if type(fallback)=="function" then
        return pcall(fallback,key.Value)
    end
    return false
end
local function releaseBoatKeys()
    for key,down in pairs(S.boatKeys) do
        if down then
            sendKey(false,Enum.KeyCode[key])
            S.boatKeys[key]=false
        end
    end
end
local function boatKey(key,down)
    if S.boatKeys[key]==down then return true end
    local ok=sendKey(down,Enum.KeyCode[key])
    if ok then S.boatKeys[key]=down end
    return ok
end
local function ownedBoat()
    local boats=workspace:FindFirstChild("Boats")
    if not boats then return nil,nil end
    local rp=root()
    local best,seat,distance
    for _,boat in ipairs(boats:GetChildren()) do
        local owner=boat:FindFirstChild("Owner")
        local value=owner and owner.Value
        local mine=value==player or tostring(value)==player.Name
            or tonumber(value)==player.UserId
        local candidate=boat:FindFirstChildWhichIsA("VehicleSeat",true)
        if mine and candidate then
            local d=rp and (candidate.Position-rp.Position).Magnitude or math.huge
            if not distance or d<distance then best,seat,distance=boat,candidate,d end
        end
    end
    return best,seat
end
local function seaDanger()
    local gui=player:FindFirstChildOfClass("PlayerGui")
    local main=gui and gui:FindFirstChild("Main")
    local compass=main and (main:FindFirstChild("SeaDanger",true)
        or main:FindFirstChild("Compass",true))
    if compass then
        for _,label in ipairs(compass:GetDescendants()) do
            if label:IsA("TextLabel") then
                local text=label.Text:lower()
                if text:find("level 6",1,true) or text:find("danger 6",1,true)
                    or text:find("????",1,true) then return 6 end
            end
        end
    end
    return nil
end
local function seekMirage(targetFn,label)
    targetFn=targetFn or mirage
    label=label or "Mirage"
    if targetFn() then releaseBoatKeys();return true end
    local boat,seat=ownedBoat()
    if not boat then
        releaseBoatKeys()
        if go(POS.tiki,"Indo ao vendedor de barco em Tiki",20)
            and once("boatBuy",15) then
            local ok,response=invoke("BuyBoat","Guardian")
            log("Barco Guardian: "..tostring(ok and response))
        end
        status(label,"Aguardando barco próprio")
        return false
    end
    local hum=humanoid()
    if not hum then return false end
    if seat.Occupant~=hum then
        releaseBoatKeys()
        if seat.Occupant then status(label,"Barco ocupado por outro jogador");return false end
        if go(seat.Position+Vector3.new(0,2,0),"Entrando no barco",9) then
            pcall(function() seat:Sit(hum) end)
        end
        return false
    end
    local x=seat.Position.X
    if x< -60000 then S.sailDirection=1 end
    if x> -29000 then S.sailDirection=-1 end
    local desired=Vector3.new(S.sailDirection,0,0)
    local heading=seat.CFrame.LookVector
    local flat=Vector3.new(heading.X,0,heading.Z)
    if flat.Magnitude<0.1 then releaseBoatKeys();return false end
    flat=flat.Unit
    local angle=flat:Cross(desired).Y
    local alignment=flat:Dot(desired)
    if alignment< -0.95 then angle=-1 end
    if not boatKey("A",angle>0.08) or not boatKey("D",angle< -0.08)
        or not boatKey("W",true) then
        releaseBoatKeys();status(label,"Executor sem entrada de barco")
        return false
    end
    if not S.sailLastPos or os.clock()-S.sailLastAt>12 then
        if S.sailLastPos and (seat.Position-S.sailLastPos).Magnitude<30 then
            S.sailStalls=S.sailStalls+1
            S.sailDirection=-S.sailDirection
            releaseBoatKeys()
            log("Barco parado; invertendo rota ("..S.sailStalls..")")
        else
            S.sailStalls=0
        end
        S.sailLastPos,S.sailLastAt=seat.Position,os.clock()
    end
    status("Procurando "..label,(seaDanger()==6 and "Danger 6" or "Rumo ao Danger 6")
        .." | X="..math.floor(x))
    return false
end
local function mirageStep()
    local island=mirage()
    if not island then
        S.attempts.mirage=S.attempts.mirage+1
        seekMirage()
        return
    end
    releaseBoatKeys()
    local gear=blueGear(island)
    if gear and gear.Transparency<0.95 then
        if go(gear.Position,"Pegando Blue Gear",8) then
            local interacted=touch(gear)
            if interacted and once("gearTouch",6) then
                S.gearTouched=true
                log("Blue Gear: tentativa de toque; verificando alavanca")
            elseif not interacted then
                status("Blue Gear","Não foi possível tocar a peça")
            end
        end
        return
    end
    if not night() then status("Mirage","Esperando a noite na ilha");return end
    local peak=highestPoint(island)
    if not peak then status("Mirage","Pico da ilha ainda não carregado");return end
    if not go(peak,"Subindo Mirage para olhar a lua",10) then return end
    local rp=root()
    local direction=Lighting:GetMoonDirection()
    if rp and direction.Magnitude>0 then
        local camera=workspace.CurrentCamera
        if camera then camera.CFrame=CFrame.lookAt(camera.CFrame.Position,
            camera.CFrame.Position+direction) end
        rp.CFrame=CFrame.lookAt(rp.Position,rp.Position+direction)
    end
    if once("mirageV3",8) then
        sendAbility()
        status("Mirage","V3 ativada olhando para a lua; esperando Blue Gear")
    end
end
local function leverStep()
    if not enterTemple() then return end
    if not go(POS.lever,"Indo à alavanca do Templo",9) then return end
    if once("leverPrompt",8) then
        S.attempts.lever=S.attempts.lever+1
        local activated=interactNear(POS.lever,18)
        log(activated and "Alavanca acionada; confirmando CheckTempleDoor"
            or "Perto da alavanca; prompt não encontrado")
        S.cacheAt.lever=nil
    end
end

local function equipCombat()
    local character=player.Character
    local hum=humanoid()
    if not character or not hum then return nil end
    local current=character:FindFirstChildOfClass("Tool")
    if current then return current end
    local bag=player:FindFirstChildOfClass("Backpack")
    if not bag then return nil end
    local selected
    for _,tool in ipairs(bag:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip=="Melee" or tool.ToolTip=="Sword") then
            selected=tool;break
        end
    end
    selected=selected or bag:FindFirstChildOfClass("Tool")
    if not selected then return nil end
    pcall(function() hum:EquipTool(selected) end)
    return character:FindFirstChildOfClass("Tool")
end
local skillKeys={Enum.KeyCode.Z,Enum.KeyCode.X,Enum.KeyCode.C,Enum.KeyCode.V}
local function attack(target)
    local rp=root()
    local hitPart=part(target)
    if not rp or not hitPart then return false end
    if not go(hitPart.Position,target.Name,35) then return false end
    local tool=equipCombat()
    if not tool then status("Combate","Equipe uma arma de combate");return false end
    if os.clock()-S.attackAt<0.38 then return true end
    S.attackAt=os.clock()
    rp=root()
    if not rp then return false end
    pcall(function() rp.CFrame=CFrame.lookAt(rp.Position,hitPart.Position) end)
    pcall(function() tool:Activate() end)
    local modules=RS:FindFirstChild("Modules")
    local net=modules and modules:FindFirstChild("Net")
    local reg=net and net:FindFirstChild("RE/RegisterAttack")
    local hit=net and net:FindFirstChild("RE/RegisterHit")
    if reg and hit and reg:IsA("RemoteEvent") and hit:IsA("RemoteEvent") then
        pcall(function()
            reg:FireServer(0.1)
            hit:FireServer(target:FindFirstChild("Head") or hitPart,{})
        end)
    end
    if os.clock()-S.skillAt>=2.5 then
        S.skillAt=os.clock()
        local key=skillKeys[(math.floor(S.skillAt/2.5)%#skillKeys)+1]
        sendKey(true,key)
        task.wait(0.12)
        sendKey(false,key)
    end
    return true
end
local function closestEnemy(filter,limit)
    local folder=workspace:FindFirstChild("Enemies")
    local rp=root()
    if not folder or not rp then return nil end
    local selected,distance
    for _,model in ipairs(folder:GetChildren()) do
        local hp=model:FindFirstChildOfClass("Humanoid")
        local location=part(model)
        local d=location and (location.Position-rp.Position).Magnitude
        if hp and hp.Health>0 and d and d<(limit or 1100)
            and (not filter or filter(model)) and (not distance or d<distance) then
            selected,distance=model,d
        end
    end
    return selected
end
local function trialEndpoint(kind)
    local map=workspace:FindFirstChild("Map")
    local parent=map and (map:FindFirstChild(kind=="Angel" and "SkyTrial" or "MinkTrial")
        or map:FindFirstChild(kind=="Angel" and "AngelTrial" or "RabbitTrial"))
    if not parent then return nil end
    if S.objective and S.objective.Parent and os.clock()-S.objectiveAt<3 then
        return S.objective
    end
    S.objectiveAt=os.clock()
    local selected,distance
    local rp=root()
    for _,obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("BasePart") then
            local low=obj.Name:lower()
            if low:find("endpoint",1,true) or low:find("finish",1,true)
                or low:find("goal",1,true) or low:find("touchpoint",1,true)
                or (kind=="Angel" and low:find("snowisland_cylinder.081",1,true)) then
                local d=rp and (obj.Position-rp.Position).Magnitude or math.huge
                if d<1800 and (not distance or d<distance) then selected,distance=obj,d end
            end
        end
    end
    S.objective=selected
    return selected
end
local function trialStep(name)
    if not S.trialSeen then
        S.trialSeen=true;S.trialStarted=os.clock();S.trialRace=name
        S.attempts.trial=S.attempts.trial+1
        log("Timer da trial "..name.." visível; executando objetivo")
    end
    if os.clock()-S.trialStarted>480 then
        status("Trial","Tempo excessivo; aguardando resultado do jogo")
        return
    end
    if name=="Human" or name=="Ghoul" then
        local enemy=closestEnemy(nil,1000)
        if enemy then
            status("Trial "..name,"Atacando "..enemy.Name)
            attack(enemy)
        else status("Trial "..name,"Aguardando onda de inimigos") end
    elseif name=="Shark" then
        local selected
        local beasts=workspace:FindFirstChild("SeaBeasts")
        if beasts then
            for _,model in ipairs(beasts:GetChildren()) do
                if part(model) then selected=model;break end
            end
        end
        selected=selected or closestEnemy(function(m)
            local low=m.Name:lower()
            return low:find("shark",1,true) or low:find("piranha",1,true)
        end,1800)
        if selected then status("Trial Shark","Atacando "..selected.Name);attack(selected)
        else status("Trial Shark","Aguardando Sea Beast") end
    elseif name=="Angel" or name=="Rabbit" then
        local target=trialEndpoint(name)
        if target then
            if go(target.Position,"Trial "..name..": fim do percurso",8) then
                touch(target)
                status("Trial "..name,"Chegou ao fim; aguardando servidor")
            end
        else status("Trial "..name,"Percurso ou final ainda não carregou") end
    elseif name=="Cyborg" then
        if go(POS.cyborgSafe,"Trial Cyborg: área segura",12) then
            status("Trial Cyborg","Aguardando bombas e cronômetro")
        end
    end
end
local function pvpStep()
    if os.clock()-S.trialEndedAt>100 then
        status("Pós-trial","Sem ponto confirmado; aguardando próxima trial")
        S.trialEndedAt=0
        return
    end
    if not go(POS.arena,"Indo à arena pós-trial",90) then return end
    local rp=root()
    if not rp then return end
    local selected,distance
    for _,candidate in ipairs(Players:GetPlayers()) do
        if candidate~=player and candidate.Character then
            local hp=candidate.Character:FindFirstChildOfClass("Humanoid")
            local target=part(candidate.Character)
            local d=target and (target.Position-POS.arena).Magnitude
            if hp and hp.Health>0 and d and d<330 then
                local from=(target.Position-rp.Position).Magnitude
                if not distance or from<distance then
                    selected,distance=candidate.Character,from
                end
            end
        end
    end
    if selected then
        S.attempts.pvp=S.attempts.pvp+1
        status("PVP pós-trial","Atacando "..selected.Name)
        attack(selected)
    else status("PVP pós-trial","Aguardando adversários/resultado") end
end
local function chooseGear(state)
    local map=workspace:FindFirstChild("Map")
    local temple=map and map:FindFirstChild("Temple of Time")
    local inner=temple and temple:FindFirstChild("InnerClock",true)
    local selected,number
    if inner then
        for _,child in ipairs(inner:GetChildren()) do
            local n=tonumber(child.Name:match("Gear(%d+)"))
            if n and child:FindFirstChild("Highlight",true)
                and (not number or n<number) then selected,number=child.Name,n end
        end
    end
    if not selected and type(state)=="table" then
        local a,b=tonumber(state.A) or 0,tonumber(state.B) or 0
        if a+b==0 then selected="Gear1" end
    end
    return selected
end
local function gearStep(clock)
    releaseBoatKeys()
    if not enterTemple() then return end
    if not go(POS.clock,"Indo ao Relógio Ancestral",12) then return end
    status("Relógio","Ponto V4 disponível; escolhendo engrenagem")
    if not once("gearSpend",8) then return end
    local selected=chooseGear(clock)
    if not selected then
        log("Ponto disponível, mas engrenagem destacada não carregou")
        promptNear(POS.clock,20,"clock")
        return
    end
    promptNear(POS.clock,20,"clock")
    local ok,response
    if selected=="Gear1" then
        ok,response=invoke("TempleClock","SpendPoint")
    elseif selected=="Gear5" then
        ok,response=invoke("TempleClock","SpendPoint",selected,"Default")
    else
        ok,response=invoke("TempleClock","SpendPoint",selected,S.path)
    end
    S.attempts.gear=S.attempts.gear+1
    log("Relógio "..selected.."/"..S.path..": "..tostring(ok and response))
    S.cacheAt.clock=nil;S.cacheAt.upgrade=nil
    task.wait(0.5)
    local latest=clockState(true)
    if type(latest)=="table" and not latest.HadPoint then
        log("Ponto do relógio gasto e confirmado")
    end
end
local function buyStep(upgrade)
    local cost=tonumber(upgrade.cost)
    local data=player:FindFirstChild("Data")
    local fragments=data and data:FindFirstChild("Fragments")
    local available=fragments and tonumber(fragments.Value) or 0
    if cost and available<cost then
        status("Upgrade V4","Faltam Fragments: "..math.floor(cost-available))
        return
    end
    if not once("upgradeBuy",12) then return end
    local before=upgrade.code
    local ok,response=invoke("UpgradeRace","Buy")
    S.attempts.buy=S.attempts.buy+1
    log("Ancient One compra: "..tostring(ok and response))
    task.wait(0.6)
    local after=upgradeState(true)
    if after and after.code~=before then log("Upgrade V4 confirmado: "..tostring(after.code)) end
end
local function trainingStep(upgrade)
    status("Treino V4","Ativando V4 e eliminando inimigos")
    if once("v4Ability",10) then
        sendKey(true,Enum.KeyCode.Y)
        task.wait(0.08)
        sendKey(false,Enum.KeyCode.Y)
    end
    local enemy=closestEnemy(function(model)
        local low=model.Name:lower()
        return low:find("skeleton",1,true) or low:find("zombie",1,true)
            or low:find("demonic soul",1,true) or low:find("mummy",1,true)
    end,900)
    if enemy then
        S.attempts.train=S.attempts.train+1
        attack(enemy)
    else
        go(POS.bones,"Procurando inimigos para treinar V4",60)
    end
    if once("trainingCheck",10) then
        local nextStatus=upgradeState(true)
        if nextStatus and nextStatus.code~=upgrade.code then
            log("Treino mudou de estado: "..tostring(upgrade.code).." -> "..tostring(nextStatus.code))
        end
    end
end

local function report()
    local lines={
        "FLOQUITAVE | KAITUN RACE V4 1.3",
        "PlaceId="..tostring(game.PlaceId).." | Race="..tostring(raceName(player)),
        "Auto="..tostring(S.auto).." | Fase="..S.phase.." | Detalhe="..S.detail,
        "FullMoon="..tostring(fullMoon()).." | Noite="..tostring(night())
            .." | EquipeTemplo="..tostring(templeTeam()),
        "Porta="..tostring(leverOpen()).." | PontoRelogio="
            ..tostring((clockState() or {}).HadPoint),
    }
    local u=upgradeState()
    lines[#lines+1]="UpgradeRace="..tostring(u and u.code)
        .." | Nivel="..tostring(u and u.level).." | Custo="..tostring(u and u.cost)
    local rp=root()
    lines[#lines+1]="Posição="..tostring(rp and rp.Position)
    lines[#lines+1]="Último movimento="..tostring(S.lastMove or "nenhum")
    lines[#lines+1]="Mirror Fractal="..tostring(hasItem("Mirror Fractal"))
    local progress=cached("progress",10,function()
        local ok,result=invoke("RaceV4Progress","Check")
        return ok and result or nil
    end)
    lines[#lines+1]="RaceV4Progress="..tostring(progress)
    for key,slot in pairs(S.remoteStates) do
        lines[#lines+1]="Remote pendente="..key.." | "
            ..math.floor(os.clock()-slot.started).."s"
    end
    for key,value in pairs(S.attempts) do
        lines[#lines+1]="Tentativas "..key.."="..tostring(value)
    end
    lines[#lines+1]="HISTORICO"
    for _,entry in ipairs(S.history) do lines[#lines+1]=entry end
    return table.concat(lines,"\n")
end

local function v4Step()
    if not IS_THIRD_SEA then
        status("Mar incorreto","Entre no Third Sea; PlaceId atual: "..tostring(game.PlaceId))
        return
    end
    local name=raceName(player)
    S.race=name
    if S.manualTarget then
        local target=S.manualTarget
        S.manualTarget=nil
        S.manual=true
        if target=="temple" then
            status("Ação V4","Tentando entrar no Templo")
            enterTemple()
        elseif target=="door" and DOOR[name] and enterTemple() then
            go(DOOR[name],"Indo à porta V4",9)
        elseif target=="lever" then
            leverStep()
        elseif target=="clock" and enterTemple() then
            go(POS.clock,"Indo ao relógio V4",12)
        elseif target=="gear" then
            local clock=clockState(true)
            if clock and clock.HadPoint then
                gearStep(clock)
            else status("Relógio","Nenhum ponto V4 disponível para gastar") end
        elseif target=="train" then
            trainingStep(upgradeState(true) or {})
        elseif target=="trial" and DOOR[name] and enterTemple()
            and go(DOOR[name],"Indo à porta da trial",9) then
            local ok=sendAbility()
            promptNear(DOOR[name],18)
            status("Iniciar trial",ok and "Habilidade acionada; aguardando timer"
                or "Habilidade não acionada; confira a lua cheia e a equipe")
        elseif target=="refresh" then
            S.cacheAt={}
            local u=upgradeState(true)
            local clock=clockState(true)
            status("Progresso V4","Upgrade="..tostring(u and u.code)
                .." | Clock="..tostring(clock and clock.HadPoint)
                .." | Porta="..tostring(leverOpen()))
        end
        S.manual=false
        return
    end
    if name=="" then status("Aguardando","Data.Race ainda não carregou");return end
    if S.forceMode=="mirage" then
        if S.gearTouched or leverOpen() then
            S.forceMode=nil
            log("Busca da Mirage encerrada; verificando Templo")
        else
            mirageStep()
            return
        end
    end
    if name=="Draco" then
        status("Draco V4","Rota Draco exige relics de Prehistoric Island; sem protocolo seguro para concluir")
        return
    end
    if not DOOR[name] then
        status("Raça sem rota","Raça detectada: "..name)
        return
    end
    if not S.initialTempleProbe then
        S.initialTempleProbe=true
        status("Entrada V4","Testando entrada no Templo antes da progressão")
        enterTemple()
        return
    end
    local upgrade=upgradeState()
    local clock=clockState()
    if not raceV3() and not (upgrade and type(upgrade.code)=="number") then
        status("Pré-requisito","Raça V3 não confirmada; veja o relatório")
        return
    end
    if upgrade and tonumber(upgrade.code)==5 and not (clock and clock.HadPoint) then
        status("V4 concluída","UpgradeRace confirmou estado final")
        S.auto=false;releaseBoatKeys();stopMove()
        return
    end
    if clock and clock.HadPoint then gearStep(clock);return end
    if upgrade and (upgrade.code==2 or upgrade.code==4 or upgrade.code==7) then
        buyStep(upgrade);return
    end
    if upgrade and (upgrade.code==1 or upgrade.code==3
        or upgrade.code==6 or upgrade.code==8) then
        trainingStep(upgrade);return
    end
    if not leverOpen() then
        if progressQuest() then
            status("Missão V4","Avançando com o Sealed King e o Templo")
            return
        end
        if not hasItem("Mirror Fractal") then
            status("Pré-requisito","Mirror Fractal necessário para a Blue Gear")
            return
        end
        -- Verifica a alavanca uma vez por sessão antes de iniciar uma viagem longa.
        -- Se já houver Blue Gear, tenta novamente após retornar de Mirage.
        if S.attempts.lever==0 or (S.gearTouched and S.attempts.lever<3) then
            leverStep()
        else
            mirageStep()
        end
        return
    end
    releaseBoatKeys()
    local rp=root()
    if trialTimer() and rp and (rp.Position-POS.temple).Magnitude<2200 then
        S.trialEndedAt=0
        trialStep(name)
        return
    end
    if S.trialSeen then
        S.trialSeen=false;S.trialEndedAt=os.clock()
        log("Timer da trial sumiu; verificando ponto e PVP")
        S.cacheAt.clock=nil;S.cacheAt.upgrade=nil
        return
    end
    if S.trialEndedAt>0 then
        pvpStep();return
    end
    if not enterTemple() then return end
    if not go(DOOR[name],"Indo à porta "..name,9) then return end
    local moon=fullMoon()
    local count=templeTeam()
    status("Porta "..name,"Lua cheia="..tostring(moon)
        .." | raças detectadas="..count.."/3 | aguardando timer")
    if once("trialActivate",7) then
        local ok=sendAbility()
        promptNear(DOOR[name],18)
        log("Porta "..name..": tentativa="..tostring(ok)
            .." | lua cheia="..tostring(moon).." | equipe="..count)
    end
end

local gui=Instance.new("ScreenGui")
gui.Name="Floquitave_Kaitun_RaceV4"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=100
local playerGui=player:WaitForChild("PlayerGui",15)
assert(playerGui,"PlayerGui não carregou após 15 segundos")
local okParent=pcall(function() gui.Parent=playerGui end)
if not okParent then
    local core=game:GetService("CoreGui")
    gui.Parent=core
end
local function box(class,parent,properties)
    local obj=Instance.new(class)
    for key,value in pairs(properties) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local Theme={
    Main=Color3.fromRGB(12,10,18),
    Header=Color3.fromRGB(19,16,28),
    Sidebar=Color3.fromRGB(14,12,21),
    Panel=Color3.fromRGB(10,9,15),
    Row=Color3.fromRGB(27,24,35),
    Accent=Color3.fromRGB(151,92,255),
    AccentDark=Color3.fromRGB(94,53,178),
    Text=Color3.fromRGB(246,245,249),
    Muted=Color3.fromRGB(174,170,184),
    Outline=Color3.fromRGB(73,57,103),
}
local function corner(parent,radius)
    box("UICorner",parent,{CornerRadius=UDim.new(0,radius or 7)})
end
local function stroke(parent,color,transparency)
    box("UIStroke",parent,{Color=color or Theme.Outline,Thickness=1,
        Transparency=transparency or 0.42})
end
local function textLabel(parent,text,x,y,w,h,size,color,bold)
    return box("TextLabel",parent,{
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
        BackgroundTransparency=1,Text=text,TextSize=size or 14,
        TextColor3=color or Theme.Text,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
end
local panel=box("Frame",gui,{
    Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(680,432),
    BackgroundColor3=Theme.Main,BorderSizePixel=0,ClipsDescendants=true,
})
corner(panel,10);stroke(panel,Theme.AccentDark,0.22)
local scale=box("UIScale",panel,{Scale=0.94})
local function fit()
    local cam=workspace.CurrentCamera
    local view=cam and cam.ViewportSize
    if view then
        scale.Scale=math.max(0.38,math.min(0.94,
            view.X*0.95/680,view.Y*0.90/432))
    else
        scale.Scale=UIS.TouchEnabled and 0.6 or 0.94
    end
end
fit()
if workspace.CurrentCamera then
    S.connections[#S.connections+1]=workspace.CurrentCamera
        :GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end
local header=box("Frame",panel,{
    Name="Header",Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,47),
    BackgroundColor3=Theme.Header,BorderSizePixel=0,
})
box("Frame",header,{Position=UDim2.fromOffset(0,45),
    Size=UDim2.new(1,0,0,2),BackgroundColor3=Theme.AccentDark,BorderSizePixel=0})
textLabel(header,"FLOQUITAVE",18,10,170,28,19,Theme.Accent,true)
textLabel(header,"/  Race V4 Kaitun",170,11,210,26,14,Theme.Text)
local minimize=box("TextButton",header,{
    Position=UDim2.new(1,-45,0,9),Size=UDim2.fromOffset(30,28),
    BackgroundColor3=Theme.Row,BorderSizePixel=0,Text="—",
    TextColor3=Theme.Text,Font=Enum.Font.GothamBold,TextSize=18,
})
corner(minimize,6);stroke(minimize,Theme.Outline,0.6)

local sidebar=box("Frame",panel,{
    Position=UDim2.fromOffset(0,47),Size=UDim2.fromOffset(155,385),
    BackgroundColor3=Theme.Sidebar,BorderSizePixel=0,
})
textLabel(sidebar,"NAVEGAÇÃO",16,20,125,20,11,Theme.Muted,true)
local function nav(label,y)
    local b=box("TextButton",sidebar,{
        Position=UDim2.fromOffset(10,y),Size=UDim2.fromOffset(135,38),
        BackgroundColor3=Theme.Sidebar,BorderSizePixel=0,
        Text="   "..label,TextColor3=Theme.Muted,
        TextSize=14,Font=Enum.Font.GothamSemibold,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    corner(b,7)
    return b
end
local raceTab=nav("Race V4",50)
local actionsTab=nav("Ações V4",95)
local logTab=nav("Relatório",140)
textLabel(sidebar,"TERCEIRO MAR",16,331,124,19,11,Theme.Muted,true)

local racePage=box("Frame",panel,{
    Position=UDim2.fromOffset(155,47),Size=UDim2.fromOffset(525,385),
    BackgroundColor3=Theme.Panel,BorderSizePixel=0,
})
local logPage=box("Frame",panel,{
    Position=UDim2.fromOffset(155,47),Size=UDim2.fromOffset(525,385),
    BackgroundColor3=Theme.Panel,BorderSizePixel=0,Visible=false,
})
local actionsPage=box("Frame",panel,{
    Position=UDim2.fromOffset(155,47),Size=UDim2.fromOffset(525,385),
    BackgroundColor3=Theme.Panel,BorderSizePixel=0,Visible=false,
})
local function switchPage(which)
    racePage.Visible=which=="race"
    logPage.Visible=which=="log"
    actionsPage.Visible=which=="actions"
    raceTab.BackgroundColor3=which=="race" and Theme.Row or Theme.Sidebar
    actionsTab.BackgroundColor3=which=="actions" and Theme.Row or Theme.Sidebar
    logTab.BackgroundColor3=which=="log" and Theme.Row or Theme.Sidebar
    raceTab.TextColor3=which=="race" and Theme.Accent or Theme.Muted
    actionsTab.TextColor3=which=="actions" and Theme.Accent or Theme.Muted
    logTab.TextColor3=which=="log" and Theme.Accent or Theme.Muted
end
switchPage("race")
S.connections[#S.connections+1]=raceTab.MouseButton1Click:Connect(function()
    switchPage("race")
end)
S.connections[#S.connections+1]=logTab.MouseButton1Click:Connect(function()
    switchPage("log")
end)
S.connections[#S.connections+1]=actionsTab.MouseButton1Click:Connect(function()
    switchPage("actions")
end)
textLabel(racePage,"RACE V4",20,15,210,29,19,Theme.Text,true)
textLabel(racePage,"Progresso e controles da raça",20,43,360,19,12,Theme.Muted)
local statusCard=box("Frame",racePage,{
    Position=UDim2.fromOffset(18,75),Size=UDim2.fromOffset(489,96),
    BackgroundColor3=Theme.Row,BorderSizePixel=0,
})
corner(statusCard,8);stroke(statusCard,Theme.Outline,0.48)
box("Frame",statusCard,{Position=UDim2.fromOffset(0,0),
    Size=UDim2.fromOffset(4,96),BackgroundColor3=Theme.Accent,BorderSizePixel=0})
textLabel(statusCard,"ETAPA ATUAL",16,11,300,16,11,Theme.Muted,true)
local phase=textLabel(statusCard,"Iniciando...",16,31,450,25,17,Theme.Accent,true)
local detail=textLabel(statusCard,"Aguardando dados do jogo",16,59,455,30,13,Theme.Text)
detail.TextWrapped=true;detail.TextYAlignment=Enum.TextYAlignment.Top
local function statCard(label,x)
    local card=box("Frame",racePage,{
        Position=UDim2.fromOffset(x,182),Size=UDim2.fromOffset(155,62),
        BackgroundColor3=Theme.Row,BorderSizePixel=0,
    })
    corner(card,7)
    textLabel(card,label,12,6,132,17,10,Theme.Muted,true)
    return textLabel(card,"...",12,26,135,25,15,Theme.Text,true)
end
local raceValue=statCard("RAÇA",18)
local moonValue=statCard("LUA CHEIA",185)
local teamValue=statCard("EQUIPE NO TEMPLO",352)
textLabel(racePage,"CONTROLES",20,259,220,19,11,Theme.Muted,true)
local function button(parent,label,x,y,w,callback,primary)
    local b=box("TextButton",parent,{
        Size=UDim2.fromOffset(w,35),Position=UDim2.fromOffset(x,y),
        BackgroundColor3=primary and Theme.AccentDark or Theme.Row,
        BorderSizePixel=0,Font=Enum.Font.GothamSemibold,TextSize=13,
        TextColor3=Theme.Text,Text=label,
    })
    corner(b,7)
    if not primary then stroke(b,Theme.Outline,0.62) end
    S.connections[#S.connections+1]=b.MouseButton1Click:Connect(callback)
    return b
end
local pauseButton=button(racePage,"Pausar",18,286,155,function()
    S.auto=not S.auto
    if not S.auto then
        S.manual=false;releaseBoatKeys();stopMove()
        status("Pausado","Aguardando botão Retomar")
    end
end,true)
local pathButton=button(racePage,"Caminho: Alpha",185,286,155,function()
    S.path=S.path=="Alpha" and "Omega" or "Alpha"
    log("Caminho da próxima engrenagem: "..S.path)
end)
local function queueAction(target,label)
    S.manualTarget=target
    status("Ação V4 solicitada",label)
    stopMove()
end
button(racePage,"Ir ao Templo",352,286,155,function()
    queueAction("temple","Entrar no Templo")
end)
button(racePage,"Ir à Porta",18,330,155,function()
    queueAction("door","Ir à porta racial")
end)
local function copyReport()
    if type(setclipboard)=="function" then
        local okCopy=pcall(setclipboard,report())
        log(okCopy and "Relatório copiado" or "Falha ao copiar relatório")
    else
        log("Executor sem setclipboard; relatório no console")
        print(report())
    end
end
button(racePage,"Copiar relatório",185,330,322,copyReport)

textLabel(actionsPage,"AÇÕES V4",20,17,230,27,19,Theme.Text,true)
textLabel(actionsPage,"Use uma ação por vez; o relatório mostra o resultado",20,47,470,19,
    12,Theme.Muted)
local actionCard=box("Frame",actionsPage,{
    Position=UDim2.fromOffset(18,80),Size=UDim2.fromOffset(489,281),
    BackgroundColor3=Theme.Row,BorderSizePixel=0,
})
corner(actionCard,8);stroke(actionCard,Theme.Outline,0.5)
button(actionCard,"Entrar no Templo",12,16,228,function()
    queueAction("temple","Entrar no Templo")
end,true)
button(actionCard,"Ir à Alavanca",250,16,227,function()
    queueAction("lever","Ir à alavanca")
end)
button(actionCard,"Ir à Porta",12,61,228,function()
    queueAction("door","Ir à porta racial")
end)
button(actionCard,"Ir ao Relógio",250,61,227,function()
    queueAction("clock","Ir ao relógio")
end)
button(actionCard,"Tentar iniciar Trial",12,106,228,function()
    queueAction("trial","Acionar habilidade na porta")
end)
button(actionCard,"Verificar progresso",250,106,227,function()
    queueAction("refresh","Ler estados V4 do servidor")
end)
button(actionCard,"Buscar Mirage / Blue Gear",12,162,228,function()
    if not DOOR[raceName(player)] then
        status("Busca Mirage","Raça atual sem rota tradicional de Mirage")
        return
    end
    S.forceMode="mirage";S.auto=true
    queueAction("refresh","Iniciando busca da Mirage")
end,true)
button(actionCard,"Parar busca da Mirage",250,162,227,function()
    S.forceMode=nil;releaseBoatKeys();stopMove()
    status("Busca Mirage","Busca interrompida")
end)
button(actionCard,"Gastar ponto V4",12,207,228,function()
    queueAction("gear","Usar ponto do relógio")
end)
button(actionCard,"Treinar V4",250,207,227,function()
    queueAction("train","Ativar V4 e treinar")
end)
local actionInfo=textLabel(actionCard,"",12,248,465,28,12,Theme.Muted)
actionInfo.TextWrapped=true
actionInfo.Text="O botão Verificar progresso também registra o retorno dos remotes no relatório."

textLabel(logPage,"RELATÓRIO V4",20,17,250,28,19,Theme.Text,true)
textLabel(logPage,"Últimas atividades do kaitun",20,45,350,18,12,Theme.Muted)
local logFrame=box("Frame",logPage,{
    Position=UDim2.fromOffset(18,76),Size=UDim2.fromOffset(489,243),
    BackgroundColor3=Theme.Row,BorderSizePixel=0,ClipsDescendants=true,
})
corner(logFrame,7);stroke(logFrame,Theme.Outline,0.55)
local history=textLabel(logFrame,"Iniciando...",12,10,462,224,12,Theme.Text)
history.TextWrapped=true
history.TextYAlignment=Enum.TextYAlignment.Top
button(logPage,"Copiar relatório completo",18,330,489,copyReport,true)

local opener=box("TextButton",gui,{
    Name="AbrirHub",Position=UDim2.fromOffset(20,180),
    Size=UDim2.fromOffset(112,42),BackgroundColor3=Theme.Header,
    BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=14,
    Text="F  ABRIR V4",TextColor3=Theme.Accent,Visible=false,
})
corner(opener,11);stroke(opener,Theme.Accent,0.1)
S.connections[#S.connections+1]=minimize.MouseButton1Click:Connect(function()
    panel.Visible=false
    opener.Visible=true
end)
S.connections[#S.connections+1]=opener.MouseButton1Click:Connect(function()
    panel.Visible=true
    opener.Visible=false
end)

-- Arrasta pelo cabeçalho, como no Floquitave.
local dragging,startInput,startPosition
S.connections[#S.connections+1]=header.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true;startInput=input.Position;startPosition=panel.Position
    end
end)
S.connections[#S.connections+1]=UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
S.connections[#S.connections+1]=UIS.InputChanged:Connect(function(input)
    if not dragging or (input.UserInputType~=Enum.UserInputType.MouseMovement
        and input.UserInputType~=Enum.UserInputType.Touch) then return end
    local delta=input.Position-startInput
    panel.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+delta.X,
        startPosition.Y.Scale,startPosition.Y.Offset+delta.Y)
end)
S.connections[#S.connections+1]=RunService.Heartbeat:Connect(function()
    if not S.alive or not gui.Parent then return end
    if not S.uiAt or os.clock()-S.uiAt>0.8 then
        S.uiAt=os.clock()
        phase.Text=S.phase
        detail.Text=S.detail
        raceValue.Text=tostring(S.race or "...")
        moonValue.Text=fullMoon() and "Sim" or "Não"
        teamValue.Text=tostring(templeTeam()).." / 3"
        pauseButton.Text=S.auto and "Pausar" or "Retomar"
        pathButton.Text="Caminho: "..S.path
        if actionsPage.Visible then
            actionInfo.Text=S.lastMove or
                "Selecione uma ação. Distância percorrida aparecerá aqui."
        end
        if logPage.Visible then
            local last={}
            for i=math.max(1,#S.history-9),#S.history do
                last[#last+1]=S.history[i]
            end
            history.Text=table.concat(last,"\n")
        end
    end
end)

S.report=report
S.stop=function()
    S.alive=false;S.auto=false
    stopMove();releaseBoatKeys()
    for _,connection in ipairs(S.connections) do pcall(function() connection:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end
S.connections[#S.connections+1]=player.Idled:Connect(function()
    if not S.alive or not VirtualUser then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
if not IS_THIRD_SEA then
    status("Mar incorreto","Entre no Third Sea; PlaceId atual: "..tostring(game.PlaceId))
else
    log("Race V4 iniciado; somente funções de despertar e upgrades V4")
end
print("[Floquitave V4 1.3] Painel criado em "..gui.Parent:GetFullName())

-- O worker inicia depois que o painel já está visível.
task.spawn(function()
    while S.alive do
        if (S.auto or S.manualTarget) and not S.busy then
            S.busy=true
            local ok,err=xpcall(v4Step,function(message)
                if debug and type(debug.traceback)=="function" then
                    return debug.traceback(tostring(message))
                end
                return tostring(message)
            end)
            S.busy=false
            S.manual=false
            if not ok then
                status("Erro na etapa",tostring(err):sub(1,200))
                warn("[Floquitave V4 1.3] "..tostring(err))
                task.wait(3)
            end
        end
        task.wait(0.75)
    end
end)
end

local ok,err=xpcall(main,function(message)
    if debug and type(debug.traceback)=="function" then
        return debug.traceback(tostring(message))
    end
    return tostring(message)
end)
if not ok then
    warn("[Floquitave V4 1.3] Falha ao iniciar: "..tostring(err))
    pcall(function()
        local players=game:GetService("Players")
        local localPlayer=players.LocalPlayer
        local pg=localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        local fail=Instance.new("ScreenGui")
        fail.Name="Floquitave_V4_Erro"
        fail.ResetOnSpawn=false
        fail.DisplayOrder=999
        local label=Instance.new("TextLabel")
        label.Size=UDim2.fromOffset(480,110)
        label.Position=UDim2.new(0.5,-240,0,70)
        label.BackgroundColor3=Color3.fromRGB(96,20,30)
        label.TextColor3=Color3.new(1,1,1)
        label.TextWrapped=true
        label.TextSize=17
        label.Text="Floquitave V4: falha ao iniciar\n"..tostring(err):sub(1,320)
        label.Parent=fail
        fail.Parent=pg
    end)
end



