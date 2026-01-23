-- [[ SOLO LEVELING: GOD HUB V10 (TRUE DAMAGE) ]] --
-- Foco: Validação Real de Dano (ClickEnemy), Quest Spam e Congelar Inimigos

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV10"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 25) -- Amarelo Queimado
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚡ GOD HUB V10 (TRUE DAMAGE)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
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
-- [[ 1. TRUE DAMAGE (CLICK ENEMY FUNCTION) ]] --
-- ========================================== --
-- Essa é a nossa grande aposta. Usar a Função, não o Evento.

AddToggle("⚔️ TRUE AUTO ATTACK (VALIDADO)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        -- Achado no Log 2: ReplicatedStorage.Remotes.ClickEnemy
        local ClickFunc = Remotes:FindFirstChild("ClickEnemy") 
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and EnemyFolder and ClickFunc then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if eroot and hum and hum.Health > 0 then
                        -- Checa distância (Pra não dar flag de alcance)
                        if (eroot.Position - root.Position).Magnitude < 25 then
                            
                            -- Dispara em thread separada para não travar
                            spawn(function()
                                -- Tenta invocar a função (O servidor deve responder)
                                pcall(function() ClickFunc:InvokeServer(enemy) end)
                                pcall(function() ClickFunc:FireServer(enemy) end) -- Caso tenha mudado pra evento
                            end)
                        end
                    end
                end
            end
            task.wait(0.1) -- 10 Hits por segundo (Seguro)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. QUEST NUKE (LEVEL UP) ]] --
-- ========================================== --
-- Tenta completar todas as missões existentes

AddToggle("📜 QUEST NUKE (XP INFINITO?)", Color3.fromRGB(0, 200, 255), function(state)
    spawn(function()
        local FinishTask = Remotes:FindFirstChild("FinishTask") --
        
        if FinishTask then
            -- Loop de IDs de Missão (Geralmente 1 a 2000)
            local currentID = 1
            while state and currentID < 2000 do
                -- Envia em pacotes de 10 pra não cair
                for i = 0, 10 do
                    pcall(function() FinishTask:FireServer(currentID + i) end)
                end
                currentID = currentID + 10
                task.wait(0.1)
                if not ScreenGui.Parent then break end
            end
        end
    end)
end)

-- ========================================== --
-- [[ 3. MOB FREEZE (HERO STUCK) ]] --
-- ========================================== --
-- Tenta travar os monstros usando um remote de debug

AddToggle("❄️ CONGELAR INIMIGOS (STUCK)", Color3.fromRGB(0, 255, 255), function(state)
    spawn(function()
        local StuckRemote = Remotes:FindFirstChild("HeroBeStuck") --
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            if StuckRemote and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    -- Aplica o "Stuck" no inimigo
                    pcall(function() StuckRemote:FireServer(enemy) end)
                    
                    -- Também tenta remover a habilidade de mover deles localmente
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum then
                        hum.WalkSpeed = 0
                        hum.PlatformStand = true -- Deixa eles moles/travados
                    end
                end
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTAS ESSENCIAIS ]] --
-- ========================================== --

AddToggle("🧲 IMÃ DE MONSTROS (NECESSÁRIO)", Color3.fromRGB(150, 150, 150), function(state)
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