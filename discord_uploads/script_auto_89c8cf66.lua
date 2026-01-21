--[[
    ⚔️ SAO TACTICAL v1 (BACKSTAB & SKILL SPAM)
    
    ESTRATÉGIA DE SOBREVIVÊNCIA:
    1. Posicionamento: Tenta ficar sempre nas COSTAS do inimigo (Blindspot).
    2. Dano Máximo: Clica em TODOS os botões da pasta Mobile (Ataque + Skills + Escudo).
    
    ALVO: PlayerGui.DeviceGui.Mobile -> Click All
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().TacticalFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 6,        -- Distância para começar a bater
    BehindDist = 4,        -- Distância para ficar atrás do bicho
    SearchRange = 3000,
}

-- Estados
local IsRunning = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("TacticalUI") then CoreGui.TacticalUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TacticalUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 30)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ TACTICAL (SKILLS + BACK)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "INICIAR COMBATE TÁTICO"
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

-- // CLICADOR DE TUDO (FULL BURST) //
local function SmashAllButtons()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local deviceGui = playerGui:FindFirstChild("DeviceGui")
    if not deviceGui then return end
    local mobileFrame = deviceGui:FindFirstChild("Mobile")
    if not mobileFrame then return end
    
    -- Varre TUDO na pasta Mobile
    for _, btn in ipairs(mobileFrame:GetChildren()) do
        -- Clica se for botão visível e não for o de Pular (geralmente JumpButton)
        if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible and not btn.Name:match("Jump") and not btn.Name:match("Pad") then
            
            -- Método Híbrido: Evento + Toque
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            
            -- Simula Toque (Só no ataque principal pra não travar)
            if btn.Name == "MobileAttackButton" then
                local pos = btn.AbsolutePosition
                local size = btn.AbsoluteSize
                local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
                VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
                VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
            end
        end
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TacticalFarm = false
    StopMove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR COMBATE TÁTICO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        StopMove()
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().TacticalFarm do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. ALVO
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    CurrentTarget = nil
                    StopMove()
                else
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- LONGE: Corre até ele
                        Status.Text = "🏃 BUSCANDO..."
                        MoveTo(root.Position)
                    else
                        -- PERTO: TÁTICA DE COSTAS
                        Status.Text = "⚔️ COSTAS + SKILLS!"
                        
                        -- Calcula posição atrás do inimigo
                        -- Pega a direção que o inimigo está olhando e vai para o oposto
                        local backPos = root.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                        
                        MoveTo(backPos.Position)
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        -- SPAM TOTAL
                        SmashAllButtons()
                    end
                end
                
            else
                -- 2. PROCURA
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