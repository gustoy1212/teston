--[[
    ⚔️ SAO SURVIVOR V7 (LEGIT / GROUND MODE)
    Foco: Parecer um jogador real (sem voar), mas com vantagens invisíveis.
    
    MELHORIAS:
    1. Movimento 100% pelo chão (MoveTo).
    2. Hitbox "Middle" ajustada (12x12) para não dar na cara.
    3. Auto Sprint (Segura CTRL pra correr).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOSurvivorV7 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 9,         -- Distância para bater (um pouco longe pq a hitbox ajuda)
    StopDist = 4,           -- Distância pra parar de andar (pra não entrar dentro do bicho)
    SearchRange = 1000,
    
    -- Hitbox (O Segredo dos Logs, mas discreto)
    ReachSize = 12,         -- Tamanho 12 é bom (não é gigante, mas acerta tudo)
    
    -- Sobrevivência
    LowHealthPercent = 30,  -- Foge com 30%
    FullHealthPercent = 90, -- Volta com 90%
}

-- Estados
local IsRunning = false
local IsInEmergency = false 
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOLegitUI") then CoreGui.SAOLegitUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOLegitUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ SAO LEGIT V7"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local HealthLabel = Instance.new("TextLabel", MainFrame)
HealthLabel.Size = UDim2.new(1, 0, 0, 25)
HealthLabel.Position = UDim2.new(0, 0, 0.35, 0)
HealthLabel.Text = "Vida: 100%"
HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HealthLabel.BackgroundTransparency = 1
HealthLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "LIGAR (MODO CHÃO)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

-- 1. APPLY REACH (Hitbox do Log "Middle")
local function ApplyReach()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            -- Procura a parte Middle (que achamos no log) ou Handle
            local damagePart = tool:FindFirstChild("Middle") or tool:FindFirstChild("Handle")
            
            if damagePart then
                -- Aplica tamanho (Discreto: 12)
                if damagePart.Size.X < 5 then 
                    damagePart.Size = Vector3.new(SETTINGS.ReachSize, SETTINGS.ReachSize, SETTINGS.ReachSize)
                    damagePart.Transparency = 1 -- 100% Invisível (Legit)
                    damagePart.CanCollide = false
                    damagePart.Massless = true
                end
                
                -- Force Touch (Atualiza o dano)
                if damagePart:FindFirstChild("TouchInterest") then
                    firetouchinterest(damagePart, damagePart, 0) 
                end
            end
        end
    end
end

-- 2. MOVIMENTO LEGIT (MoveTo)
local function WalkTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

-- 3. AUTO SPRINT (Segura Ctrl)
local function EnsureSprint()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
end

-- 4. ATAQUE + SKILLS
local function Attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(900, 500))
    ApplyReach()
    
    -- Spam Skills básico
    local keys = {"E", "R", "F", "Q"}
    for _, key in pairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end
end

-- // LÓGICA UI //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR (MODO CHÃO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        CurrentTarget = nil
        if LocalPlayer.Character then LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position) end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOSurvivorV7 = false
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SAOSurvivorV7 do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") then return end
            
            local hum = char.Humanoid
            local myRoot = char.HumanoidRootPart
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            EnsureSprint() -- Garante que tá correndo
            
            -- EQUIPAR ARMA
            if not char:FindFirstChildOfClass("Tool") then
                local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if tool then hum:EquipTool(tool) end
            end

            -- === EMERGÊNCIA (Vida Baixa) ===
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            if IsInEmergency and hpPercent >= SETTINGS.FullHealthPercent then IsInEmergency = false end
            
            if IsInEmergency then
                Status.Text = "😰 FUGINDO (Recuperando Vida)..."
                Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                -- Lógica de Fuga (Corre para longe do inimigo atual)
                if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
                    local enemyPos = CurrentTarget.HumanoidRootPart.Position
                    local myPos = myRoot.Position
                    -- Vetor oposto ao inimigo
                    local dir = (myPos - enemyPos).Unit 
                    local runSpot = myPos + (dir * 40) -- Corre 40 studs pra longe
                    WalkTo(runSpot)
                else
                    -- Se não tem alvo, corre aleatório ou fica parado
                    local randomSpot = myRoot.Position + Vector3.new(math.random(-20,20), 0, math.random(-20,20))
                    WalkTo(randomSpot)
                end
                
            -- === COMBATE (Normal) ===
            else
                -- PROCURAR ALVO
                if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget:FindFirstChild("Humanoid").Health <= 0 then
                    Status.Text = "🚶 PROCURANDO..."
                    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
                    
                    local closest, minDist = nil, SETTINGS.SearchRange
                    local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace
                    
                    for _, mob in pairs(mobsFolder:GetChildren()) do
                        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Name ~= LocalPlayer.Name and not Players:GetPlayerFromCharacter(mob) then
                            if mob:FindFirstChild("Humanoid").Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                                local d = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if d < minDist then
                                    minDist = d
                                    closest = mob
                                end
                            end
                        end
                    end
                    CurrentTarget = closest
                else
                    -- PERSEGUIR E MATAR
                    Status.Text = "⚔️ ALVO: " .. CurrentTarget.Name
                    Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                    
                    local enemyRoot = CurrentTarget.HumanoidRootPart
                    local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- Anda até o bicho
                        WalkTo(enemyRoot.Position)
                    elseif dist < SETTINGS.StopDist then
                        -- Muito perto? Para pra não bugar dentro dele
                        hum:MoveTo(myRoot.Position)
                        -- Olha pra ele
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(enemyRoot.Position.X, myRoot.Position.Y, enemyRoot.Position.Z))
                        Attack()
                    else
                        -- Distância boa? Continua andando e batendo
                        WalkTo(enemyRoot.Position)
                        Attack()
                    end
                end
            end
        end
    end
end)

-- // ANTI-COLLISION (Opcional, pra não travar nos mobs) //
RunService.Stepped:Connect(function()
    if IsRunning and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)