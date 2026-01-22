--[[
    🚑 SAO FLASH STEP v6 (KILL AURA + SURVIVAL)
    
    NOVIDADES:
    1. KILL AURA: Ataca mobs próximos sem precisar clicar/encostar.
    2. BURST DAMAGE: Tenta dar vários hits por segundo para simular "Insta-Kill".
    3. DETECÇÃO POR LOG: Usa a parte "Middle" da espada para o hit (baseado nos seus logs).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepSurvival = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate (Kill Aura)
    AuraRange = 25,         -- Alcance do Kill Aura (não exagere acima de 30)
    AttackSpeed = 5,        -- Quantos hits falsos por ciclo (Isso simula o Insta-Kill. Cuidado com crash)
    
    -- Movimento
    AttackDist = 8,         -- Distância para ficar perto do mob (para pegar drop)
    SprintDist = 15,
    SearchRange = 3000,
    
    -- Sobrevivência (Vida)
    LowHealthPercent = 25,  
    FullHealthPercent = 90, 
    SafetyDist = 50,        
}

-- Estados
local IsRunning = false
local IsInEmergency = false 
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashSurvUI") then CoreGui.FlashSurvUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashSurvUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 180)
MainFrame.Position = UDim2.new(0.5, -160, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(80, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🚑 KILL AURA + SURVIVAL"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Aguardando..."
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
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "ATIVAR AUTO FARM"
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

local function SetSprint(enable)
    if enable then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    else
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- // 🔥 NOVA FUNÇÃO: KILL AURA (Baseado no Log) //
local function DoKillAura()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Procura a Espada e a parte "Middle" (que apareceu no log)
    local weapon = char:FindFirstChildOfClass("Tool")
    if not weapon then return end
    
    local handle = weapon:FindFirstChild("Middle") or weapon:FindFirstChild("Handle")
    if not handle then return end -- Se não achar a parte da espada, não faz nada

    -- Procura mobs perto
    local folder = Workspace:FindFirstChild("Mobs")
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            local mHum = mob:FindFirstChild("Humanoid")
            local mRoot = mob:FindFirstChild("HumanoidRootPart")
            
            if mHum and mRoot and mHum.Health > 0 then
                local dist = (char.HumanoidRootPart.Position - mRoot.Position).Magnitude
                
                if dist <= SETTINGS.AuraRange then
                    -- 🔥 MÁGICA: Toca a espada no mob remotamente
                    -- Repete várias vezes para simular Insta-Kill (Burst)
                    for i = 1, SETTINGS.AttackSpeed do
                        if firetouchinterest then
                            firetouchinterest(handle, mRoot, 0) -- Toca
                            firetouchinterest(handle, mRoot, 1) -- Solta
                        end
                    end
                end
            end
        end
    end
    
    -- Ataque visual (animação) pra não parecer suspeito
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            VirtualInputManager:SendTouchEvent(999, 0, btn.AbsolutePosition.X, btn.AbsolutePosition.Y, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, btn.AbsolutePosition.X, btn.AbsolutePosition.Y, 0, false, game, 1)
        end
    end
end

-- // AUTO EQUIPAR ESPADA //
local function AutoEquip()
    local char = LocalPlayer.Character
    if not char then return end
    if char:FindFirstChildOfClass("Tool") then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then char.Humanoid:EquipTool(tool) end
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepSurvival = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "ATIVAR AUTO FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepSurvival do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            -- Lógica de Renascimento
            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                IsInEmergency = false
                task.wait(4)
                return
            end
            
            AutoEquip()

            -- === 1. MODO EMERGÊNCIA (PRIORIDADE MÁXIMA) ===
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            
            if IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    IsInEmergency = false 
                else
                    Status.Text = "🚑 FUGINDO (Recuperando Vida)..."
                    
                    -- Foge do mob mais próximo
                    local folder = Workspace:FindFirstChild("Mobs")
                    local dangerMob, closestDist = nil, 9999
                    
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < closestDist then closestDist = dist dangerMob = mob end
                            end
                        end
                    end
                    
                    SetSprint(true)
                    if dangerMob and closestDist < SETTINGS.SafetyDist then
                        -- Corre para longe
                        local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                        MoveTo(myRoot.Position + (dir * 25))
                    else
                        StopMove() -- Fica quieto pra regenerar
                    end
                end

            -- === 2. MODO CAÇA E KILL AURA (NORMAL) ===
            else
                -- Executa Kill Aura SEMPRE que não estiver fugindo
                DoKillAura() 
                
                -- Busca de Alvo para MOVER ATÉ ELE (para pegar drops)
                if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
                    Status.Text = "🔎 PROCURANDO..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    if folder then
                        local closest, minDist = nil, SETTINGS.SearchRange
                        for _, mob in ipairs(folder:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            if mHum and mRoot and mHum.Health > 0 then
                                local dist = (myRoot.Position - mRoot.Position).Magnitude
                                if dist < minDist then minDist = dist closest = mob end
                            end
                        end
                        CurrentTarget = closest
                    end
                else
                    -- Move até o alvo
                    Status.Text = "⚔️ ANIQUILANDO..."
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        -- Não precisa colar no mob se o Aura já mata, mas vamos perto pra pegar drop
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            StopMove() -- Já tá no range, deixa o Kill Aura trabalhar
                        end
                    end
                end
            end
        end
    end
end)