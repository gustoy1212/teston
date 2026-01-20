--[[
    👻 RPG GHOST PUNCHER v43 (BASE AFK)
    
    SOLUÇÃO "SEM ARMA":
    - Como você usa os punhos (RightHand/LeftHand), você precisa estar colado no inimigo.
    - Este script teleporta seu corpo fisicamente até o inimigo.
    - MAS, trava sua câmera na base para parecer que você não saiu do lugar.
    
    ALVO: Workspace.Client.Enemies (Genes)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().GhostFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackDist = 4,       -- Distância para colar no inimigo (bem perto pra soco)
    FarmSpeed = 0.1,      -- Velocidade de atualização
    HideCharacter = true, -- Deixa você invisível enquanto farma
}

-- // GUI SETUP //
if CoreGui:FindFirstChild("GhostPuncher") then CoreGui.GhostPuncher:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "GhostPuncher"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "👻 GHOST PUNCHER"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR GHOST FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES VISUAIS //
local BaseCFrame = nil -- Onde a câmera vai ficar travada

local function ToggleGhost(state)
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        -- Salva posição da base e trava câmera
        if not BaseCFrame then BaseCFrame = Camera.CFrame end
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = BaseCFrame
        
        -- Fica invisível
        if SETTINGS.HideCharacter then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("Decal") then
                    if v.Name ~= "HumanoidRootPart" then v.Transparency = 1 end
                end
            end
        end
    else
        -- Destrava
        Camera.CameraType = Enum.CameraType.Custom
        BaseCFrame = nil
        
        -- Volta visível
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                if v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
            end
        end
    end
end

-- // LIMPEZA TOTAL //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().GhostFarm = false
    ToggleGhost(false) -- Destrava câmera e boneco
    ScreenGui:Destroy()
end)

-- // LÓGICA DE FARM //
local isRunning = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        -- Salva posição atual como "Base"
        BaseCFrame = Camera.CFrame 
        ToggleGhost(true)
    else
        ToggleBtn.Text = "LIGAR GHOST FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        ToggleGhost(false)
    end
end)

-- Loop Rápido
RunService.Heartbeat:Connect(function()
    if not getgenv().GhostFarm or not isRunning then return end
    
    -- Mantém a câmera travada na base para ilusão
    if BaseCFrame then Camera.CFrame = BaseCFrame end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = char.HumanoidRootPart
    
    -- 1. LOCALIZA INIMIGOS (Pasta Confirmada na Autópsia)
    local folder = Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies")
    -- Fallback se a pasta mudar
    if not folder then 
        for _, c in ipairs(Workspace:GetChildren()) do
            if c.Name:match("Enemies") or c.Name:match("Mobs") then folder = c break end
        end
    end
    
    if not folder then Status.Text = "⚠️ Pasta Inimigos Sumiu!" return end
    
    -- 2. ENCONTRA O MAIS PRÓXIMO VIVO
    local target = nil
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            target = mob
            break -- Pega o primeiro que achar (Farm Rápido)
        end
    end
    
    -- 3. TELEPORTA E MATA
    if target then
        local tRoot = target.HumanoidRootPart
        Status.Text = "🥊 SOCO EM: " .. target.Name
        
        -- TP PARA TRÁS DO INIMIGO (Para o soco pegar)
        local attackPos = tRoot.CFrame * CFrame.new(0, 0, 3) -- 3 studs nas costas
        
        -- CFrame direto (Mais rápido que andar)
        myRoot.CFrame = CFrame.new(attackPos.Position, tRoot.Position)
        myRoot.Velocity = Vector3.new(0,0,0) -- Tira a física pra não cair
        
        -- O Auto-Attack do jogo vai detectar que você está perto e bater
    else
        Status.Text = "Procurando Genes..."
        -- Se não tem inimigo, volta pra "Base" (Escondido embaixo da terra pra não morrer)
        if BaseCFrame then
            myRoot.CFrame = BaseCFrame * CFrame.new(0, -50, 0)
            myRoot.Velocity = Vector3.new(0,0,0)
        end
    end
end)