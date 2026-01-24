--[[
    BLOX TOOLKIT V5 - VERSÃO DE EMERGÊNCIA
    - Interface na PlayerGui (Garantido aparecer)
    - Carrega o menu PRIMEIRO, depois a lógica
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- 1. CRIAÇÃO DA INTERFACE (PRIORIDADE MÁXIMA)
-- ==============================================================================

-- Remove UI antiga se existir
if LocalPlayer.PlayerGui:FindFirstChild("BloxEmergency") then 
    LocalPlayer.PlayerGui.BloxEmergency:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxEmergency"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") -- Mudei pra PlayerGui (Mais seguro)
ScreenGui.ResetOnSpawn = false -- Não some se morrer

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 260)
MainFrame.Active = true
MainFrame.Draggable = true -- Pode arrastar

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Blox Fruits V5 (Emergency)"
Title.TextColor3 = Color3.white
Title.TextSize = 18

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "Carregando..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusLabel.TextSize = 12

-- BOTÕES (JÁ CRIADOS ANTES DA LÓGICA)
local BtnTP = Instance.new("TextButton")
BtnTP.Parent = MainFrame
BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnTP.Position = UDim2.new(0.1, 0, 0.15, 0)
BtnTP.Size = UDim2.new(0.8, 0, 0, 40)
BtnTP.Font = Enum.Font.SourceSans
BtnTP.Text = "TP Frutas (Buscando...)"
BtnTP.TextColor3 = Color3.white
BtnTP.TextSize = 18

local BtnGacha = Instance.new("TextButton")
BtnGacha.Parent = MainFrame
BtnGacha.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Cinza por enquanto
BtnGacha.Position = UDim2.new(0.1, 0, 0.35, 0)
BtnGacha.Size = UDim2.new(0.8, 0, 0, 40)
BtnGacha.Font = Enum.Font.SourceSansBold
BtnGacha.Text = "Giro Random (Carregando)"
BtnGacha.TextColor3 = Color3.white
BtnGacha.TextSize = 18

local BtnStore = Instance.new("TextButton")
BtnStore.Parent = MainFrame
BtnStore.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnStore.Position = UDim2.new(0.1, 0, 0.55, 0)
BtnStore.Size = UDim2.new(0.8, 0, 0, 40)
BtnStore.Font = Enum.Font.SourceSansBold
BtnStore.Text = "Guardar Frutas"
BtnStore.TextColor3 = Color3.white
BtnStore.TextSize = 18

local Close = Instance.new("TextButton")
Close.Parent = MainFrame
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Position = UDim2.new(0.85, 0, 0, 0)
Close.Size = UDim2.new(0.15, 0, 0, 30)
Close.Text = "X"
Close.TextColor3 = Color3.white

-- ==============================================================================
-- 2. LÓGICA (RODA EM PARALELO PRA NÃO TRAVAR O MENU)
-- ==============================================================================

local CommF = nil
local tpAtivo = false

task.spawn(function()
    -- Tenta achar o Remote do Blox Fruits
    StatusLabel.Text = "Procurando CommF_..."
    
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
        CommF = ReplicatedStorage.Remotes.CommF_
    else
        -- Busca profunda se não achar no lugar padrão
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "CommF_" and v:IsA("RemoteFunction") then
                CommF = v
                break
            end
        end
    end

    -- Atualiza os botões baseado no resultado
    if CommF then
        StatusLabel.Text = "Status: Conectado!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        BtnGacha.Text = "🎲 Girar Fruta (Random)"
        BtnGacha.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
        
        BtnStore.Text = "📦 Guardar Frutas"
        BtnStore.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        StatusLabel.Text = "ERRO: Remote não achado."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        BtnGacha.Text = "Erro (Sem Remote)"
        BtnStore.Text = "Erro (Sem Remote)"
    end
    
    BtnTP.Text = "Teleportar p/ Frutas" -- TP libera sempre
end)

-- ==============================================================================
-- 3. FUNÇÕES DOS BOTÕES
-- ==============================================================================

-- TP FRUTAS
BtnTP.MouseButton1Click:Connect(function()
    tpAtivo = not tpAtivo
    if tpAtivo then
        BtnTP.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        BtnTP.Text = "[X] Buscando..."
        
        spawn(function()
            while tpAtivo do
                local achou = false
                pcall(function()
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if not tpAtivo then break end
                        
                        -- Busca simples por "Fruit"
                        if obj.Name:lower():find("fruit") and (obj:IsA("Tool") or obj:IsA("Model")) then
                             if not obj:FindFirstChild("Humanoid") and not obj.Name:lower():find("gacha") then -- Ignora NPCs
                                local handle = obj:FindFirstChild("Handle") or obj:FindFirstChild("Main") or (obj:IsA("BasePart") and obj)
                                if handle then
                                    achou = true
                                    StatusLabel.Text = "Indo: " .. obj.Name
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = handle.CFrame + Vector3.new(0,2,0)
                                    end
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end)
                if not achou then StatusLabel.Text = "Nenhuma fruta perto." end
                task.wait(2)
            end
        end)
    else
        BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        BtnTP.Text = "Teleportar p/ Frutas"
        StatusLabel.Text = "TP Parado."
    end
end)

-- GACHA
BtnGacha.MouseButton1Click:Connect(function()
    if not CommF then return end
    StatusLabel.Text = "Comprando..."
    local args = {[1] = "Cousin", [2] = "Buy"}
    pcall(function() CommF:InvokeServer(unpack(args)) end)
    
    task.wait(1)
    StatusLabel.Text = "Guardando..." -- Auto store
    local backpack = LocalPlayer.Backpack
    if backpack then
        for _, v in pairs(backpack:GetChildren()) do
            if v:IsA("Tool") and (v.ToolTip == "Blox Fruit" or v.Name:find("Fruit")) then
                pcall(function() CommF:InvokeServer("StoreFruit", v.Name, v) end)
            end
        end
    end
end)

-- STORE
BtnStore.MouseButton1Click:Connect(function()
    if not CommF then return end
    StatusLabel.Text = "Guardando tudo..."
    local backpack = LocalPlayer.Backpack
    if backpack then
        for _, v in pairs(backpack:GetChildren()) do
            if v:IsA("Tool") and (v.ToolTip == "Blox Fruit" or v.Name:find("Fruit")) then
                pcall(function() CommF:InvokeServer("StoreFruit", v.Name, v) end)
            end
        end
    end
end)

Close.MouseButton1Click:Connect(function()
    tpAtivo = false
    ScreenGui:Destroy()
end)