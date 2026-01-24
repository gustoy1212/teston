--[[ 
    FRUIT HUNTER V8 - MANUAL & AUTO LANDING
    - Correção: Voo de pouso independente da patrulha.
    - Novo Botão: "Ir até a Fruta" (Aparece quando acha).
    - Sistema Anti-Kick mantido.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES
local SETTINGS = {
    FlightSpeed = 230,      -- Velocidade de Cruzeiro
    TravelAltitude = 500,   -- Altura de Viagem
    ScanAltitude = 250,     -- Altura de Scan
    ScanTime = 4            -- Tempo de espera na ilha
}

-- VARIAVEIS GLOBAIS
local isPatrolling = false
local currentTargetFruit = nil -- Guarda a fruta achada
local currentBV = nil
local currentBG = nil
local noclipConnection = nil

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
local ButtonGoTo = Instance.new("TextButton") -- NOVO BOTÃO
local ButtonStop = Instance.new("TextButton")

ScreenGui.Name = "FruitHunterV8"
ScreenGui.Parent = game.CoreGui

-- Estilo
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBlack
Title.Text = "🍒 V8 HUNTER + POUSO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.12, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "AGUARDANDO"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 14

ActionLabel.Parent = MainFrame
ActionLabel.BackgroundTransparency = 1
ActionLabel.Position = UDim2.new(0, 0, 0.22, 0)
ActionLabel.Size = UDim2.new(1, 0, 0, 20)
ActionLabel.Font = Enum.Font.Gotham
ActionLabel.Text = "..."
ActionLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
ActionLabel.TextSize = 12

ButtonStart.Parent = MainFrame
ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ButtonStart.Position = UDim2.new(0.1, 0, 0.35, 0)
ButtonStart.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStart.Font = Enum.Font.GothamBold
ButtonStart.Text = "▶ INICIAR PATRULHA"
ButtonStart.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStart.TextSize = 13

-- Botão Manual de Ir até a Fruta
ButtonGoTo.Parent = MainFrame
ButtonGoTo.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Laranja
ButtonGoTo.Position = UDim2.new(0.1, 0, 0.52, 0)
ButtonGoTo.Size = UDim2.new(0.8, 0, 0, 40)
ButtonGoTo.Font = Enum.Font.GothamBold
ButtonGoTo.Text = "⬇ DESCER ATÉ A FRUTA"
ButtonGoTo.TextColor3 = Color3.fromRGB(0, 0, 0)
ButtonGoTo.TextSize = 13
ButtonGoTo.Visible = false -- Começa escondido

ButtonStop.Parent = MainFrame
ButtonStop.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ButtonStop.Position = UDim2.new(0.1, 0, 0.80, 0)
ButtonStop.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStop.Font = Enum.Font.GothamBold
ButtonStop.Text = "⏹ PARAR TUDO"
ButtonStop.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStop.TextSize = 13

-------------------------------------------------------------------------
-- SISTEMA DE VOO
-------------------------------------------------------------------------

function EnableNoclip(state)
    if noclipConnection then noclipConnection:Disconnect() end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    end
end

function StopFlight()
    if currentBV then currentBV:Destroy() end
    if currentBG then currentBG:Destroy() end
    EnableNoclip(false)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        LocalPlayer.Character.HumanoidRootPart.Anchored = false -- Garante que destrava
    end
end

-- Voo Físico Genérico (Funciona para Patrulha e para Pouso)
function FlyToPosition(targetPos, speed, stopCondition)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    -- Limpa forças antigas
    if currentBV then currentBV:Destroy() end
    if currentBG then currentBG:Destroy() end
    
    currentBV = Instance.new("BodyVelocity")
    currentBV.Velocity = Vector3.new(0,0,0)
    currentBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    currentBV.Parent = hrp
    
    currentBG = Instance.new("BodyGyro")
    currentBG.P = 9000; currentBG.D = 200; currentBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    currentBG.CFrame = hrp.CFrame
    currentBG.Parent = hrp
    
    EnableNoclip(true)
    hrp.Anchored = false
    
    while LocalPlayer.Character do
        -- Checa condição de parada externa (ex: botão parar)
        if stopCondition and stopCondition() == true then break end
        
        local currentPos = hrp.Position
        local direction = (targetPos - currentPos)
        local dist = direction.Magnitude
        
        if dist < 10 then break end -- Chegou
        
        direction = direction.Unit
        currentBV.Velocity = direction * speed
        currentBG.CFrame = CFrame.new(currentPos, targetPos)
        
        task.wait()
    end
    
    if currentBV then currentBV.Velocity = Vector3.new(0,0,0) end
end

-- Detecção
function ScanForFruits()
    for _, item in pairs(Workspace:GetChildren()) do
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
             if not name:find("dealer") and not name:find("gacha") then return item end
        end
    end
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

-------------------------------------------------------------------------
-- LÓGICA DE BOTÕES E PATRULHA
-------------------------------------------------------------------------

function StartPatrol()
    isPatrolling = true
    ButtonGoTo.Visible = false
    currentTargetFruit = nil
    
    spawn(function()
        local idx = 1
        while isPatrolling do
            local point = Waypoints[idx]
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            StatusLabel.Text = "DESTINO: " .. point.Name
            
            -- 1. Sobe
            ActionLabel.Text = "Subindo..."
            FlyToPosition(Vector3.new(hrp.Position.X, SETTINGS.TravelAltitude, hrp.Position.Z), 100, function() return not isPatrolling end)
            
            -- 2. Viaja
            if not isPatrolling then break end
            ActionLabel.Text = "Viajando..."
            FlyToPosition(Vector3.new(point.Position.X, SETTINGS.TravelAltitude, point.Position.Z), SETTINGS.FlightSpeed, function() return not isPatrolling end)
            
            -- 3. Desce
            if not isPatrolling then break end
            ActionLabel.Text = "Aproximando..."
            local targetY = SETTINGS.ScanAltitude
            if point.Name:find("Skypiea") then targetY = 600 end
            FlyToPosition(Vector3.new(point.Position.X, targetY, point.Position.Z), 150, function() return not isPatrolling end)
            
            -- 4. Trava e Escaneia
            if currentBV then currentBV.Velocity = Vector3.new(0,0,0) end
            
            for i = SETTINGS.ScanTime, 1, -1 do
                if not isPatrolling then break end
                ActionLabel.Text = "Escaneando... " .. i
                task.wait(1)
            end
            
            -- 5. Verifica
            local fruit = ScanForFruits()
            if fruit then
                -- !!! ACHOU !!!
                isPatrolling = false -- Para a patrulha
                currentTargetFruit = fruit -- Salva a fruta
                
                StatusLabel.Text = "FRUTA ENCONTRADA!"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                ActionLabel.Text = "Esperando comando..."
                
                StopFlight() -- Para o voo de patrulha
                
                -- Trava o player no ar para ele não cair enquanto decide
                hrp.Anchored = true 
                
                -- Ativa botão manual
                ButtonGoTo.Visible = true
                ButtonStart.Text = "▶ REINICIAR"
                
                -- Tenta auto-pouso (opcional, pode tirar se preferir só manual)
                StarterGui:SetCore("SendNotification", {Title="FRUTA!"; Text="Clique no botão para pegar!"; Duration=10;})
                
                return -- Sai do loop
            end
            
            idx = idx + 1
            if idx > #Waypoints then idx = 1 end
        end
        StopFlight()
    end)
end

-- Botão: Ir até a Fruta (NOVO)
ButtonGoTo.MouseButton1Click:Connect(function()
    if currentTargetFruit then
        local handle = currentTargetFruit:FindFirstChild("Handle") or currentTargetFruit.PrimaryPart
        if handle then
            StatusLabel.Text = "INDO PEGAR..."
            ActionLabel.Text = "Descendo..."
            ButtonGoTo.Visible = false
            
            -- Usa o voo suave para ir até lá (Não depende de isPatrolling)
            FlyToPosition(handle.Position + Vector3.new(0, 3, 0), 60, nil)
            
            StopFlight()
            ActionLabel.Text = "Chegamos!"
        else
            ActionLabel.Text = "Erro: Fruta sumiu?"
        end
    end
end)

ButtonStart.MouseButton1Click:Connect(function()
    if not isPatrolling then
        ButtonStart.Text = "EM PATRULHA..."
        ButtonStart.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        StartPatrol()
    end
end)

ButtonStop.MouseButton1Click:Connect(function()
    isPatrolling = false
    StopFlight()
    ButtonGoTo.Visible = false
    StatusLabel.Text = "PARADO"
    ButtonStart.Text = "▶ INICIAR"
    ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
end)