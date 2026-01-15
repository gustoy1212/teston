--[[ 
    RED TEAM TOOL: TELEPORT PARASITE (AUTO-RESUME)
    - Pula em Azuis.
    - Gruda (Float) em Raras/Lendárias.
    - Retoma a caçada assim que você aceita a missão (Fecha o GUI).
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.5, -- Delay entre pulos nos azuis (Anti-Kick)
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW", -- Rara
    ["88108791549573"] = "RED"     -- Lendária
}

-- Estado
getgenv().ParasiteActive = false
local VisitedList = {} 
local CurrentTargetNPC = nil -- NPC que estamos grudados agora

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ParasiteUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 90)
MainFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: PARADO"
StatusLbl.Size = UDim2.new(1, 0, 0.4, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 14
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.Text = "LIGAR PARASITA"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

-- Verifica se a GUI de missão está aberta na tela
local function isQuestGuiOpen()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local text = btn:IsA("TextButton") and btn.Text:upper() or ""
                    -- Palavras-chave do painel de missão
                    if string.find(text, "ACEITAR") or string.find(text, "REJEITAR") or string.find(text, "RECUSAR") or string.find(text, "XP") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Teleporte Simples (Para Azuis)
local function simpleTeleport(targetModel)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 0)
    end
end

-- Função "Parasita" (Gruda no NPC Raro)
local function stickToTarget(targetModel)
    CurrentTargetNPC = targetModel
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end

    StatusLbl.Text = "PARASITA: " .. targetModel.Name
    StatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)

    -- Loop de Grudar (Heartbeat)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not getgenv().ParasiteActive or not targetModel.Parent then 
            connection:Disconnect() 
            return 
        end
        
        -- Atualiza Posição (Cola no NPC)
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame -- Fica exatamente dentro dele
            root.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Não cai
        end
    end)

    -- Tenta abrir o painel (Aperta E)
    local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        fireproximityprompt(prompt)
    end

    -- === ESPERA INTELIGENTE ===
    -- 1. Espera o Painel Abrir (Timeout de 3s caso falhe)
    local sTime = os.time()
    repeat task.wait(0.1) until isQuestGuiOpen() or (os.time() - sTime > 3) or not getgenv().ParasiteActive

    -- 2. Espera o Painel FECHAR (Significa que você aceitou ou recusou)
    if isQuestGuiOpen() then
        StatusLbl.Text = "AGUARDANDO VOCÊ..."
        StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
        repeat task.wait(0.2) until not isQuestGuiOpen() or not getgenv().ParasiteActive
    end

    -- Solta o NPC
    connection:Disconnect()
    CurrentTargetNPC = nil
    
    -- Marca como visitado pra não voltar nele imediatamente
    VisitedList[targetModel] = os.time()
    
    StatusLbl.Text = "RETOMANDO CAÇADA..."
    StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    task.wait(0.5)
end

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
                    -- Se já visitamos esse raro nos últimos 10s, ignora (pra dar tempo de você sair)
                    if not VisitedList[model] or (os.time() - VisitedList[model] > 10) then
                        return {type="RARE", model=model}
                    end
                elseif npcType == "BLUE" then
                    -- Azul que não visitamos nos últimos 60s
                    if not VisitedList[model] or (os.time() - VisitedList[model] > 60) then
                        table.insert(blueNPCs, model)
                    end
                end
            end
        end
    end
    return {type="BLUE_LIST", list=blueNPCs}
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait() do
        -- Visual ESP (Roda sempre)
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

        if not getgenv().ParasiteActive then continue end
        if CurrentTargetNPC then continue end -- Se já tá grudado, não escaneia

        local result = scanMap()

        if result.type == "RARE" then
            -- === MODO PARASITA ATIVADO ===
            stickToTarget(result.model)
            
        elseif result.type == "BLUE_LIST" then
            -- === MODO GAFANHOTO ===
            local list = result.list
            if #list > 0 then
                local target = list[math.random(1, #list)]
                StatusLbl.Text = "BUSCANDO... ("..#list.." Azuis)"
                StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
                
                simpleTeleport(target)
                VisitedList[target] = os.time()
                task.wait(CONFIG.TeleportDelay)
            else
                StatusLbl.Text = "ESCANEANDO AREA..."
                task.wait(1)
            end
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().ParasiteActive = not getgenv().ParasiteActive
    if getgenv().ParasiteActive then
        ToggleBtn.Text = "DESLIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR PARASITA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
        CurrentTargetNPC = nil -- Solta qualquer NPC
    end
end)
