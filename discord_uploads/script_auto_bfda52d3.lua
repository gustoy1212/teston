-- [[ SOLO LEVELING: OMNI-REACH V9 (TITAN MODE) ]] --
-- Hitbox EXTREMA para farmar da base sem erro.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Titan Reach V9")
local Folder = Window:CreateFolder("Hitbox Suprema")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    KillAura = true,      -- Já deixei ligado por padrão
    GiantMobs = true,     -- Já deixei ligado por padrão
    AutoClick = true,     -- Já deixei ligado por padrão
    Range = 2000,         -- Alcance máximo
    HitboxSize = 300      -- Começa gigante (300x300x300)
}

-- FUNÇÃO 1: FORCE TOUCH (Dano Remoto)
local function ForceHit(target)
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool or not tool:FindFirstChild("Handle") then return end
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        firetouchinterest(tool.Handle, target.HumanoidRootPart, 0)
        firetouchinterest(tool.Handle, target.HumanoidRootPart, 1)
    end
end

-- FUNÇÃO 2: ACHAR INIMIGOS
local function GetEnemies()
    local enemies = {}
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

-- LOOP DE ATAQUE
task.spawn(function()
    while task.wait(0.1) do
        if Config.KillAura then
            local enemies = GetEnemies()
            for _, enemy in pairs(enemies) do
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist <= Config.Range then
                        ForceHit(enemy)
                    end
                end
            end
        end
    end
end)

-- LOOP DE HITBOX TITÂNICA (O Segredo)
task.spawn(function()
    while task.wait(0.5) do
        if Config.GiantMobs then
            local enemies = GetEnemies()
            for _, enemy in pairs(enemies) do
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if root then
                    -- APLICA O TAMANHO GIGANTE CONFIGURADO
                    if root.Size.X ~= Config.HitboxSize then
                        root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        root.Transparency = 0.9 -- Quase invisível pra você conseguir ver o jogo
                        root.CanCollide = false
                        root.Color = Color3.fromRGB(255, 0, 0)
                        
                        -- Remove textura pra reduzir lag
                        for _, v in pairs(enemy:GetChildren()) do
                            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                                v.Transparency = 1 
                            elseif v:IsA("Decal") then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- AUTO CLICK
task.spawn(function()
    while task.wait() do
        if Config.AutoClick then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(900, 500))
        end
    end
end)

-- AUTO COLLECT (Puxa drops gigantes também)
task.spawn(function()
    while task.wait(0.5) do
        for _, drop in pairs(Workspace:GetDescendants()) do
            if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                 drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end
end)

-- GUI
Folder:Toggle("💀 ATIVAR TUDO (Farm)", function(bool)
    Config.KillAura = bool
    Config.GiantMobs = bool
    Config.AutoClick = bool
end)

Folder:Slider("TAMANHO HITBOX", 50, 500, 300, function(v)
    Config.HitboxSize = v
end)

Folder:Label("DICA: Se lagar, diminua o tamanho!")
Folder:Label("Fique parado na base e equipe a espada.")