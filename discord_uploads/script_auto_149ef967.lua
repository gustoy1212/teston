--[[
    🧟 HUNTER ZOMBIE - THE FORCE TRIGGER (v35.0)
    
    ESTRATÉGIA DE FORÇA BRUTA:
    1. VAI ATÉ A PORTA: Usa Tween (Liso/Rápido).
    2. FORCE TOUCH: Ao chegar, usa 'firetouchinterest' em TODAS as peças num raio de 15 studs.
       - Isso simula que você encostou na parede, no chão, no teto e nos gatilhos invisíveis
         ao mesmo tempo. É impossível o jogo não detectar.
    3. MATA: Se os zumbis spawnarem, teleporta nas costas.
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
    TpSpeed = 80,         -- Velocidade de viagem
    
    -- Combate
    AttackDist = 5,
    KillRange = 2000,
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    TriggerRadius = 15,   -- Raio da "Bomba de Toque" (Toca em tudo nessa área)
    
    -- Skills
    AttackInterval = 0.3,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local visitedDoors = {}
local currentTween = nil
local LockedTarget = nil

-- // GUI //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieForceTrigger"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🛑 FORCE TRIGGER v35"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
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
ActionText.TextColor3 = Color3.fromRGB(255, 100, 100)
ActionText.BackgroundTransparency = 1
ActionText.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO MÁGICA: TOUCH SPAM //
local function ForceTouchEverythingNearby()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    Status.Text = "⚡ ATIVANDO GATILHOS..."
    
    -- Pega tudo que é peça em volta
    local parts = Workspace:GetPartBoundsInRadius(root.Position, SETTINGS.TriggerRadius)
    
    for _, part in ipairs(parts) do
        -- Não toca em si mesmo
        if not part:IsDescendantOf(char) and not part.Name:match("Baseplate") then
            -- Tenta usar firetouchinterest (Exploit Function)
            -- Simula: Encostou (0) -> Desencostou (1)
            if firetouchinterest then
                pcall(function()
                    firetouchinterest(root, part, 0)
                    firetouchinterest(root, part, 1)
                end)
            else
                -- Fallback pra quem não tem firetouchinterest (Teleporte rápido)
                -- Teleporta pra dentro da peça e volta
                local oldPos = root.CFrame
                root.CFrame = part.CFrame
                task.wait()
                root.CFrame = oldPos
            end
        end
    end
end

-- // MOVIMENTO //
local function TweenTo(pos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local dist = (char.PrimaryPart.Position - pos).Magnitude
    local time = dist / SETTINGS.TpSpeed
    
    if currentTween then currentTween:Cancel() end
    
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    -- Mantém altura Y pra não entrar no chão
    local targetCf = CFrame.new(pos.X, char.PrimaryPart.Position.Y, pos.Z)
    
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = targetCf})
    currentTween:Play()
end

-- // BUSCAS //
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
                local pos = obj:IsA("Model") and obj:GetBoundingBox().Position or obj.Position
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

-- // MAIN LOOP //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {}
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
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
    
    -- 1. ZUMBI VIVO? MATA!
    local target = FindTarget()
    
    if target then
        if currentTween then currentTween:Cancel() end
        
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ ALVO: " .. target.Name
        ActionText.Text = "Kill Mode"
        
        -- TP Costas
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3)
        char:SetPrimaryPartCFrame(CFrame.new(backPos.Position, tRoot.Position))
        
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            if tick() - lastSkillUsage > 3.0 then CastSkill() end
        end
        
    else
        -- 2. SEM ZUMBIS? VAI P/ PORTA
        local doorData = FindDoor()
        
        if doorData then
            local dist = (root.Position - doorData.Position).Magnitude
            
            if dist < 8 then
                -- ESTÁ NA PORTA
                Status.Text = "🛑 PORTA CHECADA"
                ActionText.Text = "Forçando Gatilho..."
                
                -- PARA TUDO E ATIVA O TOUCH SPAM
                if currentTween then currentTween:Cancel() end
                hum:MoveTo(root.Position) -- Para andar
                
                -- TOCA EM TUDO EM VOLTA (Força Bruta)
                ForceTouchEverythingNearby()
                
                visitedDoors[doorData.Object] = true
                
                -- Empurra um pouco pra frente pra garantir
                root.CFrame = root.CFrame * CFrame.new(0, 0, -5)
                
            else
                Status.Text = "🏃 INDO P/ PORTA"
                ActionText.Text = "Tween"
                TweenTo(doorData.Position)
            end
        else
            Status.Text = "FIM (Sem Portas)"
        end
    end
end)