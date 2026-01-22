-- [[ OMNI-SCANNER V3: ULTIMATE SPY ]] --
-- Melhorias: Remote Spy Real (Args), Filtro de Spam e UI Otimizada para Mobile

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenName = "OmniGodScanV3"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end -- Proteção Delta

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 170, 255) -- Azul Hacker
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
Title.Text = "📡 OMNI-SPY V3 (ARGS + PATHS)"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 15)
StatusLabel.Position = UDim2.new(0, 0, 0.12, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Aguardando..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 10

-- LISTA DE LOGS
local ScrollList = Instance.new("ScrollingFrame", MainFrame)
ScrollList.Size = UDim2.new(0.98, 0, 0.65, 0)
ScrollList.Position = UDim2.new(0.01, 0, 0.20, 0)
ScrollList.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout", ScrollList)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- BOTÕES
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.85, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, order, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.24, 0, 0.9, 0)
    btn.Position = UDim2.new((order-1)*0.25, 2, 0, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- VARIÁVEIS DE CONTROLE
local LogHistory = {}
local SpyEnabled = false
local ObjectScanEnabled = false
local Connections = {}

-- [[ LISTA NEGRA ]] --
-- Remotes que vamos ignorar para não travar seu celular
local IgnoreNames = {
    "Move", "Walk", "UpdateCharacter", "Ping", "Heartbeat", "Animation", "Sound", "Touch"
}

local function IsIgnored(name)
    for _, badName in pairs(IgnoreNames) do
        if string.find(name, badName) then return true end
    end
    return false
end

-- [[ FORMATADOR DE ARGUMENTOS ]] --
local function FormatArgs(args)
    local str = ""
    for i, v in pairs(args) do
        local tipo = typeof(v)
        local valor = tostring(v)
        
        -- Se for tabela, tenta mostrar o conteúdo básico
        if tipo == "table" then valor = "{...}" end
        if tipo == "Instance" then valor = v.Name end
        
        -- Colore números para destaque (AQUI ESTÁ O SEGREDO DO DANO)
        if tipo == "number" then
            str = str .. " [NUM: " .. valor .. "] "
        else
            str = str .. " [" .. valor .. "] "
        end
    end
    return str
end

local function AddLogUI(text, color)
    local label = Instance.new("TextLabel", ScrollList)
    label.Size = UDim2.new(1, 0, 0, 20) -- Altura maior para ler melhor
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 10
    label.TextWrapped = false -- Deixa passar da tela se for longo
    
    table.insert(LogHistory, text)
    
    if #ScrollList:GetChildren() > 100 then
        ScrollList:GetChildren()[1]:Destroy() -- Limpa logs antigos para não travar
    end
    ScrollList.CanvasPosition = Vector2.new(0, 99999)
end

-- [[ O ESPIÃO (HOOK) ]] --
local originalNC
originalNC = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if SpyEnabled and (method == "FireServer" or method == "InvokeServer") then
        if not IsIgnored(self.Name) then
            -- BINGO! Capturamos um remote
            local argsText = FormatArgs(args)
            local logText = "📡 " .. self.Name .. " -> " .. argsText
            
            -- Envia para a UI (usando spawn para não travar o jogo)
            task.spawn(function()
                AddLogUI(logText, Color3.fromRGB(255, 170, 0)) -- Laranja para Remotes
            end)
        end
    end

    return originalNC(self, ...)
end)

-- [[ SCANNER DE OBJETOS (ANTIGO) ]] --
local function MonitorService(service)
    local conn = service.DescendantAdded:Connect(function(obj)
        if ObjectScanEnabled then
            if obj:IsA("Tool") or obj.Name:find("Chest") or obj.Name:find("Drop") then
                 AddLogUI("📦 NOVO OBJ: " .. obj.Name .. " ("..obj.ClassName..")", Color3.fromRGB(0, 255, 0))
            end
        end
    end)
    table.insert(Connections, conn)
end

-- [[ FUNÇÕES DOS BOTÕES ]] --

local function ToggleSpy()
    SpyEnabled = not SpyEnabled
    if SpyEnabled then
        StatusLabel.Text = "📡 SPY LIGADO! (Ataque agora)"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
    else
        StatusLabel.Text = "⏸️ SPY PAUSADO"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function ToggleObj()
    ObjectScanEnabled = not ObjectScanEnabled
    if ObjectScanEnabled then
        StatusLabel.Text = "📦 SCAN OBJETOS LIGADO"
        -- Reativa conexões
        MonitorService(Workspace)
        MonitorService(ReplicatedStorage)
        MonitorService(LocalPlayer.Backpack)
    else
        StatusLabel.Text = "⏸️ SCAN OBJETOS PAUSADO"
        for _, c in pairs(Connections) do c:Disconnect() end
        Connections = {}
    end
end

local function CopyLogs()
    if setclipboard then
        setclipboard(table.concat(LogHistory, "\n"))
        StatusLabel.Text = "✅ Copiado para área de transferência!"
    else
        -- Fallback para salvar arquivo
        local filename = "GOD_LOG_" .. os.date("%H%M%S") .. ".txt"
        writefile(filename, table.concat(LogHistory, "\n"))
        StatusLabel.Text = "💾 Salvo em: " .. filename
    end
end

local function ClearUI()
    for _, child in pairs(ScrollList:GetChildren()) do 
        if child:IsA("TextLabel") then child:Destroy() end 
    end
    LogHistory = {}
    StatusLabel.Text = "🗑️ Limpo"
end

-- INICIALIZAÇÃO
CreateBtn("SPY (REMOTES)", 1, Color3.fromRGB(200, 100, 0), ToggleSpy)
CreateBtn("SCAN (DROPS)", 2, Color3.fromRGB(0, 150, 50), ToggleObj)
CreateBtn("COPIAR/SALVAR", 3, Color3.fromRGB(0, 100, 200), CopyLogs)
CreateBtn("LIMPAR", 4, Color3.fromRGB(100, 100, 100), ClearUI)

AddLogUI("--- OMNI-SPY V3 PRONTO ---", Color3.fromRGB(255, 255, 255))
AddLogUI("DICA: Ative o SPY e use um ataque.", Color3.fromRGB(150, 150, 150))