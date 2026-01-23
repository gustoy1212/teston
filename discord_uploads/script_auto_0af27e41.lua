--[[
    SBL REBORN - SURVIVAL AUTO FARM
    Baseado no estilo SAO Flash Step v5
    
    LÓGICA:
    1. Traz mobs para perto (Bring Mobs) para não precisar correr pelo mapa.
    2. Ataca com Skills e Hits.
    3. Se Vida < 30%: Para de atacar e ativa "Modo Fuga" (afasta os mobs).
    4. Auto Equip e Auto Stats inclusos.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

getgenv().SBLSurvival = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 15,       -- Distância para bater
    BringDist = 300,       -- Raio para puxar mobs
    
    -- Sobrevivência
    LowHealthPercent = 30,  -- Foge se vida < 30%
    FullHealthPercent = 85, -- Volta se vida > 85%
    
    -- Status
    StatToUp = "Melee",     -- Status para upar (Melee, Defense, Sword, Fruit)
}

-- Estados
local IsRunning = false
local IsInEmergency = false -- Estado de fuga

-- REMOTES (Do seu Log)
local Remotes = {
    Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"),
    Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"),
    Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"),
}

-- // GUI SETUP //
if CoreGui:FindFirstChild("SBLSurvUI") then CoreGui.SBLSurvUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
-- Tenta usar gethui para executores modernos, senão CoreGui
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "SBLSurvUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180) -- Um pouco maior
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Laranja (Tema SBL)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🔥 SBL SURVIVAL FARM"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local HealthLabel = Instance.new("TextLabel", MainFrame)
HealthLabel.Size = UDim2.new(1, 0, 0, 30)
HealthLabel.Position = UDim2.new(0, 0, 0.35, 0)
HealthLabel.Text = "Vida: 100%"
HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HealthLabel.BackgroundTransparency = 1
HealthLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

local function AutoEquip()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Procura ferramenta no backpack se não tiver nada equipado
    if not char:FindFirstChildOfClass("Tool") then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool") -- Pega qualquer arma (Katana/Combat)
            if tool then
                char.Humanoid:EquipTool(tool)
            end
        end
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SBLSurvival = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
        IsInEmergency = false
        Status.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().SBLSurvival do
        task.wait(0.1) -- Loop rápido mas não trava o jogo
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            
            -- 1. MONITOR DE VIDA
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            -- Cores do indicador
            if hpPercent <= 30 then HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            elseif hpPercent <= 60 then HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end

            -- Verifica morte
            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                IsInEmergency = false
                task.wait(4)
                return
            end

            -- Auto Equipar Arma (Essencial no SBL)
            AutoEquip()

            -- Auto Stats (Simples)
            pcall(function() Remotes.Stats:FireServer(SETTINGS.StatToUp, 1) end)

            -- === LÓGICA DE SOBREVIVÊNCIA ===
            if hpPercent < SETTINGS.LowHealthPercent then
                IsInEmergency = true
            elseif hpPercent >= SETTINGS.FullHealthPercent then
                IsInEmergency = false
            end

            if IsInEmergency then
                Status.Text = "🚑 VIDA CRÍTICA! AFASTANDO MOBS..."
                
                -- Em vez de fugir (o mapa é grande), empurramos os mobs para longe
                for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                    if mob:FindFirstChild("HumanoidRootPart") and (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude < 50 then
                        -- Joga o mob pra longe visualmente para ele não te bater
                        mob.HumanoidRootPart.CFrame = myRoot.CFrame * CFrame.new(0, 100, 0) -- Manda pro céu temporariamente
                    end
                end
                
            else
                -- === LÓGICA DE FARM (BRING + KILL) ===
                Status.Text = "⚔️ FARMANDO..."
                
                -- Usa skills a cada ciclo se disponível
                local skills = {"Z", "X", "C", "V"}
                for _, key in ipairs(skills) do
                    pcall(function() Remotes.Skill:FireServer(key) end)
                end

                -- Loop nos Mobs
                for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                        local mobRoot = mob.HumanoidRootPart
                        local dist = (myRoot.Position - mobRoot.Position).Magnitude
                        
                        -- Puxa mobs próximos
                        if dist < SETTINGS.BringDist then
                            -- Traz pra frente (Bring)
                            mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
                            
                            -- Trava movimento do mob
                            mob.Humanoid.WalkSpeed = 0
                            mob.Humanoid.PlatformStand = true
                            
                            -- Remove colisão
                            for _, p in pairs(mob:GetChildren()) do
                                if p:IsA("BasePart") then p.CanCollide = false end
                            end

                            -- Bate
                            pcall(function() Remotes.Hit:FireServer() end)
                        end
                    end
                end
            end
        end
    end
end)