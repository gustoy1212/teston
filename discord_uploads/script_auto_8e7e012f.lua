--[[
    🔬 SAO DUNGEON SCANNER (DEEP SCAN)
    
    OBJETIVO: Mapear objetos interativos dentro da Dungeon.
    FILTROS: ClickDetector, ProximityPrompt, TouchTransmitter, Nomes de Loot.
    VISUAL: Cria um Highlight (ESP) em volta dos objetos encontrados.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("DungeonScanUI") then CoreGui.DungeonScanUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DungeonScanUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🔬 RADAR DE DUNGEON"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local ListFrame = Instance.new("ScrollingFrame", MainFrame)
ListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
ListFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
ListFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", ListFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.45, 0, 0.12, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ScanBtn.Text = "ESCANEAR AGORA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
ClearBtn.Position = UDim2.new(0.55, 0, 0.85, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ClearBtn.Text = "LIMPAR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÕES VISUAIS (ESP) //
local Highlights = {}

local function CreateHighlight(obj, color, labelText)
    if not obj or not obj.Parent then return end
    
    -- Se for um componente (ClickDetector), pega o Pai (Part/Model)
    local target = obj
    if not obj:IsA("BasePart") and not obj:IsA("Model") then
        target = obj.Parent
    end
    
    -- Cria Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ScannerHighlight"
    hl.Adornee = target
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Parent = CoreGui
    
    -- Cria Texto no mundo (BillboardGui)
    local bg = Instance.new("BillboardGui")
    bg.Name = "ScannerLabel"
    bg.Adornee = target
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.Parent = CoreGui
    
    local txt = Instance.new("TextLabel", bg)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = labelText
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    
    table.insert(Highlights, hl)
    table.insert(Highlights, bg)
end

local function ClearHighlights()
    for _, v in pairs(Highlights) do v:Destroy() end
    Highlights = {}
    for _, v in pairs(ListFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end

local function AddListEntry(text, color)
    local lbl = Instance.new("TextLabel", ListFrame)
    lbl.Size = UDim2.new(1, -10, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
end

-- // LÓGICA DE SCAN //
ScanBtn.MouseButton1Click:Connect(function()
    ClearHighlights()
    AddListEntry("🔍 Iniciando varredura...", Color3.white)
    
    local count = 0
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        local isInteresting = false
        local typeLabel = ""
        local color = Color3.white
        
        -- 1. Objetos de Interação
        if obj:IsA("ClickDetector") then
            isInteresting = true
            typeLabel = "🖱️ ClickDetector"
            color = Color3.fromRGB(0, 255, 0) -- Verde
        elseif obj:IsA("ProximityPrompt") then
            isInteresting = true
            typeLabel = "⌨️ ProximityPrompt (E)"
            color = Color3.fromRGB(255, 255, 0) -- Amarelo
        elseif obj:IsA("TouchTransmitter") then
            isInteresting = true
            typeLabel = "🦶 TouchInterest (Pisar)"
            color = Color3.fromRGB(0, 100, 255) -- Azul
        end
        
        -- 2. Nomes Suspeitos (Baús, Loot)
        if not isInteresting and (obj:IsA("Model") or obj:IsA("BasePart")) then
            if name:match("chest") or name:match("bau") or name:match("reward") or name:match("loot") or name:match("drop") then
                isInteresting = true
                typeLabel = "📦 Loot Model"
                color = Color3.fromRGB(255, 0, 255) -- Roxo
            end
        end
        
        -- 3. Exibe Resultados
        if isInteresting then
            count = count + 1
            local path = obj:GetFullName()
            AddListEntry("["..typeLabel.."] " .. obj.Name, color)
            CreateHighlight(obj, color, typeLabel .. "\n" .. obj.Name)
        end
    end
    
    if count == 0 then
        AddListEntry("⚠️ Nada encontrado.", Color3.red)
    else
        AddListEntry("✅ Encontrados: " .. count, Color3.green)
    end
end)

ClearBtn.MouseButton1Click:Connect(ClearHighlights)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)