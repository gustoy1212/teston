--[[
    🧙‍♂️ RPG MAGNET GOD v48 (TOUCH FIX)
    
    CORREÇÃO:
    - Evento 'Activated' (Funciona melhor no toque).
    - Botão com ZIndex alto (Prioridade de toque).
    - Lógica de Puxar mantida na pasta 'Mobs'.
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
if CoreGui:FindFirstChild("MagnetTouch") then CoreGui.MagnetTouch:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MagnetTouch"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- PAINEL PRINCIPAL
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true -- Tente arrastar pelas bordas, não pelo botão

-- LISTA AUTOMÁTICA
local Layout = Instance.new("UIListLayout", MainFrame)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧲 MAGNETO v48"
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

-- BOTÃO DE AÇÃO (PRIORIDADE DE TOQUE)
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ToggleBtn.Text = "LIGAR TUDO"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.LayoutOrder = 4
ToggleBtn.ZIndex = 10 -- Fica por cima de tudo pra garantir o clique
ToggleBtn.AutoButtonColor = true -- Pisca quando clica

-- BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.LayoutOrder = 5
CloseBtn.Size = UDim2.new(0.9, 0, 0, 30)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR (X)"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 10

-- // LÓGICA //

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

-- USANDO 'ACTIVATED' (Melhor pra celular)
CloseBtn.Activated:Connect(function()
    getgenv().MagnetRunning = false
    RestoreAll()
    ScreenGui:Destroy()
end)

local isRunning = false
ToggleBtn.Activated:Connect(function()
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
            -- Verifica Atributo HP (Sem Humanoid)
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                if not OriginalSizes[mob] then OriginalSizes[mob] = root.Size end
                
                -- Força Bruta
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