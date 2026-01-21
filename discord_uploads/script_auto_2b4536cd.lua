--[[
    ⚡💤 SAO FLASH STEP v4 (FINAL VERSION)
    
    FUNCIONALIDADES:
    1. FLASH STEP: Sprint e Backstab inteligente (Baseado na v1).
    2. SMART REST: Mata 4, Descansa 60s, Foge se tiver perigo.
    3. ANTI-AFK: Evita o Error 278 simulando cliques virtuais.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser") -- Serviço para enganar o AFK
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepFinal = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 6,
    BehindDist = 5,
    SprintDist = 10,
    SearchRange = 3000,
    
    -- Descanso (Vida)
    MaxKills = 4,          -- Mata 4 Javalis
    RestTime = 60,         -- Descansa 60 segundos
    SafetyDist = 30,       -- Se chegar bicho a menos de 30m, corre
}

-- Estados
local IsRunning = false
local IsSprinting = false
local IsResting = false
local CurrentTarget = nil
local KillCount = 0
local RestStartTime = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashFinalUI") then CoreGui.FlashFinalUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashFinalUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚡ FLASH STEP (AFK PROOF)"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
ToggleBtn.Text = "LIGAR FARM 24/7"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // ANTI-AFK SYSTEM (A SOLUÇÃO DO ERRO 278) //
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new()) -- Simula clique direito do mouse
    Status.Text = "⛔ AFK RESETADO!"
end)

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

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepFinal = false
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
        ToggleBtn.Text = "LIGAR FARM 24/7"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepFinal do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart

            -- === LOGICA DE DESCANSO ===
            if IsResting then
                local elapsed = tick() - RestStartTime
                local timeLeft = math.ceil(SETTINGS.RestTime - elapsed)
                
                if timeLeft <= 0 then
                    IsResting = false
                    KillCount = 0
                    InfoLabel.Text = "Kills: 0 / " .. SETTINGS.MaxKills
                    Status.Text = "⚔️ VOLTANDO À CAÇA!"
                else
                    Status.Text = "💤 RECUPERANDO: " .. timeLeft .. "s"
                    
                    -- Radar de Perigo
                    local folder = Workspace:FindFirstChild("Mobs")
                    local danger = nil
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < SETTINGS.SafetyDist then
                                    danger = mob
                                    break
                                end
                            end
                        end
                    end
                    
                    if danger then
                        SetSprint(true)
                        Status.Text = "⚠️ FUGINDO DO PERIGO!"
                        local dir = (myRoot.Position - danger.HumanoidRootPart.Position).Unit
                        MoveTo(myRoot.Position + (dir * 25))
                    else
                        SetSprint(false)
                        StopMove()
                    end
                end
                
            -- === LÓGICA DE CAÇA (FLASH STEP ORIGINAL) ===
            else
                if CurrentTarget then
                    local hum = CurrentTarget:FindFirstChild("Humanoid")
                    local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                        -- Contabiliza Kill
                        if hum and hum.Health <= 0 then
                            KillCount = KillCount + 1
                            InfoLabel.Text = "Kills: " .. KillCount .. " / " .. SETTINGS.MaxKills
                        end
                        
                        CurrentTarget = nil
                        SetSprint(false)
                        StopMove()
                        
                        -- Verifica Meta
                        if KillCount >= SETTINGS.MaxKills then
                            IsResting = true
                            RestStartTime = tick()
                            -- Foge do corpo morto pra não bugar
                            local randDir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
                            MoveTo(myRoot.Position + randDir * 30)
                        end
                    else
                        -- COMBATE
                        local dist = (myRoot.Position - root.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(root.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(root.Position)
                        else
                            -- Backstab
                            local backPos = root.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            if (myRoot.Position - backPos.Position).Magnitude > 2.5 then
                                SetSprint(true)
                                MoveTo(backPos.Position)
                            else
                                SetSprint(false)
                                StopMove()
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                            end
                            Attack()
                        end
                    end
                else
                    -- Procura Alvo
                    Status.Text = "🔎 CAÇANDO..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    if folder then
                        local closest, minDist = nil, SETTINGS.SearchRange
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
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