--[[
    📱 PAINEL SIMPLES (MOBILE FIX)
    - Botões grandes.
    - Evento 'Activated' (Melhor pra celular).
    - Já começa ABERTO.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Garante que o script antigo pare
getgenv().PanelRunning = true

-- // CONFIGURAÇÕES DO MAGNETO //
local MAG_SETTINGS = {
    Dist = 6,
    KillRange = 3000,
}

local MagState = {
    Running = false,
    Mode = "SINGLE", -- SINGLE ou MASS
    Targets = {},
    SingleTarget = nil,
    OriginalSizes = {} 
}

-- // GUI SETUP //
if CoreGui:FindFirstChild("SimplePanel") then CoreGui.SimplePanel:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimplePanel"
-- Tenta colocar no CoreGui (melhor), se falhar vai pro PlayerGui
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 1. BOTÃO MENU (TOGGLE)
local MenuBtn = Instance.new("TextButton", ScreenGui)
MenuBtn.Size = UDim2.new(0, 60, 0, 60)
MenuBtn.Position = UDim2.new(0.8, 0, 0.1, 0) -- Canto superior direito
MenuBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
MenuBtn.Text = "MENU"
MenuBtn.TextColor3 = Color3.WHITE
MenuBtn.Font = Enum.Font.GothamBlack
MenuBtn.TextSize = 14
MenuBtn.BorderSizePixel = 0
-- Deixa redondo
local Corner = Instance.new("UICorner", MenuBtn)
Corner.CornerRadius = UDim.new(1, 0)

-- 2. PAINEL PRINCIPAL (SCROLL)
local MainFrame = Instance.new("ScrollingFrame", ScreenGui)
MainFrame.Size = UDim2.new(0.5, 0, 0.5, 0) -- Metade da tela
MainFrame.Position = UDim2.new(0.25, 0, 0.25, 0) -- Meio
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Visible = true -- Começa ABERTO pra você ver
MainFrame.Active = true
MainFrame.Draggable = true -- Pode arrastar
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainFrame.ScrollBarThickness = 6

-- LAYOUT AUTOMÁTICO
local UIList = Instance.new("UIListLayout", MainFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 10)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local UIPadding = Instance.new("UIPadding", MainFrame)
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.PaddingBottom = UDim.new(0, 10)

-- // ELEMENTOS DO PAINEL //

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0.9, 0, 0, 30)
Title.Text = "RPG CONTROL"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1
Title.LayoutOrder = 1

-- INPUT NOME NPC
local NpcInput = Instance.new("TextBox", MainFrame)
NpcInput.Size = UDim2.new(0.9, 0, 0, 40)
NpcInput.Text = "Johnny"
NpcInput.PlaceholderText = "Nome do NPC"
NpcInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NpcInput.TextColor3 = Color3.WHITE
NpcInput.Font = Enum.Font.Gotham
NpcInput.LayoutOrder = 2

-- BOTÃO IR NPC
local BtnTeleport = Instance.new("TextButton", MainFrame)
BtnTeleport.Size = UDim2.new(0.9, 0, 0, 40)
BtnTeleport.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
BtnTeleport.Text = "IR PARA NPC (Digitado)"
BtnTeleport.TextColor3 = Color3.WHITE
BtnTeleport.Font = Enum.Font.GothamBold
BtnTeleport.LayoutOrder = 3

-- BOTÃO ESCANEAR
local BtnScan = Instance.new("TextButton", MainFrame)
BtnScan.Size = UDim2.new(0.9, 0, 0, 40)
BtnScan.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
BtnScan.Text = "LISTAR TODOS NPCS"
BtnScan.TextColor3 = Color3.WHITE
BtnScan.Font = Enum.Font.GothamBold
BtnScan.LayoutOrder = 4

-- SEPARADOR
local Sep = Instance.new("Frame", MainFrame)
Sep.Size = UDim2.new(0.9, 0, 0, 2)
Sep.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
Sep.BorderSizePixel = 0
Sep.LayoutOrder = 5

-- BOTÃO MODO FARM
local BtnMode = Instance.new("TextButton", MainFrame)
BtnMode.Size = UDim2.new(0.9, 0, 0, 40)
BtnMode.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
BtnMode.Text = "MODO: 1v1 (Single)"
BtnMode.TextColor3 = Color3.WHITE
BtnMode.Font = Enum.Font.GothamBold
BtnMode.LayoutOrder = 6

-- BOTÃO LIGAR FARM
local BtnToggle = Instance.new("TextButton", MainFrame)
BtnToggle.Size = UDim2.new(0.9, 0, 0, 40)
BtnToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
BtnToggle.Text = "LIGAR FARM"
BtnToggle.TextColor3 = Color3.WHITE
BtnToggle.Font = Enum.Font.GothamBold
BtnToggle.LayoutOrder = 7

-- ÁREA DA LISTA DE NPCS
local ListFrame = Instance.new("Frame", MainFrame)
ListFrame.Size = UDim2.new(0.9, 0, 0, 0)
ListFrame.BackgroundTransparency = 1
ListFrame.AutomaticSize = Enum.AutomaticSize.Y
ListFrame.LayoutOrder = 8
local ListLayout = Instance.new("UIListLayout", ListFrame)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 5)

-- // LÓGICA (COM "ACTIVATED" PARA CELULAR) //

-- 1. Abrir/Fechar Menu
MenuBtn.Activated:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Função de TP Simples
local function TP(part)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0,0,3)
    end
end

-- 2. Teleportar no nome digitado
BtnTeleport.Activated:Connect(function()
    local name = NpcInput.Text
    local found = false
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent then
            if v.Parent.Name:lower():find(name:lower()) or (v.Parent.Parent and v.Parent.Parent.Name:lower():find(name:lower())) then
                local target = v.Parent:IsA("BasePart") and v.Parent or (v.Parent:IsA("Model") and v.Parent.PrimaryPart)
                if target then
                    TP(target)
                    found = true
                    break
                end
            end
        end
    end
    if not found then 
        BtnTeleport.Text = "NPC NÃO ACHADO!"
        task.wait(1)
        BtnTeleport.Text = "IR PARA NPC (Digitado)"
    end
end)

-- 3. Escanear e Criar Botões
BtnScan.Activated:Connect(function()
    -- Limpa botões antigos
    for _, v in pairs(ListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local npcName = "Desconhecido"
            local target = nil
            
            if v.Parent:IsA("Model") then
                npcName = v.Parent.Name
                target = v.Parent.PrimaryPart
            elseif v.Parent:IsA("BasePart") then
                npcName = v.Parent.Parent:IsA("Model") and v.Parent.Parent.Name or v.Parent.Name
                target = v.Parent
            end
            
            if target then
                count = count + 1
                local b = Instance.new("TextButton", ListFrame)
                b.Size = UDim2.new(1, 0, 0, 30)
                b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                b.Text = "✈️ " .. npcName
                b.TextColor3 = Color3.fromRGB(0, 255, 255)
                
                b.Activated:Connect(function()
                    TP(target)
                end)
            end
        end
    end
    BtnScan.Text = "LISTAR ("..count.." ENCONTRADOS)"
end)

-- 4. Magneto Lógica
BtnMode.Activated:Connect(function()
    -- Reseta os bichos
    if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) end
    for mob, _ in pairs(MagState.Targets) do RestoreMob(mob) end
    MagState.Targets = {}
    MagState.SingleTarget = nil
    
    if MagState.Mode == "SINGLE" then
        MagState.Mode = "MASS"
        BtnMode.Text = "MODO: 🌌 MASS (Buraco Negro)"
        BtnMode.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        MagState.Mode = "SINGLE"
        BtnMode.Text = "MODO: ⚔️ SINGLE (1v1)"
        BtnMode.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    end
end)

BtnToggle.Activated:Connect(function()
    MagState.Running = not MagState.Running
    if MagState.Running then
        BtnToggle.Text = "PARAR FARM"
        BtnToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    else
        BtnToggle.Text = "LIGAR FARM"
        BtnToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
        -- Restaura tudo ao parar
        if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) end
        for mob, _ in pairs(MagState.Targets) do RestoreMob(mob) end
        MagState.Targets = {}
        MagState.SingleTarget = nil
    end
end)

-- FUNÇÕES AUXILIARES DO FARM (Otimizadas)
function PrepareMob(mob)
    local r = mob:FindFirstChild("HumanoidRootPart")
    if not r then return end
    if not MagState.OriginalSizes[mob] then MagState.OriginalSizes[mob] = r.Size end
    r.Size = Vector3.new(5,5,5)
    r.Transparency = 0.5
    r.CanCollide = false
    r.Massless = true
end

function RestoreMob(mob)
    if not mob then return end
    local r = mob:FindFirstChild("HumanoidRootPart")
    if r and MagState.OriginalSizes[mob] then
        r.Size = MagState.OriginalSizes[mob]
        r.Transparency = 1
        r.CanCollide = true
    end
    MagState.OriginalSizes[mob] = nil
end

RunService.Heartbeat:Connect(function()
    if not getgenv().PanelRunning then return end
    if not MagState.Running then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -MAG_SETTINGS.Dist)
    
    -- Acha a pasta de mobs
    local folder = Workspace
    for _, c in pairs(Workspace:GetChildren()) do
        if c.Name:match("BadEntities") or c.Name:match("Entities") then folder = c break end
    end
    
    if MagState.Mode == "SINGLE" then
        -- Lógica 1v1
        if MagState.SingleTarget and MagState.SingleTarget.Parent and MagState.SingleTarget:FindFirstChild("Humanoid") and MagState.SingleTarget.Humanoid.Health > 0 then
            PrepareMob(MagState.SingleTarget)
            MagState.SingleTarget.HumanoidRootPart.CFrame = myPos
            MagState.SingleTarget.HumanoidRootPart.Velocity = Vector3.zero
        else
            MagState.SingleTarget = nil
            local closest, dist = nil, 9999
            for _, m in pairs(folder:GetChildren()) do
                if m:IsA("Model") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                    local d = (m.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                    if d < dist and d < MAG_SETTINGS.KillRange then dist = d closest = m end
                end
            end
            MagState.SingleTarget = closest
        end
    else
        -- Lógica Mass
        for _, m in pairs(folder:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                local d = (m.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                if d < MAG_SETTINGS.KillRange then
                    MagState.Targets[m] = true
                    PrepareMob(m)
                    m.HumanoidRootPart.CFrame = myPos
                    m.HumanoidRootPart.Velocity = Vector3.zero
                end
            end
        end
    end
end)