--[[
    🚑 SAO FLASH STEP v5 (SURVIVAL MODE)
    
    EVOLUÇÃO: Substitui o contador de kills por MONITOR DE VIDA.
    
    LÓGICA:
    1. Se Vida < 20%: FOGE IMEDIATAMENTE (Modo Emergência).
    2. Fica fugindo/escondido até Vida > 90%.
    3. Se morrer e renascer: Tenta reequipar a espada automaticamente.
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
    SprintDist = 10,
    SearchRange = 3000,
    
    -- Sobrevivência (Vida)
    LowHealthPercent = 25,  -- Foge se a vida cair abaixo de 25% (Aumentei um pouco pra garantir)
    FullHealthPercent = 90, -- Volta a atacar quando tiver 90%
    SafetyDist = 40,        -- Distância para fugir durante a emergência
}

-- Estados
local IsRunning = false
local IsSprinting = false
local IsInEmergency = false -- Estado de fuga
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashSurvUI") then CoreGui.FlashSurvUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashSurvUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- Vermelho Escuro (Sobrevivência)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🚑 FLASH STEP (SURVIVAL)"
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
ToggleBtn.Text = "LIGAR MODO SOBREVIVÊNCIA"
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

-- // AUTO EQUIPAR ESPADA //
local function AutoEquip()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Se já tem tool, ignora
    if char:FindFirstChildOfClass("Tool") then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        -- Tenta pegar a primeira ferramenta que achar (geralmente é a espada)
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then
            char.Humanoid:EquipTool(tool)
            Status.Text = "⚔️ ESPADA REEQUIPADA!"
        end
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
        ToggleBtn.Text = "LIGAR MODO SOBREVIVÊNCIA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
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
            
            -- Checagem de Vida
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            if hpPercent <= 30 then HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            elseif hpPercent <= 60 then HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end

            -- Verifica se morreu
            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                IsInEmergency = false
                task.wait(4) -- Espera respawn
                return
            end

            -- Tenta equipar espada se estiver sem
            AutoEquip()

            -- === LÓGICA DE EMERGÊNCIA (VIDA BAIXA) ===
            if hpPercent < SETTINGS.LowHealthPercent then
                IsInEmergency = true
            end
            
            if IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    IsInEmergency = false -- Vida cheia, volta pro jogo
                    Status.Text = "⚔️ VIDA RECUPERADA! VOLTANDO..."
                else
                    Status.Text = "🚑 VIDA CRÍTICA! FUGINDO..."
                    
                    -- Procura o inimigo mais próximo para correr DELE
                    local folder = Workspace:FindFirstChild("Mobs")
                    local dangerMob = nil
                    local closestDist = 9999
                    
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    dangerMob = mob
                                end
                            end
                        end
                    end
                    
                    SetSprint(true) -- Corre
                    
                    if dangerMob and closestDist < SETTINGS.SafetyDist then
                        -- Corre na direção oposta
                        local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                        local safePos = myRoot.Position + (dir * 20)
                        MoveTo(safePos)
                    else
                        -- Se já está longe, fica parado respirando
                        StopMove()
                        Status.Text = "💖 RECUPERANDO VIDA..."
                        SetSprint(false) -- Solta sprint pra recuperar estamina tbm
                    end
                end

            -- === LÓGICA DE CAÇA (NORMAL) ===
            else
                -- 1. ALVO
                if CurrentTarget then
                    local tHum = CurrentTarget:FindFirstChild("Humanoid")
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not tHum or tHum.Health <= 0 or not tRoot or not CurrentTarget.Parent then
                        CurrentTarget = nil
                        SetSprint(false)
                        StopMove()
                    else
                        -- COMBATE
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            -- Backstab
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
                    -- 2. PROCURA
                    Status.Text = "🔎 CAÇANDO..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    if folder then
                        local closest, minDist = nil, SETTINGS.SearchRange
                        for _, mob in ipairs(folder:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            if mHum and mRoot and mHum.Health > 0 then
                                local dist = (myRoot.Position - mRoot.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = mob
                                end
                            end
                        end
                        if closest then CurrentTarget = closest else SetSprint(false) StopMove() end
                    end
                end
            end
        end
    end
end)