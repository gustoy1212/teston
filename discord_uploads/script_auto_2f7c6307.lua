-- [[ ⚔️ OMNI-LEGACY V3: HYBRID EDITION ]] --
-- A estabilidade do seu script antigo + A potência dos novos logs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
getgenv().OmniConfig = {
    Running = true,
    MagnetMode = "OFF",   -- "OFF", "SINGLE" (1v1), "MASS" (Buraco Negro)
    HitboxSize = 60,      -- Tamanho do mob (igual seu script)
    MagnetDist = 6,       -- Distância da sua cara
    
    DPS_Mode = false,     -- Ativar Super Dano
    AnimSpeed = 50,       -- Velocidade da animação (50x é safe)
    DeleteStates = true,  -- Remove o cooldown real (Tecnologia nova)
    AutoClick = false     -- Clica sozinho
}

-- Variáveis de Controle (Do seu script antigo)
local SingleTarget = nil
local MassTargets = {}
local OriginalSizes = {} 

-- // UI SETUP (Simples e Eficiente) //
local ScreenName = "OmniLegacyUI"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 250)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja Lendário
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "⚔️ OMNI-LEGACY V3"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().OmniConfig.Running = false end)

-- Status
local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0.15, 0)
StatusLbl.Text = "Aguardando..."
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.BackgroundTransparency = 1

-- // BOTÕES DE CONTROLE //
local function CreateBtn(text, yPos, color, callback)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0.18, 0)
    btn.Position = UDim2.new(0.05, 0, yPos, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function() callback(btn) end)
end

-- 1. Botão Magneto (Ciclo: OFF -> 1v1 -> MASS -> OFF)
CreateBtn("🧲 MAGNETO: [OFF]", 0.28, Color3.fromRGB(50, 50, 60), function(btn)
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
        -- Restaura mobs ao desligar
        for mob, _ in pairs(OriginalSizes) do
            local root = mob:FindFirstChild("HumanoidRootPart")
            if root then root.Size = OriginalSizes[mob] root.Transparency = 1 end
        end
        OriginalSizes = {}
        MassTargets = {}
        SingleTarget = nil
    end
end)

-- 2. Botão DPS GOD (O Novo Hack)
CreateBtn("⚔️ DPS GOD + NO COOLDOWN: [OFF]", 0.50, Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.DPS_Mode = not getgenv().OmniConfig.DPS_Mode
    if getgenv().OmniConfig.DPS_Mode then
        btn.Text = "⚔️ DPS GOD: [ON] (DELETING STATES)"
        btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        btn.Text = "⚔️ DPS GOD: [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
end)

-- 3. Botão Auto Click
CreateBtn("🤖 AUTO CLICK: [OFF]", 0.72, Color3.fromRGB(50, 50, 60), function(btn)
    getgenv().OmniConfig.AutoClick = not getgenv().OmniConfig.AutoClick
    if getgenv().OmniConfig.AutoClick then
        btn.Text = "🤖 AUTO CLICK: [ON]"
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    else
        btn.Text = "🤖 AUTO CLICK: [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
end)

-- // FUNÇÕES LÓGICAS (DO SEU SCRIPT) //

-- Busca inteligente (Só pega o que está nas pastas de monstros)
local function GetEnemiesFolder()
    for _, child in ipairs(Workspace:GetChildren()) do
        -- Adicionei "Dungeon" e "Monsters" por garantia
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") or child.Name:match("Dungeon") then
            return child
        end
    end
    return nil -- Se não achar pasta, não faz nada (Evita lag e NPCs)
end

local function ModifyMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Salva tamanho original (Anti-Bug)
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- Aplica Hitbox Gigante (Sua técnica)
    root.Size = Vector3.new(getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize)
    root.Transparency = 0.7
    root.CanCollide = false
    root.Massless = true
    
    if getgenv().OmniConfig.MagnetMode == "MASS" then
        root.Color = Color3.fromRGB(255, 50, 50)
    else
        root.Color = Color3.fromRGB(50, 150, 255)
    end
end

-- // LOOP PRINCIPAL 1: MAGNETO (HEARTBEAT) //
RunService.Heartbeat:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    if getgenv().OmniConfig.MagnetMode == "OFF" then return end
    
    local MyChar = LocalPlayer.Character
    if not MyChar or not MyChar:FindFirstChild("HumanoidRootPart") then return end
    
    local PullPos = MyChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -getgenv().OmniConfig.MagnetDist)
    local Folder = GetEnemiesFolder()
    
    if not Folder then 
        StatusLbl.Text = "⚠️ Pasta de Mobs não encontrada!"
        return 
    end

    if getgenv().OmniConfig.MagnetMode == "SINGLE" then
        -- Lógica 1v1
        if SingleTarget and SingleTarget.Parent and SingleTarget:FindFirstChild("Humanoid") and SingleTarget.Humanoid.Health > 0 then
            ModifyMob(SingleTarget)
            local r = SingleTarget.HumanoidRootPart
            if r then
                r.CFrame = PullPos
                r.Velocity = Vector3.new(0,0,0)
            end
            StatusLbl.Text = "Target: " .. SingleTarget.Name
        else
            -- Busca novo alvo
            local closest, dist = nil, 2000
            for _, mob in ipairs(Folder:GetChildren()) do
                if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
                    local mag = (mob.HumanoidRootPart.Position - MyChar.HumanoidRootPart.Position).Magnitude
                    if mag < dist then
                        dist = mag
                        closest = mob
                    end
                end
            end
            SingleTarget = closest
        end
        
    elseif getgenv().OmniConfig.MagnetMode == "MASS" then
        -- Lógica Buraco Negro
        local count = 0
        for _, mob in ipairs(Folder:GetChildren()) do
            if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") then
                if mob.Humanoid.Health > 0 then
                    local r = mob.HumanoidRootPart
                    local dist = (r.Position - MyChar.HumanoidRootPart.Position).Magnitude
                    
                    if dist < 3000 then -- Alcance alto
                        ModifyMob(mob)
                        r.CFrame = PullPos
                        r.Velocity = Vector3.new(0,0,0) -- Tira a força dele
                        r.RotVelocity = Vector3.new(0,0,0)
                        count = count + 1
                    end
                end
            end
        end
        StatusLbl.Text = "🌌 Sugando: " .. count .. " Mobs"
    end
end)

-- // LOOP PRINCIPAL 2: DPS & NO COOLDOWN (RENDERSTEPPED) //
RunService.RenderStepped:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    
    local Char = LocalPlayer.Character
    if not Char then return end
    local Tool = Char:FindFirstChildOfClass("Tool")
    
    -- 1. Auto Click
    if Tool and getgenv().OmniConfig.AutoClick then
        Tool:Activate()
    end
    
    -- 2. Lógica DPS GOD
    if getgenv().OmniConfig.DPS_Mode then
        -- A. Deleta o State (ISSO É O SEGREDO DO LOG)
        if getgenv().OmniConfig.DeleteStates then
            pcall(function()
                local s = Char:FindFirstChild("States")
                if s then
                    local skill = s:FindFirstChild("UsingSkill")
                    if skill then skill:Destroy() end -- Puf! Jogo acha que vc parou de bater
                end
            end)
        end
        
        -- B. Acelera Animação (Do seu script antigo)
        local hum = Char:FindFirstChild("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(getgenv().OmniConfig.AnimSpeed)
                end
            end
        end
        
        -- C. Força Ferramenta Pronta
        if Tool then Tool.Enabled = true end
    end
end)