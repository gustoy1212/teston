--[[
    🧟 HUNTER ZOMBIE - INDOOR MASTER v14 (AI DOOR EDITION)
    
    NOVA INTELIGÊNCIA:
    1. Door Finder: Se houver parede entre você e o zumbi, o script ignora o zumbi
       e foca em encontrar a PORTA mais próxima para passar.
    2. Pathfinding Gordo: Aumentei o AgentRadius para 5. O boneco anda no meio do corredor,
       longe das paredes para não travar.
       
    Mantém:
    - Skill Fix (Intervalos de ataque).
    - Anti-Cadáver.
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
    FlySpeed = 50,       
    StopDist = 7,        
    FloatHeight = 4,     
    
    -- Configuração de Portas (A IA procura esses nomes)
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    
    -- Combate
    AttackInterval = 0.5,
    SkillInterval = 3.5,
    CastTime = 0.5,
    WaitBeforeSkill = 0.5,
    
    -- Navegação
    StuckTime = 1.0,     
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0
local isCastingSkill = false 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieDoorAI"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧠 INDOOR AI v14"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
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
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
ToggleBtn.Text = "LIGAR FARM (COM IA)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO: ENCONTRAR PORTA MAIS PRÓXIMA //
local function GetNearestDoor()
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
            
            if isDoor then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = part.Position
                    end
                end
            end
        end
    end
    return closest
end

-- // COMBATE //
local function CastNextSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    Status.Text = "🛑 SKILL..."
    task.wait(SETTINGS.WaitBeforeSkill)
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    task.wait(SETTINGS.CastTime)
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    isCastingSkill = false
end

-- // BUSCA ALVO //
local function GetEntityTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local zombies = entities:FindFirstChild("Zombie")
    if not zombies then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, model in ipairs(zombies:GetChildren()) do
        if model.Name ~= "ScopeSStars" then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root and root.CFrame.UpVector.Y > 0.4 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then minDist = dist closest = model end
            end
        end
    end
    return closest
end

-- // PATHFINDING INTELIGENTE //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- AgentRadius 5 = Boneco Gordo (Fica longe da parede)
    local path = PathfindingService:CreatePath({
        AgentRadius = 5, 
        AgentHeight = 5, 
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {
            Water = 20,
            Zone = 10
        }
    })
    
    local success = pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if success and path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- // ANTI-STUCK //
local lastCheckPos = Vector3.new(0,0,0)
local lastCheckTime = 0

local function CheckIfStuck()
    local char = LocalPlayer.Character
    if not char then return end
    local currentPos = char.PrimaryPart.Position
    
    if tick() - lastCheckTime > SETTINGS.StuckTime then
        local distMoved = (currentPos - lastCheckPos).Magnitude
        if distMoved < 1 then
            Status.Text = "⚠️ DESBUGANDO..."
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
            currentWaypoints = nil 
        end
        lastCheckPos = currentPos
        lastCheckTime = tick()
    end
end

-- // VISÃO (RAYCAST) //
local function CanSeeTarget(targetRoot)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetRoot.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities.Zombie}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        -- Se não for ar ou agua, é parede
        if result.Instance.Transparency < 1 then return false end
    end
    return true
end

-- // VOO //
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

-- // MAIN LOOP //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 50)
        EnableFlight()
        lastCheckPos = LocalPlayer.Character.PrimaryPart.Position
    else
        ToggleBtn.Text = "LIGAR FARM (IA)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
        Status.Text = "Parado"
        DisableFlight()
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not root:FindFirstChild("NavVelocity") then EnableFlight() end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    local target = GetEntityTarget()
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tPos = target.HumanoidRootPart.Position
        local myPos = root.Position
        local dist = (myPos - tPos).Magnitude
        
        CheckIfStuck()
        
        if dist > SETTINGS.StopDist then
            -- NAVEGAÇÃO INTELIGENTE
            isCastingSkill = false
            
            -- LÓGICA DE DECISÃO DA IA
            local finalDestination = tPos
            local useGPS = false
            
            if not CanSeeTarget(target.HumanoidRootPart) then
                -- TEM PAREDE!
                ActionText.Text = "Obstáculo Detectado!"
                useGPS = true
                
                -- Procura uma porta para usar como rota de fuga
                local doorPos = GetNearestDoor()
                if doorPos then
                    -- Se a porta estiver mais perto que o zumbi (ou no caminho), vai nela
                    local doorDist = (doorPos - myPos).Magnitude
                    if doorDist < dist then
                        ActionText.Text = "Desviando p/ Porta"
                        finalDestination = doorPos
                    end
                end
            else
                ActionText.Text = "Caminho Livre"
            end
            
            -- Executa Movimento
            if useGPS then
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(finalDestination)
                    lastPathCalc = tick()
                end
                
                local movePos = finalDestination
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    movePos = wp.Position + Vector3.new(0, SETTINGS.FloatHeight, 0)
                    if (myPos - movePos).Magnitude < 4 then currentWaypointIndex = currentWaypointIndex + 1 end
                end
                
                local direction = (movePos - myPos).Unit
                root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
                root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
            else
                -- Voo Direto
                local movePos = tPos + Vector3.new(0, SETTINGS.FloatHeight, 0)
                local direction = (movePos - myPos).Unit
                root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
                root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
            end
        else
            -- COMBATE
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
            ActionText.Text = "Combate"
            
            if not isCastingSkill then
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
                
                if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                    task.spawn(CastNextSkill)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        ActionText.Text = "-"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)