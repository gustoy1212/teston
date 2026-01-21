--[[
    ⚡ SAO FLASH STEP (SPRINT & BACKSTAB)
    
    ESTRATÉGIA DE VELOCIDADE:
    1. Usa o CTRL (Sprint) de forma inteligente.
    2. Corre para se aproximar.
    3. Corre para circular para as costas (Backstab).
    4. Descansa (Solta Ctrl) enquanto bate para regenerar Estamina.
    
    ALVO: PlayerGui.DeviceGui.Mobile -> Attack
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStep = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,        -- Distância para começar a bater
    BehindDist = 5,        -- Distância para ficar atrás do bicho
    SprintDist = 10,       -- Se estiver mais longe que isso, CORRE
    SearchRange = 3000,
}

-- Estados
local IsRunning = false
local IsSprinting = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashUI") then CoreGui.FlashUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 50, 50) -- Verde Velocidade
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚡ FLASH STEP (SPRINT)"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
ToggleBtn.Text = "INICIAR VELOCIDADE"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // CONTROLE DE SPRINT (CTRL) //
local function SetSprint(enable)
    if enable then
        if not IsSprinting then
            IsSprinting = true
            -- Segura Ctrl
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            Status.Text = "⚡ CORRENDO (Gasta Estamina)"
        end
    else
        if IsSprinting then
            IsSprinting = false
            -- Solta Ctrl
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            Status.Text = "🔋 RECUPERANDO (Caminhando)"
        end
    end
end

-- // MOVIMENTO //
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

-- // ATAQUE SIMPLES (Botão Confirmado) //
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

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStep = false
    SetSprint(false) -- Garante que solta o Ctrl
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR VELOCIDADE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStep do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    SetSprint(false)
                    StopMove()
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.SprintDist then
                        -- ESTÁ LONGE: Corre pra chegar rápido
                        SetSprint(true)
                        MoveTo(root.Position)
                        
                    elseif dist > SETTINGS.AttackDist then
                        -- ESTÁ MÉDIO (Zona de Combate): Caminha pra não gastar tudo
                        SetSprint(false)
                        MoveTo(root.Position)
                        
                    else
                        -- ESTÁ PERTO: HORA DO SHOW
                        -- Tenta ir para as costas
                        local backPos = root.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                        local distToBack = (myRoot.Position - backPos.Position).Magnitude
                        
                        -- Se não estiver nas costas ainda, dá um GÁS
                        if distToBack > 2 then
                            SetSprint(true) -- Explosão de velocidade pra driblar
                            MoveTo(backPos.Position)
                        else
                            SetSprint(false) -- Chegou nas costas, descansa e bate
                            -- Para de andar pra focar no ataque
                            StopMove()
                            -- Vira pro bicho
                            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        end
                        
                        Attack()
                    end
                end
                
            else
                -- 2. PROCURA
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
                    
                    if closest then
                        CurrentTarget = closest
                    else
                        Status.Text = "Procurando Mobs..."
                        SetSprint(false)
                        StopMove()
                    end
                end
            end
        end
    end
end)