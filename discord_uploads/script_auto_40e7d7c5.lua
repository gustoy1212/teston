-- [[ SOLO LEVELING: SHADOW OVERCLOCK ]] --
-- Foca em deixar a Sombra (Hero) agressiva e rápida

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 160)
Frame.Position = UDim2.new(0.5, -130, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(15, 0, 30) -- Roxo Sombra
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(150, 50, 255)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "☠️ SHADOW OVERCLOCK"
Title.Size = UDim2.new(1, 0, 0.25, 0)
Title.TextColor3 = Color3.fromRGB(180, 100, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.BackgroundTransparency = 1

-- BOTÃO
local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Size = UDim2.new(0.8, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 150)
ToggleBtn.Text = "ATIVAR FÚRIA DA SOMBRA"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", Frame)
Status.Text = "Status: Aguardando..."
Status.Position = UDim2.new(0,0,0.85,0)
Status.Size = UDim2.new(1,0,0,15)
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- [[ REMOTES DA SOMBRA (BASEADO NAS LOGS) ]] --
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HeroSkill = Remotes:FindFirstChild("HeroUseSkill")           -- [Log 126]
local HeroMove = Remotes:FindFirstChild("HeroMoveToEnemyPos")     -- [Log 179]
local HeroAttack = Remotes:FindFirstChild("UpdateOwnHeroDatas")    -- [Log 170] Tenta atualizar dados

local EnemyFolder = Workspace:WaitForChild("Enemys")

-- [[ LÓGICA DE TARGET ]] --
local function GetTarget()
    local closest = nil
    local maxDist = 200 -- Alcance alto para a sombra buscar longe
    
    if not EnemyFolder then return nil end

    for _, enemy in pairs(EnemyFolder:GetChildren()) do
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

-- [[ LOOP DA MALDADE ]] --
local Ativado = false

ToggleBtn.MouseButton1Click:Connect(function()
    Ativado = not Ativado
    if Ativado then
        ToggleBtn.Text = "DESATIVAR (SOMBRA LIGADA)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "Status: ⚔️ Enviando comandos..."
        
        spawn(function()
            while Ativado do
                local target = GetTarget()
                if target then
                    local targetRoot = target:FindFirstChild("HumanoidRootPart")
                    
                    if HeroSkill and targetRoot then
                        -- 1. Manda a sombra usar skill SEM PARAR
                        -- Tentativa de argumentos: (Alvo), (Posição), (SkillID)
                        pcall(function() HeroSkill:FireServer(target) end)
                        pcall(function() HeroSkill:FireServer(targetRoot.Position) end)
                        
                        -- 2. Teleporta a sombra pro pescoço do inimigo
                        if HeroMove then
                            pcall(function() HeroMove:FireServer(target) end)
                            pcall(function() HeroMove:FireServer(targetRoot.Position) end)
                        end
                    end
                else
                    Status.Text = "Status: 🔍 Procurando inimigo..."
                end
                
                task.wait() -- Mínimo delay possível (Speed Hack para Pet)
            end
        end)
    else
        ToggleBtn.Text = "ATIVAR FÚRIA DA SOMBRA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 150)
        Status.Text = "Status: Parado"
    end
end)