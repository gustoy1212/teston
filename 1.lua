--[[
    👁️ ESP INSPECTOR v1.0 (FERRAMENTA DE ANÁLISE)
    
    O que faz:
    - Mostra TODOS os Humanoids através da parede.
    - Exibe Nome, Vida e Distância.
    - Ajuda a diferenciar Inimigos Reais de Iscas/Bugs.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI DE CONTROLE //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Inspector"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 50)
MainFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Text = "ESP ATIVO (Olhe os Nomes)"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE CRIAR VISUAL //
local espFolder = Instance.new("Folder", CoreGui)
espFolder.Name = "ESP_HOLDER"

local function CreateESP(model)
    -- Remove ESP anterior se existir
    if model:FindFirstChild("InspectorESP") then return end
    
    local root = model:FindFirstChild("HumanoidRootPart")
    local hum = model:FindFirstChild("Humanoid")
    
    if root and hum then
        -- 1. Cria o Highlight (Caixa Brilhante)
        local hl = Instance.new("Highlight")
        hl.Name = "InspectorESP"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = model
        
        -- Cor diferente para Players e NPCs
        if Players:GetPlayerFromCharacter(model) then
            hl.FillColor = Color3.fromRGB(0, 255, 0) -- Verde (Player)
        else
            hl.FillColor = Color3.fromRGB(255, 0, 0) -- Vermelho (NPC/Monstro)
        end

        -- 2. Cria o Texto (BillboardGui)
        local bg = Instance.new("BillboardGui")
        bg.Name = "InfoESP"
        bg.Adornee = root
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true -- Vê através da parede
        bg.Parent = model
        
        local text = Instance.new("TextLabel", bg)
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.Code
        text.TextStrokeTransparency = 0
        text.TextColor3 = Color3.new(1, 1, 1)
        
        -- Loop de Atualização Individual
        task.spawn(function()
            while model.Parent and hum.Health > 0 do
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                
                text.Text = string.format(
                    "Nome: %s\nVida: %.0f\nDist: %.0f studs",
                    model.Name,
                    hum.Health,
                    dist
                )
                
                -- Se for o tal do ScopeSStars, pinta de Roxo pra destacar
                if model.Name == "ScopeSStars" then
                    text.TextColor3 = Color3.fromRGB(255, 0, 255)
                    hl.FillColor = Color3.fromRGB(255, 0, 255)
                end
                
                task.wait(0.1)
            end
            -- Limpeza
            bg:Destroy()
            hl:Destroy()
        end)
    end
end

-- // LOOP DE VARREDURA //
RunService.Heartbeat:Connect(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent ~= LocalPlayer.Character then
            CreateESP(obj.Parent)
        end
    end
end)
