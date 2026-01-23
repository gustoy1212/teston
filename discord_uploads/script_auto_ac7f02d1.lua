--[[
    BLOX FRUITS - NATIVE PANEL V4
    Baseado no estilo visual "SAO Flash Step" (Garantia de funcionamento no Delta).
    
    Funcionalidades:
    1. AUTO FARM (AURA): Puxa mobs e mata.
    2. AUTO BAÚS: Teleporta para todos os baús.
    3. AUTO FRUTAS: Teleporta para frutas no chão.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

getgenv().BloxNative = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmRange = 350,       -- Raio para puxar inimigos
    ChestDelay = 0.5,      -- Tempo entre baús
}

-- Estados
local IsFarming = false
local IsCollectingChests = false
local IsCollectingFruits = false

-- // --- GUI SETUP (CÓPIA FIEL DO SEU EXEMPLO) --- //

-- Remove interface antiga se existir
if CoreGui:FindFirstChild("BloxNativeUI") then CoreGui.BloxNativeUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
-- Tenta gethui (padrão moderno), senão CoreGui direto
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "BloxNativeUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 240) -- Aumentei a altura para caber os botões
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30) -- Azul Escuro (Tema Blox)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏴‍☠️ BLOX NATIVE V4"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.15, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // BOTÕES DE FUNÇÃO //

-- 1. Botão Farm
local FarmBtn = Instance.new("TextButton", MainFrame)
FarmBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
FarmBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
FarmBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
FarmBtn.Text = "LIGAR AUTO FARM (AURA)"
FarmBtn.TextColor3 = Color3.WHITE
FarmBtn.Font = Enum.Font.GothamBold

-- 2. Botão Baús
local ChestBtn = Instance.new("TextButton", MainFrame)
ChestBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
ChestBtn.Position = UDim2.new(0.05, 0, 0.52, 0) -- Abaixo do Farm
ChestBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
ChestBtn.Text = "LIGAR COLETOR DE BAÚS"
ChestBtn.TextColor3 = Color3.WHITE
ChestBtn.Font = Enum.Font.GothamBold

-- 3. Botão Frutas
local FruitBtn = Instance.new("TextButton", MainFrame)
FruitBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
FruitBtn.Position = UDim2.new(0.05, 0, 0.74, 0) -- Abaixo dos Baús
FruitBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
FruitBtn.Text = "LIGAR COLETOR DE FRUTAS"
FruitBtn.TextColor3 = Color3.WHITE
FruitBtn.Font = Enum.Font.GothamBold

-- // LÓGICA DE INTERFACE (IGUAL AO SEU SCRIPT) //

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BloxNative = false
    ScreenGui:Destroy()
end)

-- Lógica Farm Btn
FarmBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        FarmBtn.Text = "PARAR FARM"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "⚔️ MATANDO MOBS..."
    else
        FarmBtn.Text = "LIGAR AUTO FARM (AURA)"
        FarmBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
        Status.Text = "Status: Parado"
    end
end)

-- Lógica Baú Btn
ChestBtn.MouseButton1Click:Connect(function()
    IsCollectingChests = not IsCollectingChests
    if IsCollectingChests then
        ChestBtn.Text = "PARAR BAÚS"
        ChestBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "💰 PEGANDO BAÚS..."
    else
        ChestBtn.Text = "LIGAR COLETOR DE BAÚS"
        ChestBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
        Status.Text = "Status: Parado"
    end
end)

-- Lógica Fruta Btn
FruitBtn.MouseButton1Click:Connect(function()
    IsCollectingFruits = not IsCollectingFruits
    if IsCollectingFruits then
        FruitBtn.Text = "PARAR FRUTAS"
        FruitBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "🍒 PROCURANDO FRUTAS..."
    else
        FruitBtn.Text = "LIGAR COLETOR DE FRUTAS"
        FruitBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
        Status.Text = "Status: Parado"
    end
end)


-- // --- FUNÇÕES DO JOGO --- //

-- Ataque (Simulação de Toque)
local function AttackClick()
    VirtualInputManager:SendTouchEvent(999, 0, 400, 400, 0, false, game, 1)
    task.wait()
    VirtualInputManager:SendTouchEvent(999, 1, 400, 400, 0, false, game, 1)
end

-- LOOP PRINCIPAL (GERENCIA TUDO)
task.spawn(function()
    while getgenv().BloxNative do
        task.wait() -- Loop rapidinho
        
        -- 1. AUTO FARM
        if IsFarming and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local MyRoot = LocalPlayer.Character.HumanoidRootPart
            local enemies = Workspace:FindFirstChild("Enemies")
            
            if enemies then
                for _, mob in pairs(enemies:GetChildren()) do
                    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                        local mobRoot = mob.HumanoidRootPart
                        local dist = (MyRoot.Position - mobRoot.Position).Magnitude
                        
                        if dist < SETTINGS.FarmRange then
                            -- Puxa
                            mobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -5)
                            -- Trava e Hitbox
                            mobRoot.Size = Vector3.new(8, 8, 8)
                            mobRoot.CanCollide = false
                            mobRoot.Transparency = 0.5
                            mob.Humanoid.WalkSpeed = 0
                            mob.Humanoid.PlatformStand = true
                            -- Bate
                            AttackClick()
                        end
                    end
                end
            end
        end

        -- 2. AUTO BAÚS (COLETOR)
        if IsCollectingChests then
            task.wait(0.2) -- Delay pra não travar
            local chestFound = false
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Busca padrão de baús no Blox Fruits
                if obj.Name:find("Chest") and (obj:FindFirstChild("TouchInterest") or obj.Parent:FindFirstChild("TouchInterest")) then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = obj.CFrame
                        chestFound = true
                        task.wait(SETTINGS.ChestDelay)
                        if not IsCollectingChests then break end -- Para se desligar
                    end
                end
            end
            if not chestFound and IsCollectingChests then Status.Text = "❌ SEM BAÚS NO MAPA" end
        end

        -- 3. AUTO FRUTAS
        if IsCollectingFruits then
            task.wait(0.5)
            for _, tool in pairs(Workspace:GetChildren()) do -- Frutas costumam ficar soltas no Workspace
                if tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Blox Fruit") then
                    if tool:FindFirstChild("Handle") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = tool.Handle.CFrame
                        Status.Text = "🍎 FRUTA ENCONTRADA!"
                        task.wait(1)
                    end
                end
            end
        end
    end
end)