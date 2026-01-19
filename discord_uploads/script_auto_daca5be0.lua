--[[
    🧟 HUNTER ZOMBIE - THE GHOST BOMBER (v22.0)
    
    CORREÇÃO DE COLISÃO (NOCLIP):
    1. Ghost Mode: O jogador agora atravessa TUDO (paredes e hitboxes).
    2. Force Non-Collide: O script força a hitbox do zumbi a ser intangível a cada frame.
    3. Resultado: Você voa para DENTRO da hitbox gigante sem bater nela.
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
    FlySpeed = 65,        
    
    -- Posicionamento
    HoverHeight = 15,     -- Fica dentro da hitbox
    HitboxSize = 70,      -- Tamanho Gigante
    
    ClusterRadius = 60,   
    MaxClusterTargets = 4,
    
    -- Combate Burst
    AttackInterval = 0.5, 
    BurstInterval = 5.0,  
    WaitBeforeSkill = 1.0,
    SkillCastTime = 0.5,
    
    -- Anti-Bug
    MaxAttackTime = 6.0, 
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local combatState = "HUNTING" 

local LockedTarget = nil     
local LockedTime = 0         
local ClusterTargets = {}    

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieGhostBomber"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 0.7, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 30) -- Roxo Fantasma
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "👻 GHOST BOMBER v22"
Title.TextColor3 = Color3.fromRGB(200, 100, 255)
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
ClusterInfo.Text = "Noclip: ATIVADO"
ClusterInfo.TextColor3 = Color3.fromRGB(0, 255, 255)
ClusterInfo.BackgroundTransparency = 1
ClusterInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
ToggleBtn.Text = "LIGAR FARM (NOCLIP)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // NOCLIP (ATRAVESSAR PAREDES E HITBOX) //
-- Isso roda antes da física do jogo (Stepped) para garantir que você não colida
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

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
        
        -- Aplica tamanho
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 0.7 
        root.Color = Color3.fromRGB(150, 0, 255) 
        
        -- FORÇA SEM COLISÃO (IMPORTANTE)
        root.CanCollide = false
    end
end

local function RestoreHitbox(model)
    if not model then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    local original = model:FindFirstChild("OriginalSize")
    if root and original then
        root.Size = original.Value
        root.Transparency = 1
        -- Devolve colisão pro zumbi não cair no void (opcional)
        root.CanCollide = true 
        original:Destroy()
    end
end

-- // GERENCIAMENTO DE CLUSTER //
local function UpdateCluster(mainTarget)
    for i = #ClusterTargets, 1, -1 do
        local mob = ClusterTargets[i]
        if mob ~= mainTarget then
            RestoreHitbox(mob) 
        end
    end
    ClusterTargets = {}
    
    if not mainTarget then return end
    
    table.insert(ClusterTargets, mainTarget)
    ExpandHitbox(mainTarget)
    
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if #ClusterTargets >= SETTINGS.MaxClusterTargets then break end
            
            if mob ~= mainTarget and mob.Name ~= "ScopeSStars" then
                local root = mob:FindFirstChild("HumanoidRootPart")
                local mainRoot = mainTarget:FindFirstChild("HumanoidRootPart")
                
                if root and mainRoot then
                    if (root.Position - mainRoot.Position).Magnitude < SETTINGS.ClusterRadius then
                        table.insert(ClusterTargets, mob)
                        ExpandHitbox(mob)
                    end
                end
            end
        end
    end
end

-- // BUSCA DE ALVO //
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
                    if root and root.CFrame.UpVector.Y > 0.4 then 
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
    Status.Text = "🛑 SKILLS..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    task.wait(SETTINGS.WaitBeforeSkill) 
    
    for _, key in ipairs(SKILLS) do
        Status.Text = "🔥 " .. key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    lastBurstTime = tick()
    combatState = "ATTACKING"
    Status.Text = "⚔️ BATENDO"
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
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        EnableFlight()
        LockedTarget = nil 
    else
        ToggleBtn.Text = "LIGAR FARM (NOCLIP)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
        Status.Text = "Parado"
        DisableFlight()
        UpdateCluster(nil) 
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end
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

    if not LockedTarget or not LockedTarget.Parent or not LockedTarget:FindFirstChild("HumanoidRootPart") then
        LockedTarget = FindNewTarget()
        LockedTime = tick()
        combatState = "HUNTING"
    else
        if tick() - LockedTime > SETTINGS.MaxAttackTime then
             LockedTarget = FindNewTarget() 
             LockedTime = tick()
        end
    end
    
    if LockedTarget then
        local tPos = LockedTarget.HumanoidRootPart.Position
        local myPos = root.Position
        
        UpdateCluster(LockedTarget)
        
        -- REFORÇA "SEM COLISÃO" NA HITBOX (SUPER IMPORTANTE)
        for _, mob in ipairs(ClusterTargets) do
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then mobRoot.CanCollide = false end
        end
        
        -- POSICIONAMENTO DENTRO DA HITBOX
        local sniperPos = Vector3.new(tPos.X, tPos.Y + SETTINGS.HoverHeight, tPos.Z)
        local distToSniper = (myPos - sniperPos).Magnitude
        
        if distToSniper > 2 then
            local direction = (sniperPos - myPos).Unit
            root.NavVelocity.Velocity = direction * SETTINGS.FlySpeed
            root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
        else
            root.NavVelocity.Velocity = Vector3.new(0,0,0)
            root.NavGyro.CFrame = CFrame.lookAt(myPos, tPos)
            
            if combatState ~= "BURSTING" then
                if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                    if tool then tool:Activate() end
                    lastBasicAttack = tick()
                end
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