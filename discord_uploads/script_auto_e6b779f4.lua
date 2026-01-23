-- [[ SOLO LEVELING: GOD HUB V16 (TITAN SLAYER) ]] --
-- Foco: Espada Gigante (Hitbox Física), Lobotomia de Mobs e Imã

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV16"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 10, 10) -- Marrom Titã
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 100)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚔️ GOD HUB V16 (TITAN)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 200, 200)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
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
-- [[ 1. TITAN SWORD (ESPADA GIGANTE) ]] --
-- ========================================== --
-- Aumenta o tamanho físico do Handle da arma para garantir o hit

AddToggle("🗡️ ESPADA COLOSSAL (HITBOX)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            
            if tool then
                -- Procura a parte que dá dano (Handle ou Hitbox)
                -- Baseado na log: Excalibur e suas partes
                for _, part in pairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- Aumenta absurdamente o tamanho
                        -- Mas deixa invisível pra não poluir sua tela
                        part.Size = Vector3.new(80, 80, 80)
                        part.CanCollide = false
                        part.Massless = true -- Pra não deixar pesado
                        part.Transparency = 0.8 -- Semi-transparente pra você ver o alcance
                        part.Color = Color3.fromRGB(255, 0, 0)
                    end
                end
                
                -- Ativa a ferramenta para iniciar o ciclo de dano
                tool:Activate()
            end
            task.wait(0.5) -- Reaplica a cada meio segundo caso o jogo resete
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. MOB LOBOTOMY (DELETAR VALORES) ]] --
-- ========================================== --
-- Tenta bugar a vida do inimigo deletando os Values achados na log

AddToggle("🧠 LOBOTOMIA DE MOBS (BUG)", Color3.fromRGB(200, 0, 255), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    -- Procura o HumanoidRootPart onde vimos os valores na log
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root then
                        -- Tenta achar e manipular os valores específicos
                        local hpNum = root:FindFirstChild("HealthNum", true) -- Busca recursiva
                        local atkNum = root:FindFirstChild("AttackNum", true)
                        
                        if hpNum and hpNum:IsA("ValueBase") then
                            hpNum.Value = 0 -- Tenta zerar
                            -- hpNum:Destroy() -- Se zerar não funfar, descomente para destruir
                        end
                        
                        if atkNum and atkNum:IsA("ValueBase") then
                            atkNum.Value = 0 -- Tenta zerar o ataque deles
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
-- [[ 3. IMÃ (SUPORTE ESSENCIAL) ]] --
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
                        -- Puxa pra MUITO PERTO para garantir que a Espada Gigante pegue
                        root.Size = Vector3.new(10,10,10)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-2) 
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
-- [[ 4. AUTO CLICKER (FÍSICO) ]] --
-- ========================================== --

AddToggle("🖱️ AUTO CLICK (SWING)", Color3.fromRGB(0, 255, 0), function(state)
    local VIM = game:GetService("VirtualInputManager")
    spawn(function()
        while state do
            -- Clica fisicamente na tela
            VIM:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)