--[[
    🏰 SAO SOLO LEVELING BOT v5 (SMART NAVIGATOR)
    
    MELHORIAS:
    - TARGET LOCK: Escolhe um alvo e vai até o fim (acaba com o anda-para).
    - UNSTUCK: Pula se ficar preso em paredes.
    - VISUAL LINE: Mostra uma linha para onde ele está indo.
    - CLOSEST MODE: Se não conseguir ler o poder, vai no mais perto.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloSmart = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    MobFolderName = "Mobs",
    
    -- Navegação
    StuckThreshold = 0.5, -- Se mover menos que isso em 0.5s, pula
    ScanCooldown = 2,     -- Só procura portal novo a cada 2 segundos
}

-- Estados
local IsRunning = false
local CurrentTarget = nil -- Mob
local CurrentPortal = nil -- Portal (Modelo)
local TargetPart = nil    -- Parte exata para andar
local MyPower = 0
local LastPos = Vector3.new(0,0,0)
local LastMoveTime = 0

-- // VISUAL DEBUG (LINHA) //
local Line = Drawing.new("Line")
Line.Visible = false
Line.Color = Color3.new(0, 1, 0)
Line.Thickness = 2
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

-- // GUI SETUP //
if CoreGui:FindFirstChild("SoloSmartUI") then CoreGui.SoloSmartUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloSmartUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏰 SOLO SMART BOT v5"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ActionLabel = Instance.new("TextLabel", MainFrame)
ActionLabel.Size = UDim2.new(1, 0, 0, 30)
ActionLabel.Position = UDim2.new(0, 0, 0.4, 0)
ActionLabel.Text = "Ação: -"
ActionLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
ActionLabel.BackgroundTransparency = 1
ActionLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR BOT INTELIGENTE"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÕES DE MOVIMENTO //

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
        
        -- UNSTUCK SYSTEM (Se estiver andando mas não sair do lugar)
        if tick() - LastMoveTime > 0.5 then
            if (char.HumanoidRootPart.Position - LastPos).Magnitude < SETTINGS.StuckThreshold then
                -- Travou! PULA!
                char.Humanoid.Jump = true
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
    if enable then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    else
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

-- // SCANNER DE PORTAIS (COM TRAVA) //
local function GetPlayerPower()
    -- Simplificado: Tenta pegar do Leaderstats
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") then return v.Value end
        end
    end
    return 999999 -- Se não achar, assume que é fortão pra testar
end

local function FindBestPortal()
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local bestPortal = nil
    local minDist = 99999
    
    MyPower = GetPlayerPower()
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            local trigger = obj[SETTINGS.PortalTrigger]
            local dist = (myPos - trigger.Position).Magnitude
            
            -- Tenta ler poder (Opcional)
            local reqPower = 0
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text:match("%d") then
                    local n = tonumber(gui.Text:match("%d+"))
                    if n and n > 50 then reqPower = n end
                end
            end
            
            -- Lógica: 
            -- 1. Se consigo entrar (Req <= MyPower)
            -- 2. E é o mais próximo de mim (pra evitar andar km a toa)
            if reqPower <= MyPower then
                if dist < minDist then
                    minDist = dist
                    bestPortal = obj
                end
            end
        end
    end
    return bestPortal
end

-- // SCANNER DE BAÚS //
local function ScanChests()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local p = obj.Parent
            local n = p.Name:lower()
            if n:match("chest") or n:match("bau") or n:match("loot") then
                return obj
            end
        end
    end
    return nil
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloSmart = false
    Line:Remove()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR BOT INTELIGENTE"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        StopMove()
        CurrentPortal = nil
        TargetPart = nil
        Line.Visible = false
    end
end)

-- // LOOP PRINCIPAL //
RunService.RenderStepped:Connect(function()
    if not getgenv().SoloSmart then return end
    
    -- Atualiza linha visual
    if IsRunning and TargetPart then
        UpdateLine(TargetPart.Position)
    else
        UpdateLine(nil)
    end
end)

spawn(function()
    while getgenv().SoloSmart do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentPortal = nil
                TargetPart = nil
                task.wait(2)
                return
            end

            local myRoot = char.HumanoidRootPart
            
            -- 1. CHECA POR BAÚS (PRIORIDADE ABSOLUTA)
            local chestPrompt = ScanChests()
            if chestPrompt then
                Status.Text = "💎 BAÚ DETECTADO!"
                ActionLabel.Text = "Abrindo Loot..."
                
                local chestPart = chestPrompt.Parent
                if chestPart:IsA("Model") then chestPart = chestPart.PrimaryPart or chestPart:FindFirstChild("HumanoidRootPart") end
                
                if chestPart then
                    char.HumanoidRootPart.CFrame = chestPart.CFrame * CFrame.new(0,3,0) -- Teleporte curto
                    fireproximityprompt(chestPrompt)
                    task.wait(0.5)
                end
                
            -- 2. VERIFICA MOBS (MODO DUNGEON)
            else
                local mobFolder = Workspace:FindFirstChild(SETTINGS.MobFolderName)
                local hasMobs = false
                
                -- Checagem rápida de mobs
                if mobFolder then
                    for _, m in ipairs(mobFolder:GetChildren()) do
                        if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then hasMobs = true break end
                    end
                else
                     for _, m in ipairs(Workspace:GetChildren()) do
                        if m:FindFirstChild("Humanoid") and m ~= char and m:FindFirstChild("Enemy") then hasMobs = true break end
                    end
                end
                
                if hasMobs then
                    -- === MODO COMBATE ===
                    Status.Text = "⚔️ MODO DUNGEON"
                    CurrentPortal = nil -- Esquece portal enquanto luta
                    TargetPart = nil
                    
                    -- Lógica de Combate Simples e Direta
                    local closest, minDist = nil, 9999
                    local list = mobFolder and mobFolder:GetChildren() or Workspace:GetChildren()
                    
                    for _, m in ipairs(list) do
                        if m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m ~= char then
                            local d = (myRoot.Position - m.HumanoidRootPart.Position).Magnitude
                            if d < minDist then minDist = d; closest = m end
                        end
                    end
                    
                    if closest then
                        ActionLabel.Text = "Matando: " .. closest.Name
                        TargetPart = closest.HumanoidRootPart
                        
                        local dist = (myRoot.Position - TargetPart.Position).Magnitude
                        if dist > 6 then
                            SetSprint(true)
                            MoveTo(TargetPart.Position)
                            -- Auto-Equip
                            local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then char.Humanoid:EquipTool(tool) end
                        else
                            SetSprint(false)
                            StopMove()
                            -- Ataque
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendMouseButtonEvent(0,0,0,true,game,1)
                            vim:SendMouseButtonEvent(0,0,0,false,game,1)
                        end
                    end
                    
                else
                    -- === MODO LOBBY (NAVEGAÇÃO SEGURA) ===
                    Status.Text = "🚶 MODO LOBBY"
                    
                    -- Se não tenho alvo, procura um e TRAVA nele
                    if not CurrentPortal then
                        ActionLabel.Text = "Escaneando..."
                        CurrentPortal = FindBestPortal()
                        if CurrentPortal then
                            TargetPart = CurrentPortal:FindFirstChild(SETTINGS.PortalTrigger)
                            ActionLabel.Text = "Alvo: " .. CurrentPortal.Name
                        else
                            ActionLabel.Text = "Nenhum portal perto"
                        end
                    end
                    
                    -- Se tenho alvo, vai até ele
                    if TargetPart then
                        local dist = (myRoot.Position - TargetPart.Position).Magnitude
                        
                        if dist > 3 then
                            Status.Text = "🚶 CAMINHANDO..."
                            SetSprint(true)
                            MoveTo(TargetPart.Position)
                        else
                            Status.Text = "🌀 ENTRANDO..."
                            StopMove()
                            -- Interage
                            firetouchinterest(myRoot, TargetPart, 0)
                            firetouchinterest(myRoot, TargetPart, 1)
                            for _, pp in ipairs(TargetPart:GetChildren()) do
                                if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                            end
                            
                            -- Reseta alvo após entrar (dá um tempo pro teleporte)
                            task.wait(3)
                            CurrentPortal = nil
                            TargetPart = nil
                        end
                    end
                end
            end
        end
    end
end)