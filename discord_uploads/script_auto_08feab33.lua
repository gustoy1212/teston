--[[
    🐻 RPG MAGNET v2 - MOB EDITION
    
    ESTRUTURA DETECTADA:
    - Pasta: Workspace.Mobs
    - Componente: HumanoidRootPart
    
    SEGURANÇA:
    - Sem metatables (Anti-Kick 267).
    - No Collision nos monstros para não te travar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MobMagnetRunning = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Distance = 7,         -- Distância na sua frente
    Range = 3000,         -- Pega monstros do mapa todo
    HitboxSize = 5,       -- Tamanho da área de hit
}

local OriginalData = {} -- Backup para restaurar ao fechar

-- // GUI SETUP //
if CoreGui:FindFirstChild("MobMagnetGui") then CoreGui.MobMagnetGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MobMagnetGui"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🐻 MOB MAGNET v2"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
ToggleBtn.Text = "ATIVAR MAGNETO"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE LIMPEZA //
local function CleanUp()
    getgenv().MobMagnetRunning = false
    for mob, data in pairs(OriginalData) do
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            mob.HumanoidRootPart.Size = data.Size
            mob.HumanoidRootPart.CanCollide = true
        end
    end
    ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(CleanUp)

-- // LÓGICA PRINCIPAL //
local isEnabled = false

ToggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        ToggleBtn.Text = "PARAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    else
        ToggleBtn.Text = "ATIVAR MAGNETO"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 150)
    end
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().MobMagnetRunning or not isEnabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then 
        Status.Text = "⚠️ Pasta 'Mobs' não achada!"
        return 
    end
    
    local myRoot = char.HumanoidRootPart
    local targetPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.Distance)
    local count = 0
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        local mRoot = mob:FindFirstChild("HumanoidRootPart")
        local mHum = mob:FindFirstChild("Humanoid")
        
        if mRoot and mHum and mHum.Health > 0 then
            local dist = (mRoot.Position - myRoot.Position).Magnitude
            
            if dist < SETTINGS.Range then
                -- Backup e Configuração (Hitbox)
                if not OriginalData[mob] then
                    OriginalData[mob] = {Size = mRoot.Size}
                    mRoot.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                    mRoot.Transparency = 0.5
                end
                
                -- Puxa o monstro
                mRoot.CFrame = targetPos
                mRoot.Velocity = Vector3.new(0, 0, 0)
                mRoot.CanCollide = false -- Fantasma pra não travar você
                count = count + 1
            end
        end
    end
    Status.Text = "🧲 PUXANDO: " .. count .. " MONSTROS"
end)