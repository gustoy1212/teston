--[[
    🐰 SAO BERSERKER v2 (DEBUG MODE)
    
    CORREÇÕES:
    - Adicionado 'pcall' para evitar que o script morra se der erro.
    - Feedback visual imediato no botão.
    - Pulo de teste ao iniciar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().BerserkerV2 = true

-- // GUI SETUP //
if CoreGui:FindFirstChild("BerserkerV2UI") then CoreGui.BerserkerV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BerserkerV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🐰 BERSERKER v2 (FIX)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "AGUARDANDO..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextWrapped = true

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
ToggleBtn.Text = "LIGAR (TESTE)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
CloseBtn.TextColor3 = Color3.white

-- // VARIÁVEIS //
local IsRunning = false
local CurrentTarget = nil
local SearchRange = 3000

-- // FUNÇÃO DE ATAQUE (Blindada) //
local function TryAttack()
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
            local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
            if btn and btn.Visible then
                -- Método Evento
                if firesignal then
                    pcall(function() firesignal(btn.MouseButton1Click) end)
                    pcall(function() firesignal(btn.Activated) end)
                end
                -- Método Toque
                local pos = btn.AbsolutePosition
                local size = btn.AbsoluteSize
                local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
                VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
                VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
            end
        end
    end)
end

-- // BOTÃO LIGAR //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "RODANDO..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Verde = Ligado
        Status.Text = "INICIANDO..."
        
        -- TESTE DE VIDA: PULA
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Jump = true
        end
        
    else
        ToggleBtn.Text = "LIGAR (TESTE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
        Status.Text = "PAUSADO"
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position) -- Freio
        end
        CurrentTarget = nil
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BerserkerV2 = false
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL (ANTI-CRASH) //
spawn(function()
    while getgenv().BerserkerV2 do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            -- Proteção de Erro (pcall)
            local success, err = pcall(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                
                local hum = char.Humanoid
                local root = char.HumanoidRootPart
                
                -- Se morreu, espera renascer
                if hum.Health <= 0 then 
                    Status.Text = "MORTO - ESPERANDO..."
                    CurrentTarget = nil
                    return 
                end

                -- 1. VALIDA ALVO
                if CurrentTarget then
                    if not CurrentTarget.Parent or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
                        CurrentTarget = nil
                    else
                        -- COMBATE
                        local targetRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local dist = (root.Position - targetRoot.Position).Magnitude
                            
                            if dist > 8 then
                                -- LONGE: CORRE
                                Status.Text = "🏃 BUSCANDO ALVO..."
                                hum:MoveTo(targetRoot.Position)
                                if hum.SeatPart == nil and (root.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                                    hum.Jump = true -- Pula se travar
                                end
                            else
                                -- PERTO: MODO BERSERKER
                                Status.Text = "🐰 PULA E BATE!"
                                
                                -- PULA SEM PARAR
                                hum.Jump = true
                                
                                -- GIRA EM VOLTA (Orbita)
                                local time = tick() * 6 -- Velocidade do giro
                                local offset = Vector3.new(math.cos(time)*5, 0, math.sin(time)*5)
                                hum:MoveTo(targetRoot.Position + offset)
                                
                                -- OLHA PRO BICHO
                                root.CFrame = CFrame.new(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                                
                                -- BATE
                                TryAttack()
                            end
                        end
                    end
                else
                    -- 2. BUSCA NOVO
                    Status.Text = "🔎 ESCANEANDO..."
                    local folder = Workspace:FindFirstChild("Mobs")
                    local closest = nil
                    local minDist = SearchRange
                    
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            if mHum and mRoot and mHum.Health > 0 then
                                local dist = (root.Position - mRoot.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    closest = mob
                                end
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                    end
                end
            end)
            
            if not success then
                warn("Erro no script: " .. tostring(err))
                Status.Text = "ERRO INTERNO (Tentando recuperar...)"
            end
        end
    end
end)