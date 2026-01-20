--[[
    🕵️‍♂️ INTERACTION SCANNER (TECLA G / PROXIMITY)
    
    OBJETIVO:
    - Encontrar "ProximityPrompts" (A bolinha de apertar G/E).
    - Testar se conseguimos ativar ela via script.
    
    COMO USAR:
    1. Chegue perto do NPC.
    2. Clique em "ESCANEAR INTERAÇÃO (G)".
    3. Se aparecer algo na lista, clique no botão "TESTAR (FIRE)" ao lado.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("PromptScanner") then CoreGui.PromptScanner:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PromptScanner"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕵️‍♂️ SCANNER DE TECLA 'G' (Proximity)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold

-- LISTA
local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(0.95, 0, 0.65, 0)
ScrollFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 5)

-- BOTÃO SCAN
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
ScanBtn.Text = "🔍 PROCURAR BOTÃO DE INTERAGIR"
ScanBtn.TextColor3 = Color3.WHITE
ScanBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //
local function GetPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

local function CreateLog(prompt)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.Parent = ScrollFrame

    -- Nome do Objeto Pai (O NPC ou a Parte)
    local lblName = Instance.new("TextLabel", frame)
    lblName.Size = UDim2.new(0.7, 0, 0, 20)
    lblName.Position = UDim2.new(0, 5, 0, 0)
    lblName.Text = "Parent: " .. prompt.Parent.Name
    lblName.TextColor3 = Color3.fromRGB(0, 255, 255)
    lblName.TextXAlignment = Enum.TextXAlignment.Left
    lblName.BackgroundTransparency = 1
    lblName.Font = Enum.Font.GothamBold

    -- Informações da Tecla
    local lblInfo = Instance.new("TextLabel", frame)
    lblInfo.Size = UDim2.new(0.7, 0, 0, 20)
    lblInfo.Position = UDim2.new(0, 5, 0, 20)
    lblInfo.Text = "Tecla: " .. tostring(prompt.KeyboardKeyCode):gsub("Enum.KeyCode.", "") .. " | Hold: " .. prompt.HoldDuration .. "s"
    lblInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    lblInfo.TextXAlignment = Enum.TextXAlignment.Left
    lblInfo.BackgroundTransparency = 1
    
    -- Botão de Teste (Fire)
    local TestBtn = Instance.new("TextButton", frame)
    TestBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
    TestBtn.Position = UDim2.new(0.72, 0, 0.1, 0)
    TestBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    TestBtn.Text = "TESTAR (FIRE)"
    TestBtn.TextColor3 = Color3.WHITE
    TestBtn.Font = Enum.Font.GothamBold
    
    -- Função de Teste
    TestBtn.MouseButton1Click:Connect(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            TestBtn.Text = "ATIVADO!"
            wait(1)
            TestBtn.Text = "TESTAR (FIRE)"
        else
            TestBtn.Text = "SEU EXECUTOR NÃO SUPORTA"
            TestBtn.TextSize = 8
        end
    end)
    
    -- Caminho (Path)
    local lblPath = Instance.new("TextBox", frame)
    lblPath.Size = UDim2.new(0.7, 0, 0, 20)
    lblPath.Position = UDim2.new(0, 5, 0, 40)
    lblPath.Text = GetPath(prompt)
    lblPath.TextColor3 = Color3.fromRGB(100, 100, 100)
    lblPath.TextXAlignment = Enum.TextXAlignment.Left
    lblPath.BackgroundTransparency = 1
    lblPath.ClearTextOnFocus = false
    lblPath.TextEditable = false
end

-- // ESCANEAMENTO //
local function Scan()
    -- Limpa
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char.PrimaryPart.Position
    
    local foundCount = 0
    
    -- Procura ProximityPrompts num raio de 25 studs
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            -- Checa distância se o parent for uma parte
            local parentPart = v.Parent
            if parentPart:IsA("BasePart") or (parentPart:IsA("Model") and parentPart.PrimaryPart) then
                local pos = parentPart:IsA("BasePart") and parentPart.Position or parentPart.PrimaryPart.Position
                if (pos - myPos).Magnitude < 25 then
                    CreateLog(v)
                    foundCount = foundCount + 1
                end
            end
        end
    end
    
    if foundCount == 0 then
        ScanBtn.Text = "NADA ENCONTRADO (Chegue mais perto)"
    else
        ScanBtn.Text = "ENCONTRADO(S): " .. foundCount
    end
    task.wait(2)
    ScanBtn.Text = "🔍 PROCURAR BOTÃO DE INTERAGIR"
end

ScanBtn.MouseButton1Click:Connect(Scan)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)