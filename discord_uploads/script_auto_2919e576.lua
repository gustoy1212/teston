--[[
    SCRIPT SBL REBORN - GUI NATIVA (COMPATÍVEL COM DELTA/MOBILE)
    Foco: Funcionar o clique e as automações
]]

-- CONFIGURAÇÕES INICIAIS
_G.Flags = {
    AutoFarm = false,     -- Começa desligado
    AutoStats = false,    -- Começa desligado
    AutoSkills = false,   -- Começa desligado
    AutoInteract = false, -- Começa desligado
    StatToUp = "Melee"    -- Qual status upar (Melee, Defense, Sword, Fruit)
}

-- SERVIÇOS
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- REMOTES (Baseado no seu Log)
local Remotes = {
    [cite_start]Hit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"), -- [cite: 8]
    [cite_start]Skill = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"), -- [cite: 3]
    [cite_start]Stats = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AllocateStat"), -- [cite: 14]
}

-- --- CRIAÇÃO DA INTERFACE (GUI) MANUALMENTE ---
-- Isso garante que funcione no Delta Mobile

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SBL_Mobile_GUI"
-- Tenta colocar no lugar seguro do executor, senão no CoreGui
if gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = CoreGui
end

-- Botão de Abrir/Fechar
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.8, 0, 0.1, 0) -- Canto superior direito
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "MENU"
ToggleBtn.BorderSizePixel = 0
ToggleBtn.TextScaled = true

-- Painel Principal (Fundo)
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 200, 0, 250)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -125) -- Centralizado
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Visible = false -- Começa escondido
MainFrame.Active = true
MainFrame.Draggable = true -- Dá pra arrastar

-- Título
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
Title.Text = "SBL Reborn"
Title.TextColor3 = Color3.WHITE
Title.TextScaled = true

-- Layout (Organizador de botões)
local UIList = Instance.new("UIListLayout")
UIList.Parent = MainFrame
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 5)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Espaço para o título não cobrir o primeiro botão
local Padding = Instance.new("UIPadding")
Padding.Parent = MainFrame
Padding.PaddingTop = UDim.new(0, 35)

-- FUNÇÃO PARA CRIAR BOTÕES
function CreateButton(text, flagName)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Vermelho (Desligado)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.WHITE
    btn.TextScaled = true
    
    btn.MouseButton1Click:Connect(function()
        _G.Flags[flagName] = not _G.Flags[flagName]
        if _G.Flags[flagName] then
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Verde (Ligado)
            btn.Text = text .. ": ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Vermelho
            btn.Text = text .. ": OFF"
        end
    end)
end

-- Criando os botões das funções
CreateButton("Auto Farm (Bring)", "AutoFarm")
CreateButton("Auto Skills (Z,X,C,V)", "AutoSkills")
CreateButton("Auto Stats (Melee)", "AutoStats")
CreateButton("Auto Interact/Quest", "AutoInteract")

-- Lógica do Botão Menu
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- --- LÓGICA DAS FUNÇÕES (O motor do script) ---

-- 1. AUTO FARM + BRING MOBS
task.spawn(function()
    while task.wait() do
        if _G.Flags.AutoFarm then
            local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if MyRoot then
                -- Tenta atacar sempre
                pcall(function() Remotes.Hit:FireServer() end)

                -- Traz os mobs
                for _, mob in pairs(Workspace.NPCs:GetChildren()) do
                    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                        local MobRoot = mob.HumanoidRootPart
                        local Dist = (MyRoot.Position - MobRoot.Position).Magnitude
                        
                        -- Se estiver num raio de 300 studs, traz pra perto
                        if Dist < 300 and Dist > 4 then
                            MobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -4) -- Traz pra frente
                            
                            -- Remove colisão pra não travar
                            for _, p in pairs(mob:GetChildren()) do
                                if p:IsA("BasePart") then p.CanCollide = false end
                            end
                            -- Tenta travar o movimento do mob
                            mob.Humanoid.WalkSpeed = 0
                            mob.Humanoid.PlatformStand = true
                        end
                    end
                end
            end
        end
    end
end)

-- 2. AUTO SKILLS
task.spawn(function()
    local keys = {"Z", "X", "C", "V"}
    while task.wait(0.5) do
        if _G.Flags.AutoSkills then
            for _, k in pairs(keys) do
                pcall(function() Remotes.Skill:FireServer(k) end)
            end
        end
    end
end)

-- 3. AUTO STATS
task.spawn(function()
    while task.wait(1) do
        if _G.Flags.AutoStats then
            pcall(function() Remotes.Stats:FireServer(_G.Flags.StatToUp, 1) end)
        end
    end
end)

-- 4. AUTO INTERACT (Portais, Quests, Baús)
task.spawn(function()
    while task.wait(1) do
        if _G.Flags.AutoInteract then
            for _, prompt in pairs(Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    -- Verifica se está perto o suficiente para interagir (ex: 20 studs)
                    if prompt.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - prompt.Parent.Position).Magnitude
                        if dist < 25 then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end
end)