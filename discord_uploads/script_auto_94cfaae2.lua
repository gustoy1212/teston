-- [[ SOLO LEVELING: GOD HUB V19 (SWORD TELEPORT) ]] --
-- Foco: Teleporte da Lâmina (Handle), Lag Switch e Buffs

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV19"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 20, 5) -- Verde Matrix
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🗡️ GOD HUB V19 (SWORD TP)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

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
-- [[ 1. SWORD HANDLE TELEPORT (AURA FÍSICA) ]] --
-- ========================================== --
-- Teleporta a peça da espada (Handle) para dentro do monstro
-- Isso força o evento .Touched no servidor

AddToggle("🗡️ SWORD TP (MATAR)", Color3.fromRGB(0, 255, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox"))
            
            if handle and EnemyFolder then
                -- Ativa a animação de ataque para o servidor validar
                tool:Activate()
                
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- Distância segura (para não bugar o script)
                        if (root.Position - char.HumanoidRootPart.Position).Magnitude < 40 then
                            
                            -- A MÁGICA: Teleporta a lâmina
                            -- Desliga a colisão pra ela entrar no bicho
                            handle.CanCollide = false 
                            
                            -- Salva posição original (relativa à mão)
                            local oldCFrame = handle.CFrame
                            
                            -- Teleporta para o coração do inimigo
                            handle.CFrame = root.CFrame
                            
                            -- Força o toque
                            if firetouchinterest then
                                firetouchinterest(handle, root, 0)
                                firetouchinterest(handle, root, 1)
                            end
                            
                            -- Volta rápido (opcional, as vezes deixar lá é melhor)
                            -- handle.CFrame = oldCFrame 
                        end
                    end
                end
            end
            -- Velocidade extrema (RenderStepped seria ideal, mas Heartbeat é seguro)
            RunService.Heartbeat:Wait()
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. LAG SWITCH (COMBO ATTACK) ]] --
-- ========================================== --
-- Spamma o ataque remoto de forma concentrada

AddToggle("⚡ LAG ATTACK (COMBO)", Color3.fromRGB(255, 200, 0), function(state)
    spawn(function()
        local AttackEvent = ReplicatedStorage.Remotes:FindFirstChild("PlayerClickAttack")
        local ClickFunc = ReplicatedStorage.Remotes:FindFirstChild("ClickEnemy")
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            -- Acumula "energia"
            task.wait(0.2)
            
            -- Dispara tudo de uma vez (Burst)
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 30 then
                        -- Envia 5 ataques instantâneos
                        for i=1, 5 do
                            if AttackEvent then pcall(function() AttackEvent:FireServer(enemy) end) end
                            if ClickFunc then pcall(function() ClickFunc:InvokeServer(enemy) end) end
                        end
                    end
                end
            end
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. BUFF SPAM (FORÇAR PODER) ]] --
-- ========================================== --
-- Tenta pegar buff de ataque infinitamente

AddToggle("🔥 BUFF SPAM (STATUS)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local BuffRemote = ReplicatedStorage.Remotes:FindFirstChild("UpdateRandomBuff") --
        
        while state do
            if BuffRemote then
                pcall(function() BuffRemote:FireServer() end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. IMÃ DE SUPORTE ]] --
-- ========================================== --

AddToggle("🧲 IMÃ INVISÍVEL", Color3.fromRGB(150, 150, 150), function(state)
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
                        root.Size = Vector3.new(15,15,15) -- Hitbox média
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-4) -- Perto, mas não em cima
                        root.Velocity = Vector3.new(0,0,0)
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