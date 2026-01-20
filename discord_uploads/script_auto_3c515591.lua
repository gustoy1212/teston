--[[
    🧙‍♂️ RPG MAGNET GOD (DELTA MOBILE)
    
    VISUAL: IGUAL AO v39 (Simples, sem frescura).
    ALVO: Pasta "Workspace.Mobs".
    FUNÇÃO: Puxa TODOS os monstros vivos para sua frente (Mass Pull).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância na sua frente
    KillRange = 2500,     -- Alcance do ímã
    HitboxSize = 5,       -- Tamanho do monstro
}

local OriginalSizes = {} -- Para restaurar se desligar

-- // GUI SETUP (EXATAMENTE IGUAL O SEU) //
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
Title.Text = "🧲 MAGNET - PUXAR TODOS"
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

local TargetInfo = Instance.new("TextLabel", MainFrame)
TargetInfo.Size = UDim2.new(1, 0, 0, 20)
TargetInfo.Position = UDim2.new(0, 0, 0.5, 0)
TargetInfo.Text = "Alvos: 0"
TargetInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
TargetInfo.BackgroundTransparency = 1
TargetInfo.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR MAGNETO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

-- Procura a pasta MOBS (igual vimos no seu print)
local function GetMobsFolder()
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    -- Fallback se mudar de nome
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "BadEntities" or v.Name == "Entities" then return v end
    end
    return Workspace
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
    for mob, _ in pairs(OriginalSizes) do
        RestoreMob(mob)
    end
    OriginalSizes = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
        TargetInfo.Text = "Alvos: 0"
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local folder = GetMobsFolder()
    local count = 0
    
    -- PUXA TODOS (Lógica Massiva)
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and root then
                local dist = (root.Position - myRoot.Position).Magnitude
                
                if dist < SETTINGS.KillRange then
                    -- Salva tamanho original se não tiver salvo
                    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                    
                    -- Modifica o bicho pra virar "fantasma" e vir até você
                    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                    root.Transparency = 0.6
                    root.CanCollide = false
                    root.Massless = true
                    
                    -- A MÁGICA: Teleporta pra sua frente
                    root.CFrame = pullPos
                    root.Velocity = Vector3.new(0,0,0)
                    
                    count = count + 1
                end
            else
                -- Se morreu ou sumiu, restaura
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    Status.Text = "🧲 PUXANDO..."
    TargetInfo.Text = "Alvos: " .. count
end)