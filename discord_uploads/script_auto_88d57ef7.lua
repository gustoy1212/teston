-- [[ SOLO LEVELING: GOD HUB V21 (SPEED & CRIT) ]] --
-- Foco: Acelerar Animação (DPS Real) e Headshots

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV21"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 5, 20) -- Azul Escuro Profundo
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚔️ GOD HUB V21 (SPEED GOD)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
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
-- [[ 1. ANIMATION GOD (SPEEDHACK ATK) ]] --
-- ========================================== --
-- Acelera a animação de ataque em 50x.
-- Se o dano é atrelado ao movimento, isso multiplica o DPS.

AddToggle("⚡ ANIMATION SPEED (DPS)", Color3.fromRGB(0, 255, 255), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    -- Pega todas as animações rodando agora
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        -- Acelera insanamente
                        track:AdjustSpeed(50) 
                    end
                end
            end
            -- Verifica a cada frame
            RunService.Heartbeat:Wait()
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. HEAD HUNTER (CRITICAL TP) ]] --
-- ========================================== --
-- Teleporta a espada direto na CABEÇA do monstro.
-- Cabeça = Crítico (Geralmente).

AddToggle("🎯 HEAD HUNTER (CRÍTICO)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox"))
            
            if handle and EnemyFolder then
                tool:Activate() -- Tenta atacar
                
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local head = enemy:FindFirstChild("Head") -- FOCA NA CABEÇA
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if head and hum and hum.Health > 0 then
                        if (head.Position - char.HumanoidRootPart.Position).Magnitude < 30 then
                            -- Teleporta a lâmina para dentro do cérebro do mob
                            handle.CFrame = head.CFrame
                            
                            -- Toque físico rápido
                            if firetouchinterest then
                                firetouchinterest(handle, head, 0)
                                RunService.Heartbeat:Wait()
                                firetouchinterest(handle, head, 1)
                            end
                        end
                    end
                end
            end
            task.wait()
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. CLONE HITBOX (DOUBLE HIT) ]] --
-- ========================================== --
-- Cria uma parte fake que segue a espada para tentar dar hit duplo

AddToggle("👥 CLONE HITBOX (x2 HIT)", Color3.fromRGB(200, 0, 200), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox"))
            
            if handle and not handle:FindFirstChild("FakeHitbox") then
                -- Cria o clone
                local fake = handle:Clone()
                fake.Name = "FakeHitbox"
                fake.Parent = handle
                fake.Size = handle.Size * 1.5 -- Um pouco maior
                fake.Transparency = 0.5
                fake.Color = Color3.fromRGB(255, 0, 0)
                fake.CanCollide = false
                
                -- Solda na espada original
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = handle
                weld.Part1 = fake
                weld.Parent = fake
                
                -- Se tiver touch script, tenta ativar
                fake.Touched:Connect(function() end) 
            end
            task.wait(1)
            if not ScreenGui.Parent then break end
        end
        
        -- Limpa ao desligar
        local char = LocalPlayer.Character
        for _, v in pairs(char:GetDescendants()) do
            if v.Name == "FakeHitbox" then v:Destroy() end
        end
    end)
end)

-- ========================================== --
-- [[ 4. IMÃ DE MONSTROS (MANTIDO) ]] --
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
                        root.Size = Vector3.new(20,20,20)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-4)
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
-- [[ 5. AUTO CLICK (SWING) ]] --
-- ========================================== --

AddToggle("🖱️ AUTO CLICK (RÁPIDO)", Color3.fromRGB(0, 255, 100), function(state)
    local VIM = game:GetService("VirtualInputManager")
    spawn(function()
        while state do
            VIM:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait() -- Mínimo delay possível
            VIM:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            task.wait(0.01)
            if not ScreenGui.Parent then break end
        end
    end)
end)