-- [[ SOLO LEVELING: LOOT VACUUM V7 ]] --
-- Puxa moedas/drops e coleta via Remote

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 160)
Frame.Position = UDim2.new(0.5, -130, 0.5, 0) -- Mais para baixo
Frame.BackgroundColor3 = Color3.fromRGB(15, 20, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "💰 VÁCUO DE MOEDAS V7"
Title.Size = UDim2.new(1, 0, 0.25, 0)
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", Frame)
Status.Text = "Status: Aguardando..."
Status.Position = UDim2.new(0,0,0.8,0)
Status.Size = UDim2.new(1,0,0,20)
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- CONFIG
local CollectRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("CollectItem")
local LootEnabled = false

-- LISTA DE NOMES COMUNS DE DROPS
-- Se o nome do item tiver isso, ele puxa
local LootNames = {
    "Gold", "Coin", "Moeda", "Drop", "Loot", "Item", "Box", "Bau", "Recompensa"
}

-- [[ FUNÇÃO: PUXAR E COLETAR ]] --
local function VacuumLoot()
    spawn(function()
        while LootEnabled do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local myPos = char.HumanoidRootPart.CFrame
                
                -- Varre o Workspace procurando itens soltos
                for _, obj in pairs(Workspace:GetDescendants()) do
                    
                    -- Verifica se é um item válido (Parte Física solta)
                    if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
                        
                        -- Filtro 1: Tem Handle ou TouchInterest? (Geralmente drops têm)
                        local isDrop = obj:FindFirstChild("TouchInterest") or obj.Name == "Handle"
                        
                        -- Filtro 2: Verifica o nome
                        for _, name in pairs(LootNames) do
                            if obj.Name:find(name) or (obj.Parent and obj.Parent.Name:find(name)) then
                                isDrop = true
                                break
                            end
                        end
                        
                        if isDrop then
                            -- AÇÃO 1: TELEPORTE FÍSICO (VÁCUO)
                            obj.CFrame = myPos
                            obj.CanCollide = false
                            obj.Transparency = 0.5 -- Visual
                            
                            -- AÇÃO 2: DISPARO DE REMOTE (GARANTIA)
                            if CollectRemote then
                                -- Tenta enviar o objeto ou o modelo pai
                                pcall(function() CollectRemote:InvokeServer(obj) end)
                                pcall(function() CollectRemote:InvokeServer(obj.Parent) end)
                                pcall(function() CollectRemote:FireServer(obj) end)
                            end
                        end
                    end
                end
            end
            task.wait(0.2) -- Puxa 5 vezes por segundo
        end
    end)
end

-- [[ BOTÃO ]] --
local BtnLoot = Instance.new("TextButton", Frame)
BtnLoot.Size = UDim2.new(0.9, 0, 0.4, 0)
BtnLoot.Position = UDim2.new(0.05, 0, 0.35, 0)
BtnLoot.Text = "LIGAR ASPIRADOR ($$$)"
BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnLoot.TextColor3 = Color3.new(1,1,1)
BtnLoot.Font = Enum.Font.GothamBold

BtnLoot.MouseButton1Click:Connect(function()
    LootEnabled = not LootEnabled
    if LootEnabled then
        BtnLoot.Text = "💰 ASPIRANDO TUDO..."
        BtnLoot.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        VacuumLoot()
        Status.Text = "Puxando itens do chão..."
    else
        BtnLoot.Text = "LIGAR ASPIRADOR ($$$)"
        BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Status.Text = "Parado"
    end
end)