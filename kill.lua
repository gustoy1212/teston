--[[
    🧟 HUNTER ZOMBIE - AUTO FARM (v3.0 TELEPORTE INSTANTÂNEO)
    
    Mudanças:
    - Removeu o voo (Tween) -> Agora é Teleporte direto.
    - Adicionou DEBUG: Aperte F9 para ver o que o script está "pensando".
    - Busca profunda: Procura inimigos em pastas também.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    DistanceAboveHead = 5,   -- Altura acima da cabeça
    AttackDist = 10,         -- Distância para clicar
}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterZombieTeleport"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = "TP FARM: OFF 🔴"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "TP FARM: ON 🟢"
        ToggleBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
        print("✅ [DEBUG] Farm Ativado!")
    else
        ToggleBtn.Text = "TP FARM: OFF 🔴"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        print("🛑 [DEBUG] Farm Parado.")
    end
end)

-- // LÓGICA DE BUSCA //

local function isEnemy(model)
    -- Verifica se é um modelo vivo
    if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        -- Verifica se o nome é um número (Ex: "1", "2")
        if tonumber(model.Name) ~= nil then
            if model.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

local function getClosestEnemy()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = char.HumanoidRootPart.Position
    local closest = nil
    local minDist = math.huge
    
    -- Varre o Workspace (GetChildren é mais rápido, mas se estiver em pasta avisa)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if isEnemy(obj) then
            local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
            if dist < minDist then
                minDist = dist
                closest = obj
            end
        end
    end
    
    -- Se não achou nada no Workspace raiz, tenta procurar um pouco mais fundo (caso tenha pasta Mobs)
    if not closest then
        -- Otimização: Só procura em pastas chamadas "Mobs" ou "Enemies" se existirem
        -- Se não souber o nome, deixe assim por enquanto.
    end

    return closest
end

-- // LOOP PRINCIPAL //
local lastDebugTime = 0

RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local tool = char:FindFirstChildOfClass("Tool")
    
    -- Garante a tool
    if not tool then
        local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bpTool then char.Humanoid:EquipTool(bpTool) end
    end

    local target = getClosestEnemy()
    
    if target then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            -- TELEPORTE INSTANTÂNEO (TP)
            -- Fica na cabeça (CFrame do bicho + Subir Y)
            local safePos = tRoot.CFrame * CFrame.new(0, SETTINGS.DistanceAboveHead, 0)
            
            -- Aplica o TP
            hrp.CFrame = safePos
            hrp.Velocity = Vector3.new(0,0,0) -- Zera a física pra não cair
            
            -- Debug a cada 1 segundo pra não spammar
            if tick() - lastDebugTime > 1 then
                print("⚔️ [DEBUG] Atacando Inimigo: " .. target.Name)
                lastDebugTime = tick()
            end
            
            -- Ataque
            if tool then
                tool:Activate()
            end
        end
    else
        -- Debug se não achar ninguém
        if tick() - lastDebugTime > 2 then
            print("⚠️ [DEBUG] Nenhum inimigo com nome numérico encontrado no Workspace!")
            lastDebugTime = tick()
        end
    end
end)

print("✅ Script v3.0 (TP Edition) Carregado! Aperte F9 se der erro.")
