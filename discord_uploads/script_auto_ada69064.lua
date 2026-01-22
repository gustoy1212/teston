--[[
    📡 REAL-TIME LOGGER (OPTIMIZED)
    
    CORREÇÃO: 
    - Usa 'table.concat' para copiar, permitindo logs gigantes sem travar.
    - Focado em descobrir Portais e Prompts.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- 1. UI SETUP
local ScreenName = "RealTimeLogUI"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.Text = "📡 REAL-TIME LOGGER (FIXED)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.96, 0, 0.7, 0)
Scroll.Position = UDim2.new(0.02, 0, 0.12, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 2)

-- CONTROLES
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.85, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, pos, color, func)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.3, 0, 0.8, 0)
    btn.Position = UDim2.new(pos, 0, 0.1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.white
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.MouseButton1Click:Connect(func)
    return btn
end

-- LÓGICA
local LogData = {} -- Tabela para guardar os caminhos (muito mais leve)
local Connection = nil
local IsScanning = false

local function AddToLog(obj)
    -- Tenta pegar o caminho completo
    local success, path = pcall(function() return obj:GetFullName() end)
    
    if success and path then
        -- Filtra coisas inúteis (Sound, Debris) para não poluir
        if not path:match("Sound") and not path:match("Animation") then
            local fullPath = "game." .. path
            table.insert(LogData, fullPath)
            
            -- Visual (Só mostra os últimos 50 pra não lagar a tela, mas grava tudo na memória)
            if #LogData % 5 == 0 then -- Atualiza visual a cada 5 itens pra ser leve
                local label = Instance.new("TextLabel", Scroll)
                label.Size = UDim2.new(1, 0, 0, 20)
                label.BackgroundTransparency = 1
                label.Text = "  " .. obj.Name .. " (" .. obj.ClassName .. ")"
                label.TextColor3 = Color3.fromRGB(150, 255, 150)
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Font = Enum.Font.Code
                label.TextSize = 12
                
                if obj:IsA("ProximityPrompt") then
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                    label.Text = "  ⚡ PROMPT: " .. path
                end
            end
        end
    end
end

local ToggleBtn -- Referencia futura

local function ToggleScan()
    IsScanning = not IsScanning
    
    if IsScanning then
        ToggleBtn.Text = "MONITORAR: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        Connection = Workspace.DescendantAdded:Connect(function(obj)
            task.wait() -- Espera 1 frame pro objeto carregar propriedades
            if obj.Parent then
                if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("ProximityPrompt") then
                   AddToLog(obj)
                end
            end
        end)
    else
        ToggleBtn.Text = "MONITORAR: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        if Connection then Connection:Disconnect() end
    end
end

local function ClearLog()
    LogData = {}
    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end

local function CopyAll()
    if #LogData == 0 then return end
    
    -- A MÁGICA: table.concat é 1000x mais rápido que concatenar string
    local finalString = table.concat(LogData, "\n")
    setclipboard(finalString)
    
    Title.Text = "COPIADO " .. #LogData .. " ITENS! ✅"
    task.wait(2)
    Title.Text = "📡 REAL-TIME LOGGER (FIXED)"
end

-- Botões
ToggleBtn = CreateBtn("MONITORAR: OFF", 0.02, Color3.fromRGB(150, 0, 0), ToggleScan)
CreateBtn("LIMPAR LOG", 0.35, Color3.fromRGB(200, 100, 0), ClearLog)
CreateBtn("COPIAR TUDO", 0.68, Color3.fromRGB(0, 100, 200), CopyAll)