--[[ 
    FRUIT HUNTER V7 - PHYSICS FLIGHT (ANTI-KICK)
    - Usa BodyVelocity (Física) em vez de Tween/CFrame.
    - Noclip Automático (Atravessa paredes para não travar).
    - Sistema de Altitude Inteligente.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES DE SEGURANÇA
local SETTINGS = {
    FlightSpeed = 220,      -- Velocidade reduzida para evitar kick (Padrão era 300)
    TravelAltitude = 500,   -- Altura de viagem
    ScanAltitude = 250,     -- Altura de busca
    ScanTime = 5            -- Tempo parado escaneando
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

ScreenGui.Name = "FruitHunterV7_AntiKick"
ScreenGui.Parent = game.CoreGui

-- Estilo Clean
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 240)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBlack
Title.Text = "🛡️ V7 ANTI-KICK (FÍSICA)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.15, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "SISTEMA PARADO"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 14

ActionLabel.Parent = MainFrame
ActionLabel.BackgroundTransparency = 1
ActionLabel.Position = UDim2.new(0, 0, 0.28, 0)
ActionLabel.Size = UDim2.new(1, 0, 0, 20)
ActionLabel.Font = Enum.Font.Gotham
ActionLabel.Text = "Aguardando..."
ActionLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
ActionLabel.TextSize = 12

ButtonStart.Parent = MainFrame
ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ButtonStart.Position = UDim2.new(0.1, 0, 0.45, 0)
ButtonStart.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStart.Font = Enum.Font.GothamBold
ButtonStart.Text = "▶ INICIAR VOO SEGURO"
ButtonStart.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStart.TextSize = 13

ButtonStop.Parent = MainFrame
ButtonStop.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ButtonStop.Position = UDim2.new(0.1, 0, 0.70, 0)
ButtonStop.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStop.Font = Enum.Font.GothamBold
ButtonStop.Text = "⏹ POUSAR IMEDIATAMENTE"
ButtonStop.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStop.TextSize = 13

-------------------------------------------------------------------------
-- SISTEMA DE VOO FÍSICO (BODYVELOCITY)
-------------------------------------------------------------------------

local isPatrolling = false
local currentBV = nil
local currentBG = nil
local noclipConnection = nil

-- Noclip: Impede que você bata em paredes e seja kickado por "clipar"
function EnableNoclip(state)
    if noclipConnection then noclipConnection:Disconnect() end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- Função de Voo Físico
function FlyTo(targetPosition)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    -- Limpa forças anteriores
    if currentBV then currentBV:Destroy() end
    if currentBG then currentBG:Destroy() end
    
    -- Cria BodyVelocity (Motor)
    currentBV = Instance.new("BodyVelocity")
    currentBV.Velocity = Vector3.new(0,0,0)
    currentBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    currentBV.Parent = hrp
    
    -- Cria BodyGyro (Estabilidade/Rotação)
    currentBG = Instance.new("BodyGyro")
    currentBG.P = 9000
    currentBG.D = 200
    currentBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    currentBG.CFrame = hrp.CFrame
    currentBG.Parent = hrp
    
    -- Loop de movimento
    EnableNoclip(true)
    
    while isPatrolling and LocalPlayer.Character do
        local currentPos = hrp.Position
        local direction = (targetPosition - currentPos)
        local distance = direction.Magnitude
        
        -- Chegou? (Margem de erro de 5 studs)
        if distance < 10 then
            currentBV.Velocity = Vector3.new(0,0,0)
            break
        end
        
        -- Calcula velocidade (Direção normalizada * Velocidade)
        direction = direction.Unit
        currentBV.Velocity = direction * SETTINGS.FlightSpeed
        currentBG.CFrame = CFrame.new(currentPos, targetPosition)
        
        task.wait()
    end
    
    -- Limpa ao terminar este trajeto
    if currentBV then currentBV.Velocity = Vector3.new(0,0,0) end
end

function StopFlight()
    if currentBV then currentBV:Destroy() end
    if currentBG then currentBG:Destroy() end
    EnableNoclip(false)
    -- Zera gravidade residual
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
end

-- Detecção de Frutas
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

-- ROTINA PRINCIPAL
function StartPatrol()
    isPatrolling = true
    spawn(function()
        local idx = 1
        
        while isPatrolling do
            local point = Waypoints[idx]
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            StatusLabel.Text = "DESTINO: " .. point.Name
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
            
            -- 1. SOBE (Segurança)
            ActionLabel.Text = "Decolando..."
            FlyTo(Vector3.new(hrp.Position.X, SETTINGS.TravelAltitude, hrp.Position.Z))
            
            -- 2. VIAJA (Horizontal)
            if not isPatrolling then break end
            ActionLabel.Text = "Voando para ilha..."
            FlyTo(Vector3.new(point.Position.X, SETTINGS.TravelAltitude, point.Position.Z))
            
            -- 3. DESCE (Para Scan)
            if not isPatrolling then break end
            ActionLabel.Text = "Descendo para escanear..."
            
            local targetY = SETTINGS.ScanAltitude
            if point.Name:find("Skypiea") then targetY = 600 end -- Skypiea é alta
            
            FlyTo(Vector3.new(point.Position.X, targetY, point.Position.Z))
            
            -- 4. ESPERA (Carregamento)
            -- Para o voo temporariamente para economizar recursos
            if currentBV then currentBV.Velocity = Vector3.new(0,0,0) end
            
            for i = SETTINGS.ScanTime, 1, -1 do
                if not isPatrolling then break end
                ActionLabel.Text = "Procurando... " .. i .. "s"
                task.wait(1)
            end
            
            -- 5. VERIFICA
            local fruit = ScanForFruits()
            if fruit then
                isPatrolling = false
                StatusLabel.Text = "FRUTA ENCONTRADA!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                
                -- Pousa na fruta
                local handle = fruit:FindFirstChild("Handle") or fruit.PrimaryPart
                if handle then
                    ActionLabel.Text = "Pousando na fruta..."
                    FlyTo(handle.Position + Vector3.new(0, 3, 0))
                end
                
                StopFlight()
                ButtonStart.Text = "▶ REINICIAR"
                
                -- Notificação
                StarterGui:SetCore("SendNotification", {
                    Title = "FRUTA!!!";
                    Text = "Achamos: " .. fruit.Name;
                    Duration = 10;
                })
                return
            end
            
            -- Próxima Ilha
            idx = idx + 1
            if idx > #Waypoints then idx = 1 end
        end
        StopFlight()
    end)
end

-- Botões
ButtonStart.MouseButton1Click:Connect(function()
    if not isPatrolling then
        ButtonStart.Text = "EM VOO (Física Ativa)"
        ButtonStart.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        StartPatrol()
    end
end)

ButtonStop.MouseButton1Click:Connect(function()
    isPatrolling = false
    StopFlight()
    StatusLabel.Text = "PARADO"
    ActionLabel.Text = ""
    ButtonStart.Text = "▶ INICIAR VOO SEGURO"
    ButtonStart.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
end)