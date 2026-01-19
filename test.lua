```lua
--[[
    📈 ROBLOX PERFORMANCE MONITOR & WORKSPACE LOGGER (CLIENT-SIDE)

    O que faz: Este LocalScript oferece uma interface de usuário para monitorar o desempenho do cliente
               (FPS, Ping, Memória) em tempo real e para escanear o Workspace, listando detalhes
               de instâncias, como contagem de partes, modelos, scripts e identificando
               potenciais "problemas" ou objetos notáveis.

    Objetivo: Ajuda a identificar gargalos de performance e elementos inesperados no ambiente de jogo
              do cliente, útil para depuração e otimização.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

--// =========================================================================================
--// 1. CONFIGURAÇÃO DA GUI
--// =========================================================================================
local GUI_NAME = "PerformanceMonitor"
local UPDATE_INTERVAL_PERF = 0.5 -- Intervalo em segundos para atualizar métricas de desempenho
local UPDATE_INTERVAL_WORKSPACE = 5 -- Intervalo em segundos para escanear o Workspace (no modo automático)

-- Destrói qualquer GUI anterior com o mesmo nome para evitar duplicatas
if CoreGui:FindFirstChild(GUI_NAME) then
    CoreGui[GUI_NAME]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MonitorFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 450)
MainFrame.Position = UDim2.new(0.5, -250, 0.3, -150) -- Posição inicial centralizada, um pouco acima
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 200, 255)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "TitleLabel"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📈 MONITOR DE PERFORMANCE & WORKSPACE"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.BackgroundTransparency = 1
Title.TextSize = 16
Title.Parent = MainFrame

-- Frame para as métricas de desempenho
local PerfMetricsFrame = Instance.new("Frame")
PerfMetricsFrame.Name = "PerformanceMetrics"
PerfMetricsFrame.Size = UDim2.new(0.9, 0, 0.2, 0)
PerfMetricsFrame.Position = UDim2.new(0.05, 0, 0.08, 0)
PerfMetricsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
PerfMetricsFrame.BorderSizePixel = 0
PerfMetricsFrame.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.FillDirection = Enum.FillDirection.Vertical
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
Layout.VerticalAlignment = Enum.VerticalAlignment.Top
Layout.Parent = PerfMetricsFrame

local function createMetricLabel(name, parent)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = name .. ": --"
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local FPSLabel = createMetricLabel("FPS", PerfMetricsFrame)
local PingLabel = createMetricLabel("Ping", PerfMetricsFrame)
local MemoryLabel = createMetricLabel("Memory (MB)", PerfMetricsFrame)
local PartCountLabel = createMetricLabel("Workspace Parts", PerfMetricsFrame)
local ScriptCountLabel = createMetricLabel("Workspace Scripts", PerfMetricsFrame)

-- Log Box para o scanner do Workspace
local LogBoxScrollingFrame = Instance.new("ScrollingFrame")
LogBoxScrollingFrame.Name = "WorkspaceLogBox"
LogBoxScrollingFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
LogBoxScrollingFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
LogBoxScrollingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
LogBoxScrollingFrame.BorderSizePixel = 0
LogBoxScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Será ajustado automaticamente
LogBoxScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogBoxScrollingFrame.Parent = MainFrame

local LogText = Instance.new("TextLabel")
LogText.Name = "LogText"
LogText.Size = UDim2.new(1, 0, 0, 0) -- Altura será ajustada automaticamente
LogText.AutomaticSize = Enum.AutomaticSize.Y
LogText.TextColor3 = Color3.fromRGB(0, 255, 0)
LogText.BackgroundTransparency = 1
LogText.TextXAlignment = Enum.TextXAlignment.Left
LogText.TextYAlignment = Enum.TextYAlignment.Top
LogText.Font = Enum.Font.Code
LogText.TextSize = 11
LogText.TextWrapped = true
LogText.Text = "Monitoramento iniciado. Clique em 'Escanear Workspace' para começar.\n"
LogText.Parent = LogBoxScrollingFrame

-- Botões de Ação
local ScanBtn = Instance.new("TextButton")
ScanBtn.Name = "ScanButton"
ScanBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.83, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
ScanBtn.Text = "ESCANEAR WORKSPACE"
ScanBtn.TextColor3 = Color3.new(1, 1, 1)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 14
ScanBtn.Parent = MainFrame

local CopyBtn = Instance.new("TextButton")
CopyBtn.Name = "CopyButton"
CopyBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
CopyBtn.Position = UDim2.new(0.55, 0, 0.83, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
CopyBtn.Text = "COPIAR LOGS"
CopyBtn.TextColor3 = Color3.new(1, 1, 1)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 14
CopyBtn.Parent = MainFrame

local TogglePerfBtn = Instance.new("TextButton")
TogglePerfBtn.Name = "TogglePerfButton"
TogglePerfBtn.Size = UDim2.new(0.4, 0, 0.08, 0)
TogglePerfBtn.Position = UDim2.new(0.05, 0, 0.94, 0)
TogglePerfBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
TogglePerfBtn.Text = "PARAR MONITORAMENTO PERF."
TogglePerfBtn.TextColor3 = Color3.new(1, 1, 1)
TogglePerfBtn.Font = Enum.Font.GothamBold
TogglePerfBtn.TextSize = 12
TogglePerfBtn.Parent = MainFrame

local ToggleAutoScanBtn = Instance.new("TextButton")
ToggleAutoScanBtn.Name = "ToggleAutoScanButton"
ToggleAutoScanBtn.Size = UDim2.new(0.4, 0, 0.08, 0)
ToggleAutoScanBtn.Position = UDim2.new(0.55, 0, 0.94, 0)
ToggleAutoScanBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ToggleAutoScanBtn.Text = "INICIAR AUTO-SCAN"
ToggleAutoScanBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleAutoScanBtn.Font = Enum.Font.GothamBold
ToggleAutoScanBtn.TextSize = 12
ToggleAutoScanBtn.Parent = MainFrame

--// =========================================================================================
--// 2. VARIÁVEIS DE ESTADO E LOG
--// =========================================================================================
local currentLogData = ""
local performanceMonitoringEnabled = true
local autoScanEnabled = false
local lastPerfUpdate = 0
local lastWorkspaceScan = 0
local lastFpsTable = {}
local MAX_FPS_SAMPLES = 60 -- Para média de FPS

--// =========================================================================================
--// 3. FUNÇÕES DE LÓGICA
--// =========================================================================================

local function getFPSColor(fps)
    if fps >= 58 then
        return Color3.fromRGB(0, 255, 0) -- Verde (Excelente)
    elseif fps >= 30 then
        return Color3.fromRGB(255, 255, 0) -- Amarelo (Bom)
    else
        return Color3.fromRGB(255, 0, 0) -- Vermelho (Ruim)
    end
end

local function getPingColor(ping)
    if ping <= 100 then
        return Color3.fromRGB(0, 255, 0) -- Verde (Excelente)
    elseif ping <= 250 then
        return Color3.fromRGB(255, 255, 0) -- Amarelo (Moderado)
    else
        return Color3.fromRGB(255, 0, 0) -- Vermelho (Alto)
    end
end

local function getMemoryColor(memMb)
    if memMb <= 500 then
        return Color3.fromRGB(0, 255, 0) -- Verde (Baixo)
    elseif memMb <= 1000 then
        return Color3.fromRGB(255, 255, 0) -- Amarelo (Médio)
    else
        return Color3.fromRGB(255, 0, 0) -- Vermelho (Alto)
    end
end

-- Atualiza as métricas de desempenho na GUI
local function updatePerformanceMetrics()
    if not performanceMonitoringEnabled then return end

    -- FPS (calculado manualmente para maior precisão em scripts de usuário)
    local currentFps = math.round(1 / RunService.Heartbeat:Wait()) -- Simples, pega o FPS atual
    table.insert(lastFpsTable, currentFps)
    if #lastFpsTable > MAX_FPS_SAMPLES then
        table.remove(lastFpsTable, 1)
    end
    local totalFps = 0
    for _, fps in ipairs(lastFpsTable) do
        totalFps += fps
    end
    local avgFps = totalFps / #lastFpsTable

    FPSLabel.Text = string.format("FPS: %.1f", avgFps)
    FPSLabel.TextColor3 = getFPSColor(avgFps)

    -- Ping
    local ping = LocalPlayer:GetNetworkPing() * 1000 -- Convertendo para milissegundos
    PingLabel.Text = string.format("Ping: %d ms", math.round(ping))
    PingLabel.TextColor3 = getPingColor(ping)

    -- Memória (em MB)
    local memoryUsageMb = debug.getmemoryusage() / 1024 / 1024
    MemoryLabel.Text = string.format("Memória Cliente: %.2f MB", memoryUsageMb)
    MemoryLabel.TextColor3 = getMemoryColor(memoryUsageMb)
end

-- Escaneia o Workspace e atualiza os logs
local function scanWorkspace()
    task.spawn(function()
        currentLogData = "--- RELATÓRIO DO WORKSPACE ---\n"
        LogText.Text = currentLogData
        LogText:SetAttribute("CurrentLog", currentLogData) -- Usar atributo para armazenar o texto completo
        LogBoxScrollingFrame.CanvasPosition = Vector2.new(0, 0) -- Volta para o topo

        local totalParts = 0
        local totalModels = 0
        local totalScripts = 0
        local totalUnions = 0
        local totalMeshParts = 0
        local anchoredParts = 0
        local unanchoredParts = 0
        local potentialProblems = {}

        local descendants = Workspace:GetDescendants()

        for _, instance in ipairs(descendants) do
            if instance:IsA("BasePart") then
                totalParts += 1
                if instance.Anchored then
                    anchoredParts += 1
                else
                    unanchoredParts += 1
                end
                if instance:IsA("MeshPart") then totalMeshParts += 1 end
                if instance:IsA("UnionOperation") then totalUnions += 1 end

                -- Verificar partes muito distantes (pode indicar problemas de otimização/limpeza)
                if instance.Position.Magnitude > 10000 and instance.Anchored == false then -- 10000 studs de distância
                    table.insert(potentialProblems, string.format("  [!] Parte UNANCHORED MUITO LONGE: %s (%.0f studs)", instance:GetFullName(), instance.Position.Magnitude))
                end

            elseif instance:IsA("Model") then
                totalModels += 1
            elseif instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
                totalScripts += 1
                if instance.Parent == Workspace or instance.Parent:IsA("Model") and instance.Parent.Parent == Workspace then
                    table.insert(potentialProblems, string.format("  [!] Script em WORKSPACE: %s", instance:GetFullName()))
                end
            end
        end

        currentLogData = currentLogData .. string.format("Total de Instâncias: %d\n", #descendants)
        currentLogData = currentLogData .. string.format("Partes (total): %d (Ancoradas: %d, Desancoradas: %d)\n", totalParts, anchoredParts, unanchoredParts)
        currentLogData = currentLogData .. string.format("MeshParts: %d\n", totalMeshParts)
        currentLogData = currentLogData .. string.format("Unions: %d\n", totalUnions)
        currentLogData = currentLogData .. string.format("Modelos: %d\n", totalModels)
        currentLogData = currentLogData .. string.format("Scripts (total): %d\n", totalScripts)

        if #potentialProblems > 0 then
            currentLogData = currentLogData .. "\n--- POTENCIAIS PROBLEMAS/ATENÇÕES ---\n"
            for _, problem in ipairs(potentialProblems) do
                currentLogData = currentLogData .. problem .. "\n"
            end
        else
            currentLogData = currentLogData .. "\nNenhum problema aparente encontrado no Workspace.\n"
        end

        currentLogData = currentLogData .. "-----------------------------------------\n"
        LogText.Text = currentLogData
        LogText:SetAttribute("CurrentLog", currentLogData)

        PartCountLabel.Text = string.format("Workspace Parts: %d", totalParts)
        ScriptCountLabel.Text = string.format("Workspace Scripts: %d", totalScripts)

        ScanBtn.Text = "ESCANEAR WORKSPACE (Completo)"
    end)
end

-- Copia os logs para a área de transferência
local function copyLogs()
    if setclipboard then
        setclipboard(LogText:GetAttribute("CurrentLog") or LogText.Text)
        CopyBtn.Text = "COPIADO!"
        task.wait(1)
        CopyBtn.Text = "COPIAR LOGS"
    else
        CopyBtn.Text = "ERRO (Ver F9)"
        print("COPIAR LOGS:\n" .. (LogText:GetAttribute("CurrentLog") or LogText.Text))
    end
end

-- Loop principal para atualização das métricas de desempenho e auto-scan
RunService.Heartbeat:Connect(function(deltaTime)
    local currentTime = os.clock()

    if performanceMonitoringEnabled and (currentTime - lastPerfUpdate >= UPDATE_INTERVAL_PERF) then
        updatePerformanceMetrics()
        lastPerfUpdate = currentTime
    end

    if autoScanEnabled and (currentTime - lastWorkspaceScan >= UPDATE_INTERVAL_WORKSPACE) then
        scanWorkspace()
        lastWorkspaceScan = currentTime
    end
end)

--// =========================================================================================
--// 4. CONEXÕES DE EVENTOS
--// =========================================================================================

ScanBtn.MouseButton1Click:Connect(function()
    scanWorkspace()
end)

CopyBtn.MouseButton1Click:Connect(function()
    copyLogs()
end)

TogglePerfBtn.MouseButton1Click:Connect(function()
    performanceMonitoringEnabled = not performanceMonitoringEnabled
    if performanceMonitoringEnabled then
        TogglePerfBtn.Text = "PARAR MONITORAMENTO PERF."
        TogglePerfBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
        FPSLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Reset color
        PingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        MemoryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        lastPerfUpdate = 0 -- Força atualização imediata
    else
        TogglePerfBtn.Text = "INICIAR MONITORAMENTO PERF."
        TogglePerfBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        FPSLabel.Text = "FPS: --"
        PingLabel.Text = "Ping: -- ms"
        MemoryLabel.Text = "Memória Cliente: -- MB"
        FPSLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        PingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        MemoryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

ToggleAutoScanBtn.MouseButton1Click:Connect(function()
    autoScanEnabled = not autoScanEnabled
    if autoScanEnabled then
        ToggleAutoScanBtn.Text = "PARAR AUTO-SCAN"
        ToggleAutoScanBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        lastWorkspaceScan = 0 -- Força uma varredura imediata
        LogText.Text = LogText.Text .. "\n[AUTO-SCAN] Ativado. Próxima varredura em " .. UPDATE_INTERVAL_WORKSPACE .. "s.\n"
        LogText:SetAttribute("CurrentLog", LogText:GetAttribute("CurrentLog") .. "\n[AUTO-SCAN] Ativado. Próxima varredura em " .. UPDATE_INTERVAL_WORKSPACE .. "s.\n")
    else
        ToggleAutoScanBtn.Text = "INICIAR AUTO-SCAN"
        ToggleAutoScanBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        LogText.Text = LogText.Text .. "\n[AUTO-SCAN] Desativado.\n"
        LogText:SetAttribute("CurrentLog", LogText:GetAttribute("CurrentLog") .. "\n[AUTO-SCAN] Desativado.\n")
    end
    LogBoxScrollingFrame.CanvasPosition = Vector2.new(0, LogBoxScrollingFrame.CanvasSize.Y.Offset) -- Scroll to bottom
end)


--// =========================================================================================
--// 5. INICIALIZAÇÃO
--// =========================================================================================
task.wait(1) -- Pequeno atraso para a GUI carregar
updatePerformanceMetrics() -- Atualiza as métricas iniciais
LogText:SetAttribute("CurrentLog", LogText.Text) -- Inicializa o atributo de log

-- Notificação inicial
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Monitor de Performance Ativo";
    Text = "Use a GUI para monitorar FPS, Ping, Memória e escanear o Workspace.";
    Duration = 7;
})

print("Performance Monitor LocalScript Loaded.")
