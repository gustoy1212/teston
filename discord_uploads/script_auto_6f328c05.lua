--[[
    🧟 HUNTER ZOMBIE - THE FLASH WALKER (v36.0)
    
    CORREÇÃO DE GATILHO:
    - Portas: Usa WalkSpeed 100 (Físico). Garante que o jogo detecte a entrada.
    - Zumbis: Usa Teleporte (CFrame). Mata instantâneo assim que spawnar.
    
    FUNCIONALIDADES:
    - Botão FECHAR [X] real (Limpa tudo).
    - Ignora zumbis mortos.
    - Flutua (HipHeight) para não travar no chão.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- // VARIÁVEIS DE CONTROLE GLOBAL //
getgenv().ZombieScriptRunning = true -- Controle para o botão de fechar

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Velocidade (Isso ativa o gatilho sem ser lento)
    FlashSpeed = 100,     -- Muito rápido
    FloatHeight = 6,      -- Flutua pra não bater em pedra
    
    -- Combate
    AttackDist = 6,       -- Distância para bater
    KillRange = 2000,     -- Raio de visão
    
    -- Portas
    DoorNames = {"Door", "Porta", "Gate", "Saida", "Exit", "Passage"},
    DoorPassDist = 8,     -- Quanto andar DEPOIS da porta pra garantir
    
    -- Skill
    AttackInterval = 0.35,
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkillUsage = 0
local lastBasicAttack = 0

-- Estados
local LockedTarget = nil
local CurrentDoor = nil
local visitedDoors = {}

-- // GUI SETUP (COM BOTÃO FECHAR REAL) //
if CoreGui:FindFirstChild("ZombieFlashWalker") then
    CoreGui.ZombieFlashWalker:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieFlashWalker"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 150)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0) -- Topo da tela
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "⚡ FLASH WALKER v36"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- BOTÃO FECHAR (KILL SWITCH)
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- Status e Info
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionText = Instance.new("TextLabel", MainFrame)
ActionText.Size = UDim2.new(1, 0, 0, 20)
ActionText.Position = UDim2.new(0, 0, 0.45, 0)
ActionText.Text = "-"
ActionText.TextColor3 = Color3.fromRGB(100, 255, 100)
ActionText.BackgroundTransparency = 1
ActionText.Font = Enum.Font.Code

-- Botão Ligar
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE ENCERRAMENTO //
local function StopScript()
    getgenv().ZombieScriptRunning = false
    Status.Text = "ENCERRANDO..."
    
    -- Reseta boneco
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
        LocalPlayer.Character.Humanoid.HipHeight = 0
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.PrimaryPart.Position)
    end
    
    ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(StopScript)

-- // AUXILIARES //
local function GetCenter(part)
    if part:IsA("Model") then
        local cf, _ = part:GetBoundingBox()
        return cf.Position
    else
        return part.Position
    end
end

-- // COMBATE //
local function CastSkill()
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkillUsage = tick()
end

-- // BUSCA ZUMBI //
local function FindTarget()
    -- Se o alvo atual ainda existe e tá vivo, mantém ele
    if LockedTarget and LockedTarget.Parent and LockedTarget:FindFirstChild("Humanoid") and LockedTarget.Humanoid.Health > 0 then
        return LockedTarget
    end
    LockedTarget = nil

    local entities = Workspace:FindFirstChild("Entities")
    local zombies = entities and entities:FindFirstChild("Zombie")
    if not zombies then return nil end
    
    local char = LocalPlayer.Character
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, mob in ipairs(zombies:GetChildren()) do
        if mob.Name ~= "ScopeSStars" then
            local root = mob:FindFirstChild("HumanoidRootPart")
            -- Check de Vida e se não tá morto no chão (UpVector)
            if root and root.CFrame.UpVector.Y > 0.4 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist and dist < SETTINGS.KillRange then
                    minDist = dist
                    closest = mob
                end
            end
        end
    end
    LockedTarget = closest
    return closest
end

-- // BUSCA PORTA //
local function FindDoor()
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
                local pos = GetCenter(obj)
                local dist = (pos - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = {Object = obj, Position = pos}
                end
            end
        end
    end
    return closest
end

-- // LOGICA PRINCIPAL //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        visitedDoors = {}
        LockedTarget = nil
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
        -- Reseta física ao pausar
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.HipHeight = 0
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.PrimaryPart.Position)
        end
    end
end)

-- Loop Rápido
RunService.Heartbeat:Connect(function()
    if not getgenv().ZombieScriptRunning then return end -- Garante parada total
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    -- // MODO FLASH (FÍSICA) //
    -- Mantém velocidade alta e flutuação para não travar
    hum.WalkSpeed = SETTINGS.FlashSpeed
    hum.HipHeight = SETTINGS.FloatHeight
    hum.AutoRotate = false -- Nós controlamos a rotação
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end
    
    -- 1. PRIORIDADE: ZUMBI VIVO (Teleporte)
    local target = FindTarget()
    
    if target then
        local tRoot = target.HumanoidRootPart
        local dist = (root.Position - tRoot.Position).Magnitude
        
        Status.Text = "⚔️ MATANDO: " .. target.Name
        ActionText.Text = "Teleporte Ofensivo"
        
        -- Zera movimento físico pra não atrapalhar o teleporte
        hum:MoveTo(root.Position)
        
        -- TP COSTAS (CFrame é permitido aqui pq o zumbi já spawnou)
        local backPos = tRoot.CFrame * CFrame.new(0, 0, 3)
        root.CFrame = CFrame.new(backPos.Position, tRoot.Position)
        
        -- Ataque
        if dist <= SETTINGS.AttackDist then
            if tool then tool:Activate() end
            if tick() - lastSkillUsage > 3.0 then CastSkill() end
        end
        
    else
        -- 2. SEM ZUMBIS? CORRE PRA PORTA (Físico)
        if not CurrentDoor then
            local doorData = FindDoor()
            if doorData then
                CurrentDoor = doorData
                Status.Text = "🏃 PORTA ENCONTRADA"
            else
                Status.Text = "MAPA LIMPO (Fim)"
                hum:MoveTo(root.Position)
                return
            end
        end
        
        if CurrentDoor then
            local doorPos = CurrentDoor.Position
            local dist = (root.Position - doorPos).Magnitude
            
            ActionText.Text = "Movimento Físico (Flash)"
            
            -- Olha pra porta
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(doorPos.X, root.Position.Y, doorPos.Z))
            
            if dist < 8 then
                -- ESTAMOS NA PORTA
                Status.Text = "🛑 ATRAVESSANDO..."
                visitedDoors[CurrentDoor.Object] = true
                
                -- Empurra o boneco PARA FRENTE DA PORTA (passar pro outro lado)
                -- Calcula um ponto 10 studs na frente da porta
                local direction = (doorPos - root.Position).Unit
                local passPoint = doorPos + (direction * 15)
                
                hum:MoveTo(passPoint)
                CurrentDoor = nil
                
            else
                -- CORRE ATÉ A PORTA
                hum:MoveTo(doorPos)
                
                -- Se travar na parede, pula
                if root.Velocity.Magnitude < 2 then
                    hum.Jump = true
                end
            end
        end
    end
end)