--[[
    🧟 HUNTER ZOMBIE - THE TELEPORT ASSASSIN (v30.0)
    
    A ÚLTIMA CARTADA:
    1. TWEEN MOVEMENT: Não usa física. Ele "desliza" o personagem ignorando paredes.
       - Resolve o problema de ficar preso ou voar pro infinito.
    2. BACKSTAB: Teleporta para as costas do zumbi para bater (ignora hitbox server-side).
    3. AUTO-DOOR: Desliza até a porta para ativar a sala.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    
    -- Velocidade do Teleporte (Quanto menor, mais rápido/agressivo)
    TweenSpeed = 30,      -- Studs por segundo (velocidade de correr rápido)
    
    -- Distâncias
    AttackDist = 4,       -- Distância pra ficar do zumbi (colado)
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    DoorDist = 4,
    
    -- Combate
    KillRange = 250,      -- Raio pra detectar zumbis na sala
    AttackInterval = 0.5, 
    WaitBeforeSkill = 0.5,
    SkillCastTime = 0.3,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local currentTween = nil
local visitedDoors = {}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieAssassin"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 150)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🥷 TELEPORT ASSASSIN v30"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
ToggleBtn.Text = "LIGAR FARM (TWEEN)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE MOVIMENTO (TWEEN) //
local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    -- Cancela tween anterior se existir
    if currentTween then currentTween:Cancel() end
    
    local dist = (char.PrimaryPart.Position - targetCFrame.Position).Magnitude
    local time = dist / SETTINGS.TweenSpeed
    
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = targetCFrame})
    currentTween:Play()
    
    -- Espera chegar (opcional, mas evita teleportar rápido demais)
    -- return currentTween
end

-- // NOCLIP PERMANENTE (Pra atravessar parede) //
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        -- Trava gravidade pra não cair no void enquanto tweena
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(0,0,0) end
    end
end)

-- // COMBO //
local function ExecuteCombo()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local tool = char:FindFirstChildOfClass("Tool")
    
    if hum and tool then hum:UnequipTools() task.wait(0.2) end
    task.wait(SETTINGS.WaitBeforeSkill)
    
    for _, key in ipairs(SKILLS) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
        task.wait(SETTINGS.SkillCastTime)
    end
    
    if hum and tool then hum:EquipTool(tool) end
    lastBurstTime = tick()
end

-- // PORTAS //
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
            
            if isDoor and not visitedDoors[obj] then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {Object = obj, CFrame = part.CFrame}
                    end
                end
            end
        end
    end
    return closest
end

-- // MAIN LOOP //
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {}
        if currentTween then currentTween:Cancel() end
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
        Status.Text = "Parado"
        if currentTween then currentTween:Cancel() end
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
    if not tool and tick() - lastBurstTime > 3 then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    -- 1. PROCURA INIMIGOS
    local targetZombie = nil
    local entities = Workspace:FindFirstChild("Entities")
    if entities and entities:FindFirstChild("Zombie") then
        local minDist = 9999
        for _, mob in ipairs(entities.Zombie:GetChildren()) do
            if mob.Name ~= "ScopeSStars" then
                local mRoot = mob:FindFirstChild("HumanoidRootPart")
                if mRoot and mRoot.CFrame.UpVector.Y > 0.4 then -- Vivo
                    local dist = (mRoot.Position - root.Position).Magnitude
                    if dist < minDist and dist < SETTINGS.KillRange then
                        minDist = dist
                        targetZombie = mob
                    end
                end
            end
        end
    end
    
    -- 2. DECISÃO
    if targetZombie then
        Status.Text = "⚔️ MATANDO: " .. targetZombie.Name
        local mRoot = targetZombie.HumanoidRootPart
        
        -- TP PARA TRÁS DO ZUMBI
        local attackPos = mRoot.CFrame * CFrame.new(0, 0, 3) -- 3 studs atrás
        
        -- Se estiver longe, usa Tween. Se perto, teleporta direto.
        if (root.Position - mRoot.Position).Magnitude > 5 then
            TweenTo(attackPos)
        else
            if currentTween then currentTween:Cancel() end
            root.CFrame = attackPos
            
            -- Olha pro zumbi
            root.CFrame = CFrame.lookAt(root.Position, mRoot.Position)
            
            -- ATAQUE
            if tick() - lastBasicAttack > SETTINGS.AttackInterval then
                if tool then tool:Activate() end
                lastBasicAttack = tick()
            end
            if tick() - lastBurstTime > 8.0 then
                task.spawn(ExecuteCombo)
            end
        end
        
    else
        Status.Text = "🚪 BUSCANDO PORTA"
        
        local door = GetNearestDoor()
        if door then
            local dist = (root.Position - door.CFrame.Position).Magnitude
            if dist < SETTINGS.DoorDist then
                visitedDoors[door.Object] = true
                Status.Text = "✅ PORTA CHECADA"
            else
                -- Vai até a porta (no nível do chão)
                local targetPos = Vector3.new(door.CFrame.X, root.Position.Y, door.CFrame.Z)
                TweenTo(CFrame.new(targetPos))
            end
        else
            Status.Text = "MAPA LIMPO"
        end
    end
end)