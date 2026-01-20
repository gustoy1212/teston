--[[
    🌌 RPG BLACK HOLE v41 (DAMAGE FIX)
    
    CORREÇÃO DE DANO:
    1. REACH OP: Transforma a 'Handle' da sua arma numa caixa de 60 studs.
       - Isso garante que o servidor detecte o toque no inimigo.
    2. ENEMY EXPAND: Aumenta a hitbox do inimigo também.
    3. MAGNET: Traz eles visualmente pra perto.
    
    RESULTADO: Sua arma gigante toca no inimigo gigante = Dano Confirmado.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().BlackHoleFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Magneto
    MagnetDist = 5,
    
    -- Hitboxes (O SEGREDO DO DANO)
    EnemyHitboxSize = 60,   -- Tamanho do inimigo
    WeaponReachSize = 50,   -- Tamanho da sua espada (Area Damage)
    
    -- Combate
    AutoClick = true,
    ClickDelay = 0.1,
}

local OriginalSizes = {} 

-- // GUI SETUP //
if CoreGui:FindFirstChild("BlackHoleFix") then CoreGui.BlackHoleFix:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BlackHoleFix"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🌌 BLACK HOLE (REACH)"
Title.TextColor3 = Color3.fromRGB(150, 50, 255)
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
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO LIMPEZA //
local function RestoreAll()
    -- Restaura Inimigos
    for mob, size in pairs(OriginalSizes) do
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            mob.HumanoidRootPart.Size = size
            mob.HumanoidRootPart.Transparency = 1
            mob.HumanoidRootPart.CanCollide = true
        end
    end
    -- Restaura Arma
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            tool.Handle.Size = Vector3.new(1,1,1) -- Tamanho padrão aprox
            tool.Handle.Transparency = 0
            if tool.Handle:FindFirstChild("ReachBox") then tool.Handle.ReachBox:Destroy() end
        end
    end
    OriginalSizes = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BlackHoleFarm = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOCALIZA PASTA //
local function GetEnemiesFolder()
    -- Tenta achar a pasta Client.Enemies (que vimos antes)
    if Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies") then
        return Workspace.Client.Enemies
    end
    -- Fallback: Procura qualquer coisa
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            return child
        end
    end
    return Workspace
end

-- // MODIFICADOR DE ARMA (REACH) //
local function ApplyReach()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    
    if tool and tool:FindFirstChild("Handle") then
        local h = tool.Handle
        if h.Size.X < 10 then -- Se ainda tá pequena
            h.Massless = true
            h.CanCollide = false
            h.Size = Vector3.new(SETTINGS.WeaponReachSize, SETTINGS.WeaponReachSize, SETTINGS.WeaponReachSize)
            h.Transparency = 0.8 -- Meio invisível
            
            -- Visualizador
            if not h:FindFirstChild("ReachBox") then
                local b = Instance.new("SelectionBox", h)
                b.Name = "ReachBox"
                b.Adornee = h
                b.Color3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
    return tool
end

-- // MAIN LOOP //
local isRunning = false
local lastClick = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
        RestoreAll()
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().BlackHoleFarm or not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local folder = GetEnemiesFolder()
    local count = 0
    
    -- 1. APLICA REACH NA ARMA
    local tool = ApplyReach()
    
    -- 2. PUXA E EXPANDE INIMIGOS
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            local root = mob:FindFirstChild("HumanoidRootPart")
            local hum = mob:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- Backup tamanho
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- Distância (Pega longe)
                if (root.Position - myRoot.Position).Magnitude < 3000 then
                    -- Magneto
                    root.CFrame = pullPos
                    root.Velocity = Vector3.new(0,0,0)
                    root.CanCollide = false
                    
                    -- Hitbox Expander (Inimigo Gigante)
                    root.Size = Vector3.new(SETTINGS.EnemyHitboxSize, SETTINGS.EnemyHitboxSize, SETTINGS.EnemyHitboxSize)
                    root.Transparency = 0.8
                    root.Color = Color3.fromRGB(100, 0, 255)
                    
                    count = count + 1
                end
            end
        end
    end
    
    Status.Text = "🔥 FRITANDO: " .. count
    
    -- 3. AUTO CLICK
    if SETTINGS.AutoClick and tool and count > 0 then
        if tick() - lastClick > SETTINGS.ClickDelay then
            tool:Activate()
            lastClick = tick()
        end
    end
end)