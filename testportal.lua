--[[ 
    RED TEAM TOOL: AUTO-FARM V9 (PORTAL MANCER)
    - Auto-Quest (Aceita Missão).
    - Auto-Portal (Teleporta p/ PortalBranco).
    - Entity Slayer (Mata tudo na EntityFolder).
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.0,
    AttackDist = 5000,   -- Mapa todo
    HeightOffset = 9,    -- God Mode
}

-- IDs das Missões
local IDS = {
    ["74232140704943"] = "QUEST",   
    ["134433042638721"] = "QUEST",
    ["88108791549573"] = "QUEST"
}

-- Estado Global
getgenv().PortalMancerActive = false
local CurrentState = "SEARCHING" -- Estados: SEARCHING, PORTAL, KILLING
local VisitedNPCs = {} 
local CurrentTarget = nil
local QuestAcceptTime = 0

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PortalMancerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 110)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255) -- Branco (Portal)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: PARADO"
StatusLbl.Size = UDim2.new(1, 0, 0.3, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.Font = Enum.Font.GothamBlack
StatusLbl.TextSize = 13
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES ESSENCIAIS =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

-- Teleporte Seguro
local function safeTeleport(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

-- Busca MOBS na EntityFolder (Ignorando Player)
local function findEntityMob()
    local folder = workspace:FindFirstChild("EntityFolder")
    if not folder then return nil end

    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = CONFIG.AttackDist
    
    for _, model in pairs(folder:GetChildren()) do
        if model:IsA("Model") and model.Name ~= LocalPlayer.Name then -- Filtra seu próprio boneco
            local hum = model:FindFirstChild("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = model
                end
            end
        end
    end
    return closest
end

-- Busca o PORTAL BRANCO
local function findPortal()
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, "PortalBranco") and obj:IsA("Model") then
            return obj
        end
    end
    return nil
end

-- ================= LÓGICA DE ESTADOS =================

-- 1. PROCURAR MISSÃO
local function searchPhase()
    StatusLbl.Text = "BUSCANDO NPC..."
    
    -- Tenta Aceitar (Qualquer botão de Confirmar)
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local txt = (btn.Text or ""):upper()
                    if string.find(txt, "ACEITAR") or string.find(btn.Name:upper(), "ACCEPT") then
                        pcall(function() 
                             fireclickdetector(btn) 
                             for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                        end)
                        
                        -- Aceitou! Agora procura o Portal
                        StatusLbl.Text = "ACEITEI! PROCURANDO PORTAL..."
                        CurrentState = "PORTAL"
                        QuestAcceptTime = os.time()
                        task.wait(0.5)
                        return
                    end
                end
            end
        end
    end

    -- Teleporta nos NPCs
    local foundNPCs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local model = obj.Parent.Parent
            if model and model:IsA("Model") then
                local isValid = false
                for _, img in pairs(obj:GetDescendants()) do
                    if img:IsA("ImageLabel") then
                        local id = cleanID(img.Image)
                        if IDS[id] then isValid = true end
                    end
                end
                
                if isValid then
                    if not VisitedNPCs[model] or (os.time() - VisitedNPCs[model] > 60) then
                        table.insert(foundNPCs, model)
                    end
                end
            end
        end
    end

    if #foundNPCs > 0 then
        local target = foundNPCs[math.random(1, #foundNPCs)]
        if target:FindFirstChild("HumanoidRootPart") then
            safeTeleport(target.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
            
            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
            
            VisitedNPCs[target] = os.time()
            task.wait(CONFIG.TeleportDelay)
        end
    else
        VisitedNPCs = {} -- Reseta lista se acabar
    end
end

-- 2. IR PRO PORTAL
local function portalPhase()
    -- Primeiro verifica se já tem mobs (às vezes nascem sem portal)
    local mob = findEntityMob()
    if mob then
        CurrentState = "KILLING"
        return
    end

    -- Procura PortalBranco
    local portal = findPortal()
    if portal and portal:FindFirstChild("HumanoidRootPart") then
        StatusLbl.Text = "PORTAL ENCONTRADO!"
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
        
        -- Teleporta pra DENTRO do portal
        safeTeleport(portal.HumanoidRootPart.CFrame)
        
        -- Espera um pouco pros mobs spawnarem
        task.wait(1.5)
        CurrentState = "KILLING"
    else
        StatusLbl.Text = "ESPERANDO PORTAL..."
        -- Timeout de segurança
        if (os.time() - QuestAcceptTime) > 10 then
            CurrentState = "SEARCHING" -- Bugou, volta
        end
    end
end

-- 3. MATAR
local function killingPhase()
    local mob = findEntityMob()
    
    if mob then
        StatusLbl.Text = "MATANDO: " .. mob.Name
        StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- God Mode
            myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position)
            myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            attack()
        end
    else
        StatusLbl.Text = "LIMPO. VOLTANDO..."
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1)
        CurrentState = "SEARCHING"
    end
end

-- ================= LOOP =================
task.spawn(function()
    while task.wait() do
        -- Visual ESP
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and not model:FindFirstChild("MancerESP") then
                     local h = Instance.new("Highlight", model); h.Name="MancerESP"; h.FillColor=Color3.fromRGB(255,255,255); h.FillTransparency=0.5
                end
            end
        end

        if not getgenv().PortalMancerActive then continue end
        if not LocalPlayer.Character then continue end

        if CurrentState == "SEARCHING" then
            searchPhase()
        elseif CurrentState == "PORTAL" then
            portalPhase()
        elseif CurrentState == "KILLING" then
            killingPhase()
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().PortalMancerActive = not getgenv().PortalMancerActive
    if getgenv().PortalMancerActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentState = "SEARCHING"
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
    end
end)
