-- [[ OMNI-SCANNER V2 ULTRA - MODO DESENVOLVEDOR AVANÇADO ]] --

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- 1. UI MELHORADA
local ScreenName = "OmniScannerV2"
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

-- Barra de Busca (Nova!)
local SearchBox = Instance.new("TextBox", MainFrame)
SearchBox.Size = UDim2.new(1, -120, 0, 30)
SearchBox.Position = UDim2.new(0, 10, 0.1, 0)
SearchBox.PlaceholderText = "🔍 Filtrar resultados (ex: Crystal, Event, Jade)..."
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
    
    -- Cores por tipo
    if tipo == "REMOTE" then label.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif tipo == "PROMPT" then label.TextColor3 = Color3.fromRGB(255, 255, 100)
    elseif tipo == "SCRIPT" then label.TextColor3 = Color3.fromRGB(180, 100, 255)
    elseif tipo == "ATTR" then label.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif tipo == "NEW" then label.TextColor3 = Color3.fromRGB(0, 200, 255) end

    label.MouseButton1Click:Connect(function()
        setclipboard(path)
        label.Text = "  [!] CAMINHO COPIADO!"
        task.wait(1)
        label.Text = "  " .. fullText
    end)
end

-- 2. NOVOS MÓDULOS DE SCAN
local function DeepScan()
    for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    LogHistory = {}

    for _, v in pairs(Workspace:GetDescendants()) do
        -- 1. Capturar Atributos (Vida, ID da Pedra, etc)
        local attrs = v:GetAttributes()
        if next(attrs) then
            local attrList = ""
            for name, val in pairs(attrs) do attrList = attrList .. name .. "=" .. tostring(val) .. " | " end
            AddLog("ATTR", v, "game."..v:GetFullName(), " -> {"..attrList.."}")
        end

        -- 2. Capturar Scripts (Para saber quem controla a pedra)
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            AddLog("SCRIPT", v, "game."..v:GetFullName())
        end

        -- 3. Prompts (Original)
        if v:IsA("ProximityPrompt") then
            AddLog("PROMPT", v.Parent, "game."..v:GetFullName())
        end
    end
    
    -- Remotes no Replicated
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            AddLog("REMOTE", r, "game."..r:GetFullName())
        end
    end
end

-- Função de Filtro em tempo real
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
CreateBtn("COPIAR TUDO 📋", Vector2.new(0.26, 0.1), Color3.fromRGB(50, 150, 50), function()
    local t = ""
    for _, l in pairs(LogHistory) do t = t .. l.Text .. " Path: " .. l.Path .. "\n" end
    setclipboard(t)
end)
CreateBtn("LIMPAR 🧹", Vector2.new(0.50, 0.1), Color3.fromRGB(150, 50, 50), function()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    LogHistory = {}
end)
CreateBtn("REAL-TIME 👁️", Vector2.new(0.74, 0.1), Color3.fromRGB(0, 150, 200), function()
    -- Lógica de monitoramento (mantida do anterior)
    AddLog("INFO", {Name="Monitor Ativo"}, "N/A")
    Workspace.DescendantAdded:Connect(function(d)
        AddLog("NEW", d, "game."..d:GetFullName())
    end)
end)

-- Notificação
game.StarterGui:SetCore("SendNotification", {Title = "Omni-Scanner V2", Text = "Modo Deep Scan e Atributos Liberado!", Duration = 5})
