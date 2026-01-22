--[[
    🚑 SAO FLASH STEP v9 (SMART AI - FINAL LEGIT)
    
    BASEADO NA v5 (QUE FUNCIONOU PERFEITAMENTE)
    + MELHORIAS DE INTELIGÊNCIA DOS LOGS:
    
    1. LEITURA DE CONFIG: Lê 'AttackRange' e 'DetectionRange' direto do mob.
    2. SMART EVASION: Foge para fora da área de detecção do mob (não corre à toa).
    3. LOOT SNIPER: Prioriza mobs que têm drops de raridade alta na config.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepSurvival = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 6,
    BehindDist = 5,
    SprintDist = 12,
    SearchRange = 3000,
    
    -- Sobrevivência (Vida)
    LowHealthPercent = 25,  
    FullHealthPercent = 90, 
    DefaultSafetyDist = 45, -- Usado se não achar a config do mob
}

-- Estados
local IsRunning = false
local IsSprinting = false
local IsInEmergency = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashSurvUI") then CoreGui.FlashSurvUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashSurvUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 20) -- Azul Noturno (Smart)
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧠 FLASH STEP (SMART v9)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "LIGAR I.A."
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES INTELIGENTES (DOS LOGS) //

-- Lê a config oculta do mob para saber o alcance exato
local function GetMobStats(mob)
    local range = SETTINGS.DefaultSafetyDist
    local isRare = false
    
    if mob:FindFirstChild("Config") then
        -- Pega alcance de detecção (pra fugir com segurança)
        if mob.Config:FindFirstChild("DetectionRange") then
            range = mob.Config.DetectionRange.Value + 10 -- Margem de segurança
        elseif mob.Config:FindFirstChild("AttackRange") then
            range = mob.Config.AttackRange.Value + 15
        end
        
        -- Checa se tem drop raro
        if mob.Config:FindFirstChild("MaxDrops") then
            for _, item in pairs(mob.Config.MaxDrops:GetChildren()) do
                if item:FindFirstChild("Rarity") and item.Rarity.Value >= 2 then
                    isRare = true -- Prioridade!
                end
            end
        end
    end
    return range, isRare
end

-- // FUNÇÕES DE CONTROLE //

local function SetSprint(enable)
    if enable then
        if not IsSprinting then
            IsSprinting = true
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        end
    else
        if IsSprinting then
            IsSprinting = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
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

-- Ataque Original (V5) - O único que funciona 100%
local function Attack()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

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
    SetSprint(false)
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR I.A."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepSurvival do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            if hpPercent <= 30 then HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0) else HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end

            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                IsInEmergency = false
                task.wait(4)
                return
            end

            AutoEquip()

            -- === LOGICA DE EMERGÊNCIA ===
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            
            if IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    IsInEmergency = false 
                    Status.Text = "✨ VIDA CHEIA! VOLTANDO..."
                else
                    Status.Text = "🚑 VIDA CRÍTICA! CALCULANDO ROTA..."
                    
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
                    if dangerMob then
                        -- LÊ A CONFIG PARA SABER QUANTO CORRER
                        local safeDist, _ = GetMobStats(dangerMob)
                        
                        if closestDist < safeDist then
                            local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                            MoveTo(myRoot.Position + (dir * 25))
                        else
                            StopMove()
                            Status.Text = "💖 RECUPERANDO (FORA DE ALCANCE)..."
                            SetSprint(false) 
                        end
                    else
                         StopMove() -- Sem ameaça perto
                    end
                end

            -- === LÓGICA DE CAÇA INTELIGENTE ===
            else
                if CurrentTarget then
                    local tHum = CurrentTarget:FindFirstChild("Humanoid")
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not tHum or tHum.Health <= 0 or not tRoot or not CurrentTarget.Parent then
                        CurrentTarget = nil
                        SetSprint(false)
                        StopMove()
                    else
                        -- COMBATE PADRÃO (Funcional V5)
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            -- Backstab Logic
                            local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            if (myRoot.Position - backPos.Position).Magnitude > 2 then
                                SetSprint(true) 
                                MoveTo(backPos.Position)
                            else
                                SetSprint(false)
                                StopMove()
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                            end
                            Attack()
                        end
                    end
                    
                else
                    -- BUSCA INTELIGENTE (Prioriza Raros)
                    Status.Text = "🔎 ANALISANDO MOBS..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    if folder then
                        local bestMob = nil
                        local minDist = SETTINGS.SearchRange
                        
                        for _, mob in ipairs(folder:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            if mHum and mRoot and mHum.Health > 0 then
                                local dist = (myRoot.Position - mRoot.Position).Magnitude
                                local _, isRare = GetMobStats(mob)
                                
                                -- Se for raro, pega ele independente da distância (dentro do range max)
                                if isRare and dist < SETTINGS.SearchRange then
                                    bestMob = mob
                                    Status.Text = "💎 MOB RARO DETECTADO!"
                                    break -- Achou raro, para de procurar
                                elseif dist < minDist then
                                    minDist = dist
                                    bestMob = mob
                                end
                            end
                        end
                        if bestMob then CurrentTarget = bestMob else SetSprint(false) StopMove() end
                    end
                end
            end
        end
    end
end)