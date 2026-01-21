--[[
    🕳️ SAO MOLE v2 (TITAN HITBOX)
    
    ESTRATÉGIA COMBINADA:
    1. TATU: Você fica 15 studs abaixo da terra (Seguro).
    2. TITAN: Aumenta a Hitbox do inimigo para 60 studs.
    
    POR QUE FUNCIONA?
    O inimigo fica gigante. A hitbox dele atravessa o chão e chega até você
    no subsolo. Você bate nele sem precisar subir.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOMoleV2 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Depth = 15,           -- Profundidade (Mais fundo = Mais seguro)
    FlySpeed = 65,        -- Velocidade embaixo da terra
    HitboxSize = 60,      -- TAMANHO GIGANTE (Pra chegar até você)
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local CurrentTween = nil
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOMoleV2UI") then CoreGui.SAOMoleV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOMoleV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 5) -- Marrom Escuro
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕳️ MOLE v2 (TITAN BOX)"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
ToggleBtn.Text = "ENTRAR NO SOLO (FARM)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

local function ExpandHitbox(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- A MÁGICA: Cresce o bicho pra ele "entrar" na terra
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.CanCollide = false
    root.Transparency = 0.7
    root.Color = Color3.fromRGB(255, 100, 0)
end

local function RestoreHitbox(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

local function StopTween()
    if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        char.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOMoleV2 = false
    StopTween()
    -- Restaura Hitboxes
    for mob, _ in pairs(OriginalSizes) do RestoreHitbox(mob) end
    -- Sobe o player
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
        StopTween()
        CurrentTarget = nil
        -- Sobe pra respirar
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            char.PrimaryPart.CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 20, 0)
        end
    end
end)

-- // LOOP PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().SAOMoleV2 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local root = char.HumanoidRootPart
    
    -- 1. NOCLIP (Atravessar tudo)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
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
        
        -- Garante que o alvo está GIGANTE
        ExpandHitbox(CurrentTarget)
        
        -- Calcula posição ALVO (Embaixo do bicho)
        -- Ajuste: Não precisa ficar exatamente embaixo, o cubo é enorme
        local targetCFrame = mobRoot.CFrame * CFrame.new(0, -SETTINGS.Depth, 0) * CFrame.Angles(math.rad(90), 0, 0)
        local dist = (root.Position - targetCFrame.Position).Magnitude
        
        -- VIAGEM
        if dist > 10 then
            if not CurrentTween or CurrentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                Status.Text = "🕳️ NAVEGANDO..."
                local timeToFly = dist / SETTINGS.FlySpeed
                local tweenInfo = TweenInfo.new(timeToFly, Enum.EasingStyle.Linear)
                CurrentTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
                CurrentTween:Play()
            end
        else
            -- ATAQUE (Chegou no subsolo)
            if CurrentTween then StopTween() end
            Status.Text = "⚔️ PEGANDO PELA RAIZ"
            
            -- Fixa posição
            root.CFrame = targetCFrame
            root.Velocity = Vector3.new(0,0,0)
            
            -- Tenta bater
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
                -- Dica: Se o bicho for muito alto, a hitbox gigante garante que
                -- a parte de baixo dela esteja tocando sua espada.
            else
                Status.Text = "⚠️ CADÊ A ARMA?"
            end
        end
        return
    end
    
    -- 3. BUSCA NOVO ALVO
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