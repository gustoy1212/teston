--[[
    🧬 SAO FUSION BOT (LEGACY + TELEPORT)
    
    BASE: Código fornecido pelo usuário (que lê o poder corretamente).
    UPGRADE: Substituído o sistema de andar (MoveTo) por Teleporte (CFrame).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloFusion = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    MobFolderName = "Mobs",
    
    -- Combate
    AttackDist = 7,
    BehindDist = 5,
}

-- Estados
local IsRunning = false
local MyPower = 0

-- // GUI SETUP //
if CoreGui:FindFirstChild("SoloFusionUI") then CoreGui.SoloFusionUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SoloFusionUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧬 SAO FUSION BOT"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(1, 0, 0, 30)
PowerLabel.Position = UDim2.new(0, 0, 0.2, 0)
PowerLabel.Text = "LENDO PODER..."
PowerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
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
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR BOT"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

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
    local vim = game:GetService("VirtualInputManager")
    vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- // LEITOR DE PODER (CÓDIGO ORIGINAL SEU) //
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

-- // ESCOLHER E ENTRAR NO PORTAL //
local function EnterBestPortal()
    UpdatePlayerPower()
    
    local bestPortal = nil
    local highestReq = -1
    
    -- Varredura Global (Instantânea)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text
                    local num = tonumber(txt:match("%d+"))
                    
                    if num and num > 50 then -- Filtra números pequenos
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
        Status.Text = "⚡ TELEPORTANDO: Portal " .. highestReq
        
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- 1. TELEPORTA (Acima do trigger)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
        end
        
        task.wait(0.2)
        
        -- 2. ENTRA (TOUCH + PROMPT)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
        end
        
        Status.Text = "🌀 Entrando..."
        task.wait(3) -- Espera carregar dungeon
    else
        Status.Text = "⚠️ Nenhum portal compatível!"
    end
end

-- // SCANNER DE LOOT //
local function ScanAndLootChests()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local name = parent.Name:lower()
            if name:match("chest") or name:match("bau") or name:match("reward") or name:match("loot") then
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

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloFusion = false
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
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SoloFusion do
        task.wait(0.5)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 Renascendo..."
                task.wait(2)
                return
            end

            -- 1. LOOT (Prioridade Máxima)
            if ScanAndLootChests() then
                Status.Text = "💎 Pegando Loot..."
            
            else
                -- 2. VERIFICA SE ESTÁ NA DUNGEON (Monstros Perto?)
                local nearbyMobs = false
                local mobFolder = Workspace:FindFirstChild(SETTINGS.MobFolderName)
                local mobsList = {}
                
                if mobFolder then 
                    mobsList = mobFolder:GetChildren() 
                else
                    for _, m in ipairs(Workspace:GetChildren()) do
                        if m:FindFirstChild("Humanoid") and m ~= char then table.insert(mobsList, m) end
                    end
                end

                -- Filtra mobs vivos perto
                local myPos = char.HumanoidRootPart.Position
                for _, m in ipairs(mobsList) do
                    if m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m ~= char then
                        if (m.HumanoidRootPart.Position - myPos).Magnitude < 500 then -- 500 studs é um bom raio de dungeon
                            nearbyMobs = true
                            break
                        end
                    end
                end

                if nearbyMobs then
                    -- === MODO DUNGEON ===
                    Status.Text = "⚔️ Lutando..."
                    EquipWeapon()
                    
                    -- Acha o mob mais perto
                    local closest, minDist = nil, 9999
                    for _, m in ipairs(mobsList) do
                        if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and m ~= char then
                            local d = (myPos - m.HumanoidRootPart.Position).Magnitude
                            if d < minDist then minDist = d; closest = m end
                        end
                    end
                    
                    if closest then
                        local tRoot = closest.HumanoidRootPart
                        -- Teleporta costas
                        TeleportTo(tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist))
                        -- Olha pro bicho
                        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, Vector3.new(tRoot.Position.X, char.HumanoidRootPart.Position.Y, tRoot.Position.Z))
                        Attack()
                    end
                else
                    -- === MODO LOBBY ===
                    -- Se não tem loot e não tem monstro, procura portal
                    EnterBestPortal()
                end
            end
        end
    end
end)