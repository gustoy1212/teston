--[[
    ⚔️ SAO FLASH STEP v6 (GOD LOG EDITION)
    BASEADO NOS LOGS: GOD_LOG_172016 e 172026
    
    NOVIDADES:
    1. REACH (Hitbox): Aumenta a parte "Middle" da espada (descoberta nos logs).
    2. FLASH STEP REAL: Usa Tween em vez de andar (muito mais rápido).
    3. AUTO SKILLS: Usa Q, E, R, F automaticamente.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().FlashStepV6 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 8,         -- Distância para começar a bater
    BehindDist = 4,         -- Distância para ficar nas costas (Flash Step)
    SearchRange = 2000,
    UseSkills = true,       -- Usar skills Q,E,R,F
    
    -- Hitbox (O Segredo dos Logs)
    ReachSize = 25,         -- Tamanho da hitbox da espada
    
    -- Sobrevivência
    LowHealthPercent = 30,  -- Fugir com 30%
    FullHealthPercent = 85, -- Voltar com 85%
    SafetyDist = 60,        -- Distância de fuga
}

-- Estados
local IsRunning = false
local IsInEmergency = false 
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("FlashGodUI") then CoreGui.FlashGodUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FlashGodUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 180)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200) -- Azul SAO
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ SAO FLASH STEP V6 (LOGS)"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Aguardando..."
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
ToggleBtn.Text = "ATIVAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES ESPECIAIS (BASEADAS NOS LOGS) //

-- 1. APPLY REACH (Expandir a parte "Middle" da espada)
local function ApplyReach()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            -- O Log mostrou que a parte de dano se chama "Middle"
            local damagePart = tool:FindFirstChild("Middle") or tool:FindFirstChild("Handle")
            
            if damagePart then
                -- Deixa gigante e transparente pra não atrapalhar a visão
                if damagePart.Size.X < 10 then -- Só aplica se ainda não foi aplicado
                    damagePart.Size = Vector3.new(SETTINGS.ReachSize, SETTINGS.ReachSize, SETTINGS.ReachSize)
                    damagePart.Transparency = 0.8
                    damagePart.CanCollide = false
                    damagePart.Massless = true -- Pra não pesar o boneco
                end
                
                -- Se tiver TouchInterest (visto no log), forçamos a atualização
                if damagePart:FindFirstChild("TouchInterest") then
                    firetouchinterest(damagePart, damagePart, 0) 
                end
            end
        end
    end
end

-- 2. MOVIMENTO SUAVE (Tween em vez de MoveTo)
local function FlashStep(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    -- Velocidade calculada (rápido, mas não teleport instantâneo pra não dar ban)
    local speed = 60 
    local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    
    local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
    tween:Play()
    
    -- Tira gravidade enquanto voa pra não cair
    root.Velocity = Vector3.zero
end

-- 3. AUTO SKILLS (Q, E, R, F)
local function SpamSkills()
    if not SETTINGS.UseSkills then return end
    local keys = {"One", "E", "R", "F", "Q"} -- "One" visto nos logs como skill tbm
    for _, key in pairs(keys) do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end
end

-- 4. ATAQUE MOBILE OTIMIZADO
local function Attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(900, 500))
    ApplyReach() -- Garante que a hitbox tá grande na hora do ataque
    SpamSkills()
end

-- // UI LOGIC //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        IsInEmergency = false
    else
        ToggleBtn.Text = "ATIVAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        CurrentTarget = nil
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepV6 = false
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().FlashStepV6 do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") then return end
            
            local hum = char.Humanoid
            local myRoot = char.HumanoidRootPart
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            
            -- EQUIPA ARMA (Auto Equip básico)
            if not char:FindFirstChildOfClass("Tool") then
                local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if tool then hum:EquipTool(tool) end
            end

            -- === SOBREVIVÊNCIA ===
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true end
            if IsInEmergency and hpPercent >= SETTINGS.FullHealthPercent then IsInEmergency = false end
            
            if IsInEmergency then
                Status.Text = "🚑 VIDA BAIXA! FUGINDO..."
                Status.TextColor3 = Color3.fromRGB(255, 0, 0)
                
                -- Foge para cima (Voo de emergência)
                local safePos = myRoot.CFrame * CFrame.new(0, 50, 0) -- Sobe 50 metros
                FlashStep(safePos)
            
            -- === COMBATE ===
            else
                -- Procura Alvo
                if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget:FindFirstChild("Humanoid").Health <= 0 then
                    Status.Text = "🔎 PROCURANDO..."
                    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
                    
                    local closest, minDist = nil, SETTINGS.SearchRange
                    local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace -- Tenta achar pasta Mobs
                    
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
                    -- ATACA O ALVO
                    Status.Text = "⚔️ MATANDO: " .. CurrentTarget.Name
                    Status.TextColor3 = Color3.fromRGB(0, 255, 0)
                    
                    local enemyRoot = CurrentTarget.HumanoidRootPart
                    local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                    
                    -- Lógica de Movimento (Flash Step)
                    if dist > SETTINGS.AttackDist then
                        -- Voa até as costas do mob
                        local behindPos = enemyRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                        FlashStep(behindPos)
                        
                        -- Vira pra ele
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(enemyRoot.Position.X, myRoot.Position.Y, enemyRoot.Position.Z))
                    else
                        -- Já está perto, ATACA
                        -- Trava posição pra não ser empurrado
                        myRoot.Velocity = Vector3.zero 
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(enemyRoot.Position.X, myRoot.Position.Y, enemyRoot.Position.Z))
                        Attack()
                    end
                end
            end
        end
    end
end)

-- // NOCLIP (Pra não travar nas paredes) //
RunService.Stepped:Connect(function()
    if IsRunning and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)