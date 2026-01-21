--[[
    🕵️‍♂️ OMNI-SCANNER (REAL-TIME SPY)
    
    OBJETIVO: Descobrir o segredo do ataque em tempo real.
    
    COMO USAR:
    1. Ative o Script.
    2. Ataque o ar ou um monstro manualmente.
    3. Veja o LOG aparecer na tela com os IDs e Nomes.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("OmniScannerUI") then CoreGui.OmniScannerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "OmniScannerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 300)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "🕵️‍♂️ OMNI-SCANNER (Ao Vivo)"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.Code
Title.BackgroundTransparency = 1

local LogScroll = Instance.new("ScrollingFrame", MainFrame)
LogScroll.Size = UDim2.new(1, -10, 0.75, 0)
LogScroll.Position = UDim2.new(0, 5, 0.1, 0)
LogScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.45, 0, 0.1, 0)
ClearBtn.Position = UDim2.new(0.05, 0, 0.88, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ClearBtn.Text = "LIMPAR LOG"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.45, 0, 0.1, 0)
ScanBtn.Position = UDim2.new(0.5, 0, 0.88, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ScanBtn.Text = "LIGAR ESCUTA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÃO DE LOG //
local function AddLog(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.Parent = LogScroll
    
    -- Auto Scroll
    LogScroll.CanvasPosition = Vector2.new(0, 9999)
end

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end)

-- // LÓGICA DE SPY //
local IsListening = false
local Connections = {}

local function StartSpy()
    local char = LocalPlayer.Character
    if not char then AddLog("Erro: Char não encontrado!", Color3.fromRGB(255, 0, 0)) return end
    local hum = char:WaitForChild("Humanoid")
    
    AddLog("--- INICIANDO ESCUTA ---", Color3.fromRGB(0, 255, 0))
    
    -- 1. DETECTOR DE ANIMAÇÃO
    local animConn = hum.AnimationPlayed:Connect(function(track)
        local id = track.Animation.AnimationId
        -- Filtra animações inúteis (andar/pular/idle)
        -- IDs comuns do Roblox para ignorar
        if not (id:match("180435571") or id:match("180435792") or id:match("507766388") or id:match("507766666")) then 
            AddLog("🎬 ANIM: " .. id, Color3.fromRGB(255, 255, 0))
            AddLog("   Speed: " .. track.Speed .. " | Loop: " .. tostring(track.Looped), Color3.fromRGB(255, 255, 150))
        end
    end)
    table.insert(Connections, animConn)
    
    -- 2. DETECTOR DE FERRAMENTA (TOOL)
    local toolConn = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            AddLog("🛠️ EQUIPOU: " .. child.Name, Color3.fromRGB(0, 200, 255))
            
            -- Ouve ativação
            child.Activated:Connect(function()
                AddLog("⚡ TOOL ACTIVATED!", Color3.fromRGB(0, 255, 255))
            end)
            
            -- Procura Remotes na ferramenta
            for _, obj in ipairs(child:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    AddLog("📡 REMOTE ACHEI: " .. obj.Name, Color3.fromRGB(255, 0, 255))
                end
            end
        end
    end)
    table.insert(Connections, toolConn)
    
    -- Verifica ferramenta atual
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        AddLog("🛠️ JÁ EQUIPADO: " .. currentTool.Name, Color3.fromRGB(0, 200, 255))
        currentTool.Activated:Connect(function()
            AddLog("⚡ TOOL ACTIVATED!", Color3.fromRGB(0, 255, 255))
        end)
    end
    
    -- 3. DETECTOR DE CLIQUES (INPUT)
    local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not processed then -- Se clicou no mundo e não num botão
                AddLog("👆 CLIQUE NA TELA DETECTADO", Color3.fromRGB(200, 200, 200))
            end
        end
    end)
    table.insert(Connections, inputConn)
end

local function StopSpy()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    Connections = {}
    AddLog("--- ESCUTA PARADA ---", Color3.fromRGB(255, 0, 0))
end

ScanBtn.MouseButton1Click:Connect(function()
    IsListening = not IsListening
    if IsListening then
        ScanBtn.Text = "PARAR"
        ScanBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StartSpy()
    else
        ScanBtn.Text = "LIGAR ESCUTA"
        ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StopSpy()
    end
end)