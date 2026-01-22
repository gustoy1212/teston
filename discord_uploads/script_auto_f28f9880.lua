-- [[ OMNI-SCANNER V2: GOD MODE EDITION ]] --
-- Monitora: Workspace, ReplicatedStorage, Backpack, PlayerGui e Remotes.

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterPack = game:GetService("StarterPack")

local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenName = "OmniGodScan"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50) -- Vermelho Agressivo
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
Title.Text = "👁️ OMNI-SCANNER V2 (ALL)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.Code
Title.TextSize = 16

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.15, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pronto para scanear..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12

-- Scroll para ver logs em tempo real (NOVO)
local ScrollList = Instance.new("ScrollingFrame", MainFrame)
ScrollList.Size = UDim2.new(0.95, 0, 0.5, 0)
ScrollList.Position = UDim2.new(0.025, 0, 0.25, 0)
ScrollList.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout", ScrollList)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Container Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, -10, 0.2, 0)
BtnContainer.Position = UDim2.new(0, 5, 0.78, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, pos, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.32, 0, 1, 0)
    btn.Position = UDim2.new((pos-1)*0.34, 0, 0, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- LÓGICA DO SISTEMA
local LogHistory = {}
local Connections = {}
local IsScanning = false

-- Configurações de Filtro (O QUE VOCÊ QUER VER)
local FilterConfig = {
    ShowParts = false,      -- Se true, mostra todas as Parts (CAUSA LAG EXTREMO)
    ShowRemotes = true,     -- Mostra RemoteEvent e RemoteFunction
    ShowTools = true,       -- Mostra Itens/Ferramentas
    ShowScripts = true,     -- Mostra LocalScripts e ModuleScripts
    ShowValues = true,      -- Mostra IntValue, BoolValue (Váriaveis do jogo)
    ShowGui = true          -- Mostra GUIs aparecendo
}

-- Filtro de Lixo Aprimorado
local function IsGarbage(obj)
    local class = obj.ClassName
    local name = obj.Name:lower()

    -- SEMPRE MOSTRAR REMOTES E SCRIPTS (Mesmo com nomes estranhos)
    if class:find("Remote") or class:find("Script") then return false end
    if class:find("Tool") or class:find("HopperBin") then return false end

    -- Ignora lixo visual pesado
    if class == "Weld" or class == "Snap" or class == "Motor6D" or class == "Attachment" then return true end
    if class == "Sound" or class == "Animation" or class == "AnimationTrack" then return true end
    if class == "ParticleEmitter" or class == "Trail" or class == "Beam" then return true end
    
    -- Ignora partes físicas se a config estiver desligada
    if not FilterConfig.ShowParts and (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
        -- Exceção: Mostra se tiver nome de drop/baú
        if name:find("drop") or name:find("chest") or name:find("bau") or name:find("loot") then
            return false
        end
        return true 
    end
    
    return false
end

local function GetTag(obj)
    if obj:IsA("RemoteEvent") then return "[REMOTE-EVT]" end
    if obj:IsA("RemoteFunction") then return "[REMOTE-FUNC]" end
    if obj:IsA("Tool") then return "[ITEM]" end
    if obj:IsA("ModuleScript") then return "[MODULE]" end
    if obj:IsA("LocalScript") then return "[SCRIPT]" end
    if obj:IsA("ScreenGui") or obj:IsA("Frame") then return "[UI/GUI]" end
    if obj:FindFirstChild("Humanoid") then return "[MOB/NPC]" end
    if obj.Name:lower():find("chest") then return "[BAÚ]" end
    return "[OBJ]"
end

local function AddLog(obj, source)
    if IsGarbage(obj) then return end
    
    local tag = GetTag(obj)
    local timestamp = os.date("%X")
    local fullPath = obj:GetFullName()
    
    -- Cria string do log
    local logLine = string.format("[%s] %s %s -> %s", source, timestamp, tag, obj.Name)
    local detailedLog = logLine .. " | PATH: " .. fullPath
    
    table.insert(LogHistory, detailedLog)
    StatusLabel.Text = "Capturados: " .. #LogHistory

    -- Adiciona na UI Visual
    local label = Instance.new("TextLabel", ScrollList)
    label.Size = UDim2.new(1, 0, 0, 15)
    label.BackgroundTransparency = 1
    label.Text = logLine
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 10
    
    -- Cores para facilitar leitura
    if tag:find("REMOTE") then label.TextColor3 = Color3.fromRGB(255, 100, 255) end
    if tag:find("ITEM") then label.TextColor3 = Color3.fromRGB(255, 255, 0) end
    if tag:find("BAÚ") then label.TextColor3 = Color3.fromRGB(0, 255, 0) end
end

local function MonitorService(service, serviceName)
    local conn = service.DescendantAdded:Connect(function(descendant)
        task.wait() 
        pcall(function() AddLog(descendant, serviceName) end)
    end)
    table.insert(Connections, conn)
end

local function ToggleScan()
    IsScanning = not IsScanning
    if IsScanning then
        LogHistory = {}
        for _, child in pairs(ScrollList:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
        
        StatusLabel.Text = "🟢 MONITORANDO TUDO..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        -- MONITORA OS LOCAIS CRÍTICOS
        MonitorService(Workspace, "WS")
        MonitorService(ReplicatedStorage, "REP") -- Onde ficam os itens e remotes!
        MonitorService(Lighting, "LGT")
        MonitorService(LocalPlayer.PlayerGui, "GUI") -- Onde aparecem janelas de trade/drop
        MonitorService(LocalPlayer.Backpack, "INV") -- Quando item entra no inventário
        
        table.insert(LogHistory, "--- INÍCIO: " .. os.date("%c") .. " ---")
    else
        StatusLabel.Text = "🔴 PAUSADO"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        for _, conn in pairs(Connections) do conn:Disconnect() end
        Connections = {}
    end
end

local function SaveLog()
    if #LogHistory == 0 then return end
    local content = table.concat(LogHistory, "\n")
    local filename = "GOD_LOG_" .. os.date("%H%M%S") .. ".txt"
    pcall(function() writefile(filename, content) end)
    
    StatusLabel.Text = "✅ Salvo: " .. filename
end

local function Clear()
    LogHistory = {}
    for _, child in pairs(ScrollList:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    StatusLabel.Text = "🗑️ Limpo"
end

-- Snapshot: Pega o que JÁ EXISTE (Scan Estático)
local function Snapshot()
    StatusLabel.Text = "📸 Tirando foto do Replicated..."
    local count = 0
    -- Foca apenas em Remotes e Itens no ReplicatedStorage para não travar
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("Tool") then
            AddLog(v, "SNAPSHOT-REP")
            count = count + 1
        end
    end
    StatusLabel.Text = "📸 Snapshot: " .. count .. " objs achados"
end

-- Botoes
CreateBtn("SCAN (ON/OFF) 🔴", 1, Color3.fromRGB(200, 50, 50), ToggleScan)
CreateBtn("SNAPSHOT (REP) 📸", 2, Color3.fromRGB(200, 150, 50), Snapshot)
CreateBtn("SALVAR TXT 💾", 3, Color3.fromRGB(50, 150, 200), SaveLog)
