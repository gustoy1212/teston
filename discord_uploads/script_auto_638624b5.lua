--[[
    🧙‍♂️ RPG MAGNET GOD v41 (DELTA FIX)
    
    ALVO CONFIRMADO: Workspace.Mobs (Baseado no seu print)
    MODO: Puxar TODOS (Mass Pull)
    VISUAL: Clássico v39 (Sem menu extra)
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
    HitboxSize = 4,       -- Tamanho da Hitbox (Não deixe gigante pra não bugar)
}

local OriginalSizes = {} -- Backup dos tamanhos

-- // GUI SETUP (VISUAL v39 CLÁSSICO) //
if CoreGui:FindFirstChild("RPGMagnetFixed") then CoreGui.RPGMagnetFixed:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetFixed"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Vermelho pra diferenciar
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🧲 MAGNETO (MOBS FIX)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
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
ToggleBtn.Text = "LIGAR (PUXAR TODOS)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

-- Procura a pasta EXATA do seu print
local function GetMobsFolder()
    if Workspace:FindFirstChild("Mobs") then
        return Workspace.Mobs
    elseif Workspace:FindFirstChild("BadEntities") then
        return Workspace.BadEntities
    else
        -- Último recurso: varre tudo
        for _, v in pairs(Workspace:GetChildren()) do
            if v.Name == "Mobs" or v.Name == "Entities" then return v end
        end
    end
    return nil
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
        Status.Text = "Status: 🧲 ATIVO (Mobs)"
    else
        ToggleBtn.Text = "LIGAR (PUXAR TODOS)"
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
    -- Ponto onde os mobs vão ficar (Na sua frente)
    local pullCFrame = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then 
        Status.Text = "ERRO: Pasta 'Mobs' não achada!"
        return 
    end
    
    -- Varre a pasta de mobs
    local count = 0
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
            
            -- Checa se tá vivo
            if hum and hum.Health > 0 and root then
                
                -- Salva tamanho original pra restaurar depois
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- Configura o mob pra ser puxado (Fantasma)
                root.CanCollide = false
                root.Massless = true
                root.Transparency = 0.5
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                
                -- APLICA O TELEPORTE (Ímã)
                root.CFrame = pullCFrame
                root.Velocity = Vector3.new(0,0,0) -- Tira a velocidade pra ele não sair voando
                root.RotVelocity = Vector3.new(0,0,0)
                
                count = count + 1
            else
                -- Se morreu, solta ele
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    Status.Text = "🧲 Puxando: " .. count .. " Mobs"
end)