--[[ 
    GOD HAND V10 - BLACK HOLE EDITION
    - Auto Server Hop
    - Voo Segmentado (Anti-Kick)
    - SISTEMA DE COLETA AGRESSIVA (Correção do "não pegou")
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES
local SETTINGS = {
    AutoServerHop = true,       -- Troca de servidor se não achar
    FlightSpeed = 260,          -- Velocidade
    Height = 450,               -- Altura de viagem
    ScanDelay = 3.5,            -- Tempo para carregar o mapa
    CollectionRange = 15        -- Distância para ativar o "Buraco Negro"
}

-- LISTA DE ILHAS (Rota Otimizada)
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

-- GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local BtnStart = Instance.new("TextButton")
local BtnHop = Instance.new("TextButton")

ScreenGui.Name = "GodHandV10"
ScreenGui.Parent = CoreGui

MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Vermelho Agressivo
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 220)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.GothamBlack
Title.Text = "🌑 BLACK HOLE V10"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.2, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "PRONTO PARA COLETAR"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true

BtnStart.Parent = MainFrame
BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
BtnStart.Position = UDim2.new(0.05, 0, 0.45, 0)
BtnStart.Size = UDim2.new(0.9, 0, 0, 40)
BtnStart.Font = Enum.Font.GothamBold
BtnStart.Text = "▶ INICIAR CAÇA"
BtnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnStart.TextSize = 14

BtnHop.Parent = MainFrame
BtnHop.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnHop.Position = UDim2.new(0.05, 0, 0.7, 0)
BtnHop.Size = UDim2.new(0.9, 0, 0, 30)
BtnHop.Font = Enum.Font.Gotham
BtnHop.Text = "☁ SERVER HOP"
BtnHop.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnHop.TextSize = 12

-------------------------------------------------------------------------
-- LÓGICA DE COLETA (O BURACO NEGRO)
-------------------------------------------------------------------------

local isRunning = false
local noclip = nil

function ServerHop()
    StatusLabel.Text = "TROCANDO SERVIDOR..."
    local Servers = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local function Hop()
        local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(Servers)) end)
        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
    Hop()
end

-- Voo Inteligente
function SmartFly(targetPos, stopDistance)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    
    noclip = RunService.Stepped:Connect(function()
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
    
    local distance = (hrp.Position - targetPos).Magnitude
    
    while distance > stopDistance and isRunning do
        if not LocalPlayer.Character then break end
        
        local direction = (targetPos - hrp.Position).Unit
        bodyVel.Velocity = direction * SETTINGS.FlightSpeed
        
        distance = (hrp.Position - targetPos).Magnitude
        RunService.Heartbeat:Wait()
    end
    
    if bodyVel then bodyVel:Destroy() end
    if noclip then noclip:Disconnect() end
    hrp.Velocity = Vector3.new(0,0,0)
end

-- FUNÇÃO NOVA: COLETA FORÇADA
function CollectFruit(fruitModel)
    local handle = fruitModel:FindFirstChild("Handle") or fruitModel.PrimaryPart
    if not handle then return end
    
    StatusLabel.Text = "SUGANDO: " .. fruitModel.Name
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local startTime = tick()
    
    -- Loop de Coleta (Dura até 5 segundos ou até a fruta sumir)
    while fruitModel.Parent == Workspace and (tick() - startTime) < 5 do
        -- 1. Teleporta EXATAMENTE para dentro da fruta
        hrp.CFrame = handle.CFrame
        
        -- 2. Tira a velocidade (para não passar direto)
        hrp.Velocity = Vector3.new(0,0,0)
        
        -- 3. Usa FireTouch (Simula toque via código)
        firetouchinterest(hrp, handle, 0) -- Toca
        task.wait()
        firetouchinterest(hrp, handle, 1) -- Solta
        
        -- 4. Tenta equipar se for ferramenta
        if fruitModel:IsA("Tool") then
            fruitModel.Parent = LocalPlayer.Character
        end
        
        task.wait(0.1)
    end
    
    StatusLabel.Text = "COLETADO!"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
end

function StartScan()
    isRunning = true
    BtnStart.Text = "🛑 PARAR"
    BtnStart.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    
    local foundAny = false
    
    for i, point in ipairs(Route) do
        if not isRunning then break end
        
        StatusLabel.Text = "INDO PONTO: " .. i
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

        -- 1. Voo Alto
        SmartFly(Vector3.new(point.X, SETTINGS.Height, point.Z), 10)
        
        -- 2. Desce para Escanear
        SmartFly(Vector3.new(point.X, 250, point.Z), 10)
        
        StatusLabel.Text = "ESCANEANDO..."
        task.wait(SETTINGS.ScanDelay)
        
        -- 3. Busca
        for _, item in pairs(Workspace:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Model") then
                local name = item.Name:lower()
                if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
                    local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                    if handle then
                        -- Achou!
                        foundAny = true
                        StatusLabel.Text = "ACHEI: " .. item.Name
                        
                        -- VOA ATÉ ELA (Chega a 2 metros)
                        SmartFly(handle.Position, 2)
                        
                        -- ATIVA MODO SUGADOR
                        CollectFruit(item)
                        
                        isRunning = false
                        BtnStart.Text = "✅ SUCESSO"
                        return
                    end
                end
            end
        end
        
        -- Sobe de novo
        SmartFly(Vector3.new(point.X, SETTINGS.Height, point.Z), 10)
    end
    
    if not foundAny and SETTINGS.AutoServerHop then
        ServerHop()
    else
        StatusLabel.Text = "FIM DA ROTA."
        BtnStart.Text = "▶ REINICIAR"
        BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        isRunning = false
    end
end

-- BOTÕES
BtnStart.MouseButton1Click:Connect(function()
    if not isRunning then
        StartScan()
    else
        isRunning = false
        if noclip then noclip:Disconnect() end
        StatusLabel.Text = "PARADO"
        BtnStart.Text = "▶ INICIAR"
        BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end
end)

BtnHop.MouseButton1Click:Connect(ServerHop)