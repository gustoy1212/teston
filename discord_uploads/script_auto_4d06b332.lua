-- [[ SOLO LEVELING: GOD HUB V2 (FIXED) ]] --
-- Correção: Teleporte para pegar moedas Fixas + Interação com Chaves

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "SoloLevelingGodHubV2"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja Lendário
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "👑 GOD HUB V2 (COIN FIX)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.95, 0, 0.8, 0)
Container.Position = UDim2.new(0.025, 0, 0.15, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

-- FUNÇÃO BOTÃO
local function AddToggle(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text .. " [OFF]"
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextWrapped = true
    
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

-- VARIÁVEIS DO JOGO
local EnemyFolder = Workspace:FindFirstChild("Enemys")
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("PlayerClickAttack")

-- 1. IMÃ DE MONSTROS (Mantido pq funcionou)
AddToggle("🧲 IMÃ DE MONSTROS (ATK)", Color3.fromRGB(255, 50, 50), function(state)
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.CFrame
                if EnemyFolder then
                    for _, enemy in pairs(EnemyFolder:GetChildren()) do
                        local root = enemy:FindFirstChild("HumanoidRootPart")
                        local hum = enemy:FindFirstChild("Humanoid")
                        if root and hum and hum.Health > 0 then
                            -- Puxa o monstro para a morte
                            root.Size = Vector3.new(40, 40, 40) 
                            root.Transparency = 0.8
                            root.CanCollide = false
                            root.CFrame = myPos * CFrame.new(0, 0, -6)
                            root.Velocity = Vector3.new(0,0,0)
                        end
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 2. AUTO ATTACK (Mantido)
AddToggle("⚔️ AUTO-ATTACK", Color3.fromRGB(150, 0, 0), function(state)
    spawn(function()
        while state do
            pcall(function()
                if AttackRemote then AttackRemote:FireServer() end
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            end)
            task.wait(0.2)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 3. NECROMANCER (Mantido)
AddToggle("💀 AUTO ERGA-SE / DESTRUIR", Color3.fromRGB(100, 0, 200), function(state)
    spawn(function()
        while state do
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local txt = prompt.ActionText:upper()
                    -- Pega tudo: Levantar, Destruir, Pegar Chave, Abrir Baú
                    if txt:find("LEVANTAR") or txt:find("DESTRUIR") or txt:find("E") or txt:find("R") then
                        prompt.MaxActivationDistance = 9e9
                        prompt.RequiresLineOfSight = false
                        prompt.HoldDuration = 0
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end
                end
            end
            task.wait(0.3)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 4. COLETOR DE MOEDAS (NOVO: TP FARM)
-- Esse aqui vai teleportar VOCÊ até a moeda se ela for fixa
AddToggle("💰 TP FARM (MOEDAS FIXAS)", Color3.fromRGB(255, 215, 0), function(state)
    spawn(function()
        local LootNames = {"Gold", "Coin", "Moeda", "Drop"} 
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                local oldPos = root.CFrame -- Salva onde você estava (Base)
                
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if not state then break end
                    
                    if obj:IsA("BasePart") and obj.Transparency < 1 then
                        local isLoot = false
                        -- Verifica nome
                        for _, name in pairs(LootNames) do
                            if obj.Name:find(name) or (obj.Parent and obj.Parent.Name:find(name)) then
                                isLoot = true break
                            end
                        end
                        
                        -- Se for moeda e tiver TouchInterest (mesmo ancorada)
                        if isLoot and obj:FindFirstChild("TouchInterest") then
                            -- TELEPORTA LÁ
                            root.CFrame = obj.CFrame
                            task.wait(0.1) -- Tempo para coletar
                        end
                    end
                end
                
                -- Volta para a base (segurança)
                if oldPos then root.CFrame = oldPos end
            end
            task.wait(1) -- Espera um pouco antes de varrer de novo
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 5. INTERAGIR COM ACESSÓRIOS (CHAVES/BAUS)
-- Em vez de puxar a chave (que buga), a gente clica nela de longe
AddToggle("🔑 INTERAGIR ITENS (CHAVE/BAÚ)", Color3.fromRGB(0, 255, 100), function(state)
    spawn(function()
        while state do
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local parentName = prompt.Parent and prompt.Parent.Name:upper() or ""
                    -- Foca em Chaves, Baús, Portas
                    if parentName:find("KEY") or parentName:find("CHAVE") or parentName:find("CHEST") or parentName:find("BAU") then
                        prompt.MaxActivationDistance = 9e9
                        prompt.RequiresLineOfSight = false
                        prompt.HoldDuration = 0
                        if fireproximityprompt then fireproximityprompt(prompt) end
                    end
                end
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)