--[[
    🧪 RPG SLIME MAGNET v1.5 (MELEE FIX)
    
    CORREÇÃO DE DANO BÁSICO:
    - Distância reduzida para 2.5 studs (Distância de soco/abraço).
    - Alinhamento de altura (Y) para o inimigo não ficar no chão/céu.
    
    MANTÉM:
    - Modo 1v1 (Um por vez).
    - Hitbox Gigante.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SlimeMagnetV15 = true

-- // CONFIGURAÇÕES (AJUSTADAS) //
local SETTINGS = {
    Distance = 2.5,       -- [CORRIGIDO] Bem perto para o soco pegar
    HitboxSize = 15,      -- Tamanho confortável
    SearchRange = 3000,   -- Raio de busca
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalSize = nil

-- // GUI VISUAL //
if CoreGui:FindFirstChild("SlimeMeleeUI") then CoreGui.SlimeMeleeUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SlimeMeleeUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🥊 MELEE MAGNET v1.5"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR (MODO SOCO)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function RestoreTarget()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") and OriginalSize then
        CurrentTarget.HumanoidRootPart.Size = OriginalSize
        CurrentTarget.HumanoidRootPart.Transparency = 1
        CurrentTarget.HumanoidRootPart.CanCollide = true
    end
    CurrentTarget = nil
    OriginalSize = nil
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SlimeMagnetV15 = false
    RestoreTarget()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR (MODO SOCO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreTarget()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().SlimeMagnetV15 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    
    -- 1. VERIFICA ALVO ATUAL
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
        
        if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
            RestoreTarget() -- Morreu, próximo!
        else
            Status.Text = "🥊 ESMURRANDO: " .. CurrentTarget.Name
            
            -- [CORREÇÃO] Puxa para MUITO PERTO (2.5 studs)
            -- E mantém a mesma altura (Y) do seu personagem pra não ficar no chão
            local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.Distance)
            
            -- Fixar a posição
            root.CFrame = targetCFrame
            root.Velocity = Vector3.new(0,0,0)
            root.CanCollide = false
            root.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Trava física extra
            
            -- Hitbox Visual
            if not OriginalSize then OriginalSize = root.Size end
            root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
            root.Transparency = 0.6 
            root.Color = Color3.fromRGB(255, 0, 0) -- Vermelho pra ataque
            return
        end
    end
    
    -- 2. BUSCA NOVO ALVO
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then Status.Text = "⚠️ Pasta Sumiu!" return end
    
    local closestDist = SETTINGS.SearchRange
    local potentialTarget = nil
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                potentialTarget = mob
            end
        end
    end
    
    if potentialTarget then
        CurrentTarget = potentialTarget
    else
        Status.Text = "Procurando Alvos..."
    end
end)