--[[ 
    GOD HAND V9 - COLLECTOR PROFISSIONAL
    - Baseado na análise de LOG 161728
    - Auto Server Hop (Troca de servidor se não achar nada)
    - Leitura de Preço/Raridade (ReplicatedStorage)
    - Voo Segmentado (Anti-Kick)
    - ESP Visual (Wallhack)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES "INSANAS"
local SETTINGS = {
    MinPriceToPick = 0,         -- Preço mínimo da fruta para coletar (0 = pega tudo)
    AutoServerHop = true,       -- Troca de servidor se não achar nada
    FlightSpeed = 250,          -- Velocidade segura
    Height = 400,               -- Altura de cruzeiro
    ScanDelay = 3               -- Tempo esperando renderizar
}

-- LISTA DE ILHAS (Rota Otimizada Sea 1)
local Route = {
    Vector3.new(-2572, 0, 2044),  -- Starter
    Vector3.new(-1200, 0, 400),   -- Jungle
    Vector3.new(940, 0, 4360),    -- Desert
    Vector3.new(-1645, 0, -2270), -- Pirate Village
    Vector3.new(1130, 0, -1230),  -- Snow
    Vector3.new(-4950, 0, 720),   -- Marine Fortress
    Vector3.new(-4700, 0, -2000), -- Skypiea
    Vector3.new(5300, 0, -2600),  -- Magma
    Vector3.new(5000, 0, 500)     -- Impel Down
}

-- INTERFACE GRÁFICA (GUI)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local InfoLabel = Instance.new("TextLabel")
local BtnStart = Instance.new("TextButton")
local BtnHop = Instance.new("TextButton")
local ProgressBar = Instance.new("Frame")
local ProgressFill = Instance.new("Frame")

ScreenGui.Name = "GodHandV9"
ScreenGui.Parent = CoreGui

MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255) -- Roxo Neon
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 260)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(60, 0, 180)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.GothamBlack
Title.Text = "🔮 GOD HAND V9"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.15, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "SISTEMA AGUARDANDO"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12

InfoLabel.Parent = MainFrame
InfoLabel.BackgroundTransparency = 1
InfoLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
InfoLabel.Size = UDim2.new(0.9, 0, 0, 40)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Text = "Log carregado: Database de Preços Ativa.\nAnti-Kick: Segmentado"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
InfoLabel.TextSize = 11
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left

BtnStart.Parent = MainFrame
BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
BtnStart.Position = UDim2.new(0.05, 0, 0.45, 0)
BtnStart.Size = UDim2.new(0.9, 0, 0, 40)
BtnStart.Font = Enum.Font.GothamBold
BtnStart.Text = "▶ INICIAR VARREDURA"
BtnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnStart.TextSize = 14

BtnHop.Parent = MainFrame
BtnHop.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnHop.Position = UDim2.new(0.05, 0, 0.65, 0)
BtnHop.Size = UDim2.new(0.9, 0, 0, 30)
BtnHop.Font = Enum.Font.Gotham
BtnHop.Text = "☁ FORÇAR SERVER HOP"
BtnHop.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnHop.TextSize = 12

ProgressBar.Parent = MainFrame
ProgressBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ProgressBar.Position = UDim2.new(0, 0, 0.95, 0)
ProgressBar.Size = UDim2.new(1, 0, 0, 5)
ProgressBar.BorderSizePixel = 0

ProgressFill.Parent = ProgressBar
ProgressFill.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BorderSizePixel = 0

-------------------------------------------------------------------------
-- SISTEMAS AVANÇADOS
-------------------------------------------------------------------------

local isRunning = false
local noclip = nil

-- Função de Server Hop (A "Insana")
function ServerHop()
    StatusLabel.Text = "NADA AQUI... TROCANDO SERVIDOR!"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    task.wait(2)
    
    local Servers = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local function Hop()
        local success, result = pcall(function() 
            return HttpService:JSONDecode(game:HttpGet(Servers)) 
        end)
        
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        -- Se falhar, tenta dnv
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
    Hop()
end

-- Busca informações da fruta no ReplicatedStorage (Análise do Log)
function GetFruitPrice(fruitName)
    -- Remove "Fruit" do nome para buscar na pasta
    local rawName = fruitName:gsub(" Fruit", ""):gsub("Fruit ", "")
    
    -- Tenta achar em ReplicatedStorage (baseado no log enviado)
    -- O log indicou pastas como "FruitInfo" ou similar
    local fruitData = ReplicatedStorage:FindFirstChild("FruitInfo") or ReplicatedStorage:FindFirstChild("Fruits")
    
    if fruitData then
        local data = fruitData:FindFirstChild(rawName)
        if data and data:FindFirstChild("Price") then
            return data.Price.Value
        end
    end
    return 0 -- Se não achar, assume 0
end

-- Voo Segmentado (O segredo do Anti-Kick)
function SmartFly(targetPos)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    
    -- Noclip
    noclip = RunService.Stepped:Connect(function()
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
    
    local distance = (hrp.Position - targetPos).Magnitude
    
    while distance > 10 and isRunning do
        if not LocalPlayer.Character then break end
        
        local direction = (targetPos - hrp.Position).Unit
        -- Atualiza a velocidade constantemente
        bodyVel.Velocity = direction * SETTINGS.FlightSpeed
        
        -- Pulo Anti-Kick: A cada frame, garante que não é um teleporte
        distance = (hrp.Position - targetPos).Magnitude
        
        -- Atualiza barra de progresso visual
        StatusLabel.Text = "VIAJANDO: " .. math.floor(distance) .. "m"
        RunService.Heartbeat:Wait()
    end
    
    if bodyVel then bodyVel:Destroy() end
    if noclip then noclip:Disconnect() end
    hrp.Velocity = Vector3.new(0,0,0)
end

-- ESP (Desenha quadrado na fruta)
function CreateESP(part, name)
    local bill = Instance.new("BillboardGui")
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 100, 0, 50)
    bill.Adornee = part
    bill.Parent = CoreGui
    
    local lbl = Instance.new("TextLabel", bill)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🍒 " .. name
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBlack
    
    -- Caixa 3D
    local box = Instance.new("BoxHandleAdornment")
    box.Size = part.Size + Vector3.new(1,1,1)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = Color3.fromRGB(0, 255, 0)
    box.Parent = CoreGui
    
    return bill, box
end

-- Função Principal de Escaneamento
function StartScan()
    isRunning = true
    BtnStart.Text = "🛑 PARAR VARREDURA"
    BtnStart.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    
    local foundAny = false
    
    for i, point in ipairs(Route) do
        if not isRunning then break end
        
        -- Atualiza barra
        ProgressFill:TweenSize(UDim2.new(i/#Route, 0, 1, 0), "Out", "Linear", 0.5)
        
        -- 1. Voa até o ponto (Alto)
        local highPoint = Vector3.new(point.X, SETTINGS.Height, point.Z)
        SmartFly(highPoint)
        
        -- 2. Desce para renderizar
        local lowPoint = Vector3.new(point.X, 250, point.Z)
        SmartFly(lowPoint)
        
        -- 3. Espera o jogo carregar (StreamingEnabled)
        StatusLabel.Text = "ESCANEANDO ÁREA..."
        task.wait(SETTINGS.ScanDelay)
        
        -- 4. Busca Fruta
        for _, item in pairs(Workspace:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Fruit") or item.Name:find("Fruta")) then
                local handle = item:FindFirstChild("Handle")
                if handle then
                    foundAny = true
                    StatusLabel.Text = "ACHEI: " .. item.Name
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    
                    -- Verifica Preço (Log Analysis)
                    local price = GetFruitPrice(item.Name)
                    InfoLabel.Text = "Fruta: " .. item.Name .. "\nValor: $" .. price
                    
                    -- Cria ESP
                    CreateESP(handle, item.Name)
                    
                    -- Vai até ela
                    SmartFly(handle.Position)
                    
                    isRunning = false
                    BtnStart.Text = "✅ FRUTA ENCONTRADA"
                    return -- Para tudo
                end
            end
        end
        
        -- Sobe de volta antes de ir pro próximo
        SmartFly(highPoint)
    end
    
    -- Fim da rota
    if not foundAny then
        if SETTINGS.AutoServerHop then
            ServerHop()
        else
            StatusLabel.Text = "VARREDURA COMPLETA. NADA."
            BtnStart.Text = "▶ INICIAR VARREDURA"
            BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
            isRunning = false
        end
    end
end

-------------------------------------------------------------------------
-- BOTÕES
-------------------------------------------------------------------------

BtnStart.MouseButton1Click:Connect(function()
    if not isRunning then
        StartScan()
    else
        isRunning = false
        if noclip then noclip:Disconnect() end
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        StatusLabel.Text = "PARADO PELO USUÁRIO"
        BtnStart.Text = "▶ INICIAR VARREDURA"
        BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    end
end)

BtnHop.MouseButton1Click:Connect(ServerHop)