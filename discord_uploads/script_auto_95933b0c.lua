--[[
    🧟 HUNTER ZOMBIE - THE LAST STAND (v38.0)
    
    TÉCNICA "MICRO-STEP":
    - Em vez de teleportar direto, o script "fatia" o caminho pela porta em 50 passos.
    - Ele move o personagem passo-a-passo (CFrame) através da porta.
    - Isso obriga o servidor a registrar sua presença no gatilho.
    
    EXTRAS:
    - Botão FECHAR [X] (Limpa tudo).
    - Kill Aura Instantânea (Teleporta nas costas).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

getgenv().ZombieFarmRunning = true -- Variável de controle

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    KillRange = 2500,     -- Olha o mapa todo
    AttackDist = 6,
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    StepSize = 2,         -- Tamanho do "passinho" (menor = mais chance de ativar)
    StepSpeed = 0.05,     -- Tempo entre passos (muito rápido)
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local visitedDoors = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("ZombieLastStand") then CoreGui.ZombieLastStand:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieLastStand"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0) -- Preto e Vermelho (Final)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "💀 THE LAST STAND v38"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

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
ActionText.TextColor3 = Color3.fromRGB(100, 100, 100)
ActionText.BackgroundTransparency = 1
ActionText.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO FECHAR //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().ZombieFarmRunning = false
    Status.Text = "SCRIPT ENCERRADO"
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    ScreenGui:Destroy()
end)

-- // FUNÇÕES AUXILIARES //
local function GetCenter(part)
    if part:IsA("Model") then
        local cf, _ = part:GetBoundingBox()
        return cf.Position
    else
        return part.Position
    end
end

-- // MÁGICA: MICRO-STEP THROUGH DOOR //
local function MicroStepThrough(targetPos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    Status.Text = "🚶 ATRAVESSANDO..."
    ActionText.Text = "Técnica Micro-Step"
    
    local startPos = char.PrimaryPart.Position
    local direction = (targetPos - startPos).Unit
    local distance = (targetPos - startPos).Magnitude
    local steps = math.floor(distance / SETTINGS.StepSize)
    
    -- Congela física pra não bugar
    char.PrimaryPart.Anchored = true
    
    for i = 1, steps + 5 do -- +5 passos extras pra passar DEPOIS da porta
        if not getgenv().ZombieFarmRunning then break end
        
        -- Calcula próxima posição
        local newPos = startPos + (direction * (i * SETTINGS.StepSize))
        char:SetPrimaryPartCFrame(CFrame.new(newPos))
        
        -- TENTA ATIVAR GATILHOS NA FORÇA BRUTA
        local parts = Workspace:GetPartBoundsInRadius(newPos, 5)
        for _, p in ipairs(parts) do
            if firetouchinterest then
                pcall(function() firetouchinterest(char.PrimaryPart, p, 0) firetouchinterest(char.PrimaryPart, p, 1) end)
            end
        end
        
        task.wait(SETTINGS.StepSpeed)
    end
    
    char.PrimaryPart.Anchored = false
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

-- // BUSCA //
local function FindTarget()
    local entities = Workspace:FindFirstChild("Entities")
    local zombies = entities and entities:FindFirstChild("Zombie")
    if not zombies then return nil end
    
    local myPos = LocalPlayer.Character.PrimaryPart.Position
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
    return closest
end

local function FindDoor()
    local myPos = LocalPlayer.Character.PrimaryPart.Position
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        if LocalPlayer.Character then LocalPlayer.Character.PrimaryPart.Anchored = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().ZombieFarmRunning then return end
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
    
    -- 1. ZUMBIS (Prioridade Total)
    local target = FindTarget()
    
    if target then
        root.Anchored = false -- Solta o boneco
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ MATANDO"
        ActionText.Text = target.Name
        
        -- TP Costas
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3)
        root.CFrame = CFrame.new(backPos.Position, tRoot.Position)
        root.Velocity = Vector3.new(0,0,0)
        
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            if tick() - lastSkillUsage > 3.0 then CastSkill() end
        end
        
    else
        -- 2. PORTAS (Micro-Step)
        local doorData = FindDoor()
        
        if doorData then
            local dist = (root.Position - doorData.Position).Magnitude
            
            if dist > 15 then
                -- Vai rápido até perto (Tween Simples)
                Status.Text = "🚀 INDO ATÉ A PORTA"
                ActionText.Text = math.floor(dist) .. "m"
                root.Anchored = false
                
                -- Teleporte suave pra não crashar
                root.CFrame = CFrame.new(doorData.Position) * CFrame.new(0, 0, 5) -- Para 5 studs antes
                
            else
                -- CHEGOU PERTO -> ATIVA MICRO-STEP
                visitedDoors[doorData.Object] = true
                MicroStepThrough(doorData.Position)
            end
        else
            Status.Text = "FIM / NADA ENCONTRADO"
            root.Anchored = false
        end
    end
end)