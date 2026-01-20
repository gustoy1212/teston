--[[
    ⚔️ RPG HUNTER v2 (SPIRIT BLADE)
    
    SOLUÇÃO DE DANO FALSO:
    - Visual: Traz o inimigo para perto (Cliente).
    - Físico: Manda a ARMA (Handle) até a posição real do inimigo (Servidor).
    
    ALVO: Workspace.SpawnedEntities (Lobo, Galinha, Slime...)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().HunterV2 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    VisualDist = 4,       -- Distância visual na sua frente
    RealHitDist = 0,      -- Distância da espada no inimigo real (0 = dentro dele)
    SearchRange = 5000,
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalPos = nil -- Guarda onde o bicho está de verdade

-- // GUI SETUP //
if CoreGui:FindFirstChild("HunterV2UI") then CoreGui.HunterV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "HunterV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
MainFrame.BorderColor3 = Color3.fromRGB(150, 50, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ SPIRIT BLADE (1v1)"
Title.TextColor3 = Color3.fromRGB(150, 50, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
ToggleBtn.Text = "LIGAR ESPADA FANTASMA"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function ResetTarget()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") and OriginalPos then
        -- Tenta devolver o bicho pro lugar (pra não bugar respawn)
        CurrentTarget.HumanoidRootPart.CFrame = OriginalPos
        CurrentTarget.HumanoidRootPart.Transparency = 0
    end
    CurrentTarget = nil
    OriginalPos = nil
    
    -- Reseta a arma
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool.Parent = LocalPlayer.Backpack tool.Parent = char end
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().HunterV2 = false
    ResetTarget()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        ToggleBtn.Text = "LIGAR ESPADA FANTASMA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
        ResetTarget()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().HunterV2 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 1. GERENCIA ALVO
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
        
        if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
            ResetTarget() -- Morreu
        else
            Status.Text = "⚔️ MATANDO: " .. CurrentTarget.Name
            
            -- [CLIENTE] Traz pra perto (Visual)
            local visualPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -SETTINGS.VisualDist)
            root.CFrame = visualPos
            root.Velocity = Vector3.new(0,0,0)
            root.CanCollide = false
            root.Transparency = 0.5 -- Fantasma
            
            -- [SERVIDOR] Manda a espada pra posição REAL (OriginalPos)
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") and OriginalPos then
                tool.Handle.Massless = true
                -- Teleporta Handle para a posição original do monstro
                tool.Handle.CFrame = OriginalPos * CFrame.new(0, 0, SETTINGS.RealHitDist)
                
                -- Auto Activate (Opcional, se você não quiser clicar)
                tool:Activate()
                
                -- Force Touch (Garantia Extra)
                if firetouchinterest then
                    firetouchinterest(tool.Handle, root, 0)
                    firetouchinterest(tool.Handle, root, 1)
                end
            else
                Status.Text = "⚠️ EQUIPE UMA ARMA!"
            end
            
            return
        end
    end
    
    -- 2. BUSCA NOVO
    local folder = Workspace:FindFirstChild("SpawnedEntities")
    if not folder then return end
    
    local closest, minDist = nil, SETTINGS.SearchRange
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    
    if closest then
        CurrentTarget = closest
        OriginalPos = closest.HumanoidRootPart.CFrame -- Salva onde ele está de verdade
    else
        Status.Text = "Procurando..."
    end
end)