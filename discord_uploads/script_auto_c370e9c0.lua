--[[
    🗝️ DUNGEON MAGNET v1 (ROOM CLEAR)
    
    ESTRATÉGIA:
    - Foca na pasta: Workspace.dungeon
    - Identifica a sala atual (room1, room2...)
    - Puxa todos os inimigos da pasta 'enemyFolder' dessa sala.
    
    CORREÇÃO DE "BRAÇO SOLTO":
    - Se encontrar uma parte (RightLowerArm), sobe a hierarquia até achar o Modelo pai.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().DungeonMagnet = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância na frente
    HitboxSize = 25,      -- Tamanho confortável
    KillRange = 2000,     -- Alcance dentro da sala
}

-- Estados
local IsRunning = false
local MassTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("DungeonMagnetUI") then CoreGui.DungeonMagnetUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DungeonMagnetUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 10) -- Cor Dungeon
MainFrame.BorderColor3 = Color3.fromRGB(255, 150, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🗝️ DUNGEON CLEANER"
Title.TextColor3 = Color3.fromRGB(255, 150, 0)
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
ToggleBtn.Text = "LIGAR MAGNETO (SALA)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

-- Encontra a sala mais próxima ou ativa
local function GetCurrentRoom()
    local dungeon = Workspace:FindFirstChild("dungeon")
    if not dungeon then return nil end
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local myPos = char.PrimaryPart.Position
    
    local closestRoom = nil
    local minDist = 9999
    
    for _, room in ipairs(dungeon:GetChildren()) do
        -- Verifica se é uma sala e tem inimigos
        if room.Name:match("room") and room:FindFirstChild("enemyFolder") then
            -- Tenta achar o centro da sala (média dos inimigos ou um part)
            local enemies = room.enemyFolder:GetChildren()
            if #enemies > 0 then
                local firstEnemy = enemies[1]
                local root = firstEnemy:FindFirstChild("HumanoidRootPart") or firstEnemy:FindFirstChild("UpperTorso")
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestRoom = room
                    end
                end
            end
        end
    end
    return closestRoom
end

local function PrepareMob(mob)
    -- Procura a parte principal (R15 usa UpperTorso ou HumanoidRootPart)
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- Hitbox
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
    getgenv().DungeonMagnet = false
    RestoreAll()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR MAGNETO (SALA)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
        RestoreAll()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().DungeonMagnet or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local room = GetCurrentRoom()
    if not room then
        Status.Text = "Procurando Sala..."
        return
    end
    
    local enemyFolder = room:FindFirstChild("enemyFolder")
    if not enemyFolder then return end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local count = 0
    
    for _, mob in ipairs(enemyFolder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        -- Suporte R15 (UpperTorso)
        local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
        
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - myRoot.Position).Magnitude
            
            if dist < SETTINGS.KillRange then
                MassTargets[mob] = true
                PrepareMob(mob)
                
                -- PUXA (Corrigido para R15)
                root.CFrame = pullPos
                root.Velocity = Vector3.new(0,0,0)
                
                count = count + 1
            end
        else
            if MassTargets[mob] then RestoreMob(mob) MassTargets[mob] = nil end
        end
    end
    
    Status.Text = "Sala: " .. room.Name .. " | Alvos: " .. count
end)