-- [[ SOLO LEVELING: OMNI-REACH V8 (JEDI MODE) ]] --
-- Ataca de longe sem sair do lugar.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Jedi Reach V8")
local Folder = Window:CreateFolder("Ataque Distante")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    KillAura = false,     -- O ataque a distância
    GiantMobs = false,    -- Traz a hitbox deles até você (Visual)
    AutoClick = false,
    Range = 1000          -- Alcance (A dungeon inteira)
}

-- FUNÇÃO 1: FORCE TOUCH (O Segredo do Dano)
-- Isso simula que sua espada tocou no monstro
local function ForceHit(target)
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool or not tool:FindFirstChild("Handle") then return end
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        -- Simula o toque (Início e Fim)
        firetouchinterest(tool.Handle, target.HumanoidRootPart, 0)
        firetouchinterest(tool.Handle, target.HumanoidRootPart, 1)
        
        -- Tenta também nas outras partes do corpo pra garantir
        for _, part in pairs(target:GetChildren()) do
            if part:IsA("BasePart") then
                firetouchinterest(tool.Handle, part, 0)
                firetouchinterest(tool.Handle, part, 1)
            end
        end
    end
end

-- FUNÇÃO 2: ACHAR INIMIGOS (Baseado no Log: Pasta Mobs)
local function GetEnemies()
    local enemies = {}
    
    -- Procura nas pastas certas
    local folders = {Workspace:FindFirstChild("Mobs"), Workspace:FindFirstChild("Boss")}
    for _, folder in pairs(folders) do
        if folder then
            for _, mob in pairs(folder:GetChildren()) do
                if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    table.insert(enemies, mob)
                end
            end
        end
    end
    
    -- Se não achar pasta, procura geral (com filtro anti-player)
    if #enemies == 0 then
        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                if v.Name ~= LocalPlayer.Name and not Players:GetPlayerFromCharacter(v) then
                    table.insert(enemies, v)
                end
            end
        end
    end
    
    return enemies
end

-- LOOP DE ATAQUE (KILL AURA)
task.spawn(function()
    while task.wait(0.1) do -- Velocidade do ataque (0.1 = Rápido)
        if Config.KillAura then
            local enemies = GetEnemies()
            
            for _, enemy in pairs(enemies) do
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    
                    -- Se estiver dentro do alcance configurado
                    if dist <= Config.Range then
                        ForceHit(enemy)
                    end
                end
            end
        end
    end
end)

-- LOOP DE HITBOX GIGANTE (Ajuda o servidor a aceitar o dano)
task.spawn(function()
    while task.wait(1) do
        if Config.GiantMobs then
            local enemies = GetEnemies()
            for _, enemy in pairs(enemies) do
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Deixa o monstro GIGANTE (Invisível pra não poluir a tela)
                    root.Size = Vector3.new(50, 50, 50)
                    root.Transparency = 0.8
                    root.CanCollide = false
                    root.Color = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end)

-- AUTO CLICK (Pra ativar a animação da espada)
task.spawn(function()
    while task.wait() do
        if Config.AutoClick then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(900, 500))
        end
    end
end)

-- GUI
Folder:Toggle("💀 KILL AURA (Force Hit)", function(bool)
    Config.KillAura = bool
end)

Folder:Toggle("🟥 HITBOX GIGANTE (Ajuda Dano)", function(bool)
    Config.GiantMobs = bool
end)

Folder:Toggle("⚔️ AUTO CLICK (Animação)", function(bool)
    Config.AutoClick = bool
end)

Folder:Slider("Alcance (Range)", 50, 2000, 1000, function(v)
    Config.Range = v
end)

Folder:Label("Como usar:")
Folder:Label("1. Fique parado na Base")
Folder:Label("2. Equipe a Espada")
Folder:Label("3. Ative TUDO")