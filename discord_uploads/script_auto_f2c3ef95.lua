-- [[ SOLO LEVELING: MAGNET FARM V2 ]] --
-- Hitbox + Imã de Mobs + Auto Attack Real

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 200)
Frame.Position = UDim2.new(0.5, -130, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🧲 MAGNET GOD FARM"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- CONFIGURAÇÃO
local EnemyFolder = Workspace:WaitForChild("Enemys")
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("PlayerClickAttack") -- [Source: 114]

local FarmEnabled = false

-- [[ FUNÇÃO: PUXAR E BATER ]] --
local function StartFarm()
    spawn(function()
        while FarmEnabled do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.CFrame
                
                -- 1. TRAZ OS BICHOS (MAGNETO)
                if EnemyFolder then
                    for _, enemy in pairs(EnemyFolder:GetChildren()) do
                        local root = enemy:FindFirstChild("HumanoidRootPart")
                        local hum = enemy:FindFirstChild("Humanoid")
                        
                        if root and hum and hum.Health > 0 then
                            -- Deixa gigante
                            root.Size = Vector3.new(60, 60, 60) 
                            root.Transparency = 0.8
                            root.CanCollide = false
                            root.Color = Color3.fromRGB(255, 0, 0)
                            
                            -- TELEPORTA PARA VOCÊ (Imã)
                            -- Isso faz a sombra atacar aqui mesmo, sem correr
                            root.CFrame = myPos * CFrame.new(0, 0, -5) -- Traz pra frente do player
                        end
                    end
                end
                
                -- 2. AUTO ATTACK (DUPLO)
                -- Método A: Simula clique real do mouse (Universal)
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(900, 500))
                
                -- Método B: Dispara o Remote que achamos nos logs (Garantia)
                if AttackRemote then
                    AttackRemote:FireServer()
                end
                
                -- Método C: Ativa a ferramenta (Fallback)
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
            
            task.wait(0.1) -- Velocidade rápida
        end
    end)
end

-- [[ BOTÃO ]] --
local BtnFarm = Instance.new("TextButton", Frame)
BtnFarm.Size = UDim2.new(0.9, 0, 0.4, 0)
BtnFarm.Position = UDim2.new(0.05, 0, 0.35, 0)
BtnFarm.Text = "ATIVAR FARM COMPLETO"
BtnFarm.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnFarm.TextColor3 = Color3.new(1,1,1)
BtnFarm.Font = Enum.Font.GothamBold

BtnFarm.MouseButton1Click:Connect(function()
    FarmEnabled = not FarmEnabled
    if FarmEnabled then
        BtnFarm.Text = "🔴 PARAR FARM"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StartFarm()
    else
        BtnFarm.Text = "🟢 ATIVAR FARM COMPLETO"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local Status = Instance.new("TextLabel", Frame)
Status.Text = "DICA: Equipe a espada!"
Status.Position = UDim2.new(0,0,0.8,0)
Status.Size = UDim2.new(1,0,0,20)
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1