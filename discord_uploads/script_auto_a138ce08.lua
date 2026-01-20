--[[
    SIMPLE TOOLS v1 (Delta Mobile)
    - TP Johnny
    - Magneto Geral (Puxa tudo)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SimpleFarm = true
local FarmEnabled = false

-- // GUI SETUP SIMPLES //
if CoreGui:FindFirstChild("SimpleTools") then CoreGui.SimpleTools:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleTools"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 180) -- Pequeno e compacto
Frame.Position = UDim2.new(0.1, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
Frame.BorderSizePixel = 2
Frame.Active = true
Frame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "FARM SIMPLES"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

-- Botão TP JOHNNY
local BtnTP = Instance.new("TextButton", Frame)
BtnTP.Size = UDim2.new(0.9, 0, 0, 50)
BtnTP.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnTP.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
BtnTP.Text = "IR NO JOHNNY"
BtnTP.TextColor3 = Color3.WHITE
BtnTP.Font = Enum.Font.GothamBold

-- Botão PUXAR MOBS
local BtnFarm = Instance.new("TextButton", Frame)
BtnFarm.Size = UDim2.new(0.9, 0, 0, 50)
BtnFarm.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnFarm.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
BtnFarm.Text = "PUXAR MOBS: OFF"
BtnFarm.TextColor3 = Color3.WHITE
BtnFarm.Font = Enum.Font.GothamBold

-- Botão Fechar (X)
local Close = Instance.new("TextButton", Frame)
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -30, 0, 0)
Close.Text = "X"
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.TextColor3 = Color3.WHITE

-- // FUNÇÃO TP JOHNNY //
BtnTP.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local found = false
    -- Procura o Johnny no mapa todo
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "Johnny" and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            -- Teleporta 3 passos na frente dele
            char.HumanoidRootPart.CFrame = v.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            -- Vira de frente pra ele
            char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, v.HumanoidRootPart.Position)
            found = true
            break
        end
    end
    
    if not found then
        BtnTP.Text = "JOHNNY NÃO ACHADO!"
        task.wait(1)
        BtnTP.Text = "IR NO JOHNNY"
    end
end)

-- // FUNÇÃO MAGNETO (PUXAR TUDO) //
BtnFarm.MouseButton1Click:Connect(function()
    FarmEnabled = not FarmEnabled
    if FarmEnabled then
        BtnFarm.Text = "PUXAR MOBS: ON"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        BtnFarm.Text = "PUXAR MOBS: OFF"
        BtnFarm.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Loop que puxa os bichos
RunService.Heartbeat:Connect(function()
    if not getgenv().SimpleFarm or not FarmEnabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myPos = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) -- 5 studs na frente
    
    -- Varre o Workspace procurando qualquer pasta de monstros
    local mobFolder = Workspace
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name:match("BadEntities") or child.Name:match("Entities") or child.Name:match("Mobs") then
            mobFolder = child
            break
        end
    end
    
    -- Puxa todos
    for _, mob in pairs(mobFolder:GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
            if mob.Humanoid.Health > 0 then
                -- Traz o bicho
                mob.HumanoidRootPart.CFrame = myPos
                mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0) -- Tira a velocidade pra não te empurrar
                mob.HumanoidRootPart.CanCollide = false -- Fantasma
            end
        end
    end
end)

Close.MouseButton1Click:Connect(function()
    getgenv().SimpleFarm = false
    ScreenGui:Destroy()
end)