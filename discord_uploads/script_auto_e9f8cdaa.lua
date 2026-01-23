--[[
    🏴‍☠️ BLOX FRUITS - MOB MAGNET (SCANNER)
    
    ESTRATÉGIA "DEVAGAR":
    1. Não voa, não teleporta longe.
    2. Lê a pasta 'Enemies' e cria botões para cada tipo de mob encontrado.
    3. Tenta trazer os mobs selecionados para perto de você (Ímã).
    
    NOTA: Se o mob voltar para o lugar dele, é proteção do servidor.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local MAGNET_RANGE = 300 -- Só puxa se estiver a menos de 300 studs (pra não bugar)
local HOLD_DIST = 5      -- Distância que o mob fica de você

-- Estado
local SelectedMobs = {} -- Tabela com nomes dos mobs ativados: { ["Monkey"] = true }
local IsMagnetActive = false

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxMagnetUI") then CoreGui.BloxMagnetUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxMagnetUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧲 MOB SCANNER"
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack

-- Botão de Scan
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 30)
ScanBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ScanBtn.Text = "🔄 SCANEAR ÁREA ATUAL"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

-- Botão Ativar Ímã
local ToggleMagnet = Instance.new("TextButton", MainFrame)
ToggleMagnet.Size = UDim2.new(0.9, 0, 0, 30)
ToggleMagnet.Position = UDim2.new(0.05, 0, 0.85, 0)
ToggleMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleMagnet.Text = "LIGAR ÍMÃ (OFF)"
ToggleMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMagnet.Font = Enum.Font.GothamBold

-- Lista de Mobs (Scroll)
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.55, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.25, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Scroll.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout", Scroll)
UIListLayout.Padding = UDim.new(0, 5)

-- // FUNÇÕES LÓGICAS //

local function CreateCheckbox(mobName)
    -- Verifica se já existe pra não duplicar
    if Scroll:FindFirstChild(mobName) then return end

    local Btn = Instance.new("TextButton", Scroll)
    Btn.Name = mobName
    Btn.Size = UDim2.new(1, 0, 0, 25)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Btn.Text = " [ ] " .. mobName
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextXAlignment = Enum.TextXAlignment.Left

    Btn.MouseButton1Click:Connect(function()
        if SelectedMobs[mobName] then
            SelectedMobs[mobName] = false
            Btn.Text = " [ ] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            SelectedMobs[mobName] = true
            Btn.Text = " [X] " .. mobName
            Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)
end

local function ScanMobs()
    -- Limpa lista antiga (opcional, mas bom pra atualizar)
    -- for _, child in pairs(Scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then 
        warn("Pasta 'Enemies' não encontrada!") 
        return 
    end

    local foundCount = 0
    local uniqueNames = {}

    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            if not uniqueNames[mob.Name] then
                uniqueNames[mob.Name] = true
                CreateCheckbox(mob.Name)
                foundCount = foundCount + 1
            end
        end
    end
    ScanBtn.Text = "ACHEI " .. foundCount .. " TIPOS DE MOBS"
    task.wait(1)
    ScanBtn.Text = "🔄 SCANEAR ÁREA ATUAL"
end

-- Lógica do Ímã (Magnet)
local function MagnetLoop()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    
    if enemiesFolder then
        for _, mob in ipairs(enemiesFolder:GetChildren()) do
            -- Verifica se o mob está selecionado E vivo
            if SelectedMobs[mob.Name] and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                
                local mobRoot = mob.HumanoidRootPart
                local dist = (myRoot.Position - mobRoot.Position).Magnitude
                
                -- Só puxa se estiver no raio (segurança anti-kick)
                if dist <= MAGNET_RANGE then
                    -- Tenta definir o CFrame do mob para sua frente
                    -- O servidor pode brigar com isso, mas visualmente ajuda o hit
                    mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -HOLD_DIST)
                    mobRoot.Velocity = Vector3.new(0,0,0) -- Tira velocidade pra ele não sair voando
                    
                    -- Quebra a coluna do mob pra ele não levantar (Sit)
                    mob.Humanoid.Sit = true 
                end
            end
        end
    end
end

-- // EVENTOS UI //

ScanBtn.MouseButton1Click:Connect(ScanMobs)

ToggleMagnet.MouseButton1Click:Connect(function()
    IsMagnetActive = not IsMagnetActive
    if IsMagnetActive then
        ToggleMagnet.Text = "LIGAR ÍMÃ (ON)"
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ToggleMagnet.Text = "LIGAR ÍMÃ (OFF)"
        ToggleMagnet.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Loop Principal
RunService.Stepped:Connect(function()
    if IsMagnetActive then
        MagnetLoop()
    end
    
    -- NoClip simples pra os bichos não te empurrarem
    if IsMagnetActive and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Fechar
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsMagnetActive = false
    ScreenGui:Destroy()
end)