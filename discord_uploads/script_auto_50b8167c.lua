--[[
    🧬 ANIME MAGNET v2 - CLIENT ENEMIES EDITION
    
    ALVO CONFIRMADO: Workspace.Client.Enemies
    ESTRATÉGIA:
    1. Magneto: Traz os mobs dessa pasta específica para o Player.
    2. Auto Attack: Clica com a ferramenta automaticamente.
    3. Safe Mode: Sem colisão nos mobs.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

getgenv().AnimeFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância dos bichos na sua frente
    KillRange = 2000,     -- Pega monstros longe
    AutoClick = true,     -- Bater sozinho?
    ClickSpeed = 0.1,     -- Velocidade do clique
}

-- // GUI SETUP //
if CoreGui:FindFirstChild("GenesFarm") then CoreGui.GenesFarm:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GenesFarm"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧬 GENES FARM (MAGNET)"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR FARM (BASE)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO LIMPAR //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().AnimeFarm = false
    ScreenGui:Destroy()
end)

-- // LÓGICA PRINCIPAL //
local isRunning = false
local lastAttack = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR FARM (BASE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    end
end)

-- Loop Rápido (Heartbeat)
RunService.Heartbeat:Connect(function()
    if not getgenv().AnimeFarm or not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 1. LOCALIZA A PASTA ESPECÍFICA (A chave do sucesso!)
    local enemiesFolder = Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies")
    
    if not enemiesFolder then
        Status.Text = "⚠️ Pasta 'Client.Enemies' sumiu!"
        return
    end
    
    local myRoot = char.HumanoidRootPart
    -- Ponto de encontro: Na frente do player
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local count = 0
    
    -- 2. MAGNETO (Puxa os monstros)
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local eRoot = enemy:FindFirstChild("HumanoidRootPart")
        local eHum = enemy:FindFirstChild("Humanoid")
        
        -- Verifica vida > 0
        if eRoot and eHum and eHum.Health > 0 then
            local dist = (eRoot.Position - myRoot.Position).Magnitude
            
            if dist < SETTINGS.KillRange then
                -- Traz o inimigo
                eRoot.CFrame = pullPos
                eRoot.Velocity = Vector3.new(0,0,0)
                eRoot.CanCollide = false -- Fantasma
                eRoot.Transparency = 0.5 -- Meio transparente pra vc ver o bolo
                count = count + 1
            end
        end
    end
    
    Status.Text = "🔥 FRITANDO: " .. count .. " MOBS"
    
    -- 3. AUTO ATTACK (Bate sozinho)
    if SETTINGS.AutoClick and count > 0 then
        local tool = char:FindFirstChildOfClass("Tool")
        
        -- Auto Equip
        if not tool then
            local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
            if bp then char.Humanoid:EquipTool(bp) end
        end
        
        -- Click
        if tool and tick() - lastAttack > SETTINGS.ClickSpeed then
            tool:Activate()
            lastAttack = tick()
        end
    end
end)