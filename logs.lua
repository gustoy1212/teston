--[[ 
    OMNI-SCANNER V3 (SMART LITE EDITION)
    - Anti-Lag: Filtra partes inúteis (Welds, Attachments).
    - Smart Log: Registra Modelos inteiros ao invés de peças soltas.
    - Copy-Fix: Sistema de cópia otimizado para não travar o emulador.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. LIMPEZA E UI
local ScreenName = "OmniScannerV3"
if getgenv and getgenv().gethui then 
    local hui = getgenv().gethui()
    if hui:FindFirstChild(ScreenName) then hui[ScreenName]:Destroy() end
elseif CoreGui:FindFirstChild(ScreenName) then 
    CoreGui[ScreenName]:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -100, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "  OMNI-SCANNER V3 (LITE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.Code
Title.TextSize = 14

-- 2. ÁREA DE LOGS (TEXTBOX É MAIS LEVE QUE BOTÕES)
local LogBox = Instance.new("TextBox", MainFrame)
LogBox.Size = UDim2.new(1, -20, 0.75, 0)
LogBox.Position = UDim2.new(0, 10, 0.1, 0)
LogBox.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
LogBox.TextColor3 = Color3.fromRGB(200, 200, 200)
LogBox.TextXAlignment = Enum.TextXAlignment.Left
LogBox.TextYAlignment = Enum.TextYAlignment.Top
LogBox.Font = Enum.Font.Code
LogBox.TextSize = 12
LogBox.TextEditable = false
LogBox.ClearTextOnFocus = false
LogBox.TextWrapped = false -- Melhor performance sem wrap
LogBox.MultiLine = true
LogBox.Text = "-- LOGS INICIADOS --\n"

-- 3. SISTEMA DE LOGS INTELIGENTE
local Logs = {}
local MaxLogs = 200 -- Mantém apenas os ultimos 200 na tela para não travar

-- Classes para IGNORAR (Isso salva seu PC/Celular)
local BlacklistClasses = {
    ["Part"] = true, ["MeshPart"] = true, ["Weld"] = true, ["Motor6D"] = true,
    ["Attachment"] = true, ["Bone"] = true, ["Animation"] = true, ["AnimationTrack"] = true,
    ["Sound"] = true, ["ParticleEmitter"] = true, ["Trail"] = true, ["WrapTarget"] = true,
    ["BodyColors"] = true, ["Decal"] = true, ["Texture"] = true
}

local function UpdateLogUI()
    -- Junta apenas os ultimos logs para exibir
    local displayStr = ""
    local count = #Logs
    local start = math.max(1, count - 50) -- Mostra só as ultimas 50 linhas na tela pra ser rápido
    
    for i = start, count do
        displayStr = displayStr .. Logs[i] .. "\n"
    end
    LogBox.Text = displayStr
end

local function Log(prefix, obj, extra)
    local timestamp = os.date("%X")
    local name = (typeof(obj) == "Instance") and obj.Name or tostring(obj)
    local path = (typeof(obj) == "Instance") and obj:GetFullName() or "N/A"
    
    local entry = string.format("[%s] [%s] %s | %s", timestamp, prefix, name, extra or "")
    
    table.insert(Logs, entry)
    -- Não deletamos do histórico (Logs) para poder copiar tudo, 
    -- mas a UI só mostra o final.
    
    UpdateLogUI()
end

-- 4. MONITORAMENTO INTELIGENTE

-- Monitora GUIs (Janelas abrindo)
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
PlayerGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") then
        Log("GUI", child, "Abriu nova janela")
        -- Monitora botões dentro da GUI nova
        child.DescendantAdded:Connect(function(d)
            if d:IsA("TextButton") or d:IsA("ImageButton") then
                Log("BTN", d, "Botão detectado: "..(d:IsA("TextButton") and d.Text or "Img"))
            end
        end)
    end
end)

-- Monitora Cliques do Mouse (Detecta o que você clica)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mouse = Players.LocalPlayer:GetMouse()
        if mouse.Target then
            local target = mouse.Target
            -- Tenta achar o Model pai (ex: Clicou no pé do Goblin -> Mostra Goblin)
            local model = target:FindFirstAncestorOfClass("Model") or target
            
            -- Evita spam de clicar no chão
            if model.Name ~= "Baseplate" and not BlacklistClasses[model.ClassName] then
                Log("CLICK", model, "Você interagiu com isso!")
            end
        end
    end
end)

-- Monitora Workspace (Apenas coisas importantes)
Workspace.DescendantAdded:Connect(function(descendant)
    -- FILTRO PESADO: Se for classe inútil, ignora
    if BlacklistClasses[descendant.ClassName] then return end
    
    -- FILTRO DE CAMINHO: Ignora coisas dentro de 'Instanced' se for peça solta
    if descendant:GetFullName():find("Instanced") and descendant:IsA("BasePart") then return end

    -- Se for um MODELO NOVO ou PASTA (Ex: Mobs, NPCs)
    if descendant:IsA("Model") or descendant:IsA("Folder") then
        Log("NEW", descendant, "Novo Objeto Spawnado")
        
        -- Verifica se tem ClickDetector ou Prompt dentro dele
        descendant.DescendantAdded:Connect(function(sub)
            if sub:IsA("ClickDetector") or sub:IsA("ProximityPrompt") then
                Log("INTERACT", sub, "Interação encontrada dentro de: " .. descendant.Name)
            end
        end)
    
    -- Se for ferramenta
    elseif descendant:IsA("Tool") then
        Log("TOOL", descendant, "Item/Ferramenta")
    end
end)

-- Monitora EntityFolder (Específico pro seu jogo)
local EntityFolder = Workspace:FindFirstChild("EntityFolder")
if EntityFolder then
    EntityFolder.ChildAdded:Connect(function(mob)
        Log("MOB", mob, "Inimigo Spawnado na EntityFolder")
    end)
end

-- 5. BOTÕES DE CONTROLE
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.85, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, posScale, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.3, 0, 0.8, 0)
    btn.Position = UDim2.new(posScale, 0, 0.1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
end

CreateBtn("COPIAR TUDO", 0.02, Color3.fromRGB(0, 150, 200), function()
    local fullLog = table.concat(Logs, "\n")
    if setclipboard then
        setclipboard(fullLog)
        Log("SYSTEM", "Logs copiados!", "Tamanho: " .. #fullLog)
    else
        Log("ERROR", "Seu executor não suporta setclipboard", "")
    end
end)

CreateBtn("LIMPAR", 0.35, Color3.fromRGB(150, 50, 50), function()
    Logs = {}
    LogBox.Text = ""
    Log("SYSTEM", "Logs limpos", "")
end)

CreateBtn("DEEP SCAN", 0.68, Color3.fromRGB(100, 50, 150), function()
    Log("SYSTEM", "Iniciando Scan Manual...", "")
    -- Scan manual de coisas próximas
    local myPos = Players.LocalPlayer.Character.HumanoidRootPart.Position
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            if (v.HumanoidRootPart.Position - myPos).Magnitude < 50 then
                 Log("SCAN", v, "Objeto próximo detectado")
            end
        end
    end
end)

-- Notificação
game.StarterGui:SetCore("SendNotification", {Title = "Omni-Scanner V3", Text = "Lite Edition Ativado!", Duration = 5})
