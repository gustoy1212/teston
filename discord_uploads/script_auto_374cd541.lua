--[[
    📶 BLOX FRUITS - WIFI DAMAGE v6 (REACH + PACIFY)
    
    COMO FUNCIONA:
    1. REACH: Aumenta a Hitbox da SUA ARMA (não do mob). Você acerta de longe.
    2. PACIFY: Deleta o "Animator" dos mobs. Eles deslizam e não te batem.
    3. SAFE MAGNET: Traz eles para 15 studs de distância (onde seu Reach alcança).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local REACH_SIZE = 40       -- Tamanho da sua espada (40 studs = Dano Wi-Fi)
local SAFE_DIST = 15        -- Distância que os mobs ficam de você
local MAGNET_RANGE = 350    -- Alcance para puxar

-- Estados
local IsFarming = false
local IsAutoClick = true
local SelectedMobs = {} 

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxWifiUI") then CoreGui.BloxWifiUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxWifiUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 340)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano (Tech/WiFi)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "📶 WIFI DAMAGE v6"
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ScanBtn.Text = "1. SCANEAR ÁREA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Ativar
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.72, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "2. LIGAR WIFI KILL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18

-- Status Checkbox
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 25)
ClickBox.Position = UDim2.new(0.05, 0, 0.88, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBox.Text = "Auto Click: LIGADO"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 100)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.45, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.25, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES ESPECIAIS //

-- 1. REACH (O Segredo do WiFi)
-- Aumenta a hitbox da ferramenta que você está segurando
local function ApplyReach()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        -- Procura o Handle ou Hitbox
        local handle = tool:FindFirstChild("Handle")
        if handle then
            -- Cria uma SelectionBox se não tiver (Visual e ajuda no hit)
            if not handle:FindFirstChild("ReachBox") then
                local box = Instance.new("SelectionBox", handle)
                box.Name = "ReachBox"
                box.Adornee = handle
                box.Size3 = Vector3.new(REACH_SIZE, REACH_SIZE, REACH_SIZE)
                box.Transparency = 0.8
                box.Color3 = Color3.fromRGB(0, 255, 255)
            end
            
            -- O Pulo do Gato: Muda o Size físico para colidir
            -- Blox Fruits às vezes reseta isso, então rodamos em loop
            handle.Size = Vector3.new(REACH_SIZE, REACH_SIZE, REACH_SIZE)
            handle.Massless = true -- Pra não pesar sua mão
            handle.CanCollide = false
        end
    end
end

-- 2. PACIFIER (Quebra a IA do Mob)
local function PacifyMob(mob)
    local hum = mob:FindFirstChild("Humanoid")
    if hum then
        -- Remove o Animator: Mob para de rodar animação de ataque
        local animator = hum:FindFirstChild("Animator")
        if animator then animator:Destroy() end
        
        -- Tenta desequipar a arma do mob
        pcall(function() hum:UnequipTools() end)
    end
end

-- 3. SCANNER
local function ScanMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            if not Scroll:FindFirstChild(mob.Name) then
                local Btn = Instance.new("TextButton", Scroll)
                Btn.Name = mob.Name
                Btn.Size = UDim2.new(1, 0, 0, 25)
                Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                Btn.Text = " [ ] " .. mob.Name
                Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                Btn.MouseButton1Click:Connect(function()
                    if SelectedMobs[mob.Name] then
                        SelectedMobs[mob.Name] = false
                        Btn.Text = " [ ] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    else
                        SelectedMobs[mob.Name] = true
                        Btn.Text = " [X] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                    end
                end)
            end
        end
    end
end

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    if not IsFarming then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    
    -- Aplica Reach na arma atual constantemente
    ApplyReach()
    
    -- Auto Click
    if IsAutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end

    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            
            local mobRoot = mob.HumanoidRootPart
            local dist = (myRoot.Position - mobRoot.Position).Magnitude
            
            -- LÓGICA DO ÍMÃ SEGURO
            if dist <= MAGNET_RANGE then
                -- Quebra o mob pra ele não atacar
                PacifyMob(mob)
                
                -- Traz ele, mas TRAVA na distância segura (15 studs)
                -- Assim seu Reach pega ele, mas o soco dele não pega você
                mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -SAFE_DIST)
                mobRoot.Velocity = Vector3.new(0,0,0)
                mobRoot.RotVelocity = Vector3.new(0,0,0)
                
                -- Vira o mob de costas (Backstab extra safety)
                mobRoot.CFrame = CFrame.lookAt(mobRoot.Position, myRoot.Position) * CFrame.Angles(0, math.pi, 0)
            end
        end
    end
end)

-- // EVENTOS //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "WIFI ATIVADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "2. LIGAR WIFI KILL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
end)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "Auto Click: LIGADO"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        ClickBox.Text = "Auto Click: DESLIGADO"
        ClickBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    ScreenGui:Destroy()
end)