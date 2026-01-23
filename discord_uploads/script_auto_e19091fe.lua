-- [[ SOLO LEVELING: GOD HUB V10 (LOGIC BREAKER) ]] --
-- Foco: Completar Missões, Editar Arma e Validação de Ataque

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV10"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo Quest
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "📜 GOD HUB V10 (LOGIC)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
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
-- [[ 1. QUEST SHREDDER (FINISH TASK) ]] --
-- ========================================== --
-- Tenta completar todas as missões (IDs 1-500)

AddToggle("📜 COMPLETAR MISSÕES (SPAM)", Color3.fromRGB(255, 200, 0), function(state)
    spawn(function()
        local Finish = Remotes:FindFirstChild("FinishTask") -- 
        local Receive = Remotes:FindFirstChild("ReceiveTask") -- 
        
        while state do
            if Finish then
                -- Tenta completar IDs sequenciais (Missões costumam ser ID 1, 2, 3...)
                for i = 1, 50 do
                    pcall(function() Finish:FireServer(i) end)
                    -- Tenta receber a próxima também
                    if Receive then pcall(function() Receive:FireServer(i) end) end
                end
            end
            task.wait(1) -- Delay para não crashar por excesso de requests
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. WEAPON EDITOR (UPDATE WEAPON) ]] --
-- ========================================== --
-- Tenta modificar os status da arma equipada

AddButton("⚔️ BUGAR ARMA (UPDATE)", Color3.fromRGB(255, 50, 0), function()
    local UpdateW = Remotes:FindFirstChild("UpdateWeapon") -- 
    local EquipW = Remotes:FindFirstChild("EquipWeapon") -- 
    
    if UpdateW then
        -- Envia dados falsos de arma
        local fakeWeaponData = {
            ["Level"] = 999,
            ["Damage"] = 999999999,
            ["Quirk"] = "GodMode"
        }
        -- Tenta enviar para "todas" as armas ou a atual
        pcall(function() UpdateW:FireServer(fakeWeaponData) end)
        -- Tenta enviar com ID 1 (arma inicial)
        pcall(function() UpdateW:FireServer(1, fakeWeaponData) end)
    end
    
    -- Tenta equipar uma arma inexistente/bugada
    if EquipW then
        pcall(function() EquipW:FireServer(9999) end)
    end
end)

-- ========================================== --
-- [[ 3. TRUE ATTACK (CLICK ENEMY) ]] --
-- ========================================== --
-- Usa o ClickEnemy (RemoteFunction) para validar o hit

AddToggle("🎯 TRUE ATTACK (AUTO CLICK)", Color3.fromRGB(200, 0, 0), function(state)
    spawn(function()
        local ClickFunc = Remotes:FindFirstChild("ClickEnemy") -- 
        local AttackEvent = Remotes:FindFirstChild("PlayerClickAttack")
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and EnemyFolder and ClickFunc then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local eroot = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if eroot and hum and hum.Health > 0 then
                        -- Verifica distância (ataque só funciona de perto)
                        if (eroot.Position - root.Position).Magnitude < 20 then
                            
                            -- AQUI ESTÁ O TRUQUE: Invocar a função primeiro!
                            -- O jogo pode esperar que essa função retorne "True" para validar o dano
                            spawn(function()
                                pcall(function() ClickFunc:InvokeServer(enemy) end)
                                -- Depois dispara o evento visual
                                if AttackEvent then AttackEvent:FireServer(enemy) end
                            end)
                        end
                    end
                end
            end
            task.wait(0.1) -- Velocidade rápida
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 4. FERRAMENTAS EXTRAS ]] --
-- ========================================== --

AddButton("🗺️ DESBLOQUEAR MAPAS", Color3.fromRGB(0, 150, 255), function()
    local UnlockMap = Remotes:FindFirstChild("UnlockMap") -- 
    local CheckMap = Remotes:FindFirstChild("CheckIsUnlockMap") -- 
    
    if UnlockMap then
        for i=1, 20 do
            pcall(function() UnlockMap:InvokeServer(i) end)
            pcall(function() UnlockMap:FireServer(i) end)
        end
    end
end)

AddToggle("🧲 IMÃ INVISÍVEL", Color3.fromRGB(100, 100, 100), function(state)
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
                        root.Size = Vector3.new(30,30,30)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-5)
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