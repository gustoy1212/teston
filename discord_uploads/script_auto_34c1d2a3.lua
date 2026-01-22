-- [[ 👑 OMNI-KING: DUNGEON DESTROYER ]] --
-- "Não é farmar, é colher."

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES GLOBAIS //
getgenv().OmniSettings = {
    Magnet = false,       -- Puxar Mobs
    MagnetRange = 5000,   -- Alcance (Mapa todo praticamente)
    HitboxSize = 80,      -- Tamanho do mob (Gigante)
    FreezeMobs = true,    -- Deixa os mobs "moles" (não atacam)
    
    FastAttack = false,   -- Ataque Rápido
    DeleteStates = true,  -- Remove o cooldown real do jogo
    AnimSpeed = 100,      -- Velocidade da animação
    
    AutoClick = false,    -- Clica sozinho
    InvisibleMobs = false -- Deixa mobs invisíveis (FPS Boost)
}

-- // UI SETUP (VISUAL AGRESSIVO) //
local ScreenName = "OmniKingUI"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 50)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 0, 50)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size = UDim2.new(1, 0, 1, 0)
TitleLbl.Text = "👑 OMNI-KING (GOD MODE)"
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.Font = Enum.Font.GothamBlack
TitleLbl.TextSize = 18
TitleLbl.BackgroundTransparency = 1

-- Botão Fechar
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Container de Botões
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -10, 0.85, -10)
Scroll.Position = UDim2.new(0, 5, 0.12, 0)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Função para criar Toggles
local function CreateToggle(text, configKey, colorOn)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(0.95, 0, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        getgenv().OmniSettings[configKey] = not getgenv().OmniSettings[configKey]
        local state = getgenv().OmniSettings[configKey]
        
        if state then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = colorOn
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end)
end

-- CRIAÇÃO DOS BOTÕES
CreateToggle("🕳️ BURACO NEGRO (Magnet)", "Magnet", Color3.fromRGB(100, 0, 255))
CreateToggle("⚔️ DPS GOD (No Cooldown)", "FastAttack", Color3.fromRGB(255, 50, 0))
CreateToggle("🤖 AUTO CLICKER", "AutoClick", Color3.fromRGB(0, 200, 100))
CreateToggle("👻 MOBS INVISÍVEIS (No Lag)", "InvisibleMobs", Color3.fromRGB(50, 50, 50))


-- // LÓGICA DO SISTEMA //

-- 1. MAGNETO ABSURDO
RunService.Heartbeat:Connect(function()
    if not getgenv().OmniSettings.Magnet then return end
    
    local MyChar = LocalPlayer.Character
    if not MyChar or not MyChar:FindFirstChild("HumanoidRootPart") then return end
    
    local MyRoot = MyChar.HumanoidRootPart
    -- Puxa para a frente do player (distância segura pra não bugar a câmera)
    local PullCFrame = MyRoot.CFrame * CFrame.new(0, 0, -5) 

    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            -- Filtro ultra genérico para pegar TUDO que é vivo e não é você
            if obj:IsA("Humanoid") and obj.Parent ~= MyChar and obj.Health > 0 then
                local mobRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
                
                if mobRoot then
                    local dist = (mobRoot.Position - MyRoot.Position).Magnitude
                    
                    if dist <= getgenv().OmniSettings.MagnetRange then
                        -- Teleporta
                        mobRoot.CFrame = PullCFrame
                        mobRoot.Velocity = Vector3.new(0,0,0)
                        mobRoot.RotVelocity = Vector3.new(0,0,0)
                        
                        -- Deixa Gigante (Hitbox Solar)
                        mobRoot.Size = Vector3.new(getgenv().OmniSettings.HitboxSize, getgenv().OmniSettings.HitboxSize, getgenv().OmniSettings.HitboxSize)
                        mobRoot.CanCollide = false
                        
                        -- Inutiliza o Mob (Stun Infinito)
                        if getgenv().OmniSettings.FreezeMobs then
                            obj.PlatformStand = true -- Mob cai no chão e não levanta
                        end
                        
                        -- Modo Invisível (FPS)
                        if getgenv().OmniSettings.InvisibleMobs then
                            mobRoot.Transparency = 1
                            for _, part in pairs(obj.Parent:GetChildren()) do
                                if part:IsA("BasePart") then part.Transparency = 1 end
                            end
                        else
                            mobRoot.Transparency = 0.8 -- Visibilidade padrão do cheat
                            mobRoot.Color = Color3.fromRGB(255, 0, 0)
                        end
                    end
                end
            end
        end
    end)
end)

-- 2. DPS GOD & NO COOLDOWN
RunService.RenderStepped:Connect(function()
    if not getgenv().OmniSettings.FastAttack then return end
    
    local Char = LocalPlayer.Character
    if not Char then return end
    
    local Tool = Char:FindFirstChildOfClass("Tool")
    
    -- A. Deletar States (Baseado nos seus Logs)
    -- Isso engana o servidor achando que você não está atacando
    if getgenv().OmniSettings.DeleteStates then
        pcall(function()
            local States = Char:FindFirstChild("States")
            if States then
                local Skill = States:FindFirstChild("UsingSkill")
                if Skill then Skill:Destroy() end
                
                local Stun = States:FindFirstChild("Stunned") -- Remove stun se o mob te bater
                if Stun then Stun:Destroy() end
            end
        end)
    end
    
    -- B. Animação e Ativação
    if Tool then
        Tool.Enabled = true -- Força a ferramenta a estar pronta
        
        -- Acelera animações
        local Hum = Char:FindFirstChild("Humanoid")
        if Hum then
            local Animator = Hum:FindFirstChildOfClass("Animator")
            if Animator then
                for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(getgenv().OmniSettings.AnimSpeed)
                end
            end
        end
        
        -- Auto Click
        if getgenv().OmniSettings.AutoClick then
            Tool:Activate()
        end
    end
end)