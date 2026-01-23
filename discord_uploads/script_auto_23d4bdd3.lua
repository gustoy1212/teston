--[[ 
    FRUIT HUNTER V6 - STEALTH PILOT
    - Voo Suave (Sem Kick) via TweenService.
    - Sistema de Altitude Dinâmica (Sobe pra viajar, desce pra escanear).
    - Proteção Anti-Água e Monitor de Vida.
    - Rotação de Ilhas corrigida.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES DE VOO
local SETTINGS = {
    TravelAltitude = 600,   -- Altura para viajar (Ninguém te vê)
    ScanAltitude = 250,     -- Altura para verificar se tem fruta
    FlightSpeed = 300,      -- Velocidade do voo (300 é rápido mas seguro)
    WaitTime = 4            -- Tempo esperando na ilha para carregar
}

-- LISTA DE ILHAS (SEA 1)
local Waypoints = {
    {Name="Starter Pirate", Position=Vector3.new(-2572, 0, 2044)},
    {Name="Jungle (Selva)", Position=Vector3.new(-1200, 0, 400)},
    {Name="Pirate Village", Position=Vector3.new(-1645, 0, -2270)},
    {Name="Desert (Deserto)", Position=Vector3.new(940, 0, 4360)},
    {Name="Snow (Neve)", Position=Vector3.new(1130, 0, -1230)},
    {Name="Marine Fortress", Position=Vector3.new(-4950, 0, 720)},
    {Name="Skypiea (Céu)", Position=Vector3.new(-4700, 0, -2000)}, 
    {Name="Impel Down", Position=Vector3.new(5000, 0, 500)},
    {Name="Fountain City", Position=Vector3.new(-2000, 0, -5000)},
    {Name="Magma Village", Position=Vector3.new(5300, 0, -2600)}
}

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local ActionLabel = Instance.new("TextLabel")
local ButtonStart = Instance.new("TextButton")
local ButtonStop = Instance.new("TextButton")
local HealthBar = Instance.new("Frame") -- Visual da vida

ScreenGui.Name = "FruitHunterV6"
ScreenGui.Parent = game.CoreGui

-- Estilo Militar / Stealth
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 240)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBlack
Title.Text = "✈ PILOTO FANTASMA V6"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.15, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "SISTEMA OFF"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 14

ActionLabel.Parent = MainFrame
ActionLabel.BackgroundTransparency = 1
ActionLabel.Position = UDim2.new(0, 0, 0.28, 0)
ActionLabel.Size = UDim2.new(1, 0, 0, 20)
ActionLabel.Font = Enum.Font.Gotham
ActionLabel.Text = "Aguardando ordem..."
ActionLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
ActionLabel.TextSize = 12

ButtonStart.Parent = MainFrame
ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
ButtonStart.Position = UDim2.new(0.1, 0, 0.45, 0)
ButtonStart.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStart.Font = Enum.Font.GothamBold
ButtonStart.Text = "▶ DECOLAR (START)"
ButtonStart.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStart.TextSize = 14

ButtonStop.Parent = MainFrame
ButtonStop.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
ButtonStop.Position = UDim2.new(0.1, 0, 0.70, 0)
ButtonStop.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStop.Font = Enum.Font.GothamBold
ButtonStop.Text = "⏹ POUSO DE EMERGÊNCIA"
ButtonStop.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStop.TextSize = 14

-------------------------------------------------------------------------
-- SISTEMA DE VOO E SEGURANÇA
-------------------------------------------------------------------------

local isPatrolling = false
local currentTween = nil

-- Função de Notificação
function Notify(title, text)
    StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 8;})
end

-- Função para Travar/Destravar Personagem
function SetAnchor(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = state
        if state then LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0) end
    end
end

-- Função de Voo Suave (Tween)
function FlyTo(targetCFrame, speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    SetAnchor(true) -- Trava para voar sem física atrapalhar
    
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local time = distance / speed
    
    local info = TweenInfo.new(time, Enum.EasingStyle.Linear)
    currentTween = TweenService:Create(hrp, info, {CFrame = targetCFrame})
    currentTween:Play()
    
    -- Espera chegar (mas permite cancelamento)
    local reached = false
    currentTween.Completed:Connect(function() reached = true end)
    while not reached and isPatrolling do
        task.wait(0.1)
    end
    currentTween = nil
end

-- Check de Frutas
function ScanForFruits()
    for _, item in pairs(Workspace:GetChildren()) do
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
            if not name:find("dealer") and not name:find("gacha") then return item end
        end
    end
    -- Scan Profundo
    for _, item in pairs(Workspace:GetDescendants()) do
        if item:IsA("Tool") or item:IsA("Model") then
             local name = item.Name:lower()
             if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
                if not name:find("dealer") then
                    local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                    if handle and (LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude < 3000 then
                        return item
                    end
                end
             end
        end
    end
    return nil
end

-- Monitor de Vida e Água (Salva-Vidas)
spawn(function()
    while true do
        if isPatrolling and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hrp then
                -- Se a vida cair OU se estiver muito baixo (perto da água)
                if hum.Health < hum.MaxHealth * 0.9 or hrp.Position.Y < 20 then
                    if isPatrolling then
                        ActionLabel.Text = "⚠ PERIGO! SUBINDO..."
                        ActionLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                        
                        -- Cancela voo atual
                        if currentTween then currentTween:Cancel() end
                        
                        -- Sobe para segurança Imediatamente
                        hrp.CFrame = hrp.CFrame + Vector3.new(0, 100, 0)
                        hrp.Anchored = true
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- LOOP PRINCIPAL DE PATRULHA
function StartPatrol()
    isPatrolling = true
    spawn(function()
        local idx = 1
        
        while isPatrolling do
            local point = Waypoints[idx]
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- PASSO 1: SUBIDA TÁTICA
            StatusLabel.Text = "DESTINO: " .. point.Name
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
            ActionLabel.Text = "Subindo para altitude de cruzeiro..."
            
            -- Sobe para a altura de viagem acima de onde está agora
            local highPosStart = CFrame.new(hrp.Position.X, SETTINGS.TravelAltitude, hrp.Position.Z)
            FlyTo(highPosStart, 100) -- Sobe rápido
            
            if not isPatrolling then break end
            
            -- PASSO 2: VIAGEM
            ActionLabel.Text = "Viajando nas nuvens..."
            local highPosDest = CFrame.new(point.Position.X, SETTINGS.TravelAltitude, point.Position.Z)
            FlyTo(highPosDest, SETTINGS.FlightSpeed)
            
            if not isPatrolling then break end

            -- PASSO 3: DESCIDA PARA SCAN
            ActionLabel.Text = "Descendo para escanear..."
            -- Se for Skypiea, a altura é diferente
            local scanY = SETTINGS.ScanAltitude
            if point.Name:find("Skypiea") then scanY = 600 end -- Skypiea é alta
            
            local scanPos = CFrame.new(point.Position.X, scanY, point.Position.Z)
            FlyTo(scanPos, 150) -- Desce devagar
            
            -- PASSO 4: AGUARDANDO RENDERIZAÇÃO
            for i = SETTINGS.WaitTime, 1, -1 do
                if not isPatrolling then break end
                ActionLabel.Text = "Buscando frutas... " .. i .. "s"
                task.wait(1)
            end
            
            -- PASSO 5: VERIFICAÇÃO
            local fruit = ScanForFruits()
            if fruit then
                isPatrolling = false
                StatusLabel.Text = "FRUTA ENCONTRADA!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                Notify("SUCESSO!", "Achamos: " .. fruit.Name)
                
                -- Desce até a fruta
                ActionLabel.Text = "Pousando na fruta..."
                local handle = fruit:FindFirstChild("Handle") or fruit.PrimaryPart
                if handle then
                    FlyTo(handle.CFrame + Vector3.new(0, 2, 0), 50) -- Pouso suave
                end
                
                SetAnchor(false) -- Libera o player
                ButtonStart.Text = "▶ CONTINUAR PATRULHA"
                return -- Para o loop
            end
            
            -- Se não achou, próxima ilha
            idx = idx + 1
            if idx > #Waypoints then idx = 1 end
        end
        
        SetAnchor(false) -- Garante que destrava ao parar
    end)
end

-- BOTÕES
ButtonStart.MouseButton1Click:Connect(function()
    if not isPatrolling then
        ButtonStart.Text = "EM VOO..."
        ButtonStart.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
        StartPatrol()
    end
end)

ButtonStop.MouseButton1Click:Connect(function()
    isPatrolling = false
    if currentTween then currentTween:Cancel() end
    SetAnchor(false)
    StatusLabel.Text = "SISTEMA OFF"
    ActionLabel.Text = "Pouso forçado realizado."
    ButtonStart.Text = "▶ DECOLAR (START)"
    ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
end)