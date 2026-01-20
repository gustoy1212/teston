--[[
    🧙‍♂️ RPG MAGNET GOD v44 (BRUTE FORCE)
    
    ESTRATÉGIA:
    - Identifica Mobs na pasta Workspace.Mobs
    - FORÇA: Usa PivotTo() para mover o modelo todo.
    - DESTRAVA: Tira o 'Anchored' de todas as partes do monstro.
    - FREQUÊNCIA: RenderStepped (Prioridade máxima).
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
    KillRange = 9e9,      -- Infinito
    HitboxSize = 5,
}

local OriginalSizes = {}

-- // GUI SETUP SIMPLES (IGUAL AO SEU) //
if CoreGui:FindFirstChild("MagnetBrute") then CoreGui.MagnetBrute:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetBrute"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja Força Bruta
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Text = "🧲 MAGNETO (FORÇA BRUTA)"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
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
ToggleBtn.Text = "LIGAR (BRUTE FORCE)"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function GetMobsFolder()
    -- Tenta achar a pasta Mobs
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "BadEntities" or v.Name == "Entities" then return v end
    end
    return nil
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        -- Restaura colisões básicas
        for _, part in pairs(mob:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
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
        Status.Text = "Status: 🔥 PUXANDO TUDO"
    else
        ToggleBtn.Text = "LIGAR (BRUTE FORCE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL (RENDERSTEPPED = + VELOCIDADE) //
RunService.RenderStepped:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    -- Posição Alvo: 5 studs na frente
    local targetCF = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then return end
    
    local count = 0
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            
            -- CHECK DE VIDA (ATRIBUTO HP)
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                -- Backup do tamanho
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- BRUTE FORCE: Destrava o monstro
                for _, part in pairs(mob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false -- Fantasma
                        part.Anchored = false   -- Solta do chão
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end
                end
                
                -- Aumenta Hitbox
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                root.Transparency = 0.5
                
                -- MOVIMENTO (PIVOT) - Mais forte que CFrame
                if mob.PrimaryPart then
                    mob:PivotTo(targetCF)
                else
                    root.CFrame = targetCF
                end
                
                count = count + 1
            else
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    Status.Text = "🧲 Puxando: " .. count
end)