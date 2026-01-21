--[[
    🤖 SAO LEGIT BOT v2 (SMART ANIMATION)
    
    MELHORIA VISUAL:
    - Separação total entre ANDAR e BATER.
    - Se estiver longe: Apenas corre (Animação limpa).
    - Se estiver perto: Para de correr e desce o braço.
    
    ALVO: Workspace.Mobs
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().LegitBotV2 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 7,       -- Distância para começar a bater
    StopDist = 6,         -- Distância para parar de andar (ficar colado)
    SearchRange = 3000,   -- Raio de busca
}

-- Estados
local IsRunning = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("LegitBotV2UI") then CoreGui.LegitBotV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LegitBotV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 25, 30) -- Verde Tático
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🤖 LEGIT BOT v2 (SMART)"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "INICIAR FARM (BONITINHO)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE MOVIMENTO //

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        -- Manda andar para a própria posição atual (Freio)
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

local function Attack()
    -- Só clica, não anda
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().LegitBotV2 = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR FARM (BONITINHO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().LegitBotV2 do
        task.wait(0.1) -- Loop leve
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. VALIDAÇÃO DE ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil -- Já era, busca outro
                    StopMove() -- Para de andar imediatamente
                else
                    -- 2. DECISÃO INTELIGENTE
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- >>> MODO CAMINHADA (SEM ATAQUE) <<<
                        Status.Text = "🚶 BUSCANDO..."
                        MoveTo(root.Position)
                        
                        -- Pulo anti-travamento se bater em parede
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                        
                    else
                        -- >>> MODO COMBATE (PARADO) <<<
                        Status.Text = "⚔️ ELIMINANDO..."
                        StopMove() -- Garante que parou
                        
                        -- Olha pro inimigo (Face Target)
                        local lookPos = Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z)
                        myRoot.CFrame = CFrame.new(myRoot.Position, lookPos)
                        
                        -- Só bate aqui!
                        Attack()
                    end
                end
                
            else
                -- 3. SCANNER DE NOVO ALVO
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
                        Status.Text = "👀 ALVO ENCONTRADO"
                    else
                        Status.Text = "Procurando Mobs..."
                        StopMove()
                    end
                end
            end
        end
    end
end)