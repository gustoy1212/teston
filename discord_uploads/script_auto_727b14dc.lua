--[[
    🎯 MAGNET GOD v46 (TARGET SEEKER)
    
    SOLUÇÃO DEFINITIVA PARA "0 ALVOS":
    - Não busca pastas. Busca pelo NOME do inimigo.
    - Se o inimigo se chama "Genes", o script vai achar ele onde estiver.
    
    BASE: Motor v40 (Puxar) + Hitbox v44 (Dano).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetV46 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,
    HitboxSize = 40,
    TargetName = "Genes", -- Nome padrão
}

local IsRunning = false
local FoundTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("TargetMagnet") then CoreGui.TargetMagnet:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TargetMagnet"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🎯 TARGET SEEKER v46"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- Caixa de Nome
local NameBox = Instance.new("TextBox", MainFrame)
NameBox.Size = UDim2.new(0.9, 0, 0.2, 0)
NameBox.Position = UDim2.new(0.05, 0, 0.25, 0)
NameBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.Text = "Genes" -- Nome do Alvo
NameBox.PlaceholderText = "Nome do Inimigo aqui..."
NameBox.Font = Enum.Font.GothamBold
NameBox.TextSize = 16

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.5, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "BUSCAR E PUXAR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function ScanForTarget()
    local nameToFind = NameBox.Text:lower()
    local list = {}
    
    -- Varre TUDO no Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Verifica se o nome bate (ignora maiúscula/minúscula)
        if obj:IsA("Model") and obj.Name:lower():find(nameToFind) then
            local hum = obj:FindFirstChild("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- Hitbox Gigante
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.6
    root.CanCollide = false
    root.Color = Color3.fromRGB(0, 255, 0)
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
    for mob, _ in pairs(FoundTargets) do RestoreMob(mob) end
    FoundTargets = {}
end

-- // BOTÕES //
ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "BUSCAR E PUXAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetV46 = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP //
RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetV46 or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    -- Escaneia a cada frame (Pode ser pesado, mas garante achar)
    -- Se lagar, avisa que coloco um delay
    local targets = ScanForTarget()
    
    for _, mob in ipairs(targets) do
        FoundTargets[mob] = true
        PrepareMob(mob)
        
        -- Puxa (Magneto v40)
        mob.HumanoidRootPart.CFrame = pullPos
        mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
    
    Status.Text = "Alvos Achados: " .. #targets
end)