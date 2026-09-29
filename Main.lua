
-- Tave Hub LocalPlayer 4
-- UI based on the supplied screenshots/videos.
-- LocalPlayer 4: preserves all approved pages and connects the complete LocalPlayer page.
-- Shop, Status & Server, LocalPlayer, ESP, PVP, Tab Webhook and Setting are functional.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")

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
    old = guiParent:FindFirstChild("TaveHub_Shop_1_4_FIGHTING_GOTO_NPC")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_Shop_1_5_SMOOTH_TRAVEL")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_StatusServer_2")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_StatusServer_2_1_FIXED")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_QuickPages_3")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_QuickPages_3_1_WATER_DEFAULT")
    if old then old:Destroy() end
    old = guiParent:FindFirstChild("TaveHub_LocalPlayer_4")
    if old then old:Destroy() end
end)

local ScreenGui, Main, Floating
local UIControls = {}

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
        -- segmentLength is kept only for backwards compatibility; Shop 1.5 no longer steps CFrames.
        segmentLength = 28,
        smoothTravel = true,
        sourceUrl = "https://raw.githubusercontent.com/virtualia890-tech/NovaHub/refs/heads/main/Main.lua",
    }

    local FightStyles = {
        buy_black_leg = {
            label = "Black Leg",
            toolNames = {"Black Leg", "Dark Step"},
            npcNames = {"Dark Step Teacher", "Black Leg Teacher"},
            seas = {1, 2, 3},
            stageCFrames = {
                [1] = CFrame.new(-987.873047, 13.7778397, 3989.4978),
                [2] = CFrame.new(-6127.654296875, 15.951762199402, -5040.2861328125),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyBlackLeg")
            end,
        },

        buy_fishman_karate = {
            label = "Fishman Karate",
            toolNames = {"Fishman Karate", "Water Kung Fu"},
            npcNames = {"Water Kung-fu Teacher", "Water Kung Fu Teacher", "Fishman Karate Teacher"},
            seas = {1, 2, 3},
            stageCFrames = {
                [1] = CFrame.new(61581.8047, 18.8965912, 987.832703),
                [2] = CFrame.new(-6127.654296875, 15.951762199402, -5040.2861328125),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyFishmanKarate")
            end,
        },

        buy_electro = {
            label = "Electro",
            toolNames = {"Electro", "Electric"},
            npcNames = {"Mad Scientist"},
            seas = {1, 2, 3},
            stageCFrames = {
                [1] = CFrame.new(-5389.49561, 13.283, -2149.80151),
                [2] = CFrame.new(-6127.654296875, 15.951762199402, -5040.2861328125),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyElectro")
            end,
        },

        buy_dragon_breath = {
            label = "Dragon Breath",
            toolNames = {"Dragon Claw", "Dragon Breath"},
            npcNames = {"Sabi"},
            seas = {2, 3},
            stageCFrames = {
                [2] = CFrame.new(703.372986, 186.985519, 654.522034),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
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
            stageCFrames = {
                [2] = CFrame.new(753.14288330078, 408.23559570313, -5274.6147460938),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
            buy = function(remote)
                return remote:InvokeServer("BuySuperhuman")
            end,
        },

        buy_death_step = {
            label = "Death Step",
            toolNames = {"Death Step"},
            npcNames = {"Phoeyu, the Reformed", "Phoeyu"},
            seas = {2, 3},
            stageCFrames = {
                [2] = CFrame.new(6148.4116210938, 294.38687133789, -6741.1166992188),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyDeathStep")
            end,
        },

        buy_sharkman_karate = {
            label = "Sharkman Karate",
            toolNames = {"Sharkman Karate"},
            npcNames = {"Sharkman Teacher", "Daigrock, the Sharkman", "Daigrock"},
            seas = {2, 3},
            stageCFrames = {
                [2] = CFrame.new(-3032.7641601563, 317.89672851563, -10075.373046875),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
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
            stageCFrames = {
                [3] = CFrame.new(-10368, 332, -10128),
            },
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
            stageCFrames = {
                [3] = CFrame.new(5841.298828125, 1208.32177734375, 884.3173217773438),
            },
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
            stageCFrames = {
                [3] = CFrame.new(-12462, 375, -7552),
            },
            buy = function(remote)
                return remote:InvokeServer("BuyGodhuman")
            end,
        },

        buy_sanguine_art = {
            label = "Sanguine Art",
            toolNames = {"Sanguine Art"},
            npcNames = {"Shafi"},
            seas = {3},
            stageCFrames = {
                [3] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
            },
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

        -- Cancel any older Fighting Shop movement.
        FightEngine.moveNonce = FightEngine.moveNonce + 1
        local nonce = FightEngine.moveNonce
        local speed = FightEngine.travelSpeed

        humanoid.Sit = false

        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        local oldCollision = {}

        -- Noclip stays active for the whole continuous tween so terrain/buildings
        -- do not push the character upward or cause the old flick effect.
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

            local currentRoot = getRoot()
            if currentRoot then
                pcall(function()
                    currentRoot.AssemblyLinearVelocity = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                end)
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

        local function stillEnabled()
            return FightEngine.enabled[actionName] == true
                and FightEngine.activeAction == actionName
                and nonce == FightEngine.moveNonce
        end

        root = getRoot()
        if not root then
            restoreCollision()
            return false
        end

        local distance = (root.Position - targetCFrame.Position).Magnitude

        if distance <= 4 then
            if stillEnabled() then
                pcall(function()
                    root.CFrame = targetCFrame
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
                restoreCollision()
                return true
            end

            restoreCollision()
            return false
        end

        -- One single linear Tween from the current position to the teacher.
        -- No intermediate CFrame snaps, no artificial rise, no horizontal-first phase.
        local duration = math.max(distance / speed, 0.12)

        local tween = TweenService:Create(
            root,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {CFrame = targetCFrame}
        )

        local finished = false
        local playbackState = nil

        local completedConnection = tween.Completed:Connect(function(state)
            playbackState = state
            finished = true
        end)

        local played = pcall(function()
            tween:Play()
        end)

        if not played then
            completedConnection:Disconnect()
            restoreCollision()
            return false
        end

        while not finished do
            if not stillEnabled() then
                pcall(function()
                    tween:Cancel()
                end)
                completedConnection:Disconnect()
                restoreCollision()
                return false
            end

            -- If the character respawns while traveling, stop cleanly instead of
            -- snapping the new character to an old CFrame.
            local currentRoot = getRoot()
            if currentRoot ~= root then
                pcall(function()
                    tween:Cancel()
                end)
                completedConnection:Disconnect()
                restoreCollision()
                return false
            end

            task.wait(0.03)
        end

        completedConnection:Disconnect()
        restoreCollision()

        if playbackState ~= Enum.PlaybackState.Completed then
            return false
        end

        root = getRoot()
        if not root then
            return false
        end

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        return (root.Position - targetCFrame.Position).Magnitude <= 20
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

    local function goToTeacherRegion(actionName, style)
        local sea = currentSea()
        local stage = style.stageCFrames and style.stageCFrames[sea]
        if not stage then
            return true
        end

        if FightEngine.enabled[actionName] ~= true
            or FightEngine.activeAction ~= actionName
        then
            return false
        end

        local remote = getCommF()

        -- Dragon Talon / special interiors may expose a supported entrance request.
        if style.beforeFallback and remote then
            pcall(style.beforeFallback, remote)
        end

        notify(style.label, "Going to teacher location...")

        local moved = moveToCFrame(stage, actionName)
        if not moved then
            if FightEngine.enabled[actionName] then
                notify(style.label, "Could not reach teacher region.")
            end
            return false
        end

        -- Let StreamingEnabled load the island/interior/NPC after arrival.
        local started = os.clock()
        while FightEngine.enabled[actionName] == true
            and FightEngine.activeAction == actionName
            and os.clock() - started < 4.5
        do
            local npcPart = findNpc(style)
            if npcPart then
                return true
            end
            task.wait(0.25)
        end

        -- Reaching the known region is enough to attempt the fallback/buy flow.
        return FightEngine.enabled[actionName] == true
            and FightEngine.activeAction == actionName
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

        -- If this style does not exist in the current Sea, use the existing
        -- Sea-change flow first. Continuation is queued when supported.
        if travelForStyle(actionName, style) then
            return
        end

        -- IMPORTANT: always go to the known teacher region FIRST.
        -- This avoids relying on a far-away NPC being streamed into Workspace.
        if not goToTeacherRegion(actionName, style) then
            return
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        -- Once the region is loaded, find the actual NPC and move right next to it.
        local npcPart = nil
        local searchStart = os.clock()

        while FightEngine.enabled[actionName] == true
            and FightEngine.activeAction == actionName
            and os.clock() - searchStart < 6.0
        do
            npcPart = findNpc(style)
            if npcPart then
                break
            end
            task.wait(0.25)
        end

        -- Some interiors/NPCs still need a second staging point.
        if not npcPart then
            npcPart = loadFallbackRegion(actionName, style)
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        if npcPart then
            notify(style.label, "NPC loaded. Moving next to teacher...")

            local targetCF = npcPart.CFrame * CFrame.new(0, 0, 4)
            if not moveToCFrame(targetCF, actionName) then
                if FightEngine.enabled[actionName] then
                    notify(style.label, "Could not reach the NPC.")
                end
                return
            end
        else
            -- We are already at the verified teacher region. This is useful for
            -- NPCs hidden inside an interior whose model is not exposed to the client.
            notify(style.label, "Teacher region loaded. Trying purchase/equip...")
        end

        if FightEngine.enabled[actionName] ~= true then
            return
        end

        task.wait(0.40)

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


-- ============================================================
-- STATUS & SERVER RUNTIME
-- Shop 1.5 stays untouched. This block only serves page #2.
-- ============================================================
local StatusRuntime = {
    startedAt = os.clock(),
    infoLabels = {},
    jobId = "",
    spamJoin = false,
    monitorRunning = false,
    lastHeavyUpdate = 0,
    cachedElite = "--",
    cachedTyrantEyes = 0,
    cachedCakePrince = "--",
}

local StatusActions = {}

do
    local function statusNotify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tave Hub - Server",
                Text = tostring(message or ""),
                Duration = 3
            })
        end)
    end

    local function formatTime(totalSeconds)
        totalSeconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))
        local hours = math.floor(totalSeconds / 3600)
        local minutes = math.floor((totalSeconds % 3600) / 60)
        local seconds = totalSeconds % 60
        return string.format("%dh %02dm %02ds", hours, minutes, seconds)
    end

    local function setInfo(key, value)
        local label = StatusRuntime.infoLabels[key]
        if label and label.Parent then
            local nextText = tostring(value)
            if label.Text ~= nextText then
                label.Text = nextText
            end
        end
    end

    local function getCommFStatus()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        return remotes and remotes:FindFirstChild("CommF_") or nil
    end

    local function invokeStatus(...)
        local remote = getCommFStatus()
        if not remote then
            return false, nil
        end
        local args = table.pack(...)
        local ok, result = pcall(function()
            return remote:InvokeServer(table.unpack(args, 1, args.n))
        end)
        return ok, result
    end

    local function hasChildName(container, wantedNames)
        if not container then
            return false, nil
        end

        for _, child in ipairs(container:GetChildren()) do
            local low = string.lower(child.Name)
            for _, wanted in ipairs(wantedNames) do
                if string.find(low, string.lower(wanted), 1, true) then
                    return true, child
                end
            end
        end

        return false, nil
    end

    local function hasRecursiveName(container, wantedNames)
        if not container then
            return false, nil
        end

        local ok, result = pcall(function()
            for _, obj in ipairs(container:GetDescendants()) do
                local low = string.lower(obj.Name)
                for _, wanted in ipairs(wantedNames) do
                    if string.find(low, string.lower(wanted), 1, true) then
                        return true, obj
                    end
                end
            end
            return false, nil
        end)

        if ok then
            return result
        end

        return false, nil
    end

    local function playerHasItem(names)
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local character = LocalPlayer.Character

        for _, container in ipairs({backpack, character}) do
            if container then
                for _, obj in ipairs(container:GetChildren()) do
                    local low = string.lower(obj.Name)
                    for _, name in ipairs(names) do
                        if low == string.lower(name) then
                            return true
                        end
                    end
                end
            end
        end

        return false
    end

    local function getEliteStatus()
        local enemies = workspace:FindFirstChild("Enemies")
        local names = {"Diablo", "Deandre", "Urban"}

        local spawned = false
        for _, name in ipairs(names) do
            if (enemies and enemies:FindFirstChild(name))
                or ReplicatedStorage:FindFirstChild(name)
                or (enemies and enemies:FindFirstChild(name .. " [Lv. 1750] [Elite]"))
            then
                spawned = true
                break
            end
        end

        local progress = "?"
        local ok, result = invokeStatus("EliteHunter", "Progress")
        if ok and result ~= nil then
            progress = tostring(result)
        end

        if spawned then
            return "Elite Hunter: Spawned ✅ | Kills: " .. progress
        end

        return "Elite Hunter: Not spawned ❌ | Kills: " .. progress
    end

    local function getTyrantEyes()
        local ok, inventory = invokeStatus("getInventory")
        if not ok or type(inventory) ~= "table" then
            return StatusRuntime.cachedTyrantEyes or 0
        end

        local count = 0
        for _, entry in pairs(inventory) do
            if type(entry) == "table" then
                local name = tostring(entry.Name or entry.name or "")
                local low = string.lower(name)
                if string.find(low, "tyrant", 1, true)
                    and string.find(low, "eye", 1, true)
                then
                    count = tonumber(entry.Count or entry.count or entry.Amount or entry.amount or 1) or 0
                    break
                end
            end
        end

        return count
    end

    local function getCakePrinceStatus()
        local ok, result = invokeStatus("CakePrinceSpawner")
        if not ok or result == nil then
            return "--"
        end

        local s = tostring(result)

        -- Match the known Blox Fruits response layout used by older/current hubs.
        local len = #s
        local killed = nil
        if len == 88 then
            killed = tonumber(string.sub(s, 39, 41))
        elseif len == 87 then
            killed = tonumber(string.sub(s, 39, 40))
        elseif len == 86 then
            killed = tonumber(string.sub(s, 39, 39))
        end

        if killed then
            return tostring(killed) .. " / 500 Mobs"
        end

        local enemies = workspace:FindFirstChild("Enemies")
        local bossSpawned =
            (enemies and (
                enemies:FindFirstChild("Cake Prince")
                or enemies:FindFirstChild("Cake Prince [Lv. 2300] [Raid Boss]")
                or enemies:FindFirstChild("Dough King")
                or enemies:FindFirstChild("Dough King [Lv. 2300] [Raid Boss]")
            ))
            or ReplicatedStorage:FindFirstChild("Cake Prince")
            or ReplicatedStorage:FindFirstChild("Cake Prince [Lv. 2300] [Raid Boss]")
            or ReplicatedStorage:FindFirstChild("Dough King")
            or ReplicatedStorage:FindFirstChild("Dough King [Lv. 2300] [Raid Boss]")

        if bossSpawned then
            return "Boss Spawned ✅"
        end

        -- Fallback: show the server response itself, trimmed.
        if #s > 62 then
            s = string.sub(s, 1, 59) .. "..."
        end
        return s ~= "" and s or "--"
    end

    local function getMoonPhase()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then
            return "--"
        end

        local texture = tostring(sky.MoonTextureId or "")
        local phases = {
            ["9709149431"] = "100% 🌕",
            ["9709149052"] = "75%",
            ["9709143733"] = "50%",
            ["9709150401"] = "25%",
            ["9709149680"] = "15%",
            ["16223659141"] = "100% 🌕",
        }

        for id, phase in pairs(phases) do
            if string.find(texture, id, 1, true) then
                return phase
            end
        end

        return "0%"
    end

    local function checkMapObject(names, recursive)
        local map = workspace:FindFirstChild("Map")
        if not map then
            return false
        end

        if recursive then
            local found = hasRecursiveName(map, names)
            return found == true
        end

        local found = hasChildName(map, names)
        return found == true
    end

    local function getLeviathanStatus()
        local enemies = workspace:FindFirstChild("Enemies")
        local foundEnemy = hasChildName(enemies, {"Leviathan"})
        local foundStorage = hasChildName(ReplicatedStorage, {"Leviathan"})

        if foundEnemy or foundStorage then
            return "Spawned ✅"
        end

        return "Not found ❌"
    end

    local function getAncientOneStatus()
        local npcs = workspace:FindFirstChild("NPCs")
        if npcs then
            local found = hasRecursiveName(npcs, {"Ancient One"})
            if found == true then
                return "Loaded ✅"
            end
        end

        -- Ancient One belongs to the Third Sea race/V4 area. If the NPC is streamed
        -- out, avoid falsely claiming the quest state; just report load state.
        if game.PlaceId == 7449423635 then
            return "Not loaded (far away)"
        end

        return "Third Sea only"
    end

    local function updateFastStatus()
        local elapsed = os.clock() - StatusRuntime.startedAt
        local serverTime = workspace.DistributedGameTime or 0

        setInfo("timer", "Timer: " .. formatTime(elapsed))
        setInfo("server_timer", "Server Timer: " .. formatTime(serverTime))
        setInfo("place_id", "PlaceId: " .. tostring(game.PlaceId))

        local hasFist = playerHasItem({"Fist of Darkness"})
        local hasChalice = playerHasItem({"God's Chalice"})
        if hasFist or hasChalice then
            local available = {}
            if hasFist then table.insert(available, "Fist ✅") end
            if hasChalice then table.insert(available, "Chalice ✅") end
            setInfo(
                "fist_chalice",
                "Next Time Spawn Fist of Darkness or God's Chalice: "
                    .. table.concat(available, " | ")
            )
        else
            local cycle = 4 * 60 * 60
            local nextCycle = cycle - (math.floor(serverTime) % cycle)
            setInfo(
                "fist_chalice",
                "Next Time Spawn Fist of Darkness or God's Chalice: Fist ~"
                    .. formatTime(nextCycle)
                    .. " | Chalice random"
            )
        end

        -- These checks only inspect direct children / Lighting and are cheap.
        setInfo("leviathan", "Leviathan: " .. getLeviathanStatus())
        setInfo("moon", "Moon Phase: " .. getMoonPhase())
    end

    local function updateWorldStatus()
        local map = workspace:FindFirstChild("Map")
        local mirage = false
        local prehistoric = false
        local frozen = false

        -- One map traversal updates all three world-event labels.
        -- The old version could traverse the map several times every second.
        if map then
            local descendants = map:GetDescendants()
            for i = 1, #descendants do
                local low = string.lower(descendants[i].Name)

                if not mirage and (
                    string.find(low, "mysticisland", 1, true)
                    or string.find(low, "mirageisland", 1, true)
                    or string.find(low, "mirage island", 1, true)
                ) then
                    mirage = true
                end

                if not prehistoric and (
                    string.find(low, "prehistoricisland", 1, true)
                    or string.find(low, "prehistoric island", 1, true)
                ) then
                    prehistoric = true
                end

                if not frozen and (
                    string.find(low, "frozendimension", 1, true)
                    or string.find(low, "frozen dimension", 1, true)
                ) then
                    frozen = true
                end

                if mirage and prehistoric and frozen then
                    break
                end
            end
        end

        setInfo("mirage", "Mirage Island: " .. (mirage and "✅" or "❌"))
        setInfo("prehistoric", "Prehistoric Island: " .. (prehistoric and "✅" or "❌"))
        setInfo("frozen", "Frozen Dimension: " .. (frozen and "✅" or "❌"))
    end

    local function updateAncientStatus()
        setInfo("ancient_one", "Ancient One: " .. getAncientOneStatus())
    end

    local function updateEliteStatus()
        StatusRuntime.cachedElite = getEliteStatus()
        setInfo("elite", StatusRuntime.cachedElite)
    end

    local function updateTyrantStatus()
        StatusRuntime.cachedTyrantEyes = getTyrantEyes()
        setInfo("tyrant_eyes", "Tyrant Eyes: " .. tostring(StatusRuntime.cachedTyrantEyes) .. " Eyes")
    end

    local function updateCakeStatus()
        StatusRuntime.cachedCakePrince = getCakePrinceStatus()
        setInfo("cake_prince", "Cake Prince: " .. tostring(StatusRuntime.cachedCakePrince))
    end

    local function updateHeavyStatus()
        -- Kept as a manual refresh entry point, but each request runs independently.
        task.spawn(function()
            pcall(updateEliteStatus)
        end)
        task.spawn(function()
            task.wait(0.35)
            pcall(updateTyrantStatus)
        end)
        task.spawn(function()
            task.wait(0.70)
            pcall(updateCakeStatus)
        end)
    end

    local function httpGet(url)
        local ok, body = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(body) == "string" and body ~= "" then
            return body
        end

        local requestFn = rawget(getgenv and getgenv() or _G, "request")
            or rawget(getgenv and getgenv() or _G, "http_request")
            or (syn and syn.request)

        if typeof(requestFn) == "function" then
            local reqOk, response = pcall(requestFn, {
                Url = url,
                Method = "GET"
            })
            if reqOk and response then
                return response.Body or response.body
            end
        end

        return nil
    end

    local function fetchServers(lowestFirst)
        local servers = {}
        local cursor = nil

        for _ = 1, 3 do
            local url = "https://games.roblox.com/v1/games/"
                .. tostring(game.PlaceId)
                .. "/servers/Public?sortOrder="
                .. (lowestFirst and "Asc" or "Desc")
                .. "&excludeFullGames=true&limit=100"

            if cursor and cursor ~= "" then
                url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
            end

            local body = httpGet(url)
            if not body then
                break
            end

            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(body)
            end)

            if not ok or type(decoded) ~= "table" then
                break
            end

            for _, server in ipairs(decoded.data or {}) do
                if server.id
                    and server.id ~= game.JobId
                    and tonumber(server.playing or 0) < tonumber(server.maxPlayers or math.huge)
                then
                    table.insert(servers, server)
                end
            end

            cursor = decoded.nextPageCursor
            if not cursor then
                break
            end
        end

        table.sort(servers, function(a, b)
            local pa = tonumber(a.playing or 0) or 0
            local pb = tonumber(b.playing or 0) or 0
            if lowestFirst then
                return pa < pb
            end
            return pa > pb
        end)

        return servers
    end

    local function joinJobId(jobId)
        jobId = tostring(jobId or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if jobId == "" then
            statusNotify("Enter a JobId first.")
            return false
        end

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)

        if not ok then
            statusNotify("Join failed: " .. tostring(err))
            return false
        end

        return true
    end

    StatusActions.set_job_id = function(value)
        StatusRuntime.jobId = tostring(value or "")
        return true
    end

    StatusActions.spam_join = function(enabled)
        StatusRuntime.spamJoin = enabled == true

        if StatusRuntime.spamJoin then
            task.spawn(function()
                while StatusRuntime.spamJoin do
                    local jobId = tostring(StatusRuntime.jobId or "")
                    if jobId ~= "" then
                        joinJobId(jobId)
                    end
                    task.wait(1.5)
                end
            end)
        end

        return true
    end

    StatusActions.join_job_id = function()
        return joinJobId(StatusRuntime.jobId)
    end

    StatusActions.copy_job_id = function()
        local copyFn = nil
        if typeof(setclipboard) == "function" then
            copyFn = setclipboard
        elseif typeof(toclipboard) == "function" then
            copyFn = toclipboard
        end

        if not copyFn then
            statusNotify("Clipboard function not supported by this executor.")
            return false
        end

        local ok = pcall(copyFn, tostring(game.JobId))
        if ok then
            statusNotify("Current JobId copied.")
            return true
        end

        statusNotify("Could not copy JobId.")
        return false
    end

    StatusActions.hop_server = function()
        statusNotify("Searching another server...")

        task.spawn(function()
            local servers = fetchServers(false)
            if #servers == 0 then
                statusNotify("Server list unavailable. Trying normal server hop...")
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                return
            end

            local pick = servers[math.random(1, math.min(#servers, 25))]
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
            end)
        end)

        return true
    end

    StatusActions.hop_server_less = function()
        statusNotify("Searching low-player server...")

        task.spawn(function()
            local servers = fetchServers(true)
            if #servers == 0 then
                statusNotify("Low-player list unavailable. Trying normal server hop...")
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                return
            end

            local pick = servers[1]
            statusNotify(
                "Joining server with "
                    .. tostring(pick.playing or "?")
                    .. "/"
                    .. tostring(pick.maxPlayers or "?")
                    .. " players."
            )

            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
            end)
        end)

        return true
    end

    -- Explicit refresh functions used by the UI and startup.
    StatusRuntime.updateFast = updateFastStatus
    StatusRuntime.updateWorld = updateWorldStatus
    StatusRuntime.updateAncient = updateAncientStatus
    StatusRuntime.updateElite = updateEliteStatus
    StatusRuntime.updateTyrant = updateTyrantStatus
    StatusRuntime.updateCake = updateCakeStatus
    StatusRuntime.updateHeavy = updateHeavyStatus

    local function runStatusLoop(initialDelay, interval, fn)
        task.spawn(function()
            if initialDelay and initialDelay > 0 then
                task.wait(initialDelay)
            end

            while StatusRuntime.monitorRunning do
                pcall(fn)
                task.wait(interval)
            end
        end)
    end

    StatusRuntime.startMonitor = function()
        if StatusRuntime.monitorRunning then
            return
        end

        StatusRuntime.monitorRunning = true

        -- Lightweight clock/status labels.
        runStatusLoop(0, 1.0, StatusRuntime.updateFast)

        -- Map/NPC scans no longer run inside the 1-second loop.
        runStatusLoop(1.35, 3.8, StatusRuntime.updateWorld)
        runStatusLoop(3.10, 9.7, StatusRuntime.updateAncient)

        -- Network-heavy requests are intentionally staggered.
        -- They never fire together in a single 4-second burst anymore.
        runStatusLoop(0.80, 5.3, StatusRuntime.updateElite)
        runStatusLoop(2.45, 7.1, StatusRuntime.updateTyrant)
        runStatusLoop(4.15, 6.4, StatusRuntime.updateCake)
    end
end


-- ============================================================
-- QUICK PAGES RUNTIME
-- ESP / PVP / WEBHOOK / SETTING
-- ============================================================
local QuickRuntime = {
    esp = {
        berry = false,
        island = false,
        fruit = false,
        player = false,
        objects = {
            berry = {},
            island = {},
            fruit = {},
            player = {},
        },
        connections = {
            berry = {},
            island = {},
            fruit = {},
            player = {},
        },
    },

    pvp = {
        selectedPlayer = "",
        aimMethod = "Camera",
        autoAimbot = false,
        autoAimbotGun = false,
        walkSpeed = 16,
        jumpPower = 50,
        walkOnWater = true,
        waterPart = nil,
        moveNonce = 0,
        aimConnection = nil,
        waterConnection = nil,
    },

    webhook = {
        url = "",
        ping = "",
        pingEnabled = false,
        notiProfile = false,
        rarity = "Common",
        storeFruit = false,
        prehistoric = false,
        leviathan = false,
        destroyIDK = false,
        mirage = false,
        seenTools = {},
        states = {
            prehistoric = false,
            leviathan = false,
            idk = false,
            mirage = false,
        },
        monitorRunning = false,
    },

    setting = {
        white = false,
        black = false,
        removeNotifications = false,
        autoRejoin = false,
        autoLoad = false,
        guiKey = "LeftControl",
        whiteFrame = nil,
        blackFrame = nil,
        notificationConnections = {},
        disconnectConnection = nil,
        keyConnection = nil,
    },
}

local QuickActions = {}

do
    local function qNotify(title, message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = tostring(title or "Tave Hub"),
                Text = tostring(message or ""),
                Duration = 3
            })
        end)
    end

    local function getCharacter()
        return LocalPlayer.Character
    end

    local function getRootQuick()
        local character = getCharacter()
        return character and (
            character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Torso")
            or character.PrimaryPart
        ) or nil
    end

    local function getHumanoidQuick()
        local character = getCharacter()
        return character and character:FindFirstChildOfClass("Humanoid") or nil
    end

    local function getAdorneePart(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj end
        if obj:IsA("Model") then
            return obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChild("Head")
                or obj.PrimaryPart
                or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        if obj:IsA("Tool") then
            return obj:FindFirstChild("Handle")
                or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        local model = obj:FindFirstAncestorOfClass("Model")
        if model then
            return getAdorneePart(model)
        end
        return nil
    end

    -- --------------------------------------------------------
    -- Shared smooth teleport: exact movement style approved in Shop 1.5.
    -- --------------------------------------------------------
    local function smoothTeleport(targetCFrame)
        if not targetCFrame then return false end

        local root = getRootQuick()
        local hum = getHumanoidQuick()
        if not root or not hum then
            return false
        end

        QuickRuntime.pvp.moveNonce = QuickRuntime.pvp.moveNonce + 1
        local nonce = QuickRuntime.pvp.moveNonce

        hum.Sit = false

        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        local oldCollision = {}
        local noclip = RunService.Stepped:Connect(function()
            local character = getCharacter()
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if oldCollision[part] == nil then
                        oldCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
            local currentRoot = getRootQuick()
            if currentRoot then
                pcall(function()
                    currentRoot.AssemblyLinearVelocity = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end)

        local function restore()
            if noclip then
                noclip:Disconnect()
                noclip = nil
            end
            for part, state in pairs(oldCollision) do
                if part and part.Parent then
                    pcall(function()
                        part.CanCollide = state
                    end)
                end
            end
        end

        local distance = (root.Position - targetCFrame.Position).Magnitude
        if distance <= 4 then
            root.CFrame = targetCFrame
            restore()
            return true
        end

        local duration = math.max(distance / 170, 0.12)
        local tween = TweenService:Create(
            root,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {CFrame = targetCFrame}
        )

        local done = false
        local state = nil
        local conn = tween.Completed:Connect(function(s)
            state = s
            done = true
        end)

        tween:Play()

        while not done do
            if nonce ~= QuickRuntime.pvp.moveNonce then
                pcall(function() tween:Cancel() end)
                conn:Disconnect()
                restore()
                return false
            end

            local currentRoot = getRootQuick()
            if currentRoot ~= root then
                pcall(function() tween:Cancel() end)
                conn:Disconnect()
                restore()
                return false
            end

            task.wait(0.03)
        end

        conn:Disconnect()
        restore()

        root = getRootQuick()
        if not root or state ~= Enum.PlaybackState.Completed then
            return false
        end

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        return (root.Position - targetCFrame.Position).Magnitude <= 20
    end

    QuickRuntime.smoothTeleport = smoothTeleport
    QuickRuntime.stopSmoothTeleport = function()
        QuickRuntime.pvp.moveNonce = QuickRuntime.pvp.moveNonce + 1
        local root = getRootQuick()
        if root then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    -- --------------------------------------------------------
    -- ESP
    -- --------------------------------------------------------
    local function clearConnections(kind)
        for _, connection in ipairs(QuickRuntime.esp.connections[kind] or {}) do
            pcall(function() connection:Disconnect() end)
        end
        QuickRuntime.esp.connections[kind] = {}
    end

    local function clearEsp(kind)
        clearConnections(kind)
        for obj, gui in pairs(QuickRuntime.esp.objects[kind] or {}) do
            if gui then
                pcall(function() gui:Destroy() end)
            end
            QuickRuntime.esp.objects[kind][obj] = nil
        end
    end

    local function createEspLabel(kind, obj, textValue)
        if not ScreenGui or not ScreenGui.Parent or not obj then
            return
        end
        if QuickRuntime.esp.objects[kind][obj] then
            return
        end

        local part = getAdorneePart(obj)
        if not part then
            return
        end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "TaveESP_" .. kind
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(180, 32)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.MaxDistance = 100000
        billboard.Parent = ScreenGui

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 0.25
        label.BackgroundColor3 = Color3.fromRGB(10, 9, 14)
        label.BorderSizePixel = 0
        label.Text = tostring(textValue or obj.Name)
        label.TextColor3 = Color3.fromRGB(205, 177, 255)
        label.TextStrokeTransparency = 0.55
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = label

        QuickRuntime.esp.objects[kind][obj] = billboard

        obj.AncestryChanged:Connect(function(_, parent)
            if not parent and QuickRuntime.esp.objects[kind][obj] then
                pcall(function()
                    QuickRuntime.esp.objects[kind][obj]:Destroy()
                end)
                QuickRuntime.esp.objects[kind][obj] = nil
            end
        end)
    end

    local function isBerry(obj)
        local low = string.lower(obj.Name)
        return string.find(low, "berry", 1, true) ~= nil
    end

    local function isFruit(obj)
        if obj:IsA("Tool") then
            local tooltip = tostring(obj.ToolTip or "")
            if tooltip == "Blox Fruit" then
                return true
            end
        end

        local low = string.lower(obj.Name)
        return string.find(low, "fruit", 1, true) ~= nil
            and (
                obj:IsA("Tool")
                or obj:IsA("Model")
                or obj:IsA("BasePart")
            )
    end

    local function enableBerryEsp()
        clearEsp("berry")
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, obj in ipairs(map:GetDescendants()) do
                if isBerry(obj) then
                    createEspLabel("berry", obj, "🍓 " .. obj.Name)
                end
            end
            table.insert(
                QuickRuntime.esp.connections.berry,
                map.DescendantAdded:Connect(function(obj)
                    if QuickRuntime.esp.berry and isBerry(obj) then
                        task.defer(createEspLabel, "berry", obj, "🍓 " .. obj.Name)
                    end
                end)
            )
        end
    end

    local function enableIslandEsp()
        clearEsp("island")
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, obj in ipairs(map:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart") then
                    createEspLabel("island", obj, "🏝 " .. obj.Name)
                end
            end
            table.insert(
                QuickRuntime.esp.connections.island,
                map.ChildAdded:Connect(function(obj)
                    if QuickRuntime.esp.island then
                        task.wait(0.2)
                        createEspLabel("island", obj, "🏝 " .. obj.Name)
                    end
                end)
            )
        end
    end

    local function enableFruitEsp()
        clearEsp("fruit")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isFruit(obj) then
                createEspLabel("fruit", obj, "🍈 " .. obj.Name)
            end
        end
        table.insert(
            QuickRuntime.esp.connections.fruit,
            workspace.DescendantAdded:Connect(function(obj)
                if QuickRuntime.esp.fruit and isFruit(obj) then
                    task.wait(0.1)
                    createEspLabel("fruit", obj, "🍈 " .. obj.Name)
                end
            end)
        )
    end

    local function addPlayerEsp(player)
        if player == LocalPlayer or not QuickRuntime.esp.player then
            return
        end

        local function apply(character)
            if not character or not QuickRuntime.esp.player then return end

            createEspLabel("player", character, "👤 " .. player.Name)

            if not character:FindFirstChild("TavePlayerHighlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "TavePlayerHighlight"
                highlight.FillTransparency = 0.78
                highlight.OutlineTransparency = 0.10
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = character
            end
        end

        if player.Character then
            apply(player.Character)
        end

        local conn = player.CharacterAdded:Connect(function(character)
            task.wait(0.2)
            apply(character)
        end)
        table.insert(QuickRuntime.esp.connections.player, conn)
    end

    local function enablePlayerEsp()
        clearEsp("player")

        for _, player in ipairs(Players:GetPlayers()) do
            addPlayerEsp(player)
        end

        table.insert(
            QuickRuntime.esp.connections.player,
            Players.PlayerAdded:Connect(function(player)
                if QuickRuntime.esp.player then
                    addPlayerEsp(player)
                end
            end)
        )

        table.insert(
            QuickRuntime.esp.connections.player,
            Players.PlayerRemoving:Connect(function(player)
                local char = player.Character
                if char and QuickRuntime.esp.objects.player[char] then
                    QuickRuntime.esp.objects.player[char]:Destroy()
                    QuickRuntime.esp.objects.player[char] = nil
                end
            end)
        )
    end

    QuickActions.esp_berry = function(enabled)
        QuickRuntime.esp.berry = enabled == true
        if enabled then enableBerryEsp() else clearEsp("berry") end
        return true
    end

    QuickActions.esp_island = function(enabled)
        QuickRuntime.esp.island = enabled == true
        if enabled then enableIslandEsp() else clearEsp("island") end
        return true
    end

    QuickActions.esp_fruit = function(enabled)
        QuickRuntime.esp.fruit = enabled == true
        if enabled then enableFruitEsp() else clearEsp("fruit") end
        return true
    end

    QuickActions.esp_player = function(enabled)
        QuickRuntime.esp.player = enabled == true
        if enabled then
            enablePlayerEsp()
        else
            clearEsp("player")
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                local h = character and character:FindFirstChild("TavePlayerHighlight")
                if h then h:Destroy() end
            end
        end
        return true
    end

    -- --------------------------------------------------------
    -- PVP
    -- --------------------------------------------------------
    local function selectedPlayer()
        local name = tostring(QuickRuntime.pvp.selectedPlayer or "")
        if name == "" or name == "Select Player" then
            return nil
        end
        return Players:FindFirstChild(name)
    end

    local function selectedTargetPart()
        local player = selectedPlayer()
        local character = player and player.Character
        return character and (
            character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Head")
        ) or nil
    end

    local function refreshPlayerDropdown()
        local names = {"Select Player"}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(names, player.Name)
            end
        end
        table.sort(names, function(a, b)
            if a == "Select Player" then return true end
            if b == "Select Player" then return false end
            return string.lower(a) < string.lower(b)
        end)

        local control = UIControls["Select Player PVP"]
        if control and control.SetOptions then
            control.SetOptions(names)
        end
    end

    QuickRuntime.refreshPlayerDropdown = refreshPlayerDropdown

    QuickActions.pvp_select_player = function(value)
        QuickRuntime.pvp.selectedPlayer = tostring(value or "")
        return true
    end

    QuickActions.pvp_aim_method = function(value)
        QuickRuntime.pvp.aimMethod = tostring(value or "Camera")
        return true
    end

    QuickActions.pvp_refresh_player = function()
        refreshPlayerDropdown()
        qNotify("PVP", "Player list refreshed.")
        return true
    end

    QuickActions.pvp_teleport_player = function()
        local target = selectedTargetPart()
        if not target then
            qNotify("PVP", "Select a valid player first.")
            return false
        end
        task.spawn(function()
            smoothTeleport(target.CFrame * CFrame.new(0, 0, 5))
        end)
        return true
    end

    local function applyAim()
        local target = selectedTargetPart()
        local camera = workspace.CurrentCamera
        if not target or not camera then
            return
        end

        local method = tostring(QuickRuntime.pvp.aimMethod or "Camera")

        if method == "Mouse" and typeof(mousemoverel) == "function" then
            local point, visible = camera:WorldToViewportPoint(target.Position)
            if visible then
                local mousePos = UserInputService:GetMouseLocation()
                local dx = (point.X - mousePos.X) * 0.20
                local dy = (point.Y - mousePos.Y) * 0.20
                pcall(mousemoverel, dx, dy)
            end
        else
            local pos = camera.CFrame.Position
            camera.CFrame = CFrame.lookAt(pos, target.Position)
        end
    end

    local function applyGunAim()
        local target = selectedTargetPart()
        if not target then return end

        local character = getCharacter()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        for _, container in ipairs({character, backpack}) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tostring(tool.ToolTip or "") == "Gun" then
                        for _, obj in ipairs(tool:GetDescendants()) do
                            if obj.Name == "MousePos" and obj:IsA("Vector3Value") then
                                obj.Value = target.Position
                            end
                        end
                    end
                end
            end
        end

        applyAim()
    end

    local function ensureAimLoop()
        if QuickRuntime.pvp.aimConnection then
            return
        end

        QuickRuntime.pvp.aimConnection = RunService.RenderStepped:Connect(function()
            if QuickRuntime.pvp.autoAimbot then
                pcall(applyAim)
            end
            if QuickRuntime.pvp.autoAimbotGun then
                pcall(applyGunAim)
            end
        end)
    end

    QuickActions.pvp_auto_aimbot = function(enabled)
        QuickRuntime.pvp.autoAimbot = enabled == true
        ensureAimLoop()
        return true
    end

    QuickActions.pvp_auto_aimbot_gun = function(enabled)
        QuickRuntime.pvp.autoAimbotGun = enabled == true
        ensureAimLoop()
        return true
    end

    QuickActions.pvp_walkspeed_value = function(value)
        QuickRuntime.pvp.walkSpeed = tonumber(value) or 16
        return true
    end

    QuickActions.pvp_jumppower_value = function(value)
        QuickRuntime.pvp.jumpPower = tonumber(value) or 50
        return true
    end

    QuickActions.pvp_apply_walkspeed = function()
        local hum = getHumanoidQuick()
        if not hum then return false end
        hum.WalkSpeed = QuickRuntime.pvp.walkSpeed
        qNotify("PVP", "WalkSpeed: " .. tostring(QuickRuntime.pvp.walkSpeed))
        return true
    end

    QuickActions.pvp_apply_jumppower = function()
        local hum = getHumanoidQuick()
        if not hum then return false end
        pcall(function() hum.UseJumpPower = true end)
        hum.JumpPower = QuickRuntime.pvp.jumpPower
        qNotify("PVP", "JumpPower: " .. tostring(QuickRuntime.pvp.jumpPower))
        return true
    end

    local function ensureWaterPart()
        if QuickRuntime.pvp.waterPart and QuickRuntime.pvp.waterPart.Parent then
            return QuickRuntime.pvp.waterPart
        end

        local part = Instance.new("Part")
        part.Name = "TaveWalkOnWater"
        part.Size = Vector3.new(12, 0.5, 12)
        part.Anchored = true
        part.CanCollide = true
        part.CanTouch = false
        part.CanQuery = false
        part.Transparency = 1
        part.Position = Vector3.new(0, -10000, 0)
        part.Parent = workspace
        QuickRuntime.pvp.waterPart = part
        return part
    end

    QuickActions.pvp_walk_on_water = function(enabled)
        QuickRuntime.pvp.walkOnWater = enabled == true

        if not enabled then
            if QuickRuntime.pvp.waterConnection then
                QuickRuntime.pvp.waterConnection:Disconnect()
                QuickRuntime.pvp.waterConnection = nil
            end
            if QuickRuntime.pvp.waterPart then
                QuickRuntime.pvp.waterPart.Position = Vector3.new(0, -10000, 0)
            end
            return true
        end

        local part = ensureWaterPart()
        if QuickRuntime.pvp.waterConnection then
            QuickRuntime.pvp.waterConnection:Disconnect()
        end

        QuickRuntime.pvp.waterConnection = RunService.Heartbeat:Connect(function()
            if not QuickRuntime.pvp.walkOnWater then return end

            local root = getRootQuick()
            if not root then
                part.Position = Vector3.new(0, -10000, 0)
                return
            end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {getCharacter(), part}
            params.IgnoreWater = false

            local result = workspace:Raycast(
                root.Position + Vector3.new(0, 2, 0),
                Vector3.new(0, -14, 0),
                params
            )

            if result and result.Material == Enum.Material.Water then
                part.CFrame = CFrame.new(root.Position.X, result.Position.Y + 0.05, root.Position.Z)
            else
                part.Position = Vector3.new(0, -10000, 0)
            end
        end)

        return true
    end

    -- --------------------------------------------------------
    -- WEBHOOK
    -- --------------------------------------------------------
    local rarityRank = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Legendary = 4,
        Mythical = 5,
    }

    local fruitRarity = {
        ["Rocket"] = "Common",
        ["Spin"] = "Common",
        ["Blade"] = "Common",
        ["Spring"] = "Common",
        ["Bomb"] = "Common",
        ["Smoke"] = "Common",
        ["Spike"] = "Common",

        ["Flame"] = "Uncommon",
        ["Falcon"] = "Uncommon",
        ["Eagle"] = "Uncommon",
        ["Ice"] = "Uncommon",
        ["Sand"] = "Uncommon",
        ["Dark"] = "Uncommon",
        ["Diamond"] = "Uncommon",

        ["Light"] = "Rare",
        ["Rubber"] = "Rare",
        ["Barrier"] = "Rare",
        ["Ghost"] = "Rare",
        ["Magma"] = "Rare",

        ["Quake"] = "Legendary",
        ["Buddha"] = "Legendary",
        ["Love"] = "Legendary",
        ["Spider"] = "Legendary",
        ["Sound"] = "Legendary",
        ["Phoenix"] = "Legendary",
        ["Portal"] = "Legendary",
        ["Rumble"] = "Legendary",
        ["Pain"] = "Legendary",
        ["Blizzard"] = "Legendary",

        ["Gravity"] = "Mythical",
        ["Mammoth"] = "Mythical",
        ["T-Rex"] = "Mythical",
        ["Dough"] = "Mythical",
        ["Shadow"] = "Mythical",
        ["Venom"] = "Mythical",
        ["Control"] = "Mythical",
        ["Spirit"] = "Mythical",
        ["Dragon"] = "Mythical",
        ["Leopard"] = "Mythical",
        ["Kitsune"] = "Mythical",
        ["Gas"] = "Mythical",
        ["Yeti"] = "Mythical",
    }

    local function webhookRequest(payload)
        local url = tostring(QuickRuntime.webhook.url or "")
        if url == "" then
            qNotify("Webhook", "Set Webhook URL first.")
            return false
        end

        local requestFn =
            (typeof(request) == "function" and request)
            or (typeof(http_request) == "function" and http_request)
            or (syn and typeof(syn.request) == "function" and syn.request)
            or (fluxus and typeof(fluxus.request) == "function" and fluxus.request)

        if not requestFn then
            qNotify("Webhook", "Executor request function not supported.")
            return false
        end

        local body = HttpService:JSONEncode(payload)

        local ok, result = pcall(requestFn, {
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })

        if not ok then
            qNotify("Webhook", "Request failed.")
            return false
        end

        local status = tonumber(result and (result.StatusCode or result.Status or result.status_code))
        if status and status >= 400 then
            qNotify("Webhook", "Discord returned HTTP " .. tostring(status))
            return false
        end

        return true
    end

    local function pingText()
        if not QuickRuntime.webhook.pingEnabled then
            return ""
        end

        local ping = tostring(QuickRuntime.webhook.ping or "")
        ping = ping:gsub("^%s+", ""):gsub("%s+$", "")

        if ping == "" or string.lower(ping) == "everyone" then
            return "@everyone"
        end

        if string.sub(ping, 1, 2) == "<@" then
            return ping
        end

        if tonumber(ping) then
            return "<@" .. ping .. ">"
        end

        return ping
    end

    local function sendWebhook(title, description)
        local content = pingText()

        local payload = {
            username = "Tave Hub",
            content = content,
            embeds = {{
                title = tostring(title or "Tave Hub"),
                description = tostring(description or ""),
                color = 9911551,
                footer = {
                    text = "Tave Hub"
                }
            }}
        }

        return webhookRequest(payload)
    end

    QuickActions.webhook_url = function(value)
        QuickRuntime.webhook.url = tostring(value or "")
        return true
    end

    QuickActions.webhook_ping = function(value)
        QuickRuntime.webhook.ping = tostring(value or "")
        return true
    end

    QuickActions.webhook_ping_enabled = function(enabled)
        QuickRuntime.webhook.pingEnabled = enabled == true
        return true
    end

    QuickActions.webhook_profile = function(enabled)
        QuickRuntime.webhook.notiProfile = enabled == true

        if enabled then
            task.spawn(function()
                local data = {
                    "User: **" .. LocalPlayer.Name .. "**",
                    "Display: **" .. tostring(LocalPlayer.DisplayName) .. "**",
                    "UserId: `" .. tostring(LocalPlayer.UserId) .. "`",
                    "PlaceId: `" .. tostring(game.PlaceId) .. "`",
                    "JobId: `" .. tostring(game.JobId) .. "`",
                }
                sendWebhook("Profile", table.concat(data, "\n"))
            end)
        end

        return true
    end

    QuickActions.webhook_rarity = function(value)
        QuickRuntime.webhook.rarity = tostring(value or "Common")
        return true
    end

    QuickActions.webhook_store_fruit = function(enabled)
        QuickRuntime.webhook.storeFruit = enabled == true
        return true
    end

    QuickActions.webhook_prehistoric = function(enabled)
        QuickRuntime.webhook.prehistoric = enabled == true
        return true
    end

    QuickActions.webhook_leviathan = function(enabled)
        QuickRuntime.webhook.leviathan = enabled == true
        return true
    end

    QuickActions.webhook_destroy_idk = function(enabled)
        QuickRuntime.webhook.destroyIDK = enabled == true
        return true
    end

    QuickActions.webhook_mirage = function(enabled)
        QuickRuntime.webhook.mirage = enabled == true
        return true
    end

    local function fruitNameFromTool(tool)
        local name = tostring(tool.Name or "")
        name = name:gsub(" Fruit$", "")
        name = name:gsub("%-%w+ Fruit$", "")
        return name
    end

    local function shouldNotifyFruit(tool)
        if not tool:IsA("Tool") then return false end
        if tostring(tool.ToolTip or "") ~= "Blox Fruit"
            and not string.find(string.lower(tool.Name), "fruit", 1, true)
        then
            return false
        end

        local fruit = fruitNameFromTool(tool)
        local rarity = fruitRarity[fruit] or "Common"
        local selected = QuickRuntime.webhook.rarity or "Common"

        return (rarityRank[rarity] or 1) >= (rarityRank[selected] or 1), fruit, rarity
    end

    local function mapHas(names)
        local map = workspace:FindFirstChild("Map")
        if not map then return false end

        for _, obj in ipairs(map:GetDescendants()) do
            local low = string.lower(obj.Name)
            for _, wanted in ipairs(names) do
                if string.find(low, string.lower(wanted), 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function leviathanExists()
        local enemies = workspace:FindFirstChild("Enemies")
        for _, container in ipairs({enemies, ReplicatedStorage}) do
            if container then
                for _, child in ipairs(container:GetChildren()) do
                    if string.find(string.lower(child.Name), "leviathan", 1, true) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function idkExists()
        return workspace:FindFirstChild("IDK", true) ~= nil
            or ReplicatedStorage:FindFirstChild("IDK", true) ~= nil
    end

    local function startWebhookMonitor()
        if QuickRuntime.webhook.monitorRunning then return end
        QuickRuntime.webhook.monitorRunning = true

        task.spawn(function()
            while QuickRuntime.webhook.monitorRunning and ScreenGui and ScreenGui.Parent do
                if QuickRuntime.webhook.storeFruit then
                    for _, container in ipairs({
                        LocalPlayer:FindFirstChildOfClass("Backpack"),
                        getCharacter()
                    }) do
                        if container then
                            for _, tool in ipairs(container:GetChildren()) do
                                if not QuickRuntime.webhook.seenTools[tool] then
                                    local okFruit, fruit, rarity = shouldNotifyFruit(tool)
                                    if okFruit then
                                        QuickRuntime.webhook.seenTools[tool] = true
                                        sendWebhook(
                                            "Fruit Stored / Found",
                                            "**" .. tostring(fruit) .. "**\nRarity: **" .. tostring(rarity) .. "**"
                                        )
                                    end
                                end
                            end
                        end
                    end
                end

                local prehistoricNow = mapHas({"PrehistoricIsland", "Prehistoric Island"})
                if QuickRuntime.webhook.prehistoric
                    and prehistoricNow
                    and not QuickRuntime.webhook.states.prehistoric
                then
                    sendWebhook("Prehistoric Island", "Prehistoric Island spawned ✅")
                end
                QuickRuntime.webhook.states.prehistoric = prehistoricNow

                local leviathanNow = leviathanExists()
                if QuickRuntime.webhook.leviathan
                    and leviathanNow
                    and not QuickRuntime.webhook.states.leviathan
                then
                    sendWebhook("Leviathan", "Leviathan found ✅")
                end
                QuickRuntime.webhook.states.leviathan = leviathanNow

                local mirageNow = mapHas({"MysticIsland", "MirageIsland", "Mirage Island"})
                if QuickRuntime.webhook.mirage
                    and mirageNow
                    and not QuickRuntime.webhook.states.mirage
                then
                    sendWebhook("Mirage Island", "Mirage Island spawned ✅")
                end
                QuickRuntime.webhook.states.mirage = mirageNow

                local idkNow = idkExists()
                if QuickRuntime.webhook.destroyIDK
                    and not idkNow
                    and QuickRuntime.webhook.states.idk
                then
                    sendWebhook("Destroy IDK", "IDK object was destroyed / removed.")
                end
                QuickRuntime.webhook.states.idk = idkNow

                task.wait(2)
            end
        end)
    end

    QuickRuntime.startWebhookMonitor = startWebhookMonitor

    -- --------------------------------------------------------
    -- SETTING
    -- --------------------------------------------------------
    local function ensureOverlay(which)
        local key = which == "white" and "whiteFrame" or "blackFrame"
        local existing = QuickRuntime.setting[key]
        if existing and existing.Parent then
            return existing
        end

        local frame = Instance.new("Frame")
        frame.Name = "Tave_" .. which .. "_screen"
        frame.Size = UDim2.fromScale(1, 1)
        frame.Position = UDim2.fromScale(0, 0)
        frame.BackgroundColor3 = which == "white"
            and Color3.new(1, 1, 1)
            or Color3.new(0, 0, 0)
        frame.BorderSizePixel = 0
        frame.ZIndex = 0
        frame.Visible = false
        frame.Parent = ScreenGui
        QuickRuntime.setting[key] = frame
        return frame
    end

    QuickActions.setting_white = function(enabled)
        QuickRuntime.setting.white = enabled == true
        ensureOverlay("white").Visible = QuickRuntime.setting.white
        return true
    end

    QuickActions.setting_black = function(enabled)
        QuickRuntime.setting.black = enabled == true
        ensureOverlay("black").Visible = QuickRuntime.setting.black
        return true
    end

    local function hideNotificationObject(obj)
        if not QuickRuntime.setting.removeNotifications then return end
        if ScreenGui and obj:IsDescendantOf(ScreenGui) then return end

        local low = string.lower(obj.Name)
        if string.find(low, "notification", 1, true)
            or string.find(low, "notify", 1, true)
        then
            if obj:IsA("GuiObject") then
                pcall(function() obj.Visible = false end)
            end
        end
    end

    QuickActions.setting_remove_notifications = function(enabled)
        QuickRuntime.setting.removeNotifications = enabled == true

        for _, connection in ipairs(QuickRuntime.setting.notificationConnections) do
            pcall(function() connection:Disconnect() end)
        end
        QuickRuntime.setting.notificationConnections = {}

        if not enabled then
            return true
        end

        for _, rootGui in ipairs({
            CoreGui,
            LocalPlayer:FindFirstChildOfClass("PlayerGui")
        }) do
            if rootGui then
                for _, obj in ipairs(rootGui:GetDescendants()) do
                    hideNotificationObject(obj)
                end
                table.insert(
                    QuickRuntime.setting.notificationConnections,
                    rootGui.DescendantAdded:Connect(function(obj)
                        task.defer(hideNotificationObject, obj)
                    end)
                )
            end
        end

        return true
    end

    QuickActions.setting_auto_rejoin = function(enabled)
        QuickRuntime.setting.autoRejoin = enabled == true

        if QuickRuntime.setting.disconnectConnection then
            QuickRuntime.setting.disconnectConnection:Disconnect()
            QuickRuntime.setting.disconnectConnection = nil
        end

        if not enabled then
            return true
        end

        QuickRuntime.setting.disconnectConnection = GuiService.ErrorMessageChanged:Connect(function()
            if not QuickRuntime.setting.autoRejoin then return end
            local message = ""
            pcall(function()
                message = GuiService:GetErrorMessage()
            end)
            if message and message ~= "" then
                task.wait(2)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        end)

        return true
    end

    local function queueFunction()
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

    QuickActions.setting_auto_load = function(enabled)
        QuickRuntime.setting.autoLoad = enabled == true
        if not enabled then return true end

        local queue = queueFunction()
        if not queue then
            qNotify("Setting", "queue_on_teleport is not supported.")
            return false
        end

        local loader = [[
task.wait(3)
loadstring(game:HttpGet("https://raw.githubusercontent.com/virtualia890-tech/NovaHub/refs/heads/main/Main.lua?v=" .. tostring(os.time())))()
]]
        local ok = pcall(queue, loader)
        if ok then
            qNotify("Setting", "Auto Load queued for next teleport.")
            return true
        end
        return false
    end

    QuickActions.setting_boost_fps = function()
        task.spawn(function()
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 1e9
                Lighting.Brightness = 1
            end)

            for _, obj in ipairs(game:GetDescendants()) do
                pcall(function()
                    if obj:IsA("BasePart") then
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    elseif obj:IsA("ParticleEmitter")
                        or obj:IsA("Trail")
                        or obj:IsA("Smoke")
                        or obj:IsA("Fire")
                        or obj:IsA("Sparkles")
                    then
                        obj.Enabled = false
                    elseif obj:IsA("PostEffect") then
                        obj.Enabled = false
                    end
                end)
            end

            qNotify("Setting", "Boost FPS applied.")
        end)
        return true
    end

    QuickActions.setting_copy_config = function()
        local config = {
            PVP = {
                Player = QuickRuntime.pvp.selectedPlayer,
                AimMethod = QuickRuntime.pvp.aimMethod,
                WalkSpeed = QuickRuntime.pvp.walkSpeed,
                JumpPower = QuickRuntime.pvp.jumpPower,
            },
            Webhook = {
                URL = QuickRuntime.webhook.url,
                Ping = QuickRuntime.webhook.ping,
                PingEnabled = QuickRuntime.webhook.pingEnabled,
                Rarity = QuickRuntime.webhook.rarity,
            },
            Setting = {
                AutoRejoin = QuickRuntime.setting.autoRejoin,
                AutoLoad = QuickRuntime.setting.autoLoad,
                ToggleGUI = QuickRuntime.setting.guiKey,
            }
        }

        local encoded = HttpService:JSONEncode(config)
        local copyFn =
            (typeof(setclipboard) == "function" and setclipboard)
            or (typeof(toclipboard) == "function" and toclipboard)

        if not copyFn then
            qNotify("Setting", "Clipboard not supported.")
            return false
        end

        local ok = pcall(copyFn, encoded)
        if ok then
            qNotify("Setting", "Config copied.")
            return true
        end
        return false
    end

    QuickActions.setting_gui_key = function(value)
        QuickRuntime.setting.guiKey = tostring(value or "LeftControl")
        return true
    end

    local function keyCodeFromName(name)
        local map = {
            LeftControl = Enum.KeyCode.LeftControl,
            RightControl = Enum.KeyCode.RightControl,
            Insert = Enum.KeyCode.Insert,
            Home = Enum.KeyCode.Home,
        }
        return map[name] or Enum.KeyCode.LeftControl
    end

    QuickRuntime.startGuiKey = function()
        if QuickRuntime.setting.keyConnection then return end

        QuickRuntime.setting.keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if UserInputService:GetFocusedTextBox() then return end

            if input.KeyCode == keyCodeFromName(QuickRuntime.setting.guiKey) then
                if Main then
                    Main.Visible = not Main.Visible
                    if Floating then
                        Floating.Visible = not Main.Visible
                    end
                end
            end
        end)
    end
end



-- ============================================================
-- LOCALPLAYER RUNTIME
-- Reuses the same continuous smooth teleport approved in Shop/PVP.
-- ============================================================
local LocalRuntime = {
    autoTranslate = false,
    translator = nil,
    translateConnection = nil,
    originalText = {},

    selectedStat = "Demon Fruit",
    autoStats = false,
    selectedTeam = "Pirate",

    noclip = false,
    noclipConnection = nil,
    collisionState = {},

    selectedNpc = "Experienced Captain",
    selectedIsland = "Hydra Island",
}

local LocalActions = {}

do
    local function lpNotify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tave Hub - LocalPlayer",
                Text = tostring(message or ""),
                Duration = 3
            })
        end)
    end

    local function commFLocal(...)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        if not remote then
            return false, "CommF_ not found"
        end

        local args = table.pack(...)
        local ok, result = pcall(function()
            return remote:InvokeServer(table.unpack(args, 1, args.n))
        end)

        return ok, result
    end

    local function currentSeaLocal()
        if game.PlaceId == 2753915549 then return 1 end
        if game.PlaceId == 4442272183 then return 2 end
        if game.PlaceId == 7449423635 then return 3 end
        return 0
    end

    local function getLocalRoot()
        local character = LocalPlayer.Character
        return character and (
            character:FindFirstChild("HumanoidRootPart")
            or character:FindFirstChild("Torso")
            or character.PrimaryPart
        ) or nil
    end

    local function smoothGo(targetCFrame)
        if not targetCFrame then
            return false
        end

        if QuickRuntime and QuickRuntime.smoothTeleport then
            return QuickRuntime.smoothTeleport(targetCFrame)
        end

        return false
    end

    local function cancelMove()
        if QuickRuntime and QuickRuntime.stopSmoothTeleport then
            QuickRuntime.stopSmoothTeleport()
        end
    end

    -- --------------------------------------------------------
    -- Utility
    -- --------------------------------------------------------
    local function translateObject(obj)
        if not LocalRuntime.autoTranslate or not LocalRuntime.translator then
            return
        end
        if ScreenGui and obj:IsDescendantOf(ScreenGui) then
            return
        end
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            return
        end

        if LocalRuntime.originalText[obj] == nil then
            LocalRuntime.originalText[obj] = obj.Text
        end

        pcall(function()
            local translated = LocalRuntime.translator:Translate(obj, obj.Text)
            if translated and translated ~= "" then
                obj.Text = translated
            end
        end)
    end

    LocalActions.lp_auto_translate = function(enabled)
        LocalRuntime.autoTranslate = enabled == true

        if LocalRuntime.translateConnection then
            LocalRuntime.translateConnection:Disconnect()
            LocalRuntime.translateConnection = nil
        end

        if not enabled then
            for obj, original in pairs(LocalRuntime.originalText) do
                if obj and obj.Parent then
                    pcall(function()
                        obj.Text = original
                    end)
                end
            end
            LocalRuntime.originalText = {}
            return true
        end

        local ok, translator = pcall(function()
            return LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer)
        end)

        if not ok or not translator then
            lpNotify("Translator is not available in this server.")
            return false
        end

        LocalRuntime.translator = translator

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, obj in ipairs(playerGui:GetDescendants()) do
                translateObject(obj)
            end

            LocalRuntime.translateConnection = playerGui.DescendantAdded:Connect(function(obj)
                if LocalRuntime.autoTranslate then
                    task.defer(translateObject, obj)
                end
            end)
        end

        return true
    end

    LocalActions.lp_stop_tween = function()
        cancelMove()
        lpNotify("Smooth teleport stopped.")
        return true
    end

    LocalActions.lp_show_item = function()
        commFLocal("getInventoryWeapons")
        task.wait(0.15)

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local inventory = main and main:FindFirstChild("Inventory")

        if inventory and inventory:IsA("GuiObject") then
            inventory.Visible = true
            return true
        end

        lpNotify("Inventory UI not found.")
        return false
    end

    local function openFruitShop()
        commFLocal("GetFruits")
        task.wait(0.12)

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local shop = main and main:FindFirstChild("FruitShop")

        if shop and shop:IsA("GuiObject") then
            shop.Visible = true
            return true
        end

        lpNotify("Fruit Shop UI not found.")
        return false
    end

    LocalActions.lp_open_fruit_shop = function()
        return openFruitShop()
    end

    local function findNpcByAliases(aliases)
        local roots = {}
        local npcFolder = workspace:FindFirstChild("NPCs")
        if npcFolder then
            table.insert(roots, npcFolder)
        end

        local function scan(list)
            for _, obj in ipairs(list) do
                local low = string.lower(obj.Name)
                for _, alias in ipairs(aliases) do
                    local want = string.lower(alias)
                    if low == want or string.find(low, want, 1, true) then
                        if obj:IsA("Model") then
                            local part = obj:FindFirstChild("HumanoidRootPart")
                                or obj:FindFirstChild("Head")
                                or obj.PrimaryPart
                                or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                return part
                            end
                        elseif obj:IsA("BasePart") then
                            return obj
                        end
                    end
                end
            end
            return nil
        end

        for _, root in ipairs(roots) do
            local result = scan(root:GetDescendants())
            if result then
                return result
            end
        end

        if typeof(getnilinstances) == "function" then
            local ok, list = pcall(getnilinstances)
            if ok and type(list) == "table" then
                local result = scan(list)
                if result then
                    return result
                end
            end
        end

        return nil
    end

    LocalActions.lp_open_fruit_shop_mirage = function()
        local dealer = findNpcByAliases({"Advanced Fruit Dealer"})

        if not dealer then
            lpNotify("Advanced Fruit Dealer is not loaded. Mirage may not be spawned.")
            return false
        end

        task.spawn(function()
            smoothGo(dealer.CFrame * CFrame.new(0, 0, 5))
            task.wait(0.35)
            openFruitShop()
        end)

        return true
    end

    LocalActions.lp_open_title = function()
        commFLocal("getTitles")
        task.wait(0.10)

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local titles = main and main:FindFirstChild("Titles")

        if titles and titles:IsA("GuiObject") then
            titles.Visible = true
            return true
        end

        lpNotify("Title UI not found.")
        return false
    end

    LocalActions.lp_open_color = function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local colors = main and main:FindFirstChild("Colors")

        if colors and colors:IsA("GuiObject") then
            colors.Visible = true
            return true
        end

        lpNotify("Color UI not found.")
        return false
    end

    -- --------------------------------------------------------
    -- Stats / Team
    -- --------------------------------------------------------
    LocalActions.lp_select_stat = function(value)
        LocalRuntime.selectedStat = tostring(value or "Demon Fruit")
        return true
    end

    LocalActions.lp_auto_stats = function(enabled)
        LocalRuntime.autoStats = enabled == true

        if not enabled then
            return true
        end

        task.spawn(function()
            while LocalRuntime.autoStats do
                local data = LocalPlayer:FindFirstChild("Data")
                local points = data and data:FindFirstChild("Points")
                local available = points and tonumber(points.Value) or 0

                if available > 0 then
                    local amount = math.clamp(math.floor(available), 1, 50)
                    commFLocal("AddPoint", LocalRuntime.selectedStat, amount)
                    task.wait(0.20)
                else
                    task.wait(0.65)
                end
            end
        end)

        return true
    end

    LocalActions.lp_select_team = function(value)
        LocalRuntime.selectedTeam = tostring(value or "Pirate")
        return true
    end

    LocalActions.lp_change_team = function()
        local team = LocalRuntime.selectedTeam == "Marine" and "Marines" or "Pirates"
        local ok, result = commFLocal("SetTeam", team)

        if ok then
            lpNotify("Team request: " .. team)
            return true
        end

        lpNotify("Team change failed: " .. tostring(result))
        return false
    end

    -- --------------------------------------------------------
    -- Noclip
    -- --------------------------------------------------------
    local function stopNoclip()
        if LocalRuntime.noclipConnection then
            LocalRuntime.noclipConnection:Disconnect()
            LocalRuntime.noclipConnection = nil
        end

        for part, oldState in pairs(LocalRuntime.collisionState) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = oldState
                end)
            end
        end

        LocalRuntime.collisionState = {}
    end

    LocalActions.lp_noclip = function(enabled)
        LocalRuntime.noclip = enabled == true
        stopNoclip()

        if not enabled then
            return true
        end

        LocalRuntime.noclipConnection = RunService.Stepped:Connect(function()
            if not LocalRuntime.noclip then
                return
            end

            local character = LocalPlayer.Character
            if not character then
                return
            end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if LocalRuntime.collisionState[part] == nil then
                        LocalRuntime.collisionState[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)

        return true
    end

    -- --------------------------------------------------------
    -- NPC teleport
    -- --------------------------------------------------------
    local NpcData = {
        ["Experienced Captain"] = {
            aliases = {"Experienced Captain"},
            stages = {
                [1] = CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094),
                [2] = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
        },
        ["Blacksmith"] = {
            aliases = {"Blacksmith"},
            stages = {
                [1] = CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094),
                [2] = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
        },
        ["Fisherman"] = {
            aliases = {"Fisherman"},
            stages = {
                [3] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
            },
        },
        ["Pirate Port Quest Giver"] = {
            aliases = {"Pirate Port Quest Giver", "Pirate Port Quest"},
            stages = {
                [3] = CFrame.new(-290.7376708984375, 6.729952812194824, 5343.5537109375),
            },
        },
        ["Blox Fruit Dealer"] = {
            aliases = {"Blox Fruit Dealer", "Blox Fruits Dealer"},
            stages = {
                [1] = CFrame.new(-690.33081054688, 15.09425163269, 1582.2380371094),
                [2] = CFrame.new(-380.47927856445, 77.220390319824, 255.82550048828),
                [3] = CFrame.new(-5074.45556640625, 314.5155334472656, -2991.054443359375),
            },
        },
        ["Fossil Expert"] = {
            aliases = {"Fossil Expert"},
            stages = {
                [3] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
            },
        },
        ["Lucien"] = {
            aliases = {"Lucien"},
            stages = {
                [3] = CFrame.new(-290.7376708984375, 6.729952812194824, 5343.5537109375),
            },
        },
        ["Submarine Worker"] = {
            aliases = {"Submarine Worker"},
            stages = {
                [3] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
            },
        },
        ["Sharkman Master"] = {
            aliases = {"Sharkman Master", "Sharkman Teacher", "Daigrock"},
            stages = {
                [3] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
            },
        },
        ["Doghouse"] = {
            aliases = {"Doghouse", "Dog House"},
            stages = {
                [3] = CFrame.new(-12462, 375, -7552),
            },
        },
        ["Mysterious Force"] = {
            aliases = {"Mysterious Force"},
            stages = {
                [3] = CFrame.new(28286.35546875, 14895.3017578125, 102.62469482421875),
            },
        },
        ["Ancient One"] = {
            aliases = {"Ancient One"},
            stages = {
                [3] = CFrame.new(28981.552734375, 14888.4267578125, -120.245849609375),
            },
        },
        ["Sealed King"] = {
            aliases = {"Sealed King"},
            stages = {
                [3] = CFrame.new(3030.39453125, 2280.6171875, -7320.18359375),
            },
        },
        ["Gravestone"] = {
            aliases = {"Gravestone"},
            stages = {
                [3] = CFrame.new(-8652.99707, 143.450119, 6170.50879),
            },
        },
        ["Skeleton Machine"] = {
            aliases = {"Skeleton Machine"},
            stages = {
                [3] = CFrame.new(-9515.3720703125, 164.00624084473, 5786.0610351562),
            },
        },
        ["Frozen Watcher"] = {
            aliases = {"Frozen Watcher"},
        },
        ["Dojo Trainer"] = {
            aliases = {"Dojo Trainer"},
            stages = {
                [3] = CFrame.new(5841.298828125, 1208.32177734375, 884.3173217773438),
            },
            entrance = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906),
        },
        ["Dragon Tamer"] = {
            aliases = {"Dragon Tamer"},
            stages = {
                [3] = CFrame.new(5841.298828125, 1208.32177734375, 884.3173217773438),
            },
            entrance = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906),
        },
        ["Sweet Crafter"] = {
            aliases = {"Sweet Crafter"},
            stages = {
                [3] = CFrame.new(-1884.7747802734375, 19.327526092529297, -11666.8974609375),
            },
        },
        ["Cake Scientist"] = {
            aliases = {"Cake Scientist"},
            stages = {
                [3] = CFrame.new(-1884.7747802734375, 19.327526092529297, -11666.8974609375),
            },
        },
        ["Elite Hunter"] = {
            aliases = {"Elite Hunter"},
            stages = {
                [3] = CFrame.new(-5420, 314, -2828),
            },
        },
        ["Player Hunter"] = {
            aliases = {"Player Hunter"},
            stages = {
                [3] = CFrame.new(-5559, 314, -2840),
            },
        },
    }

    LocalActions.lp_select_npc = function(value)
        LocalRuntime.selectedNpc = tostring(value or "")
        return true
    end

    local function frozenWatcherTarget()
        local map = workspace:FindFirstChild("Map")
        if not map then
            return nil
        end

        for _, obj in ipairs(map:GetDescendants()) do
            if string.find(string.lower(obj.Name), "frozendimension", 1, true)
                or string.find(string.lower(obj.Name), "frozen dimension", 1, true)
            then
                if obj:IsA("BasePart") then
                    return obj.CFrame
                end
                if obj:IsA("Model") then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        return part.CFrame
                    end
                end
            end
        end

        return nil
    end

    LocalActions.lp_teleport_npc = function()
        local name = LocalRuntime.selectedNpc
        local data = NpcData[name]

        if not data then
            lpNotify("NPC data not found.")
            return false
        end

        task.spawn(function()
            local part = findNpcByAliases(data.aliases or {name})

            if part then
                smoothGo(part.CFrame * CFrame.new(0, 0, 4))
                return
            end

            if name == "Frozen Watcher" then
                local frozenCF = frozenWatcherTarget()
                if frozenCF then
                    smoothGo(frozenCF)
                    task.wait(1.0)
                    local loaded = findNpcByAliases(data.aliases)
                    if loaded then
                        smoothGo(loaded.CFrame * CFrame.new(0, 0, 4))
                    end
                else
                    lpNotify("Frozen Dimension is not spawned.")
                end
                return
            end

            local sea = currentSeaLocal()
            local stage = data.stages and data.stages[sea]

            if not stage and data.stages and data.stages[3] and sea ~= 3 then
                lpNotify(name .. " is in Third Sea.")
                return
            end

            if not stage then
                lpNotify("No teleport location available for this NPC in the current Sea.")
                return
            end

            if data.entrance then
                commFLocal("requestEntrance", data.entrance)
                task.wait(0.35)
            end

            lpNotify("Going to " .. name .. " region...")
            if not smoothGo(stage) then
                return
            end

            local started = os.clock()
            while os.clock() - started < 5 do
                part = findNpcByAliases(data.aliases or {name})
                if part then
                    smoothGo(part.CFrame * CFrame.new(0, 0, 4))
                    return
                end
                task.wait(0.25)
            end

            lpNotify(name .. " region reached. NPC model is not loaded.")
        end)

        return true
    end

    -- --------------------------------------------------------
    -- Island teleport
    -- --------------------------------------------------------
    local IslandData = {
        ["Hydra Island"] = CFrame.new(5255.1049, 1004.1949, 344.7700),
        ["Peanut Island"] = CFrame.new(-2062.7475585938, 50.473892211914, -10232.568359375),
        ["Ice Cream Island"] = CFrame.new(-902.56817626953, 79.93204498291, -10988.84765625),
        ["House Hydra Island"] = CFrame.new(5657.88623046875, 1013.0790405273438, -335.4996337890625),
        ["Tiki"] = CFrame.new(-16218.6826, 9.08636189, 445.618408),
        ["Haunted Castle"] = CFrame.new(-9515.3720703125, 164.00624084473, 5786.0610351562),
        ["Port Town"] = CFrame.new(-290.7376708984375, 6.729952812194824, 5343.5537109375),
        ["Great Tree"] = CFrame.new(2681.2736816406, 1682.8092041016, -7190.9853515625),
        ["Floating Turtle"] = CFrame.new(-13274.528320313, 531.82073974609, -7579.22265625),
        ["Room Enma/Yama & Secret Temple"] = CFrame.new(5319, 23, -93),
    }

    LocalActions.lp_select_island = function(value)
        LocalRuntime.selectedIsland = tostring(value or "Hydra Island")
        return true
    end

    LocalActions.lp_teleport_island = function()
        local target = IslandData[LocalRuntime.selectedIsland]
        if not target then
            lpNotify("Island coordinate not found.")
            return false
        end

        if currentSeaLocal() ~= 3 then
            lpNotify("These LocalPlayer island shortcuts are Third Sea locations.")
            return false
        end

        task.spawn(function()
            smoothGo(target)
        end)

        return true
    end

    LocalActions.lp_teleport_mirage = function()
        task.spawn(function()
            local worldOrigin = workspace:FindFirstChild("_WorldOrigin")
            local locations = worldOrigin and worldOrigin:FindFirstChild("Locations")
            local mirage = locations and locations:FindFirstChild("Mirage Island")

            if mirage then
                local cf = nil
                if mirage:IsA("BasePart") then
                    cf = mirage.CFrame
                elseif mirage:IsA("Model") then
                    local part = mirage.PrimaryPart or mirage:FindFirstChildWhichIsA("BasePart", true)
                    cf = part and part.CFrame
                end

                if cf then
                    smoothGo(cf * CFrame.new(0, 333, 0))
                    return
                end
            end

            local map = workspace:FindFirstChild("Map")
            local mapMirage = map and (
                map:FindFirstChild("MysticIsland")
                or map:FindFirstChild("MirageIsland")
                or map:FindFirstChild("Mirage Island")
            )

            if mapMirage then
                local part = mapMirage:IsA("Model")
                    and (mapMirage.PrimaryPart or mapMirage:FindFirstChildWhichIsA("BasePart", true))
                    or (mapMirage:IsA("BasePart") and mapMirage or nil)

                if part then
                    smoothGo(part.CFrame * CFrame.new(0, 150, 0))
                    return
                end
            end

            lpNotify("Mirage Island is not spawned.")
        end)

        return true
    end

    LocalActions.lp_teleport_prehistoric = function()
        task.spawn(function()
            local map = workspace:FindFirstChild("Map")
            local island = map and (
                map:FindFirstChild("PrehistoricIsland")
                or map:FindFirstChild("Prehistoric Island")
            )

            if not island then
                lpNotify("Prehistoric Island is not spawned.")
                return
            end

            local target = nil

            local core = island:FindFirstChild("Core")
            local relic = core and core:FindFirstChild("PrehistoricRelic")
            local skull = relic and relic:FindFirstChild("Skull")

            if skull then
                if skull:IsA("BasePart") then
                    target = skull.CFrame
                elseif skull:IsA("Model") then
                    local part = skull.PrimaryPart or skull:FindFirstChildWhichIsA("BasePart", true)
                    target = part and part.CFrame
                end
            end

            if not target then
                local part = island:IsA("Model")
                    and (island.PrimaryPart or island:FindFirstChildWhichIsA("BasePart", true))
                    or (island:IsA("BasePart") and island or nil)
                target = part and part.CFrame
            end

            if target then
                smoothGo(target * CFrame.new(0, 5, 0))
            else
                lpNotify("Could not find a Prehistoric Island anchor.")
            end
        end)

        return true
    end

    LocalRuntime.stop = function()
        LocalRuntime.autoStats = false
        LocalRuntime.noclip = false
        stopNoclip()

        if LocalRuntime.translateConnection then
            LocalRuntime.translateConnection:Disconnect()
            LocalRuntime.translateConnection = nil
        end
    end
end


local ActionRegistry = setmetatable(LocalActions, {
    __index = function(_, key)
        return QuickActions[key] or StatusActions[key] or ShopActions[key]
    end
})

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
            { type = "info", text = "Timer: 0h 00m 00s", infoKey = "timer" },
            { type = "info", text = "Server Timer: 0h 00m 00s", infoKey = "server_timer" },
            { type = "info", text = "Next Time Spawn Fist of Darkness or God's Chalice: --", infoKey = "fist_chalice" },
            { type = "info", text = "Elite Hunter: --", infoKey = "elite" },
            { type = "info", text = "Tyrant Eyes: 0 Eyes", infoKey = "tyrant_eyes" },
            { type = "info", text = "Cake Prince: -- Mobs", infoKey = "cake_prince" },
            { type = "info", text = "Leviathan: --", infoKey = "leviathan" },
            { type = "info", text = "Mirage Island: ❌", infoKey = "mirage" },
            { type = "info", text = "Prehistoric Island: ❌", infoKey = "prehistoric" },
            { type = "info", text = "Frozen Dimension: ❌", infoKey = "frozen" },
            { type = "info", text = "Moon Phase: --", infoKey = "moon" },
            { type = "info", text = "Ancient One: --", infoKey = "ancient_one" },
        } },
        { title = "Server", items = {
            { type = "info", text = "PlaceId: CURRENT_PLACE_ID", infoKey = "place_id" },
            { type = "input", text = "Input JobId Normal And JobId", placeholder = "Paste JobId here", action = "set_job_id" },
            { type = "toggle", text = "Spam Join", action = "spam_join" },
            { type = "button", text = "Join JobId", action = "join_job_id" },
            { type = "button", text = "Copy JobId", action = "copy_job_id" },
            { type = "button", text = "Hop Server", action = "hop_server" },
            { type = "button", text = "Hop Server Less People", action = "hop_server_less" },
        } },
    } },
    { name = "LocalPlayer", sections = {
        { title = "Utility", items = {
            { type = "toggle", text = "Auto Translate", action = "lp_auto_translate" },
            { type = "button", text = "Stop Tween", action = "lp_stop_tween" },
            { type = "button", text = "Show Item", action = "lp_show_item" },
            { type = "button", text = "Open Devil Fruit Shop", action = "lp_open_fruit_shop" },
            { type = "button", text = "Open Devil Fruit Shop Mirage", action = "lp_open_fruit_shop_mirage" },
            { type = "button", text = "Open Title", action = "lp_open_title" },
            { type = "button", text = "Open Color", action = "lp_open_color" },
        } },
        { title = "Stats / Team", items = {
            { type = "dropdown", text = "Select Stats", options = { "Demon Fruit", "Defense", "Melee", "Sword", "Gun" }, action = "lp_select_stat" },
            { type = "toggle", text = "Auto Stats", action = "lp_auto_stats" },
            { type = "dropdown", text = "Select Team", options = { "Pirate", "Marine" }, action = "lp_select_team" },
            { type = "button", text = "Change Team", action = "lp_change_team" },
        } },
        { title = "Movement", items = {
            { type = "toggle", text = "Noclip", action = "lp_noclip" },
        } },
        { title = "NPC Teleport", items = {
            { type = "dropdown", text = "Select NPC", options = { "Experienced Captain", "Blacksmith", "Fisherman", "Pirate Port Quest Giver", "Blox Fruit Dealer", "Fossil Expert", "Lucien", "Submarine Worker", "Sharkman Master", "Doghouse", "Mysterious Force", "Ancient One", "Sealed King", "Gravestone", "Skeleton Machine", "Frozen Watcher", "Dojo Trainer", "Dragon Tamer", "Sweet Crafter", "Cake Scientist", "Elite Hunter", "Player Hunter" }, action = "lp_select_npc" },
            { type = "button", text = "Teleport To NPC", action = "lp_teleport_npc" },
        } },
        { title = "Island Teleport", items = {
            { type = "dropdown", text = "Select Island", options = { "Hydra Island", "Peanut Island", "Ice Cream Island", "House Hydra Island", "Tiki", "Haunted Castle", "Port Town", "Great Tree", "Floating Turtle", "Room Enma/Yama & Secret Temple" }, action = "lp_select_island" },
            { type = "button", text = "Teleport To Island", action = "lp_teleport_island" },
            { type = "button", text = "Teleport Mirage", action = "lp_teleport_mirage" },
            { type = "button", text = "Teleport Prehistoric Island", action = "lp_teleport_prehistoric" },
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
            { type = "toggle", text = "ESP Berry", action = "esp_berry" },
            { type = "toggle", text = "ESP Island", action = "esp_island" },
            { type = "toggle", text = "ESP Fruit", action = "esp_fruit" },
            { type = "toggle", text = "ESP Player", action = "esp_player" },
        } },
    } },
    { name = "PVP", sections = {
        { title = "PVP", items = {
            { type = "dropdown", text = "Select Player PVP", options = { "Select Player" }, action = "pvp_select_player" },
            { type = "dropdown", text = "Select Method Aimbot", options = { "Camera", "Mouse" }, action = "pvp_aim_method" },
            { type = "button", text = "Refresh Player", action = "pvp_refresh_player" },
            { type = "button", text = "Teleport Player", action = "pvp_teleport_player" },
            { type = "toggle", text = "Auto Aimbot", action = "pvp_auto_aimbot" },
            { type = "toggle", text = "Auto Aimbot Gun", action = "pvp_auto_aimbot_gun" },
        } },
        { title = "Misc PVP", items = {
            { type = "slider", text = "WalkSpeed", value = 16, min = 0, max = 250, action = "pvp_walkspeed_value" },
            { type = "slider", text = "JumpPower", value = 50, min = 0, max = 250, action = "pvp_jumppower_value" },
            { type = "button", text = "Change JumpPower", action = "pvp_apply_jumppower" },
            { type = "button", text = "Change WalkSpeed", action = "pvp_apply_walkspeed" },
            { type = "toggle", text = "Walk On Water", action = "pvp_walk_on_water", default = true },
        } },
    } },
    { name = "Tab Webhook", sections = {
        { title = "Webhook", items = {
            { type = "input", text = "Input Webhook URL", placeholder = "https://discord.com/api/webhooks/...", action = "webhook_url" },
            { type = "input", text = "Input Discord Ping", placeholder = "User ID / Role ID / everyone", action = "webhook_ping" },
            { type = "toggle", text = "Ping Everyone/ID Discord", action = "webhook_ping_enabled" },
            { type = "toggle", text = "Noti Profile", action = "webhook_profile" },
            { type = "dropdown", text = "Select Rarity Fruit", options = { "Common", "Uncommon", "Rare", "Legendary", "Mythical" }, action = "webhook_rarity" },
            { type = "toggle", text = "Webhook Store Fruit", action = "webhook_store_fruit" },
            { type = "toggle", text = "Webhook Find Prehistoric Island", action = "webhook_prehistoric" },
            { type = "toggle", text = "Webhook Find Leviathan", action = "webhook_leviathan" },
            { type = "toggle", text = "Webhook Destroy IDK", action = "webhook_destroy_idk" },
            { type = "toggle", text = "Webhook Find Mirage", action = "webhook_mirage" },
        } },
    } },
    { name = "Setting", sections = {
        { title = "Setting", items = {
            { type = "toggle", text = "White Screen", action = "setting_white" },
            { type = "toggle", text = "Black Screen", action = "setting_black" },
            { type = "toggle", text = "Remove Notifications", action = "setting_remove_notifications" },
            { type = "toggle", text = "Auto Rejoin Disconnect", action = "setting_auto_rejoin" },
            { type = "toggle", text = "Auto Load Script", action = "setting_auto_load" },
            { type = "button", text = "Boost FPS", action = "setting_boost_fps" },
            { type = "button", text = "Copy Config", action = "setting_copy_config" },
            { type = "dropdown", text = "Toggle GUI", options = { "LeftControl", "RightControl", "Insert", "Home" }, action = "setting_gui_key" },
        } },
    } },
}

ScreenGui = New("ScreenGui", {
    Name = "TaveHub_LocalPlayer_4",
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

Main = New("Frame", {
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

local function AddToggle(parent, text, callback, defaultValue)
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

    local enabled = defaultValue == true
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

    if enabled and callback then
        task.defer(function()
            pcall(callback, true)
        end)
    end

    return row
end

local function AddInfo(parent, text, infoKey)
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
    if infoKey and StatusRuntime and StatusRuntime.infoLabels then
        StatusRuntime.infoLabels[infoKey] = label

        -- Timer heartbeat is independent of all remote/API status checks.
        if infoKey == "timer" then
            task.spawn(function()
                while label and label.Parent and ScreenGui and ScreenGui.Parent do
                    local elapsed = math.max(0, math.floor(os.clock() - StatusRuntime.startedAt))
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = elapsed % 60
                    label.Text = string.format("Timer: %dh %02dm %02ds", h, m, s)
                    task.wait(1)
                end
            end)
        elseif infoKey == "server_timer" then
            task.spawn(function()
                while label and label.Parent and ScreenGui and ScreenGui.Parent do
                    local elapsed = math.max(0, math.floor(workspace.DistributedGameTime or 0))
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = elapsed % 60
                    label.Text = string.format("Server Timer: %dh %02dm %02ds", h, m, s)
                    task.wait(1)
                end
            end)
        end
    end
    return row
end

local function AddInput(parent, text, placeholder, callback)
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

    holder:SetAttribute("Value", "")
    box:GetPropertyChangedSignal("Text"):Connect(function()
        holder:SetAttribute("Value", box.Text)
        if callback then
            pcall(callback, box.Text)
        end
    end)

    return holder
end

local function AddDropdown(parent, text, options, callback)
    options = options or {"Select..."}
    if #options < 1 then
        options = {"Select..."}
    end

    local closedHeight = 39
    local optionHeight = 30
    local maxVisible = 5

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
        Size = UDim2.new(1, 0, 0, 40),
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
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.AccentSoft
    }, menu)

    New("UIListLayout", {
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, scroll)

    local opened = false
    local optionButtons = {}

    local function recalcMenu()
        local visibleCount = math.max(1, math.min(#options, maxVisible))
        local menuHeight = (visibleCount * optionHeight) + 6
        menu.Size = UDim2.new(1, 0, 0, menuHeight)
        scroll.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight)
        scroll.ScrollBarThickness = #options > maxVisible and 3 or 0

        if opened then
            holder.Size = UDim2.new(1, 0, 0, closedHeight + menuHeight + 5)
        end
    end

    local function setOpen(state)
        opened = state == true
        menu.Visible = opened
        arrow.Text = opened and "▲" or "▼"

        local visibleCount = math.max(1, math.min(#options, maxVisible))
        local menuHeight = (visibleCount * optionHeight) + 6
        holder.Size = UDim2.new(
            1, 0, 0,
            opened and (closedHeight + menuHeight + 5) or closedHeight
        )
    end

    local function choose(optionText, fire)
        current = tostring(optionText or "Select...")
        label.Text = text .. ": " .. current
        holder:SetAttribute("Value", current)
        setOpen(false)

        if fire and callback then
            pcall(callback, current)
        end
    end

    local function rebuild(newOptions)
        for _, button in ipairs(optionButtons) do
            pcall(function() button:Destroy() end)
        end
        optionButtons = {}

        options = newOptions or {"Select..."}
        if #options < 1 then
            options = {"Select..."}
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
                choose(optionText, true)
            end)

            table.insert(optionButtons, optionButton)
        end

        local exists = false
        for _, option in ipairs(options) do
            if tostring(option) == current then
                exists = true
                break
            end
        end

        if not exists then
            choose(options[1], true)
        end

        recalcMenu()
    end

    holder:SetAttribute("Value", current)
    rebuild(options)

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

    UIControls[text] = {
        Holder = holder,
        SetOptions = rebuild,
        SetValue = function(value)
            choose(value, true)
        end,
        GetValue = function()
            return current
        end
    }

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
                obj = AddButton(page, item.text, item.action and ActionRegistry[item.action] or nil)
            elseif item.type == "toggle" then
                obj = AddToggle(page, item.text, item.action and ActionRegistry[item.action] or nil, item.default)
            elseif item.type == "info" then
                obj = AddInfo(page, item.text, item.infoKey)
            elseif item.type == "input" then
                obj = AddInput(page, item.text, item.placeholder, item.action and ActionRegistry[item.action] or nil)
            elseif item.type == "dropdown" then
                obj = AddDropdown(page, item.text, item.options, item.action and ActionRegistry[item.action] or nil)
            elseif item.type == "slider" then
                obj = AddSlider(page, item.text, item.value, item.min, item.max, function(v)
                    item.value = v
                    if item.action and ActionRegistry[item.action] then
                        pcall(ActionRegistry[item.action], v)
                    end
                end)
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

Floating = New("TextButton", {
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
    StatusRuntime.spamJoin = false
    StatusRuntime.monitorRunning = false

    QuickRuntime.webhook.monitorRunning = false

    if LocalRuntime and LocalRuntime.stop then
        pcall(LocalRuntime.stop)
    end

    if QuickRuntime.pvp.aimConnection then
        QuickRuntime.pvp.aimConnection:Disconnect()
    end
    if QuickRuntime.pvp.waterConnection then
        QuickRuntime.pvp.waterConnection:Disconnect()
    end
    if QuickRuntime.setting.keyConnection then
        QuickRuntime.setting.keyConnection:Disconnect()
    end
    if QuickRuntime.setting.disconnectConnection then
        QuickRuntime.setting.disconnectConnection:Disconnect()
    end

    for _, group in pairs(QuickRuntime.esp.connections) do
        for _, connection in ipairs(group) do
            pcall(function() connection:Disconnect() end)
        end
    end

    if QuickRuntime.pvp.waterPart then
        QuickRuntime.pvp.waterPart:Destroy()
    end

    ScreenGui:Destroy()
end)

ShowPage("Shop")

-- Labels already exist at this point, so populate them immediately instead of
-- waiting for the first background cycle.
pcall(StatusRuntime.updateFast)
task.spawn(function()
    pcall(StatusRuntime.updateWorld)
end)
task.spawn(function()
    task.wait(0.45)
    pcall(StatusRuntime.updateAncient)
end)
task.spawn(function()
    task.wait(0.90)
    pcall(StatusRuntime.updateElite)
end)
task.spawn(function()
    task.wait(1.75)
    pcall(StatusRuntime.updateTyrant)
end)
task.spawn(function()
    task.wait(2.60)
    pcall(StatusRuntime.updateCake)
end)
StatusRuntime.startMonitor()
QuickRuntime.startWebhookMonitor()
QuickRuntime.startGuiKey()

task.defer(function()
    if QuickRuntime.refreshPlayerDropdown then
        QuickRuntime.refreshPlayerDropdown()
    end
end)

print("[Tave Hub] LocalPlayer 4 loaded - LocalPlayer page functional; approved smooth teleport reused.")
