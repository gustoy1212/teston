--[[
    🧟 HUNTER ZOMBIE - THE CLUSTER BOMB (v21.0)
    
    ESTRATÉGIA NOVA:
    1. TARGET LOCK: Escolhe 1 zumbi e vai até o fim (sem indecisão).
    2. CLUSTER MODE: Expande a hitbox do Alvo + 3 Vizinhos próximos (Total 4).
    3. POSITIONING: Voa exatamente 35 studs acima da cabeça do alvo.
    4. COMBO: Para de bater -> Solta todas as skills -> Volta a bater.
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
    FlySpeed = 65,        -- Aumentei para chegar rápido e não ficar "olhando"
    
    -- Posicionamento
    HoverHeight = 35,     -- Altura exata que você pediu
    HitboxSize = 60,      -- Tamanho Gigante
    ClusterRadius = 60,   -- Distância para pegar zumbis vizinhos
    MaxClusterTargets = 4,-- Quantos zumbis atacar ao mesmo tempo
    
    -- Combate Burst
    AttackInterval = 0.5, 
    BurstInterval = 5.0,  
    WaitBeforeSkill = 1.0,
    SkillCastTime = 0.5,
    
    -- Anti-Bug
    MaxAttackTime = 6.0, -- Tempo máximo no mesmo alvo antes de trocar (caso bugue)
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "HUNTING" -- HUNTING, ATTACKING, BURSTING

local LockedTarget = nil     -- O alvo principal atual
local LockedTime = 0         -- Quando começamos a focar nele
local ClusterTargets = {}    -- Lista dos outros 3 zumbis vizinhos

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieCluster"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 0) -- Laranja Escuro
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "💣 CLUSTER BOMB v21"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ClusterInfo = Instance.new("TextLabel", MainFrame)
ClusterInfo.Size = UDim2.new(1, 0, 0, 20)
ClusterInfo.Position = UDim2.new(0, 0, 0.4, 0)
ClusterInfo.Text = "Alvos: 0/4"
ClusterInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
ClusterInfo.BackgroundTransparency = 1
ClusterInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 0)
ToggleBtn.Text = "LIGAR FARM (MULTI-HIT)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE HITBOX //
local function ExpandHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.CanCollide = false
        root.Transparency = 0.7 
        root.Color = Color3.fromRGB(255, 100, 0) -- Laranja Explosão
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

-- // GERENCIAMENTO DE CLUSTER (VIZINHOS) //
local function UpdateCluster(mainTarget)
    -- Limpa hits antigos que não são mais vizinhos
    for i = #ClusterTargets, 1, -1 do
        local mob = ClusterTargets[i]
        if mob ~= mainTarget then
            RestoreHitbox(mob) -- Reseta visual
        end
    end
    ClusterTargets = {}
    
    if not mainTarget then return end
    
    -- Adiciona o principal
    table.insert(ClusterTargets, mainTarget)
    ExpandHitbox(mainTarget)
    
    -- Procura vizinhos
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if #ClusterTargets >= SETTINGS.MaxClusterTargets then break end
            
            if mob ~= mainTarget and mob.Name ~= "ScopeSStars" then
                local root = mob:FindFirstChild("HumanoidRootPart")
                local mainRoot = mainTarget:FindFirstChild("HumanoidRootPart")
                
                if root and mainRoot then
                    -- Se estiver perto do alvo principal (formando um grupo)
                    if (root.Position - mainRoot.Position).Magnitude < SETTINGS.ClusterRadius then
                        table.insert(ClusterTargets, mob)
                        ExpandHitbox(mob)
                    end
                end
            end
        end
    end
    
    ClusterInfo.Text = "Cluster: " .. #ClusterTargets .. " Zumbis"
end

-- // BUSCA DE ALVO (SIMPLES E DIRETA) //
local function FindNewTarget()
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
                if model.Name ~= "ScopeSStars" then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root and root.CFrame.UpVector.Y > 0.4 then -- Em pé
                        local dist = (root.Position - myPos).Magnitude
                        if dist < minDist then minDist = dist closest = model end
                    end
                end
            end
        end
    end
    return closest
end

-- // COMBO DE SKILLS //
local function ExecuteCombo()
    combatState = "BURSTING"
    Status.Text = "🛑 PREPARANDO SKILLS..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.WaitBeforeSkill) -- 1s parado
    
    for _, key in ipairs(SKILLS) do
        Status.Text = "🔥 SOLTANDO: " .. key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    lastBurstTime = tick()
    combatState = "ATTACKING"
    Status.Text = "⚔️ VOLTANDO A BATER"
end

-- // NAVEGAÇÃO //
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
        LockedTarget = nil -- Reseta trava
    else
        ToggleBtn.Text = "LIGAR CLUSTER FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 0)
        Status.Text = "Parado"
        DisableFlight()
        UpdateCluster(nil) -- Limpa hitboxes
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

    -- 1. SISTEMA DE TRAVA (TARGET LOCK)
    -- Se não temos alvo, ou ele morreu, ou sumiu -> Procura Novo
    if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("HumanoidRootPart") then
        LockedTarget = FindNewTarget()
        LockedTime = tick()
        combatState = "HUNTING"
    else
        -- Se já estamos focando no mesmo há muito tempo (anti-bug), troca
        if tick() - LockedTime > SETTINGS.MaxAttackTime then
             LockedTarget = FindNewTarget() -- Troca forçada
             LockedTime = tick()
        end
    end
    
    -- Se tiver alvo travado
    if LockedTarget then
        local tPos = LockedTarget.HumanoidRootPart.Position
        local myPos = root.Position
        
        -- Atualiza Hitboxes (Alvo + 3 Vizinhos)
        UpdateCluster(LockedTarget)
        
        -- 2. MOVIMENTAÇÃO AGRESSIVA (35 Studs acima)
        -- Calcula posição exata em cima da cabeça
        local sniperPos = Vector3.new(tPos.X, tPos.Y + SETTINGS.HoverHeight, tPos.Z)
        local distToSniper = (myPos - sniperPos).Magnitude
        
        -- Se estiver longe da posição de voo, vai rápido
        if distToSniper > 2 then
            local direction = (sniperPos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            -- Olha pro alvo
            root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
        else
            -- Chegou na posição: FREIA
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
            
            -- 3. COMBATE
            if combatState ~= "BURSTING" then
                -- Ataque Básico
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
                
                -- Checa Combo
                if tick() - lastBurstTime > SETTINGS.BurstInterval then
                    task.spawn(ExecuteCombo)
                end
            end
        end
    else
        Status.Text = "Procurando Zumbi..."
        ClusterInfo.Text = "---"
        root.NavVelocity.Velocity = Vector3.new(0,0,0)
        UpdateCluster(nil)
    end
end)
