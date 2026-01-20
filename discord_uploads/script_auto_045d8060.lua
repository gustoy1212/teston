--[[
    🧲 ZOMBIE MAGNET v4.0 - MODO FILA (1 por 1)
    
    Mudanças:
    - Foco Único: Puxa um mob de cada vez.
    - PivotTo: Usa sistema de movimento de modelo (mais forte que CFrame).
    - Auto-Switch: Detecta morte (HP=0) e puxa o próximo da fila.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieMagnetV4"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 150) -- Menor e mais compacto
MainFrame.Position = UDim2.new(0.5, -175, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧬 MAGNETO 1-por-1 (v4)"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

-- STATUS DO ALVO
local TargetLabel = Instance.new("TextLabel", MainFrame)
TargetLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
TargetLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
TargetLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TargetLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
TargetLabel.Text = "Alvo: Nenhum"
TargetLabel.Font = Enum.Font.Code
TargetLabel.TextScaled = true

-- BOTÃO TOGGLE
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.45, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "DESLIGADO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
CloseBtn.Position = UDim2.new(0.55, 0, 0.6, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // LÓGICA 1 POR 1 //
local Active = false
local CurrentTarget = nil
local LoopConnection = nil

local function IsAlive(mob)
    if not mob then return false end
    if not mob:IsDescendantOf(Workspace) then return false end
    
    -- Checa atributo HP (baseado nas suas prints)
    local hp = mob:GetAttribute("HP")
    if hp and hp <= 0 then return false end
    
    -- Checa Humanoid padrão (caso o atributo falhe)
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    
    return true
end

local function GetClosestTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local closest = nil
    local minDist = 99999
    
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return nil end
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root and IsAlive(mob) then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    
    return closest
end

local function GameLoop()
    if not Active then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    
    -- 1. Se não temos alvo ou o alvo morreu, busca novo
    if not CurrentTarget or not IsAlive(CurrentTarget) then
        CurrentTarget = GetClosestTarget()
        if CurrentTarget then
            TargetLabel.Text = "Alvo: " .. CurrentTarget.Name .. " (HP: " .. tostring(CurrentTarget:GetAttribute("HP") or "?") .. ")"
            TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo (Novo alvo)
        else
            TargetLabel.Text = "Procurando alvos..."
            TargetLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    
    -- 2. Se temos um alvo válido, traz ele pra perto
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local targetRoot = CurrentTarget.HumanoidRootPart
        
        -- Posição: 4 studs na frente do player, na altura do player
        local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
        
        -- Resetar rotação para ele ficar de frente pra você (opcional, ajuda a bater)
        local lookAt = CFrame.lookAt(targetCFrame.Position, myRoot.Position)
        
        -- USA PIVOT TO (Mais forte para mover Models)
        CurrentTarget:PivotTo(lookAt)
        
        -- Tenta anular a física dele para ele não cair ou voar
        targetRoot.Velocity = Vector3.new(0,0,0)
        targetRoot.RotVelocity = Vector3.new(0,0,0)
        
        TargetLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Verde (Travado)
    end
end

-- // BOTÕES //
ToggleBtn.MouseButton1Click:Connect(function()
    Active = not Active
    if Active then
        ToggleBtn.Text = "LIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        LoopConnection = RunService.Heartbeat:Connect(GameLoop)
    else
        ToggleBtn.Text = "DESLIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        if LoopConnection then LoopConnection:Disconnect() end
        CurrentTarget = nil
        TargetLabel.Text = "Pausado"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if LoopConnection then LoopConnection:Disconnect() end
    ScreenGui:Destroy()
end)