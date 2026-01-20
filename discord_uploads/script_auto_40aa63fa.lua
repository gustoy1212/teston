--[[
    🧪 RPG SLIME MAGNET v1 (DUELIST MODE)
    
    ALVO: Workspace.Enemies (Ogre Slime, etc)
    ESTRATÉGIA:
    - Foca em UM inimigo por vez (evita lag e bagunça).
    - Traz ele até você e deixa GIGANTE.
    - Quando ele morre, puxa o próximo da fila.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SlimeMagnet = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Distance = 6,         -- Distância na sua frente
    HitboxSize = 20,      -- Tamanho do inimigo (Cubo Perfeito)
    SearchRange = 3000,   -- Onde buscar novos alvos
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalSize = nil

-- // GUI VISUAL //
if CoreGui:FindFirstChild("SlimeMagnetUI") then CoreGui.SlimeMagnetUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SlimeMagnetUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 10) -- Verde Slime
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧪 SLIME MAGNET (1v1)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 255, 200)
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
ToggleBtn.Text = "LIGAR MAGNETO (1 POR 1)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

-- Restaura o bicho se você desligar ou trocar de alvo
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
    getgenv().SlimeMagnet = false
    RestoreTarget()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MAGNETO (1 POR 1)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreTarget()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().SlimeMagnet or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 1. SE JÁ TEM ALVO, VERIFICA SE AINDA ESTÁ VIVO
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
        
        if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
            -- Morreu ou sumiu: Restaura e busca próximo
            RestoreTarget()
        else
            -- VIVO: Puxa e Mantém Gigante
            Status.Text = "⚔️ MATANDO: " .. CurrentTarget.Name
            
            -- Teleporta pra sua frente
            root.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -SETTINGS.Distance)
            root.Velocity = Vector3.new(0,0,0)
            root.CanCollide = false
            
            -- Garante tamanho (Hitbox)
            if not OriginalSize then OriginalSize = root.Size end
            root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
            root.Transparency = 0.6 -- Roxo transparente
            root.Color = Color3.fromRGB(150, 0, 255)
            return -- Sai do loop para focar só nesse
        end
    end
    
    -- 2. SE NÃO TEM ALVO, BUSCA O MAIS PRÓXIMO NA PASTA CERTA
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then
        Status.Text = "⚠️ Pasta 'Enemies' sumiu!"
        return
    end
    
    local closestDist = SETTINGS.SearchRange
    local potentialTarget = nil
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        -- Verifica vida e componentes
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                potentialTarget = mob
            end
        end
    end
    
    -- Define novo alvo
    if potentialTarget then
        CurrentTarget = potentialTarget
    else
        Status.Text = "Procurando Ogre Slimes..."
    end
end)