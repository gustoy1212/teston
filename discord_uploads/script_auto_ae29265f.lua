--[[
    🌪️ BLOX FRUITS - VORTEX LOCK v11
    
    ESTRATÉGIA:
    1. VORTEX: Puxa o mob e TRAVA ele a 18 studs de distância.
    2. SAFE ZONE: O mob fica Ancorado (congelado) longe de você.
    3. REACH: Aumenta sua hitbox para acertar ele dessa distância.
    4. SKILL SPAM: Usa Z, X, C, V automaticamente mirando no mob.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SAFE_DISTANCE = 18    -- Distância que o mob fica travado (Longe do soco dele)
local ATTACK_REACH = 25     -- Alcance do SEU ataque (Tem que ser maior que a Safe Distance)
local MAGNET_RANGE = 300    -- Raio de busca

-- Estados
local IsFarming = false
local IsAutoClick = true
local IsAutoSkill = true
local SelectedMobs = {} 
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxVortexUI") then CoreGui.BloxVortexUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxVortexUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 360)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano (Vortex)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🌪️ VORTEX LOCK v11"
Title.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.12, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScanBtn.Text = "1. SCANEAR MOBS"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Farm
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.68, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "2. ATIVAR VORTEX"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- Opções
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.44, 0, 0, 30)
ClickBox.Position = UDim2.new(0.05, 0, 0.85, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ClickBox.Text = "Click: ON"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)

local SkillBox = Instance.new("TextButton", MainFrame)
SkillBox.Size = UDim2.new(0.44, 0, 0, 30)
SkillBox.Position = UDim2.new(0.51, 0, 0.85, 0)
SkillBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SkillBox.Text = "Skills: ON"
SkillBox.TextColor3 = Color3.fromRGB(0, 255, 0)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.35, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.3, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES DE COMBATE //

-- Aplica o Reach (Hitbox Gigante na sua arma)
local function ApplyReach()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle")
        if handle then
            handle.Size = Vector3.new(ATTACK_REACH, ATTACK_REACH, ATTACK_REACH)
            handle.Massless = true
            handle.CanCollide = false
            -- Visualizador (opcional, pra vc saber que tá funfando)
            if not handle:FindFirstChild("ReachBox") then
                local b = Instance.new("SelectionBox", handle)
                b.Name = "ReachBox"
                b.Adornee = handle
                b.Size3 = handle.Size
                b.Transparency = 0.9
                b.Color3 = Color3.fromRGB(0, 255, 255)
            end
        end
    end
end

-- Usa Skills Automaticamente
local function SpamSkills()
    if not IsAutoSkill then return end
    
    local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait() -- Muito rápido
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- Auto Click
local function AutoClick()
    if IsAutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

-- // SCAN & FARM //

local function ScanMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            if not Scroll:FindFirstChild(mob.Name) then
                local Btn = Instance.new("TextButton", Scroll)
                Btn.Name = mob.Name
                Btn.Size = UDim2.new(1, 0, 0, 25)
                Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Btn.Text = " [ ] " .. mob.Name
                Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                Btn.MouseButton1Click:Connect(function()
                    if SelectedMobs[mob.Name] then
                        SelectedMobs[mob.Name] = false
                        Btn.Text = " [ ] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    else
                        SelectedMobs[mob.Name] = true
                        Btn.Text = " [X] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                    end
                end)
            end
        end
    end
end

local function GetClosestTarget()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return nil end
    
    local closest, minDist = nil, MAGNET_RANGE
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            local dist = (myPos - mob.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    return closest
end

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    if IsFarming then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local myRoot = char.HumanoidRootPart
        
        ApplyReach()
        AutoClick()
        
        -- Busca alvo
        if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
            CurrentTarget = GetClosestTarget()
            -- Solta o target antigo se tiver morrido (pra não ficar ancorado no nada)
            local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
            if enemiesFolder then
                for _, m in pairs(enemiesFolder:GetChildren()) do
                    if m ~= CurrentTarget and m:FindFirstChild("HumanoidRootPart") then
                        m.HumanoidRootPart.Anchored = false 
                    end
                end
            end
        end
        
        if CurrentTarget then
            local tRoot = CurrentTarget.HumanoidRootPart
            Status.Text = "⚔️ TRAVADO EM: " .. CurrentTarget.Name
            Status.TextColor3 = Color3.fromRGB(255, 0, 0)
            
            -- === A MÁGICA DO VORTEX LOCK === --
            
            -- 1. Calcula onde o mob deve ficar (Na sua frente, a 18 studs)
            local lockPos = myRoot.CFrame * CFrame.new(0, 0, -SAFE_DISTANCE)
            
            -- 2. Traz ele pra cá (Magnet)
            tRoot.CFrame = lockPos
            tRoot.Velocity = Vector3.new(0,0,0) -- Tira a física
            tRoot.RotVelocity = Vector3.new(0,0,0)
            
            -- 3. TRAVA ELE (Anchor) pra ele não andar na sua direção
            tRoot.Anchored = true
            
            -- 4. Vira ele de costas (pra demorar mais pra reagir)
            tRoot.CFrame = CFrame.lookAt(tRoot.Position, myRoot.Position) * CFrame.Angles(0, math.pi, 0)
            
            -- 5. Mira você nele (Para as skills acertarem)
            myRoot.CFrame = CFrame.lookAt(myRoot.Position, tRoot.Position)
            
            -- 6. Solta as Skills
            SpamSkills()
            
        else
            Status.Text = "🔎 PROCURANDO..."
            Status.TextColor3 = Color3.fromRGB(0, 255, 255)
        end
    end
end)

-- // EVENTOS UI //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR VORTEX"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "2. ATIVAR VORTEX"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        Status.Text = "Status: Parado"
        
        -- Desancora todos ao parar
        local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
        if enemiesFolder then
            for _, m in pairs(enemiesFolder:GetChildren()) do
                if m:FindFirstChild("HumanoidRootPart") then m.HumanoidRootPart.Anchored = false end
            end
        end
    end
end)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "Click: ON"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        ClickBox.Text = "Click: OFF"
        ClickBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

SkillBox.MouseButton1Click:Connect(function()
    IsAutoSkill = not IsAutoSkill
    if IsAutoSkill then
        SkillBox.Text = "Skills: ON"
        SkillBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        SkillBox.Text = "Skills: OFF"
        SkillBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    ScreenGui:Destroy()
end)