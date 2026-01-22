-- [[ SOLO LEVELING: GOD MODE V4 (MULTI-HIT) ]] --
-- Magneto + Auto Attack + Multiplicador de Hits + Auto Quest

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP (Dark Theme Otimizado)
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 320) -- Maior para caber as opções
Frame.Position = UDim2.new(0.5, -150, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(120, 0, 255) -- Roxo Solo Leveling
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "☠️ GOD MODE V4"
Title.Size = UDim2.new(1, 0, 0.15, 0)
Title.TextColor3 = Color3.fromRGB(180, 100, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.BackgroundTransparency = 1

-- CONFIGURAÇÃO
local EnemyFolder = Workspace:WaitForChild("Enemys")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRemote = Remotes:FindFirstChild("PlayerClickAttack") -- [Source: 114]

local MagnetEnabled = false
local AttackEnabled = false
local Multiplier = 1 -- Padrão 1x

-- [[ 1. IMÃ DE MOBS (O QUE JÁ FUNCIONA) ]] --
local function StartMagnet()
    spawn(function()
        while MagnetEnabled do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.CFrame
                
                if EnemyFolder then
                    for _, enemy in pairs(EnemyFolder:GetChildren()) do
                        local root = enemy:FindFirstChild("HumanoidRootPart")
                        local hum = enemy:FindFirstChild("Humanoid")
                        
                        if root and hum and hum.Health > 0 then
                            -- Hitbox Limpa
                            root.Size = Vector3.new(40, 40, 40) 
                            root.Transparency = 0.8
                            root.CanCollide = false
                            root.Color = Color3.fromRGB(255, 0, 0)
                            
                            -- Puxa para frente do player (Trava a posição)
                            root.CFrame = myPos * CFrame.new(0, 0, -5)
                            root.Velocity = Vector3.new(0,0,0)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- [[ 2. AUTO ATTACK COM MULTI-HIT (NOVO) ]] --
local function StartAutoAttack()
    spawn(function()
        while AttackEnabled do
            -- A mágica do "Aumento de Dano" acontece aqui
            -- Repete o ataque X vezes baseado no Slider
            for i = 1, Multiplier do
                if not AttackEnabled then break end -- Para se desligar
                
                -- Dispara o Remote (Método Silencioso)
                if AttackRemote then
                    pcall(function()
                        AttackRemote:FireServer() 
                        -- Alguns jogos pedem posição, enviamos fake só pra garantir
                        AttackRemote:FireServer(LocalPlayer:GetMouse().Hit.Position)
                    end)
                end
            end
            
            -- Simula clique visual (apenas 1 vez para não travar o celular)
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            end)
            
            task.wait(0.15) -- Velocidade do ataque
        end
    end)
end

-- [[ 3. AUTO QUEST & RECURSOS (BASEADO NAS LOGS) ]] --
local function ClaimRewards()
    local RewardRemotes = {
        Remotes:FindFirstChild("ClaimDailyTaskReward"), -- [Source: 157]
        Remotes:FindFirstChild("ClaimVipReward"),       -- [Source: 102]
        Remotes:FindFirstChild("ClaimSevenLoginReward"),-- [Source: 112]
        Remotes:FindFirstChild("FinishTask")            -- [Source: 128]
    }
    
    local count = 0
    for _, remote in pairs(RewardRemotes) do
        if remote then
            -- Tenta pegar recompensas genericas
            pcall(function() remote:FireServer() end)
            -- Tenta burlar IDs de tarefas (1 a 20)
            for i = 1, 10 do 
                pcall(function() remote:FireServer(i) end)
            end
            count = count + 1
        end
    end
    return count
end

-- [[ INTERFACE E BOTÕES ]] --

-- Botão Magneto
local BtnMagnet = Instance.new("TextButton", Frame)
BtnMagnet.Size = UDim2.new(0.9, 0, 0.2, 0)
BtnMagnet.Position = UDim2.new(0.05, 0, 0.15, 0)
BtnMagnet.Text = "🧲 ATIVAR IMÃ (TRAZER MOBS)"
BtnMagnet.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnMagnet.TextColor3 = Color3.new(1,1,1)
BtnMagnet.Font = Enum.Font.GothamBold

BtnMagnet.MouseButton1Click:Connect(function()
    MagnetEnabled = not MagnetEnabled
    if MagnetEnabled then
        BtnMagnet.Text = "🧲 IMÃ LIGADO"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
        StartMagnet()
    else
        BtnMagnet.Text = "🧲 ATIVAR IMÃ (TRAZER MOBS)"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

-- Botão Auto Attack
local BtnAttack = Instance.new("TextButton", Frame)
BtnAttack.Size = UDim2.new(0.9, 0, 0.2, 0)
BtnAttack.Position = UDim2.new(0.05, 0, 0.4, 0)
BtnAttack.Text = "⚔️ AUTO ATTACK (MULTI-HIT)"
BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnAttack.TextColor3 = Color3.new(1,1,1)
BtnAttack.Font = Enum.Font.GothamBold

BtnAttack.MouseButton1Click:Connect(function()
    AttackEnabled = not AttackEnabled
    if AttackEnabled then
        BtnAttack.Text = "⚔️ BATENDO (x" .. Multiplier .. ")"
        BtnAttack.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StartAutoAttack()
    else
        BtnAttack.Text = "⚔️ AUTO ATTACK (MULTI-HIT)"
        BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

-- Slider de Dano (Fake)
local LabelMult = Instance.new("TextLabel", Frame)
LabelMult.Text = "MULTIPLICADOR DE HITS: 1x"
LabelMult.Size = UDim2.new(0.9, 0, 0.1, 0)
LabelMult.Position = UDim2.new(0.05, 0, 0.62, 0)
LabelMult.TextColor3 = Color3.fromRGB(255, 200, 0)
LabelMult.BackgroundTransparency = 1

local BtnMult = Instance.new("TextButton", Frame)
BtnMult.Size = UDim2.new(0.9, 0, 0.1, 0)
BtnMult.Position = UDim2.new(0.05, 0, 0.72, 0)
BtnMult.Text = "AUMENTAR DANO (+)"
BtnMult.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
BtnMult.TextColor3 = Color3.new(1,1,1)

BtnMult.MouseButton1Click:Connect(function()
    Multiplier = Multiplier + 1
    if Multiplier > 10 then Multiplier = 1 end -- Reseta se passar de 10
    LabelMult.Text = "MULTIPLICADOR DE HITS: " .. Multiplier .. "x"
    if AttackEnabled then BtnAttack.Text = "⚔️ BATENDO (x" .. Multiplier .. ")" end
end)

-- Botão de Recursos
local BtnQuest = Instance.new("TextButton", Frame)
BtnQuest.Size = UDim2.new(0.9, 0, 0.12, 0)
BtnQuest.Position = UDim2.new(0.05, 0, 0.85, 0)
BtnQuest.Text = "💰 PEGAR RECOMPENSAS DIÁRIAS"
BtnQuest.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
BtnQuest.TextColor3 = Color3.new(1,1,1)
BtnQuest.Font = Enum.Font.GothamBold

BtnQuest.MouseButton1Click:Connect(function()
    BtnQuest.Text = "COLETANDO..."
    ClaimRewards()
    task.wait(1)
    BtnQuest.Text = "💰 PEGAR RECOMPENSAS DIÁRIAS"
end)