-- [[ SOLO LEVELING: SLAYER V11 (BOSS FIX & ANIM CANCEL) ]] --
-- Correção de Posição Manual (Rotação) e Dano por Reset de Equipamento

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Slayer V11")
local Folder = Window:CreateFolder("Boss Fix")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    AutoFarm = false,
    AnimCancel = true,    -- O Segredo do Dano
    RotationAngle = 180,  -- 180 = Costas, 0 = Frente
    Height = 5,           -- Altura do chão
    Distance = 6,         -- Distância do alvo
    TargetPart = "Head"   -- Tenta focar na Cabeça
}

-- Variável para guardar a ferramenta atual
local CurrentWeapon = nil

-- FUNÇÃO 1: ANIMATION CANCEL (EQUIP RESET)
-- Tira e põe a arma pra bater mais rápido
local function AttackReset()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local tool = char:FindFirstChildWhichIsA("Tool")
    
    if tool then
        CurrentWeapon = tool -- Salva qual é a arma
        
        -- 1. Ataca
        tool:Activate()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(900, 500))
        
        if Config.AnimCancel then
            -- 2. Desequipa (Reseta animação)
            humanoid:UnequipTools()
            
            -- 3. Equipa de volta instantaneamente
            task.wait() -- Mínimo delay pro jogo processar
            humanoid:EquipTool(CurrentWeapon)
        end
    else
        -- Se estiver sem arma, tenta equipar a última usada ou a primeira da mochila
        if CurrentWeapon and CurrentWeapon.Parent == LocalPlayer.Backpack then
            humanoid:EquipTool(CurrentWeapon)
        else
            local backpackTool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
            if backpackTool then humanoid:EquipTool(backpackTool) end
        end
    end
end

-- FUNÇÃO 2: CALCULAR POSIÇÃO (COM ROTAÇÃO MANUAL)
local function GetOrbitPosition(targetPart)
    local rootPos = targetPart.Position
    local angleRad = math.rad(Config.RotationAngle)
    
    -- Calcula a posição baseada no ângulo escolhido (Matemática de Círculo)
    -- Isso permite você girar ao redor do Boss sem depender do "LookVector" dele
    local offsetX = math.sin(angleRad) * Config.Distance
    local offsetZ = math.cos(angleRad) * Config.Distance
    
    local finalPos = Vector3.new(rootPos.X + offsetX, rootPos.Y + Config.Height, rootPos.Z + offsetZ)
    
    -- Retorna CFrame olhando para o Boss
    return CFrame.new(finalPos, rootPos)
end

-- FUNÇÃO 3: MOVIMENTO (TWEEN SUAVE)
local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    -- Tween Rápido
    local dist = (root.Position - cframe.Position).Magnitude
    if dist > 50 then
        root.CFrame = cframe
    else
        local info = TweenInfo.new(dist / 60, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, info, {CFrame = cframe})
        tween:Play()
    end
    
    root.Velocity = Vector3.zero
end

-- FUNÇÃO 4: ACHAR INIMIGO (CABEÇA OU TORSO)
local function GetTarget()
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossFolder = Workspace:FindFirstChild("Boss")
    local targets = {}
    
    if mobsFolder then for _,m in pairs(mobsFolder:GetChildren()) do table.insert(targets, m) end end
    if bossFolder then for _,b in pairs(bossFolder:GetChildren()) do table.insert(targets, b) end end
    
    -- Procura soltos se precisar
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
        if e:FindFirstChild("Humanoid") and e.Humanoid.Health > 0 then
            -- Tenta achar a parte configurada (Head) ou RootPart
            local part = e:FindFirstChild(Config.TargetPart) or e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Torso")
            
            if part then
                local d = (part.Position - myPos).Magnitude
                if d < minDist then
                    minDist = d
                    nearest = e
                end
            end
        end
    end
    return nearest
end

-- LOOP PRINCIPAL
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm and LocalPlayer.Character then
            local enemy = GetTarget()
            
            if enemy then
                -- Define qual parte atacar (Cabeça ou Corpo)
                local targetPart = enemy:FindFirstChild(Config.TargetPart) or enemy:FindFirstChild("HumanoidRootPart")
                
                if targetPart then
                    -- 1. Calcula onde ficar (usando o Slider de Rotação)
                    local attackCF = GetOrbitPosition(targetPart)
                    
                    -- 2. Move
                    TeleportTo(attackCF)
                    
                    -- 3. Ataca com Reset
                    AttackReset()
                    
                    -- 4. Skills (Spam)
                    local keys = {"E", "R", "F", "Q", "C", "V"}
                    for _, k in pairs(keys) do
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game)
                    end
                end
            end
        end
    end
end)

-- AUTO COLLECT
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoFarm then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                     drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

-- NOCLIP
RunService.Stepped:Connect(function()
    if Config.AutoFarm and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- GUI
Folder:Toggle("⚔️ Auto Farm V11", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("🔄 Anim Cancel (Mais Dano)", function(bool)
    Config.AnimCancel = bool
end)

Folder:Slider("Ângulo (Girar no Boss)", 0, 360, 180, function(v)
    Config.RotationAngle = v
end)

Folder:Slider("Altura (Voar)", -5, 15, 5, function(v)
    Config.Height = v
end)

Folder:Slider("Distância", 1, 15, 6, function(v)
    Config.Distance = v
end)

Folder:Label("USE O SLIDER 'ÂNGULO' PARA SAIR DA FRENTE DA COBRA!")