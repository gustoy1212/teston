-- [[ SOLO LEVELING: MAP EATER EDITION ]] --
-- Hitbox Global + Auto Farm Seguro

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 180)
Frame.Position = UDim2.new(0.1, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 170, 0)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🌍 MAP HITBOX FARM"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- CONFIGURAÇÃO
local EnemyFolder = Workspace:WaitForChild("Enemys")
local HitboxEnabled = false
local AutoAttack = false

-- [[ FUNÇÃO 1: HITBOX GLOBAL ]] --
local function ExpandirHitboxes()
    spawn(function()
        while HitboxEnabled do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    -- Só aumenta se estiver vivo
                    if root and hum and hum.Health > 0 then
                        root.Size = Vector3.new(800, 800, 800) -- TAMANHO DO MAPA
                        root.Transparency = 0.9 -- Quase invisível para não atrapalhar
                        root.CanCollide = false -- Você passa por dentro
                        root.Color = Color3.fromRGB(255, 0, 0)
                        
                        -- Traz o bicho um pouco pra cima para não bugar no chão
                        -- root.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
            task.wait(0.5) -- Atualiza a cada meio segundo para pegar monstros novos
        end
    end)
end

-- [[ FUNÇÃO 2: AUTO ESPADA ]] --
local function AtacarSozinho()
    spawn(function()
        while AutoAttack do
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate() -- Balança a espada
                end
            end
            task.wait(0.1) -- Velocidade do clique
        end
    end)
end

-- [[ BOTÕES ]] --
local BtnHitbox = Instance.new("TextButton", Frame)
BtnHitbox.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnHitbox.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnHitbox.Text = "ATIVAR HITBOX (MAPA)"
BtnHitbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnHitbox.TextColor3 = Color3.new(1,1,1)

BtnHitbox.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    if HitboxEnabled then
        BtnHitbox.Text = "HITBOX LIGADA (800x)"
        BtnHitbox.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        ExpandirHitboxes()
    else
        BtnHitbox.Text = "ATIVAR HITBOX (MAPA)"
        BtnHitbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local BtnAttack = Instance.new("TextButton", Frame)
BtnAttack.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnAttack.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnAttack.Text = "AUTO-SWING (BATER)"
BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnAttack.TextColor3 = Color3.new(1,1,1)

BtnAttack.MouseButton1Click:Connect(function()
    AutoAttack = not AutoAttack
    if AutoAttack then
        BtnAttack.Text = "BATENDO SOZINHO..."
        BtnAttack.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        AtacarSozinho()
    else
        BtnAttack.Text = "AUTO-SWING (BATER)"
        BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)