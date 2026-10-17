-- FLOQUITAVE | Race V4 Kaitun 1.0 | Blox Fruits / Third Sea
-- Script independente: somente etapas diretamente ligadas a Race V4.
-- O painel inicia em modo automatico. Botao Pausar interrompe movimento e acoes.
-- O jogo precisa estar aberto no Third Sea (PlaceId 7449423635).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
while not player do task.wait(0.2); player = Players.LocalPlayer end
if game.PlaceId ~= 7449423635 then
    warn("[Floquitave V4] Entre no Third Sea para iniciar o kaitun.")
    return
end

local env = type(getgenv) == "function" and getgenv() or _G
if env.__FloquitaveV4 and type(env.__FloquitaveV4.stop) == "function" then
    pcall(env.__FloquitaveV4.stop)
end
local S = {
    alive=true, auto=true, phase="Iniciando", detail="", started=os.clock(),
    history={}, connections={}, nonce=0, busy=false,
    cache={}, cacheAt={}, lastAction={},
    trialSeen=false, trialStarted=0, trialEndedAt=0, trialRace=nil,
    gearTouched=false, v3At=0, attackAt=0, skillAt=0, hopAt=0,
    sailDirection=-1, sailLastPos=nil, sailLastAt=0, sailStalls=0,
    boatKeys={}, race=nil, objective=nil, objectiveAt=0,
    attempts={quest=0,mirage=0,lever=0,trial=0,pvp=0,gear=0,train=0,buy=0},
    path="Alpha", reportMax=150,
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
    return obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
        or obj:FindFirstChildWhichIsA("BasePart",true)
end
local function invoke(...)
    local folder=RS:FindFirstChild("Remotes")
    local remote=folder and folder:FindFirstChild("CommF_")
    if not remote then return false,"CommF_ ausente" end
    local args=table.pack(...)
    return pcall(function() return remote:InvokeServer(table.unpack(args,1,args.n)) end)
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
        return ok and result==true
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
        or (not S.auto and not S.manual) then return false end
    local distance=(rp.Position-position).Magnitude
    if distance<=(reach or 10) then return true end
    status("Movimento",label)
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
    local tween=TweenService:Create(rp,TweenInfo.new(duration,Enum.EasingStyle.Linear),
        {CFrame=CFrame.new(limited)})
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
    return success and root() and (root().Position-position).Magnitude<=(reach or 10)
end
local function touch(target)
    local rp=root()
    if not rp or not target or not target.Parent then return false end
    if (rp.Position-target.Position).Magnitude>12 then return false end
    if type(firetouchinterest)=="function" then
        pcall(firetouchinterest,rp,target,0)
        pcall(firetouchinterest,rp,target,1)
    end
    return true
end
local function promptNear(center,radius,nameFilter)
    local rp=root()
    if not rp or (rp.Position-center).Magnitude>(radius or 20) then return false end
    local best,dist
    local map=workspace:FindFirstChild("Map")
    local temple=map and (map:FindFirstChild("Temple of Time") or map:FindFirstChild("TempleOfTime"))
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

local function enterTemple()
    local rp=root()
    if not rp then return false end
    if (rp.Position-POS.temple).Magnitude<1600 then return true end
    if once("entrance",7) then
        local ok,response=invoke("requestEntrance",POS.temple)
        log("Entrada no Templo: "..tostring(ok and response or "remoto indisponivel"))
    end
    task.wait(0.3)
    rp=root()
    if rp and (rp.Position-POS.temple).Magnitude<1600 then return true end
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

local function releaseBoatKeys()
    for key,down in pairs(S.boatKeys) do
        if down then
            pcall(function() VIM:SendKeyEvent(false,Enum.KeyCode[key],false,game) end)
            S.boatKeys[key]=false
        end
    end
end
local function boatKey(key,down)
    if S.boatKeys[key]==down then return true end
    local ok=pcall(function() VIM:SendKeyEvent(down,Enum.KeyCode[key],false,game) end)
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
            touch(gear)
            if once("gearTouch",6) then
                S.gearTouched=true
                log("Blue Gear tocada; verificando Templo")
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
        local activated=promptNear(POS.lever,18)
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
        pcall(function()
            VIM:SendKeyEvent(true,key,false,game)
            task.wait(0.12)
            VIM:SendKeyEvent(false,key,false,game)
        end)
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
        pcall(function()
            VIM:SendKeyEvent(true,Enum.KeyCode.Y,false,game)
            task.wait(0.08)
            VIM:SendKeyEvent(false,Enum.KeyCode.Y,false,game)
        end)
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
        "FLOQUITAVE | KAITUN RACE V4 1.0",
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
    for key,value in pairs(S.attempts) do
        lines[#lines+1]="Tentativas "..key.."="..tostring(value)
    end
    lines[#lines+1]="HISTORICO"
    for _,entry in ipairs(S.history) do lines[#lines+1]=entry end
    return table.concat(lines,"\n")
end

local function v4Step()
    local name=raceName(player)
    S.race=name
    if S.manualTarget then
        local target=S.manualTarget
        S.manualTarget=nil
        S.manual=true
        if target=="temple" then
            enterTemple()
        elseif target=="door" and DOOR[name] and enterTemple() then
            go(DOOR[name],"Indo à porta V4",9)
        end
        S.manual=false
        return
    end
    if name=="" then status("Aguardando","Data.Race ainda não carregou");return end
    if name=="Draco" then
        status("Draco V4","Rota Draco exige relics de Prehistoric Island; sem protocolo seguro para concluir")
        return
    end
    if not DOOR[name] then
        status("Raça sem rota","Raça detectada: "..name)
        return
    end
    if not raceV3() then
        status("Pré-requisito","Raça "..name.." V3 necessária antes da V4")
        return
    end
    local upgrade=upgradeState()
    local clock=clockState()
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
    if trialTimer() then
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
    if not fullMoon() then
        status("Porta "..name,"Aguardando lua cheia para iniciar trial")
        return
    end
    local count=templeTeam()
    if count<3 then
        status("Porta "..name,"Aguardando 3 raças diferentes no Templo ("..count.."/3)")
        return
    end
    if once("trialActivate",7) then
        sendAbility()
        promptNear(DOOR[name],18)
        log("Porta "..name..": habilidade acionada para iniciar trial")
    end
end

-- Um único worker impede múltiplos tweens e remotes concorrendo entre si.
task.spawn(function()
    while S.alive do
        if (S.auto or S.manualTarget) and not S.busy then
            S.busy=true
            local ok,err=xpcall(v4Step,debug.traceback)
            S.busy=false
            if not ok then
                status("Erro na etapa",tostring(err):sub(1,200))
                task.wait(3)
            end
        end
        task.wait(0.75)
    end
end)

local gui=Instance.new("ScreenGui")
gui.Name="Floquitave_Kaitun_RaceV4"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
local okParent=pcall(function() gui.Parent=CoreGui end)
if not okParent then gui.Parent=player:WaitForChild("PlayerGui") end
local function box(class,parent,properties)
    local obj=Instance.new(class)
    for key,value in pairs(properties) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local panel=box("Frame",gui,{
    Name="Panel",Size=UDim2.fromOffset(355,258),Position=UDim2.new(0,16,0.5,-129),
    BackgroundColor3=Color3.fromRGB(24,28,39),BorderSizePixel=0,
})
box("UICorner",panel,{CornerRadius=UDim.new(0,12)})
local title=box("TextLabel",panel,{
    Size=UDim2.new(1,-16,0,35),Position=UDim2.fromOffset(8,5),
    BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=17,
    TextColor3=Color3.fromRGB(225,236,252),TextXAlignment=Enum.TextXAlignment.Left,
    Text="FLOQUITAVE  |  RACE V4",
})
local detail=box("TextLabel",panel,{
    Size=UDim2.new(1,-24,0,94),Position=UDim2.fromOffset(12,42),
    BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=14,
    TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3=Color3.fromRGB(206,215,232),Text="Iniciando...",
})
local function button(label,x,y,w,callback)
    local b=box("TextButton",panel,{
        Size=UDim2.fromOffset(w,34),Position=UDim2.fromOffset(x,y),
        BackgroundColor3=Color3.fromRGB(49,69,108),BorderSizePixel=0,
        Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=Color3.new(1,1,1),Text=label,
    })
    box("UICorner",b,{CornerRadius=UDim.new(0,7)})
    S.connections[#S.connections+1]=b.MouseButton1Click:Connect(callback)
    return b
end
local pauseButton=button("Pausar",12,142,106,function()
    S.auto=not S.auto
    if not S.auto then S.manual=false;releaseBoatKeys();stopMove();status("Pausado","Aguardando botão Retomar") end
end)
button("Alpha / Omega",124,142,133,function()
    S.path=S.path=="Alpha" and "Omega" or "Alpha"
    log("Caminho da próxima engrenagem: "..S.path)
end)
button("Minimizar",263,142,80,function()
    panel.Visible=false
end)
button("Templo",12,185,106,function()
    S.manualTarget="temple"
    stopMove()
end)
button("Porta",124,185,106,function()
    S.manualTarget="door"
    stopMove()
end)
button("Copiar relatório",236,185,107,function()
    if type(setclipboard)=="function" then
        pcall(setclipboard,report())
        log("Relatório copiado")
    else log("Executor sem setclipboard; relatório exibido no console")
        print(report()) end
end)
local footer=box("TextLabel",panel,{
    Size=UDim2.new(1,-24,0,28),Position=UDim2.fromOffset(12,223),
    BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=12,
    TextColor3=Color3.fromRGB(161,175,200),TextXAlignment=Enum.TextXAlignment.Left,
    Text="Caminho: Alpha  |  Third Sea",
})
local opener=box("TextButton",gui,{
    Size=UDim2.fromOffset(104,38),Position=UDim2.new(0,16,0.5,-129),
    BackgroundColor3=Color3.fromRGB(43,78,130),BorderSizePixel=0,
    Font=Enum.Font.GothamBold,TextSize=13,Text="ABRIR V4",
    TextColor3=Color3.new(1,1,1),Visible=false,
})
box("UICorner",opener,{CornerRadius=UDim.new(0,8)})
S.connections[#S.connections+1]=opener.MouseButton1Click:Connect(function()
    panel.Visible=true;opener.Visible=false
end)
S.connections[#S.connections+1]=panel:GetPropertyChangedSignal("Visible"):Connect(function()
    opener.Visible=not panel.Visible
end)
S.connections[#S.connections+1]=RunService.Heartbeat:Connect(function()
    if not S.alive or not gui.Parent then return end
    if not S.uiAt or os.clock()-S.uiAt>0.8 then
        S.uiAt=os.clock()
        detail.Text=S.phase.."\n"..S.detail.."\nRaça: "..tostring(S.race or "...")
            .."  |  Lua cheia: "..(fullMoon() and "sim" or "não")
        pauseButton.Text=S.auto and "Pausar" or "Retomar"
        footer.Text="Caminho: "..S.path.."  |  Third Sea"
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
    if not S.alive then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
log("Race V4 iniciado; somente funções de despertar e upgrades V4")



