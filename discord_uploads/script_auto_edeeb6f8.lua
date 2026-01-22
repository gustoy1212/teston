-- [[ GOD MODE & KILL AURA - DELTA MOBILE ]] --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. CONFIGURAÇÃO (Baseada nas suas logs)
local RemoteName = "PlayerClickAttack" -- Nome que pegamos no Log 1
local EnemyFolder = Workspace:WaitForChild("Enemys") -- Pasta que pegamos no Log 1

-- Tenta achar o remote
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild(RemoteName)

-- UI SIMPLES
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 150)
Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🔥 GOD MODE / AURA"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", Frame)
Status.Text = "Status: PARADO"
Status.Position = UDim2.new(0,0,0.3,0)
Status.Size = UDim2.new(1,0,0,20)
Status.TextColor3 = Color3.new(1,1,1)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Size = UDim2.new(0.8, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
ToggleBtn.Text = "ATIVAR AURA"

-- LÓGICA DO KILL AURA
local AuraAtivada = false

local function GetClosestEnemy()
    local closest = nil
    local maxDist = 50 -- Distância máxima para atacar (aumente se quiser)
    
    if not EnemyFolder then return nil end

    for _, enemy in pairs(EnemyFolder:GetChildren()) do
        -- Verifica se o inimigo está vivo
        local hum = enemy:FindFirstChild("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if dist < maxDist then
                closest = enemy
                maxDist = dist
            end
        end
    end
    return closest
end

ToggleBtn.MouseButton1Click:Connect(function()
    AuraAtivada = not AuraAtivada
    if AuraAtivada then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "Status: ⚔️ MATANDO..."
        
        -- LOOP DE ATAQUE (O SEGREDO)
        spawn(function()
            while AuraAtivada do
                local target = GetClosestEnemy()
                if target and AttackRemote then
                    -- Estratégia 1: Manda o alvo normal (Speed Attack)
                    AttackRemote:FireServer(target)
                    
                    -- Estratégia 2: Tenta injetar Dano absurdo (Caso funcione)
                    -- Tenta enviar (Alvo, Dano)
                    AttackRemote:FireServer(target, 999999999) 
                    
                    -- Estratégia 3: Tenta enviar só o Dano (Alguns jogos usam assim)
                    AttackRemote:FireServer(999999999)
                end
                task.wait() -- Velocidade insana (sem delay perceptível)
            end
        end)
    else
        ToggleBtn.Text = "ATIVAR AURA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
        Status.Text = "Status: PARADO"
    end
end)