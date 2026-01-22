-- [[ SOLO LEVELING: ALTERNATIVE EXPLOITS ]] --
-- Se o dano não funciona, vamos quebrar o jogo de outras formas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 220)
Frame.Position = UDim2.new(0.5, -150, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 150, 255)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🛠️ TOOLPACK (PATCH-FIX)"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundTransparency = 1

local Container = Instance.new("Frame", Frame)
Container.Size = UDim2.new(1, 0, 0.8, 0)
Container.Position = UDim2.new(0, 0, 0.2, 0)
Container.BackgroundTransparency = 1

local function CreateBtn(text, order, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(0.9, 0, 0.25, 0)
    btn.Position = UDim2.new(0.05, 0, (order-1)*0.3, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- [[ 1. HITBOX EXPANDER (Gigante) ]] --
-- Aumenta o tamanho da área de acerto dos inimigos na pasta "Enemys" [cite: 13]
local HitboxEnabled = false
CreateBtn("1. HITBOX GIGANTE (Enemys)", 1, Color3.fromRGB(200, 100, 0), function()
    HitboxEnabled = not HitboxEnabled
    local EnemyFolder = Workspace:FindFirstChild("Enemys")
    
    if HitboxEnabled and EnemyFolder then
        spawn(function()
            while HitboxEnabled do
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size = Vector3.new(50, 50, 50) -- Tamanho Absurdo
                        root.Transparency = 0.7
                        root.Color = Color3.fromRGB(255, 0, 0)
                        root.CanCollide = false
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

-- [[ 2. TASK & REWARD SPAM (Gemas Infinitas?) ]] --
-- Tenta disparar eventos de completar tarefa e pegar recompensa [cite: 128, 102, 111]
local SpamRewards = false
CreateBtn("2. SPAM DE RECOMPENSAS (Teste)", 2, Color3.fromRGB(0, 150, 50), function()
    SpamRewards = not SpamRewards
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Lista de eventos achados nas suas logs
    local RewardEvents = {
        Remotes:FindFirstChild("FinishTask"),           -- [Source: 128]
        Remotes:FindFirstChild("ClaimDailyTaskReward"), 
        Remotes:FindFirstChild("ClaimVipReward"),       -- [Source: 102]
        Remotes:FindFirstChild("ClaimSeasonPassReward"),-- [Source: 111]
        Remotes:FindFirstChild("ClaimSevenLoginReward"),
        Remotes:FindFirstChild("UnlockAchievement")     -- [Source: 168]
    }

    if SpamRewards then
        spawn(function()
            while SpamRewards do
                for _, remote in pairs(RewardEvents) do
                    if remote then
                        -- Tenta enviar IDs de 1 a 100 (chute de IDs de quest)
                        for i = 1, 20 do 
                            pcall(function() remote:FireServer(i) end)
                            pcall(function() remote:InvokeServer(i) end)
                        end
                        -- Tenta enviar sem argumento
                        pcall(function() remote:FireServer() end)
                    end
                end
                task.wait(0.5) -- Delay pra não cair
            end
        end)
    end
end)

-- [[ 3. HERO LEVEL UP GLITCH ]] --
-- Tenta upar o nível do herói/sombra forçadamente 
local AutoLevel = false
CreateBtn("3. BUGAR NIVEL HEROI (Remote 112)", 3, Color3.fromRGB(150, 0, 150), function()
    AutoLevel = not AutoLevel
    local LevelUp = ReplicatedStorage.Remotes:FindFirstChild("HeroLevelUp") -- [Source: 112]
    
    if AutoLevel and LevelUp then
        spawn(function()
            while AutoLevel do
                -- Tenta upar o herói atual ou todos os IDs
                -- Argumentos chutados: (HeroID)
                for id = 1, 10 do -- Tenta os 10 primeiros heróis
                    pcall(function() LevelUp:FireServer(id) end)
                end
                task.wait(0.1)
            end
        end)
    end
end)