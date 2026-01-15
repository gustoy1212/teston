--[[ 
    RED TEAM TOOL: PROJECT OMNI (FARM + SUPER LOGS)
    - Auto-Farm Universal (Azul/Amarela/Vermelha).
    - Super Scanner Integrado (Mostra tudo o que acontece).
    - Botão de Copiar Logs para Debug.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.0, -- Mais rápido
    AttackDist = 5000,   -- Mapa todo
    HeightOffset = 9,    -- God Mode
}

-- IDs (Agora todas são tratadas como ALVO)
local IDS = {
    ["74232140704943"] = "QUEST",   
    ["134433042638721"] = "QUEST",
    ["88108791549573"] = "QUEST"
}

-- Variáveis
getgenv().OmniActive = false
local CurrentState = "SEARCHING"
local VisitedNPCs = {}
local LogHistory = {}

-- ================= INTERFACE (PAINEL DUPLO) =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OmniTool"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

-- PAINEL CONTROLE (ESQUERDA)
local ControlFrame = Instance.new("Frame")
ControlFrame.Name = "ControlPanel"
ControlFrame.Size = UDim2.new(0, 180, 0, 150)
ControlFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
ControlFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ControlFrame.BorderSizePixel = 2
ControlFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
ControlFrame.Active = true
MainFrame = ControlFrame -- Legado
ControlFrame.Draggable = true
ControlFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "OMNI FARM"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.Parent = ControlFrame

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: PARADO"
StatusLbl.Size = UDim2.new(1, 0, 0.2, 0)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.Font = Enum.Font.Code
StatusLbl.TextScaled = true
StatusLbl.Parent = ControlFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ControlFrame

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
CopyBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
CopyBtn.Text = "COPIAR LOGS"
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 100)
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.Parent = ControlFrame

-- PAINEL LOGS (DIREITA)
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Name = "LogPanel"
LogFrame.Size = UDim2.new(0, 300, 0, 200)
LogFrame.Position = UDim2.new(0.7, 0, 0.3, 0) -- Lado direito
LogFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LogFrame.BackgroundTransparency = 0.3
LogFrame.BorderSizePixel = 1
LogFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
LogFrame.ScrollBarThickness = 5
LogFrame.Parent = ScreenGui

local LogText = Instance.new("TextLabel")
LogText.Size = UDim2.new(1, -10, 0, 5000) -- Altura dinâmica
LogText.Position = UDim2.new(0, 5, 0, 0)
LogText.BackgroundTransparency = 1
LogText.TextColor3 = Color3.fromRGB(0, 255, 0)
LogText.TextXAlignment = Enum.TextXAlignment.Left
LogText.TextYAlignment = Enum.TextYAlignment.Top
LogText.Font = Enum.Font.Code
LogText.TextSize = 12
LogText.Text = ">>> INICIANDO SUPER SCANNER..."
LogText.Parent = LogFrame

-- ================= SISTEMA DE LOGS =================
local function log(msg)
    local time = os.date("%X")
    local newEntry = "["..time.."] " .. msg
    table.insert(LogHistory, 1, newEntry) -- Adiciona no topo
    
    -- Mantém apenas 50 logs para não travar
    if #LogHistory > 50 then table.remove(LogHistory, #LogHistory) end
    
    LogText.Text = table.concat(LogHistory, "\n")
end

-- Monitora GUIs abrindo
PlayerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        log("[GUI] Nova Janela: " .. child.Name)
        -- Monitora botões dentro da nova GUI
        for _, btn in pairs(child:GetDescendants()) do
            if btn:IsA("TextButton") then
                log("   > Botão Detectado: " .. btn.Name .. " (Texto: "..(btn.Text or "N/A")..")")
            end
        end
    end
end)

-- Monitora Mobs na EntityFolder
local EntityFolder = workspace:FindFirstChild("EntityFolder")
if EntityFolder then
    EntityFolder.ChildAdded:Connect(function(child)
        log("[MOB] Spawnou: " .. child.Name)
    end)
else
    log("[ALERTA] EntityFolder não encontrada no início!")
end

-- ================= FUNÇÕES DO FARM =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(999, 999))
end

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

-- ================= LÓGICA DE ESTADOS =================

-- FASE 1: PROCURAR QUALQUER MISSÃO
local function searchPhase()
    StatusLbl.Text = "BUSCANDO (TODAS)..."
    
    -- 1. Verifica se tem GUI de Aceitar aberta
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local txt = (btn.Text or ""):upper()
                    if string.find(txt, "ACEITAR") or string.find(btn.Name:upper(), "ACCEPT") then
                        log("[AÇÃO] Clicando em ACEITAR...")
                        pcall(function()
                            fireclickdetector(btn)
                            for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                        end)
                        CurrentState = "WAITING"
                        task.wait(1)
                        return
                    end
                end
            end
        end
    end

    -- 2. Procura NPCs (Sem filtro de cor)
    local allNPCs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local model = obj.Parent.Parent
            if model and model:IsA("Model") then
                -- Verifica se é um dos nossos IDs (Azul, Amarelo ou Vermelho)
                local isValid = false
                for _, img in pairs(obj:GetDescendants()) do
                    if img:IsA("ImageLabel") then
                        local id = cleanID(img.Image)
                        if IDS[id] then isValid = true end
                    end
                end
                
                if isValid then
                    -- Se não visitou recentemente
                    if not VisitedNPCs[model] or (os.time() - VisitedNPCs[model] > 45) then
                        table.insert(allNPCs, model)
                    end
                end
            end
        end
    end

    if #allNPCs > 0 then
        -- Pega o mais próximo ou aleatório
        local target = allNPCs[math.random(1, #allNPCs)]
        log("[MOVE] Indo para NPC: " .. target.Name)
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart") then
            -- Teleporta
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
            
            -- Interage
            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then 
                log("[INTERAGE] Apertando E...")
                fireproximityprompt(prompt) 
            end
            
            VisitedNPCs[target] = os.time()
            task.wait(CONFIG.TeleportDelay)
        end
    else
        log("[AVISO] Nenhum NPC novo encontrado. Limpando lista...")
        VisitedNPCs = {}
        task.wait(1)
    end
end

-- FASE 2: MATAR
local function killingPhase()
    local mob = findEntityMob()
    
    if mob then
        StatusLbl.Text = "MATANDO: " .. mob.Name
        
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        
        if myRoot and mobRoot then
            -- God Mode
            myRoot.CFrame = mobRoot.CFrame * CFrame.new(0, CONFIG.HeightOffset, 0)
            myRoot.CFrame = CFrame.new(myRoot.Position, mobRoot.Position) -- Olha pra baixo
            myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            
            attack()
        end
    else
        StatusLbl.Text = "SEM MOBS..."
        -- Se não tem mob, volta a procurar missão (pode ter acabado)
        CurrentState = "SEARCHING"
    end
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait(0.1) do
        if not getgenv().OmniActive then continue end
        if not LocalPlayer.Character then continue end

        -- Verifica se tem Mob na EntityFolder (Prioridade Máxima)
        -- Se tiver mob, mata. Se não tiver, procura missão.
        local hasMob = findEntityMob()
        
        if hasMob then
            CurrentState = "KILLING"
        else
            if CurrentState == "KILLING" then
                log("[INFO] Mobs acabaram. Voltando a buscar...")
            end
            CurrentState = "SEARCHING"
        end

        if CurrentState == "SEARCHING" then
            searchPhase()
        elseif CurrentState == "KILLING" then
            killingPhase()
        end
    end
end)

-- ================= BOTÕES =================
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().OmniActive = not getgenv().OmniActive
    if getgenv().OmniActive then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        log(">>> FARM INICIADO (MODO TRATOR)")
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        log(">>> FARM PAUSADO")
        StatusLbl.Text = "PARADO"
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(LogHistory, "\n"))
        log(">>> LOGS COPIADOS PARA O CLIPBOARD!")
        CopyBtn.Text = "COPIADO!"
        task.wait(1)
        CopyBtn.Text = "COPIAR LOGS"
    else
        log("[ERRO] Seu executor não suporta setclipboard")
    end
end)
