--[[
    BLOX FRUITS FIX V4 (MODO DIAGNÓSTICO)
    - Procura o CommF_ automaticamente onde quer que ele esteja
    - Não trava se não achar o remote
    - Teleporte independente
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- 1. BUSCADOR DE REMOTE INTELIGENTE
-- ==============================================================================
local CommF = nil

-- Tenta achar o CommF_ de todas as formas possiveis
local function LocalizarRemote()
    print("🔍 Procurando Remote CommF_...")
    
    -- Tentativa 1: Caminho Padrão
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_") then
        CommF = ReplicatedStorage.Remotes.CommF_
        return
    end
    
    -- Tentativa 2: Busca Recursiva (Varre tudo)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "CommF_" and v:IsA("RemoteFunction") then
            CommF = v
            print("✅ Achei o Remote escondido em: " .. v:GetFullName())
            return
        end
    end
end

LocalizarRemote() -- Roda a busca

-- ==============================================================================
-- 2. INTERFACE (GUI)
-- ==============================================================================
if game.CoreGui:FindFirstChild("BloxToolkitFix") then game.CoreGui.BloxToolkitFix:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxToolkitFix"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 280)
MainFrame.Active = true
MainFrame.Draggable = true -- Tenta arrastar pra ver se nao ta travado

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Blox Fix V4"
Title.TextColor3 = Color3.white
Title.TextSize = 20

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12

if CommF then
    StatusLabel.Text = "Status: Conectado (Remote OK)"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
else
    StatusLabel.Text = "ERRO: Remote não encontrado!"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
end

-- ==============================================================================
-- 3. BOTÕES E FUNÇÕES
-- ==============================================================================

-- [TELEPORTE] (Não depende de Remote)
local BtnTP = Instance.new("TextButton")
BtnTP.Parent = MainFrame
BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnTP.Position = UDim2.new(0.1, 0, 0.15, 0)
BtnTP.Size = UDim2.new(0.8, 0, 0, 40)
BtnTP.Font = Enum.Font.SourceSans
BtnTP.Text = "Teleportar p/ Frutas"
BtnTP.TextColor3 = Color3.white
BtnTP.TextSize = 18

local tpAtivo = false
BtnTP.MouseButton1Click:Connect(function()
    print("Botão TP Clicado!") -- Debug no Console (F9)
    tpAtivo = not tpAtivo
    
    if tpAtivo then
        BtnTP.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        BtnTP.Text = "Buscando..."
        
        spawn(function()
            while tpAtivo do
                local achou = false
                
                -- Busca Genérica (Pega qualquer ferramenta ou modelo com 'Fruit' no nome)
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if not tpAtivo then break end
                    
                    -- Filtro de Nome Simples
                    if obj.Name:lower():find("fruit") and (obj:IsA("Tool") or obj:IsA("Model")) then
                        -- Evita pegar NPCs ou Lojas
                        if not obj:FindFirstChild("Humanoid") and not obj.Name:lower():find("gacha") then
                            
                            local handle = obj:FindFirstChild("Handle") or obj:FindFirstChild("Main") or (obj:IsA("BasePart") and obj)
                            
                            if handle then
                                achou = true
                                StatusLabel.Text = "Indo até: " .. obj.Name
                                
                                -- TP Simples (Sem Tween pra testar se funciona)
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = handle.CFrame + Vector3.new(0, 2, 0)
                                end
                                task.wait(1) -- Espera 1s na fruta
                            end
                        end
                    end
                end
                
                if not achou then StatusLabel.Text = "Nenhuma fruta no chão." end
                task.wait(2)
            end
        end)
    else
        BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        BtnTP.Text = "Teleportar p/ Frutas"
        StatusLabel.Text = "TP Parado."
    end
end)

-- [GACHA / RANDOM FRUIT]
local BtnGacha = Instance.new("TextButton")
BtnGacha.Parent = MainFrame
BtnGacha.Position = UDim2.new(0.1, 0, 0.35, 0)
BtnGacha.Size = UDim2.new(0.8, 0, 0, 40)
BtnGacha.Font = Enum.Font.SourceSansBold
BtnGacha.TextSize = 18

if CommF then
    BtnGacha.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    BtnGacha.Text = "Girar Fruta (Random)"
else
    BtnGacha.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    BtnGacha.Text = "Gacha (OFF - Sem Remote)"
end

BtnGacha.MouseButton1Click:Connect(function()
    if not CommF then 
        StatusLabel.Text = "Erro: Jogo incompatível?" 
        return 
    end
    
    StatusLabel.Text = "Comprando..."
    local args = {[1] = "Cousin", [2] = "Buy"}
    pcall(function() CommF:InvokeServer(unpack(args)) end)
    
    -- Tenta guardar logo em seguida
    task.wait(1)
    StatusLabel.Text = "Tentando guardar..."
    
    -- Auto Store Integrado no botão
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    local items = {}
    if backpack then for _, v in pairs(backpack:GetChildren()) do table.insert(items, v) end end
    if char then for _, v in pairs(char:GetChildren()) do table.insert(items, v) end end

    for _, v in pairs(items) do
        if v:IsA("Tool") and (v.ToolTip == "Blox Fruit" or v.Name:find("Fruit")) then
            pcall(function() CommF:InvokeServer("StoreFruit", v.Name, v) end)
        end
    end
end)

-- [STORE ALL]
local BtnStore = Instance.new("TextButton")
BtnStore.Parent = MainFrame
BtnStore.Position = UDim2.new(0.1, 0, 0.55, 0)
BtnStore.Size = UDim2.new(0.8, 0, 0, 40)
BtnStore.Font = Enum.Font.SourceSansBold
BtnStore.TextSize = 18

if CommF then
    BtnStore.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    BtnStore.Text = "Guardar Frutas"
else
    BtnStore.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    BtnStore.Text = "Store (OFF - Sem Remote)"
end

BtnStore.MouseButton1Click:Connect(function()
    if not CommF then return end
    StatusLabel.Text = "Guardando tudo..."
    
    local backpack = LocalPlayer.Backpack
    local items = backpack:GetChildren()
    for _, v in pairs(items) do
        if v:IsA("Tool") and (v.ToolTip == "Blox Fruit" or v.Name:find("Fruit")) then
            pcall(function() CommF:InvokeServer("StoreFruit", v.Name, v) end)
        end
    end
end)

-- Fechar
local Close = Instance.new("TextButton")
Close.Parent = MainFrame
Close.BackgroundColor3 = Color3.fromRGB(200,0,0)
Close.Position = UDim2.new(0.85, 0, 0, 0)
Close.Size = UDim2.new(0.15,0,0,30)
Close.Text = "X"
Close.TextColor3 = Color3.white

Close.MouseButton1Click:Connect(function()
    tpAtivo = false
    ScreenGui:Destroy()
end)