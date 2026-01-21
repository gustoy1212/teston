--[[
    ⚡ SAO TURBO CHARGER (DANO EXTRA)
    
    OBJETIVO: Acelerar a animação de ataque para tentar multiplicar o dano.
    COMO USAR: Deixe o Bot de Farm ligado e ative este script junto.
    
    ID DO ATAQUE: rbxassetid://83373559139957
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().TurboDamage = true

-- // GUI SIMPLES //
if CoreGui:FindFirstChild("TurboUI") then CoreGui.TurboUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TurboUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.8, 0, 0.3, 0) -- Canto direito pra não atrapalhar o outro
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ TURBO DANO"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.Text = "ATIVAR (50x)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local IsRunning = false
local AttackAnimID = "rbxassetid://83373559139957"
local LoadedTrack = nil

-- // FUNÇÃO TURBO //
local function SpamAnimation()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    -- Carrega a animação se não tiver
    if not LoadedTrack then
        local anim = Instance.new("Animation")
        anim.AnimationId = AttackAnimID
        LoadedTrack = hum:LoadAnimation(anim)
        LoadedTrack.Priority = Enum.AnimationPriority.Action
        LoadedTrack.Looped = false
    end
    
    -- Toca, Acelera, Para (Loop Insano)
    LoadedTrack:Play()
    LoadedTrack:AdjustSpeed(50) -- VELOCIDADE 50x
    
    -- Nota: Não colocamos wait() aqui para ser o mais rápido possível
    -- Mas se travar seu jogo, me avisa que colocamos um task.wait(0.01)
end

-- // HOOK DE VELOCIDADE (Passivo) //
-- Isso garante que mesmo o ataque normal do outro script seja acelerado
spawn(function()
    while getgenv().TurboDamage do
        if IsRunning then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId == AttackAnimID then
                            track:AdjustSpeed(50) -- Força 50x em qualquer ataque
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "🔥 RODANDO..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        -- Loop Ativo (Spam)
        spawn(function()
            while IsRunning and getgenv().TurboDamage do
                SpamAnimation()
                task.wait() -- Mínimo delay possível
            end
        end)
    else
        ToggleBtn.Text = "ATIVAR (50x)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Botão de fechar simples
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -20, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
CloseBtn.TextColor3 = Color3.white

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TurboDamage = false
    ScreenGui:Destroy()
end)