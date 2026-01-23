-- [[ SOLO LEVELING: GOD HUB V12 (POSITION & WUKONG) ]] --
-- Foco: Autorizar Ataque (Posição), Modo Wukong e Rage Infinito

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV12"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 5) -- Vermelho Wukong
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🐵 GOD HUB V12 (WUKONG)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
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
-- [[ 1. ATTACK AUTHORIZER (BYPASS) ]] --
-- ========================================== --
-- Diz pro servidor "Estou na posição de bater" antes de atacar

AddToggle("🔓 LIBERAR ATAQUE (BYPASS)", Color3.fromRGB(0, 255, 100), function(state)
    spawn(function()
        local ReachedPos = Remotes:FindFirstChild("HeroReachedAttackPos") --
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if ReachedPos and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Envia sinal de que chegou no inimigo
                        -- Tenta enviar o Modelo ou a Posição
                        pcall(function() ReachedPos:FireServer(enemy) end)
                        pcall(function() ReachedPos:FireServer(enemy.HumanoidRootPart.Position) end)
                    end
                end
            end
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. WUKONG MODE (GOD ATTACK) ]] --
-- ========================================== --
-- Tenta usar os ataques do Wukong

AddToggle("🐵 WUKONG ATTACK (CRASH?)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        local Wukong = Remotes:FindFirstChild("UpdateWuKongAttack") --
        local Attack = Remotes:FindFirstChild("PlayerClickAttack")
        
        while state do
            if Wukong then
                -- Tenta disparar o ataque especial
                pcall(function() Wukong:FireServer() end)
                pcall(function() Wukong:FireServer(true) end)
            end
            
            -- Combina com ataque normal
            if Attack then pcall(function() Attack:FireServer() end) end
            
            -- Clique virtual para garantir
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            
            task.wait(0.15)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. RAGE MODE (INFINITE ULT) ]] --
-- ========================================== --
-- Tenta ativar o status de "Raiva" permanentemente

AddToggle("🔥 RAGE MODE (ULT INFINITA)", Color3.fromRGB(255, 0, 0), function(state)
    spawn(function()
        local Angry = Remotes:FindFirstChild("UpdateAngrySkilStatus") --
        
        while state do
            if Angry then
                -- Envia True (Ativado) ou 100 (Carga cheia)
                pcall(function() Angry:FireServer(true) end)
                pcall(function() Angry:FireServer(100) end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTA: IMÃ (MANTIDO) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ INVISÍVEL", Color3.fromRGB(150, 150, 150), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    if eroot and hum and hum.Health > 0 then
                        eroot.Size = Vector3.new(30,30,30)
                        eroot.CanCollide = false
                        eroot.CFrame = myRoot.CFrame * CFrame.new(0,0,-5)
                        eroot.Velocity = Vector3.new(0,0,0)
                        for _, p in pairs(enemy:GetDescendants()) do
                            if p:IsA("BasePart") then p.Transparency = 1 end
                            if p:IsA("BillboardGui") then p.Enabled = false end
                        end
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)