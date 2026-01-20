--[[
    🩸 DPS BOOSTER - COOLDOWN BREAKER
    
    OBJETIVO:
    - Remover o limite de velocidade da arma.
    - Acelerar a animação de ataque.
    - Multiplicar o DPS (Dano por Segundo).
    
    COMO USAR:
    - Equipe a arma.
    - Ative o script.
    - Segure o clique (ou deixe o Magneto bater).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().DamageBooster = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AnimSpeed = 10,       -- Velocidade da animação (10x mais rápido)
    ForceCooldown = true, -- Obriga a arma a ficar pronta
}

-- // GUI SIMPLES //
if CoreGui:FindFirstChild("DPSBooster") then CoreGui.DPSBooster:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DPSBooster"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 80)
Frame.Position = UDim2.new(0.1, 0, 0.2, 0) -- No canto pra não atrapalhar
Frame.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
Frame.BorderSizePixel = 2
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "🩸 DANO x10 (ON)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Frame)
CloseBtn.Size = UDim2.new(0, 30, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, 0, 0, 50)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Quebrando Cooldown..."
Status.TextColor3 = Color3.fromRGB(255, 200, 200)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Code

-- // LIMPEZA //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().DamageBooster = false
    Status.Text = "Desligado."
    task.wait(1)
    ScreenGui:Destroy()
end)

-- // LÓGICA DE QUEBRA //
RunService.Stepped:Connect(function()
    if not getgenv().DamageBooster then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    local hum = char:FindFirstChild("Humanoid")
    
    if tool then
        -- 1. QUEBRA DE COOLDOWN (Force Enable)
        if SETTINGS.ForceCooldown then
            tool.Enabled = true -- Diz pro jogo "Tô pronto" mesmo não estando
        end
        
        -- 2. ACELERA ANIMAÇÃO (Animation Speed)
        if hum then
            local animator = hum:FindFirstChild("Animator") or hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    -- Acelera qualquer animação que pareça de ataque
                    if track.Length > 0 then 
                        track:AdjustSpeed(SETTINGS.AnimSpeed)
                    end
                end
            end
        end
        
        -- 3. SPAM CLICK (Garanta que está ativando)
        tool:Activate()
    else
        Status.Text = "Equipe a Arma!"
    end
end)