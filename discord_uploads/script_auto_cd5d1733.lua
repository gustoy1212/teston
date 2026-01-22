-- [[ SOLO LEVELING: ASTRAL GOD MODE V5 ]] --
-- Você fica parado assistindo, seu espírito mata tudo.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wall%20v3"))()
local Window = Library:CreateWindow("Astral God V5")
local Folder = Window:CreateFolder("Farm Fantasma")

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configurações
local Config = {
    AutoFarm = false,
    AutoCollect = false,
    AstralMode = false, -- O Segredo
    AttackDist = 5
}

-- Variáveis do Clone
local FakeCharacter = nil
local RealCharacter = nil

-- FUNÇÃO 1: CRIAR CLONE (PROJEÇÃO)
local function CreateClone()
    if FakeCharacter then FakeCharacter:Destroy() end
    
    RealCharacter = LocalPlayer.Character
    RealCharacter.Archivable = true
    
    -- Clona o boneco
    FakeCharacter = RealCharacter:Clone()
    FakeCharacter.Name = "AstralClone"
    FakeCharacter.Parent = Workspace
    
    -- Posiciona onde você estava
    local root = RealCharacter:FindFirstChild("HumanoidRootPart")
    if root then
        FakeCharacter:SetPrimaryPartCFrame(root.CFrame)
    end
    
    -- Trava a física do clone (pra não cair)
    for _, part in pairs(FakeCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            if part.Name == "HumanoidRootPart" then part.Transparency = 1 end
        end
    end
    
    -- Remove scripts do clone pra não dar erro
    for _, script in pairs(FakeCharacter:GetDescendants()) do
        if script:IsA("LocalScript") or script:IsA("Script") then script:Destroy() end
    end
end

-- FUNÇÃO 2: CONTROLAR VISUAL (INVISIBILIDADE)
local function ToggleAstral(bool)
    Config.AstralMode = bool
    
    if bool then
        -- 1. Cria o Clone
        CreateClone()
        
        -- 2. Trava a Câmera no Clone
        Camera.CameraSubject = FakeCharacter:FindFirstChild("Humanoid")
        
        -- 3. Deixa o Real Invisível (Client-Side)
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 1 -- Fica invisível
            elseif v:IsA("Decal") then
                v.Transparency = 1
            end
        end
        
    else
        -- Desliga tudo
        if FakeCharacter then FakeCharacter:Destroy() FakeCharacter = nil end
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        
        -- Volta a visibilidade
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0
            elseif v:IsA("Decal") then
                v.Transparency = 0
            end
        end
    end
end

-- FUNÇÃO 3: LÓGICA DE KILL (V4 OTIMIZADA)
local function IsValidTarget(model)
    if not model or not model:FindFirstChild("Humanoid") or not model:FindFirstChild("HumanoidRootPart") then return false end
    if model.Name == LocalPlayer.Name then return false end
    if model.Humanoid.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end -- Não mata player
    local n = model.Name:lower()
    if n:find("shadow") or n:find("igris") or n:find("tank") then return false end -- Não mata pet
    return true
end

-- LOOP DE FARM
task.spawn(function()
    while task.wait() do
        if Config.AutoFarm then
            pcall(function()
                -- Aumenta Hitbox da Arma (Reach)
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool.Handle.Size = Vector3.new(15, 15, 15)
                    tool.Handle.Massless = true
                end

                local closest = nil
                local distMin = 9999
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("Model") and IsValidTarget(v) then
                        local d = (myPos - v.HumanoidRootPart.Position).Magnitude
                        if d < distMin then
                            distMin = d
                            closest = v
                        end
                    end
                end
                
                if closest then
                    local realRoot = LocalPlayer.Character.HumanoidRootPart
                    local enemyRoot = closest.HumanoidRootPart
                    
                    -- TELEPORTE REAL (Vai lá matar)
                    realRoot.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, Config.AttackDist)
                    realRoot.CFrame = CFrame.new(realRoot.Position, enemyRoot.Position)
                    realRoot.Velocity = Vector3.new(0,0,0)
                    
                    -- ATAQUE
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(900, 500))
                elseif Config.AstralMode and FakeCharacter then
                    -- Se não tem inimigo, volta pro corpo do clone (descansar)
                    local fakeRoot = FakeCharacter:FindFirstChild("HumanoidRootPart")
                    if fakeRoot then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = fakeRoot.CFrame
                    end
                end
            end)
        end
    end
end)

-- AUTO COLLECT (Traz os itens pro Clone)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoCollect then
            local targetPos = LocalPlayer.Character.HumanoidRootPart.CFrame
            -- Se estiver no modo Astral, traz itens para onde a câmera está (o clone)
            if Config.AstralMode and FakeCharacter and FakeCharacter:FindFirstChild("HumanoidRootPart") then
                targetPos = FakeCharacter.HumanoidRootPart.CFrame
            end
            
            for _, drop in pairs(Workspace:GetDescendants()) do
                if (drop:IsA("Tool") or drop:IsA("Model")) and drop:FindFirstChild("Handle") then
                   local item = drop.Handle
                   item.CFrame = targetPos
                end
            end
        end
    end
end)

-- GUI
Folder:Toggle("👻 MODO ASTRAL (Ficar Parado)", function(bool)
    ToggleAstral(bool)
end)

Folder:Toggle("⚔️ AUTO KILL (Invisível)", function(bool)
    Config.AutoFarm = bool
end)

Folder:Toggle("🧲 PUXAR ITENS (Para o Clone)", function(bool)
    Config.AutoCollect = bool
end)

Folder:Label("1. Entre na Dungeon")
Folder:Label("2. Ative MODO ASTRAL")
Folder:Label("3. Ative AUTO KILL")
Folder:Label("Você verá seu clone parado enquanto tudo morre!")