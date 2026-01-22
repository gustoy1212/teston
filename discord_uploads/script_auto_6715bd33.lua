--[[
    🚪 SAO PORTAL RUNNER (PACIFIST MODE)
    
    OBJETIVO ÚNICO: Encontrar e Entrar em Portais.
    CORREÇÕES:
    1. Ignora completamente Goblins/Mobs da cidade.
    2. Lê números com vírgula (Ex: "1,400" vira 1400).
    3. Foca em encontrar a "ProximityPart" dentro do "PortalModel".
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().PortalRunner = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    StuckThreshold = 0.5, -- Se andar menos que isso, pula
}

-- Estados
local IsRunning = false
local CurrentPortal = nil
local TargetPart = nil
local MyPower = 0
local LastPos = Vector3.new(0,0,0)
local LastMoveTime = 0

-- // VISUAL (LINHA VERDE) //
local Line = Drawing.new("Line")
Line.Visible = false
Line.Color = Color3.new(0, 1, 0) -- Verde Matrix
Line.Thickness = 3
Line.Transparency = 1

local function UpdateLine(targetPos)
    if not IsRunning or not targetPos then 
        Line.Visible = false 
        return 
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(char.HumanoidRootPart.Position)
    local destPos, destOnScreen = Workspace.CurrentCamera:WorldToViewportPoint(targetPos)
    
    if onScreen and destOnScreen then
        Line.From = Vector2.new(rootPos.X, rootPos.Y)
        Line.To = Vector2.new(destPos.X, destPos.Y)
        Line.Visible = true
    else
        Line.Visible = false
    end
end

-- // UI SETUP //
if CoreGui:FindFirstChild("PortalRunnerUI") then CoreGui.PortalRunnerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PortalRunnerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 220)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🚪 PORTAL RUNNER (AUTO)"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerInfo = Instance.new("TextLabel", MainFrame)
PowerInfo.Size = UDim2.new(1, 0, 0, 25)
PowerInfo.Position = UDim2.new(0, 0, 0.15, 0)
PowerInfo.Text = "MEU PODER: ???"
PowerInfo.TextColor3 = Color3.fromRGB(255, 200, 0)
PowerInfo.BackgroundTransparency = 1
PowerInfo.Font = Enum.Font.GothamBold

local TargetInfo = Instance.new("TextLabel", MainFrame)
TargetInfo.Size = UDim2.new(1, 0, 0, 40)
TargetInfo.Position = UDim2.new(0, 0, 0.3, 0)
TargetInfo.Text = "Alvo: Nenhum"
TargetInfo.TextColor3 = Color3.white
TargetInfo.BackgroundTransparency = 1
TargetInfo.TextWrapped = true
TargetInfo.Font = Enum.Font.Code

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.5, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR BUSCA"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // MOVIMENTAÇÃO INTELIGENTE (UNSTUCK) //
local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
        
        -- Se estiver andando mas travado na parede
        if tick() - LastMoveTime > 0.5 then
            if (char.HumanoidRootPart.Position - LastPos).Magnitude < SETTINGS.StuckThreshold then
                char.Humanoid.Jump = true -- Pula obstáculo
            end
            LastPos = char.HumanoidRootPart.Position
            LastMoveTime = tick()
        end
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

local function SetSprint(enable)
    local vim = game:GetService("VirtualInputManager")
    if enable then
        vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    else
        vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

-- // LEITURA DE PODER (OCR) //
local function GetMyPower()
    local power = 0
    -- Procura na UI (PlayerGui)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                local txt = v.Text:lower():gsub(",", "") -- Remove vírgula
                if txt:match("poder") or txt:match("power") then
                    -- Pega o número depois da palavra
                    local num = tonumber(txt:match("%d+"))
                    if num and num > power then power = num end
                end
            end
        end
    end
    
    -- Backup: Leaderstats
    if power == 0 and LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            if v.Name:lower():match("power") then power = v.Value end
        end
    end
    
    MyPower = power
    PowerInfo.Text = "MEU PODER: " .. (MyPower > 0 and MyPower or "Não achado")
    return power
end

-- // LÓGICA DE ESCOLHA DE PORTAL //
local function FindBestPortal()
    local bestObj = nil
    local bestReq = -1
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local closestDist = 99999
    
    GetMyPower() -- Atualiza poder
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Busca pelo NOME EXATO que você achou no scanner
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê a plaquinha do portal
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local rawText = gui.Text:lower():gsub(",", "") -- Remove vírgula (1,400 -> 1400)
                    local num = tonumber(rawText:match("%d+"))
                    
                    if num and num > 50 then -- Filtra números pequenos (player count)
                        reqPower = num
                        -- Se tiver "Poder" escrito perto, confirma mais ainda
                        if rawText:match("poder") then break end
                    end
                end
            end
            
            -- LÓGICA DE SELEÇÃO:
            -- 1. Eu tenho poder suficiente? (Req <= MyPower)
            if reqPower <= MyPower then
                -- 2. É o portal mais forte que achei? (Req > bestReq)
                -- OU se for igual, é o mais perto?
                local dist = (myPos - obj[SETTINGS.PortalTrigger].Position).Magnitude
                
                if reqPower > bestReq then
                    bestReq = reqPower
                    bestObj = obj
                    closestDist = dist
                elseif reqPower == bestReq then
                    if dist < closestDist then
                        bestObj = obj
                        closestDist = dist
                    end
                end
            end
        end
    end
    
    return bestObj, bestReq
end

-- // INTERFACE //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().PortalRunner = false
    Line:Remove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR BUSCA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        StopMove()
        CurrentPortal = nil
        TargetPart = nil
        Line.Visible = false
    end
end)

-- // LOOP PRINCIPAL //
RunService.RenderStepped:Connect(function()
    if IsRunning and TargetPart then UpdateLine(TargetPart.Position) else UpdateLine(nil) end
end)

spawn(function()
    while getgenv().PortalRunner do
        task.wait(0.2)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            -- Se não tenho portal alvo, procura um
            if not CurrentPortal then
                Status.Text = "🔎 ESCANEANDO..."
                local pObj, pReq = FindBestPortal()
                
                if pObj then
                    CurrentPortal = pObj
                    TargetPart = pObj[SETTINGS.PortalTrigger]
                    TargetInfo.Text = "Indo para: Portal " .. pReq .. "\n(Distância: " .. math.floor((char.HumanoidRootPart.Position - TargetPart.Position).Magnitude) .. "m)"
                    Status.Text = "🏃 EM MOVIMENTO"
                else
                    Status.Text = "⚠️ NENHUM PORTAL COMPATÍVEL"
                    TargetInfo.Text = "Alvo: -"
                    -- Se não achar nada, tenta atualizar poder de novo
                    GetMyPower()
                end
            end
            
            -- Se tenho alvo, anda até ele
            if TargetPart then
                local dist = (char.HumanoidRootPart.Position - TargetPart.Position).Magnitude
                
                if dist > 4 then
                    -- Andando
                    SetSprint(true)
                    MoveTo(TargetPart.Position)
                    Status.Text = "🏃 INDO... (" .. math.floor(dist) .. "m)"
                else
                    -- Chegou
                    Status.Text = "🌀 ENTRANDO..."
                    StopMove()
                    
                    -- Tenta interagir de todas as formas
                    firetouchinterest(char.HumanoidRootPart, TargetPart, 0)
                    firetouchinterest(char.HumanoidRootPart, TargetPart, 1)
                    
                    for _, pp in ipairs(TargetPart:GetChildren()) do
                        if pp:IsA("ProximityPrompt") then 
                            fireproximityprompt(pp)
                            print("Prompt disparado!")
                        end
                    end
                    
                    task.wait(2) -- Espera carregar dungeon
                end
            end
        end
    end
end)