-- [[ SOLO LEVELING: GOD HUB V3 (LOG UPDATE) ]] --
-- Novidades: Instant Win, Auto Chest (Sem Chave) e Sell Hack

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV3"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Tech
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "⚡ GOD HUB V3 (INSTANT WIN)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

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
-- [[ NOVAS FUNÇÕES (BASEADO NO LOG 2) ]] --
-- ========================================== --

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- 1. INSTANT WIN (O Santo Graal)
-- Tenta dizer ao jogo que você venceu a Raid/Boss
AddButton("🏆 FORÇAR VITÓRIA (RAID/BOSS)", Color3.fromRGB(255, 215, 0), function()
    local SuccessRemotes = {
        Remotes:FindFirstChild("ChallengeRaidsSuccess"),        -- [Source: 357]
        Remotes:FindFirstChild("ChallengeGarrisonBossSuccess"), -- [Source: 356]
        Remotes:FindFirstChild("MapBossEscapeFinish"),          -- [Source: 405]
        Remotes:FindFirstChild("TowerEnterNextLevel")           -- [Source: 349]
    }
    
    for _, remote in pairs(SuccessRemotes) do
        if remote then
            -- Tenta enviar vazio ou com argumentos padrão (1, true, etc)
            pcall(function() remote:FireServer() end)
            pcall(function() remote:FireServer(true) end)
            pcall(function() remote:FireServer(1) end)
        end
    end
end)

-- 2. AUTO CHEST (Sem Chave)
-- Usa o OpenAntiqueBox direto no baú
AddToggle("📦 AUTO ABRIR BAÚS (REMOTE)", Color3.fromRGB(0, 200, 100), function(state)
    spawn(function()
        while state do
            local OpenRemote = Remotes:FindFirstChild("OpenAntiqueBox") -- [Source: 493]
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Procura por Baús
                if obj.Name:find("Chest") or obj.Name:find("Box") or obj.Name:find("Bau") then
                    if OpenRemote then
                        -- Tenta abrir remotamente (enviando o objeto)
                        pcall(function() OpenRemote:FireServer(obj) end)
                        pcall(function() OpenRemote:FireServer(obj.Parent) end)
                    end
                    
                    -- Tenta também via ProximityPrompt (Interação)
                    if obj:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(obj.ProximityPrompt)
                    end
                end
            end
            task.wait(1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 3. SELL SPAM (Teste de Dinheiro)
AddToggle("💰 VENDER ITENS (SPAM)", Color3.fromRGB(150, 50, 50), function(state)
    spawn(function()
        local SellRemote = Remotes:FindFirstChild("SellItem") -- [Source: 555]
        while state do
            if SellRemote then
                -- Tenta vender "nada" ou itens genéricos
                -- CUIDADO: Pode vender coisas do inventário se o ID for 1, 2, 3...
                -- Teste com segurança primeiro
                pcall(function() SellRemote:FireServer() end)
            end
            task.wait(0.5)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 4. IMÃ DE MONSTROS (O Clássico que funciona)
AddToggle("🧲 IMÃ DE MONSTROS", Color3.fromRGB(255, 50, 50), function(state)
    local EnemyFolder = Workspace:FindFirstChild("Enemys")
    spawn(function()
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    if eroot and hum and hum.Health > 0 then
                        eroot.Size = Vector3.new(40,40,40)
                        eroot.Transparency = 0.8
                        eroot.CanCollide = false
                        eroot.CFrame = root.CFrame * CFrame.new(0,0,-6)
                        eroot.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- 5. AUTO ATTACK + SKILL
AddToggle("⚔️ AUTO ATTACK + SKILL", Color3.fromRGB(150, 0, 0), function(state)
    spawn(function()
        while state do
            local Attack = Remotes:FindFirstChild("PlayerClickAttack")
            local Skill = Remotes:FindFirstChild("PlayerClickAttackSkill") -- [Source: 174]
            local Resp = Remotes:FindFirstChild("PlayerRespirationSkillAttack") -- [Source: 323]
            
            pcall(function() Attack:FireServer() end)
            pcall(function() Skill:FireServer() end)
            pcall(function() Resp:FireServer() end)
            
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(500, 500, 0, false, game, 1)
            
            task.wait(0.15)
            if not ScreenGui.Parent then break end
        end
    end)
end)