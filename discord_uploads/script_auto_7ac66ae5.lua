-- [[ SOLO LEVELING: MAGNET KING V3 ]] --
-- Correção do Auto-Attack para Mobile/Emulador

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 280, 0, 220)
Frame.Position = UDim2.new(0.5, -140, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🧲 MAGNET KING V3"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- CONFIGURAÇÃO
local EnemyFolder = Workspace:WaitForChild("Enemys")
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("PlayerClickAttack")

local MagnetEnabled = false
local AttackEnabled = false

-- [[ 1. MAGNETO + HITBOX (O que já funcionou) ]] --
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
                            -- Hitbox Gigante (Visualmente limpa)
                            root.Size = Vector3.new(50, 50, 50) 
                            root.Transparency = 0.8
                            root.CanCollide = false
                            root.Color = Color3.fromRGB(255, 0, 0)
                            
                            -- Puxa para a frente do jogador (Z -5)
                            root.CFrame = myPos * CFrame.new(0, 0, -4)
                            
                            -- Remove Velocity para eles não "escorregarem"
                            if root:FindFirstChild("BodyVelocity") then root.BodyVelocity:Destroy() end
                            root.Velocity = Vector3.new(0,0,0)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- [[ 2. AUTO ATTACK V3 (CORRIGIDO) ]] --
local function StartAutoAttack()
    spawn(function()
        while AttackEnabled do
            local char = LocalPlayer.Character
            
            -- Método 1: Virtual Input Manager (Toque Real)
            -- Simula clique no centro da tela
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            end)

            -- Método 2: Remote com Posição do Mouse (Muitos jogos pedem isso)
            if AttackRemote then
                pcall(function()
                    -- Envia a posição onde você está olhando (Mouse Hit)
                    local mouseHit = LocalPlayer:GetMouse().Hit.Position
                    AttackRemote:FireServer(mouseHit)
                    -- Tenta enviar vazio também
                    AttackRemote:FireServer()
                end)
            end

            -- Método 3: Ativação Clássica da Ferramenta
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then 
                    tool:Activate() 
                end
            end
            
            task.wait(0.15) -- Velocidade de clique natural
        end
    end)
end

-- [[ BOTÕES ]] --
local BtnMagnet = Instance.new("TextButton", Frame)
BtnMagnet.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnMagnet.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnMagnet.Text = "ATIVAR IMÃ (PUXAR MOBS)"
BtnMagnet.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnMagnet.TextColor3 = Color3.new(1,1,1)
BtnMagnet.Font = Enum.Font.GothamBold

BtnMagnet.MouseButton1Click:Connect(function()
    MagnetEnabled = not MagnetEnabled
    if MagnetEnabled then
        BtnMagnet.Text = "🧲 IMÃ LIGADO"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
        StartMagnet()
    else
        BtnMagnet.Text = "ATIVAR IMÃ (PUXAR MOBS)"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local BtnAttack = Instance.new("TextButton", Frame)
BtnAttack.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnAttack.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnAttack.Text = "⚔️ AUTO ATTACK V3"
BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnAttack.TextColor3 = Color3.new(1,1,1)
BtnAttack.Font = Enum.Font.GothamBold

BtnAttack.MouseButton1Click:Connect(function()
    AttackEnabled = not AttackEnabled
    if AttackEnabled then
        BtnAttack.Text = "BATENDO... (V3)"
        BtnAttack.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StartAutoAttack()
    else
        BtnAttack.Text = "⚔️ AUTO ATTACK V3"
        BtnAttack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local Status = Instance.new("TextLabel", Frame)
Status.Text = "OBS: Equipe a espada!"
Status.Position = UDim2.new(0,0,0.9,0)
Status.Size = UDim2.new(1,0,0,15)
Status.TextColor3 = Color3.fromRGB(100, 100, 100)
Status.BackgroundTransparency = 1