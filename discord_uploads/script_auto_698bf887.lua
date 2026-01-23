-- [[ SOLO LEVELING: GOD HUB V4 (DESTROYER) ]] --
-- Foco: DestroyEnemy (Instant Kill) + Todas as Recompensas

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV4"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0) -- Vermelho Escuro
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "👹 GOD HUB V4 (DESTROYER)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
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

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- FUNÇÃO ADD BUTTON
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

local function AddAction(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(callback)
end

-- ========================================== --
-- [[ 1. INSTANT KILL (DestroyEnemy) ]] --
-- ========================================== --
-- Achado no log: ReplicatedStorage.Remotes.DestroyEnemy 

AddToggle("☠️ INSTANT KILL (DESTROY)", Color3.fromRGB(255, 0, 0), function(state)
    spawn(function()
        local DestroyRemote = Remotes:FindFirstChild("DestroyEnemy")
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            if DestroyRemote and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Tenta deletar o inimigo diretamente
                        pcall(function() DestroyRemote:FireServer(enemy) end)
                        
                        -- Tenta deletar pelo Humanoid ou RootPart (vários métodos)
                        pcall(function() DestroyRemote:FireServer(enemy:FindFirstChild("HumanoidRootPart")) end)
                    end
                end
            end
            task.wait(0.2) -- 5 vezes por segundo
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. AUTO CLAIM (PEGAR TUDO) ]] --
-- ========================================== --
-- Lista massiva de recompensas achadas no seu log

AddAction("💰 PEGAR TODAS RECOMPENSAS", Color3.fromRGB(0, 200, 0), function()
    local RewardList = {
        "ClaimVipReward",           -- 
        "ClaimSeasonPassReward",    -- 
        "ClaimSevenLoginReward",    -- 
        "ClaimDailyTaskReward",     -- 
        "ClaimOnlineReward",        -- 
        "ClaimGroupReward",         -- 
        "ClaimActivitySpinReward",  -- 
        "GetReferralReward",        -- 
        "ExtraReward",              -- 
        "ClaimActivitySpinTicket",  -- 
        "GainRaidsRewards"          -- 
    }
    
    for _, name in pairs(RewardList) do
        local remote = Remotes:FindFirstChild(name)
        if remote then
            -- Tenta pegar genérico
            pcall(function() remote:FireServer() end)
            pcall(function() remote:InvokeServer() end)
            -- Tenta pegar por ID (1 a 10)
            for i=1, 5 do
                pcall(function() remote:FireServer(i) end)
            end
        end
    end
end)

-- ========================================== --
-- [[ 3. AUTO UPGRADE & FORGE ]] --
-- ========================================== --

AddToggle("⚡ AUTO UPGRADE HERO (LEVEL UP)", Color3.fromRGB(0, 100, 255), function(state)
    spawn(function()
        local LevelUp = Remotes:FindFirstChild("HeroLevelUp") -- 
        local Ascend = Remotes:FindFirstChild("HeroAscension") -- 
        
        while state do
            -- Tenta upar o herói equipado ou IDs baixos
            if LevelUp then
                pcall(function() LevelUp:FireServer() end)
                for i=1, 5 do pcall(function() LevelUp:FireServer(i) end) end
            end
            if Ascend then
                pcall(function() Ascend:FireServer() end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTAS EXTRAS (IMÃ) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ DE MONSTROS (SUPORTE)", Color3.fromRGB(150, 0, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    if eroot and hum and hum.Health > 0 then
                        eroot.Size = Vector3.new(30,30,30)
                        eroot.CanCollide = false
                        eroot.CFrame = root.CFrame * CFrame.new(0,0,-5)
                        eroot.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)