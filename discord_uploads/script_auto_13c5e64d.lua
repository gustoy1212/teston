-- [[ SOLO LEVELING: GOD HUB V18 (THE BLACK HOLE) ]] --
-- Foco: Jogar mobs no Void, Spam de Skill e Quebrar Juntas

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV18"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 0, 15) -- Roxo Escuro
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🌌 GOD HUB V18 (BLACK HOLE)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(150, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- FUNÇÕES UI
local function AddToggle(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text .. " [OFF]"
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = color
            btn.TextColor3 = Color3.new(1,1,1)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        callback(enabled)
    end)
end

-- ========================================== --
-- [[ 1. VOID HOLE (MOVER PRO ABISMO) ]] --
-- ========================================== --
-- Se o imã funciona, isso AQUI tem que funcionar.
-- Tira o bicho do mapa e joga ele no Y -500.

AddToggle("🌌 VOID MAGNET (INSTA KILL?)", Color3.fromRGB(150, 0, 255), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- Remove a velocidade para ele cair reto
                        root.Velocity = Vector3.new(0, -500, 0)
                        -- Define a posição lá embaixo
                        root.CFrame = CFrame.new(99999, -490, 99999) 
                        
                        -- Tenta destruir o HumanoidRootPart (As vezes mata)
                        -- root:Destroy() -- (Opcional, teste se o TP falhar)
                    end
                end
            end
            task.wait(0.1) -- Muito rápido
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. SKILL AURA (METRALHADORA) ]] --
-- ========================================== --
-- Baseado nos logs, usa Skills em vez de ataque básico.

AddToggle("🔥 SKILL MACHINE GUN (SPAM)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        -- Remotes achados na LOG 205536
        local Skill1 = Remotes:FindFirstChild("PlayerClickAttackSkill") 
        local Skill2 = Remotes:FindFirstChild("PlayerGemSkillAttack")
        local Skill3 = Remotes:FindFirstChild("PlayerRespirationSkillAttack")
        local EnemyFolder = Workspace:WaitForChild("Enemys")

        while state do
            -- Dispara as skills sem parar
            if Skill1 then pcall(function() Skill1:FireServer() end) end
            if Skill2 then pcall(function() Skill2:InvokeServer() end) end
            if Skill3 then pcall(function() Skill3:FireServer() end) end
            
            -- Tenta disparar skills DIRECIONADAS nos inimigos
            for _, enemy in pairs(EnemyFolder:GetChildren()) do
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 50 then
                     if Skill1 then pcall(function() Skill1:FireServer(enemy) end) end
                end
            end
            
            task.wait() -- Sem delay
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. NECK BREAKER (LOCAL DELETE) ]] --
-- ========================================== --
-- Tenta deletar as juntas do corpo do monstro.

AddToggle("💀 QUEBRAR JUNTAS (DELETAR)", Color3.fromRGB(255, 0, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Procura o RootJoint (A peça que segura o corpo)
                        local rootPart = enemy:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local joint = rootPart:FindFirstChild("RootJoint")
                            if joint then
                                joint:Destroy() -- Quebra o boneco
                            end
                        end
                        -- Tenta quebrar o pescoço
                        local head = enemy:FindFirstChild("Head")
                        if head then
                            local neck = head:FindFirstChild("Neck")
                            if neck then neck:Destroy() end
                        end
                    end
                end
            end
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. IMÃ CLÁSSICO (SE O VOID FALHAR) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ NORMAL (PUXAR)", Color3.fromRGB(150, 150, 150), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    if root and hum and hum.Health > 0 then
                        root.Size = Vector3.new(30,30,30)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-5)
                        root.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)