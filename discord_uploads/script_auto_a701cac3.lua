--[[
    ⚡💤 SAO FLASH STEP v3 (SMART REST)
    
    BASE: Flash Step (Sprint & Backstab) - O que funcionou melhor.
    NOVIDADE: Sistema de Descanso Inteligente.
    
    LÓGICA:
    1. Mata 4 Inimigos.
    2. Entra em modo DESCANSO por 60 segundos.
    3. Durante o descanso, se algo chegar perto, ele FOGE automaticamente.
    4. Depois de recuperar, volta a caçar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepRest = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 6,
    BehindDist = 5,
    SprintDist = 10,
    SearchRange = 3000,
    
    -- Descanso
    MaxKills = 4,          -- Mata 4 e para
    RestTime = 60,         -- Descansa 1 minuto
    SafetyDist = 35,       -- Distância segura durante o descanso (Se chegar perto, corre)
}

-- Estados
local IsRunning = false
local IsSprinting = false
local IsResting = false
local CurrentTarget = nil
local KillCount = 0
local RestStartTime = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashRestUI") then CoreGui.FlashRestUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashRestUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180) -- Um pouco maior pra caber infos
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 60)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚡ FLASH STEP (AUTO REST)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 30)
InfoLabel.Position = UDim2.new(0, 0, 0.35, 0)
InfoLabel.Text = "Kills: 0 / 4"
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR FARM INTELIGENTE"
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

-- // BOTÕES UI //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepRest = false
    SetSprint(false)
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        KillCount = 0
        IsResting = false
        InfoLabel.Text = "Kills: 0 / " .. SETTINGS.MaxKills
    else
        ToggleBtn.Text = "LIGAR FARM INTELIGENTE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepRest do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid

            -- === MODO DESCANSO ===
            if IsResting then
                local elapsed = tick() - RestStartTime
                local timeLeft = math.ceil(SETTINGS.RestTime - elapsed)
                
                if timeLeft <= 0 then
                    -- Fim do descanso
                    IsResting = false
                    KillCount = 0
                    InfoLabel.Text = "Kills: 0 / " .. SETTINGS.MaxKills
                    Status.Text = "⚔️ HORA DO SHOW!"
                else
                    -- LÓGICA DE DEFESA ENQUANTO DESCANSA
                    Status.Text = "💤 RECUPERANDO: " .. timeLeft .. "s"
                    InfoLabel.Text = "Modo: Evasão/Cura"
                    
                    -- Verifica se tem inimigo perto
                    local folder = Workspace:FindFirstChild("Mobs")
                    local dangerMob = nil
                    
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < SETTINGS.SafetyDist then
                                    dangerMob = mob
                                    break -- Achou um perigo, reage!
                                end
                            end
                        end
                    end
                    
                    if dangerMob then
                        -- PERIGO! CORRE!
                        Status.Text = "⚠️ AFASTANDO DO PERIGO!"
                        SetSprint(true)
                        
                        -- Calcula direção oposta
                        local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                        local safeSpot = myRoot.Position + (dir * 20) -- Corre 20 studs pra longe
                        
                        MoveTo(safeSpot)
                    else
                        -- SEGURO
                        SetSprint(false)
                        StopMove()
                    end
                end
                
            -- === MODO CAÇA ===
            else
                -- 1. ALVO
                if CurrentTarget then
                    local tHum = CurrentTarget:FindFirstChild("Humanoid")
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not tHum or tHum.Health <= 0 or not tRoot or not CurrentTarget.Parent then
                        -- ALVO MORREU OU SUMIU
                        if tHum and tHum.Health <= 0 then
                            KillCount = KillCount + 1
                            InfoLabel.Text = "Kills: " .. KillCount .. " / " .. SETTINGS.MaxKills
                        end
                        
                        CurrentTarget = nil
                        SetSprint(false)
                        StopMove()
                        
                        -- VERIFICA META DE KILLS
                        if KillCount >= SETTINGS.MaxKills then
                            IsResting = true
                            RestStartTime = tick()
                            -- Dá uma corrida inicial pra longe do último corpo
                            local randDir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
                            MoveTo(myRoot.Position + randDir * 30)
                        end
                        
                    else
                        -- COMBATE (Mesma lógica do Flash Step)
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            -- Perto: Costas + Ataque
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
                            local hum = mob:FindFirstChild("Humanoid")
                            local root = mob:FindFirstChild("HumanoidRootPart")
                            if hum and root and hum.Health > 0 then
                                local dist = (myRoot.Position - root.Position).Magnitude
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