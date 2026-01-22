-- [[ OMNI-SCANNER: REAL-TIME EDITION ]] --
-- Focado exclusivamente em monitorar Drops e Spawns e copiar com segurança

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- 1. LIMPEZA E CONFIGURAÇÃO DA UI
local ScreenName = "OmniRealTime"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 20) -- Azul Dark Profundo
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255) -- Azul Neon
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
Title.Text = "👁️ REAL-TIME MONITOR"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 16

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Área de Log
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 0.7, 0)
Scroll.Position = UDim2.new(0, 10, 0.12, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(5, 8, 10)
Scroll.ScrollBarThickness = 6

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 2)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Container de Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, -20, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 10, 0.83, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, order, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    -- Ajuste de tamanho para 3 botões
    btn.Size = UDim2.new(0.32, 0, 1, 0) 
    btn.Position = UDim2.new((order-1)*0.34, 0, 0, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- SISTEMA LÓGICO
local LogHistory = {} -- Aqui ficam os caminhos crus para copiar
local RealTimeConnection = nil
local IsMonitoring = false

-- Função Auxiliar: Adicionar na Lista
local function AddLog(obj)
    -- Pega o caminho completo seguro
    local success, path = pcall(function() return "game." .. obj:GetFullName() end)
    if not success or not obj.Parent then return end -- Evita erro se o objeto sumir muito rápido

    local timestamp = os.date("%X")
    local displayLabel = string.format("[%s] %s", timestamp, obj.Name)

    -- 1. Salva na tabela de histórico (apenas o path)
    table.insert(LogHistory, path)

    -- 2. Cria o visual
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. displayLabel
    btn.TextColor3 = Color3.fromRGB(100, 220, 255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    
    -- Copiar individual
    btn.MouseButton1Click:Connect(function()
        setclipboard(path)
        btn.Text = "  COPIADO! ✅"
        task.wait(0.8)
        btn.Text = "  " .. displayLabel
    end)
    
    -- Auto-scroll para baixo
    Scroll.CanvasPosition = Vector2.new(0, 99999)
end

-- Função 1: Ligar/Desligar Monitoramento
local function ToggleMonitor()
    IsMonitoring = not IsMonitoring
    
    if IsMonitoring then
        Title.Text = "👁️ MONITORANDO... (Faça algo no jogo)"
        Title.TextColor3 = Color3.fromRGB(0, 255, 100)
        
        RealTimeConnection = Workspace.DescendantAdded:Connect(function(descendant)
            -- Filtro Anti-Lag: Ignora coisas inúteis
            if descendant:IsA("BasePart") or descendant:IsA("Model") or descendant:IsA("Tool") or descendant:IsA("RemoteEvent") then
                task.wait() -- Espera um frame para garantir propriedades
                AddLog(descendant)
            end
        end)
    else
        Title.Text = "⏸️ PAUSADO"
        Title.TextColor3 = Color3.fromRGB(255, 100, 100)
        if RealTimeConnection then RealTimeConnection:Disconnect() end
    end
end

-- Função 2: Copiar Tudo (CORRIGIDA)
local function CopyAll()
    if #LogHistory == 0 then
        Title.Text = "❌ NADA PARA COPIAR"
        task.wait(1)
        Title.Text = "👁️ REAL-TIME MONITOR"
        return
    end

    -- Método otimizado: table.concat é 100x mais rápido que concatenar strings
    local finalString = table.concat(LogHistory, "\n")
    
    setclipboard(finalString)
    
    Title.Text = "✅ " .. #LogHistory .. " CAMINHOS COPIADOS!"
    task.wait(1.5)
    Title.Text = "👁️ REAL-TIME MONITOR"
end

-- Função 3: Limpar Logs
local function ClearLogs()
    LogHistory = {} -- Zera a memória
    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    Title.Text = "🗑️ LOGS LIMPOS"
    task.wait(1)
    Title.Text = "👁️ REAL-TIME MONITOR"
end

-- BOTOES
CreateBtn("ON/OFF 👁️", 1, Color3.fromRGB(0, 100, 200), ToggleMonitor)
CreateBtn("COPIAR TUDO 📋", 2, Color3.fromRGB(0, 180, 100), CopyAll)
CreateBtn("LIMPAR 🗑️", 3, Color3.fromRGB(200, 50, 50), ClearLogs)

-- Notificação
game.StarterGui:SetCore("SendNotification", {
    Title = "MONITOR LIGADO";
    Text = "Ative o ON/OFF para começar a capturar.";
    Duration = 3;
})