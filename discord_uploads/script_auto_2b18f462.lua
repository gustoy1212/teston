--[[
    🧟 HUNTER ZOMBIE - THE DOOR BREACHER (v34.0)
    
    SOLUÇÃO DO GATILHO:
    1. TWEEN TRAVEL: Usa teleporte rápido para viajar pelo mapa até perto da porta.
    2. PHYSICAL BREACH: Ao chegar a 8 studs da porta, DESLIGA O TELEPORTE.
       - O boneco ANDA (MoveTo) através da porta fisicamente.
       - Isso garante que o evento .Touched dispare e ative os zumbis.
    3. KILL MODE: Assim que passa, volta a usar Teleporte nas Costas (Backstab).
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
    
    -- Velocidades
    TpSpeed = 90,         -- Velocidade de viagem (Rápido)
    BreachSpeed = 20,     -- Velocidade ao passar na porta (Lento pra garantir trigger)
    
    -- Combate
    AttackDist = 5,
    KillRange = 2000,
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    PreDoorDist = 10,     -- Distância para parar de teleportar e começar a andar
    
    -- Skills
    AttackInterval = 0.3,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0

-- Estados
local LockedTarget = nil
local CurrentDoor = nil
local visitedDoors = {}
local currentTween = nil
local isBreaching = false -- Se está no modo "Passar pela porta"

-- // GUI //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieBreacher"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚪 DOOR BREACHER v34"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionText = Instance.new("TextLabel", MainFrame)
ActionText.Size = UDim2.new(1, 0, 0, 20)
ActionText.Position = UDim2.new(0, 0, 0.5, 0)
ActionText.Text = "-"
ActionText.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionText.BackgroundTransparency = 1
ActionText.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 0)
ToggleBtn.Text = "LIGAR FARM"
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

-- // MOVIMENTO TWEEN //
local function TweenMove(targetPos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local dist = (char.PrimaryPart.Position - targetPos).Magnitude
    local time = dist / SETTINGS.TpSpeed
    
    if currentTween then currentTween:Cancel() end
    
    -- Ajusta altura pra não entrar no chão
    local finalCf = CFrame.new(targetPos.X, char.PrimaryPart.Position.Y, targetPos.Z)
    
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = finalCf})
    currentTween:Play()
end

-- // MOVIMENTO FÍSICO (ANDAR) //
local function PhysicalWalk(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    if currentTween then currentTween:Cancel() end
    hum:MoveTo(targetPos)
end

-- // COMBATE //
local function CastSkill()
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
end

-- // BUSCA ALVO (Só zumbis ativos) //
local function FindTarget()
    -- Se tiver travado em alguém vivo, mantém
    if LockedTarget and LockedTarget.Parent and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
        return LockedTarget
    end
    LockedTarget = nil

    local entities = Workspace:FindFirstChild("Entities")
    local zombies = entities and entities:FindFirstChild("Zombie")
    if not zombies then return nil end
    
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, mob in ipairs(zombies:GetChildren()) do
        if mob.Name ~= "ScopeSStars" then
            local root = mob:FindFirstChild("HumanoidRootPart")
            -- Check Vida + UpVector (Não tá morto no chão)
            if root and root.CFrame.UpVector.Y > 0.4 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist and dist < SETTINGS.KillRange then
                    minDist = dist
                    closest = mob
                end
            end
        end
    end
    LockedTarget = closest
    return closest
end

-- // BUSCA PORTA //
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

-- // NOCLIP (Só ativa durante Tween/Combate) //
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        -- Se estiver BREACHING (Passando porta), precisa de colisão no pé pra andar? 
        -- Não, MoveTo funciona sem colisão, mas precisa de chão.
        -- Vamos manter noclip mas garantir que a gravidade funcione no modo Breach
        
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if isBreaching then
                root.Velocity = Vector3.new(root.Velocity.X, -10, root.Velocity.Z) -- Gravidade manual
            else
                root.Velocity = Vector3.new(0,0,0) -- Flutuar no modo Tween
            end
        end
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
        isBreaching = false
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 0)
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
    
    -- 1. TENTA MATAR (Prioridade)
    local target = FindTarget()
    
    if target then
        -- MODO COMBATE
        isBreaching = false
        CurrentDoor = nil
        if currentTween then currentTween:Cancel() end
        
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ MATANDO: " .. target.Name
        ActionText.Text = "Teleporte nas Costas"
        
        -- TP COSTAS
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3)
        char:SetPrimaryPartCFrame(CFrame.new(backPos.Position, tRoot.Position))
        
        -- ATAQUE
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            if tick() - lastSkillUsage > 3.0 then CastSkill() end
        end
        
    else
        -- 2. BUSCA PORTA
        if not CurrentDoor then
            local doorData = FindDoor()
            if doorData then
                CurrentDoor = doorData
                Status.Text = "🚪 PORTA ENCONTRADA"
            else
                Status.Text = "MAPA LIMPO (Fim)"
                if currentTween then currentTween:Cancel() end
                return
            end
        end
        
        -- LÓGICA DE APROXIMAÇÃO
        if CurrentDoor then
            local doorPos = CurrentDoor.CFrame.Position
            local dist = (root.Position - doorPos).Magnitude
            
            if dist < 6 then
                -- ESTAMOS DENTRO/PASSANDO
                visitedDoors[CurrentDoor.Object] = true
                Status.Text = "✅ SALA ATIVADA!"
                isBreaching = false
                CurrentDoor = nil -- Procura zumbis agora
                
            elseif dist < SETTINGS.PreDoorDist then
                -- ESTAMOS PERTO -> MODO CAMINHADA (BREACH)
                isBreaching = true
                hum.WalkSpeed = SETTINGS.BreachSpeed -- Velocidade normal
                
                Status.Text = "🚶 PASSANDO PELA PORTA..."
                ActionText.Text = "Andando Fisicamente"
                
                -- Calcula ponto 5 metros DEPOIS da porta
                local direction = (doorPos - root.Position).Unit
                local passPoint = doorPos + (direction * 8)
                
                PhysicalWalk(passPoint)
                
            else
                -- ESTAMOS LONGE -> MODO TWEEN (TÁXI)
                isBreaching = false
                Status.Text = "🚖 INDO ATÉ A PORTA"
                ActionText.Text = "Tween Rápido"
                
                TweenMove(doorPos)
            end
        end
    end
end)