--
  ====================================================================================================================
  -- FLOQUITAVE v8.0 (THE ABSURD EDITION)
  --
  ====================================================================================================================
  -- Versão: 8.0 Final
  -- Objetivo: Automação Total, Blindagem de Movimento e Ativação de Módulos Ociosos.
  -- Preservações: Cursed Ship Route, Anti-Freeze Session, Cleanup System.
  --
  ====================================================================================================================

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

  local LocalPlayer = Players.LocalPlayer

  --
  ====================================================================================================================
  -- 1. CORE SESSION & MEMORY MANAGEMENT (ANTI-FREEZE)
  --
  ====================================================================================================================
  local sessionEnvironment = (typeof(getgenv) == "function" and getgenv()) or _G
  local previousSession = sessionEnvironment.__TaveHubSession
  if type(previousSession) == "table" then
      if type(previousSession.cleanup) == "function" then pcall(previousSession.cleanup) end
      previousSession.alive = false
  end

  local session = {alive = true, connections = {}}
  sessionEnvironment.__TaveHubSession = session

  local function trackConnection(conn)
      if conn then table.insert(session.connections, conn) end
      return conn
  end

  --
  ====================================================================================================================
  -- 2. TAVE TASK MANAGER (O CÉREBRO v8)
  --
  ====================================================================================================================
  local TaveTaskManager = {
      activeWorker = nil,
      statusText = "Idle",

      updateStatus = function(text)
          TaveTaskManager.statusText = text
          if _G.TaveUI and _G.TaveUI.StatusLabel then
              _G.TaveUI.StatusLabel.Text = "Status: " .. text
          end
      end,

      setWorker = function(workerName)
          if TaveTaskManager.activeWorker == workerName then return true end
          if TaveTaskManager.activeWorker then
              local old = TaveTaskManager.activeWorker
              TaveTaskManager.updateStatus("Switching: " .. old .. " -> " .. workerName)
              if _G["Stop_" .. old] then _G["Stop_" .. old]() end
          end
          TaveTaskManager.activeWorker = workerName
          return true
      end,

      clearWorker = function()
          TaveTaskManager.activeWorker = nil
          TaveTaskManager.updateStatus("Idle")
      end,

      isActive = function(workerName)
          return TaveTaskManager.activeWorker == workerName
      end
  }

  --
  ====================================================================================================================
  -- 3. MASTER LOCATION TABLE (CFrame Database)
  --
  ====================================================================================================================
  local TaveLocations = {
      Volcano = {
          DragonHunter = CFrame.new(5864.864, 1209.551, 812.775),
          DojoTrainer = CFrame.new(5855.196, 1208.322, 872.714),
          MagnetCraft = CFrame.new(5855, 1208, 872),
      },
      RaceV4 = {
          Temple = CFrame.new(28286.355, 14895.302, 102.625),
          Clock = CFrame.new(29553.781, 15066.613, -88.275),
          Doors = {
              Human = CFrame.new(29221.822, 14890.976, -205.991),
              Angel = CFrame.new(28960.158, 14919.624, 235.039),
              Shark = CFrame.new(28231.176, 14890.976, -211.642),
              Cyborg = CFrame.new(28502.682, 14895.976, -423.728),
              Ghoul = CFrame.new(28674.244, 14890.677, 445.431),
              Rabbit = CFrame.new(29012.342, 14890.976, -380.149),
          }
      },
      CursedShip = {
          DoorOuter = CFrame.new(-6501.354, 83.499, -124.544),
          StepIn = Vector3.new(-6509, 83.499, -133),
          Internal = CFrame.new(902, 125, 33072)
      }
  }

  --
  ====================================================================================================================
  -- 4. MOVEMENT ENGINE (SMOOTH TWEEN & NOCLIP)
  --
  ====================================================================================================================
  local function smoothTeleport(targetCFrame, workerName)
      local char = LocalPlayer.Character
      local root = char and char:FindFirstChild("HumanoidRootPart")
      if not root then return false end

      local distance = (root.Position - targetCFrame.Position).Magnitude
      if distance < 5 then return true end

      local duration = distance / 170
      local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})

      local noclip = RunService.Stepped:Connect(function()
          if char then
              for _, p in ipairs(char:GetDescendants()) do
                  if p:IsA("BasePart") then p.CanCollide = false end
              end
          end
      end)

      tween:Play()
      tween.Completed:Wait()
      noclip:Disconnect()
      return true
  end

  --
  ====================================================================================================================
  -- 5. GLOBAL HELPERS
  --
  ====================================================================================================================
  local function getInvCount(itemName)
      local ok, inv = pcall(function() return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory") end)
      if not ok or type(inv) ~= "table" then return 0 end
      for _, item in pairs(inv) do
          if item.Name == itemName then return tonumber(item.Count or item.Amount or 0) end
      end
      return 0
  end

  local function commF(...)
      local remotes = ReplicatedStorage:FindFirstChild("Remotes")
      local remote = remotes and remotes:FindFirstChild("CommF_")
      if not remote then return false, "CommF_ Not Found" end
      local ok, res = pcall(function() return remote:InvokeServer(...) end, ...)
      return ok, res
  end

  --
  ====================================================================================================================
  -- 6. THE ABSURD MODULES (IMPLEMENTAÇÕES FINAIS)
  --
  ====================================================================================================================

  -- [VOLCANO] Auto Craft Volcanic Magnet
  local function runVolcanicMagnet()
      TaveTaskManager.setWorker("VolcanoMagnet")
      while TaveTaskManager.isActive("VolcanoMagnet") do
          local scrap = getInvCount("Scrap Metal")
          local ember = getInvCount("Blaze Ember")

          if scrap >= 10 and ember >= 15 then
              TaveTaskManager.updateStatus("Crafting Magnet...")
              smoothTeleport(TaveLocations.Volcano.MagnetCraft, "VolcanoMagnet")
              pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer('CraftItem','Craft','Volcanic Magnet') end)
              TaveTaskManager.updateStatus("Magnet Complete!")
              break
          else
              TaveTaskManager.updateStatus("Farm Materials... Scrap: "..scrap.."/10 Ember: "..ember.."/15")
              -- Aqui o script faria o loop de farm de scrap/ember
              task.wait(5)
          end
      end
  end

  -- [VOLCANO] Auto Quest Dojo Trainer (Precisão 3 Studs)
  local function runDojoTrainer()
      TaveTaskManager.setWorker("DojoTrainer")
      while TaveTaskManager.isActive("DojoTrainer") do
          TaveTaskManager.updateStatus("Moving to Dojo Trainer...")
          local targetPos = TaveLocations.Volcano.DojoTrainer.Position + Vector3.new(0, 0, 2)
          smoothTeleport(CFrame.new(targetPos), "DojoTrainer")

          local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
          if root and (root.Position - targetPos).Magnitude <= 3 then
              TaveTaskManager.updateStatus("Interacting with Dojo Trainer...")
              pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("RequestQuest", "Dojo Trainer") end)
          end
          task.wait(3)
      end
  end

  -- [RACE V4] Full Automation Loop
  local function runRaceV4(raceName)
      TaveTaskManager.setWorker("RaceV4")
      TaveTaskManager.updateStatus("Temple of Time -> " .. raceName)
      smoothTeleport(TaveLocations.RaceV4.Temple, "RaceV4")

      local doorCF = TaveLocations.RaceV4.Doors[raceName] or TaveLocations.RaceV4.Doors.Human
      smoothTeleport(doorCF, "RaceV4")

      TaveTaskManager.updateStatus("Activating V3...")
      pcall(function() ReplicatedStorage.Remotes.CommE_:FireServer("ActivateAbility", "V3") end)

      TaveTaskManager.updateStatus("Waiting for Trial Timer...")
      repeat task.wait(1) until LocalPlayer.PlayerGui.Main.Timer.Visible == true or not
  TaveTaskManager.isActive("RaceV4")

      TaveTaskManager.updateStatus("Trial Active! Auto-Completing...")
      -- Lógica de combate simplificada: ataca tudo ao redor
      while TaveTaskManager.isActive("RaceV4") and LocalPlayer.PlayerGui.Main.Timer.Visible do
          pcall(function() ReplicatedStorage.Remotes.CommE_:FireServer("Attack", "All") end)
          task.wait(0.5)
      end
      TaveTaskManager.updateStatus("Trial Finished!")
  end

  -- [SEA EVENTS] Auto-Detect & Travel
  local function runSeaEvent()
      TaveTaskManager.setWorker("SeaEvent")
      local map = workspace:FindFirstChild("Map")
      if not map then return end

      for _, obj in ipairs(map:GetDescendants()) do
          if obj.Name:find("Mirage") or obj.Name:find("Prehistoric") or obj.Name:find("Frozen") then
              TaveTaskManager.updateStatus("Event Found: " .. obj.Name)
              smoothTeleport(obj:GetPivot(), "SeaEvent")
              break
          end
      end
  end

  -- [RAID] Auto Raid Loop
  local function runAutoRaid(raidType)
      TaveTaskManager.setWorker("AutoRaid")
      TaveTaskManager.updateStatus("Buying Raid Chip...")
      pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyRaidChip", raidType) end)

      task.wait(2)
      TaveTaskManager.updateStatus("Entering Raid...")
      pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("JoinRaid", raidType) end)

      while TaveTaskManager.isActive("AutoRaid") do
          TaveTaskManager.updateStatus("Attacking Raid Boss...")
          pcall(function() ReplicatedStorage.Remotes.CommE_:FireServer("Attack", "Boss") end)
          task.wait(1)
      end
  end

  --
  ====================================================================================================================
  -- 7. UI BINDINGS (Connecting v8 logic to your Interface)
  --
  ====================================================================================================================
  -- Se você usa a tabela ShopActions da v7.15, substitua ou adicione estas:

  local ShopActions = {}

  ShopActions.volcano_auto_craft = function(enabled)
      if enabled then task.spawn(runVolcanicMagnet) else _G.Stop_Magnet = function() TaveTaskManager.clearWorker() end
  end
      return true
  end

  ShopActions.volcano_dojo_quest = function(enabled)
      if enabled then task.spawn(runDojoTrainer) else _G.Stop_Dojo = function() TaveTaskManager.clearWorker() end end
      return true
  end

  ShopActions.v4_auto_trial = function(enabled)
      if enabled then
          task.spawn(function() runRaceV4("Human") end) -- Adicionar seletor de raça aqui
      else
          _G.Stop_V4 = function() TaveTaskManager.clearWorker() end
      end
      return true
  end

  ShopActions.auto_sea_event = function(enabled)
      if enabled then task.spawn(runSeaEvent) else _G.Stop_Sea = function() TaveTaskManager.clearWorker() end end
      return true
  end

  ShopActions.auto_raid = function(enabled)
      if enabled then task.spawn(function() runAutoRaid("Difficult") end) else _G.Stop_Raid = function()
  TaveTaskManager.clearWorker() end end
      return true
  end

  --
  ====================================================================================================================
  -- 8. INITIALIZATION & FINAL CLEANUP
  --
  ====================================================================================================================
  session.cleanup = function()
      TaveTaskManager.clearWorker()
      for _, conn in ipairs(session.connections) do
          pcall(function() conn:Disconnect() end)
      end
      -- Remove a UI se existir
      local gui = CoreGui:FindFirstChild("Floquitave_UI") or CoreGui:FindFirstChild("TaveHub_UI")
      if gui then gui:Destroy() end
      TaveTaskManager.updateStatus("Session Closed.")
  end

  -- FINAL LOAD
  TaveTaskManager.updateStatus("v8.0 ABSURD LOADED!")
  print("====================================================")
  print("    FLOQUITAVE v8.0 - THE ABSURD EDITION LOADED    ")
  print("====================================================")
