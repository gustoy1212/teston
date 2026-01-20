--[[
    🌍 ZOMBIE MAGNET v7.0 - WORLD EATER HITBOX
    
    Solução Final para Mapa Grande + Lag:
    - HITBOX COLOSSAL: Transforma a peça central do zumbi num cubo de 500x500x500.
    - POSICIONAMENTO: Centraliza esse cubo gigante EXATAMENTE no seu personagem.
    - É praticamente impossível errar o golpe, pois a área de dano cobre o mapa quase todo ao seu redor.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieWorldEaterV7"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 180)
MainFrame.Position = UDim2.new(0.5, -175, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50) -- Vermelho Sangue
MainFrame.BorderSizePixel = 3
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🌍 DEVORADOR DE MUNDOS (v7)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
StatusLbl.Position = UDim2.new(0.05, 0, 0.25, 0)
StatusLbl.Text = "Status: Aguardando..."
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true
StatusLbl.Font = Enum.Font.Code

-- BOTÃO ATIVAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "ATIVAR HITBOX COLOSSAL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // CONFIGURAÇÕES //
-- 500 é um tamanho absurdo de grande. Se der lag, diminua para 200.
local COLOSSAL_SIZE = Vector3.new(500, 500, 500) 

local Active = false
local Connection = nil

-- // FUNÇÃO DE VIDA //
local function IsAlive(mob)
    if not mob or not mob.Parent then return false end
    local hp = mob:GetAttribute("HP")
    if hp and hp <= 0 then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

-- // LOOP PRINCIPAL (HEARTBEAT) //
local function Loop()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return end
    
    local modifiedCount = 0
    
    -- Varre todos os mobs vivos
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if IsAlive(mob) then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                -- 1. APLICA O TAMANHO COLOSSAL
                mobRoot.Size = COLOSSAL_SIZE
                mobRoot.CanCollide = false -- Essencial pra não travar seu boneco
                mobRoot.Transparency = 0.85 -- Bem transparente pra não poluir a tela
                mobRoot.Color = Color3.fromRGB(255, 50, 50) -- Vermelho gigante
                
                -- 2. TELEPORTA O CENTRO DO CUBO GIGANTE PARA O SEU CORPO
                -- Não na frente, mas EXATAMENTE onde você está.
                -- Assim, você está no centro de uma área de dano de 500 metros.
                mobRoot.CFrame = myRoot.CFrame
                
                -- Tira a física
                mobRoot.Velocity = Vector3.new(0,0,0)
                mobRoot.RotVelocity = Vector3.new(0,0,0)
                
                modifiedCount = modifiedCount + 1
            end
        end
    end
    
    if modifiedCount > 0 then
        StatusLbl.Text = "🔥 " .. modifiedCount .. " Hitboxes Colossais ativas!\nBata em qualquer lugar!"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
    else
        StatusLbl.Text = "💤 Nenhum mob vivo encontrado."
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- // EVENTOS //
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "LIGADO (MODO COLOSSAL)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Vermelho forte
        -- Usa Heartbeat para máxima prioridade de física
        Connection = RunService.Heartbeat:Connect(Loop)
    else
        ToggleBtn.Text = "ATIVAR HITBOX COLOSSAL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLbl.Text = "Pausado."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        if Connection then Connection:Disconnect() end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)