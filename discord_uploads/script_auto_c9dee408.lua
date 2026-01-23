--[[
    ⚡ BLOX FRUITS - OMNI TOUCH v13 (GOD REACH)
    
    BASEADO NAS SUAS LOGS:
    - Tenta usar 'TouchInterest' (Evento de Toque) da espada/soco.
    - Dispara contra TODOS os inimigos da ilha SIMULTANEAMENTE.
    - NÃO move você. NÃO move os mobs. NÃO cria clones.
    
    NOTA: Se o dano for 0, o Anti-Cheat (Net Module) barrou a distância.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local ATTACK_DELAY = 0.1   -- Velocidade dos ataques (Não ponha 0 para não crashar)
local SHOW_LINES = true    -- Mostra linhas ligando você aos mobs (Visual)

-- Estados
local IsFarming = false
local IsAutoClick = true

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxOmniUI") then CoreGui.BloxOmniUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxOmniUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 250)
MainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Vermelho Agressivo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡ OMNI-TOUCH v13 (GLOBAL)"
Title.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, 0, 0, 25)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.Text = "Status: Aguardando Arma..."
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
ToggleBtn.Text = "ATIVAR DANO GLOBAL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20

local ClickBox = Instance.new("TextButton", MainFrame)
ClickBox.Size = UDim2.new(0.9, 0, 0, 30)
ClickBox.Position = UDim2.new(0.05, 0, 0.75, 0)
ClickBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBox.Text = "Auto Click (Necessário): ON"
ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)

-- Container para linhas visuais
local LineFolder = Instance.new("Folder", Workspace)
LineFolder.Name = "OmniLines"

-- // FUNÇÕES CORE //

local function DrawLine(from, to)
    if not SHOW_LINES then return end
    
    local part = Instance.new("Part")
    part.Name = "VisualLine"
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Size = Vector3.new(0.2, 0.2, (from - to).Magnitude)
    part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -(from - to).Magnitude / 2)
    part.Parent = LineFolder
    
    game.Debris:AddItem(part, 0.1) -- Some rápido
end

local function GodTouchAttack()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then 
        StatusLbl.Text = "⚠️ EQUIPE UMA ARMA!"
        StatusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
        return 
    end
    
    -- Tenta achar a parte que dá dano (Handle, Middle, etc)
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("Middle") or tool:FindFirstChild("Part")
    if not handle then return end
    
    StatusLbl.Text = "🔥 ATACANDO TODOS..."
    StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)

    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return end

    -- LOOP MÁGICO: Toca em todos ao mesmo tempo
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            
            -- Não verifica distância. Tenta forçar o hit.
            local mobRoot = mob.HumanoidRootPart
            
            if firetouchinterest then
                -- Simula o toque da espada na pele do mob
                firetouchinterest(handle, mobRoot, 0) 
                firetouchinterest(handle, mobRoot, 1)
                
                -- Desenha linha visual pra vc ver quem tá sendo atacado
                if IsFarming then
                    DrawLine(handle.Position, mobRoot.Position)
                end
            end
        end
    end
end

-- // LOOP PRINCIPAL //
spawn(function()
    while true do
        task.wait(ATTACK_DELAY) -- Ciclo de ataque
        
        if IsFarming then
            -- 1. Força o ataque global
            GodTouchAttack()
            
            -- 2. Auto Click (Pro jogo validar que vc tá atacando)
            if IsAutoClick then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end
    end
end)

-- // EVENTOS UI //
ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR ATAQUE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "ATIVAR DANO GLOBAL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
        StatusLbl.Text = "Status: Parado"
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        LineFolder:ClearAllChildren()
    end
end)

ClickBox.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBox.Text = "Auto Click (Necessário): ON"
        ClickBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        ClickBox.Text = "Auto Click (Necessário): OFF"
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
    LineFolder:Destroy()
end)