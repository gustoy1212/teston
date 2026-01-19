--[[
    🧟 HUNTER ZOMBIE - THE NATURAL KILLER (v24.0)
    
    CORREÇÕES:
    1. Invisible Hitbox: Transparency = 1 (Não polui a tela).
    2. Natural Physics: Removeu Noclip do player (respeita paredes).
    3. Height Stabilizer: Evita o "sobe e desce" constante.
    4. Skill Priority: Para de clicar 1.5s antes para garantir a Skill.
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
    AttackHeight = 14,    -- Altura de combate (Segura)
    NavHeight = 4,        -- Altura de navegação (Chão)
    
    -- Hitbox (Invisível mas Gigante)
    HitboxSize = 70,      
    HitboxTransparency = 1, -- 1 = Invisível
    
    ClusterRadius = 60,   
    MaxClusterTargets = 4,
    
    -- Combate (Com Pausa Longa)
    AttackInterval = 0.6, 
    BurstInterval = 6.0,  
    WaitBeforeSkill = 1.2, -- Tempo de silêncio antes da skill
    SkillCastTime = 0.5,
    
    -- Anti-Bug
    MaxAttackTime = 8.0, 
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "HUNTING" 
local movementState = "NAVIGATING" -- NAVIGATING ou ATTACKING
local lastStateChange = 0

local LockedTarget = nil     
local LockedTime = 0         
local ClusterTargets = {}    

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieNatural"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🍃 NATURAL KILLER v24"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE HITBOX (INVISÍVEL) //
local function ExpandHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = SETTINGS.HitboxTransparency -- 1 = Invisível
        root.CanCollide = false
    end
end

local function RestoreHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    local original = model:FindFirstChild("OriginalSize")
    if root and original then
        root.Size = original.Value
        root.Transparency = 1
        root.CanCollide = true 
        original:Destroy()
    end
end

-- // CLUSTER //
local function UpdateCluster(mainTarget)
    for i = #ClusterTargets, 1, -1 do
        local mob = ClusterTargets[i]
        if mob ~= mainTarget then RestoreHitbox(mob) end
    end
    ClusterTargets = {}
    if not mainTarget then return end
    table.insert(ClusterTargets, mainTarget)
    ExpandHitbox(mainTarget)
    
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if #ClusterTargets >= SETTINGS.MaxClusterTargets then break end
            if mob ~= mainTarget and mob.Name ~= "ScopeSStars" then
                local root = mob:FindFirstChild("HumanoidRootPart")
                local mainRoot = mainTarget:FindFirstChild("HumanoidRootPart")
                if root and mainRoot then
                    if (root.Position - mainRoot.Position).Magnitude < SETTINGS.ClusterRadius then
                        table.insert(ClusterTargets, mob)
                        ExpandHitbox(mob)
                    end
                end
            end
        end
    end
end

-- // BUSCA DE ALVO //
local function FindNewTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local folders = {entities:FindFirstChild("Zombie"), entities:FindFirstChild("Boss")}
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, folder in pairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model.Name ~= "ScopeSStars" then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    -- Check se tá vivo (UpVector > 0.4)
                    if root and root.CFrame.UpVector.Y > 0.4 then 
                        local dist = (root.Position - myPos).Magnitude
                        if dist < minDist then minDist = dist closest = model end
                    end
                end
            end
        end
    end
    return closest
end

-- // COMBO DE SKILLS //
local function ExecuteCombo()
    combatState = "BURSTING"
    Status.Text = "🛑 SKILLS..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    -- Pausa longa para parar qualquer clique
    task.wait(SETTINGS.WaitBeforeSkill) 
    
    for _, key in ipairs(SKILLS) do
        Status.Text = "🔥 SOLTANDO: " .. key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    lastBurstTime = tick()
    combatState = "ATTACKING"
    Status.Text = "⚔️ VOLTANDO A BATER"
end

-- // PATHFINDING INTELIGENTE //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    local path = PathfindingService:CreatePath({
        AgentRadius = 3, -- Tamanho real do boneco
        AgentHeight = 5, 
        AgentCanJump = true, 
        WaypointSpacing = 5
    })
    pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- Raycast Simples para ver se tem parede na frente
local function IsPathBlocked(targetPos)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetPos - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        -- Se bater em algo que não seja "Air", tá bloqueado
        if result.Instance.Transparency < 1 and result.Instance.CanCollide then
            return true
        end
    end
    return false
end

-- // VOO COM COLISÃO (SAFETY) //
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
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        LockedTarget = nil 
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Status.Text = "Parado"
        DisableFlight()
        UpdateCluster(nil) 
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
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

    -- ALVO
    if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("HumanoidRootPart") then
        LockedTarget = FindNewTarget()
        LockedTime = tick()
    else
        local tRoot = LockedTarget:FindFirstChild("HumanoidRootPart")
        if tRoot and tRoot.CFrame.UpVector.Y < 0.4 then
             LockedTarget = FindNewTarget() 
             LockedTime = tick()
        elseif tick() - LockedTime > SETTINGS.MaxAttackTime then
             LockedTarget = FindNewTarget() 
             LockedTime = tick()
        end
    end
    
    if LockedTarget then
        local tPos = LockedTarget.HumanoidRootPart.Position
        local myPos = root.Position
        
        UpdateCluster(LockedTarget)
        
        -- Garante que a Hitbox não tem colisão (pra gente entrar nela)
        for _, mob in ipairs(ClusterTargets) do
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then mobRoot.CanCollide = false end
        end
        
        -- ESTABILIZADOR DE ALTURA (Hysteresis)
        -- Só muda de estado se passou 2 segundos para evitar tremor
        if tick() - lastStateChange > 2.0 then
            if IsPathBlocked(tPos + Vector3.new(0, SETTINGS.AttackHeight, 0)) then
                movementState = "NAVIGATING"
                lastStateChange = tick()
            else
                movementState = "ATTACKING"
                lastStateChange = tick()
            end
        end
        
        local targetMovePos = tPos
        
        if movementState == "NAVIGATING" then
            -- MODO CHÃO (Passar Portas)
            ActionInfo.Text = "Navegando..."
            if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                ComputePathTo(tPos)
                lastPathCalc = tick()
            end
            
            if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                local wp = currentWaypoints[currentWaypointIndex]
                targetMovePos = wp.Position + Vector3.new(0, SETTINGS.NavHeight, 0)
                
                if (myPos - targetMovePos).Magnitude < 4 then 
                    currentWaypointIndex = currentWaypointIndex + 1 
                end
            end
        else
            -- MODO AÉREO (Ataque)
            ActionInfo.Text = "Atacando!"
            targetMovePos = tPos + Vector3.new(0, SETTINGS.AttackHeight, 0)
        end
        
        -- Aplica Movimento (Suave)
        local direction = (targetMovePos - myPos).Unit
        -- Se estivermos muito perto, desacelera
        if (myPos - targetMovePos).Magnitude < 1 then
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
        else
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
        end
        root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
        
        -- COMBATE (Se estivermos no modo ataque ou perto do alvo)
        if combatState ~= "BURSTING" then
            -- Só bate se estivermos no modo ataque ou muito perto
            if movementState == "ATTACKING" or (myPos - tPos).Magnitude < 15 then
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
                
                if tick() - lastBurstTime > SETTINGS.BurstInterval then
                    task.spawn(ExecuteCombo)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        ActionInfo.Text = "---"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
        UpdateCluster(nil)
    end
end)