--[[
    🧟 HUNTER ZOMBIE - THE SNIPER (v20.0)
    
    ESTRATÉGIA DE SEGURANÇA (NO REGEN):
    1. Hitbox Expansion: Aumenta o alvo para 60 studs.
    2. High Ground: Voa a 35-40 studs de altura (fora do alcance do zumbi).
    3. Resultado: Você acerta a hitbox gigante, mas o zumbi não te alcança.
    
    ESTRATÉGIA DE COMBO (BURST):
    - Ciclo: Bate -> Para 1s -> Z -> X -> C -> V -> Volta a bater.
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
    
    -- Configuração Sniper
    HitboxSize = 60,      -- Tamanho do Zumbi (Gigante)
    SniperHeight = 35,    -- Altura do voo (Longe do chão, perto da hitbox)
    StopDist = 5,         -- Distância horizontal (ficar em cima dele)
    
    -- Combate Burst (Sequência Completa)
    AttackInterval = 0.5, -- Velocidade dos cliques (M1)
    BurstInterval = 6.0,  -- A cada quanto tempo solta o combo de skills?
    
    WaitBeforeSkill = 1.0, -- Tempo parado antes de começar (Seu pedido: 1s)
    SkillCastTime = 0.5,   -- Tempo entre cada skill (Z..0.5s..X..0.5s..)
    
    -- Anti-Bug
    MaxAttackTime = 5.0,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "ATTACKING" 

local TempBlacklist = {} 
local currentTargetID = nil
local startAttackTime = 0
local currentExpandedTarget = nil -- Para limpar a hitbox depois

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieSniper"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.65, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30) -- Azul Tático
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎯 THE SNIPER v20"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
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
CombatStatus.Text = "Modo: -"
CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
CombatStatus.BackgroundTransparency = 1
CombatStatus.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
ToggleBtn.Text = "LIGAR FARM (HITBOX)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // SISTEMA DE HITBOX EXPANSION //
local function ExpandHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        -- Salva tamanho original pra restaurar se precisar
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        
        -- Transforma em GIGANTE
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.CanCollide = false
        root.Transparency = 0.7 -- Meio invisível pra não poluir
        root.Color = Color3.fromRGB(255, 0, 0) -- Vermelho pra ver onde bater
        currentExpandedTarget = model
    end
end

local function RestoreHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    local original = model:FindFirstChild("OriginalSize")
    if root and original then
        root.Size = original.Value
        root.Transparency = 1
        original:Destroy()
    end
end

-- // AUTO-REHOOK (SE MORRER) //
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if isRunning then
        Status.Text = "♻️ Renascendo..."
        task.wait(1)
        EnableFlight()
    end
end)

-- // FUNÇÃO DE COMBO (Z -> X -> C -> V) //
local function ExecuteFullCombo()
    if combatState ~= "ATTACKING" then return end
    
    -- 1. PAUSA (1 Segundo)
    combatState = "PREPARING"
    CombatStatus.Text = "⏳ PREPARANDO COMBO..."
    CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.WaitBeforeSkill)
    
    -- 2. SEQUÊNCIA DE DISPAROS
    combatState = "CASTING"
    
    for _, key in ipairs(SKILLS) do
        CombatStatus.Text = "🔥 USANDO: " .. key
        CombatStatus.TextColor3 = Color3.fromRGB(255, 0, 255)
        
        -- Aperta
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        
        -- Espera a animação da skill atual
        task.wait(SETTINGS.SkillCastTime)
    end
    
    lastBurstTime = tick()
    
    -- 3. VOLTA A BATER
    combatState = "ATTACKING"
    CombatStatus.Text = "⚔️ RETOMANDO ATAQUE"
    CombatStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
end

-- // BUSCA ALVO (ENTITIES) //
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
                        -- Check se tá vivo/em pé
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

-- // VOO //
local function EnableFlight()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
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
        char.Humanoid.PlatformStand = true
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
isRunning = false 

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        TempBlacklist = {}
    else
        ToggleBtn.Text = "LIGAR FARM (HITBOX)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
        Status.Text = "Parado"
        DisableFlight()
        if currentExpandedTarget then RestoreHitbox(currentExpandedTarget) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    if not root:FindFirstChild("NavVelocity") then EnableFlight() end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    local target = GetEntityTarget()
    
    -- Limpa hitbox do alvo anterior se trocou
    if currentExpandedTarget and currentExpandedTarget ~= target then
        RestoreHitbox(currentExpandedTarget)
        currentExpandedTarget = nil
    end

    if target and target:FindFirstChild("HumanoidRootPart") then
        local tPos = target.HumanoidRootPart.Position
        local myPos = root.Position
        local dist = (myPos - tPos).Magnitude
        
        -- 1. APLICA HITBOX GIGANTE
        ExpandHitbox(target)
        
        -- Timeout System
        if currentTargetID ~= target then
            currentTargetID = target
            startAttackTime = tick()
        else
            -- Se não for Boss e demorar demais
            local isBoss = target.Name:lower():find("boss") or target.Name:lower():find("titan")
            if not isBoss and tick() - startAttackTime > SETTINGS.MaxAttackTime then
                TempBlacklist[target] = tick() + 3 
                RestoreHitbox(target)
                return 
            end
        end
        
        Status.Text = "Alvo: " .. target.Name
        
        -- 2. MOVIMENTAÇÃO (Fica no alto)
        -- Mira na posição + Altura Sniper
        local sniperPos = tPos + Vector3.new(0, SETTINGS.SniperHeight, 0)
        local distToSniperPos = (myPos - sniperPos).Magnitude
        
        if distToSniperPos > 5 then
            -- Navegação
            local movePos = sniperPos
            if not CanSeeTarget(target.HumanoidRootPart) then
                 -- Se tiver parede, usa GPS para chegar perto
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(tPos) -- Vai até o chão do zumbi
                    lastPathCalc = tick()
                end
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    movePos = wp.Position + Vector3.new(0, SETTINGS.SniperHeight, 0) -- Mas voa alto
                    if (myPos - movePos).Magnitude < 4 then currentWaypointIndex = currentWaypointIndex + 1 end
                end
            end
            
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
        else
            -- ESTABILIZA (Freia no ar)
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            -- Olha pra baixo (pro zumbi)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
            
            -- 3. COMBATE
            if combatState == "ATTACKING" then
                -- Ataque Básico (M1)
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
                
                -- Checa hora do Combo
                if tick() - lastBurstTime > SETTINGS.BurstInterval then
                    task.spawn(ExecuteFullCombo)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        CombatStatus.Text = "💤"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
        if currentExpandedTarget then RestoreHitbox(currentExpandedTarget) end
    end
end)
