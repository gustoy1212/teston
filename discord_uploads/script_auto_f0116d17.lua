--[[
    🧙‍♂️ RPG MAGNET KILLER v39 (MANUAL EDITION)
    
    ESTRATÉGIA "UM POR UM":
    1. SCANNER: Busca o inimigo vivo mais próximo.
    2. MAGNETISMO: Traz a Hitbox dele para sua frente (5 studs de distância).
    3. SEM TRAVAMENTO: O inimigo fica sem colisão (CanCollide = false) para você andar livre.
    4. MANUAL: Você bate. Quando ele morrer, o script puxa o próximo automaticamente.
    
    CONTROLES:
    - Ative o script e fique parado ou ande. Os bichos virão até você.
    - Aperte X para fechar tudo.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância que o bicho fica de você (na sua frente)
    HitboxSize = 5,       -- Tamanho da Hitbox (Não precisa ser gigante, só grande o suficiente)
    PullSpeed = 1,        -- Velocidade de atualização (1 = Instantâneo)
    KillRange = 2000,     -- Raio de busca
}

local CurrentTarget = nil
local OriginalSize = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("RPGMagnet") then CoreGui.RPGMagnet:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnet"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🧲 MAGNET KILLER v39"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local TargetName = Instance.new("TextLabel", MainFrame)
TargetName.Size = UDim2.new(1, 0, 0, 20)
TargetName.Position = UDim2.new(0, 0, 0.5, 0)
TargetName.Text = "-"
TargetName.TextColor3 = Color3.fromRGB(100, 255, 100)
TargetName.BackgroundTransparency = 1
TargetName.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR MAGNETO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO LIMPEZA //
local function ReleaseTarget()
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") and OriginalSize then
        CurrentTarget.HumanoidRootPart.Size = OriginalSize
        CurrentTarget.HumanoidRootPart.Transparency = 1 -- Deixa invisível ou padrão
        CurrentTarget.HumanoidRootPart.CanCollide = true
        if CurrentTarget.HumanoidRootPart:FindFirstChild("MagESP") then
            CurrentTarget.HumanoidRootPart.MagESP:Destroy()
        end
    end
    CurrentTarget = nil
    OriginalSize = nil
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetRunning = false
    ReleaseTarget()
    ScreenGui:Destroy()
end)

-- // LOCALIZADOR DE PASTA //
local function GetEnemiesFolder()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            return child
        end
    end
    return Workspace
end

-- // BUSCA ALVO //
local function FindNextTarget()
    local folder = GetEnemiesFolder()
    local myPos = LocalPlayer.Character.PrimaryPart.Position
    local closest = nil
    local minDist = 9999
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= LocalPlayer.Character then
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            
            -- Só pega se tiver vivo e não for o alvo atual (se ele morreu)
            if hum and hum.Health > 0 and root then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist and dist < SETTINGS.KillRange then
                    minDist = dist
                    closest = mob
                end
            end
        end
    end
    return closest
end

-- // MAIN LOOP //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        ReleaseTarget()
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    -- Se não tem alvo ou alvo morreu, busca outro
    if not CurrentTarget or not CurrentTarget.Parent or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
        ReleaseTarget() -- Limpa o anterior
        local newTarget = FindNextTarget()
        
        if newTarget then
            CurrentTarget = newTarget
            local root = newTarget:FindFirstChild("HumanoidRootPart")
            if root then
                OriginalSize = root.Size -- Salva tamanho original
                
                -- Configura Visual
                local box = Instance.new("SelectionBox")
                box.Name = "MagESP"
                box.Adornee = root
                box.Color3 = Color3.fromRGB(0, 255, 0)
                box.Parent = root
                
                -- Aumenta um pouco pra ficar fácil de clicar
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                root.Transparency = 0.5 -- Meio transparente pra vc ver
                root.CanCollide = false -- PRA NÃO TE TRAVAR
                root.Massless = true
            end
        else
            Status.Text = "Procurando..."
            TargetName.Text = "Nenhum"
        end
    end
    
    -- SE TEM ALVO, PUXA ELE
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local root = CurrentTarget.HumanoidRootPart
        local hum = CurrentTarget.Humanoid
        
        if hum.Health > 0 then
            Status.Text = "🧲 PUXANDO..."
            TargetName.Text = CurrentTarget.Name .. " [" .. math.floor(hum.Health) .. "]"
            
            -- Traz pra frente do player
            local myCF = char.PrimaryPart.CFrame
            local pullPos = myCF * CFrame.new(0, 0, -SETTINGS.MagnetDist)
            
            root.CFrame = pullPos
            root.Velocity = Vector3.new(0,0,0) -- Tira inércia
            root.CanCollide = false -- Garante a cada frame
        else
            ReleaseTarget() -- Morreu, solta
        end
    end
end)