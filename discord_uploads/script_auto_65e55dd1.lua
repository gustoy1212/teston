-- [[ SOLO LEVELING: DUNGEON SLAYER V7 ]] --
-- Correções: Distância do Boss, Auto-Equip (Tecla 1) e Anti-Morte

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Slayer V7")
local Folder = Window:CreateFolder("Combate")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Config = {
    AutoFarm = false,
    UseSkills = true,
    AutoCollect = false,
    DistanciaExtra = 3, -- Distância ALÉM do tamanho do bicho
    AutoEquip = true
}

-- FUNÇÃO: EQUIPAR ARMA (TECLA 1)
local function EquipWeapon()
    if not Config.AutoEquip then return end
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        -- Verifica se já tem arma na mão
        if not char:FindFirstChildWhichIsA("Tool") then
            
            -- Tenta apertar a tecla "1"
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            
            -- PLANO B: Equipa direto da mochila se a tecla falhar
            local tool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
            if tool then
                char.Humanoid:EquipTool(tool)
            end
        end
    end
end

-- FUNÇÃO: CALCULAR POSIÇÃO IDEAL (COLADO NO INIMIGO)
local function GetAttackPosition(enemyRoot)
    -- Pega o tamanho do inimigo (pra saber se é Boss gigante)
    local enemySize = enemyRoot.Size.Z / 2 
    -- A distância final é: Tamanho do Bicho + Distancia Configurada
    local finalDist = enemySize + Config.DistanciaExtra
    
    -- Retorna a posição ATRÁS do inimigo
    return enemyRoot.CFrame * CFrame.new(0, 0, finalDist)
end

-- FUNÇÃO: MOVIMENTO (TWEEN)
local function MoveTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    -- Trava a mira no inimigo
    local lookAt = CFrame.new(targetCFrame.Position, root.Position + root.CFrame.LookVector)
    
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    if dist > 50 then
        root.CFrame = targetCFrame -- TP se longe
    else
        -- Tween rápido pra não morrer
        local info = TweenInfo.new(dist / 45, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
        tween:Play()
    end
    
    -- Mantém a altura correta (não voa muito alto)
    root.Velocity = Vector3.new(0,0,0)
end

-- FUNÇÃO: ACHAR ALVO (PRIORIDADE BOSS)
local function GetTarget()
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    local bossFolder = Workspace:FindFirstChild("Boss") -- Alguns mapas tem pasta Boss
    local targets = {}
    
    -- Adiciona Mobs normais
    if mobsFolder then
        for _, m in pairs(mobsFolder:GetChildren()) do table.insert(targets, m) end
    end
    
    -- Adiciona Bosses (Prioridade)
    if bossFolder then
        for _, b in pairs(bossFolder:GetChildren()) do table.insert(targets, b) end
    end
    
    -- Procura soltos se não achar pastas
    if #targets == 0 then
        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) and v.Name ~= LocalPlayer.Name then
                table.insert(targets, v)
            end
        end
    end

    -- Escolhe o mais próximo
    local nearest = nil
    local minDist = 9999
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, e in pairs(targets) do
        if e:FindFirstChild("HumanoidRootPart") and e:FindFirstChild("Humanoid") and e.Humanoid.Health > 0 then
            local d = (e.HumanoidRootPart.Position - myPos).Magnitude
            if d < minDist then
                minDist = d
                nearest = e
            end
        end
    end
    return nearest
end

-- LOOP PRINCIPAL
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm and LocalPlayer.Character then
            -- 1. Verifica Arma
            EquipWeapon()
            
            -- 2. Busca Inimigo
            local enemy = GetTarget()
            
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local enemyRoot = enemy.HumanoidRootPart
                
                -- 3. Calcula onde ficar (Colado nas costas)
                local attackPos = GetAttackPosition(enemyRoot)
                
                -- 4. Move
                MoveTo(attackPos)
                
                -- 5. Vira pro inimigo
                root.CFrame = CFrame.new(root.Position, Vector3.new(enemyRoot.Position.X, root.Position.Y, enemyRoot.Position.Z))
                
                -- 6. Ataca
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(900, 500))
                
                -- 7. Skills (Spam agressivo)
                if Config.UseSkills then
                    local keys = {"E", "R", "F", "Q", "C", "V"}
                    for _, k in pairs(keys) do
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game)
                    end
                end
            end
        end
    end
end)

-- AUTO COLLECT (Mantido igual pq funciona)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoCollect then
            for _, drop in pairs(Workspace:GetDescendants()) do
                if drop:IsA("Tool") and drop:FindFirstChild("Handle") then
                     drop.Handle.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                elseif drop:IsA("ProximityPrompt") then
                    fireproximityprompt(drop)
                end
            end
        end
    end
end)

-- NOCLIP ETERNO (Pra não travar em parede)
RunService.Stepped:Connect(function()
    if Config.AutoFarm and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- GUI
Folder:Toggle("⚔️ Auto Farm V7", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("🔫 Auto Equipar (Tecla 1)", function(bool)
    Config.AutoEquip = bool
end)

Folder:Toggle("🔥 Usar Skills", function(bool)
    Config.UseSkills = bool
end)

Folder:Toggle("📦 Auto Collect", function(bool)
    Config.AutoCollect = bool
end)

Folder:Slider("Distância Extra", 0, 10, 3, function(v)
    Config.DistanciaExtra = v
end)

Folder:Label("DICA: Distância 3 é bom pra Boss!")