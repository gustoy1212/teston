-- [[ SOLO LEVELING: GOD HUB V7 (STAT EDITOR) ]] --
-- Foco: Modificar Status (Força/Ataque) e Bugar Dinheiro

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV7"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 10) -- Laranja/Marrom RPG
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 150, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "💪 GOD HUB V7 (STATS)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
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

-- FUNÇÕES DA UI
local function AddButton(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(callback)
end

-- ========================================== --
-- [[ 1. GOD STATS (MODIFICAR ATRIBUTOS) ]] --
-- ========================================== --
-- Tenta usar UpdateOwnHeroDatas para mudar seus status

AddButton("💪 INJETAR FORÇA 999K (TESTE 1)", Color3.fromRGB(255, 100, 0), function()
    local UpdateStats = Remotes:FindFirstChild("UpdateOwnHeroDatas") -- 
    local UpdateStats2 = Remotes:FindFirstChild("UpdateOwnHeroDatasAndStatics") -- 
    
    local FakeStats = {
        ["Attack"] = 99999999,
        ["Damage"] = 99999999,
        ["Strength"] = 99999999,
        ["Power"] = 99999999,
        ["Crit"] = 100,
        ["Speed"] = 500
    }
    
    if UpdateStats then
        pcall(function() UpdateStats:FireServer(FakeStats) end)
        -- Tenta enviar como lista também
        pcall(function() UpdateStats:FireServer(999999, 999999) end)
    end
    
    if UpdateStats2 then
        pcall(function() UpdateStats2:FireServer(FakeStats) end)
    end
end)

AddButton("🗡️ BUFFAR ARMA (WEAPON DMG)", Color3.fromRGB(255, 50, 0), function()
    local UpdateWeapon = Remotes:FindFirstChild("UpdateWeapon") -- 
    -- Tenta dizer que sua arma atual tem nível 1000
    if UpdateWeapon then
        pcall(function() 
            UpdateWeapon:FireServer({
                ["Level"] = 1000,
                ["Damage"] = 9999999
            }) 
        end)
    end
end)

-- ========================================== --
-- [[ 2. MONEY GLITCH (BUG DA TROCA) ]] --
-- ========================================== --
-- Tenta explorar o erro de digitação no remote "MoneytExchangeItem"

AddButton("💰 MONEY GLITCH (TROCA BUGADA)", Color3.fromRGB(0, 200, 50), function()
    local BuggyRemote = Remotes:FindFirstChild("MoneytExchangeItem") -- 
    
    if BuggyRemote then
        -- Tentativa 1: Trocar NADA por dinheiro
        pcall(function() BuggyRemote:InvokeServer() end)
        
        -- Tentativa 2: Trocar quantidade negativa (Ex: -100 itens = +100 itens pra você?)
        for i = 1, 10 do
            pcall(function() BuggyRemote:InvokeServer(1, -100) end) -- ID 1, Quantidade -100
            pcall(function() BuggyRemote:InvokeServer(1, 0) end)    -- ID 1, Quantidade 0
        end
    end
end)

-- ========================================== --
-- [[ 3. BUFF GOD (STATUS INFINITO) ]] --
-- ========================================== --

AddButton("⚡ FORÇAR TODOS OS BUFFS", Color3.fromRGB(0, 150, 255), function()
    local BuffRemote = Remotes:FindFirstChild("UpdateRandomBuff") -- 
    local BuffTime = Remotes:FindFirstChild("UpdateBuffTimes") -- 
    
    if BuffRemote then
        -- Spamma para tentar pegar Attack Up
        for i=1, 20 do
            pcall(function() BuffRemote:FireServer() end)
        end
    end
    
    if BuffTime then
        -- Tenta estender o tempo dos buffs para infinito
        pcall(function() BuffTime:FireServer(999999) end)
    end
end)

-- ========================================== --
-- [[ 4. AUTO UPGRADE (SPAM) ]] --
-- ========================================== --

AddButton("🔨 FORÇAR UPGRADE ARMA", Color3.fromRGB(150, 150, 150), function()
    local Forge = Remotes:FindFirstChild("ForgeWeapon") -- 
    local Improve = Remotes:FindFirstChild("HeroGradeImprove") -- 
    
    if Forge then
        for i=1, 10 do pcall(function() Forge:InvokeServer(i) end) end
    end
    
    if Improve then
         pcall(function() Improve:InvokeServer() end)
    end
end)

-- ========================================== --
-- [[ 5. SUPORTE (IMÃ) ]] --
-- ========================================== --

local MagnetEnabled = false
AddButton("🧲 IMÃ INVISÍVEL (LIGAR/DESLIGAR)", Color3.fromRGB(100, 100, 100), function()
    MagnetEnabled = not MagnetEnabled
    if MagnetEnabled then
        spawn(function()
            local EnemyFolder = Workspace:FindFirstChild("Enemys")
            while MagnetEnabled do
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
    end
end)