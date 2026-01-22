--[[
    📜 SAO LOG-BASED TELEPORT (FINAL FIX)
    
    BASEADO NO SEU LOG:
    - Alvos: "PortalModel" e "RedPortalModel".
    - Caminho: model.ProximityPart.ProximityPrompt
    - Ação: Teleporte + FireProximityPrompt.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloLogBased = true

-- // UI SETUP //
if CoreGui:FindFirstChild("SoloLogUI") then CoreGui.SoloLogUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloLogUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📜 LOG-BASED TELEPORT"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR AUTO-DUNGEON"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- VARIÁVEIS DE CONTROLE
local IsRunning = false
local MyPower = 0

-- // 1. LEITOR DE PODER (MOTOR v4 - FUNCIONAL) //
local function UpdatePlayerPower()
    local power = 0
    
    -- Tenta Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") then
                power = v.Value
                break
            end
        end
    end
    
    -- Tenta GUI
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

-- // 2. LÓGICA DE TELEPORTE BASEADA NO LOG //
local function ScanAndEnter()
    UpdatePlayerPower()
    
    -- Se não leu poder, não faz nada pra não bugar
    if MyPower == 0 then 
        Status.Text = "⚠️ Aguardando leitura de poder..."
        return 
    end
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        -- Baseado no seu Log: "PortalModel" ou "RedPortalModel"
        if obj.Name == "PortalModel" or obj.Name == "RedPortalModel" then
            
            -- Tenta ler requisito (Plaquinhas)
            local reqPower = 0
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:lower():gsub(",", "") -- Remove vírgula
                    local num = tonumber(txt:match("%d+"))
                    
                    if num and num > 50 then -- Filtra números pequenos
                        reqPower = num
                        if txt:match("poder") then break end -- Se achou escrito "poder", confirma
                    end
                end
            end
            
            -- LÓGICA DE ESCOLHA
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    -- AÇÃO FINAL
    if bestPortal then
        -- Procura a parte exata baseada no LOG
        local targetPart = bestPortal:FindFirstChild("ProximityPart")
        
        -- Fallback: Se não achar ProximityPart, tenta Gate (visto no log tbm)
        if not targetPart then
            if bestPortal:FindFirstChild("Gate") then
                targetPart = bestPortal.Gate:FindFirstChild("ProximityAttachment")
            end
        end
        
        if targetPart then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - targetPart.Position).Magnitude
                
                -- Se longe -> Teleporta
                if dist > 5 then
                    Status.Text = "⚡ TP: Portal " .. highestReq
                    char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
                else
                    Status.Text = "🌀 Entrando..."
                end
                
                -- DISPARA O PROMPT (Baseado no Log)
                task.wait(0.1)
                for _, child in ipairs(targetPart:GetChildren()) do
                    if child:IsA("ProximityPrompt") then
                        fireproximityprompt(child)
                        print("Prompt Disparado!")
                    end
                end
            end
        end
    else
        Status.Text = "❌ Nenhum portal acessível."
    end
end

-- // CONTROLES //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloLogBased = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR AUTO-DUNGEON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    end
end)

-- LOOP
spawn(function()
    while getgenv().SoloLogBased do
        task.wait(0.5)
        if IsRunning then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                ScanAndEnter()
            end
        end
    end
end)