--[[
    🧟 HUNTER ZOMBIE - THE NAVIGATOR (v11.0 PATHFINDING)
    
    Correção Crítica:
    - Adicionado PathfindingService (GPS).
    - O boneco agora calcula a rota para desviar de paredes e entrar em portas.
    - Se houver parede no caminho -> Segue rota do GPS.
    - Se caminho livre -> Voa direto (Ataque Aéreo).
    
    Mantém:
    - Auto Skills (Z, X, C, V)
    - Voo Físico para empurrar portas.
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
    FlySpeed = 55,       -- Velocidade
    StopDist = 6,        -- Distância pra bater
    FloatHeight = 4,     -- Altura do chão
    SkillDelay = 0.8     -- Delay das skills
}

local SKILLS = {"Z", "X", "C", "V"}
local currentSkillIndex = 1
local lastSkillTime = 0

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieNavigator"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 120)
MainFrame.Position = UDim2.new(0.5, -140, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Laranja GPS
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🗺️ THE NAVIGATOR v11"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 10)
ToggleBtn.Text = "ATIVAR GPS FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function UseSkills()
    if tick() - lastSkillTime > SETTINGS.SkillDelay then
        local key = SKILLS[currentSkillIndex]
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        
        currentSkillIndex = currentSkillIndex + 1
        if currentSkillIndex > #SKILLS then currentSkillIndex = 1 end
        lastSkillTime = tick()
    end
end

-- // BUSCA ALVO (NA PASTA ENTITIES) //
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
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and model.Name ~= "ScopeSStars" then
            local dist = (root.Position - myPos).Magnitude
            if dist < minDist then
                minDist = dist
                closest = model
            end
        end
    end
    return closest
end

-- // SISTEMA DE PATHFINDING (GPS) //
local currentPath = nil
local currentWaypoints = nil
local currentWaypointIndex = 2

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Configuração do Agente (Tamanho do boneco)
    local agentParams = {
        AgentRadius = 3,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    }
    
    local path = PathfindingService:CreatePath(agentParams)
    local success, errorMessage = pcall(function()
        path:ComputeAsync(char.PrimaryPart.Position, targetPos)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        currentPath = path
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2 -- Começa do 2 (o 1 é onde estamos)
        return true
    end
    return false
end

-- // CHECK DE VISÃO (RAYCAST) //
local function CanSeeTarget(targetRoot)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetRoot.Position - origin)
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities.Zombie} -- Ignora eu e zumbis
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(origin, direction, params)
    
    -- Se bateu em algo (parede/porta) antes de chegar no zumbi
    if result and result.Instance then
        -- Se for uma porta (geralmente CanCollide false ou Part solta), tenta atravessar
        if result.Instance.Name:lower():find("door") then return true end
        return false -- Parede sólida
    end
    return true -- Caminho livre
end

-- // VOO FÍSICO //
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
local isRunning = false
local lastPathCalc = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        EnableFlight()
    else
        ToggleBtn.Text = "ATIVAR GPS FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 10)
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
    
    -- Garante voo
    if not root:FindFirstChild("NavVelocity") then EnableFlight() end
    
    -- Auto Equip
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
        
        if dist > SETTINGS.StopDist then
            -- MOVIMENTAÇÃO
            local movePos = tPos -- Padrão: ir direto
            
            -- Checa se precisa de GPS (se tem parede)
            if not CanSeeTarget(target.HumanoidRootPart) then
                Status.Text = "Modo: GPS (Desviando)"
                Status.TextColor3 = Color3.fromRGB(255, 150, 0)
                
                -- Recalcula rota a cada 1s ou se acabou os pontos
                if tick() - lastPathCalc > 1 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(tPos)
                    lastPathCalc = tick()
                end
                
                -- Segue Waypoints
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    movePos = wp.Position + Vector3.new(0, SETTINGS.FloatHeight, 0) -- Mira no waypoint + altura
                    
                    -- Se chegou perto do waypoint, vai pro próximo
                    if (myPos - movePos).Magnitude < 4 then
                        currentWaypointIndex = currentWaypointIndex + 1
                    end
                end
            else
                Status.Text = "Modo: AÉREO (Direto)"
                Status.TextColor3 = Color3.fromRGB(0, 255, 255)
                movePos = tPos + Vector3.new(0, SETTINGS.FloatHeight, 0) -- Mira no zumbi + altura
            end
            
            -- APLICA O VOO
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
            
        else
            -- ATAQUE (Freia)
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            if tool then tool:Activate() end
            UseSkills()
        end
    else
        Status.Text = "Procurando..."
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
