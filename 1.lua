--[[
    🧟 HUNTER ZOMBIE - THE JETPACK CASTER (v10.0)
    
    Mudanças:
    1. Movimento: Usa BodyVelocity (Voo Físico) em vez de andar.
       - Isso garante que ele NÃO fique parado e empurre portas.
    2. Combate: Adicionado Auto-Skill (Z, X, C, V) sequencial.
    3. Altura: Flutua levemente do chão para não tropeçar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    FlySpeed = 60,       -- Velocidade do Voo
    StopDist = 8,        -- Distância para parar e atacar
    FloatHeight = 3,     -- Altura do voo (3 studs do chão)
    SkillDelay = 1.0     -- Tempo entre cada skill (pra não floodar)
}

-- Lista de Skills
local SKILLS = {"Z", "X", "C", "V"}
local currentSkillIndex = 1
local lastSkillTime = 0

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieJetpack"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 110)
MainFrame.Position = UDim2.new(0.5, -130, 0.75, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Tech
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚁 JETPACK CASTER v10"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
ToggleBtn.Text = "ATIVAR VOO + SKILLS"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //
local function UseNextSkill()
    if tick() - lastSkillTime > SETTINGS.SkillDelay then
        local key = SKILLS[currentSkillIndex]
        local keyEnum = Enum.KeyCode[key]
        
        -- Pressiona a tecla virtualmente
        VirtualInputManager:SendKeyEvent(true, keyEnum, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, keyEnum, false, game)
        
        Status.Text = "Usando Skill: " .. key
        Status.TextColor3 = Color3.fromRGB(255, 0, 255) -- Roxo
        
        -- Passa para a próxima
        currentSkillIndex = currentSkillIndex + 1
        if currentSkillIndex > #SKILLS then
            currentSkillIndex = 1
        end
        lastSkillTime = tick()
    end
end

-- // BUSCA ALVO //
local function GetEntityTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local zombiesFolder = entities:FindFirstChild("Zombie")
    if not zombiesFolder then return nil end
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = 9999
    
    for _, model in ipairs(zombiesFolder:GetChildren()) do
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and model.Name ~= "ScopeSStars" then -- Ignora a isca
             -- Verifica se está "vivo" (ainda na pasta)
             local dist = (root.Position - myPos).Magnitude
             if dist < minDist then
                 minDist = dist
                 closest = model
             end
        end
    end
    return closest
end

-- // SISTEMA DE VOO (BODYVELOCITY) //
local bv = nil
local bg = nil

local function EnableFlight()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Cria os motores se não existirem
    if not root:FindFirstChild("FarmVelocity") then
        bv = Instance.new("BodyVelocity")
        bv.Name = "FarmVelocity"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = root
    end
    
    if not root:FindFirstChild("FarmGyro") then
        bg = Instance.new("BodyGyro")
        bg.Name = "FarmGyro"
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 10000
        bg.CFrame = root.CFrame
        bg.Parent = root
    end
    
    -- Tira o atrito e a gravidade do Humanoid
    char.Humanoid.PlatformStand = true
end

local function DisableFlight()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root and root:FindFirstChild("FarmVelocity") then root.FarmVelocity:Destroy() end
    if root and root:FindFirstChild("FarmGyro") then root.FarmGyro:Destroy() end
    
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
    bv = nil
    bg = nil
end

-- // LOOP PRINCIPAL //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        EnableFlight()
    else
        ToggleBtn.Text = "ATIVAR VOO + SKILLS"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
        Status.Text = "Parado"
        DisableFlight()
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    -- Garante que o voo está ativo
    if not root:FindFirstChild("FarmVelocity") then EnableFlight() end
    
    -- Auto Equip Tool
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    local target = GetEntityTarget()
    
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tPos = target.HumanoidRootPart.Position
        local myPos = root.Position
        local dist = (myPos - tPos).Magnitude
        
        -- Direção do Voo
        local direction = (tPos - myPos).Unit
        
        -- Olha para o inimigo
        if root:FindFirstChild("FarmGyro") then
            root.FarmGyro.CFrame = CFrame.lookAt(myPos, Vector3.new(tPos.X, myPos.Y, tPos.Z))
        end
        
        if dist > SETTINGS.StopDist then
            -- VOANDO ATÉ O ALVO
            if root:FindFirstChild("FarmVelocity") then
                -- Voo com altura fixa (FloatHeight) para bater na porta mas não arrastar no chão
                local targetVel = direction * SETTINGS.FlySpeed
                -- Ajuste vertical suave
                targetVel = Vector3.new(targetVel.X, (tPos.Y + SETTINGS.FloatHeight - myPos.Y) * 5, targetVel.Z)
                root.FarmVelocity.Velocity = targetVel
            end
            Status.Text = "Voando até: " .. target.Name
            Status.TextColor3 = Color3.fromRGB(0, 255, 255)
        else
            -- CHEGOU PERTO
            if root:FindFirstChild("FarmVelocity") then
                root.FarmVelocity.Velocity = Vector3.new(0, 0, 0) -- Freia
            end
            
            -- ATAQUE
            if tool then tool:Activate() end
            UseNextSkill() -- Solta Z, X, C, V
        end
    else
        -- Sem alvo: Fica parado flutuando
        if root:FindFirstChild("FarmVelocity") then
            root.FarmVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        Status.Text = "Procurando..."
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)
