
-- Tave Hub Relatorio 7.3: Sea destinations and visible travel diagnostics.
-- Volcano Event worker: guarded local defense/collection; sea search and quest chain need live validation.
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

-- One owner per execution. Re-running this version stops its previous workers.
local sessionEnvironment = (typeof(getgenv) == "function" and getgenv()) or _G
local previousSession = sessionEnvironment.__TaveHubSession
if type(previousSession) == "table" then
    if type(previousSession.cleanup) == "function" then
        pcall(previousSession.cleanup)
    end
    previousSession.alive = false
end
local session = {alive = true, connections = {}}
sessionEnvironment.__TaveHubSession = session
local MovementConfig = {speed = 170}
local FarmSettings = {
    autoClick = false, dragonStormAura = false, autoBuso = false,
    autoObservation = false, autoV4 = false, autoV3 = false,
    autoDodgeMobs = false, lowHealthTeleport = false,
    healthPercent = 40, teleportY = 800, safeTweenWithItems = false,
    hopMinutes = 10, usePortalTeleport = false, bringMobCount = 2,
    bringMob = false, resetTeleport = false, tweenSpeed = 170,
}
sessionEnvironment.__TaveFarmSettings = FarmSettings
local SkillSettings = {
    fastNoHold = false,
    selected = {
        Melee = {Z = false, X = false, C = false},
        Sword = {Z = false, X = false},
        Gun = {Z = false, X = false},
        ["Blox Fruit"] = {Z = false, X = false, C = false, V = false, F = false},
    },
    holdSeconds = {
        Melee = {Z = 0.5, X = 0.5, C = 0.5},
        Sword = {Z = 0.5, X = 0.5},
        Gun = {Z = 0.5, X = 0.5},
        ["Blox Fruit"] = {Z = 0.5, X = 0.5, C = 0.5, V = 0.5, F = 0.5},
    },
}
sessionEnvironment.__TaveSkillSettings = SkillSettings
local FarmingConfig = {
    method = "Farm Katakuri", auraDistance = 300,
    ignoreKatakuriAttack = false, hopFindKatakuri = false,
    autoQuest = false, masteryCategory = "Melee", masteryHealth = 40,
    material = "Vampire Fang",
}
sessionEnvironment.__TaveFarmingConfig = FarmingConfig

-- Session-only diagnostics. No remote transmission, credentials or input values.
local ReportRuntime = {
    entries = {}, functions = {}, maximum = 1000, dropped = 0,
    sequence = 0, startedAt = os.clock(), visible = false, scheduled = false,
    label = nil, feedback = nil, lastExport = nil,
}
local ReportActions = {}
local function reportSnapshot()
    local lines = {
        "Floquitave 7.11 - Relatorio da sessao",
        "PlaceId: " .. tostring(game.PlaceId),
        "Tempo da sessao: " .. tostring(math.floor(os.clock() - ReportRuntime.startedAt)) .. "s",
        "ACEITE = comando aceite; nao comprova efeito no jogo.",
        "CONFIRMADO = condicao observada pelo script (ex.: chegada ao destino).",
        "OBSERVADO = estado informado; nao comprova resultado final.",
        "NAO TESTADA / NAO IMPLEMENTADA / RECUSADO / ERRO = veja detalhes.",
        "Valores de campos de entrada, URLs de webhook e credenciais nao sao registados.",
        "Historico limitado a " .. tostring(ReportRuntime.maximum) .. " registos; descartados: " .. tostring(ReportRuntime.dropped),
        "", "FUNCOES",
    }
    local names = {}
    for name in pairs(ReportRuntime.functions) do table.insert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local f = ReportRuntime.functions[name]
        table.insert(lines, "[" .. f.status .. "] " .. name .. (f.detail ~= "" and (" | " .. f.detail) or ""))
    end
    table.insert(lines, "")
    table.insert(lines, "HISTORICO")
    for _, e in ipairs(ReportRuntime.entries) do
        table.insert(lines, string.format("#%d +%.1fs [%s] %s | %s", e.id, e.elapsed, e.status, e.name, e.detail))
    end
    return table.concat(lines, "\n")
end
ReportRuntime.snapshot = reportSnapshot
local function reportRefresh()
    if ReportRuntime.label and ReportRuntime.label.Parent then
        ReportRuntime.label.Text = reportSnapshot()
    end
end
ReportRuntime.refresh = reportRefresh
local function reportFeedback(message)
    if ReportRuntime.feedback and ReportRuntime.feedback.Parent then
        ReportRuntime.feedback.Text = tostring(message)
    end
end
local function reportRecord(name, status, detail)
    name, detail = tostring(name), tostring(detail or ""):sub(1, 1200)
    detail = detail:gsub("https?://%S+", "[URL omitida]")
    ReportRuntime.sequence = ReportRuntime.sequence + 1
    local e = {id = ReportRuntime.sequence, elapsed = os.clock() - ReportRuntime.startedAt,
        name = name, status = status, detail = detail}
    table.insert(ReportRuntime.entries, e)
    if #ReportRuntime.entries > ReportRuntime.maximum then
        table.remove(ReportRuntime.entries, 1)
        ReportRuntime.dropped = ReportRuntime.dropped + 1
    end
    ReportRuntime.functions[name] = {status = status, detail = detail}
    if ReportRuntime.visible and not ReportRuntime.scheduled then
        ReportRuntime.scheduled = true
        task.delay(0.35, function()
            ReportRuntime.scheduled = false
            if session.alive and ReportRuntime.visible then reportRefresh() end
        end)
    end
    return e.id
end
ReportRuntime.record = reportRecord
local function reportInvoke(name, kind, callback, ...)
    if type(callback) ~= "function" then
        reportRecord(name, "NAO IMPLEMENTADA", "Controle sem acao ligada nesta versao.")
        return false
    end
    local args = table.pack(...)
    local detail = "Acao solicitada"
    if kind == "toggle" then detail = args[1] == true and "Ligar" or "Desligar" end
    if kind == "input" then detail = "Campo atualizado; valor omitido" end
    reportRecord(name, "SOLICITADO", detail)
    local result = table.pack(pcall(callback, table.unpack(args, 1, args.n)))
    if not result[1] then
        reportRecord(name, "ERRO", tostring(result[2]))
        return false
    end
    if result[2] == false then
        reportRecord(name, "RECUSADO", "A acao devolveu false; consulte os estados e avisos proximos.")
        return false
    end
    reportRecord(name, "ACEITE", "Callback executado. Resultado no jogo ainda nao confirmado.")
    return table.unpack(result, 2, result.n)
end
ReportRuntime.invoke = reportInvoke
ReportActions.report_copy = function()
    local clip = (typeof(setclipboard) == "function" and setclipboard)
        or (typeof(toclipboard) == "function" and toclipboard)
    if not clip then
        reportFeedback("Clipboard indisponivel. Use Exportar TXT se o executor suportar writefile.")
        return false
    end
    local ok, err = pcall(clip, reportSnapshot())
    reportFeedback(ok and "Relatorio copiado. Pode colar aqui ou num arquivo TXT."
        or ("Falha ao copiar: " .. tostring(err):sub(1, 160)))
    return ok
end
ReportActions.report_export = function()
    if typeof(writefile) ~= "function" then
        reportFeedback("writefile indisponivel. Use Copiar Relatorio e guarde o texto como TXT.")
        return false
    end
    local name = "TaveHub_Relatorio_" .. tostring(os.time()) .. "_" .. tostring(ReportRuntime.sequence) .. ".txt"
    local ok, err = pcall(writefile, name, reportSnapshot())
    if ok then ReportRuntime.lastExport = name end
    reportFeedback(ok and ("TXT gravado na pasta do executor: " .. name)
        or ("Falha ao exportar: " .. tostring(err):sub(1, 160)))
    return ok
end
ReportActions.report_refresh = function() reportRefresh(); return true end
ReportActions.report_clear = function()
    ReportRuntime.entries, ReportRuntime.dropped = {}, 0
    for _, f in pairs(ReportRuntime.functions) do
        if f.status ~= "NAO IMPLEMENTADA" then f.status, f.detail = "NAO TESTADA", "" end
    end
    reportRefresh()
    reportFeedback("Historico reiniciado nesta sessao.")
    return true
end
ReportActions.report_marker = function()
    reportRecord("Teste manual", "OBSERVADO", "Inicio de um novo teste marcado pelo utilizador.")
    reportRefresh()
    return true
end
-- END SESSION REPORT MODULE

local function trackExternal(connection)
    table.insert(session.connections, connection)
    return connection
end

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
        local speed = MovementConfig.speed

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
        if not session.alive then return end
        local pending = getgenv and getgenv().__TavePendingFight or nil
        if pending and FightStyles[pending] then
            if getgenv then
                getgenv().__TavePendingFight = nil
            end
            ShopActions[pending](true)
        end
    end)

    task.spawn(function()
        while session.alive and task.wait(0.85) do
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
        while session.alive and task.wait(0.85) do
            if ShopRuntime.autoTrueTripleKatana then
                commF("MysteriousMan", "1")
                task.wait(0.10)
                commF("MysteriousMan", "2")
            end
        end
    end)

    ShopRuntime.stop = function()
        ShopRuntime.autoLegendarySword = false
        ShopRuntime.autoTrueTripleKatana = false
        for action in pairs(FightEngine.enabled) do
            FightEngine.enabled[action] = false
        end
        FightEngine.activeAction = nil
        cancelFightMove()
    end
end


local WorldEventCache = {
    mirage = false,
    prehistoric = false,
    frozen = false,
    map = nil,
    addedConnection = nil,
    removingConnection = nil,
}

local function worldEventKind(name)
    local low = string.lower(tostring(name or ""))

    if string.find(low, "mysticisland", 1, true)
        or string.find(low, "mirageisland", 1, true)
        or string.find(low, "mirage island", 1, true)
    then
        return "mirage"
    end

    if string.find(low, "prehistoricisland", 1, true)
        or string.find(low, "prehistoric island", 1, true)
    then
        return "prehistoric"
    end

    if string.find(low, "frozendimension", 1, true)
        or string.find(low, "frozen dimension", 1, true)
    then
        return "frozen"
    end

    return nil
end

local function rebuildWorldEventCache()
    WorldEventCache.mirage = false
    WorldEventCache.prehistoric = false
    WorldEventCache.frozen = false

    local map = workspace:FindFirstChild("Map")
    WorldEventCache.map = map
    if not map then
        return
    end

    for _, obj in ipairs(map:GetDescendants()) do
        local kind = worldEventKind(obj.Name)
        if kind then
            WorldEventCache[kind] = true
        end

        if WorldEventCache.mirage
            and WorldEventCache.prehistoric
            and WorldEventCache.frozen
        then
            break
        end
    end
end

local function bindWorldEventCache()
    if WorldEventCache.addedConnection then
        WorldEventCache.addedConnection:Disconnect()
        WorldEventCache.addedConnection = nil
    end
    if WorldEventCache.removingConnection then
        WorldEventCache.removingConnection:Disconnect()
        WorldEventCache.removingConnection = nil
    end

    local map = workspace:FindFirstChild("Map")
    if not map then
        return
    end

    WorldEventCache.map = map

    WorldEventCache.addedConnection = map.DescendantAdded:Connect(function(obj)
        local kind = worldEventKind(obj.Name)
        if kind then
            WorldEventCache[kind] = true
        end
    end)

    WorldEventCache.removingConnection = map.DescendantRemoving:Connect(function(obj)
        local kind = worldEventKind(obj.Name)
        if kind then
            -- Removal of a world event is rare; rebuild once only when it happens.
            task.defer(rebuildWorldEventCache)
        end
    end)
end

task.spawn(function()
    if not session.alive then return end
    rebuildWorldEventCache()
    if not session.alive then return end
    bindWorldEventCache()

    WorldEventCache.workspaceConnection = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Map" then
            task.defer(function()
                rebuildWorldEventCache()
                bindWorldEventCache()
            end)
        end
    end)
end)

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
    lastRemoteRefresh = -math.huge,
    remoteRefreshRunning = false,
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
        setInfo(
            "mirage",
            "Mirage Island: " .. (WorldEventCache.mirage and "✅" or "❌")
        )
        setInfo(
            "prehistoric",
            "Prehistoric Island: " .. (WorldEventCache.prehistoric and "✅" or "❌")
        )
        setInfo(
            "frozen",
            "Frozen Dimension: " .. (WorldEventCache.frozen and "✅" or "❌")
        )
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

    -- RemoteFunction calls are requested only when Status is opened. Keep one
    -- request in flight at a time; opening another page cancels the queue.
    StatusRuntime.refreshRemote = function()
        if StatusRuntime.remoteRefreshRunning
            or os.clock() - StatusRuntime.lastRemoteRefresh < 45
        then
            return
        end
        StatusRuntime.lastRemoteRefresh = os.clock()
        StatusRuntime.remoteRefreshRunning = true
        task.spawn(function()
            for _, fn in ipairs({updateEliteStatus, updateTyrantStatus, updateCakeStatus}) do
                if not session.alive or not ScreenGui or not ScreenGui.Parent
                    or not StatusRuntime.isVisible or not StatusRuntime.isVisible()
                then
                    break
                end
                pcall(fn)
                task.wait(1.2)
            end
            StatusRuntime.remoteRefreshRunning = false
        end)
    end

    local function runStatusLoop(initialDelay, interval, fn)
        task.spawn(function()
            if initialDelay and initialDelay > 0 then
                task.wait(initialDelay)
            end

            while StatusRuntime.monitorRunning and session.alive
                and ScreenGui and ScreenGui.Parent do
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
        runStatusLoop(0, 2.0, StatusRuntime.updateFast)

        -- Map/NPC scans no longer run inside the 1-second loop.
        runStatusLoop(1.35, 10, StatusRuntime.updateWorld)
        runStatusLoop(3.10, 30, function()
            if StatusRuntime.isVisible and StatusRuntime.isVisible() then
                StatusRuntime.updateAncient()
            end
        end)
        runStatusLoop(60, 60, function()
            if StatusRuntime.isVisible and StatusRuntime.isVisible() then
                StatusRuntime.refreshRemote()
            end
        end)
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
        local character = getCharacter()
        local function disableCollision(part)
            if not part:IsA("BasePart") then return end
            if oldCollision[part] == nil then
                oldCollision[part] = part.CanCollide
            end
            part.CanCollide = false
        end
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                disableCollision(part)
            end
        end
        local added = character and character.DescendantAdded:Connect(disableCollision)
        local noclip = RunService.Stepped:Connect(function()
            for part in pairs(oldCollision) do
                if part.Parent then part.CanCollide = false end
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
            if added then
                added:Disconnect()
                added = nil
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

        local duration = math.max(distance / MovementConfig.speed, 0.12)
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

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = false
        local lastSample = -math.huge
        local waterY = nil
        local hidden = false

        QuickRuntime.pvp.waterConnection = RunService.Heartbeat:Connect(function()
            if not session.alive or not QuickRuntime.pvp.walkOnWater then return end

            local root = getRootQuick()
            if not root then
                waterY = nil
                if not hidden then
                    part.Position = Vector3.new(0, -10000, 0)
                    hidden = true
                end
                return
            end

            -- Raycasting and filter allocation every frame is unnecessary.
            local now = os.clock()
            if now - lastSample >= 0.15 then
                lastSample = now
                params.FilterDescendantsInstances = {getCharacter(), part}
                local result = workspace:Raycast(
                    root.Position + Vector3.new(0, 2, 0),
                    Vector3.new(0, -14, 0),
                    params
                )
                waterY = result and result.Material == Enum.Material.Water
                    and (result.Position.Y + 0.05) or nil
            end

            if waterY then
                part.CFrame = CFrame.new(root.Position.X, waterY, root.Position.Z)
                hidden = false
            else
                if not hidden then
                    part.Position = Vector3.new(0, -10000, 0)
                    hidden = true
                end
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

    local function webhookMonitorHasWork()
        return QuickRuntime.webhook.storeFruit
            or QuickRuntime.webhook.prehistoric
            or QuickRuntime.webhook.leviathan
            or QuickRuntime.webhook.destroyIDK
            or QuickRuntime.webhook.mirage
    end

    local function startWebhookMonitor()
        if QuickRuntime.webhook.monitorRunning then return end
        QuickRuntime.webhook.monitorRunning = true

        task.spawn(function()
            while QuickRuntime.webhook.monitorRunning and ScreenGui and ScreenGui.Parent do
                -- Important: the old build scanned the whole Map every 2 seconds
                -- even when every webhook toggle was OFF.
                if not webhookMonitorHasWork() then
                    task.wait(1.25)
                    continue
                end

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

                if QuickRuntime.webhook.prehistoric then
                    local prehistoricNow = WorldEventCache.prehistoric == true
                    if prehistoricNow and not QuickRuntime.webhook.states.prehistoric then
                        sendWebhook("Prehistoric Island", "Prehistoric Island spawned ✅")
                    end
                    QuickRuntime.webhook.states.prehistoric = prehistoricNow
                end

                if QuickRuntime.webhook.leviathan then
                    local leviathanNow = leviathanExists()
                    if leviathanNow and not QuickRuntime.webhook.states.leviathan then
                        sendWebhook("Leviathan", "Leviathan found ✅")
                    end
                    QuickRuntime.webhook.states.leviathan = leviathanNow
                end

                if QuickRuntime.webhook.mirage then
                    local mirageNow = WorldEventCache.mirage == true
                    if mirageNow and not QuickRuntime.webhook.states.mirage then
                        sendWebhook("Mirage Island", "Mirage Island spawned ✅")
                    end
                    QuickRuntime.webhook.states.mirage = mirageNow
                end

                if QuickRuntime.webhook.destroyIDK then
                    local idkNow = idkExists()
                    if not idkNow and QuickRuntime.webhook.states.idk then
                        sendWebhook("Destroy IDK", "IDK object was destroyed / removed.")
                    end
                    QuickRuntime.webhook.states.idk = idkNow
                end

                -- Active webhook checks are intentionally slow and selective.
                task.wait(4.5)
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
    selectedIsland = "",
}

local LocalActions = {}

do
    local function lpNotify(message)
        reportRecord("LocalPlayer / Aviso", "OBSERVADO", message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tave Hub - LocalPlayer",
                Text = tostring(message or ""),
                Duration = 3
            })
        end)
    end

    local function lpTravelStatus(message)
        local value = "Teleport: " .. tostring(message)
        local label = StatusRuntime.infoLabels.teleport_status
        if label and label.Parent then label.Text = value end
        print("[Tave Hub / LocalPlayer] " .. value)
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

    local manualSea, syncingSea
    local function isCanonicalPlace()
        return game.PlaceId == 2753915549 or game.PlaceId == 4442272183
            or game.PlaceId == 7449423635
    end
    local function normalizeMapName(value)
        return string.lower(tostring(value or "")):gsub("[^%w]", "")
    end
    local seaMarkers = {
        [1] = {"windmill", "middletown", "jungle", "desert", "piratevillage", "marinefortress", "magmavillage", "fountaincity", "fishmanisland"},
        [2] = {"kingdomofrose", "cafe", "factory", "greenzone", "cursedship", "icecastle", "forgottenisland"},
        [3] = {"hydraisland", "floatingturtle", "hauntedcastle", "greattree", "porttown", "tikioutpost", "castleonthesea", "cakeisland"},
    }
    local function currentSeaLocal()
        if game.PlaceId == 2753915549 then return 1 end
        if game.PlaceId == 4442272183 then return 2 end
        if game.PlaceId == 7449423635 then return 3 end
        if manualSea then return manualSea end
        local map = workspace:FindFirstChild("Map")
        if not map then return 0 end
        local score = {0, 0, 0}
        -- Inspect a small, stable portion of the map. A single generic
        -- landmark must not choose a Sea when the PlaceId is unfamiliar.
        local function scoreName(name)
            local normalized = normalizeMapName(name)
            for sea, markers in ipairs(seaMarkers) do
                for _, marker in ipairs(markers) do
                    if normalized == marker then score[sea] = score[sea] + 1; break end
                end
            end
        end
        for _, child in ipairs(map:GetChildren()) do
            scoreName(child.Name)
            if child:IsA("Folder") then
                for _, nested in ipairs(child:GetChildren()) do scoreName(nested.Name) end
            end
        end
        local best, bestScore, tied = 0, 0, false
        for sea = 1, 3 do
            if score[sea] > bestScore then
                best, bestScore, tied = sea, score[sea], false
            elseif score[sea] > 0 and score[sea] == bestScore then
                tied = true
            end
        end
        return not tied and bestScore > 0 and best or 0
    end

    LocalActions.lp_current_sea = currentSeaLocal
    LocalActions.lp_sea_override = function(value)
        if syncingSea then return true end
        syncingSea = true
        if isCanonicalPlace() then value = "Auto" end
        manualSea = ({["First Sea"] = 1, ["Second Sea"] = 2, ["Third Sea"] = 3})[value]
        for _, controlName in ipairs({"Sea (manual if auto fails)", "Sea for Volcano (manual if auto fails)"}) do
            local control = UIControls[controlName]
            if control and control.GetValue() ~= value then control.SetValue(value) end
        end
        syncingSea = false
        reportRecord("Teleport / Sea manual", "OBSERVADO", "Selecao=" .. tostring(value)
            .. " | PlaceId=" .. tostring(game.PlaceId))
        if UIControls["Select Island"] and UIControls["Select NPC"]
            and LocalActions.lp_refresh_destinations then
            return LocalActions.lp_refresh_destinations()
        end
        return true
    end


    local function seaName(sea)
        return ({[1] = "First Sea", [2] = "Second Sea", [3] = "Third Sea"})[sea]
            or ("unknown Sea (PlaceId " .. tostring(game.PlaceId) .. ")")
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

    local function travelTo(targetCFrame, label)
        local root = getLocalRoot()
        if not root then
            lpTravelStatus("Character not ready")
            lpNotify("Character is not ready for teleport.")
            return false
        end
        local seconds = math.ceil((root.Position - targetCFrame.Position).Magnitude / MovementConfig.speed)
        lpTravelStatus("Going to " .. label .. " (~" .. tostring(seconds) .. "s)")
        print("[Tave Hub / LocalPlayer] PlaceId=" .. tostring(game.PlaceId)
            .. " start=" .. tostring(root.Position) .. " target=" .. tostring(targetCFrame.Position))
        lpNotify("Going to " .. label .. " (~" .. tostring(seconds) .. "s). Stop Tween cancels travel.")
        local reportName = "Teleport / " .. label
        reportRecord(reportName, "SOLICITADO", "PlaceId=" .. tostring(game.PlaceId)
            .. " | origem=" .. tostring(root.Position) .. " | destino=" .. tostring(targetCFrame.Position))
        local ok, arrived = pcall(smoothGo, targetCFrame)
        if not ok then
            reportRecord(reportName, "ERRO", tostring(arrived))
            lpTravelStatus("Error: " .. label)
            return false
        end
        local finalRoot = getLocalRoot()
        local remaining = finalRoot and (finalRoot.Position - targetCFrame.Position).Magnitude or nil
        arrived = arrived == true and remaining ~= nil and remaining <= 20
        if arrived and remaining and remaining <= 20 then
            reportRecord(reportName, "CONFIRMADO", "Chegada observada; distancia final=" .. string.format("%.1f", remaining))
        else
            reportRecord(reportName, "INTERROMPIDO_OU_FALHOU", "Chegada nao confirmada; distancia final=" .. tostring(remaining))
        end
        if not arrived and session.alive then
            lpTravelStatus("Failed or stopped: " .. label)
            lpNotify("Teleport to " .. label .. " stopped or failed. Try again after the character loads.")
        elseif arrived then
            lpTravelStatus("Arrived: " .. label)
        end
        return arrived
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
        if npcFolder then table.insert(roots, npcFolder) end
        local map = workspace:FindFirstChild("Map")
        if map then table.insert(roots, map) end
        for _, root in ipairs(roots) do
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("Model") then
                    local low = string.lower(obj.Name)
                    for _, alias in ipairs(aliases) do
                        local want = string.lower(alias)
                        if low == want or string.find(low, want, 1, true) then
                            local part = obj:FindFirstChild("HumanoidRootPart")
                                or obj:FindFirstChild("Head") or obj.PrimaryPart
                            if part and part:IsA("BasePart") then return part end
                        end
                    end
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

    -- Stable NPC names are always listed. The island is a staging point;
    -- the loaded NPC model is used for the final approach.
    local NpcRegions = {
        [1] = {
            ["Blox Fruit Gacha"] = "Jungle",
            ["Dark Step Teacher"] = "Pirate Village",
            ["Ability Teacher"] = "Frozen Village",
            ["Military Detective"] = "Prison",
            ["Water Kung Fu Teacher"] = "Underwater City",
            ["Instinct Teacher"] = "Sky Island 2",
            ["Experienced Captain"] = "Middle Town",
            ["Blacksmith"] = "Middle Town",
            ["Blox Fruit Dealer"] = "Middle Town",
        },
        [2] = {
            ["Manager"] = "Cafe", ["Bartilo"] = "Cafe", ["Trevor"] = "Cafe",
            ["Nerd"] = "Cafe", ["Blox Fruit Gacha"] = "Cafe",
            ["Experienced Captain"] = "Cafe", ["Blacksmith"] = "Cafe",
            ["Blox Fruit Dealer"] = "Cafe",
            ["Alchemist"] = "Green Zone", ["Mr. Captain"] = "Green Zone",
            ["Mysterious Scientist"] = "Cold Island",
            ["King Red Head"] = "Colosseum",
            ["Cyborg"] = "Factory",
            ["El Perro"] = "Cursed Ship",
            ["Ghoul"] = "Cursed Ship",
        },
        [3] = {
            ["Dojo Trainer"] = "House Hydra Island",
            ["Dragon Tamer"] = "House Hydra Island",
            ["Dragon Hunter"] = "House Hydra Island",
            ["Elite Hunter"] = "Castle on the Sea",
            ["Player Hunter"] = "Castle on the Sea",
            ["Sweet Crafter"] = "Cake Island",
            ["Cake Scientist"] = "Cake Island",
        },
    }
    for sea, entries in pairs(NpcRegions) do
        for name, island in pairs(entries) do
            local record = NpcData[name]
            if not record then
                record = {aliases = {name}}
                NpcData[name] = record
            end
            record.regions = record.regions or {}
            record.regions[sea] = island
        end
    end
    local npcRegionRoute
    local function requestIslandEntrance(destination, entrance, quiet)
        for attempt = 1, 2 do
            local ok, result = commFLocal("requestEntrance", entrance)
            task.wait(0.6)
            local root = getLocalRoot()
            local arrived = root ~= nil and (root.Position - entrance).Magnitude <= 650
            reportRecord("Teleport / Entrada " .. destination,
                arrived and "CONFIRMADO" or "OBSERVADO",
                "tentativa=" .. tostring(attempt) .. " | chamada=" .. tostring(ok)
                    .. " | resposta=" .. tostring(result) .. " | perto=" .. tostring(arrived))
            if arrived then return true end
        end
        lpTravelStatus("Entrance failed: " .. destination)
        if not quiet then
            lpNotify("Entrance did not move the character to " .. destination .. ".")
        end
        return false
    end

    local cursedShipInterior = Vector3.new(923.2125, 126.976, 32852.832)
    local cursedShipDoor = CFrame.new(-6501.354, 83.499, -124.544)
    local cursedShipDoorInside = Vector3.new(-6509, 83.499, -133)
    local function insideCursedShip()
        local root = getLocalRoot()
        return root ~= nil and (root.Position - cursedShipInterior).Magnitude <= 650
    end

    local function enterCursedShip()
        if insideCursedShip() then return true end
        if requestIslandEntrance("Cursed Ship", cursedShipInterior, true) then
            return true
        end

        -- The remote entrance may be refused at long range. Move to the
        -- observed exterior door and walk through its trigger instead.
        local reachedDoor = travelTo(cursedShipDoor, "Cursed Ship door")
        if insideCursedShip() then return true end
        if not reachedDoor then
            lpNotify("Could not reach the Cursed Ship door.")
            return false
        end

        local root = getLocalRoot()
        local character = root and root.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:MoveTo(cursedShipDoorInside)
            local started = os.clock()
            while session.alive and os.clock() - started < 3 do
                if insideCursedShip() then
                    reportRecord("Teleport / Porta Cursed Ship", "CONFIRMADO", "Passagem pela porta observada")
                    return true
                end
                task.wait(0.15)
            end
        end

        -- Some servers accept the entrance request only after approaching it.
        if requestIslandEntrance("Cursed Ship", cursedShipInterior, true) then
            return true
        end
        reportRecord("Teleport / Porta Cursed Ship", "INTERROMPIDO_OU_FALHOU",
            "Porta alcancada; passagem nao confirmada | PlaceId=" .. tostring(game.PlaceId))
        lpTravelStatus("Cursed Ship door reached, entry not confirmed")
        lpNotify("Reached the Cursed Ship door, but entry was not confirmed. Check the Relatorio page.")
        return false
    end

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
            -- NPCs that are currently streamed in can be used without a saved
            -- coordinate. Never invent a far-away route for an unknown NPC.
            local loaded = findNpcByAliases({name})
            if loaded then
                task.spawn(function()
                    travelTo(loaded.CFrame * CFrame.new(0, 0, 4), name)
                end)
                return true
            end
            lpNotify(name .. " is not loaded; no verified route is available.")
            return false
        end

        local sea = currentSeaLocal()
        if sea == 0 then
            local loaded = findNpcByAliases(data.aliases or {name})
            if loaded then
                reportRecord("Teleport / " .. name, "OBSERVADO", "Sea desconhecido; NPC carregado encontrado")
                task.spawn(function() travelTo(loaded.CFrame * CFrame.new(0, 0, 4), name) end)
                return true
            end
            lpTravelStatus("Sea unknown and NPC not loaded: " .. name)
            lpNotify("Select the current Sea or wait for the NPC to load (PlaceId " .. tostring(game.PlaceId) .. ").")
            return false
        end
        if not (data.stages and data.stages[sea])
            and not (data.regions and data.regions[sea])
            and not findNpcByAliases(data.aliases or {name}) then
            lpTravelStatus("No NPC route in " .. seaName(sea) .. ": " .. name)
            lpNotify(name .. " has no route in " .. seaName(sea) .. ".")
            return false
        end
        if name == "Frozen Watcher" and sea ~= 3 then
            lpNotify("Frozen Watcher is in Third Sea.")
            return false
        end

        task.spawn(function()
            local part = findNpcByAliases(data.aliases or {name})

            if part then
                travelTo(part.CFrame * CFrame.new(0, 0, 4), name)
                return
            end

            if name == "Frozen Watcher" then
                local frozenCF = frozenWatcherTarget()
                if frozenCF then
                    if not travelTo(frozenCF, "Frozen Dimension") then return end
                    task.wait(1.0)
                    local loaded = findNpcByAliases(data.aliases)
                    if loaded then
                        travelTo(loaded.CFrame * CFrame.new(0, 0, 4), name)
                    else
                        lpNotify("Frozen Watcher did not load at the destination.")
                    end
                else
                    lpNotify("Frozen Dimension is not spawned.")
                end
                return
            end

            local stage = (isCanonicalPlace() and data.stages and data.stages[sea])
                or (npcRegionRoute and npcRegionRoute(sea, name))

            if not stage then
                lpTravelStatus("NPC not loaded / no live route: " .. name)
                reportRecord("Teleport / " .. name, "RECUSADO", "NPC nao carregado e ilha de referencia indisponivel")
                lpNotify("NPC not loaded and its island route is unavailable.")
                return
            end

            if data.entrance then
                commFLocal("requestEntrance", data.entrance)
                task.wait(0.35)
            end

            if sea == 2 and data.regions and data.regions[sea] == "Cursed Ship" then
                if not enterCursedShip() then
                    return
                end
            end

            if not travelTo(stage, name .. " region") then
                return
            end

            local started = os.clock()
            while session.alive and os.clock() - started < 10 do
                part = findNpcByAliases(data.aliases or {name})
                if part then
                    travelTo(part.CFrame * CFrame.new(0, 0, 4), name)
                    return
                end
                task.wait(0.5)
            end

            if session.alive then
                lpNotify(name .. " region reached, but the NPC did not load. Its saved location may be outdated.")
            end
        end)

        return true
    end

    -- --------------------------------------------------------
    -- Island teleport
    -- --------------------------------------------------------
    -- Each saved CFrame belongs to one place. These are approximate staging
    -- positions; the real-world arrival needs validation inside the game.
    local IslandData = {
        [1] = {
            ["Pirate Starter"] = CFrame.new(1071, 16, 1427),
            ["Marine Starter"] = CFrame.new(-2573, 7, 2047),
            ["Middle Town"] = CFrame.new(-656, 8, 1437),
            ["Jungle"] = CFrame.new(-1250, 12, 341),
            ["Pirate Village"] = CFrame.new(-1122, 5, 3856),
            ["Desert"] = CFrame.new(1094, 7, 4193),
            ["Frozen Village"] = CFrame.new(1198, 27, -1212),
            ["Marine Fortress"] = CFrame.new(-4505, 21, 4261),
            ["Colosseum"] = CFrame.new(-1428, 8, -3014),
            ["Sky Island 1"] = CFrame.new(-4970, 718, -2622),
            ["Sky Island 2"] = CFrame.new(-4813, 904, -1913),
            ["Sky Island 3"] = CFrame.new(-7952, 5546, -321),
            ["Prison"] = CFrame.new(4854, 6, 740),
            ["Magma Village"] = CFrame.new(-5232, 9, 8468),
            ["Underwater City"] = CFrame.new(61164, 12, 1820),
            ["Fountain City"] = CFrame.new(5133, 5, 4038),
        },
        [2] = {
            ["Dock"] = CFrame.new(83, 19, 2835),
            ["Kingdom of Rose"] = CFrame.new(-395, 119, 1246),
            ["Cafe"] = CFrame.new(-385, 73, 297),
            ["Mansion"] = CFrame.new(-390, 332, 673),
            ["Factory"] = CFrame.new(430, 210, -433),
            ["Green Zone"] = CFrame.new(-2372, 73, -3167),
            ["Dark Arena"] = CFrame.new(3494, 13, -3259),
            ["Flamingo Room"] = CFrame.new(2285, 15, 905),
            ["Colosseum"] = CFrame.new(-1837, 45, 1360),
            ["Graveyard"] = CFrame.new(-6027.102, 6.715, -1326.406),
            ["Snow Mountain"] = CFrame.new(512, 402, -5380),
            ["Hot Island"] = CFrame.new(-5478, 16, -5247),
            ["Cold Island"] = CFrame.new(-6027, 15, -5072),
            ["Cursed Ship"] = CFrame.new(902, 125, 33072),
            ["Ice Castle"] = CFrame.new(5400, 29, -6237),
            ["Forgotten Island"] = CFrame.new(-3043, 239, -10192),
            ["Usoap Island"] = CFrame.new(4749, 9, 2850),
        },
        [3] = {
            ["Hydra Island"] = CFrame.new(5255.1049, 1004.1949, 344.7700),
            ["Peanut Island"] = CFrame.new(-2062.7476, 50.4739, -10232.5684),
            ["Ice Cream Island"] = CFrame.new(-902.5682, 79.932, -10988.8477),
            ["House Hydra Island"] = CFrame.new(5657.8862, 1013.079, -335.4996),
            ["Tiki"] = CFrame.new(-16218.6826, 9.0864, 445.6184),
            ["Haunted Castle"] = CFrame.new(-9515.3721, 164.0062, 5786.061),
            ["Port Town"] = CFrame.new(-290.7377, 6.73, 5343.5537),
            ["Great Tree"] = CFrame.new(2681.2737, 1682.8092, -7190.9854),
            ["Floating Turtle"] = CFrame.new(-13274.5283, 531.8207, -7579.2227),
            ["Mansion"] = CFrame.new(-12553.8125, 332.404, -7621.9175),
            ["Castle on the Sea"] = CFrame.new(-5477.6284, 313.7947, -2808.4585),
            ["Cake Island"] = CFrame.new(-1897, 15, -11576),
            ["Candy Cane Island"] = CFrame.new(-1038, 10, -14076),
            ["Room Enma/Yama & Secret Temple"] = CFrame.new(5319, 23, -93),
        },
    }

    local IslandOrder = {
        [1] = {"Pirate Starter", "Marine Starter", "Middle Town", "Jungle", "Pirate Village", "Desert", "Frozen Village", "Marine Fortress", "Colosseum", "Sky Island 1", "Sky Island 2", "Sky Island 3", "Prison", "Magma Village", "Underwater City", "Fountain City"},
        [2] = {"Dock", "Kingdom of Rose", "Cafe", "Mansion", "Factory", "Green Zone", "Dark Arena", "Flamingo Room", "Colosseum", "Graveyard", "Snow Mountain", "Hot Island", "Cold Island", "Cursed Ship", "Ice Castle", "Forgotten Island", "Usoap Island"},
        [3] = {"Hydra Island", "Peanut Island", "Ice Cream Island", "House Hydra Island", "Tiki", "Haunted Castle", "Port Town", "Great Tree", "Floating Turtle", "Mansion", "Castle on the Sea", "Cake Island", "Candy Cane Island", "Room Enma/Yama & Secret Temple"},
    }

    -- Build these lists from the live place when the page is created, and on refresh.
    -- This avoids briefly presenting Third Sea destinations in First/Second Sea.
    LocalActions.lp_destination_lists = function()
        local sea = currentSeaLocal()
        local islands = IslandOrder[sea] or {"Sea not detected - check PlaceId"}
        local names, seen = {}, {}
        if sea ~= 0 then
            for name, data in pairs(NpcData) do
                if (data.stages and data.stages[sea]) or (data.regions and data.regions[sea])
                    or (sea == 3 and name == "Frozen Watcher") then
                    table.insert(names, name)
                    seen[name] = true
                end
            end
        end
        local folder = workspace:FindFirstChild("NPCs")
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("Model") and not seen[obj.Name]
                    and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")) then
                    seen[obj.Name] = true
                    table.insert(names, obj.Name)
                end
            end
        end
        table.sort(names)
        if #names == 0 then names = {"No NPCs available in this Sea"} end
        return sea, islands, names
    end

    LocalActions.lp_refresh_destinations = function()
        local sea, islands, names = LocalActions.lp_destination_lists()
        local islandControl = UIControls["Select Island"]
        local npcControl = UIControls["Select NPC"]
        if not islandControl or not npcControl then
            lpTravelStatus("Destination controls missing / PlaceId " .. tostring(game.PlaceId))
            reportRecord("Teleport / Destinos", "ERRO", "Controles de ilha/NPC nao encontrados")
            return false
        end
        islandControl.SetOptions(islands)
        npcControl.SetOptions(names)
        if sea == 0 then
            lpTravelStatus("Sea unknown; select Sea for islands / " .. tostring(#names) .. " NPC entries")
            reportRecord("Teleport / Destinos", "OBSERVADO", "Sea nao identificado; PlaceId="
                .. tostring(game.PlaceId) .. " | NPCs carregados=" .. tostring(#names))
            return #names > 0 and names[1] ~= "No NPCs available in this Sea"
        end
        lpTravelStatus(seaName(sea) .. (manualSea and " (manual)" or " (auto)")
            .. " / " .. tostring(#islands) .. " islands / " .. tostring(#names) .. " NPCs")
        reportRecord("Teleport / Destinos", "CONFIRMADO", "PlaceId=" .. tostring(game.PlaceId)
            .. " | " .. seaName(sea) .. " | fonte=" .. (manualSea and "manual" or "auto")
            .. " | ilhas=" .. tostring(#islands) .. " | NPCs=" .. tostring(#names)
            .. " | selecionada=" .. tostring(islandControl.GetValue()))
        return true
    end

    local IslandAliases = {
        [1] = {
            ["Pirate Starter"] = {"WindMill", "Pirate Starter"}, ["Marine Starter"] = {"Marine", "Marine Starter"},
            ["Middle Town"] = {"Middle Town", "MiddleTown"}, ["Frozen Village"] = {"Snow", "Frozen Village"},
            ["Sky Island 1"] = {"Sky Island 1"}, ["Sky Island 2"] = {"Sky Island 2"},
            ["Sky Island 3"] = {"Sky Island 3"}, ["Underwater City"] = {"FishmanIsland", "Underwater City"},
        },
        [2] = {
            ["Dock"] = {"Dock", "First Spot"}, ["Cafe"] = {"Cafe", "The Cafe"},
            ["Mansion"] = {"Mansion", "Flamingo Mansion"}, ["Hot Island"] = {"Hot Island", "Hot"},
            ["Cold Island"] = {"Cold Island", "Cold"}, ["Cursed Ship"] = {"Cursed Ship", "CursedShip"},
            ["Usoap Island"] = {"Usoap Island", "Ussop Island"},
        },
        [3] = {
            ["Tiki"] = {"Tiki", "Tiki Outpost"}, ["Mansion"] = {"Mansion", "Floating Turtle Mansion"},
            ["Cake Island"] = {"Cake Island", "CakeIsland"},
        },
    }
    local function liveIslandDestination(sea, destination)
        local map = workspace:FindFirstChild("Map")
        if not map then return nil end
        local aliases = IslandAliases[sea] and IslandAliases[sea][destination] or {destination}
        local wanted = {}
        for _, alias in ipairs(aliases) do wanted[normalizeMapName(alias)] = true end
        local function candidate(obj)
            if not wanted[normalizeMapName(obj.Name)] then return nil end
            local part = obj:IsA("BasePart") and obj or (obj:IsA("Model")
                and (obj:FindFirstChild("SpawnPoint", true)
                    or obj:FindFirstChild("Entrance", true)
                    or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
            if part and part:IsA("BasePart") and part.Position.Magnitude > 20 then
                return CFrame.new(part.Position + Vector3.new(0, 10, 0))
            end
            return nil
        end
        for _, obj in ipairs(map:GetChildren()) do
            local cf = candidate(obj)
            if cf then return cf end
            if obj:IsA("Folder") then
                for _, nested in ipairs(obj:GetChildren()) do
                    cf = candidate(nested)
                    if cf then return cf end
                end
            end
        end
        return nil
    end

    npcRegionRoute = function(sea, name)
        local record = NpcData[name]
        local region = record and record.regions and record.regions[sea]
        if not region then return nil end
        if isCanonicalPlace() and IslandData[sea] then return IslandData[sea][region] end
        if sea == 2 and region == "Cursed Ship" then
            return liveIslandDestination(sea, region) or IslandData[2][region]
        end
        return liveIslandDestination(sea, region)
    end

    LocalActions.lp_select_island = function(value)
        LocalRuntime.selectedIsland = tostring(value or "")
        return true
    end

    LocalActions.lp_teleport_island = function()
        local sea = currentSeaLocal()
        local routes = IslandData[sea]
        local destination = LocalRuntime.selectedIsland
        local target = isCanonicalPlace() and routes and routes[destination]
            or liveIslandDestination(sea, destination)
        if not target and sea == 2 and destination == "Cursed Ship" then
            target = CFrame.new(902, 125, 33072)
        end
        if not target then
            lpTravelStatus("No live island route: " .. tostring(destination))
            reportRecord("Teleport / " .. tostring(destination), "RECUSADO",
                "Sem marcador carregado no mapa; PlaceId=" .. tostring(game.PlaceId)
                    .. " | Sea=" .. tostring(sea))
            lpNotify("Island marker not loaded for " .. tostring(destination) .. ".")
            return false
        end
        reportRecord("Teleport / Rota", "OBSERVADO",
            "Sea=" .. tostring(sea) .. " | ilha=" .. tostring(destination)
                .. " | origem=" .. (isCanonicalPlace() and "coordenada salva" or "mapa carregado"))

        task.spawn(function()
            if sea == 2 and destination == "Cursed Ship" then
                if not enterCursedShip() then
                    return
                end
                if not isCanonicalPlace() then
                    target = liveIslandDestination(sea, destination)
                        or CFrame.new(902, 125, 33072)
                end
            elseif sea == 1 and destination == "Underwater City" then
                if not requestIslandEntrance(destination,
                    Vector3.new(61163.8516, 11.6797, 1819.7842)) then
                    return
                end
            end
            travelTo(target, destination)
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

            local core = island:FindFirstChild("Core")
            local relic = core and core:FindFirstChild("PrehistoricRelic")
            local skull = relic and relic:FindFirstChild("Skull")
            local anchor = skull and (skull:IsA("BasePart") and skull
                or (skull:IsA("Model") and (skull.PrimaryPart
                    or skull:FindFirstChildWhichIsA("BasePart", true))))
            if not anchor then
                local spawn = island:FindFirstChild("SpawnPoint", true)
                anchor = spawn and spawn:IsA("BasePart") and spawn or nil
            end
            if anchor then
                travelTo(CFrame.new(anchor.Position + Vector3.new(0, 5, 0)), "Prehistoric Island")
            else
                lpTravelStatus("Prehistoric Island found, safe anchor missing")
                lpNotify("Island loaded, but the relic/spawn anchor is not available.")
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

-- ============================================================
-- SETTING FARM
-- Options that need an active farming target are stored here for the Farming
-- runtime. Independent actions run only while their own toggle is enabled.
-- ============================================================
local SettingFarmActions = {}
local FarmRuntime = {
    clickRunning = false,
    busoCharacterConnection = nil,
    healthCharacterConnection = nil,
    healthConnection = nil,
    healthBindNonce = 0,
    lowHealthTriggered = false,
}

do
    local function farmNotify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tave Hub - Setting Farm",
                Text = tostring(message), Duration = 3
            })
        end)
    end

    local function activateBuso()
        if not session.alive or not FarmSettings.autoBuso then return end
        local character = LocalPlayer.Character
        if not character then return end
        local marker = character:FindFirstChild("HasBuso")
        if marker and (not marker:IsA("BoolValue") or marker.Value) then return end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        if remote then
            pcall(function() remote:InvokeServer("Buso") end)
        end
    end

    local function bindHealth(character)
        FarmRuntime.healthBindNonce = FarmRuntime.healthBindNonce + 1
        local nonce = FarmRuntime.healthBindNonce
        if FarmRuntime.healthConnection then
            FarmRuntime.healthConnection:Disconnect()
            FarmRuntime.healthConnection = nil
        end
        FarmRuntime.lowHealthTriggered = false
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 5)
        if not humanoid or not FarmSettings.lowHealthTeleport
            or nonce ~= FarmRuntime.healthBindNonce then return end

        FarmRuntime.healthConnection = humanoid.HealthChanged:Connect(function(health)
            if not session.alive or not FarmSettings.lowHealthTeleport then return end
            local threshold = humanoid.MaxHealth * FarmSettings.healthPercent / 100
            if health > threshold then
                FarmRuntime.lowHealthTriggered = false
                return
            end
            if health <= 0 or FarmRuntime.lowHealthTriggered then return end
            FarmRuntime.lowHealthTriggered = true
            task.spawn(function()
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root or not root.Parent then return end
                local target = root.CFrame + Vector3.new(0, FarmSettings.teleportY, 0)
                if QuickRuntime.smoothTeleport then
                    QuickRuntime.smoothTeleport(target)
                end
            end)
        end)
    end

    SettingFarmActions.farm_auto_click = function(enabled)
        FarmSettings.autoClick = enabled == true
        if not enabled or FarmRuntime.clickRunning then return true end
        FarmRuntime.clickRunning = true
        task.spawn(function()
            while session.alive and FarmSettings.autoClick do
                local character = LocalPlayer.Character
                local tool = character and character:FindFirstChildOfClass("Tool")
                if tool and tool.Enabled then
                    pcall(function() tool:Activate() end)
                end
                task.wait(tool and 0.20 or 0.45)
            end
            FarmRuntime.clickRunning = false
        end)
        return true
    end

    SettingFarmActions.farm_auto_buso = function(enabled)
        FarmSettings.autoBuso = enabled == true
        if FarmRuntime.busoCharacterConnection then
            FarmRuntime.busoCharacterConnection:Disconnect()
            FarmRuntime.busoCharacterConnection = nil
        end
        if enabled then
            FarmRuntime.busoCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
                task.delay(1, activateBuso)
            end)
            task.spawn(activateBuso)
        end
        return true
    end

    SettingFarmActions.farm_low_health = function(enabled)
        FarmSettings.lowHealthTeleport = enabled == true
        if FarmRuntime.healthCharacterConnection then
            FarmRuntime.healthCharacterConnection:Disconnect()
            FarmRuntime.healthCharacterConnection = nil
        end
        if enabled then
            FarmRuntime.healthCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
                task.spawn(bindHealth, character)
            end)
            task.spawn(bindHealth, LocalPlayer.Character)
        else
            bindHealth(nil)
        end
        return true
    end

    local passiveFlags = {
        farm_dragon_storm = "dragonStormAura",
        farm_auto_observation = "autoObservation",
        farm_auto_v4 = "autoV4", farm_auto_v3 = "autoV3",
        farm_dodge_mobs = "autoDodgeMobs",
        farm_safe_items = "safeTweenWithItems",
        farm_portal = "usePortalTeleport", farm_bring_mob = "bringMob",
        farm_reset_teleport = "resetTeleport",
    }
    for action, key in pairs(passiveFlags) do
        SettingFarmActions[action] = function(enabled)
            FarmSettings[key] = enabled == true
            if enabled then
                farmNotify("Setting saved; this automation is not connected in this build yet.")
            end
            return true
        end
    end

    local sliders = {
        farm_health_percent = {key = "healthPercent", min = 0, max = 100},
        farm_teleport_y = {key = "teleportY", min = 0, max = 2000},
        farm_hop_minutes = {key = "hopMinutes", min = 1, max = 60},
        farm_bring_count = {key = "bringMobCount", min = 1, max = 10},
        farm_tween_speed = {key = "tweenSpeed", min = 50, max = 400},
    }
    for action, spec in pairs(sliders) do
        SettingFarmActions[action] = function(value)
            local number = math.clamp(tonumber(value) or spec.min, spec.min, spec.max)
            FarmSettings[spec.key] = number
            if spec.key == "tweenSpeed" then
                MovementConfig.speed = number
            end
            return true
        end
    end

    FarmRuntime.stop = function()
        FarmRuntime.healthBindNonce = FarmRuntime.healthBindNonce + 1
        FarmSettings.autoClick = false
        FarmSettings.autoBuso = false
        FarmSettings.lowHealthTeleport = false
        if FarmRuntime.busoCharacterConnection then FarmRuntime.busoCharacterConnection:Disconnect() end
        if FarmRuntime.healthCharacterConnection then FarmRuntime.healthCharacterConnection:Disconnect() end
        if FarmRuntime.healthConnection then FarmRuntime.healthConnection:Disconnect() end
    end
end

-- Skill choices and hold times are read by the Farming combat controller.
local SkillActions = {}
do
    local selectActions = {
        skill_select_melee = "Melee",
        skill_select_sword = "Sword",
        skill_select_gun = "Gun",
        skill_select_fruit = "Blox Fruit",
    }
    for action, category in pairs(selectActions) do
        SkillActions[action] = function(letter, enabled)
            local selected = SkillSettings.selected[category]
            if selected[letter] == nil then return false end
            selected[letter] = enabled == true
            return true
        end
    end

    SkillActions.skill_fast_no_hold = function(enabled)
        SkillSettings.fastNoHold = enabled == true
        return true
    end

    local delayActions = {
        skill_delay_melee_z = {"Melee", "Z"},
        skill_delay_melee_x = {"Melee", "X"},
        skill_delay_melee_c = {"Melee", "C"},
        skill_delay_sword_z = {"Sword", "Z"},
        skill_delay_sword_x = {"Sword", "X"},
        skill_delay_gun_z = {"Gun", "Z"},
        skill_delay_gun_x = {"Gun", "X"},
        skill_delay_fruit_z = {"Blox Fruit", "Z"},
        skill_delay_fruit_x = {"Blox Fruit", "X"},
        skill_delay_fruit_c = {"Blox Fruit", "C"},
        skill_delay_fruit_v = {"Blox Fruit", "V"},
        skill_delay_fruit_f = {"Blox Fruit", "F"},
    }
    for action, spec in pairs(delayActions) do
        SkillActions[action] = function(value)
            SkillSettings.holdSeconds[spec[1]][spec[2]] = math.clamp(tonumber(value) or 0.5, 0, 5)
            return true
        end
    end

    SkillSettings.getSelected = function(category)
        local result = {}
        local selected = SkillSettings.selected[category]
        if not selected then return result end
        for _, letter in ipairs({"Z", "X", "C", "V", "F"}) do
            if selected[letter] then
                table.insert(result, {
                    key = letter,
                    hold = SkillSettings.fastNoHold and 0.05
                        or SkillSettings.holdSeconds[category][letter],
                })
            end
        end
        return result
    end
end

-- ============================================================
-- FARMING RUNTIME
-- One worker owns movement and attacks. It only targets live, loaded models.
-- ============================================================
local FarmingActions = {}
local FarmingRuntime = {
    mode = nil, nonce = 0, status = "Farm: Idle", lastSkillAt = 0,
    skillIndex = 0, missingSince = nil, hopAttempted = false,
    inputWarningShown = false, inputUnsupported = false,
    target = nil,
}

do
    local targetGroups = {
        ["Farm Katakuri"] = {"Cake Prince", "Dough King", "Katakuri"},
        ["Farm Bone"] = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy", "Possessed Mummy"},
        ["Farm Tyrant"] = {"Tyrant of the Skies", "Tyrant"},
    }
    local materialGroups = {
        ["Vampire Fang"] = {"Vampire"},
        ["Fish Tail"] = {"Fishman Warrior", "Fishman Commando", "Fishman Raider", "Fishman Captain"},
        ["Gunpowder"] = {"Pistol Billionaire"},
        ["Bones"] = targetGroups["Farm Bone"],
        ["Mystic Droplet"] = {"Sea Soldier", "Water Fighter"},
        ["Conjured Cocoa"] = {"Chocolate Bar Battler", "Sweet Thief", "Candy Rebel"},
        ["Dragon Scale"] = {"Dragon Crew Warrior", "Dragon Crew Archer"},
        ["Leather"] = {"Pirate", "Brute", "Mercenary"},
        ["Ectoplasm"] = {"Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer"},
        ["Mini Tusk"] = {"Mythological Pirate"},
        ["Magma Ore"] = {"Military Soldier", "Military Spy", "Magma Ninja", "Lava Pirate"},
        ["Scrap Metal"] = {"Pirate", "Brute", "Mercenary"},
        ["Angel Wings"] = {"God's Guard"},
        ["Radioactive Material"] = {"Factory Staff"},
        ["Demonic Wisp"] = {"Demonic Soul"},
    }

    local function setFarmStatus(message)
        local value = "Farm: " .. tostring(message)
        if FarmingRuntime.status == value then return end
        reportRecord("Farming / Estado", "OBSERVADO", value)
        FarmingRuntime.status = value
        local label = StatusRuntime.infoLabels.farm_status
        if label and label.Parent then label.Text = value end
    end

    local function farmNotify(message)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Tave Hub - Farming", Text = tostring(message), Duration = 4
            })
        end)
    end

    local function liveEnemy(model)
        if not model:IsA("Model") then return nil, nil end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if humanoid and root and humanoid.Health > 0 then return humanoid, root end
        return nil, nil
    end

    local function findEnemy(mode, playerRoot)
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return nil, nil, nil end
        local names = mode == "main" and targetGroups[FarmingConfig.method]
            or (mode == "material" and materialGroups[FarmingConfig.material] or nil)
        local best, bestHumanoid, bestRoot, bestDistance
        for _, model in ipairs(enemies:GetChildren()) do
            local humanoid, root = liveEnemy(model)
            if humanoid then
                local matched = not names
                if names then
                    local low = string.lower(model.Name)
                    for _, alias in ipairs(names) do
                        if string.find(low, string.lower(alias), 1, true) then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    local distance = (root.Position - playerRoot.Position).Magnitude
                    if not bestDistance or distance < bestDistance then
                        best, bestHumanoid, bestRoot, bestDistance = model, humanoid, root, distance
                    end
                end
            end
        end
        return best, bestHumanoid, bestRoot
    end

    local function toolCategory(tool)
        if not tool then return nil end
        local tooltip = string.lower(tostring(tool.ToolTip or ""))
        if tooltip == "melee" then return "Melee" end
        if tooltip == "sword" then return "Sword" end
        if tooltip == "gun" then return "Gun" end
        if tooltip == "blox fruit" or tooltip == "blox fruits" then return "Blox Fruit" end
        return nil
    end

    local function equippedTool(category)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not character or not humanoid then return nil, nil end
        local equipped = character:FindFirstChildOfClass("Tool")
        if not category then return equipped, toolCategory(equipped) end
        if equipped and toolCategory(equipped) == category then return equipped, category end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and (not category or toolCategory(tool) == category) then
                    pcall(function() humanoid:EquipTool(tool) end)
                    local active = character:FindFirstChildOfClass("Tool")
                    if active then return active, toolCategory(active) end
                end
            end
        end
        return category == nil and equipped or nil, category
    end

    local function sendSkillKey(letter, hold)
        if FarmingRuntime.inputUnsupported then return false end
        if UserInputService:GetFocusedTextBox() then return nil end
        local key = Enum.KeyCode[letter]
        if not key then return false end

        -- Executor key input is optional; Tool:Activate remains the fallback.
        if typeof(keypress) == "function" and typeof(keyrelease) == "function" then
            local code = string.byte(letter)
            local ok = pcall(keypress, code)
            if ok then
                task.wait(math.max(0.05, hold))
                pcall(keyrelease, code)
                return true
            end
        end
        local ok, virtualInput = pcall(function()
            return UserInputService:CreateVirtualInput()
        end)
        if ok and virtualInput then
            local sent = pcall(function() virtualInput:SendKey(true, key, false) end)
            if sent then
                task.wait(math.max(0.05, hold))
                pcall(function() virtualInput:SendKey(false, key, false) end)
                return true
            end
        end
        local managerOk, manager = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        if managerOk and manager then
            local sent = pcall(function() manager:SendKeyEvent(true, key, false, game) end)
            if sent then
                task.wait(math.max(0.05, hold))
                pcall(function() manager:SendKeyEvent(false, key, false, game) end)
                return true
            end
        end
        FarmingRuntime.inputUnsupported = true
        return false
    end

    local function attack(tool, category)
        if not tool or not tool.Parent then return end
        if not FarmSettings.autoClick and tool.Enabled then
            pcall(function() tool:Activate() end)
        end
        if not category or os.clock() - FarmingRuntime.lastSkillAt < 1.25 then return end
        local skills = SkillSettings.getSelected(category)
        if #skills == 0 then return end
        FarmingRuntime.skillIndex = FarmingRuntime.skillIndex % #skills + 1
        local skill = skills[FarmingRuntime.skillIndex]
        FarmingRuntime.lastSkillAt = os.clock()
        local result = sendSkillKey(skill.key, skill.hold)
        if result == false and FarmingRuntime.inputUnsupported
            and not FarmingRuntime.inputWarningShown then
            FarmingRuntime.inputWarningShown = true
            farmNotify("Selected skills need key input support from this executor; M1 remains active.")
        end
    end

    local function worker(mode, nonce)
        while session.alive and FarmingRuntime.mode == mode and FarmingRuntime.nonce == nonce do
            local character = LocalPlayer.Character
            local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
            local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not playerRoot or not playerHumanoid or playerHumanoid.Health <= 0 then
                setFarmStatus("waiting for character")
                task.wait(1)
                continue
            end
            if FarmRuntime.lowHealthTriggered and FarmSettings.lowHealthTeleport then
                setFarmStatus("low health protection active")
                task.wait(0.6)
                continue
            end

            local enemy = FarmingRuntime.target
            local enemyHumanoid, enemyRoot
            local enemiesFolder = workspace:FindFirstChild("Enemies")
            if enemy and enemiesFolder and enemy.Parent == enemiesFolder then
                enemyHumanoid, enemyRoot = liveEnemy(enemy)
            end
            if not enemyHumanoid then
                enemy, enemyHumanoid, enemyRoot = findEnemy(mode, playerRoot)
                FarmingRuntime.target = enemy
            end
            if not enemy then
                if not FarmingRuntime.missingSince then FarmingRuntime.missingSince = os.clock() end
                local wanted = mode == "main" and FarmingConfig.method
                    or (mode == "material" and FarmingConfig.material or "a loaded enemy")
                setFarmStatus("waiting for " .. wanted)
                if mode == "main" and FarmingConfig.method == "Farm Katakuri"
                    and FarmingConfig.hopFindKatakuri and not FarmingRuntime.hopAttempted
                    and os.clock() - FarmingRuntime.missingSince >= FarmSettings.hopMinutes * 60 then
                    FarmingRuntime.hopAttempted = true
                    StatusActions.hop_server()
                end
                task.wait(1.2)
                continue
            end
            FarmingRuntime.missingSince = nil
            local distance = (playerRoot.Position - enemyRoot.Position).Magnitude
            local height = FarmingConfig.ignoreKatakuriAttack and mode == "main"
                and FarmingConfig.method == "Farm Katakuri" and 18 or 7
            local engageDistance = mode == "main"
                and math.clamp(FarmingConfig.auraDistance / 15, 8, 28) or 20
            if distance > engageDistance then
                setFarmStatus("going to " .. enemy.Name)
                local destination = CFrame.new(enemyRoot.Position + Vector3.new(0, height, 8))
                QuickRuntime.smoothTeleport(destination)
                task.wait(0.15)
                continue
            end

            local category = nil
            if mode == "mastery" then
                local threshold = enemyHumanoid.MaxHealth * FarmingConfig.masteryHealth / 100
                category = enemyHumanoid.Health <= threshold
                    and FarmingConfig.masteryCategory or "Melee"
            end
            local tool, actualCategory = equippedTool(category)
            if not tool then
                setFarmStatus("equip a " .. tostring(category or "weapon") .. " Tool")
                task.wait(0.65)
                continue
            end
            setFarmStatus("attacking " .. enemy.Name)
            attack(tool, actualCategory)
            task.wait(0.30)
        end
    end

    local function setMode(mode, enabled)
        if enabled then
            if FarmingRuntime.mode and FarmingRuntime.mode ~= mode then
                farmNotify("Stop " .. FarmingRuntime.mode .. " farm before starting another.")
                return false
            end
            if FarmingRuntime.mode == mode then return true end
            FarmingRuntime.mode = mode
            FarmingRuntime.nonce = FarmingRuntime.nonce + 1
            FarmingRuntime.missingSince = nil
            FarmingRuntime.hopAttempted = false
            FarmingRuntime.inputWarningShown = false
            FarmingRuntime.inputUnsupported = false
            FarmingRuntime.target = nil
            setFarmStatus("starting " .. mode)
            local nonce = FarmingRuntime.nonce
            task.spawn(function()
                local ok, err = pcall(worker, mode, nonce)
                if not ok and FarmingRuntime.nonce == nonce then
                    FarmingRuntime.mode = nil
                    setFarmStatus("error: " .. tostring(err):sub(1, 80))
                    farmNotify("Farm error: " .. tostring(err):sub(1, 110))
                end
            end)
        elseif FarmingRuntime.mode == mode then
            FarmingRuntime.mode = nil
            FarmingRuntime.nonce = FarmingRuntime.nonce + 1
            FarmingRuntime.target = nil
            QuickRuntime.stopSmoothTeleport()
            setFarmStatus("Idle")
        end
        return true
    end

    FarmingActions.farming_method = function(value)
        if not targetGroups[value] then return false end
        FarmingConfig.method = value
        FarmingRuntime.missingSince = nil
        FarmingRuntime.target = nil
        return true
    end
    FarmingActions.farming_aura_distance = function(value)
        FarmingConfig.auraDistance = math.clamp(tonumber(value) or 300, 0, 1000)
        return true
    end
    FarmingActions.farming_ignore_katakuri = function(enabled)
        FarmingConfig.ignoreKatakuriAttack = enabled == true
        return true
    end
    FarmingActions.farming_hop_katakuri = function(enabled)
        FarmingConfig.hopFindKatakuri = enabled == true
        return true
    end
    FarmingActions.farming_auto_quest = function(enabled)
        if enabled then
            farmNotify("Quest routing is not connected for these bosses yet.")
            return false
        end
        FarmingConfig.autoQuest = false
        return true
    end
    FarmingActions.farming_main = function(enabled) return setMode("main", enabled) end
    FarmingActions.farming_mastery_method = function(value)
        FarmingConfig.masteryCategory = value
        return true
    end
    FarmingActions.farming_mastery_health = function(value)
        FarmingConfig.masteryHealth = math.clamp(tonumber(value) or 40, 0, 100)
        return true
    end
    FarmingActions.farming_mastery = function(enabled) return setMode("mastery", enabled) end
    FarmingActions.farming_material_select = function(value)
        if not materialGroups[value] then return false end
        FarmingConfig.material = value
        FarmingRuntime.missingSince = nil
        FarmingRuntime.target = nil
        return true
    end
    FarmingActions.farming_material = function(enabled) return setMode("material", enabled) end

    FarmingRuntime.stop = function()
        FarmingRuntime.mode = nil
        FarmingRuntime.nonce = FarmingRuntime.nonce + 1
        FarmingRuntime.target = nil
        if QuickRuntime.stopSmoothTeleport then QuickRuntime.stopSmoothTeleport() end
    end
end


-- Volcano automation uses live objects and confirms crafting through inventory.
local VolcanoActions = {}
local volcanoLastStatus
local volcanoMaterialCounts
local function volcanoStatus(message)
    local label = StatusRuntime.infoLabels.volcano_status
    if label and label.Parent then label.Text = "Volcano: " .. tostring(message) end
    if volcanoLastStatus ~= message then
        volcanoLastStatus = message
        reportRecord("Volcano / Estado", "OBSERVADO", tostring(message))
    end
end
VolcanoActions.volcano_craft = function()
    if LocalActions.lp_current_sea() ~= 3 then
        volcanoStatus("Volcanic Magnet requires Third Sea")
        return false
    end
    local counts = volcanoMaterialCounts and volcanoMaterialCounts(true)
    if not counts then
        volcanoStatus("inventory unavailable; cannot verify magnet recipe")
        return false
    end
    if counts.magnet >= 1 then
        volcanoStatus("Volcanic Magnet already owned")
        return true
    end
    if counts.scrap < 10 or counts.ember < 15 then
        volcanoStatus("materials needed: Scrap " .. counts.scrap .. "/10, Ember " .. counts.ember .. "/15")
        return false
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("CommF_")
    if not remote then
        volcanoStatus("CommF_ missing")
        reportRecord("Volcano / Magnet", "ERRO", "CommF_ nao encontrado")
        return false
    end
    local ok, result = pcall(function()
        return remote:InvokeServer("CraftItem", "Craft", "Volcanic Magnet")
    end)
    if not ok or result == false then
        volcanoStatus("craft rejected: " .. tostring(result):sub(1, 70))
        reportRecord("Volcano / Magnet", "RECUSADO", tostring(result))
        return false
    end
    task.wait(0.8)
    local after = volcanoMaterialCounts(true)
    local crafted = after and after.magnet > counts.magnet
    reportRecord("Volcano / Magnet", crafted and "CONFIRMADO" or "OBSERVADO",
        "resposta=" .. tostring(result) .. " | magnet=" .. tostring(after and after.magnet or "?")
            .. " | materiais antes=" .. counts.scrap .. "/" .. counts.ember)
    volcanoStatus(crafted and "Volcanic Magnet crafted" or "craft sent; inventory not yet confirmed")
    return crafted == true
end

-- Bounded Volcano worker: runs only while an event option is enabled.
local VolcanoRuntime = {
    flags = {}, running = false, nonce = 0, island = nil, lastCraft = -math.huge,
    prompted = false, promptedAt = 0, visited = {}, arrivedIsland = false,
    lastPickupScan = -math.huge, lastEgg = 0, pickup = nil,
    counts = nil, countsAt = 0, questAt = -math.huge, lastBoatBuy = -math.huge,
    dragonCheckAt = -math.huge, dragonQuest = nil, dragonMisses = 0,
    lastEmberRemote = -math.huge, lastEmberScan = -math.huge, emberPart = nil,
    lastTreeAttack = -math.huge, treeIndex = 1,
    questSwitchAt = 0, questPhase = "dragon", dojoBelt = nil, lastDojoAt = -math.huge,
    boatDirection = -1, boatLastPosition = nil, boatLastProgress = 0, boatStalls = 0,
    pressed = {}, inputMode = nil,
    golemWeapon = "Melee", lavaWeapon = "Gun", method = "Normal",
}
local function volcanoEnabled()
    local flags = VolcanoRuntime.flags
    return flags.craft or flags.find or flags.event or flags.bone or flags.egg
        or flags.fully or flags.dojo or flags.dragon or false
end
local function volcanoPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end
local function volcanoTool(category)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and string.lower(tostring(tool.ToolTip)) == string.lower(category) then return tool end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, candidate in ipairs(backpack:GetChildren()) do
            if candidate:IsA("Tool") and string.lower(tostring(candidate.ToolTip)) == string.lower(category) then
                humanoid:EquipTool(candidate)
                return character:FindFirstChildOfClass("Tool")
            end
        end
    end
    return nil
end
local function volcanoMove(part, label, offset)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not part then volcanoStatus("waiting for character/" .. label); return false end
    if (root.Position - part.Position).Magnitude > 11 then
        volcanoStatus("going to " .. label)
        return QuickRuntime.smoothTeleport(CFrame.new(part.Position + (offset or Vector3.new(0, 7, 3))))
    end
    return true
end
local function volcanoIsland()
    local map = workspace:FindFirstChild("Map")
    return map and (map:FindFirstChild("PrehistoricIsland")
        or map:FindFirstChild("Prehistoric Island"))
end
local function volcanoRelicPart(island)
    local core = island and island:FindFirstChild("Core")
    local relic = core and core:FindFirstChild("PrehistoricRelic")
    local skull = relic and relic:FindFirstChild("Skull")
    return skull and volcanoPart(skull) or nil
end
volcanoMaterialCounts = function(force)
    if not force and VolcanoRuntime.counts
        and os.clock() - VolcanoRuntime.countsAt < 4 then
        return VolcanoRuntime.counts
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("CommF_")
    if not remote then return nil end
    local ok, inventory = pcall(function() return remote:InvokeServer("getInventory") end)
    if not ok or type(inventory) ~= "table" then return nil end
    local counts = {scrap = 0, ember = 0, magnet = 0, bone = 0, egg = 0}
    for key, item in pairs(inventory) do
        local name, amount
        if type(item) == "table" then
            name = tostring(item.Name or item.name or key)
            amount = tonumber(item.Count or item.count or item.Amount or item.amount or 1) or 0
        elseif type(key) == "string" then
            name, amount = key, tonumber(item) or 0
        end
        if name then
            local low = string.lower(name)
            if low == "scrap metal" then counts.scrap = amount end
            if low == "blaze ember" then counts.ember = amount end
            if low == "volcanic magnet" then counts.magnet = amount end
            if low == "dino bone" or low == "dinosaur bone" then counts.bone = amount end
            if low == "dragon egg" then counts.egg = amount end
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local character = LocalPlayer.Character
    if (backpack and backpack:FindFirstChild("Volcanic Magnet"))
        or (character and character:FindFirstChild("Volcanic Magnet")) then
        counts.magnet = math.max(counts.magnet, 1)
    end
    VolcanoRuntime.counts, VolcanoRuntime.countsAt = counts, os.clock()
    return counts
end
local function volcanoNetFunction(name, argument)
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    local remote = net and net:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteFunction") then return false, "remote unavailable" end
    return pcall(function() return remote:InvokeServer(argument) end)
end
local function volcanoGoTo(position, label)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then volcanoStatus("waiting for character"); return false end
    if (root.Position - position).Magnitude <= 20 then return true end
    volcanoStatus("going to " .. label)
    return QuickRuntime.smoothTeleport(CFrame.new(position))
end
local function volcanoDojo()
    local entrance = Vector3.new(5661.532, 1013.091, -334.965)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position - Vector3.new(5841, 1208, 884)).Magnitude > 450 then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("CommF_")
        if remote then pcall(function() remote:InvokeServer("requestEntrance", entrance) end) end
    end
    return volcanoGoTo(Vector3.new(5864.864, 1209.551, 812.775), "Dragon Hunter")
end
local function volcanoAttack(part, category, model)
    local tool = volcanoTool(category)
    if not tool then
        volcanoStatus("equip a " .. category .. " tool")
        return false
    end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and part then
        pcall(function() root.CFrame = CFrame.lookAt(root.Position, part.Position) end)
    end
    local used = tool.Enabled and pcall(function() tool:Activate() end)
    if model then
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local net = modules and modules:FindFirstChild("Net")
        local attack = net and net:FindFirstChild("RE/RegisterAttack")
        local hit = net and net:FindFirstChild("RE/RegisterHit")
        if attack and hit and attack:IsA("RemoteEvent") and hit:IsA("RemoteEvent")
            and os.clock() - (VolcanoRuntime.lastCombatRemote or -math.huge) >= 0.5 then
            VolcanoRuntime.lastCombatRemote = os.clock()
            local head = model:FindFirstChild("Head") or part
            pcall(function()
                attack:FireServer(0.1)
                hit:FireServer(head, {})
            end)
        end
    end
    return used
end
local function volcanoFarmEnemy(name, stage)
    local enemies = workspace:FindFirstChild("Enemies")
    local target, targetModel, targetHumanoid
    if enemies then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local bestDistance
        for _, model in ipairs(enemies:GetChildren()) do
            if string.find(string.lower(model.Name), string.lower(name), 1, true) then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local part = volcanoPart(model)
                if hum and hum.Health > 0 and part then
                    local dist = root and (part.Position - root.Position).Magnitude or math.huge
                    if not bestDistance or dist < bestDistance then
                        target, targetModel, targetHumanoid, bestDistance = part, model, hum, dist
                    end
                end
            end
        end
    end
    if not target then
        if stage then volcanoGoTo(stage, name .. " spawn") end
        volcanoStatus("waiting for " .. name .. " to load")
        return false
    end
    if not volcanoMove(target, name, Vector3.new(0, 3, 4)) then return false end
    if volcanoAttack(target, "Melee", targetModel) then
        local now = os.clock()
        if VolcanoRuntime.lastEnemy ~= targetModel or targetHumanoid.Health < (VolcanoRuntime.lastEnemyHealth or math.huge) then
            VolcanoRuntime.lastEnemy, VolcanoRuntime.lastEnemyHealth = targetModel, targetHumanoid.Health
            VolcanoRuntime.lastEnemyProgress = now
        elseif now - (VolcanoRuntime.lastEnemyProgress or now) > 18 then
            volcanoStatus("no damage observed on " .. name .. "; check weapon/input")
            return false
        end
        volcanoStatus("attacking " .. name .. " (" .. math.floor(targetHumanoid.Health) .. " HP)")
        return true
    end
    return false
end
local function volcanoQuestText(value, depth)
    if depth > 6 then return "" end
    if type(value) == "string" then return value end
    if type(value) ~= "table" then return "" end
    local best = ""
    for _, child in pairs(value) do
        local found = volcanoQuestText(child, depth + 1)
        if #found > #best then best = found end
        local low = string.lower(found)
        if low:find("hydra enforcer", 1, true) or low:find("venomous assailant", 1, true)
            or (low:find("tree", 1, true) and low:find("destroy", 1, true))
            or low:find("head back", 1, true) then return found end
    end
    return best
end
local function volcanoCollectEmber()
    local now = os.clock()
    if now - VolcanoRuntime.lastEmberRemote >= 2 then
        VolcanoRuntime.lastEmberRemote = now
        local net = ReplicatedStorage:FindFirstChild("Modules")
        net = net and net:FindFirstChild("Net")
        local remote = net and net:FindFirstChild("RE/DragonDojoEmber")
        if remote and remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer() end)
        end
    end
    if now - VolcanoRuntime.lastEmberScan >= 3 then
        VolcanoRuntime.lastEmberScan = now
        VolcanoRuntime.emberPart = nil
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local bestDistance
        -- Scan immediate children and likely ember groups; Azure/Kitsune embers are unrelated.
        local function consider(obj)
            if not obj:IsA("BasePart") then return end
            local low = string.lower(obj.Name)
            if not low:find("ember", 1, true) or low:find("azure", 1, true) then return end
            if obj:FindFirstAncestor("EmberTemplate") then return end
            local dist = root and (root.Position - obj.Position).Magnitude or math.huge
            if dist < 650 and (not bestDistance or dist < bestDistance) then
                VolcanoRuntime.emberPart, bestDistance = obj, dist
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            consider(obj)
            if string.lower(obj.Name):find("ember", 1, true) and obj.Name ~= "EmberTemplate" then
                for _, child in ipairs(obj:GetDescendants()) do consider(child) end
            end
        end
    end
    local ember = VolcanoRuntime.emberPart
    if not ember or not ember.Parent then return false end
    if not volcanoGoTo(ember.Position + Vector3.new(0, 2, 0), "Blaze Ember") then return true end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and typeof(firetouchinterest) == "function" then
        pcall(firetouchinterest, root, ember, 0)
        pcall(firetouchinterest, root, ember, 1)
    end
    volcanoStatus("Blaze Ember contact attempted; checking inventory")
    return true
end
local volcanoTreePoints = {
    Vector3.new(5255.105, 1004.195, 344.770), Vector3.new(5340.358, 1004.195, 362.639),
    Vector3.new(5323.644, 1004.195, 440.716), Vector3.new(5244.362, 1004.195, 422.457),
}
local function volcanoDragonHunterStep()
    local now = os.clock()
    if now - VolcanoRuntime.dragonCheckAt >= 4 then
        VolcanoRuntime.dragonCheckAt = now
        local ok, result = volcanoNetFunction("RF/DragonHunter", {Context = "Check"})
        if not ok then volcanoStatus("Dragon Hunter Check unavailable: " .. tostring(result)); return end
        local found = volcanoQuestText(result, 0)
        if found ~= "" then
            VolcanoRuntime.dragonQuest, VolcanoRuntime.dragonMisses = found, 0
        else
            VolcanoRuntime.dragonMisses = VolcanoRuntime.dragonMisses + 1
            if VolcanoRuntime.dragonMisses >= 2 then VolcanoRuntime.dragonQuest = nil end
        end
    end
    local low = string.lower(tostring(VolcanoRuntime.dragonQuest or ""))
    if low:find("hydra enforcer", 1, true) then
        volcanoFarmEnemy("Hydra Enforcer", Vector3.new(4547.115, 1003.102, 334.195))
    elseif low:find("venomous assailant", 1, true) then
        volcanoFarmEnemy("Venomous Assailant", Vector3.new(4674.927, 1134.827, 996.309))
    elseif low:find("destroy", 1, true) and low:find("tree", 1, true) then
        local point = volcanoTreePoints[VolcanoRuntime.treeIndex]
        if not volcanoGoTo(point + Vector3.new(0, 3, 0), "Hydra trees") then return end
        if now - VolcanoRuntime.lastTreeAttack >= 2 then
            VolcanoRuntime.lastTreeAttack = now
            local tool = volcanoTool("Melee")
            if tool and tool.Enabled then pcall(function() tool:Activate() end) end
            VolcanoRuntime.treeIndex = VolcanoRuntime.treeIndex % #volcanoTreePoints + 1
        end
        volcanoStatus("attacking Hydra trees; awaiting quest progress")
    elseif low:find("head back", 1, true) or low:find("return", 1, true) then
        if not volcanoDojo() then return end
        if now - VolcanoRuntime.questAt >= 8 then
            VolcanoRuntime.questAt = now
            local ok, result = volcanoNetFunction("RF/DragonHunter", {Context = "RequestQuest"})
            reportRecord("Volcano / Dragon Hunter", ok and "OBSERVADO" or "ERRO", tostring(result))
        end
        volcanoStatus("returning to Dragon Hunter")
    elseif now - VolcanoRuntime.questAt >= 8 then
        if not volcanoDojo() then return end
        VolcanoRuntime.questAt = now
        local ok, result = volcanoNetFunction("RF/DragonHunter", {Context = "RequestQuest"})
        reportRecord("Volcano / Dragon Hunter", ok and "OBSERVADO" or "ERRO", tostring(result))
        volcanoStatus(ok and "Dragon Hunter quest requested; awaiting Check" or "Dragon Hunter quest refused")
    else
        volcanoStatus("waiting for Dragon Hunter quest")
    end
    -- The dedicated remote is polled during material farming, even when no visible ember spawns.
    if VolcanoRuntime.flags.craft or VolcanoRuntime.flags.dragon or VolcanoRuntime.flags.fully then
        volcanoCollectEmber()
    end
end
local function volcanoFarmMagnet()
    local counts = volcanoMaterialCounts()
    if not counts then volcanoStatus("inventory unavailable; material farm paused"); return false end
    if counts.magnet >= 1 then
        volcanoStatus("Volcanic Magnet ready")
        return true
    end
    if counts.scrap < 10 then
        volcanoStatus("Scrap Metal " .. counts.scrap .. "/10")
        volcanoFarmEnemy("Forest Pirate", Vector3.new(-13206.452, 425.892, -7964.554))
        return false
    end
    if counts.ember < 15 then
        volcanoStatus("Blaze Ember " .. counts.ember .. "/15")
        volcanoDragonHunterStep()
        return false
    end
    if os.clock() - VolcanoRuntime.lastCraft > 12 then
        VolcanoRuntime.lastCraft = os.clock()
        VolcanoActions.volcano_craft()
    end
    return false
end
local function volcanoDojoQuestStep()
    local belt = string.lower(tostring(VolcanoRuntime.dojoBelt or ""))
    if belt:find("skull slayer", 1, true) or belt == "white" then
        -- Keep farming at Tiki until the quest state actually changes.
        if os.clock() - VolcanoRuntime.lastDojoAt >= 8 then
            VolcanoRuntime.lastDojoAt = os.clock()
            local ok, result = volcanoNetFunction("RF/InteractDragonQuest",
                {NPC = "Dojo Trainer", Command = "CheckQuest"})
            if ok then
                local checked = string.lower(volcanoQuestText(result, 0))
                if checked:find("complete", 1, true) or checked:find("claim", 1, true) then
                    VolcanoRuntime.dojoBelt = "claim"
                    return
                end
            end
        end
        volcanoFarmEnemy("Skull Slayer", Vector3.new(-16759.59, 71.28, 1595.34))
        return
    end
    if not volcanoDojo() then return end
    if os.clock() - VolcanoRuntime.lastDojoAt < 8 then return end
    VolcanoRuntime.lastDojoAt = os.clock()
    local command = belt == "claim" and "ClaimQuest" or "RequestQuest"
    local ok, result = volcanoNetFunction("RF/InteractDragonQuest",
        {NPC = "Dojo Trainer", Command = command})
    if not ok then volcanoStatus("Dojo Trainer " .. command .. " unavailable"); return end
    local response = volcanoQuestText(result, 0)
    local low = string.lower(response)
    reportRecord("Volcano / Dojo Trainer", "OBSERVADO", command .. ": " .. response:sub(1, 110))
    if low:find("skull slayer", 1, true) or low:find("white", 1, true) then
        VolcanoRuntime.dojoBelt = "white"
        volcanoStatus("White belt: farming Skull Slayer")
    elseif belt == "claim" then
        VolcanoRuntime.dojoBelt = nil
        volcanoStatus("Dojo claim attempted; awaiting next quest")
    else
        VolcanoRuntime.dojoBelt = response ~= "" and response or nil
        volcanoStatus("Dojo quest: " .. (response ~= "" and response:sub(1, 65) or "awaiting response"))
    end
end
local function volcanoInputKey(letter, down)
    local code = string.byte(letter)
    if typeof(keypress) == "function" and typeof(keyrelease) == "function" then
        return pcall(down and keypress or keyrelease, code)
    end
    local ok, manager = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and manager then
        return pcall(function()
            manager:SendKeyEvent(down, Enum.KeyCode[letter], false, game)
        end)
    end
    return false
end
local function volcanoBoatKey(letter, down)
    if VolcanoRuntime.pressed[letter] == down then return true end
    if not volcanoInputKey(letter, down) then return false end
    VolcanoRuntime.pressed[letter] = down
    return true
end
local function volcanoReleaseBoatKeys()
    for _, letter in ipairs({"W", "A", "D"}) do
        if VolcanoRuntime.pressed[letter] then
            volcanoInputKey(letter, false)
            VolcanoRuntime.pressed[letter] = false
        end
    end
end
local function volcanoIslandMarker()
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local locations = origin and origin:FindFirstChild("Locations")
    return locations and (locations:FindFirstChild("Prehistoric Island")
        or locations:FindFirstChild("PrehistoricIsland"))
end
local function volcanoOwnedBoat()
    local boats = workspace:FindFirstChild("Boats")
    if not boats then return nil, nil end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best, seat, bestDistance
    for _, boat in ipairs(boats:GetChildren()) do
        local owner = boat:FindFirstChild("Owner")
        local value = owner and owner.Value
        local owned = value == LocalPlayer or tostring(value) == LocalPlayer.Name
            or tonumber(value) == LocalPlayer.UserId
        local candidate = boat:FindFirstChild("VehicleSeat", true)
            or boat:FindFirstChildWhichIsA("VehicleSeat", true)
        if owned and candidate then
            local health = boat:FindFirstChild("Humanoid")
            if not health or not health:IsA("NumberValue") or health.Value > 0 then
                local distance = root and (candidate.Position - root.Position).Magnitude or math.huge
                if not bestDistance or distance < bestDistance then
                    best, seat, bestDistance = boat, candidate, distance
                end
            end
        end
    end
    if bestDistance and bestDistance > 2500 then return nil, nil end
    return best, seat
end
local function volcanoSeaLevel()
    if os.clock() - (VolcanoRuntime.lastSeaCheck or 0) < 6 then
        return VolcanoRuntime.seaLevel
    end
    VolcanoRuntime.lastSeaCheck = os.clock()
    VolcanoRuntime.seaLevel = nil
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local main = gui and gui:FindFirstChild("Main")
    local compass = main and (main:FindFirstChild("Compass", true)
        or main:FindFirstChild("SeaDanger", true))
    if compass then
        for _, obj in ipairs(compass:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local value = string.lower(obj.Text or "")
                if string.find(value, "????", 1, true)
                    or string.find(value, "level 6", 1, true) then
                    VolcanoRuntime.seaLevel = 6
                    break
                end
            end
        end
    end
    return VolcanoRuntime.seaLevel
end
local function volcanoBoatSearch()
    if volcanoIsland() then
        volcanoReleaseBoatKeys()
        volcanoStatus("Prehistoric Island map loaded")
        return
    end
    local boat, seat = volcanoOwnedBoat()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        volcanoReleaseBoatKeys()
        volcanoStatus("waiting for character before sailing")
        return
    end
    if not boat then
        volcanoReleaseBoatKeys()
        local dealer = Vector3.new(-16927.451, 9.086, 433.864)
        if not volcanoGoTo(dealer, "Tiki boat dealer") then return end
        if os.clock() - VolcanoRuntime.lastBoatBuy > 12 then
            VolcanoRuntime.lastBoatBuy = os.clock()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local remote = remotes and remotes:FindFirstChild("CommF_")
            if remote then
                local ok, reply = pcall(function() return remote:InvokeServer("BuyBoat", "Guardian") end)
                reportRecord("Volcano / Barco", ok and "OBSERVADO" or "ERRO", "Guardian: " .. tostring(reply))
            end
        end
        volcanoStatus("waiting for owned Guardian boat")
        return
    end
    if seat.Occupant ~= humanoid then
        volcanoReleaseBoatKeys()
        if seat.Occupant then
            volcanoStatus("owned boat seat occupied by another player")
            return
        end
        if not volcanoGoTo(seat.Position + Vector3.new(0, 3, 0), "owned boat seat") then return end
        pcall(function() seat:Sit(humanoid) end)
        volcanoStatus("boarding owned boat")
        return
    end
    local marker = volcanoIslandMarker()
    if marker then
        local markerPart = volcanoPart(marker)
        local position = markerPart and markerPart.Position
        if not position and marker:IsA("CFrameValue") then position = marker.Value.Position end
        if not position and marker:IsA("Vector3Value") then position = marker.Value end
        if position then
            local distance = (seat.Position - position).Magnitude
            if distance < 300 then
                volcanoReleaseBoatKeys()
                volcanoStatus("island marker reached; waiting for map stream")
                return
            end
            VolcanoRuntime.boatTarget = position
        else
            volcanoReleaseBoatKeys()
            volcanoStatus("island marker found without position; waiting for map")
            return
        end
    else
        VolcanoRuntime.boatTarget = nil
    end
    local x = seat.Position.X
    if x < -60000 then VolcanoRuntime.boatDirection = 1 end
    if x > -29000 then VolcanoRuntime.boatDirection = -1 end
    local desired = VolcanoRuntime.boatTarget
        and Vector3.new(VolcanoRuntime.boatTarget.X - x, 0,
            VolcanoRuntime.boatTarget.Z - seat.Position.Z)
        or Vector3.new(VolcanoRuntime.boatDirection, 0, 0)
    if desired.Magnitude > 0.1 then desired = desired.Unit end
    local look = seat.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.1 then
        volcanoReleaseBoatKeys()
        volcanoStatus("boat heading unavailable")
        return
    end
    flat = flat.Unit
    local alignment = flat:Dot(desired)
    local turn = alignment < 0.95 and flat:Cross(desired).Y or 0
    if alignment < -0.95 then turn = -1 end
    local left, right = turn > 0.08, turn < -0.08
    if not volcanoBoatKey("A", left) or not volcanoBoatKey("D", right)
        or not volcanoBoatKey("W", true) then
        volcanoReleaseBoatKeys()
        volcanoStatus("boat input unavailable on this executor")
        return
    end
    local now = os.clock()
    if not VolcanoRuntime.boatLastPosition or now - VolcanoRuntime.boatLastProgress > 12 then
        if VolcanoRuntime.boatLastPosition
            and (seat.Position - VolcanoRuntime.boatLastPosition).Magnitude < 30 then
            volcanoReleaseBoatKeys()
            VolcanoRuntime.boatStalls = VolcanoRuntime.boatStalls + 1
            VolcanoRuntime.boatDirection = -VolcanoRuntime.boatDirection
            VolcanoRuntime.boatLastPosition, VolcanoRuntime.boatLastProgress = seat.Position, now
            volcanoStatus(VolcanoRuntime.boatStalls < 3 and "boat stalled; changing course"
                or "boat cannot advance; check sea obstacles or executor input")
            return
        end
        VolcanoRuntime.boatStalls = 0
        VolcanoRuntime.boatLastPosition, VolcanoRuntime.boatLastProgress = seat.Position, now
    end
    volcanoStatus((volcanoSeaLevel() == 6 and "sailing in Danger 6" or "sailing toward Danger 6")
        .. " | X=" .. tostring(math.floor(x)))
end
local function volcanoPickup(island)
    local now = os.clock()
    if now - VolcanoRuntime.lastPickupScan < 2.5 then
        local saved = VolcanoRuntime.pickup
        if saved and saved.Parent then return saved end
        return nil
    end
    VolcanoRuntime.lastPickupScan = now
    VolcanoRuntime.pickup = nil
    for _, obj in ipairs(island:GetDescendants()) do
        local low = string.lower(obj.Name):gsub("[%s_%-]", "")
        local bone = (VolcanoRuntime.flags.bone or (VolcanoRuntime.flags.fully
            and not VolcanoRuntime.flags.ignoreBone)) and (low == "dinobone" or low == "dinosaurbone")
        local egg = (VolcanoRuntime.flags.egg or VolcanoRuntime.flags.fully) and low == "dragonegg"
        if (bone or egg) and (not VolcanoRuntime.visited[obj]
            or now - VolcanoRuntime.visited[obj] > 15) and volcanoPart(obj) then
            VolcanoRuntime.pickup = obj
            break
        end
    end
    return VolcanoRuntime.pickup
end
local function volcanoStep()
    if LocalActions.lp_current_sea() ~= 3 then
        volcanoReleaseBoatKeys()
        volcanoStatus("Third Sea required")
        return
    end
    local full = VolcanoRuntime.flags.fully
    local island = volcanoIsland()
    if not island and (VolcanoRuntime.flags.craft or (full and not VolcanoRuntime.flags.ignoreCraft)) then
        volcanoReleaseBoatKeys()
        if not volcanoFarmMagnet() then return end
    end
    if not island then
        VolcanoRuntime.island, VolcanoRuntime.prompted, VolcanoRuntime.visited = nil, false, {}
        VolcanoRuntime.pickup, VolcanoRuntime.arrivedIsland = nil, false
        if full or VolcanoRuntime.flags.find then
            volcanoBoatSearch()
        elseif VolcanoRuntime.flags.dragon and VolcanoRuntime.flags.dojo then
            volcanoReleaseBoatKeys()
            if os.clock() - VolcanoRuntime.questSwitchAt > 30 then
                VolcanoRuntime.questPhase = VolcanoRuntime.questPhase == "dragon" and "dojo" or "dragon"
                VolcanoRuntime.questSwitchAt = os.clock()
            end
            if VolcanoRuntime.questPhase == "dojo" then
                volcanoDojoQuestStep()
            else
                volcanoDragonHunterStep()
            end
        elseif VolcanoRuntime.flags.dragon then
            volcanoReleaseBoatKeys()
            volcanoDragonHunterStep()
        elseif VolcanoRuntime.flags.dojo then
            volcanoReleaseBoatKeys()
            volcanoDojoQuestStep()
        else
            volcanoReleaseBoatKeys()
            volcanoStatus("waiting for Prehistoric Island")
        end
        return
    end
    volcanoReleaseBoatKeys()
    if VolcanoRuntime.island ~= island then
        VolcanoRuntime.island, VolcanoRuntime.prompted, VolcanoRuntime.visited = island, false, {}
        VolcanoRuntime.arrivedIsland, VolcanoRuntime.pickup = false, nil
        VolcanoRuntime.lastPickupScan, VolcanoRuntime.lastEgg = -math.huge, 0
        reportRecord("Volcano / Ilha", "CONFIRMADO", "PrehistoricIsland carregada em workspace.Map")
    end
    if (full or VolcanoRuntime.flags.find) and not VolcanoRuntime.arrivedIsland then
        local part = volcanoRelicPart(island)
        local spawn = island:FindFirstChild("SpawnPoint", true)
        if not part and spawn and spawn:IsA("BasePart") then part = spawn end
        if not part then
            volcanoStatus("island found; relic/spawn anchor not loaded")
            return
        end
        if not volcanoMove(part, "Prehistoric Island") then return end
        VolcanoRuntime.arrivedIsland = true
        reportRecord("Volcano / Chegada", "CONFIRMADO", "Ancora da ilha alcancada")
    end
    local pickup = (full or VolcanoRuntime.flags.bone or VolcanoRuntime.flags.egg)
        and volcanoPickup(island) or nil
    if pickup then
        local part = volcanoPart(pickup)
        if part then
            if not volcanoMove(part, pickup.Name) then return end
            if not QuickRuntime.smoothTeleport(CFrame.new(part.Position + Vector3.new(0, 2, 0))) then
                return
            end
            VolcanoRuntime.visited[pickup], VolcanoRuntime.pickup = os.clock(), nil
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and typeof(firetouchinterest) == "function" then
                pcall(firetouchinterest, root, part, 0)
                pcall(firetouchinterest, root, part, 1)
            end
            local low = string.lower(pickup.Name):gsub("[%s_%-]", "")
            if low == "dragonegg" and os.clock() - VolcanoRuntime.lastEgg > 15 then
                local modules = ReplicatedStorage:FindFirstChild("Modules")
                local net = modules and modules:FindFirstChild("Net")
                local remote = net and net:FindFirstChild("RE/CollectedDragonEgg")
                if remote and remote:IsA("RemoteEvent") then
                    VolcanoRuntime.lastEgg = os.clock()
                    pcall(function() remote:FireServer() end)
                end
            end
            reportRecord("Volcano / Coleta", "OBSERVADO", "Contato tentado com " .. pickup.Name
                .. "; inventario ainda nao confirmado")
            volcanoStatus("collection attempted: " .. pickup.Name)
            return
        end
    end
    if full or VolcanoRuntime.flags.event then
        local enemies = workspace:FindFirstChild("Enemies")
        local target, category, label, targetModel
        local core = island:FindFirstChild("Core")
        local rocks = core and core:FindFirstChild("VolcanoRocks")
        local relicPart = volcanoRelicPart(island)
        if enemies then
            for _, obj in ipairs(enemies:GetChildren()) do
                if string.find(string.lower(obj.Name), "lava golem", 1, true) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local part = volcanoPart(obj)
                    if hum and hum.Health > 0 and part and relicPart
                        and (part.Position - relicPart.Position).Magnitude < 220 then
                        target, category, label, targetModel = part, VolcanoRuntime.golemWeapon, "Lava Golem", obj
                        break
                    end
                end
            end
        end
        if not target and rocks then
            for _, obj in ipairs(rocks:GetDescendants()) do
                if string.lower(obj.Name) == "volcanorock" and obj:IsA("BasePart") then
                    local c = obj.Color
                    local layer = obj:FindFirstChild("VFXLayer")
                    local at = layer and layer:FindFirstChild("At0")
                    local glow = at and at:FindFirstChild("Glow")
                    local active = false
                    if glow then pcall(function() active = glow.Enabled == true end) end
                    if active or (math.abs(c.R - 185/255) < 0.08
                        and math.abs(c.G - 53/255) < 0.08) then
                        target, category, label = obj, VolcanoRuntime.lavaWeapon, "lava rock"
                        break
                    end
                end
            end
        end
        if not target and enemies then
            for _, obj in ipairs(enemies:GetChildren()) do
                if string.find(string.lower(obj.Name), "lava golem", 1, true) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local part = volcanoPart(obj)
                    if hum and hum.Health > 0 and part then
                        target, category, label, targetModel = part, VolcanoRuntime.golemWeapon, "Lava Golem", obj
                        break
                    end
                end
            end
        end
        if target then
            if not volcanoMove(target, label, Vector3.new(0, 3, 4)) then return end
            if volcanoAttack(target, category, targetModel) then
                volcanoStatus("attacking " .. label .. " with " .. category)
            end
            return
        end
        if not pickup and (not VolcanoRuntime.prompted or os.clock() - VolcanoRuntime.promptedAt > 25) then
            local relic = core and core:FindFirstChild("PrehistoricRelic")
            local skull = relic and relic:FindFirstChild("Skull")
            local skullPart = skull and volcanoPart(skull)
            if skullPart then
                local prompt, interactionPart = nil, skullPart
                for _, obj in ipairs(relic:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        prompt = obj
                        if obj.Parent and obj.Parent:IsA("BasePart") then
                            interactionPart = obj.Parent
                        end
                        break
                    elseif obj:IsA("TouchTransmitter") and obj.Parent
                        and obj.Parent:IsA("BasePart") then
                        interactionPart = obj.Parent
                    elseif obj:IsA("BasePart")
                        and string.find(string.lower(obj.Name), "fossil", 1, true) then
                        interactionPart = obj
                    end
                end
                if not volcanoMove(interactionPart, "Prehistoric Relic") then return end
                local ok, method = false, "none"
                if prompt then
                    method = "prompt"
                    ok = pcall(function()
                        if typeof(fireproximityprompt) == "function" then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(math.max(prompt.HoldDuration, 0.1))
                            prompt:InputHoldEnd()
                        end
                    end)
                elseif typeof(firetouchinterest) == "function" then
                    method = "touch"
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    ok = root ~= nil and pcall(function()
                        firetouchinterest(root, interactionPart, 0)
                        firetouchinterest(root, interactionPart, 1)
                    end)
                else
                    method = "walk"
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:MoveTo(interactionPart.Position)
                        ok = true
                    end
                end
                VolcanoRuntime.prompted, VolcanoRuntime.promptedAt = true, os.clock()
                reportRecord("Volcano / Relic", ok and "OBSERVADO" or "ERRO",
                    "metodo=" .. method .. " | inicio do evento depende de confirmacao no jogo")
                volcanoStatus(ok and "relic interaction attempted" or "relic interaction unavailable")
                return
            end
            volcanoStatus("relic skull not loaded")
            return
        end
    end
    volcanoStatus("island loaded; waiting for event objects")
end
local function volcanoSetFlag(flag, enabled)
    if enabled and LocalActions.lp_current_sea() ~= 3 then
        volcanoStatus("Third Sea required for " .. flag)
        return false
    end
    if enabled and FarmingRuntime.mode then
        volcanoStatus("stop Farming before Volcano automation")
        return false
    end
    VolcanoRuntime.flags[flag] = enabled == true
    if not (VolcanoRuntime.flags.find or VolcanoRuntime.flags.fully) then
        volcanoReleaseBoatKeys()
    end
    if volcanoEnabled() and not VolcanoRuntime.running then
        VolcanoRuntime.running = true
        VolcanoRuntime.nonce = VolcanoRuntime.nonce + 1
        local nonce = VolcanoRuntime.nonce
        task.spawn(function()
            while session.alive and VolcanoRuntime.nonce == nonce and volcanoEnabled() do
                local ok, err = pcall(volcanoStep)
                if not ok then
                    volcanoStatus("error: " .. tostring(err):sub(1, 90))
                    reportRecord("Volcano / Worker", "ERRO", tostring(err))
                    break
                end
                task.wait(VolcanoRuntime.method == "Fast" and 0.55 or 1.2)
            end
            if VolcanoRuntime.nonce == nonce then
                VolcanoRuntime.running = false
                volcanoReleaseBoatKeys()
            end
        end)
    elseif not volcanoEnabled() then
        VolcanoRuntime.nonce = VolcanoRuntime.nonce + 1
        VolcanoRuntime.running = false
        volcanoReleaseBoatKeys()
        QuickRuntime.stopSmoothTeleport()
        volcanoStatus("idle")
    end
    return true
end
for action, flag in pairs({
    volcano_auto_craft="craft", volcano_auto_find="find", volcano_auto_event="event",
    volcano_auto_bone="bone", volcano_auto_egg="egg", volcano_fully="fully",
    volcano_ignore_craft="ignoreCraft", volcano_ignore_bone="ignoreBone",
    volcano_dojo_quest="dojo", volcano_dragon_hunter="dragon",
}) do
    VolcanoActions[action] = function(enabled) return volcanoSetFlag(flag, enabled) end
end
VolcanoActions.volcano_golem_weapon = function(value) VolcanoRuntime.golemWeapon = value; return true end
VolcanoActions.volcano_lava_weapon = function(value) VolcanoRuntime.lavaWeapon = value; return true end
VolcanoActions.volcano_golem_method = function(value) VolcanoRuntime.method = value; return true end
VolcanoRuntime.stop = function()
    VolcanoRuntime.flags = {}
    VolcanoRuntime.nonce = VolcanoRuntime.nonce + 1
    volcanoReleaseBoatKeys()
    QuickRuntime.stopSmoothTeleport()
end

local ActionRegistry = setmetatable(LocalActions, {
    __index = function(_, key)
        return ReportActions[key] or VolcanoActions[key] or FarmingActions[key] or SkillActions[key] or SettingFarmActions[key]
            or QuickActions[key] or StatusActions[key] or ShopActions[key]
    end
})

local PagesData = {
    { name = "Relatorio", sections = {
        { title = "Relatorio da sessao", items = {
            { type = "report_view", text = "Resultados e historico" },
            { type = "button", text = "Copiar Relatorio", action = "report_copy" },
            { type = "button", text = "Exportar TXT", action = "report_export" },
            { type = "button", text = "Atualizar Relatorio", action = "report_refresh" },
            { type = "button", text = "Marcar Novo Teste", action = "report_marker" },
            { type = "button", text = "Limpar Relatorio", action = "report_clear" },
        } },
    } },
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
            { type = "info", text = "Teleport: Ready", infoKey = "teleport_status" },
            { type = "dropdown", text = "Sea (manual if auto fails)", options = { "Auto", "First Sea", "Second Sea", "Third Sea" }, action = "lp_sea_override" },
            { type = "button", text = "Refresh Destinations", action = "lp_refresh_destinations" },
            { type = "dropdown", text = "Select NPC", options = (function() local _, _, list = LocalActions.lp_destination_lists(); return list end)(), action = "lp_select_npc" },
            { type = "button", text = "Teleport To NPC", action = "lp_teleport_npc" },
        } },
        { title = "Island Teleport", items = {
            { type = "dropdown", text = "Select Island", options = (function() local _, list = LocalActions.lp_destination_lists(); return list end)(), action = "lp_select_island" },
            { type = "button", text = "Teleport To Island", action = "lp_teleport_island" },
            { type = "button", text = "Teleport Mirage", action = "lp_teleport_mirage" },
            { type = "button", text = "Teleport Prehistoric Island", action = "lp_teleport_prehistoric" },
        } },
    } },
    { name = "Setting Farm", sections = {
        { title = "Farm Setting", items = {
            { type = "toggle", text = "Auto Click", action = "farm_auto_click" },
            { type = "toggle", text = "Kill Aura With DragonStorm", action = "farm_dragon_storm" },
            { type = "toggle", text = "Auto Turn On Buso", action = "farm_auto_buso" },
            { type = "toggle", text = "Auto Turn On Observation", action = "farm_auto_observation" },
            { type = "toggle", text = "Auto Turn On V4", action = "farm_auto_v4" },
            { type = "toggle", text = "Auto Turn On V3", action = "farm_auto_v3" },
            { type = "toggle", text = "Auto Dodge Skill Mobs", action = "farm_dodge_mobs" },
            { type = "toggle", text = "Teleport Y if low health", action = "farm_low_health" },
            { type = "slider", text = "% Health Player", value = 40, min = 0, max = 100, action = "farm_health_percent" },
            { type = "slider", text = "Distance Teleport Y", value = 800, min = 0, max = 2000, action = "farm_teleport_y" },
            { type = "toggle", text = "Tween Safe if have Items", action = "farm_safe_items" },
            { type = "slider", text = "Time Hop Server", value = 10, min = 1, max = 60, action = "farm_hop_minutes" },
            { type = "toggle", text = "Use Portal Teleport", action = "farm_portal" },
            { type = "slider", text = "Bring Mob Count", value = 2, min = 1, max = 10, action = "farm_bring_count" },
            { type = "toggle", text = "Bring Mob", action = "farm_bring_mob" },
            { type = "toggle", text = "Reset Teleport [Beta]", action = "farm_reset_teleport" },
            { type = "slider", text = "Tween Speed", value = 170, min = 50, max = 400, action = "farm_tween_speed" },
        } },
    } },
    { name = "Hold and Select Skill", sections = {
        { title = "Select Skills", items = {
            { type = "skill_multi", text = "Select Skills Melee", options = { "Z", "X", "C" }, action = "skill_select_melee" },
            { type = "skill_multi", text = "Select Skills Sword", options = { "Z", "X" }, action = "skill_select_sword" },
            { type = "skill_multi", text = "Select Skills Gun", options = { "Z", "X" }, action = "skill_select_gun" },
            { type = "skill_multi", text = "Select Skills Blox Fruit", options = { "Z", "X", "C", "V", "F" }, action = "skill_select_fruit" },
        } },
        { title = "Hold Skills", items = {
            { type = "toggle", text = "Use skill fast dont hold", action = "skill_fast_no_hold" },
            { type = "slider", text = "Set Delay Melee Z", value = 0.5, min = 0, max = 5, action = "skill_delay_melee_z" },
            { type = "slider", text = "Set Delay Melee X", value = 0.5, min = 0, max = 5, action = "skill_delay_melee_x" },
            { type = "slider", text = "Set Delay Melee C", value = 0.5, min = 0, max = 5, action = "skill_delay_melee_c" },
            { type = "slider", text = "Set Delay Sword Z", value = 0.5, min = 0, max = 5, action = "skill_delay_sword_z" },
            { type = "slider", text = "Set Delay Sword X", value = 0.5, min = 0, max = 5, action = "skill_delay_sword_x" },
            { type = "slider", text = "Set Delay Gun Z", value = 0.5, min = 0, max = 5, action = "skill_delay_gun_z" },
            { type = "slider", text = "Set Delay Gun X", value = 0.5, min = 0, max = 5, action = "skill_delay_gun_x" },
            { type = "slider", text = "Set Delay Blox Fruit Z", value = 0.5, min = 0, max = 5, action = "skill_delay_fruit_z" },
            { type = "slider", text = "Set Delay Blox Fruit X", value = 0.5, min = 0, max = 5, action = "skill_delay_fruit_x" },
            { type = "slider", text = "Set Delay Blox Fruit C", value = 0.5, min = 0, max = 5, action = "skill_delay_fruit_c" },
            { type = "slider", text = "Set Delay Blox Fruit V", value = 0.5, min = 0, max = 5, action = "skill_delay_fruit_v" },
            { type = "slider", text = "Set Delay Blox Fruit F", value = 0.5, min = 0, max = 5, action = "skill_delay_fruit_f" },
        } },
    } },
    { name = "Farming", sections = {
        { title = "Farming", items = {
            { type = "info", text = "Farm: Idle", infoKey = "farm_status" },
            { type = "dropdown", text = "Select Method Farm", options = { "Farm Katakuri", "Farm Bone", "Farm Tyrant" }, action = "farming_method" },
            { type = "slider", text = "Distance Farm Aura", value = 300, min = 0, max = 1000, action = "farming_aura_distance" },
            { type = "toggle", text = "Ignore Attack Katakuri", action = "farming_ignore_katakuri" },
            { type = "toggle", text = "Hop Find Katakuri", action = "farming_hop_katakuri" },
            { type = "toggle", text = "Auto Quest [Katakuri/Bone/Tyrant]", action = "farming_auto_quest" },
            { type = "toggle", text = "Start Farm", action = "farming_main" },
        } },
        { title = "Mastery Farm", items = {
            { type = "dropdown", text = "Select Method Farm Mastery", options = { "Melee", "Sword", "Gun", "Blox Fruit" }, action = "farming_mastery_method" },
            { type = "slider", text = "Health %", value = 40, min = 0, max = 100, action = "farming_mastery_health" },
            { type = "toggle", text = "Farm Mastery", action = "farming_mastery" },
        } },
        { title = "Farming Material", items = {
            { type = "dropdown", text = "Select Material", options = { "Vampire Fang", "Fish Tail", "Gunpowder", "Bones", "Mystic Droplet", "Conjured Cocoa", "Dragon Scale", "Leather", "Ectoplasm", "Mini Tusk", "Magma Ore", "Scrap Metal", "Angel Wings", "Radioactive Material", "Demonic Wisp" }, action = "farming_material_select" },
            { type = "toggle", text = "Farm Material", action = "farming_material" },
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
            { type = "toggle", text = "Ignore Craft Volcanic Magnet", action = "volcano_ignore_craft" },
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
            { type = "info", text = "Volcano: status da automação", infoKey = "volcano_status" },
            { type = "info", text = "Magnet: 10 Scrap Metal + 15 Blaze Ember. Sea search uses your boat in Danger 6." },
            { type = "button", text = "Craft Volcanic Magnet", action = "volcano_craft" },
            { type = "toggle", text = "Auto Crafting Volcanic Magnet", action = "volcano_auto_craft" },
            { type = "toggle", text = "Auto Quest Dojo Trainer (White)", action = "volcano_dojo_quest" },
            { type = "toggle", text = "Auto Quest Dragon Hunter", action = "volcano_dragon_hunter" },
            { type = "dropdown", text = "Select Weapon Kill Golem", options = { "Melee", "Sword", "Gun", "Blox Fruit" }, action = "volcano_golem_weapon" },
            { type = "dropdown", text = "Select Weapons Fix Lava", options = { "Gun", "Melee", "Sword", "Blox Fruit" }, action = "volcano_lava_weapon" },
            { type = "dropdown", text = "Select Method Kill Golem", options = { "Normal", "Fast" }, action = "volcano_golem_method" },
            { type = "toggle", text = "Auto Find Prehistoric Island (boat / Danger 6)", action = "volcano_auto_find" },
            { type = "toggle", text = "Auto Event Prehistoric Island", action = "volcano_auto_event" },
            { type = "toggle", text = "Auto Collect Bone", action = "volcano_auto_bone" },
            { type = "toggle", text = "Auto Collect Egg", action = "volcano_auto_egg" },
        } },
        { title = "Fully Volcano", items = {
            { type = "toggle", text = "Ignore Craft Volcanic Magnet", action = "volcano_ignore_craft" },
            { type = "toggle", text = "Ignore Collect Bone", action = "volcano_ignore_bone" },
            { type = "toggle", text = "Fully Event Prehistoric Island (parcial)", action = "volcano_fully" },
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
    trackExternal(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale))
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
    Text = '<font color="#975CFF"><b>Tave Hub</b></font>  - Blox Fruit (Volcano 7.11)',
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
    -- The whole row is clickable, including the label (important on touch screens).
    local hitArea = New("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, row)
    hitArea.MouseButton1Click:Connect(function()
        enabled = not enabled
        fill.Visible = enabled
        row:SetAttribute("Value", enabled)

        if callback then
            local ok, result = pcall(callback, enabled)
            if not ok or result == false then
                enabled = not enabled
                fill.Visible = enabled
                row:SetAttribute("Value", enabled)
                if not ok then
                    warn("Tave Hub toggle " .. text .. ": " .. tostring(result))
                    if string.find(text, "Farm", 1, true) then
                        local label = StatusRuntime.infoLabels.farm_status
                        if label and label.Parent then
                            label.Text = "Farm: toggle error: " .. tostring(result):sub(1, 70)
                        end
                    end
                end
            end
        elseif string.find(text, "Farm", 1, true) then
            local label = StatusRuntime.infoLabels.farm_status
            if label and label.Parent then label.Text = "Farm: " .. text .. " unavailable" end
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
    if callback then pcall(callback, current) end

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

local function AddSkillMultiDropdown(parent, text, options, callback)
    local closedHeight, optionHeight = 40, 28
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, closedHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, parent)
    local row = RowBase(holder, closedHeight)
    local label = New("TextLabel", {
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -58, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. ": None",
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
        Text = "▼", TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold, TextSize = 11,
        AutoButtonColor = false
    }, row)
    Corner(arrow, 4)
    Stroke(arrow, Theme.Accent, 1.4, 0)

    local menuHeight = #options * optionHeight + 6
    local menu = New("Frame", {
        Position = UDim2.fromOffset(0, closedHeight + 3),
        Size = UDim2.new(1, 0, 0, menuHeight),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Visible = false
    }, holder)
    Corner(menu, 5)
    Stroke(menu, Theme.AccentDark, 1, 0.35)
    local list = New("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundTransparency = 1
    }, menu)
    New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)

    local selected, buttons = {}, {}
    local opened = false
    local function updateLabel()
        local values = {}
        for _, option in ipairs(options) do
            if selected[option] then table.insert(values, option) end
            local button = buttons[option]
            if button then
                button.Text = (selected[option] and "  ☑ " or "  ☐ ") .. option
            end
        end
        local value = #values > 0 and table.concat(values, ", ") or "None"
        label.Text = text .. ": " .. value
        holder:SetAttribute("Value", value)
    end
    local function setOpen(value)
        opened = value == true
        menu.Visible = opened
        arrow.Text = opened and "▲" or "▼"
        holder.Size = UDim2.new(1, 0, 0,
            opened and (closedHeight + menuHeight + 5) or closedHeight)
    end
    for index, option in ipairs(options) do
        local button = New("TextButton", {
            Size = UDim2.new(1, 0, 0, optionHeight - 1),
            BackgroundColor3 = Theme.Row,
            BorderSizePixel = 0,
            Text = "  ☐ " .. option,
            TextColor3 = Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = index
        }, list)
        Corner(button, 4)
        buttons[option] = button
        button.MouseButton1Click:Connect(function()
            local nextValue = not selected[option]
            if callback then
                local ok, result = pcall(callback, option, nextValue)
                if not ok or result == false then return end
            end
            selected[option] = nextValue
            updateLabel()
        end)
    end
    updateLabel()
    arrow.MouseButton1Click:Connect(function() setOpen(not opened) end)
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.X < arrow.AbsolutePosition.X then
                setOpen(not opened)
            end
        end
    end)
    UIControls[text] = {
        Holder = holder,
        GetValue = function()
            local result = {}
            for _, option in ipairs(options) do
                if selected[option] then table.insert(result, option) end
            end
            return result
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

    trackExternal(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.Touch and (activeInput == input or activeInput == nil) then
            setFromX(input.Position.X)
        end
    end))

    trackExternal(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            activeInput = nil
        end
    end))

    setValue(currentValue, false)
    return row
end

local function ItemMatches(item, query)
    if query == "" then return true end
    local hay = string.lower(item.text or "")
    return string.find(hay, query, 1, true) ~= nil
end


local function AddReportView(parent)
    local holder = New("Frame", {Size = UDim2.new(1, 0, 0, 300), BackgroundTransparency = 1}, parent)
    local feedback = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1,
        Text = "Copie o relatorio ou exporte TXT para a pasta do executor.",
        TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    local scroll = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 252),
        BackgroundColor3 = Theme.Row, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
    }, holder)
    local label = New("TextLabel", {
        Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -22, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        Text = "", RichText = false, TextWrapped = true, TextColor3 = Theme.Text,
        Font = Enum.Font.Code, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, scroll)
    ReportRuntime.label, ReportRuntime.feedback = label, feedback
    reportRefresh()
    return holder
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
            local actionName = pageData.name .. " / " .. item.text
            local rawCallback = item.action and ActionRegistry[item.action] or nil
            local callback = rawCallback
            if pageData.name ~= "Relatorio" and item.type ~= "info" and item.type ~= "report_view" then
                ReportRuntime.functions[actionName] = {
                    status = rawCallback and "NAO TESTADA" or "NAO IMPLEMENTADA", detail = ""
                }
                callback = function(...)
                    return reportInvoke(actionName, item.type, rawCallback, ...)
                end
            end
            if item.type == "report_view" then
                obj = AddReportView(page)
            elseif item.type == "button" then
                obj = AddButton(page, item.text, callback)
            elseif item.type == "toggle" then
                obj = AddToggle(page, item.text, callback, item.default)
            elseif item.type == "info" then
                obj = AddInfo(page, item.text, item.infoKey)
            elseif item.type == "input" then
                obj = AddInput(page, item.text, item.placeholder, callback)
            elseif item.type == "dropdown" then
                obj = AddDropdown(page, item.text, item.options, callback)
            elseif item.type == "skill_multi" then
                obj = AddSkillMultiDropdown(page, item.text, item.options,
                    callback)
            elseif item.type == "slider" then
                obj = AddSlider(page, item.text, item.value, item.min, item.max, function(v)
                    item.value = v
                    if callback then pcall(callback, v) end
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
    ReportRuntime.visible = name == "Relatorio"
    if ReportRuntime.visible then reportRefresh() end
    if name == "Status & Server" then
        StatusRuntime.refreshRemote()
    end
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
    if name == "LocalPlayer" then
        local ok, result = pcall(LocalActions.lp_refresh_destinations)
        if not ok then
            local label = StatusRuntime.infoLabels.teleport_status
            if label and label.Parent then label.Text = "Teleport: Refresh error: " .. tostring(result):sub(1, 80) end
            reportRecord("Teleport / Destinos", "ERRO", tostring(result))
        end
    end
end
StatusRuntime.isVisible = function()
    return SelectedPage == "Status & Server" and Main and Main.Visible
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

    trackExternal(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end))
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

local function stopHub()
    if not session.alive then return end
    reportRecord("Hub / Sessao", "OBSERVADO", "Hub encerrado; exporte antes de fechar para guardar o historico.")
    session.alive = false
    StatusRuntime.spamJoin = false
    StatusRuntime.monitorRunning = false
    QuickRuntime.webhook.monitorRunning = false
    if ShopRuntime.stop then ShopRuntime.stop() end
    if FarmRuntime.stop then FarmRuntime.stop() end
    if FarmingRuntime.stop then FarmingRuntime.stop() end
    if VolcanoRuntime.stop then VolcanoRuntime.stop() end

    if LocalRuntime and LocalRuntime.stop then
        pcall(LocalRuntime.stop)
    end

    QuickRuntime.pvp.walkOnWater = false

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
    for _, connection in ipairs(QuickRuntime.setting.notificationConnections) do
        pcall(function() connection:Disconnect() end)
    end
    if WorldEventCache.addedConnection then
        WorldEventCache.addedConnection:Disconnect()
    end
    if WorldEventCache.removingConnection then
        WorldEventCache.removingConnection:Disconnect()
    end
    if WorldEventCache.workspaceConnection then
        WorldEventCache.workspaceConnection:Disconnect()
    end
    for _, connection in ipairs(session.connections) do
        pcall(function() connection:Disconnect() end)
    end

    for _, group in pairs(QuickRuntime.esp.connections) do
        for _, connection in ipairs(group) do
            pcall(function() connection:Disconnect() end)
        end
    end

    if QuickRuntime.pvp.waterPart then
        QuickRuntime.pvp.waterPart:Destroy()
    end

    if ScreenGui then ScreenGui:Destroy() end
    if sessionEnvironment.__TaveHubSession == session then
        sessionEnvironment.__TaveHubSession = nil
    end
    if sessionEnvironment.__TaveFarmSettings == FarmSettings then
        sessionEnvironment.__TaveFarmSettings = nil
    end
    if sessionEnvironment.__TaveSkillSettings == SkillSettings then
        sessionEnvironment.__TaveSkillSettings = nil
    end
    if sessionEnvironment.__TaveFarmingConfig == FarmingConfig then
        sessionEnvironment.__TaveFarmingConfig = nil
    end
end
session.cleanup = stopHub
CloseBtn.MouseButton1Click:Connect(stopHub)
ScreenGui.Destroying:Connect(stopHub)

reportRecord("Hub / Sessao", "OBSERVADO", "Relatorio 7.11 iniciado; magneto e busca maritima; validacao no Roblox pendente.")
ShowPage("Shop")

-- Populate cheap local status once. Remote status refreshes when its page opens.
pcall(StatusRuntime.updateFast)
task.spawn(function()
    pcall(StatusRuntime.updateWorld)
end)
StatusRuntime.startMonitor()
QuickRuntime.startWebhookMonitor()
QuickRuntime.startGuiKey()

task.defer(function()
    if QuickRuntime.refreshPlayerDropdown then
        QuickRuntime.refreshPlayerDropdown()
    end
end)

print("[Floquitave] Volcano 7.11 loaded - copy/export diagnostics from Relatorio.")
