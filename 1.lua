--[[
    🧟 HUNTER ZOMBIE - THE UNDERTAKER (v15.0 ANTI-CORPSE)
    
    Correção Crítica:
    - Dead Check: Verifica se o zumbi "caiu" (Ragdoll). Se estiver deitado, ignora.
    - Patience Timer: Se bater no mesmo alvo por muito tempo (ex: 3s), troca de alvo.
    - Isso evita ficar batendo em zumbis mortos esperando eles sumirem.
    
    Mantém:
    - GPS Indoor (Entra em portas).
    - Combo de Skills com Prioridade.
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
    
    -- Combate
    SkillInterval = 3.5,
    PreCastDelay = 0.35, 
    CastTime = 0.6,
    
    -- Anti-Cadáver (NOVO)
    MaxAttackTime = 2.5,  -- Tempo máximo batendo num zumbi antes de trocar (ajuste se seu dano for baixo)
    IgnoreRagdolls = true -- Ignora zumbis caídos no chão
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local combatState = "ATTACKING" 

-- Blacklist Temporária (Zumbis que demoram pra morrer)
local TempBlacklist = {} 
local currentTargetID = nil
local startAttackTime = 0

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieUndertaker"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 150)
MainFrame.Position = UDim2.new(0.5, -140, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100) -- Cinza Morte
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚰️ UNDERTAKER v15"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local CombatStatus = Instance.new("TextLabel", MainFrame)
CombatStatus.Size = UDim2.new(1, 0, 0, 20)
CombatStatus.Position = UDim2.new(0, 0, 0.45, 0)
CombatStatus.Text = "Alvo: NENHUM"
CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
CombatStatus.BackgroundTransparency = 1
CombatStatus.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Text = "LIGAR FARM INTELIGENTE"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // LÓGICA DE SKILL //
local function CastNextSkillSequence()
    if combatState ~= "ATTACKING" then return end
    combatState = "PREPARING"
    CombatStatus.Text = "✋ PARANDO..."
    CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.PreCastDelay)
    
    combatState = "CASTING"
    local key = SKILLS[skillIndex]
    CombatStatus.Text = "⚡ SKILL: " .. key
    CombatStatus.TextColor3 = Color3.fromRGB(255, 0, 255)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.15)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    task.wait(SETTINGS.CastTime)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    combatState = "ATTACKING"
    CombatStatus.Text = "👊 BATENDO"
    CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
end

-- // VERIFICADOR DE CADÁVER (NOVO!) //
local function IsDeadOrBugged(model)
    -- 1. Check de Blacklist (Tempo Excedido)
    if TempBlacklist[model] and tick() < TempBlacklist[model] then
        return true
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return true end

    -- 2. Check de Ragdoll (Se deitou, morreu)
    if SETTINGS.IgnoreRagdolls then
        -- UpVector aponta pra cima. Se for < 0.5, o boneco tá torto/deitado
        if root.CFrame.UpVector.Y < 0.4 then
            return true 
        end
    end
    
    return false
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
        -- Filtros de Segurança + Anti-Corpse
        if model.Name ~= "ScopeSStars" and not IsDeadOrBugged(model) then
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
    local path = PathfindingService:CreatePath({AgentRadius = 4, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 3})
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
    params.FilterDescendantsInstances = {LocalPlayer.Character, Workspace.Entities.Zombie}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        if result.Instance.Name:lower():find("door") then return true end
        return false
    end
    return true
end

-- // ANTI-STUCK //
local lastCheckPos = Vector3.new(0,0,0)
local lastCheckTime = 0
local function CheckIfStuck()
    local char = LocalPlayer.Character
    if not char then return end
    if tick() - lastCheckTime > 1.0 then
        if (char.PrimaryPart.Position - lastCheckPos).Magnitude < 1 then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 2, 2)
            currentWaypoints = nil 
        end
        lastCheckPos = char.PrimaryPart.Position
        lastCheckTime = tick()
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 50)
        EnableFlight()
        lastCheckPos = LocalPlayer.Character.PrimaryPart.Position
        TempBlacklist = {} -- Reseta lista negra
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
        
        -- SISTEMA DE CRONÔMETRO (NOVO)
        if currentTargetID ~= target then
            currentTargetID = target
            startAttackTime = tick() -- Começa a contar tempo nesse novo alvo
        else
            -- Se já estou no mesmo alvo há muito tempo
            if tick() - startAttackTime > SETTINGS.MaxAttackTime then
                -- Adiciona na lista negra por 3 segundos (tempo pro corpo sumir)
                TempBlacklist[target] = tick() + 3 
                Status.Text = "💀 Ignorando Cadáver..."
                Status.TextColor3 = Color3.fromRGB(100, 100, 100)
                return -- Pula pro próximo frame pra pegar outro alvo
            end
        end

        if dist > SETTINGS.StopDist then
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
            CombatStatus.Text = "🏃 BUSCANDO"
            CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 255)
        else
            -- COMBATE
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
            if combatState == "ATTACKING" then
                if tool then tool:Activate() end
                CombatStatus.Text = "👊 BATENDO"
                CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
                
                if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                    task.spawn(CastNextSkillSequence)
                end
            end
        end
    else
        Status.Text = "Mapa Limpo..."
        CombatStatus.Text = "💤"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
