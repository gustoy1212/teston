--[[ 
    FRUIT COLLECTOR V3 - ULTIMATE EDITION
    - Anti-NPC (Vendedor)
    - Teleporte Inteligente (Perto/Longe)
    - ESP (Wallhack de Frutas)
    - Explorador de Mapa
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Limpeza de GUIs antigos para não duplicar
for _, ui in pairs(CoreGui:GetChildren()) do
    if ui.Name == "FruitCollectorV3" then ui:Destroy() end
end

-- GUI PRINCIPAL
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ButtonSuck = Instance.new("TextButton")
local ButtonTP = Instance.new("TextButton")
local ButtonESP = Instance.new("TextButton") -- NOVO
local ButtonScan = Instance.new("TextButton") -- NOVO
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "FruitCollectorV3"
ScreenGui.Parent = CoreGui

-- Estilo Dark Moderno
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 280) -- Maior para caber novos botões
MainFrame.Active = true
MainFrame.Draggable = true 

-- Título
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 85, 0) -- Laranja Blox Fruits
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.GothamBold
Title.Text = "🍊 FRUIT SNIPER V3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

-- Botão 1: Sugar
ButtonSuck.Parent = MainFrame
ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonSuck.Position = UDim2.new(0.05, 0, 0.18, 0)
ButtonSuck.Size = UDim2.new(0.9, 0, 0, 35)
ButtonSuck.Font = Enum.Font.GothamSemibold
ButtonSuck.Text = "🧲 MODO MAGNET (Perto)"
ButtonSuck.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonSuck.TextSize = 14

-- Botão 2: Teleportar
ButtonTP.Parent = MainFrame
ButtonTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonTP.Position = UDim2.new(0.05, 0, 0.33, 0)
ButtonTP.Size = UDim2.new(0.9, 0, 0, 35)
ButtonTP.Font = Enum.Font.GothamSemibold
ButtonTP.Text = "✈️ TELEPORTAR (Longe)"
ButtonTP.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonTP.TextSize = 14

-- Botão 3: ESP (Radar)
ButtonESP.Parent = MainFrame
ButtonESP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonESP.Position = UDim2.new(0.05, 0, 0.48, 0)
ButtonESP.Size = UDim2.new(0.9, 0, 0, 35)
ButtonESP.Font = Enum.Font.GothamSemibold
ButtonESP.Text = "👁️ ESP FRUTAS (Wallhack)"
ButtonESP.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonESP.TextSize = 14

-- Botão 4: Explorar Mapa
ButtonScan.Parent = MainFrame
ButtonScan.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ButtonScan.Position = UDim2.new(0.05, 0, 0.63, 0)
ButtonScan.Size = UDim2.new(0.9, 0, 0, 35)
ButtonScan.Font = Enum.Font.GothamSemibold
ButtonScan.Text = "📡 IR PARA O ALTO (Render)"
ButtonScan.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonScan.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Aguardando comando..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true

-------------------------------------------------------------------------
-- SISTEMA INTELIGENTE DE BUSCA
-------------------------------------------------------------------------

local settings = {
    suck = false,
    tp = false,
    esp = false
}

local esp_drawings = {} -- Armazena os desenhos do ESP

-- Filtro Rigoroso (O mesmo que funcionou pra você)
function GetFruitHandle(object)
    if not object or not object.Parent then return nil end
    local name = object.Name:lower()
    
    -- Lista Negra (Ignora lojas, gachas, npcs)
    if name:find("dealer") or name:find("gacha") or name:find("quest") or name:find("manager") or name:find("bloxfruit") then 
        -- Blox Fruit Dealer tem esse nome, cuidado
        if object:FindFirstChildOfClass("Humanoid") then return nil end
    end
    
    -- Ignora coisas com vida (NPCs/Players)
    if object:FindFirstChildOfClass("Humanoid") then return nil end

    -- Busca por "Fruit" ou "Fruta"
    if (name:find("fruit") or name:find("fruta")) then
        if object:IsA("Tool") or object:IsA("Model") then
            -- Se estiver na mão de alguém, ignora
            if object.Parent:FindFirstChildOfClass("Humanoid") then return nil end
            return object:FindFirstChild("Handle") or object.PrimaryPart
        end
    end
    return nil
end

-- Função de ESP (Desenha na tela onde está a fruta)
function UpdateESP()
    -- Limpa desenhos antigos
    for _, drawing in pairs(esp_drawings) do drawing:Remove() end
    esp_drawings = {}

    if not settings.esp then return end

    for _, item in pairs(Workspace:GetDescendants()) do
        local handle = GetFruitHandle(item)
        if handle then
            -- Converte posição 3D para 2D (Tela)
            local vector, onScreen = Camera:WorldToViewportPoint(handle.Position)
            
            if onScreen then
                local text = Drawing.new("Text")
                text.Text = item.Name .. " [" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - handle.Position).Magnitude) .. "m]"
                text.Size = 18
                text.Color = Color3.fromRGB(0, 255, 0)
                text.Center = true
                text.Outline = true
                text.Position = Vector2.new(vector.X, vector.Y)
                text.Visible = true
                
                table.insert(esp_drawings, text)
                
                -- Desenha linha
                local line = Drawing.new("Line")
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(vector.X, vector.Y)
                line.Color = Color3.fromRGB(0, 255, 0)
                line.Thickness = 1
                line.Transparency = 0.5
                line.Visible = true
                
                table.insert(esp_drawings, line)
            end
        end
    end
end

-- Loop Principal (Gerencia TP e Magnet)
spawn(function()
    while true do
        if settings.esp then UpdateESP() end
        
        -- Busca Frutas
        local targetHandle = nil
        local targetItem = nil
        
        -- Varredura Global
        for _, item in pairs(Workspace:GetDescendants()) do
            local h = GetFruitHandle(item)
            if h then
                targetHandle = h
                targetItem = item
                break -- Foca na primeira que achar
            end
        end

        if targetHandle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local distance = (hrp.Position - targetHandle.Position).Magnitude
            
            -- Lógica de Teleporte
            if settings.tp then
                StatusLabel.Text = "DETECTADO: " .. targetItem.Name
                
                -- Se estiver muito longe (>3000 studs), teleporta com Bypass (CFrame direto)
                -- Se estiver perto, vai voando suave (Tween) para não ser kickado
                if distance > 3000 then
                    hrp.CFrame = targetHandle.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.2) -- Espera carregar
                else
                    local speed = 350
                    local info = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, info, {CFrame = targetHandle.CFrame})
                    tween:Play()
                    -- Se chegar perto, cancela tween e pega
                    task.wait(distance/speed)
                end
                
                -- Tenta pegar equipando
                if targetItem:IsA("Tool") then
                    targetItem.Parent = LocalPlayer.Character
                end
            end
            
            -- Lógica de Magnet (Sugar)
            if settings.suck then
                StatusLabel.Text = "PUXANDO: " .. targetItem.Name
                if targetHandle:IsA("BasePart") then
                    targetHandle.CFrame = hrp.CFrame
                    targetHandle.Velocity = Vector3.new(0,0,0) -- Para a fruta não sair voando
                    targetHandle.CanCollide = false
                end
                firetouchinterest(hrp, targetHandle, 0)
                task.wait()
                firetouchinterest(hrp, targetHandle, 1)
            end
        else
            if settings.tp or settings.suck then
                StatusLabel.Text = "Procurando frutas no mapa..."
            end
        end
        
        task.wait(0.1)
    end
end)

-------------------------------------------------------------------------
-- BOTÕES
-------------------------------------------------------------------------

ButtonSuck.MouseButton1Click:Connect(function()
    settings.suck = not settings.suck
    settings.tp = false -- Desativa TP para não conflitar
    ButtonTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ButtonSuck.BackgroundColor3 = settings.suck and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
end)

ButtonTP.MouseButton1Click:Connect(function()
    settings.tp = not settings.tp
    settings.suck = false -- Desativa Suck
    ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ButtonTP.BackgroundColor3 = settings.tp and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
end)

ButtonESP.MouseButton1Click:Connect(function()
    settings.esp = not settings.esp
    ButtonESP.BackgroundColor3 = settings.esp and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
    if not settings.esp then
        for _, drawing in pairs(esp_drawings) do drawing:Remove() end
    end
end)

-- FUNÇÃO ESPECIAL: EXPLORADOR
ButtonScan.MouseButton1Click:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    StatusLabel.Text = "Subindo para renderizar mapa..."
    local hrp = LocalPlayer.Character.HumanoidRootPart
    
    -- Teleporta para o centro do mapa bem alto (Y = 1500)
    -- Isso geralmente força o client a carregar ilhas num raio maior
    local oldPos = hrp.CFrame
    hrp.CFrame = CFrame.new(0, 1500, 0)
    
    -- Trava no ar por 3 segundos
    local bv = Instance.new("BodyVelocity", hrp)
    bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    
    task.wait(3)
    bv:Destroy()
    
    StatusLabel.Text = "Scan concluído. Verifique o ESP."
end)