--[[
    🧟 HUNTER ZOMBIE - AUTO FARM (v4.0 DEEP SCAN)
    
    Correções:
    - Usa GetDescendants() para achar inimigos escondidos em sub-pastas.
    - Adiciona ESP (Brilho) no alvo atual para você saber quem ele está focando.
    - Teleporte Agressivo com trava de segurança.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmEnabled = false,
    DistanceAboveHead = 5,   -- Altura do TP
}

-- // GUI //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterZombieDeep"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 60)
MainFrame.Position = UDim2.new(0.5, -80, 0.1, 0) -- No meio, em cima
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -10, 1, -10)
ToggleBtn.Position = UDim2.new(0, 5, 0, 5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.Text = "LIGAR FARM (Deep Scan)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame

ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "FARM LIGADO (BUSCANDO...)"
        ToggleBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        ToggleBtn.Text = "FARM DESLIGADO"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

-- // FUNÇÃO DE ESP (HIGHLIGHT) //
local currentHighlight = nil

local function highlightTarget(model)
    if currentHighlight then currentHighlight:Destroy() currentHighlight = nil end
    
    local hl = Instance.new("Highlight")
    hl.Name = "FarmTargetESP"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.Parent = model
    currentHighlight = hl
end

-- // LÓGICA DE BUSCA PROFUNDA //
local function getDeepClosestEnemy()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = char.HumanoidRootPart.Position
    local closest = nil
    local minDist = 5000 -- Raio máximo de busca (aumentei pra pegar o mapa todo)
    
    -- GetDescendants varre TUDO (Pastas, Mapas, Subpastas)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            -- Verifica se é numérico
            if tonumber(obj.Name) ~= nil then
                if obj.Humanoid.Health > 0 then
                    local dist = (obj.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    return closest
end

-- // LOOP //
RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then 
        if currentHighlight then currentHighlight:Destroy() currentHighlight = nil end
        return 
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local tool = char:FindFirstChildOfClass("Tool")
    
    if not tool then
        local bpTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bpTool then char.Humanoid:EquipTool(bpTool) end
    end

    -- Busca (Pode ser um pouco mais pesado, mas garante achar)
    local target = getDeepClosestEnemy()
    
    if target then
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            -- Marca visualmente o alvo
            if not target:FindFirstChild("FarmTargetESP") then
                highlightTarget(target)
            end
            
            -- TP
            local safePos = tRoot.CFrame * CFrame.new(0, SETTINGS.DistanceAboveHead, 0)
            hrp.CFrame = safePos
            hrp.Velocity = Vector3.new(0,0,0)
            
            -- Ataque
            if tool then tool:Activate() end
        end
    end
end)
