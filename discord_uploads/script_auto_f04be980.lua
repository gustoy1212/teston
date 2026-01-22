--[[
    🏰 SAO DUNGEON CRAWLER (FULL AUTO)
    
    1. COMBATE: Usa o Flash Step Survival (Já aprovado).
    2. LOOT: Teleporta nos baús e usa ProximityPrompt (Tecla E instantânea).
    3. TARGET: Prioriza o Boss, depois os baús.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().DungeonCrawler = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    -- Combate
    AttackDist = 7,
    BehindDist = 5,
    SprintDist = 12,
    
    -- Sobrevivência
    LowHealthPercent = 30,
    SafetyDist = 30,
    
    -- Loot
    LootRange = 5000, -- Procura baús no mapa todo
}

-- Estados
local IsRunning = false
local IsInEmergency = false
local CurrentTarget = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("DungeonUI") then CoreGui.DungeonUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DungeonUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30) -- Roxo Dungeon
MainFrame.BorderColor3 = Color3.fromRGB(150, 50, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🏰 DUNGEON CRAWLER"
Title.TextColor3 = Color3.fromRGB(150, 50, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
ToggleBtn.Text = "LIGAR AUTO-DUNGEON"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÕES AUXILIARES //

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

local function TeleportTo(cframe)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = cframe
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
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

-- // FUNÇÃO DE LOOT (ABRIDOR DE BAÚS) //
local function AutoOpenChests()
    -- Procura no Workspace inteiro por coisas que pareçam baús
    local foundChest = false
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Verifica se tem ProximityPrompt (interação com tecla E)
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local parentName = parent.Name:lower()
            
            -- Filtra se é um baú
            if parentName:match("chest") or parentName:match("bau") or parentName:match("reward") or parentName:match("loot") then
                
                -- Se achou, teleporta e abre
                if parent:IsA("BasePart") then
                    TeleportTo(parent.CFrame * CFrame.new(0, 3, 0))
                elseif parent:IsA("Model") and parent.PrimaryPart then
                    TeleportTo(parent.PrimaryPart.CFrame * CFrame.new(0, 3, 0))
                elseif parent:FindFirstChild("HumanoidRootPart") then
                     TeleportTo(parent.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0))
                else
                    -- Tenta teleportar para a posição do prompt se não achar parte principal
                    if parent:IsA("BasePart") then TeleportTo(parent.CFrame) end
                end
                
                -- Dispara o prompt (Abre o baú)
                fireproximityprompt(obj)
                foundChest = true
                Status.Text = "💎 ABRINDO BAÚ!"
                task.wait(0.2) -- Espera abrir
            end
        end
    end
    return foundChest
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().DungeonCrawler = false
    SetSprint(false)
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "LIGAR AUTO-DUNGEON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
        SetSprint(false)
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().DungeonCrawler do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid

            -- 1. VERIFICA VIDA (Sobrevivência)
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            if hpPercent < SETTINGS.LowHealthPercent then
                IsInEmergency = true
            elseif hpPercent > 90 then
                IsInEmergency = false
            end
            
            if IsInEmergency then
                Status.Text = "🚑 VIDA CRÍTICA! FUGINDO..."
                -- Foge do inimigo mais próximo
                local folder = Workspace:FindFirstChild("Mobs")
                local danger = nil
                local minDist = 9999
                if folder then
                    for _, m in ipairs(folder:GetChildren()) do
                        if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 then
                            local d = (myRoot.Position - m.HumanoidRootPart.Position).Magnitude
                            if d < minDist then minDist = d; danger = m end
                        end
                    end
                end
                
                if danger then
                    local dir = (myRoot.Position - danger.HumanoidRootPart.Position).Unit
                    MoveTo(myRoot.Position + dir * 30)
                    SetSprint(true)
                else
                    MoveTo(myRoot.Position) -- Fica parado se não tiver ninguém perto
                end
            
            else
                -- 2. VERIFICA INIMIGOS (Boss/Mobs)
                local folder = Workspace:FindFirstChild("Mobs")
                local foundMob = false
                
                if folder then
                    local closest, minDist = nil, 9999
                    for _, mob in ipairs(folder:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                        foundMob = true
                        
                        -- Lógica de Combate (Flash Step)
                        local tRoot = closest.HumanoidRootPart
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            Status.Text = "🏃 INDO ATÉ O BOSS..."
                            SetSprint(true)
                            MoveTo(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            SetSprint(false)
                            MoveTo(tRoot.Position)
                        else
                            Status.Text = "⚔️ MATANDO BOSS..."
                            -- Backstab
                            local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            if (myRoot.Position - backPos.Position).Magnitude > 3 then
                                SetSprint(true)
                                MoveTo(backPos.Position)
                            else
                                SetSprint(false)
                                MoveTo(myRoot.Position) -- Para pra bater
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                            end
                            Attack()
                        end
                    end
                end
                
                -- 3. SE NÃO TEM MOB, PROCURA BAÚS
                if not foundMob then
                    Status.Text = "💎 PROCURANDO BAÚS..."
                    local looted = AutoOpenChests()
                    if not looted then
                        Status.Text = "✅ DUNGEON LIMPA (Esperando...)"
                    end
                end
            end
        end
    end
end)