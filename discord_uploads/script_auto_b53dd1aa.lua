-- Configurações Iniciais
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ButtonSuck = Instance.new("TextButton")
local ButtonTP = Instance.new("TextButton")
local ButtonIsland = Instance.new("TextButton") -- NOVO BOTÃO
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "FruitCollectorV2_5"
ScreenGui.Parent = game.CoreGui

-- Estilo (Levemente aumentado para caber o novo botão)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 230) -- Aumentei altura
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Coletor V2.5 (Com Ilhas)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20

-- Botão Sugar
ButtonSuck.Name = "BtnSuck"
ButtonSuck.Parent = MainFrame
ButtonSuck.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonSuck.Position = UDim2.new(0.1, 0, 0.20, 0)
ButtonSuck.Size = UDim2.new(0.8, 0, 0, 35)
ButtonSuck.Font = Enum.Font.SourceSans
ButtonSuck.Text = "[ ] Sugar Frutas"
ButtonSuck.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonSuck.TextSize = 18

-- Botão TP Fruta
ButtonTP.Name = "BtnTP"
ButtonTP.Parent = MainFrame
ButtonTP.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ButtonTP.Position = UDim2.new(0.1, 0, 0.40, 0)
ButtonTP.Size = UDim2.new(0.8, 0, 0, 35)
ButtonTP.Font = Enum.Font.SourceSans
ButtonTP.Text = "[ ] TP p/ Fruta (Detectada)"
ButtonTP.TextColor3 = Color3.fromRGB(255, 255, 255)
ButtonTP.TextSize = 18

-- Botão TP Ilha (NOVO)
ButtonIsland.Name = "BtnIsland"
ButtonIsland.Parent = MainFrame
ButtonIsland.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Cor Laranja
ButtonIsland.Position = UDim2.new(0.1, 0, 0.60, 0)
ButtonIsland.Size = UDim2.new(0.8, 0, 0, 35)
ButtonIsland.Font = Enum.Font.SourceSansBold
ButtonIsland.Text = ">>> Próxima Ilha >>>"
ButtonIsland.TextColor3 = Color3.fromRGB(0, 0, 0)
ButtonIsland.TextSize = 18

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSansItalic
StatusLabel.Text = "Parado"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14

-------------------------------------------------------------------------
-- LÓGICA DE ILHAS (SIMPLES E MANUAL)
-------------------------------------------------------------------------
local islandList = {}
local currentIslandIndex = 1

function ScanIslands()
    islandList = {}
    StatusLabel.Text = "Mapeando ilhas..."
    
    -- Tenta pegar SpawnLocations (Pontos de Respawn)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(islandList, obj.CFrame + Vector3.new(0, 10, 0))
        end
    end
    
    -- Se achar poucos spawns, usa NPCs como referência (toda ilha tem NPC)
    if #islandList < 3 and Workspace:FindFirstChild("NPCs") then
        for _, npc in pairs(Workspace.NPCs:GetChildren()) do
            if npc:FindFirstChild("HumanoidRootPart") then
                local isFar = true
                -- Verifica se já temos um ponto perto desse NPC (para não marcar a mesma ilha 2x)
                for _, pos in pairs(islandList) do
                    if (pos.Position - npc.HumanoidRootPart.Position).Magnitude < 500 then
                        isFar = false
                        break
                    end
                end
                
                if isFar then
                    table.insert(islandList, npc.HumanoidRootPart.CFrame + Vector3.new(0, 20, 0))
                end
            end
        end
    end
    
    StatusLabel.Text = "Ilhas encontradas: " .. #islandList
    task.wait(1)
end

-- Roda o scan uma vez ao iniciar
spawn(ScanIslands)

ButtonIsland.MouseButton1Click:Connect(function()
    if #islandList == 0 then ScanIslands() end
    if #islandList == 0 then StatusLabel.Text = "Nenhuma ilha achada!" return end
    
    currentIslandIndex = currentIslandIndex + 1
    if currentIslandIndex > #islandList then currentIslandIndex = 1 end
    
    local targetCFrame = islandList[currentIslandIndex]
    StatusLabel.Text = "Viajando p/ Ilha " .. currentIslandIndex
    
    -- TP Suave (para evitar kick)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    if dist > 3000 then
        -- Se for muito longe, TP direto (Bypass)
        hrp.CFrame = targetCFrame
    else
        -- Voo rápido
        local tween = TweenService:Create(hrp, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
    end
end)

-------------------------------------------------------------------------
-- LÓGICA DE FRUTAS (A MESMA DO V2)
-------------------------------------------------------------------------

local suckEnabled = false
local tpEnabled = false

function IsRealFruit(object)
    if not object or not object.Parent then return nil end
    local name = object.Name:lower()
    
    if name:find("dealer") or name:find("gacha") or name:find("bloxfruit gacha") or name:find("quest") or name:find("manager") then return nil end
    if object:FindFirstChildOfClass("Humanoid") then return nil end

    if (name:find("fruit") or name:find("fruta")) then
        if object:IsA("Tool") or object:IsA("Model") then
            if object.Parent:FindFirstChildOfClass("Humanoid") then return nil end
            return object:FindFirstChild("Handle") or object.PrimaryPart
        end
    end
    return nil
end

function SuckFruits()
    spawn(function()
        while suckEnabled do
            local foundSomething = false
            for _, item in pairs(Workspace:GetChildren()) do
                local handle = IsRealFruit(item)
                if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    foundSomething = true
                    StatusLabel.Text = "Puxando: " .. item.Name
                    if handle:IsA("BasePart") then
                        handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 0)
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, handle, 1)
                    end
                end
            end
            if not foundSomething then
                for _, item in pairs(Workspace:GetDescendants()) do
                     local handle = IsRealFruit(item)
                     if handle and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        foundSomething = true
                        handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                     end
                     if foundSomething then break end
                end
            end
            if not foundSomething then StatusLabel.Text = "Procurando frutas..." end
            task.wait(0.1)
        end
    end)
end

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
                        hrp.CFrame = handle.CFrame
                    else
                        local tweenInfo = TweenInfo.new(distance / 350, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = handle.CFrame})
                        tween:Play()
                        tween.Completed:Wait()
                    end
                    task.wait(0.5)
                end
                if not tpEnabled then break end
            end
            if not foundSomething then StatusLabel.Text = "Nenhuma fruta no mapa." end
            task.wait(1.5)
        end
    end)
end

-- Botões das Frutas
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