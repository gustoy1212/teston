--[[
    🏴‍☠️ BLOX FRUITS - HITBOX EXTENDER + SAFE MAGNET
    
    COMO FUNCIONA:
    1. Aumenta a Hitbox dos inimigos para 60x60x60 (Quadrado Transparente).
    2. Puxa os inimigos para ficarem a 25 studs de distância (Segurança).
    3. Você bate no "vento" (na hitbox gigante) e acerta eles sem tomar dano.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    HitboxSize = 60,       -- Tamanho do monstro (Gigante)
    SafeDistance = 25,     -- Distância que ele fica de você (Longe o suficiente pra não te bater)
    MagnetRange = 300,     -- Alcance para puxar
    HitboxColor = Color3.fromRGB(255, 0, 0),
    HitboxTransparency = 0.8
}

-- Estados
local IsHitboxActive = false
local IsMagnetActive = false
local SelectedMobs = {} 

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxHitboxUI") then CoreGui.BloxHitboxUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxHitboxUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🥊 HITBOX KING v3"
Title.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

-- Botão Hitbox
local HitboxBtn = Instance.new("TextButton", MainFrame)
HitboxBtn.Size = UDim2.new(0.9, 0, 0, 35)
HitboxBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HitboxBtn.Text = "1. ATIVAR HITBOX GIGANTE"
HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxBtn.Font = Enum.Font.GothamBold

-- Botão Ímã Seguro
local MagnetBtn = Instance.new("TextButton", MainFrame)
MagnetBtn.Size = UDim2.new(0.9, 0, 0, 35)
MagnetBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 0)
MagnetBtn.Text = "2. LIGAR ÍMÃ DE SEGURANÇA"
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Font = Enum.Font.GothamBold

-- Lista de Scan
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.5, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.3, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Scroll.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES LÓGICAS //

-- Aumenta a Hitbox
local function ExpandHitbox(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root then
        -- Desativa colisão pra não empurrar você
        root.CanCollide = false
        -- Muda o tamanho
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        -- Visual
        root.Transparency = SETTINGS.HitboxTransparency
        root.Color = SETTINGS.HitboxColor
        root.Material = Enum.Material.ForceField
    end
end

-- Restaura Hitbox (opcional, pra não bugar respawn)
local function ResetHitbox(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size = Vector3.new(2, 2, 1) -- Tamanho padrão do Roblox
        root.Transparency = 1
    end
end

-- Scan Automático (Agora roda no loop para pegar respawn)
local function UpdateMobList()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            -- Adiciona checkbox se não tiver
            if not Scroll:FindFirstChild(mob.Name) then
                local Btn = Instance.new("TextButton", Scroll)
                Btn.Name = mob.Name
                Btn.Size = UDim2.new(1, 0, 0, 25)
                Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                Btn.Text = " [ ] " .. mob.Name
                Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                Btn.MouseButton1Click:Connect(function()
                    SelectedMobs[mob.Name] = not SelectedMobs[mob.Name]
                    if SelectedMobs[mob.Name] then
                        Btn.Text = " [X] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                    else
                        Btn.Text = " [ ] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    end
                end)
            end
        end
    end
end

-- Loop Principal (Hitbox + Magnet)
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    
    -- Atualiza lista de tempos em tempos (gambiarra simples)
    if math.random(1, 100) == 1 then UpdateMobList() end

    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            
            -- 1. APLICA HITBOX (Se ativo e selecionado ou todos)
            if IsHitboxActive then
                ExpandHitbox(mob)
            end
            
            -- 2. APLICA ÍMÃ SEGURO
            if IsMagnetActive and SelectedMobs[mob.Name] then
                local myRoot = char.HumanoidRootPart
                local mobRoot = mob.HumanoidRootPart
                
                local dist = (myRoot.Position - mobRoot.Position).Magnitude
                
                if dist <= SETTINGS.MagnetRange then
                    -- LÓGICA DE OURO: Mantém ele na sua frente, mas TRAVADO na distância segura
                    -- CFrame.new(0, 0, -25) significa "25 passos na minha frente"
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.SafeDistance)
                    
                    -- Zera velocidade pra ele não bugar voando
                    mobRoot.Velocity = Vector3.new(0,0,0)
                    mobRoot.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end
    end
end)

-- // EVENTOS //
HitboxBtn.MouseButton1Click:Connect(function()
    IsHitboxActive = not IsHitboxActive
    if IsHitboxActive then
        HitboxBtn.Text = "HITBOX ATIVADA (60x60)"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        HitboxBtn.Text = "1. ATIVAR HITBOX GIGANTE"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

MagnetBtn.MouseButton1Click:Connect(function()
    IsMagnetActive = not IsMagnetActive
    if IsMagnetActive then
        MagnetBtn.Text = "ÍMÃ SEGURO LIGADO"
        MagnetBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        MagnetBtn.Text = "2. LIGAR ÍMÃ DE SEGURANÇA"
        MagnetBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    IsHitboxActive = false
    IsMagnetActive = false
end)