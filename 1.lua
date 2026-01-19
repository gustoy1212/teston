--[[
    🧟 HUNTER ZOMBIE - ULTIMATE FARM (v5.0 HYBRID)
    Baseado na análise dos seus scripts "Domain Expansion" e "Omni-Scanner".
    
    Técnicas Aplicadas:
    1. Hitbox Expander: Transforma inimigos em alvos gigantes (Fácil de acertar).
    2. Deep Scan: Acha inimigos numéricos em qualquer lugar.
    3. GUI Core: Estilo Dark Mode igual aos seus scripts.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES (Estilo Domain Expansion) //
local SETTINGS = {
    FarmEnabled = false,
    HitboxSize = 60,         -- Tamanho da Cabeça do Zumbi (Gigante)
    DistanceAbove = 12,      -- Distância segura (Voando acima da hitbox)
    AttackDelay = 0.1        -- Velocidade do Spam
}

-- // GUI SETUP (Estilo Omni-Scanner) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterZombieUltimate"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.5, -125, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 100) -- Vermelho Neon
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧟 HUNTER ZOMBIE (DOMAIN)"
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.fromRGB(255, 0, 100)
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES TÉCNICAS (Adaptadas dos seus arquivos) //

-- Expande a Hitbox (Igual ao seu script Domain Expansion)
local function ExpandHitbox(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    if root then
        -- Salva tamanho original pra não bugar visualmente pra sempre
        if not model:FindFirstChild("OriginalSize") then
            local val = Instance.new("Vector3Value", model)
            val.Name = "OriginalSize"
            val.Value = root.Size
        end
        
        root.CanCollide = false
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 0.7
        root.Color = Color3.fromRGB(255, 0, 0) -- Fica vermelho pra você ver
        root.Material = Enum.Material.ForceField
    end
end

-- Restaura (Limpeza)
local function RestoreHitbox(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    local orig = model:FindFirstChild("OriginalSize")
    if root and orig then
        root.Size = orig.Value
        root.Transparency = 1
        orig:Destroy()
    end
end

-- Busca Profunda (Deep Scan + Filtro Numérico)
local function GetTarget()
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = 99999

    -- Varre TUDO (igual ao seu Omni-Scanner)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            -- Validação: Nome numérico e Vida > 0
            if tonumber(obj.Name) ~= nil and obj.Humanoid.Health > 0 then
                local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
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
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "Buscando alvos..."
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Status.Text = "Parado."
    end
end)

RunService.Heartbeat:Connect(function()
    if not isRunning then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        -- Auto Equip
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end

    local target = GetTarget()
    
    if target then
        Status.Text = "Alvo: " .. target.Name
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        -- 1. Expande Hitbox (pra facilitar o hit)
        ExpandHitbox(target)
        
        -- 2. Teleporta pra CIMA da hitbox (Safe Spot)
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            char.HumanoidRootPart.CFrame = tRoot.CFrame * CFrame.new(0, SETTINGS.DistanceAbove, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0) -- Anti-Queda
            
            -- 3. Ataca
            if tool then
                tool:Activate()
            end
        end
    else
        Status.Text = "Nenhum inimigo encontrado..."
        Status.TextColor3 = Color3.fromRGB(255, 100, 0)
    end
end)
