--[[
    📶 BLOX FRUITS - WIFI REACH v7 (TRUE RANGE)
    
    LÓGICA:
    1. Não move o jogador.
    2. Não move os mobs (eles ficam no spawn).
    3. Aumenta a HITBOX DA SUA ARMA para 60 studs.
    4. Spama o evento de toque (TouchInterest) nos inimigos próximos.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local REACH_SIZE = 60       -- Alcance do Wifi (60 studs é seguro, acima disso pode dar 0 dano)
local ATTACK_SPEED = 0.1    -- Velocidade do Spam

-- Estados
local IsFarming = false
local IsAutoClick = true

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxReachUI") then CoreGui.BloxReachUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxReachUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "📶 WIFI REACH v7"
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20

-- Status
local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.Text = "Status: Arma Normal"
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.BackgroundTransparency = 1

-- Botão Ativar
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "LIGAR WIFI (REACH)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18

-- Botão Auto Click
local ClickBtn = Instance.new("TextButton", MainFrame)
ClickBtn.Size = UDim2.new(0.9, 0, 0, 30)
ClickBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
ClickBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBtn.Text = "Auto Click: LIGADO"
ClickBtn.TextColor3 = Color3.fromRGB(0, 255, 100)

-- // FUNÇÕES MÁGICAS //

-- Aumenta a Hitbox da ferramenta atual
local function ExpandToolHitbox()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    -- Procura o Handle (Cabo da espada/mão)
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle") -- "Middle" veio do seu log
    
    if handle then
        -- Cria visualizador (Box Azul) pra vc ver o alcance
        if not handle:FindFirstChild("WifiBox") then
            local box = Instance.new("SelectionBox", handle)
            box.Name = "WifiBox"
            box.Adornee = handle
            box.Size3 = Vector3.new(REACH_SIZE, REACH_SIZE, REACH_SIZE)
            box.Transparency = 0.8
            box.Color3 = Color3.fromRGB(0, 255, 255)
        end
        
        -- A Mágica: Aumenta o tamanho físico sem mudar o visual da espada
        handle.Massless = true
        handle.Size = Vector3.new(REACH_SIZE, REACH_SIZE, REACH_SIZE)
        handle.CanCollide = false -- Pra não travar na parede
    end
end

-- Simula o toque da espada no inimigo (Log Based)
local function SpamTouch()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle")
    if not handle then return end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end

    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            
            local myRoot = char.HumanoidRootPart
            local mobRoot = mob.HumanoidRootPart
            local dist = (myRoot.Position - mobRoot.Position).Magnitude
            
            -- Só ataca quem está dentro do alcance do Wifi
            if dist <= REACH_SIZE then
                -- Se o executor suportar, força o evento de toque
                if firetouchinterest then
                    firetouchinterest(handle, mobRoot, 0) -- Toca
                    firetouchinterest(handle, mobRoot, 1) -- Solta
                end
            end
        end
    end
end

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    if IsFarming then
        -- 1. Mantém a espada gigante
        ExpandToolHitbox()
        
        -- 2. Spama o evento de toque
        SpamTouch()
        
        -- 3. Auto Click (Necessário pro jogo validar o dano)
        if IsAutoClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        
        StatusLbl.Text = "Status: 📡 WIFI ATIVO (Alcance: " .. REACH_SIZE .. ")"
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
    else
        StatusLbl.Text = "Status: Arma Normal"
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        
        -- Reseta tamanho (visual)
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then 
                    handle.Size = Vector3.new(1, 1, 4) -- Tamanho normal +/-
                    if handle:FindFirstChild("WifiBox") then handle.WifiBox:Destroy() end
                end
            end
        end
    end
end)

-- // EVENTOS UI //
ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR WIFI"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR WIFI (REACH)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
end)

ClickBtn.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBtn.Text = "Auto Click: LIGADO"
        ClickBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        ClickBtn.Text = "Auto Click: DESLIGADO"
        ClickBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
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