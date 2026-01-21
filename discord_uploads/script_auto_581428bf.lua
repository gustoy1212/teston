--[[
    👑 SAO PROTOCOL v5 (ANIMATION KING)
    
    ALVO: Workspace.Mobs
    ID CONFIRMADO: rbxassetid://83373559139957
    
    CORREÇÕES:
    - Removido o pulo automático (que fazia o boneco ficar doido).
    - Foca 100% em tocar a animação para causar dano.
    - Velocidade de Ataque: 3x (Turbo).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().ProtocolV5 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 7,       -- Distância para começar a "dança da morte"
    SearchRange = 3000,
    AnimID = "rbxassetid://83373559139957", -- O ID Mágico
    AnimSpeed = 3,        -- Velocidade do Ataque (3x mais rápido)
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local AttackTrack = nil -- Guarda a animação

-- // GUI SETUP //
if CoreGui:FindFirstChild("ProtocolV5UI") then CoreGui.ProtocolV5UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ProtocolV5UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "👑 PROTOCOL v5 (KING)"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
ToggleBtn.Text = "INICIAR (AUTO ATTACK)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

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

-- CARREGADOR DE ANIMAÇÃO
local function PlayAttack()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    -- Se a animação já não estiver carregada, carrega ela
    if not AttackTrack then
        local anim = Instance.new("Animation")
        anim.AnimationId = SETTINGS.AnimID
        AttackTrack = hum:LoadAnimation(anim)
        AttackTrack.Priority = Enum.AnimationPriority.Action
        AttackTrack.Looped = false
    end
    
    -- Toca a animação
    AttackTrack:Play()
    AttackTrack:AdjustSpeed(SETTINGS.AnimSpeed)
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().ProtocolV5 = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR (AUTO ATTACK)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().ProtocolV5 do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. VALIDAÇÃO DE ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    StopMove()
                else
                    -- DISTÂNCIA
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- LONGE: APENAS ANDA
                        Status.Text = "🏃 INDO ATÉ O ALVO..."
                        MoveTo(root.Position)
                    else
                        -- PERTO: METRALHADORA DE ANIMAÇÃO
                        Status.Text = "⚔️ RETALHANDO!"
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        -- Dispara o ataque
                        PlayAttack()
                    end
                end
                
            else
                -- 2. BUSCA NOVO ALVO
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
                        StopMove()
                    end
                end
            end
        end
    end
end)