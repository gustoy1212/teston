-- [[ SOLO LEVELING: DUNGEON DESTROYER V2 ]] --
-- Corrigido: Não ataca mais outros jogadores!

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()

local Window = Library:CreateWindow("Dungeon V2")
local Folder = Window:CreateFolder("Farm Seguro")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    AutoFarm = false,
    AutoChest = false,
    AutoCollect = false,
    DistanciaAtaque = 6,
    IgnorarSummons = true -- Tenta não bater em invocações (sombras)
}

-- FUNÇÃO: É um Player Real?
local function IsRealPlayer(model)
    if Players:GetPlayerFromCharacter(model) then
        return true -- É um jogador
    end
    return false -- É NPC ou Mob
end

-- FUNÇÃO: Ataque
local function AttackTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local root = LocalPlayer.Character.HumanoidRootPart
    local enemyRoot = target.HumanoidRootPart
    
    -- Teleporta para as costas (Backstab)
    root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, Config.DistanciaAtaque)
    
    -- Olha para o inimigo
    root.CFrame = CFrame.new(root.Position, enemyRoot.Position)
    
    -- Clica
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(900, 500))
end

-- Loop Principal
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm then
            pcall(function()
                local closestEnemy = nil
                local shortestDist = 9999
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                
                for _, obj in pairs(Workspace:GetDescendants()) do
                    -- 1. Verifica se tem vida e corpo
                    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                        
                        -- 2. FILTRO DE SEGURANÇA (NOVO)
                        -- Só continua se NÃO for o próprio player E NÃO for outro player
                        if obj.Name ~= LocalPlayer.Name and not IsRealPlayer(obj) then
                            
                            -- 3. Verifica se está vivo
                            if obj.Humanoid.Health > 0 then
                                
                                -- 4. Filtro Opcional: Ignorar Sombras/Pets (pelo nome comum)
                                -- Se quiser bater em tudo que não for player, pode desativar isso
                                local nome = obj.Name:lower()
                                local ehSombra = (nome:find("shadow") or nome:find("igris") or nome:find("tank"))
                                
                                if not (Config.IgnorarSummons and ehSombra) then
                                    local dist = (myPos - obj.HumanoidRootPart.Position).Magnitude
                                    if dist < shortestDist then
                                        shortestDist = dist
                                        closestEnemy = obj
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Ataca o escolhido
                if closestEnemy then
                    AttackTarget(closestEnemy)
                end
            end)
        end
    end
end)

-- Auto Chest (Mantive igual pq estava bom)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoChest then
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    if prompt.Parent then fireproximityprompt(prompt) end
                end
            end
        end
    end
end)

-- Auto Collect
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoCollect then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") or (drop:IsA("Model") and drop:FindFirstChild("Handle")) then
                    local item = drop:FindFirstChild("Handle") or drop
                    if item and item:IsA("BasePart") then
                        item.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("Auto Kill Mobs (Safe) 🛡️", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("Ignorar Sombras/Pets", function(bool)
    Config.IgnorarSummons = bool
end)

Folder:Toggle("Auto Baús 📦", function(bool)
    Config.AutoChest = bool
end)

Folder:Toggle("Auto Drops 🧲", function(bool)
    Config.AutoCollect = bool
end)

Folder:Slider("Distância", 1, 10, 6, function(v) Config.DistanciaAtaque = v end)