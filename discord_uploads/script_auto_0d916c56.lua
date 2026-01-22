--[[
    🏰 SAO SOLO LEVELING BOT v4.1 (POWER READER + TELEPORT)
    
    BASE: Seu script v4 original (que lê o poder corretamente).
    UPGRADE: Substituído o sistema de andar até o portal por TELEPORTE.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloTeleportV4 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    MobFolderName = "Mobs",
    
    -- Combate (Mantido do original)
    AttackDist = 7,
    BehindDist = 5,
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local CurrentPortal = nil
local MyPower = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("SoloTeleportUI") then CoreGui.SoloTeleportUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloTeleportUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Verde Teleporte
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏰 SOLO BOT (TELEPORT)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 25)
PowerLabel.Position = UDim2.new(0, 0, 0.15, 0)
PowerLabel.Text = "SEU PODER: ???"
PowerLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 30)
InfoLabel.Position = UDim2.new(0, 0, 0.45, 0)
InfoLabel.Text = "Modo: Aguardando"
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR BOT"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÕES AUXILIARES //

local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
    end
end

local function EquipWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChildOfClass("Tool") then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool then char.Humanoid:EquipTool(tool) end
        end
    end
end

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
            local cx, cy = pos.X + btn.AbsoluteSize.X/2, pos.Y + btn.AbsoluteSize.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // LEITOR DE PODER (MANTIDO DO SEU SCRIPT) //
local function UpdatePlayerPower()
    local power = 0
    
    if LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            local n = v.Name:lower()
            if n:match("power") or n:match("poder") or n:match("strength") or n:match("força") then
                power = v.Value
                break
            end
        end
    end
    
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

-- // SCANNER DE PORTAIS (MANTIDO DO SEU SCRIPT) //
local function ScanPortals()
    local bestPortal = nil
    local highestReq = -1
    UpdatePlayerPower()
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    if num then
                        if num > 50 then reqPower = num end
                    end
                end
            end
            
            if reqPower <= MyPower and reqPower > highestReq then
                highestReq = reqPower
                bestPortal = obj
            end
        end
    end
    
    if bestPortal then
        Status.Text = "PORTAL ACHADO: Poder " .. highestReq
    end
    return bestPortal
end

-- // SCANNER DE LOOT //
local function ScanAndLootChests()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local name = parent.Name:lower()
            if name:match("chest") or name:match("bau") or name:match("reward") or name:match("loot") then
                -- TELEPORTE PARA LOOT
                if parent:IsA("BasePart") then TeleportTo(parent.CFrame * CFrame.new(0, 3, 0))
                elseif parent:IsA("Model") and parent.PrimaryPart then TeleportTo(parent.PrimaryPart.CFrame * CFrame.new(0, 3, 0))
                else if parent:IsA("BasePart") then TeleportTo(parent.CFrame) end end
                fireproximityprompt(obj)
                return true
            end
        end
    end
    return false
end

-- // UI //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloTeleportV4 = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        UpdatePlayerPower()
    else
        ToggleBtn.Text = "LIGAR BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        CurrentTarget = nil
        CurrentPortal = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SoloTeleportV4 do
        task.wait(0.2) -- Loop mais tranquilo
        
        if IsRunning then
            local char = LocalPlayer.Character
            
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                CurrentTarget = nil
                CurrentPortal = nil
                task.wait(1)
                return
            end

            -- 1. LOOT
            if ScanAndLootChests() then
                Status.Text = "💎 PEGANDO LOOT..."
                InfoLabel.Text = "Modo: LOOT"
                
            else
                -- 2. COMBATE (Dungeon)
                local mobFolder = Workspace:FindFirstChild(SETTINGS.MobFolderName)
                local hasMobs = false
                
                local mobsList = {}
                if mobFolder then mobsList = mobFolder:GetChildren()
                else
                    for _, m in ipairs(Workspace:GetChildren()) do
                        if m:FindFirstChild("Humanoid") and m ~= char then table.insert(mobsList, m) end
                    end
                end

                for _, m in ipairs(mobsList) do
                    if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m ~= char then
                        hasMobs = true
                        break
                    end
                end
                
                if hasMobs then
                    InfoLabel.Text = "Modo: COMBATE"
                    EquipWeapon()
                    
                    if not CurrentTarget or not CurrentTarget.Parent or CurrentTarget.Humanoid.Health <= 0 then
                        Status.Text = "🔎 BUSCANDO ALVO..."
                        local closest, cDist = nil, 9999
                        for _, m in ipairs(mobsList) do
                            if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and m ~= char then
                                local d = (char.HumanoidRootPart.Position - m.HumanoidRootPart.Position).Magnitude
                                if d < cDist then cDist = d; closest = m end
                            end
                        end
                        CurrentTarget = closest
                    else
                        local tRoot = CurrentTarget.HumanoidRootPart
                        -- TELEPORTE PARA COMBATE
                        TeleportTo(tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist))
                        
                        -- Vira o boneco pro bicho
                        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(tRoot.Position.X, char.HumanoidRootPart.Position.Y, tRoot.Position.Z))
                        
                        Attack()
                    end
                    
                else
                    -- 3. LOBBY (PORTAL) - AQUI ESTÁ A MUDANÇA
                    InfoLabel.Text = "Modo: LOBBY"
                    
                    if not CurrentPortal then
                        Status.Text = "🌀 ANALISANDO PORTAIS..."
                        CurrentPortal = ScanPortals()
                        if not CurrentPortal then Status.Text = "⚠️ SEM PORTAL COMPATÍVEL" end
                    else
                        local targetPart = CurrentPortal:FindFirstChild(SETTINGS.PortalTrigger)
                        
                        if targetPart then
                            -- TELEPORTE DIRETO PARA O PORTAL
                            Status.Text = "⚡ TELEPORTANDO..."
                            TeleportTo(targetPart.CFrame * CFrame.new(0, 2, 0))
                            
                            task.wait(0.2)
                            
                            Status.Text = "🌀 ENTRANDO..."
                            firetouchinterest(char.HumanoidRootPart, targetPart, 0)
                            firetouchinterest(char.HumanoidRootPart, targetPart, 1)
                            
                            for _, pp in ipairs(targetPart:GetChildren()) do
                                if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                            end
                            
                            CurrentPortal = nil
                            task.wait(3) -- Espera carregar
                        else
                            CurrentPortal = nil
                        end
                    end
                end
            end
        end
    end
end)