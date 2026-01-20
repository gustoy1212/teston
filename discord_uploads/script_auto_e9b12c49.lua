--[[
    🧙‍♂️ RPG MAGNET GOD v42 (CUSTOM MOB FIX)
    
    CORREÇÃO CRÍTICA:
    - O jogo usa 'AnimationController' em vez de 'Humanoid'.
    - A vida (HP) está nos Atributos.
    - O script agora lê 'GetAttribute("HP")' para saber se o bicho tá vivo.
    
    ALVO: Workspace.Mobs
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância (Frente do player)
    HitboxSize = 5,       -- Tamanho da Hitbox
    KillRange = 2500,     -- Raio de busca
}

local OriginalSizes = {} -- Backup dos tamanhos

-- // GUI SETUP (IGUAL AO v39) //
if CoreGui:FindFirstChild("RPGMagnetV42") then CoreGui.RPGMagnetV42:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetV42"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Roxo para diferenciar
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🧲 MAGNET v42 (NO-HUMANOID)"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
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

local function GetMobsFolder()
    -- Busca direta na pasta Mobs que vimos no print
    if Workspace:FindFirstChild("Mobs") then
        return Workspace.Mobs
    end
    -- Fallback
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "BadEntities" or v.Name == "Entities" then return v end
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
        Status.Text = "Status: 🧲 ATIVO"
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
    local pullCFrame = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then return end
    
    local count = 0
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            -- AQUI ESTÁ A CORREÇÃO:
            -- Não buscamos mais Humanoid. Buscamos HumanoidRootPart e Atributo HP.
            local root = mob:FindFirstChild("HumanoidRootPart")
            local hp = mob:GetAttribute("HP")
            
            -- Se não tiver atributo HP, assume que está vivo (ou verifica se root existe)
            -- Se tiver HP, verifica se é maior que 0
            local isAlive = true
            if hp and hp <= 0 then isAlive = false end
            
            if root and isAlive then
                local dist = (root.Position - myRoot.Position).Magnitude
                
                if dist < SETTINGS.KillRange then
                    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                    
                    -- Configura Hitbox
                    root.CanCollide = false
                    root.Massless = true
                    root.Transparency = 0.5
                    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                    
                    -- Puxa
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
    
    Status.Text = "🧲 Puxando: " .. count .. " Mobs"
end)