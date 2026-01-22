-- [[ SOLO LEVELING: DUNGEON VACUUM V3 ]] --
-- Tenta trazer os mobs até você para farmar parado

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Mob Vacuum")
local Folder = Window:CreateFolder("Aspirador")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    Vacuum = false,       -- Puxar mobs
    Hitbox = false,       -- Aumentar tamanho (Hitbox)
    AutoAttack = false,   -- Bater sozinho
    Distancia = 5,        -- Distância que eles ficam de você
    VacuumForce = true    -- Tenta quebrar a física deles
}

-- FUNÇÃO 1: É Jogador? (Proteção)
local function IsRealPlayer(model)
    if Players:GetPlayerFromCharacter(model) then return true end
    return false
end

-- FUNÇÃO 2: Puxar Mobs (Vacuum)
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if Config.Vacuum and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = LocalPlayer.Character.HumanoidRootPart.CFrame
            
            for _, obj in pairs(Workspace:GetDescendants()) do
                -- Verifica se é Mob Inimigo
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if obj.Name ~= LocalPlayer.Name and not IsRealPlayer(obj) and obj.Humanoid.Health > 0 then
                        
                        -- Ignora Sombras aliadas se precisar (opcional)
                        if not (obj.Name:lower():find("shadow") or obj.Name:lower():find("igris")) then
                            
                            local mobRoot = obj.HumanoidRootPart
                            
                            -- MAGIA: Traz o bicho pra sua frente
                            -- Define a posição deles como: Sua Posição + 5 passos pra frente
                            if Config.VacuumForce then
                                -- Modo Agressivo: Tenta dominar a física
                                mobRoot.CanCollide = false -- Deixa eles "fantasmas" pra não te empurrar
                                mobRoot.CFrame = myPos * CFrame.new(0, 0, -Config.Distancia)
                                mobRoot.Velocity = Vector3.new(0,0,0) -- Tenta parar eles
                            else
                                -- Modo Suave (Tween - visual)
                                mobRoot.CFrame = myPos * CFrame.new(0, 0, -Config.Distancia)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- FUNÇÃO 3: Hitbox Expander (Cabeça Gigante)
-- Isso ajuda a bater neles mesmo se o Vacuum estiver falhando
task.spawn(function()
    while task.wait(1) do
        if Config.Hitbox then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    if obj.Name ~= LocalPlayer.Name and not IsRealPlayer(obj) then
                        -- Aumenta a HumanoidRootPart para 15x15x15
                        obj.HumanoidRootPart.Size = Vector3.new(15, 15, 15)
                        obj.HumanoidRootPart.Transparency = 0.7 -- Meio transparente pra vc ver
                        obj.HumanoidRootPart.Color = Color3.fromRGB(255, 0, 0)
                        obj.HumanoidRootPart.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- FUNÇÃO 4: Auto Attack (Bate na frente)
task.spawn(function()
    while task.wait() do
        if Config.AutoAttack then
            -- Clica o tempo todo
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(900, 500))
        end
    end
end)

-- GUI
Folder:Toggle("🧲 MOB VACUUM (Puxar)", function(bool)
    Config.Vacuum = bool
    -- Trava seu boneco no chão pra não ser empurrado pelos mobs
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = bool
    end
end)

Folder:Toggle("🟥 HITBOX GIGANTE", function(bool)
    Config.Hitbox = bool
end)

Folder:Toggle("⚔️ AUTO CLICK", function(bool)
    Config.AutoAttack = bool
end)

Folder:Slider("Distância (Perto/Longe)", 2, 20, 5, function(v)
    Config.Distancia = v
end)

Folder:Label("DICA: Se os mobs voltarem, ative a Hitbox!")