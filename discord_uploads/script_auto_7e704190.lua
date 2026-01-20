--[[
    🧙‍♂️ RPG MAGNET GOD v40 (DELTA MOBILE)
    
    ADAPTADO PARA: Novo RPG (Pasta Workspace.Mobs)
    
    MODOS:
    1. SINGLE (1v1): Puxa um bicho por vez (Seguro).
    2. MASS (Buraco Negro): Puxa TODOS os monstros vivos da pasta Mobs.
    
    INTERFACE:
    - Botões grandes para celular.
    - Começa ABERTO.
    - Botão MENU para minimizar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetGodRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância (Frente do player)
    HitboxSize = 5,       -- Tamanho da Hitbox
    KillRange = 2500,     -- Raio de busca
}

-- Variáveis de Estado
local MagState = {
    Running = false,
    Mode = "MASS", -- Começa no modo MASS (Buraco Negro) por padrão
    Targets = {},       
    SingleTarget = nil,
    OriginalSizes = {}     
}

-- // GUI SETUP (SIMPLIFICADO PARA MOBILE) //
if CoreGui:FindFirstChild("RPGMagnetMobile") then CoreGui.RPGMagnetMobile:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetMobile"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 1. BOTÃO TOGGLE MENU (ABRIR/FECHAR)
local MenuBtn = Instance.new("TextButton", ScreenGui)
MenuBtn.Size = UDim2.new(0, 60, 0, 60)
MenuBtn.Position = UDim2.new(0.85, 0, 0.15, 0) -- Canto direito
MenuBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
MenuBtn.Text = "MENU"
MenuBtn.TextColor3 = Color3.WHITE
MenuBtn.Font = Enum.Font.GothamBlack
MenuBtn.TextSize = 14
-- Arredondar
local Corner = Instance.new("UICorner", MenuBtn)
Corner.CornerRadius = UDim.new(1, 0)

-- 2. PAINEL PRINCIPAL
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0.5, 0, 0.4, 0) -- Tamanho médio
MainFrame.Position = UDim2.new(0.25, 0, 0.3, 0) -- Centro
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.Visible = true -- Começa visível
MainFrame.Active = true
MainFrame.Draggable = true

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.Text = "🧲 MAGNET GOD v40"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextScaled = true

-- STATUS TEXT
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0.15, 0)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.Gotham

-- BOTÃO MODO (SINGLE/MASS)
local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ModeBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ModeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Vermelho (MASS)
ModeBtn.Text = "MODO: 🌌 MASS (Buraco Negro)"
ModeBtn.TextColor3 = Color3.WHITE
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextScaled = true

-- BOTÃO LIGAR/DESLIGAR
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR MAGNETO"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextScaled = true

-- // LÓGICA DE INTERFACE //

MenuBtn.Activated:Connect(function() -- Usa Activated pro mobile
    MainFrame.Visible = not MainFrame.Visible
end)

-- // FUNÇÕES AUXILIARES //

-- Procura a pasta certa com base na sua imagem (Workspace.Mobs)
local function GetEnemiesFolder()
    if Workspace:FindFirstChild("Mobs") then
        return Workspace.Mobs
    end
    -- Fallback caso mude o nome
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") then
            return child
        end
    end
    return Workspace
end

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Salva tamanho original
    if not MagState.OriginalSizes[mob] then
        MagState.OriginalSizes[mob] = root.Size
    end
    
    -- Transforma em "Fantasma Magnético"
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.6
    root.Color = (MagState.Mode == "MASS") and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    root.CanCollide = false
    root.Massless = true
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and MagState.OriginalSizes[mob] then
        root.Size = MagState.OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
        root.Color = Color3.new(1,1,1) -- Restaura cor aprox
    end
    MagState.OriginalSizes[mob] = nil
end

local function RestoreAll()
    if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) MagState.SingleTarget = nil end
    for mob, _ in pairs(MagState.Targets) do RestoreMob(mob) end
    MagState.Targets = {}
end

-- // EVENTOS DOS BOTÕES //

ModeBtn.Activated:Connect(function()
    RestoreAll() -- Limpa ao trocar de modo
    if MagState.Mode == "SINGLE" then
        MagState.Mode = "MASS"
        ModeBtn.Text = "MODO: 🌌 MASS (Buraco Negro)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        MagState.Mode = "SINGLE"
        ModeBtn.Text = "MODO: ⚔️ SINGLE (1v1)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
    end
end)

ToggleBtn.Activated:Connect(function()
    MagState.Running = not MagState.Running
    if MagState.Running then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
    end
end)

-- // LÓGICA PRINCIPAL (HEARTBEAT) //
RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetGodRunning then return end
    if not MagState.Running then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local folder = GetEnemiesFolder()
    
    if MagState.Mode == "SINGLE" then
        -- === LÓGICA 1v1 === --
        if MagState.SingleTarget and MagState.SingleTarget.Parent and MagState.SingleTarget:FindFirstChild("Humanoid") and MagState.SingleTarget.Humanoid.Health > 0 then
            PrepareMob(MagState.SingleTarget)
            local r = MagState.SingleTarget.HumanoidRootPart
            if r then
                r.CFrame = pullPos
                r.Velocity = Vector3.new(0,0,0)
                Status.Text = "🧲 ALVO: " .. MagState.SingleTarget.Name
            end
        else
            -- Busca novo
            if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) end
            MagState.SingleTarget = nil
            
            local closest = nil
            local minDist = 9999
            for _, mob in ipairs(folder:GetChildren()) do
                if mob:IsA("Model") and mob ~= char then
                    local hum = mob:FindFirstChild("Humanoid")
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if dist < minDist and dist < SETTINGS.KillRange then
                            minDist = dist
                            closest = mob
                        end
                    end
                end
            end
            MagState.SingleTarget = closest
            Status.Text = "Procurando..."
        end
        
    elseif MagState.Mode == "MASS" then
        -- === LÓGICA BURACO NEGRO (MASS) === --
        local count = 0
        
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and mob ~= char then
                local hum = mob:FindFirstChild("Humanoid")
                local root = mob:FindFirstChild("HumanoidRootPart")
                
                if hum and hum.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    
                    if dist < SETTINGS.KillRange then
                        MagState.Targets[mob] = true
                        PrepareMob(mob)
                        
                        -- PUXA TODOS PRO MESMO LUGAR
                        root.CFrame = pullPos
                        root.Velocity = Vector3.new(0,0,0)
                        count = count + 1
                    end
                else
                    -- Limpa mortos da lista
                    if MagState.Targets[mob] then
                        RestoreMob(mob)
                        MagState.Targets[mob] = nil
                    end
                end
            end
        end
        Status.Text = "🌌 PUXANDO: " .. count .. " MOBS"
    end
end)