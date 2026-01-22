--[[
    ⚡ SAO INSTANT TRANSMISSION v7 (TELEPORT)
    
    OBJETIVO: Teleporte instantâneo para o melhor portal disponível.
    LÓGICA:
    1. Lê seu Poder (HUD).
    2. Acha o Portal mais difícil que você aguenta.
    3. Teleporta -> Entra -> Farma (Dungeon) -> Repete.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloTeleport = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    PortalName = "PortalModel", 
    PortalTrigger = "ProximityPart",
    MobFolderName = "Mobs", -- Pasta dos monstros na Dungeon
    
    -- Combate (Dungeon)
    AttackDist = 7,
    BehindDist = 5,
}

-- Estados
local IsRunning = false
local MyPower = 0
local CurrentTarget = nil -- Para combate

-- // UI SETUP //
if CoreGui:FindFirstChild("TeleportBotUI") then CoreGui.TeleportBotUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TeleportBotUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Roxo Teleporte
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ TELEPORT BOT v7"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 40)
InfoLabel.Position = UDim2.new(0, 0, 0.2, 0)
InfoLabel.Text = "Poder: ???"
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextWrapped = true

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.45, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.white
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
ToggleBtn.Text = "LIGAR AUTO-FARM"
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÕES ÚTEIS //

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

-- // LEITOR DE PODER (HUD) //
local function UpdatePower()
    local power = 0
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                local txt = v.Text:upper():gsub(",", "") -- Remove vírgula
                if txt:match("PODER") then
                    local num = tonumber(txt:match("%d+"))
                    if num then power = num end
                end
            end
        end
    end
    
    -- Backup Leaderstats
    if power == 0 and LocalPlayer:FindFirstChild("leaderstats") then
        for _, v in pairs(LocalPlayer.leaderstats:GetChildren()) do
            if v.Name:lower():match("power") then power = v.Value end
        end
    end
    
    MyPower = power
    InfoLabel.Text = "Meu Poder: " .. MyPower
    return power
end

-- // PROCURAR E ENTRAR NO PORTAL //
local function ScanAndEnterPortal()
    UpdatePower()
    
    local bestPortal = nil
    local bestReq = -1
    
    -- Varredura Global Instantânea
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == SETTINGS.PortalName and obj:FindFirstChild(SETTINGS.PortalTrigger) then
            
            local reqPower = 0
            -- Lê placas
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:lower():gsub(",", "")
                    if txt:match("poder") then
                        local num = tonumber(txt:match("%d+"))
                        if num then reqPower = num end
                    end
                end
            end
            
            -- Lógica: Quero o portal mais forte que eu aguento
            if reqPower <= MyPower then
                if reqPower > bestReq then
                    bestReq = reqPower
                    bestPortal = obj
                end
            end
        end
    end
    
    if bestPortal then
        Status.Text = "⚡ TELEPORTANDO: Portal " .. bestReq
        
        local trigger = bestPortal[SETTINGS.PortalTrigger]
        
        -- Teleporta para cima do gatilho
        TeleportTo(trigger.CFrame * CFrame.new(0, 2, 0))
        task.wait(0.2)
        
        -- Tenta entrar (Spam de interação)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 0)
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, trigger, 1)
        
        for _, pp in ipairs(trigger:GetChildren()) do
            if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
        end
        
        Status.Text = "🌀 ENTRANDO..."
        task.wait(3) -- Espera carregar
    else
        Status.Text = "⚠️ Nenhum portal para Poder " .. MyPower
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SoloTeleport = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR AUTO-FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().SoloTeleport do
        task.wait(0.5)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 Aguardando Renascer..."
                task.wait(2)
                return
            end

            -- 1. VERIFICA SE ESTOU NA DUNGEON (Tem Monstros?)
            local mobFolder = Workspace:FindFirstChild(SETTINGS.MobFolderName)
            local hasMobs = false
            local mobsList = {}
            
            if mobFolder then 
                mobsList = mobFolder:GetChildren() 
            else
                -- Busca genérica se não achar pasta
                for _, m in ipairs(Workspace:GetChildren()) do
                    if m:FindFirstChild("Humanoid") and m ~= char then table.insert(mobsList, m) end
                end
            end

            for _, m in ipairs(mobsList) do
                if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m ~= char then
                    -- Ignora NPCs de loja, foca em quem tem vida e não é player
                    hasMobs = true 
                    break 
                end
            end

            if hasMobs then
                -- === MODO DUNGEON (KAMIKAZE) ===
                Status.Text = "⚔️ LUTANDO..."
                EquipWeapon()
                
                -- Procura alvo mais perto
                local closest, minDist = nil, 9999
                local myRoot = char.HumanoidRootPart
                
                for _, m in ipairs(mobsList) do
                    if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and m ~= char then
                        local d = (myRoot.Position - m.HumanoidRootPart.Position).Magnitude
                        if d < minDist then minDist = d; closest = m end
                    end
                end
                
                if closest then
                    local tRoot = closest.HumanoidRootPart
                    -- Teleporta nas costas do bicho
                    TeleportTo(tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist))
                    
                    -- Olha pro bicho
                    myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                    Attack()
                end
                
                -- Checa Baús (Prioridade)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local n = obj.Parent.Name:lower()
                        if n:match("chest") or n:match("bau") or n:match("loot") then
                            Status.Text = "💎 PEGANDO LOOT!"
                            TeleportTo(obj.Parent.CFrame)
                            fireproximityprompt(obj)
                        end
                    end
                end
                
            else
                -- === MODO LOBBY ===
                -- Se não tem bicho, assume que está no Lobby e procura portal
                ScanAndEnterPortal()
            end
        end
    end
end)