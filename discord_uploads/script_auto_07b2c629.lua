--[[
    🧙‍♂️ RPG MAGNET v3 - RECURSIVE EDITION
    
    MELHORIAS:
    - Busca em todas as pastas (não apenas Workspace.Mobs).
    - Identifica alvos pelo componente 'Humanoid' e 'HP'.
    - Anti-Kick: Sem manipulação de metatables.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().MobMagnetV3 = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Distance = 8,         -- Distância na sua frente
    Range = 5000,         -- Raio de busca (Mapa todo)
    HitboxSize = 6,       
}

local OriginalData = {} 

-- // GUI SETUP //
if CoreGui:FindFirstChild("MobMagnetV3") then CoreGui.MobMagnetV3:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "MobMagnetV3"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🧲 MAGNET V3 (BUSCA TOTAL)"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
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
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Pronto"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
ToggleBtn.Text = "LIGAR MAGNETO TOTAL"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE LIMPEZA //
local function CleanUp()
    getgenv().MobMagnetV3 = false
    for mob, data in pairs(OriginalData) do
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            mob.HumanoidRootPart.Size = data.Size
            mob.HumanoidRootPart.CanCollide = true
            mob.HumanoidRootPart.Transparency = data.Trans
        end
    end
    ScreenGui:Destroy()
end
CloseBtn.MouseButton1Click:Connect(CleanUp)

-- // LÓGICA DE BUSCA //
local function IsEnemy(obj)
    if obj:IsA("Model") and obj ~= LocalPlayer.Character then
        local hum = obj:FindFirstChildOfClass("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart")
        -- Verifica se tem vida e se não é um player
        if hum and root and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
            return true
        end
    end
    return false
end

-- // LÓGICA PRINCIPAL //
local isEnabled = false
ToggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    ToggleBtn.Text = isEnabled and "PARAR MAGNETO" or "LIGAR MAGNETO TOTAL"
    ToggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(20, 60, 20)
end)

RunService.Heartbeat:Connect(function()
    if not getgenv().MobMagnetV3 or not isEnabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    local targetPos = myRoot.CFrame * CFrame.new(0, 0, -SETTINGS.Distance)
    local count = 0
    
    -- Busca recursiva em todo o Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsEnemy(obj) then
            local mRoot = obj.HumanoidRootPart
            local mHum = obj:FindFirstChildOfClass("Humanoid")
            local dist = (mRoot.Position - myRoot.Position).Magnitude
            
            if dist < SETTINGS.Range then
                -- Backup
                if not OriginalData[obj] then
                    OriginalData[obj] = {Size = mRoot.Size, Trans = mRoot.Transparency}
                    mRoot.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
                    mRoot.Transparency = 0.5
                end
                
                -- Magnetismo
                mRoot.CFrame = targetPos
                mRoot.Velocity = Vector3.new(0, 0, 0)
                mRoot.CanCollide = false
                count = count + 1
            end
        end
    end
    Status.Text = "🎯 ALVOS PUXADOS: " .. count
end)