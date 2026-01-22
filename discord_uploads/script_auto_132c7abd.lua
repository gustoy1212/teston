-- [[ 👑 OMNI-LEGACY V7: TARGET LIST FIX ]] --
-- Correção da UI de Seleção de Mobs + Scanner Otimizado

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // CONFIGURAÇÕES GLOBAIS //
getgenv().OmniConfig = {
    Running = true,
    MagnetMode = "OFF",     -- "OFF", "SINGLE", "MASS"
    TargetMode = "ALL",     -- "ALL" (Tudo), "SELECT" (Lista)
    SelectedMobs = {},      -- Lista de nomes permitidos
    HitboxSize = 60,
    MagnetDist = 5,
    DPS_Mode = false,     
    AnimSpeed = 50,
    DeleteStates = true,
    AutoClick = false,
    LootVacuum = false,
    AutoChest = false,
    GodBody = false
}

local OriginalSizes = {} 

-- // UI SETUP //
local ScreenName = "OmniLegacyV7"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 480)
MainFrame.Position = UDim2.new(0.5, -200, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja V7
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Cabeçalho
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Text = "🛠️ OMNI-LEGACY V7 (LIST FIX)"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Title.BorderSizePixel = 0

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().OmniConfig.Running = false end)

-- ABAS
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0.09, 0)
TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TabContainer.BorderSizePixel = 0

local Page1 = Instance.new("Frame", MainFrame) -- Home
local Page2 = Instance.new("Frame", MainFrame) -- Alvos

local function SetupPage(page)
    page.Size = UDim2.new(1, 0, 0.82, 0)
    page.Position = UDim2.new(0, 0, 0.18, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
end
SetupPage(Page1)
SetupPage(Page2)
Page1.Visible = true

local function SwitchTab(btn, pageToShow)
    for _, v in pairs(TabContainer:GetChildren()) do
        if v:IsA("TextButton") then
            v.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            v.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    btn.TextColor3 = Color3.fromRGB(20, 20, 20)
    Page1.Visible = false
    Page2.Visible = false
    pageToShow.Visible = true
end

local Tab1Btn = Instance.new("TextButton", TabContainer)
Tab1Btn.Size = UDim2.new(0.5, 0, 1, 0)
Tab1Btn.Text = "🏠 HOME"
Tab1Btn.Font = Enum.Font.GothamBold
Tab1Btn.MouseButton1Click:Connect(function() SwitchTab(Tab1Btn, Page1) end)

local Tab2Btn = Instance.new("TextButton", TabContainer)
Tab2Btn.Size = UDim2.new(0.5, 0, 1, 0)
Tab2Btn.Position = UDim2.new(0.5, 0, 0, 0)
Tab2Btn.Text = "🎯 LISTA DE MOBS"
Tab2Btn.Font = Enum.Font.GothamBold
Tab2Btn.MouseButton1Click:Connect(function() SwitchTab(Tab2Btn, Page2) end)
SwitchTab(Tab1Btn, Page1) -- Inicia na Home

-- [[ CONTEÚDO PÁGINA 1: CONTROLES ]] --
local Scroll1 = Instance.new("ScrollingFrame", Page1)
Scroll1.Size = UDim2.new(0.9, 0, 0.95, 0)
Scroll1.Position = UDim2.new(0.05, 0, 0.02, 0)
Scroll1.BackgroundTransparency = 1
Scroll1.BorderSizePixel = 0
Scroll1.AutomaticCanvasSize = Enum.AutomaticSize.Y -- FIX CRÍTICO
Scroll1.CanvasSize = UDim2.new(0,0,0,0)

local List1 = Instance.new("UIListLayout", Scroll1)
List1.Padding = UDim.new(0, 6)
List1.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function CreateToggle(text, colorOn, callback)
    local btn = Instance.new("TextButton", Scroll1)
    btn.Size = UDim2.new(1, 0, 0, 40)
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
            if newVal then btn.Text = newVal end
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    return btn
end

-- Botões Home
CreateToggle("🧲 MAGNETO", Color3.fromRGB(0, 150, 255), function()
    if getgenv().OmniConfig.MagnetMode == "OFF" then
        getgenv().OmniConfig.MagnetMode = "SINGLE"
        return true, "🧲 MAGNETO: [1v1]"
    elseif getgenv().OmniConfig.MagnetMode == "SINGLE" then
        getgenv().OmniConfig.MagnetMode = "MASS"
        return true, "🧲 MAGNETO: [BURACO NEGRO]"
    else
        getgenv().OmniConfig.MagnetMode = "OFF"
        -- Restore
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

local ModeBtn = CreateToggle("🎯 MODO", Color3.fromRGB(255, 150, 0), function()
    if getgenv().OmniConfig.TargetMode == "ALL" then
        getgenv().OmniConfig.TargetMode = "SELECT"
        return true, "🎯 MODO: [SÓ DA LISTA]"
    else
        getgenv().OmniConfig.TargetMode = "ALL"
        return false 
    end
end)
ModeBtn.Text = "🎯 MODO: [PEGAR TUDO]"

CreateToggle("⚔️ DPS GOD", Color3.fromRGB(200, 50, 50), function()
    getgenv().OmniConfig.DPS_Mode = not getgenv().OmniConfig.DPS_Mode
    return getgenv().OmniConfig.DPS_Mode
end)

CreateToggle("🧹 LOOT VACUUM", Color3.fromRGB(255, 100, 0), function()
    getgenv().OmniConfig.LootVacuum = not getgenv().OmniConfig.LootVacuum
    return getgenv().OmniConfig.LootVacuum
end)

CreateToggle("📦 AUTO BAÚ", Color3.fromRGB(0, 200, 0), function()
    getgenv().OmniConfig.AutoChest = not getgenv().OmniConfig.AutoChest
    return getgenv().OmniConfig.AutoChest
end)

-- [[ CONTEÚDO PÁGINA 2: LISTA FIX ]] --

local ScanBtn = Instance.new("TextButton", Page2)
ScanBtn.Size = UDim2.new(0.9, 0, 0, 40)
ScanBtn.Position = UDim2.new(0.05, 0, 0.02, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 150)
ScanBtn.Text = "🔄 ATUALIZAR LISTA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local StatusLbl = Instance.new("TextLabel", Page2)
StatusLbl.Size = UDim2.new(1, 0, 0, 20)
StatusLbl.Position = UDim2.new(0, 0, 0.12, 0)
StatusLbl.Text = "Aguardando scan..."
StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLbl.BackgroundTransparency = 1

local Scroll2 = Instance.new("ScrollingFrame", Page2)
Scroll2.Size = UDim2.new(0.9, 0, 0.75, 0) -- Espaço para a lista
Scroll2.Position = UDim2.new(0.05, 0, 0.20, 0)
Scroll2.BackgroundTransparency = 0.5
Scroll2.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Scroll2.BorderSizePixel = 0
Scroll2.AutomaticCanvasSize = Enum.AutomaticSize.Y -- O FIX ESTÁ AQUI
Scroll2.ScrollBarThickness = 6

local List2 = Instance.new("UIListLayout", Scroll2)
List2.Padding = UDim.new(0, 4)
List2.SortOrder = Enum.SortOrder.Name

-- Lógica de Scan Otimizada
ScanBtn.MouseButton1Click:Connect(function()
    -- Limpa lista visual
    for _, child in pairs(Scroll2:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    StatusLbl.Text = "Escaneando..."
    local FoundNames = {}
    local Count = 0
    
    -- Função Helper: Adiciona se for novo
    local function AddIfNew(model)
        if model and model.Name and not FoundNames[model.Name] then
            FoundNames[model.Name] = true
            Count = Count + 1
            
            local btn = Instance.new("TextButton", Scroll2)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Name = model.Name -- Para ordenação
            
            -- Estado Inicial
            if getgenv().OmniConfig.SelectedMobs[model.Name] then
                btn.Text = "✅ " .. model.Name
                btn.BackgroundColor3 = Color3.fromRGB(20, 100, 20)
            else
                btn.Text = "❌ " .. model.Name
                btn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
            end
            
            -- Click
            btn.MouseButton1Click:Connect(function()
                if getgenv().OmniConfig.SelectedMobs[model.Name] then
                    getgenv().OmniConfig.SelectedMobs[model.Name] = nil
                    btn.Text = "❌ " .. model.Name
                    btn.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
                else
                    getgenv().OmniConfig.SelectedMobs[model.Name] = true
                    btn.Text = "✅ " .. model.Name
                    btn.BackgroundColor3 = Color3.fromRGB(20, 100, 20)
                end
            end)
        end
    end

    -- 1. Scan Rápido (Pastas Conhecidas)
    local folders = {"Mobs", "Entities", "BadEntities", "Dungeon", "Enemies", "NPCs"}
    for _, fName in pairs(folders) do
        local folder = Workspace:FindFirstChild(fName, true) -- Busca Recursiva
        if folder then
            for _, child in pairs(folder:GetChildren()) do
                if child:FindFirstChild("Humanoid") then
                    AddIfNew(child)
                end
            end
        end
    end
    
    -- 2. Scan Geral (Se achou pouco, varre tudo)
    if Count < 5 then
        StatusLbl.Text = "Scan profundo..."
        for _, obj in pairs(Workspace:GetDescendants()) do
             if obj:IsA("Humanoid") and obj.Parent ~= LocalPlayer.Character then
                 AddIfNew(obj.Parent)
             end
        end
    end
    
    StatusLbl.Text = "Encontrados: " .. Count .. " tipos de Mobs."
end)


-- // SISTEMA LÓGICO (MANTIDO E MELHORADO) //

local function IsTargetValid(mob)
    if getgenv().OmniConfig.TargetMode == "ALL" then return true end
    if getgenv().OmniConfig.SelectedMobs[mob.Name] then return true end
    return false
end

local function ModifyMob(mob)
    if not mob then return end
    local r = mob:FindFirstChild("HumanoidRootPart")
    if not r then return end
    if not OriginalSizes[mob] then OriginalSizes[mob] = r.Size end
    
    r.Size = Vector3.new(getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize, getgenv().OmniConfig.HitboxSize)
    r.Transparency = 0.7
    r.CanCollide = false
    r.Massless = true
end

-- LOOP MAGNETO
task.spawn(function()
    while true do
        task.wait(0.1)
        if not getgenv().OmniConfig.Running then break end
        
        if getgenv().OmniConfig.MagnetMode == "MASS" then
            local Char = LocalPlayer.Character
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                local PullPos = Char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -getgenv().OmniConfig.MagnetDist)
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent ~= Char and obj.Health > 0 then
                        local mob = obj.Parent
                        if IsTargetValid(mob) then
                            ModifyMob(mob)
                            local r = mob:FindFirstChild("HumanoidRootPart")
                            if r then
                                r.CFrame = PullPos
                                r.Velocity = Vector3.new(0,0,0)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- LOOP SECUNDÁRIO (1v1, Loot, Etc)
RunService.Heartbeat:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")

    -- 1v1
    if getgenv().OmniConfig.MagnetMode == "SINGLE" and Root then
        local closest, dist = nil, 50000
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Parent ~= Char and obj.Health > 0 then
                local mob = obj.Parent
                if IsTargetValid(mob) then
                    local r = mob:FindFirstChild("HumanoidRootPart")
                    if r then
                        local mag = (r.Position - Root.Position).Magnitude
                        if mag < dist then
                            dist = mag
                            closest = mob
                        end
                    end
                end
            end
        end
        if closest then
            ModifyMob(closest)
            closest.HumanoidRootPart.CFrame = Root.CFrame * CFrame.new(0,0,-getgenv().OmniConfig.MagnetDist)
        end
    end

    -- Loot
    if getgenv().OmniConfig.LootVacuum and Root then
        pcall(function()
             for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Tool") and v:FindFirstChild("Handle") then
                    v.Handle.CFrame = Root.CFrame
                elseif (v.Name:lower():find("drop") or v.Name:lower():find("coin")) and v:IsA("BasePart") then
                    v.CFrame = Root.CFrame
                end
             end
        end)
    end
    
    -- Auto Chest
    if getgenv().OmniConfig.AutoChest then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and (v.Parent.Name:lower():find("chest") or v.Parent.Name:lower():find("bau")) then
                fireproximityprompt(v)
            end
        end
    end
end)

-- LOOP DE ATAQUE
RunService.RenderStepped:Connect(function()
    if not getgenv().OmniConfig.Running then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    
    if getgenv().OmniConfig.DPS_Mode or getgenv().OmniConfig.GodBody then
        pcall(function()
            local s = Char:FindFirstChild("States")
            if s then
                if getgenv().OmniConfig.DPS_Mode and s:FindFirstChild("UsingSkill") then s.UsingSkill:Destroy() end
                if getgenv().OmniConfig.GodBody then
                    if s:FindFirstChild("Stunned") then s.Stunned:Destroy() end
                    if s:FindFirstChild("Knockback") then s.Knockback:Destroy() end
                end
            end
        end)
        
        if getgenv().OmniConfig.DPS_Mode then
            local h = Char:FindFirstChild("Humanoid")
            if h then 
                local anim = h:FindFirstChildOfClass("Animator")
                if anim then for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:AdjustSpeed(getgenv().OmniConfig.AnimSpeed) end end
            end
        end
    end
    
    if getgenv().OmniConfig.AutoClick then
        local t = Char:FindFirstChildOfClass("Tool")
        if t then t.Enabled=true t:Activate() end
    end
end)