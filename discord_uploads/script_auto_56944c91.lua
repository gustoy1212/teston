--[[
    🚀 SAO TELEPORT FINAL v5 (WEAPON TRIGGER)
    
    CORREÇÃO CRÍTICA:
    - Força equipar a arma ao iniciar para atualizar o status de Poder (Bug do jogo).
    - Usa o leitor de poder da v4 (que funciona).
    - Remove todo o combate. Apenas: Equipar -> Ler -> Teleportar -> Entrar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloFinal = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("SoloFinalUI") then CoreGui.SoloFinalUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloFinalUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚀 TELEPORT FINAL"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 30)
PowerLabel.Position = UDim2.new(0, 0, 0.2, 0)
PowerLabel.Text = "LENDO PODER..."
PowerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR BOT"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÕES CRÍTICAS //

-- 1. EQUIPAR ARMA (O SEGREDO PARA LER O PODER)
local function ForceEquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Se já tiver ferramenta equipada, ignora
    if char:FindFirstChildOfClass("Tool") then return end
    
    Status.Text = "⚔️ Equipando para ler status..."
    
    -- Tenta equipar do inventário
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local tool = bp:FindFirstChildOfClass("Tool")
        if tool then 
            char.Humanoid:EquipTool(tool)
            task.wait(0.5) -- Espera o jogo atualizar o status
        end
    end
    
    -- Tenta simular tecla 1 e 2 (caso backpack falhe)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- 2. LEITOR DE PODER (MOTOR V4)
local function UpdatePlayerPower()
    local power = 0
    
    -- Tenta ler Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") then
                power = v.Value
                break
            end
        end
    end
    
    -- Tenta ler GUI (Funciona melhor com arma na mão)
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
    PowerLabel.Text = "SEU PODER: " .. MyPower
    return power
end

-- 3. TELEPORTE (SEM COMBATE)
local function TeleportToBestPortal()
    -- Garante que o poder está atualizado
    UpdatePlayerPower()
    
    if MyPower == 0 then
        Status.Text = "⚠️ Equipe a arma para ler o poder!"
        ForceEquipWeapon() -- Tenta forçar de novo
        return
    end
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê a placa
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    if num and num > 50 then reqPower = num end
                end
            end
            
            -- Lógica Simples: Posso entrar? É o mais forte?
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    if bestPortal then
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- CHECA SE ESTOU LONGE (Pra não ficar teleportando no lugar)
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local dist = (myPos - trigger.Position).Magnitude
        
        if dist > 5 then
            Status.Text = "⚡ Teleportando: Portal " .. highestReq
            -- Teleporte
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
            end
        else
            Status.Text = "🌀 Entrando..."
        end
        
        -- TENTA ENTRAR
        task.wait(0.2)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
        end
    else
        Status.Text = "❌ Nenhum portal para Poder " .. MyPower
    end
end

-- // UI E CONTROLES //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloFinal = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        ForceEquipWeapon() -- O GATILHO MÁGICO
    else
        ToggleBtn.Text = "LIGAR BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    end
end)

-- LOOP
spawn(function()
    while getgenv().SoloFinal do
        task.wait(0.5)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                TeleportToBestPortal()
            end
        end
    end
end)