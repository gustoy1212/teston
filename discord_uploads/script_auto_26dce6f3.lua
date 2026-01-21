--[[
    🕳️ SAO MOLE v1 (FARM TATU)
    
    ESTRATÉGIA "STEALTH":
    - Mantém o jogador 12 studs ABAIXO do chão (Subsolo).
    - Ninguém te vê voando.
    - O servidor aceita o dano porque você está PERTO (só que embaixo).
    
    ALVO: Workspace.Mobs
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOMole = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Depth = 12,           -- Profundidade (Quanto mais alto o valor, mais fundo na terra)
    FlySpeed = 65,        -- Velocidade de viagem no subsolo
    AttackDist = 15,      -- Distância para começar a bater (Vertical)
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local CurrentTween = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOMoleUI") then CoreGui.SAOMoleUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOMoleUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 20) -- Marrom Terra
MainFrame.BorderColor3 = Color3.fromRGB(150, 100, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕳️ MODO TATU (INVISIBLE)"
Title.TextColor3 = Color3.fromRGB(255, 180, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Superfície"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
ToggleBtn.Text = "ENTRAR NO SOLO (FARM)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function StopTween()
    if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        char.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOMole = false
    StopTween()
    -- Tenta subir o personagem pra não morrer enterrado
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        char.PrimaryPart.CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 20, 0)
    end
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "SAIR DO SOLO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        ToggleBtn.Text = "ENTRAR NO SOLO (FARM)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
        StopTween()
        CurrentTarget = nil
        -- Sobe pra respirar
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            char.PrimaryPart.CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 15, 0)
        end
    end
end)

-- // LOOP PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().SAOMole or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local root = char.HumanoidRootPart
    
    -- 1. NOCLIP CONSTANTE (Pra não travar na terra)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
    
    -- 2. ALVO ATUAL
    if CurrentTarget then
        local mobRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        
        if not mobRoot or not hum or hum.Health <= 0 or not CurrentTarget.Parent then
            CurrentTarget = nil
            StopTween()
            return
        end
        
        -- Calcula posição ALVO (Embaixo do bicho)
        local targetCFrame = mobRoot.CFrame * CFrame.new(0, -SETTINGS.Depth, 0) * CFrame.Angles(math.rad(90), 0, 0)
        local dist = (root.Position - targetCFrame.Position).Magnitude
        
        -- MOVIMENTO (TWEEN)
        if dist > 5 then
            if not CurrentTween or CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                Status.Text = "🕳️ CAVANDO ATÉ O ALVO..."
                local timeToFly = dist / SETTINGS.FlySpeed
                local tweenInfo = TweenInfo.new(timeToFly, Enum.EasingStyle.Linear)
                CurrentTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
                CurrentTween:Play()
            end
        else
            -- ATAQUE (Quando chegar embaixo)
            if CurrentTween then StopTween() end
            
            Status.Text = "⚔️ ATACANDO (DE BAIXO)"
            
            -- Fixa posição embaixo do bicho
            root.CFrame = targetCFrame
            root.Velocity = Vector3.new(0,0,0)
            
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            else
                Status.Text = "⚠️ PEGUE A ARMA!"
            end
        end
        return
    end
    
    -- 3. BUSCAR NOVO
    local folder = Workspace:FindFirstChild("Mobs")
    if not folder then return end
    
    local closest, minDist = nil, 99999
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and mobRoot and hum.Health > 0 then
            local dist = (root.Position - mobRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    
    if closest then
        CurrentTarget = closest
        StopTween()
    else
        Status.Text = "Procurando na Superfície..."
    end
end)