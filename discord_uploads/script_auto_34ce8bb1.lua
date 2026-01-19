--[[
    🧙‍♂️ RPG SILENT KILLER v2 (GHOST EDITION)
    
    CORREÇÕES:
    - HITBOX FANTASMA: Força CanCollide = false em todos os frames.
      (Resolve o problema de ficar travado dentro do monstro).
    - INVISÍVEL: Hitbox com transparência total para não atrapalhar a visão.
    - ESP: Mostra uma caixa vermelha (SelectionBox) para saber onde o bicho tá.
    
    COMO USAR:
    - Fique parado num lugar seguro.
    - Ative. Os monstros vão "encher a sala", mas você não vai sentir (fantasma).
    - Seu boneco vai bater no ar e matar eles.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

getgenv().SilentGhost = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    HitboxSize = 250,      -- Tamanho Gigante (Cobre mapa)
    AttackInterval = 0.1,  -- Velocidade do clique
    SkillInterval = 1.5,   -- Velocidade das skills
    AnchorPlayer = true,   -- Trava seu boneco (Recomendado pra AFK)
}

local SKILLS = {"Z", "X", "C", "V"}
local skillIndex = 1
local lastSkill = 0
local lastAttack = 0
local ExpandedMobs = {} 

-- // GUI SETUP //
if CoreGui:FindFirstChild("RPGGhost") then CoreGui.RPGGhost:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGGhost"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 140)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "👻 SILENT GHOST v2"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
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
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
ToggleBtn.Text = "LIGAR FARM (NO COLLISION)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO FECHAR //
local function RestoreAll()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    -- Restaura mobs
    for mob, vals in pairs(ExpandedMobs) do
        if mob and mob.Parent and mob:FindFirstChild("HumanoidRootPart") and vals.OriginalSize then
            mob.HumanoidRootPart.Size = vals.OriginalSize
            mob.HumanoidRootPart.Transparency = vals.OriginalTransp
            mob.HumanoidRootPart.CanCollide = true
            if mob.HumanoidRootPart:FindFirstChild("GhostESP") then
                mob.HumanoidRootPart.GhostESP:Destroy()
            end
        end
    end
    ExpandedMobs = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SilentGhost = false
    Status.Text = "ENCERRADO"
    RestoreAll()
    ScreenGui:Destroy()
end)

-- // LOCALIZADOR //
local function GetEnemiesFolder()
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            return child
        end
    end
    return Workspace
end

-- // EXPANSÃO FANTASMA //
local function ExpandMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChild("Humanoid")
    
    if root and hum and hum.Health > 0 then
        -- Salva estado original (uma vez só)
        if not ExpandedMobs[mob] then
            ExpandedMobs[mob] = {
                OriginalSize = root.Size,
                OriginalTransp = root.Transparency
            }
            
            -- Cria ESP visual (já que a hitbox vai ficar invisível)
            local box = Instance.new("SelectionBox")
            box.Name = "GhostESP"
            box.Adornee = root
            box.Color3 = Color3.fromRGB(255, 0, 0)
            box.Transparency = 0.5
            box.Parent = root
        end
        
        -- APLICA O MODO FANTASMA
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = 1 -- Invisível pra não poluir
        root.CanCollide = false -- SEM COLISÃO
        root.CanTouch = true    -- MAS TOCA NA ESPADA
        root.Massless = true    -- SEM PESO
        
        -- Traz pra perto (Opcional, ajuda se o ataque for curto)
        -- root.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end

-- // GARANTIDOR DE "SEM COLISÃO" //
-- Roda a cada frame de física para garantir que ninguém fique sólido
RunService.Stepped:Connect(function()
    if not getgenv().SilentGhost then return end
    
    for mob, _ in pairs(ExpandedMobs) do
        if mob and mob.Parent and mob:FindFirstChild("HumanoidRootPart") then
            -- Força bruta: Ninguém tem colisão
            mob.HumanoidRootPart.CanCollide = false
            for _, part in pairs(mob:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        else
            ExpandedMobs[mob] = nil -- Limpa memória se morreu
        end
    end
end)

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

-- // MAIN LOOP //
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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
        RestoreAll()
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().SilentGhost then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Auto Equip
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if bp then char.Humanoid:EquipTool(bp) end
    end
    
    -- Varre Pasta
    local folder = GetEnemiesFolder()
    local activeTargets = 0
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            local hum = mob:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                ExpandMob(mob)
                activeTargets = activeTargets + 1
            end
        end
    end
    
    if activeTargets > 0 then
        Status.Text = "☠️ DRENANDO: " .. activeTargets .. " ALVOS"
        
        -- ATAQUE
        if tool and tick() - lastAttack > SETTINGS.AttackInterval then
            tool:Activate()
            lastAttack = tick()
        end
        
        if tick() - lastSkill > SETTINGS.SkillInterval then
            CastSkills()
        end
    else
        Status.Text = "Procurando na Pasta..."
    end
end)

-- Anti-AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)