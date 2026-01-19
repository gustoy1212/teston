--[[
    🧟 HUNTER ZOMBIE - DOMAIN EXPANSION (v29.0)
    
    HIBRIDO PERFEITO:
    1. CRAWLER: Anda até a porta para ativar a sala (igual o script v28).
    2. DOMAIN: Assim que os zumbis aparecem, EXPANDIMOS a hitbox deles para 80 studs.
       - Eles ficam gigantes e invisíveis.
       - Você bate no ar e acerta todos da sala ao mesmo tempo.
       
    3. FILTRO DE ISCA: Ignora "ScopeSStars" e foca nos zumbis reais.
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
    WalkSpeed = 50,       -- Velocidade para chegar na porta rápido
    
    -- DOMAIN EXPANSION (A Mágica)
    ExpansionSize = 80,   -- Tamanho da Hitbox do Zumbi (Cobre a sala)
    KillRange = 200,      -- Se o zumbi estiver nessa distância, expande ele
    
    -- Portas (Para ativar o spawn)
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"}, 
    DoorDistance = 6,
    
    -- Skills
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.4,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local currentState = "SEEKING_DOOR" 
local currentDoorObj = nil
local visitedDoors = {} 
local ExpandedMobs = {} -- Lista de mobs que já expandimos

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieDomain"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 170)
MainFrame.Position = UDim2.new(0.5, -175, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 30) -- Roxo Domínio
MainFrame.BorderColor3 = Color3.fromRGB(150, 50, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🤞 DOMAIN EXPANSION v29"
Title.TextColor3 = Color3.fromRGB(200, 100, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionInfo = Instance.new("TextLabel", MainFrame)
ActionInfo.Size = UDim2.new(1, 0, 0, 25)
ActionInfo.Position = UDim2.new(0, 0, 0.45, 0)
ActionInfo.Text = "-"
ActionInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionInfo.BackgroundTransparency = 1
ActionInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 80)
ToggleBtn.Text = "EXPANDIR DOMÍNIO (FARM)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO: EXPANDIR ALVO (A Lógica do seu script antigo) //
local function ExpandTarget(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Evita expandir quem já tá expandido pra não lagar
    if ExpandedMobs[mob] then return end
    
    -- Salva tamanho original
    if not mob:FindFirstChild("OriginalSize") then
        local val = Instance.new("Vector3Value", mob)
        val.Name = "OriginalSize"
        val.Value = root.Size
    end
    
    -- MÁGICA: Transforma o mob numa sala inteira
    root.CanCollide = false -- Importante pra não te jogar longe
    root.Size = Vector3.new(SETTINGS.ExpansionSize, SETTINGS.ExpansionSize, SETTINGS.ExpansionSize)
    root.Transparency = 0.8 -- Quase invisível
    root.Color = Color3.fromRGB(100, 0, 255) -- Roxo pra identificar
    
    ExpandedMobs[mob] = true
end

local function RestoreTarget(mob)
    if not mob then return end
    ExpandedMobs[mob] = nil
    local root = mob:FindFirstChild("HumanoidRootPart")
    local original = mob:FindFirstChild("OriginalSize")
    if root and original then
        root.Size = original.Value
        root.Transparency = 1
        root.CanCollide = true
        original:Destroy()
    end
end

-- // FUNÇÕES DE COMBATE //
local function ExecuteCombo()
    Status.Text = "🛑 SKILL COMBO..."
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    
    -- Unequip para destravar skills
    if hum and equippedTool then hum:UnequipTools() task.wait(0.2) end
    task.wait(SETTINGS.WaitBeforeSkill)
    
    for _, key in ipairs(SKILLS) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    -- Re-equip
    if hum and equippedTool then hum:EquipTool(equippedTool) end
    lastBurstTime = tick()
end

-- // PATHFINDING (Ir até a porta) //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function WalkTo(targetPos)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    
    if tick() - lastPathCalc > 1.0 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
        pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
        if path.Status == Enum.PathStatus.Success then
            currentWaypoints = path:GetWaypoints()
            currentWaypointIndex = 2
            lastPathCalc = tick()
        else
            hum:MoveTo(targetPos)
            return
        end
    end
    
    if currentWaypoints and currentWaypoints[currentWaypointIndex] then
        local wp = currentWaypoints[currentWaypointIndex]
        if (char.PrimaryPart.Position - wp.Position).Magnitude < 4 then
            currentWaypointIndex = currentWaypointIndex + 1
        end
        hum:MoveTo(wp.Position)
        if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
    else
        hum:MoveTo(targetPos)
    end
end

-- // PORTAS //
local function GetNearestUnvisitedDoor()
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
            
            if isDoor and not visitedDoors[obj] then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {Object = obj, Position = part.Position}
                    end
                end
            end
        end
    end
    return closest
end

-- // LOOP PRINCIPAL //
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR (DOMÍNIO ABERTO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {}
        currentState = "SEEKING_DOOR"
    else
        ToggleBtn.Text = "EXPANDIR DOMÍNIO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 80)
        Status.Text = "Domínio Fechado"
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.PrimaryPart.Position)
            char.Humanoid.WalkSpeed = 16
        end
        -- Restaura mobs
        for mob, _ in pairs(ExpandedMobs) do RestoreTarget(mob) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    -- Speed Hack (Pra chegar na porta)
    hum.WalkSpeed = SETTINGS.WalkSpeed
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if currentState ~= "COMBOING" and not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    -- 1. DETECÇÃO DE INIMIGOS (Ignora iscas)
    local targets = {}
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then -- Filtro de Nome (Anti-Isca)
                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                local mHum = mob:FindFirstChild("Humanoid")
                
                -- Se tiver vivo e perto
                if mRoot and mHum and mHum.Health > 0 then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < SETTINGS.KillRange then
                        table.insert(targets, mob)
                    end
                end
            end
        end
    end
    
    -- 2. DECISÃO DE ESTADO
    if #targets > 0 then
        -- MODO DOMÍNIO: Tem zumbis na sala!
        currentState = "DOMAIN_EXPANSION"
        currentDoorObj = nil -- Esquece a porta, foca em matar
        
        Status.Text = "🤞 EXTERMÍNIO: " .. #targets
        ActionInfo.Text = "HITBOX EXPANDIDA"
        
        -- FICA PARADO
        hum:MoveTo(root.Position)
        
        -- APLICA A TÉCNICA (Expandir todos os alvos)
        for _, mob in ipairs(targets) do
            ExpandTarget(mob)
        end
        
        -- ATACA (No vento mesmo, a hitbox gigante pega)
        if tick() - lastBasicAttack > 0.4 then
            if tool then tool:Activate() end
            lastBasicAttack = tick()
        end
        
        -- SKILLS
        if tick() - lastBurstTime > 6.0 then
            task.spawn(ExecuteCombo)
        end
        
    else
        -- MODO CRAWLER: Sala limpa, procura porta
        currentState = "SEEKING_DOOR"
        ActionInfo.Text = "BUSCANDO SALA"
        
        -- Limpa lista de expandidos pra economizar memória
        for mob, _ in pairs(ExpandedMobs) do 
            if not mob.Parent or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then
                ExpandedMobs[mob] = nil
            end
        end

        if not currentDoorObj then
            local doorData = GetNearestUnvisitedDoor()
            if doorData then
                currentDoorObj = doorData
                Status.Text = "🏃 PORTA: " .. doorData.Object.Name
            else
                Status.Text = "MAPA LIMPO (Fim)"
                hum:MoveTo(root.Position)
            end
        end
        
        if currentDoorObj then
            local dist = (root.Position - currentDoorObj.Position).Magnitude
            if dist < SETTINGS.DoorDistance then
                visitedDoors[currentDoorObj.Object] = true
                currentDoorObj = nil
                Status.Text = "✅ SALA ATIVADA"
            else
                WalkTo(currentDoorObj.Position)
            end
        end
    end
end)