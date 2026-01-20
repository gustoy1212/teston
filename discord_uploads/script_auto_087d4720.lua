--[[
    🏹 RPG HUNTER v1 (SPAWNED ENTITIES)
    
    ALVO CONFIRMADO: Workspace.SpawnedEntities
    (Funciona para Lobo, Galinha, Slime e qualquer coisa nova que nascer)
    
    MODO: Duelista (Puxa 1 por vez para não lagar/bugar).
    DANO: Garante acerto com Hitbox Expandida e Proximidade.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().HunterV1 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Distance = 3,         -- Distância do "Abraço" (Perto pra bater)
    HitboxSize = 20,      -- Tamanho do alvo (Cubo)
    SearchRange = 5000,   -- Busca no mapa todo
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalSize = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("HunterUI") then CoreGui.HunterUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "HunterUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏹 HUNTER v1 (UNIVERSAL)"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "LIGAR CAÇADA (1v1)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

local function RestoreTarget()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") and OriginalSize then
        CurrentTarget.HumanoidRootPart.Size = OriginalSize
        CurrentTarget.HumanoidRootPart.Transparency = 1
        CurrentTarget.HumanoidRootPart.CanCollide = true
    end
    CurrentTarget = nil
    OriginalSize = nil
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().HunterV1 = false
    RestoreTarget()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR CAÇADA (1v1)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        RestoreTarget()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().HunterV1 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 1. VERIFICA ALVO ATUAL (Foco Total)
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
        
        -- Se morreu ou sumiu, libera para o próximo
        if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
            RestoreTarget()
        else
            Status.Text = "⚔️ ALVO: " .. CurrentTarget.Name
            
            -- PUXA (Magneto)
            local myRoot = char.HumanoidRootPart
            local targetPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.Distance)
            
            root.CFrame = targetPos
            root.Velocity = Vector3.new(0,0,0) -- Anula física/knockback
            root.CanCollide = false
            
            -- HITBOX (Garante que o soco pegue)
            if not OriginalSize then OriginalSize = root.Size end
            root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
            root.Transparency = 0.6
            root.Color = Color3.fromRGB(0, 255, 255) -- Ciano
            return -- Sai do loop para não buscar outro
        end
    end
    
    -- 2. BUSCA NOVO ALVO (Na pasta SpawnedEntities)
    local folder = Workspace:FindFirstChild("SpawnedEntities")
    if not folder then Status.Text = "⚠️ Pasta 'SpawnedEntities' sumiu!" return end
    
    local closestDist = SETTINGS.SearchRange
    local potentialTarget = nil
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                potentialTarget = mob
            end
        end
    end
    
    if potentialTarget then
        CurrentTarget = potentialTarget
    else
        Status.Text = "Procurando Presas..."
    end
end)