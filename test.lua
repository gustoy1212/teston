--[[ 
    RED TEAM TOOL: TELEPORT HUNTER (ANTI-KICK)
    - Pula em NPCs Azuis (1.5s delay).
    - Para instantaneamente na Amarela/Vermelha.
    - Evita repetição de NPCs comuns.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    TeleportDelay = 1.5, -- Tempo para evitar kick
    IgnoreTime = 60,     -- Tempo que ele ignora um azul visitado
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW", -- Rara
    ["88108791549573"] = "RED"     -- Lendária
}

-- Estado
getgenv().TeleportActive = false
local VisitedList = {} -- Lista negra temporária

-- ================= INTERFACE =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportHunterUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 110)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: AGUARDANDO"
StatusLbl.Size = UDim2.new(1, 0, 0.3, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 14
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.Text = "INICIAR CAÇADA"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

-- Função segura de teleporte
local function safeTeleport(targetModel)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        -- Teleporta um pouco acima para não bugar no chão
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 0)
    end
end

-- Scanner de Mapa
local function scanMap()
    local blueNPCs = {}
    local rareNPC = nil
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local parent = obj.Parent
            local model = parent and parent.Parent
            
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                -- Identifica Tipo
                local npcType = nil
                for _, child in pairs(obj:GetDescendants()) do
                    if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        local id = cleanID(child.Image)
                        if IDS[id] then npcType = IDS[id] break end
                    end
                end
                
                -- Lógica de Prioridade
                if npcType == "YELLOW" or npcType == "RED" then
                    -- Se achar Rara, retorna imediatamente
                    return {type="RARE", model=model}
                elseif npcType == "BLUE" then
                    -- Se for azul e não foi visitado recentemente, adiciona na lista
                    if not VisitedList[model] or (os.time() - VisitedList[model] > CONFIG.IgnoreTime) then
                        table.insert(blueNPCs, model)
                    end
                end
            end
        end
    end
    
    return {type="BLUE_LIST", list=blueNPCs}
end

-- Desenha ESP (Visual)
task.spawn(function()
    while task.wait(1) do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and model:IsA("Model") and not model:FindFirstChild("RedTeamESP") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            local id = cleanID(child.Image)
                            if IDS[id] == "YELLOW" then 
                                local h = Instance.new("Highlight", model); h.Name="RedTeamESP"; h.FillColor=Color3.fromRGB(255,215,0)
                            elseif IDS[id] == "RED" then 
                                local h = Instance.new("Highlight", model); h.Name="RedTeamESP"; h.FillColor=Color3.fromRGB(255,0,0)
                            elseif IDS[id] == "BLUE" then 
                                local h = Instance.new("Highlight", model); h.Name="RedTeamESP"; h.FillColor=Color3.fromRGB(0,100,255); h.FillTransparency=0.8
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- LOOP PRINCIPAL DE TELEPORTE
task.spawn(function()
    while task.wait() do
        if not getgenv().TeleportActive then continue end
        
        local result = scanMap()
        
        if result.type == "RARE" then
            -- === ACHOU RARA ===
            StatusLbl.Text = "ACHEI! ESPERANDO VOCÊ..."
            StatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            
            safeTeleport(result.model)
            
            -- Desliga automático para você clicar
            getgenv().TeleportActive = false
            ToggleBtn.Text = "PRÓXIMO (CONTINUAR)"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 150)
            
            -- Adiciona na lista de visitados pra não voltar nele logo em seguida
            VisitedList[result.model] = os.time() + 120 -- Ignora por 2 min
            
            -- Aperta E automático (Opcional, remove se quiser clicar manual)
            local prompt = result.model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
            
        elseif result.type == "BLUE_LIST" then
            -- === SÓ TEM AZUL ===
            local list = result.list
            
            if #list > 0 then
                -- Pega um azul aleatório ou o mais próximo
                local target = list[math.random(1, #list)]
                
                StatusLbl.Text = "PULANDO EM AZUIS... ("..#list..")"
                StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
                
                safeTeleport(target)
                VisitedList[target] = os.time() -- Marca como visitado
                
                -- Espera 1.5s pra não tomar kick
                task.wait(CONFIG.TeleportDelay)
            else
                -- Acabaram os azuis novos, limpa a lista pra revisitar
                StatusLbl.Text = "REINICIANDO LISTA..."
                VisitedList = {}
                task.wait(1)
            end
        end
    end
end)

-- Botão Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().TeleportActive = not getgenv().TeleportActive
    
    if getgenv().TeleportActive then
        ToggleBtn.Text = "PARAR CAÇADA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR CAÇADA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PAUSADO"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)
