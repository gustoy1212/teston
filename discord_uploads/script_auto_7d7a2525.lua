--[[
    🧙‍♂️ RPG MAGNET GOD v43 (INFINITE EDITION)
    
    ATUALIZAÇÕES:
    - ALCANCE INFINITO: Puxa de qualquer lugar do mapa.
    - TRAVA AGRESSIVA: Impede que o monstro volte.
    - SUPORTE: Funciona com 'HumanoidRootPart' ou 'RootPart'.
    
    COMO USAR:
    - Fique na base.
    - Ligue o Magneto.
    - Os monstros devem teleportar na sua cara.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância na sua frente (Studs)
    HitboxSize = 5,       -- Tamanho da Hitbox
    KillRange = 999999,   -- ALCANCE INFINITO
}

local OriginalSizes = {} 

-- // GUI SETUP (MANTENDO O VISUAL QUE VOCÊ GOSTA) //
if CoreGui:FindFirstChild("RPGMagnetInfinite") then CoreGui.RPGMagnetInfinite:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetInfinite"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50) -- Vermelho Sangue
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🧲 MAGNETO (INFINITO)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
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
Status.Position = UDim2.new(0, 0, 0.35, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function GetMobsFolder()
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "BadEntities" or v.Name == "Entities" then return v end
    end
    return nil
end

local function RestoreMob(mob)
    if not mob then return end
    -- Tenta achar a parte raiz (HumanoidRootPart ou RootPart)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
    
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

local function RestoreAll()
    for mob, _ in pairs(OriginalSizes) do RestoreMob(mob) end
    OriginalSizes = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "Status: ☢️ MODO INFINITO"
    else
        ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    -- Ponto de atração (na sua frente)
    local pullCFrame = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then return end
    
    local count = 0
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            
            -- LÓGICA DE VIDA (SEM HUMANOID)
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            -- LÓGICA DE PARTE RAIZ (ROBUSTA)
            -- Procura HumanoidRootPart OU RootPart (seu print mostrou RootPart também)
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                -- Checa distância (Agora é infinita, mas mantém check pra evitar erro)
                local dist = (root.Position - myRoot.Position).Magnitude
                
                if dist < SETTINGS.KillRange then
                    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                    
                    -- Prepara o corpo do bicho
                    root.CanCollide = false
                    root.Massless = true
                    root.Transparency = 0.5
                    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                    
                    -- TRAVA A POSIÇÃO NA SUA FRENTE
                    root.CFrame = pullCFrame
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                    
                    count = count + 1
                end
            else
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    Status.Text = "🧲 Puxando: " .. count
end)