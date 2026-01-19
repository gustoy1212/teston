--[[
    🧟 HUNTER ZOMBIE - THE SURGEON (v8.0 STRUCTURE FARM)
    
    DESCOBERTA: Os zumbis não têm Humanoid e ficam em Workspace.Entities.Zombie
    
    Lógica Nova:
    1. Foca EXCLUSIVAMENTE na pasta 'Entities/Zombie'.
    2. Não checa vida (Assume que se existe na pasta, está vivo).
    3. Teleporta para o 'HumanoidRootPart' encontrado na autópsia.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    Distance = 5,       -- Distância do ataque (Bem perto, já que não tem hitbox gigante)
    Height = 2,         -- Altura (Levemente acima do chão)
    AttackDelay = 0.1   -- Velocidade do clique
}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieSurgeon"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.5, -125, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 10) -- Verde Escuro
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "THE SURGEON v8"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 255, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
ToggleBtn.Text = "LIGAR FARM (ENTITIES)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE BUSCA CIRÚRGICA //
local function GetEntityTarget()
    -- 1. Verifica se a pasta existe (Segurança)
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then return nil end
    
    local zombiesFolder = entities:FindFirstChild("Zombie")
    if not zombiesFolder then return nil end
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = 9999
    
    -- 2. Varre apenas a pasta descoberta
    for _, model in ipairs(zombiesFolder:GetChildren()) do
        -- A Autópsia mostrou que eles têm HumanoidRootPart
        local root = model:FindFirstChild("HumanoidRootPart")
        
        if root then
            local dist = (root.Position - myPos).Magnitude
            if dist < minDist then
                minDist = dist
                closest = model
            end
        end
    end
    
    return closest
end

-- // LOOP PRINCIPAL //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        ToggleBtn.Text = "LIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        Status.Text = "Parado"
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Auto Equip (Essencial)
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    local target = GetEntityTarget()
    
    if target then
        Status.Text = "Alvo: " .. target.Name -- Deve mostrar "10", "4", etc.
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            -- TP SIMPLES (Sem voar muito alto pra garantir o hit)
            -- Fica atrás do zumbi
            local attackPos = tRoot.CFrame * CFrame.new(0, SETTINGS.Height, SETTINGS.Distance)
            
            char.HumanoidRootPart.CFrame = attackPos
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0) -- Trava física
            
            -- Olha para o zumbi (Face Target)
            char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, tRoot.Position)
            
            if tool then
                tool:Activate()
            end
        end
    else
        Status.Text = "Pasta Entities vazia..."
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)
