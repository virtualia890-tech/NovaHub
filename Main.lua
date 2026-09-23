
Um minuto. Exatamente isso. A base é a versão limpa que a gente combinou. Não vou voltar pra versão antiga, tá? Ou seja, a gente parte da versão enxuta e só aplica o novo visual por cima, sem mexer no que funciona.


Bom dia Paula

Bom dia! Bom dia, Gustavo! Tô aqui. Vamos seguir de onde a gente parou?


Pode criar

Pronto. Usei exatamente a versão 2.7.3x que você enviou como base. O arquivo confirma que essa build já tinha o Teleport Directory e a estrutura principal que a gente queria preservar. 


Baixar Floquitave 2.7.3y — Clean Purple UI

Nessa versão eu fiz a limpeza e o visual juntos, mas de forma conservadora: removi o Auto Mastery duplicado antigo, a página Raids que era só placeholder, o Anti AFK de teste e os painéis de status que ficavam narrando cada passo do farm. A lógica real de farm foi mantida.

O tema principal agora ficou preto/grafite com violeta controlado, mais sóbrio. O próprio arquivo anterior já tinha essa estrutura de temas e o accent configurável, então trabalhei por cima disso sem mudar a arquitetura. 


Também redesenhei a bolinha de minimizar: ela não é mais só um círculo roxo com um F. Agora é um botão escuro, com contorno violeta, um círculo interno e um símbolo F mais discreto com um pequeno detalhe violeta. O quadradinho do logo no topo segue a mesma identidade.

E verifiquei programaticamente que o bloco TeleportToIsland ficou exatamente igual ao da 2.7.3x, então essa limpeza não mexeu no sistema de teleport que você pediu para preservar. 

 


Floquitave_Hub_2.7.3y_CleanPurpleUI.lua
Código


vou testar e falo oq achei

Perfeito, Gustavo. Testa com calma.

Principalmente observa três coisas: se o hub executa normalmente, se a nova aparência/bolinha ficou do jeito que você imaginava e, principalmente, se Teleport, Boss Farm e Mastery continuam funcionando como antes.

Quando puder, me fala o que gostou e o que não gostou. A partir da 2.7.3y a gente vai refinando sem reconstruir tudo de novo.



Biblioteca
/
Floquitave_Hub_2.7.3y_CleanPurpleUI.lua



4881
4882
4883
4884
4885
4886
4887
4888
4889
4890
4891
4892
4893
4894
4895
4896
4897
4898
4899
4900
4901
4902
4903
4904
4905
4906
4907
4908
4909
4910
4911
4912
4913
4914
4915
4916
4917
4918
4919
4920
4921
4922
4923
4924
4925
4926
4927
4928
4929
4930
4931
4932
4933
4934
4935
4936
4937
4938
4939
4940
4941
4942
4943
4944
4945
4946
4947
4948
4949
4950
4951
4952
4953
4954
4955
4956
4957
4958
4959
4960
4961
4962
4963
4964
4965
4966
--[[
        if not me or not destination then return false end
        if MovementService.TeleportPriority then return false end

        MovementService:Stop()
        MovementService.Active = true
        MovementService.DestinationName = label or "Boss"
        MovementService.Status = "Boss travel"
        MovementService:SetCollision(false)

        local target = destination * CFrame.new(0, 12, 0)
        local ok = MovementService:TweenRoot(me, target)

        MovementService:SetCollision(true)
        MovementService.Active = false
        MovementService.Status = ok and "Arrived" or "Failed"
        return ok
    end

    local function travelToStoredBoss(name)
        local destination = nil

        for base,cf in pairs(BOSS_ROUTE) do
            if bossBaseMatches(base, name) then
                destination = cf
                break
            end
        end

        if not destination then
            local model, root = storedBoss(name)
            destination = root and root.CFrame or nil
        end

        if not destination then return false end

        S.Status = "Travelling to boss: " .. name
        statusValue.Text = S.Status
        return bossDirectTravel(destination, "Boss Spawn:" .. name)
    end

    local function bossAttack(target)
        if not bossAlive(target) then return false end

        local tool = GetEquippedTool()
        if not tool or not IsLikelyFightingStyle(tool) then
            tool = EquipFirstTool()
        end
        if not tool then
            S.Status = "Boss found - no fighting style equipped"
            statusValue.Text = S.Status
            return false
        end

        pcall(function()
            tool:Activate()
        end)
        return true
    end

    local function bossMoveAndFight(target)
        if not bossAlive(target) then return false end

        local me = GetCharacterRoot()
        local tr = bossRoot(target)
        if not me or not tr then return false end

        local distance = (me.Position - tr.Position).Magnitude

        if distance > 42 then
            local destination = CFrame.new(
                (tr.CFrame * CFrame.new(0, FarmState.Distance, 0)).Position,
                tr.Position
            )
            bossDirectTravel(destination, "Boss Target:" .. target.Name)
            return true
        end

        if MovementService.TeleportPriority then return false end
            MovementService:Stop()

        -- Keep the player in the same above-target position used by the working
        -- normal/special farms, but without normal-farm target validation.
        pcall(function()
            me.CFrame = CFrame.new(
                (tr.CFrame * CFrame.new(0, FarmState.Distance, 0)).Position,
                tr.Position

