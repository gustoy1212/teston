--[[
    🧙‍♂️ RPG MAGNET GOD v44 (BIG HITBOX EDITION)
    
    VOLTA ÀS ORIGENS (Base v40):
    - Usa o sistema de puxar que você confirmou que funciona.
    
    SOLUÇÃO DE DANO E ESQUIVA:
    - HITBOX EXPANDER: Transforma o inimigo num cubo de 50 studs.
    - Se ele esquivar, a hitbox ainda cobre a área. Você não erra nunca.
    
    DIAGNÓSTICO:
    - Mostra na tela exatamente qual pasta de inimigos ele achou.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetGodV44 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 6,       -- Distância para puxar
    HitboxSize = 40,      -- Tamanho do inimigo (Gigante para não errar)
    KillRange = 3000,     -- Alcance
}

-- Estados
local IsMagnetOn = false
local IsHitboxOn = false
local MassTargets = {}
local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("MagnetV44") then CoreGui.MagnetV44:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetV44"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧬 MAGNET GOD v44"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.15, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextWrapped = true
Status.TextSize = 12

-- Botão Magneto
local BtnMagnet = Instance.new("TextButton", MainFrame)
BtnMagnet.Size = UDim2.new(0.9, 0, 0.25, 0)
BtnMagnet.Position = UDim2.new(0.05, 0, 0.4, 0)
BtnMagnet.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
BtnMagnet.Text = "1. LIGAR MAGNETO (PUXAR)"
BtnMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnMagnet.Font = Enum.Font.GothamBold

-- Botão Hitbox
local BtnHitbox = Instance.new("TextButton", MainFrame)
BtnHitbox.Size = UDim2.new(0.9, 0, 0.25, 0)
BtnHitbox.Position = UDim2.new(0.05, 0, 0.7, 0)
BtnHitbox.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
BtnHitbox.Text = "2. HITBOX GIGANTE (DANO)"
BtnHitbox.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnHitbox.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

-- Tenta achar a pasta de inimigos automaticamente
local function FindEnemyFolder()
    -- Prioridade 1: A pasta que vimos na print
    if Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies") then
        return Workspace.Client.Enemies, "Client.Enemies"
    end
    -- Prioridade 2: Busca genérica
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("Enemies") or child.Name:match("Mobs") or child.Name:match("BadEntities") then
            return child, child.Name
        end
    end
    return nil, "NÃO ACHEI"
end

local function ExpandMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- Deixa Gigante
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.Transparency = 0.7 -- Meio transparente pra você ver
    root.CanCollide = false -- Fantasma
    root.Color = Color3.fromRGB(255, 0, 255) -- Roxo
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
    for mob, _ in pairs(MassTargets) do RestoreMob(mob) end
    MassTargets = {}
end

-- // BOTÕES //
BtnMagnet.MouseButton1Click:Connect(function()
    IsMagnetOn = not IsMagnetOn
    if IsMagnetOn then
        BtnMagnet.Text = "PARAR MAGNETO"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        BtnMagnet.Text = "1. LIGAR MAGNETO (PUXAR)"
        BtnMagnet.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
        RestoreAll() -- Solta se desligar
    end
end)

BtnHitbox.MouseButton1Click:Connect(function()
    IsHitboxOn = not IsHitboxOn
    if IsHitboxOn then
        BtnHitbox.Text = "PARAR HITBOX"
        BtnHitbox.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        BtnHitbox.Text = "2. HITBOX GIGANTE (DANO)"
        BtnHitbox.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetGodV44 = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOOP PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().MagnetGodV44 then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    -- Diagnóstico de Pasta
    local folder, folderName = FindEnemyFolder()
    if not folder then
        Status.Text = "ERRO: Pasta de inimigos sumiu!"
        return
    end
    
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    local count = 0
    
    -- Lógica Magneto + Hitbox
    if IsMagnetOn then
        for _, mob in ipairs(folder:GetChildren()) do
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                local dist = (root.Position - myRoot.Position).Magnitude
                
                if dist < SETTINGS.KillRange then
                    MassTargets[mob] = true
                    
                    -- 1. PUXA (Magneto)
                    root.CFrame = pullPos
                    root.Velocity = Vector3.new(0,0,0)
                    root.CanCollide = false
                    
                    -- 2. HITBOX (Se ativado)
                    if IsHitboxOn then
                        ExpandMob(mob)
                    end
                    
                    count = count + 1
                end
            else
                -- Limpa mortos
                if MassTargets[mob] then
                    RestoreMob(mob)
                    MassTargets[mob] = nil
                end
            end
        end
        Status.Text = "Pasta: " .. folderName .. "\nAlvos: " .. count
    else
        Status.Text = "Pasta encontrada: " .. folderName .. "\nPronto para iniciar."
    end
end)