-- [[ SOLO LEVELING: DUNGEON SNIPER V6 ]] --
-- Focado na pasta "Workspace.Mobs" descoberta no seu log.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Dungeon Sniper")
local Folder = Window:CreateFolder("Farm Inteligente")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    AutoFarm = false,
    UseSkills = true,     -- Usa E, R, F, Q, C, V
    AutoCollect = false,
    Distancia = 7,        -- Fica um pouco longe pra não tomar dano
    MoveMethod = "Tween"  -- Movimento suave
}

-- FUNÇÃO 1: MOVIMENTO SUAVE (TWEEN)
-- Isso evita que o jogo te puxe de volta (Rubberbanding)
local function MoveTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    -- Se estiver perto, só vira. Se longe, voa.
    if dist > 200 then
        -- Teleporte bruto se for muito longe (pra não demorar anos)
        root.CFrame = targetCFrame
    else
        -- Voo suave (Tween)
        local info = TweenInfo.new(dist / 60, Enum.EasingStyle.Linear) -- Velocidade 60 studs/s
        local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
        tween:Play()
        -- Espera chegar (ou quase)
        task.wait(dist / 70) 
        -- Para o Tween para poder atacar
        if tween.PlaybackState == Enum.PlaybackState.Playing then tween:Cancel() end
        root.CFrame = targetCFrame -- Garante posição final
    end
end

-- FUNÇÃO 2: ENCONTRAR INIMIGO REAL
local function GetTarget()
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossFolder = Workspace:FindFirstChild("Boss") -- Tenta achar pasta Boss tbm
    
    local targets = {}
    
    -- Pega todos os Mobs da pasta correta
    if mobsFolder then
        for _, mob in pairs(mobsFolder:GetChildren()) do
            table.insert(targets, mob)
        end
    end
    
    -- Pega Bosses se houver pasta separada
    if bossFolder then
        for _, boss in pairs(bossFolder:GetChildren()) do
            table.insert(targets, boss)
        end
    end

    -- Se não achou pastas, procura solto mas com filtro rigoroso
    if #targets == 0 then
        for _, obj in pairs(Workspace:GetChildren()) do
            -- Só aceita se tiver Humanoid E NÃO FOR PLAYER
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                if obj.Name ~= LocalPlayer.Name then
                    table.insert(targets, obj)
                end
            end
        end
    end

    -- Retorna o mais próximo
    local nearest = nil
    local minDist = 9999
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, enemy in pairs(targets) do
        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local d = (enemy.HumanoidRootPart.Position - myPos).Magnitude
            if d < minDist then
                minDist = d
                nearest = enemy
            end
        end
    end
    
    return nearest
end

-- FUNÇÃO 3: USAR SKILLS
local function SpamSkills()
    local keys = {"E", "R", "F", "Q", "C", "V", "One", "Two", "Three"}
    for _, key in pairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end
end

-- LOOP PRINCIPAL
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local enemy = GetTarget()
            
            if enemy then
                local root = LocalPlayer.Character.HumanoidRootPart
                local enemyRoot = enemy.HumanoidRootPart
                
                -- Posição de ataque (atrás e um pouco acima pra evitar colisão de chão)
                local attackPos = enemyRoot.CFrame * CFrame.new(0, 2, Config.Distancia)
                
                -- 1. Vai até lá
                MoveTo(attackPos)
                
                -- 2. Trava a mira no inimigo
                root.CFrame = CFrame.new(root.Position, enemyRoot.Position)
                
                -- 3. Tira gravidade pra flutuar
                root.Velocity = Vector3.new(0,0,0)
                
                -- 4. Ataque Básico
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(900, 500))
                
                -- 5. Solta Skills
                if Config.UseSkills then
                    SpamSkills()
                end
            end
        end
    end
end)

-- AUTO COLLECT (Atualizado para o Log)
task.spawn(function()
    while task.wait(1) do
        if Config.AutoCollect then
            -- 1. Pega Drops soltos (Tools)
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                     drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
            
            -- 2. Interage com Portais e Baús
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    -- Filtro: Não interage com players (armaduras têm prompt às vezes)
                    local parentModel = prompt.Parent:FindFirstAncestorWhichIsA("Model")
                    if not parentModel or not Players:GetPlayerFromCharacter(parentModel) then
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("⚔️ Auto Farm (Pasta Mobs)", function(bool)
    Config.AutoFarm = bool
    -- Liga/Desliga Noclip pra não travar na parede
    if bool then
        game:GetService("RunService"):BindToRenderStep("NoClip", 100, function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    else
        game:GetService("RunService"):UnbindFromRenderStep("NoClip")
    end
end)

Folder:Toggle("🔥 Usar Skills (E, R, F...)", function(bool)
    Config.UseSkills = bool
end)

Folder:Toggle("📦 Auto Collect / Baús", function(bool)
    Config.AutoCollect = bool
end)

Folder:Slider("Distância", 1, 15, 7, function(v)
    Config.Distancia = v
end)

Folder:Label("DICA: Deixe seu personagem voando!")