--[[
    SCRIPT PERSONALIZADO PARA SBL REBORN / ANIME SPIRITS
    Baseado no Log: GOD_LOG_154929.txt
    Funcionalidades: Bring Mobs, Auto Farm, Auto Quest, Auto Stats, Auto Skill
]]

-- CONFIGURAÇÕES (Edite aqui se precisar)
_G.Settings = {
    AutoFarm = true,       -- Ativa o sistema de bater e trazer mobs
    BringMobs = true,      -- Traz os mobs até você (Visual/Client) para bater de longe
    AutoQuest = true,      -- Pega missões do NPC 1 ao 11 automaticamente
    AutoStats = true,      -- Upa status automaticamente
    StatsToUp = "Melee",   -- Qual status upar: "Melee", "Defense", "Sword", "Fruit"
    AutoSkill = true,      -- Usa as habilidades Z, X, C, V automaticamente
    AutoInteract = true,   -- Coleta Baús, Checkpoints e Portais
    AttackDistance = 15,   -- Distância para considerar o ataque
}

-- SERVIÇOS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- REFERÊNCIAS DOS REMOTES (Extraídos do seu Log)
local Remotes = {
    [cite_start]Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"), -- [cite: 8]
    [cite_start]Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"), -- [cite: 3]
    [cite_start]Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"), -- [cite: 14]
    [cite_start]Quest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept") -- [cite: 14]
}

-- LISTA DE NPCS IMPORTANTES (Baseado no Log)
local QuestNPCs = {
    "QuestNPC1", "QuestNPC2", "QuestNPC3", "QuestNPC4", "QuestNPC5",
    "QuestNPC6", "QuestNPC7", "QuestNPC8", "QuestNPC9", "QuestNPC10", "QuestNPC11"
}

-- FUNÇÃO: PEGAR MISSÕES E INTERAGIR COM O MUNDO
task.spawn(function()
    while task.wait(2) do
        if _G.Settings.AutoInteract then
            [cite_start]-- Tenta interagir com Checkpoints e Portais [cite: 19]
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local parentName = obj.Parent.Name
                    -- Filtra apenas os prompts que você pediu
                    if parentName:find("SpawnPointCrystal") or 
                       parentName:find("Portal") or 
                       [cite_start]parentName:find("FruitDealer") or -- [cite: 21]
                       [cite_start]parentName:find("Katana") or -- Blacksmith/Loja [cite: 21]
                       [cite_start]parentName:find("RerollStat") then -- Stat Reroll [cite: 22]
                        
                        fireproximityprompt(obj)
                    end
                end
            end
        end

        if _G.Settings.AutoQuest then
            [cite_start]-- Tenta pegar quest nos NPCs de 1 a 11 [cite: 22, 23]
            for _, npcName in pairs(QuestNPCs) do
                local npc = Workspace.ServiceNPCs:FindFirstChild(npcName)
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local prompt = npc.HumanoidRootPart:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        -- Teleporta rapidinho pra pegar a quest se estiver perto (opcional) ou só interage
                        fireproximityprompt(prompt) 
                    end
                end
            end
        end
    end
end)

[cite_start]-- FUNÇÃO: AUTO STATS [cite: 14]
task.spawn(function()
    while task.wait(1) do
        if _G.Settings.AutoStats then
            -- Dispara o evento para alocar pontos. Geralmente o argumento é (StatName, Amount)
            -- Ajuste a quantidade "1" se o jogo permitir mais por vez
            Remotes.Stats:FireServer(_G.Settings.StatsToUp, 1)
        end
    end
end)

[cite_start]-- FUNÇÃO: AUTO SKILL [cite: 3]
task.spawn(function()
    while task.wait(0.5) do
        if _G.Settings.AutoSkill then
            -- Tenta usar todas as teclas de habilidade
            local keys = {"Z", "X", "C", "V"}
            for _, key in pairs(keys) do
                -- Simula o disparo da skill. 
                -- O log mostra RequestAbility, geralmente pede a tecla ou o nome da skill.
                -- Tentando enviar a Tecla como argumento primário, comum nesse tipo de sistema.
                pcall(function()
                    Remotes.Skill:FireServer(key)
                end)
            end
        end
    end
end)

-- FUNÇÃO PRINCIPAL: BRING MOBS + AUTO HIT (FARM)
-- Isso faz os mobs virem até você visualmente para você bater neles sem andar
RunService.Heartbeat:Connect(function()
    if _G.Settings.AutoFarm then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        [cite_start]for _, mob in pairs(Workspace.NPCs:GetChildren()) do -- [cite: 19] Pasta de NPCs identificada no log
            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                
                local mobRoot = mob.HumanoidRootPart
                local distance = (myRoot.Position - mobRoot.Position).Magnitude

                -- LÓGICA DE BRING MOBS (Trazer Mob)
                -- Traz mobs próximos (dentro de 300 studs) para sua frente
                if _G.Settings.BringMobs and distance < 300 and distance > 5 then
                    -- Move o mob para 4 studs na sua frente
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
                    
                    -- Remove a colisão para não te empurrar
                    for _, part in pairs(mob:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end

                [cite_start]-- AUTO HIT (Ataque) [cite: 8]
                -- Se o mob estiver perto o suficiente (seja pq ele veio ou vc foi), ataca
                if (myRoot.Position - mobRoot.Position).Magnitude <= _G.Settings.AttackDistance then
                    -- RequestHit geralmente pede: (Argumentos variam, mas o padrão é nenhum ou o alvo)
                    -- Enviando spam de ataque
                    Remotes.Hit:FireServer()
                end
            end
        end
    end
end)

-- NOTIFICAÇÃO DE INÍCIO
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Script Carregado";
    Text = "Auto Farm e Bring Mobs Ativados!";
    Duration = 5;
})