-- [[ SOLO LEVELING: GOD HUB V22 (PARASITE) ]] --
-- Foco: Roubar Skills dos outros, Roubar Itens do Server e Backstab

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV22"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 5) -- Amarelo Toxico
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(200, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "☣️ GOD HUB V22 (PARASITA)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(200, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
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
-- [[ 1. PROJECTILE STEAL (ROUBAR DANO) ]] --
-- ========================================== --
-- Pega qualquer coisa com "TouchInterest" que NÃO seja sua
-- e teleporta para os monstros perto de você.

AddToggle("🔥 ROUBAR MAGIAS (KILL STEAL)", Color3.fromRGB(255, 100, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        
        while state do
            local myChar = LocalPlayer.Character
            local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
            
            if myPos and EnemyFolder then
                -- Procura projéteis/skills no Workspace
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj.Name ~= "Terrain" then
                        -- Verifica se é algo que dá dano (tem TouchInterest)
                        if obj:FindFirstChild("TouchInterest") then
                            -- Verifica se NÃO é seu (evita bugar sua arma)
                            if not obj:IsDescendantOf(myChar) and not obj:IsDescendantOf(EnemyFolder) then
                                
                                -- Acha um inimigo perto de você para jogar a magia nele
                                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                                    local root = enemy:FindFirstChild("HumanoidRootPart")
                                    local hum = enemy:FindFirstChild("Humanoid")
                                    
                                    if root and hum and hum.Health > 0 then
                                        if (root.Position - myPos).Magnitude < 40 then
                                            -- TELEPORTA A MAGIA DO OUTRO CARA PRO SEU INIMIGO
                                            obj.CFrame = root.CFrame
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.05) -- Muito rápido
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. REPLICATED STEAL (CLONAR ITENS) ]] --
-- ========================================== --
-- Procura ferramentas escondidas no jogo e te dá.

AddButton("🗡️ ROUBAR ITENS DO JOGO (CLONE)", Color3.fromRGB(0, 200, 255), function()
    local count = 0
    -- Varre ReplicatedStorage procurando Tools
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Tool") then
            -- Clona para sua mochila
            local clone = obj:Clone()
            clone.Parent = LocalPlayer.Backpack
            count = count + 1
        end
    end
    -- Varre Workspace também (itens no chão?)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and not obj.Parent:FindFirstChild("Humanoid") then
             local clone = obj:Clone()
             clone.Parent = LocalPlayer.Backpack
             count = count + 1
        end
    end
end)

-- ========================================== --
-- [[ 3. BACKSTAB AURA (COSTAS) ]] --
-- ========================================== --
-- Teleporta para trás do inimigo para bônus de dano.

AddToggle("🔪 BACKSTAB TP (CRÍTICO)", Color3.fromRGB(200, 0, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:WaitForChild("Enemys")
        local VIM = game:GetService("VirtualInputManager")
        
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    if not state then break end
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if eroot and hum and hum.Health > 0 then
                        -- Pega a posição das COSTAS (CFrame * CFrame.new(0,0,3))
                        local backPos = eroot.CFrame * CFrame.new(0, 0, 3)
                        
                        -- Teleporta
                        root.CFrame = CFrame.new(backPos.Position, eroot.Position) -- Olha pro inimigo
                        
                        -- Bate
                        VIM:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                        task.wait(0.1)
                        VIM:SendMouseButtonEvent(500, 500, 0, false, game, 1)
                        
                        task.wait(0.1) 
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. QUIRK SPAM (PASSIVA) ]] --
-- ========================================== --
-- Tenta ganhar habilidade passiva na sorte

AddToggle("⚡ QUIRK GLITCH (PASSIVA)", Color3.fromRGB(255, 255, 0), function(state)
    spawn(function()
        local Quirk = ReplicatedStorage.Remotes:FindFirstChild("InheritWeaponQuirk") --
        while state do
            if Quirk then
                pcall(function() Quirk:FireServer() end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)