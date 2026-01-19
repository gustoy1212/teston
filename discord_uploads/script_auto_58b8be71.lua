--[[
    🧙‍♂️ RPG SILENT KILLER v1 (AFK EDITION)
    
    ESTRATÉGIA "NINGUÉM VÊ":
    1. ZERO MOVIMENTO: Seu personagem é travado no chão (Anchor).
    2. HITBOX EXPANSION: Aumenta a hitbox dos monstros para cobrir o mapa.
       - Você acerta eles de qualquer lugar sem precisar andar.
    3. AUTO ATTACK: Spamma Skills e Cliques no "vento" (que na verdade é o monstro).
    
    PERFEITO PARA SERVIDORES CHEIOS.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

getgenv().SilentFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    HitboxSize = 200,      -- Tamanho da Hitbox (200 já cobre muita coisa)
    AttackInterval = 0.1,  -- Velocidade do clique
    SkillInterval = 1.5,   -- Velocidade das skills
    AnchorPlayer = true,   -- Trava seu boneco pra não ser empurrado
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkill = 0
local lastAttack = 0
local ExpandedMobs = {} -- Lista para não bugar expansão repetida

-- // GUI SETUP //
if CoreGui:FindFirstChild("RPGSilent") then CoreGui.RPGSilent:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGSilent"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(100, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🤫 SILENT KILLER (AFK)"
Title.TextColor3 = Color3.fromRGB(150, 100, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 100)
ToggleBtn.Text = "LIGAR FARM (SEM MOVER)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO FECHAR //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SilentFarm = false
    Status.Text = "ENCERRADO"
    -- Restaura boneco
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    -- Restaura mobs
    for mob, vals in pairs(ExpandedMobs) do
        if mob and mob:FindFirstChild("HumanoidRootPart") and vals.OriginalSize then
            mob.HumanoidRootPart.Size = vals.OriginalSize
            mob.HumanoidRootPart.Transparency = vals.OriginalTransp
            mob.HumanoidRootPart.CanCollide = true
        end
    end
    ScreenGui:Destroy()
end)

-- // LOCALIZADOR DE PASTA //
local function GetEnemiesFolder()
    -- Procura a pasta BadEntities ou similar
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            return child
        end
    end
    return Workspace
end

-- // EXPANSÃO DE HITBOX //
local function ExpandMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChild("Humanoid")
    
    if root and hum and hum.Health > 0 then
        -- Se já expandiu, ignora
        if ExpandedMobs[mob] then 
            -- Mantém a posição atualizada para "colar" em você (Opcional, mas a Hitbox gigante já resolve)
            -- root.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            return 
        end
        
        -- Salva original pra restaurar se precisar
        ExpandedMobs[mob] = {
            OriginalSize = root.Size,
            OriginalTransp = root.Transparency
        }
        
        -- A Mágica: Transforma o monstro numa sala gigante
        root.CanCollide = false
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 0.9 -- Quase invisível pra ninguém ver quadrado gigante
        
        -- Dica: Se o jogo checa distância, a gente traz o CFrame pra perto
        -- root.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    end
end

-- // COMBATE //
local function CastSkills()
    local key = SKILLS[skillIndex]
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    
    skillIndex = skillIndex + 1
    if skillIndex > #SKILLS then skillIndex = 1 end
    lastSkill = tick()
end

-- // LOOP PRINCIPAL //
local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        if SETTINGS.AnchorPlayer and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
        end
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 100)
        if LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().SilentFarm then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end
    
    -- Varre Inimigos
    local folder = GetEnemiesFolder()
    local hitSomething = false
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            local hum = mob:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                ExpandMob(mob)
                hitSomething = true
            else
                -- Limpa da memória se morreu
                ExpandedMobs[mob] = nil
            end
        end
    end
    
    if hitSomething then
        Status.Text = "⚔️ ATACANDO ÁREA"
        
        -- Bate no vento (hitbox gigante vai pegar)
        if tool and tick() - lastAttack > SETTINGS.AttackInterval then
            tool:Activate()
            lastAttack = tick()
        end
        
        if tick() - lastSkill > SETTINGS.SkillInterval then
            CastSkills()
        end
    else
        Status.Text = "Procurando Alvos..."
    end
end)

-- Anti-AFK Simples
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)