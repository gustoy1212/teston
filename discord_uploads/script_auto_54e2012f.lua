--[[
    🏴‍☠️ BLOX FRUITS - MAGNET v2 (SAFE MODE)
    
    NOVIDADES:
    1. PLATAFORMA SAFE: Cria um chão invisível no ar para você não tomar dano.
    2. ÍMÃ REVERSO: Puxa os mobs para BAIXO da sua plataforma.
    3. AUTO CLICK: Bate sozinho enquanto você farma.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local MAGNET_RANGE = 300 
local SAFE_HEIGHT = 14   -- Altura que você fica do chão (14 studs é seguro pra Bandidos)
local HOLD_DIST_Y = -14  -- Onde o mob fica em relação a você (embaixo)

-- Estado
local SelectedMobs = {} 
local IsMagnetActive = false
local IsBaseActive = false
local IsAutoClick = false
local SafePlatform = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxMagnetUI") then CoreGui.BloxMagnetUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxMagnetUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 360) -- Aumentei um pouco
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🛡️ MAGNET SAFE v2"
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ScanBtn.Text = "1. SCANEAR MOBS"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Base (Segurança)
local BaseBtn = Instance.new("TextButton", MainFrame)
BaseBtn.Size = UDim2.new(0.9, 0, 0, 30)
BaseBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
BaseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
BaseBtn.Text = "2. SUBIR BASE (SAFE)"
BaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BaseBtn.Font = Enum.Font.GothamBold

-- Botão Ímã
local ToggleMagnet = Instance.new("TextButton", MainFrame)
ToggleMagnet.Size = UDim2.new(0.44, 0, 0, 30)
ToggleMagnet.Position = UDim2.new(0.05, 0, 0.86, 0)
ToggleMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleMagnet.Text = "3. ÍMÃ"
ToggleMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMagnet.Font = Enum.Font.GothamBold

-- Botão Auto Click
local ToggleClick = Instance.new("TextButton", MainFrame)
ToggleClick.Size = UDim2.new(0.44, 0, 0, 30)
ToggleClick.Position = UDim2.new(0.51, 0, 0.86, 0)
ToggleClick.BackgroundColor3 = Color3.fromRGB(150, 80, 0)
ToggleClick.Text = "4. ATACAR"
ToggleClick.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleClick.Font = Enum.Font.GothamBold

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.53, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.2, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Scroll.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES //

local function CreateCheckbox(mobName)
    if Scroll:FindFirstChild(mobName) then return end
    local Btn = Instance.new("TextButton", Scroll)
    Btn.Name = mobName
    Btn.Size = UDim2.new(1, 0, 0, 25)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Btn.Text = " [ ] " .. mobName
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Font = Enum.Font.SourceSansBold
    
    Btn.MouseButton1Click:Connect(function()
        if SelectedMobs[mobName] then
            SelectedMobs[mobName] = false
            Btn.Text = " [ ] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            SelectedMobs[mobName] = true
            Btn.Text = " [X] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)
end

local function ScanMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    local uniqueNames = {}
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            if not uniqueNames[mob.Name] then
                uniqueNames[mob.Name] = true
                CreateCheckbox(mob.Name)
            end
        end
    end
end

-- CRIA A BASE SEGURA
local function ToggleBase(enable)
    if enable then
        if not SafePlatform then
            local p = Instance.new("Part", Workspace)
            p.Name = "SafeFarmPlatform"
            p.Size = Vector3.new(20, 1, 20)
            p.Anchored = true
            p.Transparency = 0.5
            p.Color = Color3.fromRGB(0, 255, 100)
            p.Material = Enum.Material.Neon
            
            -- Posiciona acima da cabeça do player
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                p.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, SAFE_HEIGHT, 0)
                -- Teleporta player pra cima
                char.HumanoidRootPart.CFrame = p.CFrame * CFrame.new(0, 3, 0)
            end
            SafePlatform = p
        end
    else
        if SafePlatform then
            SafePlatform:Destroy()
            SafePlatform = nil
        end
    end
end

-- ÍMÃ
local function MagnetLoop()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                local mobRoot = mob.HumanoidRootPart
                local dist = (myRoot.Position - mobRoot.Position).Magnitude
                
                if dist <= MAGNET_RANGE then
                    -- PUXA PARA BAIXO DA BASE (Onde você pode bater, mas eles não te alcançam)
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, HOLD_DIST_Y, 0)
                    mobRoot.Velocity = Vector3.new(0,0,0)
                    mob.Humanoid.Sit = true -- Tenta sentar o bicho pra ele não pular
                end
            end
        end
    end
end

-- AUTO CLICKER
local function AutoClickLoop()
    -- Simula clique
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // EVENTOS //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

BaseBtn.MouseButton1Click:Connect(function()
    IsBaseActive = not IsBaseActive
    if IsBaseActive then
        BaseBtn.Text = "DESCER DA BASE"
        BaseBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        ToggleBase(true)
    else
        BaseBtn.Text = "2. SUBIR BASE (SAFE)"
        BaseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        ToggleBase(false)
    end
end)

ToggleMagnet.MouseButton1Click:Connect(function()
    IsMagnetActive = not IsMagnetActive
    if IsMagnetActive then
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

ToggleClick.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ToggleClick.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ToggleClick.BackgroundColor3 = Color3.fromRGB(150, 80, 0)
    end
end)

-- Loop Principal
RunService.Stepped:Connect(function()
    if IsMagnetActive then MagnetLoop() end
    if IsAutoClick then AutoClickLoop() end
    
    -- Mantém a plataforma perto do player se ele andar, mas mantém a altura
    if IsBaseActive and SafePlatform and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        -- A plataforma só ajusta X e Z, o Y fica fixo onde foi criada pra não bugar
        SafePlatform.Position = Vector3.new(myPos.X, SafePlatform.Position.Y, myPos.Z)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsBaseActive = false
    ToggleBase(false)
    ScreenGui:Destroy()
end)