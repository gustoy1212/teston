--[[
    🧲 ZOMBIE MAGNET v3.0
    
    Novidades:
    - Botão "ATIVAR IMÃ": Traz os mobs até você.
    - Exploit: Usa a vulnerabilidade 'ClientHandled' para teleportar os mobs.
    - Filtro: Só puxa se tiver HP > 0 (Vivo).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieMagnetGUI"
-- Tenta colocar no CoreGui para ficar escondido, senão vai no PlayerGui
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🧬 ZOMBIE MAGNET v3"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20

-- BOTÃO DO SCAN (Mantido para debug)
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ScanBtn.Text = "🔍 APENAS ESCANEAR (Debug)"
ScanBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ScanBtn.Font = Enum.Font.GothamBold

-- BOTÃO DO IMÃ (O NOVO!)
local MagnetBtn = Instance.new("TextButton", MainFrame)
MagnetBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
MagnetBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
MagnetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Vermelho (Desligado)
MagnetBtn.Text = "🧲 IMÃ: DESLIGADO"
MagnetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MagnetBtn.Font = Enum.Font.GothamBlack
MagnetBtn.TextSize = 18

local StatusText = Instance.new("TextLabel", MainFrame)
StatusText.Size = UDim2.new(0.9, 0, 0.5, 0)
StatusText.Position = UDim2.new(0.05, 0, 0.42, 0)
StatusText.BackgroundTransparency = 1
StatusText.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.TextYAlignment = Enum.TextYAlignment.Top
StatusText.Text = "Status: Aguardando..."
StatusText.Font = Enum.Font.Code
StatusText.TextSize = 12

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR SCRIPT"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // VARIÁVEIS DE CONTROLE //
local MagnetEnabled = false
local Connection = nil

-- // FUNÇÃO DE PUXAR (O PULO DO GATO) //
local function PullMobs()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local mobsFolder = Workspace:FindFirstChild("Mobs") -- Baseado na sua print
    
    if not mobsFolder then 
        StatusText.Text = "❌ Pasta 'Workspace.Mobs' não encontrada!"
        return 
    end

    local count = 0
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        -- Checagens de segurança para ver se é um mob válido
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        local hp = mob:GetAttribute("HP") -- Baseado na sua print 2
        
        -- Se não tiver atributo HP, assume que tá vivo (nil) ou checa se é > 0
        local isAlive = (hp == nil) or (hp > 0)
        
        if mobRoot and isAlive then
            -- A MÁGICA: Teleporta o mob para 3 studs na sua frente
            -- Mantemos a rotação do mob, mas mudamos a posição
            mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
            
            -- Tira a velocidade dele para ele não sair voando
            mobRoot.Velocity = Vector3.new(0,0,0)
            mobRoot.RotVelocity = Vector3.new(0,0,0)
            
            -- Opcional: Quebra as juntas se quiser matar instantaneo (pode crashar ou não funcionar)
            -- Mas o foco aqui é trazer para bater
            
            count = count + 1
        end
    end
    
    StatusText.Text = "🧲 Puxando: " .. count .. " mobs...\nBata neles agora!"
end

-- // CONTROLE DO LOOP //
MagnetBtn.MouseButton1Click:Connect(function()
    MagnetEnabled = not MagnetEnabled
    
    if MagnetEnabled then
        MagnetBtn.Text = "🧲 IMÃ: LIGADO"
        MagnetBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100) -- Verde
        
        -- Inicia o Loop Rápido (Heartbeat roda a cada frame de física)
        Connection = RunService.Heartbeat:Connect(PullMobs)
    else
        MagnetBtn.Text = "🧲 IMÃ: DESLIGADO"
        MagnetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Vermelho
        StatusText.Text = "⏸️ Imã pausado."
        
        -- Desliga o Loop
        if Connection then Connection:Disconnect() end
    end
end)

-- Botão de Scan (Só para testar se achou algo novo)
ScanBtn.MouseButton1Click:Connect(function()
    local mobs = Workspace:FindFirstChild("Mobs")
    if mobs then
        StatusText.Text = "🔍 Scan: Encontrei " .. #mobs:GetChildren() .. " objetos na pasta Mobs."
    else
        StatusText.Text = "❌ Pasta Mobs sumiu?"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)