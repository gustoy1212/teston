--[[
    🎣 ZOMBIE HOOK v5.0 (O Pescador)
    
    Correção do Bug de Hit:
    - O script vai até o zumbi rapidinho para "validar" a posição.
    - Traz o zumbi e você de volta para a Base Segura.
    - Mantém o zumbi preso na sua frente até morrer.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieHookV5"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 170, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎣 O PESCADOR (v5)"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0.2, 0)
StatusLbl.Position = UDim2.new(0.05, 0, 0.2, 0)
StatusLbl.Text = "1. Fique num lugar seguro\n2. Clique em 'DEFINIR BASE'"
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true

-- BOTÃO DEFINIR BASE
local SetBaseBtn = Instance.new("TextButton", MainFrame)
SetBaseBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
SetBaseBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
SetBaseBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
SetBaseBtn.Text = "📍 DEFINIR BASE AQUI"
SetBaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetBaseBtn.Font = Enum.Font.GothamBold

-- BOTÃO ATIVAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.45, 0, 0.2, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "DESLIGADO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
CloseBtn.Position = UDim2.new(0.55, 0, 0.7, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // VARIÁVEIS //
local BaseCFrame = nil
local Active = false
local CurrentTarget = nil
local LoopConnection = nil
local IsFetching = false -- Se está indo buscar o bicho

-- // FUNÇÕES //

local function IsAlive(mob)
    if not mob or not mob.Parent then return false end
    local hp = mob:GetAttribute("HP")
    if hp and hp <= 0 then return false end
    
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    
    return true
end

local function GetClosestTarget()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return nil end
    
    local closest = nil
    local minDist = 99999
    
    -- Se tivermos uma Base definida, procura o mais perto da BASE, não do player (para não ficar trocando)
    local searchPoint = BaseCFrame and BaseCFrame.Position or myRoot.Position
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root and IsAlive(mob) then
            local dist = (root.Position - searchPoint).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    return closest
end

local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

local function BringMob(mob, targetCFrame)
    if mob and mob:FindFirstChild("HumanoidRootPart") then
        mob:PivotTo(targetCFrame)
        mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        mob.HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
    end
end

local function Loop()
    if not Active or not BaseCFrame then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- 1. Verifica alvo atual
    if not CurrentTarget or not IsAlive(CurrentTarget) then
        CurrentTarget = GetClosestTarget()
        IsFetching = true -- Precisa buscar o novo alvo
    end
    
    if CurrentTarget then
        local mobRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
        if mobRoot then
            local distFromBase = (mobRoot.Position - BaseCFrame.Position).Magnitude
            
            -- Se o bicho está longe da base (> 10 studs), vamos BUSCAR
            if distFromBase > 15 and IsFetching then
                StatusLbl.Text = "🎣 Pescando: " .. CurrentTarget.Name
                
                -- A. Vai até o bicho (TP Player)
                TeleportTo(mobRoot.CFrame * CFrame.new(0,0,2))
                
                -- B. Puxa o bicho pro Player (Garante ownership)
                BringMob(CurrentTarget, char.HumanoidRootPart.CFrame * CFrame.new(0,0,-3))
                
                -- C. Volta pra base COM o bicho
                TeleportTo(BaseCFrame)
                BringMob(CurrentTarget, BaseCFrame * CFrame.new(0,0,-4))
                
                IsFetching = false -- Já pescou
            else
                -- D. Mantém ele preso na base para matar
                StatusLbl.Text = "⚔️ Mate agora! (HP: " .. tostring(CurrentTarget:GetAttribute("HP") or "?") .. ")"
                
                -- Garante que o player fique na base
                TeleportTo(BaseCFrame)
                -- Garante que o bicho fique na frente
                BringMob(CurrentTarget, BaseCFrame * CFrame.new(0,0,-4))
            end
        end
    else
        StatusLbl.Text = "💤 Nenhum zumbi encontrado..."
        IsFetching = true
    end
end

-- // EVENTOS //
SetBaseBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        BaseCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        SetBaseBtn.Text = "✅ BASE DEFINIDA!"
        SetBaseBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        StatusLbl.Text = "Pode ativar o script agora."
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if not BaseCFrame then
        StatusLbl.Text = "❌ DEFINA A BASE PRIMEIRO!"
        return
    end

    Active = not Active
    if Active then
        ToggleBtn.Text = "LIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        -- Loop rápido (Heartbeat) para travar posição
        LoopConnection = RunService.Heartbeat:Connect(Loop)
    else
        ToggleBtn.Text = "DESLIGADO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        if LoopConnection then LoopConnection:Disconnect() end
        StatusLbl.Text = "Pausado."
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if LoopConnection then LoopConnection:Disconnect() end
    ScreenGui:Destroy()
end)