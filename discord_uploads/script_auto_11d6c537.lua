--[[
    🧹 DUNGEON MAGNET v2 (GLOBAL VACUUM)
    
    SOLUÇÃO "PROCURANDO SALA":
    - Removeu a verificação de sala.
    - Agora varre TODA a pasta 'Workspace.dungeon' direto.
    
    ALVO: Qualquer coisa viva dentro de 'dungeon' num raio de 3000 studs.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().DungeonVacuum = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância na frente
    HitboxSize = 20,      -- Tamanho da Hitbox
    Range = 3000,         -- Pega monstros de salas vizinhas
}

-- Estados
local IsRunning = false
local MassTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("DungeonVacuumUI") then CoreGui.DungeonVacuumUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DungeonVacuumUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧹 DUNGEON VACUUM v2"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
ToggleBtn.Text = "LIGAR ASPIRADOR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

-- Varredura recursiva (procura em todas as subpastas de 'dungeon')
local function GetEnemiesInDungeon()
    local dungeon = Workspace:FindFirstChild("dungeon")
    if not dungeon then return {} end
    
    local enemies = {}
    -- Pega tudo que tem vida dentro da pasta dungeon
    for _, obj in ipairs(dungeon:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            -- Verifica se tem parte física (Root ou Torso)
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("UpperTorso") then
                if obj.Humanoid.Health > 0 then
                    table.insert(enemies, obj)
                end
            end
        end
    end
    return enemies
end

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.6
    root.Color = Color3.fromRGB(255, 100, 0)
    root.CanCollide = false
    root.Massless = true
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

local function RestoreAll()
    for mob, _ in pairs(MassTargets) do RestoreMob(mob) end
    MassTargets = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().DungeonVacuum = false
    RestoreAll()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR ASPIRADOR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
        RestoreAll()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().DungeonVacuum or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    -- Busca direta (Sem frescura de sala)
    local allEnemies = GetEnemiesInDungeon()
    local count = 0
    
    if #allEnemies == 0 then
        Status.Text = "⚠️ Pasta 'dungeon' vazia ou longe!"
    else
        for _, mob in ipairs(allEnemies) do
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
            local dist = (root.Position - myRoot.Position).Magnitude
            
            if dist < SETTINGS.Range then
                MassTargets[mob] = true
                PrepareMob(mob)
                
                -- Puxa
                root.CFrame = pullPos
                root.Velocity = Vector3.new(0,0,0)
                count = count + 1
            else
                if MassTargets[mob] then RestoreMob(mob) MassTargets[mob] = nil end
            end
        end
        Status.Text = "🧹 SUGANDO: " .. count .. " MOBS"
    end
end)