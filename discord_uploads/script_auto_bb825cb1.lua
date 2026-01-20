--[[
    🧙‍♂️ RPG MAGNET GOD v45 (FINAL FIX)
    
    VISUAL: Idêntico ao v39 (Cinza/Verde, pequeno, simples).
    LÓGICA: 
    - Busca em 'Workspace.Mobs'
    - Lê vida pelo Atributo 'HP' (já que não tem Humanoid)
    - Usa 'PivotTo' e 'Unanchor' para forçar o movimento.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,       -- Distância na sua frente
    HitboxSize = 5,       -- Tamanho da Hitbox
}

local OriginalSizes = {}

-- // GUI SETUP (VISUAL CLÁSSICO v39 - SEM TELA PRETA) //
if CoreGui:FindFirstChild("RPGMagnetFinal") then CoreGui.RPGMagnetFinal:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RPGMagnetFinal"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Painel Pequeno e Centralizado
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 140)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0) -- Bem no meio superior
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25) -- Cinza Escuro (Visível)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Borda Verde Neon
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧲 MAGNETO v45 (FIX)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- Botão Fechar
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold

-- Status
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

-- Contador
local CountLbl = Instance.new("TextLabel", MainFrame)
CountLbl.Size = UDim2.new(1, 0, 0, 20)
CountLbl.Position = UDim2.new(0, 0, 0.45, 0)
CountLbl.Text = "Alvos na mira: 0"
CountLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
CountLbl.BackgroundTransparency = 1

-- Botão Ligar
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50) -- Verde Escuro
ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES LÓGICAS //

local function GetMobsFolder()
    -- Prioridade: Workspace.Mobs (Visto no seu print)
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    if Workspace:FindFirstChild("BadEntities") then return Workspace.BadEntities end
    if Workspace:FindFirstChild("Entities") then return Workspace.Entities end
    return nil
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        -- Restaura colisões
        for _, p in pairs(mob:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true p.Anchored = false end
        end
    end
    OriginalSizes[mob] = nil
end

local function RestoreAll()
    for mob, _ in pairs(OriginalSizes) do RestoreMob(mob) end
    OriginalSizes = {}
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().MagnetRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

local isRunning = false
ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "Status: 🔥 FORÇA BRUTA ATIVA"
    else
        ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
        CountLbl.Text = "Alvos na mira: 0"
    end
end)

-- // LOOP ULTRA RÁPIDO (RENDERSTEPPED) //
RunService.RenderStepped:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    -- Destino: 5 studs na frente do player
    local targetCF = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then 
        Status.Text = "Erro: Pasta MOBS não achada!"
        return 
    end
    
    local count = 0
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            
            -- 1. CHECAGEM DE VIDA (CUSTOMIZADA PARA SEU JOGO)
            -- O jogo usa Atributo HP, não Humanoid.Health
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            
            -- Se tiver HP e for <= 0, tá morto. Se não tiver atributo HP, assume vivo por enquanto.
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            -- 2. CHECAGEM DE CORPO
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                -- Backup pra restaurar depois
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- 3. APLICAÇÃO DE FORÇA (DESANCORAR TUDO)
                for _, part in pairs(mob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Anchored = false -- O segredo pra soltar o bicho
                        part.Velocity = Vector3.zero 
                    end
                end
                
                -- Hitbox
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                root.Transparency = 0.6
                
                -- 4. MOVIMENTO (PIVOT - Mais forte que CFrame)
                if mob.PrimaryPart then
                    mob:PivotTo(targetCF)
                else
                    root.CFrame = targetCF
                end
                
                count = count + 1
            else
                -- Limpeza se morreu
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    CountLbl.Text = "Alvos puxados: " .. count
end)