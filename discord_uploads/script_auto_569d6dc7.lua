--[[
    🧙‍♂️ RPG MAGNET GOD v41 (SLAYER EDITION)
    
    UPGRADE DE DANO:
    - FAST ATTACK: Spamma o clique da ferramenta (Activate).
    - MULTI-TOUCH: Força o toque físico da arma no inimigo (Dano x10).
    
    MODOS MANTIDOS:
    - SINGLE (1v1) e MASS (Buraco Negro).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetGodRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância (Frente do player)
    HitboxSize = 5,       -- Tamanho da Hitbox
    KillRange = 2500,     -- Raio de busca
    AttackSpeed = 0.05,   -- Velocidade do Fast Attack (0.05 é muito rápido)
}

-- Variáveis de Estado
local IsMagnetOn = false
local IsDamageOn = false -- Novo controle de dano
local CurrentMode = "SINGLE"
local SingleTarget = nil
local MassTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("RPGMagnetSlayer") then CoreGui.RPGMagnetSlayer:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetSlayer"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 220) -- Maior pra caber botões
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "👹 GOD SLAYER v41"
Title.TextColor3 = Color3.fromRGB(255, 0, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.15, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

-- Botão Modo (Magneto)
local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ModeBtn.Position = UDim2.new(0.05, 0, 0.28, 0)
ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ModeBtn.Text = "MODO: 1v1 (SINGLE)"
ModeBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
ModeBtn.Font = Enum.Font.GothamBold

-- Botão Ligar Magneto
local ToggleMagnet = Instance.new("TextButton", MainFrame)
ToggleMagnet.Size = UDim2.new(0.9, 0, 0.2, 0)
ToggleMagnet.Position = UDim2.new(0.05, 0, 0.48, 0)
ToggleMagnet.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleMagnet.Text = "LIGAR MAGNETO (PUXAR)"
ToggleMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMagnet.Font = Enum.Font.GothamBold

-- Botão Dano (NOVO)
local ToggleDamage = Instance.new("TextButton", MainFrame)
ToggleDamage.Size = UDim2.new(0.9, 0, 0.2, 0)
ToggleDamage.Position = UDim2.new(0.05, 0, 0.72, 0)
ToggleDamage.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
ToggleDamage.Text = "LIGAR FAST ATTACK (DANO)"
ToggleDamage.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleDamage.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function GetEnemiesFolder()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            return child
        end
    end
    return Workspace
end

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.6
    root.Color = (CurrentMode == "MASS") and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    root.CanCollide = false
    root.Massless = true
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

local function RestoreAll()
    if SingleTarget then RestoreMob(SingleTarget) SingleTarget = nil end
    for mob, _ in pairs(MassTargets) do RestoreMob(mob) end
    MassTargets = {}
end

-- // BOTOES //
ModeBtn.MouseButton1Click:Connect(function()
    RestoreAll()
    if CurrentMode == "SINGLE" then
        CurrentMode = "MASS"
        ModeBtn.Text = "MODO: BURACO NEGRO (MASS)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        CurrentMode = "SINGLE"
        ModeBtn.Text = "MODO: 1v1 (SINGLE)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
    end
end)

ToggleMagnet.MouseButton1Click:Connect(function()
    IsMagnetOn = not IsMagnetOn
    if IsMagnetOn then
        ToggleMagnet.Text = "PARAR MAGNETO"
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleMagnet.Text = "LIGAR MAGNETO (PUXAR)"
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
    end
end)

ToggleDamage.MouseButton1Click:Connect(function()
    IsDamageOn = not IsDamageOn
    if IsDamageOn then
        ToggleDamage.Text = "PARAR FAST ATTACK"
        ToggleDamage.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    else
        ToggleDamage.Text = "LIGAR FAST ATTACK (DANO)"
        ToggleDamage.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetGodRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
local lastAttack = 0

RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetGodRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local myRoot = char.HumanoidRootPart
    
    -- === 1. LÓGICA DE MAGNETO (PUXAR) ===
    if IsMagnetOn then
        local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
        local folder = GetEnemiesFolder()
        
        if CurrentMode == "SINGLE" then
            -- 1v1
            if SingleTarget and (not SingleTarget.Parent or SingleTarget.Humanoid.Health <= 0) then
                RestoreMob(SingleTarget)
                SingleTarget = nil
            end
            
            if not SingleTarget then
                -- Busca novo
                local closest, minDist = nil, 9999
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob:IsA("Model") and mob ~= char then
                        local hum = mob:FindFirstChild("Humanoid")
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and root then
                            local dist = (root.Position - myRoot.Position).Magnitude
                            if dist < minDist and dist < SETTINGS.KillRange then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                end
                SingleTarget = closest
            end
            
            if SingleTarget then
                PrepareMob(SingleTarget)
                SingleTarget.HumanoidRootPart.CFrame = pullPos
                SingleTarget.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                Status.Text = "⚔️ ALVO: " .. SingleTarget.Name
            end
            
        elseif CurrentMode == "MASS" then
            -- MASSIVE
            local count = 0
            for _, mob in ipairs(folder:GetChildren()) do
                if mob:IsA("Model") and mob ~= char then
                    local hum = mob:FindFirstChild("Humanoid")
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root then
                        if (root.Position - myRoot.Position).Magnitude < SETTINGS.KillRange then
                            MassTargets[mob] = true
                            PrepareMob(mob)
                            root.CFrame = pullPos
                            root.Velocity = Vector3.new(0,0,0)
                            count = count + 1
                        end
                    else
                         if MassTargets[mob] then MassTargets[mob] = nil end
                    end
                end
            end
            Status.Text = "⚔️ ALVOS: " .. count
        end
    end
    
    -- === 2. LÓGICA DE DANO (FAST ATTACK) ===
    if IsDamageOn then
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then 
            -- Tenta equipar se não tiver
            local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if bp then char.Humanoid:EquipTool(bp) end
        end
        
        if tool then
            -- A) Fast Activate (Clique Rápido)
            if tick() - lastAttack > SETTINGS.AttackSpeed then
                tool:Activate()
                lastAttack = tick()
            end
            
            -- B) Multi-Touch (Dano Físico Forçado)
            -- Se tiver Handle, força o toque dele nos inimigos puxados
            local handle = tool:FindFirstChild("Handle")
            if handle and firetouchinterest then
                -- Se tiver alvo único
                if SingleTarget and SingleTarget:FindFirstChild("HumanoidRootPart") then
                    firetouchinterest(handle, SingleTarget.HumanoidRootPart, 0) -- Toca
                    firetouchinterest(handle, SingleTarget.HumanoidRootPart, 1) -- Solta
                end
                
                -- Se tiver alvos em massa
                for mob, _ in pairs(MassTargets) do
                    if mob and mob:FindFirstChild("HumanoidRootPart") then
                        firetouchinterest(handle, mob.HumanoidRootPart, 0)
                        firetouchinterest(handle, mob.HumanoidRootPart, 1)
                    end
                end
            end
        end
    end
end)