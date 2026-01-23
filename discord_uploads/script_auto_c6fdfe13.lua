-- [[ SOLO LEVELING: GOD HUB V6 (GLITCH EDITION) ]] --
-- Foco: HP Glitch, Skill Spam e Raid Rewards

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV6"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 450)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Roxo Glitch
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "👾 GOD HUB V6 (GLITCH)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
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
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

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

-- ========================================== --
-- [[ 1. HP GLITCH (NOVA APOSTA) ]] --
-- ========================================== --
-- Tenta manipular a vida do inimigo via UpdateEnemyDatas

AddToggle("🩸 HP GLITCH (SET 0 LIFE)", Color3.fromRGB(200, 0, 50), function(state)
    spawn(function()
        local UpdateData = Remotes:FindFirstChild("UpdateEnemyDatas") -- 
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if UpdateData and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Tenta enviar uma tabela de dados falsos
                        -- Formato comum: {Model, Vida, MaxVida}
                        local fakeData = {
                            [1] = enemy,
                            [2] = 0, -- Vida 0
                            [3] = 0  -- Max Vida 0
                        }
                        pcall(function() UpdateData:FireServer(fakeData) end)
                        
                        -- Tenta enviar direto
                        pcall(function() UpdateData:FireServer(enemy, 0) end)
                    end
                end
            end
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. SKILL MACHINE GUN (NO COOLDOWN) ]] --
-- ========================================== --
-- Spamma a habilidade especial sem parar

AddToggle("⚔️ SKILL SPAM (NO COOLDOWN)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        local Skill = Remotes:FindFirstChild("PlayerClickAttackSkill") -- 
        local RespSkill = Remotes:FindFirstChild("PlayerRespirationSkillAttack") -- 
        
        while state do
            -- Dispara loucamente
            pcall(function() Skill:FireServer() end)
            pcall(function() RespSkill:FireServer() end)
            
            -- Tenta forçar a animação de ataque (as vezes o dano é atrelado a isso)
            local PlayAnim = Remotes:FindFirstChild("PlayWeaponSkillAnim")
            if PlayAnim then pcall(function() PlayAnim:FireServer() end) end

            task.wait() -- Sem delay (Speed máximo)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. RAID REWARD BYPASS ]] --
-- ========================================== --
-- Tenta pegar o prêmio da Raid sem entrar nela

AddButton("🏆 PEGAR RECOMPENSA RAID (GLITCH)", Color3.fromRGB(255, 215, 0), function()
    local RaidReward = Remotes:FindFirstChild("GainRaidsRewards") -- 
    local BossReward = Remotes:FindFirstChild("GainGarrisonBossRankRewards") -- 
    
    if RaidReward then
        -- Tenta IDs de Raid de 1 a 10
        for i=1, 10 do
            pcall(function() RaidReward:InvokeServer(i) end) -- Se for Function
            pcall(function() RaidReward:FireServer(i) end)   -- Se for Event
        end
    end
    
    if BossReward then
        pcall(function() BossReward:FireServer() end)
    end
end)

-- ========================================== --
-- [[ 4. BUFF GOD (STATUS INFINITO) ]] --
-- ========================================== --
-- Tenta ativar buffs aleatórios

AddButton("⚡ ATIVAR BUFFS ALEATÓRIOS", Color3.fromRGB(0, 255, 255), function()
    local RandomBuff = Remotes:FindFirstChild("UpdateRandomBuff") -- 
    local FriendBuff = Remotes:FindFirstChild("AddFriendEvent") -- 
    
    if RandomBuff then
        pcall(function() RandomBuff:FireServer() end)
    end
    
    -- Tenta bugar o buff de amigo
    if FriendBuff then
        for i=1, 5 do pcall(function() FriendBuff:FireServer() end) end
    end
end)

-- ========================================== --
-- [[ 5. IMÃ INVISÍVEL (RESTAURADO) ]] --
-- ========================================== --

AddToggle("👻 IMÃ INVISÍVEL (SUPORTE)", Color3.fromRGB(100, 100, 100), function(state)
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
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-6)
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

-- ========================================== --
-- [[ 6. NECROMANCER (GLOBAL) ]] --
-- ========================================== --

AddToggle("🔮 AUTO SOMBRAS (GLOBAL)", Color3.fromRGB(100, 0, 200), function(state)
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