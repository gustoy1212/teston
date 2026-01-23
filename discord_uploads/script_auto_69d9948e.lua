--[[
    🕳️ BLOX FRUITS - UNDERGROUND CONTROL v10
    
    NOVIDADES:
    - Botões para AJUSTAR ALTURA (Subir/Descer) em tempo real.
    - Plataforma Sólida (Anti-Limbo).
    - Ímã Vertical: Traz os mobs para a altura da sua plataforma.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES INICIAIS //
local CURRENT_DEPTH = 30     -- Começa 30 metros abaixo (ajustável)
local MAGNET_RANGE = 300     -- Alcance horizontal
local PLATFORM_SIZE = 50     -- Tamanho do chão

-- Estados
local IsFarming = false
local IsAutoClick = true
local SelectedMobs = {} 
local BunkerPart = nil
local OriginalPos = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxUnderUI") then CoreGui.BloxUnderUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxUnderUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 380)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja (Construção)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "🏗️ UNDERGROUND v10"
Title.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

-- Status Altura
local HeightLbl = Instance.new("TextLabel", MainFrame)
HeightLbl.Size = UDim2.new(1, 0, 0, 25)
HeightLbl.Position = UDim2.new(0, 0, 0.12, 0)
HeightLbl.Text = "Profundidade Atual: " .. CURRENT_DEPTH
HeightLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
HeightLbl.BackgroundTransparency = 1
HeightLbl.Font = Enum.Font.Code

-- Botões de Ajuste
local UpBtn = Instance.new("TextButton", MainFrame)
UpBtn.Size = UDim2.new(0.4, 0, 0, 30)
UpBtn.Position = UDim2.new(0.05, 0, 0.22, 0)
UpBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
UpBtn.Text = "⬆️ SUBIR (5m)"
UpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UpBtn.Font = Enum.Font.GothamBold

local DownBtn = Instance.new("TextButton", MainFrame)
DownBtn.Size = UDim2.new(0.4, 0, 0, 30)
DownBtn.Position = UDim2.new(0.55, 0, 0.22, 0)
DownBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 0)
DownBtn.Text = "⬇️ DESCER (5m)"
DownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DownBtn.Font = Enum.Font.GothamBold

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ScanBtn.Text = "1. SCANEAR ÁREA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Start
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.72, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "2. CRIAR BUNKER & FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- Checkbox Auto Click
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 25)
ClickBox.Position = UDim2.new(0.05, 0, 0.88, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBox.Text = "Auto Click: LIGADO"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 100)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.25, 0) -- Menor pra caber os botões
Scroll.Position = UDim2.new(0.05, 0, 0.45, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // LÓGICA DO BUNKER //

local function UpdatePlatform()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    if not OriginalPos then OriginalPos = char.HumanoidRootPart.CFrame end
    
    -- Cria ou Move a Plataforma
    if not BunkerPart then
        BunkerPart = Instance.new("Part", Workspace)
        BunkerPart.Name = "SafeBunker"
        BunkerPart.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
        BunkerPart.Anchored = true
        BunkerPart.Transparency = 0.5
        BunkerPart.Material = Enum.Material.Neon
        BunkerPart.Color = Color3.fromRGB(255, 170, 0)
    end
    
    -- Posiciona a plataforma baseada na posição original (superfície) - profundidade
    -- Mantém o X e Z originais pra não sair do lugar
    local targetPos = OriginalPos * CFrame.new(0, -CURRENT_DEPTH, 0)
    BunkerPart.CFrame = targetPos
    
    -- Teleporta o jogador pra cima dela
    char.HumanoidRootPart.CFrame = BunkerPart.CFrame * CFrame.new(0, 3, 0)
end

local function AdjustHeight(amount)
    CURRENT_DEPTH = CURRENT_DEPTH + amount
    HeightLbl.Text = "Profundidade Atual: " .. CURRENT_DEPTH
    if IsFarming then
        UpdatePlatform() -- Atualiza na hora se estiver farmando
    end
end

-- // SCAN & FARM //

local function ScanMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            if not Scroll:FindFirstChild(mob.Name) then
                local Btn = Instance.new("TextButton", Scroll)
                Btn.Name = mob.Name
                Btn.Size = UDim2.new(1, 0, 0, 25)
                Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Btn.Text = " [ ] " .. mob.Name
                Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                Btn.MouseButton1Click:Connect(function()
                    if SelectedMobs[mob.Name] then
                        SelectedMobs[mob.Name] = false
                        Btn.Text = " [ ] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    else
                        SelectedMobs[mob.Name] = true
                        Btn.Text = " [X] " .. mob.Name
                        Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                    end
                end)
            end
        end
    end
end

-- Loop Principal
RunService.Stepped:Connect(function()
    if IsFarming and BunkerPart then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        -- Garante que o jogador não caia da plataforma
        -- Se distanciar muito do centro Y, puxa de volta
        if math.abs(char.HumanoidRootPart.Position.Y - BunkerPart.Position.Y) > 10 then
            char.HumanoidRootPart.CFrame = BunkerPart.CFrame * CFrame.new(0, 3, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
        
        -- Auto Click
        if IsAutoClick then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        
        -- Lógica de Puxar Mobs
        local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
        if not enemiesFolder then return end
        
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                
                local mobRoot = mob.HumanoidRootPart
                -- Distância Horizontal (ignora altura)
                local myPos = char.HumanoidRootPart.Position
                local mobPos = mobRoot.Position
                local distH = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(mobPos.X, 0, mobPos.Z)).Magnitude
                
                if distH <= MAGNET_RANGE then
                    -- Traz o mob para a MESMA ALTURA da plataforma
                    -- Mantém o X/Z dele (pra não teleportar e resetar), só afunda ele
                    
                    -- Se ele estiver muito longe horizontalmente, puxa um pouco pra perto (Magnet Suave)
                    if distH > 5 then
                        mobRoot.CFrame = CFrame.new(myPos.X, BunkerPart.Position.Y + 3, myPos.Z) * CFrame.new(0, 0, -5) -- 5 studs na frente
                    else
                        mobRoot.CFrame = CFrame.new(mobPos.X, BunkerPart.Position.Y + 3, mobPos.Z)
                    end
                    
                    mobRoot.Velocity = Vector3.new(0, -50, 0) -- Força pra baixo pra garantir
                    
                    -- Quebra colisão pra ele não ficar flutuando no teto do mapa
                    for _, p in pairs(mob:GetChildren()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end
        end
    end
end)

-- // EVENTOS //

UpBtn.MouseButton1Click:Connect(function() AdjustHeight(-5) end) -- Menos profundidade = Subir
DownBtn.MouseButton1Click:Connect(function() AdjustHeight(5) end) -- Mais profundidade = Descer

ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR (VOLTAR SUP.)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        UpdatePlatform() -- Inicia o bunker
    else
        ToggleBtn.Text = "2. CRIAR BUNKER & FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        
        -- Volta pra superfície
        if OriginalPos and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = OriginalPos
            OriginalPos = nil
        end
        if BunkerPart then BunkerPart:Destroy() BunkerPart = nil end
    end
end)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "Auto Click: LIGADO"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        ClickBox.Text = "Auto Click: DESLIGADO"
        ClickBox.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    if BunkerPart then BunkerPart:Destroy() end
    ScreenGui:Destroy()
end)