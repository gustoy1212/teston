--[[
    🧟 HUNTER ZOMBIE - THE SIMPLE WALKER (FINAL VERSION)
    
    ESTRATÉGIA "FEIJÃO COM ARROZ":
    1. MOVIMENTAÇÃO: Humanoid:MoveTo() (Nativo do Roblox).
       - O próprio jogo calcula o desvio de paredes.
    2. VELOCIDADE: WalkSpeed 60 + HipHeight 5.
       - Corre rápido e flutua sobre o chão para não ter atrito.
    3. COMBATE: Só bate se estiver COLADO no zumbi (< 6 studs).
       - Não gasta skill nem clique à toa.
    4. ANTI-STUCK: Se parar de andar, PULA automaticamente.
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
    
    -- Andar
    WalkSpeed = 60,      -- Rápido
    HipHeight = 5,       -- Flutua do chão (Essencial pra não arrastar)
    
    -- Combate
    StopDist = 5,        -- Chega até aqui e para
    AttackDist = 6,      -- Começa a bater aqui
    KillRange = 1000,
    
    -- Desbugador
    StuckTime = 0.5,     -- Se ficar 0.5s parado, pula
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0
local isCastingSkill = false 

-- Variáveis de Controle
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0
local lastPos = Vector3.new(0,0,0)
local stuckTimer = 0

-- // GUI //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieSimple"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 120)
MainFrame.Position = UDim2.new(0.5, -125, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "SIMPLE WALKER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "LIGAR / DESLIGAR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //
local function CastSkill()
    if isCastingSkill then return end
    isCastingSkill = true
    
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
    isCastingSkill = false
end

local function GetTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local zombies = entities:FindFirstChild("Zombie")
    if not zombies then return nil end
    
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, model in ipairs(zombies:GetChildren()) do
        if model.Name ~= "ScopeSStars" then
            local root = model:FindFirstChild("HumanoidRootPart")
            -- Verifica vida e se não caiu no chão (morto)
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

local function MoveToTarget(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    -- Calcula Rota (GPS)
    if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
        local path = PathfindingService:CreatePath({
            AgentRadius = 3, AgentHeight = 5, AgentCanJump = true
        })
        pcall(function() path:ComputeAsync(root.Position, targetPos) end)
        
        if path.Status == Enum.PathStatus.Success then
            currentWaypoints = path:GetWaypoints()
            currentWaypointIndex = 2
            lastPathCalc = tick()
        else
            -- Falha no GPS? Vai reto
            hum:MoveTo(targetPos)
            return
        end
    end
    
    -- Segue Rota
    if currentWaypoints and currentWaypoints[currentWaypointIndex] then
        local wp = currentWaypoints[currentWaypointIndex]
        if (root.Position - wp.Position).Magnitude < 4 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
        hum:MoveTo(wp.Position)
        if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
    end
end

-- // LOOP //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        local char = LocalPlayer.Character
        if char then char.Humanoid.HipHeight = 0 end -- Reseta altura
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    -- CONFIGURAÇÃO FÍSICA
    hum.WalkSpeed = SETTINGS.WalkSpeed
    hum.HipHeight = SETTINGS.HipHeight -- Flutua pra não arrastar
    hum.AutoRotate = true
    
    -- ANTI-STUCK (Se a velocidade for 0, PULA)
    if root.Velocity.Magnitude < 1 then
        stuckTimer = stuckTimer + RunService.Heartbeat:Wait()
        if stuckTimer > SETTINGS.StuckTime then
            hum.Jump = true
            -- Dá um passinho pro lado aleatório pra desbugar
            hum:MoveTo(root.Position + Vector3.new(math.random(-5,5), 0, math.random(-5,5)))
            stuckTimer = 0
            currentWaypoints = nil -- Recalcula rota
        end
    else
        stuckTimer = 0
    end
    
    -- LÓGICA
    local target = GetTarget()
    local tool = char:FindFirstChildOfClass("Tool")
    
    -- Auto Equip
    if not tool and not isCastingSkill then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    if target then
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        if dist > SETTINGS.StopDist then
            Status.Text = "Correndo: " .. math.floor(dist)
            MoveToTarget(tRoot.Position)
        else
            Status.Text = "Ataque!"
            hum:MoveTo(root.Position) -- Para
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tRoot.Position.X, root.Position.Y, tRoot.Position.Z))
            
            -- SÓ BATE SE TIVER PERTO (< 6)
            if dist <= SETTINGS.AttackDist and not isCastingSkill then
                if tool then tool:Activate() end
                
                if tick() - lastSkillUsage > 3.5 then
                    task.spawn(CastSkill)
                end
            end
        end
    else
        Status.Text = "Procurando..."
        -- Se não tem zumbi, tenta achar a porta mais próxima
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "Door" or obj.Name == "Porta" then
                if obj:IsA("BasePart") then
                    MoveToTarget(obj.Position)
                    break
                end
            end
        end
    end
end)