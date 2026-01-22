--[[
    🩸 SAO PURE TELEPORT (CLEAN VERSION)
    
    BASE: Código de leitura do v4 (que você confirmou que funciona).
    AÇÃO: Apenas Teleporte para Portal.
    REMOVIDO: Combate, Armas, Mobs, Loot, Caminhada.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloClean = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // UI //
if CoreGui:FindFirstChild("SoloCleanUI") then CoreGui.SoloCleanUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloCleanUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🩸 PURE TELEPORT"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 30)
PowerLabel.Position = UDim2.new(0, 0, 0.2, 0)
PowerLabel.Text = "LENDO PODER..."
PowerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 0)
ToggleBtn.Text = "LIGAR AUTO-PORTAL"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // LEITOR DE PODER (CÓPIA EXATA DO SEU SCRIPT v4) //
local function UpdatePlayerPower()
    local power = 0
    
    -- 1. Tenta Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") or n:match("força") then
                power = v.Value
                break
            end
        end
    end
    
    -- 2. Tenta na Tela (PlayerGui)
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

-- // TELEPORTE (LÓGICA LIMPA) //
local function TeleportToPortal()
    UpdatePlayerPower()
    
    if MyPower == 0 then
        Status.Text = "⚠️ Poder Zero/Não lido"
        return
    end
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varre Workspace procurando APENAS Portais
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê as placas
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    
                    if num and num > 10 then -- Filtro básico
                        reqPower = num
                    end
                end
            end
            
            -- LÓGICA: Requisito <= Meu Poder
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    if bestPortal then
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- Checa distância (pra não ficar teleportando no mesmo lugar)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = LocalPlayer.Character.HumanoidRootPart.Position
            local dist = (myPos - trigger.Position).Magnitude
            
            if dist > 5 then
                Status.Text = "⚡ Teleportando: Portal " .. highestReq
                -- TP
                LocalPlayer.Character.HumanoidRootPart.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
            else
                Status.Text = "🌀 Entrando..."
            end
            
            -- TENTA ENTRAR
            task.wait(0.1)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
            
            for _, pp in ipairs(trigger:GetChildren()) do
                if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
            end
        end
    else
        Status.Text = "❌ Sem portal compatível"
    end
end

-- // CONTROLES //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloClean = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        UpdatePlayerPower()
    else
        ToggleBtn.Text = "LIGAR AUTO-PORTAL"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 0)
    end
end)

-- Loop Rápido (0.5s)
spawn(function()
    while getgenv().SoloClean do
        task.wait(0.5)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                TeleportToPortal()
            end
        end
    end
end)