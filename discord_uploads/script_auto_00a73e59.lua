--[[
    🧟 HUNTER ZOMBIE - THE DUNGEON CRAWLER (v26.0)
    
    ESTRATÉGIA DE PROGRESSÃO:
    1. EXPLORAR: Encontra a porta mais próxima e passa por ela (física real).
    2. ATIVAR: Ao passar, o jogo libera os zumbis da sala.
    3. MAGNETIZAR: Puxa os zumbis da sala atual (raio curto) para matar.
    4. REPETIR: Sala limpa? Vai para a próxima porta.
    
    Mantém:
    - Skill Unjam (Desequipa arma para usar skill).
    - Hitbox Invisível.
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
    WalkSpeed = 25,        -- Velocidade de andar (Não voa muito rápido pra não bugar a porta)
    
    -- Configuração de Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit"}, -- Nomes das portas no jogo
    DoorDistance = 6,      -- Distância para considerar que "passou" pela porta
    
    -- Configuração de Combate (Magnet)
    MagnetRange = 150,     -- Puxa zumbis só da sala atual (não do mapa todo)
    HitboxSize = 20,       -- Tamanho da Hitbox
    
    -- Combate Skills
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.4,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "IDLE" -- IDLE, MOVING_TO_DOOR, KILLING
local visitedDoors = {}    -- Lista negra de portas já abertas

local ActiveTargets = {}   -- Zumbis sendo puxados
local CurrentDoor = nil    -- Porta alvo atual

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieCrawler"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 10) -- Marrom Caverna
MainFrame.BorderColor3 = Color3.fromRGB(255, 150, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🗝️ DUNGEON CRAWLER v26"
Title.TextColor3 = Color3.fromRGB(255, 150, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionInfo = Instance.new("TextLabel", MainFrame)
ActionInfo.Size = UDim2.new(1, 0, 0, 20)
ActionInfo.Position = UDim2.new(0, 0, 0.4, 0)
ActionInfo.Text = "-"
ActionInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionInfo.BackgroundTransparency = 1
ActionInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
ToggleBtn.Text = "LIGAR CRAWLER"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE PORTA //
local function GetNearestDoor()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = 9999
    
    -- Varre o mapa procurando portas
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            -- Verifica se o nome bate com a lista
            local isDoor = false
            for _, name in ipairs(SETTINGS.DoorNames) do
                if obj.Name:find(name) then isDoor = true break end
            end
            
            if isDoor then
                -- Se for model, pega a PrimaryPart ou a primeira parte
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                
                if part and not visitedDoors[obj] then
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

-- // FUNÇÕES DE COMBATE (MAGNET) //
local function PrepareMob(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        root.CanCollide = false
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 1 -- Invisível
        root.Anchored = true
    end
end

local function ReleaseMob(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    local original = model:FindFirstChild("OriginalSize")
    if root then
        root.Anchored = false
        if original then
            root.Size = original.Value
            root.CanCollide = true
            original:Destroy()
        end
    end
end

local function ExecuteCombo()
    Status.Text = "🛑 SKILL COMBO..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    
    -- 1. Desequipa
    if hum and equippedTool then hum:UnequipTools() task.wait(0.2) end
    task.wait(SETTINGS.WaitBeforeSkill) 
    
    -- 2. Solta Skills
    for _, key in ipairs(SKILLS) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    -- 3. Re-equipa
    if hum and equippedTool then hum:EquipTool(equippedTool) end
    
    lastBurstTime = tick()
    Status.Text = "⚔️ LIMPANDO SALA"
end

-- // PATHFINDING //
local currentWaypoints = nil
local currentWaypointIndex = 2
local lastPathCalc = 0

local function ComputePathTo(targetPos)
    local char = LocalPlayer.Character
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    if path.Status == Enum.PathStatus.Success then
        currentWaypoints = path:GetWaypoints()
        currentWaypointIndex = 2
        return true
    end
    return false
end

-- // MAIN LOOP //
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {} -- Reseta portas ao reiniciar
    else
        ToggleBtn.Text = "LIGAR CRAWLER"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
        Status.Text = "Parado"
        for i = #ActiveTargets, 1, -1 do ReleaseMob(ActiveTargets[i]) table.remove(ActiveTargets, i) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if combatState ~= "BURSTING" and not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    -- 1. CHECK DE INIMIGOS NA SALA (MAGNET)
    -- Antes de andar, verifique se tem inimigo perto (Raio 150)
    local entities = Workspace:FindFirstChild("Entities")
    local zombiesNearby = false
    
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then
                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                if mRoot and mRoot.CFrame.UpVector.Y > 0.4 then
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < SETTINGS.MagnetRange then
                        -- ACHOU INIMIGO PERTO! MODO DE COMBATE
                        zombiesNearby = true
                        
                        -- Adiciona na lista de imã se não tiver
                        local alreadyIn = false
                        for _, t in ipairs(ActiveTargets) do if t == mob then alreadyIn = true break end end
                        if not alreadyIn then
                            table.insert(ActiveTargets, mob)
                            PrepareMob(mob)
                        end
                    end
                end
            end
        end
    end
    
    -- Limpa mortos da lista
    for i = #ActiveTargets, 1, -1 do
        local mob = ActiveTargets[i]
        local mRoot = mob:FindFirstChild("HumanoidRootPart")
        if not mob.Parent or not mRoot or mRoot.CFrame.UpVector.Y < 0.4 then
            ReleaseMob(mob)
            table.remove(ActiveTargets, i)
        end
    end
    
    -- LÓGICA DE ESTADO
    if #ActiveTargets > 0 then
        combatState = "KILLING"
        CurrentDoor = nil -- Esquece a porta enquanto luta
        
        Status.Text = "⚠️ LIMPANDO SALA (" .. #ActiveTargets .. ")"
        ActionInfo.Text = "COMBATE"
        
        -- MAGNETISMO
        local magnetPos = root.CFrame * CFrame.new(0, 0, -5) -- 5 studs na frente
        for _, mob in ipairs(ActiveTargets) do
            local mRoot = mob:FindFirstChild("HumanoidRootPart")
            if mRoot then
                mRoot.CFrame = magnetPos
                mRoot.Velocity = Vector3.new(0,0,0)
            end
        end
        
        -- ATAQUE
        hum:MoveTo(root.Position) -- Fica parado
        
        if tick() - lastBasicAttack > 0.5 then
            if tool then tool:Activate() end
            lastBasicAttack = tick()
        end
        if tick() - lastBurstTime > SETTINGS.BurstInterval then
            task.spawn(ExecuteCombo)
        end
        
    else
        combatState = "MOVING_TO_DOOR"
        
        -- 2. BUSCA PORTA
        if not CurrentDoor then
            local doorData = GetNearestDoor()
            if doorData then
                CurrentDoor = doorData
                Status.Text = "🚪 INDO ATÉ: " .. doorData.Object.Name
            else
                Status.Text = "FIM DA LINHA (Sem portas)"
            end
        end
        
        if CurrentDoor then
            local distToDoor = (root.Position - CurrentDoor.Position).Magnitude
            ActionInfo.Text = "Dist: " .. math.floor(distToDoor)
            
            if distToDoor < SETTINGS.DoorDistance then
                -- CHEGOU NA PORTA!
                visitedDoors[CurrentDoor.Object] = true -- Marca como visitada
                CurrentDoor = nil -- Reseta pra procurar a próxima (ou inimigos)
                Status.Text = "✅ PORTA ABERTA"
            else
                -- CAMINHA ATÉ A PORTA
                if tick() - lastPathCalc > 0.5 or not currentWaypoints or currentWaypointIndex > #currentWaypoints then
                    ComputePathTo(CurrentDoor.Position)
                    lastPathCalc = tick()
                end
                
                if currentWaypoints and currentWaypoints[currentWaypointIndex] then
                    local wp = currentWaypoints[currentWaypointIndex]
                    
                    -- Se a porta estiver muito alta ou baixa, ajusta o waypoint
                    local targetWp = wp.Position
                    if (targetWp - root.Position).Magnitude < 4 then
                        currentWaypointIndex = currentWaypointIndex + 1
                    end
                    hum:MoveTo(targetWp)
                else
                    hum:MoveTo(CurrentDoor.Position)
                end
            end
        else
             hum:MoveTo(root.Position) -- Parado
        end
    end
end)