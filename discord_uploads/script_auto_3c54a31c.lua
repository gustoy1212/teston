--[[
    🧟 HUNTER ZOMBIE - INDOOR MASTER REMASTERED (v13.5)
    
    BASEADO NO V13 (O QUE FUNCIONOU MELHOR):
    - Navegação Híbrida (GPS Indoor + Voo Outdoor).
    
    MELHORIAS APLICADAS:
    1. SKILL FIX: Adicionei "AttackInterval" (0.5s) para parar de floodar clique e deixar a skill sair.
    2. ANTI-CORPSE: Verifica se o zumbi caiu (UpVector < 0.4) para ignorar mortos.
    3. PORTAS: Se bater numa porta, ele força a passagem.
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
    StopDist = 7,        
    FloatHeight = 4,     
    
    -- Combate Ajustado (Pra Skill Sair)
    AttackInterval = 0.5, -- Bate devagar (2x por segundo)
    SkillInterval = 3.5,
    CastTime = 0.5,
    WaitBeforeSkill = 0.5, -- Pausa antes da skill
    
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
ScreenGui.Name = "ZombieIndoorRemaster"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 130)
MainFrame.Position = UDim2.new(0.5, -140, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏠 INDOOR REMASTER v13.5"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function CastNextSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    
    Status.Text = "🛑 PREPARANDO SKILL..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.WaitBeforeSkill) -- Pausa os cliques
    
    local key = SKILLS[skillIndex]
    Status.Text = "🔥 SKILL: " .. key
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    task.wait(SETTINGS.CastTime)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    isCastingSkill = false
    Status.Text = "⚔️ VOLTANDO A BATER"
end

-- // BUSCA ALVO (COM ANTI-CORPSE) //
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
            -- Check se tá vivo (UpVector > 0.4)
            if root and root.CFrame.UpVector.Y > 0.4 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then minDist = dist closest = model end
            end
        end
    end
    return closest
end

-- // PATHFINDING (Mantido do v13) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- AgentRadius 4 afasta das paredes
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
    
    if tick() - lastCheckTime > SETTINGS.StuckTime then
        local distMoved = (currentPos - lastCheckPos).Magnitude
        
        if distMoved < 1 then
            Status.Text = "⚠️ DESBUGANDO..."
            
            -- Tenta pular e ir pra trás
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 3, 3)
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
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
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
            -- NAVEGAÇÃO
            isCastingSkill = false
            local movePos = tPos
            
            if not CanSeeTarget(target.HumanoidRootPart) then
                -- Modo GPS
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
                -- Modo Aéreo
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
                -- ATTACK INTERVAL (0.5s) - O Segredo das Skills
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
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)