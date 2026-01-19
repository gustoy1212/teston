--[[
    🧟 HUNTER ZOMBIE - THE ROOM CLEARER (v27.0)
    
    ESTRATÉGIA SEQUENCIAL:
    1. FLY TO DOOR: Voa (com GPS) até a porta mais próxima para ativar o spawn.
    2. EXPAND & KILL: Ao ativar a porta, expande hitboxes e mata todos da sala.
    3. NEXT ROOM: Limpou a sala? Procura a próxima porta.
    
    Correções:
    - Hitbox Expansion (Sem puxar, apenas aumenta o tamanho).
    - Voo com Pathfinding (Não atravessa paredes, desvia delas).
    - Skill Unjam (Guarda a arma para soltar skill).
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
    FlySpeed = 55,        
    
    -- Alturas
    TravelHeight = 4.5,   -- Altura para passar em portas (Baixo)
    CombatHeight = 15,    -- Altura para matar (Alto/Seguro)
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"}, 
    DoorReach = 6,        -- Distância para considerar "ativada"
    
    -- Combate
    HitboxSize = 60,      -- Tamanho do alvo (Gigante)
    KillRange = 150,      -- Raio de detecção de inimigos na sala
    
    -- Skills
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.4,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0

-- Estados: "SEEKING_DOOR" ou "CLEARING_ROOM"
local currentState = "SEEKING_DOOR" 
local currentDoorObj = nil
local visitedDoors = {} 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieRoomClearer"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 10) -- Verde Tático
MainFrame.BorderColor3 = Color3.fromRGB(50, 255, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚪 ROOM CLEARER v27"
Title.TextColor3 = Color3.fromRGB(50, 255, 50)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function ExpandHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        root.CanCollide = false
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 1 -- Invisível
        -- Não puxa (Anchor) para não bugar, só aumenta
    end
end

local function ExecuteCombo()
    Status.Text = "🛑 SKILL COMBO..."
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    
    -- Desequipa
    if hum and equippedTool then hum:UnequipTools() task.wait(0.2) end
    task.wait(SETTINGS.WaitBeforeSkill)
    
    -- Skills
    for _, key in ipairs(SKILLS) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    -- Re-equipa
    if hum and equippedTool then hum:EquipTool(equippedTool) end
    lastBurstTime = tick()
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

-- // PATHFINDING (GPS) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- Radius pequeno pra passar na porta
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- // VOO CONTROLADO //
local function EnableFlight()
    local root = LocalPlayer.Character.HumanoidRootPart
    if not root:FindFirstChild("NavVelocity") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "NavVelocity"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = root
        local bg = Instance.new("BodyGyro")
        bg.Name = "NavGyro"
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 20000
        bg.CFrame = root.CFrame
        bg.Parent = root
        LocalPlayer.Character.Humanoid.PlatformStand = true
    end
end

local function DisableFlight()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if char.HumanoidRootPart:FindFirstChild("NavVelocity") then char.HumanoidRootPart.NavVelocity:Destroy() end
        if char.HumanoidRootPart:FindFirstChild("NavGyro") then char.HumanoidRootPart.NavGyro:Destroy() end
        char.Humanoid.PlatformStand = false
    end
end

-- // LOOP PRINCIPAL //
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {} -- Reseta memória de portas
        currentState = "SEEKING_DOOR"
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
        Status.Text = "Parado"
        DisableFlight()
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not root:FindFirstChild("NavVelocity") then EnableFlight() end
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if currentState ~= "COMBOING" and not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    -- 1. DETECTOR DE INIMIGOS (Determina o Estado)
    local enemiesNearby = {}
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then
                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                if mRoot and mRoot.CFrame.UpVector.Y > 0.4 then -- Vivo
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < SETTINGS.KillRange then
                        table.insert(enemiesNearby, mob)
                    end
                end
            end
        end
    end
    
    -- Se tem inimigo perto E já passamos por uma porta recentemente, mata eles
    -- Mas se estamos muito longe da porta alvo, prioriza chegar nela primeiro
    if #enemiesNearby > 0 and currentState == "CLEARING_ROOM" then
        -- MANTÉM MODO COMBATE
    elseif #enemiesNearby > 0 and currentState == "SEEKING_DOOR" then
        -- Se esbarrar em inimigo no caminho, ignora a menos que esteja muito perto?
        -- O usuário pediu: Voa até a porta -> Ativa -> Mata.
        -- Então só muda pra CLEARING se a porta foi visitada.
    end

    -- MÁQUINA DE ESTADOS
    if currentState == "SEEKING_DOOR" then
        ActionInfo.Text = "Procurando Porta..."
        
        if not currentDoorObj then
            local doorData = GetNearestUnvisitedDoor()
            if doorData then
                currentDoorObj = doorData
            else
                Status.Text = "FIM DA DG (Sem portas)"
            end
        end
        
        if currentDoorObj then
            Status.Text = "🚪 INDO: " .. currentDoorObj.Object.Name
            local dist = (root.Position - currentDoorObj.Position).Magnitude
            
            if dist < SETTINGS.DoorReach then
                -- CHEGOU!
                visitedDoors[currentDoorObj.Object] = true
                currentDoorObj = nil
                
                -- Agora verifica se tem inimigos pra matar
                if #enemiesNearby > 0 then
                    currentState = "CLEARING_ROOM"
                    Status.Text = "⚔️ HORA DO SHOW"
                else
                    Status.Text = "Salão Vazio, Próxima..."
                    -- Continua SEEKING_DOOR
                end
            else
                -- VOA ATÉ A PORTA (GPS)
                local targetPos = currentDoorObj.Position
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(targetPos)
                    lastPathCalc = tick()
                end
                
                local movePos = targetPos
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    -- Voa BAIXO pra passar na porta
                    movePos = wp.Position + Vector3.new(0, SETTINGS.TravelHeight, 0)
                    if (root.Position - movePos).Magnitude < 4 then
                        currentWaypointIndex = currentWaypointIndex + 1
                    end
                else
                     movePos = targetPos + Vector3.new(0, SETTINGS.TravelHeight, 0)
                end
                
                local dir = (movePos - root.Position).Unit
                root.NavVelocity.Velocity = dir * SETTINGS.FlySpeed
                root.NavGyro.CFrame = CFrame.lookAt(root.Position, movePos)
            end
        end
        
    elseif currentState == "CLEARING_ROOM" then
        ActionInfo.Text = "Limpando: " .. #enemiesNearby
        
        if #enemiesNearby == 0 then
            currentState = "SEEKING_DOOR" -- Limpou tudo, volta a andar
            return
        end
        
        -- EXPANDE HITBOXES
        for _, mob in ipairs(enemiesNearby) do
            ExpandHitbox(mob)
        end
        
        -- SOBE PRA FICAR SEGURO
        local safePos = root.Position + Vector3.new(0, SETTINGS.CombatHeight - root.Position.Y, 0)
        -- Mantém posição X/Z, só sobe Y
        if root.Position.Y < SETTINGS.CombatHeight then
             root.NavVelocity.Velocity = Vector3.new(0, 20, 0)
        else
             -- Flutua parado
             root.NavVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Olha pro zumbi mais próximo
        if enemiesNearby[1] and enemiesNearby[1]:FindFirstChild("HumanoidRootPart") then
            root.NavGyro.CFrame = CFrame.lookAt(root.Position, enemiesNearby[1].HumanoidRootPart.Position)
        end
        
        -- ATAQUE
        if tick() - lastBasicAttack > 0.5 then
            if tool then tool:Activate() end
            lastBasicAttack = tick()
        end
        if tick() - lastBurstTime > SETTINGS.WaitBeforeSkill + 6 then -- 6s cooldown
            task.spawn(ExecuteCombo)
        end
    end
end)