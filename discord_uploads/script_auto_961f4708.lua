--[[
    🛡️ SAO GUARDIAN v1 (AUTO PARRY / BLOCK)
    
    INTELIGÊNCIA ARTIFICIAL DE COMBATE:
    1. Monitora a "AnimationTrack" do inimigo.
    2. Se uma nova animação começar (Ataque), ele ativa a defesa.
    3. Simula a tecla "E" (para Emulador) e busca o botão de Shield (Mobile).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().GuardianFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,        -- Distância de ataque
    SearchRange = 3000,
    BlockTime = 0.8,       -- Quanto tempo ficar segurando o escudo
    ReactionTime = 0,      -- 0 = Defesa Instantânea
}

-- Estados
local IsRunning = false
local IsBlocking = false
local CurrentTarget = nil
local TargetAnimConnection = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("GuardianUI") then CoreGui.GuardianUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GuardianUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 50) -- Azul Guardião
MainFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🛡️ SAO GUARDIAN (AUTO E)"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "INICIAR GUARDIÃO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE COMBATE //

-- Simula apertar "E" ou clicar no botão de escudo
local function StartBlock()
    if IsBlocking then return end
    IsBlocking = true
    Status.Text = "🛡️ BLOQUEANDO!"
    
    -- 1. Simula Tecla E (PC/Emulador)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    
    -- 2. Tenta achar o botão Mobile (Caso o E falhe)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        for _, btn in ipairs(playerGui.DeviceGui.Mobile:GetChildren()) do
            -- Procura algo com nome de Block, Shield ou Defend
            if btn.Name:match("Block") or btn.Name:match("Shield") or btn.Name:match("Defend") then
                 if firesignal then pcall(function() firesignal(btn.MouseButton1Down) end) end
            end
        end
    end
    
    -- Segura o escudo por um tempo
    task.wait(SETTINGS.BlockTime)
    
    -- Solta
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    -- Solta Mobile (MouseButton1Up)
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        for _, btn in ipairs(playerGui.DeviceGui.Mobile:GetChildren()) do
            if btn.Name:match("Block") or btn.Name:match("Shield") or btn.Name:match("Defend") then
                 if firesignal then pcall(function() firesignal(btn.MouseButton1Up) end) end
            end
        end
    end
    
    IsBlocking = false
    Status.Text = "⚔️ Contra-Atacando..."
end

-- Ataque Normal (Quando não está bloqueando)
local function Attack()
    if IsBlocking then return end
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    -- Usa o botão que descobrimos antes: MobileAttackButton
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            -- Fallback touch
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

-- // MOVIMENTO //
local function MoveTo(pos)
    if IsBlocking then return end -- Não anda enquanto defende
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- // CÉREBRO DA IA (DETECTOR) //
local function WatchEnemy(mob)
    if TargetAnimConnection then TargetAnimConnection:Disconnect() end
    
    local hum = mob:FindFirstChild("Humanoid")
    if not hum then return end
    
    -- Ouve qualquer animação que começar no inimigo
    TargetAnimConnection = hum.AnimationPlayed:Connect(function(track)
        -- Filtro: Ignora animações de Andar/Correr/Idle (Ids comuns)
        local id = track.Animation.AnimationId
        
        -- Se a animação for rápida ou tiver prioridade de ação, é ataque!
        if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Movement then
            -- OPA! ELE VAI BATER!
            spawn(function()
                task.wait(SETTINGS.ReactionTime) -- Reflexo humano (opcional)
                StartBlock()
            end)
        end
    end)
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().GuardianFarm = false
    if TargetAnimConnection then TargetAnimConnection:Disconnect() end
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR GUARDIÃO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR GUARDIÃO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        StopMove()
        if TargetAnimConnection then TargetAnimConnection:Disconnect() end
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().GuardianFarm do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    if TargetAnimConnection then TargetAnimConnection:Disconnect() end
                    CurrentTarget = nil
                    StopMove()
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- LONGE: Corre
                        Status.Text = "🏃 BUSCANDO..."
                        MoveTo(root.Position)
                    else
                        -- PERTO: COMBATE
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        if not IsBlocking then
                            Status.Text = "⚔️ ATACANDO..."
                            Attack()
                        end
                    end
                end
                
            else
                -- 2. PROCURA
                local folder = Workspace:FindFirstChild("Mobs")
                if folder then
                    local closest, minDist = nil, SETTINGS.SearchRange
                    
                    for _, mob in ipairs(folder:GetChildren()) do
                        local hum = mob:FindFirstChild("Humanoid")
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            local dist = (myRoot.Position - root.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                        -- LIGA O SENSOR NO NOVO ALVO
                        WatchEnemy(closest)
                    else
                        Status.Text = "Procurando Mobs..."
                        StopMove()
                    end
                end
            end
        end
    end
end)