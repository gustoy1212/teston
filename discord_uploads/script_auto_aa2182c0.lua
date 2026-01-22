-- [[ OMNI-SCANNER: DELTA EDITION ]] --
-- Otimizado para Emuladores e Executores Mobile

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- 1. UI SETUP
local ScreenName = "OmniDeltaScan"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 550, 0, 320)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) 
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 120)
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Title.Text = "📱 OMNI-SCANNER (DELTA MODE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 120)
Title.Font = Enum.Font.Code
Title.TextSize = 16

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Área de Log
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 0.65, 0)
Scroll.Position = UDim2.new(0, 10, 0.13, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
Scroll.ScrollBarThickness = 8

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Container Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, -20, 0.18, 0)
BtnContainer.Position = UDim2.new(0, 10, 0.80, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, order, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.24, 0, 0.9, 0) -- 4 botões agora
    btn.Position = UDim2.new((order-1)*0.253, 0, 0, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- LÓGICA
local LogHistory = {}
local RealTimeConnection = nil
local IsMonitoring = false
local IgnoreSpam = true -- Começa ativado para evitar lag

-- Função: Adicionar Log
local function AddLog(obj)
    local success, path = pcall(function() return obj:GetFullName() end)
    if not success or not obj.Parent then return end

    -- FILTRO ANTI-LIXO (Importante para evitar 5000 itens inúteis)
    if IgnoreSpam then
        if obj:IsA("MeshPart") or obj:IsA("Part") or obj:IsA("Attachment") or obj:IsA("Trail") or obj:IsA("Beam") then
            return -- Ignora partes visuais puras
        end
    end

    local timestamp = os.date("%X")
    local logEntry = string.format("[%s] %s (%s)", timestamp, obj.Name, obj.ClassName)
    local fullInfo = "game." .. path
    
    table.insert(LogHistory, fullInfo)
    
    -- Visual (limitado aos ultimos 100 para não travar a UI)
    if #Scroll:GetChildren() > 100 then
        Scroll:GetChildren()[1]:Destroy() -- Remove o mais antigo visualmente
    end

    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, 0, 0, 18)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. logEntry
    btn.TextColor3 = Color3.fromRGB(100, 220, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    
    btn.MouseButton1Click:Connect(function()
        setclipboard(fullInfo)
        btn.Text = "  COPIADO! ✅"
        task.wait(0.5)
        btn.Text = "  " .. logEntry
    end)
    
    Scroll.CanvasPosition = Vector2.new(0, 99999)
end

-- Toggle Monitor
local function ToggleMonitor()
    IsMonitoring = not IsMonitoring
    if IsMonitoring then
        Title.Text = "👁️ MONITORANDO... (Use Skills/Itens)"
        Title.TextColor3 = Color3.fromRGB(0, 255, 120)
        LogHistory = {} -- Limpa ao iniciar novo scan
        
        RealTimeConnection = Workspace.DescendantAdded:Connect(function(descendant)
            task.wait() 
            AddLog(descendant)
        end)
    else
        Title.Text = "⏸️ PAUSADO - " .. #LogHistory .. " ITENS"
        Title.TextColor3 = Color3.fromRGB(255, 100, 100)
        if RealTimeConnection then RealTimeConnection:Disconnect() end
    end
end

-- Salvar em Arquivo (A SOLUÇÃO DO DELTA)
local function SaveToFile()
    if #LogHistory == 0 then return end
    
    local content = "-- LOG OMNI-SCANNER (" .. os.date("%c") .. ") --\n\n"
    content = content .. table.concat(LogHistory, "\n")
    
    -- Tenta usar writefile (padrão de executores)
    local success, err = pcall(function()
        writefile("omni_logs.txt", content)
    end)
    
    if success then
        Title.Text = "✅ SALVO EM 'omni_logs.txt'!"
        -- Tenta avisar onde fica
        game.StarterGui:SetCore("SendNotification", {
            Title = "SUCESSO!";
            Text = "Procure o arquivo omni_logs.txt na pasta do Delta.";
            Duration = 5;
        })
    else
        Title.Text = "❌ ERRO AO SALVAR ARQUIVO"
        warn("Erro Writefile:", err)
    end
    task.wait(2)
    Title.Text = "📱 OMNI-SCANNER (DELTA MODE)"
end

-- Copiar Safe (Copia só os ultimos 50 se for muito grande)
local function CopySafe()
    if #LogHistory == 0 then return end
    
    -- Se tiver menos que 1000 caracteres, copia tudo
    local fullText = table.concat(LogHistory, "\n")
    if string.len(fullText) < 5000 then
        setclipboard(fullText)
        Title.Text = "📋 TUDO COPIADO!"
    else
        -- Se for gigante, copia só os ultimos 20 itens
        local lastItems = {}
        local start = math.max(1, #LogHistory - 50)
        for i = start, #LogHistory do
            table.insert(lastItems, LogHistory[i])
        end
        setclipboard(table.concat(lastItems, "\n"))
        Title.Text = "⚠️ MUITO GRANDE! COPIEI OS ÚLTIMOS 50"
    end
    task.wait(2)
    Title.Text = "📱 OMNI-SCANNER (DELTA MODE)"
end

local function ToggleFilter()
    IgnoreSpam = not IgnoreSpam
    if IgnoreSpam then
        Title.Text = "🛡️ FILTRO: ATIVADO (Sem lixo)"
    else
        Title.Text = "🛡️ FILTRO: DESATIVADO (Tudo)"
    end
    task.wait(1)
    Title.Text = "📱 OMNI-SCANNER (DELTA MODE)"
end

-- BOTOES
CreateBtn("ON/OFF 👁️", 1, Color3.fromRGB(0, 120, 200), ToggleMonitor)
CreateBtn("FILTRO 🛡️", 2, Color3.fromRGB(200, 150, 0), ToggleFilter)
CreateBtn("SALVAR TXT 📁", 3, Color3.fromRGB(0, 180, 80), SaveToFile)
CreateBtn("COPIAR 📋", 4, Color3.fromRGB(150, 50, 150), CopySafe)

game.StarterGui:SetCore("SendNotification", {
    Title = "DELTA SCANNER";
    Text = "Use 'SALVAR TXT' se a lista for grande!";
    Duration = 5;
})