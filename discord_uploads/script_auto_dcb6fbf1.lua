--[[ 
    FRUIT HUNTER V5 - MODO HELICÓPTERO (ANTI-ÁGUA)
    - Trava o personagem no ar enquanto escaneia (Safety Lock).
    - Tempo de espera aumentado para carregar o mapa.
    - Sistema de aterrissagem segura.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local ButtonAutoFarm = Instance.new("TextButton")
local ButtonStop = Instance.new("TextButton")
local TimerLabel = Instance.new("TextLabel") -- Mostra o tempo

ScreenGui.Name = "FruitHunterV5_Safe"
ScreenGui.Parent = game.CoreGui

-- Estilo Visual (Azul Segurança)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 240, 0, 220)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "🚁 FRUIT PATROL V5 (SAFE)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.2, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "AGUARDANDO..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
StatusLabel.TextSize = 14

TimerLabel.Parent = MainFrame
TimerLabel.BackgroundTransparency = 1
TimerLabel.Position = UDim2.new(0, 0, 0.32, 0)
TimerLabel.Size = UDim2.new(1, 0, 0, 20)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Text = ""
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
TimerLabel.TextSize = 16

ButtonAutoFarm.Parent = MainFrame
ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ButtonAutoFarm.Position = UDim2.new(0.1, 0, 0.50, 0)
ButtonAutoFarm.Size = UDim2.new(0.8, 0, 0, 40)
ButtonAutoFarm.Font = Enum.Font.GothamBold
ButtonAutoFarm.Text = "▶ INICIAR PATRULHA"
ButtonAutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonAutoFarm.TextSize = 14

ButtonStop.Parent = MainFrame
ButtonStop.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ButtonStop.Position = UDim2.new(0.1, 0, 0.75, 0)
ButtonStop.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStop.Font = Enum.Font.GothamBold
ButtonStop.Text = "⏹ PARAR / POUSAR"
ButtonStop.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStop.TextSize = 14

-------------------------------------------------------------------------
-- SISTEMA DE COORDENADAS (ALTURA CORRIGIDA)
-------------------------------------------------------------------------
-- Coloquei a altura (Y) em 250 para ficar bem longe da água
local Waypoints = {
    {Name="Pirate Starter", CFrame=CFrame.new(-2572, 250, 2044)},
    {Name="Jungle (Selva)", CFrame=CFrame.new(-1200, 250, 400)},
    {Name="Pirate Village", CFrame=CFrame.new(-1645, 250, -2270)},
    {Name="Desert (Deserto)", CFrame=CFrame.new(940, 250, 4360)},
    {Name="Snow (Neve)", CFrame=CFrame.new(1130, 250, -1230)},
    {Name="Marine Ford", CFrame=CFrame.new(-4950, 250, 720)},
    {Name="Skypiea (Céu)", CFrame=CFrame.new(-4700, 500, -2000)}, -- Skypiea é mais alto
    {Name="Impel Down", CFrame=CFrame.new(5000, 250, 500)},
    {Name="Fountain City", CFrame=CFrame.new(-2000, 250, -5000)},
    {Name="Magma Village", CFrame=CFrame.new(5300, 250, -2600)}
}

local patrolActive = false
local foundFruit = false

-- Configurações de Tempo
local WAIT_TIME = 4.5 -- Segundos para esperar em cada ilha (Aumente se o PC for lento)

function Notify(title, text)
    StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 10;})
end

function CheckForFruit()
    -- Procura frutas carregadas
    for _, item in pairs(Workspace:GetChildren()) do
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
            -- Filtra nomes proibidos
            if not name:find("dealer") and not name:find("gacha") and not name:find("manager") then
                 return item
            end
        end
    end
    -- Procura profunda (caso esteja dentro de pastas)
    for _, item in pairs(Workspace:GetDescendants()) do
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
             if not name:find("dealer") and not name:find("gacha") then
                if item:IsA("Tool") or item:IsA("Model") then
                    local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                    -- Distância segura (2000 studs)
                    if handle and (LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude < 2500 then
                        return item
                    end
                end
            end
        end
    end
    return nil
end

function ToggleAnchor(state)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = state
        -- Zera a velocidade para não "escorregar" no ar
        if state then
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
end

function StartPatrol()
    patrolActive = true
    foundFruit = false
    
    spawn(function()
        local idx = 1
        while patrolActive do
            if foundFruit then break end
            
            local point = Waypoints[idx]
            
            -- FASE 1: VIAGEM
            StatusLabel.Text = "✈ INDO: " .. point.Name
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
            
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- Destrava para mover
            ToggleAnchor(false)
            
            -- TP para o alto da ilha
            hrp.CFrame = point.CFrame
            task.wait(0.2) 
            
            -- FASE 2: TRAVAR NO AR (HELICÓPTERO)
            ToggleAnchor(true) -- AQUI ESTÁ A SEGURANÇA! Você fica congelado no ar.
            
            -- FASE 3: ESCANEAMENTO COM CONTAGEM
            for i = WAIT_TIME, 1, -1 do
                if not patrolActive then break end
                StatusLabel.Text = "ESCANEANDO: " .. point.Name
                TimerLabel.Text = "Aguardando... " .. i .. "s"
                task.wait(1)
            end
            TimerLabel.Text = ""

            -- FASE 4: CHECAGEM FINAL
            local fruit = CheckForFruit()
            
            if fruit then
                -- !!! ACHOU !!!
                foundFruit = true
                patrolActive = false
                ToggleAnchor(false) -- Destrava
                
                StatusLabel.Text = "ACHEI: " .. fruit.Name
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                Notify("FRUTA ENCONTRADA!", "Local: " .. point.Name)
                
                -- Desce suavemente até a fruta
                local handle = fruit:FindFirstChild("Handle") or fruit.PrimaryPart
                if handle then
                    hrp.CFrame = handle.CFrame + Vector3.new(0, 3, 0) -- Cai 3 blocos acima dela
                end
                
                ButtonAutoFarm.Text = "▶ REINICIAR BUSCA"
                return
            end
            
            -- Se não achou, destrava rapidinho e vai para a próxima
            if patrolActive then
                idx = idx + 1
                if idx > #Waypoints then idx = 1 end
            end
        end
        -- Garantia: se parou o loop, destrava o player
        ToggleAnchor(false)
    end)
end

-- EVENTOS
ButtonAutoFarm.MouseButton1Click:Connect(function()
    if not patrolActive then
        ButtonAutoFarm.Text = "EM PATRULHA (Travado no Ar)"
        ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        StartPatrol()
    end
end)

ButtonStop.MouseButton1Click:Connect(function()
    patrolActive = false
    foundFruit = false
    ToggleAnchor(false) -- Solta o player imediatamente
    StatusLabel.Text = "PARADO"
    TimerLabel.Text = ""
    ButtonAutoFarm.Text = "▶ INICIAR PATRULHA"
    ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
end)