--[[ 
    RED TEAM TOOL: AUTO-FARM V8 (TITAN SLAYER)
    - Volta do Teleporte em NPCs (Gafanhoto).
    - Foco total na EntityFolder (Mobs 34_E_0, etc).
    - Ciclo: Achar Missão -> Aceitar -> Teleportar p/ Mob -> Matar -> Repetir.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.2, -- Velocidade do pulo entre NPCs
    AttackDist = 5000,   -- Raio gigantesco para achar mobs no mapa todo
    HeightOffset = 9,    -- Altura do God Mode (Flutuar)
    MobWaitTime = 5,     -- Tempo que espera os mobs spawnarem depois de aceitar
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW",
    ["88108791549573"] = "RED"
}

-- Estado Global
getgenv().TitanActive = false
local CurrentState = "SEARCHING" -- Estados: SEARCHING, WAITING_MOBS, KILLING
local VisitedNPCs = {} 
local CurrentMob = nil
local QuestAcceptTime = 0

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TitanSlayerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 110)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Neon
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: PARADO"
StatusLbl.Size = UDim2.new(1, 0, 0.3, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.Font = Enum.Font.GothamBlack
StatusLbl.TextSize = 14
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.Text = "LIGAR TITAN"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES DE COMBATE/SISTEMA =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

-- Busca qualquer coisa viva na EntityFolder
local function findEntityMob()
    local folder = workspace:FindFirstChild("EntityFolder")
    if not folder then return nil end

    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = CONFIG.AttackDist
    
    for _, model in pairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local hum = model:FindFirstChild("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            
            -- Verifica se tem vida > 0
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

-- Teleporte seguro
local function safeTeleport(targetCFrame)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

-- ================= LÓGICA DE ESTADOS =================

-- 1. PROCURAR MISSÃO (Teleporte Gafanhoto)
local function searchPhase()
    StatusLbl.Text = "BUSCANDO NPC..."
    StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)

    -- A. TENTA ACEITAR GUI SE TIVER ABERTA
    local guiAccepted = false
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local txt = (btn.Text or ""):upper()
                    -- Clica em ACEITAR ou Dialogos
                    if string.find(txt, "ACEITAR") or string.find(btn.Name:upper(), "ACCEPT") or string.find(btn.Name:upper(), "CONFIRM") then
                        pcall(function() 
                            fireclickdetector(btn) 
                            for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                        end)
                        guiAccepted = true
                    end
                end
            end
        end
    end

    if guiAccepted then
        -- Se clicou em aceitar, muda para espera dos mobs
        StatusLbl.Text = "MISSÃO ACEITA! ESPERANDO MOBS..."
        CurrentState = "WAITING_MOBS"
        QuestAcceptTime = os.time()
        task.wait(1)
        return
    end

    -- B. TELEPORTA PARA NPCS
    local foundBlue = {}
    local priorityNPC = nil

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local model = obj.Parent.Parent
            if model and model:IsA("Model") then
                local type = nil
                for _, img in pairs(obj:GetDescendants()) do
                    if img:IsA("ImageLabel") then
                        local id = cleanID(img.Image)
                        if IDS[id] then type = IDS[id] end
                    end
                end
                
                if type == "YELLOW" or type == "RED" then
                    priorityNPC = model
                elseif type == "BLUE" then
                    -- Só adiciona se não visitou recentemente
                    if not VisitedNPCs[model] or (os.time() - VisitedNPCs[model] > 60) then
                        table.insert(foundBlue, model)
                    end
                end
            end
        end
    end

    -- Lógica de Escolha
    local target = priorityNPC
    if not target and #foundBlue > 0 then
        target = foundBlue[math.random(1, #foundBlue)]
    end

    if target and target:FindFirstChild("HumanoidRootPart") then
        -- Teleporta
        safeTeleport(target.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
        VisitedNPCs[target] = os.time()
        
        -- Interage (E)
        local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then fireproximityprompt(prompt) end
        
        task.wait(CONFIG.TeleportDelay)
    else
        -- Se não achou nada, limpa lista para revisitar
        if #foundBlue == 0 then VisitedNPCs = {} end
    end
end

-- 2. ESPERANDO MOBS (Delay tático)
local function waitingPhase()
    -- Verifica se mobs apareceram na EntityFolder
    local mob = findEntityMob()
    if mob then
        StatusLbl.Text = "MOBS DETECTADOS!"
        CurrentState = "KILLING"
    else
        StatusLbl.Text = "PROCURANDO MOBS/PORTAL..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 0)
        
        -- Se passou muito tempo e não achou mob, volta a procurar missão (talvez bugou)
        if (os.time() - QuestAcceptTime) > 15 then
            StatusLbl.Text = "TIMEOUT - VOLTANDO..."
            CurrentState = "SEARCHING"
        end
    end
end

-- 3. MATAR (Kill Aura)
local function killingPhase()
    local mob = findEntityMob()
    
    if mob then
        CurrentMob = mob
        StatusLbl.Text = "ELIMINANDO: " .. mob.Name
        StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- GOD MODE: Fica em cima da cabeça do mob
            local godPos = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            safeTeleport(godPos)
            
            -- Olha pra baixo (pra bater)
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position)
            
            attack()
        end
    else
        -- Se não tem mais mobs na pasta
        StatusLbl.Text = "AREA LIMPA! VOLTANDO..."
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1)
        CurrentState = "SEARCHING"
    end
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait() do
        -- Visual ESP (Sempre Ativo)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and model:IsA("Model") and not model:FindFirstChild("TitanESP") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") then
                            local id = cleanID(child.Image)
                            if IDS[id] == "YELLOW" then 
                                local h = Instance.new("Highlight", model); h.Name="TitanESP"; h.FillColor=Color3.fromRGB(255,215,0)
                            elseif IDS[id] == "RED" then 
                                local h = Instance.new("Highlight", model); h.Name="TitanESP"; h.FillColor=Color3.fromRGB(255,0,0)
                            end
                        end
                    end
                end
            end
        end

        if not getgenv().TitanActive then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

        -- Auto-Equipar Arma
        local bp = LocalPlayer.Backpack
        local ch = LocalPlayer.Character
        if not ch:FindFirstChildWhichIsA("Tool") then
            local t = bp:FindFirstChildWhichIsA("Tool")
            if t then t.Parent = ch end
        end

        -- Máquina de Estados
        if CurrentState == "SEARCHING" then
            searchPhase()
        elseif CurrentState == "WAITING_MOBS" then
            waitingPhase()
        elseif CurrentState == "KILLING" then
            killingPhase()
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().TitanActive = not getgenv().TitanActive
    if getgenv().TitanActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentState = "SEARCHING"
    else
        ToggleBtn.Text = "LIGAR TITAN"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
    end
end)
