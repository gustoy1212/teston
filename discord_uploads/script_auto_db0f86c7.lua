-- [[ SOLO LEVELING: EXTERMINADOR (MOBILE) ]] --
-- Simples, Leve e Funcional. Sem frescuras.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIGURAÇÕES
local Settings = {
    Farm = false,
    Collect = false,
    Distancia = 5 -- Distância pra ficar do bicho
}

-- GUI SIMPLES (Pra não travar)
local Screen = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.new(0, 200, 0, 150)
Main.Position = UDim2.new(0.1, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.Active = true
Main.Draggable = true

local Title = Instance.new("TextLabel", Main)
Title.Text = "🗡️ EXTERMINADOR"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(50, 0, 0)

local Status = Instance.new("TextLabel", Main)
Status.Text = "Status: Parado"
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.85, 0)
Status.TextColor3 = Color3.fromRGB(255, 255, 0)
Status.BackgroundTransparency = 1

-- BOTÃO FARM
local BtnFarm = Instance.new("TextButton", Main)
BtnFarm.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnFarm.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnFarm.Text = "MATAR TUDO: OFF"
BtnFarm.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

BtnFarm.MouseButton1Click:Connect(function()
    Settings.Farm = not Settings.Farm
    BtnFarm.Text = Settings.Farm and "MATAR TUDO: ON" or "MATAR TUDO: OFF"
    BtnFarm.BackgroundColor3 = Settings.Farm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
end)

-- BOTÃO COLETAR
local BtnCollect = Instance.new("TextButton", Main)
BtnCollect.Size = UDim2.new(0.9, 0, 0.2, 0)
BtnCollect.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnCollect.Text = "PEGAR ITENS: OFF"
BtnCollect.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

BtnCollect.MouseButton1Click:Connect(function()
    Settings.Collect = not Settings.Collect
    BtnCollect.Text = Settings.Collect and "PEGAR ITENS: ON" or "PEGAR ITENS: OFF"
    BtnCollect.BackgroundColor3 = Settings.Collect and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(100, 100, 100)
end)

-- FUNÇÃO: NOCLIP (Atravessar Paredes)
RunService.Stepped:Connect(function()
    if Settings.Farm then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- FUNÇÃO: ACHAR INIMIGO
local function GetEnemy()
    local nearest = nil
    local dist = 9999
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            -- FILTROS DE SEGURANÇA
            if obj.Name ~= LocalPlayer.Name -- Não sou eu
            and obj.Humanoid.Health > 0 -- Tá vivo
            and not Players:GetPlayerFromCharacter(obj) -- NÃO É PLAYER (IMPORTANTE)
            then
                -- Filtro Anti-Pet (Opcional, se tiver pet chamado Shadow)
                if not (obj.Name:find("Shadow") or obj.Name:find("Igris")) then
                    local d = (LocalPlayer.Character.HumanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest
end

-- LOOP PRINCIPAL (Rápido e Sujo)
task.spawn(function()
    while task.wait() do
        if Settings.Farm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local enemy = GetEnemy()
            
            if enemy then
                Status.Text = "Alvo: " .. enemy.Name
                local root = LocalPlayer.Character.HumanoidRootPart
                local enemyRoot = enemy.HumanoidRootPart
                
                -- 1. TELEPORTE (Nas costas)
                local targetCFrame = enemyRoot.CFrame * CFrame.new(0, 0, Settings.Distancia)
                
                -- Usa CFrame direto (Mais rápido que Tween)
                root.CFrame = CFrame.new(targetCFrame.Position, enemyRoot.Position)
                
                -- 2. TIRA VELOCIDADE (Pra não cair)
                root.Velocity = Vector3.new(0,0,0)
                
                -- 3. BATE
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(900, 500))
                
                -- 4. ATAQUE EXTRA (Se tiver ferramenta)
                pcall(function()
                    LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):Activate()
                end)
            else
                Status.Text = "Procurando inimigos..."
            end
        end
    end
end)

-- LOOP COLETAR
task.spawn(function()
    while task.wait(0.5) do
        if Settings.Collect and LocalPlayer.Character then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Tool") or (v:IsA("Model") and v:FindFirstChild("Handle") and v.Name ~= LocalPlayer.Name) then
                    local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                    if handle then
                        v.Parent = LocalPlayer.Character -- Tenta equipar direto
                        handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame -- Ou teleporta
                    end
                end
            end
        end
    end
end)

-- LOOP DE BAÚS (Automático sempre ativo se achar prompt)
task.spawn(function()
    while task.wait(1) do
        if Settings.Farm then
            for _, p in pairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    fireproximityprompt(p)
                end
            end
        end
    end
end)