--[[
    BLOX FRUITS - V2 "ANTI-BUG" UI
    Correção: Troca de "MouseButton1Click" para "Activated" (Melhor para Mobile).
    Foco: Testar se o botão funciona e se o ataque sai.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

getgenv().BloxKill = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    Range = 400, -- Raio de 400 metros
}

-- // LIMPEZA DE UI ANTIGA //
if CoreGui:FindFirstChild("BloxUI_Mobile") then CoreGui.BloxUI_Mobile:Destroy() end

-- // CRIAÇÃO DA GUI //
local ScreenGui = Instance.new("ScreenGui")
-- Tenta colocar no PlayerGui se o gethui falhar (as vezes resolve bug de toque)
local targetParent = gethui and gethui() or CoreGui
ScreenGui.Parent = targetParent
ScreenGui.Name = "BloxUI_Mobile"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 150)
MainFrame.Position = UDim2.new(0.5, -110, 0.3, 0) -- Centralizado
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Amarelo
MainFrame.BorderSizePixel = 3
MainFrame.Active = true -- Importante para o toque funcionar
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⚡ BLOX MOBILE V2"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.WHITE
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.SourceSansBold

-- BOTÃO CONFIGURADO PARA TOQUE
local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.4, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Cinza (Desligado)
ToggleBtn.Text = "ATIVAR (CLIQUE AQUI)"
ToggleBtn.TextColor3 = Color3.WHITE
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.ZIndex = 10 -- Garante que o botão esteja no topo de tudo
ToggleBtn.AutoButtonColor = true

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE
CloseBtn.ZIndex = 10

-- // ESTADO //
local IsRunning = false

-- // LÓGICA DE INTERFACE (USANDO ACTIVATED) //
-- Activated funciona melhor em telas de toque do que MouseButton1Click

ToggleBtn.Activated:Connect(function()
    IsRunning = not IsRunning
    
    if IsRunning then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Verde
        ToggleBtn.Text = "LIGADO (RODANDO)"
        Status.Text = "🔥 PROCURANDO..."
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Cinza
        ToggleBtn.Text = "ATIVAR (CLIQUE AQUI)"
        Status.Text = "💤 PARADO"
    end
end)

CloseBtn.Activated:Connect(function()
    getgenv().BloxKill = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO DE ATAQUE (SIMULAÇÃO) //
local function AttackClick()
    -- Simula toque no centro da tela
    VirtualInputManager:SendTouchEvent(999, 0, 400, 400, 0, false, game, 1) 
    task.wait()
    VirtualInputManager:SendTouchEvent(999, 1, 400, 400, 0, false, game, 1)
end

-- // LOOP PRINCIPAL //
task.spawn(function()
    while getgenv().BloxKill do
        task.wait() -- Loop rápido
        
        if IsRunning then
            -- Verifica se o personagem existe
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local MyRoot = LocalPlayer.Character.HumanoidRootPart
                
                -- Procura inimigos
                local enemies = Workspace:FindFirstChild("Enemies")
                local found = false
                
                if enemies then
                    for _, mob in pairs(enemies:GetChildren()) do
                        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
                            local mobRoot = mob.HumanoidRootPart
                            local dist = (MyRoot.Position - mobRoot.Position).Magnitude
                            
                            -- Se achou alguém perto (400 studs)
                            if dist < SETTINGS.Range then
                                found = true
                                
                                -- 1. PUXA (Bring)
                                mobRoot.CFrame = MyRoot.CFrame * CFrame.new(0, 0, -5)
                                
                                -- 2. HITBOX & TRAVA
                                mobRoot.Size = Vector3.new(8, 8, 8)
                                mobRoot.CanCollide = false
                                mobRoot.Transparency = 0.5
                                mob.Humanoid.WalkSpeed = 0
                                mob.Humanoid.PlatformStand = true
                                
                                -- 3. ATAQUE
                                AttackClick()
                            end
                        end
                    end
                end
                
                if found then
                    Status.Text = "⚔️ BATENDO..."
                else
                    Status.Text = "🔍 SEM INIMIGOS..."
                end
            end
        end
    end
end)