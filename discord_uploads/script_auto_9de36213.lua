--[[
    🐰 SAO BERSERKER v1 (JUMP & KILL)
    
    ESTRATÉGIA:
    - Simplificada para garantir que o script LIGUE.
    - Usa "Bunny Hop" (Pulos constantes) para evitar dano.
    - Clica no botão confirmado: DeviceGui.Mobile.MobileAttackButton
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().BerserkerFarm = true

-- // GUI SETUP (SIMPLIFICADO) //
if CoreGui:FindFirstChild("BerserkerUI") then CoreGui.BerserkerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BerserkerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 130)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- Vermelho Sangue
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🐰 BERSERKER (PULA-PULA)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "PARADO"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
ToggleBtn.Text = "LIGAR MODO DOIDO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
CloseBtn.TextColor3 = Color3.white

-- // CONFIGURAÇÕES //
local IsRunning = false
local CurrentTarget = nil
local AttackDist = 7
local SearchRange = 3000

-- // FUNÇÕES DE COMBATE //
local function AttackMobile()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    -- Busca direta e segura
    if playerGui and playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn and btn.Visible then
            -- Tenta evento interno
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            -- Tenta toque
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

-- // MOVIMENTO //
local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

-- // LOOP PRINCIPAL (SIMPLIFICADO) //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MODO DOIDO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
        local char = LocalPlayer.Character
        if char then char.Humanoid:MoveTo(char.HumanoidRootPart.Position) end
        CurrentTarget = nil
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BerserkerFarm = false
    ScreenGui:Destroy()
end)

spawn(function()
    while getgenv().BerserkerFarm do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local myRoot = char.HumanoidRootPart
                local hum = char.Humanoid
                
                -- 1. Verifica Alvo Atual
                if CurrentTarget then
                    if not CurrentTarget.Parent or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
                        CurrentTarget = nil -- Morreu
                    else
                        -- Combate
                        local targetRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local dist = (myRoot.Position - targetRoot.Position).Magnitude
                            
                            if dist > AttackDist then
                                -- Corre até ele
                                Status.Text = "🏃 INDO..."
                                hum:MoveTo(targetRoot.Position)
                            else
                                -- CAOS TOTAL (PULA E BATE)
                                Status.Text = "🐰 PULANDO E BATENDO!"
                                
                                -- Pula
                                hum.Jump = true
                                
                                -- Move em círculos (Orbita) para dificultar o hit do inimigo
                                -- Fica andando levemente para os lados
                                local offset = Vector3.new(math.sin(tick()*5)*3, 0, math.cos(tick()*5)*3)
                                hum:MoveTo(targetRoot.Position + offset)
                                
                                -- Olha pro bicho
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z))
                                
                                -- Bate
                                AttackMobile()
                            end
                        end
                    end
                else
                    -- 2. Busca Novo Alvo
                    Status.Text = "🔎 PROCURANDO..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    local closest = nil
                    local minDist = SearchRange
                    
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = mob
                                end
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                    else
                         hum:MoveTo(myRoot.Position) -- Para se não achar nada
                    end
                end
            end
        end
    end
end)