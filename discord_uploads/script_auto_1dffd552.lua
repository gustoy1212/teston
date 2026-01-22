-- [[ SOLO LEVELING: SPEED DEMON V10 ]] --
-- Foco: Matar rápido cortando animações e travando a câmera na base.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Speed Demon V10")
local Folder = Window:CreateFolder("Farm Rápido")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configurações
local Config = {
    AutoFarm = false,
    FastAttack = true,    -- Corta animação pra bater rápido
    BaseCam = true,       -- Trava a câmera onde você ativou
    AutoEquip = true,
    AttackDist = 4        -- Distância pra colar no bicho
}

-- Variável para guardar a posição da câmera
local FixedCamCFrame = nil

-- FUNÇÃO 1: FAST ATTACK (LIQUIDIFICADOR)
-- Acelera a animação de ataque para bater mais vezes por segundo
local function BoostAttackSpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local animator = char.Humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                -- Se for animação de ataque (geralmente tem prioridade alta)
                if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action4 then
                    track:AdjustSpeed(100) -- Acelera 100x
                end
            end
        end
    end
end

-- FUNÇÃO 2: MOVIMENTO INVISÍVEL
local function TeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    -- Deixa invisível pra não poluir sua tela
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 1 end
        if v:IsA("Decal") then v.Transparency = 1 end
    end
    
    -- Tween Rápido (Pra o servidor aceitar a posição)
    local dist = (root.Position - targetCFrame.Position).Magnitude
    if dist > 5 then
        local speed = 80 -- Velocidade alta
        local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
        tween:Play()
        
        -- Enquanto voa, trava a câmera na base se estiver ativado
        if Config.BaseCam and FixedCamCFrame then
            Camera.CFrame = FixedCamCFrame
        end
        
        -- Espera chegar (quase)
        task.wait(dist/speed)
    end
    
    root.CFrame = targetCFrame
    root.Velocity = Vector3.zero -- Para de escorregar
end

-- FUNÇÃO 3: AUTO EQUIPAR (TECLA 1)
local function EquipWeapon()
    if not Config.AutoEquip then return end
    local char = LocalPlayer.Character
    if char and not char:FindFirstChildWhichIsA("Tool") then
        -- Tenta apertar "1"
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.One, false, game)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.One, false, game)
    end
end

-- FUNÇÃO 4: ACHAR INIMIGO (PRIORIDADE MOBS)
local function GetTarget()
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossFolder = Workspace:FindFirstChild("Boss")
    local targets = {}
    
    if mobsFolder then for _,m in pairs(mobsFolder:GetChildren()) do table.insert(targets, m) end end
    if bossFolder then for _,b in pairs(bossFolder:GetChildren()) do table.insert(targets, b) end end
    
    -- Se não achar nada nas pastas, procura geral
    if #targets == 0 then
        for _,v in pairs(Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) and v.Name ~= LocalPlayer.Name then
                table.insert(targets, v)
            end
        end
    end
    
    local nearest = nil
    local minDist = 9999
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, e in pairs(targets) do
        if e:FindFirstChild("Humanoid") and e.Humanoid.Health > 0 and e:FindFirstChild("HumanoidRootPart") then
            local d = (e.HumanoidRootPart.Position - myPos).Magnitude
            if d < minDist then
                minDist = d
                nearest = e
            end
        end
    end
    return nearest
end

-- LOOP PRINCIPAL (FARM)
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm and LocalPlayer.Character then
            -- 1. Trava Câmera na Base (Setup Inicial)
            if Config.BaseCam and not FixedCamCFrame then
                FixedCamCFrame = Camera.CFrame -- Salva onde você está olhando agora
            end
            
            -- 2. Mantém Câmera Travada
            if Config.BaseCam and FixedCamCFrame then
                Camera.CFrame = FixedCamCFrame
            end
            
            -- 3. Equipa
            EquipWeapon()
            
            -- 4. Acha e Mata
            local enemy = GetTarget()
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local enemyRoot = enemy.HumanoidRootPart
                
                -- Vai até as costas dele
                local attackPos = enemyRoot.CFrame * CFrame.new(0, 0, Config.AttackDist)
                TeleportTo(attackPos)
                
                -- Olha pro inimigo
                root.CFrame = CFrame.new(root.Position, Vector3.new(enemyRoot.Position.X, root.Position.Y, enemyRoot.Position.Z))
                
                -- SPAM CLICK (Ataque)
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(900, 500))
                
                -- Fast Attack (Corta Cooldown)
                if Config.FastAttack then
                    BoostAttackSpeed()
                end
                
                -- Usa Skills também
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            else
                -- Se não tem inimigo, volta pra posição da câmera (Base) se quiser
                -- (Opcional, mas ajuda a descansar o boneco)
            end
        else
            FixedCamCFrame = nil -- Destrava câmera se desligar
            -- Devolve visibilidade
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.Transparency = 0 end
                    if v:IsA("Decal") then v.Transparency = 0 end
                end
            end
        end
    end
end)

-- AUTO COLLECT CORRIGIDO
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoFarm then -- Só coleta se farm estiver ligado
            for _, drop in pairs(Workspace:GetDescendants()) do
                -- Verifica se é ferramenta E se está no chão (Workspace)
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") and drop.Parent == Workspace then
                    drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("⚡ Auto Farm (Speed Demon)", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("📷 Travar Câmera na Base", function(bool)
    Config.BaseCam = bool
end)

Folder:Toggle("⚔️ Fast Attack (Corta Cooldown)", function(bool)
    Config.FastAttack = bool
end)

Folder:Label("Fique parado na base e ative.")
Folder:Label("Seu personagem vai invisível matar tudo.")