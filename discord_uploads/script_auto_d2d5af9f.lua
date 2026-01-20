--[[
    🔘 BOTÃO ÚNICO - MAGNETO SUPREMO
    
    INTERFACE:
    - Apenas um botão gigante no meio da tela.
    - Se ficar preto, é culpa do executor, mas fiz transparente pra evitar.
    
    LÓGICA:
    - Puxa da pasta 'Mobs'.
    - Trava na sua frente (5 studs).
    - Tira a colisão pra não te empurrar.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SimpleMagnet = false -- Começa desligado

-- // GUI SETUP (SIMPLIFICADO AO MÁXIMO) //
if CoreGui:FindFirstChild("OneButtonMagnet") then CoreGui.OneButtonMagnet:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OneButtonMagnet"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local BigButton = Instance.new("TextButton", ScreenGui)
BigButton.Size = UDim2.new(0, 200, 0, 80)
BigButton.Position = UDim2.new(0.5, -100, 0.15, 0) -- Meio superior
BigButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Verde (LIGAR)
BigButton.Text = "LIGAR MAGNETO"
BigButton.TextColor3 = Color3.WHITE
BigButton.Font = Enum.Font.GothamBlack
BigButton.TextSize = 20
BigButton.BorderSizePixel = 3
BigButton.BorderColor3 = Color3.WHITE
BigButton.ZIndex = 999 -- Fica na frente de tudo

-- // FUNÇÃO DE ALTERNAR (LIGA/DESLIGA) //
BigButton.Activated:Connect(function()
    getgenv().SimpleMagnet = not getgenv().SimpleMagnet
    
    if getgenv().SimpleMagnet then
        BigButton.Text = "PARAR (ATIVO)"
        BigButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Vermelho
    else
        BigButton.Text = "LIGAR MAGNETO"
        BigButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Verde
        
        -- Restaura os bichos quando desliga
        for _, mob in pairs(Workspace.Mobs:GetChildren()) do
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            if root then root.CanCollide = true end
        end
    end
end)

-- // LOOP PRINCIPAL (TRAVAMENTO) //
RunService.RenderStepped:Connect(function()
    if not getgenv().SimpleMagnet then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myRoot = char.HumanoidRootPart
    -- Posição de travamento: 5 studs na frente
    local lockPos = myRoot.CFrame * CFrame.new(0, 0, -5)
    
    -- Busca na pasta certa
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if not mobsFolder then return end
    
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") and mob ~= char then
            
            -- Checa vida pelo Atributo (como no seu print)
            local hp = mob:GetAttribute("HP")
            local isAlive = true
            if hp ~= nil and hp <= 0 then isAlive = false end
            
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("RootPart") or mob.PrimaryPart
            
            if root and isAlive then
                -- Configura para não ter colisão (Fantasma)
                root.CanCollide = false
                root.Anchored = false
                root.Velocity = Vector3.zero 
                root.RotVelocity = Vector3.zero
                
                -- FORÇA BRUTA: Move o modelo inteiro pra sua frente
                if mob.PrimaryPart then
                    mob:PivotTo(lockPos)
                else
                    root.CFrame = lockPos
                end
            end
        end
    end
end)