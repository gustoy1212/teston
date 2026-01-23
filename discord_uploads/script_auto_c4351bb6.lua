-- [[ SOLO LEVELING: GOD HUB V20 (DAMAGE OVERFLOW) ]] --
-- Foco: Acúmulo de Status (Stack Glitch) e Dano Crítico Forçado

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV20"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Roxo Glitch
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🩸 GOD HUB V20 (DAMAGE)"
Title.Size = UDim2.new(1, -30, 0.15, 0)
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
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
Container.Size = UDim2.new(0.95, 0, 0.8, 0)
Container.Position = UDim2.new(0.025, 0, 0.15, 0)
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
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        callback(enabled)
    end)
end

-- ========================================== --
-- [[ 1. DAMAGE STACK (EQUIP GLITCH) ]] --
-- ========================================== --
-- Tenta equipar a mesma arma infinitas vezes para somar o dano

AddToggle("📈 DAMAGE STACK (ACUMULAR)", Color3.fromRGB(255, 0, 255), function(state)
    spawn(function()
        local Equip = Remotes:FindFirstChild("EquipWeapon") --
        
        while state do
            if Equip then
                -- NÃO desequipa. Só manda equipar de novo e de novo.
                -- Tenta ID 1 (Geralmente a arma principal) ou procura no inventário
                pcall(function() Equip:FireServer(1) end)
                
                -- Se tiver Remote de Buff, usa também
                local Buff = Remotes:FindFirstChild("UpdateRandomBuff")
                if Buff then pcall(function() Buff:FireServer() end) end
            end
            task.wait(0.1) -- Rápido
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. CRITICAL FORCE (ARGUMENTS) ]] --
-- ========================================== --
-- Intercepta o visual de dano e tenta forçar "Crítico: True"

AddToggle("💥 CRITICAL HIT (FORCE)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local ShowDmg = Remotes:FindFirstChild("ShowEnemyTakeDamageInfo")
        local EnemyFolder = game.Workspace:FindFirstChild("Enemys")
        
        while state do
            if ShowDmg and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local dist = (enemy.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 20 then
                            -- Argumentos comuns: Alvo, Dano, É Crítico?, Tipo
                            -- Enviamos TRUE no terceiro argumento
                            pcall(function() ShowDmg:FireServer(enemy, 1, true) end)
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
-- [[ 3. FAST TOUCH (HITBOX REFRESH) ]] --
-- ========================================== --
-- Liga e desliga o hitbox da espada para contar mais hits

AddToggle("⚔️ FAST HIT (HITBOX SPAM)", Color3.fromRGB(0, 255, 100), function(state)
    spawn(function()
        local EnemyFolder = game.Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox"))
            
            if handle and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - char.HumanoidRootPart.Position).Magnitude < 25 then
                        
                        -- Toca
                        if firetouchinterest then
                            firetouchinterest(handle, root, 0)
                        end
                        -- Não solta imediatamente, espera um frame (Game Logic Tick)
                        RunService.Heartbeat:Wait()
                        
                        -- Solta
                        if firetouchinterest then
                            firetouchinterest(handle, root, 1)
                        end
                    end
                end
            end
            -- Espera um tiquinho pro jogo processar o dano
            task.wait(0.05)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. IMÃ (SUPORTE) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ (PUXAR)", Color3.fromRGB(150, 150, 150), function(state)
    spawn(function()
        local EnemyFolder = game.Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    if root and hum and hum.Health > 0 then
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-4)
                        root.CanCollide = false
                        root.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)