--[[
    🧟 HUNTER ZOMBIE - INDOOR MASTER v18 (SMART EDITION)
    
    BASE: v13 (Voo Físico + GPS) - O que você gostou.
    
    NOVAS INTELIGÊNCIAS:
    1. DEAD CHECK: Ignora zumbis caídos/mortos (UpVector < 0.4).
    2. SMART RANGE: Só bate se distância < 6 studs (aprox 2 metros).
    3. AUTO DODGE: Faz "Circle Strafe" (move pros lados) enquanto bate para desviar.
    4. DOOR CRASHER: Identifica portas e força a passagem.
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
    FlySpeed = 65,       -- Aumentei um pouco pra ser mais ágil
    
    -- Distâncias
    StopDist = 6,        -- Distância pra parar perto do zumbi (2 metros aprox)
    AttackDist = 7,      -- Distância pra começar a clicar (Garante o hit)
    FloatHeight = 4,     -- Altura do chão
    
    -- Combate
    AttackInterval = 0.4, 
    SkillInterval = 3.5,
    CastTime = 0.5,
    WaitBeforeSkill = 0.5,
    
    -- Navegação
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    StuckTime = 1.0,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0
local isCastingSkill = false 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieSmartMaster"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧠 SMART MASTER v18"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
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
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
ToggleBtn.Text = "LIGAR FARM (SMART)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function CastNextSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    Status.Text = "🛑 SKILL..."
    
    -- Pausa pra não bugar o clique
    task.wait(SETTINGS.WaitBeforeSkill)
    
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.15)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    task.wait(SETTINGS.CastTime)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    isCastingSkill = false
end

-- // INTELIGÊNCIA DE ALVO (DEAD CHECK) //
local function IsAlive(model)
    if not model then return false end
    local hum = model:FindFirstChild("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 then return false end
    if not root then return false end
    
    -- Verifica se tá deitado (Ragdoll/Morto)
    -- UpVector.Y < 0.4 geralmente significa que caiu no chão
    if root.CFrame.UpVector.Y < 0.4 then return false end
    
    return true
end

local function GetSmartTarget()
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
        if model.Name ~= "ScopeSStars" and IsAlive(model) then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then minDist = dist closest = model end
            end
        end
    end
    return closest
end

-- // PATHFINDING //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- Radius 4 pra não bater na parede
    local path = PathfindingService:CreatePath({
        AgentRadius = 4, 
        AgentHeight = 5, 
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success = pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if success and path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- // VISÃO & PORTAS //
local function CheckLineOfSight(targetRoot)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetRoot.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities.Zombie}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        -- Se for transparente (ar/trigger) passa
        if result.Instance.Transparency == 1 then return "Clear" end
        
        -- IA DE PORTA: Verifica se bateu numa porta
        for _, name in ipairs(SETTINGS.DoorNames) do
            if result.Instance.Name:find(name) or result.Instance.Parent.Name:find(name) then
                return "Door"
            end
        end
        
        return "Wall" -- Parede sólida
    end
    return "Clear"
end

-- // VOO FÍSICO (BodyVelocity) //
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
local stuckCheckPos = Vector3.new(0,0,0)
local stuckCheckTime = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        EnableFlight()
        stuckCheckPos = LocalPlayer.Character.PrimaryPart.Position
    else
        ToggleBtn.Text = "LIGAR FARM (SMART)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
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

    local target = GetSmartTarget()
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tPos = target.HumanoidRootPart.Position
        local myPos = root.Position
        local dist = (myPos - tPos).Magnitude
        
        -- Anti-Stuck Simples
        if tick() - stuckCheckTime > SETTINGS.StuckTime then
            if (myPos - stuckCheckPos).Magnitude < 1 and dist > 10 then
                -- Travado: Pula pra cima e reseta rota
                root.CFrame = root.CFrame * CFrame.new(0, 5, 0)
                currentWaypoints = nil
            end
            stuckCheckPos = myPos
            stuckCheckTime = tick()
        end
        
        if dist > SETTINGS.StopDist then
            -- NAVEGAÇÃO
            isCastingSkill = false
            local movePos = tPos
            
            local sight = CheckLineOfSight(target.HumanoidRootPart)
            
            if sight == "Door" then
                ActionText.Text = "Atravessando Porta..."
                -- Voa direto na porta pra forçar passagem
                movePos = tPos
            elseif sight == "Wall" then
                ActionText.Text = "Desviando Parede (GPS)"
                -- Pathfinding
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
                ActionText.Text = "Voo Livre"
                -- Voo direto (com altura)
                movePos = tPos + Vector3.new(0, SETTINGS.FloatHeight, 0)
            end
            
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
        else
            -- COMBATE (PERTO)
            ActionText.Text = "COMBATE: " .. math.floor(dist) .. "m"
            
            -- ESQUIVA (STRAFE)
            -- Move para os lados usando Seno, criando um movimento de zig-zag/círculo
            local strafeSpeed = 20
            local strafe = root.CFrame.RightVector * math.sin(tick() * 5) * strafeSpeed
            root.NavVelocity.Velocity = strafe
            
            -- Mira no Zumbi
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
            if not isCastingSkill then
                -- SÓ BATE SE ESTIVER NO RANGE DE ATAQUE (Economia de clique)
                if dist <= SETTINGS.AttackDist then
                    if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                        if tool then tool:Activate() end
                        lastBasicAttack = tick()
                    end
                end
                
                if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                    task.spawn(CastNextSkill)
                end
            end
        end
    else
        Status.Text = "Procurando Zumbi Vivo..."
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)