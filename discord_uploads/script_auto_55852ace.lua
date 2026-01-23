--[[
    PAINEL DE CONTROLE - SBL REBORN / ANIME SPIRITS
    Criado para: Delta Mobile (LDPlayer)
    Use o botão no canto da tela para abrir/fechar o menu se ele sumir.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/turtle"))()

local Window = Library:Window("SBL Reborn - Delta Panel")

-- SERVIÇOS E VARIÁVEIS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Remotes = {
    Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"),
    Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"),
    Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"),
}

-- CONTROLES (Flags)
local Flags = {
    AutoFarm = false,
    BringMobs = false,
    AutoSkills = false,
    AutoStats = false,
    AutoQuest = false,
    AutoInteract = false,
    SelectedStat = "Melee",
    AttackDist = 15
}

-- [[ ABA: FARM & COMBATE ]] --
local FarmTab = Window:Tab("Auto Farm")

FarmTab:Toggle("Auto Attack (Kill Aura)", false, function(state)
    Flags.AutoFarm = state
end)

FarmTab:Toggle("Bring Mobs (Puxar Mobs)", false, function(state)
    Flags.BringMobs = state
end)

FarmTab:Slider("Distância do Ataque", 10, 50, 15, function(value)
    Flags.AttackDist = value
end)

FarmTab:Toggle("Auto Skills (Z, X, C, V)", false, function(state)
    Flags.AutoSkills = state
end)

-- [[ ABA: STATUS & PLAYER ]] --
local StatsTab = Window:Tab("Status & Misc")

StatsTab:Dropdown("Escolher Status", {"Melee", "Defense", "Sword", "Fruit"}, function(selected)
    Flags.SelectedStat = selected
end)

StatsTab:Toggle("Auto Upgrade Status", false, function(state)
    Flags.AutoStats = state
end)

StatsTab:Toggle("Auto Interagir (Baús/Portais)", false, function(state)
    Flags.AutoInteract = state
end)

-- [[ LÓGICA DO SCRIPT ]] --

-- 1. LOOP DE COMBATE E BRING
task.spawn(function()
    while task.wait() do
        if Flags.AutoFarm then
            pcall(function()
                -- Tenta atacar
                Remotes.Hit:FireServer()
                
                -- Se Bring Mobs estiver ligado
                if Flags.BringMobs then
                    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if MyRoot then
                        for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                                local MobRoot = mob.HumanoidRootPart
                                local Dist = (MyRoot.Position - MobRoot.Position).Magnitude
                                
                                -- Puxa se estiver perto (raio de 250 studs)
                                if Dist < 250 and Dist > 4 then
                                    MobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -5) -- Coloca na sua frente
                                    mob.Humanoid.WalkSpeed = 0 -- Tenta travar o mob
                                    mob.Humanoid.JumpPower = 0
                                    
                                    -- Tira colisão pra não travar seu boneco
                                    for _, part in pairs(mob:GetChildren()) do
                                        if part:IsA("BasePart") then part.CanCollide = false end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. AUTO SKILLS
task.spawn(function()
    local SkillKeys = {"Z", "X", "C", "V"}
    while task.wait(1) do
        if Flags.AutoSkills then
            for _, key in ipairs(SkillKeys) do
                pcall(function()
                    Remotes.Skill:FireServer(key)
                end)
                task.wait(0.2)
            end
        end
    end
end)

-- 3. AUTO STATS
task.spawn(function()
    while task.wait(0.5) do
        if Flags.AutoStats then
            pcall(function()
                Remotes.Stats:FireServer(Flags.SelectedStat, 1) -- Upa 1 ponto por vez
            end)
        end
    end
end)

-- 4. AUTO INTERACT (BAÚS, PORTAIS, QUESTS)
task.spawn(function()
    while task.wait(1.5) do
        if Flags.AutoInteract then
            pcall(function()
                -- Interagir com ProximityPrompts no Workspace
                for _, prompt in pairs(Workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local parentName = prompt.Parent.Name
                        -- Filtro inteligente baseado no seu LOG
                        if parentName:find("SpawnPoint") or 
                           parentName:find("Portal") or 
                           parentName:find("Quest") or 
                           parentName:find("Chest") then
                            
                            -- Tenta acionar o prompt ignorando o tempo de espera
                            fireproximityprompt(prompt, 0)
                        end
                    end
                end
            end)
        end
    end
end)

-- NOTIFICAÇÃO
Library:DestroyGui() -- Limpa GUIs antigos para não duplicar
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "SBL Script";
    Text = "Painel Carregado! Abra o menu.";
    Duration = 5;
})