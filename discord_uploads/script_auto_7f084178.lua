--[[ 
    FRUIT HUNTER V4 - AUTO PATRULHA
    - Viaja sozinho entre as ilhas procurando frutas.
    - Para automaticamente quando encontra algo.
    - Notificação de tela e som.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local ButtonAutoFarm = Instance.new("TextButton")
local ButtonStop = Instance.new("TextButton")

ScreenGui.Name = "FruitHunterV4"
ScreenGui.Parent = game.CoreGui

-- Estilo Visual (Vermelho e Preto - Estilo Radar)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 200)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "🍒 FRUIT HUNTER V4"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.2, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 40)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "SISTEMA PRONTO"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true

-- Botão Iniciar Patrulha
ButtonAutoFarm.Parent = MainFrame
ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ButtonAutoFarm.Position = UDim2.new(0.1, 0, 0.45, 0)
ButtonAutoFarm.Size = UDim2.new(0.8, 0, 0, 40)
ButtonAutoFarm.Font = Enum.Font.GothamBold
ButtonAutoFarm.Text = "▶ INICIAR PATRULHA"
ButtonAutoFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonAutoFarm.TextSize = 14

-- Botão Parar
ButtonStop.Parent = MainFrame
ButtonStop.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ButtonStop.Position = UDim2.new(0.1, 0, 0.70, 0)
ButtonStop.Size = UDim2.new(0.8, 0, 0, 40)
ButtonStop.Font = Enum.Font.GothamBold
ButtonStop.Text = "⏹ PARAR TUDO"
ButtonStop.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonStop.TextSize = 14

-------------------------------------------------------------------------
-- SISTEMA DE DETECÇÃO
-------------------------------------------------------------------------

-- Coordenadas das Ilhas (Sea 1 Padrão)
local Waypoints = {
    {Name="Pirate Starter", CFrame=CFrame.new(-2572, 100, 2044)},
    {Name="Jungle", CFrame=CFrame.new(-1200, 100, 400)},
    {Name="Buggy Island", CFrame=CFrame.new(-1645, 100, -2270)},
    {Name="Desert", CFrame=CFrame.new(940, 100, 4360)},
    {Name="Snow Village", CFrame=CFrame.new(1130, 100, -1230)},
    {Name="Marine Ford", CFrame=CFrame.new(-4950, 100, 720)},
    {Name="Skypiea Lower", CFrame=CFrame.new(-4700, 500, -2000)},
    {Name="Skypiea Upper", CFrame=CFrame.new(-7900, 1000, -5600)},
    {Name="Impel Down", CFrame=CFrame.new(5000, 100, 500)},
    {Name="Fountain City", CFrame=CFrame.new(-2000, 100, -5000)},
    {Name="Magma Village", CFrame=CFrame.new(5300, 100, -2600)}
}

local patrolActive = false
local foundFruit = false

function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 10;
    })
    -- Tenta tocar um som de "ding"
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://4590662766" -- Som de notificação
    sound.Parent = Workspace
    sound.PlayOnRemove = true
    sound:Destroy()
end

function CheckForFruit()
    for _, item in pairs(Workspace:GetChildren()) do
        -- Lógica de filtro (Anti-NPC/Dealer)
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
            if not name:find("dealer") and not name:find("gacha") and not name:find("manager") then
                 if item:IsA("Tool") or item:IsA("Model") then
                    return item -- Retorna a fruta achada
                 end
            end
        end
    end
    -- Varredura profunda se não achar na raiz
    for _, item in pairs(Workspace:GetDescendants()) do
        local name = item.Name:lower()
        if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
            -- Verifica distância (só pega se tiver perto, < 2000 studs)
            if LocalPlayer.Character and (item:IsA("Tool") or item:IsA("Model")) then
                local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                if handle then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude
                    if dist < 2000 then -- Confirma que é uma fruta carregada PELA ilha atual
                         return item
                    end
                end
            end
        end
    end
    return nil
end

function StartPatrol()
    patrolActive = true
    foundFruit = false
    
    spawn(function()
        local idx = 1
        while patrolActive do
            if foundFruit then break end -- Para se achou fruta
            
            local point = Waypoints[idx]
            StatusLabel.Text = "Indo para: " .. point.Name
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- TELEPORTE RÁPIDO (Bypass)
            -- Como estamos caçando, usamos TP direto para carregar o chunk rápido
            hrp.CFrame = point.CFrame
            
            -- Espera o jogo carregar a ilha (StreamingEnabled precisa de tempo)
            StatusLabel.Text = "Escaneando: " .. point.Name
            task.wait(1.5) -- Tempo para renderizar as frutas
            
            -- CHECAGEM
            local fruit = CheckForFruit()
            if fruit then
                foundFruit = true
                patrolActive = false
                
                -- AÇÃO QUANDO ACHA
                StatusLabel.Text = "FRUTA DETECTADA!!!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                Notify("FRUTA ENCONTRADA!", "Local: " .. point.Name .. "\nFruta: " .. fruit.Name)
                
                -- Vai até a fruta
                local handle = fruit:FindFirstChild("Handle") or fruit.PrimaryPart
                if handle then
                    hrp.CFrame = handle.CFrame
                    -- Tenta pegar
                    firetouchinterest(hrp, handle, 0)
                    firetouchinterest(hrp, handle, 1)
                end
                
                ButtonAutoFarm.Text = "▶ REINICIAR BUSCA"
                ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
                return -- Encerra o loop
            end
            
            -- Se não achou, próxima ilha
            idx = idx + 1
            if idx > #Waypoints then idx = 1 end
            task.wait(0.5)
        end
    end)
end

-- EVENTOS DE BOTÃO
ButtonAutoFarm.MouseButton1Click:Connect(function()
    if not patrolActive then
        ButtonAutoFarm.Text = "EM PATRULHA..."
        ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
        StartPatrol()
    end
end)

ButtonStop.MouseButton1Click:Connect(function()
    patrolActive = false
    foundFruit = false
    StatusLabel.Text = "PARADO PELO USUÁRIO"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ButtonAutoFarm.Text = "▶ INICIAR PATRULHA"
    ButtonAutoFarm.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
end)