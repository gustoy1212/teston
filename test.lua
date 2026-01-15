--[[ 
    RED TEAM TOOL: AUTO-FARM V6 (THE SLAYER)
    - Auto-Quest (Teleport)
    - Auto-Travel (Segue a Seta/Track)
    - Kill Aura (Flutua e Mata)
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.2,
    AttackDist = 50,    -- Distância para detectar inimigo
    HeightOffset = 8,   -- Altura que ele flutua acima do mob (God Mode)
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW",
    ["88108791549573"] = "RED"
}

-- Estado Global
getgenv().SlayerActive = false
local CurrentState = "HUNTING" -- HUNTING, TRAVELING, KILLING
local VisitedList = {} 
local CurrentTargetMob = nil

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlayerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- Vermelho Sangue
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
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
ToggleBtn.Text = "LIGAR SLAYER"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES ESSENCIAIS =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

-- Simula Clique (Ataque)
local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

-- Verifica se a Missão está ativa (GUI Track ou XP)
local function hasActiveQuest()
    -- 1. Verifica GUI Track (Seta)
    local track = PlayerGui:FindFirstChild("Track")
    if track and track.Enabled then return true end
    
    -- 2. Verifica GUI de XP/Objetivo
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, lbl in pairs(gui:GetDescendants()) do
                if lbl:IsA("TextLabel") and (string.find(lbl.Text, "/") or string.find(lbl.Text, "Matar")) then
                    return true
                end
            end
        end
    end
    return false
end

-- Tenta descobrir para onde a seta aponta
local function getQuestDestination()
    local track = PlayerGui:FindFirstChild("Track")
    if track then
        -- Tenta achar o Adornee (Peça que a seta segue)
        for _, v in pairs(track:GetDescendants()) do
            if v:IsA("BillboardGui") and v.Adornee then
                return v.Adornee -- Achamos o alvo!
            end
        end
    end
    return nil
end

-- Kill Aura (Encontra mob mais próximo)
local function findNearestMob()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local closest = nil
    local minDist = CONFIG.AttackDist
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= LocalPlayer.Character and obj.Health > 0 then
            local mobRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
            if mobRoot then
                local dist = (mobRoot.Position - myRoot.Position).Magnitude
                if dist < minDist then
                    -- Filtro Básico: Ignora NPCs de Missão (Geralmente tem nome fixo ou não tomam dano)
                    -- Aqui vamos assumir que se tem vida e não é player, é mob
                    if not Players:GetPlayerFromCharacter(obj.Parent) then
                        minDist = dist
                        closest = obj.Parent
                    end
                end
            end
        end
    end
    return closest
end

-- ================= LÓGICA DE ESTADOS =================

-- 1. CAÇAR MISSÃO (Igual V5)
local function huntPhase()
    StatusLbl.Text = "CAÇANDO MISSÃO..."
    
    -- Verifica se abriu painel para aceitar
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    if string.find(btn.Name:upper(), "ACCEPT") or string.find((btn.Text or ""):upper(), "ACEITAR") then
                        -- Clica Aceitar
                        pcall(function() 
                             for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                             fireclickdetector(btn)
                        end)
                        task.wait(1)
                        return -- Aceitou
                    end
                end
            end
        end
    end

    -- Se já tem missão, muda de fase
    if hasActiveQuest() then
        CurrentState = "TRAVELING"
        return
    end

    -- Teleporte Hunter (Lógica V5 Simplificada)
    local foundBlue = {}
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
                    -- Vai direto e tenta pegar
                    if LocalPlayer.Character.HumanoidRootPart then
                         LocalPlayer.Character.HumanoidRootPart.CFrame = model.HumanoidRootPart.CFrame
                         local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                         if prompt then fireproximityprompt(prompt) end
                    end
                    return
                elseif type == "BLUE" then
                    if not VisitedList[model] then table.insert(foundBlue, model) end
                end
            end
        end
    end
    
    if #foundBlue > 0 then
        local target = foundBlue[math.random(1, #foundBlue)]
        if LocalPlayer.Character.HumanoidRootPart then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0,2,0)
            VisitedList[target] = true
            task.wait(CONFIG.TeleportDelay)
        end
    else
        VisitedList = {} -- Reseta lista
    end
end

-- 2. VIAJAR (Ir até o Portal/Objetivo)
local function travelPhase()
    StatusLbl.Text = "INDO PRO OBJETIVO..."
    
    local dest = getQuestDestination()
    if dest then
        -- Teleporta para o alvo da seta
        if LocalPlayer.Character.HumanoidRootPart then
            LocalPlayer.Character.HumanoidRootPart.CFrame = dest.CFrame * CFrame.new(0, 5, 0)
            CurrentState = "KILLING" -- Chegou, hora de matar
        end
    else
        -- Se não achou destino (seta bugada), tenta procurar mobs perto
        local mob = findNearestMob()
        if mob then
            CurrentState = "KILLING"
        else
            StatusLbl.Text = "PROCURANDO DESTINO..."
            -- Pode adicionar lógica de vagar aqui se travar
        end
    end
end

-- 3. MATAR (Kill Aura + God Mode)
local function killPhase()
    local mob = findNearestMob()
    
    if mob then
        CurrentTargetMob = mob
        StatusLbl.Text = "MATANDO: " .. mob.Name
        StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- God Mode: Fica em cima da cabeça
            myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            -- Olha pra baixo
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position)
            -- Zera velocidade pra não cair
            myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            
            -- Ataca
            attack()
        end
    else
        StatusLbl.Text = "PROCURANDO MOBS..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
        -- Se não tem mob perto, verifica se a missão acabou
        if not hasActiveQuest() then
            CurrentState = "HUNTING" -- Missão acabou, volta a caçar
        else
            -- Missão ativa mas sem mob? Tenta ver a seta de novo (talvez mudou de lugar)
            local dest = getQuestDestination()
            if dest then
                 if LocalPlayer.Character.HumanoidRootPart then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = dest.CFrame * CFrame.new(0,5,0)
                 end
            end
        end
    end
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait(0.1) do
        if not getgenv().SlayerActive then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

        -- Equipa Arma (Se tiver)
        local backpack = LocalPlayer.Backpack
        local char = LocalPlayer.Character
        if not char:FindFirstChildWhichIsA("Tool") then
             local tool = backpack:FindFirstChildWhichIsA("Tool")
             if tool then tool.Parent = char end
        end

        -- Máquina de Estados
        if CurrentState == "HUNTING" then
            huntPhase()
        elseif CurrentState == "TRAVELING" then
            travelPhase()
        elseif CurrentState == "KILLING" then
            killPhase()
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().SlayerActive = not getgenv().SlayerActive
    if getgenv().SlayerActive then
        ToggleBtn.Text = "PARAR SLAYER"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentState = "HUNTING"
    else
        ToggleBtn.Text = "LIGAR SLAYER"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
    end
end)
