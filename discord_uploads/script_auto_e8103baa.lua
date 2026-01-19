--[[
    🧟 HUNTER ZOMBIE - THE FLASH TRIGGER (v33.0)
    
    ESTRATÉGIA "TELEPORT MASTER":
    1. MOVIMENTO: Usa TweenService (Deslize) em vez de andar. 
       - Atravessa paredes e chega na porta instantaneamente.
    2. GATILHO DE PORTA: Identifica a porta, vai até ela e atravessa para ativar o spawn.
    3. FOCO DE MIRA: Trava em 1 zumbi até ele morrer (não fica trocando).
    4. BACKSTAB: Teleporta para as costas do zumbi (colado) para matar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    
    -- Velocidade do Teleporte (Quanto maior, mais rápido)
    TpSpeed = 80,         -- Bem rápido
    
    -- Distâncias
    AttackDist = 4,       -- Distância para bater (Colado)
    KillRange = 2000,     -- Raio de detecção alto
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    DoorTriggerDist = 5,  -- Distância para considerar que passou a porta
    
    -- Combate
    AttackInterval = 0.3, 
    WaitBeforeSkill = 0.5,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0

-- Variáveis de Estado
local LockedTarget = nil     -- Zumbi focado atual
local CurrentDoor = nil      -- Porta alvo atual
local visitedDoors = {}      -- Lista de portas já passadas
local currentTween = nil     -- O Tween atual

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieFlash"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ FLASH TRIGGER v33"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 0)
ToggleBtn.Text = "LIGAR (TELEPORT)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function GetCenter(part)
    if part:IsA("Model") then
        local cf, size = part:GetBoundingBox()
        return cf
    else
        return part.CFrame
    end
end

-- // MOVIMENTO TWEEN (O SEGREDO DO LISO) //
local function TP_To(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    -- Calcula tempo baseado na distância (Velocidade Constante)
    local dist = (char.PrimaryPart.Position - targetCFrame.Position).Magnitude
    
    -- Se estiver muito perto, teleporta instantâneo (CFrame puro)
    if dist < 5 then
        if currentTween then currentTween:Cancel() end
        char:SetPrimaryPartCFrame(targetCFrame)
        return
    end

    local time = dist / SETTINGS.TpSpeed
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    -- Só cria tween novo se o destino mudou muito ou não tem tween
    if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
        -- Otimização: Não cancela se o destino for o mesmo
        return 
    end
    
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = targetCFrame})
    currentTween:Play()
end

-- // COMBATE //
local function CastSkill()
    -- Skill simples e rápida
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
end

-- // BUSCA DE ALVOS //
local function FindTarget()
    -- Se já temos um alvo travado, verifica se ele ainda existe e está vivo
    if LockedTarget then
        if LockedTarget.Parent and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
            return LockedTarget -- Mantém o foco!
        else
            LockedTarget = nil -- Morreu, libera pra buscar outro
        end
    end

    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local zombies = entities:FindFirstChild("Zombie")
    
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    if zombies then
        for _, mob in ipairs(zombies:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then
                local root = mob:FindFirstChild("HumanoidRootPart")
                -- Check de Vida
                if root and root.CFrame.UpVector.Y > 0.4 then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < minDist and dist < SETTINGS.KillRange then
                        minDist = dist
                        closest = mob
                    end
                end
            end
        end
    end
    
    LockedTarget = closest -- Trava no novo alvo
    return closest
end

-- // BUSCA DE PORTAS //
local function FindDoor()
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local isDoor = false
            for _, name in ipairs(SETTINGS.DoorNames) do
                if obj.Name:find(name) then isDoor = true break end
            end
            
            if isDoor and not visitedDoors[obj] then
                local cf = GetCenter(obj)
                local dist = (cf.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = {Object = obj, CFrame = cf}
                end
            end
        end
    end
    return closest
end

-- // NOCLIP (ATRAVESSAR PAREDES) //
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(0,0,0) end -- Tira física
    end
end)

-- // MAIN LOOP //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {}
        LockedTarget = nil
    else
        ToggleBtn.Text = "LIGAR (TELEPORT)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 0)
        Status.Text = "Parado"
        if currentTween then currentTween:Cancel() end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    -- 1. PRIORIDADE: MATAR ZUMBIS (Se tiver zumbi, ignora porta)
    local target = FindTarget()
    
    if target then
        -- MODO ASSASSINO
        CurrentDoor = nil -- Esquece a porta
        if currentTween then currentTween:Cancel() end -- Cancela tween de porta
        
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ MATANDO: " .. target.Name
        
        -- TP PARA AS COSTAS (Teleporte CFrame Direto - Mais rápido pra combate)
        -- Fica 3 studs atrás
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3) 
        char:SetPrimaryPartCFrame(CFrame.new(backPos.Position, tRoot.Position))
        
        -- BATER
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            
            if tick() - lastSkillUsage > 3.0 then
                CastSkill()
            end
        end
        
    else
        -- 2. SEM ZUMBIS? VAI PARA PORTA
        if not CurrentDoor then
            local doorData = FindDoor()
            if doorData then
                CurrentDoor = doorData
                Status.Text = "🏃 INDO P/ PORTA..."
            else
                Status.Text = "MAPA LIMPO (Fim)"
            end
        end
        
        if CurrentDoor then
            local doorPos = CurrentDoor.CFrame
            local dist = (root.Position - doorPos.Position).Magnitude
            
            if dist < SETTINGS.DoorTriggerDist then
                -- CHEGOU NA PORTA
                visitedDoors[CurrentDoor.Object] = true
                Status.Text = "✅ PORTA ATIVADA"
                
                -- Empurrãozinho pra frente pra garantir o trigger
                char:SetPrimaryPartCFrame(root.CFrame * CFrame.new(0, 0, -8))
                CurrentDoor = nil -- Busca próxima ou zumbis
            else
                -- TELEPORTA (Tween) ATÉ A PORTA
                -- Mantém a altura do player pra não entrar no chão
                local targetPos = CFrame.new(doorPos.X, root.Position.Y, doorPos.Z)
                TP_To(targetPos)
            end
        end
    end
end)