-------------------------------------------------------------------------
-- NOVA FUNCIONALIDADE: AUTO GACHA & STORE (VIA REMOTE)
-- Baseado na log GOD_LOG_161728.txt (CommF_)
-------------------------------------------------------------------------

-- Localizando o Remote Principal do Blox Fruits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- GUI: Adicionar Botão de Gacha
local ButtonGacha = Instance.new("TextButton")
ButtonGacha.Name = "BtnGacha"
ButtonGacha.Parent = MainFrame -- Certifique-se que 'MainFrame' é visível aqui
ButtonGacha.BackgroundColor3 = Color3.fromRGB(100, 50, 150) -- Roxo
ButtonGacha.Position = UDim2.new(0.1, 0, 0.85, 0) -- Ajuste a posição conforme seu menu
ButtonGacha.Size = UDim2.new(0.8, 0, 0, 30)
ButtonGacha.Font = Enum.Font.SourceSansBold
ButtonGacha.Text = "[💲] Girar Fruta (Random)"
ButtonGacha.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonGacha.TextSize = 16

-- Função para Guardar Frutas (Auto Store)
function AutoStoreFruits()
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    
    -- Procura frutas na mochila e no personagem
    local items = {}
    if backpack then 
        for _, v in pairs(backpack:GetChildren()) do table.insert(items, v) end 
    end
    if char then 
        for _, v in pairs(char:GetChildren()) do table.insert(items, v) end 
    end

    for _, tool in pairs(items) do
        -- No Blox Fruits, as frutas são Tools com "Fruit" no nome
        if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
            -- Envia o sinal pro servidor guardar a fruta
            -- O argumento encontrado na log para guardar é: CommF_:InvokeServer("StoreFruit", "NomeDaFruta", model)
            local args = {
                [1] = "StoreFruit",
                [2] = tool.Name,
                [3] = tool
            }
            pcall(function()
                StatusLabel.Text = "Guardando: " .. tool.Name
                CommF:InvokeServer(unpack(args))
            end)
        end
    end
end

-- Função para Comprar Fruta (Gacha)
function BuyRandomFruit()
    StatusLabel.Text = "Tentando comprar fruta..."
    
    -- Argumentos do CommF_ para comprar fruta (Cousin)
    local args = {
        [1] = "Cousin",
        [2] = "Buy"
    }
    
    local success, result = pcall(function()
        return CommF:InvokeServer(unpack(args))
    end)
    
    if success then
        StatusLabel.Text = "Resultado: " .. tostring(result)
        task.wait(1)
        -- Tenta guardar a fruta que acabou de ganhar
        AutoStoreFruits()
    else
        StatusLabel.Text = "Erro ao comprar (Sem dinheiro?)"
    end
end

-- Conectar o Botão
ButtonGacha.MouseButton1Click:Connect(function()
    BuyRandomFruit()
end)