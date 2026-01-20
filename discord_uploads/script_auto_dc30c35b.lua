--[[
    📱 RPG CONTROL PANEL (DELTA MOBILE EDITION)
    
    CORREÇÕES:
    - Interface ajustada para Celular (Não fica tela preta).
    - Botão "Minimizar" (Bolinha Azul no canto) para não atrapalhar a visão.
    - Scanner de NPC com lista de rolagem.
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
    OriginalSizes = {} 
}

-- // UI SETUP (CELULAR) //
if CoreGui:FindFirstChild("DeltaPanel") then CoreGui.DeltaPanel:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaPanel"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 1. BOTÃO DE ABRIR/FECHAR (MINIMIZADO)
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.85, 0, 0.15, 0) -- Canto superior direito
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
OpenBtn.Text = "MENU"
OpenBtn.TextColor3 = Color3.WHITE
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.BorderSizePixel = 0
OpenBtn.UICorner = Instance.new("UICorner", OpenBtn)
OpenBtn.UICorner.CornerRadius = UDim.new(1, 0) -- Redondo

-- 2. PAINEL PRINCIPAL
local MainFrame = Instance.new("ScrollingFrame", ScreenGui)
MainFrame.Size = UDim2.new(0.6, 0, 0.5, 0) -- Tamanho bom pra celular
MainFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Visible = false -- Começa fechado
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto ajuste
MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainFrame.ScrollBarThickness = 5

-- LISTA DE ORGANIZAÇÃO (CRUCIAL PRA NÃO FICAR PRETO)
local UIList = Instance.new("UIListLayout", MainFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local UIPadding = Instance.new("UIPadding", MainFrame)
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.PaddingBottom = UDim.new(0, 10)

-- // COMPONENTES DA UI //

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(0.9, 0, 0, 30)
Title.Text = "👑 PAINEL DELTA v2"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1
Title.LayoutOrder = 1

-- === SEÇÃO TELEPORTE ===
local LabelTP = Instance.new("TextLabel", MainFrame)
LabelTP.Size = UDim2.new(0.9, 0, 0, 20)
LabelTP.Text = "📍 TELEPORTE NPC"
LabelTP.TextColor3 = Color3.fromRGB(255, 255, 0)
LabelTP.BackgroundTransparency = 1
LabelTP.Font = Enum.Font.GothamBold
LabelTP.LayoutOrder = 2

local NpcBox = Instance.new("TextBox", MainFrame)
NpcBox.Size = UDim2.new(0.9, 0, 0, 35)
NpcBox.Text = "Johnny"
NpcBox.PlaceholderText = "Nome do NPC"
NpcBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
NpcBox.TextColor3 = Color3.WHITE
NpcBox.LayoutOrder = 3

local TpBtn = Instance.new("TextButton", MainFrame)
TpBtn.Size = UDim2.new(0.9, 0, 0, 35)
TpBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
TpBtn.Text = "IR PARA O NPC (Digitado)"
TpBtn.TextColor3 = Color3.WHITE
TpBtn.Font = Enum.Font.GothamBold
TpBtn.LayoutOrder = 4

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 35)
ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
ScanBtn.Text = "🔍 LISTAR NPCS PRÓXIMOS"
ScanBtn.TextColor3 = Color3.BLACK
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.LayoutOrder = 5

-- LISTA DE NPCS (Container)
local NpcListFrame = Instance.new("Frame", MainFrame)
NpcListFrame.Size = UDim2.new(0.9, 0, 0, 0) -- Altura auto
NpcListFrame.BackgroundTransparency = 1
NpcListFrame.AutomaticSize = Enum.AutomaticSize.Y
NpcListFrame.LayoutOrder = 6

local NpcListLayout = Instance.new("UIListLayout", NpcListFrame)
NpcListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NpcListLayout.Padding = UDim.new(0, 2)

-- === SEÇÃO MAGNETO ===
local Separator = Instance.new("Frame", MainFrame)
Separator.Size = UDim2.new(0.9, 0, 0, 2)
Separator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
Separator.BorderSizePixel = 0
Separator.LayoutOrder = 7

local LabelMag = Instance.new("TextLabel", MainFrame)
LabelMag.Size = UDim2.new(0.9, 0, 0, 20)
LabelMag.Text = "🧲 FARM MAGNETO"
LabelMag.TextColor3 = Color3.fromRGB(150, 0, 255)
LabelMag.BackgroundTransparency = 1
LabelMag.Font = Enum.Font.GothamBold
LabelMag.LayoutOrder = 8

local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.9, 0, 0, 35)
ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
ModeBtn.Text = "MODO: 1v1 (Single)"
ModeBtn.TextColor3 = Color3.fromRGB(100, 255, 255)
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.LayoutOrder = 9

local ToggleMagBtn = Instance.new("TextButton", MainFrame)
ToggleMagBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleMagBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleMagBtn.Text = "LIGAR MAGNETO"
ToggleMagBtn.TextColor3 = Color3.WHITE
ToggleMagBtn.Font = Enum.Font.GothamBold
ToggleMagBtn.LayoutOrder = 10

-- // LÓGICA DA UI //
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- // LÓGICA DE TELEPORTE //
local function TeleportTo(targetPart)
    if not targetPart then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPart.Position)
    end
end

TpBtn.MouseButton1Click:Connect(function()
    local name = NpcBox.Text
    local found = false
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Parent and (v.Parent.Name:lower():find(name:lower())) then
            local part = v.Parent:IsA("BasePart") and v.Parent or (v.Parent:IsA("Model") and v.Parent.PrimaryPart)
            if part then
                TeleportTo(part)
                found = true
                break
            end
        end
    end
    if not found then TpBtn.Text = "NÃO ACHOU!" task.wait(1) TpBtn.Text = "IR PARA O NPC (Digitado)" end
end)

ScanBtn.MouseButton1Click:Connect(function()
    -- Limpa lista antiga
    for _, v in pairs(NpcListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local npcName = "NPC"
            local part = nil
            
            if v.Parent:IsA("Model") then
                npcName = v.Parent.Name
                part = v.Parent.PrimaryPart
            elseif v.Parent:IsA("BasePart") then
                npcName = v.Parent.Parent:IsA("Model") and v.Parent.Parent.Name or v.Parent.Name
                part = v.Parent
            end
            
            if part then
                count = count + 1
                local btn = Instance.new("TextButton", NpcListFrame)
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                btn.Text = "✈️ " .. npcName
                btn.TextColor3 = Color3.fromRGB(0, 255, 255)
                btn.Font = Enum.Font.Code
                
                btn.MouseButton1Click:Connect(function()
                    TeleportTo(part)
                end)
            end
        end
    end
    ScanBtn.Text = "🔍 LISTAR ("..count.." encontrados)"
end)

-- // LÓGICA DO MAGNETO //
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
        root.Color = Color3.new(1,1,1)
    end
    MagState.OriginalSizes[mob] = nil
end

local function RestoreAll()
    if MagState.SingleTarget then RestoreMob(MagState.SingleTarget) MagState.SingleTarget = nil end
    for mob, _ in pairs(MagState.Targets) do RestoreMob(mob) end
    MagState.Targets = {}
end

ModeBtn.MouseButton1Click:Connect(function()
    RestoreAll()
    if MagState.Mode == "SINGLE" then
        MagState.Mode = "MASS"
        ModeBtn.Text = "MODO: 🌌 BURACO NEGRO (Mass)"
        ModeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        MagState.Mode = "SINGLE"
        ModeBtn.Text = "MODO: ⚔️ 1v1 (Single)"
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

RunService.Heartbeat:Connect(function()
    if not getgenv().PanelRunning then return end
    if not MagState.Running then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    local pullPos = myRoot.CFrame * CFrame.new(0, 0, -MAG_SETTINGS.Dist)
    
    local folder = Workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") then
            folder = child break
        end
    end
    
    if MagState.Mode == "SINGLE" then
        if MagState.SingleTarget and MagState.SingleTarget.Parent and MagState.SingleTarget:FindFirstChild("Humanoid") and MagState.SingleTarget.Humanoid.Health > 0 then
            PrepareMob(MagState.SingleTarget)
            local r = MagState.SingleTarget.HumanoidRootPart
            if r then
                r.CFrame = pullPos
                r.Velocity = Vector3.new(0,0,0)
            end
        else
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
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                local dist = (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist < MAG_SETTINGS.KillRange then
                    MagState.Targets[mob] = true
                    PrepareMob(mob)
                    local r = mob:FindFirstChild("HumanoidRootPart")
                    if r then r.CFrame = pullPos r.Velocity = Vector3.new(0,0,0) end
                end
            end
        end
    end
end)