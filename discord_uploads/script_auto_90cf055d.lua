--[[
    ⚡ SAO TELEPORT v8 (MANUAL INPUT FIX)
    
    PROBLEMA RESOLVIDO:
    - Se o script não ler o poder, VOCÊ DIGITA manualmente.
    - Mostra quantos portais achou e por que não entrou.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloV8 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    SearchDelay = 1, -- Procura a cada 1 segundo
}

-- Estados
local IsRunning = false
local MyPower = 0 -- Começa zerado, você edita se precisar

-- // UI SETUP //
if CoreGui:FindFirstChild("SoloV8UI") then CoreGui.SoloV8UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloV8UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 200, 0) -- Amarelo
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ TELEPORT BOT v8"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- Input de Poder (A CORREÇÃO)
local PowerBox = Instance.new("TextBox", MainFrame)
PowerBox.Size = UDim2.new(0.5, 0, 0.2, 0)
PowerBox.Position = UDim2.new(0.25, 0, 0.15, 0)
PowerBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
PowerBox.TextColor3 = Color3.white
PowerBox.Text = "900" -- Valor padrão pra não bugar
PowerBox.PlaceholderText = "Digite seu Poder..."
PowerBox.Font = Enum.Font.GothamBold
PowerBox.TextSize = 20

local LabelPoder = Instance.new("TextLabel", MainFrame)
LabelPoder.Size = UDim2.new(1, 0, 0, 15)
LabelPoder.Position = UDim2.new(0, 0, 0.36, 0)
LabelPoder.Text = "^ SEU PODER AQUI ^"
LabelPoder.TextColor3 = Color3.fromRGB(150, 150, 150)
LabelPoder.BackgroundTransparency = 1

local StatusLog = Instance.new("TextLabel", MainFrame)
StatusLog.Size = UDim2.new(0.9, 0, 0.25, 0)
StatusLog.Position = UDim2.new(0.05, 0, 0.45, 0)
StatusLog.Text = "Status: Aguardando..."
StatusLog.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLog.BackgroundTransparency = 1
StatusLog.TextWrapped = true
StatusLog.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR TELEPORTE"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÃO DE TELEPORTE //
local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

-- // SCANNER PRINCIPAL //
local function FindBestPortal()
    -- Pega o poder da caixinha (Convertendo texto pra número)
    local inputPower = tonumber(PowerBox.Text)
    if not inputPower then
        StatusLog.Text = "⚠️ ERRO: Digite apenas números no Poder!"
        return
    end
    MyPower = inputPower
    
    StatusLog.Text = "🔍 Buscando portal para Poder " .. MyPower .. "..."
    
    local bestPortal = nil
    local bestReq = -1
    local foundCount = 0
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName then
            foundCount = foundCount + 1
            
            -- Verifica se tem gatilho
            local trigger = obj:FindFirstChild(SETTINGS.PortalTrigger)
            if trigger then
                
                local reqPower = 0
                -- Tenta ler plaquinhas
                for _, gui in ipairs(obj:GetDescendants()) do
                    if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                        local txt = gui.Text:lower():gsub(",", "") -- Tira virgula
                        -- Procura números grandes
                        local num = tonumber(txt:match("%d+"))
                        if num and num > 50 then -- Filtro de numero pequeno
                            reqPower = num
                            -- Se tiver escrito "Poder", confia mais
                            if txt:match("poder") then break end
                        end
                    end
                end
                
                -- Lógica de Escolha
                if reqPower <= MyPower then
                    if reqPower > bestReq then
                        bestReq = reqPower
                        bestPortal = obj
                    end
                end
            end
        end
    end
    
    if foundCount == 0 then
        StatusLog.Text = "⚠️ Nenhum 'PortalModel' encontrado no mapa!"
        return
    end
    
    if bestPortal then
        StatusLog.Text = "✅ ALVO: Portal Poder " .. bestReq
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- TELEPORTA
        TeleportTo(trigger.CFrame * CFrame.new(0, 2, 0))
        
        -- TENTA ENTRAR
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then 
                fireproximityprompt(pp)
                StatusLog.Text = "🌀 Interagindo com Portal..."
            end
        end
    else
        StatusLog.Text = "❌ Achei " .. foundCount .. " portais, mas todos exigem mais que " .. MyPower
    end
end

-- // LOOP //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloV8 = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR TELEPORTE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    end
end)

spawn(function()
    while getgenv().SoloV8 do
        task.wait(SETTINGS.SearchDelay)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Só procura portal se não tiver mobs por perto (Lobby)
                -- (Adicionei essa checagem simples pra ele não teleportar no meio da luta)
                local nearbyMobs = false
                local mobFolder = Workspace:FindFirstChild("Mobs")
                if mobFolder then
                    for _, m in ipairs(mobFolder:GetChildren()) do
                        if m:FindFirstChild("HumanoidRootPart") and (m.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude < 50 then
                            nearbyMobs = true
                            break
                        end
                    end
                end
                
                if not nearbyMobs then
                    FindBestPortal()
                else
                    StatusLog.Text = "⚔️ Combate detectado! Pausando TP."
                end
            end
        end
    end
end)