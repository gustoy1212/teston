-- [[ SOLO LEVELING: GHOST LOOTER V8 ]] --
-- Coleta itens do chão simulando toque (TouchInterest) e Teleporte

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 260, 0, 180)
Frame.Position = UDim2.new(0.5, -130, 0.55, 0)
Frame.BackgroundColor3 = Color3.fromRGB(15, 20, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 215, 0)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "👻 GHOST LOOTER V8"
Title.Size = UDim2.new(1, 0, 0.25, 0)
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
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
local CollectRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("CollectItem")
local LootEnabled = false

-- LISTA DE NOMES (Para identificar drops)
local LootNames = {
    "Gold", "Coin", "Moeda", "Drop", "Loot", "Item", "Box", "Bau", "Recompensa", "Soul", "Sombra"
}

-- [[ FUNÇÃO MÁGICA: SIMULAR TOQUE ]] --
local function SimulateTouch(part)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Método 1: FireTouchInterest (Melhor método, invisível)
    if firetouchinterest then
        firetouchinterest(root, part, 0) -- Toca
        firetouchinterest(root, part, 1) -- Solta
    else
        -- Método 2: Teleporte Rápido (Fallback)
        -- Move o player até lá e volta muito rápido
        local oldPos = root.CFrame
        root.CFrame = part.CFrame
        task.wait() -- Espera um frame pro jogo registrar
        root.CFrame = oldPos
    end
end

-- [[ LOOP DE COLETA ]] --
local function StartLooting()
    spawn(function()
        while LootEnabled do
            local foundCount = 0
            
            -- Varre o Workspace procurando drops
            for _, obj in pairs(Workspace:GetDescendants()) do
                if not LootEnabled then break end
                
                -- Verifica se é uma peça física
                if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
                    
                    local isLoot = false
                    
                    -- Critério A: Tem TouchInterest? (Quase todo drop tem)
                    if obj:FindFirstChild("TouchInterest") then
                        isLoot = true
                    end
                    
                    -- Critério B: Nome suspeito
                    if not isLoot then
                        for _, name in pairs(LootNames) do
                            if obj.Name:find(name) or (obj.Parent and obj.Parent.Name:find(name)) then
                                isLoot = true
                                break
                            end
                        end
                    end

                    -- SE FOR DROP, PEGA!
                    if isLoot then
                        foundCount = foundCount + 1
                        
                        -- 1. Simula Toque Físico
                        SimulateTouch(obj)
                        
                        -- 2. Dispara Remote (Tentativa de Bypass)
                        if CollectRemote then
                            pcall(function() CollectRemote:FireServer(obj) end)
                            pcall(function() CollectRemote:FireServer(obj.Parent) end)
                        end
                        
                        -- 3. Se tiver ProximityPrompt (Botão E), ativa também
                        if obj:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(obj.ProximityPrompt)
                        end
                    end
                end
            end
            
            if foundCount > 0 then
                Status.Text = "Coletando: " .. foundCount .. " itens..."
            else
                Status.Text = "Procurando drops..."
            end
            
            task.wait(0.5) -- Verifica 2x por segundo
        end
    end)
end

-- [[ BOTÃO ]] --
local BtnLoot = Instance.new("TextButton", Frame)
BtnLoot.Size = UDim2.new(0.9, 0, 0.4, 0)
BtnLoot.Position = UDim2.new(0.05, 0, 0.35, 0)
BtnLoot.Text = "LIGAR GHOST LOOT ($$$)"
BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnLoot.TextColor3 = Color3.new(1,1,1)
BtnLoot.Font = Enum.Font.GothamBold

BtnLoot.MouseButton1Click:Connect(function()
    LootEnabled = not LootEnabled
    if LootEnabled then
        BtnLoot.Text = "COLETANDO TUDO..."
        BtnLoot.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
        StartLooting()
    else
        BtnLoot.Text = "LIGAR GHOST LOOT ($$$)"
        BtnLoot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Status.Text = "Parado"
    end
end)