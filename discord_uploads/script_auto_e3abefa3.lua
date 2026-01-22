-- [[ 👑 OMNI-KING V2: SMART & LITE ]] --
-- "Puxa só o que deve, mata sem travar."

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES AVANÇADAS //
getgenv().OmniSettings = {
    -- Magneto
    Magnet = false,
    MagnetRange = 3000, 
    MagnetSpeed = 0.1,    -- Delay entre puxadas (aumente se ainda lagar)
    
    -- Combate
    FastAttack = false,
    HitboxSize = 20,      -- Diminuí um pouco para evitar crash visual, mas ainda é grande
    DeleteStates = true,  -- Remove cooldown
    
    -- Otimização (Lag Fix)
    FreezePhysics = true, -- Ancora os mobs (ESSENCIAL PRA NÃO LAGAR)
    InvisibleMobs = false -- Deixa mobs invisíveis
}

-- LISTA NEGRA: Coloque aqui nomes de NPCs que não devem ser puxados
local SafeNameList = {
    "Quest Giver",
    "Shop",
    "Guide",
    "Merchant",
    "Velukov" -- Exemplo do seu log, se ele for amigo, mantenha aqui
}

-- // UI SETUP //
local ScreenName = "OmniKingV2"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
Title.Text = "👑 OMNI-KING V2 (NO LAG)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().OmniSettings.Magnet = false end)

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.8, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.15, 0)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)

-- Função Toggle
local function CreateToggle(text, configKey, colorOn)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        getgenv().OmniSettings[configKey] = not getgenv().OmniSettings[configKey]
        if getgenv().OmniSettings[configKey] then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = colorOn
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
end

CreateToggle("🧲 MAGNETO INTELIGENTE", "Magnet", Color3.fromRGB(0, 150, 255))
CreateToggle("❄️ CONGELAR FÍSICA (Anti-Lag)", "FreezePhysics", Color3.fromRGB(100, 100, 255))
CreateToggle("⚔️ ATAQUE RÁPIDO", "FastAttack", Color3.fromRGB(255, 50, 50))
CreateToggle("👻 MOBS INVISÍVEIS", "InvisibleMobs", Color3.fromRGB(100, 100, 100))

-- // LÓGICA INTELIGENTE //

local function IsSafeNPC(model)
    -- 1. Verifica Nome na Lista Negra
    for _, safeName in pairs(SafeNameList) do
        if model.Name:lower():find(safeName:lower()) then return true end
    end
    
    -- 2. Verifica se tem interação (NPCs de conversa)
    if model:FindFirstChild("ProximityPrompt", true) then return true end
    if model:FindFirstChild("Head") and model.Head:FindFirstChild("QuestIcon") then return true end
    
    -- 3. Verifica se é aliado (Opcional: Time)
    local hum = model:FindFirstChild("Humanoid")
    if hum and hum.MaxHealth > 10000000 then return true end -- NPCs imortais geralmente
    
    return false
end

-- Thread do Magneto (Rodando em Loop Controlado)
task.spawn(function()
    while true do
        task.wait(getgenv().OmniSettings.MagnetSpeed) -- Controle de velocidade pra não lagar
        
        if getgenv().OmniSettings.Magnet then
            pcall(function()
                local MyChar = LocalPlayer.Character
                if MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
                    local MyRoot = MyChar.HumanoidRootPart
                    local PullPos = MyRoot.CFrame * CFrame.new(0, 0, -4) -- 4 studs na frente

                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("Humanoid") and obj.Parent ~= MyChar and obj.Health > 0 then
                            local mobModel = obj.Parent
                            local mobRoot = mobModel:FindFirstChild("HumanoidRootPart")
                            
                            -- APLICA OS FILTROS
                            if mobRoot and not IsSafeNPC(mobModel) then
                                local dist = (mobRoot.Position - MyRoot.Position).Magnitude
                                if dist <= getgenv().OmniSettings.MagnetRange then
                                    
                                    -- 1. Teleporta
                                    mobRoot.CFrame = PullPos
                                    
                                    -- 2. ANTI-LAG (O Segredo)
                                    if getgenv().OmniSettings.FreezePhysics then
                                        -- Ancora o mob. Ele para de calcular física.
                                        -- Ele vira uma estátua, mas ainda toma dano.
                                        for _, part in pairs(mobModel:GetChildren()) do
                                            if part:IsA("BasePart") then
                                                part.Anchored = true
                                                part.CanCollide = false
                                            end
                                        end
                                    end
                                    
                                    -- 3. Hitbox
                                    mobRoot.Size = Vector3.new(getgenv().OmniSettings.HitboxSize, getgenv().OmniSettings.HitboxSize, getgenv().OmniSettings.HitboxSize)
                                    mobRoot.Transparency = 0.6
                                    mobRoot.Color = Color3.fromRGB(255, 0, 0)
                                    
                                    -- 4. Invisibilidade (FPS Boost extra)
                                    if getgenv().OmniSettings.InvisibleMobs then
                                        for _, part in pairs(mobModel:GetChildren()) do
                                            if part:IsA("BasePart") and part ~= mobRoot then
                                                part.Transparency = 1
                                            end
                                        end
                                    end
                                    
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Thread de Ataque (RenderStepped para velocidade máxima)
RunService.RenderStepped:Connect(function()
    if getgenv().OmniSettings.FastAttack then
        local Char = LocalPlayer.Character
        if Char then
            -- Remove Cooldown
            if getgenv().OmniSettings.DeleteStates then
                pcall(function()
                    local s = Char:FindFirstChild("States")
                    if s then 
                        if s:FindFirstChild("UsingSkill") then s.UsingSkill:Destroy() end
                    end
                end)
            end
            
            -- Ativa Tool
            local Tool = Char:FindFirstChildOfClass("Tool")
            if Tool then
                Tool.Enabled = true
                Tool:Activate()
            end
        end
    end
end)