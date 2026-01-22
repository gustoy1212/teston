-- [[ SOLO LEVELING: NECROMANCER (AUTO ARISE) ]] --
-- Clica em "Erga-se" e "Extrair" automaticamente no mapa todo

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 280, 0, 180)
Frame.Position = UDim2.new(0.5, -140, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(50, 0, 200) -- Roxo Necromante
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🔮 NECROMANCER (AUTO ARISE)"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(150, 50, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- REMOTES (Baseado no seu Log)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UnlockHero = Remotes:FindFirstChild("UnlockHero") -- [Source: 201] (Provável "Erga-se")
local ExtractUpdate = Remotes:FindFirstChild("ExtractUpdate") -- [Source: 182] (Provável "Destruir")

-- CONFIG
local AriseEnabled = false
local DestroyEnabled = false

-- [[ FUNÇÃO 1: CLICAR NOS BOTÕES (GUI) ]] --
local function ClickGuiButtons(targetText)
    -- Procura em todo o Workspace por botões flutuantes (BillboardGui)
    for _, desc in pairs(Workspace:GetDescendants()) do
        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
            -- Verifica se o botão está visível
            if desc.Visible then
                -- Verifica o texto (se tiver) ou nome
                local text = ""
                if desc:IsA("TextButton") then text = desc.Text:lower() end
                local name = desc.Name:lower()
                
                -- Se bater com o que queremos (Erga-se ou Destruir)
                if text:find(targetText) or name:find(targetText) then
                    -- Tenta clicar via Signal (Funciona de longe)
                    for _, connection in pairs(getconnections(desc.MouseButton1Click)) do
                        connection:Fire()
                    end
                    -- Fallback: Tenta ativar direto
                    pcall(function() desc.MouseButton1Click:Fire() end)
                end
            end
        end
    end
end

-- [[ FUNÇÃO 2: DISPARAR REMOTE (TÉCNICA) ]] --
local function SpamRemotes(actionType)
    local EnemyFolder = Workspace:FindFirstChild("Enemys")
    if not EnemyFolder then return end

    for _, enemy in pairs(EnemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChild("Humanoid")
        -- Se o bicho morreu (Vida 0)
        if hum and hum.Health <= 0 then
            
            if actionType == "arise" and UnlockHero then
                -- Tenta disparar o Erga-se (UnlockHero)
                pcall(function() UnlockHero:FireServer(enemy) end) -- Envia o Modelo
                pcall(function() UnlockHero:InvokeServer(enemy) end)
            
            elseif actionType == "destroy" and ExtractUpdate then
                -- Tenta disparar o Destruir (Extract)
                pcall(function() ExtractUpdate:FireServer(enemy) end)
            end
        end
    end
end

-- [[ LOOP PRINCIPAL ]] --
spawn(function()
    while true do
        if AriseEnabled then
            -- Procura botões "Erga-se" ou "Arise"
            ClickGuiButtons("erga") 
            ClickGuiButtons("arise")
            -- Tenta via Remote
            SpamRemotes("arise")
        end
        
        if DestroyEnabled then
            -- Procura botões "Destruir" ou "Extract"
            ClickGuiButtons("destruir")
            ClickGuiButtons("extract")
            -- Tenta via Remote
            SpamRemotes("destroy")
        end
        
        task.wait(0.5) -- Verifica a cada meio segundo
    end
end)

-- [[ BOTÕES DA UI ]] --
local BtnArise = Instance.new("TextButton", Frame)
BtnArise.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnArise.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnArise.Text = "AUTO ERGA-SE (SOMBRAS)"
BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnArise.TextColor3 = Color3.new(1,1,1)
BtnArise.Font = Enum.Font.GothamBold

BtnArise.MouseButton1Click:Connect(function()
    AriseEnabled = not AriseEnabled
    if AriseEnabled then
        BtnArise.Text = "INVOCANDO SOMBRAS..."
        BtnArise.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
    else
        BtnArise.Text = "AUTO ERGA-SE (SOMBRAS)"
        BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local BtnDestroy = Instance.new("TextButton", Frame)
BtnDestroy.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnDestroy.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnDestroy.Text = "AUTO DESTRUIR (MOEDAS)"
BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnDestroy.TextColor3 = Color3.new(1,1,1)
BtnDestroy.Font = Enum.Font.GothamBold

BtnDestroy.MouseButton1Click:Connect(function()
    DestroyEnabled = not DestroyEnabled
    if DestroyEnabled then
        BtnDestroy.Text = "COLETANDO MOEDAS..."
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    else
        BtnDestroy.Text = "AUTO DESTRUIR (MOEDAS)"
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)