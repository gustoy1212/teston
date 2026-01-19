--[[
    🧟 HUNTER ZOMBIE - TITAN SLAYER (v17.0)
    
    Correções de Boss:
    1. Distância Dinâmica: Fica longe (20 studs) de Bosses para não bugar a física.
    2. Paciência Infinita: Não troca de alvo se o inimigo for um Boss (HP Alto).
    3. Void Rescue: Se cair no chão (Y < -20), teleporta de volta pra cima.
    
    Mantém:
    - Ritmo de Combate (Maestro).
    - Navegação Indoor (GPS).
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
    NormalDist = 7,      -- Distância pra Zumbi Comum
    BossDist = 20,       -- Distância pra Boss (Evita entrar no chão)
    FloatHeight = 5,     -- Altura do voo
    
    -- Combate
    AttackInterval = 0.25,
    SkillInterval = 3.5,
    PreCastDelay = 0.5,
    CastTime = 0.6,
    
    -- Anti-Bug
    MaxAttackTime = 3.0,  -- Tempo limite para zumbis normais
    BossHPThreshold = 500 -- Acima disso é considerado Boss
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
ScreenGui.Name = "ZombieTitanSlayer"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.65, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 5) -- Vermelho Sangue
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "👹 TITAN SLAYER v17"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local TargetInfo = Instance.new("TextLabel", MainFrame)
TargetInfo.Size = UDim2.new(1, 0, 0, 20)
TargetInfo.Position = UDim2.new(0, 0, 0.4, 0)
TargetInfo.Text = "Alvo: NENHUM"
TargetInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInfo.BackgroundTransparency = 1
TargetInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
ToggleBtn.Text = "LIGAR TITAN FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function IsBoss(model)
    -- Checa por Nome
    if model.Name:lower():find("boss") or model.Name:lower():find("titan") then return true end
    
    -- Checa por HP (Se tiver Humanoid, o que descobrimos que não tem, mas vai que o Boss tem)
    -- Alternativa: Se o tamanho for muito grande
    local root = model:FindFirstChild("HumanoidRootPart")
    if root and root.Size.Y > 6 then return true end -- Bosses geralmente são altos
    
    -- Se tiver numa pasta especial (Ex: Entities.Boss)
    if model.Parent.Name == "Boss" then return true end
    
    return false
end

-- // LÓGICA DE SKILL //
local function CastNextSkillSequence()
    if combatState ~= "ATTACKING" then return end
    
    combatState = "PREPARING"
    Status.Text = "✋ PREPARANDO COMBO..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.PreCastDelay)
    
    combatState = "CASTING"
    local key = SKILLS[skillIndex]
    Status.Text = "🔥 ULTRA SKILL: " .. key
    Status.TextColor3 = Color3.fromRGB(255, 100, 0)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.2) -- Segura um pouco mais em Bosses
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    task.wait(SETTINGS.CastTime)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    
    combatState = "ATTACKING"
    Status.Text = "⚔️ ATACANDO"
    Status.TextColor3 = Color3.fromRGB(255, 0, 0)
end

-- // BUSCA ALVO //
local function GetEntityTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    
    -- Procura em Zumbis e Bosses (se tiver pasta separada)
    local folders = {entities:FindFirstChild("Zombie"), entities:FindFirstChild("Boss")}
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, folder in pairs(folders) do
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                -- Checa blacklist temporária (zumbis bugados)
                local isIgnored = TempBlacklist[model] and tick() < TempBlacklist[model]
                
                if model.Name ~= "ScopeSStars" and not isIgnored then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root then
                        -- Check de Ragdoll (Morto)
                        if root.CFrame.UpVector.Y > 0.4 then -- Só pega quem tá em pé
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

-- // PATHFINDING (GPS) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    -- AgentRadius 5 = Super Gordo (Pra não chegar perto de paredes em Boss Fight)
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

-- // ANTI-VOID (RESGATE) //
local function CheckVoid()
    local char = LocalPlayer.Character
    if char and char.PrimaryPart.Position.Y < -20 then
        Status.Text = "⚠️ SAINDO DO CHÃO (VOID)..."
        -- Teleporta pra cima
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
        ToggleBtn.Text = "LIGAR TITAN FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
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
    
    CheckVoid() -- Verifica se caiu no chão
    
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
        
        -- IDENTIFICAÇÃO DE BOSS
        local isBossFight = IsBoss(target)
        local safeDist = isBossFight and SETTINGS.BossDist or SETTINGS.NormalDist
        
        -- MONITOR DE PACIÊNCIA
        if currentTargetID ~= target then
            currentTargetID = target
            startAttackTime = tick()
        else
            -- Só desiste se NÃO for Boss
            if not isBossFight and tick() - startAttackTime > SETTINGS.MaxAttackTime then
                TempBlacklist[target] = tick() + 3 
                return 
            end
        end
        
        TargetInfo.Text = "Alvo: " .. target.Name .. (isBossFight and " [BOSS]" or " [MOB]")
        TargetInfo.TextColor3 = isBossFight and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)

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
            -- COMBATE (FREIO)
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
            
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
        TargetInfo.Text = "---"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
