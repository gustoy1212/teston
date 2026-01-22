-- [[ OMNI-SCANNER V2.5: NO-LAG EDITION ]] --
-- Adicionado: Filtro de Repetição e Leitor de Argumentos (Spy)

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenName = "OmniGodScan_V2_5"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
-- Proteção para Delta/Fluxus (gethui)
if gethui then 
    ScreenGui.Parent = gethui() 
else 
    ScreenGui.Parent = CoreGui 
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
Title.Text = "👁️ OMNI V2.5 (NO REPEAT)"
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

-- Scroll List
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
local LogHistory = {} -- Guarda o histórico para salvar
local SeenLogs = {}   -- Guarda o que já foi visto para não repetir (ANTI-FLOOD)
local Connections = {}
local IsScanning = false

-- 1. SISTEMA DE LOG NA TELA (COM FILTRO DE REPETIÇÃO)
local function AddLogToUI(text, color, isImportant)
    -- FILTRO DE REPETIÇÃO: Se essa mensagem já apareceu, ignora!
    if SeenLogs[text] then return end
    SeenLogs[text] = true -- Marca como vista
    
    -- Salva no histórico para o .txt
    table.insert(LogHistory, text)
    StatusLabel.Text = "Capturados (Únicos): " .. #LogHistory

    -- Adiciona visualmente
    local label = Instance.new("TextLabel", ScrollList)
    label.Size = UDim2.new(1, 0, 0, 20) -- Aumentei um pouco
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.TextWrapped = false 

    -- Se for importante, destaca mais
    if isImportant then
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
    end
end

-- 2. SCANNER DE OBJETOS (O QUE VOCÊ JÁ TINHA)
local function MonitorService(service, serviceName)
    local conn = service.DescendantAdded:Connect(function(descendant)
        -- Filtro básico de lixo
        if descendant:IsA("TouchTransmitter") or descendant.Name == "Handle" then return end
        
        local tag = "[OBJ]"
        local color = Color3.fromRGB(200, 200, 200)

        if descendant:IsA("RemoteEvent") then 
            tag = "[REMOTE]" 
            color = Color3.fromRGB(255, 100, 255)
        elseif descendant:IsA("Tool") then 
            tag = "[ITEM]" 
            color = Color3.fromRGB(255, 255, 0)
        end
        
        local logLine = string.format("[%s] %s -> %s", serviceName, tag, descendant.Name)
        
        -- Só mostra se for Remote ou Item (Filtra sujeira visual)
        if descendant:IsA("RemoteEvent") or descendant:IsA("Tool") or descendant.Name:lower():find("attack") then
             AddLogToUI(logLine, color, false)
        end
    end)
    table.insert(Connections, conn)
end

-- 3. SPY DE ATAQUE (NOVO - TENTA LER OS DANOS)
-- Tenta injetar o espião apenas nos Remotes de Ataque para não travar o celular
local function SetupAttackSpy()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    
    -- Permite editar a metatable
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Verifica se é um disparo para o servidor
        if method == "FireServer" and IsScanning then
            local name = self.Name:lower()
            
            -- SÓ OLHA SE FOR ATAQUE (Para não lagar)
            if name:find("attack") or name:find("skill") or name:find("hit") or name:find("damage") then
                
                -- Formata os argumentos para você ler
                local argsString = ""
                for _, v in pairs(args) do
                    if typeof(v) == "number" then
                        argsString = argsString .. " [NUM: " .. tostring(v) .. "]"
                    elseif typeof(v) == "Instance" then
                        argsString = argsString .. " [" .. v.Name .. "]"
                    else
                        argsString = argsString .. " [" .. tostring(v) .. "]"
                    end
                end

                -- Manda para a UI
                local logMsg = "⚔️ " .. self.Name .. " ARGS: " .. argsString
                AddLogToUI(logMsg, Color3.fromRGB(255, 170, 0), true)
            end
        end
        return oldNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
end

-- BOTÕES E FUNÇÕES
local function ToggleScan()
    IsScanning = not IsScanning
    if IsScanning then
        StatusLabel.Text = "🟢 MONITORANDO (SEM REPETIÇÕES)..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        MonitorService(Workspace, "WS")
        MonitorService(ReplicatedStorage, "REP")
        MonitorService(LocalPlayer.Backpack, "INV")
        
        -- Tenta ativar o Spy
        pcall(SetupAttackSpy)
        
    else
        StatusLabel.Text = "🔴 PAUSADO"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        for _, conn in pairs(Connections) do conn:Disconnect() end
        Connections = {}
    end
end

local function Clear()
    LogHistory = {}
    SeenLogs = {} -- Reseta o filtro de repetição
    for _, child in pairs(ScrollList:GetChildren()) do if child:IsA("TextLabel") then child:Destroy() end end
    StatusLabel.Text = "🗑️ Limpo"
end

local function SaveLog()
    if #LogHistory == 0 then return end
    local content = table.concat(LogHistory, "\n")
    local filename = "GOD_LOG_" .. os.date("%H%M%S") .. ".txt"
    
    -- Tenta salvar
    if writefile then
        writefile(filename, content)
        StatusLabel.Text = "✅ Salvo: " .. filename
    else
        StatusLabel.Text = "❌ Seu executor não salva arquivos!"
    end
end

-- Botoes
CreateBtn("SCAN (ON/OFF) 🔴", 1, Color3.fromRGB(200, 50, 50), ToggleScan)
CreateBtn("LIMPAR TELA 🗑️", 2, Color3.fromRGB(200, 150, 50), Clear)
CreateBtn("SALVAR TXT 💾", 3, Color3.fromRGB(50, 150, 200), SaveLog)