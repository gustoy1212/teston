--[[
    🗺️ SAO PATHFINDER AI v6 (GPS REAL)
    
    MELHORIAS:
    1. PATHFINDING SERVICE: Calcula rotas complexas (escadas, muros).
    2. LEITURA DE PODER: Focada no HUD inferior esquerdo ("PODER 913").
    3. VISUALIZAÇÃO: Mostra o caminho com bolinhas (waypoints).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloPathfinder = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    ScanCooldown = 3, -- Recalcula rota a cada 3s se perder
}

-- Estados
local IsRunning = false
local CurrentPortal = nil
local MyPower = 0
local Waypoints = {}
local CurrentWaypointIndex = 0
local IsMoving = false

-- // UI SETUP //
if CoreGui:FindFirstChild("PathfinderUI") then CoreGui.PathfinderUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PathfinderUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 200)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🗺️ SAO PATHFINDER AI"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 50)
InfoLabel.Position = UDim2.new(0, 0, 0.2, 0)
InfoLabel.Text = "Aguardando..."
InfoLabel.TextColor3 = Color3.white
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextWrapped = true

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR GPS"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // VISUALIZAÇÃO DO CAMINHO (BOLINHAS) //
local WaypointMarkers = {}

local function ClearWaypoints()
    for _, m in pairs(WaypointMarkers) do m:Destroy() end
    WaypointMarkers = {}
end

local function ShowPath(waypoints)
    ClearWaypoints()
    for i, wp in ipairs(waypoints) do
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Position = wp.Position
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(0, 150, 255)
        part.Parent = Workspace
        table.insert(WaypointMarkers, part)
    end
end

-- // LEITOR DE PODER (HUD FIX) //
local function GetMyPower()
    local power = 0
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                -- Procura exato "PODER 913"
                local txt = v.Text:upper():gsub(",", "") -- Tira virgula e bota maiusculo
                if txt:match("PODER") then
                    local num = tonumber(txt:match("%d+"))
                    if num then power = num end
                end
            end
        end
    end
    
    -- Se não achar no HUD, tenta leaderstats
    if power == 0 and LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            if v.Name:lower():match("power") or v.Name:lower():match("poder") then
                power = v.Value
            end
        end
    end
    
    MyPower = power
    return power
end

-- // SISTEMA DE NAVEGAÇÃO (PATHFINDING) //
local function MoveToPath(targetPosition)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Calcula o caminho
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        WaypointSpacing = 4
    })
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(char.HumanoidRootPart.Position, targetPosition)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        Waypoints = path:GetWaypoints()
        ShowPath(Waypoints) -- Mostra bolinhas
        CurrentWaypointIndex = 2 -- Começa do segundo ponto (o primeiro é onde vc ta)
        IsMoving = true
        return true
    else
        InfoLabel.Text = "Erro de Rota: " .. tostring(errorMessage)
        return false
    end
end

-- // INTELIGÊNCIA DE PORTAL //
local function FindAndGoToPortal()
    GetMyPower()
    InfoLabel.Text = "Poder: " .. MyPower .. "\nEscaneando..."
    
    local bestPortal = nil
    local bestReq = -1
    local char = LocalPlayer.Character
    local myPos = char.HumanoidRootPart.Position
    
    -- Varre mapa
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê placas
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:lower():gsub(",", "")
                    if txt:match("poder") then
                        local num = tonumber(txt:match("%d+"))
                        if num then reqPower = num end
                    end
                end
            end
            
            -- Lógica de Escolha
            if reqPower <= MyPower then
                -- Prioriza o maior poder possivel
                if reqPower > bestReq then
                    bestReq = reqPower
                    bestPortal = obj
                end
            end
        end
    end
    
    if bestPortal then
        CurrentPortal = bestPortal
        InfoLabel.Text = "Alvo: Portal " .. bestReq .. "\nCalculando Rota..."
        
        local targetPart = bestPortal[SETTINGS.PortalTrigger]
        local success = MoveToPath(targetPart.Position)
        
        if not success then
            InfoLabel.Text = "Rota bloqueada! Tentando outro..."
            CurrentPortal = nil -- Tenta achar outro na proxima
        end
    else
        InfoLabel.Text = "Nenhum portal para Poder " .. MyPower
    end
end

-- // LOOP DE MOVIMENTO //
RunService.Heartbeat:Connect(function()
    if not getgenv().SoloPathfinder or not IsRunning or not IsMoving then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Segue os waypoints
    if CurrentWaypointIndex <= #Waypoints then
        local wp = Waypoints[CurrentWaypointIndex]
        
        if wp.Action == Enum.PathWaypointAction.Jump then
            char.Humanoid.Jump = true
        end
        
        char.Humanoid:MoveTo(wp.Position)
        
        -- Checa se chegou perto do waypoint
        local dist = (char.HumanoidRootPart.Position - wp.Position).Magnitude
        if dist < 4 then
            CurrentWaypointIndex = CurrentWaypointIndex + 1
        end
    else
        -- Chegou no fim do caminho
        IsMoving = false
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position) -- Para
        
        -- Tenta Entrar
        if CurrentPortal then
            local trigger = CurrentPortal:FindFirstChild(SETTINGS.PortalTrigger)
            if trigger and (char.HumanoidRootPart.Position - trigger.Position).Magnitude < 10 then
                InfoLabel.Text = "Entrando..."
                firetouchinterest(char.HumanoidRootPart, trigger, 0)
                firetouchinterest(char.HumanoidRootPart, trigger, 1)
                for _, pp in ipairs(trigger:GetChildren()) do
                    if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                end
                task.wait(2)
            else
                InfoLabel.Text = "Cheguei mas o portal sumiu?"
            end
        end
    end
end)

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloPathfinder = false
    ClearWaypoints()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        spawn(function()
            while IsRunning do
                if not IsMoving then
                    FindAndGoToPortal()
                end
                task.wait(2)
            end
        end)
    else
        ToggleBtn.Text = "LIGAR GPS"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        IsMoving = false
        ClearWaypoints()
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
    end
end)