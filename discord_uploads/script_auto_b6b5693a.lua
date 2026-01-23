-- [[ SOLO LEVELING: GOD HUB V8 (THE BREAKER) ]] --
-- Foco: Rank Up, Defense Break e Animation Overload

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV8"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10) -- Azul Profundo
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 100, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "💎 GOD HUB V8 (RANK UP)"
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
-- [[ 1. HERO RANK GLITCH (GRADE IMPROVE) ]] --
-- ========================================== --
-- Tenta forçar o Upgrade de Rank (E -> D -> C -> B -> A -> S)

AddToggle("💎 AUTO RANK UP (SPAM GRADE)", Color3.fromRGB(0, 150, 255), function(state)
    spawn(function()
        -- Remotes achados no log 2
        local GradeImprove = Remotes:FindFirstChild("HeroGradeImprove") -- 
        local HighGrade = Remotes:FindFirstChild("HeroHightMGradeImprove") -- 
        local Ascension = Remotes:FindFirstChild("HeroAscension") -- 
        
        while state do
            -- Tenta melhorar o Rank Comum
            if GradeImprove then pcall(function() GradeImprove:InvokeServer() end) end
            
            -- Tenta melhorar Rank Alto (High Grade)
            if HighGrade then pcall(function() HighGrade:InvokeServer() end) end
            
            -- Tenta Ascensão (Estrelas)
            if Ascension then pcall(function() Ascension:InvokeServer() end) end
            
            task.wait(0.5) -- Delay para não crashar
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. DEFENSE BREAKER (ARMOR 0) ]] --
-- ========================================== --
-- Tenta definir a Defesa do inimigo para 0 via UpdateEnemyDatas

AddToggle("🛡️ DEFENSE BREAKER (0 ARMOR)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        local UpdateData = Remotes:FindFirstChild("UpdateEnemyDatas") -- 
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if UpdateData and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Tenta injetar dados onde a Defesa é nula
                        -- A maioria dos jogos usa uma estrutura {Model, Stats}
                        local fakeStats = {
                            ["Defense"] = 0,
                            ["Armor"] = 0,
                            ["Dodge"] = 0
                        }
                        pcall(function() UpdateData:FireServer(enemy, fakeStats) end)
                    end
                end
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. ANIMATION OVERLOAD (LAG KILL) ]] --
-- ========================================== --
-- Força o servidor a tocar a animação de "Tomei Dano" no monstro infinitamente

AddToggle("⚡ LAG KILL (ANIMATION SPAM)", Color3.fromRGB(150, 0, 150), function(state)
    spawn(function()
        local PlayAnim = Remotes:FindFirstChild("PlayAddAttackAnim") -- 
        local HitRemote = Remotes:FindFirstChild("ShowEnemyTakeDamageInfo") -- 
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Força animação de ataque NO INIMIGO
                        if PlayAnim then 
                            pcall(function() PlayAnim:FireServer(enemy) end) 
                        end
                        
                        -- Força popup de dano (Visual ou Lógico?)
                        if HitRemote then
                            -- Envia um dano falso alto para ver se o HP desce visualmente
                            pcall(function() HitRemote:FireServer(enemy, 999999, false) end)
                        end
                    end
                end
            end
            task.wait() -- Sem delay (Máxima velocidade)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTAS BÁSICAS ]] --
-- ========================================== --

AddToggle("🧲 IMÃ INVISÍVEL", Color3.fromRGB(100, 100, 100), function(state)
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