--[[ 
    RED TEAM TOOL: AUTO-FARM "E" INTERACTION
    Baseado no seu script visual + Automação de Movimento e Tecla E.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIGURAÇÃO =================
local CONFIG = {
    WalkSpeed = 22,       -- Velocidade para andar
    WanderDist = 50,      -- Distância que ele anda aleatório
    InteractDist = 8      -- Distância para apertar E
}

local IDS = {
    ["74232140704943"] = "BLUE",   -- Comum
    ["134433042638721"] = "YELLOW", -- Rara
    ["88108791549573"] = "RED"     -- Lendária
}

-- Estado do Bot
getgenv().FarmActive = false -- Começa desligado
local CurrentTarget = nil
local trackedNPCs = {} 

-- ================= PAINEL (LADO ESQUERDO) =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RedTeamAuto"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 90)
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0) -- Esquerda
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "AUTO-FARM (Tecla E)"
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0.5, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.Text = "DESLIGADO [OFF]"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Parent = MainFrame

-- ================= FUNÇÕES AUXILIARES =================

local function cleanID(str)
    return tostring(str):match("%d+") or "NIL"
end

local function playAlert()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://12221967"
    sound.Parent = SoundService
    sound.Volume = 2
    sound:Play()
    game.Debris:AddItem(sound, 2)
end

-- Tenta clicar no botão ACEITAR da GUI (Depois de apertar E)
local function tryAcceptQuest()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, btn in pairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                    local text = btn:IsA("TextButton") and btn.Text:upper() or ""
                    if string.find(text, "ACEITAR") then
                        -- Dispara clique
                        pcall(function()
                            for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                            for _, c in pairs(getconnections(btn.Activated)) do c:Fire() end
                        end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ================= VISUAL (SEU SCRIPT) =================

local function createBeam(model, color)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if root:FindFirstChild("RedTeamBeamAtt") then return end

    local attNPC = Instance.new("Attachment", root)
    attNPC.Name = "RedTeamBeamAtt"

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local attPlayer = myRoot:FindFirstChild("RedTeamPlayerAtt") or Instance.new("Attachment", myRoot)
    attPlayer.Name = "RedTeamPlayerAtt"

    local beam = Instance.new("Beam", root)
    beam.Name = "RedTeamTracker"
    beam.Attachment0 = attPlayer
    beam.Attachment1 = attNPC
    beam.Color = ColorSequence.new(color)
    beam.FaceCamera = true
    beam.Width0 = 0.5; beam.Width1 = 0.5
    beam.Texture = "rbxassetid://446111271"
    beam.TextureSpeed = 2; beam.TextureLength = 10
end

local function applyTracker(model, color, text, isRare)
    if model:FindFirstChild("RedTeamESP") then return end

    local h = Instance.new("Highlight", model)
    h.Name = "RedTeamESP"
    h.FillColor = color
    h.OutlineColor = Color3.new(0,0,0)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    if isRare then
        h.FillTransparency = 0.1
        h.OutlineTransparency = 0
        createBeam(model, color)
        if not trackedNPCs[model] then playAlert(); trackedNPCs[model] = true end
    else
        h.FillTransparency = 0.8
        h.OutlineTransparency = 0.8
    end

    local bg = Instance.new("BillboardGui", h)
    bg.Adornee = model:FindFirstChild("Head") or model.PrimaryPart
    bg.Size = UDim2.new(0, 200, 0, 70)
    bg.StudsOffset = Vector3.new(0, 5, 0)
    bg.AlwaysOnTop = true
    
    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 20
    tl.Text = text
end

-- ================= LÓGICA DE AUTO-FARM =================

local function findTarget()
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closest = nil
    local minDist = 99999
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Quest Simbol" then
            local parent = obj.Parent
            local model = parent and parent.Parent
            
            if model and model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                -- Checa IDs
                local isPriority = false
                for _, child in pairs(obj:GetDescendants()) do
                    if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        local id = cleanID(child.Image)
                        -- SÓ MARCA COMO ALVO SE FOR AMARELA OU VERMELHA
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

-- Loop Principal de Automação
task.spawn(function()
    while task.wait(0.2) do
        -- 1. Roda o Scanner Visual (Seu script original)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Quest Simbol" then
                local model = obj.Parent.Parent
                if model and model:IsA("Model") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            local id = cleanID(child.Image)
                            if IDS[id] == "YELLOW" then applyTracker(model, Color3.fromRGB(255, 215, 0), "★ RARA ★", true)
                            elseif IDS[id] == "RED" then applyTracker(model, Color3.fromRGB(255, 0, 0), "!!! LENDÁRIA !!!", true)
                            elseif IDS[id] == "BLUE" then applyTracker(model, Color3.fromRGB(0, 100, 255), "Comum", false) end
                        end
                    end
                end
            end
        end

        -- 2. Se o Botão estiver LIGADO
        if getgenv().FarmActive and LocalPlayer.Character then
            local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if Hum and Root then
                Hum.WalkSpeed = CONFIG.WalkSpeed
                
                -- Tenta Aceitar GUI primeiro
                if tryAcceptQuest() then
                    task.wait(1)
                    continue
                end

                -- Busca Alvo
                local target = findTarget()
                if target then
                    local targetPos = target.HumanoidRootPart.Position
                    local dist = (Root.Position - targetPos).Magnitude
                    
                    if dist > CONFIG.InteractDist then
                        -- Anda até o NPC
                        Hum:MoveTo(targetPos)
                        if Root.AssemblyLinearVelocity.Magnitude < 1 then Hum.Jump = true end -- Destravar
                    else
                        -- Chegou perto: PARA e INTERAGE
                        Hum:MoveTo(Root.Position)
                        
                        -- APERTAR "E" (ProximityPrompt)
                        local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            fireproximityprompt(prompt) -- Função mágica que aperta E sem teclado
                        end
                        task.wait(0.5)
                    end
                else
                    -- Sem alvo: Vagar aleatoriamente
                    local rand = Vector3.new(math.random(-50,50), 0, math.random(-50,50))
                    Hum:MoveTo(Root.Position + rand)
                    task.wait(1)
                end
            end
        end
    end
end)

-- Botão Toggle
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().FarmActive = not getgenv().FarmActive
    if getgenv().FarmActive then
        ToggleBtn.Text = "LIGADO [ON]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ToggleBtn.Text = "DESLIGADO [OFF]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        if LocalPlayer.Character then -- Freia o boneco
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
        end
    end
end)
