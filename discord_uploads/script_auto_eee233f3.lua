--[[
    👻 RPG SPECTRAL SWORD v42 (HANDLE TP)
    
    ESTRATÉGIA "CORPO NA BASE, ESPADA NO INIMIGO":
    1. Mantém seu personagem (HumanoidRootPart) seguro na base.
    2. Teleporta a PEÇA DE DANO (Handle) da sua arma até o inimigo.
    3. Ativa a ferramenta e simula o toque.
    
    Isso engana o servidor: Ele vê a arma tocando no monstro e valida o dano.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SpectralFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    AttackSpeed = 0.1,    -- Velocidade do ataque
    KillRange = 3000,     -- Alcance (Mapa todo)
    TeleportHandle = true -- O segredo do script
}

-- // GUI SETUP //
if CoreGui:FindFirstChild("SpectralSword") then CoreGui.SpectralSword:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SpectralSword"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 30)
MainFrame.BorderColor3 = Color3.fromRGB(200, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "👻 SPECTRAL SWORD v42"
Title.TextColor3 = Color3.fromRGB(200, 50, 255)
Title.Font = Enum.Font.GothamBlack
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
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
ToggleBtn.Text = "LIGAR ESPADA ESPIRITUAL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO LIMPEZA //
local function RestoreWeapon()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            -- Tenta devolver a arma pra mão (Reset simples)
            tool.Parent = LocalPlayer.Backpack
            task.wait(0.1)
            tool.Parent = char
        end
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SpectralFarm = false
    RestoreWeapon()
    ScreenGui:Destroy()
end)

-- // LOCALIZA PASTA //
local function GetTargetFolder()
    -- Prioridade: Pasta que descobrimos na autópsia
    if Workspace:FindFirstChild("Client") and Workspace.Client:FindFirstChild("Enemies") then
        return Workspace.Client.Enemies
    end
    -- Fallback
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Enemies") then
            return child
        end
    end
    return Workspace
end

-- // LÓGICA PRINCIPAL //
local isRunning = false
local lastAttack = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR ESPADA ESPIRITUAL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
        RestoreWeapon()
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().SpectralFarm or not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
        return
    end
    
    -- Verifica se a arma tem Handle (parte física)
    local handle = tool:FindFirstChild("Handle")
    if not handle then 
        Status.Text = "⚠️ Arma sem 'Handle'!"
        return 
    end
    
    -- Busca Alvo
    local folder = GetTargetFolder()
    local target = nil
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and root and hum.Health > 0 then
            -- Pega o primeiro vivo que achar
            target = mob
            break
        end
    end
    
    if target then
        local tRoot = target.HumanoidRootPart
        Status.Text = "⚔️ CEIFANDO: " .. target.Name
        
        -- A MÁGICA: Teleporta o Handle da arma para dentro do inimigo
        -- Desliga a solda manual se precisar (Massless ajuda)
        handle.Massless = true
        
        -- Move a espada para o inimigo (CFrame)
        -- Fica "sambando" dentro dele pra garantir o toque
        handle.CFrame = tRoot.CFrame * CFrame.Angles(math.random(), math.random(), math.random())
        
        -- Ativa o dano
        tool:Activate()
        
        -- FireTouchInterest (Força Bruta se o TP não bastar)
        if firetouchinterest then
            firetouchinterest(handle, tRoot, 0)
            firetouchinterest(handle, tRoot, 1)
        end
        
    else
        Status.Text = "Procurando Almas..."
        -- Traz a espada de volta pra mão (Visual)
        if char:FindFirstChild("RightHand") then
            -- handle.CFrame = char.RightHand.CFrame -- Opcional
        end
    end
end)