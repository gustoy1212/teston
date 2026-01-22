--[[
    🛑 SAO COMMANDER v12 (MANUAL OVERRIDE)
    
    A SOLUÇÃO FINAL:
    - O script NÃO tenta mais ler seu poder automaticamente se falhar.
    - VOCÊ digita o poder na caixa.
    - Clica no botão -> Ele teleporta. Simples e infalível.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // UI SETUP //
if CoreGui:FindFirstChild("CommanderUI") then CoreGui.CommanderUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "CommanderUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 220)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🛑 MODO COMANDANTE"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Desc = Instance.new("TextLabel", MainFrame)
Desc.Size = UDim2.new(1, 0, 0, 20)
Desc.Position = UDim2.new(0, 0, 0.15, 0)
Desc.Text = "Digite seu poder abaixo:"
Desc.TextColor3 = Color3.white
Desc.BackgroundTransparency = 1

-- CAIXA DE PODER (MANUAL)
local PowerBox = Instance.new("TextBox", MainFrame)
PowerBox.Size = UDim2.new(0.6, 0, 0.2, 0)
PowerBox.Position = UDim2.new(0.2, 0, 0.25, 0)
PowerBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PowerBox.Text = "913" -- Valor inicial de exemplo
PowerBox.TextColor3 = Color3.fromRGB(255, 255, 0)
PowerBox.Font = Enum.Font.GothamBold
PowerBox.TextSize = 24

local LogLabel = Instance.new("TextLabel", MainFrame)
LogLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
LogLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
LogLabel.Text = "Aguardando ordem..."
LogLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
LogLabel.BackgroundTransparency = 1
LogLabel.Font = Enum.Font.Code

local TeleportBtn = Instance.new("TextButton", MainFrame)
TeleportBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
TeleportBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
TeleportBtn.Text = "TELEPORTAR AGORA"
TeleportBtn.TextColor3 = Color3.white
TeleportBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // LÓGICA DE TELEPORTE //
local function ExecuteTeleport()
    -- 1. Pega o número que VOCÊ digitou
    local myPower = tonumber(PowerBox.Text)
    if not myPower then
        LogLabel.Text = "❌ Erro: Digite apenas números!"
        return
    end
    
    LogLabel.Text = "🔎 Buscando portal..."
    
    local bestPortal = nil
    local bestReq = -1
    local found = 0
    
    -- 2. Varre o mapa
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "PortalModel" then
            found = found + 1
            local req = 0
            
            -- Lê a placa do portal
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:lower():gsub(",", "")
                    local num = tonumber(txt:match("%d+"))
                    -- Filtro inteligente: Pega número maior que 10 e se tiver "poder" escrito
                    if num and num > 10 then
                        if txt:match("poder") then
                            req = num
                            break
                        elseif num > 50 then -- Se for só número mas for alto, aceita
                            req = num
                        end
                    end
                end
            end
            
            -- 3. Compara: Portal <= Seu Poder (escolhe o mais forte)
            if req <= myPower then
                if req > bestReq then
                    bestReq = req
                    bestPortal = obj
                end
            end
        end
    end
    
    -- 4. Ação
    if bestPortal then
        LogLabel.Text = "⚡ Alvo: Portal " .. bestReq
        
        -- Acha onde teleportar
        local target = bestPortal:FindFirstChild("ProximityPart") 
                    or bestPortal.PrimaryPart 
                    or bestPortal:FindFirstChildWhichIsA("BasePart")
        
        if target then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- TELEPORTA
                char.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 2, 0)
                
                -- ENTRA (Força Bruta)
                task.wait(0.1)
                firetouchinterest(char.HumanoidRootPart, target, 0)
                firetouchinterest(char.HumanoidRootPart, target, 1)
                
                local prompted = false
                for _, pp in ipairs(bestPortal:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then 
                        fireproximityprompt(pp) 
                        prompted = true
                    end
                end
                
                if prompted then
                    LogLabel.Text = "🌀 Entrando (Prompt)..."
                else
                    LogLabel.Text = "🌀 Entrando (Toque)..."
                end
            end
        else
            LogLabel.Text = "⚠️ Portal sem corpo físico!"
        end
    else
        LogLabel.Text = "❌ Nada encontrado para Poder " .. myPower
    end
end

-- // EVENTOS //
TeleportBtn.MouseButton1Click:Connect(ExecuteTeleport)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)