--[[
    🧟 HUNTER ZOMBIE - AUTO FARM GOD MODE (v2.0)
    Features:
    - GUI de Controle (On/Off)
    - Safe Spot (Fica flutuando na cabeça do monstro)
    - Anti-Kick (Voa suavemente até o alvo se estiver longe)
    - Auto-Attack com Tools
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES AVANÇADAS //
local SETTINGS = {
    FarmEnabled = false,       -- Começa desligado
    DistanceAboveHead = 6,     -- Altura acima da cabeça (Safe Spot)
    TweenSpeed = 200,          -- Velocidade do voo (Studs por segundo) - Ajuste se tiver lento
    AttackDist = 15,           -- Distância para começar a atacar
}

-- // SISTEMA DE GUI (PAINEL) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HunterZombieGUI"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0) -- Canto esquerdo
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true -- Pode arrastar o painel
MainFrame.Parent = ScreenGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = "FARM: OFF 🔴"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

-- Função do Botão
ToggleBtn.MouseButton1Click:Connect(function()
    SETTINGS.FarmEnabled = not SETTINGS.FarmEnabled
    if SETTINGS.FarmEnabled then
        ToggleBtn.Text = "FARM: ON 🟢"
        ToggleBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        ToggleBtn.Text = "FARM: OFF 🔴"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        -- Cancela qualquer movimento atual
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- Para o personagem no ar
            char.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
end)

-- // LÓGICA DO FARM //

local currentTween = nil

-- Verifica se é inimigo (Nome Numérico)
local function isEnemy(model)
    if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
        if tonumber(model.Name) ~= nil then -- Se o nome for número (1, 2, 3...)
            if model.Humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

-- Pega o inimigo mais próximo
local function getClosestEnemy()
    local closest = nil
    local minDistance = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not myRoot then return nil end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if isEnemy(obj) then
            local dist = (myRoot.Position - obj.HumanoidRootPart.Position).Magnitude
            if dist < minDistance then
                minDistance = dist
                closest = obj
            end
        end
    end
    return closest
end

-- Loop Principal
RunService.Heartbeat:Connect(function()
    if not SETTINGS.FarmEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChild("Humanoid")

    -- Garante que a ferramenta está equipada
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local backpackTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if backpackTool then humanoid:EquipTool(backpackTool) end
    end

    -- Busca Alvo
    local target = getClosestEnemy()
    
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        
        -- Calcula altura do monstro para ficar na cabeça
        local enemyHeight = target:GetExtentsSize().Y
        local safePosition = targetRoot.CFrame * CFrame.new(0, (enemyHeight/2) + SETTINGS.DistanceAboveHead, 0)
        
        local dist = (hrp.Position - safePosition.Position).Magnitude

        -- SISTEMA ANTI-KICK (Movimento Híbrido)
        if dist > 50 then
            -- Se estiver longe (>50 studs), usa Tween (Voo Suave) para não ser kickado
            local timeToTravel = dist / SETTINGS.TweenSpeed
            local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
            
            if not currentTween or currentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = safePosition})
                currentTween:Play()
            else
                -- Atualiza o destino se o monstro andou, mas sem spammar tweens
                -- (Otimização básica)
            end
            
            -- Tira gravidade para voar liso
            hrp.Velocity = Vector3.new(0, 0, 0)
            
        else
            -- Se estiver perto, TELEPORTA e TRAVA na cabeça (Lock)
            if currentTween then currentTween:Cancel() currentTween = nil end
            
            hrp.CFrame = safePosition
            hrp.Velocity = Vector3.new(0, 0, 0) -- Não cair
            
            -- ATAQUE
            if tool and dist < SETTINGS.AttackDist then
                tool:Activate()
            end
        end
    else
        -- Se não tiver inimigo, para o tween e fica parado
        if currentTween then currentTween:Cancel() end
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- Anti-Afk Simples (pra não cair por inatividade)
LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

print("✅ Auto-Farm GUI Carregado!")
