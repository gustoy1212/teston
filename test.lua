--[[ 
    RED TEAM TOOL: AUTO-FARM V7 (ENTITY SLAYER)
    - Foco: Pasta 'EntityFolder' (Onde vivem os mobs 0_E_1).
    - Auto-Quest + Auto-Travel (Segue Seta) + God Mode Kill.
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
    AttackDist = 80,    -- Aumentei para detectar mobs longe
    HeightOffset = 8,   -- Altura do God Mode
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW",
    ["88108791549573"] = "RED"
}

-- Estado Global
getgenv().EntitySlayerActive = false
local CurrentState = "HUNTING" -- Estados: HUNTING, TRAVELING, KILLING
local VisitedList = {} 
local CurrentTargetMob = nil

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EntitySlayerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 20) -- Roxo Profundo
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
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
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES ESSENCIAIS =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

-- Verifica se tem missão ativa
local function hasActiveQuest()
    -- 1. Verifica Seta (Track)
    local track = PlayerGui:FindFirstChild("Track")
    if track and track.Enabled then return true end
    
    -- 2. Verifica Texto de Objetivo
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, lbl in pairs(gui:GetDescendants()) do
                if lbl:IsA("TextLabel") and (string.find(lbl.Text, "/") or string.find(lbl.Text:lower(), "matar")) then
                    return true
                end
            end
        end
    end
    return false
end

-- Pega o destino da seta (Portal/Mob)
local function getQuestDestination()
    local track = PlayerGui:FindFirstChild("Track")
    if track then
        for _, v in pairs(track:GetDescendants()) do
            if v:IsA("BillboardGui") and v.Adornee then
                return v.Adornee 
            end
        end
    end
    return nil
end

-- PROCURA MOBS NA PASTA 'EntityFolder'
local function findEntityMob()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local folder = workspace:FindFirstChild("EntityFolder") -- O SEGREDO ESTÁ AQUI
    if not folder then return nil end

    local closest = nil
    local minDist = CONFIG.AttackDist
    
    for _, model in pairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local hum = model:FindFirstChild("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            
            -- Verifica se está vivo e perto
            if hum and root and hum.Health > 0 then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = model
                end
            end
        end
    end
    return closest
end

-- ================= LÓGICA DE ESTADOS =================

-- 1. CAÇAR MISSÃO
local function huntPhase()
    StatusLbl.Text = "BUSCANDO NPC..."
    
    -- Tenta Aceitar
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    if string.find(btn.Name:upper(), "ACCEPT") or string.find((btn.Text or ""):upper(), "ACEITAR") then
                        pcall(function() 
                             for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                             fireclickdetector(btn)
                        end)
                        task.wait(1)
                        return 
                    end
                end
            end
        end
    end

    if hasActiveQuest() then
        CurrentState = "TRAVELING"
        return
    end

    -- Teleporta nos NPCs
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
                    -- Vai direto
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
        VisitedList = {}
    end
end

-- 2. VIAJAR (Seguir Seta)
local function travelPhase()
    StatusLbl.Text = "INDO PRO LOCAL..."
    
    local dest = getQuestDestination()
    if dest then
        if LocalPlayer.Character.HumanoidRootPart then
            LocalPlayer.Character.HumanoidRootPart.CFrame = dest.CFrame * CFrame.new(0, 5, 0)
            -- Se tiver mob perto, muda pra matar
            if findEntityMob() then
                CurrentState = "KILLING"
            end
        end
    else
        -- Seta sumiu? Procura mob na EntityFolder direto
        if findEntityMob() then
            CurrentState = "KILLING"
        else
            StatusLbl.Text = "PROCURANDO DESTINO..."
        end
    end
end

-- 3. MATAR (Foco na EntityFolder)
local function killPhase()
    local mob = findEntityMob() -- Usa a função nova otimizada
    
    if mob then
        CurrentTargetMob = mob
        StatusLbl.Text = "MATANDO: " .. mob.Name -- Vai aparecer 0_E_1
        StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- God Mode
            myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            -- Olha pra baixo
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position)
            myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            
            attack()
        end
    else
        StatusLbl.Text = "AREA LIMPA..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        if not hasActiveQuest() then
            CurrentState = "HUNTING" -- Acabou, volta a caçar
        else
            -- Ainda tem missão mas não achou mob? Segue a seta de novo
            local dest = getQuestDestination()
            if dest then
                 if LocalPlayer.Character.HumanoidRootPart then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = dest.CFrame * CFrame.new(0,5,0)
                 end
            end
        end
    end
end

-- ================= LOOP =================
task.spawn(function()
    while task.wait() do -- Loop ultra rápido
        if not getgenv().EntitySlayerActive then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

        -- Auto-Equip
        local backpack = LocalPlayer.Backpack
        local char = LocalPlayer.Character
        if not char:FindFirstChildWhichIsA("Tool") then
             local tool = backpack:FindFirstChildWhichIsA("Tool")
             if tool then tool.Parent = char end
        end

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
    getgenv().EntitySlayerActive = not getgenv().EntitySlayerActive
    if getgenv().EntitySlayerActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentState = "HUNTING"
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
    end
end)
