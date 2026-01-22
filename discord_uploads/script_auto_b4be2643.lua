-- [[ SOLO LEVELING: TELEKINESIS LOOT V9 (NO TP) ]] --
-- Traz os itens até você. Você NÃO se mexe.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 150)
Frame.Position = UDim2.new(0.5, -130, 0.65, 0) -- Posição ajustada
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 100)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🛸 IMÃ DE ITENS (SEM TP)"
Title.Size = UDim2.new(1, 0, 0.25, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", Frame)
Status.Text = "Status: Parado"
Status.Position = UDim2.new(0,0,0.8,0)
Status.Size = UDim2.new(1,0,0,20)
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- CONFIG
local LootEnabled = false

-- LISTA DE NOMES (O que vamos puxar)
local LootNames = {
    "Gold", "Coin", "Moeda", "Drop", "Loot", "Item", "Box", "Bau", "Recompensa", "Soul", "Sombra"
}

-- [[ FUNÇÃO: TRAZER ITEM (TELEKINESIS) ]] --
local function BringLoot()
    -- Usamos Heartbeat para ser muito rápido e vencer o servidor
    RunService.Heartbeat:Connect(function()
        if not LootEnabled then return end
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Verifica se é um item válido (Parte Física)
                if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
                    
                    local isLoot = false
                    
                    -- Critério 1: Tem TouchInterest (Item coletável)
                    if obj:FindFirstChild("TouchInterest") then
                        isLoot = true
                    end
                    
                    -- Critério 2: Nome na lista
                    if not isLoot then
                        for _, name in pairs(LootNames) do
                            if obj.Name:find(name) or (obj.Parent and obj.Parent.Name:find(name)) then
                                isLoot = true
                                break
                            end
                        end
                    end

                    -- SE FOR DROP, TRAZ PARA O PÉ DO JOGADOR
                    if isLoot then
                        -- Remove colisão para não te empurrar
                        obj.CanCollide = false
                        obj.Transparency = 0.5 
                        
                        -- Puxa o item para sua posição (TELEKINESIS)
                        obj.CFrame = root.CFrame
                        obj.Velocity = Vector3.new(0,0,0) -- Para de cair/rolar
                    end
                end
            end
        end
    end)
end

-- [[ BOTÃO ]] --
local BtnLoot = Instance.new("TextButton", Frame)
BtnLoot.Size = UDim2.new(0.9, 0, 0.4, 0)
BtnLoot.Position = UDim2.new(0.05, 0, 0.35, 0)
BtnLoot.Text = "LIGAR IMÃ DE ITENS"
BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnLoot.TextColor3 = Color3.new(1,1,1)
BtnLoot.Font = Enum.Font.GothamBold

local ConexaoLoop = nil

BtnLoot.MouseButton1Click:Connect(function()
    LootEnabled = not LootEnabled
    if LootEnabled then
        BtnLoot.Text = "PUXANDO TUDO..."
        BtnLoot.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        Status.Text = "Itens vindo até você..."
        
        -- Inicia o loop apenas uma vez
        if not ConexaoLoop then
            BringLoot()
            ConexaoLoop = true 
        end
    else
        BtnLoot.Text = "LIGAR IMÃ DE ITENS"
        BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Status.Text = "Parado"
    end
end)