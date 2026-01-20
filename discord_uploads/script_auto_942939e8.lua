--[[
    ⚡ THE FLASH AUTO-FARM v9.0
    
    Mudança de Estratégia:
    - Já que o servidor não deixa puxar os mobs de longe...
    - Nós vamos até eles, matamos e vamos para o próximo.
    - Tudo automático.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlashFarmV9"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 0) -- Amarelo Escuro
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ THE FLASH FARM (v9)"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0.3, 0)
StatusLbl.Position = UDim2.new(0.05, 0, 0.25, 0)
StatusLbl.Text = "Segure sua espada e ative!"
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true

-- BOTÃO ATIVAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "ATIVAR AUTO-FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // VARIÁVEIS //
local Active = false
local Connection = nil
local CurrentTarget = nil

-- // FUNÇÃO DE VIDA //
local function IsAlive(mob)
    if not mob or not mob.Parent then return false end
    local hp = mob:GetAttribute("HP") -- Seu jogo usa esse atributo
    if hp and hp <= 0 then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

-- // AUTO CLICK //
local function Attack()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(800, 600))
    end)
    
    -- Tenta ativar a ferramenta se tiver
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        end
    end
end

-- // BUSCAR PRÓXIMO ALVO //
local function GetNextTarget()
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return nil end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = 99999
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if IsAlive(mob) and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - myPos).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    return closest
end

-- // LOOP PRINCIPAL //
local function FarmLoop()
    if not Active then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    
    -- Se não tiver alvo ou alvo morreu, busca outro
    if not CurrentTarget or not IsAlive(CurrentTarget) then
        CurrentTarget = GetNextTarget()
        if not CurrentTarget then
            StatusLbl.Text = "💤 Nenhum mob vivo..."
            return
        end
        StatusLbl.Text = "⚔️ Matando: " .. CurrentTarget.Name
    end
    
    -- Lógica de Ataque
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetRoot = CurrentTarget.HumanoidRootPart
        
        -- 1. TELEPORTA PARA TRÁS DO MOB (Ponto cego)
        -- Fica 3 studs atrás dele e olhando pra ele
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3) 
        
        -- 2. TIRA VELOCIDADE (Pra você não cair do mundo)
        myRoot.Velocity = Vector3.new(0,0,0)
        
        -- 3. BATE
        Attack()
    end
end

-- // EVENTOS //
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "⚡ FARMANDO..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
        StatusLbl.Text = "Iniciando..."
        -- Loop rápido
        Connection = RunService.Heartbeat:Connect(FarmLoop)
    else
        ToggleBtn.Text = "ATIVAR AUTO-FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatusLbl.Text = "Pausado."
        if Connection then Connection:Disconnect() end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)