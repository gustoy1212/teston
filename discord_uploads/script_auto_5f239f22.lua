-- [[ SOLO LEVELING: DUNGEON DESTROYER V1 ]] --
-- Auto-Farm Inteligente baseado no seu Log

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()

local Window = Library:CreateWindow("Dungeon Destroyer")
local Folder = Window:CreateFolder("Principal")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    AutoFarm = false,
    AutoChest = false,
    AutoCollect = false,
    DistanciaAtaque = 6, -- Distância para bater (atrás do mob)
    AttackDelay = 0.1
}

-- FUNÇÃO 1: ATAQUE AUTOMÁTICO (KILL AURA)
local function AttackTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local root = LocalPlayer.Character.HumanoidRootPart
    local enemyRoot = target.HumanoidRootPart
    
    -- 1. Teleporta para trás do inimigo (pra evitar tomar dano de frente)
    root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, Config.DistanciaAtaque)
    
    -- 2. Vira o personagem para olhar pro inimigo
    root.CFrame = CFrame.new(root.Position, enemyRoot.Position)
    
    -- 3. Simula o Clique do Mouse (Ataque)
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(900, 500))
end

-- Loop de Farm
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm then
            pcall(function()
                -- Procura o inimigo mais próximo
                local closestEnemy = nil
                local shortestDist = 9999
                
                for _, obj in pairs(Workspace:GetDescendants()) do
                    -- Filtro Inteligente: Tem Humanoide? Está vivo? Não sou eu?
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                        if obj.Name ~= LocalPlayer.Name and obj.Humanoid.Health > 0 then
                            -- Ignora NPCs aliados (se houver, adicione filtros aqui)
                            
                            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                closestEnemy = obj
                            end
                        end
                    end
                end
                
                -- Se achou inimigo, ataca!
                if closestEnemy then
                    AttackTarget(closestEnemy)
                end
            end)
        end
    end
end)

-- FUNÇÃO 2: ABRIR BAÚS E PORTAIS (AUTO-INTERACT)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoChest then
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    -- Verifica se é um baú ou portal pelo log que você mandou
                    -- O script tenta disparar qualquer prompt próximo para garantir
                    if prompt.Parent then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    end
end)

-- FUNÇÃO 3: PUXAR DROPS (AUTO-COLLECT)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoCollect then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") or (drop:IsA("Model") and drop:FindFirstChild("Handle")) then
                     -- Move o item até o player
                    if drop:FindFirstChild("Handle") then
                        drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    elseif drop:IsA("BasePart") then
                        drop.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end
end)

-- INTERFACE GRÁFICA
Folder:Toggle("Auto Farm (Mobs/Boss) ⚔️", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("Auto Baús/Portais 📦", function(bool)
    Config.AutoChest = bool
end)

Folder:Toggle("Auto Collect Drops 🧲", function(bool)
    Config.AutoCollect = bool
end)

Folder:Slider("Distância do Ataque", 1, 10, 6, function(value)
    Config.DistanciaAtaque = value
end)

Folder:Label("Use com uma arma equipada!")