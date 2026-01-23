-- [[ SOLO LEVELING: GOD HUB V17 (FLING DESTROYER) ]] --
-- Foco: Matar monstros arremessando eles (Physics Glitch)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV17"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🌪️ FLING DESTROYER"
Title.Size = UDim2.new(1, -30, 0.15, 0)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
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
Container.Size = UDim2.new(0.95, 0, 0.8, 0)
Container.Position = UDim2.new(0.025, 0, 0.15, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

-- FUNÇÃO UI
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
-- [[ 1. FLING (O LIQUIDIFICADOR) ]] --
-- ========================================== --

AddToggle("🌪️ ATIVAR FLING (MATAR TUDO)", Color3.fromRGB(255, 0, 0), function(state)
    local NoclipConn = nil
    
    if state then
        -- Ativa Noclip para você não sair voando
        NoclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
        
        spawn(function()
            local AngularVelocity = Instance.new("BodyAngularVelocity")
            AngularVelocity.P = math.huge
            AngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            AngularVelocity.AngularVelocity = Vector3.new(0, 99999, 0) -- Giro Infinito
            
            while state do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root then
                    -- Adiciona a força de giro se não tiver
                    if not root:FindFirstChild("BodyAngularVelocity") then
                        AngularVelocity:Clone().Parent = root
                    end
                    
                    -- Mantém a velocidade
                    local vel = root:FindFirstChild("BodyAngularVelocity")
                    if vel then vel.AngularVelocity = Vector3.new(0, 99999, 0) end
                    
                    -- Zera velocidade vertical pra não cair do mundo
                    root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                end
                task.wait()
                if not ScreenGui.Parent then break end
            end
            
            -- Limpeza ao desligar
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local vel = char.HumanoidRootPart:FindFirstChild("BodyAngularVelocity")
                if vel then vel:Destroy() end
                char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                char.HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect() end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local vel = char.HumanoidRootPart:FindFirstChild("BodyAngularVelocity")
            if vel then vel:Destroy() end
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            char.HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
        end
    end
end)

-- ========================================== --
-- [[ 2. IMÃ (TRAZ A VÍTIMA) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ DE MONSTROS (NECESSÁRIO)", Color3.fromRGB(150, 150, 150), function(state)
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
                        -- Traz MUITO perto (dentro de você) para o Fling pegar
                        root.Size = Vector3.new(5,5,5) 
                        root.CanCollide = true -- IMPORTANTE: Tem que colidir pro Fling funcionar
                        root.CFrame = myRoot.CFrame -- Cola no player
                        root.Velocity = Vector3.new(0,0,0)
                        
                        -- Limpa visual
                        for _, p in pairs(enemy:GetDescendants()) do
                            if p:IsA("BasePart") then p.Transparency = 0.5 end
                        end
                    end
                end
            end
            task.wait() -- Máxima velocidade
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. AUTO ATTACK (AUXILIAR) ]] --
-- ========================================== --

AddToggle("⚔️ AUTO ATTACK (AJUDA)", Color3.fromRGB(100, 100, 100), function(state)
    local VIM = game:GetService("VirtualInputManager")
    spawn(function()
        while state do
            VIM:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait()
            VIM:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)