--[[
    🩸 SAO GUERRILLA v1 (HIT & RUN)
    
    ESTRATÉGIA DE SOBREVIVÊNCIA MÁXIMA:
    1. Corre até o inimigo (Sprint).
    2. Bate por 0.5 segundos.
    3. Foge imediatamente para longe (Sprint).
    4. Repete.
    
    ALVO: PlayerGui.DeviceGui.Mobile -> Attack
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().GuerrillaFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,        -- Distância para bater
    RetreatDist = 25,      -- Distância para fugir (Longe!)
    AttackDuration = 0.4,  -- Fica batendo por apenas 0.4 segundos
    SearchRange = 3000,
}

-- Estados da Máquina
local State = "SEARCH" -- SEARCH, APPROACH, ATTACK, RETREAT
local CurrentTarget = nil
local StateTimer = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("GuerrillaUI") then CoreGui.GuerrillaUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GuerrillaUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 20, 0) -- Marrom Guerrilha
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🩸 GUERRILLA (HIT & RUN)"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
ToggleBtn.Text = "INICIAR GUERRILHA"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // CONTROLES //
local IsRunning = false
local IsSprinting = false

local function SetSprint(enable)
    if enable then
        if not IsSprinting then
            IsSprinting = true
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        end
    else
        if IsSprinting then
            IsSprinting = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end
end

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
    getgenv().GuerrillaFarm = false
    SetSprint(false)
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        State = "SEARCH"
    else
        ToggleBtn.Text = "INICIAR GUERRILHA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
        SetSprint(false)
        StopMove()
        CurrentTarget = nil
    end
end

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().GuerrillaFarm do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- VALIDAÇÃO DO ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    State = "SEARCH"
                    SetSprint(false)
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    -- MÁQUINA DE ESTADOS
                    
                    if State == "APPROACH" then
                        Status.Text = "😡 AVANÇANDO!"
                        SetSprint(true) -- Corre pra cima
                        MoveTo(root.Position)
                        
                        -- Pulo anti-travamento
                        if char.Humanoid.SeatPart == nil and (myRoot.Velocity * Vector3.new(1,0,1)).Magnitude < 0.2 then
                            char.Humanoid.Jump = true
                        end
                        
                        if dist <= SETTINGS.AttackDist then
                            State = "ATTACK"
                            StateTimer = tick()
                            StopMove()
                        end
                        
                    elseif State == "ATTACK" then
                        Status.Text = "⚔️ BATE RÁPIDO!"
                        SetSprint(false)
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        Attack()
                        
                        -- Se passou o tempo limite do ataque, foge
                        if tick() - StateTimer > SETTINGS.AttackDuration then
                            State = "RETREAT"
                        end
                        
                    elseif State == "RETREAT" then
                        Status.Text = "🏃 FUGINDO!"
                        SetSprint(true) -- Corre pra longe
                        
                        -- Calcula vetor oposto ao monstro
                        local fleeDir = (myRoot.Position - root.Position).Unit
                        local fleePos = root.Position + (fleeDir * SETTINGS.RetreatDist)
                        
                        MoveTo(fleePos)
                        
                        -- Se já fugiu o suficiente, volta a atacar
                        if dist >= SETTINGS.RetreatDist then
                            State = "APPROACH"
                        end
                    end
                end
                
            else
                -- ESTADO DE BUSCA
                State = "SEARCH"
                Status.Text = "Procurando Mobs..."
                
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
                        State = "APPROACH"
                    else
                        StopMove()
                        SetSprint(false)
                    end
                end
            end
        end
    end
end)