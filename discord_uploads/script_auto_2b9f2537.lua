--[[
    📍 TP JOHNNY (SIMPLES E DIRETO)
    - Cria um botão azul na tela.
    - Clicou -> Vai direto pro Johnny.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Remove se já existir para não duplicar
if CoreGui:FindFirstChild("TPJohnny") then CoreGui.TPJohnny:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPJohnny"
-- Tenta colocar no CoreGui (melhor), se falhar vai pro PlayerGui
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- BOTÃO AZUL GRANDE
local Button = Instance.new("TextButton", ScreenGui)
Button.Size = UDim2.new(0, 200, 0, 80)
Button.Position = UDim2.new(0.5, -100, 0.2, 0) -- Meio da tela, um pouco pra cima
Button.BackgroundColor3 = Color3.fromRGB(0, 80, 255)
Button.Text = "IR NO JOHNNY"
Button.TextColor3 = Color3.WHITE
Button.Font = Enum.Font.GothamBlack
Button.TextSize = 20
Button.BorderSizePixel = 2
Button.BorderColor3 = Color3.WHITE

-- BOTÃO FECHAR (X) PEQUENO EM CIMA
local Close = Instance.new("TextButton", Button)
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -15, 0, -15) -- Canto direito superior
Close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Close.Text = "X"
Close.TextColor3 = Color3.WHITE
Close.Font = Enum.Font.GothamBold

-- // LÓGICA DO TELEPORTE //
Button.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local found = false
    
    -- Procura o Johnny em TUDO
    for _, v in pairs(Workspace:GetDescendants()) do
        -- Verifica se o nome é Johnny e se é um boneco (Model)
        if v.Name == "Johnny" and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
            
            -- TELEPORTA 3 PASSOS NA FRENTE DELE
            char.HumanoidRootPart.CFrame = v.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            
            -- OLHA PARA ELE
            char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, v.HumanoidRootPart.Position)
            
            found = true
            Button.Text = "CHEGOU!"
            task.wait(1)
            Button.Text = "IR NO JOHNNY"
            break
        end
    end
    
    if not found then
        Button.Text = "JOHNNY NÃO ESTÁ AQUI"
        task.wait(1)
        Button.Text = "IR NO JOHNNY"
    end
end)

-- FECHAR SCRIPT
Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)