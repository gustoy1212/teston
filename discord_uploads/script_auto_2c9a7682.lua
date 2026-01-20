--[[
    🧟 ZOMBIE MAGNET v6.0 - HITBOX EXPANDER
    
    Correção para Ping Alto / Desync:
    - Não move seu personagem.
    - Puxa o zumbi visualmente.
    - AUMENTA A HITBOX DO ZUMBI (Size 50x50x50).
    - Isso permite acertar o zumbi mesmo se o servidor achar que ele está longe.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieHitboxV6"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Roxo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧟 HITBOX EXPANDER (v6)"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
StatusLbl.Position = UDim2.new(0.05, 0, 0.25, 0)
StatusLbl.Text = "Status: Parado"
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true

-- BOTÃO ATIVAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "ATIVAR PUXADOR + HITBOX"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // CONFIGURAÇÕES //
local HITBOX_SIZE = Vector3.new(40, 40, 40) -- Tamanho gigante (Cubo de 40 studs)
local PULL_DISTANCE = 5 -- Distância visual (5 studs na frente)

local Active = false
local Connection = nil

-- // FUNÇÃO DE VIDA //
local function IsAlive(mob)
    if not mob or not mob.Parent then return false end
    
    -- Checagem de Atributo HP (do seu jogo específico)
    local hp = mob:GetAttribute("HP")
    if hp and hp <= 0 then return false end
    
    -- Checagem Padrão Roblox
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    
    return true
end

-- // LOOP PRINCIPAL //
local function Loop()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return end
    
    local draggedCount = 0
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if IsAlive(mob) then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                -- 1. PUXAR (Visual / Client)
                -- Traz o mob para perto de você
                mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -PULL_DISTANCE)
                
                -- Tira a física pra ele não cair
                mobRoot.Velocity = Vector3.new(0,0,0)
                mobRoot.RotVelocity = Vector3.new(0,0,0)
                
                -- 2. HITBOX EXPANDER (O Segredo!)
                -- Transforma a peça principal num cubo gigante fantasma
                mobRoot.Size = HITBOX_SIZE
                mobRoot.CanCollide = false -- Importante: Pra não te empurrar/voar
                mobRoot.Transparency = 0.7 -- Meio invisível pra você conseguir ver
                mobRoot.Color = Color3.fromRGB(255, 0, 255) -- Fica roxo pra você saber que funcionou
                
                draggedCount = draggedCount + 1
            end
        end
    end
    
    if draggedCount > 0 then
        StatusLbl.Text = "🔮 Puxando " .. draggedCount .. " mobs\n(Bata no cubo roxo!)"
    else
        StatusLbl.Text = "💤 Procurando mobs..."
    end
end

-- // EVENTOS //
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "LIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 255) -- Roxo
        -- Heartbeat roda todo frame físico (super rápido)
        Connection = RunService.Heartbeat:Connect(Loop)
    else
        ToggleBtn.Text = "DESLIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLbl.Text = "Pausado"
        if Connection then Connection:Disconnect() end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)