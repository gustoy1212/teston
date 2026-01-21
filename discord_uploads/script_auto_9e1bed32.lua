--[[
    🏆 SAO PROTOCOL FINAL (BUTTON SMASHER)
    
    ALVO: Workspace.Mobs
    BOTÃO CONFIRMADO: PlayerGui.DeviceGui.Mobile.MobileAttackButton
    
    LÓGICA:
    1. Anda até o mob (Anti-Kick).
    2. Chega perto -> Para de andar.
    3. Clica especificamente no 'MobileAttackButton'.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOFinal = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 7,       -- Distância para começar a bater
    SearchRange = 3000,   -- Raio de busca
    ClickSpeed = 0.1,     -- Velocidade dos cliques
}

-- Estados
local IsRunning = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOFinalUI") then CoreGui.SAOFinalUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOFinalUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Vermelho Final
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏆 SAO FINAL (AUTO FARM)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
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
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "INICIAR MODO DEUS"
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
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- CLICA NO BOTÃO EXATO QUE DESCOBRIMOS
local function SmashButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Caminho confirmado pela sua print:
    -- PlayerGui -> DeviceGui -> Mobile -> MobileAttackButton
    local deviceGui = playerGui:FindFirstChild("DeviceGui")
    if not deviceGui then return end
    
    local mobileFrame = deviceGui:FindFirstChild("Mobile")
    if not mobileFrame then return end
    
    local btn = mobileFrame:FindFirstChild("MobileAttackButton")
    
    if btn and btn.Visible then
        -- Método 1: Tenta ativar o evento interno (Melhor)
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
        
        -- Método 2: Simula Toque Físico na posição do botão (Garantia)
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local centerX = pos.X + (size.X / 2)
        local centerY = pos.Y + (size.Y / 2)
        
        VirtualInputManager:SendTouchEvent(999, 0, centerX, centerY, 0, false, game, 1)
        task.wait()
        VirtualInputManager:SendTouchEvent(999, 1, centerX, centerY, 0, false, game, 1)
    else
        Status.Text = "⚠️ Botão Sumiu! (Equipe a Espada)"
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOFinal = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR MODO DEUS"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SAOFinal do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. VALIDAÇÃO DE ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    StopMove()
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- ANDA
                        Status.Text = "🚶 BUSCANDO... ("..math.floor(dist).."m)"
                        MoveTo(root.Position)
                        
                        -- Pulo anti-travamento leve
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                    else
                        -- ATAQUE TOTAL
                        Status.Text = "⚔️ DESTRUINDO!"
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        -- Clica no botão descoberto
                        SmashButton()
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