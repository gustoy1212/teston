--[[
    🧟 HUNTER ZOMBIE - THE ROOM ANNIHILATOR (v28.0)
    
    MUDANÇAS DRÁSTICAS:
    1. MASSIVE REACH: Aumenta o tamanho da SUA ARMA para 80 studs.
       - Você acerta a sala inteira sem precisar andar até os zumbis.
    2. ESTABILIDADE: Substituí o Voo por Speed Hack (WalkSpeed 50).
       - Resolve o bug de "voar infinitamente" e garante ativar as portas.
    3. FLUXO: Porta -> Reach (Mata Geral) -> Próxima Porta.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    MoveSpeed = 50,       -- Velocidade para correr até a porta (Sem voo bugado)
    
    -- Alcance da Arma (O Segredo)
    ReachSize = 80,       -- Tamanho da espada (Cobre a sala toda)
    KillRange = 150,      -- Se tiver zumbi nesse raio, ATACA
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"}, 
    DoorDistance = 6,     -- Distância para marcar porta como "passada"
    
    -- Skills
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.4,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local currentState = "SEEKING_DOOR" 
local currentDoorObj = nil
local visitedDoors = {} 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieAnnihilator"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 10, 10) -- Vermelho Sangue
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🩸 ANNIHILATOR v28"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionInfo = Instance.new("TextLabel", MainFrame)
ActionInfo.Size = UDim2.new(1, 0, 0, 20)
ActionInfo.Position = UDim2.new(0, 0, 0.4, 0)
ActionInfo.Text = "-"
ActionInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionInfo.BackgroundTransparency = 1
ActionInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE REACH (ALCANCE INFINITO) //
local function EnableReach()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then
            -- Transforma o cabo da espada numa caixa gigante
            if handle.Size.X < 10 then -- Só aumenta se for pequeno
                handle.Massless = true -- Pra não pesar e te derrubar
                handle.CanCollide = false
                handle.Size = Vector3.new(SETTINGS.ReachSize, SETTINGS.ReachSize, SETTINGS.ReachSize)
                handle.Transparency = 0.8 -- Meio invisível pra você ver
                
                -- Cria visualização (opcional)
                if not handle:FindFirstChild("ReachBox") then
                    local box = Instance.new("SelectionBox", handle)
                    box.Name = "ReachBox"
                    box.Adornee = handle
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end
end

-- // FUNÇÕES DE PORTA //
local function GetNearestUnvisitedDoor()
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
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {Object = obj, Position = part.Position}
                    end
                end
            end
        end
    end
    return closest
end

-- // PATHFINDING (MOVETO) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function WalkTo(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    
    -- Calcula rota se mudou muito ou se acabou
    if tick() - lastPathCalc > 1.0 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
        pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
        if path.Status == Enum.PathStatus.Success then
            currentWaypoints = path:GetWaypoints()
            currentWaypointIndex = 2
            lastPathCalc = tick()
        else
            -- Se falhar o path, vai reto
            hum:MoveTo(targetPos)
            return
        end
    end
    
    if currentWaypoints and currentWaypoints[currentWaypointIndex] then
        local wp = currentWaypoints[currentWaypointIndex]
        if (char.PrimaryPart.Position - wp.Position).Magnitude < 4 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
        hum:MoveTo(wp.Position)
        
        -- Pula se necessário
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
    else
        hum:MoveTo(targetPos)
    end
end

-- // COMBO SKILLS //
local function ExecuteCombo()
    Status.Text = "🛑 SKILL COMBO..."
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    
    if hum and equippedTool then hum:UnequipTools() task.wait(0.2) end
    task.wait(SETTINGS.WaitBeforeSkill)
    
    for _, key in ipairs(SKILLS) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    if hum and equippedTool then hum:EquipTool(equippedTool) end
    lastBurstTime = tick()
end

-- // LOOP PRINCIPAL //
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        visitedDoors = {}
        currentState = "SEEKING_DOOR"
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        Status.Text = "Parado"
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.PrimaryPart.Position) -- Para de andar
            char.Humanoid.WalkSpeed = 16 -- Reseta speed
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    -- SPEED HACK (Pra chegar na porta logo)
    hum.WalkSpeed = SETTINGS.MoveSpeed
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if currentState ~= "COMBOING" and not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    -- ATIVA REACH (SEMPRE QUE TIVER ARMA)
    EnableReach()

    -- 1. DETECTOR DE INIMIGOS
    local enemiesNearby = {}
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then
                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                if mRoot and mRoot.CFrame.UpVector.Y > 0.4 then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < SETTINGS.KillRange then
                        table.insert(enemiesNearby, mob)
                    end
                end
            end
        end
    end
    
    -- DECISÃO DE ESTADO
    if #enemiesNearby > 0 then
        currentState = "CLEARING_ROOM"
    else
        currentState = "SEEKING_DOOR"
    end
    
    -- LÓGICA
    if currentState == "CLEARING_ROOM" then
        Status.Text = "⚔️ ANIQUILANDO (" .. #enemiesNearby .. ")"
        ActionInfo.Text = "REACH ATIVO"
        currentDoorObj = nil -- Reseta foco na porta
        
        -- Fica parado pra bater
        hum:MoveTo(root.Position)
        
        -- Olha pro inimigo
        if enemiesNearby[1] and enemiesNearby[1]:FindFirstChild("HumanoidRootPart") then
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(enemiesNearby[1].HumanoidRootPart.Position.X, root.Position.Y, enemiesNearby[1].HumanoidRootPart.Position.Z))
        end
        
        -- ATAQUE
        if tick() - lastBasicAttack > 0.4 then
            if tool then tool:Activate() end
            lastBasicAttack = tick()
        end
        if tick() - lastBurstTime > 6.0 then
            task.spawn(ExecuteCombo)
        end
        
    elseif currentState == "SEEKING_DOOR" then
        ActionInfo.Text = "BUSCANDO SAÍDA"
        
        if not currentDoorObj then
            local doorData = GetNearestUnvisitedDoor()
            if doorData then
                currentDoorObj = doorData
                Status.Text = "🏃 INDO: " .. doorData.Object.Name
            else
                Status.Text = "DG LIMPA / SEM PORTAS"
                hum:MoveTo(root.Position)
            end
        end
        
        if currentDoorObj then
            local dist = (root.Position - currentDoorObj.Position).Magnitude
            if dist < SETTINGS.DoorDistance then
                visitedDoors[currentDoorObj.Object] = true
                currentDoorObj = nil
                Status.Text = "✅ CHEGOU NA PORTA"
            else
                WalkTo(currentDoorObj.Position)
            end
        end
    end
end)