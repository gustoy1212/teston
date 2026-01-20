--[[
    🧙‍♂️ RPG MAGNET GOD v46 (SAFE GUI)
    
    VISUAL:
    - Fundo Cinza (Não Preto) para não bugar no celular.
    - Transparência ativada.
    
    LÓGICA:
    - Lê pasta 'Workspace.Mobs'.
    - Lê Atributo 'HP' (Sem Humanoid).
    - Usa PivotTo (Força Bruta) para puxar.
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

-- // GUI SETUP (MODO SEGURO - SEM TELA PRETA) //
if CoreGui:FindFirstChild("MagnetSafe") then CoreGui.MagnetSafe:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetSafe"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- PAINEL CINZA (Não Preto)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 150)
MainFrame.Position = UDim2.new(0.5, -140, 0.2, 0) -- Meio
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50) -- CINZA CHUMBO (Pra não ficar preto)
MainFrame.BackgroundTransparency = 0.1 -- Levemente transparente
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100) -- Borda Verde
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧲 MAGNETO (SAFE MODE)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- BOTÃO FECHAR (X)
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold

-- STATUS (Texto Branco pra ler melhor)
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1

-- CONTADOR
local CountLbl = Instance.new("TextLabel", MainFrame)
CountLbl.Size = UDim2.new(1, 0, 0, 20)
CountLbl.Position = UDim2.new(0, 0, 0.4, 0)
CountLbl.Text = "Mobs na mira: 0"
CountLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
CountLbl.BackgroundTransparency = 1

-- BOTÃO DE AÇÃO
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

-- // LÓGICA TÉCNICA (Baseada no seu Print) //

local function GetMobsFolder()
    -- Prioridade Absoluta: Workspace.Mobs
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    -- Fallbacks
    if Workspace:FindFirstChild("BadEntities") then return Workspace.BadEntities end
    if Workspace:FindFirstChild("Entities") then return Workspace.Entities end
    return nil
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
        -- Restaura física
        for _, p in pairs(mob:GetDescendants()) do
            if p:IsA("BasePart") then 
                p.CanCollide = true 
                p.Anchored = false 
            end
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
        Status.Text = "Status: ☢️ FORÇA BRUTA"
    else
        ToggleBtn.Text = "LIGAR (PUXAR TUDO)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
        CountLbl.Text = "Mobs na mira: 0"
    end
end)

-- // LOOP DE FÍSICA (RENDERSTEPPED) //
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
        Status.Text = "Erro: Pasta 'Mobs' sumiu!"
        return 
    end
    
    local count = 0
    
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            
            -- 1. VERIFICA VIDA (ATRIBUTO HP)
            -- Como visto no print
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            -- 2. PEGA PARTE PRINCIPAL
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                -- Salva tamanho original
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- 3. FORÇA BRUTA (Desancora tudo)
                for _, part in pairs(mob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Anchored = false
                        part.Velocity = Vector3.zero
                        part.RotVelocity = Vector3.zero
                    end
                end
                
                -- Visual Hitbox
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                root.Transparency = 0.5
                
                -- 4. MOVE (PivotTo é mais forte que CFrame)
                if mob.PrimaryPart then
                    mob:PivotTo(targetCF)
                else
                    root.CFrame = targetCF
                end
                
                count = count + 1
            else
                -- Se morreu, solta
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    
    CountLbl.Text = "Puxando: " .. count
end)