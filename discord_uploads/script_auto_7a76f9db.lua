--[[
    🧟 HUNTER ZOMBIE - THE DOOR BANGER (v37.0)
    
    SOLUÇÃO FINAL DE GATILHO:
    1. VAI E VOLTA: Se passar na porta e não spawnar, ele volta e tenta de novo.
       - Ele fica "esfregando" na porta até o jogo detectar.
    2. VELOCIDADE NORMAL: Passa pela porta andando devagar (WalkSpeed 20).
       - Isso impede que você "pule" o frame de detecção do servidor.
    3. PULO AUTOMÁTICO: Pula enquanto passa pra garantir triggers aéreos ou no chão.
    
    Controles:
    - Botão X para fechar completamente.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

getgenv().ScriptRunning = true -- Controle global

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Navegação
    TravelSpeed = 80,     -- Velocidade até chegar perto da porta
    BreachSpeed = 22,     -- Velocidade LENTA para ativar o gatilho (Importante!)
    
    -- Combate
    AttackDist = 6,
    KillRange = 2500,     -- Raio alto pra ver se o zumbi spawnou longe
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    
    -- Skill
    AttackInterval = 0.3,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local currentTween = nil
local LockedTarget = nil

-- Lógica de Porta
local CurrentDoor = nil
local visitedDoors = {}
local doorRetryCount = 0 -- Quantas vezes tentou a mesma porta
local isBreaching = false

-- // GUI SETUP //
if CoreGui:FindFirstChild("ZombieDoorBanger") then CoreGui.ZombieDoorBanger:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieDoorBanger"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🚪 DOOR BANGER v37"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionText = Instance.new("TextLabel", MainFrame)
ActionText.Size = UDim2.new(1, 0, 0, 20)
ActionText.Position = UDim2.new(0, 0, 0.45, 0)
ActionText.Text = "-"
ActionText.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionText.BackgroundTransparency = 1
ActionText.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO FECHAR //
local function StopScript()
    getgenv().ScriptRunning = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
        LocalPlayer.Character.Humanoid.HipHeight = 0
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.PrimaryPart.Position)
    end
    ScreenGui:Destroy()
end
CloseBtn.MouseButton1Click:Connect(StopScript)

-- // AUXILIARES //
local function GetCenter(part)
    if part:IsA("Model") then
        local cf, _ = part:GetBoundingBox()
        return cf.Position
    else
        return part.Position
    end
end

local function TweenTo(pos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local dist = (char.PrimaryPart.Position - pos).Magnitude
    local time = dist / SETTINGS.TravelSpeed
    
    if currentTween then currentTween:Cancel() end
    local targetCf = CFrame.new(pos.X, char.PrimaryPart.Position.Y, pos.Z)
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = targetCf})
    currentTween:Play()
end

local function CastSkill()
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
end

-- // BUSCA ZUMBI //
local function FindTarget()
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
                local pos = GetCenter(obj)
                local dist = (pos - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = {Object = obj, Position = pos}
                end
            end
        end
    end
    return closest
end

-- // LOOP PRINCIPAL //
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        if currentTween then currentTween:Cancel() end
    end
end)

local breachTimer = 0
local breachStage = 1 -- 1: Vai, 2: Volta

RunService.Heartbeat:Connect(function()
    if not getgenv().ScriptRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    -- 1. CHECA SE TEM ZUMBI VIVO
    local target = FindTarget()
    
    if target then
        -- MOD: COMBATE
        isBreaching = false
        CurrentDoor = nil
        if currentTween then currentTween:Cancel() end
        
        -- CONFIGURAÇÃO DE COMBATE
        hum.HipHeight = SETTINGS.FloatHeight
        hum.WalkSpeed = 16 -- Normal pra não bugar ataque
        
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ MATANDO ZUMBI"
        ActionText.Text = target.Name
        
        -- TP nas Costas
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3)
        root.CFrame = CFrame.new(backPos.Position, tRoot.Position)
        
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            if tick() - lastSkillUsage > 3.0 then CastSkill() end
        end
        
        -- Se achou zumbi, reseta o contador de retry da porta, pois funcionou
        doorRetryCount = 0
        
    else
        -- 2. SEM ZUMBIS -> TRABALHAR NA PORTA
        if not CurrentDoor then
            local doorData = FindDoor()
            if doorData then
                CurrentDoor = doorData
                doorRetryCount = 0
                Status.Text = "🚪 PORTA À VISTA"
            else
                Status.Text = "MAPA LIMPO (Fim)"
                hum:MoveTo(root.Position)
                return
            end
        end
        
        if CurrentDoor then
            local doorPos = CurrentDoor.Position
            local dist = (root.Position - doorPos).Magnitude
            
            -- Se estamos longe, vai rápido
            if dist > 12 and not isBreaching then
                Status.Text = "🚖 INDO P/ PORTA"
                ActionText.Text = "Tween Rápido"
                hum.HipHeight = 5
                hum.WalkSpeed = 0
                TweenTo(doorPos)
            else
                -- CHEGOU NA ZONA DA PORTA
                if currentTween then currentTween:Cancel() end
                isBreaching = true
                
                -- CONFIGURAÇÃO "HUMANA" PARA ATIVAR GATILHO
                hum.HipHeight = 0 -- Chão mesmo, pra tocar no trigger de chão
                hum.WalkSpeed = SETTINGS.BreachSpeed -- Velocidade normal
                
                Status.Text = "🛑 ATIVANDO GATILHO..."
                
                -- Lógica "Vai e Volta" (Esfregar na porta)
                breachTimer = breachTimer + RunService.Heartbeat:Wait()
                if breachTimer > 0.8 then -- Muda de direção a cada 0.8s
                    breachStage = (breachStage == 1) and 2 or 1
                    breachTimer = 0
                    hum.Jump = true -- Pula pra garantir
                    
                    -- Incrementa tentativas
                    doorRetryCount = doorRetryCount + 1
                    if doorRetryCount > 8 then
                        -- Se tentou 8 vezes (aprox 6 segundos) e nada spawnou, marca como visitada e vai pra próxima
                        visitedDoors[CurrentDoor.Object] = true
                        CurrentDoor = nil
                        isBreaching = false
                        Status.Text = "❌ FALHA NA PORTA (IGNORANDO)"
                        return
                    end
                end
                
                local dir = (doorPos - root.Position).Unit
                
                if breachStage == 1 then
                    -- EMPURRA PRA FRENTE (Passa porta)
                    ActionText.Text = "Tentativa: " .. doorRetryCount .. " (INDO)"
                    local target = doorPos + (dir * 12) -- 12 studs pra frente
                    hum:MoveTo(target)
                else
                    -- VOLTA UM POUCO (Recua)
                    ActionText.Text = "Tentativa: " .. doorRetryCount .. " (VOLTANDO)"
                    local target = doorPos - (dir * 5) -- 5 studs pra trás
                    hum:MoveTo(target)
                end
            end
        end
    end
end)