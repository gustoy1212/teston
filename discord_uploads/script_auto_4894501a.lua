-- [[ OMNI-SCANNER V3 - MOBILE FIX EDITION ]] --

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- 1. UI MELHORADA
local ScreenName = "OmniScannerV3"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350) -- Diminui um pouco pra caber melhor no celular
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 255, 150)
Stroke.Thickness = 2

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "OMNI-SCANNER V3 (Mobile Fix)"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

-- Barra de Busca
local SearchBox = Instance.new("TextBox", MainFrame)
SearchBox.Size = UDim2.new(0.9, 0, 0.1, 0)
SearchBox.Position = UDim2.new(0.05, 0, 0.1, 0)
SearchBox.PlaceholderText = "🔍 Filtrar (ex: Chest, Portal, Mítica)..."
SearchBox.Text = ""
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SearchBox.TextColor3 = Color3.new(1,1,1)
SearchBox.Font = Enum.Font.Code
SearchBox.TextSize = 14
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

-- Área de Log
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.55, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.22, 0)
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
    local fullText = string.format("[%s] [%s] %s %s", timestamp, tipo, objeto.Name, infoExtra)
    
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
    AddLog("SYS", {Name="Iniciando..."}, "Aguarde...")

    -- Scan Workspace
    for _, v in pairs(Workspace:GetDescendants()) do
        -- 1. Atributos
        local attrs = v:GetAttributes()
        if next(attrs) then
            local attrList = ""
            for name, val in pairs(attrs) do attrList = attrList .. name .. "=" .. tostring(val) .. "|" end
            AddLog("ATTR", v, v:GetFullName(), "{"..attrList.."}")
        end

        -- 2. Scripts
        if v:IsA("LocalScript") or v:IsA("ModuleScript") then
            AddLog("SCRIPT", v, v:GetFullName())
        end

        -- 3. Prompts & ClickDetectors (IMPORTANTE PRA DUNGEON)
        if v:IsA("ProximityPrompt") or v:IsA("ClickDetector") or v:IsA("TouchTransmitter") then
            AddLog("INTERACT", v.Parent, v:GetFullName(), "("..v.ClassName..")")
        end
        
        -- 4. Nomes suspeitos
        local n = v.Name:lower()
        if n:match("chest") or n:match("portal") or n:match("loot") or n:match("reward") then
             AddLog("SUSPECT", v, v:GetFullName())
        end
    end
    
    -- Remotes no Replicated
    for _, r in pairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            AddLog("REMOTE", r, r:GetFullName())
        end
    end
    
    AddLog("SYS", {Name="Fim do Scan"}, "Total: " .. #LogHistory)
end

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
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.82, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, posScale, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.28, 0, 0.8, 0)
    btn.Position = UDim2.new(posScale.X, 0, posScale.Y, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

CreateBtn("ESCANEAR 🧠", Vector2.new(0.04, 0.1), Color3.fromRGB(100, 50, 150), DeepScan)

-- BOTÃO DE CÓPIA OTIMIZADO
local CopyBtn = CreateBtn("SALVAR TUDO 💾", Vector2.new(0.36, 0.1), Color3.fromRGB(50, 150, 50), function()
    if #LogHistory == 0 then return end
    
    -- Método Otimizado: Tabela -> Texto
    local buffer = {}
    table.insert(buffer, "=== OMNI SCANNER DUMP ===")
    table.insert(buffer, "Data: " .. os.date("%x %X"))
    table.insert(buffer, "Total Objects: " .. #LogHistory)
    table.insert(buffer, "-------------------------")
    
    for _, log in ipairs(LogHistory) do
        table.insert(buffer, log.Text .. " || PATH: " .. log.Path)
    end
    
    local finalString = table.concat(buffer, "\n")
    
    -- 1. Tenta Clipboard
    pcall(function() setclipboard(finalString) end)
    
    -- 2. Salva em Arquivo (GARANTIDO NO DELTA)
    local fileName = "ScanResult_" .. math.random(1000,9999) .. ".txt"
    if writefile then
        writefile(fileName, finalString)
        game.StarterGui:SetCore("SendNotification", {
            Title = "Salvo!",
            Text = "Arquivo: " .. fileName,
            Duration = 5
        })
    else
        -- 3. Se não tiver writefile, printa no console (F9)
        print(finalString)
    end
end)

CreateBtn("LIMPAR 🧹", Vector2.new(0.68, 0.1), Color3.fromRGB(150, 50, 50), function()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    LogHistory = {}
end)

game.StarterGui:SetCore("SendNotification", {Title = "Omni-Scanner V3", Text = "Pronto para uso!", Duration = 3})