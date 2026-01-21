--[[
    📱 SAO MOBILE WARRIOR v3 (TOUCH ATTACK)
    
    CORREÇÃO MOBILE:
    - O script agora procura botões visíveis no canto direito da tela (onde fica o ataque).
    - Simula toque físico (Touch) nesses botões.
    
    MANTÉM:
    - Andar em vez de teleportar (Anti-Kick).
    - Farm Automático.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MobileWarrior = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,       -- Chega bem perto pra bater
    SearchRange = 3000,
}

-- Estados
local IsRunning = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("MobileWarriorUI") then CoreGui.MobileWarriorUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MobileWarriorUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 150)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0) -- Esquerda pra não tapar os botões
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 50)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "📱 MOBILE WARRIOR v3"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "INICIAR FARM (MOBILE)"
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
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- // FUNÇÃO DE ATAQUE MOBILE (BUSCA BOTÕES) //
local function MobileAttack()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Varre a interface procurando botões de ataque
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("ImageButton") or gui:IsA("TextButton")) and gui.Visible then
            -- Verifica se o botão está no CANTO DIREITO INFERIOR (Onde fica o ataque)
            -- Posição X > 0.6 (Direita) e Y > 0.5 (Baixo)
            local pos = gui.AbsolutePosition
            local screenSize = workspace.CurrentCamera.ViewportSize
            
            if (pos.X / screenSize.X) > 0.6 and (pos.Y / screenSize.Y) > 0.5 then
                -- É provável que seja o botão de ataque ou skill
                
                -- Simula toque no centro do botão
                local centerX = pos.X + (gui.AbsoluteSize.X / 2)
                local centerY = pos.Y + (gui.AbsoluteSize.Y / 2)
                
                VirtualInputManager:SendTouchEvent(1234, 0, centerX, centerY, 0, false, game, 1) -- Touch Start
                task.wait()
                VirtualInputManager:SendTouchEvent(1234, 1, centerX, centerY, 0, false, game, 1) -- Touch End
            end
        end
    end
    
    -- Fallback: Tenta ativar a Tool padrão também
    pcall(function()
        LocalPlayer.Character:FindFirstChildOfClass("Tool"):Activate()
    end)
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MobileWarrior = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR FARM (MOBILE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().MobileWarrior do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. GERENCIA ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    StopMove()
                else
                    -- CALCULA
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- LONGE: Corre
                        Status.Text = "🏃 CORRENDO ATÉ ALVO..."
                        MoveTo(root.Position)
                        
                        -- Anti-Travamento (Pulo)
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                    else
                        -- PERTO: Desce o dedo nos botões
                        Status.Text = "⚔️ ESPANCANDO..."
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        MobileAttack() -- SPAM CLICK MOBILE
                    end
                end
                
            else
                -- 2. PROCURA NOVO
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