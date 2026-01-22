-- [[ SOLO LEVELING: OMNI-LOOT V12 (INSTANT OPENER) ]] --
-- Abre baús instantaneamente via Remote (sem precisar andar).

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Loot V12")
local Folder = Window:CreateFolder("Baús Remotos")

-- Serviços
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Configurações
local Config = {
    AutoOpen = true,      -- Abre sozinho assim que spawna
    AutoCollect = true,   -- Puxa os itens pro chão
    Notify = true         -- Avisa na tela
}

-- Mapeamento dos Remotes (Baseado no seu Log Blackbox)
local BossDropsService = ReplicatedStorage:WaitForChild("RemoteServices"):WaitForChild("BossDropsService")
local ChestRemote = nil

-- Tenta achar o Remote de abrir (Pode variar o nome ou caminho)
-- No log apareceu apenas "OpenChest", vamos procurar onde ele fica
local function FindOpenRemote()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "OpenChest" then
            return v
        end
    end
    -- Fallback: Tenta no BossDropsService se não achar solto
    if BossDropsService:FindFirstChild("RE") and BossDropsService.RE:FindFirstChild("OpenChest") then
        return BossDropsService.RE.OpenChest
    end
    return nil
end

ChestRemote = FindOpenRemote()

-- FUNÇÃO 1: ESCUTAR SPAWN DE BAÚS
if BossDropsService and BossDropsService:FindFirstChild("RE") and BossDropsService.RE:FindFirstChild("SpawnChest") then
    BossDropsService.RE.SpawnChest.OnClientEvent:Connect(function(...)
        if Config.AutoOpen then
            local args = {...}
            -- O Log mostrou que os args são: 
            -- 1=Dono, 2=Posição, 3=ChestID, 4=Tipo...
            
            local chestID = args[3] -- O ID único é crucial
            local chestType = args[4]
            
            if chestID then
                if Config.Notify then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "BAÚ DETECTADO!";
                        Text = "Tipo: " .. tostring(chestType);
                        Duration = 3;
                    })
                end
                
                -- TENTATIVA 1: Abrir Remotamente (God Mode)
                if ChestRemote then
                    -- Envia o comando de abrir direto pro servidor
                    -- Geralmente precisa passar o ID do baú ou o Modelo
                    ChestRemote:FireServer(chestID) 
                    ChestRemote:FireServer(args[1]) -- Tenta mandar o dono tbm
                    
                    print("🔓 Tentativa de abrir remoto: " .. tostring(chestID))
                end
                
                -- TENTATIVA 2: Teleporte + Prompt (Garantia)
                -- Caso o remoto tenha proteção de distância
                task.spawn(function()
                    task.wait(0.2) -- Espera o modelo carregar no Workspace
                    
                    -- Procura o modelo do baú pelo ID (geralmente fica no nome ou atributo)
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name == "Chest" or obj.Name == tostring(chestType)) then
                            -- Verifica se é o baú certo (pela posição ou ID)
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                -- TP para garantir
                                if Players.LocalPlayer.Character then
                                    Players.LocalPlayer.Character.HumanoidRootPart.CFrame = obj.PrimaryPart.CFrame
                                end
                                task.wait(0.1)
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end)
            end
        end
    end)
else
    game.StarterGui:SetCore("SendNotification", {Title="ERRO", Text="Remote SpawnChest não encontrado!"})
end

-- FUNÇÃO 2: AUTO COLLECT (Puxar Drops)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoCollect then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                     drop.Handle.CFrame = Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("🔓 Auto Abrir Baú (Instant)", function(bool)
    Config.AutoOpen = bool
end)

Folder:Toggle("🧲 Auto Puxar Drops", function(bool)
    Config.AutoCollect = bool
end)

Folder:Label("Status: Monitorando Rede...")
if ChestRemote then
    Folder:Label("✅ Remote de Abrir: DETECTADO")
else
    Folder:Label("⚠️ Remote de Abrir: NÃO ACHEI (Usando Prompt)")
end