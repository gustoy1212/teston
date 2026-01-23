--[[
    🕳️ BLOX FRUITS - MAGNET BUNKER v5 (UNDERGROUND)
    
    NOVIDADES:
    1. TECLA 'Z': Liga/Desliga tudo instantaneamente.
    2. BUNKER: Cria uma plataforma 50 studs abaixo da terra.
    3. GHOST MOBS: Faz os mobs atravessarem o chão para cair no seu bunker.
    4. MANTIDO: Sistema de Congelar + Costas (Backstab).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local MAGNET_RANGE = 300    -- Alcance do ímã
local BUNKER_DEPTH = 50     -- Profundidade (50 metros abaixo da terra)
local ATTACK_DIST = 4       -- Distância do soco
local FREEZE_DIST = 8       -- Distância que o mob congela

-- Estados
local IsFarming = false
local IsAutoClick = true
local SelectedMobs = {} 
local TargetMob = nil
local BunkerPart = nil
local OldPosition = nil     -- Para onde voltar quando desligar

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxBunkerUI") then CoreGui.BloxBunkerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxBunkerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(100, 50, 255) -- Roxo (Underground)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🕳️ FARM BUNKER v5 (Tecla Z)"
Title.BackgroundColor3 = Color3.fromRGB(50, 20, 100)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.1, 0)
Status.Text = "Status: Superfície (OFF)"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.18, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScanBtn.Text = "1. SCANEAR MOBS"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Farm
local ToggleFarmBtn = Instance.new("TextButton", MainFrame)
ToggleFarmBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleFarmBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleFarmBtn.Text = "2. IR PARA O BUNKER (Z)"
ToggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFarmBtn.Font = Enum.Font.GothamBold
ToggleFarmBtn.TextSize = 16

-- Checkbox Auto Click
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 25)
ClickBox.Position = UDim2.new(0.05, 0, 0.9, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ClickBox.Text = "[X] Auto Click Ligado"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.5, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.28, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES LÓGICAS //

-- Cria/Destroi o Bunker
local function ManageBunker(enable)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    if enable then
        -- Salva posição original pra voltar depois
        if not OldPosition then OldPosition = char.HumanoidRootPart.CFrame end
        
        -- Cria chão invisível lá embaixo
        if not BunkerPart then
            BunkerPart = Instance.new("Part", Workspace)
            BunkerPart.Name = "FarmBunker"
            BunkerPart.Size = Vector3.new(50, 1, 50)
            BunkerPart.Anchored = true
            BunkerPart.Transparency = 0.5 -- Meio visível pra vc saber onde tá
            BunkerPart.Color = Color3.fromRGB(100, 0, 255)
            BunkerPart.Material = Enum.Material.Neon
            
            -- Posiciona o bunker 50 metros abaixo de onde vc estava
            BunkerPart.CFrame = OldPosition * CFrame.new(0, -BUNKER_DEPTH, 0)
        end
        
        -- Teleporta Player pro Bunker
        char.HumanoidRootPart.CFrame = BunkerPart.CFrame * CFrame.new(0, 3, 0)
        Status.Text = "Status: 🔽 NO SUBSOLO (ON)"
        
    else
        -- Volta pra superfície
        if OldPosition then 
            char.HumanoidRootPart.CFrame = OldPosition 
            OldPosition = nil
        end
        
        -- Destroi bunker
        if BunkerPart then
            BunkerPart:Destroy()
            BunkerPart = nil
        end
        Status.Text = "Status: 🔼 SUPERFÍCIE (OFF)"
        
        -- Descongela todo mundo pra não bugar
        local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
        if enemiesFolder then
            for _, mob in ipairs(enemiesFolder:GetChildren()) do
                if mob:FindFirstChild("HumanoidRootPart") then
                    mob.HumanoidRootPart.Anchored = false
                end
            end
        end
    end
end

-- Ativa/Desativa Farm (Função Central)
local function ToggleFarm()
    IsFarming = not IsFarming
    
    if IsFarming then
        ToggleFarmBtn.Text = "PARAR FARM (Z)"
        ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        ManageBunker(true)
    else
        ToggleFarmBtn.Text = "2. IR PARA O BUNKER (Z)"
        ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        ManageBunker(false)
    end
end

-- Escaneia Mobs
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
                Btn.Font = Enum.Font.SourceSansBold
                
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

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    if not IsFarming then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    
    -- Garante que o bunker existe e está perto (se vc cair, ele cria outro embaixo)
    if not BunkerPart or (myRoot.Position - BunkerPart.Position).Magnitude > 60 then
        OldPosition = myRoot.CFrame * CFrame.new(0, BUNKER_DEPTH, 0) -- Recalcula
        ManageBunker(true)
    end

    -- Auto Click
    if IsAutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end

    local closest, minDist = nil, MAGNET_RANGE
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if SelectedMobs[mob.Name] and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            
            local mobRoot = mob.HumanoidRootPart
            
            -- 🔥 FAZ O MOB ATRAVESSAR O CHÃO 🔥
            -- Desativa colisão das partes do mob para ele cair da superfície até você
            for _, part in pairs(mob:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
            
            local dist = (myRoot.Position - mobRoot.Position).Magnitude
            
            if dist <= MAGNET_RANGE then
                -- Lógica: Puxa o mob até o bunker
                if dist > FREEZE_DIST then
                    mobRoot.Anchored = false
                    -- Teleporta direto pro bunker
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -FREEZE_DIST)
                else
                    -- Congela pra bater
                    mobRoot.Anchored = true
                    mobRoot.Velocity = Vector3.new(0,0,0)
                    
                    if dist < minDist then minDist = dist closest = mob end
                end
            end
        end
    end
    
    -- Backstab Logic (Costas)
    if closest and closest:FindFirstChild("HumanoidRootPart") then
        local tRoot = closest.HumanoidRootPart
        -- Fica atrás do mob congelado
        local behindPos = tRoot.CFrame * CFrame.new(0, 0, ATTACK_DIST) 
        local lookAt = CFrame.new(behindPos.Position, tRoot.Position)
        myRoot.CFrame = lookAt
    end
end)

-- // INPUT (TECLA Z) //
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
        ToggleFarm()
    end
end)

-- // EVENTOS UI //
ScanBtn.MouseButton1Click:Connect(ScanMobs)
ToggleFarmBtn.MouseButton1Click:Connect(ToggleFarm)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "[X] Auto Click Ligado"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        ClickBox.Text = "[ ] Auto Click Desligado"
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
    ManageBunker(false)
    ScreenGui:Destroy()
end)