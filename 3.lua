--[[
    🧟 HUNTER ZOMBIE - SKILL UNLEASHED (v18.0)
    
    CORREÇÃO DE SKILL:
    1. AttackInterval aumentado para 0.8s (Deixa a animação terminar).
    2. KeyHoldTime aumentado para 0.35s (Segura a tecla com vontade).
    3. Pausa Dramática: Para de bater 1.0s antes de soltar skill.
    
    Mantém:
    - Titan Slayer (Boss Mode).
    - Undertaker (Anti-Cadáver).
    - Navigator (GPS).
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
    
    -- Distâncias
    NormalDist = 7,
    BossDist = 20,
    FloatHeight = 5,
    
    -- COMBATE AJUSTADO (O SEGREDO ESTÁ AQUI)
    AttackInterval = 0.8, -- Bate devagar (quase 1 por segundo) pra não travar animação
    SkillInterval = 4.0,  -- Usa skill a cada 4 segundos
    
    PreCastDelay = 0.8,   -- Fica 0.8s SEM FAZER NADA antes de soltar skill
    KeyHoldTime = 0.35,   -- Segura a tecla da skill por 0.35s
    CastTime = 0.5,       -- Espera 0.5s depois da skill
    
    -- Anti-Bug
    MaxAttackTime = 4.0,
    BossHPThreshold = 500
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0
local combatState = "ATTACKING" 

local TempBlacklist = {} 
local currentTargetID = nil
local startAttackTime = 0

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieSkillFix"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.65, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 20, 5) -- Verde Escuro Tático
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧪 SKILL FIXER v18"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local CombatStatus = Instance.new("TextLabel", MainFrame)
CombatStatus.Size = UDim2.new(1, 0, 0, 20)
CombatStatus.Position = UDim2.new(0, 0, 0.4, 0)
CombatStatus.Text = "Ação: -"
CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
CombatStatus.BackgroundTransparency = 1
CombatStatus.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
ToggleBtn.Text = "LIGAR FARM (SLOW MODE)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function IsBoss(model)
    if model.Name:lower():find("boss") or model.Name:lower():find("titan") then return true end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root.Size.Y > 6 then return true end
    if model.Parent.Name == "Boss" then return true end
    return false
end

-- // LÓGICA DE SKILL ROBUSTA //
local function CastNextSkillSequence()
    if combatState ~= "ATTACKING" then return end
    
    -- 1. PARAR TUDO (SINAL VERMELHO)
    combatState = "PREPARING"
    CombatStatus.Text = "🛑 PARANDO ATAQUE..."
    CombatStatus.TextColor3 = Color3.fromRGB(255, 50, 50)
    
    -- Espera a animação do ataque básico acabar totalmente
    task.wait(SETTINGS.PreCastDelay)
    
    -- 2. SOLTAR SKILL (SINAL AMARELO)
    combatState = "CASTING"
    local key = SKILLS[skillIndex]
    CombatStatus.Text = "⚡ SEGURANDO: " .. key
    CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    -- Segura a tecla com vontade
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(SETTINGS.KeyHoldTime) -- Segura por 0.35s
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    -- 3. ESPERA PÓS-CAST
    task.wait(SETTINGS.CastTime)
    
    -- Prepara próxima
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    
    -- 4. VOLTA A BATER (SINAL VERDE)
    combatState = "ATTACKING"
    CombatStatus.Text = "⚔️ BATENDO (Lento)"
    CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
end

-- // BUSCA ALVO //
local function GetEntityTarget()
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
                local isIgnored = TempBlacklist[model] and tick() < TempBlacklist[model]
                if model.Name ~= "ScopeSStars" and not isIgnored then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root then
                        if root.CFrame.UpVector.Y > 0.4 then
                            local dist = (root.Position - myPos).Magnitude
                            if dist < minDist then minDist = dist closest = model end
                        end
                    end
                end
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
    local path = PathfindingService:CreatePath({AgentRadius = 5, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
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
        if result.Instance.Name:lower():find("door") then return true end
        return false
    end
    return true
end

-- // ANTI-VOID //
local function CheckVoid()
    local char = LocalPlayer.Character
    if char and char.PrimaryPart.Position.Y < -20 then
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 50, 0)
        char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        TempBlacklist = {}
    else
        ToggleBtn.Text = "LIGAR FARM (SLOW MODE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
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
    
    CheckVoid()
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
        
        local isBossFight = IsBoss(target)
        local safeDist = isBossFight and SETTINGS.BossDist or SETTINGS.NormalDist
        
        if currentTargetID ~= target then
            currentTargetID = target
            startAttackTime = tick()
        else
            if not isBossFight and tick() - startAttackTime > SETTINGS.MaxAttackTime then
                TempBlacklist[target] = tick() + 3 
                return 
            end
        end
        
        Status.Text = "Alvo: " .. target.Name
        
        if dist > safeDist then
            -- NAVEGAÇÃO
            local movePos = tPos
            if not CanSeeTarget(target.HumanoidRootPart) then
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
                movePos = tPos + Vector3.new(0, SETTINGS.FloatHeight, 0)
            end
            
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
            
            combatState = "ATTACKING"
        else
            -- COMBATE
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
            if combatState == "ATTACKING" then
                -- ATAQUE LENTO (0.8s)
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
                
                -- TENTA USAR SKILL
                if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                    task.spawn(CastNextSkillSequence)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        CombatStatus.Text = "💤"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
