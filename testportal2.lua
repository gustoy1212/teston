--[[ 
    RED TEAM TOOL: AUTO-FARM V10 (FINAL ANSWER)
    - Movimento: Gafanhoto (Pula em todos os NPCs sem parar).
    - Interação: Spam de Tecla E + Clique.
    - Gatilho: Assim que ver 'PortalBranco' ou Mobs, ele muda para MATAR.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.0, -- Tempo em cada NPC (Rápido)
    AttackDist = 6000,   -- Raio de detecção de mob
    HeightOffset = 8,    -- Altura do God Mode
}

-- IDs (Todas as cores)
local IDS = {
    ["74232140704943"] = true, -- AZUL
    ["134433042638721"] = true, -- AMARELA
    ["88108791549573"] = true   -- VERMELHA
}

-- Estado Global
getgenv().FarmActive = false
local CurrentState = "SEARCHING" -- Estados: SEARCHING, KILLING
local VisitedNPCs = {} 
local CurrentMob = nil
local LastTeleport = 0

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmV10"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 120)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0) -- Verde Hacker
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: AGUARDANDO"
StatusLbl.Size = UDim2.new(1, 0, 0.3, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLbl.Font = Enum.Font.Code
StatusLbl.TextSize = 14
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.Text = "ATIVAR MODO GAFANHOTO"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

-- Teleporte Seguro (Reseta velocidade pra não bugar)
local function safeTeleport(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

-- Busca PortalBranco (Gatilho de Missão)
local function findPortal()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "PortalBranco" and obj:IsA("Model") then
            return obj
        end
    end
    return nil
end

-- Busca Mobs na EntityFolder
local function findEntityMob()
    local folder = workspace:FindFirstChild("EntityFolder")
    if not folder then return nil end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = CONFIG.AttackDist
    
    for _, model in pairs(folder:GetChildren()) do
        if model:IsA("Model") and model.Name ~= LocalPlayer.Name then
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

-- ================= ESTADOS =================

-- FASE 1: GAFANHOTO (Pula em NPCs + Aceita Missão)
local function searchState()
    StatusLbl.Text = "PROCURANDO NPC..."
    
    -- 1. VERIFICAÇÃO DE GATILHOS (Prioridade Alta)
    -- Se aparecer Portal ou Mob, para de procurar NPC e vai matar
    if findPortal() or findEntityMob() then
        StatusLbl.Text = "OBJETIVO DETECTADO!"
        CurrentState = "KILLING"
        return
    end

    -- 2. AUTO-ACEITAR (Verifica GUIs)
    local accepted = false
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local txt = (btn.Text or ""):upper()
                    if string.find(txt, "ACEITAR") or string.find(btn.Name:upper(), "ACCEPT") then
                        -- Clica de todas as formas
                        pcall(function()
                            fireclickdetector(btn)
                            for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                        end)
                        StatusLbl.Text = "ACEITANDO MISSÃO..."
                        accepted = true
                    end
                end
            end
        end
    end
    
    if accepted then
        task.wait(0.5) -- Breve pausa pro jogo processar o aceite
        return 
    end

    -- 3. TELEPORTE (Só se passou o delay)
    if (os.clock() - LastTeleport) < CONFIG.TeleportDelay then return end

    local targets = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local model = obj.Parent.Parent
            if model and model:IsA("Model") then
                -- Verifica ID
                local isTarget = false
                for _, img in pairs(obj:GetDescendants()) do
                    if img:IsA("ImageLabel") then
                        local id = cleanID(img.Image)
                        if IDS[id] then isTarget = true break end
                    end
                end
                
                if isTarget then
                    -- Se não visitou nos últimos 40s
                    if not VisitedNPCs[model] or (os.time() - VisitedNPCs[model] > 40) then
                        table.insert(targets, model)
                    end
                end
            end
        end
    end

    if #targets > 0 then
        local npc = targets[math.random(1, #targets)]
        if npc:FindFirstChild("HumanoidRootPart") then
            -- Vai pro NPC
            safeTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
            
            -- Interage (Tecla E + ProximityPrompt)
            local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then 
                fireproximityprompt(prompt) 
            end
            
            -- Marca visitado
            VisitedNPCs[npc] = os.time()
            LastTeleport = os.clock()
        end
    else
        -- Reseta lista se acabou os NPCs
        VisitedNPCs = {} 
    end
end

-- FASE 2: MATANÇA (Vai pro Portal + Mata Mobs)
local function killingState()
    -- 1. Verifica Mobs primeiro
    local mob = findEntityMob()
    
    if mob then
        -- MODO EXTERMINADOR
        StatusLbl.Text = "MATANDO: " .. mob.Name
        StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- God Mode (Cima e Olhando pra baixo)
            myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position)
            myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            
            attack()
        end
        return
    end

    -- 2. Se não tem mob, verifica Portal
    local portal = findPortal()
    if portal and portal:FindFirstChild("HumanoidRootPart") then
        StatusLbl.Text = "INDO PRO PORTAL..."
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
        
        -- Teleporta para o Portal
        safeTeleport(portal.HumanoidRootPart.CFrame)
        return
    end

    -- 3. Se não tem nem mob nem portal -> Acabou a missão
    StatusLbl.Text = "LIMPO! VOLTANDO..."
    StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    task.wait(1)
    CurrentState = "SEARCHING"
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait() do
        -- Visual ESP (Sempre roda pra garantir que o script tá vivo)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and not model:FindFirstChild("V10ESP") then
                     local h = Instance.new("Highlight", model); h.Name="V10ESP"; h.FillColor=Color3.fromRGB(0,255,0); h.FillTransparency=0.5
                end
            end
        end

        if not getgenv().FarmActive then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end

        -- Auto-Equipar
        local char = LocalPlayer.Character
        if not char:FindFirstChildWhichIsA("Tool") then
            local t = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
            if t then t.Parent = char end
        end

        -- Máquina de Estados Simples
        if CurrentState == "SEARCHING" then
            searchState()
        elseif CurrentState == "KILLING" then
            killingState()
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().FarmActive = not getgenv().FarmActive
    if getgenv().FarmActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CurrentState = "SEARCHING"
        VisitedNPCs = {} -- Reseta pra começar fresco
    else
        ToggleBtn.Text = "ATIVAR MODO GAFANHOTO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        StatusLbl.Text = "PARADO"
    end
end)
