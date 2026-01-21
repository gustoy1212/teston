--[[
    ⚔️ SAO HUNTER v1 (AUTO BOAR)
    
    ALVO: Workspace.Mobs (Qualquer Mob com ID numérico)
    ESTRATÉGIA: Spirit Blade (Visual Perto + Espada Longe).
    
    COMO FUNCIONA:
    - O script ignora os nomes aleatórios (Mob176...).
    - Pega qualquer coisa viva dentro da pasta 'Mobs'.
    - Traz visualmente para você ver.
    - Manda sua espada (Handle) para a posição real para dar dano.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOHunter = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    VisualDist = 3,       -- O bicho fica a 3 metros de você (Visual)
    SearchRange = 3000,   -- Raio de busca (3km)
    HitboxSize = 15,      -- Tamanho do alvo
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalPos = nil -- Onde o bicho está de verdade

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOHunterUI") then CoreGui.SAOHunterUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOHunterUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 30) -- Azul Tecnológico SAO
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ SAO HUNTER (BOAR)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "LIGAR LINK START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function ResetTarget()
    -- Tenta devolver o bicho pro lugar se ainda estiver vivo
    if CurrentTarget and CurrentTarget:FindFirstChild("HumanoidRootPart") and OriginalPos then
        CurrentTarget.HumanoidRootPart.CFrame = OriginalPos
        CurrentTarget.HumanoidRootPart.Transparency = 0
    end
    CurrentTarget = nil
    OriginalPos = nil
    
    -- Reseta a arma
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool.Parent = LocalPlayer.Backpack tool.Parent = char end
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOHunter = false
    ResetTarget()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        ToggleBtn.Text = "LIGAR LINK START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
        ResetTarget()
    end
end)

-- // LÓGICA PRINCIPAL //
RunService.Heartbeat:Connect(function()
    if not getgenv().SAOHunter or not IsRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- 1. GERENCIA ALVO ATUAL
    if CurrentTarget then
        local hum = CurrentTarget:FindFirstChild("Humanoid")
        local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
        
        -- Verifica se morreu ou sumiu
        if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
            ResetTarget() -- Busca próximo
        else
            Status.Text = "⚔️ COMBATE: Javali/Mob"
            
            -- [CLIENTE] Traz visualmente pra perto
            local visualPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -SETTINGS.VisualDist)
            root.CFrame = visualPos
            root.Velocity = Vector3.new(0,0,0)
            root.CanCollide = false
            root.Transparency = 0.5 -- Meio invisível
            
            -- Hitbox Visual Gigante
            root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
            root.Color = Color3.fromRGB(0, 255, 255)
            
            -- [SERVIDOR] Manda a espada pra posição REAL (OriginalPos)
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") and OriginalPos then
                tool.Handle.Massless = true
                -- Teleporta o Dano (Handle) lá pro mato onde o bicho tá
                tool.Handle.CFrame = OriginalPos
                
                tool:Activate() -- Auto Click
                
                -- Force Touch (Dano Físico)
                if firetouchinterest then
                    firetouchinterest(tool.Handle, root, 0)
                    firetouchinterest(tool.Handle, root, 1)
                end
            else
                Status.Text = "⚠️ EQUIPE A ESPADA!"
            end
            
            return
        end
    end
    
    -- 2. BUSCA NOVO ALVO NA PASTA 'MOBS'
    local folder = Workspace:FindFirstChild("Mobs")
    if not folder then 
        Status.Text = "Pasta 'Mobs' não encontrada!" 
        return 
    end
    
    local closest, minDist = nil, SETTINGS.SearchRange
    
    for _, mob in ipairs(folder:GetChildren()) do
        -- Filtro: Tem Humanoid? Tem Vida? Tem RootPart?
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    
    if closest then
        CurrentTarget = closest
        OriginalPos = closest.HumanoidRootPart.CFrame -- Salva a posição real
    else
        Status.Text = "Procurando Javalis..."
    end
end)