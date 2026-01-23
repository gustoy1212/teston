--[[
    BLOX FRUITS - AUTO FARM V1 (SAFE MODE)
    Foco: Puxar Mobs + Auto Quest + Auto Attack
    Nota: Fique na mesma ilha dos mobs para evitar que eles resetem.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

getgenv().BloxFram = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    BringRange = 300,       -- Puxa mobs num raio de 300 studs
    AutoClickDelay = 0.2,   -- Velocidade do clique
    QuestMode = true,       -- Pegar missão automaticamente
}

-- // TABELA DE MISSÕES (EXEMPLO SEA 1) //
-- Adicionei as primeiras para teste. O sistema verifica seu nível.
local QuestDatabase = {
    {Level = 0,   Name = "BanditQuest1",  Mob = "Bandit",     ID = 1},
    {Level = 10,  Name = "JungleQuest",   Mob = "Monkey",     ID = 1},
    {Level = 15,  Name = "JungleQuest",   Mob = "Gorilla",    ID = 2},
    {Level = 30,  Name = "BuggyQuest1",   Mob = "Pirate",     ID = 1},
    {Level = 40,  Name = "BuggyQuest1",   Mob = "Brute",      ID = 2},
    {Level = 60,  Name = "DesertQuest",   Mob = "Desert Bandit", ID = 1},
    {Level = 75,  Name = "DesertQuest",   Mob = "Desert Officer", ID = 2},
}

-- // GUI NATIVA //
if CoreGui:FindFirstChild("BloxFruitFarmUI") then CoreGui.BloxFruitFarmUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "BloxFruitFarmUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 15, 30) -- Azul Escuro Blox
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🏴‍☠️ BLOX FARM V1"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size = UDim2.new(1, 0, 0, 25)
StatusLbl.Position = UDim2.new(0, 0, 0.2, 0)
StatusLbl.Text = "Status: Parado"
StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLbl.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ToggleBtn.Text = "LIGAR FARM"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE

-- // VARIÁVEIS //
local IsFarming = false
local CurrentMobName = "Bandit" -- Padrão

-- // FUNÇÕES LÓGICAS //

-- 1. Identificar Missão Ideal
function GetCurrentQuest()
    local myLevel = LocalPlayer.Data.Level.Value
    local bestQuest = nil
    
    for _, q in ipairs(QuestDatabase) do
        if myLevel >= q.Level then
            bestQuest = q
        end
    end
    return bestQuest
end

-- 2. Pegar Missão (CommF_)
function TakeQuest(questData)
    -- Verifica se já tem missão ativa (A interface do player mostra isso, mas vamos tentar pegar igual)
    -- Args: "StartQuest", "NomeDaQuest", ID (1 ou 2)
    pcall(function()
        CommF:InvokeServer("StartQuest", questData.Name, questData.ID)
    end)
end

-- 3. Equipar Arma (Qualquer uma)
function EquipWeapon()
    if not LocalPlayer.Character then return end
    if not LocalPlayer.Character:FindFirstChildOfClass("Tool") then
        local bp = LocalPlayer.Backpack:GetChildren()
        for _, tool in pairs(bp) do
            if tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool.ToolTip == "Blox Fruit" then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end

-- 4. Ataque (Simula Clique)
function AutoClick()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(800,600))
end

-- // UI LÓGICA //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BloxFram = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsFarming = not IsFarming
    if IsFarming then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        ToggleBtn.Text = "LIGAR FARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        StatusLbl.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().BloxFram do
        task.wait()
        
        if IsFarming and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local MyRoot = LocalPlayer.Character.HumanoidRootPart
            
            -- A. GERENCIAR MISSÃO
            if SETTINGS.QuestMode then
                local quest = GetCurrentQuest()
                if quest then
                    CurrentMobName = quest.Mob
                    StatusLbl.Text = "Alvo: " .. CurrentMobName
                    
                    -- Tenta pegar a missão a cada 5 segundos (para não spammar o server)
                    if tick() % 5 < 0.1 then
                        TakeQuest(quest)
                    end
                end
            end
            
            -- B. EQUIPAR E ATACAR
            EquipWeapon()
            AutoClick()
            
            -- C. BRING MOBS (LÓGICA BLOX FRUITS)
            -- Mobs ficam em Workspace.Enemies
            local enemies = Workspace:FindFirstChild("Enemies")
            if enemies then
                for _, mob in pairs(enemies:GetChildren()) do
                    -- Verifica se é o mob certo e se está vivo
                    if mob.Name == CurrentMobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                        
                        local mobRoot = mob.HumanoidRootPart
                        local dist = (MyRoot.Position - mobRoot.Position).Magnitude
                        
                        -- Se estiver perto o suficiente (dentro da mesma ilha/área)
                        if dist < SETTINGS.BringRange then
                            -- Traz para frente do player
                            mobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -5)
                            
                            -- Tenta travar
                            mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                            mob.Humanoid.WalkSpeed = 0
                            
                            -- Hitbox Expandida (Para garantir o hit)
                            if mobRoot.Size.X < 5 then
                                mobRoot.Size = Vector3.new(5, 5, 5)
                                mobRoot.CanCollide = false
                                mobRoot.Transparency = 0.5
                            end
                        end
                    end
                end
            end
        end
    end
end)