--[[ 
    RED TEAM TOOL: TELEPORT EXPLORER (V5)
    - Anti-Stuck: Reinicia lista se acabar os NPCs.
    - Map Roaming: Teleporta para áreas aleatórias se não achar nada.
    - Parasita: Gruda na Amarela/Vermelha até aceitar.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.2, -- Pulo mais rápido
    StuckTimeout = 1.5,  -- Tempo limite parado antes de resetar
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW", -- Rara
    ["88108791549573"] = "RED"     -- Lendária
}

-- PONTOS DE EMERGÊNCIA (Céu da Cidade)
-- Se não achar NPC, ele vai pra cá carregar o mapa
local SAFE_ZONES = {
    Vector3.new(0, 100, 0),         -- Centro Alto
    Vector3.new(600, 100, 600),     -- Nordeste
    Vector3.new(-600, 100, 600),    -- Noroeste
    Vector3.new(-600, 100, -600),   -- Sudoeste
    Vector3.new(600, 100, -600),    -- Sudeste
}

-- Estado
getgenv().ExplorerActive = false
local VisitedList = {} 
local LastTeleportTime = 0
local CurrentTargetNPC = nil 

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExplorerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 100)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Laranja
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: AGUARDANDO"
StatusLbl.Size = UDim2.new(1, 0, 0.4, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 13
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.Text = "LIGAR EXPLORER"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function isQuestGuiOpen()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local text = btn:IsA("TextButton") and btn.Text:upper() or ""
                    if string.find(text, "ACEITAR") or string.find(text, "XP") or string.find(text, "REJEITAR") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Teleporta para o NPC (Um pouco acima pra não bugar no chão)
local function teleportToModel(model)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
        root.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Zera velocidade pra não morrer de queda
    end
end

-- Teleporta para Coordenada (Emergência)
local function teleportToZone(pos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end

-- MODO PARASITA (Gruda no Raro)
local function startParasite(targetModel)
    CurrentTargetNPC = targetModel
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end

    StatusLbl.Text = "ALVO: " .. targetModel.Name
    StatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)

    -- Loop de Fixação (Heartbeat)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not getgenv().ExplorerActive or not targetModel.Parent or not CurrentTargetNPC then 
            connection:Disconnect()
            return 
        end
        -- Cola no NPC
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)

    -- Tenta Interagir
    local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then fireproximityprompt(prompt) end

    -- Espera Painel Abrir
    local sTime = os.time()
    repeat task.wait(0.1) until isQuestGuiOpen() or (os.time() - sTime > 3) or not getgenv().ExplorerActive

    -- Espera Você Aceitar (Painel Fechar)
    if isQuestGuiOpen() then
        StatusLbl.Text = "ESPERANDO VOCÊ..."
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        repeat task.wait(0.2) until not isQuestGuiOpen() or not getgenv().ExplorerActive
    end

    -- Solta e Reseta
    connection:Disconnect()
    CurrentTargetNPC = nil
    
    -- Ignora esse NPC por um tempo curto
    VisitedList[targetModel] = os.time()
    
    StatusLbl.Text = "RETOMANDO..."
    task.wait(0.5)
end

-- SCANNER
local function scanMap()
    local blueNPCs = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local parent = obj.Parent
            local model = parent and parent.Parent
            
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                local npcType = nil
                for _, child in pairs(obj:GetDescendants()) do
                    if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        local id = cleanID(child.Image)
                        if IDS[id] then npcType = IDS[id] break end
                    end
                end
                
                if npcType == "YELLOW" or npcType == "RED" then
                    -- Rara encontrada (Retorna prioridade se não visitada recentemente)
                    if not VisitedList[model] or (os.time() - VisitedList[model] > 5) then
                        return {type="RARE", model=model}
                    end
                elseif npcType == "BLUE" then
                    -- Azul encontrada
                    if not VisitedList[model] then
                        table.insert(blueNPCs, model)
                    end
                end
            end
        end
    end
    return {type="LIST", blues=blueNPCs}
end

-- LOOP PRINCIPAL
task.spawn(function()
    while task.wait() do
        -- Visual (ESP)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and model:IsA("Model") and not model:FindFirstChild("RedTeamESP") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            local id = cleanID(child.Image)
                            if IDS[id] == "YELLOW" then local h=Instance.new("Highlight", model); h.Name="RedTeamESP"; h.FillColor=Color3.fromRGB(255,215,0)
                            elseif IDS[id] == "RED" then local h=Instance.new("Highlight", model); h.Name="RedTeamESP"; h.FillColor=Color3.fromRGB(255,0,0) end
                        end
                    end
                end
            end
        end

        if not getgenv().ExplorerActive then continue end
        if CurrentTargetNPC then continue end -- Em modo parasita, não faz nada

        -- Verifica delay (Para não teleportar rápido demais)
        if (os.clock() - LastTeleportTime) < CONFIG.TeleportDelay then continue end

        local result = scanMap()

        if result.type == "RARE" then
            -- === ACHOU RARA ===
            LastTeleportTime = os.clock()
            startParasite(result.model)

        else
            -- === LISTA DE AZUIS ===
            local blues = result.blues
            
            if #blues > 0 then
                -- Tem NPC Azul novo por perto
                local target = blues[math.random(1, #blues)]
                
                StatusLbl.Text = "PULANDO... (" .. #blues .. ")"
                StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
                
                teleportToModel(target)
                VisitedList[target] = os.time() -- Marca como visitado
                LastTeleportTime = os.clock()
                
            else
                -- === NÃO TEM NPC (LISTA VAZIA) ===
                -- Verifica se estamos travados há muito tempo
                if (os.clock() - LastTeleportTime) > CONFIG.StuckTimeout then
                    
                    -- Tenta Limpar a Lista (Revisitar antigos)
                    if next(VisitedList) ~= nil then
                        StatusLbl.Text = "RESETANDO LISTA..."
                        VisitedList = {} -- Esquece quem visitou e tenta de novo
                        task.wait(0.5)
                    else
                        -- Se já limpou a lista e CONTINUA sem nada: MAPA VAZIO
                        -- Vamos para uma Zona de Emergência carregar chunks
                        StatusLbl.Text = "TROCANDO DE AREA..."
                        StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 0)
                        
                        local randomZone = SAFE_ZONES[math.random(1, #SAFE_ZONES)]
                        teleportToZone(randomZone)
                        
                        LastTeleportTime = os.clock() + 2 -- Dá 2 segundos pro mapa carregar
                    end
                end
            end
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().ExplorerActive = not getgenv().ExplorerActive
    if getgenv().ExplorerActive then
        ToggleBtn.Text = "DESLIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        VisitedList = {} -- Reseta lista ao ligar
        LastTeleportTime = 0
    else
        ToggleBtn.Text = "LIGAR EXPLORER"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
        CurrentTargetNPC = nil
    end
end)
