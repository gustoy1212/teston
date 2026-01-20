--[[
    🧙‍♂️ RPG MAGNET GOD v47 (BUTTON FIX)
    
    CORREÇÃO VISUAL:
    - Usa 'UIListLayout' para empilhar os botões.
    - Garante que o botão de LIGAR apareça na tela.
    
    LÓGICA:
    - Puxa de 'Workspace.Mobs'.
    - Verifica atributo 'HP'.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    MagnetDist = 5,
    HitboxSize = 5,
}

local OriginalSizes = {}

-- // GUI SETUP //
if CoreGui:FindFirstChild("MagnetV47") then CoreGui.MagnetV47:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetV47"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- PAINEL PRINCIPAL
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 180) -- Altura maior pra caber tudo
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45) -- Cinza (Não Preto)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- ORGANIZADOR AUTOMÁTICO (O SEGREDO PRA NÃO SUMIR BOTÃO)
local Layout = Instance.new("UIListLayout", MainFrame)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧲 MAGNETO v47"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1
Title.LayoutOrder = 1

-- STATUS
local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.LayoutOrder = 2

-- CONTADOR
local CountLbl = Instance.new("TextLabel", MainFrame)
CountLbl.Size = UDim2.new(1, 0, 0, 25)
CountLbl.Text = "Mobs: 0"
CountLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
CountLbl.BackgroundTransparency = 1
CountLbl.LayoutOrder = 3

-- BOTÃO DE AÇÃO (GRANDE E VISÍVEL)
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 50) -- Botão Grande
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50) -- Verde Escuro
ToggleBtn.Text = "LIGAR TUDO"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.LayoutOrder = 4

-- BOTÃO FECHAR (Separado pra ficar no canto)
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0) -- Canto direito absoluto
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
-- Tira do Layout automático
CloseBtn.Parent = ScreenGui 
-- Gambiarra visual: Coloca um frame invisivel pai pra ele seguir o MainFrame ou deixa solto?
-- Melhor deixar dentro do MainFrame mas ignorar layout? Não dá facil.
-- Vou colocar ele dentro do MainFrame com position absoluta, mas o Layout pode empurrar.
-- SOLUÇÃO: Coloquei ele como filho do ScreenGui mas posicionado manualmente, 
-- ou melhor: Dentro do MainFrame mas com tamanho 0 na lista? 
-- Vamos simplificar: O botão X vai ser o ultimo da lista (LayoutOrder 5) vermelho.
CloseBtn.Parent = MainFrame
CloseBtn.LayoutOrder = 5
CloseBtn.Size = UDim2.new(0.9, 0, 0, 30)
CloseBtn.Text = "FECHAR SCRIPT (X)"

-- // LÓGICA TÉCNICA //

local function GetMobsFolder()
    -- Prioridade: Workspace.Mobs
    if Workspace:FindFirstChild("Mobs") then return Workspace.Mobs end
    if Workspace:FindFirstChild("BadEntities") then return Workspace.BadEntities end
    return nil
end

local function RestoreMob(mob)
    if not mob then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
    if root and OriginalSizes[mob] then
        root.Size = OriginalSizes[mob]
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
        Status.Text = "Status: ATIVO"
    else
        ToggleBtn.Text = "LIGAR TUDO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
        RestoreAll()
        Status.Text = "Status: Parado"
        CountLbl.Text = "Mobs: 0"
    end
end)

-- // LOOP RÁPIDO //
RunService.RenderStepped:Connect(function()
    if not getgenv().MagnetRunning then return end
    if not isRunning then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local targetCF = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.MagnetDist)
    
    local folder = GetMobsFolder()
    if not folder then Status.Text = "Sem pasta Mobs" return end
    
    local count = 0
    for _, mob in ipairs(folder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            -- VERIFICA VIDA (Atributo HP)
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- FORÇA BRUTA (Desancora e Pivota)
                for _, part in pairs(mob:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Anchored = false
                        part.Velocity = Vector3.zero
                    end
                end
                
                root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                root.Transparency = 0.5
                
                if mob.PrimaryPart then
                    mob:PivotTo(targetCF)
                else
                    root.CFrame = targetCF
                end
                count = count + 1
            else
                if OriginalSizes[mob] then RestoreMob(mob) end
            end
        end
    end
    CountLbl.Text = "Puxando: " .. count
end)