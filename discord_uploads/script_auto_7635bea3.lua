--[[
    🏰 SAO SOLO LEVELING BOT v2 (KAMIKAZE & LOOT)
    
    LÓGICA HÍBRIDA:
    1. PRIORIDADE 1 (LOOT): Se ver baús, abre IMEDIATAMENTE.
    2. PRIORIDADE 2 (COMBATE): Se ver monstros, mata (Kamikaze - sem fugir).
    3. PRIORIDADE 3 (LOBBY): Se não ver nada, procura Portais e entra.
    
    MORTE: Se morrer, espera renascer e reequipa a arma.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloKamikaze = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Nomes (Ajuste se precisar)
    PortalFolderName = "Portals", 
    MobFolderName = "Mobs",       
    
    -- Combate
    AttackDist = 7,
    BehindDist = 5,
    SprintDist = 12,
    
    -- Loot
    LootRange = 5000, -- Olha o mapa todo
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local CurrentPortal = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("KamikazeUI") then CoreGui.KamikazeUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "KamikazeUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0) -- Vermelho Sangue
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏰 SOLO KAMIKAZE v2"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 30)
InfoLabel.Position = UDim2.new(0, 0, 0.35, 0)
InfoLabel.Text = "Modo: Aguardando"
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÕES BÁSICAS //

local function SetSprint(enable)
    if enable then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    else
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

-- EQUIPA ARMA (TECLA 1 e INVENTÁRIO)
local function EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    
    if not char:FindFirstChildOfClass("Tool") then
        -- Tenta Tecla 1
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        
        -- Tenta pegar do Backpack se a tecla falhar
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool then char.Humanoid:EquipTool(tool) end
        end
    end
end

-- ATAQUE
local function Attack()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
    -- Click backup
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // SCANNER DE BAÚS (PRIORIDADE) //
local function ScanAndLootChests()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local name = parent.Name:lower()
            -- Palavras chave de Loot
            if name:match("chest") or name:match("bau") or name:match("reward") or name:match("loot") then
                -- É um baú!
                if parent:IsA("BasePart") then
                    TeleportTo(parent.CFrame * CFrame.new(0, 3, 0))
                elseif parent:IsA("Model") and parent.PrimaryPart then
                    TeleportTo(parent.PrimaryPart.CFrame * CFrame.new(0, 3, 0))
                else
                    if parent:IsA("BasePart") then TeleportTo(parent.CFrame) end
                end
                
                -- Abre
                fireproximityprompt(obj)
                return true -- Achou e tentou abrir
            end
        end
    end
    return false
end

-- // SCANNER DE PORTAIS (LOBBY) //
local function GetPlayerLevel()
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            if v.Name:match("Level") or v.Name:match("Lvl") or v.Name:match("Rank") then return v.Value end
        end
    end
    return 1
end

local function ScanPortals()
    local bestPortal = nil
    local highestReq = -1
    local myLevel = GetPlayerLevel()
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:match("Portal") or obj.Name:match("Gate") or obj.Name:match("Dungeon") then
            if obj:IsA("Model") or obj:IsA("Part") then
                local reqLevel = 0
                for _, gui in ipairs(obj:GetDescendants()) do
                    if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text:match("%d") then
                        reqLevel = tonumber(gui.Text:match("%d+")) or 0
                        break
                    end
                end
                if reqLevel <= myLevel and reqLevel > highestReq then
                    highestReq = reqLevel
                    bestPortal = obj
                end
            end
        end
    end
    return bestPortal
end

-- // UI //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloKamikaze = false
    SetSprint(false)
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        SetSprint(false)
        CurrentTarget = nil
        CurrentPortal = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SoloKamikaze do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            
            -- RENASCIMENTO (Kamikaze)
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                task.wait(1)
                return
            end

            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid

            -- 1. CHECA POR BAÚS (PRIORIDADE MÁXIMA - Fim de Dungeon)
            local foundLoot = ScanAndLootChests()
            if foundLoot then
                Status.Text = "💎 SAQUEANDO BAÚS!"
                InfoLabel.Text = "Modo: LOOT"
                SetSprint(false)
                -- Não faz mais nada, só foca em pegar o loot
                
            else
                -- 2. SE NÃO TEM BAÚ, PROCURA INIMIGOS
                local mobFolder = Workspace:FindFirstChild(SETTINGS.MobFolderName)
                local hasMobs = false
                
                if mobFolder then
                    for _, m in ipairs(mobFolder:GetChildren()) do
                        if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                            hasMobs = true
                            break
                        end
                    end
                end
                
                if hasMobs then
                    -- === MODO COMBATE ===
                    InfoLabel.Text = "Modo: COMBATE"
                    EquipWeapon()
                    
                    if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
                        -- Busca novo alvo
                        Status.Text = "🔎 CAÇANDO..."
                        local closest, cDist = nil, 9999
                        for _, m in ipairs(mobFolder:GetChildren()) do
                            if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 then
                                local d = (myRoot.Position - m.HumanoidRootPart.Position).Magnitude
                                if d < cDist then cDist = d; closest = m end
                            end
                        end
                        CurrentTarget = closest
                    else
                        -- KAMIKAZE ATTACK
                        local tRoot = CurrentTarget.HumanoidRootPart
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            Status.Text = "🏃 AVANÇANDO..."
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            Status.Text = "⚔️ MATANDO..."
                            -- Backstab rápido
                            local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            if (myRoot.Position - backPos.Position).Magnitude > 3 then
                                SetSprint(true)
                                MoveTo(backPos.Position)
                            else
                                SetSprint(false)
                                StopMove()
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                            end
                            Attack()
                        end
                    end
                    
                else
                    -- === MODO LOBBY ===
                    InfoLabel.Text = "Modo: LOBBY"
                    
                    if not CurrentPortal then
                        Status.Text = "🌀 PROCURANDO PORTAL..."
                        CurrentPortal = ScanPortals()
                        if not CurrentPortal then Status.Text = "⚠️ SEM PORTAL (Nível Baixo?)" end
                    else
                        local pRoot = CurrentPortal:FindFirstChild("PrimaryPart") or CurrentPortal:FindFirstChild("HumanoidRootPart") or CurrentPortal:FindFirstChildWhichIsA("BasePart")
                        if pRoot then
                            local dist = (myRoot.Position - pRoot.Position).Magnitude
                            if dist > 5 then
                                Status.Text = "🚶 INDO PRO PORTAL..."
                                SetSprint(true)
                                MoveTo(pRoot.Position)
                            else
                                Status.Text = "🌀 ENTRANDO..."
                                StopMove()
                                hum.Jump = true
                                -- Tenta entrar
                                for _, pp in ipairs(CurrentPortal:GetDescendants()) do
                                    if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                                end
                                CurrentPortal = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)