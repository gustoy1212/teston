--[[
    🚑 SAO FLASH STEP v7 (KILL AURA CORRIGIDO + AUTO CLICK)
    
    CORREÇÃO CRÍTICA:
    - Agora o script "CLICA" sozinho (Tool Activate) para validar o dano.
    - O Kill Aura só funciona se a espada estiver balançando.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

getgenv().FlashStepSurvival = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AuraRange = 18,         -- Alcance (Reduzi para 18 para garantir que o hit conte)
    AttackSpeed = 10,       -- Velocidade do Spam de hits
    
    -- Movimento
    AttackDist = 7,         -- Distância para PARAR e bater (Tem que ser menor que o AuraRange)
    SearchRange = 3000,
    
    -- Sobrevivência
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
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🚑 AUTO FARM v7 (FIX)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
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
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
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

local function SetSprint(enable)
    if enable then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    else
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

-- // 🔥 KILL AURA CORRIGIDO //
local function DoKillAura()
    local char = LocalPlayer.Character
    if not char then return end
    
    local weapon = char:FindFirstChildOfClass("Tool")
    if not weapon then 
        -- Tenta equipar se não tiver arma na mão
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool")
            if tool then char.Humanoid:EquipTool(tool) end
        end
        return 
    end
    
    -- 1. FORÇA O ATAQUE (O boneco tem que balançar a espada)
    weapon:Activate()
    
    local handle = weapon:FindFirstChild("Middle") or weapon:FindFirstChild("Handle")
    if not handle then return end

    local folder = Workspace:FindFirstChild("Mobs")
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            local mHum = mob:FindFirstChild("Humanoid")
            local mRoot = mob:FindFirstChild("HumanoidRootPart")
            
            if mHum and mRoot and mHum.Health > 0 then
                local dist = (char.HumanoidRootPart.Position - mRoot.Position).Magnitude
                
                if dist <= SETTINGS.AuraRange then
                    -- 2. SPAM DE TOQUE (Se o executor suportar)
                    -- Isso conecta a hitbox da espada no bicho "magicamente"
                    if firetouchinterest then
                        for i=1, 3 do -- Tenta 3x por frame
                            firetouchinterest(handle, mRoot, 0)
                            firetouchinterest(handle, mRoot, 1)
                        end
                    end
                end
            end
        end
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
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepSurvival do
        -- Loop super rápido para combate fluido
        task.wait() 
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            -- Renascimento
            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                IsInEmergency = false
                task.wait(4)
                return
            end

            -- === 1. MODO EMERGÊNCIA ===
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            
            if IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    IsInEmergency = false 
                else
                    Status.Text = "🚑 FUGINDO..."
                    
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
                        local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                        MoveTo(myRoot.Position + (dir * 25))
                    else
                        StopMove()
                    end
                end

            -- === 2. COMBATE ===
            else
                -- Busca Alvo
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
                    -- Vai até o alvo e mata
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        -- Kill Aura Ativo sempre que tiver alvo
                        if dist <= SETTINGS.AuraRange then
                            Status.Text = "⚔️ BATENDO..."
                            StopMove() -- Para de andar pra bater melhor
                            DoKillAura()
                        else
                            Status.Text = "🏃 INDO ATÉ O ALVO..."
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        end
                    end
                end
            end
        end
    end
end)