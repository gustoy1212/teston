--[[
    👻 BLOX FRUITS - ASTRAL FARM v8 (FAKE WIFI)
    
    COMO FUNCIONA:
    1. Cria um CLONE VISUAL onde você ativou o script.
    2. Trava a câmera nesse clone (você se sente parado).
    3. Seu corpo VERDADEIRO fica invisível e vai até o mob bater.
    4. O jogo aceita o dano porque seu corpo está perto, mas você não vê isso.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES //
local FARM_DIST = 350       -- Distância para buscar inimigos
local ATTACK_DIST = 4       -- Distância para colar no inimigo
local TWEEN_SPEED = 300     -- Velocidade do voo (Quanto maior, mais lento/seguro)

-- Estados
local IsFarming = false
local IsAutoClick = true
local AnchorPoint = nil     -- Onde o "Clone" vai ficar
local FakePart = nil        -- A peça que segura a câmera

-- // GUI SETUP //
if CoreGui:FindFirstChild("BloxAstralUI") then CoreGui.BloxAstralUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BloxAstralUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 30) -- Roxo Escuro (Astral)
MainFrame.BorderColor3 = Color3.fromRGB(150, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "👻 ASTRAL WIFI v8"
Title.BackgroundColor3 = Color3.fromRGB(80, 0, 150)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, 0, 0, 25)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.Text = "Status: Corpo Presente"
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
ToggleBtn.Text = "SAIR DO CORPO (START)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18

local ClickBtn = Instance.new("TextButton", MainFrame)
ClickBtn.Size = UDim2.new(0.9, 0, 0, 30)
ClickBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
ClickBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ClickBtn.Text = "Auto Click: LIGADO"
ClickBtn.TextColor3 = Color3.fromRGB(0, 255, 100)

-- // FUNÇÕES ASTRAIS //

local function CreateFakeBody()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    -- Salva onde você está
    AnchorPoint = char.HumanoidRootPart.CFrame
    
    -- Cria uma peça invisível para segurar a câmera
    FakePart = Instance.new("Part", Workspace)
    FakePart.Name = "AstralAnchor"
    FakePart.Size = Vector3.new(1, 1, 1)
    FakePart.Anchored = true
    FakePart.CanCollide = false
    FakePart.Transparency = 1
    FakePart.CFrame = AnchorPoint
    
    -- TRAVA A CÂMERA AQUI
    Workspace.CurrentCamera.CameraSubject = FakePart
    
    -- Deixa o char invisível (Opcional, pra dar imersão)
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = 0.8 -- Fantasma
        end
    end
end

local function ReturnToBody()
    local char = LocalPlayer.Character
    if char and AnchorPoint then
        -- Teleporta de volta
        char.HumanoidRootPart.CFrame = AnchorPoint
        
        -- Destrava câmera
        if char:FindFirstChild("Humanoid") then
            Workspace.CurrentCamera.CameraSubject = char.Humanoid
        end
        
        -- Volta a visibilidade
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.Transparency = 0 end
        end
    end
    
    if FakePart then FakePart:Destroy() FakePart = nil end
    AnchorPoint = nil
end

local function TweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    -- Se estiver perto, só teleporta (CFrame)
    if dist < 50 then
        root.CFrame = targetCFrame
    else
        -- Se longe, usa Tween pra não tomar kick
        local info = TweenInfo.new(dist / TWEEN_SPEED, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function GetClosestEnemy()
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Characters")
    if not enemiesFolder then return nil end
    
    local closest, minDist = nil, FARM_DIST
    local myPos = FakePart and FakePart.Position or LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, mob in ipairs(enemiesFolder:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
            local dist = (myPos - mob.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = mob
            end
        end
    end
    return closest
end

-- // LOOP PRINCIPAL //
spawn(function()
    while true do
        task.wait()
        
        if IsFarming and AnchorPoint and FakePart then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
                IsFarming = false -- Morreu, para tudo
                ReturnToBody()
                continue
            end
            
            -- Auto Click
            if IsAutoClick then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
            
            local target = GetClosestEnemy()
            
            if target then
                StatusLbl.Text = "Status: ⚔️ ATACANDO " .. target.Name
                StatusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
                
                -- CORPO VAI ATÉ O MOB
                local tRoot = target:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    -- Posição de ataque: Atrás e um pouco acima (God Mode Básico)
                    local attackPos = tRoot.CFrame * CFrame.new(0, 4, 3) 
                    
                    -- Verifica distância REAL do corpo até o mob
                    local realDist = (char.HumanoidRootPart.Position - tRoot.Position).Magnitude
                    
                    if realDist > 10 then
                        TweenTo(attackPos) -- Voa até lá
                    else
                        char.HumanoidRootPart.CFrame = attackPos -- Gruda nele
                        char.HumanoidRootPart.Velocity = Vector3.new(0,0,0) -- Não cai
                    end
                end
            else
                StatusLbl.Text = "Status: 💤 NENHUM ALVO PERTO"
                StatusLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
                
                -- Se não tem inimigo, o corpo volta pro ponto de origem (descansar)
                local distHome = (char.HumanoidRootPart.Position - AnchorPoint.Position).Magnitude
                if distHome > 5 then
                    TweenTo(AnchorPoint)
                end
            end
        end
    end
end)

-- // EVENTOS UI //
ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "VOLTAR AO CORPO (STOP)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CreateFakeBody()
    else
        ToggleBtn.Text = "SAIR DO CORPO (START)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        StatusLbl.Text = "Status: Corpo Presente"
        ReturnToBody()
    end
end)

ClickBtn.MouseButton1Click:Connect(function()
    IsAutoClick = not IsAutoClick
    if IsAutoClick then
        ClickBtn.Text = "Auto Click: LIGADO"
        ClickBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        ClickBtn.Text = "Auto Click: DESLIGADO"
        ClickBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.MouseButton1Click:Connect(function()
    IsFarming = false
    ReturnToBody()
    ScreenGui:Destroy()
end)