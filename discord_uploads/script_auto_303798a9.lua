--[[
    🌀 SAO PORTAL ONLY (NO COMBAT)
    
    CORREÇÃO:
    - Removida toda a lógica de combate/mobs.
    - O script não vai mais atacar Goblins na cidade.
    - Foco 100% em: Ler Poder -> Achar Portal -> Teleportar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloPortalOnly = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("SoloPortalUI") then CoreGui.SoloPortalUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloPortalUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 160)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🌀 PORTAL ONLY"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 25)
PowerLabel.Position = UDim2.new(0, 0, 0.2, 0)
PowerLabel.Text = "LENDO PODER..."
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
ToggleBtn.Text = "LIGAR TELEPORTE"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // LEITOR DE PODER (QUE FUNCIONA) //
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
    
    -- 2. Tela (Visual)
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

-- // TELEPORTADOR //
local function TeleportToPortal()
    UpdatePlayerPower()
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varre o mapa
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê a placa
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    if num and num > 50 then 
                        reqPower = num
                    end
                end
            end
            
            -- Lógica: Requisito <= Meu Poder
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    if bestPortal then
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- CHECAGEM DE DISTÂNCIA (Opcional, pra não spammar)
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local dist = (myPos - trigger.Position).Magnitude
        
        if dist > 5 then
            Status.Text = "⚡ TELEPORTANDO: Portal " .. highestReq
            
            -- TELEPORTE
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
            end
        else
            Status.Text = "🌀 ENTRANDO..."
        end
        
        -- INTERAÇÃO (SEMPRE TENTA ENTRAR)
        task.wait(0.1)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
        end
    else
        Status.Text = "⚠️ Nenhum portal compatível!"
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloPortalOnly = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        UpdatePlayerPower()
    else
        ToggleBtn.Text = "LIGAR TELEPORTE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SoloPortalOnly do
        task.wait(0.2) -- Verifica rápido
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                TeleportToPortal()
            end
        end
    end
end)