--[[
    🏆 SAO LEGACY BOT v11 (BACK TO BASICS)
    
    RETORNO ÀS ORIGENS:
    - Usa a lógica antiga de leitura de poder (que funcionava).
    - Adiciona leitura do número flutuante na cabeça (Backup).
    - Teleporte direto e agressivo para o portal.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloLegacy = true

-- // UI SETUP SIMPLIFICADA //
if CoreGui:FindFirstChild("LegacyUI") then CoreGui.LegacyUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LegacyUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏆 SOLO BOT v11"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 30)
PowerLabel.Position = UDim2.new(0, 0, 0.25, 0)
PowerLabel.Text = "LENDO PODER..."
PowerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Font = Enum.Font.GothamBold
PowerLabel.TextSize = 16

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0.45, 0)
StatusLabel.Text = "Aguardando..."
StatusLabel.TextColor3 = Color3.white
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Code

local StartBtn = Instance.new("TextButton", MainFrame)
StartBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
StartBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
StartBtn.Text = "INICIAR AUTO-DUNGEON"
StartBtn.TextColor3 = Color3.white
StartBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // VARIÁVEIS //
local MyPower = 0
local IsRunning = false

-- // FUNÇÃO 1: LER PODER (A MÁGICA) //
local function GetPower()
    local p = 0
    
    -- TENTATIVA 1: Leaderstats (Clássico)
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("força") then
                p = v.Value
            end
        end
    end
    
    -- TENTATIVA 2: Número na Cabeça (Visual)
    if p == 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        for _, gui in ipairs(LocalPlayer.Character.Head:GetChildren()) do
            if gui:IsA("BillboardGui") then
                for _, lbl in ipairs(gui:GetChildren()) do
                    if lbl:IsA("TextLabel") then
                        local num = tonumber(lbl.Text:gsub(",", "")) -- Tira virgula
                        if num and num > p then p = num end
                    end
                end
            end
        end
    end
    
    -- TENTATIVA 3: GUI da Tela (HUD)
    if p == 0 then
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, v in ipairs(gui:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local txt = v.Text:upper():gsub(",", "")
                    if txt:match("PODER") then
                        local num = tonumber(txt:match("%d+"))
                        if num and num > p then p = num end
                    end
                end
            end
        end
    end
    
    MyPower = p
    PowerLabel.Text = "PODER: " .. MyPower
    return p
end

-- // FUNÇÃO 2: TELEPORTAR E ENTRAR //
local function TeleportToPortal()
    GetPower()
    
    if MyPower == 0 then
        StatusLabel.Text = "⚠️ Poder não identificado!"
        return
    end
    
    StatusLabel.Text = "🔍 Buscando Portal..."
    
    local bestPortal = nil
    local bestReq = -1
    
    -- Varre Workspace procurando "PortalModel"
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "PortalModel" then
            
            local req = 0
            -- Lê a placa do portal
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:lower():gsub(",", "")
                    if txt:match("poder") then
                        local num = tonumber(txt:match("%d+"))
                        if num then req = num end
                    end
                end
            end
            
            -- Lógica: Requisito <= Meu Poder (e escolhe o maior possível)
            if req <= MyPower then
                if req > bestReq then
                    bestReq = req
                    bestPortal = obj
                end
            end
        end
    end
    
    if bestPortal then
        StatusLabel.Text = "⚡ Indo p/ Portal " .. bestReq
        
        -- Acha a parte física pra teleportar
        local target = bestPortal:FindFirstChild("ProximityPart") 
                    or bestPortal.PrimaryPart 
                    or bestPortal:FindFirstChildWhichIsA("BasePart")
        
        if target then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- TELEPORTE
                char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 2, 0)
                
                task.wait(0.2)
                -- ENTRADA (TOUCH + PROMPT)
                firetouchinterest(char.HumanoidRootPart, target, 0)
                firetouchinterest(char.HumanoidRootPart, target, 1)
                
                for _, pp in ipairs(bestPortal:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                end
                
                StatusLabel.Text = "🌀 Entrando..."
                task.wait(2)
            end
        end
    else
        StatusLabel.Text = "❌ Nenhum portal para Poder " .. MyPower
    end
end

-- // CONTROLES //
StartBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        StartBtn.Text = "PARAR"
        StartBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        StartBtn.Text = "INICIAR AUTO-DUNGEON"
        StartBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLabel.Text = "Parado."
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloLegacy = false
    ScreenGui:Destroy()
end)

-- Loop
spawn(function()
    while getgenv().SoloLegacy do
        task.wait(1) -- Verifica a cada 1 segundo
        if IsRunning then
            -- Só tenta entrar se não estiver lutando (checa se tem mobs perto)
            local nearbyMobs = false
            local mobFolder = Workspace:FindFirstChild("Mobs")
            if mobFolder then
                local char = LocalPlayer.Character
                if char then
                    for _, m in ipairs(mobFolder:GetChildren()) do
                         if m:FindFirstChild("HumanoidRootPart") and (m.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude < 100 then
                            nearbyMobs = true
                            break
                        end
                    end
                end
            end
            
            if not nearbyMobs then
                TeleportToPortal()
            else
                StatusLabel.Text = "⚔️ Lutando..."
            end
        end
    end
end)

-- Atualiza poder ao iniciar
GetPower()