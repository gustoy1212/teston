--[[
    🚑 SAO FLASH STEP v8 (VOLTA DO SISTEMA DE CLIQUE + SURVIVAL)
    
    CORREÇÃO:
    - Reimplementado o sistema de clicar no botão "MobileAttackButton" (que funcionava na v5).
    - Adicionado suporte a clique de mouse (PC) por garantia.
    - Mantido o sistema de sobrevivência inteligente.
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
    AttackDist = 7,         -- Distância para começar a bater
    ClickSpeed = 0.1,       -- Intervalo entre cliques (Muito rápido)
    
    -- Movimento
    SprintDist = 15,
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
local LastAttack = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashSurvUI") then CoreGui.FlashSurvUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashSurvUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🚑 AUTO FARM v8 (CLICK)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
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

-- Função Crucial: Tenta clicar no botão de todas as formas
local function ForceAttack()
    local char = LocalPlayer.Character
    if not char then return end

    -- 1. Método da Ferramenta (Padrão)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end

    -- 2. Método Mobile (O que funcionava na v5)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local btn = nil
    
    -- Tenta achar o botão com segurança
    pcall(function() 
        if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
            btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        end
    end)

    if btn then
        -- Simula toque na tela (Mobile)
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
        
        VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
        task.wait() -- Pequeno delay pro toque registrar
        VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
    else
        -- 3. Método PC (Fallback)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

local function LookAt(targetPos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        -- Olha pro alvo mantendo a altura (pra não girar pro chão)
        root.CFrame = CFrame.new(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepSurvival do
        task.wait() -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            -- Auto Equipar (Caso tenha morrido ou desequipado)
            if not char:FindFirstChildOfClass("Tool") then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local tool = backpack:FindFirstChildOfClass("Tool")
                    if tool then hum:EquipTool(tool) end
                end
            end

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

            -- === 2. COMBATE (NORMAL) ===
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
                    -- Lógica de Ataque
                    local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        -- Se estiver perto, BATE
                        if dist <= SETTINGS.AttackDist then
                            Status.Text = "⚔️ BATENDO (SPAM)..."
                            StopMove()      -- Para de andar
                            LookAt(tRoot.Position) -- Olha pro bicho
                            
                            -- Spam de Ataque (Controlado pelo tempo)
                            if tick() - LastAttack > SETTINGS.ClickSpeed then
                                ForceAttack()
                                LastAttack = tick()
                            end
                        else
                            -- Se longe, CORRE
                            Status.Text = "🏃 SEGUINDO..."
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        end
                    end
                end
            end
        end
    end
end)