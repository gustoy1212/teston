--[[
    🐍 RPG MEDUSA v42 (ANTI-EVADE / GUARANTEE HIT)
    
    ESTRATÉGIA PARA NUNCA ERRAR:
    1. MAGNETO: Puxa os inimigos para um ponto fixo.
    2. ANCHOR (Congelar): Trava a física do inimigo (Anchored=true).
       - Eles não podem se mexer, nem usar animação de esquiva.
    3. TOUCH SPAM: Força o toque físico da arma na "estátua" do inimigo.
    4. ANIM BOOST: Mantém o ataque rápido (50x).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MedusaRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância da "estátua" na sua frente
    KillRange = 3000,     -- Alcance do magnetismo
    AnimSpeed = 50,       -- Velocidade do ataque (Dano alto)
}

-- Estados
local IsRunning = false
local CurrentMode = "MASS" -- Começa no modo MASS (Buraco Negro)
local FrozenTargets = {}   -- Lista dos que foram transformados em pedra
local OriginalState = {}   -- Backup para restaurar depois

-- // GUI SETUP //
if CoreGui:FindFirstChild("RPGMedusa") then CoreGui.RPGMedusa:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "RPGMedusa"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🐍 MEDUSA: ANTI-EVADE"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
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
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ModeBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
ModeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ModeBtn.Text = "MODO: BURACO NEGRO (MASS)"
ModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
ToggleBtn.Text = "LIGAR MEDUSA (CONGELAR)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DO NÚCLEO //

-- 1. Busca a pasta correta (Baseado nas suas prints anteriores)
local function GetEnemiesFolder()
    if Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies") then
        return Workspace.Client.Enemies -- Alvo principal (Genes)
    end
    -- Fallback genérico
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("Enemies") or child.Name:match("Mobs") then return child end
    end
    return Workspace
end

-- 2. Transforma em Pedra (Congela)
local function FreezeMob(mob, positionCFrame)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Backup
    if not OriginalState[mob] then OriginalState[mob] = {Anchored = root.Anchored, CanCollide = root.CanCollide} end
    
    -- O SEGREDO: Teleporta E Trava
    root.CFrame = positionCFrame
    root.Velocity = Vector3.new(0,0,0) -- Para o movimento atual
    root.Anchored = true   -- TRAVA NO ESPAÇO (Adeus esquiva)
    root.CanCollide = false -- Para eles ficarem um dentro do outro
    
    -- Visual (Opcional: Deixa vermelho pra saber que tá travado)
    root.Transparency = 0.5
    root.Color = Color3.fromRGB(255, 50, 50) 
end

-- 3. Descongela (Restaura)
local function UnfreezeMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and OriginalState[mob] then
        root.Anchored = OriginalState[mob].Anchored
        root.CanCollide = OriginalState[mob].CanCollide
        root.Transparency = 1 -- Volta ao normal (invisível)
    end
    OriginalState[mob] = nil
    FrozenTargets[mob] = nil
end

local function RestoreAll()
    for mob, _ in pairs(FrozenTargets) do UnfreezeMob(mob) end
    FrozenTargets = {}
end

-- // INTERFACE E CONTROLE //
ModeBtn.MouseButton1Click:Connect(function()
    RestoreAll()
    if CurrentMode == "SINGLE" then
        CurrentMode = "MASS"
        ModeBtn.Text = "MODO: BURACO NEGRO (MASS)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    else
        CurrentMode = "SINGLE"
        ModeBtn.Text = "MODO: 1v1 (SINGLE)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 0)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR MEDUSA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MEDUSA (CONGELAR)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
        RestoreAll()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MedusaRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL (RENDERSTEPPED - Prioridade Máxima) //
RunService.RenderStepped:Connect(function()
    if not getgenv().MedusaRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local myRoot = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    local tool = char:FindFirstChildOfClass("Tool")
    
    -- A) Acelera Animação (Dano Booster Embutido)
    if hum and tool then
        local animator = hum:FindFirstChild("Animator") or hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(SETTINGS.AnimSpeed)
            end
        end
        tool:Activate() -- Spam Click
    end
    
    if not IsRunning then return end
    
    -- B) Lógica Medusa (Congelar Inimigos)
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local folder = GetEnemiesFolder()
    local currentFrozenCount = 0
    
    local targetsToFreeze = {}
    
    -- Define quem vai ser congelado
    if CurrentMode == "MASS" then
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and mob ~= char and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                 if (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude < SETTINGS.KillRange then
                    table.insert(targetsToFreeze, mob)
                 end
            end
        end
    elseif CurrentMode == "SINGLE" then
        -- (Lógica simplificada pra 1v1, pega o mais perto)
        local closest, minDist = nil, 9999
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist < minDist then minDist = dist closest = mob end
            end
        end
        if closest then table.insert(targetsToFreeze, closest) end
    end
    
    -- Aplica o Congelamento e Força o Dano
    for _, mob in ipairs(targetsToFreeze) do
        FrozenTargets[mob] = true
        FreezeMob(mob, pullPos) -- Vira pedra na sua frente
        currentFrozenCount = currentFrozenCount + 1
        
        -- GARANTIA DE HIT (Força toque físico)
        if tool and tool:FindFirstChild("Handle") and firetouchinterest then
            firetouchinterest(tool.Handle, mob.HumanoidRootPart, 0) -- Toca
            firetouchinterest(tool.Handle, mob.HumanoidRootPart, 1) -- Solta
        end
    end
    
    -- Limpa os mortos da lista de congelados
    for mob, _ in pairs(FrozenTargets) do
        if not mob.Parent or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then
            UnfreezeMob(mob)
        end
    end
    
    Status.Text = "🐍 ESTATUAS: " .. currentFrozenCount
end)