--[[
    🧟 HUNTER ZOMBIE - THE RUNNER (v9.0 PHYSICS FARM)
    
    Correção Crítica:
    - Substituído TP (Teleporte) por MoveTo (Andar Rápido).
    - Motivo: É necessário COLIDIR com as portas para ativar os zumbis.
    
    Como funciona:
    1. Acha o Zumbi na pasta Entities.
    2. Corre até ele (Speed 50).
    3. Empurra portas e ativa gatilhos no caminho.
    4. Ataca quando estiver perto.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    WalkSpeed = 40,      -- Velocidade da corrida (Não exagere pra não bugar a porta)
    AttackDist = 8,      -- Distância para começar a bater
    FloatHeight = 0,     -- 0 = Chão (Melhor para abrir portas)
}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieRunner"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.5, -125, 0.8, 0) -- Em baixo para não atrapalhar
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ THE RUNNER v9"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
ToggleBtn.Text = "LIGAR SPEED RUN"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // BUSCA DO ALVO (ENTITIES) //
local function GetEntityTarget()
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    local zombiesFolder = entities:FindFirstChild("Zombie")
    if not zombiesFolder then return nil end
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = 9999
    
    for _, model in ipairs(zombiesFolder:GetChildren()) do
        local root = model:FindFirstChild("HumanoidRootPart")
        if root then
            -- Verifica se não é aquele "ScopeSStars" (Isca) pelo nome
            if model.Name ~= "ScopeSStars" then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = model
                end
            end
        end
    end
    return closest
end

-- // MOVIMENTO FÍSICO //
local function MoveToTarget(targetPosition)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    -- Aumenta velocidade para chegar rápido
    hum.WalkSpeed = SETTINGS.WalkSpeed
    
    -- Manda o boneco andar (Isso ativa colisão e portas)
    hum:MoveTo(targetPosition)
    
    -- Se tiver caindo ou preso, pula
    if hum.FloorMaterial == Enum.Material.Air then
        -- Lógica anti-queda simples
    end
end

-- // LOOP PRINCIPAL //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR SPEED RUN"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        Status.Text = "Parado"
        
        -- Restaura velocidade
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hum = char:FindFirstChild("Humanoid")
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    local target = GetEntityTarget()
    
    if target then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            Status.Text = "Correndo para: " .. target.Name
            Status.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            local dist = (char.HumanoidRootPart.Position - tRoot.Position).Magnitude
            
            if dist > SETTINGS.AttackDist then
                -- Corre até ele
                MoveToTarget(tRoot.Position)
            else
                -- Chegou perto: Para e Ataca
                hum:MoveTo(char.HumanoidRootPart.Position) -- Para de andar
                
                -- Olha para o inimigo
                char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, Vector3.new(tRoot.Position.X, char.HumanoidRootPart.Position.Y, tRoot.Position.Z))
                
                if tool then
                    tool:Activate()
                end
            end
        end
    else
        Status.Text = "Procurando na pasta Entities..."
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)
