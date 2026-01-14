-- [[ OMNI-SCANNER V1 - A FERRAMENTA DO DESENVOLVEDOR ]] --
-- Use isso para descobrir os nomes das coisas e criar seus scripts

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- 1. CRIAÇÃO DA UI (INTERFACE DE HACKER)
local ScreenName = "OmniScannerUI"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15) -- Dark Mode Profundo
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Verde Matrix
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.Text = "📡 OMNI-SCANNER: MONITORAMENTO EM TEMPO REAL"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.Code
Title.TextSize = 18

-- Botão Fechar
local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Área de Log (Onde aparecem os itens)
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 0.7, 0)
Scroll.Position = UDim2.new(0, 10, 0.12, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Botões de Controle
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.85, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, posScale, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.22, 0, 0.8, 0)
    btn.Position = UDim2.new(posScale, 0, 0.1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

-- VARIÁVEIS DE CONTROLE
local LogHistory = {} -- Guarda tudo que foi scaneado
local RealTimeConnection = nil

-- FUNÇÃO: Adicionar item na lista
local function AddLog(tipo, objeto, path)
    local timestamp = os.date("%H:%M:%S")
    local fullText = string.format("[%s] %s: %s", timestamp, tipo, objeto.Name)
    
    -- Salva na memória para copiar depois
    table.insert(LogHistory, {Path = path, Text = fullText})
    
    -- Cria visual
    local label = Instance.new("TextButton", Scroll) -- Botão para poder clicar e copiar individual
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    label.Text = "  " .. fullText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 12
    
    if tipo == "REMOTE" then label.TextColor3 = Color3.fromRGB(255, 100, 100) end
    if tipo == "PROMPT" then label.TextColor3 = Color3.fromRGB(255, 255, 0) end
    if tipo == "DROP/NEW" then label.TextColor3 = Color3.fromRGB(0, 200, 255) end

    -- Clique no item copia o path
    label.MouseButton1Click:Connect(function()
        setclipboard(path)
        label.Text = "  COPIADO! -> " .. objeto.Name
        task.wait(1)
        label.Text = "  " .. fullText
    end)
end

-- FUNÇÃO 1: Scan de Remotes (O Segredo dos Auto-Farms)
local function ScanRemotes()
    for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    LogHistory = {}
    
    local function recursiva(parent)
        for _, v in pairs(parent:GetChildren()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                -- Tenta criar o caminho
                local path = "game." .. v:GetFullName()
                AddLog("REMOTE", v, path)
            end
            if v:IsA("Folder") or v:IsA("Model") then
                pcall(function() recursiva(v) end) -- Entra nas pastas
            end
        end
    end
    
    recursiva(ReplicatedStorage)
    recursiva(Workspace)
    AddLog("INFO", {Name="Scan de Remotes Finalizado"}, "")
end

-- FUNÇÃO 2: Scan de Interações (Botões E)
local function ScanPrompts()
    for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    LogHistory = {}
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local path = "game." .. v:GetFullName()
            AddLog("PROMPT", v.Parent, path) -- Loga o pai (a pedra/item)
        end
    end
    AddLog("INFO", {Name="Scan de Prompts Finalizado"}, "")
end

-- FUNÇÃO 3: Monitor em Tempo Real (Drops e Spawns)
local function ToggleRealTime()
    if RealTimeConnection then
        RealTimeConnection:Disconnect()
        RealTimeConnection = nil
        AddLog("INFO", {Name="Monitoramento PARADO"}, "")
    else
        AddLog("INFO", {Name="Monitoramento INICIADO (Faça algo no jogo!)"}, "")
        RealTimeConnection = Workspace.DescendantAdded:Connect(function(descendant)
            -- Filtros para não travar seu PC com lixo
            if descendant:IsA("BasePart") or descendant:IsA("Model") or descendant:IsA("Tool") then
                -- Espera um pouco pra ver se não é lixo temporário
                task.wait(0.1)
                if descendant.Parent then -- Se ainda existe
                    local path = "game." .. descendant:GetFullName()
                    AddLog("DROP/NEW", descendant, path)
                end
            end
        end)
    end
end

-- FUNÇÃO 4: Copiar Tudo
local function CopyAll()
    local textToCopy = "-- LOG GERADO POR OMNI-SCANNER --\n"
    for _, log in pairs(LogHistory) do
        textToCopy = textToCopy .. log.Path .. "\n"
    end
    setclipboard(textToCopy)
    Title.Text = "COPIADO PARA O CLIPBOARD! ✅"
    task.wait(2)
    Title.Text = "📡 OMNI-SCANNER: MONITORAMENTO EM TEMPO REAL"
end

-- CRIANDO OS BOTÕES
CreateBtn("SCAN REMOTES 📡", 0.02, Color3.fromRGB(150, 50, 50), ScanRemotes)
CreateBtn("SCAN PROMPTS 🖐️", 0.26, Color3.fromRGB(150, 150, 0), ScanPrompts)
CreateBtn("REAL-TIME (ON/OFF) 👁️", 0.50, Color3.fromRGB(0, 100, 150), ToggleRealTime)
CreateBtn("COPIAR TUDO 📋", 0.74, Color3.fromRGB(50, 150, 50), CopyAll)

-- Notificação Inicial
game.StarterGui:SetCore("SendNotification", {
    Title = "OMNI-SCANNER ATIVO";
    Text = "Use isso para descobrir como o jogo funciona!";
    Duration = 5;
})
