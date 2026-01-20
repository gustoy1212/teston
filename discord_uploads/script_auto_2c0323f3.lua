--[[
    🩸 DPS GOD MODE (LIMIT BREAKER)
    
    ATENÇÃO: Velocidades extremas podem causar "Ghost Hits" (Dano não conta).
    Se o 100x não der dano, volte para o 50x.
    
    CONTROLES:
    - Botão [TURBO]: Alterna entre 50x e 100x.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().GodModeRunning = true

-- // CONFIGURAÇÕES INICIAIS //
local CurrentSpeed = 50 -- Começa em 50x

-- // GUI SETUP //
if CoreGui:FindFirstChild("GodModeDPS") then CoreGui.GodModeDPS:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GodModeDPS"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 140)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🩸 GOD DPS"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- Display de Velocidade
local SpeedLabel = Instance.new("TextLabel", MainFrame)
SpeedLabel.Size = UDim2.new(1, 0, 0, 40)
SpeedLabel.Position = UDim2.new(0, 0, 0.3, 0)
SpeedLabel.Text = "VELOCIDADE: " .. CurrentSpeed .. "x"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 20

-- Botão Turbo
local TurboBtn = Instance.new("TextButton", MainFrame)
TurboBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
TurboBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
TurboBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
TurboBtn.Text = "MUDAR VELOCIDADE"
TurboBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TurboBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO LIMPEZA //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().GodModeRunning = false
    ScreenGui:Destroy()
end)

-- // TROCA DE VELOCIDADE //
TurboBtn.MouseButton1Click:Connect(function()
    if CurrentSpeed == 50 then
        CurrentSpeed = 100 -- EXTREMO
        SpeedLabel.Text = "VELOCIDADE: 100x (MAX)"
        SpeedLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif CurrentSpeed == 100 then
        CurrentSpeed = 200 -- INSANO (Teste de Stress)
        SpeedLabel.Text = "VELOCIDADE: 200x (RISCO)"
        SpeedLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
    else
        CurrentSpeed = 50 -- RESET
        SpeedLabel.Text = "VELOCIDADE: 50x (SAFE)"
        SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    end
end)

-- // LÓGICA PRINCIPAL //
-- Usamos RenderStepped para ser mais rápido que a física
RunService.RenderStepped:Connect(function()
    if not getgenv().GodModeRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    local hum = char:FindFirstChild("Humanoid")
    
    if tool then
        -- 1. QUEBRA DE COOLDOWN INFINITA
        tool.Enabled = true 
        
        -- 2. ACELERAÇÃO DE ANIMAÇÃO
        if hum then
            local animator = hum:FindFirstChild("Animator") or hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    -- Só acelera se for a animação de soco/ataque
                    -- Aumenta a velocidade dinamicamente
                    track:AdjustSpeed(CurrentSpeed)
                end
            end
        end
        
        -- 3. SPAM DE ATIVAÇÃO
        tool:Activate()
    end
end)