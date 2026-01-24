-- Configurações Iniciais
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ButtonSuck = Instance.new("TextButton")
local ButtonTP = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "FruitCollectorV2"
ScreenGui.Parent = game.CoreGui

-- Estilo
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Coletor V2 (Anti-NPC)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20

-- Botão Sugar
ButtonSuck.Name = "BtnSuck"
ButtonSuck.Parent = MainFrame
ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonSuck.Position = UDim2.new(0.1, 0, 0.25, 0)
ButtonSuck.Size = UDim2.new(0.8, 0, 0, 40)
ButtonSuck.Font = Enum.Font.SourceSans
ButtonSuck.Text = "[ ] Sugar Frutas"
ButtonSuck.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonSuck.TextSize = 18

-- Botão TP
ButtonTP.Name = "BtnTP"
ButtonTP.Parent = MainFrame
ButtonTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonTP.Position = UDim2.new(0.1, 0, 0.55, 0)
ButtonTP.Size = UDim2.new(0.8, 0, 0, 40)
ButtonTP.Font = Enum.Font.SourceSans
ButtonTP.Text = "[ ] Teleportar p/ Frutas"
ButtonTP.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonTP.TextSize = 18

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.Text = "Parado"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14

-------------------------------------------------------------------------
-- LÓGICA DE FILTRAGEM (CORRIGIDA)
-------------------------------------------------------------------------

local suckEnabled = false
local tpEnabled = false

function IsRealFruit(object)
    -- 1. Valida se é um objeto válido e se tem nome
    if not object or not object.Parent then return nil end
    
    local name = object.Name:lower()
    
    -- 2. FILTRO DE PALAVRAS (Lista Negra)
    -- Ignora Vendedor, Gacha, NPCs, Quests, etc.
    if name:find("dealer") or name:find("gacha") or name:find("bloxfruit gacha") or name:find("quest") or name:find("manager") then
        return nil
    end

    -- 3. FILTRO DE HUMANOID (Essencial)
    -- Se tiver vida (Humanoid), é NPC ou Player, então ignora.
    if object:FindFirstChildOfClass("Humanoid") then
        return nil
    end

    -- 4. Verifica se tem "Fruit" no nome
    if (name:find("fruit") or name:find("fruta")) then
        
        -- Garante que é uma Tool (item pegável) ou Model solto no mapa
        if object:IsA("Tool") or object:IsA("Model") then
            
            -- Ignora frutas que já estão na mão ou mochila de alguém
            if object.Parent:FindFirstChildOfClass("Humanoid") then return nil end
            
            -- Retorna a parte principal (Handle) para coletar
            return object:FindFirstChild("Handle") or object.PrimaryPart
        end
    end
    
    return nil
end

-- Função 1: Sugar (Magnet)
function SuckFruits()
    spawn(function()
        while suckEnabled do
            local foundSomething = false
            -- Varre o Workspace
            for _, item in pairs(Workspace:GetChildren()) do -- GetChildren é mais leve que GetDescendants aqui
                local handle = IsRealFruit(item)
                if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    foundSomething = true
                    StatusLabel.Text = "Puxando: " .. item.Name
                    
                    -- Traz a fruta pra você
                    if handle:IsA("BasePart") then
                        handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                        -- Simula toque
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                    end
                end
            end
            
            -- Se não achou na raiz, tenta procurar dentro de pastas comuns
            if not foundSomething then
                -- Alguns jogos colocam frutas dentro de pastas específicas, tenta varrer descendentes com cuidado
                for _, item in pairs(Workspace:GetDescendants()) do
                     local handle = IsRealFruit(item)
                     if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        foundSomething = true
                        handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                     end
                     if foundSomething then break end -- Foca em uma por vez pra não lagar
                end
            end

            if not foundSomething then StatusLabel.Text = "Procurando frutas..." end
            task.wait(0.1)
        end
    end)
end

-- Função 2: Teleporte
function TeleportToFruits()
    spawn(function()
        while tpEnabled do
            local foundSomething = false
            for _, item in pairs(Workspace:GetDescendants()) do
                local handle = IsRealFruit(item)
                if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    foundSomething = true
                    StatusLabel.Text = "Indo até: " .. item.Name
                    
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    local distance = (hrp.Position - handle.Position).Magnitude
                    
                    if distance > 3000 then 
                        -- Se for muito longe, apenas teleporta direto (Bypass simples)
                        hrp.CFrame = handle.CFrame
                    else
                        -- Se for perto, vai suave (Tween)
                        local tweenInfo = TweenInfo.new(distance / 350, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = handle.CFrame})
                        tween:Play()
                        tween.Completed:Wait()
                    end
                    
                    task.wait(0.5) -- Tempo pra coletar
                end
                if not tpEnabled then break end
            end
            if not foundSomething then StatusLabel.Text = "Nenhuma fruta no mapa." end
            task.wait(1.5)
        end
    end)
end

-- Conexão dos Botões
ButtonSuck.MouseButton1Click:Connect(function()
    suckEnabled = not suckEnabled
    if suckEnabled then 
        tpEnabled = false 
        ButtonTP.Text = "[ ] Teleportar p/ Frutas"
        ButtonSuck.Text = "[X] Sugando..."
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        SuckFruits()
    else
        ButtonSuck.Text = "[ ] Sugar Frutas"
        ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLabel.Text = "Parado"
    end
end)

ButtonTP.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    if tpEnabled then 
        suckEnabled = false 
        ButtonSuck.Text = "[ ] Sugar Frutas"
        ButtonTP.Text = "[X] Teleportando..."
        ButtonTP.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        TeleportToFruits()
    else
        ButtonTP.Text = "[ ] Teleportar p/ Frutas"
        ButtonTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLabel.Text = "Parado"
    end
end)
