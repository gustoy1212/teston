--[[
    🧟 HUNTER ZOMBIE - THE HOVER STRIKER (v17.0)
    
    CORREÇÕES:
    1. ZERO ATRITO: Uso 'HipHeight' para fazer o boneco flutuar 5 studs do chão.
       - Isso impede ele de arrastar, tropeçar ou perder velocidade.
    2. SMART TRIGGER: O clique e a skill só ativam se a distância for < 5 studs.
       - Acaba com o problema de bater no vento.
       
    Mantém:
    - Pathfinding (GPS) que está acertando as portas.
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
    
    -- Movimentação
    WalkSpeed = 75,      -- Velocidade Turbo
    JumpPower = 60,      
    HoverHeight = 6,     -- ALTURA DA FLUTUAÇÃO (Aumente se ainda arrastar)
    
    -- Distâncias
    StopDist = 5,        -- Distância pra parar de andar
    AttackTrigger = 5,   -- SÓ BATE SE TIVER NESSA DISTÂNCIA
    KillRange = 1000,    
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    
    -- Combate
    AttackInterval = 0.4, 
    SkillInterval = 3.5,
    CastTime = 0.5,
    WaitBeforeSkill = 0.5,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0
local isCastingSkill = false 

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieHoverStriker"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🛸 HOVER STRIKER v17"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 0)
ToggleBtn.Text = "LIGAR FARM (FLUTUAR)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function GetModelCenter(model)
    if model:IsA("BasePart") then return model.Position end
    local cf, size = model:GetBoundingBox()
    return cf.Position
end

local function GetNearestDoor()
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local isDoor = false
            for _, name in ipairs(SETTINGS.DoorNames) do
                if obj.Name:find(name) then isDoor = true break end
            end
            
            if isDoor then
                local centerPos = GetModelCenter(obj)
                local dist = (centerPos - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = centerPos
                end
            end
        end
    end
    return closest
end

-- // COMBATE //
local function CastNextSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    Status.Text = "🛑 USANDO SKILL..."
    task.wait(SETTINGS.WaitBeforeSkill)
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    task.wait(SETTINGS.CastTime)
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    isCastingSkill = false
end

local function GetZombieTarget()
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
            if root and root.CFrame.UpVector.Y > 0.4 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist and dist < SETTINGS.KillRange then
                    minDist = dist
                    closest = model
                end
            end
        end
    end
    return closest
end

-- // MOVIMENTAÇÃO (GPS) //
local function MoveTo(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    -- Configuração do GPS
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = { Water = 20 }
    })
    
    local success = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        if waypoints and #waypoints >= 2 then
            local nextWp = waypoints[2]
            -- Otimização de curva
            if (root.Position - nextWp.Position).Magnitude < 4 and #waypoints >= 3 then
                nextWp = waypoints[3]
            end
            hum:MoveTo(nextWp.Position)
            if nextWp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
        else
            hum:MoveTo(targetPos)
        end
    else
        hum:MoveTo(targetPos)
        -- Pulo de desbug
        if (root.Velocity * Vector3.new(1,0,1)).Magnitude < 1 then hum.Jump = true end
    end
end

-- // MAIN LOOP //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR FARM (FLUTUAR)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 0)
        Status.Text = "Parado"
        local char = LocalPlayer.Character
        if char then 
            char.Humanoid:MoveTo(char.PrimaryPart.Position) 
            char.Humanoid.HipHeight = 0 -- Reseta altura ao parar
        end 
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    -- 1. APLICA FLUTUAÇÃO (HOVER)
    -- Isso tira o atrito com o chão!
    hum.HipHeight = SETTINGS.HoverHeight
    
    -- 2. STATUS
    hum.WalkSpeed = SETTINGS.WalkSpeed
    hum.JumpPower = SETTINGS.JumpPower
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool and not isCastingSkill then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    local target = GetZombieTarget()
    
    if target then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        local dist = (root.Position - tRoot.Position).Magnitude
        
        if dist > SETTINGS.StopDist then
            -- CAÇAR (CORRENDO E FLUTUANDO)
            Status.Text = "🛸 CAÇANDO: " .. target.Name
            isCastingSkill = false
            
            -- Check de Parede
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char, Workspace.Entities.Zombie}
            local ray = Workspace:Raycast(root.Position, (tRoot.Position - root.Position).Unit * dist, params)
            
            if ray and ray.Instance and ray.Instance.Transparency < 1 then
                ActionText.Text = "Desviando..."
                MoveTo(tRoot.Position)
            else
                ActionText.Text = "Caminho Limpo"
                MoveTo(tRoot.Position)
            end
        else
            -- MODO COMBATE
            hum:MoveTo(root.Position) -- Freia
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
            
            -- *** AQUI ESTÁ A INTELIGÊNCIA ARTIFICIAL DE ATAQUE *** --
            if dist <= SETTINGS.AttackTrigger then
                Status.Text = "⚔️ ATACANDO (Perto)"
                ActionText.Text = "Dist: " .. math.floor(dist)
                
                if not isCastingSkill then
                    if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                        if tool then tool:Activate() end
                        lastBasicAttack = tick()
                    end
                    
                    if tick() - lastSkillUsage > SETTINGS.SkillInterval then
                        task.spawn(CastNextSkill)
                    end
                end
            else
                -- Está perto, mas não o suficiente pra bater (evita bater no vento)
                Status.Text = "👀 MIRANDO..."
                ActionText.Text = "Aproximando..."
                -- Dá um passinho pra frente pra chegar no range
                hum:MoveTo(tRoot.Position) 
            end
        end
    else
        -- SEM ZUMBIS -> VAI PRA PORTA
        Status.Text = "🚪 CORRENDO P/ SAÍDA"
        local doorPos = GetNearestDoor()
        
        if doorPos then
            local dist = (root.Position - doorPos).Magnitude
            if dist < 4 then
                Status.Text = "✅ PASSANDO..."
                hum:MoveTo(doorPos + (doorPos - root.Position).Unit * 5)
            else
                ActionText.Text = "GPS: Porta"
                MoveTo(doorPos)
            end
        else
            Status.Text = "MAPA LIMPO"
        end
    end
end)