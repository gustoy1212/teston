--[[
    🛡️ SAO TITAN SLAYER (HITBOX + SAFE ZONE)
    
    ESTRATÉGIA:
    1. Aumenta a Hitbox do inimigo para 60x60x60.
    2. Para o jogador a 18 studs de distância (Seguro).
    3. Clica no botão MobileAttackButton.
    
    RESULTADO: Você acerta ele, ele não te alcança.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().TitanSlayer = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    SafeDist = 18,        -- Fica a 18 metros (Longe do alcance do bicho)
    HitboxSize = 60,      -- Tamanho do alvo (Gigante pra compensar a distância)
    SearchRange = 3000,
    ClickSpeed = 0.1,
}

-- Estados
local IsRunning = false
local CurrentTarget = nil
local OriginalSizes = {} -- Guarda tamanho original pra não bugar depois

-- // GUI SETUP //
if CoreGui:FindFirstChild("TitanUI") then CoreGui.TitanUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TitanUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 10, 50)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🛡️ TITAN SLAYER (SAFE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ToggleBtn.Text = "INICIAR MODO TITÃ"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES DE HITBOX //

local function ExpandHitbox(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
    
    -- Transforma em cubo gigante fantasma
    root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
    root.CanCollide = false -- Importante pra você não travar nele
    root.Transparency = 0.7 -- Meio invisível pra você ver onde ele tá
    root.Color = Color3.fromRGB(0, 255, 255)
end

local function RestoreHitbox(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        root.Transparency = 1
        root.CanCollide = true
    end
    OriginalSizes[mob] = nil
end

-- // MOVIMENTO //

local function MoveTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMove()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- // ATAQUE (BUTTON SMASHER INTEGRADO) //
local function SmashButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    -- Caminho confirmado
    local btn = playerGui:FindFirstChild("DeviceGui")
        and playerGui.DeviceGui:FindFirstChild("Mobile")
        and playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
    
    if btn and btn.Visible then
        -- Ativa Evento
        if firesignal then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            pcall(function() firesignal(btn.Activated) end)
        end
        -- Simula Toque
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local centerX = pos.X + (size.X / 2)
        local centerY = pos.Y + (size.Y / 2)
        
        VirtualInputManager:SendTouchEvent(999, 0, centerX, centerY, 0, false, game, 1)
        task.wait()
        VirtualInputManager:SendTouchEvent(999, 1, centerX, centerY, 0, false, game, 1)
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TitanSlayer = false
    StopMove()
    -- Limpa bagunça
    for mob, _ in pairs(OriginalSizes) do RestoreHitbox(mob) end
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "INICIAR MODO TITÃ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        StopMove()
        if CurrentTarget then RestoreHitbox(CurrentTarget) end
        CurrentTarget = nil
    end
end)

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().TitanSlayer do
        task.wait(0.1)
        
        if IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local myRoot = char.HumanoidRootPart
            
            -- 1. ALVO ATUAL
            if CurrentTarget then
                local hum = CurrentTarget:FindFirstChild("Humanoid")
                local root = CurrentTarget:FindFirstChild("HumanoidRootPart")
                
                if not hum or hum.Health <= 0 or not root or not CurrentTarget.Parent then
                    -- Morreu
                    RestoreHitbox(CurrentTarget)
                    CurrentTarget = nil
                    StopMove()
                else
                    -- MANTÉM GIGANTE
                    ExpandHitbox(CurrentTarget)
                    
                    local dist = (myRoot.Position - root.Position).Magnitude
                    
                    -- LÓGICA DE DISTÂNCIA SEGURA
                    if dist > SETTINGS.SafeDist then
                        -- Se estiver longe, aproxima
                        Status.Text = "🏃 APROXIMANDO..."
                        MoveTo(root.Position)
                    elseif dist < (SETTINGS.SafeDist - 2) then
                         -- Se estiver MUITO perto, recua (pra não levar dano)
                        Status.Text = "⚠️ RECUANDO (MUITO PERTO)"
                        local awayDir = (myRoot.Position - root.Position).Unit
                        MoveTo(myRoot.Position + awayDir * 5)
                    else
                        -- ESTÁ NA DISTÂNCIA PERFEITA
                        Status.Text = "⚔️ ATACANDO (SEGURO)"
                        StopMove()
                        
                        -- Olha pro bicho
                        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(root.Position.X, myRoot.Position.Y, root.Position.Z))
                        
                        SmashButton()
                    end
                end
                
            else
                -- 2. BUSCA NOVO
                local folder = Workspace:FindFirstChild("Mobs")
                if folder then
                    local closest, minDist = nil, SETTINGS.SearchRange
                    
                    for _, mob in ipairs(folder:GetChildren()) do
                        local hum = mob:FindFirstChild("Humanoid")
                        local root = mob:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            local dist = (myRoot.Position - root.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                closest = mob
                            end
                        end
                    end
                    
                    if closest then
                        CurrentTarget = closest
                    else
                        Status.Text = "Procurando Mobs..."
                        StopMove()
                    end
                end
            end
        end
    end
end)