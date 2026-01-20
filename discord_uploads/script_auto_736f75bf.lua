--[[
    📍 SIMPLE TELEPORT - JOHNNY
    Baseado na lógica que funcionou para você.
    - Apenas um botão.
    - Clicou -> Teleportou.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Configuração: Nome do NPC
local TargetName = "Johnny"

-- // GUI SETUP SIMPLES //
if CoreGui:FindFirstChild("SimpleTP") then CoreGui.SimpleTP:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleTP"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Janelinha Pequena
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 160, 0, 80) -- Bem pequeno
Frame.Position = UDim2.new(0.1, 0, 0.3, 0) -- Canto esquerdo
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
Frame.BorderSizePixel = 2
Frame.Active = true
Frame.Draggable = true

-- Botão TP
local TPBtn = Instance.new("TextButton", Frame)
TPBtn.Size = UDim2.new(1, -10, 1, -10)
TPBtn.Position = UDim2.new(0, 5, 0, 5)
TPBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
TPBtn.Text = "IR NO JOHNNY"
TPBtn.TextColor3 = Color3.WHITE
TPBtn.Font = Enum.Font.GothamBlack
TPBtn.TextSize = 16

-- Botão Fechar (X) Pequeno no canto
local Close = Instance.new("TextButton", Frame)
Close.Size = UDim2.new(0, 20, 0, 20)
Close.Position = UDim2.new(1, -20, 0, 0)
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Text = "X"
Close.TextColor3 = Color3.WHITE
Close.BorderSizePixel = 0
Close.ZIndex = 2 -- Fica por cima

-- // LÓGICA DE TELEPORTE (A MESMA DO SEU SCRIPT) //
TPBtn.Activated:Connect(function() -- 'Activated' funciona melhor no celular
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local found = false
    
    -- Busca EXATA do seu script anterior que funcionou
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local parent = v.Parent
            
            -- Verifica se é o Johnny
            if parent.Name == TargetName or (parent.Parent and parent.Parent.Name == TargetName) then
                
                -- Descobre qual parte é o corpo pra teleportar
                local targetPart = nil
                if parent:IsA("BasePart") then
                    targetPart = parent
                elseif parent:IsA("Model") then
                    targetPart = parent.PrimaryPart
                end
                
                if targetPart then
                    -- TELEPORTA
                    char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
                    
                    -- OLHA PRO NPC
                    char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPart.Position)
                    
                    found = true
                    TPBtn.Text = "CHEGOU!"
                    task.wait(1)
                    TPBtn.Text = "IR NO JOHNNY"
                    break
                end
            end
        end
    end
    
    if not found then
        TPBtn.Text = "NAO ACHEI!"
        task.wait(1)
        TPBtn.Text = "IR NO JOHNNY"
    end
end)

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)