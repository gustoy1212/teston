--[[
    🤖 SAO LEGIT BOT v1 (WALK & KILL)
    
    SOLUÇÃO "ANTI-KICK" DEFINITIVA:
    - Respeita as regras do jogo: Anda até o inimigo em vez de teleportar.
    - 100% Seguro em Servidor Público (Parece um jogador normal farmando).
    - Resolve o erro de "Distance" pois ataca fisicamente de perto.
    
    ALVO: Workspace.Mobs
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().LegitBot = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,       -- Distância para parar de andar e bater
    SearchRange = 3000,   -- Raio de busca
}

-- Estados
local IsRunning = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("LegitBotUI") then CoreGui.LegitBotUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LegitBotUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 20) -- Verde Militar
MainFrame.BorderColor3 = Color3.fromRGB(50, 255, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🤖 LEGIT BOT (AUTO WALK)"
Title.TextColor3 = Color3.fromRGB(50, 255, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "INICIAR FARM (ANDAR)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position) -- Anda pro próprio pé (Para)
    end
end

local function Attack()
    -- Simula clique na tela (Funciona pra espada equipada com Q)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().LegitBot = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR FARM (ANDAR)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP INTELIGENTE //
spawn(function()
    while getgenv().LegitBot do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. VALIDA ALVO ATUAL
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil -- Morreu ou sumiu
                    StopMove()
                else
                    -- CALCULA DISTÂNCIA
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- LONGE: ANDA
                        Status.Text = "🚶 INDO ATÉ: " .. math.floor(dist) .. "m"
                        MoveTo(root.Position)
                        
                        -- Se travou na parede, pula
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                    else
                        -- PERTO: BATE
                        Status.Text = "⚔️ ATACANDO!"
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        Attack()
                    end
                end
                
            else
                -- 2. BUSCA NOVO ALVO
                local folder = Workspace:FindFirstChild("Mobs")
                if folder then
                    local closest, minDist = nil, SETTINGS.SearchRange
                    
                    for _, mob in ipairs(folder:GetChildren()) do
                        local hum = mob:FindFirstChild("Humanoid")
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            local dist = (myRoot.Position - root.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                    else
                        Status.Text = "Procurando Mobs..."
                        StopMove()
                    end
                end
            end
        end
    end
end)