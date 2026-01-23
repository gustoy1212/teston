--[[
    BLOX FRUITS - MULTI-TOOL V3 (DELTA MOBILE)
    
    [X] Auto Farm: Puxa mobs e mata (Aura).
    [X] Auto Baús: Teleporta e pega TODOS os baús do servidor.
    [X] Auto Frutas: Procura frutas no chão e teleporta para pegar.
    
    Interface: Painel com Caixinhas (Checkboxes) para ligar/desligar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

getgenv().BloxMulti = true

-- // CONFIGURAÇÕES GLOBAIS //
local Flags = {
    AutoFarm = false,
    AutoChests = false,
    AutoFruits = false
}

local SETTINGS = {
    FarmRange = 400,        -- Distância para puxar inimigos
    CollectDelay = 0.5,     -- Tempo entre pegar um baú e outro (evita kick)
}

-- // LIMPEZA DE UI ANTIGA //
if CoreGui:FindFirstChild("BloxMultiUI") then CoreGui.BloxMultiUI:Destroy() end

-- // CRIANDO A GUI (ESTILO CAIXINHA) //
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "BloxMultiUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 230) -- Mais alto para caber as opções
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0) -- Esquerda
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Verde Tech
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🥝 BLOX MULTI V3"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1
Title.TextSize = 18

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO CRIADORA DE CAIXINHAS (CHECKBOX) //
local function CreateCheckbox(text, flagName, yPos)
    local CheckBox = Instance.new("TextButton", MainFrame)
    CheckBox.Size = UDim2.new(0.9, 0, 0, 35)
    CheckBox.Position = UDim2.new(0.05, 0, 0, yPos)
    CheckBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    CheckBox.Text = "" -- Texto vazio, usamos Labels dentro
    CheckBox.AutoButtonColor = false

    local Box = Instance.new("Frame", CheckBox)
    Box.Size = UDim2.new(0, 20, 0, 20)
    Box.Position = UDim2.new(0, 10, 0.5, -10)
    Box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Box.BorderColor3 = Color3.fromRGB(100, 100, 100)
    
    local CheckMark = Instance.new("Frame", Box) -- O "Verde" de ligado
    CheckMark.Size = UDim2.new(1, -4, 1, -4)
    CheckMark.Position = UDim2.new(0, 2, 0, 2)
    CheckMark.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    CheckMark.Visible = false -- Começa desligado
    
    local Label = Instance.new("TextLabel", CheckBox)
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 40, 0, 0)
    Label.Text = text
    Label.TextColor3 = Color3.WHITE
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    
    -- Lógica de Clique
    CheckBox.Activated:Connect(function()
        Flags[flagName] = not Flags[flagName]
        CheckMark.Visible = Flags[flagName]
        
        if Flags[flagName] then
            Label.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            Label.TextColor3 = Color3.WHITE
        end
    end)
end

-- CRIANDO AS OPÇÕES
CreateCheckbox("Auto Farm (Aura)", "AutoFarm", 45)
CreateCheckbox("Coletar Baús (TP)", "AutoChests", 90)
CreateCheckbox("Coletar Frutas (TP)", "AutoFruits", 135)

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.8, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.SourceSansItalic

-- Lógica Fechar
CloseBtn.Activated:Connect(function()
    getgenv().BloxMulti = false
    ScreenGui:Destroy()
end)

-- // --- FUNÇÕES DO SCRIPT --- //

-- 1. FUNÇÃO ATAQUE
local function AttackClick()
    VirtualInputManager:SendTouchEvent(999, 0, 400, 400, 0, false, game, 1)
    task.wait()
    VirtualInputManager:SendTouchEvent(999, 1, 400, 400, 0, false, game, 1)
end

-- 2. AUTO FARM (AURA)
task.spawn(function()
    while getgenv().BloxMulti do
        task.wait()
        if Flags.AutoFarm then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
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
                                -- Trava
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
        end
    end
end)

-- 3. COLETOR DE BAÚS (Teleporte)
task.spawn(function()
    while getgenv().BloxMulti do
        task.wait(0.5) -- Delay para não travar
        if Flags.AutoChests then
            Status.Text = "🔍 Procurando Baús..."
            local foundChest = false
            
            -- Blox Fruits geralmente coloca baús soltos no Workspace ou pastas
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Verifica se é um baú válido (nome contém Chest e tem TouchInterest)
                if obj.Name:find("Chest") and (obj:FindFirstChild("TouchInterest") or obj.Parent:FindFirstChild("TouchInterest")) then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        -- Teleporta para o baú
                        LocalPlayer.Character.HumanoidRootPart.CFrame = obj.CFrame
                        foundChest = true
                        Status.Text = "💰 Pegando Baú!"
                        task.wait(SETTINGS.CollectDelay) -- Espera pegar
                        
                        -- Se o usuário desligar no meio, para
                        if not Flags.AutoChests then break end
                    end
                end
            end
            
            if not foundChest then Status.Text = "❌ Sem Baús Perto" end
        end
    end
end)

-- 4. COLETOR DE FRUTAS (Teleporte)
task.spawn(function()
    while getgenv().BloxMulti do
        task.wait(1)
        if Flags.AutoFruits then
            Status.Text = "🍒 Procurando Frutas..."
            
            -- Procura Handles de ferramentas que sejam Frutas
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                    -- Verifica se é uma fruta (Geralmente tem "Fruit" no nome ou tooltip)
                    if obj.Name:find("Fruit") or (obj.ToolTip and obj.ToolTip:find("Fruit")) then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            
                            -- Teleporta para a fruta
                            LocalPlayer.Character.HumanoidRootPart.CFrame = obj.Handle.CFrame
                            Status.Text = "🍎 Fruta Encontrada!"
                            task.wait(0.5)
                            
                            -- No Blox Fruits, fruta no chão precisa tocar ou guardar
                            -- O teleporte geralmente coleta se você passar por cima
                        end
                    end
                end
            end
        end
    end
end)