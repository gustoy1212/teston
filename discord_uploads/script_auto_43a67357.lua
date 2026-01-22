-- [[ OMNI-SCANNER V2 ULTRA - FIXED COPY ]] --

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- 1. UI MELHORADA
local ScreenName = "OmniScannerV2_Fixed"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 650, 0, 450)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 255, 150)
Stroke.Thickness = 2

-- Barra de Busca
local SearchBox = Instance.new("TextBox", MainFrame)
SearchBox.Size = UDim2.new(1, -120, 0, 30)
SearchBox.Position = UDim2.new(0, 10, 0.1, 0)
SearchBox.PlaceholderText = "🔍 Filtrar resultados..."
SearchBox.Text = ""
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SearchBox.TextColor3 = Color3.new(1,1,1)
SearchBox.Font = Enum.Font.Code
SearchBox.TextSize = 14
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

-- Área de Log
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 0.6, 0)
Scroll.Position = UDim2.new(0, 10, 0.18, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 2)

-- LOGS E MEMÓRIA
local LogHistory = {}

local function AddLog(tipo, objeto, path, extra)
    local timestamp = os.date("%H:%M:%S")
    local infoExtra = extra or ""
    local fullText = string.format("[%s] %s: %s %s", timestamp, tipo, objeto.Name, infoExtra)
    
    table.insert(LogHistory, {Path = path, Text = fullText, ObjName = objeto.Name:lower(), Type = tipo})
    
    local label = Instance.new("TextButton", Scroll)
    label.Size = UDim2.new(1, -10, 0, 25)
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    label.Text = "  " .. fullText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.Name = objeto.Name -- Para o filtro
    
    if tipo == "REMOTE" then label.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif tipo == "PROMPT" then label.TextColor3 = Color3.fromRGB(255, 255, 100)
    elseif tipo == "SCRIPT" then label.TextColor3 = Color3.fromRGB(180, 100, 255)
    elseif tipo == "ATTR" then label.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif tipo == "NEW" then label.TextColor3 = Color3.fromRGB(0, 200, 255) end

    label.MouseButton1Click:Connect(function()
        setclipboard(path)
        label.Text = "  [!] COPIADO!"
        task.wait(1)
        label.Text = "  " .. fullText
    end)
end

-- 2. NOVOS MÓDULOS DE SCAN
local function DeepScan()
    for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    LogHistory = {}

    for _, v in pairs(Workspace:GetDescendants()) do
        local attrs = v:GetAttributes()
        if next(attrs) then
            local attrList = ""
            for name, val in pairs(attrs) do attrList = attrList .. name .. "=" .. tostring(val) .. " | " end
            AddLog("ATTR", v, v:GetFullName(), " -> {"..attrList.."}")
        end

        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            AddLog("SCRIPT", v, v:GetFullName())
        end

        if v:IsA("ProximityPrompt") then
            AddLog("PROMPT", v.Parent, v:GetFullName())
        end
        
        -- Adicionado filtro extra pra pegar portais mesmo sem prompt
        local n = v.Name:lower()
        if (v:IsA("Model") or v:IsA("BasePart")) and (n:match("portal") or n:match("gate") or n:match("dungeon")) then
             AddLog("POSSIBLE", v, v:GetFullName())
        end
    end
    
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            AddLog("REMOTE", r, r:GetFullName())
        end
    end
end

-- Filtro
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = SearchBox.Text:lower()
    for _, label in pairs(Scroll:GetChildren()) do
        if label:IsA("TextButton") then
            if query == "" or label.Text:lower():find(query) then
                label.Visible = true
            else
                label.Visible = false
            end
        end
    end
end)

-- >>> FUNÇÃO DE EXIBIÇÃO MANUAL (A CORREÇÃO) <<<
local function ShowManualCopyBox(text)
    local CopyFrame = Instance.new("Frame", ScreenGui)
    CopyFrame.Size = UDim2.new(0, 600, 0, 400)
    CopyFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    CopyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    CopyFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    CopyFrame.BorderSizePixel = 2
    CopyFrame.Active = true
    CopyFrame.Draggable = true
    
    local Tip = Instance.new("TextLabel", CopyFrame)
    Tip.Size = UDim2.new(1, 0, 0, 30)
    Tip.Text = "CLIQUE ABAIXO -> CTRL+A -> CTRL+C"
    Tip.TextColor3 = Color3.fromRGB(0, 255, 0)
    Tip.BackgroundTransparency = 1
    
    local TextBox = Instance.new("TextBox", CopyFrame)
    TextBox.Size = UDim2.new(0.95, 0, 0.8, 0)
    TextBox.Position = UDim2.new(0.025, 0, 0.1, 0)
    TextBox.Text = text
    TextBox.TextColor3 = Color3.white
    TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TextBox.ClearTextOnFocus = false
    TextBox.MultiLine = true
    TextBox.TextWrapped = false -- Deixa rolar pro lado se precisar
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.TextYAlignment = Enum.TextYAlignment.Top
    TextBox.Font = Enum.Font.Code
    TextBox.TextSize = 12
    
    local CloseCopy = Instance.new("TextButton", CopyFrame)
    CloseCopy.Size = UDim2.new(1, 0, 0.1, 0)
    CloseCopy.Position = UDim2.new(0, 0, 0.9, 0)
    CloseCopy.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    CloseCopy.Text = "FECHAR"
    CloseCopy.TextColor3 = Color3.white
    CloseCopy.MouseButton1Click:Connect(function() CopyFrame:Destroy() end)
end

-- 3. INTERFACE DE BOTÕES
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.2, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.8, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, posScale, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.22, 0, 0.4, 0)
    btn.Position = UDim2.new(posScale.X, 0, posScale.Y, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
end

CreateBtn("DEEP SCAN 🧠", Vector2.new(0.02, 0.1), Color3.fromRGB(100, 50, 150), DeepScan)

-- BOTÃO COPIAR ARRUMADO
CreateBtn("COPIAR TUDO 📋", Vector2.new(0.26, 0.1), Color3.fromRGB(50, 150, 50), function()
    -- Junta o texto de forma otimizada
    local buffer = {}
    for _, l in ipairs(LogHistory) do
        table.insert(buffer, l.Text .. " || PATH: " .. l.Path)
    end
    local finalString = table.concat(buffer, "\n")
    
    -- Abre a janela manual
    ShowManualCopyBox(finalString)
    
    -- Tenta copiar auto tbm, vai que cola
    pcall(function() setclipboard(finalString) end)
end)

CreateBtn("LIMPAR 🧹", Vector2.new(0.50, 0.1), Color3.fromRGB(150, 50, 50), function()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    LogHistory = {}
end)

CreateBtn("REAL-TIME 👁️", Vector2.new(0.74, 0.1), Color3.fromRGB(0, 150, 200), function()
    AddLog("INFO", {Name="Monitor Ativo"}, "N/A")
    Workspace.DescendantAdded:Connect(function(d)
        AddLog("NEW", d, "game."..d:GetFullName())
    end)
end)