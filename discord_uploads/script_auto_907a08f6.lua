-- Configurações Iniciais
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- GUI: Criação das "Caixinhas" (Interface)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ButtonSuck = Instance.new("TextButton") -- Botão "Sugar"
local ButtonTP = Instance.new("TextButton")   -- Botão "Teleportar"
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "FruitCollectorGUI"
ScreenGui.Parent = game.CoreGui

-- Estilo da Janela Principal
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true -- Permite arrastar a janelinha

-- Título
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Coletor de Frutas"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20

-- Botão 1: Sugar (Bring Fruits)
ButtonSuck.Name = "BtnSuck"
ButtonSuck.Parent = MainFrame
ButtonSuck.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ButtonSuck.Position = UDim2.new(0.1, 0, 0.25, 0)
ButtonSuck.Size = UDim2.new(0.8, 0, 0, 40)
ButtonSuck.Font = Enum.Font.SourceSans
ButtonSuck.Text = "[ ] Sugar Frutas (Magnet)"
ButtonSuck.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonSuck.TextSize = 18

-- Botão 2: Teleportar (Tween TP)
ButtonTP.Name = "BtnTP"
ButtonTP.Parent = MainFrame
ButtonTP.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ButtonTP.Position = UDim2.new(0.1, 0, 0.55, 0)
ButtonTP.Size = UDim2.new(0.8, 0, 0, 40)
ButtonTP.Font = Enum.Font.SourceSans
ButtonTP.Text = "[ ] Teleportar p/ Frutas"
ButtonTP.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonTP.TextSize = 18

-- Status
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.Text = "Aguardando..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14

-------------------------------------------------------------------------
-- LÓGICA DO SCRIPT
-------------------------------------------------------------------------

local suckEnabled = false
local tpEnabled = false

-- Função para validar se é uma fruta
function IsFruit(object)
    -- Verifica se tem "Fruit" no nome e se é uma Tool (ferramenta) ou Modelo solto
    if (object:IsA("Tool") or object:IsA("Model")) and (string.find(object.Name, "Fruit") or string.find(object.Name, "Fruta")) then
        -- Evita pegar a fruta que já está na mão do jogador
        if object.Parent ~= LocalPlayer.Character and object.Parent ~= LocalPlayer.Backpack then
            return object:FindFirstChild("Handle") or object.PrimaryPart
        end
    end
    return nil
end

-- Função 1: Sugar (Magnet)
-- Tenta trazer a fruta até você ou simular o toque
function SuckFruits()
    spawn(function()
        while suckEnabled do
            local found = false
            for _, item in pairs(Workspace:GetDescendants()) do
                local handle = IsFruit(item)
                if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    found = true
                    StatusLabel.Text = "Sugando: " .. item.Name
                    
                    -- Método Magente: Tenta mover a fruta para o jogador (Funciona se não estiver ancorada)
                    handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    
                    -- Método FireTouch: Tenta disparar o evento de toque (Funciona se tiver TouchInterest)
                    if handle:FindFirstChild("TouchInterest") then
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                        task.wait()
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                    end
                end
            end
            if not found then StatusLabel.Text = "Nenhuma fruta encontrada." end
            task.wait(0.1)
        end
    end)
end

-- Função 2: Teleporte (Tween)
-- Leva o jogador até a fruta
function TeleportToFruits()
    spawn(function()
        while tpEnabled do
            local found = false
            for _, item in pairs(Workspace:GetDescendants()) do
                local handle = IsFruit(item)
                if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if not tpEnabled then break end
                    found = true
                    StatusLabel.Text = "Indo até: " .. item.Name
                    
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    
                    -- Cria o Tween (Movimento suave para evitar kick)
                    local distance = (hrp.Position - handle.Position).Magnitude
                    local speed = 300 -- Velocidade do voo
                    local info = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, info, {CFrame = handle.CFrame})
                    
                    tween:Play()
                    tween.Completed:Wait()
                    
                    -- Espera um pouco para coletar
                    task.wait(0.5)
                end
            end
            if not found then StatusLabel.Text = "Nenhuma fruta encontrada." end
            task.wait(1)
        end
    end)
end

-- Conectar Botões
ButtonSuck.MouseButton1Click:Connect(function()
    suckEnabled = not suckEnabled
    -- Desativa o outro modo para não conflitar
    if suckEnabled then 
        tpEnabled = false 
        ButtonTP.Text = "[ ] Teleportar p/ Frutas"
        ButtonTP.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        
        ButtonSuck.Text = "[X] Sugando..."
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        SuckFruits()
    else
        ButtonSuck.Text = "[ ] Sugar Frutas (Magnet)"
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        StatusLabel.Text = "Parado."
    end
end)

ButtonTP.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    -- Desativa o outro modo
    if tpEnabled then 
        suckEnabled = false 
        ButtonSuck.Text = "[ ] Sugar Frutas (Magnet)"
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        
        ButtonTP.Text = "[X] Teleportando..."
        ButtonTP.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        TeleportToFruits()
    else
        ButtonTP.Text = "[ ] Teleportar p/ Frutas"
        ButtonTP.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        StatusLabel.Text = "Parado."
    end
end)