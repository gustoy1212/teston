--[[
    🚑 SAO FLASH STEP v5.5 (LOG ENHANCED)
    BASE: Seu script original (Movimentação e Sobrevivência mantidas 100%).
    UPGRADE DAS LOGS: 
    1. Hitbox Expandida na peça "Middle" (Dano garantido).
    2. Auto Skills (Q, E, R) durante o ataque.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepSurvival = true

-- // CONFIGURAÇÕES (Mantidas do seu gosto) //
local SETTINGS = {
    -- Combate
    AttackDist = 6,
    BehindDist = 5,
    SprintDist = 10,
    SearchRange = 3000,
    
    -- Hitbox (Ouro da Log)
    ReachSize = 15, -- Tamanho 15 garante que o hit pegue sempre
    
    -- Sobrevivência (Vida)
    LowHealthPercent = 25, 
    FullHealthPercent = 90, 
    SafetyDist = 40,        
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
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🚑 FLASH STEP (LOG MOD)"
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

-- [NOVO] Aplica Hitbox baseada na Log (Middle)
local function ApplyReach()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            -- O Log mostrou que a peça de dano é "Middle"
            local damagePart = tool:FindFirstChild("Middle") or tool:FindFirstChild("Handle")
            if damagePart then
                if damagePart.Size.X < 5 then -- Só aumenta se for pequena
                    damagePart.Size = Vector3.new(SETTINGS.ReachSize, SETTINGS.ReachSize, SETTINGS.ReachSize)
                    damagePart.Transparency = 1 -- Invisível pra ficar bonito
                    damagePart.CanCollide = false
                    damagePart.Massless = true
                end
                -- Força atualização do toque
                if damagePart:FindFirstChild("TouchInterest") then
                    firetouchinterest(damagePart, damagePart, 0)
                end
            end
        end
    end
end

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
    -- [NOVO] Aplica o Reach antes de bater
    ApplyReach()
    
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
    
    -- [NOVO] Usa Skills Q, E, R (Sem F pra não defender)
    local keys = {"E", "R", "Q"}
    for _, k in pairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game)
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
                task.wait(4)
                return
            end

            AutoEquip()

            -- === EMERGÊNCIA (Mantido do seu) ===
            if hpPercent < SETTINGS.LowHealthPercent then
                IsInEmergency = true
            end
            
            if IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    IsInEmergency = false 
                    Status.Text = "⚔️ VOLTANDO PRO ATAQUE..."
                else
                    Status.Text = "🚑 RECUPERANDO VIDA..."
                    
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
                    
                    SetSprint(true)
                    
                    if dangerMob and closestDist < SETTINGS.SafetyDist then
                        local dir = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                        local safePos = myRoot.Position + (dir * 20)
                        MoveTo(safePos)
                    else
                        StopMove()
                        SetSprint(false) 
                    end
                end

            -- === CAÇA (Mantido do seu) ===
            else
                if CurrentTarget then
                    local tHum = CurrentTarget:FindFirstChild("Humanoid")
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not tHum or tHum.Health <= 0 or not tRoot or not CurrentTarget.Parent then
                        CurrentTarget = nil
                        SetSprint(false)
                        StopMove()
                    else
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            -- Backstab (Sua lógica perfeita)
                            local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            if (myRoot.Position - backPos.Position).Magnitude > 2 then
                                SetSprint(true) 
                                MoveTo(backPos.Position)
                            else
                                SetSprint(false)
                                StopMove()
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                            end
                            Attack() -- Agora com Reach e Skills!
                        end
                    end
                    
                else
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