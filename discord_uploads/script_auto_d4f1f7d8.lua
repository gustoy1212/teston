--[[
    ⚔️ SAO PROTOCOL v4 (ANIMATION OVERRIDE)
    
    DESCOBERTA DO SCANNER:
    - ID da Animação de Ataque: 83373559139957
    
    ESTRATÉGIA:
    1. Anda até o mob (Anti-Kick).
    2. Chegando perto, FORÇA a animação a tocar manualmente.
    3. Tenta clicar na posição provável do botão de ataque (Mobile).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().ProtocolV4 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,
    SearchRange = 3000,
    AnimID = "rbxassetid://83373559139957", -- ID Capturado no Scan
    AnimSpeed = 2, -- Velocidade do ataque (2x mais rápido)
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local AttackTrack = nil -- Guarda a animação carregada

-- // GUI SETUP //
if CoreGui:FindFirstChild("ProtocolV4UI") then CoreGui.ProtocolV4UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ProtocolV4UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 0, 100) -- Roxo Dark
MainFrame.BorderColor3 = Color3.fromRGB(200, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ PROTOCOL v4 (ANIMATION)"
Title.TextColor3 = Color3.fromRGB(200, 100, 255)
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

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
ToggleBtn.Text = "INICIAR (WALK + ANIM)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- Mira Visual (Onde o script tá clicando)
local ClickDot = Instance.new("Frame", ScreenGui)
ClickDot.Size = UDim2.new(0, 20, 0, 20)
ClickDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ClickDot.Visible = false
Instance.new("UICorner", ClickDot).CornerRadius = UDim.new(1, 0)

-- // FUNÇÕES //

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

-- CARREGA A ANIMAÇÃO
local function LoadAttackAnim()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = SETTINGS.AnimID
    
    AttackTrack = hum:LoadAnimation(anim)
    AttackTrack.Priority = Enum.AnimationPriority.Action
    AttackTrack.Looped = false
end

-- FORÇA O ATAQUE
local function ForceAttack()
    -- 1. Toca a Animação (O Segredo)
    if AttackTrack then
        AttackTrack:Play()
        AttackTrack:AdjustSpeed(SETTINGS.AnimSpeed) -- Acelera o ataque
    else
        LoadAttackAnim()
    end
    
    -- 2. Tenta Clicar no Botão (Mobile)
    -- Posição estimada do botão de ataque (80% Direita, 75% Baixo)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local clickX = screenSize.X * 0.85 
    local clickY = screenSize.Y * 0.75
    
    -- Mostra a bolinha vermelha
    ClickDot.Position = UDim2.new(0, clickX - 10, 0, clickY - 10)
    ClickDot.Visible = true
    
    VirtualInputManager:SendTouchEvent(999, 0, clickX, clickY, 0, false, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendTouchEvent(999, 1, clickX, clickY, 0, false, game, 1)
    
    -- Esconde bolinha rápido pra não atrapalhar
    task.wait(0.1) 
    ClickDot.Visible = false
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().ProtocolV4 = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        LoadAttackAnim() -- Prepara a animação
    else
        ToggleBtn.Text = "INICIAR (WALK + ANIM)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().ProtocolV4 do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    StopMove()
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        Status.Text = "🏃 INDO ATÉ O ALVO..."
                        MoveTo(root.Position)
                        
                        -- Pulo se travar
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                    else
                        Status.Text = "⚔️ FORÇANDO ANIMAÇÃO!"
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        ForceAttack()
                    end
                end
            else
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
                    if closest then CurrentTarget = closest else Status.Text = "Procurando..." StopMove() end
                end
            end
        end
    end
end)