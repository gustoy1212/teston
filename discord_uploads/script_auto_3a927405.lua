-- [[ SOLO LEVELING: GOD HUB V11 (PHYSICS & TOWER) ]] --
-- Foco: Dano Físico (TouchInterest), Tower Skip e Equip Spam

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV11"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 25) -- Azul Aço
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚡ GOD HUB V11 (PHYSICS)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
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
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
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
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        callback(enabled)
    end)
end

-- ========================================== --
-- [[ 1. PHYSICS KILL AURA (SWORD TOUCH) ]] --
-- ========================================== --
-- Simula o toque físico da espada no inimigo (Bypass de Remote)

AddToggle("⚔️ SWORD AURA (FÍSICO)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            -- Procura a ferramenta equipada
            local tool = char and char:FindFirstChildOfClass("Tool")
            local handle = tool and tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox") -- Tenta achar a lâmina
            
            if handle and EnemyFolder then
                -- Ativa o hitbox da espada (alguns jogos precisam disso)
                if tool:FindFirstChild("HitboxActive") then tool.HitboxActive.Value = true end
                tool:Activate() 
                
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
                    
                    if hum and hum.Health > 0 and root then
                        -- Checa distância (Pra não bugar)
                        if (root.Position - char.HumanoidRootPart.Position).Magnitude < 25 then
                            
                            -- A MÁGICA: Simula o toque físico
                            -- O jogo acha que você encostou a espada no bicho
                            if firetouchinterest then
                                firetouchinterest(handle, root, 0) -- Toca
                                firetouchinterest(handle, root, 1) -- Solta
                            else
                                -- Fallback para executores fracos: Teleporta a espada no bicho?
                                -- Difícil sem mover o player, mas tentamos mover o handle localmente
                                handle.CFrame = root.CFrame
                            end
                        end
                    end
                end
            end
            task.wait() -- Velocidade máxima (RenderStepped seria melhor, mas wait() é seguro)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. TOWER GOD (AUTO CLIMB) ]] --
-- ========================================== --
-- Tenta subir a torre infinita sem lutar

AddToggle("🗼 TOWER SPEEDRUN (SKIP)", Color3.fromRGB(255, 215, 0), function(state)
    spawn(function()
        local NextLevel = Remotes:FindFirstChild("TowerEnterNextLevel") --
        local UpdateFloor = Remotes:FindFirstChild("UpdateNewSingleTowerFloor") --
        local GetReward = Remotes:FindFirstChild("GetNewSingleTowerTargetReward") --
        
        while state do
            if NextLevel then
                pcall(function() NextLevel:FireServer() end)
            end
            
            if UpdateFloor then
                -- Tenta forçar atualização do andar (pular +1)
                pcall(function() UpdateFloor:FireServer() end)
            end
            
            if GetReward then
                -- Tenta pegar recompensa do andar atual
                pcall(function() GetReward:FireServer() end)
            end
            
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. EQUIP SPAM (RESET ATTACK) ]] --
-- ========================================== --
-- Equipa/Desequipa rápido para resetar cooldown

AddToggle("🔄 EQUIP SPAM (NO DELAY)", Color3.fromRGB(0, 200, 100), function(state)
    spawn(function()
        local Equip = Remotes:FindFirstChild("EquipWeapon") --
        local Unequip = Remotes:FindFirstChild("UnbufferWeapon")
        
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            
            if tool then
                tool.Parent = LocalPlayer.Backpack -- Desequipa
                task.wait()
                tool.Parent = char -- Equipa
            end
            
            -- Tenta via Remote também
            if Equip then 
                -- ID 1 é geralmente a arma principal
                pcall(function() Equip:FireServer(1) end) 
            end
            
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. DECOMPOSE GLITCH (ITENS) ]] --
-- ========================================== --
-- Tenta decompor itens inexistentes para ganhar material

AddToggle("♻️ DECOMPOSE GLITCH (MATERIAIS)", Color3.fromRGB(150, 0, 150), function(state)
    spawn(function()
        local Decompose = Remotes:FindFirstChild("DecomposeItems") --
        
        while state do
            if Decompose then
                -- Tenta decompor listas vazias ou IDs negativos
                -- Às vezes o jogo buga e te dá o material sem tirar o item
                pcall(function() Decompose:FireServer({}) end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 5. SUPORTE (IMÃ) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ INVISÍVEL (NECESSÁRIO)", Color3.fromRGB(100, 100, 100), function(state)
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
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-3) -- Bem perto pra espada pegar
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