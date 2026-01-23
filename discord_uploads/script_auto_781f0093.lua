--[[
    BLOX FRUITS - TESTE DE COMBATE (KILL AURA)
    Foco: Matar qualquer coisa perto (sem missão) para testar o script.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

getgenv().BloxTest = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Range = 500, -- Raio de busca (meia ilha)
}

-- // GUI NATIVA (Igual a que funcionou antes) //
if CoreGui:FindFirstChild("BloxTestUI") then CoreGui.BloxTestUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
ScreenGui.Name = "BloxTestUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🔪 BLOX KILL AURA"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Parado"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.Text = "ATIVAR AURA"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE

-- // ESTADO //
local IsRunning = false

-- // LÓGICA DE CLICK (SIMULAÇÃO DE DEDO) //
local function AttackClick()
    VirtualInputManager:SendTouchEvent(999, 0, 500, 500, 0, false, game, 1) -- Toque no meio da tela
    task.wait()
    VirtualInputManager:SendTouchEvent(999, 1, 500, 500, 0, false, game, 1) -- Solta
end

-- // INTERFACE //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BloxTest = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        Status.Text = "🔥 PROCURANDO INIMIGOS..."
    else
        ToggleBtn.Text = "ATIVAR AURA"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        Status.Text = "Status: Parado"
    end
end)

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().BloxTest do
        task.wait() -- Loop rápido
        
        if IsRunning then
            -- Garante que o player existe
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local MyRoot = LocalPlayer.Character.HumanoidRootPart
                
                -- Procura inimigos na pasta Enemies
                local enemies = Workspace:FindFirstChild("Enemies")
                local foundTarget = false
                
                if enemies then
                    for _, mob in pairs(enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            local mobRoot = mob.HumanoidRootPart
                            local dist = (MyRoot.Position - mobRoot.Position).Magnitude
                            
                            -- Se estiver no raio de 500 metros
                            if dist < SETTINGS.Range then
                                foundTarget = true
                                
                                -- 1. PUXAR (Bring)
                                mobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -5) -- Traz pra frente
                                mobRoot.Size = Vector3.new(10, 10, 10) -- Hitbox Gigante
                                mobRoot.Transparency = 0.5
                                mobRoot.CanCollide = false
                                
                                -- Trava o mob
                                mob.Humanoid.WalkSpeed = 0
                                mob.Humanoid.PlatformStand = true
                                
                                -- 2. ATACAR
                                AttackClick()
                            end
                        end
                    end
                end
                
                if foundTarget then
                    Status.Text = "⚔️ MATANDO..."
                else
                    Status.Text = "🔍 NADA PERTO..."
                end
            end
        end
    end
end)