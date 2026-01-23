--[[
    SBL REBORN - V5 MAP CLEANER (DELTA/MOBILE)
    
    FUNCIONALIDADES:
    1. Alcance Infinito: Puxa todos os NPCs do mapa.
    2. Fast Attack: Spamma o remote de ataque para maximizar o DPS.
    3. Multi-Hit: Junta todos os mobs num ponto só para matar todos de uma vez.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

getgenv().SBLMapCleaner = true

-- // REMOTES (Extraídos do Log) //
local Remotes = {
    Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"), -- [cite: 8]
    Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"), -- [cite: 3]
    Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"), -- [cite: 14]
}

-- // GUI NATIVA (PARA FUNCIONAR O CLIQUE NO DELTA) //
if CoreGui:FindFirstChild("SBLCleanerUI") then CoreGui.SBLCleanerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "SBLCleanerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 160)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0) -- Centralizado
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50) -- Vermelho Agressivo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "💀 MAP CLEANER V5"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.SourceSansBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.Text = "ATIVAR LOOP KILL"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE

-- // VARIÁVEIS DE CONTROLE //
local IsFarming = false

-- // LÓGICA DE INTERFACE //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SBLMapCleaner = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR LOOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Verde
        Status.Text = "🔥 PUXANDO TUDO..."
    else
        ToggleBtn.Text = "ATIVAR LOOP KILL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Vermelho
        Status.Text = "💤 AGUARDANDO"
    end
end)

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().SBLMapCleaner do
        if IsFarming then
            -- Otimização: Só roda se o player existir
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myRoot = char.HumanoidRootPart
                
                -- [[ 1. ATAQUE ULTRA RÁPIDO ]]
                -- Dispara o ataque múltiplas vezes para tentar burlar o delay visual
                task.spawn(function()
                    for i = 1, 3 do -- Tenta bater 3x por loop
                        pcall(function() Remotes.Hit:FireServer() end)
                    end
                end)

                -- [[ 2. AUTO SKILLS (TODAS) ]]
                task.spawn(function()
                    local skills = {"Z", "X", "C", "V"}
                    for _, k in pairs(skills) do
                        pcall(function() Remotes.Skill:FireServer(k) end)
                    end
                end)

                -- [[ 3. PUXAR O MAPA INTEIRO ]]
                -- Itera sobre a pasta NPCs 
                local mobFolder = Workspace:FindFirstChild("NPCs")
                if mobFolder then
                    for _, mob in pairs(mobFolder:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            
                            local mobRoot = mob.HumanoidRootPart
                            
                            -- LÓGICA DE PUXAR (BRING)
                            -- Coloca o mob 5 studs na frente do player.
                            -- Como o loop é muito rápido, isso mantém eles "presos" na sua frente.
                            mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5)
                            
                            -- TRAVA TOTAL DO MOB
                            mob.Humanoid.WalkSpeed = 0
                            mob.Humanoid.PlatformStand = true
                            
                            -- Remove colisão das partes do mob para caberem todos no mesmo lugar
                            for _, part in pairs(mob:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.Velocity = Vector3.new(0,0,0) -- Zera física
                                end
                            end
                        end
                    end
                end
            end
        end
        -- Velocidade do Loop: Quase instantâneo (RunService.Heartbeat seria mais rápido, mas task.wait() trava menos o celular)
        task.wait() 
    end
end)