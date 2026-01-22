-- [[ SOLO LEVELING: OMNI-LOOT V13 (THIEF EDITION) ]] --
-- Tenta roubar baús de outros jogadores forçando a abertura.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Loot Thief V13")
local Folder = Window:CreateFolder("Roubo de Baús")

-- Serviços
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    StealMode = true,     -- Tenta abrir baú dos outros
    AutoCollect = true,   -- Puxa o item se cair
    TeleportToSteal = true -- Vai até o baú (chance maior de funcionar)
}

-- Mapeamento
local BossDropsService = ReplicatedStorage:WaitForChild("RemoteServices"):WaitForChild("BossDropsService")
local ChestRemote = nil

-- Procura o Remote de Abrir (Mesma lógica do V12 que funcionou)
local function FindOpenRemote()
    if BossDropsService:FindFirstChild("RE") and BossDropsService.RE:FindFirstChild("OpenChest") then
        return BossDropsService.RE.OpenChest
    end
    -- Fallback
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "OpenChest" then return v end
    end
    return nil
end

ChestRemote = FindOpenRemote()

-- FUNÇÃO: TENTAR ROUBAR
local function TrySteal(chestID, ownerName, chestType)
    if not Config.StealMode then return end
    
    local isMine = (ownerName == LocalPlayer.Name)
    local logPrefix = isMine and "✅ MEU BAÚ: " or "😈 ROUBANDO DE " .. tostring(ownerName) .. ": "
    
    print(logPrefix .. chestType)
    
    if Config.TeleportToSteal and not isMine then
        -- Se não for meu, teleporta lá pra garantir o "toque"
        -- Precisamos achar o modelo físico no Workspace pelo ID ou esperar nascer
        task.spawn(function()
            local attempts = 0
            while attempts < 20 do -- Tenta achar o baú por 2 segundos
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name == "Chest" or obj.Name == tostring(chestType)) then
                        -- Tenta ver se é o baú certo (Muitas vezes o ID está num Atributo)
                        -- Se não tiver como saber, vai no mais próximo
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and obj.PrimaryPart then
                                -- TP Rápido
                                local oldCF = root.CFrame
                                root.CFrame = obj.PrimaryPart.CFrame
                                task.wait(0.1)
                                fireproximityprompt(prompt) -- Tenta manual
                                
                                -- Se for roubo, fica um pouco mais pra garantir
                                if not isMine then task.wait(0.1) end
                                -- Opcional: Voltar (root.CFrame = oldCF)
                            end
                        end
                    end
                end
                attempts = attempts + 1
                task.wait(0.1)
            end
        end)
    end

    -- TENTATIVA VIA REMOTE (A mais importante)
    if ChestRemote then
        -- Manda o sinal repetidas vezes
        for i = 1, 5 do
            ChestRemote:FireServer(chestID) 
            -- Alguns jogos pedem o nome do dono original pra validar, vamos tentar enganar
            ChestRemote:FireServer(chestID, ownerName) 
            ChestRemote:FireServer(chestID, LocalPlayer.Name) -- Tenta fingir que é meu
        end
    end
end

-- MONITOR: ESCUTAR SPAWN
if BossDropsService and BossDropsService:FindFirstChild("RE") and BossDropsService.RE:FindFirstChild("SpawnChest") then
    BossDropsService.RE.SpawnChest.OnClientEvent:Connect(function(...)
        local args = {...}
        -- Args do seu log: 1=Dono, 3=ChestID, 4=Tipo
        local owner = args[1]
        local id = args[3]
        local type = args[4]
        
        if id then
            TrySteal(id, owner, type)
            
            -- Notificação Visual
            if owner ~= LocalPlayer.Name then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "ALVO DETECTADO";
                    Text = "Tentando roubar de: " .. tostring(owner);
                    Duration = 3;
                })
            end
        end
    end)
end

-- AUTO COLLECT (Puxar o que cair)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoCollect then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                     drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("😈 MODO LADRÃO (Steal)", function(bool)
    Config.StealMode = bool
end)

Folder:Toggle("🏃 Teleportar no Baú", function(bool)
    Config.TeleportToSteal = bool
end)

Folder:Label("Se funcionar, você verá itens")
Folder:Label("de outras pessoas voando pra você!")