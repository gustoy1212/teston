--[[
    🧟 HUNTER ZOMBIE - THE SMOOTH GLIDER (v32.0)
    
    ZERO LAG EDITION:
    - Movimento: TweenService (Deslize suave sem física).
    - Colisão: Noclip Total (Atravessa portas e paredes sem travar).
    - Altura: Flutua a 5 studs do chão para não tropeçar.
    - Lógica: Mata Zumbis -> Se limpar, desliza para a Porta.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    
    -- Velocidade do Deslize (Quanto menor o tempo, mais rápido)
    -- Speed = Studs por Segundo
    GlideSpeed = 45,       
    
    -- Altura do Voo (Pra não bater no chão)
    HoverHeight = 5,
    
    -- Distâncias
    AttackDist = 6,        -- Distância pra parar perto do zumbi
    KillRange = 300,       -- Raio pra detectar inimigos na sala
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    DoorDist = 6,
    
    -- Combate
    AttackInterval = 0.4, 
    WaitBeforeSkill = 0.5,
}

local SKILLS = {"Z", "X", "C", "V"}
local lastBurstTime = 0
local lastBasicAttack = 0
local currentTween = nil
local visitedDoors = {}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieGlider"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 140)
MainFrame.Position = UDim2.new(0.5, -160, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⛸️ SMOOTH GLIDER v32"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
ToggleBtn.Text = "LIGAR FARM (NO-LAG)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE MOVIMENTO (TWEEN) //
local function GlideTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    -- Calcula tempo baseado na distância (Velocidade Constante)
    local dist = (char.PrimaryPart.Position - targetCFrame.Position).Magnitude
    local time = dist / SETTINGS.GlideSpeed
    
    -- Se já estivermos tweenando pro mesmo lugar, não cancela (evita stutter)
    -- Mas como é loop, vamos criar um novo se a distância for grande
    
    local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)
    
    -- Ajusta altura (Flutuar)
    local finalCFrame = targetCFrame * CFrame.new(0, SETTINGS.HoverHeight, 0)
    
    -- Se tiver tween rodando, cancela pra atualizar a rota
    if currentTween then currentTween:Cancel() end
    
    currentTween = TweenService:Create(char.PrimaryPart, ti, {CFrame = finalCFrame})
    currentTween:Play()
end

-- // NOCLIP (ATRAVESSAR TUDO) //
RunService.Stepped:Connect(function()
    if SETTINGS.FarmEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then 
                part.CanCollide = false 
            end
        end
        -- Trava gravidade pra não cair
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
        task.wait(0.3)
    end
    
    if hum and tool then hum:EquipTool(tool) end
    lastBurstTime = tick()
end

-- // ENCONTRAR COISAS //
local function GetNearest(typeSearch)
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    if typeSearch == "Zombie" then
        local entities = Workspace:FindFirstChild("Entities")
        if entities and entities:FindFirstChild("Zombie") then
            for _, mob in ipairs(entities.Zombie:GetChildren()) do
                if mob.Name ~= "ScopeSStars" then
                    local mRoot = mob:FindFirstChild("HumanoidRootPart")
                    if mRoot and mRoot.CFrame.UpVector.Y > 0.4 then -- Vivo
                        local dist = (mRoot.Position - myPos).Magnitude
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
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
        Status.Text = "Parado"
        if currentTween then currentTween:Cancel() end
        -- Destrava boneco
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
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

    -- 1. PRIORIDADE: ZUMBIS NA SALA
    local targetZombie = GetNearest("Zombie")
    
    if targetZombie then
        Status.Text = "⚔️ ALVO: " .. targetZombie.Name
        local mRoot = targetZombie.HumanoidRootPart
        
        -- Desliza até perto do zumbi (mas não dentro dele)
        -- Fica a 3 studs de distância pra bater
        local attackPos = mRoot.CFrame * CFrame.new(0, 0, 3)
        
        -- Se estiver longe (> 5), desliza. Se estiver perto, só olha.
        if (root.Position - mRoot.Position).Magnitude > SETTINGS.AttackDist then
            GlideTo(attackPos)
        else
            if currentTween then currentTween:Cancel() end
            -- Mantém a altura flutuando
            root.CFrame = CFrame.new(root.Position, mRoot.Position)
            
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
        -- 2. PRIORIDADE: PORTA
        Status.Text = "🚪 BUSCANDO PORTA..."
        local door = GetNearest("Door")
        
        if door then
            local dist = (root.Position - door.CFrame.Position).Magnitude
            
            if dist < SETTINGS.DoorDist then
                visitedDoors[door.Object] = true
                Status.Text = "✅ PASSOU PORTA"
                -- Força um empurrãozinho pra frente pra garantir que entrou na sala
                root.CFrame = root.CFrame * CFrame.new(0, 0, -5)
            else
                -- Desliza até a porta
                GlideTo(door.CFrame)
            end
        else
            Status.Text = "SALÃO LIMPO / FIM"
            if currentTween then currentTween:Cancel() end
        end
    end
end)