--[[
    🧟 HUNTER ZOMBIE - UNIVERSAL FARM (v6.0 KILL ALL)
    
    Mudança Crítica:
    - NÃO procura mais por nomes ("1", "2").
    - Procura por QUALQUER Humanoid vivo no mapa.
    - Sistema de Debug Visual:
      > AMARELO: Achei que é vivo.
      > VERMELHO: Estou atacando.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    HitboxSize = 50,         -- Tamanho da Hitbox
    DistanceAbove = 10,      -- Altura do voo
    ScanRange = 1000,        -- Distância máxima de busca
}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterZombieUniversal"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 80)
MainFrame.Position = UDim2.new(0.5, -100, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "UNIVERSAL KILLER"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES VISUAIS //
local function HighlightObj(model, color)
    if model:FindFirstChild("FarmESP") then model.FarmESP:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "FarmESP"
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.Parent = model
end

local function ExpandHitbox(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        root.CanCollide = false
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 0.6
        root.Color = Color3.fromRGB(255, 0, 0)
    end
end

-- // BUSCA UNIVERSAL (Procura Humanoids) //
local function GetUniversalTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = SETTINGS.ScanRange
    
    -- Varre descendentes (Pode ser pesado, mas acha tudo)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Verifica se é um Humanoid
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            
            -- FILTROS DE SEGURANÇA:
            -- 1. Não pode ser eu mesmo
            if model.Name ~= LocalPlayer.Name then
                -- 2. Tem que ter RootPart
                local root = model:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = model
                    end
                end
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Status.Text = "Parado"
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Auto Equip Tool
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    local target = GetUniversalTarget()
    
    if target then
        Status.Text = "Matando: " .. target.Name -- Vai mostrar o nome REAL
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        -- Visual e Hitbox
        HighlightObj(target, Color3.fromRGB(255, 0, 0))
        ExpandHitbox(target)
        
        -- TP Seguro
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            char.HumanoidRootPart.CFrame = tRoot.CFrame * CFrame.new(0, SETTINGS.DistanceAbove, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            
            if tool then tool:Activate() end
        end
    else
        Status.Text = "Procurando vidas..."
        Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    end
end)
