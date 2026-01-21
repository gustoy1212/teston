--[[
    ⚡🐰 SAO FLASH STEP v2 (JUMP REMIX)
    
    BASEADO NO SCRIPT QUE FUNCIONOU!
    
    MELHORIAS:
    1. Adicionado PULO AUTOMÁTICO durante o ataque para evitar dano.
    2. Mantém a lógica de Sprint (Ctrl) inteligente.
    3. Mantém a busca pelo botão MobileAttackButton.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepV2 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 7,        -- Aumentei um pouquinho pra bater antes de encostar
    BehindDist = 5,        -- Distância para ficar atrás do bicho
    SprintDist = 12,       -- Se estiver longe, CORRE
    SearchRange = 3000,
}

-- Estados
local IsRunning = false
local IsSprinting = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashV2UI") then CoreGui.FlashV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 50) -- Azul Escuro
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚡ FLASH STEP v2 (JUMP)"
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ToggleBtn.Text = "LIGAR MODO CANGURU"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // CONTROLE DE SPRINT (CTRL) //
local function SetSprint(enable)
    if enable then
        if not IsSprinting then
            IsSprinting = true
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            Status.Text = "⚡ CORRENDO..."
        end
    else
        if IsSprinting then
            IsSprinting = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            Status.Text = "🔋 RECUPERANDO..."
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

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- // ATAQUE SIMPLES //
local function Attack()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepV2 = false
    SetSprint(false) 
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MODO CANGURU"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepV2 do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            
            -- 1. ALVO
            if CurrentTarget then
                local tHum = CurrentTarget:FindFirstChild("Humanoid")
                local tRoot = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not tHum or tHum.Health <= 0 or not tRoot or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    SetSprint(false)
                    StopMove()
                else
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    
                    if dist > SETTINGS.SprintDist then
                        -- ESTÁ LONGE: Corre
                        SetSprint(true)
                        MoveTo(tRoot.Position)
                        
                    elseif dist > SETTINGS.AttackDist then
                        -- ESTÁ MÉDIO: Caminha
                        SetSprint(false)
                        MoveTo(tRoot.Position)
                        
                    else
                        -- ESTÁ PERTO: ATAQUE + PULO
                        Status.Text = "⚔️🐰 PULANDO E BATENDO!"
                        
                        -- Tenta ir para as costas
                        local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                        local distToBack = (myRoot.Position - backPos.Position).Magnitude
                        
                        -- Se estiver longe das costas, corre pra lá
                        if distToBack > 3 then
                            SetSprint(true) 
                            MoveTo(backPos.Position)
                        else
                            SetSprint(false)
                            StopMove()
                            -- Vira pro bicho
                            myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                        end
                        
                        -- >>> A MÁGICA: PULO INFINITO <<<
                        hum.Jump = true 
                        
                        Attack()
                    end
                end
                
            else
                -- 2. PROCURA
                local folder = Workspace:FindFirstChild("Mobs")
                if folder then
                    local closest, minDist = nil, SETTINGS.SearchRange
                    
                    for _, mob in ipairs(folder:GetChildren()) do
                        local mHum = mob:FindFirstChild("Humanoid")
                        local mRoot = mob:FindFirstChild("HumanoidRootPart")
                        
                        if mHum and mRoot and mHum.Health > 0 then
                            local dist = (myRoot.Position - mRoot.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                    else
                        Status.Text = "Procurando..."
                        SetSprint(false)
                        StopMove()
                    end
                end
            end
        end
    end
end)