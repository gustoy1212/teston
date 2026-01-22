-- [[ OMNI-KILLER V1: MOB MAGNET & INSTA-HIT ]] --
-- Baseado na anulação de States e Teleporte de CFrame

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- CONFIGURAÇÕES GLOBAIS (Toggle)
getgenv().Configs = {
    MobMagnet = false,   -- Puxar mobs
    NoCooldown = false,  -- Bater super rápido (deleta state)
    BigHitbox = false    -- Aumentar alcance
}

-- [[ 1. CRIAÇÃO DA UI (A CAIXINHA SEGURA) ]] --
local ScreenName = "OmniKillerUI"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 300) -- Pequena e compacta
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
Title.Text = "👹 OMNI-KILLER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18

-- Função para criar Botões de Switch
local function CreateSwitch(text, configKey, yPos)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    
    -- Arredondar bordas
    local uiCorner = Instance.new("UICorner", btn)
    uiCorner.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        -- Inverte o valor
        getgenv().Configs[configKey] = not getgenv().Configs[configKey]
        
        -- Atualiza visual
        if getgenv().Configs[configKey] then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Verde
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Cinza
            btn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

CreateSwitch("🧲 PUXAR MOBS", "MobMagnet", 60)
CreateSwitch("⚔️ 50x ATAQUE (No CD)", "NoCooldown", 110)
CreateSwitch("🎯 HITBOX GIGANTE", "BigHitbox", 160)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0, 30)
CloseBtn.Position = UDim2.new(0, 0, 1, -30)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.Text = "FECHAR GUI"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- [[ 2. LÓGICA DO SCRIPT ]] --

-- Loop Rápido (Roda a cada frame do jogo)
RunService.RenderStepped:Connect(function()
    
    local MyChar = LocalPlayer.Character
    if not MyChar or not MyChar:FindFirstChild("HumanoidRootPart") then return end

    -- Lógica 1: PUXAR MOBS (MAGNET)
    if getgenv().Configs.MobMagnet then
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Procura Humanoids que não sejam você
                if obj:IsA("Humanoid") and obj.Parent ~= MyChar then
                    local mobRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
                    if mobRoot and obj.Health > 0 then
                        -- Traz o mob para 3 studs na sua frente
                        mobRoot.CFrame = MyChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
                        -- Quebra a física deles pra eles não te empurrarem
                        mobRoot.CanCollide = false
                        mobRoot.Velocity = Vector3.new(0,0,0) 
                    end
                end
            end
        end)
    end

    -- Lógica 2: REMOVER COOLDOWN (Baseado no Log)
    if getgenv().Configs.NoCooldown then
        pcall(function()
            -- O log mostrou: Workspace.Characters.SEUNOME.States.UsingSkill
            -- Se acharmos isso, destruímos na hora.
            local StatesFolder = MyChar:FindFirstChild("States")
            if StatesFolder then
                local SkillState = StatesFolder:FindFirstChild("UsingSkill")
                if SkillState then
                    SkillState:Destroy() -- Puf! O jogo acha que você já parou de atacar
                end
            end
        end)
    end

    -- Lógica 3: HITBOXES (Para acertar fácil)
    if getgenv().Configs.BigHitbox then
        pcall(function()
             -- Procura por objetos de Hitbox (vimos 'KnifeLocker' e 'Hitbox' no log)
             for _, v in pairs(Workspace:GetDescendants()) do
                if (v.Name == "Hitbox" or v.Name == "KnifeLocker") and v:IsA("BasePart") then
                    v.Size = Vector3.new(30, 30, 30) -- Gigante
                    v.Transparency = 0.8 -- Invisível pra não poluir a tela
                    v.CanCollide = false
                end
            end
        end)
    end
end)