-- [[ GOD MODE: BRUTE FORCE EDITION ]] --
-- Tenta disparar TODOS os remotes de ataque com TODOS os tipos de dano

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI PARA CONTROLE
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 120)
Frame.Position = UDim2.new(0.5, -125, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "👹 GOD MODE (AUTO)"
Title.Size = UDim2.new(1, 0, 0.3, 0)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ToggleBtn.Text = "ATIVAR AUTO-KILL"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16

-- [[ PREPARAÇÃO DOS REMOTES ]] --
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)

-- Pegamos os dois suspeitos das suas logs
local Remote1 = RemotesFolder and RemotesFolder:FindFirstChild("PlayerClickAttack") -- [Source: 114]
local Remote2 = RemotesFolder and RemotesFolder:FindFirstChild("ClickEnemy") -- [Source: 197]
local Remote3 = RemotesFolder and RemotesFolder:FindFirstChild("PlayerClickAttackSkill") -- [Source: 174]

-- [[ LÓGICA DE ATAQUE ]] --
local Active = false
local EnemyFolder = Workspace:FindFirstChild("Enemys") -- [Source: 13]

local function AttackTarget(targetModel)
    if not targetModel then return end
    
    -- Argumentos para testar (Dano Infinito, Dano Alto, Bug)
    local DmgGod = 9e18 -- Um número gigantesco
    local DmgHigh = 999999999
    
    -- Tenta pegar as partes vitais
    local root = targetModel:FindFirstChild("HumanoidRootPart")
    local hum = targetModel:FindFirstChild("Humanoid")
    
    if not root or not hum or hum.Health <= 0 then return end

    spawn(function()
        -- METRALHADORA DE REMOTES (Tenta acertar de todas as formas)
        
        -- TENTATIVA 1: PlayerClickAttack (O mais comum)
        if Remote1 then
            pcall(function() Remote1:FireServer(targetModel) end) -- Só o modelo
            pcall(function() Remote1:FireServer(targetModel, DmgGod) end) -- Modelo + Dano Infinito
            pcall(function() Remote1:FireServer(DmgGod) end) -- Só Dano
        end
        
        -- TENTATIVA 2: ClickEnemy (Achado na log 197 - Pode ser RemoteFunction)
        if Remote2 then
            if Remote2:IsA("RemoteFunction") then
                pcall(function() Remote2:InvokeServer(targetModel) end)
                pcall(function() Remote2:InvokeServer(targetModel, DmgHigh) end)
            else
                pcall(function() Remote2:FireServer(targetModel) end)
                pcall(function() Remote2:FireServer(targetModel, DmgHigh) end)
            end
        end

        -- TENTATIVA 3: Skill (Se os outros falharem)
        if Remote3 then
            pcall(function() Remote3:FireServer(targetModel, DmgGod) end)
        end
    end)
end

local function GetBestTarget()
    if not EnemyFolder then return nil end
    
    local closest = nil
    local maxDist = 100 -- Raio de alcance
    
    for _, enemy in pairs(EnemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChild("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if dist < maxDist then
                maxDist = dist
                closest = enemy
            end
        end
    end
    return closest
end

-- LOOP PRINCIPAL (RÁPIDO)
spawn(function()
    while true do
        if Active then
            local target = GetBestTarget()
            if target then
                AttackTarget(target)
            end
            task.wait() -- Sem delay para ser Instant Kill (Speed)
        else
            task.wait(0.5)
        end
    end
end)

-- CONTROLE DO BOTÃO
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "MATANDO..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        
        if not EnemyFolder then 
            ToggleBtn.Text = "ERRO: PASTA ENEMYS Ñ ACHADA" 
            warn("Pasta 'Enemys' não encontrada no Workspace!")
        end
    else
        ToggleBtn.Text = "ATIVAR AUTO-KILL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    end
end)