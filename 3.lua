--[[
    🧟 HUNTER ZOMBIE - THE IMMORTAL (v19.0)
    
    Melhorias de Sobrevivência:
    1. BOSS ORBIT: Gira em círculos ao redor do Boss para desviar de tiros.
    2. EMERGENCY RETREAT: Se HP < 40%, voa para o céu (Safe Zone) para curar.
    3. AUTO-REHOOK: Se morrer, o script reconecta sozinho no novo corpo.
    
    Mantém:
    - Skill Fix (Delay 0.8s).
    - Titan Slayer (Identifica Boss).
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
    FlySpeed = 55,       
    
    -- Distâncias e Alturas
    NormalDist = 7,
    BossDist = 18,        -- Distância do Boss (Raio do Círculo)
    FloatHeight = 5,      -- Altura normal
    BossHeight = 15,      -- Altura contra Boss (Mais alto é mais seguro)
    
    -- Sobrevivência (NOVO)
    EmergencyHP = 40,     -- Se HP% for menor que isso, foge!
    RetreatHeight = 60,   -- Altura da fuga (Nuvens)
    OrbitSpeed = 2,       -- Velocidade do giro em volta do Boss
    
    -- Combate (Lento e Preciso)
    AttackInterval = 0.8, 
    SkillInterval = 4.0,  
    PreCastDelay = 0.8,   
    KeyHoldTime = 0.35,   
    CastTime = 0.5,       
    
    -- Anti-Bug
    MaxAttackTime = 4.0,
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
ScreenGui.Name = "ZombieImmortal"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 170)
MainFrame.Position = UDim2.new(0.5, -160, 0.65, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30) -- Azul Noturno
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🛡️ IMMORTAL v19"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
ToggleBtn.Text = "LIGAR FARM (AUTO-REHOOK)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // AUTO-REHOOK (RESSURREIÇÃO) //
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if isRunning then
        Status.Text = "♻️ Renascendo..."
        task.wait(1) -- Espera carregar
        EnableFlight() -- Reativa voo no novo corpo
        Status.Text = "♻️ Reconectado!"
    end
end)

-- // FUNÇÕES AUXILIARES //
local function IsBoss(model)
    if model.Name:lower():find("boss") or model.Name:lower():find("titan") then return true end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root.Size.Y > 6 then return true end
    if model.Parent.Name == "Boss" then return true end
    return false
end

-- // LÓGICA DE SKILL //
local function CastNextSkillSequence()
    if combatState ~= "ATTACKING" then return end
    
    combatState = "PREPARING"
    CombatStatus.Text = "🛑 SKILL PREP..."
    CombatStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    
    task.wait(SETTINGS.PreCastDelay)
    
    combatState = "CASTING"
    local key = SKILLS[skillIndex]
    CombatStatus.Text = "⚡ CAST: " .. key
    CombatStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(SETTINGS.KeyHoldTime)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    task.wait(SETTINGS.CastTime)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    
    combatState = "ATTACKING"
    CombatStatus.Text = "⚔️ COMBATE"
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
isRunning = false -- Global para o Rehook ver

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        TempBlacklist = {}
    else
        ToggleBtn.Text = "LIGAR IMMORTAL FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
        Status.Text = "Parado"
        DisableFlight()
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    CheckVoid()
    if not root:FindFirstChild("NavVelocity") then EnableFlight() end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    -- MONITOR DE EMERGÊNCIA (HP)
    local hpPercent = (hum.Health / hum.MaxHealth) * 100
    if hpPercent < SETTINGS.EmergencyHP then
        Status.Text = "🚨 EMERGÊNCIA! CURANDO..."
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
        CombatStatus.Text = "HP BAIXO (" .. math.floor(hpPercent) .. "%)"
        
        -- Voa pro céu
        root.NavVelocity.Velocity = Vector3.new(0, 50, 0) 
        root.NavGyro.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(0,1,0))
        return -- Interrompe o resto do loop pra focar em fugir
    end

    local target = GetEntityTarget()
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tPos = target.HumanoidRootPart.Position
        local myPos = root.Position
        local dist = (myPos - tPos).Magnitude
        
        local isBossFight = IsBoss(target)
        local safeDist = isBossFight and SETTINGS.BossDist or SETTINGS.NormalDist
        local safeHeight = isBossFight and SETTINGS.BossHeight or SETTINGS.FloatHeight
        
        -- Timeout
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
        
        if dist > safeDist + 5 then -- +5 de margem pra não ficar tremendo
            -- NAVEGAÇÃO (CHEGANDO PERTO)
            local movePos = tPos
            if not CanSeeTarget(target.HumanoidRootPart) then
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(tPos)
                    lastPathCalc = tick()
                end
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    movePos = wp.Position + Vector3.new(0, safeHeight, 0)
                    if (myPos - movePos).Magnitude < 4 then currentWaypointIndex = currentWaypointIndex + 1 end
                end
            else
                movePos = tPos + Vector3.new(0, safeHeight, 0)
            end
            
            local direction = (movePos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(movePos.X, myPos.Y, movePos.Z))
            
            combatState = "ATTACKING"
        else
            -- COMBATE (MODO ORBIT)
            if isBossFight then
                -- Matemática de Giro: Cria um círculo em volta do Boss
                local time = tick() * SETTINGS.OrbitSpeed
                local orbitOffset = Vector3.new(math.cos(time) * safeDist, safeHeight, math.sin(time) * safeDist)
                local orbitPos = tPos + orbitOffset
                
                -- Voa para a posição do giro
                local direction = (orbitPos - myPos).Unit
                root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
                root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos) -- Olha pro Boss
            else
                -- Zumbi normal só freia
                root.NavVelocity.Velocity = Vector3.new(0,0,0)
                root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            end
            
            if combatState == "ATTACKING" then
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
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
