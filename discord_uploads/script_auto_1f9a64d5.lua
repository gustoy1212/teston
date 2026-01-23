--[[
    🏴‍☠️ BLOX FRUITS - GHOST FARM (LOG BASED)
    
    FUNCIONALIDADES:
    1. AUTO FARM: Voa até o inimigo mais próximo.
    2. GOD MODE (POSIÇÃO): Fica flutuando acima do inimigo para evitar dano.
    3. SKILL SPAM: Usa Z, X, C, V e Ataque Básico (Baseado na estrutura da Rubber/Flame dos logs).
    4. NO CLIP: Atravessa paredes enquanto voa.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().BloxFruitsFarm = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    FarmDist = 3000,       -- Distância máxima para buscar inimigos
    AttackDistance = 7,    -- Distância para ficar do inimigo (acima dele)
    TweenSpeed = 250,      -- Velocidade do voo (Não coloque muito alto ou toma kick)
    SpamSkills = true,     -- Usar habilidades (Z, X, C, V)
}

-- Estados
local IsFarming = false
local CurrentEnemy = nil
local BodyVelocity = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxFarmUI") then CoreGui.BloxFarmUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxFarmUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 15, 30) -- Azul Oceano
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏴‍☠️ GHOST FARM (BLOX FRUITS)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "ATIVAR FARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES ÚTEIS //

-- NoClip para não bater em paredes
local function EnableNoClip()
    RunService.Stepped:Connect(function()
        if IsFarming and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

-- Levitação (Para não cair)
local function ToggleFloat(enable)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    if enable then
        if not char.HumanoidRootPart:FindFirstChild("FarmVelocity") then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "FarmVelocity"
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(100000, 100000, 100000)
            bv.Parent = char.HumanoidRootPart
        end
    else
        if char.HumanoidRootPart:FindFirstChild("FarmVelocity") then
            char.HumanoidRootPart.FarmVelocity:Destroy()
        end
    end
end

-- Sistema de Ataque (Click + Skills)
local function SpamSkills()
    -- Clica (Mouse/Touch)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    if SETTINGS.SpamSkills then
        -- Aperta Z, X, C, V (Funciona pra PC e emuladores)
        local keys = {Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V}
        for _, key in ipairs(keys) do
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end
    end
end

-- Movimento Suave (Tween)
local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local time = distance / SETTINGS.TweenSpeed
    
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    -- Se estiver muito longe, espera chegar. Se perto, não espera.
    if distance > 50 then
        tween.Completed:Wait()
    end
end

-- Encontra Inimigo
local function GetClosestEnemy()
    local closest, minDist = nil, SETTINGS.FarmDist
    
    -- No Blox Fruits os mobs ficam na pasta Enemies ou Characters (dependendo se é boss)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    
    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            local hum = enemy:FindFirstChild("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            
            if hum and root and hum.Health > 0 then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = enemy
                end
            end
        end
    end
    return closest
end

-- // AUTO EQUIP //
local function AutoEquip()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    
    if backpack and char and not char:FindFirstChildOfClass("Tool") then
        -- Prioriza armas ou frutas (Melee, Sword, Blox Fruit)
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.ToolTip == "Melee" or item.ToolTip == "Sword" or item.ToolTip == "Blox Fruit") then
                char.Humanoid:EquipTool(item)
                break
            end
        end
        -- Se não achou tipo específico, pega qualquer um (ex: Cutlass do log)
        if not char:FindFirstChildOfClass("Tool") then
            local anyTool = backpack:FindFirstChildOfClass("Tool")
            if anyTool then char.Humanoid:EquipTool(anyTool) end
        end
    end
end

-- // UI LOGIC //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BloxFruitsFarm = false
    ToggleFloat(false)
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        ToggleFloat(true)
    else
        ToggleBtn.Text = "ATIVAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        ToggleFloat(false)
        CurrentEnemy = nil
        -- Cancela tween atual
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.1), {CFrame = char.HumanoidRootPart.CFrame}):Play()
        end
    end
end

EnableNoClip()

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().BloxFruitsFarm do
        task.wait()
        
        if IsFarming then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                Status.Text = "💀 Aguardando Respawn..."
                task.wait(2)
                continue
            end
            
            AutoEquip()
            
            -- Busca Inimigo
            if not CurrentEnemy or not CurrentEnemy.Parent or CurrentEnemy.Humanoid.Health <= 0 then
                Status.Text = "🔎 Buscando Alvo..."
                CurrentEnemy = GetClosestEnemy()
            else
                -- Lógica de Combate
                local enemyRoot = CurrentEnemy:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    Status.Text = "⚔️ Farmando: " .. CurrentEnemy.Name
                    
                    -- Posição de Farm: 7 blocos ACIMA do inimigo (God Mode Básico)
                    -- Assim ele não te acerta, mas sua fruta acerta ele.
                    local farmPos = CFrame.new(enemyRoot.Position + Vector3.new(0, SETTINGS.AttackDistance, 0), enemyRoot.Position)
                    
                    local myRoot = char.HumanoidRootPart
                    local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                    
                    if dist > 10 then
                        -- Se longe, voa até lá
                        TweenTo(farmPos)
                    else
                        -- Se perto, trava posição e bate
                        myRoot.CFrame = farmPos -- Teleporte constante pra manter posição
                        SpamSkills()
                    end
                end
            end
        end
    end
end)