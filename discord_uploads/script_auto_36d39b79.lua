--[[
    🎮 INTERACTION DEBUGGER & GUI PATH FINDER
    
    1. SIMULADOR G: Tenta forçar a interação via VirtualInputManager.
    2. GUI DETECTOR: Quando você clicar em "Aceitar Missão", ele te dá o caminho do botão.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // GUI SETUP //
if CoreGui:FindFirstChild("InteractionDebug") then CoreGui.InteractionDebug:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InteractionDebug"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = PlayerGui end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 180)
MainFrame.Position = UDim2.new(0.5, -175, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎮 INTERACTION DEBUGGER"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(0.9, 0, 0, 40)
StatusLbl.Position = UDim2.new(0.05, 0, 0.25, 0)
StatusLbl.Text = "1. Chegue perto do NPC.\n2. Clique em 'SIMULAR TECLA G'."
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1
StatusLbl.TextScaled = true

-- BOTÃO SIMULAR G
local SimGBtn = Instance.new("TextButton", MainFrame)
SimGBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
SimGBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
SimGBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
SimGBtn.Text = "PRESSIONAR 'G' (Virtual)"
SimGBtn.TextColor3 = Color3.WHITE
SimGBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO: SIMULAR TECLA //
SimGBtn.MouseButton1Click:Connect(function()
    StatusLbl.Text = "Enviando sinal de tecla 'G'..."
    -- Simula pressionar a tecla fisicamente
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
    StatusLbl.Text = "Sinal enviado! A janela abriu?"
end)

-- // FUNÇÃO: DETECTAR CLIQUE NA GUI //
-- Isso vai monitorar onde você clica na tela para pegar o caminho do botão de aceitar
local Mouse = LocalPlayer:GetMouse()

local connection
connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Quando clicar, verifica se clicou numa GUI
        local guiObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)
        
        for _, obj in pairs(guiObjects) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                -- Mostra o caminho no console (F9) e na tela
                local path = obj:GetFullName()
                print("🔘 BOTÃO CLICADO: " .. path)
                
                -- Copia para a área de transferência se o executor suportar
                if setclipboard then
                    setclipboard(path)
                end
                
                Title.Text = "CAMINHO COPIADO (F9)!"
                StatusLbl.Text = obj.Name
                StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
        end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if connection then connection:Disconnect() end
    ScreenGui:Destroy()
end)