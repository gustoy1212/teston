--[[
    🧟 HUNTER ZOMBIE - THE SHADOW WALKER (v31.0)
    
    ESTILO DE JOGO:
    - Movimentação: 100% Chão (Pathfinding). Respeita paredes e portas.
    - Combate: "Hit & Teleport". Bate de frente, mas se o zumbi for revidar,
      teleporta para as COSTAS dele instantaneamente.
    - Zero Bugs: Sistema Anti-Stuck monitora se travou e destrava sozinho.
    - Skills: DESATIVADAS (Foco total em ataque básico rápido).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    
    -- Combate e Esquiva
    AttackDist = 5,       -- Distância para começar a bater
    DodgeDist = 4,        -- SE CHEGAR NESSA DISTÂNCIA, TELEPORTA PRAS COSTAS
    BackstabOffset = 3,   -- Quantos metros atrás do zumbi teleportar
    
    -- Navegação
    KillRange = 250,      -- Raio de busca de inimigos
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    
    -- Anti-Stuck
    StuckTimeout = 1.5,   -- Segundos parado para considerar "preso"
}

local currentTarget = nil
local lastPos = Vector3.new(0,0,0)
local lastMoveTime = 0
local isStuck = false
local stuckTimer = 0

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieShadowWalker"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 140)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🥋 SHADOW WALKER v31"
Title.TextColor3 = Color3.fromRGB(100, 100, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
ToggleBtn.Text = "LIGAR FARM (NO-FLY)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function GetNearestEntity(typeSearch)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local closest = nil
    local minDist = 9999
    
    if typeSearch == "Zombie" then
        local entities = Workspace:FindFirstChild("Entities")
        if entities and entities:FindFirstChild("Zombie") then
            for _, mob in ipairs(entities.Zombie:GetChildren()) do
                if mob.Name ~= "ScopeSStars" then
                    local mRoot = mob:FindFirstChild("HumanoidRootPart")
                    local mHum = mob:FindFirstChild("Humanoid")
                    if mRoot and mHum and mHum.Health > 0 then
                        local dist = (mRoot.Position - root.Position).Magnitude
                        if dist < minDist and dist < SETTINGS.KillRange then
                            minDist = dist
                            closest = mob
                        end
                    end
                end
            end
        end
    elseif typeSearch == "Door" then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local isDoor = false
                for _, name in ipairs(SETTINGS.DoorNames) do
                    if obj.Name:find(name) then isDoor = true break end
                end
                if isDoor then
                    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = part
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- // PATHFINDING INTELIGENTE //
local function MoveToTarget(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    -- Calcula rota desviando de paredes
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(root.Position, targetPos)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        -- Vai para o segundo waypoint (o primeiro é onde estamos)
        if waypoints and waypoints[2] then
            local nextPoint = waypoints[2]
            hum:MoveTo(nextPoint.Position)
            if nextPoint.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
        else
            hum:MoveTo(targetPos) -- Caminho reto se estiver perto
        end
    else
        hum:MoveTo(targetPos) -- Falha no path, tenta reto
    end
end

-- // SISTEMA ANTI-STUCK //
local function CheckStuck()
    local char = LocalPlayer.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    
    if (root.Position - lastPos).Magnitude < 0.5 then
        stuckTimer = stuckTimer + RunService.Heartbeat:Wait()
        if stuckTimer > SETTINGS.StuckTimeout then
            isStuck = true
            Status.Text = "⚠️ PRESO! DESBUGANDO..."
            -- Pula e anda pra um lado aleatório
            hum.Jump = true
            local randomOffset = Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            hum:MoveTo(root.Position + randomOffset)
            task.wait(0.5)
            stuckTimer = 0
            isStuck = false
        end
    else
        stuckTimer = 0
        lastPos = root.Position
    end
end

-- // MAIN LOOP //
local isActive = false

ToggleBtn.MouseButton1Click:Connect(function()
    isActive = not isActive
    if isActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        lastPos = LocalPlayer.Character.HumanoidRootPart.Position
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
        Status.Text = "Parado"
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
    end
end)

RunService.Heartbeat:Connect(function()
    if not isActive then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local tool = char:FindFirstChildOfClass("Tool")
    
    if not hum or not root then return end
    
    -- Auto Equip
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    -- Checa se travou na parede
    CheckStuck()
    if isStuck then return end -- Se tá desbugando, não faz nada
    
    -- LÓGICA DE ALVO
    local target = GetNearestEntity("Zombie")
    
    if target then
        currentTarget = target
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        
        if tRoot then
            local dist = (root.Position - tRoot.Position).Magnitude
            Status.Text = "⚔️ ALVO: " .. target.Name .. " (" .. math.floor(dist) .. "m)"
            
            -- LÓGICA DE REFLEXO (ESQUIVA)
            if dist < SETTINGS.DodgeDist then
                -- PERIGO! Muito perto, ele vai bater.
                -- Teleporta para as costas (Backstab)
                local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BackstabOffset)
                root.CFrame = CFrame.new(backPos.Position, tRoot.Position) -- Vai pras costas olhando pra ele
            else
                -- Longe? Anda até ele (GPS)
                MoveToTarget(tRoot.Position)
            end
            
            -- ATAQUE
            if dist < SETTINGS.AttackDist + 2 then
                if tool then tool:Activate() end
            end
        end
    else
        -- SEM ZUMBIS? BUSCA PORTA
        Status.Text = "🚪 BUSCANDO PORTA..."
        local door = GetNearestEntity("Door")
        if door then
            local dist = (root.Position - door.Position).Magnitude
            if dist < 4 then
                Status.Text = "✅ NA PORTA"
                -- Força andar reto pra passar
                hum:MoveTo(door.Position + (door.CFrame.LookVector * 5)) 
            else
                MoveToTarget(door.Position)
            end
        else
            Status.Text = "MAPA LIMPO / PERDIDO"
        end
    end
end)