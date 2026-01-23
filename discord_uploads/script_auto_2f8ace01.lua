--[[
    ❄️ BLOX FRUITS - MAGNET FREEZE (BACKSTAB FARM)
    
    ESTRATÉGIA PARA QUEM USA SOCO (COMBAT):
    1. PUXA o mob até você.
    2. CONGELA (Anchor) o mob localmente para ele não se mexer.
    3. Posiciona você nas COSTAS dele (Ponto cego).
    4. Assim você acerta o soco (perto) mas ele não te acerta (costas).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local MAGNET_RANGE = 250    -- Alcance para puxar
local ATTACK_DIST = 4       -- Distância para bater (4 studs é bom para soco)
local FREEZE_DIST = 10      -- Distância que o mob congela ao chegar perto

-- Estados
local IsFarming = false
local IsAutoClick = false
local SelectedMobs = {} 
local TargetMob = nil       -- O mob que estamos focando agora

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxFreezeUI") then CoreGui.BloxFreezeUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxFreezeUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "❄️ MAGNET FREEZE v4"
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

-- Botão Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ScanBtn.Text = "1. SCANEAR MOBS"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Farm
local ToggleFarm = Instance.new("TextButton", MainFrame)
ToggleFarm.Size = UDim2.new(0.9, 0, 0, 40)
ToggleFarm.Position = UDim2.new(0.05, 0, 0.75, 0)
ToggleFarm.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleFarm.Text = "2. ATIVAR CONGELADOR"
ToggleFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleFarm.Font = Enum.Font.GothamBold
ToggleFarm.TextSize = 16

-- Checkbox Auto Click
local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 25)
ClickBox.Position = UDim2.new(0.05, 0, 0.9, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBox.Text = "[X] Auto Click Ligado"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)
IsAutoClick = true -- Ligado por padrão

-- Lista
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.5, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.23, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Scroll.ScrollBarThickness = 6
local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES AUXILIARES //

local function CreateCheckbox(mobName)
    if Scroll:FindFirstChild(mobName) then return end
    local Btn = Instance.new("TextButton", Scroll)
    Btn.Name = mobName
    Btn.Size = UDim2.new(1, 0, 0, 25)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Btn.Text = " [ ] " .. mobName
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Font = Enum.Font.SourceSansBold
    
    Btn.MouseButton1Click:Connect(function()
        if SelectedMobs[mobName] then
            SelectedMobs[mobName] = false
            Btn.Text = " [ ] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            SelectedMobs[mobName] = true
            Btn.Text = " [X] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)
end

local function ScanMobs()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            CreateCheckbox(mob.Name)
        end
    end
end

-- Congela o Mob (Anchor Local)
local function FreezeMob(mob, freeze)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root then
        root.Anchored = freeze
        if freeze then
            root.Velocity = Vector3.new(0,0,0) -- Para o movimento
        end
    end
end

-- // LOOP PRINCIPAL //
RunService.Stepped:Connect(function()
    if not IsFarming then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart

    -- AUTO CLICK
    if IsAutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end

    -- Encontrar o Mob Selecionado mais próximo
    local closest, minDist = nil, MAGNET_RANGE
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if SelectedMobs[mob.Name] and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            local mobRoot = mob.HumanoidRootPart
            local dist = (myRoot.Position - mobRoot.Position).Magnitude
            
            -- LÓGICA DO ÍMÃ + FREEZE
            if dist <= MAGNET_RANGE then
                -- 1. Traz o mob até a distância de congelamento
                if dist > FREEZE_DIST then
                    FreezeMob(mob, false) -- Solta pra ele vir
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -FREEZE_DIST) -- Puxa
                else
                    -- 2. Congela o mob quando está perto
                    FreezeMob(mob, true)
                    
                    -- Se for o mais próximo, foca nele
                    if dist < minDist then
                        minDist = dist
                        closest = mob
                    end
                end
            end
        end
    end
    
    TargetMob = closest

    -- POSICIONAMENTO DO JOGADOR (BACKSTAB)
    if TargetMob and TargetMob:FindFirstChild("HumanoidRootPart") then
        local tRoot = TargetMob.HumanoidRootPart
        
        -- Teleporta você para as COSTAS do mob congelado
        -- ATTACK_DIST = distância (4 studs)
        local behindPos = tRoot.CFrame * CFrame.new(0, 0, ATTACK_DIST) 
        
        -- Faz você olhar para o mob
        local lookAt = CFrame.new(behindPos.Position, tRoot.Position)
        
        myRoot.CFrame = lookAt
    end
end)

-- // EVENTOS UI //
ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleFarm.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleFarm.Text = "PARAR FARM"
        ToggleFarm.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleFarm.Text = "2. ATIVAR CONGELADOR"
        ToggleFarm.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        -- Descongela mobs ao parar (pra não bugar o jogo)
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, mob in ipairs(enemiesFolder:GetChildren()) do
                FreezeMob(mob, false)
            end
        end
    end
end)

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
    ScreenGui:Destroy()
end)