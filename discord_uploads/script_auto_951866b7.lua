--[[
    🔬 DEEP ANALYZER (SCAN DE CHÃO)
    
    O que faz: Verifica TUDO o que está tocando ou perto do seu pé.
    Objetivo: Descobrir se o item é uma Part, um Mesh, se tem TouchInterest, etc.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

--// GUI SETUP
local guiName = "DeepAnalyzer"
if game.CoreGui:FindFirstChild(guiName) then game.CoreGui[guiName]:Destroy() end
local ScreenGui = Instance.new("ScreenGui", game.CoreGui); ScreenGui.Name = guiName

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.Active = true; MainFrame.Draggable = true
local Stroke = Instance.new("UIStroke", MainFrame); Stroke.Color = Color3.fromRGB(255, 0, 255); Stroke.Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30); Title.Text = "🔬 DEEP ANALYZER"; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 0, 255); Title.BackgroundTransparency = 1

local LogBox = Instance.new("ScrollingFrame", MainFrame)
LogBox.Size = UDim2.new(0.9, 0, 0.65, 0); LogBox.Position = UDim2.new(0.05, 0, 0.15, 0)
LogBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25); LogBox.AutomaticCanvasSize = Enum.AutomaticSize.Y

local LogText = Instance.new("TextLabel", LogBox)
LogText.Size = UDim2.new(1, 0, 0, 0); LogText.AutomaticSize = Enum.AutomaticSize.Y
LogText.TextColor3 = Color3.new(0, 1, 0); LogText.BackgroundTransparency = 1
LogText.TextXAlignment = Enum.TextXAlignment.Left; LogText.TextYAlignment = Enum.TextYAlignment.Top
LogText.Font = Enum.Font.Code; LogText.TextSize = 12
LogText.Text = "Fique em cima do item e clique em SCAN..."

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.4, 0, 0.12, 0); ScanBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200); ScanBtn.Text = "ESCANEAR AGORA"; ScanBtn.TextColor3 = Color3.new(1,1,1); ScanBtn.Font = Enum.Font.GothamBold

local CopyBtn = Instance.new("TextButton", MainFrame)
CopyBtn.Size = UDim2.new(0.4, 0, 0.12, 0); CopyBtn.Position = UDim2.new(0.55, 0, 0.85, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100); CopyBtn.Text = "COPIAR LOGS"; CopyBtn.TextColor3 = Color3.new(1,1,1); CopyBtn.Font = Enum.Font.GothamBold

local reportData = ""

local function ScanFeet()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPos = char.HumanoidRootPart.Position
    reportData = "--- RELATÓRIO DE CHÃO (RAIO 8 STUDS) ---\n"
    
    -- Esfera de detecção
    local parts = Workspace:GetPartBoundsInRadius(rootPos, 8)
    
    local foundSomething = false
    
    for _, part in pairs(parts) do
        -- Ignora o próprio personagem e o terreno
        if not part:IsDescendantOf(char) and part.Name ~= "Terrain" and part.Name ~= "Baseplate" then
            foundSomething = true
            
            reportData = reportData .. "OBJETO: " .. part.Name .. "\n"
            reportData = reportData .. "   Class: " .. part.ClassName .. "\n"
            reportData = reportData .. "   Parent: " .. part.Parent.Name .. "\n"
            reportData = reportData .. "   Path: " .. part:GetFullName() .. "\n"
            
            -- Verifica se tem ClickDetector
            if part:FindFirstChildOfClass("ClickDetector") then
                reportData = reportData .. "   [!] TEM CLICKDETECTOR!\n"
            end
            
            -- Verifica se tem TouchInterest (Colisão)
            if part:FindFirstChild("TouchInterest") then
                reportData = reportData .. "   [!] TEM TOUCHINTEREST (Pisável)\n"
            end
            
            reportData = reportData .. "----------------------------------\n"
            
            -- Desenha uma caixa em volta pra você ver o que ele detectou
            local box = Instance.new("SelectionBox")
            box.Adornee = part
            box.Color3 = Color3.new(1, 0, 0)
            box.Parent = part
            game.Debris:AddItem(box, 3) -- Some em 3 segundos
        end
    end
    
    if not foundSomething then
        reportData = reportData .. "Nada encontrado! Chegue mais perto."
    end
    
    LogText.Text = reportData
end

ScanBtn.MouseButton1Click:Connect(ScanFeet)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(reportData)
        CopyBtn.Text = "COPIADO!"
    else
        CopyBtn.Text = "ERRO (Ver F9)"
        print(reportData)
    end
    task.wait(1)
    CopyBtn.Text = "COPIAR LOGS"
end)