-- [[ SOLO LEVELING: GOD HUB V9 (ADMIN & UNLOCKER) ]] --
-- Foco: Ativar Admin, Desbloquear Armas/Heróis e Bugar Rank de Boss

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV9"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 20) -- Verde Hacker
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "💻 GOD HUB V9 (ADMIN)"
Title.Size = UDim2.new(1, -30, 0.1, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
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

-- FUNÇÃO BOTÃO
local function AddButton(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(callback)
end

-- ========================================== --
-- [[ 1. ADMIN PRIVILEGE ]] --
-- ========================================== --
-- Tenta ativar modo de desenvolvedor/admin

AddButton("💻 ATIVAR PRIVILÉGIO ADMIN", Color3.fromRGB(0, 200, 0), function()
    local SetPriv = Remotes:FindFirstChild("SetPrivilegeEnabled") -- 
    
    if SetPriv then
        -- Tenta várias combinações comuns de ativação
        pcall(function() SetPriv:InvokeServer(true) end)
        pcall(function() SetPriv:InvokeServer(1) end)
        pcall(function() SetPriv:InvokeServer("Admin") end)
        pcall(function() SetPriv:InvokeServer("Developer") end)
        pcall(function() SetPriv:FireServer(true) end) -- Caso seja evento disfarçado
    end
end)

-- ========================================== --
-- [[ 2. ITEM & HERO UNLOCKER ]] --
-- ========================================== --
-- Tenta desbloquear armas e heróis enviando IDs de 1 a 100

AddButton("🔓 DESBLOQUEAR ARMAS/HERÓIS (SPAM)", Color3.fromRGB(0, 150, 255), function()
    local UnlockW = Remotes:FindFirstChild("UnlockWeapon") -- 
    local UnlockH = Remotes:FindFirstChild("UnlockHero")   -- 
    local UnlockR = Remotes:FindFirstChild("UnlockRaidsLevel") -- 
    local UnlockResp = Remotes:FindFirstChild("UnlockRespiration") -- 
    
    spawn(function()
        -- Tenta IDs de 1 a 50 (Geralmente os IDs de itens são sequenciais)
        for i = 1, 50 do
            if UnlockW then pcall(function() UnlockW:FireServer(i) end) end
            if UnlockH then pcall(function() UnlockH:InvokeServer(i) end) end
            if UnlockR then pcall(function() UnlockR:FireServer(i) end) end
            if UnlockResp then pcall(function() UnlockResp:FireServer(i) end) end
            
            -- Tenta enviar tabelas (alguns jogos pedem dados do item)
            if UnlockW then pcall(function() UnlockW:FireServer({["Id"] = i}) end) end
            
            if i % 10 == 0 then task.wait(0.1) end -- Pausa pra não cair
        end
    end)
end)

-- ========================================== --
-- [[ 3. RESPIRATION GOD (STATUS) ]] --
-- ========================================== --
-- Tenta aumentar o nível da sua Respiração (Buff)

AddButton("💨 MAXIMIZAR RESPIRAÇÃO (BUFF)", Color3.fromRGB(255, 255, 0), function()
    local UpdateResp = Remotes:FindFirstChild("UpdateRespirationAddtion") -- 
    local UpdateResp2 = Remotes:FindFirstChild("UpdateRespiration") -- 
    
    if UpdateResp then
        -- Tenta enviar valores altos
        pcall(function() UpdateResp:FireServer(99999) end)
        pcall(function() UpdateResp:FireServer({["Level"] = 999, ["Exp"] = 99999}) end)
    end
    
    if UpdateResp2 then
         pcall(function() UpdateResp2:FireServer() end)
    end
end)

-- ========================================== --
-- [[ 4. WORLD BOSS RANK SPOOF ]] --
-- ========================================== --
-- Tenta dizer pro servidor que você deu 1 Bilhão de dano no Boss

AddButton("🏆 BUGAR RANK BOSS (TOP 1)", Color3.fromRGB(255, 50, 50), function()
    local BossRank = Remotes:FindFirstChild("UpdateWorldBossDamageRank") -- 
    local GarrisonRank = Remotes:FindFirstChild("GainGarrisonBossRankRewards") -- 
    
    if BossRank then
        -- Envia dano falso
        pcall(function() BossRank:FireServer(999999999) end)
    end
    
    if GarrisonRank then
        -- Tenta pegar recompensa direto
        pcall(function() GarrisonRank:FireServer() end)
    end
end)

-- ========================================== --
-- [[ 5. IMÃ (SUPORTE) ]] --
-- ========================================== --

local MagnetEnabled = false
AddButton("🧲 IMÃ INVISÍVEL (LIGAR/DESLIGAR)", Color3.fromRGB(100, 100, 100), function()
    MagnetEnabled = not MagnetEnabled
    if MagnetEnabled then
        spawn(function()
            local EnemyFolder = Workspace:FindFirstChild("Enemys")
            while MagnetEnabled do
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
    end
end)