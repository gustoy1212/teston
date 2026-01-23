-- [[ SOLO LEVELING: GOD HUB V23 (MEATBALL MASSACRE) ]] --
-- Foco: Agrupar todos os mobs (Stack), Hitbox Gigante e Farm em Massa

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV23"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 5, 5) -- Vermelho Carne
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🥩 GOD HUB V23 (MEATBALL)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
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
-- [[ 1. MEATBALL FARM (STACK MOBS) ]] --
-- ========================================== --
-- Junta todos os mobs em um único ponto e aumenta o tamanho deles

AddToggle("🥩 ALMÔNDEGA (AGRUPAR TUDO)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if myRoot and EnemyFolder then
                -- Define o ponto de abate (na sua frente)
                local killZone = myRoot.CFrame * CFrame.new(0, 0, -5)
                
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        -- 1. HITBOX GIGANTE (Pra você nunca errar)
                        root.Size = Vector3.new(50, 50, 50)
                        root.Transparency = 0.8
                        root.CanCollide = false
                        root.Color = Color3.fromRGB(255, 0, 0)
                        
                        -- 2. TELEPORTA PRA KILLZONE (Stack)
                        root.CFrame = killZone
                        root.Velocity = Vector3.new(0,0,0) -- Tira inércia
                        root.RotVelocity = Vector3.new(0,0,0)
                        
                        -- 3. REMOVE COLISÃO DAS OUTRAS PARTES (Pra caber todos)
                        for _, part in pairs(enemy:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end
            task.wait() -- Atualiza a cada frame (super rápido) to keep them stuck
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. AUTO ATTACK (CLÁSSICO) ]] --
-- ========================================== --

AddToggle("⚔️ AUTO CLICK (SWING)", Color3.fromRGB(200, 0, 0), function(state)
    spawn(function()
        local VIM = game:GetService("VirtualInputManager")
        while state do
            -- Clica fisicamente (simula mouse)
            VIM:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait()
            VIM:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            task.wait(0.15)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. ANTI-LAG (DELETE MAP) ]] --
-- ========================================== --
-- Deleta o cenário para focar FPS no farm

AddButton("🗑️ DELETAR MAPA (FPS BOOST)", Color3.fromRGB(100, 100, 100), function()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name ~= "Enemys" and obj.Name ~= LocalPlayer.Name and not obj:IsA("Camera") then
            -- Tenta esconder ou destruir coisas que não são mobs nem players
            if obj:IsA("Model") or obj:IsA("BasePart") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end)

-- ========================================== --
-- [[ 4. ANIMATION SPEED (AJUDA O DPS) ]] --
-- ========================================== --

AddToggle("⚡ ANIMATION SPEED (50x)", Color3.fromRGB(0, 255, 255), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(50) 
                    end
                end
            end
            RunService.Heartbeat:Wait()
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 5. GOD MODE TEST (DATA EQUIP) ]] --
-- ========================================== --
-- Tenta equipar herói com dados modificados (Baseado na Log)

AddButton("🛡️ TENTAR GOD MODE (LOG)", Color3.fromRGB(255, 215, 0), function()
    local EquipData = game:GetService("ReplicatedStorage").Remotes:FindFirstChild("EquipHeroWithData")
    if EquipData then
        -- Envia dados falsos de vida/defesa
        local FakeData = {
            ["Health"] = 9999999,
            ["Defense"] = 9999999,
            ["Attack"] = 9999999
        }
        pcall(function() EquipData:FireServer(FakeData) end)
        pcall(function() EquipData:FireServer(1, FakeData) end)
    end
end)