--[[
    🩸 SAO HYBRID BOT (THE WORKING ONE)
    
    BASE: O script v4 que você confirmou que lê o poder.
    MODIFICAÇÃO: 
    - Mantém o Equipar Arma (Essencial para ler o poder).
    - Remove a parte de seguir Mobs.
    - Adiciona o Teleporte Instantâneo para o Portal.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloHybrid = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // UI SETUP //
if CoreGui:FindFirstChild("SoloHybridUI") then CoreGui.SoloHybridUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloHybridUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 10) -- Vermelho Escuro
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🩸 HYBRID BOT (FIX)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 30)
PowerLabel.Position = UDim2.new(0, 0, 0.2, 0)
PowerLabel.Text = "AGUARDANDO ARMA..."
PowerLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.4, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.white
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "LIGAR (IGUAL O ANTIGO)"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÕES ESSENCIAIS (DO SCRIPT QUE FUNCIONA) //

local function EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Tenta equipar tecla 1 (Simulação de Teclado)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
    
    -- Tenta equipar do inventário (Caso mobile/touch)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local tool = bp:FindFirstChildOfClass("Tool")
        if tool then char.Humanoid:EquipTool(tool) end
    end
end

local function UpdatePlayerPower()
    local power = 0
    
    -- 1. Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") then
                power = v.Value
                break
            end
        end
    end
    
    -- 2. GUI (Tela)
    if power == 0 then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in ipairs(pGui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local txt = v.Text:lower()
                    if txt:match("poder") or txt:match("power") then
                        local num = tonumber(txt:match("%d+"))
                        if num and num > power then power = num end
                    end
                end
            end
        end
    end
    
    MyPower = power
    PowerLabel.Text = "PODER LIDO: " .. MyPower
    return power
end

local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

-- // LÓGICA PRINCIPAL //

local function MainLoop()
    -- 1. EQUIPA ARMA (Pra atualizar o status)
    EquipWeapon()
    
    -- 2. LÊ O PODER
    UpdatePlayerPower()
    
    if MyPower == 0 then
        Status.Text = "⚠️ Tentando ler poder..."
        return
    end
    
    -- 3. PROCURA PORTAL
    local bestPortal = nil
    local highestReq = -1
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    if num and num > 50 then reqPower = num end
                end
            end
            
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    -- 4. AÇÃO (TELEPORTE)
    if bestPortal then
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- Checa distância pra não spammar TP se já tiver lá
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        if (myPos - trigger.Position).Magnitude > 5 then
            Status.Text = "⚡ TP: Portal " .. highestReq
            TeleportTo(trigger.CFrame * CFrame.new(0, 2, 0))
        else
            Status.Text = "🌀 Entrando..."
        end
        
        -- INTERAGE (SPAM)
        task.wait(0.1)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
        end
    else
        Status.Text = "❌ Sem portal pro seu nível"
    end
end

-- // CONTROLES //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloHybrid = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    else
        ToggleBtn.Text = "LIGAR (IGUAL O ANTIGO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    end
end)

spawn(function()
    while getgenv().SoloHybrid do
        task.wait(0.5)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                MainLoop()
            end
        end
    end
end)