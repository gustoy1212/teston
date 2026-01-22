-- [[ 👑 OMNI-LEGACY V5: BLACK HOLE EDITION ]] --
-- Alcance Infinito + Varredura Global de Mobs

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
getgenv().OmniConfig = {
    Running = true,
    
    -- Magneto & Alcance
    MagnetMode = "OFF",   -- "OFF", "SINGLE", "MASS"
    HitboxSize = 70,      -- Aumentei um pouco mais
    MagnetDist = 5,       -- Distância da sua cara
    UniversalScan = false, -- [NOVO] Se true, varre o mapa todo (ignora pastas)
    
    -- Ataque
    DPS_Mode = false,     
    AnimSpeed = 60,
    DeleteStates = true,
    AutoClick = false,
    
    -- Extras
    LootVacuum = false,
    AutoChest = false,
    GodBody = false
}

-- Variáveis Internas
local OriginalSizes = {} 
local SingleTarget = nil

-- // UI SETUP //
local ScreenName = "OmniLegacyV5"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 360, 0, 420)
MainFrame.Position = UDim2.new(0.5, -180, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderColor3 = Color3.fromRGB(170, 0, 255) -- Roxo Black Hole
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🌌 OMNI-LEGACY V5 (BLACK HOLE)"
Title.TextColor3 = Color3.fromRGB(170, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().OmniConfig.Running = false end)

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.85, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.10, 0)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 5)

-- Função Helper para Botões
local function CreateBtn(text, color, callback)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

-- 1. MAGNETO
CreateBtn("🧲 MAGNETO: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    if getgenv().OmniConfig.MagnetMode == "OFF" then
        getgenv().OmniConfig.MagnetMode = "SINGLE"
        btn.Text = "🧲 MAGNETO: [1v1]"
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    elseif getgenv().OmniConfig.MagnetMode == "SINGLE" then
        getgenv().OmniConfig.MagnetMode = "MASS"
        btn.Text = "🧲 MAGNETO: [BURACO NEGRO]"
        btn.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
    else
        getgenv().OmniConfig.MagnetMode = "OFF"
        btn.Text = "🧲 MAGNETO: [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        -- Limpa
        for mob, _ in pairs(OriginalSizes) do
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                mob.HumanoidRootPart.Size = OriginalSizes[mob]
                mob.HumanoidRootPart.Transparency = 0
            end
        end
        OriginalSizes = {}
    end
end)

-- 2. UNIVERSAL SCAN (O SEGREDO DO ALCANCE)
CreateBtn("📡 VARREDURA GLOBAL: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.UniversalScan = not getgenv().OmniConfig.UniversalScan
    if getgenv().OmniConfig.UniversalScan then
        btn.Text = "📡 VARREDURA GLOBAL: [ON] (LAG ALERT)"
        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    else
        btn.Text = "📡 VARREDURA GLOBAL: [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
end)

-- 3. DPS GOD
CreateBtn("⚔️ DPS GOD (NO CD): [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.DPS_Mode = not getgenv().OmniConfig.DPS_Mode
    btn.Text = getgenv().OmniConfig.DPS_Mode and "⚔️ DPS GOD: [ON]" or "⚔️ DPS GOD: [OFF]"
    btn.BackgroundColor3 = getgenv().OmniConfig.DPS_Mode and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 50, 60)
end)

-- 4. AUTO CLICK
CreateBtn("🤖 AUTO CLICK: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.AutoClick = not getgenv().OmniConfig.AutoClick
    btn.Text = getgenv().OmniConfig.AutoClick and "🤖 AUTO CLICK: [ON]" or "🤖 AUTO CLICK: [OFF]"
    btn.BackgroundColor3 = getgenv().OmniConfig.AutoClick and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(50, 50, 60)
end)

-- 5. LOOT VACUUM
CreateBtn("🧹 ASPIRADOR DE LOOT: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.LootVacuum = not getgenv().OmniConfig.LootVacuum
    btn.Text = getgenv().OmniConfig.LootVacuum and "🧹 LOOT VACUUM: [ON]" or "🧹 LOOT VACUUM: [OFF]"
    btn.BackgroundColor3 = getgenv().OmniConfig.LootVacuum and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(50, 50, 60)
end)

-- 6. AUTO CHEST
CreateBtn("📦 AUTO BAÚ: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.AutoChest = not getgenv().OmniConfig.AutoChest
    btn.Text = getgenv().OmniConfig.AutoChest and "📦 AUTO BAÚ: [ON]" or "📦 AUTO BAÚ: [OFF]"
    btn.BackgroundColor3 = getgenv().OmniConfig.AutoChest and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 60)
end)

CreateBtn("🛡️ ANTI-STUN/KB: [OFF]", Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.GodBody = not getgenv().OmniConfig.GodBody
    btn.Text = getgenv().OmniConfig.GodBody and "🛡️ ANTI-STUN: [ON]" or "🛡️ ANTI-STUN: [OFF]"
    btn.BackgroundColor3 = getgenv().OmniConfig.GodBody and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(50, 50, 60)
end)


-- // LÓGICA DE DETECÇÃO (ATUALIZADA) //

local function GetTargets()
    local targets = {}
    
    if getgenv().OmniConfig.UniversalScan then
        -- MODO AGRESSIVO: Varre tudo no Workspace (Cuidado com LAG)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Parent ~= LocalPlayer.Character and obj.Health > 0 then
                table.insert(targets, obj.Parent)
            end
        end
    else
        -- MODO SEGURO: Procura pastas específicas
        local foldersToScan = {}
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") or child.Name:match("Dungeon") or child.Name:match("Enemy") then
                table.insert(foldersToScan, child)
            end
        end
        
        for _, folder in ipairs(foldersToScan) do
            for _, mob in ipairs(folder:GetChildren()) do
                if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    table.insert(targets, mob)
                end
            end
        end
    end
    
    return targets
end

local function ModifyMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    root.Size = Vector3.new(getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize)
    root.Transparency = 0.7
    root.CanCollide = false
    root.Massless = true
end

-- // LOOPS PRINCIPAIS //

-- Loop Lento (Para buscar alvos e não travar PC)
task.spawn(function()
    while true do
        task.wait(0.2) -- Verifica a cada 0.2s
        if not getgenv().OmniConfig.Running then break end
        
        if getgenv().OmniConfig.MagnetMode == "MASS" then
             local MyChar = LocalPlayer.Character
             if MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
                local PullPos = MyChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -getgenv().OmniConfig.MagnetDist)
                local targets = GetTargets()
                
                for _, mob in ipairs(targets) do
                    pcall(function()
                        local r = mob:FindFirstChild("HumanoidRootPart")
                        if r then
                             -- Removi o limite de distância (Alcance Infinito)
                             ModifyMob(mob)
                             r.CFrame = PullPos
                             r.Velocity = Vector3.new(0,0,0)
                             r.RotVelocity = Vector3.new(0,0,0)
                        end
                    end)
                end
             end
        end
    end
end)

-- Loop Rápido (Single Target e Features Visuais)
RunService.Heartbeat:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")

    -- 1v1 Mode (Renderizado rápido)
    if getgenv().OmniConfig.MagnetMode == "SINGLE" and MyRoot then
        local targets = GetTargets()
        local closest, dist = nil, 50000 -- Alcance máximo absurdo
        
        for _, mob in ipairs(targets) do
            local r = mob:FindFirstChild("HumanoidRootPart")
            if r then
                local mag = (r.Position - MyRoot.Position).Magnitude
                if mag < dist then
                    dist = mag
                    closest = mob
                end
            end
        end
        
        if closest then
            local r = closest.HumanoidRootPart
            local PullPos = MyRoot.CFrame * CFrame.new(0, 0, -getgenv().OmniConfig.MagnetDist)
            ModifyMob(closest)
            r.CFrame = PullPos
            r.Velocity = Vector3.new(0,0,0)
        end
    end

    -- LOOT VACUUM
    if getgenv().OmniConfig.LootVacuum and MyRoot then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if (obj:IsA("Tool") or obj.Name:lower():find("drop") or obj.Name:lower():find("coin") or obj.Name:lower():find("potion")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                    if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                        obj.Handle.CFrame = MyRoot.CFrame
                    elseif obj:IsA("BasePart") and not obj:FindFirstAncestorOfClass("Player") then
                        obj.CFrame = MyRoot.CFrame
                    end
                end
            end
        end)
    end
    
    -- AUTO CHEST
    if getgenv().OmniConfig.AutoChest then
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local pName = v.Parent.Name:lower()
                    if pName:find("chest") or pName:find("bau") or pName:find("loot") then
                        fireproximityprompt(v)
                    end
                end
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    
    -- DPS & ANTI-STUN
    if getgenv().OmniConfig.DPS_Mode or getgenv().OmniConfig.GodBody then
        pcall(function()
            local s = Char:FindFirstChild("States")
            if s then
                if getgenv().OmniConfig.DPS_Mode and s:FindFirstChild("UsingSkill") then s.UsingSkill:Destroy() end
                if getgenv().OmniConfig.GodBody then
                    if s:FindFirstChild("Stunned") then s.Stunned:Destroy() end
                    if s:FindFirstChild("Knockback") then s.Knockback:Destroy() end
                    if s:FindFirstChild("Slowed") then s.Slowed:Destroy() end
                end
            end
        end)
        
        if getgenv().OmniConfig.DPS_Mode then
            local hum = Char:FindFirstChild("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(getgenv().OmniConfig.AnimSpeed)
                    end
                end
            end
        end
    end
    
    if getgenv().OmniConfig.AutoClick then
        local Tool = Char:FindFirstChildOfClass("Tool")
        if Tool then Tool.Enabled = true Tool:Activate() end
    end
end)