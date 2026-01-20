--[[
    🧬 MAGNET GOD v45 (HYBRID - DEEP SCAN)
    
    CORREÇÃO DE "0 ALVOS":
    - Usa 'GetDescendants()' em vez de 'GetChildren()'.
    - Isso acha inimigos escondidos dentro de subpastas (ex: Waves, Groups).
    
    FUNCIONALIDADES:
    - Magneto (Motor v40): Puxa suave e constante.
    - Hitbox (Dano): Aumenta o tamanho do inimigo para você não errar o ataque.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetV45 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância na frente
    HitboxSize = 50,      -- TAMANHO GIGANTE (Pra garantir o dano)
    KillRange = 4000,     -- Alcance alto
}

-- Estados
local IsRunning = false
local MassTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("MagnetV45") then CoreGui.MagnetV45:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetV45"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧬 GOD v45 (DEEP SCAN)"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextWrapped = true
Status.TextSize = 12

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
ToggleBtn.Text = "LIGAR TUDO (PUXAR + DANO)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

-- Busca Profunda (Resolve o problema de não achar)
local function GetAllEnemies()
    local list = {}
    
    -- 1. Tenta a pasta da Autópsia (Busca Profunda)
    if Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies") then
        for _, obj in ipairs(Workspace.Client.Enemies:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                if obj.Humanoid.Health > 0 then
                    table.insert(list, obj)
                end
            end
        end
    end
    
    -- 2. Se não achou nada, tenta busca genérica no Workspace
    if #list == 0 then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if (obj.Name == "Mobs" or obj.Name == "BadEntities" or obj.Name == "Enemies") then
                for _, mob in ipairs(obj:GetDescendants()) do
                    if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                        if mob.Humanoid.Health > 0 then table.insert(list, mob) end
                    end
                end
            end
        end
    end
    
    return list
end

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- APLICA HITBOX (Dano)
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.7 
    root.Color = Color3.fromRGB(255, 0, 255) -- Roxo
    root.CanCollide = false -- Fantasma
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

local function RestoreAll()
    for mob, _ in pairs(MassTargets) do RestoreMob(mob) end
    MassTargets = {}
end

-- // CONTROLE //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR TUDO (PUXAR + DANO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
        RestoreAll()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetV45 = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetV45 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    -- Busca
    local enemies = GetAllEnemies()
    local count = 0
    
    for _, mob in ipairs(enemies) do
        local root = mob.HumanoidRootPart
        local dist = (root.Position - myRoot.Position).Magnitude
        
        if dist < SETTINGS.KillRange then
            MassTargets[mob] = true
            PrepareMob(mob) -- Aplica Hitbox Gigante
            
            -- Puxa (Magneto v40 Style)
            root.CFrame = pullPos
            root.Velocity = Vector3.new(0,0,0)
            
            count = count + 1
        end
    end
    
    Status.Text = "🧬 SUGANDO: " .. count .. " ALVOS"
end)