--[[ 
    GOD HAND V13 - AUTO RUN EDITION
    - Auto Start: Começa sozinho sem clicar em nada.
    - Otimizado para pasta 'autoexec' do Delta.
    - Mantém todas as funções do V12 (Radar, Buraco Negro, Hop).
]]

-- !!! CONFIGURAÇÃO DE AUTO-START !!!
local SETTINGS = {
    AutoStart = true,           -- [TRUE] Começa sozinho / [FALSE] Espera botão
    AutoServerHop = true,       -- Troca de servidor se acabar
    FlightSpeed = 265,          -- Velocidade
    Height = 450,               -- Altura
    ScanFrequency = 0.3,        -- Radar a cada 0.3s
    MinSlotsFree = 2            -- Vagas livres pra entrar
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

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

-- GUI SETUP (Minimizado para não atrapalhar no Auto Run)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local RadarLabel = Instance.new("TextLabel")
local BtnHop = Instance.new("TextButton")

ScreenGui.Name = "GodHandV13_Auto"
ScreenGui.Parent = CoreGui

MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.02, 0, 0.2, 0) -- Mais pra cima pra não atrapalhar
MainFrame.Size = UDim2.new(0, 250, 0, 150) -- Menor
MainFrame.Active = true
MainFrame.Draggable = true 

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBlack
Title.Text = "⚡ GOD HAND V13 (AUTO)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.25, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "INICIANDO..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12

RadarLabel.Parent = MainFrame
RadarLabel.BackgroundTransparency = 1
RadarLabel.Position = UDim2.new(0, 0, 0.4, 0)
RadarLabel.Size = UDim2.new(1, 0, 0, 20)
RadarLabel.Font = Enum.Font.GothamBold
RadarLabel.Text = "RADAR: ATIVO"
RadarLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
RadarLabel.TextSize = 11

BtnHop.Parent = MainFrame
BtnHop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BtnHop.BorderColor3 = Color3.fromRGB(255, 215, 0)
BtnHop.Position = UDim2.new(0.05, 0, 0.65, 0)
BtnHop.Size = UDim2.new(0.9, 0, 0, 30)
BtnHop.Font = Enum.Font.Gotham
BtnHop.Text = "🔁 SKIP SERVER"
BtnHop.TextColor3 = Color3.fromRGB(255, 215, 0)
BtnHop.TextSize = 12

-------------------------------------------------------------------------
-- FUNÇÕES DE SISTEMA
-------------------------------------------------------------------------

function QuickScan()
    for _, item in pairs(Workspace:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            local name = item.Name:lower()
            if (name:find("fruit") or name:find("fruta")) and not item:FindFirstChild("Humanoid") then
                if not name:find("dealer") and not name:find("gacha") then
                    local handle = item:FindFirstChild("Handle") or item.PrimaryPart
                    if handle then return item end
                end
            end
        end
    end
    return nil
end

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
        
        local direction = (targetPos - hrp.Position).Unit
        bodyVel.Velocity = direction * SETTINGS.FlightSpeed
        
        if tick() - lastScanTime > SETTINGS.ScanFrequency then
            lastScanTime = tick()
            RadarLabel.Text = "RADAR: VARRENDO..."
            RadarLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            local fruitFound = QuickScan()
            if fruitFound then
                if bodyVel then bodyVel:Destroy() end
                if noclip then noclip:Disconnect() end
                return fruitFound
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
    return nil
end

function CollectFruit(fruitModel)
    local handle = fruitModel:FindFirstChild("Handle") or fruitModel.PrimaryPart
    if not handle then return end
    
    StatusLabel.Text = "PEGANDO: " .. fruitModel.Name
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
    
    SmartFly(handle.Position, 3) 
    
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

function ServerHop()
    StatusLabel.Text = "BUSCANDO SERVER..."
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
                StatusLabel.Text = "CONECTANDO..."
                TeleportService:TeleportToPlaceInstance(PlaceId, candidates[math.random(1, #candidates)], LocalPlayer)
            else
                StatusLabel.Text = "SEM VAGAS... RETENTANDO"
                task.wait(1)
                Hop()
            end
        else
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end
    Hop()
end

function StartScan()
    isRunning = true
    local foundAny = false
    
    -- Espera carregar o personagem
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    task.wait(2) -- Espera carregar o jogo inicial
    
    for i, point in ipairs(Route) do
        if not isRunning then break end
        StatusLabel.Text = "ROTA: " .. i
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

        local interceptedFruit = SmartFly(Vector3.new(point.X, SETTINGS.Height, point.Z), 10)
        if interceptedFruit then
            foundAny = true; CollectFruit(interceptedFruit); break
        end
        
        local interceptedFruitDown = SmartFly(Vector3.new(point.X, 250, point.Z), 10)
        if interceptedFruitDown then
            foundAny = true; CollectFruit(interceptedFruitDown); break
        end
        
        StatusLabel.Text = "VERIFICANDO..."
        task.wait(1.5)
        
        local staticScan = QuickScan()
        if staticScan then
             foundAny = true; CollectFruit(staticScan); break
        end
    end
    
    if not foundAny and SETTINGS.AutoServerHop then
        ServerHop()
    else
        StatusLabel.Text = "FIM."
        isRunning = false
    end
end

BtnHop.MouseButton1Click:Connect(ServerHop)

-- !!! GATILHO DE AUTO START !!!
if SETTINGS.AutoStart then
    spawn(StartScan)
end