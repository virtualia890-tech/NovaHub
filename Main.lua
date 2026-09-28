
-- Tave Hub Shop 1.3 - Fighting Fallback
-- UI based on the supplied screenshots/videos.
-- Shop 1.3: adds long-distance region fallbacks for Electric Claw, Dragon Talon and Sanguine Art.
-- Other categories remain UI-only.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

pcall(function()
    local guiParent = (typeof(gethui) == "function" and gethui() or CoreGui)
    local old = guiParent:FindFirstChild("NovaHub_UI_Base_2")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_UI_Base_3_1_FIXED")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_Shop_1")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_Shop_1_1_FIGHTING_FIX")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_Shop_1_2_FIGHTING_NPC")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_Shop_1_3_FIGHTING_FALLBACK")
    if old then old:Destroy() end
end)

local Theme = {
    Main = Color3.fromRGB(12, 10, 18),
    Header = Color3.fromRGB(19, 16, 28),
    Sidebar = Color3.fromRGB(14, 12, 21),
    Panel = Color3.fromRGB(10, 9, 15),
    Row = Color3.fromRGB(27, 24, 35),
    RowHover = Color3.fromRGB(35, 30, 47),
    Input = Color3.fromRGB(31, 27, 41),
    Accent = Color3.fromRGB(151, 92, 255),
    AccentDark = Color3.fromRGB(94, 53, 178),
    AccentSoft = Color3.fromRGB(125, 78, 215),
    Text = Color3.fromRGB(246, 245, 249),
    Muted = Color3.fromRGB(174, 170, 184),
    Outline = Color3.fromRGB(73, 57, 103),
    Track = Color3.fromRGB(55, 51, 64),
}

local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Theme.Outline,
        Thickness = thickness or 1,
        Transparency = transparency == nil and 0.45 or transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end


-- =========================
-- SHOP RUNTIME (Shop 1)
-- Only the Shop category is connected in this build.
-- =========================
local ShopRuntime = {
    autoLegendarySword = false,
    autoTrueTripleKatana = false,
}

local ShopActions = {}

do
    local function notify(title, message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = tostring(title or "Tave Hub"),
                Text = tostring(message or ""),
                Duration = 3
            })
        end)
    end

    local function commF(...)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        if not remote then
            return false, "CommF_ not found"
        end

        local ok, result = pcall(function(...)
            return remote:InvokeServer(...)
        end, ...)

        if not ok then
            return false, result
        end
        return true, result
    end

    local function simpleRemote(...)
        local ok, result = commF(...)
        if not ok then
            notify("Shop", "Remote error: " .. tostring(result))
            return false
        end
        return true, result
    end

    local function getCommF()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        if not remote then
            notify("Fighting Shop", "CommF_ not found.")
            return nil
        end
        return remote
    end

    local function formatServerResult(result)
        if result == nil then
            return "Request sent."
        end
        local s = tostring(result)
        if #s > 90 then
            s = string.sub(s, 1, 87) .. "..."
        end
        return s
    end

    local function directFightCall(styleName, ...)
        local remote = getCommF()
        if not remote then
            return false
        end

        local args = table.pack(...)
        local ok, result = pcall(function()
            return remote:InvokeServer(table.unpack(args, 1, args.n))
        end)

        if not ok then
            notify(styleName, "Remote error: " .. tostring(result))
            return false
        end

        notify(styleName, formatServerResult(result))
        return true, result
    end

    local function directFightSequence(styleName, calls)
        local remote = getCommF()
        if not remote then
            return false
        end

        local lastResult = nil
        for _, callArgs in ipairs(calls) do
            local ok, result = pcall(function()
                return remote:InvokeServer(table.unpack(callArgs, 1, #callArgs))
            end)

            if not ok then
                notify(styleName, "Remote error: " .. tostring(result))
                return false
            end

            lastResult = result
            task.wait(0.12)
        end

        notify(styleName, formatServerResult(lastResult))
        return true, lastResult
    end

    ShopActions.redeem_codes = function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local redeem = remotes and remotes:FindFirstChild("Redeem")
        if not redeem then
            notify("Redeem Code", "Redeem remote not found.")
            return false
        end

        local codes = {
            "EASTEREXP",
            "KITT_RESET",
            "SUB2GAMERROBOT_EXP1",
            "SUB2GAMERROBOT_RESET1",
            "Sub2UncleKizaru",
            "Sub2CaptainMaui",
            "Sub2Fer999",
            "Enyu_is_Pro",
            "Magicbus",
            "JCWK",
            "kittgaming",
            "Starcodeheo",
            "Bluxxy",
            "Axiore",
            "Sub2Daigrock",
            "Sub2NoobMaster123",
            "TheGreatAce",
            "Sub2OfficialNoobie",
            "TantaiGaming",
            "StrawHatMaine",
            "Fudd10",
            "Fudd10_v2",
            "Bignews",
            "Chandler",
        }

        task.spawn(function()
            for _, code in ipairs(codes) do
                pcall(function()
                    redeem:InvokeServer(code)
                end)
                task.wait(0.08)
            end
            notify("Redeem Code", "Finished trying the current code list.")
        end)
        return true
    end

    ShopActions.travel_main = function()
        return simpleRemote("TravelMain")
    end

    ShopActions.travel_dressrosa = function()
        return simpleRemote("TravelDressrosa")
    end

    ShopActions.travel_zou = function()
        return simpleRemote("TravelZou")
    end

    ShopActions.buy_dual_flintlock = function()
        local ok, result = simpleRemote("BuyItem", "Dual Flintlock")
        if not ok then
            return false, result
        end
        notify("Shop", "Dual Flintlock purchase requested.")
        return true
    end

    ShopActions.reroll_race = function()
        simpleRemote("BlackbeardReward", "Reroll", "1")
        task.wait(0.10)
        local ok = simpleRemote("BlackbeardReward", "Reroll", "2")
        return ok
    end

    ShopActions.reset_stats = function()
        simpleRemote("BlackbeardReward", "Refund", "1")
        task.wait(0.10)
        local ok = simpleRemote("BlackbeardReward", "Refund", "2")
        return ok
    end

    ShopActions.buy_cyborg = function()
        local ok = simpleRemote("CyborgTrainer", "Buy")
        if ok then
            notify("Shop", "Cyborg purchase requested.")
        end
        return ok
    end

    ShopActions.buy_ghoul = function()
        simpleRemote("Ectoplasm", "BuyCheck", 4)
        task.wait(0.10)
        local ok = simpleRemote("Ectoplasm", "Change", 4)
        if ok then
            notify("Shop", "Ghoul purchase requested.")
        end
        return ok
    end

    ShopActions.auto_legendary_sword = function(enabled)
        ShopRuntime.autoLegendarySword = enabled == true
        notify("Shop", ShopRuntime.autoLegendarySword and "Auto Legendary Sword ON" or "Auto Legendary Sword OFF")
        return true
    end

    ShopActions.auto_true_triple_katana = function(enabled)
        ShopRuntime.autoTrueTripleKatana = enabled == true
        notify("Shop", ShopRuntime.autoTrueTripleKatana and "True Triple Katana ON" or "True Triple Katana OFF")
        return true
    end

    -- ============================================================
    -- FIGHTING STYLE NPC ENGINE
    -- One active style at a time. Toggle OFF cancels travel immediately.
    -- Dynamic NPC search is preferred so the same code works with copies
    -- of the teachers across First / Second / Third Sea.
    -- ============================================================
    local FightEngine = {
        activeAction = nil,
        enabled = {},
        moveNonce = 0,
        travelSpeed = 170,
        segmentLength = 28,
        sourceUrl = "https://raw.githubusercontent.com/virtualia890-tech/NovaHub/refs/heads/main/Main.lua",
    }

    local FightStyles = {
        buy_black_leg = {
            label = "Black Leg",
            toolNames = {"Black Leg", "Dark Step"},
            npcNames = {"Dark Step Teacher", "Black Leg Teacher"},
            seas = {1, 2, 3},
            buy = function(remote)
                return remote:InvokeServer("BuyBlackLeg")
            end,
        },

        buy_fishman_karate = {
            label = "Fishman Karate",
            toolNames = {"Fishman Karate", "Water Kung Fu"},
            npcNames = {"Water Kung-fu Teacher", "Water Kung Fu Teacher", "Fishman Karate Teacher"},
            seas = {1, 2, 3},
            buy = function(remote)
                return remote:InvokeServer("BuyFishmanKarate")
            end,
        },

        buy_electro = {
            label = "Electro",
            toolNames = {"Electro", "Electric"},
            npcNames = {"Mad Scientist"},
            seas = {1, 2, 3},
            buy = function(remote)
                return remote:InvokeServer("BuyElectro")
            end,
        },

        buy_dragon_breath = {
            label = "Dragon Breath",
            toolNames = {"Dragon Claw", "Dragon Breath"},
            npcNames = {"Sabi"},
            seas = {2, 3},
            buy = function(remote)
                remote:InvokeServer("BlackbeardReward", "DragonClaw", "1")
                task.wait(0.12)
                return remote:InvokeServer("BlackbeardReward", "DragonClaw", "2")
            end,
        },

        buy_superhuman = {
            label = "SuperHuman",
            toolNames = {"Superhuman", "SuperHuman"},
            npcNames = {"Martial Arts Master"},
            seas = {2, 3},
            buy = function(remote)
                return remote:InvokeServer("BuySuperhuman")
            end,
        },

        buy_death_step = {
            label = "Death Step",
            toolNames = {"Death Step"},
            npcNames = {"Phoeyu, the Reformed", "Phoeyu"},
            seas = {2, 3},
            buy = function(remote)
                return remote:InvokeServer("BuyDeathStep")
            end,
        },

        buy_sharkman_karate = {
            label = "Sharkman Karate",
            toolNames = {"Sharkman Karate"},
            npcNames = {"Sharkman Teacher", "Daigrock, the Sharkman", "Daigrock"},
            seas = {2, 3},
            buy = function(remote)
                remote:InvokeServer("BuySharkmanKarate", true)
                task.wait(0.12)
                return remote:InvokeServer("BuySharkmanKarate")
            end,
        },

        buy_electric_claw = {
            label = "Electric Claw",
            toolNames = {"Electric Claw"},
            npcNames = {"Previous Hero"},
            seas = {3},
            fallbackCFrames = {
                -- Previous Hero / Floating Turtle
                CFrame.new(-10371.4717, 330.764496, -10131.4199),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyElectricClaw")
            end,
        },

        buy_dragon_talon = {
            label = "Dragon Talon",
            toolNames = {"Dragon Talon"},
            npcNames = {"Uzoth"},
            seas = {3},
            fallbackCFrames = {
                -- Current Dragon Dojo / Hydra region
                CFrame.new(5841.298828125, 1208.32177734375, 884.3173217773438),
                -- Older Uzoth/Haunted Castle fallback for compatible maps
                CFrame.new(-9785, 852, 6667),
            },
            beforeFallback = function(remote)
                -- Harmless if unavailable; helps load the Dragon Dojo region in compatible maps.
                pcall(function()
                    remote:InvokeServer(
                        "requestEntrance",
                        Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)
                    )
                end)
                task.wait(0.35)
            end,
            buy = function(remote)
                remote:InvokeServer("BuyDragonTalon", true)
                task.wait(0.12)
                return remote:InvokeServer("BuyDragonTalon")
            end,
        },

        buy_godhuman = {
            label = "God Human",
            toolNames = {"Godhuman", "God Human"},
            npcNames = {"Ancient Monk"},
            seas = {3},
            buy = function(remote)
                return remote:InvokeServer("BuyGodhuman")
            end,
        },

        buy_sanguine_art = {
            label = "Sanguine Art",
            toolNames = {"Sanguine Art"},
            npcNames = {"Shafi"},
            seas = {3},
            fallbackCFrames = {
                -- Tiki Outpost main region
                CFrame.new(-16218.6826, 9.08636189, 445.618408),
                -- Island Boy side of Tiki, close to Shafi's tunnel/base
                CFrame.new(-16901.26171875, 84.06756591796875, -192.88906860351562),
            },
            buy = function(remote)
                remote:InvokeServer("BuySanguineArt", true)
                task.wait(0.12)
                return remote:InvokeServer("BuySanguineArt")
            end,
        },
    }

    local function containsSea(list, sea)
        for _, value in ipairs(list or {}) do
            if value == sea then
                return true
            end
        end
        return false
    end

    local function currentSea()
        local id = game.PlaceId
        if id == 2753915549 then
            return 1
        elseif id == 4442272183 then
            return 2
        elseif id == 7449423635 then
            return 3
        end

        -- Fallback for games/copies that keep Blox Fruits map naming.
        local map = workspace:FindFirstChild("Map")
        if map then
            local function mapHas(name)
                local wanted = string.lower(name)
                for _, obj in ipairs(map:GetDescendants()) do
                    if string.find(string.lower(obj.Name), wanted, 1, true) then
                        return true
                    end
                end
                return false
            end

            if mapHas("tiki") or mapHas("hydra") or mapHas("floating turtle") or mapHas("great tree") then
                return 3
            end
            if mapHas("kingdom") or mapHas("hot and cold") or mapHas("forgotten") or mapHas("snow mountain") then
                return 2
            end
            if mapHas("jungle") or mapHas("pirate village") or mapHas("sky") or mapHas("underwater") then
                return 1
            end
        end

        return 0
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if not character then
            return nil
        end
        return character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Torso")
            or character.PrimaryPart
    end

    local function getHumanoid()
        local character = LocalPlayer.Character
        return character and character:FindFirstChildOfClass("Humanoid") or nil
    end

    local function hasStyleTool(style)
        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        local function containerHas(container)
            if not container then
                return false
            end
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    local low = string.lower(obj.Name)
                    for _, toolName in ipairs(style.toolNames or {}) do
                        if low == string.lower(toolName) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        return containerHas(character) or containerHas(backpack)
    end

    local function npcPartFromObject(obj)
        if not obj then
            return nil
        end

        if obj:IsA("BasePart") then
            return obj
        end

        if obj:IsA("Model") then
            return obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChild("Torso")
                or obj:FindFirstChild("UpperTorso")
                or obj:FindFirstChild("Head")
                or obj.PrimaryPart
        end

        local model = obj:FindFirstAncestorOfClass("Model")
        if model then
            return model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChild("Torso")
                or model:FindFirstChild("UpperTorso")
                or model:FindFirstChild("Head")
                or model.PrimaryPart
        end

        return nil
    end

    local function findNpc(style)
        local aliases = style.npcNames or {}
        local bestPart = nil
        local bestDistance = math.huge
        local playerRoot = getRoot()

        local containers = {}
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs then
            table.insert(containers, npcs)
        end
        table.insert(containers, workspace)

        local visited = {}

        for _, container in ipairs(containers) do
            for _, obj in ipairs(container:GetDescendants()) do
                if not visited[obj] then
                    visited[obj] = true

                    local lowName = string.lower(obj.Name)
                    local matches = false

                    for _, alias in ipairs(aliases) do
                        local lowAlias = string.lower(alias)
                        if lowName == lowAlias or string.find(lowName, lowAlias, 1, true) then
                            matches = true
                            break
                        end
                    end

                    if matches then
                        local part = npcPartFromObject(obj)
                        if part then
                            local distance = playerRoot and (playerRoot.Position - part.Position).Magnitude or 0
                            if distance < bestDistance then
                                bestDistance = distance
                                bestPart = part
                            end
                        end
                    end
                end
            end
        end

        return bestPart
    end

    local function cancelFightMove()
        FightEngine.moveNonce = FightEngine.moveNonce + 1
    end

    local function moveToCFrame(targetCFrame, actionName)
        if not targetCFrame then
            return false
        end

        local root = getRoot()
        local humanoid = getHumanoid()
        if not root or not humanoid then
            return false
        end

        FightEngine.moveNonce = FightEngine.moveNonce + 1
        local nonce = FightEngine.moveNonce
        local speed = FightEngine.travelSpeed
        local segmentLength = FightEngine.segmentLength

        humanoid.Sit = false

        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        local oldCollision = {}
        local noclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if not character then
                return
            end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if oldCollision[part] == nil then
                        oldCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)

        local function restoreCollision()
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            for part, state in pairs(oldCollision) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = state
                    end)
                end
            end
        end

        local targetPosition = targetCFrame.Position
        local horizontalDistance = Vector3.new(
            targetPosition.X - root.Position.X,
            0,
            targetPosition.Z - root.Position.Z
        ).Magnitude
        local verticalDifference = math.abs(targetPosition.Y - root.Position.Y)
        local horizontalFirst = horizontalDistance > 700 and verticalDifference > 180

        local function stillEnabled()
            return FightEngine.enabled[actionName] == true
                and FightEngine.activeAction == actionName
                and nonce == FightEngine.moveNonce
        end

        local function moveLine(destinationPosition, finalLookAt)
            local currentRoot = getRoot()
            if not currentRoot then
                return false
            end

            local startPosition = currentRoot.Position
            local delta = destinationPosition - startPosition
            local distance = delta.Magnitude

            if distance <= 4 then
                pcall(function()
                    currentRoot.CFrame = CFrame.lookAt(
                        destinationPosition,
                        finalLookAt or (destinationPosition + currentRoot.CFrame.LookVector)
                    )
                end)
                return true
            end

            local direction = delta.Unit
            local travelled = 0

            while travelled < distance do
                if not stillEnabled() then
                    return false
                end

                currentRoot = getRoot()
                if not currentRoot then
                    return false
                end

                travelled = math.min(travelled + segmentLength, distance)
                local nextPosition = startPosition + direction * travelled
                local lookAt = finalLookAt or destinationPosition

                if (lookAt - nextPosition).Magnitude < 0.1 then
                    lookAt = nextPosition + currentRoot.CFrame.LookVector
                end

                local nextCFrame = CFrame.lookAt(nextPosition, lookAt)
                local stepDistance = (currentRoot.Position - nextPosition).Magnitude
                local duration = math.max(stepDistance / speed, 0.035)

                local tween = TweenService:Create(
                    currentRoot,
                    TweenInfo.new(duration, Enum.EasingStyle.Linear),
                    {CFrame = nextCFrame}
                )

                local ok = pcall(function()
                    tween:Play()
                    tween.Completed:Wait()
                end)

                if not ok then
                    return false
                end
            end

            return true
        end

        local ok = true

        if horizontalFirst then
            local horizontalTarget = Vector3.new(
                targetPosition.X,
                root.Position.Y,
                targetPosition.Z
            )
            ok = moveLine(horizontalTarget, horizontalTarget + targetCFrame.LookVector)

            if ok then
                ok = moveLine(targetPosition, targetPosition + targetCFrame.LookVector)
            end
        else
            ok = moveLine(targetPosition, targetPosition + targetCFrame.LookVector)
        end

        restoreCollision()

        root = getRoot()
        if not ok or not root then
            return false
        end

        return (root.Position - targetPosition).Magnitude <= 18
    end

    local function getQueueOnTeleport()
        if typeof(queue_on_teleport) == "function" then
            return queue_on_teleport
        end
        if syn and typeof(syn.queue_on_teleport) == "function" then
            return syn.queue_on_teleport
        end
        if fluxus and typeof(fluxus.queue_on_teleport) == "function" then
            return fluxus.queue_on_teleport
        end
        return nil
    end

    local function queueContinuation(actionName)
        local queue = getQueueOnTeleport()
        if not queue then
            return false
        end

        local pending = string.format("%q", actionName)
        local source = string.format("%q", FightEngine.sourceUrl)
        local code = "getgenv().__TavePendingFight=" .. pending
            .. ";task.wait(3);"
            .. "local u=" .. source .. ";"
            .. "local ok,s=pcall(function() return game:HttpGet(u..'?v='..tostring(os.time())) end);"
            .. "if ok and s then pcall(function() loadstring(s)() end) end"

        local ok = pcall(queue, code)
        return ok
    end

    local function travelForStyle(actionName, style)
        local sea = currentSea()
        if sea == 0 or containsSea(style.seas, sea) then
            return false
        end

        local remote = getCommF()
        if not remote then
            return false
        end

        local queued = queueContinuation(actionName)

        if sea == 1 then
            notify(style.label, queued
                and "Changing to Second Sea. Automation will continue after teleport."
                or "Changing to Second Sea. Re-run the hub after teleport if needed.")
            pcall(function()
                remote:InvokeServer("TravelDressrosa")
            end)
            return true
        end

        if sea == 2 and containsSea(style.seas, 3) then
            notify(style.label, queued
                and "Changing to Third Sea. Automation will continue after teleport."
                or "Changing to Third Sea. Re-run the hub after teleport if needed.")
            pcall(function()
                remote:InvokeServer("TravelZou")
            end)
            return true
        end

        return false
    end

    local function runElectricClawQuest(remote, npcPart, actionName)
        -- Current/reference flow:
        -- Previous Hero -> start challenge -> Mansion -> Previous Hero -> buy.
        local ok, result = pcall(function()
            return remote:InvokeServer("BuyElectricClaw")
        end)

        if not ok then
            notify("Electric Claw", "Remote error: " .. tostring(result))
            return false
        end

        if hasStyleTool(FightStyles.buy_electric_claw) then
            return true
        end

        -- The source flow starts the challenge explicitly.
        pcall(function()
            remote:InvokeServer("BuyElectricClaw", "Start")
        end)

        if FightEngine.enabled[actionName] ~= true then
            return false
        end

        local mansion = CFrame.new(-12550.532226563, 336.22631835938, -7510.4233398438)
        if not moveToCFrame(mansion, actionName) then
            return false
        end

        task.wait(0.8)

        if FightEngine.enabled[actionName] ~= true then
            return false
        end

        local refreshedNpc = findNpc(FightStyles.buy_electric_claw) or npcPart
        if refreshedNpc then
            local npcCF = refreshedNpc.CFrame * CFrame.new(0, 0, 5)
            if not moveToCFrame(npcCF, actionName) then
                return false
            end
        else
            local fallback = FightStyles.buy_electric_claw.fallbackCFrames
                and FightStyles.buy_electric_claw.fallbackCFrames[1]
            if fallback and not moveToCFrame(fallback, actionName) then
                return false
            end
        end

        task.wait(0.4)

        local buyOk, buyResult = pcall(function()
            return remote:InvokeServer("BuyElectricClaw")
        end)

        if not buyOk then
            notify("Electric Claw", "Remote error: " .. tostring(buyResult))
            return false
        end

        notify("Electric Claw", formatServerResult(buyResult))
        return true
    end

    local function loadFallbackRegion(actionName, style)
        local fallbacks = style.fallbackCFrames
        if not fallbacks or #fallbacks == 0 then
            return nil
        end

        local remote = getCommF()

        if style.beforeFallback and remote then
            pcall(style.beforeFallback, remote)
        end

        for index, fallbackCF in ipairs(fallbacks) do
            if FightEngine.enabled[actionName] ~= true
                or FightEngine.activeAction ~= actionName
            then
                return nil
            end

            notify(
                style.label,
                "NPC is far away. Loading region " .. tostring(index) .. "/" .. tostring(#fallbacks) .. "..."
            )

            local moved = moveToCFrame(fallbackCF, actionName)
            if not moved then
                if FightEngine.enabled[actionName] ~= true then
                    return nil
                end
            end

            -- Give StreamingEnabled / NPC folders time to populate after arriving.
            local started = os.clock()
            while FightEngine.enabled[actionName] == true
                and FightEngine.activeAction == actionName
                and os.clock() - started < 5.0
            do
                local npcPart = findNpc(style)
                if npcPart then
                    return npcPart
                end
                task.wait(0.25)
            end
        end

        return nil
    end

    local function runFightStyle(actionName)
        local style = FightStyles[actionName]
        if not style then
            return
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        if travelForStyle(actionName, style) then
            return
        end

        notify(style.label, "Searching for " .. tostring(style.npcNames[1]) .. "...")

        local npcPart = nil
        local searchStart = os.clock()

        while FightEngine.enabled[actionName] == true
            and FightEngine.activeAction == actionName
            and os.clock() - searchStart < 12
        do
            npcPart = findNpc(style)
            if npcPart then
                break
            end
            task.wait(0.5)
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        if not npcPart then
            npcPart = loadFallbackRegion(actionName, style)
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        if npcPart then
            notify(style.label, "Going to NPC...")

            local targetCF = npcPart.CFrame * CFrame.new(0, 0, 5)
            if not moveToCFrame(targetCF, actionName) then
                if FightEngine.enabled[actionName] then
                    notify(style.label, "Movement stopped or failed.")
                end
                return
            end
        elseif style.fallbackCFrames and #style.fallbackCFrames > 0 then
            -- Region is loaded but NPC may be hidden inside a base/interior.
            -- Stay at the last fallback and still try the purchase/equip remote.
            notify(style.label, "Region loaded. Trying the style purchase...")
        else
            local sea = currentSea()
            notify(style.label, "NPC not found in Sea " .. tostring(sea) .. ".")
            return
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        task.wait(0.35)

        local remote = getCommF()
        if not remote then
            return
        end

        if actionName == "buy_electric_claw" then
            runElectricClawQuest(remote, npcPart, actionName)
            return
        end

        local ok, result = pcall(function()
            return style.buy(remote)
        end)

        if not ok then
            notify(style.label, "Remote error: " .. tostring(result))
            return
        end

        task.wait(0.25)

        if hasStyleTool(style) then
            notify(style.label, "Style equipped.")
        else
            notify(style.label, formatServerResult(result))
        end
    end

    local function setFightStyle(actionName, enabled)
        local style = FightStyles[actionName]
        if not style then
            return false
        end

        if enabled then
            if FightEngine.activeAction and FightEngine.activeAction ~= actionName then
                local other = FightStyles[FightEngine.activeAction]
                notify("Fighting Shop", "Turn OFF " .. tostring(other and other.label or "the other style") .. " first.")
                return false
            end

            FightEngine.activeAction = actionName
            FightEngine.enabled[actionName] = true

            task.spawn(function()
                runFightStyle(actionName)
            end)

            return true
        end

        FightEngine.enabled[actionName] = false
        if FightEngine.activeAction == actionName then
            FightEngine.activeAction = nil
        end
        cancelFightMove()
        notify(style.label, "Automation OFF")
        return true
    end

    ShopActions.buy_black_leg = function(enabled)
        return setFightStyle("buy_black_leg", enabled)
    end

    ShopActions.buy_fishman_karate = function(enabled)
        return setFightStyle("buy_fishman_karate", enabled)
    end

    ShopActions.buy_electro = function(enabled)
        return setFightStyle("buy_electro", enabled)
    end

    ShopActions.buy_dragon_breath = function(enabled)
        return setFightStyle("buy_dragon_breath", enabled)
    end

    ShopActions.buy_superhuman = function(enabled)
        return setFightStyle("buy_superhuman", enabled)
    end

    ShopActions.buy_death_step = function(enabled)
        return setFightStyle("buy_death_step", enabled)
    end

    ShopActions.buy_sharkman_karate = function(enabled)
        return setFightStyle("buy_sharkman_karate", enabled)
    end

    ShopActions.buy_electric_claw = function(enabled)
        return setFightStyle("buy_electric_claw", enabled)
    end

    ShopActions.buy_dragon_talon = function(enabled)
        return setFightStyle("buy_dragon_talon", enabled)
    end

    ShopActions.buy_godhuman = function(enabled)
        return setFightStyle("buy_godhuman", enabled)
    end

    ShopActions.buy_sanguine_art = function(enabled)
        return setFightStyle("buy_sanguine_art", enabled)
    end

    ShopActions.buy_geppo = function()
        return simpleRemote("BuyHaki", "Geppo")
    end

    ShopActions.buy_buso = function()
        return simpleRemote("BuyHaki", "Buso")
    end

    ShopActions.buy_observation = function()
        return simpleRemote("KenTalk", "Buy")
    end

    ShopActions.buy_soru = function()
        return simpleRemote("BuyHaki", "Soru")
    end

    task.spawn(function()
        task.wait(2.0)
        local pending = getgenv and getgenv().__TavePendingFight or nil
        if pending and FightStyles[pending] then
            if getgenv then
                getgenv().__TavePendingFight = nil
            end
            ShopActions[pending](true)
        end
    end)

    task.spawn(function()
        while task.wait(0.85) do
            if ShopRuntime.autoLegendarySword then
                for slot = 1, 3 do
                    if not ShopRuntime.autoLegendarySword then
                        break
                    end
                    commF("LegendarySwordDealer", tostring(slot))
                    task.wait(0.12)
                end
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.85) do
            if ShopRuntime.autoTrueTripleKatana then
                commF("MysteriousMan", "1")
                task.wait(0.10)
                commF("MysteriousMan", "2")
            end
        end
    end)
end

local PagesData = {
    { name = "Shop", sections = {
        { title = "Misc Shop", items = {
            { type = "button", text = "Redeem Code", action = "redeem_codes" },
            { type = "button", text = "Teleport Old World", action = "travel_main" },
            { type = "button", text = "Teleport New World", action = "travel_dressrosa" },
            { type = "button", text = "Teleport Third Sea", action = "travel_zou" },
            { type = "button", text = "Buy Dual Flintlock", action = "buy_dual_flintlock" },
            { type = "button", text = "Reroll Race", action = "reroll_race" },
            { type = "button", text = "Reset Stats", action = "reset_stats" },
            { type = "button", text = "Buy Cyborg Race", action = "buy_cyborg" },
            { type = "button", text = "Buy Ghoul Race", action = "buy_ghoul" },
            { type = "toggle", text = "Auto Buy Legendary Sword", action = "auto_legendary_sword" },
            { type = "toggle", text = "True Triple Katana", action = "auto_true_triple_katana" },
        } },
        { title = "Fighting Shop", items = {
            { type = "toggle", text = "Black Leg", action = "buy_black_leg" },
            { type = "toggle", text = "Fishman Karate", action = "buy_fishman_karate" },
            { type = "toggle", text = "Electro", action = "buy_electro" },
            { type = "toggle", text = "Dragon Breath", action = "buy_dragon_breath" },
            { type = "toggle", text = "SuperHuman", action = "buy_superhuman" },
            { type = "toggle", text = "Death Step", action = "buy_death_step" },
            { type = "toggle", text = "Sharkman Karate", action = "buy_sharkman_karate" },
            { type = "toggle", text = "Electric Claw", action = "buy_electric_claw" },
            { type = "toggle", text = "Dragon Talon", action = "buy_dragon_talon" },
            { type = "toggle", text = "God Human", action = "buy_godhuman" },
            { type = "toggle", text = "Sanguine Art", action = "buy_sanguine_art" },
        } },
        { title = "Abilities Shop", items = {
            { type = "button", text = "Skyjump [ $10,000 Beli ]", action = "buy_geppo" },
            { type = "button", text = "Buso Haki [ $25,000 Beli ]", action = "buy_buso" },
            { type = "button", text = "Observation haki [ $750,000 Beli ]", action = "buy_observation" },
            { type = "button", text = "Soru [ $100,000 Beli ]", action = "buy_soru" },
        } },
    } },
    { name = "Status & Server", sections = {
        { title = "Status", items = {
            { type = "info", text = "Timer: 0h 00m 00s" },
            { type = "info", text = "Server Timer: 0h 00m 00s" },
            { type = "info", text = "Next Time Spawn Fist of Darkness or God's Chalice: --" },
            { type = "info", text = "Elite Hunter: --" },
            { type = "info", text = "Tyrant Eyes: 0 Eyes" },
            { type = "info", text = "Cake Prince: -- Mobs" },
            { type = "info", text = "Leviathan: I DON'T KNOW" },
            { type = "info", text = "Mirage Island: ❌" },
            { type = "info", text = "Prehistoric Island: ❌" },
            { type = "info", text = "Frozen Dimension: ❌" },
            { type = "info", text = "Moon Phase: --" },
            { type = "info", text = "Ancient One: --" },
        } },
        { title = "Server", items = {
            { type = "info", text = "PlaceId: CURRENT_PLACE_ID" },
            { type = "input", text = "Input JobId Normal And JobId", placeholder = "Type here" },
            { type = "toggle", text = "Spam Join" },
            { type = "button", text = "Join JobId" },
            { type = "button", text = "Copy JobId" },
            { type = "button", text = "Hop Server" },
            { type = "button", text = "Hop Server Less People" },
        } },
    } },
    { name = "LocalPlayer", sections = {
        { title = "Utility", items = {
            { type = "toggle", text = "Auto Translate" },
            { type = "button", text = "Stop Tween" },
            { type = "button", text = "Fix UI Button Game" },
            { type = "button", text = "Show Item" },
            { type = "button", text = "Open Devil Fruit Shop" },
            { type = "button", text = "Open Devil Fruit Shop Mirage" },
            { type = "button", text = "Open Title" },
            { type = "button", text = "Open Color" },
        } },
        { title = "Stats / Team", items = {
            { type = "dropdown", text = "Select Stats", options = { "Demon Fruit", "Defense", "Melee", "Sword", "Gun" } },
            { type = "toggle", text = "Auto Stats" },
            { type = "dropdown", text = "Select Team", options = { "Pirate", "Marine" } },
            { type = "button", text = "Change Team" },
        } },
        { title = "Movement", items = {
            { type = "toggle", text = "Noclip" },
        } },
        { title = "NPC Teleport", items = {
            { type = "dropdown", text = "Select NPC", options = { "Experienced Captain", "Blacksmith", "Fisherman", "Pirate Port Quest Giver", "Blox Fruit Dealer", "Fossil Expert", "Lucien", "Submarine Worker", "Sharkman Master", "Doghouse", "Mysterious Force", "Ancient One", "Sealed King", "Gravestone", "Skeleton Machine", "Frozen Watcher", "Dojo Trainer", "Dragon Tamer", "Sweet Crafter", "Cake Scientist", "Elite Hunter", "Player Hunter" } },
            { type = "button", text = "Teleport To NPC" },
        } },
        { title = "Island Teleport", items = {
            { type = "dropdown", text = "Select Island", options = { "Hydra Island", "Peanut Island", "Ice Cream Island", "House Hydra Island", "Tiki", "Haunted Castle", "Port Town", "Great Tree", "Floating Turtle", "Room Enma/Yama & Secret Temple" } },
            { type = "button", text = "Teleport To Island" },
            { type = "button", text = "Teleport Mirage" },
            { type = "button", text = "Teleport Prehistoric Island" },
        } },
    } },
    { name = "Setting Farm", sections = {
        { title = "Farm Setting", items = {
            { type = "toggle", text = "Auto Click" },
            { type = "toggle", text = "Kill Aura With DragonStorm" },
            { type = "toggle", text = "Auto Turn On Buso" },
            { type = "toggle", text = "Auto Turn On Observation" },
            { type = "toggle", text = "Auto Turn On V4" },
            { type = "toggle", text = "Auto Turn On V3" },
            { type = "toggle", text = "Auto Dodge Skill Mobs" },
            { type = "toggle", text = "Teleport Y if low health" },
            { type = "slider", text = "% Health Player", value = 40, min = 0, max = 100 },
            { type = "slider", text = "Distance Teleport Y", value = 800, min = 0, max = 2000 },
            { type = "toggle", text = "Tween Safe if have Items" },
            { type = "slider", text = "Time Hop Server", value = 10, min = 1, max = 60 },
            { type = "toggle", text = "Use Portal Teleport" },
            { type = "slider", text = "Bring Mob Count", value = 2, min = 1, max = 10 },
            { type = "toggle", text = "Bring Mob" },
            { type = "toggle", text = "Reset Teleport [Beta]" },
            { type = "slider", text = "Tween Speed", value = 170, min = 50, max = 400 },
        } },
    } },
    { name = "Hold and Select Skill", sections = {
        { title = "Select Skills", items = {
            { type = "dropdown", text = "Select Skills Melee", options = { "Z", "X", "C" } },
            { type = "dropdown", text = "Select Skills Sword", options = { "Z", "X" } },
            { type = "dropdown", text = "Select Skills Gun", options = { "Z", "X" } },
            { type = "dropdown", text = "Select Skills Blox Fruit", options = { "Z", "X", "C", "V", "F" } },
        } },
        { title = "Hold Skills", items = {
            { type = "toggle", text = "Use skill fast dont hold" },
            { type = "slider", text = "Set Delay Melee Z", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Melee X", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Melee C", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Sword Z", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Sword X", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Gun Z", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Gun X", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Blox Fruit Z", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Blox Fruit X", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Blox Fruit C", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Blox Fruit V", value = 0.5, min = 0, max = 5 },
            { type = "slider", text = "Set Delay Blox Fruit F", value = 0.5, min = 0, max = 5 },
        } },
    } },
    { name = "Farming", sections = {
        { title = "Farming", items = {
            { type = "dropdown", text = "Select Method Farm", options = { "Farm Katakuri" } },
            { type = "slider", text = "Distance Farm Aura", value = 300, min = 0, max = 1000 },
            { type = "toggle", text = "Ignore Attack Katakuri" },
            { type = "toggle", text = "Hop Find Katakuri" },
            { type = "toggle", text = "Auto Quest [Katakuri/Bone/Tyrant]" },
            { type = "toggle", text = "Start Farm" },
        } },
        { title = "Mastery Farm", items = {
            { type = "dropdown", text = "Select Method Farm Mastery", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "slider", text = "Health %", value = 40, min = 0, max = 100 },
            { type = "toggle", text = "Farm Mastery" },
        } },
        { title = "Farming Material", items = {
            { type = "dropdown", text = "Select Material", options = { "Vampire Fang", "Fish Tail", "Gunpowder", "Bones", "Mystic Droplet", "Conjured Cocoa", "Dragon Scale", "Leather", "Ectoplasm", "Mini Tusk", "Magma Ore", "Scrap Metal", "Angel Wings", "Radioactive Material", "Demonic Wisp" } },
            { type = "toggle", text = "Farm Material" },
        } },
    } },
    { name = "Stack Farming", sections = {
        { title = "Auto World", items = {
            { type = "toggle", text = "Auto New World" },
            { type = "toggle", text = "Auto Third World" },
        } },
        { title = "Devil Fruit", items = {
            { type = "toggle", text = "Collect Chest When Server Spawn God's Chalice or Fist of Darkness" },
            { type = "toggle", text = "Teleport To Fruit" },
            { type = "toggle", text = "Teleport To Fruit [Hop Server]" },
        } },
        { title = "Event Game", items = {
            { type = "toggle", text = "Auto Factory" },
            { type = "toggle", text = "Auto Pirate Raid" },
        } },
        { title = "Boss Rip Indra", items = {
            { type = "toggle", text = "Auto Elite Hunter" },
            { type = "toggle", text = "Hop Server Elite Hunter" },
            { type = "toggle", text = "Auto Touch Pad Haki" },
            { type = "toggle", text = "Auto Summon Rip Indra" },
            { type = "toggle", text = "Attack Rip Indra" },
        } },
        { title = "Boss Soul Reaper", items = {
            { type = "toggle", text = "Attack Soul Reaper" },
            { type = "toggle", text = "Summon Soul Reaper" },
        } },
        { title = "Boss Dough King", items = {
            { type = "toggle", text = "Attack Dough King" },
            { type = "toggle", text = "Summon Dough King" },
            { type = "toggle", text = "Hop Find Dough King" },
        } },
        { title = "Boss Darkbeard", items = {
            { type = "toggle", text = "Attack Darkbeard" },
            { type = "toggle", text = "Summon Darkbeard" },
            { type = "toggle", text = "Hop Find Darkbeard" },
        } },
    } },
    { name = "Farming Other", sections = {
        { title = "Event Magnet", items = {
            { type = "toggle", text = "Auto Event Magnet" },
        } },
        { title = "Fishing", items = {
            { type = "toggle", text = "Change Size Reel" },
            { type = "toggle", text = "Auto Slap Battle" },
            { type = "info", text = "Position Fishing: --" },
            { type = "button", text = "Save Position Fishing" },
            { type = "dropdown", text = "Select Bait", options = { "Basic Bait", "Good Bait", "Perfect Bait" } },
            { type = "info", text = "Status Fishing: Idle" },
            { type = "toggle", text = "Auto Tween To Event Fishing Spot" },
            { type = "toggle", text = "Auto Fishing" },
            { type = "toggle", text = "Auto Sell Fishing" },
            { type = "toggle", text = "Auto Open Chest" },
            { type = "dropdown", text = "Select Quest Fishing", options = { "Quest 1", "Quest 2", "Quest 3" } },
            { type = "toggle", text = "Auto Accept Quest Fishing" },
        } },
        { title = "Quest Dragon", items = {
            { type = "toggle", text = "Auto Quest Dojo Trainer" },
            { type = "toggle", text = "Auto Quest Dragon Hunter" },
        } },
        { title = "Attack All Mobs", items = {
            { type = "toggle", text = "Auto Attack All Mob and Boss" },
        } },
        { title = "Berry", items = {
            { type = "toggle", text = "Hop Find Berry" },
            { type = "toggle", text = "Auto Collect Berry" },
        } },
        { title = "Farm Chest", items = {
            { type = "slider", text = "Value Collect Chest to Hop", value = 29.5, min = 1, max = 100 },
            { type = "toggle", text = "Auto Chest Hop" },
            { type = "toggle", text = "Use Method Teleport [Risk]" },
            { type = "toggle", text = "Auto Chest" },
        } },
        { title = "Raid Law", items = {
            { type = "toggle", text = "Auto Buy Chip and Attack Law" },
        } },
        { title = "Farm Observation", items = {
            { type = "toggle", text = "Auto UP Observation V2" },
            { type = "toggle", text = "Farm Observation" },
            { type = "toggle", text = "Farm Observation [Hop Server]" },
        } },
        { title = "Auto Kill Mob", items = {
            { type = "dropdown", text = "Select Mob", options = { "Select..." } },
            { type = "toggle", text = "Kill Mob" },
        } },
        { title = "Auto Boss", items = {
            { type = "dropdown", text = "Select Boss", options = { "Select..." } },
            { type = "button", text = "Refresh Boss" },
            { type = "toggle", text = "Kill Boss" },
            { type = "toggle", text = "Kill All Boss" },
            { type = "toggle", text = "Hop Server Find Boss" },
        } },
    } },
    { name = "Fruit and Raid and Dungeon", sections = {
        { title = "Devil Fruit", items = {
            { type = "button", text = "Random Devil Fruit" },
            { type = "toggle", text = "Auto Roll Magnetic Gacha" },
            { type = "toggle", text = "Auto Store Fruit" },
            { type = "dropdown", text = "Blox Fruit Sniper Shop", options = { "Select Fruit" } },
            { type = "toggle", text = "Buy Blox Fruit Sniper Shop" },
        } },
        { title = "Raids", items = {
            { type = "dropdown", text = "Select Raid", options = { "Flame", "Ice", "Sand", "Dark", "Light", "Magma", "Quake", "Buddha", "Spider", "Rumble", "Phoenix", "Dough" } },
            { type = "toggle", text = "Get Fruit In Inventory Low Beli" },
            { type = "toggle", text = "Auto Raid" },
            { type = "toggle", text = "Hop Server Raid" },
            { type = "toggle", text = "Auto Awake Fruit" },
        } },
        { title = "Multi Raid", items = {
            { type = "dropdown", text = "Select Player", options = { "Select Player" } },
            { type = "button", text = "Refresh Player" },
            { type = "toggle", text = "Account Buy Chip" },
            { type = "dropdown", text = "Account Pick Slot Raid", options = { "1", "2", "3", "4" } },
            { type = "toggle", text = "Auto Multi Raid" },
        } },
        { title = "Join Dungeon", items = {
            { type = "dropdown", text = "Select Account Join", options = { "Select Account" } },
            { type = "button", text = "Refresh Player" },
            { type = "slider", text = "Min Player Join Dungeon", value = 1, min = 1, max = 12 },
            { type = "dropdown", text = "Select Difficulty", options = { "Easy", "Normal", "Hard" } },
            { type = "toggle", text = "Account Start Dungeon" },
            { type = "toggle", text = "Auto Join Dungeon" },
        } },
        { title = "Dungeon", items = {
            { type = "dropdown", text = "Select Weapon Dungeon", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "dropdown", text = "Select Card Priority", options = { "Damage", "Cooldown", "Defense" } },
            { type = "toggle", text = "Auto Attack Dungeon" },
            { type = "toggle", text = "Auto Pick Card Dungeon" },
        } },
    } },
    { name = "Sea Event", sections = {
        { title = "Setting", items = {
            { type = "dropdown", text = "Select Zone", options = { "Zone 1", "Zone 2", "Zone 3", "Zone 4", "Zone 5", "Zone 6" } },
            { type = "dropdown", text = "Select Sea Events", options = { "Sea Beast", "Terrorshark", "Piranha", "Shark", "Fish Crew", "Ghost Ship" } },
            { type = "dropdown", text = "Select Boat", options = { "Guardian", "Beast Hunter", "Lantern" } },
            { type = "dropdown", text = "Select Weapons Use Skill", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "toggle", text = "Use Dragonstorm For Sea Event" },
            { type = "toggle", text = "Use Click M1 Skull Guitar For Sea Event" },
            { type = "toggle", text = "Auto Change Dragonstorm With Skull Guitar" },
            { type = "toggle", text = "Auto Change Dragonstorm When Kill Boat" },
            { type = "toggle", text = "Use Click M1 Fruit For Sea Event" },
            { type = "toggle", text = "Reset Character Buy Boat" },
            { type = "toggle", text = "Auto Dodge Skill Terrorshark / Seabeast" },
            { type = "toggle", text = "Teleport Boat Other CFrame if Rough Sea" },
            { type = "toggle", text = "Tween Until Have Sea Event" },
            { type = "toggle", text = "Will Back When over 10km" },
        } },
        { title = "Farming", items = {
            { type = "dropdown", text = "Select Friend", options = { "Select Friend" } },
            { type = "toggle", text = "Auto Sea Event With Friend" },
            { type = "toggle", text = "Auto Repair Ur Ship" },
            { type = "toggle", text = "Auto Sea Event" },
            { type = "toggle", text = "Auto Find Mirage" },
        } },
        { title = "Kitsune Event", items = {
            { type = "button", text = "Teleport Kitsune Island" },
            { type = "toggle", text = "Hop Server" },
            { type = "toggle", text = "Auto Spawn Kitsune Island" },
            { type = "toggle", text = "Auto Summon/Collect Soul Ember" },
            { type = "toggle", text = "Azure Ember" },
            { type = "toggle", text = "Auto Trade Azure Ember" },
        } },
        { title = "Leviathan", items = {
            { type = "button", text = "Buy Spy" },
            { type = "toggle", text = "Auto Buy Spy" },
            { type = "toggle", text = "Beast Hunter" },
            { type = "toggle", text = "Multi Find Leviathan" },
            { type = "toggle", text = "Auto Find Leviathan" },
            { type = "toggle", text = "Auto Start Leviathan" },
            { type = "toggle", text = "Attack Leviathan Segments" },
            { type = "toggle", text = "Attack Leviathan With Fruit" },
            { type = "toggle", text = "Attack Leviathan With DragonStorm" },
            { type = "toggle", text = "Attack Leviathan With Skull Guitar" },
            { type = "toggle", text = "Auto Find Frozen Dimension" },
            { type = "toggle", text = "Shoot Leviathan Heart" },
        } },
        { title = "Boat Setting", items = {
            { type = "toggle", text = "Fly Boat" },
            { type = "slider", text = "Speed Boat", value = 250, min = 50, max = 1000 },
            { type = "slider", text = "Speed Fly Boat", value = 250, min = 50, max = 1000 },
            { type = "button", text = "Change Speed Boat" },
            { type = "button", text = "Drive to Tiki" },
            { type = "button", text = "Drive to Hydra" },
        } },
    } },
    { name = "Upgrade Race", sections = {
        { title = "Draco", items = {
            { type = "toggle", text = "Auto Trial Draco" },
            { type = "toggle", text = "Fully Trial Draco" },
            { type = "toggle", text = "Ignore Craft Volcanic Magnet" },
            { type = "toggle", text = "Auto Buy Gear Draco" },
            { type = "toggle", text = "Auto Finish Train Draco Quest" },
        } },
        { title = "Race Normal", items = {
            { type = "toggle", text = "Auto Upgrade Race V2-V3" },
            { type = "toggle", text = "Auto Get Fully Cyborg" },
            { type = "toggle", text = "Auto Get Cyborg Hop Collect Chest" },
            { type = "toggle", text = "Auto Get Cyborg" },
            { type = "toggle", text = "Hop Cursed Captain" },
            { type = "toggle", text = "Auto Get Ghoul" },
        } },
        { title = "Race V4", items = {
            { type = "toggle", text = "No Frog" },
            { type = "button", text = "Teleport Ancient Clock" },
            { type = "toggle", text = "Auto Buy Gear" },
            { type = "dropdown", text = "Select Gear V4", options = { "Gear 1", "Gear 2", "Gear 3" } },
            { type = "toggle", text = "Auto Choose Gears" },
            { type = "toggle", text = "Auto Finish Train Quest" },
            { type = "toggle", text = "Stack Train With Trial Race" },
            { type = "toggle", text = "Hop Server Trial/Pull Lever" },
            { type = "toggle", text = "Auto Pull Lever" },
            { type = "dropdown", text = "Select Players Multi", options = { "Select Player" } },
            { type = "toggle", text = "Multi Trial" },
            { type = "toggle", text = "Auto Reset Character" },
            { type = "toggle", text = "Auto Trial" },
            { type = "toggle", text = "Auto Turn On V3 Near Door" },
        } },
        { title = "Kill Trial", items = {
            { type = "dropdown", text = "Select Weapon Attack Trial", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "toggle", text = "Kill Players When Complete Trial" },
            { type = "toggle", text = "Use Skill When Kill Player" },
            { type = "toggle", text = "Just Use Skill When Player Active Ken" },
        } },
    } },
    { name = "Get and Upgrade Items", sections = {
        { title = "Items", items = {
            { type = "toggle", text = "Auto Trade Bone" },
            { type = "toggle", text = "Auto Buy Legendary Sword" },
            { type = "toggle", text = "Auto Buy Haki Color" },
            { type = "toggle", text = "Hop Server [Haki color or Legendary Sword]" },
            { type = "toggle", text = "Auto Get Rainbow Haki" },
            { type = "toggle", text = "Auto Soul Guitar" },
            { type = "dropdown", text = "Select Method Hop CDK", options = { "Normal", "Hop Server" } },
            { type = "toggle", text = "Auto CDK" },
            { type = "toggle", text = "Auto Yama" },
            { type = "toggle", text = "Auto Tushita" },
            { type = "toggle", text = "Auto TTK" },
            { type = "toggle", text = "Auto Saber" },
            { type = "toggle", text = "Auto Craft Shark Anchor" },
            { type = "toggle", text = "Auto Yoru Mini" },
            { type = "toggle", text = "Auto Yoru Mini [Hop Server]" },
        } },
        { title = "Mastery Weapon", items = {
            { type = "toggle", text = "Auto Farm Mastery 600 Melees" },
            { type = "toggle", text = "Auto Farm Mastery 600 Sword In Inventory" },
        } },
        { title = "Upgrade Weapon", items = {
            { type = "toggle", text = "Auto Upgrade Sword Inventory" },
            { type = "toggle", text = "Auto Upgrade Gun Inventory" },
        } },
    } },
    { name = "Volcano Event", sections = {
        { title = "Volcano", items = {
            { type = "dropdown", text = "Select Weapon Kill Golem", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "dropdown", text = "Select Weapons Fix Lava", options = { "Melee", "Sword", "Gun", "Blox Fruit" } },
            { type = "dropdown", text = "Select Method Kill Golem", options = { "Normal", "Fast" } },
            { type = "toggle", text = "Auto Crafting Volcanic Magnet" },
            { type = "toggle", text = "Auto Find Prehistoric Island" },
            { type = "toggle", text = "Auto Event Prehistoric Island" },
            { type = "toggle", text = "Auto Collect Bone" },
            { type = "toggle", text = "Auto Collect Egg" },
        } },
        { title = "Fully Volcano", items = {
            { type = "toggle", text = "Ignore Craft Volcanic Magnet" },
            { type = "toggle", text = "Ignore Collect Bone" },
            { type = "toggle", text = "Fully Event Prehistoric Island" },
        } },
    } },
    { name = "ESP", sections = {
        { title = "ESP", items = {
            { type = "toggle", text = "ESP Berry" },
            { type = "toggle", text = "ESP Island" },
            { type = "toggle", text = "ESP Fruit" },
            { type = "toggle", text = "ESP Player" },
        } },
    } },
    { name = "PVP", sections = {
        { title = "PVP", items = {
            { type = "dropdown", text = "Select Player PVP", options = { "Select Player" } },
            { type = "dropdown", text = "Select Method Aimbot", options = { "Camera", "Mouse" } },
            { type = "button", text = "Refresh Player" },
            { type = "button", text = "Teleport Player" },
            { type = "toggle", text = "Auto Aimbot" },
            { type = "toggle", text = "Auto Aimbot Gun" },
        } },
        { title = "Misc PVP", items = {
            { type = "slider", text = "WalkSpeed", value = 16, min = 0, max = 250 },
            { type = "slider", text = "JumpPower", value = 50, min = 0, max = 250 },
            { type = "button", text = "Change JumpPower" },
            { type = "button", text = "Change WalkSpeed" },
            { type = "toggle", text = "Walk On Water" },
        } },
    } },
    { name = "Tab Webhook", sections = {
        { title = "Webhook", items = {
            { type = "input", text = "Input Discord Ping", placeholder = "User ID / Role ID" },
            { type = "toggle", text = "Ping Everyone/ID Discord" },
            { type = "toggle", text = "Noti Profile" },
            { type = "dropdown", text = "Select Rarity Fruit", options = { "Common", "Uncommon", "Rare", "Legendary", "Mythical" } },
            { type = "toggle", text = "Webhook Store Fruit" },
            { type = "toggle", text = "Webhook Find Prehistoric Island" },
            { type = "toggle", text = "Webhook Find Leviathan" },
            { type = "toggle", text = "Webhook Destroy IDK" },
            { type = "toggle", text = "Webhook Find Mirage" },
        } },
    } },
    { name = "Setting", sections = {
        { title = "Setting", items = {
            { type = "toggle", text = "White Screen" },
            { type = "toggle", text = "Black Screen" },
            { type = "toggle", text = "Remove Notifications" },
            { type = "toggle", text = "Auto Rejoin Disconnect" },
            { type = "toggle", text = "Auto Load Script" },
            { type = "button", text = "Boost FPS" },
            { type = "button", text = "Copy Config" },
            { type = "dropdown", text = "Toggle GUI", options = { "LeftControl", "RightControl", "Insert", "Home" } },
        } },
    } },
}

local ScreenGui = New("ScreenGui", {
    Name = "TaveHub_Shop_1_3_FIGHTING_FALLBACK",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = false
})

do
    local parented = false
    if typeof(gethui) == "function" then
        parented = pcall(function() ScreenGui.Parent = gethui() end)
    end
    if not parented then
        parented = pcall(function() ScreenGui.Parent = CoreGui end)
    end
    if not parented then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local Main = New("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(810, 555),
    BackgroundColor3 = Theme.Main,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, ScreenGui)
Corner(Main, 7)
Stroke(Main, Theme.AccentDark, 1.4, 0.28)

local Scale = New("UIScale", {}, Main)
local function UpdateScale()
    local wanted = UserInputService.TouchEnabled and 0.52 or 0.91
    local cam = workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        local fit = math.min((vp.X * 0.94) / 810, (vp.Y * 0.92) / 555)
        wanted = math.min(wanted, fit)
    end
    Scale.Scale = math.clamp(wanted, 0.34, 0.95)
end
UpdateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0
}, Main)


local Title = New("TextLabel", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    RichText = true,
    Text = '<font color="#975CFF"><b>Tave Hub</b></font>  - Blox Fruit',
    TextColor3 = Theme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Center
}, Header)

local HideBtn = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -40, 0.5, 0),
    Size = UDim2.fromOffset(24, 22),
    BackgroundColor3 = Theme.Row,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false
}, Header)
Corner(HideBtn, 5)
Stroke(HideBtn, Theme.Outline, 1, 0.55)

local CloseBtn = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.fromOffset(24, 22),
    BackgroundColor3 = Theme.Row,
    BorderSizePixel = 0,
    Text = "X",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    AutoButtonColor = false
}, Header)
Corner(CloseBtn, 5)
Stroke(CloseBtn, Theme.Outline, 1, 0.55)

local Body = New("Frame", {
    Position = UDim2.fromOffset(0, 38),
    Size = UDim2.new(1, 0, 1, -38),
    BackgroundTransparency = 1
}, Main)

local Sidebar = New("Frame", {
    Position = UDim2.fromOffset(6, 5),
    Size = UDim2.new(0, 218, 1, -10),
    BackgroundColor3 = Theme.Sidebar,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0
}, Body)
Corner(Sidebar, 5)
Stroke(Sidebar, Theme.AccentDark, 1, 0.62)

local SearchHolder = New("Frame", {
    Position = UDim2.fromOffset(6, 6),
    Size = UDim2.new(1, -12, 0, 31),
    BackgroundColor3 = Theme.Input,
    BorderSizePixel = 0
}, Sidebar)
Corner(SearchHolder, 4)
Stroke(SearchHolder, Theme.AccentDark, 1, 0.72)

New("TextLabel", {
    Position = UDim2.fromOffset(7, 0),
    Size = UDim2.fromOffset(22, 31),
    BackgroundTransparency = 1,
    Text = "⌕",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 18
}, SearchHolder)

local Search = New("TextBox", {
    Position = UDim2.fromOffset(28, 0),
    Size = UDim2.new(1, -32, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Search section or Function",
    PlaceholderColor3 = Color3.fromRGB(165, 166, 171),
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false
}, SearchHolder)

local PageList = New("ScrollingFrame", {
    Position = UDim2.fromOffset(5, 42),
    Size = UDim2.new(1, -10, 1, -47),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(180, 180, 184)
}, Sidebar)
New("UIListLayout", {Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder}, PageList)

local Right = New("Frame", {
    Position = UDim2.fromOffset(230, 5),
    Size = UDim2.new(1, -236, 1, -10),
    BackgroundColor3 = Theme.Panel,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0
}, Body)
Corner(Right, 5)
Stroke(Right, Theme.AccentDark, 1, 0.66)

local PageTitle = New("TextLabel", {
    Position = UDim2.fromOffset(10, 5),
    Size = UDim2.new(1, -42, 0, 26),
    BackgroundTransparency = 1,
    Text = "Shop",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, Right)

New("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 5),
    Size = UDim2.fromOffset(24, 24),
    BackgroundTransparency = 1,
    Text = "⌕",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 19
}, Right)

local PageHost = New("Frame", {
    Position = UDim2.fromOffset(8, 34),
    Size = UDim2.new(1, -16, 1, -40),
    BackgroundTransparency = 1
}, Right)

local PageFrames = {}
local PageButtons = {}
local itemSearchCache = {}

local function SectionHeader(parent, text)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1
    }, parent)

    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center
    }, holder)

    New("Frame", {
        Position = UDim2.new(0, 4, 1, -3),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundColor3 = Theme.AccentDark,
        BorderSizePixel = 0
    }, holder)
    return holder
end

local function RowBase(parent, height)
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 38),
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
        Active = true
    }, parent)
    Corner(row, 6)
    Stroke(row, Theme.Outline, 1, 0.62)
    row.MouseEnter:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.RowHover}, 0.10)
    end)
    row.MouseLeave:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.Row}, 0.10)
    end)
    return row
end

local function AddButton(parent, text, callback)
    local row = RowBase(parent, 39)
    local label = New("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -125, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local button = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(94, 30),
        BackgroundColor3 = Theme.AccentSoft,
        BorderSizePixel = 0,
        Text = "Click",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false
    }, row)
    Corner(button, 12)
    Stroke(button, Theme.Accent, 1, 0.34)
    New("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(169, 117, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(101, 57, 185))
        })
    }, button)
    button.MouseButton1Click:Connect(function()
        local old = button.Text
        button.Text = "..."
        Tween(button, {BackgroundColor3 = Theme.Accent}, 0.08)

        local callbackOk = true
        if callback then
            local ok, result = pcall(callback)
            callbackOk = ok and result ~= false
        end

        task.delay(0.18, function()
            if button.Parent then
                button.Text = callbackOk and old or "Error"
                Tween(button, {BackgroundColor3 = callbackOk and Theme.AccentSoft or Color3.fromRGB(145, 55, 76)}, 0.12)
                if not callbackOk then
                    task.delay(0.65, function()
                        if button.Parent then
                            button.Text = old
                            Tween(button, {BackgroundColor3 = Theme.AccentSoft}, 0.12)
                        end
                    end)
                end
            end
        end)
    end)
    return row
end

local function AddToggle(parent, text, callback)
    local row = RowBase(parent, 35)
    New("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -54, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local box = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, row)
    Corner(box, 4)
    Stroke(box, Theme.Accent, 1.5, 0)

    local fill = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false
    }, box)
    Corner(fill, 2)

    local enabled = false
    box.MouseButton1Click:Connect(function()
        enabled = not enabled
        fill.Visible = enabled
        row:SetAttribute("Value", enabled)

        if callback then
            local ok, result = pcall(callback, enabled)
            if not ok or result == false then
                enabled = not enabled
                fill.Visible = enabled
                row:SetAttribute("Value", enabled)
            end
        end
    end)
    row:SetAttribute("Value", enabled)
    return row
end

local function AddInfo(parent, text)
    local row = RowBase(parent, 31)
    local label = New("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -22, 1, 0),
        BackgroundTransparency = 1,
        Text = text == "PlaceId: CURRENT_PLACE_ID" and ("PlaceId: " .. tostring(game.PlaceId)) or text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    return row
end

local function AddInput(parent, text, placeholder)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1
    }, parent)
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local box = New("TextBox", {
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 31),
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder or "Type here",
        PlaceholderColor3 = Theme.Muted,
        TextColor3 = Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    }, holder)
    Corner(box, 4)
    Stroke(box, Color3.fromRGB(55, 56, 63), 1, 0.55)
    New("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, box)
    return holder
end

local function AddDropdown(parent, text, options)
    options = options or {"Select..."}
    if #options < 1 then
        options = {"Select..."}
    end

    local closedHeight = 39
    local optionHeight = 30
    local maxVisible = 5
    local visibleCount = math.min(#options, maxVisible)
    local menuHeight = (visibleCount * optionHeight) + 6

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, closedHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, parent)

    local row = RowBase(holder, closedHeight)

    local current = tostring(options[1] or "Select...")

    local label = New("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -58, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. current,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)

    local arrow = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(24, 22),
        BackgroundColor3 = Theme.Row,
        BorderSizePixel = 0,
        Text = "▼",
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false
    }, row)
    Corner(arrow, 4)
    Stroke(arrow, Theme.Accent, 1.4, 0)

    local menu = New("Frame", {
        Position = UDim2.fromOffset(0, closedHeight + 3),
        Size = UDim2.new(1, 0, 0, menuHeight),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Visible = false
    }, holder)
    Corner(menu, 5)
    Stroke(menu, Theme.AccentDark, 1, 0.35)

    local scroll = New("ScrollingFrame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight),
        ScrollBarThickness = #options > maxVisible and 3 or 0,
        ScrollBarImageColor3 = Theme.AccentSoft
    }, menu)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, scroll)

    local opened = false

    local function setOpen(state)
        opened = state == true
        menu.Visible = opened
        arrow.Text = opened and "▲" or "▼"
        holder.Size = UDim2.new(
            1, 0, 0,
            opened and (closedHeight + menuHeight + 5) or closedHeight
        )
    end

    for index, option in ipairs(options) do
        local optionText = tostring(option)
        local optionButton = New("TextButton", {
            Size = UDim2.new(1, -4, 0, optionHeight - 1),
            BackgroundColor3 = Theme.Row,
            BorderSizePixel = 0,
            Text = "  " .. optionText,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = index
        }, scroll)
        Corner(optionButton, 4)

        optionButton.MouseButton1Click:Connect(function()
            current = optionText
            label.Text = text .. ": " .. current
            holder:SetAttribute("Value", current)
            setOpen(false)
        end)
    end

    holder:SetAttribute("Value", current)

    arrow.MouseButton1Click:Connect(function()
        setOpen(not opened)
    end)

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local x = input.Position.X
            if x < arrow.AbsolutePosition.X then
                setOpen(not opened)
            end
        end
    end)

    return holder
end

local function AddSlider(parent, text, value, minValue, maxValue, onChanged)
    local row = RowBase(parent, 52)
    local currentValue = tonumber(value) or tonumber(minValue) or 0
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 100
    if maxValue < minValue then
        minValue, maxValue = maxValue, minValue
    end

    -- Decimal defaults (0.5, 29.5, etc.) keep tenths; whole-number defaults move in integers.
    local step = (math.abs(currentValue - math.floor(currentValue)) > 0.0001) and 0.1 or 1
    local decimals = step < 1 and 1 or 0

    local valueLabel = New("TextLabel", {
        Position = UDim2.fromOffset(11, 3),
        Size = UDim2.new(1, -22, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local bar = New("Frame", {
        Position = UDim2.new(0, 11, 1, -16),
        Size = UDim2.new(1, -22, 0, 6),
        BackgroundColor3 = Theme.Track,
        BorderSizePixel = 0,
        Active = true
    }, row)
    Corner(bar, 3)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0
    }, bar)
    Corner(fill, 3)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(225, 210, 255),
        BorderSizePixel = 0,
        ZIndex = 3
    }, bar)
    Corner(knob, 7)
    Stroke(knob, Theme.Accent, 1.5, 0.05)

    local hitbox = New("TextButton", {
        Position = UDim2.fromOffset(-5, -10),
        Size = UDim2.new(1, 10, 1, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    }, bar)

    local function roundToStep(v)
        if step <= 0 then return v end
        return math.floor((v / step) + 0.5) * step
    end

    local function valueString(v)
        if decimals == 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%.1f", v)
    end

    local function setValue(v, fireCallback)
        v = math.clamp(roundToStep(tonumber(v) or minValue), minValue, maxValue)
        currentValue = v
        local ratio = (maxValue == minValue) and 0 or ((v - minValue) / (maxValue - minValue))
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLabel.Text = text .. ": " .. valueString(v)
        row:SetAttribute("Value", v)
        if fireCallback and onChanged then
            pcall(onChanged, v)
        end
    end

    local function setFromX(x)
        local width = math.max(bar.AbsoluteSize.X, 1)
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
        setValue(minValue + ((maxValue - minValue) * ratio), true)
    end

    local dragging = false
    local activeInput = nil

    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = input
            setFromX(input.Position.X)
        end
    end)

    hitbox.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.Touch and (activeInput == input or activeInput == nil) then
            setFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            activeInput = nil
        end
    end)

    setValue(currentValue, false)
    return row
end

local function ItemMatches(item, query)
    if query == "" then return true end
    local hay = string.lower(item.text or "")
    return string.find(hay, query, 1, true) ~= nil
end

local function BuildPage(pageData)
    local page = New("ScrollingFrame", {
        Name = pageData.name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(184, 184, 188),
        Visible = false
    }, PageHost)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    local records = {}
    for _, section in ipairs(pageData.sections) do
        local sectionHeader = SectionHeader(page, section.title)
        table.insert(records, {kind="section", object=sectionHeader, title=section.title, items={}})
        local sectionRecord = records[#records]

        for _, item in ipairs(section.items) do
            local obj
            if item.type == "button" then
                obj = AddButton(page, item.text, item.action and ShopActions[item.action] or nil)
            elseif item.type == "toggle" then
                obj = AddToggle(page, item.text, item.action and ShopActions[item.action] or nil)
            elseif item.type == "info" then
                obj = AddInfo(page, item.text)
            elseif item.type == "input" then
                obj = AddInput(page, item.text, item.placeholder)
            elseif item.type == "dropdown" then
                obj = AddDropdown(page, item.text, item.options)
            elseif item.type == "slider" then
                obj = AddSlider(page, item.text, item.value, item.min, item.max, function(v) item.value = v end)
            end
            if obj then
                table.insert(sectionRecord.items, {object=obj, item=item})
            end
        end
    end

    PageFrames[pageData.name] = page
    itemSearchCache[pageData.name] = records
end

for _, pageData in ipairs(PagesData) do
    BuildPage(pageData)
end

local SelectedPage = nil
local function ShowPage(name)
    SelectedPage = name
    PageTitle.Text = name
    for pageName, page in pairs(PageFrames) do
        page.Visible = pageName == name
        if pageName == name then page.CanvasPosition = Vector2.new(0, 0) end
    end
    for pageName, rec in pairs(PageButtons) do
        local selected = pageName == name
        rec.button.BackgroundColor3 = selected and Color3.fromRGB(30, 25, 40) or Theme.Sidebar
        rec.button.TextColor3 = selected and Theme.Text or Theme.Text
        rec.bar.Visible = selected
    end
end

for index, pageData in ipairs(PagesData) do
    local button = New("TextButton", {
        Size = UDim2.new(1, -2, 0, 30),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Text = "      " .. pageData.name,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = index
    }, PageList)
    Corner(button, 3)

    local selectedBar = New("Frame", {
        Position = UDim2.fromOffset(3, 5),
        Size = UDim2.fromOffset(4, 20),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false
    }, button)
    Corner(selectedBar, 2)

    button.MouseEnter:Connect(function()
        if SelectedPage ~= pageData.name then
            Tween(button, {BackgroundColor3 = Color3.fromRGB(25, 21, 33)}, 0.10)
        end
    end)
    button.MouseLeave:Connect(function()
        if SelectedPage ~= pageData.name then
            Tween(button, {BackgroundColor3 = Theme.Sidebar}, 0.10)
        end
    end)
    button.MouseButton1Click:Connect(function()
        ShowPage(pageData.name)
    end)

    PageButtons[pageData.name] = {button=button, bar=selectedBar, data=pageData}
end

local function CategoryHasMatch(pageData, query)
    if query == "" then return true end
    if string.find(string.lower(pageData.name), query, 1, true) then return true end
    for _, section in ipairs(pageData.sections) do
        if string.find(string.lower(section.title), query, 1, true) then return true end
        for _, item in ipairs(section.items) do
            if ItemMatches(item, query) then return true end
        end
    end
    return false
end

Search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(Search.Text or "")
    for pageName, rec in pairs(PageButtons) do
        rec.button.Visible = CategoryHasMatch(rec.data, q)
    end
end)

-- Drag window by header.
do
    local dragging = false
    local dragStart
    local startPos

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

local Floating = New("TextButton", {
    Position = UDim2.fromOffset(20, 180),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
    Text = "T",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    Visible = false,
    AutoButtonColor = false
}, ScreenGui)
Corner(Floating, 24)
Stroke(Floating, Theme.Accent, 1.3, 0.2)

HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Floating.Visible = true
end)
Floating.MouseButton1Click:Connect(function()
    Floating.Visible = false
    Main.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

ShowPage("Shop")

print("[Tave Hub] Shop 1.3 loaded - long-distance Fighting Style fallbacks active.")
