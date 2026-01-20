--[[
    👑 ULTIMATE RPG PANEL v1
    
    FUNCIONALIDADES:
    1. TELEPORT QUEST: 
       - TP direto para o NPC pelo nome.
       - Lista (Scanner) de NPCs próximos para escolher.
       - APENAS TP (Você interage manualmente).
       
    2. MAGNET GOD (Farm):
       - Modo 1v1: Puxa um por um.
       - Modo Buraco Negro: Puxa o mapa todo.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().PanelRunning = true

-- // CONFIGURAÇÕES DO MAGNETO //
local MAG_SETTINGS = {
    Dist = 6,        -- Distância na sua frente
    KillRange = 3000, -- Alcance
}

local MagState = {
    Running = false,
    Mode = "SINGLE", -- "SINGLE" ou "MASS"
    Targets = {},    -- Lista de monstros
    SingleTarget = nil,
    OriginalSizes = {} -- Backup para restaurar depois
}

-- // UI SETUP //
if CoreGui:FindFirstChild("UltimatePanel") then CoreGui.UltimatePanel:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimatePanel"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 350)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "👑 PAINEL DE CONTROLE v1"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold

-- === SEÇÃO 1: TELEPORTE NPC === --
local SectionTP = Instance.new("Frame", MainFrame)
SectionTP.Size = UDim2.new(0.9, 0, 0.45, 0)
SectionTP.Position = UDim2.new(0.05, 0, 0.12, 0)
SectionTP.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
SectionTP.BorderSizePixel = 0

local LblTP = Instance.new("TextLabel", SectionTP)
LblTP.Size = UDim2.new(1, 0, 0, 20)
LblTP.Text = "📍 TELEPORTE DE MISSÃO"
LblTP.TextColor3 = Color3.fromRGB(255, 255, 0)
LblTP.BackgroundTransparency = 1
LblTP.Font = Enum.Font.GothamBold

local NpcBox = Instance.new("TextBox", SectionTP)
NpcBox.Size = UDim2.new(0.6, 0, 0, 25)
NpcBox.Position = UDim2.new(0.05, 0, 0.2, 0)
NpcBox.Text = "Johnny" -- Padrão
NpcBox.PlaceholderText = "Nome do NPC"
NpcBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NpcBox.TextColor3 = Color3.WHITE

local TpBtn = Instance.new("TextButton", SectionTP)
TpBtn.Size = UDim2.new(0.25, 0, 0, 25)
TpBtn.Position = UDim2.new(0.7, 0, 0.2, 0)
TpBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
TpBtn.Text = "IR AGORA"
TpBtn.TextColor3 = Color3.WHITE
TpBtn.Font = Enum.Font.GothamBold

-- Lista de NPCs (Scanner)
local ScanBtn = Instance.new("TextButton", SectionTP)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 20)
ScanBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
ScanBtn.Text = "🔍 ESCANEAR NPCS PRÓXIMOS"
ScanBtn.TextColor3 = Color3.BLACK
ScanBtn.Font = Enum.Font.GothamBold

local ScrollNPC = Instance.new("ScrollingFrame", SectionTP)
ScrollNPC.Size = UDim2.new(0.9, 0, 0.35, 0)
ScrollNPC.Position = UDim2.new(0.05, 0, 0.62, 0)
ScrollNPC.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ScrollNPC.CanvasSize = UDim2.new(0,0,0,0)
ScrollNPC.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListNPC = Instance.new("UIListLayout", ScrollNPC)
UIListNPC.SortOrder = Enum.SortOrder.LayoutOrder

-- === SEÇÃO 2: MAGNETO === --
local SectionMag = Instance.new("Frame", MainFrame)
SectionMag.Size = UDim2.new(0.9, 0, 0.35, 0)
SectionMag.Position = UDim2.new(0.05, 0, 0.6, 0)
SectionMag.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
SectionMag.BorderSizePixel = 0

local LblMag = Instance.new("TextLabel", SectionMag)
LblMag.Size = UDim2.new(1, 0, 0, 20)
LblMag.Text = "🧲 MAGNET GOD (FARM)"
LblMag.TextColor3 = Color3.fromRGB(150, 0, 255)
LblMag.BackgroundTransparency = 1
LblMag.Font = Enum.Font.GothamBold

local ModeBtn = Instance.new("TextButton", SectionMag)
ModeBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ModeBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ModeBtn.Text = "MODO: 1v1 (SINGLE)"
ModeBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
ModeBtn.Font = Enum.Font.GothamBold

local ToggleMagBtn = Instance.new("TextButton", SectionMag)
ToggleMagBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleMagBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleMagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleMagBtn.Text = "LIGAR MAGNETO"
ToggleMagBtn.TextColor3 = Color3.WHITE
ToggleMagBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES TELEPORTE // --

local function TeleportTo(targetPart)
    if not targetPart then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        -- TP 3 studs na frente do NPC
        char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
        -- Olha pro NPC
        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPart.Position)
    end
end

-- Botão TP direto (Nome da Caixa)
TpBtn.MouseButton1Click:Connect(function()
    local name = NpcBox.Text
    local found = false
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent and (v.Parent.Name:lower() == name:lower() or (v.Parent.Parent and v.Parent.Parent.Name:lower() == name:lower())) then
            local part = v.Parent:IsA("BasePart") and v.Parent or v.Parent.PrimaryPart
            if part then
                TeleportTo(part)
                found = true
                break
            end
        end
    end
    
    if not found then TpBtn.Text = "NÃO ACHOU!" wait(1) TpBtn.Text = "IR AGORA" end
end)

-- Botão SCANNER (Lista)
ScanBtn.MouseButton1Click:Connect(function()
    -- Limpa lista
    for _, v in pairs(ScrollNPC:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local npcName = "Desconhecido"
            local part = nil
            
            if v.Parent:IsA("Model") then
                npcName = v.Parent.Name
                part = v.Parent.PrimaryPart
            elseif v.Parent:IsA("BasePart") then
                npcName = v.Parent.Parent:IsA("Model") and v.Parent.Parent.Name or v.Parent.Name
                part = v.Parent
            end
            
            if part then
                local btn = Instance.new("TextButton", ScrollNPC)
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                btn.Text = "✈️ " .. npcName
                btn.TextColor3 = Color3.WHITE
                
                btn.MouseButton1Click:Connect(function()
                    TeleportTo(part)
                end)
            end
        end
    end
end)


-- // FUNÇÕES MAGNETO // --

local function PrepareMob(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not MagState.OriginalSizes[mob] then MagState.OriginalSizes[mob] = root.Size end
    
    root.Size = Vector3.new(5, 5, 5)
    root.Transparency = 0.6
    root.Color = (MagState.Mode == "MASS") and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    root.CanCollide = false
    root.Massless = true
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and MagState.OriginalSizes[mob] then
        root.Size = MagState.OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
        root.Color = Color3.new(1,1,1) -- Tenta restaurar cor (aprox)
    end
    MagState.OriginalSizes[mob] = nil
end

local function RestoreAll()
    if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) MagState.SingleTarget = nil end
    for mob, _ in pairs(MagState.Targets) do RestoreMob(mob) end
    MagState.Targets = {}
end

-- Botões Magneto
ModeBtn.MouseButton1Click:Connect(function()
    RestoreAll()
    if MagState.Mode == "SINGLE" then
        MagState.Mode = "MASS"
        ModeBtn.Text = "MODO: 🌌 BURACO NEGRO (MASS)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        MagState.Mode = "SINGLE"
        ModeBtn.Text = "MODO: ⚔️ 1v1 (SINGLE)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
    end
end)

ToggleMagBtn.MouseButton1Click:Connect(function()
    MagState.Running = not MagState.Running
    if MagState.Running then
        ToggleMagBtn.Text = "PARAR MAGNETO"
        ToggleMagBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleMagBtn.Text = "LIGAR MAGNETO"
        ToggleMagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().PanelRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

-- LOOP PRINCIPAL (FARM)
RunService.Heartbeat:Connect(function()
    if not getgenv().PanelRunning then return end
    if not MagState.Running then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -MAG_SETTINGS.Dist)
    
    -- Busca Pasta de Inimigos
    local folder = Workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") then
            folder = child break
        end
    end
    
    if MagState.Mode == "SINGLE" then
        -- MODO 1v1
        if MagState.SingleTarget and MagState.SingleTarget.Parent and MagState.SingleTarget:FindFirstChild("Humanoid") and MagState.SingleTarget.Humanoid.Health > 0 then
            -- Puxa o atual
            PrepareMob(MagState.SingleTarget)
            local r = MagState.SingleTarget.HumanoidRootPart
            if r then
                r.CFrame = pullPos
                r.Velocity = Vector3.new(0,0,0)
            end
        else
            -- Procura novo
            RestoreMob(MagState.SingleTarget)
            MagState.SingleTarget = nil
            local closest, minDist = nil, 9999
            for _, mob in ipairs(folder:GetChildren()) do
                if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                    if dist < minDist and dist < MAG_SETTINGS.KillRange then
                        minDist = dist
                        closest = mob
                    end
                end
            end
            MagState.SingleTarget = closest
        end
        
    elseif MagState.Mode == "MASS" then
        -- MODO BURACO NEGRO
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist < MAG_SETTINGS.KillRange then
                    MagState.Targets[mob] = true
                    PrepareMob(mob)
                    local r = mob:FindFirstChild("HumanoidRootPart")
                    if r then
                        r.CFrame = pullPos
                        r.Velocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    end
end)