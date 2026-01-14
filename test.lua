--[[ 
    RED TEAM TOOL: AUTO-FARM "UBER" MODE
    - Leva até o NPC e PARA.
    - Espera você aceitar manualmente.
    - Retoma a busca assim que o painel fecha.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    WalkSpeed = 22,       
    InteractDist = 3, -- Chega MUITO perto (dentro do NPC)
}

local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW", 
    ["88108791549573"] = "RED"     
}

-- Estado do Bot
getgenv().UberActive = false 
local IgnoreList = {} -- Lista de NPCs que já visitamos recentemente

-- ================= PAINEL =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UberBotUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 100)
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "AGUARDANDO..."
StatusLbl.Size = UDim2.new(1, 0, 0.3, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 14
StatusLbl.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleBtn.Text = "LIGAR BOT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 18
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

-- Verifica se tem algum painel de missão aberto na tela
local function isQuestPanelOpen()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local text = btn:IsA("TextButton") and btn.Text:upper() or ""
                    -- Se tem botão aceitar ou recusar visível, o painel tá aberto
                    if string.find(text, "ACEITAR") or string.find(text, "REJEITAR") or string.find(text, "RECUSAR") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Função para encontrar o alvo (Ignorando os recentes)
local function findTarget()
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = 99999
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local parent = obj.Parent
            local model = parent and parent.Parent
            
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                -- Se esse NPC está na lista de ignorados (já visitado), pula ele
                if IgnoreList[model] and (os.time() - IgnoreList[model] < 20) then
                    continue -- Espera 20 segundos antes de voltar no mesmo
                end

                local isPriority = false
                for _, child in pairs(obj:GetDescendants()) do
                    if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        local id = cleanID(child.Image)
                        if IDS[id] == "YELLOW" or IDS[id] == "RED" then
                            isPriority = true
                            break
                        end
                    end
                end
                
                if isPriority then
                    local dist = (model.HumanoidRootPart.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = model
                    end
                end
            end
        end
    end
    return closest
end

-- Lógica Principal
task.spawn(function()
    while task.wait(0.1) do
        -- Visual (ESP Beam) continua rodando sempre
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and model:IsA("Model") and not model:FindFirstChild("RedTeamESP") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            local id = cleanID(child.Image)
                            if IDS[id] == "YELLOW" then 
                                local h = Instance.new("Highlight", model)
                                h.Name = "RedTeamESP"; h.FillColor = Color3.fromRGB(255, 215, 0)
                            elseif IDS[id] == "RED" then 
                                local h = Instance.new("Highlight", model)
                                h.Name = "RedTeamESP"; h.FillColor = Color3.fromRGB(255, 0, 0)
                            end
                        end
                    end
                end
            end
        end

        -- Se o Bot estiver DESLIGADO, não faz nada de movimento
        if not getgenv().UberActive then continue end
        
        local Char = LocalPlayer.Character
        local Hum = Char and Char:FindFirstChild("Humanoid")
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        if not Hum or not Root then continue end

        Hum.WalkSpeed = CONFIG.WalkSpeed

        -- 1. VERIFICA SE O PAINEL ESTÁ ABERTO (VOCÊ ESTÁ LENDO/ACEITANDO)
        if isQuestPanelOpen() then
            StatusLbl.Text = "ESPERANDO VOCÊ..."
            StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
            -- PARA TUDO! Fica parado esperando você clicar
            Hum:MoveTo(Root.Position)
            continue
        end

        -- 2. BUSCA NOVO ALVO
        local target = findTarget()

        if target then
            StatusLbl.Text = "INDO: " .. target.Name
            StatusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)

            local targetPos = target.HumanoidRootPart.Position
            local dist = (Root.Position - targetPos).Magnitude
            
            if dist > CONFIG.InteractDist then
                -- Vai até lá
                Hum:MoveTo(targetPos)
                if Root.AssemblyLinearVelocity.Magnitude < 0.5 then Hum.Jump = true end
            else
                -- CHEGOU NO LOCAL (DENTRO DO NPC)
                Hum:MoveTo(Root.Position) -- Freia bruscamente
                
                -- Aperta E
                local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    fireproximityprompt(prompt)
                end
                
                -- Adiciona na lista de ignorados temporários para não ficar preso nesse NPC
                -- Só adiciona se o painel abrir na próxima checagem
                IgnoreList[target] = os.time()
                task.wait(0.5) 
            end
        else
            -- 3. MODO VAGAR (Nenhuma Rara por perto)
            StatusLbl.Text = "PROCURANDO..."
            StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
            
            local rand = Vector3.new(math.random(-40,40), 0, math.random(-40,40))
            Hum:MoveTo(Root.Position + rand)
            task.wait(1)
        end
    end
end)

-- Botão
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().UberActive = not getgenv().UberActive
    if getgenv().UberActive then
        ToggleBtn.Text = "DESLIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "PARADO"
        if LocalPlayer.Character then
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
        end
    end
end)
