--[[
    BLOX FRUITS TOOLKIT V3 (COMPLETO)
    - Auto Gacha (Giro)
    - Auto Store (Guardar)
    - Fruit Finder (Teleporte)
    
    Baseado na Log: GOD_LOG_161728.txt (CommF_)
]]

-- 1. SERVIÇOS & VARIÁVEIS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Tenta achar o Remote do Blox Fruits (Baseado na sua log)
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- 2. CRIAÇÃO DA INTERFACE (GUI)
if game.CoreGui:FindFirstChild("BloxToolkit") then game.CoreGui.BloxToolkit:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloxToolkit"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0) -- Centralizado
MainFrame.Size = UDim2.new(0, 250, 0, 250) -- Aumentei pra caber os botões novos
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Blox Fruits Toolkit V3"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.Text = "Aguardando comando..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14

-- 3. BOTÕES

-- Botão TP Frutas
local BtnTP = Instance.new("TextButton")
BtnTP.Parent = MainFrame
BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnTP.Position = UDim2.new(0.1, 0, 0.15, 0)
BtnTP.Size = UDim2.new(0.8, 0, 0, 40)
BtnTP.Font = Enum.Font.SourceSans
BtnTP.Text = "[ ] Teleportar p/ Frutas"
BtnTP.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnTP.TextSize = 18

-- Botão Gacha (Giro)
local BtnGacha = Instance.new("TextButton")
BtnGacha.Parent = MainFrame
BtnGacha.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Roxo
BtnGacha.Position = UDim2.new(0.1, 0, 0.35, 0)
BtnGacha.Size = UDim2.new(0.8, 0, 0, 40)
BtnGacha.Font = Enum.Font.SourceSansBold
BtnGacha.Text = "🎲 Girar Fruta (Random)"
BtnGacha.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnGacha.TextSize = 18

-- Botão Store (Guardar)
local BtnStore = Instance.new("TextButton")
BtnStore.Parent = MainFrame
BtnStore.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Verde
BtnStore.Position = UDim2.new(0.1, 0, 0.55, 0)
BtnStore.Size = UDim2.new(0.8, 0, 0, 40)
BtnStore.Font = Enum.Font.SourceSansBold
BtnStore.Text = "📦 Guardar Frutas (Inv)"
BtnStore.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnStore.TextSize = 18

-- Botão Fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Position = UDim2.new(0.85, 0, 0, 0)
CloseBtn.Size = UDim2.new(0.15, 0, 0, 30)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.white

-- 4. FUNÇÕES LÓGICAS

-- Função Auxiliar: Verifica se é fruta de verdade
function IsFruit(obj)
    -- No Blox Fruits, frutas spawnam soltas ou dentro de pastas
    if not obj then return false end
    local nome = obj.Name:lower()
    
    -- Filtro básico pelo nome "Fruit"
    if nome:find("fruit") then
        -- Filtra coisas que NÃO são frutas (Vendedores, NPCs)
        if nome:find("dealer") or nome:find("gacha") or nome:find("npc") or obj:FindFirstChild("Humanoid") then
            return false
        end
        return true
    end
    return false
end

-- [FUNÇÃO 1] AUTO STORE (Guardar no Inventário)
function StoreAllFruits()
    local storedCount = 0
    StatusLabel.Text = "Verificando mochila..."
    
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    
    local items = {}
    if backpack then for _, v in pairs(backpack:GetChildren()) do table.insert(items, v) end end
    if char then for _, v in pairs(char:GetChildren()) do table.insert(items, v) end end

    for _, tool in pairs(items) do
        -- No Blox Fruits, frutas são Tools.
        -- O argumento para guardar é: "StoreFruit", "NomeDaFruta", Objeto
        if tool:IsA("Tool") and (tool.ToolTip == "Blox Fruit" or tool.Name:find("Fruit")) then
            local args = {
                [1] = "StoreFruit",
                [2] = tool.Name, -- No Blox Fruits as vezes precisa tratar o nome, mas o padrão costuma funcionar
                [3] = tool
            }
            
            pcall(function()
                CommF:InvokeServer(unpack(args))
                storedCount = storedCount + 1
            end)
        end
    end
    
    if storedCount > 0 then
        StatusLabel.Text = "Guardou " .. storedCount .. " frutas!"
    else
        StatusLabel.Text = "Nenhuma fruta para guardar."
    end
end

-- [FUNÇÃO 2] AUTO GACHA (Comprar Fruta)
function BuyGacha()
    StatusLabel.Text = "Girando fruta..."
    
    -- Argumentos achados na Log para o NPC Cousin (Gacha)
    local args = {
        [1] = "Cousin",
        [2] = "Buy"
    }
    
    -- InvokeServer retorna o resultado da compra
    local success, result = pcall(function()
        return CommF:InvokeServer(unpack(args))
    end)
    
    if success then
        StatusLabel.Text = "Comprou! Tentando guardar..."
        task.wait(1)
        StoreAllFruits() -- Já tenta guardar automaticamente pra não perder
    else
        StatusLabel.Text = "Falha (Sem dinheiro ou Cooldown?)"
    end
end

-- [FUNÇÃO 3] TELEPORTE PARA FRUTAS
local tpActive = false
function ToggleTP()
    tpActive = not tpActive
    
    if tpActive then
        BtnTP.Text = "[X] Buscando Frutas..."
        BtnTP.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        
        spawn(function()
            while tpActive do
                local found = false
                
                -- Procura em todo o Workspace
                for _, v in pairs(Workspace:GetDescendants()) do
                    if not tpActive then break end
                    
                    if IsFruit(v) and v:IsA("BasePart") or (v:IsA("Model") and v:FindFirstChild("Handle")) then
                        local handle = v:IsA("BasePart") and v or v:FindFirstChild("Handle")
                        
                        if handle then
                            found = true
                            StatusLabel.Text = "Indo até: " .. v.Name
                            
                            -- Teleporta usando Tween (Mais suave)
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local hrp = LocalPlayer.Character.HumanoidRootPart
                                local dist = (hrp.Position - handle.Position).Magnitude
                                
                                -- Se tiver muito longe, tp direto (bypass simples)
                                if dist > 1000 then
                                    hrp.CFrame = handle.CFrame + Vector3.new(0, 5, 0)
                                else
                                    local info = TweenInfo.new(dist / 300, Enum.EasingStyle.Linear)
                                    local tween = TweenService:Create(hrp, info, {CFrame = handle.CFrame})
                                    tween:Play()
                                    tween.Completed:Wait()
                                end
                                
                                -- Espera um pouco pra pegar
                                task.wait(0.5)
                            end
                        end
                    end
                end
                
                if not found then StatusLabel.Text = "Nenhuma fruta no chão." end
                task.wait(2)
            end
        end)
    else
        BtnTP.Text = "[ ] Teleportar p/ Frutas"
        BtnTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLabel.Text = "TP Parado."
    end
end

-- 5. CONECTANDO TUDO
BtnGacha.MouseButton1Click:Connect(BuyGacha)
BtnStore.MouseButton1Click:Connect(StoreAllFruits)
BtnTP.MouseButton1Click:Connect(ToggleTP)

CloseBtn.MouseButton1Click:Connect(function()
    tpActive = false
    ScreenGui:Destroy()
end)