--[[
    🕳️ BLOX FRUITS - BLACK HOLE FARM v9
    
    ESTRATÉGIA:
    1. Vai para debaixo da terra (Stealth).
    2. Puxa os mobs para baixo (Vertical Magnet).
    3. Usa Fast Attack para travar eles (Stun).
    4. Reach Modesto (25 studs) para bater sem colar neles.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local UNDERGROUND_DEPTH = 40    -- Profundidade (40 studs abaixo do mob)
local ATTACK_RANGE = 25         -- Tamanho da Hitbox do seu soco
local MAGNET_RANGE = 250        -- Raio de busca

-- Estados
local IsFarming = false
local IsAutoClick = true
local SelectedMobs = {} 
local CurrentTarget = nil
local BasePlatform = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxHoleUI") then CoreGui.BloxHoleUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxHoleUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🕳️ BLACK HOLE v9"
Title.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.12, 0)
Status.Text = "Status: Superfície"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScanBtn.Text = "1. SCANEAR ÁREA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Farm
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.72, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "2. INICIAR BURACO NEGRO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- Checkbox Auto Click
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 25)
ClickBox.Position = UDim2.new(0.05, 0, 0.9, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ClickBox.Text = "Fast Attack: ON"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.45, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.3, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES MÁGICAS //

-- Aplica Reach (Hitbox Extendida)
local function ApplyReach()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle")
        if handle then
            handle.Size = Vector3.new(ATTACK_RANGE, ATTACK_RANGE, ATTACK_RANGE)
            handle.Massless = true
            handle.CanCollide = false
            -- Visualizador
            if not handle:FindFirstChild("ReachVis") then
                local box = Instance.new("SelectionBox", handle)
                box.Name = "ReachVis"
                box.Adornee = handle
                box.Size3 = Vector3.new(ATTACK_RANGE, ATTACK_RANGE, ATTACK_RANGE)
                box.Transparency = 0.9
                box.Color3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end

-- Fast Attack (Clica muito rápido)
local function FastAttack()
    if IsAutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

-- Gerencia a Plataforma Subterrânea
local function UpdatePlatform(pos)
    if not BasePlatform then
        BasePlatform = Instance.new("Part", Workspace)
        BasePlatform.Name = "FarmPlatform"
        BasePlatform.Size = Vector3.new(20, 1, 20)
        BasePlatform.Anchored = true
        BasePlatform.Transparency = 0.5
        BasePlatform.Color = Color3.fromRGB(100, 0, 255)
    end
    -- Mantém a plataforma embaixo do target
    BasePlatform.CFrame = CFrame.new(pos.X, pos.Y - UNDERGROUND_DEPTH, pos.Z)
end

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

-- Encontra o mob MAIS PRÓXIMO (Surface)
local function GetTarget()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return nil end
    
    local closest, minDist = nil, MAGNET_RANGE
    -- Usa a posição da câmera ou do player na superfície (ignorando Y)
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            -- Calcula distância horizontal apenas (pra não bugar quando descer)
            local mobPos = mob.HumanoidRootPart.Position
            local dist = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(mobPos.X, 0, mobPos.Z)).Magnitude
            
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
        
        -- Garante Reach e Fast Attack
        ApplyReach()
        FastAttack()
        
        -- Busca Alvo
        if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
            CurrentTarget = GetTarget()
        end
        
        if CurrentTarget then
            local tRoot = CurrentTarget.HumanoidRootPart
            
            Status.Text = "⚔️ Matando: " .. CurrentTarget.Name
            
            -- 1. Cria/Move Plataforma para DEBAIXO do Mob
            -- (Mas mantém a coordenada Y baixa)
            local surfacePos = tRoot.Position
            UpdatePlatform(surfacePos)
            
            -- 2. Teleporta Player para a Plataforma (Segurança)
            myRoot.CFrame = BasePlatform.CFrame * CFrame.new(0, 3, 0)
            myRoot.Velocity = Vector3.new(0,0,0)
            
            -- 3. PUXA O MOB PARA BAIXO (Buraco Negro)
            -- Como estamos exatamente embaixo dele (X, Z iguais), ele cai
            tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 2, -3) -- 3 studs na frente
            tRoot.Velocity = Vector3.new(0, -50, 0) -- Força pra baixo
            
            -- 4. Congela levemente
            tRoot.RotVelocity = Vector3.new(0,0,0)
            
        else
            Status.Text = "🔎 Procurando..."
            -- Se não tem mob, volta um pouco pra cima pra procurar (Opcional)
        end
    end
end)

-- // EVENTOS UI //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "2. INICIAR BURACO NEGRO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        Status.Text = "Status: Superfície"
        CurrentTarget = nil
        if BasePlatform then BasePlatform:Destroy() BasePlatform = nil end
        
        -- Teleporta de volta pra superfície (segurança)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, UNDERGROUND_DEPTH + 5, 0)
        end
    end
end)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "Fast Attack: ON"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        ClickBox.Text = "Fast Attack: OFF"
        ClickBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    if BasePlatform then BasePlatform:Destroy() end
    ScreenGui:Destroy()
end)