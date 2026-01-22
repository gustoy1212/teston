--[[
    🩸 SAO v4.5 - TELEPORT ONLY
    
    BASEADO NO SEU SCRIPT v4 (QUE FUNCIONA):
    - Mantido: Leitura de Poder e Leitura de Placas.
    - Removido: Mobs, Ataque, Caminhada.
    - Adicionado: Teleporte direto para o gatilho do portal.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloTeleport = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // UI SETUP //
if CoreGui:FindFirstChild("SoloTeleportUI") then CoreGui.SoloTeleportUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloTeleportUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🩸 TELEPORT ONLY (v4 BASE)"
Title.TextColor3 = Color3.fromRGB(150, 0, 255)
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
Status.Position = UDim2.new(0, 0, 0.45, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
ToggleBtn.Text = "LIGAR TELEPORTE"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // LEITOR DE PODER (EXATAMENTE COMO NO SEU SCRIPT) //
local function UpdatePlayerPower()
    local power = 0
    
    -- 1. Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") or n:match("força") then
                power = v.Value
                break
            end
        end
    end
    
    -- 2. PlayerGui
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

-- // TELEPORTE (LÓGICA SIMPLIFICADA) //
local function TeleportToPortal()
    UpdatePlayerPower() -- Garante poder atualizado
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê placas (igual seu script)
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    if num and num > 50 then -- Filtro pra não pegar nível baixo
                        reqPower = num
                    end
                end
            end
            
            -- LÓGICA: Escolhe o portal mais forte que eu aguento
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    if bestPortal then
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- Checa distância pra não ficar teleportando no mesmo lugar
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local dist = (myRoot.Position - trigger.Position).Magnitude
            
            if dist > 5 then
                Status.Text = "⚡ TELEPORTANDO: Portal " .. highestReq
                -- TP
                myRoot.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
            else
                Status.Text = "🌀 TENTANDO ENTRAR..."
            end
            
            -- INTERAÇÃO (ABRE O PORTAL)
            task.wait(0.1)
            firetouchinterest(myRoot, trigger, 0)
            firetouchinterest(myRoot, trigger, 1)
            
            for _, pp in ipairs(trigger:GetChildren()) do
                if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
            end
        end
    else
        Status.Text = "⚠️ Nenhum portal compatível!"
    end
end

-- // BOTÕES E LOOP //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloTeleport = false
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 100)
    end
end)

spawn(function()
    while getgenv().SoloTeleport do
        task.wait(0.5)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                TeleportToPortal()
            end
        end
    end
end)