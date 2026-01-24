--[[ 
    GOD HAND V12 - OMNISCIENT EDITION
    - Scan-While-Fly: Escaneia o mapa ENQUANTO viaja (Não perde nada).
    - Intercepção de Rota: Desvia se achar algo no caminho.
    - Server Hop V11 (Manteve o filtro de vagas livres).
    - Coleta "Buraco Negro" (V10).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES PROFISSIONAIS
local SETTINGS = {
    AutoServerHop = true,       -- Troca de servidor se acabar
    FlightSpeed = 265,          -- Velocidade Otimizada
    Height = 450,               -- Altura de Cruzeiro
    ScanFrequency = 0.3,        -- Escaneia a cada 0.3 segundos durante o voo
    MinSlotsFree = 2            -- Vagas livres exigidas para trocar de server
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

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local RadarLabel = Instance.new("TextLabel") -- Novo
local BtnStart = Instance.new("TextButton")
local BtnHop = Instance.new("TextButton")

ScreenGui.Name = "GodHandV12"
ScreenGui.Parent = CoreGui

MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 240)
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(120, 100, 0)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.GothamBlack
Title.Text = "👁️ OMNISCIENT V12"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.18, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "SISTEMA PRONTO"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12

RadarLabel.Parent = MainFrame
RadarLabel.BackgroundTransparency = 1
RadarLabel.Position = UDim2.new(0, 0, 0.28, 0)
RadarLabel.Size = UDim2.new(1, 0, 0, 20)
RadarLabel.Font = Enum.Font.GothamBold
RadarLabel.Text = "RADAR: OFF"
RadarLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
RadarLabel.TextSize = 11

BtnStart.Parent = MainFrame
BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
BtnStart.Position = UDim2.new(0.05, 0, 0.45, 0)
BtnStart.Size = UDim2.new(0.9, 0, 0, 40)
BtnStart.Font = Enum.Font.GothamBold
BtnStart.Text = "▶ INICIAR (SCAN EM VOO)"
BtnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnStart.TextSize = 13

BtnHop.Parent = MainFrame
BtnHop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BtnHop.BorderColor3 = Color3.fromRGB(255, 215, 0)
BtnHop.Position = UDim2.new(0.05, 0, 0.7, 0)
BtnHop.Size = UDim2.new(0.9, 0, 0, 30)
BtnHop.Font = Enum.Font.Gotham
BtnHop.Text = "🔁 HOP INTELIGENTE"
BtnHop.TextColor3 = Color3.fromRGB(255, 215, 0)
BtnHop.TextSize = 12

-------------------------------------------------------------------------
-- SISTEMA DE DETECÇÃO (ULTRA LEVE)
-------------------------------------------------------------------------

function QuickScan()
    -- Scan rápido otimizado para rodar durante o voo
    for _, item in pairs(Workspace:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            local name = item.Name:lower()
            if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
                -- Filtro de Lixo
                if not name:find("dealer") and not name:find("gacha") then
                    local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                    if handle then
                         return item -- RETORNA A FRUTA IMEDIATAMENTE
                    end
                end
            end
        end
    end
    return nil
end

-------------------------------------------------------------------------
-- SISTEMA DE VOO "OMNISCIENT"
-------------------------------------------------------------------------
local isRunning = false
local noclip = nil

function SmartFly(targetPos, stopDistance)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    
    noclip = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)
    
    local distance = (hrp.Position - targetPos).Magnitude
    local lastScanTime = 0
    
    while distance > stopDistance and isRunning do
        if not LocalPlayer.Character then break end
        
        -- MOVIMENTO
        local direction = (targetPos - hrp.Position).Unit
        bodyVel.Velocity = direction * SETTINGS.FlightSpeed
        
        -- RADAR EM VOO (A Mágica acontece aqui)
        if tick() - lastScanTime > SETTINGS.ScanFrequency then
            lastScanTime = tick()
            RadarLabel.Text = "RADAR: VARRENDO..."
            RadarLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            
            local fruitFound = QuickScan()
            if fruitFound then
                -- PAUSA TUDO! ACHAMOS ALGO NO CAMINHO!
                if bodyVel then bodyVel:Destroy() end
                if noclip then noclip:Disconnect() end
                return fruitFound -- Retorna a fruta para o controle principal
            end
        else
             RadarLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        end
        
        distance = (hrp.Position - targetPos).Magnitude
        RunService.Heartbeat:Wait()
    end
    
    if bodyVel then bodyVel:Destroy() end
    if noclip then noclip:Disconnect() end
    if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0) end
    return nil -- Chegou no destino sem achar nada
end

-------------------------------------------------------------------------
-- COLETA BURACO NEGRO (V10)
-------------------------------------------------------------------------
function CollectFruit(fruitModel)
    local handle = fruitModel:FindFirstChild("Handle") or fruitModel.PrimaryPart
    if not handle then return end
    
    StatusLabel.Text = "INTERCEPTANDO: " .. fruitModel.Name
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
    
    -- Voa até ela (Curta distância)
    SmartFly(handle.Position, 3) 
    
    -- Modo Sugador
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local startTime = tick()
    
    while fruitModel.Parent == Workspace and (tick() - startTime) < 5 do
        hrp.CFrame = handle.CFrame
        hrp.Velocity = Vector3.new(0,0,0)
        firetouchinterest(hrp, handle, 0)
        task.wait()
        firetouchinterest(hrp, handle, 1)
        if fruitModel:IsA("Tool") then fruitModel.Parent = LocalPlayer.Character end
        task.wait(0.1)
    end
    StatusLabel.Text = "COLETADO!"
end

-------------------------------------------------------------------------
-- HOP INTELIGENTE (V11)
-------------------------------------------------------------------------
function ServerHop()
    StatusLabel.Text = "BUSCANDO SERVER VAZIO..."
    local PlaceId = game.PlaceId
    local Servers = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
    
    local function Hop()
        local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(Servers)) end)
        if success and result and result.data then
            local candidates = {}
            for _, server in pairs(result.data) do
                if server.playing and server.maxPlayers and server.id ~= game.JobId then
                    if (server.maxPlayers - server.playing) >= SETTINGS.MinSlotsFree then
                        table.insert(candidates, server.id)
                    end
                end
            end
            if #candidates > 0 then
                StatusLabel.Text = "CONECTANDO A SERVER BOM..."
                TeleportService:TeleportToPlaceInstance(PlaceId, candidates[math.random(1, #candidates)], LocalPlayer)
            else
                StatusLabel.Text = "SEM VAGAS... TENTANDO DNV"
                task.wait(1)
                Hop()
            end
        else
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end
    Hop()
end

-------------------------------------------------------------------------
-- LOOP PRINCIPAL (ROTA)
-------------------------------------------------------------------------
function StartScan()
    isRunning = true
    BtnStart.Text = "🛑 PARAR"
    BtnStart.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    
    local foundAny = false
    
    for i, point in ipairs(Route) do
        if not isRunning then break end
        
        StatusLabel.Text = "ROTA PONTO " .. i
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

        -- 1. VOO DE SUBIDA / CRUZEIRO (COM SCAN)
        -- Se SmartFly retornar algo, é porque achou fruta no caminho!
        local interceptedFruit = SmartFly(Vector3.new(point.X, SETTINGS.Height, point.Z), 10)
        
        if interceptedFruit then
            foundAny = true
            CollectFruit(interceptedFruit)
            isRunning = false
            BtnStart.Text = "✅ FRUTA PEGA NO AR"
            return
        end
        
        -- 2. DESCIDA (COM SCAN)
        local interceptedFruitDown = SmartFly(Vector3.new(point.X, 250, point.Z), 10)
        
        if interceptedFruitDown then
            foundAny = true
            CollectFruit(interceptedFruitDown)
            isRunning = false
            BtnStart.Text = "✅ FRUTA PEGA NO CHÃO"
            return
        end
        
        -- 3. SCAN ESTÁTICO (Garantia)
        StatusLabel.Text = "VERIFICANDO ÁREA..."
        task.wait(1.5) -- Pausa rápida pra carregar
        
        local staticScan = QuickScan()
        if staticScan then
             foundAny = true
             CollectFruit(staticScan)
             isRunning = false
             BtnStart.Text = "✅ SUCESSO"
             return
        end
    end
    
    if not foundAny and SETTINGS.AutoServerHop then
        ServerHop()
    else
        StatusLabel.Text = "NADA ENCONTRADO."
        BtnStart.Text = "▶ REINICIAR"
        BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        isRunning = false
    end
end

-- EVENTOS
BtnStart.MouseButton1Click:Connect(function()
    if not isRunning then
        StartScan()
    else
        isRunning = false
        if noclip then noclip:Disconnect() end
        StatusLabel.Text = "PARADO"
        RadarLabel.Text = "RADAR: OFF"
        BtnStart.Text = "▶ INICIAR"
        BtnStart.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    end
end)

BtnHop.MouseButton1Click:Connect(ServerHop)