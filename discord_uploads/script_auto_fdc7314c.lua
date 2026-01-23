--[[
    🌌 BLOX FRUITS - VORTEX SUPERNOVA v12
    
    ATUALIZAÇÕES:
    1. MULTI-TARGET: Puxa TODOS os mobs selecionados ao mesmo tempo.
    2. CLOSE RANGE: Traz eles para 5 studs (bem perto).
    3. BACK-LOCK: Vira eles de costas pra você (não te batem).
    4. FLY MODE: Sistema de voo para farmar no céu.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // CONFIGURAÇÕES //
local LOCK_DISTANCE = 6     -- Distância (Bem perto, mas seguro)
local MAGNET_RANGE = 350    -- Alcance do puxão
local FLY_SPEED = 50        -- Velocidade do voo

-- Estados
local IsFarming = false
local IsFlying = false
local IsAutoClick = true
local IsAutoSkill = true
local SelectedMobs = {} 

-- Variáveis de Voo
local BodyGyro, BodyVelocity

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxNovaUI") then CoreGui.BloxNovaUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxNovaUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 400)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
MainFrame.BorderColor3 = Color3.fromRGB(170, 0, 255) -- Roxo Supernova
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🌌 SUPERNOVA v12"
Title.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScanBtn.Text = "1. SCANEAR MOBS"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Fly
local FlyBtn = Instance.new("TextButton", MainFrame)
FlyBtn.Size = UDim2.new(0.9, 0, 0, 35)
FlyBtn.Position = UDim2.new(0.05, 0, 0.22, 0)
FlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
FlyBtn.Text = "2. MODO VOO (OFF)"
FlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyBtn.Font = Enum.Font.GothamBold

-- Botão Farm
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "3. ATIVAR VORTEX TOTAL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16

-- Checkboxes
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.44, 0, 0, 30)
ClickBox.Position = UDim2.new(0.05, 0, 0.82, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ClickBox.Text = "Click: ON"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)

local SkillBox = Instance.new("TextButton", MainFrame)
SkillBox.Size = UDim2.new(0.44, 0, 0, 30)
SkillBox.Position = UDim2.new(0.51, 0, 0.82, 0)
SkillBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SkillBox.Text = "Skills: ON"
SkillBox.TextColor3 = Color3.fromRGB(0, 255, 0)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.3, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.33, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // SISTEMA DE VOO //

local function StartFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    
    BodyGyro = Instance.new("BodyGyro", root)
    BodyGyro.P = 9e4
    BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = root.CFrame
    
    BodyVelocity = Instance.new("BodyVelocity", root)
    BodyVelocity.velocity = Vector3.new(0, 0, 0)
    BodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    
    IsFlying = true
    FlyBtn.Text = "2. MODO VOO (ON)"
    FlyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    
    -- Animação de voo (opcional, só pra garantir que o char não caia)
    char.Humanoid.PlatformStand = true
end

local function StopFly()
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
    if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.PlatformStand = false
    end
    
    IsFlying = false
    FlyBtn.Text = "2. MODO VOO (OFF)"
    FlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
end

-- // COMBATE //

local function ApplyReach()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle")
        if handle then
            handle.Size = Vector3.new(30, 30, 30) -- Reach Grande
            handle.Massless = true
            handle.CanCollide = false
            if not handle:FindFirstChild("NovaBox") then
                local b = Instance.new("SelectionBox", handle)
                b.Name = "NovaBox"
                b.Adornee = handle
                b.Size3 = handle.Size
                b.Transparency = 0.8
                b.Color3 = Color3.fromRGB(170, 0, 255)
            end
        end
    end
end

local function SpamSkills()
    if not IsAutoSkill then return end
    local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
    for _, key in ipairs(keys) do
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait() 
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- // FARM LOGIC //

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

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    -- Lógica de Voo
    if IsFlying and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local camCF = Camera.CFrame
        
        BodyGyro.CFrame = camCF
        
        local vel = Vector3.new(0, 0, 0)
        local input = game:GetService("UserInputService")
        
        if input:IsKeyDown(Enum.KeyCode.W) then vel = vel + camCF.LookVector end
        if input:IsKeyDown(Enum.KeyCode.S) then vel = vel - camCF.LookVector end
        if input:IsKeyDown(Enum.KeyCode.A) then vel = vel - camCF.RightVector end
        if input:IsKeyDown(Enum.KeyCode.D) then vel = vel + camCF.RightVector end
        
        BodyVelocity.velocity = vel * FLY_SPEED
    end
    
    -- Lógica de Farm
    if IsFarming then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local myRoot = char.HumanoidRootPart
        
        ApplyReach()
        if IsAutoClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        SpamSkills()
        
        local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
        if not enemiesFolder then return end
        
        -- PUXA TODOS AO MESMO TEMPO
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                
                local mobRoot = mob.HumanoidRootPart
                local dist = (myRoot.Position - mobRoot.Position).Magnitude
                
                if dist <= MAGNET_RANGE then
                    -- 1. Posição de Travamento: Na sua frente, bem perto
                    -- CFrame.new(0, -2, -LOCK_DISTANCE) -> 2 studs abaixo e 6 na frente
                    -- Colocar um pouco abaixo ajuda a bugar o ataque deles
                    local lockPos = myRoot.CFrame * CFrame.new(0, -2, -LOCK_DISTANCE)
                    
                    mobRoot.CFrame = lockPos
                    mobRoot.Velocity = Vector3.new(0,0,0)
                    mobRoot.RotVelocity = Vector3.new(0,0,0)
                    
                    -- 2. VIRA DE COSTAS PARA VOCÊ (Segurança Máxima)
                    -- Faz o mob olhar para a mesma direção que você (ou seja, de costas pra vc)
                    mobRoot.CFrame = CFrame.new(mobRoot.Position, mobRoot.Position + myRoot.CFrame.LookVector)
                    
                    -- 3. Congela
                    mobRoot.Anchored = true
                    
                    -- 4. Quebra as armas deles (Pacify)
                    pcall(function() mob.Humanoid:UnequipTools() end)
                end
            end
        end
    end
end)

-- // EVENTOS //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

FlyBtn.MouseButton1Click:Connect(function()
    if IsFlying then StopFly() else StartFly() end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR VORTEX"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "3. ATIVAR VORTEX TOTAL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        
        -- Descongela mobs
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
    ClickBox.Text = IsAutoClick and "Click: ON" or "Click: OFF"
    ClickBox.TextColor3 = IsAutoClick and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

SkillBox.MouseButton1Click:Connect(function()
    IsAutoSkill = not IsAutoSkill
    SkillBox.Text = IsAutoSkill and "Skills: ON" or "Skills: OFF"
    SkillBox.TextColor3 = IsAutoSkill and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    StopFly()
    ScreenGui:Destroy()
end)