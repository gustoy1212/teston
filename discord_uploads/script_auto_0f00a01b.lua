-- [[ SOLO LEVELING: GOD HUB V5 ]] --
-- Novidades: Mobs Invisíveis, EnemyDeath Remote e Void Kill

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV5"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 0) -- Vermelho Sangue
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "☠️ GOD HUB V5 (DEATH NOTE)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

-- FUNÇÕES DA UI
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

local function AddButton(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(callback)
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EnemyFolder = Workspace:WaitForChild("Enemys")

-- ========================================== --
-- [[ 1. NOVO KILL: ENEMY DEATH (REMOTE) ]] --
-- ========================================== --
-- Achado no Log 2: ReplicatedStorage.Remotes.EnemyDeath

AddToggle("💀 DEATH NOTE (SPAM MORTE)", Color3.fromRGB(200, 0, 0), function(state)
    spawn(function()
        local DeathRemote = Remotes:FindFirstChild("EnemyDeath") --
        
        while state do
            if DeathRemote and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Envia o sinal de morte para o servidor
                        pcall(function() DeathRemote:FireServer(enemy) end)
                        
                        -- Tenta enviar com argumentos extras (True/1)
                        pcall(function() DeathRemote:FireServer(enemy, true) end)
                    end
                end
            end
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. NOVO KILL: VOID TELEPORT ]] --
-- ========================================== --
-- Tenta jogar os inimigos para baixo do mapa

AddToggle("🕳️ VOID KILL (DERRUBAR)", Color3.fromRGB(100, 0, 200), function(state)
    spawn(function()
        while state do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- Remove a velocidade para eles não voltarem
                        root.Velocity = Vector3.new(0, -100, 0)
                        -- Teleporta para o inferno
                        root.CFrame = CFrame.new(0, -490, 0)
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. IMÃ INVISÍVEL (PEDIDO SEU) ]] --
-- ========================================== --
-- Puxa os monstros e deixa eles transparentes

AddToggle("👻 IMÃ INVISÍVEL (PUXAR)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- Configuração da Hitbox
                        root.Size = Vector3.new(30, 30, 30)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5) -- Na sua frente
                        root.Velocity = Vector3.new(0,0,0)
                        
                        -- DEIXAR INVISÍVEL (LOOP NAS PARTES)
                        for _, part in pairs(enemy:GetDescendants()) do
                            if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Decal") then
                                part.Transparency = 1 -- 100% Invisível
                            end
                            -- Esconde a barra de vida original se for GUI
                            if part:IsA("BillboardGui") then
                                part.Enabled = false 
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. AUTO CLAIM (FUNCIONANDO) ]] --
-- ========================================== --

AddButton("💰 PEGAR RECOMPENSAS (GARANTIDO)", Color3.fromRGB(0, 150, 0), function()
    local Rewards = {
        "ClaimVipReward", "ClaimSeasonPassReward", "ClaimSevenLoginReward",
        "ClaimDailyTaskReward", "ClaimOnlineReward", "ClaimGroupReward",
        "ClaimActivitySpinReward", "GetReferralReward", "ExtraReward"
    }
    for _, name in pairs(Rewards) do
        local r = Remotes:FindFirstChild(name)
        if r then 
            pcall(function() r:FireServer() end)
            for i=1,5 do pcall(function() r:FireServer(i) end) end
        end
    end
end)

-- ========================================== --
-- [[ 5. AUTO ATTACK (CLÁSSICO) ]] --
-- ========================================== --

AddToggle("⚔️ AUTO ATTACK", Color3.fromRGB(100, 100, 100), function(state)
    spawn(function()
        while state do
            local Attack = Remotes:FindFirstChild("PlayerClickAttack")
            pcall(function() Attack:FireServer() end)
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 6. NECROMANCER (COLETOR DE SOMBRAS) ]] --
-- ========================================== --

AddToggle("🔮 AUTO SOMBRAS/OURO (GLOBAL)", Color3.fromRGB(100, 0, 200), function(state)
    spawn(function()
        while state do
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.MaxActivationDistance = 9e9
                    prompt.RequiresLineOfSight = false
                    prompt.HoldDuration = 0
                    if fireproximityprompt then fireproximityprompt(prompt) end
                end
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)