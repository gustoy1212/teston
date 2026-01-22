--[[
    📡 SAO WORLD MAPPER (PORTAL SCANNER)
    
    OBJETIVO: Mapear a localização e hierarquia de todos os portais do mapa.
    USO: Use isso para descobrir o nome da PASTA onde ficam os portais.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("PortalScannerUI") then CoreGui.PortalScannerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PortalScannerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 350)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Verde Hacker
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📡 RADAR DE PORTAIS"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local ListFrame = Instance.new("ScrollingFrame", MainFrame)
ListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
ListFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
ListFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", ListFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.12, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ScanBtn.Text = "ESCANEAR MUNDO"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
CloseBtn.TextColor3 = Color3.white

-- // VISUAIS //
local Visuals = {}

local function ClearVisuals()
    for _, v in pairs(Visuals) do v:Destroy() end
    Visuals = {}
    for _, v in pairs(ListFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end

local function AddLog(text, color)
    local lbl = Instance.new("TextLabel", ListFrame)
    lbl.Size = UDim2.new(1, -10, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.white
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextWrapped = true
end

local function CreateESP(model, name, level)
    local hl = Instance.new("Highlight")
    hl.Adornee = model
    hl.FillColor = Color3.fromRGB(0, 255, 255)
    hl.OutlineColor = Color3.white
    hl.FillTransparency = 0.7
    hl.Parent = CoreGui
    table.insert(Visuals, hl)

    local bg = Instance.new("BillboardGui")
    bg.Adornee = model
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 5, 0)
    bg.AlwaysOnTop = true
    bg.Parent = CoreGui
    table.insert(Visuals, bg)

    local txt = Instance.new("TextLabel", bg)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name .. "\n[" .. level .. "]"
    txt.TextColor3 = Color3.fromRGB(0, 255, 255)
    txt.TextStrokeTransparency = 0
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
end

-- // LÓGICA DE SCAN //
ScanBtn.MouseButton1Click:Connect(function()
    ClearVisuals()
    AddLog("🔍 Iniciando varredura global...", Color3.yellow)
    
    local count = 0
    local foundFolders = {}
    
    -- Varre o Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or (obj:IsA("Part") and obj.Name:match("Portal")) then
            local name = obj.Name:lower()
            
            -- Filtra nomes de Portais
            if name:match("portal") or name:match("gate") or name:match("dungeon") or name:match("rank") then
                
                -- Tenta achar o nível escrito em algum lugar
                local levelText = "Nível ?"
                for _, gui in ipairs(obj:GetDescendants()) do
                    if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text:match("%d") then
                        levelText = gui.Text
                        break
                    end
                end
                
                -- Cria visual
                CreateESP(obj, obj.Name, levelText)
                
                -- Registra o caminho (Path)
                local path = obj:GetFullName()
                AddLog("📍 " .. obj.Name .. " (" .. levelText .. ")", Color3.cyan)
                
                -- Tenta identificar a PASTA PAI (Isso é importante pro robô)
                if obj.Parent and obj.Parent ~= Workspace then
                    if not foundFolders[obj.Parent.Name] then
                        foundFolders[obj.Parent.Name] = true
                        AddLog("📂 PASTA DETECTADA: " .. obj.Parent:GetFullName(), Color3.fromRGB(255, 0, 255))
                    end
                end
                
                count = count + 1
            end
        end
    end
    
    if count == 0 then
        AddLog("⚠️ Nenhum portal encontrado.", Color3.red)
        AddLog("Tente ir para uma área diferente.", Color3.gray)
    else
        AddLog("✅ Total encontrado: " .. count, Color3.green)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ClearVisuals()
    ScreenGui:Destroy()
end)