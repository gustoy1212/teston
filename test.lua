--[[ 
    RED TEAM TOOL: CITY ROAMER (V4 - GLOBAL MAP)
    - Waypoints Globais (Cobre o mapa todo).
    - Slider de Velocidade.
    - Perseguição "Velcro" (Cola no NPC).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local IDS = {
    ["74232140704943"] = "BLUE",   
    ["134433042638721"] = "YELLOW", -- Rara
    ["88108791549573"] = "RED"     -- Lendária
}

-- PONTOS DE PATRULHA (Baseado no seu mapa: Cantos e Centro)
-- O Bot vai viajar entre esses pontos para garantir que carregue o mapa todo
local WAYPOINTS = {
    Vector3.new(0, 0, 0),         -- Centro (Spawn)
    Vector3.new(800, 0, 800),     -- Canto Superior Direito (Goblin?)
    Vector3.new(-800, 0, 800),    -- Canto Superior Esquerdo
    Vector3.new(-800, 0, -800),   -- Canto Inferior Esquerdo (Insect?)
    Vector3.new(800, 0, -800),    -- Canto Inferior Direito
    Vector3.new(0, 0, 1000),      -- Extremo Norte
    Vector3.new(0, 0, -1000)      -- Extremo Sul
}

-- Estado
getgenv().BotActive = false
local CurrentSpeed = 22
local CurrentWaypointIndex = 1
local IgnoreList = {} 

-- ================= INTERFACE (ROXO/CIANO) =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CityRoamerUI"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 140)
MainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30) -- Roxo Escuro
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Neon
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "CITY ROAMER V4"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.Parent = MainFrame

-- Status Text
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text = "STATUS: PARADO"
StatusLbl.Size = UDim2.new(1, 0, 0.2, 0)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 255) -- Magenta
StatusLbl.Font = Enum.Font.Code
StatusLbl.Parent = MainFrame

-- Botão Toggle
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.Text = "LIGAR BOT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

-- Slider de Velocidade (Input Box simples pra não bugar no emulador)
local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0.9, 0, 0.2, 0)
SpeedInput.Position = UDim2.new(0.05, 0, 0.8, 0)
SpeedInput.Text = "Speed: 22"
SpeedInput.BackgroundColor3 = Color3.fromRGB(50, 0, 50)
SpeedInput.TextColor3 = Color3.fromRGB(0, 255, 255)
SpeedInput.Parent = MainFrame

SpeedInput.FocusLost:Connect(function()
    local num = tonumber(string.match(SpeedInput.Text, "%d+"))
    if num then
        CurrentSpeed = num
        SpeedInput.Text = "Speed: " .. num
    else
        SpeedInput.Text = "Speed: " .. CurrentSpeed
    end
end)

-- ================= FUNÇÕES DO BOT =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function isQuestPanelOpen()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local text = btn:IsA("TextButton") and btn.Text:upper() or ""
                    if string.find(text, "ACEITAR") or string.find(text, "REJEITAR") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function findTarget()
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = 99999
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local parent = obj.Parent
            local model = parent and parent.Parent
            
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                -- Ignora recentes
                if IgnoreList[model] and (os.time() - IgnoreList[model] < 20) then continue end

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

-- Movimento Inteligente (Vai pro próximo Waypoint se travar)
local function moveTowards(targetPos)
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root then return end

    Hum:MoveTo(targetPos)
    
    -- Destrava se ficar parado
    if Root.AssemblyLinearVelocity.Magnitude < 0.2 then
        Hum.Jump = true
        -- Se pular não resolver, muda o waypoint para forçar nova rota
        if math.random(1, 20) == 1 then
            CurrentWaypointIndex = (CurrentWaypointIndex % #WAYPOINTS) + 1
        end
    end
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    while task.wait() do -- Loop rápido
        -- 1. Desenha ESP (Sempre ativo)
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
                            end
                        end
                    end
                end
            end
        end

        -- Se desligado, pula
        if not getgenv().BotActive then continue end
        
        local Char = LocalPlayer.Character
        if not Char then continue end
        local Hum = Char:FindFirstChild("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        if not Hum or not Root then continue end

        -- Aplica Velocidade
        Hum.WalkSpeed = CurrentSpeed

        -- 2. PAUSA SE ESTIVER COM MENU ABERTO
        if isQuestPanelOpen() then
            StatusLbl.Text = "AGUARDANDO VOCÊ..."
            Hum:MoveTo(Root.Position)
            continue
        end

        -- 3. BUSCA ALVO
        local target = findTarget()

        if target then
            StatusLbl.Text = "CAÇANDO: " .. target.Name
            local targetPos = target.HumanoidRootPart.Position
            local dist = (Root.Position - targetPos).Magnitude

            if dist > 3 then
                -- PERSEGUIÇÃO AGRESSIVA
                Hum:MoveTo(targetPos)
            else
                -- CHEGOU NO ALVO (COLA NELE)
                Hum:MoveTo(Root.Position) -- Para movimento normal
                
                -- Força posição (Anti-Lag do NPC)
                Root.CFrame = CFrame.new(Root.Position, targetPos) -- Olha pro NPC
                
                -- Aperta E
                local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then fireproximityprompt(prompt) end
                
                IgnoreList[target] = os.time()
                task.wait(0.2)
            end
        else
            -- 4. PATRULHA GLOBAL (WAYPOINTS)
            StatusLbl.Text = "PATRULHANDO CIDADE..."
            
            local dest = WAYPOINTS[CurrentWaypointIndex]
            local distToWaypoint = (Root.Position - dest).Magnitude
            
            if distToWaypoint < 20 then
                -- Chegou no ponto, vai pro próximo
                CurrentWaypointIndex = (CurrentWaypointIndex % #WAYPOINTS) + 1
            else
                moveTowards(dest)
            end
        end
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().BotActive = not getgenv().BotActive
    if getgenv().BotActive then
        ToggleBtn.Text = "DESLIGAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        StatusLbl.Text = "PARADO"
        if LocalPlayer.Character then
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
        end
    end
end)
