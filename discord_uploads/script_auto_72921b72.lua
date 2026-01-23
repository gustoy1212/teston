-- [[ SOLO LEVELING: GOD HUB V14 (SPEEDSTER) ]] --
-- Foco: Teleporte de Ataque (Flash), Buffer Glitch e Speed Control

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV14"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 15, 30) -- Azul Elétrico
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚡ GOD HUB V14 (SPEEDSTER)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
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

local function AddSlider(text, min, max, callback)
    local frame = Instance.new("Frame", Container)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0.4, 0)
    label.Text = text .. ": " .. min
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    
    local sliderBtn = Instance.new("TextButton", frame)
    sliderBtn.Size = UDim2.new(1, 0, 0.4, 0)
    sliderBtn.Position = UDim2.new(0, 0, 0.5, 0)
    sliderBtn.Text = ""
    sliderBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    
    local fill = Instance.new("Frame", sliderBtn)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    
    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    game:GetService("UserInputService").InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
    end)
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouseX = game:GetService("UserInputService"):GetMouseLocation().X
            local btnX = sliderBtn.AbsolutePosition.X
            local btnW = sliderBtn.AbsoluteSize.X
            local pct = math.clamp((mouseX - btnX) / btnW, 0, 1)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            local value = math.floor(min + (max - min) * pct)
            label.Text = text .. ": " .. value
            callback(value)
        end
    end)
end

-- ========================================== --
-- [[ 1. SPEED HACK (CONFIRMADO) ]] --
-- ========================================== --

local currentSpeed = 50
AddSlider("⚡ VELOCIDADE", 16, 300, function(val)
    currentSpeed = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val
    end
    -- Usa o Remote que funcionou
    local SpeedRemote = Remotes:FindFirstChild("ChangeMoveSpeed") --
    if SpeedRemote then pcall(function() SpeedRemote:FireServer(val) end) end
end)

AddToggle("⚡ MANTER VELOCIDADE (LOOP)", Color3.fromRGB(0, 200, 255), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = currentSpeed
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. FLASH FARM (TELEPORT KILL) ]] --
-- ========================================== --
-- Teleporta para o inimigo, bate e vai pro próximo.
-- Usa a liberdade de movimento que descobrimos.

AddToggle("⚔️ FLASH FARM (TELEPORT KILL)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        local AttackRemote = Remotes:FindFirstChild("PlayerClickAttack")
        local ClickFunc = Remotes:FindFirstChild("ClickEnemy")
        
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    if not state then break end
                    
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if eroot and hum and hum.Health > 0 then
                        -- TELEPORTA PARA TRÁS DO INIMIGO
                        root.CFrame = eroot.CFrame * CFrame.new(0, 0, 3) 
                        
                        -- ATAQUE RÁPIDO
                        VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                        if AttackRemote then pcall(function() AttackRemote:FireServer() end) end
                        if ClickFunc then pcall(function() ClickFunc:InvokeServer(enemy) end) end
                        
                        -- Pequeno delay para registrar o hit
                        task.wait(0.15) 
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. BUFFER GLITCH (WEAPON) ]] --
-- ========================================== --
-- Tenta "Bufferizar" uma arma forte (Pré-carregar no slot)

AddToggle("🗡️ BUFFER WEAPON (GLITCH)", Color3.fromRGB(150, 0, 150), function(state)
    spawn(function()
        local BufferW = Remotes:FindFirstChild("BufferWeapon") --
        local EquipW = Remotes:FindFirstChild("EquipWeapon")
        
        while state do
            if BufferW then
                -- Tenta "Bufferizar" armas com IDs altos (possíveis armas de late game)
                -- ID 1 geralmente é fraca. Vamos tentar IDs aleatórios ou altos.
                pcall(function() BufferW:FireServer(999) end) 
                pcall(function() BufferW:FireServer(100) end)
            end
            
            -- Tenta equipar o que foi bufferizado
            if EquipW then
                pcall(function() EquipW:FireServer(999) end)
            end
            
            task.wait(1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. DAMAGE SPOOF (POSSÍVEL HIT KILL) ]] --
-- ========================================== --
-- Tenta usar o remote de visualização de dano para causar dano real
-- Alguns jogos mal feitos usam o mesmo remote para as duas coisas

AddToggle("🩸 FAKE DAMAGE (VISUAL -> REAL)", Color3.fromRGB(200, 0, 0), function(state)
    spawn(function()
        local ShowDmg = Remotes:FindFirstChild("ShowEnemyTakeDamageInfo") --
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            if ShowDmg and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local hum = enemy:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        -- Tenta enviar o pacote de dano
                        -- Argumentos comuns: (Inimigo, Dano, Critico, Tipo)
                        pcall(function() ShowDmg:FireServer(enemy, 999999, true) end)
                        pcall(function() ShowDmg:FireServer(enemy, 999999, true, 1) end)
                    end
                end
            end
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)