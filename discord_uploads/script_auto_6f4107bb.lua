-- [[ OMNI-SCANNER V3: ULTIMATE LOGGER ]] --
-- Melhorias: Anti-Duplicação, Scan de Interações e Performance Otimizada

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES AVANÇADAS
local Config = {
    IgnoreVisuals = true,  -- Ignora efeitos, sons, animações (Lixo)
    ShowRemotes = true,    -- Foca em RemoteEvent/Function
    ShowInteract = true,   -- Mostra ProximityPrompt, ClickDetector, TouchInterest
    ShowItems = true,      -- Mostra Tools, Keys, Handles
    ShowMobs = true,       -- Mostra Humanoids (NPCs/Mobs)
    AutoSaveTime = 60,     -- Salva automático a cada X segundos (0 = Desligado)
}

-- UI SETUP (Mantendo seu estilo Dark)
local ScreenName = "OmniScannerV3"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150) -- Verde Hacker
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
Title.Text = "👁️ OMNI-SCANNER V3 (ANTI-DUP)"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.12, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Aguardando comando..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12

-- Lista de Logs
local ScrollList = Instance.new("ScrollingFrame", MainFrame)
ScrollList.Size = UDim2.new(0.98, 0, 0.65, 0)
ScrollList.Position = UDim2.new(0.01, 0, 0.2, 0)
ScrollList.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", ScrollList)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Variáveis de Controle
local LogHistory = {}    -- Lista ordenada para salvar no TXT
local SeenPaths = {}     -- Tabela Hash para verificar duplicatas (O SEGREDO)
local Connections = {}
local IsScanning = false
local LogQueue = {}      -- Fila para não travar a UI

-- [[ FUNÇÃO 1: FILTRO INTELIGENTE ]] --
local function GetLogType(obj)
    local class = obj.ClassName
    local name = obj.Name:lower()
    
    -- Prioridade Máxima (Hacks)
    if class == "RemoteEvent" then return "REMOTE-EVT", Color3.fromRGB(255, 100, 255) end
    if class == "RemoteFunction" then return "REMOTE-FUNC", Color3.fromRGB(200, 50, 200) end
    
    -- Interações (Drops/Botões)
    if class == "ProximityPrompt" then return "INTERACT-E", Color3.fromRGB(0, 255, 255) end
    if class == "ClickDetector" then return "CLICK", Color3.fromRGB(0, 200, 255) end
    if class == "TouchTransmitter" or name == "touchinterest" then return "TOUCH", Color3.fromRGB(0, 150, 255) end
    
    -- Itens
    if class == "Tool" or class == "HopperBin" then return "ITEM", Color3.fromRGB(255, 255, 0) end
    if class == "ModuleScript" then return "MODULE", Color3.fromRGB(100, 100, 255) end
    
    -- Mobs
    if class == "Humanoid" and obj.Parent and obj.Parent ~= LocalPlayer.Character then 
        return "MOB", Color3.fromRGB(255, 50, 50) 
    end
    
    -- Coisas suspeitas genéricas (Baús, Drops)
    if name:find("chest") or name:find("reward") or name:find("prize") or name:find("drop") then
        return "SUSPECT", Color3.fromRGB(0, 255, 0)
    end
    
    return nil, nil
end

local function IsIgnored(obj)
    if not Config.IgnoreVisuals then return false end
    local class = obj.ClassName
    -- Filtra lixo visual pesado
    if class == "Part" or class == "MeshPart" or class == "Weld" or class == "Attachment" or 
       class == "Sound" or class == "Animation" or class == "ParticleEmitter" or 
       class == "Trail" or class == "Beam" or class == "Decal" then
       return true
    end
    return false
end

-- [[ FUNÇÃO 2: PROCESSADOR DE LOGS ]] --
local function ProcessObject(obj, sourceLabel)
    if not obj or not obj.Parent then return end
    if IsIgnored(obj) then return end
    
    local logType, color = GetLogType(obj)
    if not logType then return end -- Se não for interessante, ignora
    
    local fullPath = obj:GetFullName()
    
    -- ANTI-DUPLICAÇÃO: Se já vimos esse caminho exato, ignoramos
    if SeenPaths[fullPath] then return end
    SeenPaths[fullPath] = true -- Marca como visto
    
    local timestamp = os.date("%X")
    local logEntry = string.format("[%s] [%s] %s", timestamp, logType, obj.Name)
    local fileEntry = string.format("[%s] [%s] PATH: %s", timestamp, logType, fullPath)
    
    table.insert(LogHistory, fileEntry)
    
    -- Adiciona na fila visual (para não lagar)
    table.insert(LogQueue, {Text = logEntry, Color = color, Path = fullPath})
end

-- [[ FUNÇÃO 3: MONITORAMENTO ]] --
local function MonitorService(service)
    local conn = service.DescendantAdded:Connect(function(descendant)
        if IsScanning then
            ProcessObject(descendant, "AUTO")
        end
    end)
    table.insert(Connections, conn)
end

-- [[ SISTEMA DE UPDATE VISUAL (ANTI-LAG) ]] --
RunService.Heartbeat:Connect(function()
    if #LogQueue > 0 then
        -- Processa apenas 5 logs por frame para não travar
        local count = 0
        while #LogQueue > 0 and count < 5 do
            local data = table.remove(LogQueue, 1)
            count = count + 1
            
            local lbl = Instance.new("TextLabel", ScrollList)
            lbl.Size = UDim2.new(1, 0, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Text = data.Text
            lbl.TextColor3 = data.Color
            lbl.Font = Enum.Font.Code
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Tooltip simples (Mostra path se clicar - Opcional)
            -- (Pode adicionar botão invisivel se quiser copiar path na UI)
        end
        StatusLabel.Text = "Capturados: " .. #LogHistory .. " (Fila: " .. #LogQueue .. ")"
    end
end)

-- [[ FUNÇÕES DOS BOTÕES ]] --

local function ToggleScan()
    IsScanning = not IsScanning
    if IsScanning then
        StatusLabel.Text = "🟢 MONITORANDO (ANTI-DUP ATIVADO)..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        if #Connections == 0 then
            MonitorService(Workspace)
            MonitorService(ReplicatedStorage)
            MonitorService(Lighting)
            MonitorService(LocalPlayer.PlayerGui)
        end
    else
        StatusLabel.Text = "🔴 PAUSADO"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local function FullSnapshot()
    StatusLabel.Text = "📸 ESCANEANDO JOGO TODO..."
    task.wait() -- Pausa pra renderizar UI
    
    local count = 0
    -- Varre tudo que existe AGORA
    local targets = {ReplicatedStorage, Workspace, Lighting, LocalPlayer.PlayerGui, LocalPlayer.Backpack}
    
    for _, service in pairs(targets) do
        for _, v in pairs(service:GetDescendants()) do
            ProcessObject(v, "SNAP")
            count = count + 1
            if count % 1000 == 0 then task.wait() end -- Pausa a cada 1000 objs pra não crashar
        end
    end
    StatusLabel.Text = "📸 Snapshot Finalizado!"
end

local function SaveToFile()
    if #LogHistory == 0 then return end
    local fileName = "GOD_LOG_" .. os.date("%H%M%S") .. ".txt"
    local content = table.concat(LogHistory, "\n")
    
    -- Tenta salvar
    local success, err = pcall(function() writefile(fileName, content) end)
    
    if success then
        StatusLabel.Text = "✅ SALVO: " .. fileName
        -- Pisca verde
        MainFrame.BorderColor3 = Color3.new(0,1,0)
        task.wait(0.5)
        MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
    else
        StatusLabel.Text = "❌ ERRO AO SALVAR"
        warn(err)
    end
end

local function ClearLogs()
    LogHistory = {}
    SeenPaths = {} -- Limpa o cache de duplicação também!
    for _, v in pairs(ScrollList:GetChildren()) do 
        if v:IsA("TextLabel") then v:Destroy() end 
    end
    StatusLabel.Text = "🗑️ LIMPADO (CACHE RESETADO)"
end

-- [[ BOTÕES ]] --
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, -10, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 5, 0.82, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, order, color, func)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.23, 0, 1, 0)
    btn.Position = UDim2.new((order-1)*0.25, 0, 0, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(func)
end

CreateBtn("SCAN ON/OFF", 1, Color3.fromRGB(200, 50, 50), ToggleScan)
CreateBtn("SNAPSHOT (ALL)", 2, Color3.fromRGB(200, 150, 0), FullSnapshot)
CreateBtn("SALVAR TXT", 3, Color3.fromRGB(0, 150, 200), SaveToFile)
CreateBtn("LIMPAR", 4, Color3.fromRGB(100, 100, 100), ClearLogs)