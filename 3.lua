--[[
    🧟 HUNTER ZOMBIE - INDOOR MASTER (v13.0)
    
    Melhorias para Interiores:
    1. AgentRadius Aumentado: O GPS agora traça rotas longe das paredes.
    2. Waypoint Preciso: Curvas mais suaves para entrar em portas.
    3. Monitor Anti-Stuck: Se travar na parede, ele teleporta para desbugar.
    
    Mantém:
    - Auto Skills (Z, X, C, V) com ritmo.
    - Voo Físico.
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
    FlySpeed = 50,       -- Reduzi levemente pra manobrar melhor em prédios
    StopDist = 7,        
    FloatHeight = 4,     
    
    -- Combate
    SkillInterval = 3.0,
    CastTime = 0.6,
    
    -- Navegação
    StuckTime = 1.0,     -- Tempo parado pra considerar travado
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local isCastingSkill = false 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieIndoorMaster"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 130)
MainFrame.Position = UDim2.new(0.5, -140, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏢 INDOOR MASTER v13"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
ToggleBtn.Text = "LIGAR FARM HÍBRIDO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function CastNextSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    local key = SKILLS[skillIndex]
    
    Status.Text = "SKILL: " .. key
    Status.TextColor3 = Color3.fromRGB(255, 0, 255)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.15)
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
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and model.Name ~= "ScopeSStars" then
            local dist = (root.Position - myPos).Magnitude
            if dist < minDist then minDist = dist closest = model end
        end
    end
    return closest
end

-- // PATHFINDING MELHORADO (ANTI-PAREDE) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- AQUI ESTÁ O SEGREDO: AgentRadius = 4 (Mais gordo = Longe da parede)
    -- WaypointSpacing = 3 (Mais preciso em curvas)
    local path = PathfindingService:CreatePath({
        AgentRadius = 4, 
        AgentHeight = 5, 
        AgentCanJump = true,
        WaypointSpacing = 3
    })
    
    local success = pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if success and path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- // ANTI-STUCK SYSTEM //
local lastCheckPos = Vector3.new(0,0,0)
local lastCheckTime = 0

local function CheckIfStuck()
    local char = LocalPlayer.Character
    if not char then return end
    local currentPos = char.PrimaryPart.Position
    
    -- Checa a cada 1 segundo
    if tick() - lastCheckTime > SETTINGS.StuckTime then
        local distMoved = (currentPos - lastCheckPos).Magnitude
        
        -- Se moveu menos de 1 stud e deveria estar andando
        if distMoved < 1 then
            Status.Text = "⚠️ TRAVADO! Desbugando..."
            Status.TextColor3 = Color3.fromRGB(255, 0, 0)
            
            -- Pulo de desbug (Teleporte leve pra cima e pra trás)
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 2, 2)
            
            -- Força recalcular rota
            currentWaypoints = nil 
        end
        
        lastCheckPos = currentPos
        lastCheckTime = tick()
    end
end

-- // VISÃO //
local function CanSeeTarget(targetRoot)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetRoot.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities.Zombie}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        if result.Instance.Name:lower():find("door") then return true end
        return false -- Parede
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
        ToggleBtn.Text = "LIGAR FARM HÍBRIDO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
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
        
        -- Checagem de Travamento (Novo!)
        CheckIfStuck()
        
        if dist > SETTINGS.StopDist then
            -- NAVEGAÇÃO
            isCastingSkill = false
            local movePos = tPos
            
            if not CanSeeTarget(target.HumanoidRootPart) then
                -- Modo GPS (Interior)
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(tPos)
                    lastPathCalc = tick()
                end
                
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    movePos = wp.Position + Vector3.new(0, SETTINGS.FloatHeight, 0)
                    if (myPos - movePos).Magnitude < 4 then currentWaypointIndex = currentWaypointIndex + 1 end
                end
            else
                -- Modo Aéreo (Exterior/Livre)
                movePos = tPos + Vector3.new(0, SETTINGS.FloatHeight, 0)
            end
            
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
        else
            -- COMBATE
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
            if not isCastingSkill then
                if tool then tool:Activate() end
                Status.Text = "COMBATE: Espancando..."
                Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                
                if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                    task.spawn(CastNextSkill)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
