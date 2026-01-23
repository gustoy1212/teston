--[[ 
    FRUIT COLLECTOR V3 - SISTEMA GPS
    - Lista de Ilhas pré-configurada (Sea 1 Padrão)
    - Botão para Salvar Locais Personalizados
    - Teleporte Aéreo (Para não cair na água)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ButtonSuck = Instance.new("TextButton")
local ButtonTPFruit = Instance.new("TextButton")
local ButtonNextIsland = Instance.new("TextButton")
local ButtonSaveSpot = Instance.new("TextButton") -- NOVO
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "FruitCollectorGPS"
ScreenGui.Parent = game.CoreGui

-- Estilo
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 260)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "🍊 FRUIT GPS V3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

-- Botões
function CreateButton(name, text, order, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = MainFrame
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    btn.Position = UDim2.new(0.05, 0, 0.15 + (order * 0.16), 0)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    return btn
end

ButtonSuck = CreateButton("BtnSuck", "[ ] Sugar Frutas (Perto)", 0)
ButtonTPFruit = CreateButton("BtnTP", "[ ] TP p/ Fruta (Achada)", 1)
ButtonNextIsland = CreateButton("BtnNext", "✈️ Próxima Ilha (GPS)", 2, Color3.fromRGB(0, 100, 200))
ButtonSaveSpot = CreateButton("BtnSave", "📍 Salvar Local Atual", 3, Color3.fromRGB(200, 150, 0))

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.88, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "GPS Carregado."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12

-------------------------------------------------------------------------
-- SISTEMA GPS (COORDENADAS)
-------------------------------------------------------------------------

-- Lista de coordenadas aproximadas do Sea 1 (Padrão Blox Fruits)
-- Se o jogo for um clone fiel, isso vai funcionar.
local Waypoints = {
    CFrame.new(-2572, 100, 2044),  -- Starter Pirate
    CFrame.new(-1200, 100, 400),   -- Jungle (Meio)
    CFrame.new(-1645, 100, -2270), -- Buggy (Pirate Village)
    CFrame.new(940, 100, 4360),    -- Desert
    CFrame.new(1130, 100, -1230),  -- Snow / Frozen Village
    CFrame.new(-4950, 100, 720),   -- Marine Fortress
    CFrame.new(-4700, 500, -2000), -- Skypiea (Baixo)
    CFrame.new(-7900, 1000, -5600),-- Skypiea (Alto)
    CFrame.new(5000, 100, 500),    -- Prison / Impel Down
    CFrame.new(-2000, 100, -5000), -- Fountain City
    CFrame.new(5300, 100, -2600)   -- Magma Village
}

local currentIndex = 1

-- Botão: Salvar Local
ButtonSaveSpot.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.CFrame
        table.insert(Waypoints, pos)
        StatusLabel.Text = "Local salvo! Total: " .. #Waypoints
        ButtonSaveSpot.Text = "📍 Salvo! (" .. #Waypoints .. ")"
        wait(1)
        ButtonSaveSpot.Text = "📍 Salvar Local Atual"
    end
end)

-- Botão: Próxima Ilha
ButtonNextIsland.MouseButton1Click:Connect(function()
    if #Waypoints == 0 then StatusLabel.Text = "Nenhum waypoint!" return end
    
    local target = Waypoints[currentIndex]
    StatusLabel.Text = "Viajando para Local " .. currentIndex .. "..."
    
    -- Teleporte Seguro (Voando)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    -- Sobe primeiro para não bater em paredes
    local upPos = hrp.CFrame + Vector3.new(0, 200, 0)
    local tweenUp = TweenService:Create(hrp, TweenInfo.new(0.5), {CFrame = upPos})
    tweenUp:Play()
    tweenUp.Completed:Wait()
    
    -- Calcula tempo baseado na distância (velocidade 350)
    local dist = (hrp.Position - target.Position).Magnitude
    local time = dist / 350
    if time < 1 then time = 1 end
    
    -- Vai até o destino (mantendo altura)
    local travelCFrame = CFrame.new(target.Position.X, 300, target.Position.Z) -- Vai por cima (Y=300)
    local tweenTravel = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = travelCFrame})
    tweenTravel:Play()
    tweenTravel.Completed:Wait()
    
    -- Desce
    hrp.CFrame = target + Vector3.new(0, 50, 0) -- Cai um pouco acima do ponto
    
    StatusLabel.Text = "Chegou no Local " .. currentIndex
    currentIndex = currentIndex + 1
    if currentIndex > #Waypoints then currentIndex = 1 end
end)

-------------------------------------------------------------------------
-- SISTEMA DE COLETA (MANTIDO DO ANTERIOR)
-------------------------------------------------------------------------

local suckEnabled = false
local tpEnabled = false

function IsRealFruit(object)
    if not object or not object.Parent then return nil end
    local name = object.Name:lower()
    
    if name:find("dealer") or name:find("gacha") or name:find("quest") or name:find("manager") or name:find("bloxfruit") then 
         if object:FindFirstChildOfClass("Humanoid") then return nil end
    end
    if object:FindFirstChildOfClass("Humanoid") then return nil end

    if (name:find("fruit") or name:find("fruta")) then
        if object:IsA("Tool") or object:IsA("Model") then
            if object.Parent:FindFirstChildOfClass("Humanoid") then return nil end
            return object:FindFirstChild("Handle") or object.PrimaryPart
        end
    end
    return nil
end

function ScanAndAct()
    spawn(function()
        while suckEnabled or tpEnabled do
            local found = false
            -- Varre Workspace
            for _, item in pairs(Workspace:GetChildren()) do
                local handle = IsRealFruit(item)
                if handle and LocalPlayer.Character then
                    found = true
                    StatusLabel.Text = "ACHEI: " .. item.Name
                    
                    if suckEnabled then
                         if handle:IsA("BasePart") then
                            handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                        end
                    elseif tpEnabled then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = handle.CFrame
                    end
                end
            end
            if not found then StatusLabel.Text = "Procurando nesta ilha..." end
            task.wait(0.2)
        end
    end)
end

ButtonSuck.MouseButton1Click:Connect(function()
    suckEnabled = not suckEnabled
    tpEnabled = false
    if suckEnabled then 
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        ScanAndAct()
    else
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

ButtonTPFruit.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    suckEnabled = false
    if tpEnabled then 
        ButtonTPFruit.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        ScanAndAct()
    else
        ButtonTPFruit.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)