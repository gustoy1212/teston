--[[
    SBL REBORN - SURVIVAL V6 (BIG HITBOX + MAP PULL)
    
    MELHORIAS:
    1. EXPAND HITBOX: Aumenta o tamanho dos mobs para você nunca errar o hit.
    2. MEGA PULL: Puxa mobs de muito longe (2000 studs).
    3. FIX DE ACERTO: Mantém os mobs colados na posição perfeita de ataque.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

getgenv().SBLSurvivalV6 = true

-- // CONFIGURAÇÕES TURBINADAS //
local SETTINGS = {
    -- Combate
    BringDist = 2000,       -- Puxa a ilha inteira praticamente
    HitboxSize = 5,         -- Tamanho da hitbox (cabeça/torso) dos inimigos
    
    -- Sobrevivência
    LowHealthPercent = 30,  -- Foge se vida < 30%
    FullHealthPercent = 85, -- Volta se vida > 85%
    
    -- Status
    StatToUp = "Melee",     
}

-- Estados
local IsRunning = false
local IsInEmergency = false 

-- REMOTES
local Remotes = {
    Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"),
    Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"),
    Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"),
}

-- // GUI SETUP (Visual SAO/SBL que você gostou) //
if CoreGui:FindFirstChild("SBLSurvUI_V6") then CoreGui.SBLSurvUI_V6:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "SBLSurvUI_V6"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Laranja
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🔥 SBL V6: BIG HITBOX"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local HealthLabel = Instance.new("TextLabel", MainFrame)
HealthLabel.Size = UDim2.new(1, 0, 0, 30)
HealthLabel.Position = UDim2.new(0, 0, 0.35, 0)
HealthLabel.Text = "Vida: 100%"
HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HealthLabel.BackgroundTransparency = 1
HealthLabel.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES AUXILIARES //

local function AutoEquip()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChildOfClass("Tool") then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool")
            if tool then char.Humanoid:EquipTool(tool) end
        end
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SBLSurvivalV6 = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        IsInEmergency = false
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
        IsInEmergency = false
        Status.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().SBLSurvivalV6 do
        task.wait() -- Loop rapidinho
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            
            -- MONITOR DE VIDA
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            HealthLabel.Text = "Vida: " .. math.floor(hpPercent) .. "%"
            if hpPercent <= 30 then HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            elseif hpPercent <= 60 then HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end

            if hum.Health <= 0 then
                Status.Text = "💀 RENASCENDO..."
                IsInEmergency = false
                task.wait(4)
                return
            end

            AutoEquip()
            pcall(function() Remotes.Stats:FireServer(SETTINGS.StatToUp, 1) end)

            -- SOBREVIVÊNCIA
            if hpPercent < SETTINGS.LowHealthPercent then IsInEmergency = true
            elseif hpPercent >= SETTINGS.FullHealthPercent then IsInEmergency = false end

            if IsInEmergency then
                Status.Text = "🚑 VIDA CRÍTICA! AFASTANDO..."
                for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                    if mob:FindFirstChild("HumanoidRootPart") and (mob.HumanoidRootPart.Position - myRoot.Position).Magnitude < 50 then
                        mob.HumanoidRootPart.CFrame = myRoot.CFrame * CFrame.new(0, 100, 0) -- Joga pro céu
                    end
                end
            else
                -- === FARM ===
                Status.Text = "⚔️ FARMANDO GERAL..."
                
                -- Skills
                local skills = {"Z", "X", "C", "V"}
                for _, k in pairs(skills) do pcall(function() Remotes.Skill:FireServer(k) end) end

                -- Loop nos Mobs
                for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                        local mobRoot = mob.HumanoidRootPart
                        local dist = (myRoot.Position - mobRoot.Position).Magnitude
                        
                        -- [[ NOVIDADE: HITBOX EXPANDER ]]
                        -- Aumenta a parte do corpo do bicho para facilitar o acerto
                        pcall(function()
                            if mobRoot.Size.X < SETTINGS.HitboxSize then
                                mobRoot.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                                mobRoot.CanCollide = false
                                mobRoot.Transparency = 0.7 -- Deixa meio transparente pra não atrapalhar a visão
                            end
                        end)
                        
                        -- PUXA MOBS (Raio gigante de 2000)
                        if dist < SETTINGS.BringDist then
                            -- Puxa para 5 studs na frente (Posição ideal)
                            mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5)
                            
                            -- Trava movimento
                            mob.Humanoid.WalkSpeed = 0
                            mob.Humanoid.PlatformStand = true
                            
                            -- Remove colisão
                            for _, p in pairs(mob:GetChildren()) do
                                if p:IsA("BasePart") then p.CanCollide = false end
                            end

                            -- Bate 2x por loop pra garantir
                            pcall(function() Remotes.Hit:FireServer() end)
                            pcall(function() Remotes.Hit:FireServer() end)
                        end
                    end
                end
            end
        end
    end
end)