-- [[ SOLO LEVELING: GOD HUB V13 (BLACK MARKET) ]] --
-- Foco: Bugar Loja, Speedhack e Skills Especiais

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV13"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150) -- Verde Dinheiro
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "💸 GOD HUB V13 (LOJA BUGADA)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
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
-- [[ 1. SHOP GLITCH (DINHEIRO/ITENS) ]] --
-- ========================================== --
-- Tenta explorar remotes de troca para conseguir itens grátis

AddButton("💰 TENTAR BUGAR LOJA (CLIQUE VARIAS VEZES)", Color3.fromRGB(255, 200, 0), function()
    -- Remotes achados no log 2
    local MoneyExchange = Remotes:FindFirstChild("MoneytExchangeItem") --
    local TowerEx = Remotes:FindFirstChild("TowerExchange") 
    local MapShop = Remotes:FindFirstChild("MapShopExchange")
    
    spawn(function()
        -- Tenta IDs de 1 a 50 (Itens da loja)
        for i = 1, 20 do
            -- Tenta comprar com quantidade negativa (Bug clássico: -1 item = + Dinheiro)
            if MoneyExchange then pcall(function() MoneyExchange:InvokeServer(i, -100) end) end
            if TowerEx then pcall(function() TowerEx:FireServer(i, -100) end) end
            
            -- Tenta comprar de graça (Custo 0?)
            if MoneyExchange then pcall(function() MoneyExchange:InvokeServer(i, 0) end) end
            
            task.wait(0.05)
        end
    end)
end)

-- ========================================== --
-- [[ 2. SPECIAL SKILL SPAM (GEMA/RESPIRAÇÃO) ]] --
-- ========================================== --
-- Foca em ataques especiais que podem não ter cooldown

AddToggle("🔥 SPECIAL SKILL SPAM (GEMA/RESP)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        local GemSkill = Remotes:FindFirstChild("PlayerGemSkillAttack") --
        local RespSkill = Remotes:FindFirstChild("PlayerRespirationSkillAttack") --
        
        while state do
            -- Dispara skills especiais loucamente
            pcall(function() GemSkill:InvokeServer() end)
            pcall(function() GemSkill:FireServer() end)
            
            pcall(function() RespSkill:InvokeServer() end)
            pcall(function() RespSkill:FireServer() end)
            
            task.wait(0.1) -- Rápido, mas não trava
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. SPEEDHACK REAL (REMOTE) ]] --
-- ========================================== --
-- Usa o remote ChangeMoveSpeed para alterar a velocidade

AddToggle("⚡ SPEEDHACK (REMOTE)", Color3.fromRGB(0, 200, 255), function(state)
    local SpeedRemote = Remotes:FindFirstChild("ChangeMoveSpeed") --
    
    spawn(function()
        while state do
            -- Força velocidade 100 via Remote
            if SpeedRemote then
                pcall(function() SpeedRemote:FireServer(100) end)
            end
            
            -- Força velocidade via Cliente também
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 100
            end
            
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
        
        -- Reset ao desligar
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTA: IMÃ (O QUE FUNCIONA) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ INVISÍVEL (MANTIDO)", Color3.fromRGB(150, 150, 150), function(state)
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

-- ========================================== --
-- [[ 5. AUTO POTION (SOBREVIVÊNCIA) ]] --
-- ========================================== --
-- Tenta usar poção automaticamente

AddToggle("🧪 AUTO POÇÃO (INFINITA?)", Color3.fromRGB(255, 0, 255), function(state)
    spawn(function()
        local UseItem = Remotes:FindFirstChild("UseItem") --
        
        while state do
            if UseItem then
                -- Tenta usar poção (IDs comuns de poção: 1, 100, 101)
                pcall(function() UseItem:FireServer(1) end)
                pcall(function() UseItem:InvokeServer(1) end)
            end
            task.wait(2)
            if not ScreenGui.Parent then break end
        end
    end)
end)