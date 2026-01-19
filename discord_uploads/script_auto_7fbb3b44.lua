--[[
    🧟 HUNTER ZOMBIE - THE DOOR CRASHER (v23.0)
    
    NOVIDADES:
    1. ELEVADOR AUTOMÁTICO: 
       - Se estiver usando GPS (indo até o zumbi), desce para o chão (3 studs) para abrir portas.
       - Se estiver atacando (linha reta), sobe para 12 studs (Sniper Mode).
       
    2. SKILL UNJAMMER (Destravamento):
       - O script agora DESEQUIPA a arma antes de soltar skills e REEQUIPA depois.
       - Isso resolve o problema da arma bloquear o teclado.
       
    3. DEAD CHECK V2: Detecção de morte instantânea por ângulo.
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
    FlySpeed = 60,        
    
    -- Alturas Dinâmicas
    AttackHeight = 12,    -- Altura de Ataque (Baixei um pouco como pediu)
    NavHeight = 3.5,      -- Altura de Navegação (Baixo para passar em portas)
    
    -- Hitbox
    HitboxSize = 70,      
    ClusterRadius = 60,   
    MaxClusterTargets = 4,
    
    -- Combate Burst (Com Unequip)
    AttackInterval = 0.5, 
    BurstInterval = 5.0,  
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.4,
    
    -- Anti-Bug
    MaxAttackTime = 6.0, 
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "HUNTING" 

local LockedTarget = nil     
local LockedTime = 0         
local ClusterTargets = {}    

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieDoorCrasher"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 30) -- Azul Petróleo
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚪 DOOR CRASHER v23"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ActionInfo = Instance.new("TextLabel", MainFrame)
ActionInfo.Size = UDim2.new(1, 0, 0, 20)
ActionInfo.Position = UDim2.new(0, 0, 0.4, 0)
ActionInfo.Text = "Modo: -"
ActionInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionInfo.BackgroundTransparency = 1
ActionInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 60)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // NOCLIP //
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- // FUNÇÕES DE HITBOX //
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
        root.Transparency = 0.8 
        root.Color = Color3.fromRGB(0, 255, 255) 
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
                    -- Check de Morte (UpVector < 0.4 significa que caiu/morreu)
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

-- // COMBO DE SKILLS (MODO DESEQUIPAR) //
local function ExecuteCombo()
    combatState = "BURSTING"
    Status.Text = "🛑 COMBO..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    -- 1. Guarda a Arma (Pra liberar o teclado)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    
    if hum and equippedTool then
        hum:UnequipTools()
        task.wait(0.2)
    end
    
    task.wait(SETTINGS.WaitBeforeSkill) 
    
    -- 2. Solta as Skills
    for _, key in ipairs(SKILLS) do
        Status.Text = "🔥 SKILL: " .. key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    -- 3. Pega a Arma de volta
    if hum and equippedTool then
        hum:EquipTool(equippedTool)
    end
    
    lastBurstTime = tick()
    combatState = "ATTACKING"
    Status.Text = "⚔️ BATENDO"
end

-- // PATHFINDING E VISÃO //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- Radius menor pra passar na porta
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
    pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

local function CanSeeTarget(targetRoot)
    local origin = LocalPlayer.Character.PrimaryPart.Position
    local direction = (targetRoot.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    
    if result and result.Instance then
        -- Se bater em porta ou parede, retorna false (precisa de GPS)
        return false 
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
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        LockedTarget = nil 
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 60)
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
    
    -- Auto Equip (Só se não estiver usando skill)
    local tool = char:FindFirstChildOfClass("Tool")
    if combatState ~= "BURSTING" and not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    -- Busca Alvo
    if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("HumanoidRootPart") then
        LockedTarget = FindNewTarget()
        LockedTime = tick()
        combatState = "HUNTING"
    else
        -- Check se morreu (Caiu)
        local tRoot = LockedTarget:FindFirstChild("HumanoidRootPart")
        if tRoot and tRoot.CFrame.UpVector.Y < 0.4 then
             LockedTarget = FindNewTarget() -- Morreu, troca já
             LockedTime = tick()
        elseif tick() - LockedTime > SETTINGS.MaxAttackTime then
             LockedTarget = FindNewTarget() -- Demorou demais, troca
             LockedTime = tick()
        end
    end
    
    if LockedTarget then
        local tPos = LockedTarget.HumanoidRootPart.Position
        local myPos = root.Position
        
        UpdateCluster(LockedTarget)
        
        -- REFORÇA "SEM COLISÃO" NA HITBOX
        for _, mob in ipairs(ClusterTargets) do
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then mobRoot.CanCollide = false end
        end
        
        -- LÓGICA DO "ELEVADOR" (GPS vs AÉREO)
        local targetHeight = SETTINGS.AttackHeight -- Padrão: Alto (12)
        local movePos = tPos
        local useGPS = false
        
        if not CanSeeTarget(LockedTarget.HumanoidRootPart) then
            -- Tem parede/porta: Usa GPS e DESCE
            useGPS = true
            targetHeight = SETTINGS.NavHeight -- Desce pro chão (3.5)
            
            ActionInfo.Text = "Navegando (Portas)"
            
            if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                ComputePathTo(tPos)
                lastPathCalc = tick()
            end
            
            if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                local wp = currentWaypoints[currentWaypointIndex]
                movePos = wp.Position
                if (myPos - movePos).Magnitude < 4 then currentWaypointIndex = currentWaypointIndex + 1 end
            end
        else
            ActionInfo.Text = "Ataque Aéreo"
        end
        
        -- Aplica Movimento
        local finalPos = Vector3.new(movePos.X, movePos.Y + targetHeight, movePos.Z)
        local direction = (finalPos - myPos).Unit
        
        -- Se estiver perto, para. Se longe, voa.
        if (myPos - finalPos).Magnitude > 2 then
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
        else
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
        end
        root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
        
        -- Combate
        if combatState ~= "BURSTING" then
            if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                if tool then tool:Activate() end
                lastBasicAttack = tick()
            end
            if tick() - lastBurstTime > SETTINGS.BurstInterval then
                task.spawn(ExecuteCombo)
            end
        end
    else
        Status.Text = "Sem Zumbis..."
        ActionInfo.Text = "---"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
        UpdateCluster(nil)
    end
end)