--[[
    ⚔️ SAO SURVIVOR V8 (BERSERK MODE)
    
    CORREÇÕES:
    1. REMOVIDO "F" da lista de skills (Para parar de defender).
    2. Aumento de agressividade (Cola mais no inimigo).
    3. Prioridade total para Ataque Básico.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOSurvivorV8 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 10,        -- Começa a ir atrás
    StopDist = 3,           -- Fica BEM PERTO (3 studs) pra garantir o hit
    SearchRange = 1500,
    
    -- Hitbox (Aumentei um pouco pra compensar o lag)
    ReachSize = 14,         
    
    -- Sobrevivência
    LowHealthPercent = 25,  -- Foge só se estiver morrendo mesmo
    FullHealthPercent = 80, -- Volta rápido pra luta
}

-- Estados
local IsRunning = false
local IsInEmergency = false 
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOBerserkUI") then CoreGui.SAOBerserkUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOBerserkUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0) -- Vermelho Berserk
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ SAO BERSERK V8"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.Text = "LIGAR (FULL ATAQUE)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

-- 1. HITBOX (Middle)
local function ApplyReach()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local damagePart = tool:FindFirstChild("Middle") or tool:FindFirstChild("Handle")
            if damagePart then
                if damagePart.Size.X < 5 then 
                    damagePart.Size = Vector3.new(SETTINGS.ReachSize, SETTINGS.ReachSize, SETTINGS.ReachSize)
                    damagePart.Transparency = 1 
                    damagePart.CanCollide = false
                    damagePart.Massless = true
                end
                if damagePart:FindFirstChild("TouchInterest") then
                    firetouchinterest(damagePart, damagePart, 0) 
                end
            end
        end
    end
end

-- 2. MOVIMENTO
local function WalkTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

-- 3. AUTO SPRINT (Sempre correndo)
local function EnsureSprint()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
end

-- 4. ATAQUE AGRESSIVO (SEM 'F')
local function Attack()
    -- Clique Primário (Espadada)
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(900, 500))
    
    ApplyReach() -- Garante hitbox
    
    -- SKILLS (REMOVI O "F" DA LISTA)
    local keys = {"E", "R", "Q"} -- Só ataque, nada de defesa
    for _, key in pairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end
end

-- // UI LÓGICA //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR (FULL ATAQUE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentTarget = nil
        if LocalPlayer.Character then LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position) end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOSurvivorV8 = false
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SAOSurvivorV8 do
        task.wait(0.1) -- Loop rápido
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") then return end
            
            local hum = char.Humanoid
            local myRoot = char.HumanoidRootPart
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            EnsureSprint() 
            
            -- EQUIPAR
            if not char:FindFirstChildOfClass("Tool") then
                local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if tool then hum:EquipTool(tool) end
            end

            -- EMERGÊNCIA
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            if IsInEmergency and hpPercent >= SETTINGS.FullHealthPercent then IsInEmergency = false end
            
            if IsInEmergency then
                Status.Text = "🩸 FUGINDO..."
                Status.TextColor3 = Color3.fromRGB(255, 0, 0)
                
                if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
                    local dir = (myRoot.Position - CurrentTarget.HumanoidRootPart.Position).Unit 
                    WalkTo(myRoot.Position + (dir * 40))
                else
                    WalkTo(myRoot.Position + Vector3.new(math.random(-30,30), 0, math.random(-30,30)))
                end
                
            -- COMBATE
            else
                -- BUSCA
                if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget:FindFirstChild("Humanoid").Health <= 0 then
                    Status.Text = "😠 PROCURANDO..."
                    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
                    
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
                    -- ATAQUE
                    Status.Text = "⚔️ MATANDO: " .. CurrentTarget.Name
                    Status.TextColor3 = Color3.fromRGB(255, 0, 0)
                    
                    local enemyRoot = CurrentTarget.HumanoidRootPart
                    local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                    
                    if dist > SETTINGS.AttackDist then
                        -- Longe: Anda até ele
                        WalkTo(enemyRoot.Position)
                    elseif dist <= SETTINGS.StopDist then
                        -- Colado: Para e espanca
                        hum:MoveTo(myRoot.Position) 
                        -- Vira pra ele
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(enemyRoot.Position.X, myRoot.Position.Y, enemyRoot.Position.Z))
                        Attack()
                    else
                        -- Médio: Continua andando e batendo
                        WalkTo(enemyRoot.Position)
                        Attack()
                    end
                end
            end
        end
    end
end)

-- ANTI-COLLISION
RunService.Stepped:Connect(function()
    if IsRunning and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)