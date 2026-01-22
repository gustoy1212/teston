-- [[ 👑 OMNI-LEGACY V6: TARGET SELECTOR ]] --
-- Adicionado: Sistema de Abas e Lista de Seleção de Mobs (Whitelist)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES GLOBAIS //
getgenv().OmniConfig = {
    Running = true,
    
    -- Magneto
    MagnetMode = "OFF",     -- "OFF", "SINGLE", "MASS"
    TargetMode = "ALL",     -- "ALL" (Puxa tudo), "SELECT" (Puxa só os marcados)
    SelectedMobs = {},      -- Lista de nomes permitidos
    
    HitboxSize = 60,
    MagnetDist = 5,
    
    -- Combate
    DPS_Mode = false,     
    AnimSpeed = 50,
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
local FoundMobNames = {} -- Cache de nomes encontrados

-- // UI SETUP (ESTILO PROFISSIONAL) //
local ScreenName = "OmniLegacyV6"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 450)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200) -- Ciano Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 35)
Title.Text = "💠 OMNI-LEGACY V6"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.BorderSizePixel = 0

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().OmniConfig.Running = false end)

-- // SISTEMA DE ABAS //
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, 0, 0, 30)
TabContainer.Position = UDim2.new(0, 0, 0.08, 0)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TabContainer.BorderSizePixel = 0

local Page1 = Instance.new("ScrollingFrame", MainFrame) -- Home
local Page2 = Instance.new("ScrollingFrame", MainFrame) -- Alvos

local function SetupPage(page)
    page.Size = UDim2.new(1, 0, 0.82, 0)
    page.Position = UDim2.new(0, 0, 0.16, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return page
end

SetupPage(Page1)
SetupPage(Page2)
Page1.Visible = true -- Começa na Home

local function SwitchTab(btn, pageToShow)
    -- Reset cores dos botões
    for _, v in pairs(TabContainer:GetChildren()) do
        if v:IsA("TextButton") then
            v.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            v.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    -- Ativa o atual
    btn.BackgroundColor3 = Color3.fromRGB(0, 150, 120)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    Page1.Visible = false
    Page2.Visible = false
    pageToShow.Visible = true
end

local Tab1Btn = Instance.new("TextButton", TabContainer)
Tab1Btn.Size = UDim2.new(0.5, 0, 1, 0)
Tab1Btn.Text = "🏠 CONTROLES"
Tab1Btn.Font = Enum.Font.GothamBold
Tab1Btn.MouseButton1Click:Connect(function() SwitchTab(Tab1Btn, Page1) end)

local Tab2Btn = Instance.new("TextButton", TabContainer)
Tab2Btn.Size = UDim2.new(0.5, 0, 1, 0)
Tab2Btn.Position = UDim2.new(0.5, 0, 0, 0)
Tab2Btn.Text = "🎯 SELECIONAR ALVOS"
Tab2Btn.Font = Enum.Font.GothamBold
Tab2Btn.MouseButton1Click:Connect(function() SwitchTab(Tab2Btn, Page2) end)

-- Inicializa Tab 1 ativa
SwitchTab(Tab1Btn, Page1)


-- // CONTEÚDO DA PAGINA 1 (CONTROLES) //

local function CreateToggle(parent, text, colorOn, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local isOn, newVal = callback()
        if isOn then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = colorOn
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            if newVal then btn.Text = newVal end -- Texto customizado opcional
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    return btn
end

-- 1. Botão Magneto
CreateToggle(Page1, "🧲 MAGNETO", Color3.fromRGB(0, 150, 255), function()
    if getgenv().OmniConfig.MagnetMode == "OFF" then
        getgenv().OmniConfig.MagnetMode = "SINGLE"
        return true, "🧲 MAGNETO: [1v1]"
    elseif getgenv().OmniConfig.MagnetMode == "SINGLE" then
        getgenv().OmniConfig.MagnetMode = "MASS"
        return true, "🧲 MAGNETO: [BURACO NEGRO]"
    else
        getgenv().OmniConfig.MagnetMode = "OFF"
        -- Limpa
        for mob, _ in pairs(OriginalSizes) do
            if mob and mob:FindFirstChild("HumanoidRootPart") then
                mob.HumanoidRootPart.Size = OriginalSizes[mob]
                mob.HumanoidRootPart.Transparency = 0
            end
        end
        OriginalSizes = {}
        return false
    end
end)

-- 2. Modo de Alvo (IMPORTANTE)
CreateToggle(Page1, "🎯 MODO ALVO", Color3.fromRGB(255, 150, 0), function()
    if getgenv().OmniConfig.TargetMode == "ALL" then
        getgenv().OmniConfig.TargetMode = "SELECT"
        return true, "🎯 MODO: [SÓ MARCADOS]"
    else
        getgenv().OmniConfig.TargetMode = "ALL"
        return false -- Volta para OFF (que visualmente será "ALL")
    end
end).Text = "🎯 MODO: [PEGAR TUDO]" -- Texto inicial

-- 3. DPS God
CreateToggle(Page1, "⚔️ DPS GOD (NO CD)", Color3.fromRGB(200, 50, 50), function()
    getgenv().OmniConfig.DPS_Mode = not getgenv().OmniConfig.DPS_Mode
    return getgenv().OmniConfig.DPS_Mode
end)

-- 4. Auto Click
CreateToggle(Page1, "🤖 AUTO CLICK", Color3.fromRGB(0, 150, 100), function()
    getgenv().OmniConfig.AutoClick = not getgenv().OmniConfig.AutoClick
    return getgenv().OmniConfig.AutoClick
end)

-- 5. Loot Vacuum
CreateToggle(Page1, "🧹 LOOT VACUUM", Color3.fromRGB(255, 100, 0), function()
    getgenv().OmniConfig.LootVacuum = not getgenv().OmniConfig.LootVacuum
    return getgenv().OmniConfig.LootVacuum
end)

-- 6. Extras
CreateToggle(Page1, "📦 AUTO BAÚ", Color3.fromRGB(0, 200, 0), function()
    getgenv().OmniConfig.AutoChest = not getgenv().OmniConfig.AutoChest
    return getgenv().OmniConfig.AutoChest
end)

CreateToggle(Page1, "🛡️ ANTI-STUN/KB", Color3.fromRGB(100, 100, 255), function()
    getgenv().OmniConfig.GodBody = not getgenv().OmniConfig.GodBody
    return getgenv().OmniConfig.GodBody
end)


-- // CONTEÚDO DA PAGINA 2 (LISTA DE MOBS) //

local RefreshBtn = Instance.new("TextButton", Page2)
RefreshBtn.Size = UDim2.new(0.95, 0, 0, 35)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
RefreshBtn.Text = "🔄 ESCANEAR MOBS (Atualizar Lista)"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local MobListContainer = Instance.new("Frame", Page2)
MobListContainer.Size = UDim2.new(1, 0, 1, -40) -- Resto do espaço
MobListContainer.BackgroundTransparency = 1
local MobListLayout = Instance.new("UIListLayout", MobListContainer)
MobListLayout.Padding = UDim.new(0, 2)

-- Função para atualizar a lista
local function RefreshMobList()
    -- Limpa lista visual antiga (menos o botão de refresh)
    for _, child in pairs(Page2:GetChildren()) do
        if child.Name == "MobButton" then child:Destroy() end
    end
    
    local CurrentNames = {}
    
    -- Escaneia Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent ~= LocalPlayer.Character and obj.Health > 0 then
            local name = obj.Parent.Name
            if not CurrentNames[name] then
                CurrentNames[name] = true
            end
        end
    end
    
    -- Cria botões para cada nome único
    for name, _ in pairs(CurrentNames) do
        local btn = Instance.new("TextButton", Page2)
        btn.Name = "MobButton"
        btn.Size = UDim2.new(0.9, 0, 0, 30)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        -- Verifica estado atual
        if getgenv().OmniConfig.SelectedMobs[name] then
            btn.Text = "✅ " .. name
            btn.BackgroundColor3 = Color3.fromRGB(20, 100, 20)
            btn.TextColor3 = Color3.fromRGB(150, 255, 150)
        else
            btn.Text = "❌ " .. name
            btn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
            btn.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        -- Função de Clicar
        btn.MouseButton1Click:Connect(function()
            if getgenv().OmniConfig.SelectedMobs[name] then
                -- Desmarcar
                getgenv().OmniConfig.SelectedMobs[name] = nil
                btn.Text = "❌ " .. name
                btn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
                btn.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                -- Marcar
                getgenv().OmniConfig.SelectedMobs[name] = true
                btn.Text = "✅ " .. name
                btn.BackgroundColor3 = Color3.fromRGB(20, 100, 20)
                btn.TextColor3 = Color3.fromRGB(150, 255, 150)
            end
        end)
    end
end

RefreshBtn.MouseButton1Click:Connect(RefreshMobList)


-- // LÓGICA DE EXECUÇÃO //

local function IsTargetValid(mob)
    if getgenv().OmniConfig.TargetMode == "ALL" then
        return true -- Pega tudo
    else
        -- Pega só o que está na tabela SelectedMobs
        if getgenv().OmniConfig.SelectedMobs[mob.Name] then
            return true
        end
    end
    return false
end

-- Função de Modificar o Mob (Hitbox)
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

-- LOOP DO MAGNETO
task.spawn(function()
    while true do
        task.wait(0.1) -- Rápido, mas não trava
        if not getgenv().OmniConfig.Running then break end
        
        if getgenv().OmniConfig.MagnetMode == "MASS" then
             local MyChar = LocalPlayer.Character
             if MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
                local PullPos = MyChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -getgenv().OmniConfig.MagnetDist)
                
                -- Escaneia o mapa
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent ~= MyChar and obj.Health > 0 then
                        local mob = obj.Parent
                        local r = mob:FindFirstChild("HumanoidRootPart")
                        
                        -- APLICA A VALIDAÇÃO DO ALVO AQUI
                        if r and IsTargetValid(mob) then
                             ModifyMob(mob)
                             r.CFrame = PullPos
                             r.Velocity = Vector3.new(0,0,0)
                             r.RotVelocity = Vector3.new(0,0,0)
                        end
                    end
                end
             end
        end
    end
end)

-- LOOP DO 1v1 E VISUAIS
RunService.Heartbeat:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")

    -- Lógica 1v1
    if getgenv().OmniConfig.MagnetMode == "SINGLE" and MyRoot then
        local closest, dist = nil, 50000
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Parent ~= MyChar and obj.Health > 0 then
                local mob = obj.Parent
                -- VALIDAÇÃO
                if IsTargetValid(mob) then
                    local r = mob:FindFirstChild("HumanoidRootPart")
                    if r then
                        local mag = (r.Position - MyRoot.Position).Magnitude
                        if mag < dist then
                            dist = mag
                            closest = mob
                        end
                    end
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

-- LOOP DE ATAQUE (RENDERSTEPPED)
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