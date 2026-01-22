-- [[ OMNI-SCANNER V2.5: DELTA FIX ]] --
-- Leve, sem travar ataque e SEM REPETIÇÕES

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- UI SETUP
local ScreenName = "OmniScan_NoRepeat"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 250)
MainFrame.Position = UDim2.new(0.5, -225, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
Title.Text = "🛡️ SCANNER (ANTI-SPAM MODE)"
Title.TextColor3 = Color3.fromRGB(255, 100, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local ScrollList = Instance.new("ScrollingFrame", MainFrame)
ScrollList.Size = UDim2.new(0.95, 0, 0.7, 0)
ScrollList.Position = UDim2.new(0.025, 0, 0.15, 0)
ScrollList.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", ScrollList)

-- SISTEMA ANTI-REPETIÇÃO
local SeenLogs = {} -- Tabela para lembrar o que já vimos
local LogHistory = {}
local Connections = {}
local IsScanning = false

local function AddLog(text, color)
    -- O SEGREDO: Se já vimos esse texto exato, ignora!
    if SeenLogs[text] then return end
    SeenLogs[text] = true
    
    table.insert(LogHistory, text)

    local label = Instance.new("TextLabel", ScrollList)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = " > " .. text
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 11
    
    ScrollList.CanvasPosition = Vector2.new(0, 9999) -- Auto scroll
end

local function Monitor(service, prefix)
    local conn = service.DescendantAdded:Connect(function(obj)
        task.wait() -- Pequeno delay para evitar lag
        -- Filtra lixo pesado
        if obj:IsA("TouchTransmitter") or obj.Name == "Handle" then return end
        
        local logTxt = prefix .. " | " .. obj.Name
        
        if obj:IsA("RemoteEvent") then
            AddLog(logTxt .. " [REMOTE]", Color3.fromRGB(255, 150, 0))
        elseif obj:IsA("Tool") then
            AddLog(logTxt .. " [ITEM]", Color3.fromRGB(255, 255, 0))
        elseif obj.Name:lower():find("attack") or obj.Name:lower():find("damage") then
             -- Se tiver nome de ataque, destaca
            AddLog(logTxt .. " [ATK/DMG]", Color3.fromRGB(0, 255, 255))
        end
    end)
    table.insert(Connections, conn)
end

-- Botões
local Btn = Instance.new("TextButton", MainFrame)
Btn.Size = UDim2.new(0.4, 0, 0.1, 0)
Btn.Position = UDim2.new(0.05, 0, 0.88, 0)
Btn.Text = "LIGAR/DESLIGAR SCAN"
Btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
Btn.TextColor3 = Color3.new(1,1,1)

Btn.MouseButton1Click:Connect(function()
    IsScanning = not IsScanning
    if IsScanning then
        Btn.Text = "PARAR SCAN"
        Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Monitor(ReplicatedStorage, "REP")
        Monitor(Workspace, "WS")
        Monitor(Players.LocalPlayer.Backpack, "INV")
    else
        Btn.Text = "LIGAR SCAN"
        Btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        for _, c in pairs(Connections) do c:Disconnect() end
        Connections = {}
    end
end)

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
ClearBtn.Position = UDim2.new(0.55, 0, 0.88, 0)
ClearBtn.Text = "LIMPAR & RESETAR"
ClearBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
ClearBtn.TextColor3 = Color3.new(1,1,1)

ClearBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(ScrollList:GetChildren()) do 
        if c:IsA("TextLabel") then c:Destroy() end 
    end
    SeenLogs = {} -- Reseta a memória para poder ver logs de novo
    LogHistory = {}
end)