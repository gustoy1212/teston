--[[
    🕳️ ZOMBIE BLACK HOLE v8.0
    
    A Fusão Perfeita:
    1. PUXAR (TP): Traz os mobs para a sua posição (Resolve a validação de distância do servidor).
    2. GIGANTE (Size): Deixa eles enormes (100 studs) para garantir que o hit conte.
    3. SEM COLISÃO: Desativa a colisão para você não ser empurrado pelos cubos gigantes.
    
    Resultado: Uma chuva de zumbis gigantes caindo na sua espada.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieBlackHoleV8"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255) -- Roxo Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🕳️ BURACO NEGRO (v8)"
Title.TextColor3 = Color3.fromRGB(180, 100, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
StatusLbl.Position = UDim2.new(0.05, 0, 0.2, 0)
StatusLbl.Text = "Status: Aguardando ativação..."
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true
StatusLbl.Font = Enum.Font.Code

-- BOTÃO ATIVAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "ATIVAR BURACO NEGRO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "FECHAR SCRIPT"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // CONFIGURAÇÕES //
local HITBOX_SIZE = Vector3.new(80, 80, 80) -- Cubo de 80 studs (Enorme, mas não trava o PC)
local PULL_RADIUS = 5 -- Traz eles para 5 studs de você

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

-- // LOOP PRINCIPAL //
local function Loop()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return end
    
    local count = 0
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if IsAlive(mob) then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                -- 1. PUXAR (Teleporte contínuo para o player)
                -- Traz para o mesmo lugar que você, levemente ajustado
                local targetPos = myRoot.CFrame * CFrame.new(0, 0, -PULL_RADIUS)
                
                -- Usa PivotTo para mover o modelo todo (mais estável)
                mob:PivotTo(targetPos)
                
                -- Tira a velocidade para ele não sair voando
                mobRoot.Velocity = Vector3.new(0,0,0)
                mobRoot.RotVelocity = Vector3.new(0,0,0)
                
                -- 2. HITBOX GIGANTE
                mobRoot.Size = HITBOX_SIZE
                mobRoot.Transparency = 0.7 -- Transparente pra você ver o que tá rolando
                mobRoot.Color = Color3.fromRGB(100, 0, 255) -- Roxo
                mobRoot.CanCollide = false -- MUITO IMPORTANTE: Sem isso você é jogado pro espaço
                
                -- 3. REMOVER TEXTURAS (Opcional, ajuda a ver a hitbox)
                -- Se tiver mesh, deixamos visível só a caixa
                
                count = count + 1
            end
        end
    end
    
    if count > 0 then
        StatusLbl.Text = "🌪️ Sugando " .. count .. " Mobs!\nAtaque a nuvem roxa!"
        StatusLbl.TextColor3 = Color3.fromRGB(150, 50, 255)
    else
        StatusLbl.Text = "💤 Nenhum mob vivo..."
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- // EVENTOS //
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "⚫ MODO BURACO NEGRO: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
        -- Heartbeat: Executa todo frame de física
        Connection = RunService.Heartbeat:Connect(Loop)
    else
        ToggleBtn.Text = "ATIVAR BURACO NEGRO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        StatusLbl.Text = "Pausado."
        if Connection then Connection:Disconnect() end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)