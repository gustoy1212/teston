--[[
    👁️ SAO VISION BOT v10 (TEXT BASED)
    
    A SOLUÇÃO VISUAL:
    - Não busca por nomes de pastas ou modelos.
    - Busca pelo TEXTO que aparece em cima dos portais ("Poder 250", etc).
    - Compara com o seu poder e entra no melhor.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SoloVision = true

-- // UI SETUP //
if CoreGui:FindFirstChild("VisionBotUI") then CoreGui.VisionBotUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "VisionBotUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 280)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "👁️ VISION BOT v10"
Title.TextColor3 = Color3.fromRGB(0, 255, 200)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local PowerLabel = Instance.new("TextLabel", MainFrame)
PowerLabel.Size = UDim2.new(0.4, 0, 0.15, 0)
PowerLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
PowerLabel.Text = "SEU PODER:"
PowerLabel.TextColor3 = Color3.white
PowerLabel.BackgroundTransparency = 1
PowerLabel.Font = Enum.Font.GothamBold

local PowerInput = Instance.new("TextBox", MainFrame)
PowerInput.Size = UDim2.new(0.4, 0, 0.15, 0)
PowerInput.Position = UDim2.new(0.5, 0, 0.15, 0)
PowerInput.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
PowerInput.TextColor3 = Color3.fromRGB(255, 255, 0)
PowerInput.Text = "0"
PowerInput.Font = Enum.Font.Code
PowerInput.TextSize = 16

local StatusLog = Instance.new("TextLabel", MainFrame)
StatusLog.Size = UDim2.new(0.9, 0, 0.3, 0)
StatusLog.Position = UDim2.new(0.05, 0, 0.35, 0)
StatusLog.Text = "Aguardando comando..."
StatusLog.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLog.BackgroundTransparency = 1
StatusLog.TextWrapped = true
StatusLog.Font = Enum.Font.Code
StatusLog.TextYAlignment = Enum.TextYAlignment.Top

local ActionBtn = Instance.new("TextButton", MainFrame)
ActionBtn.Size = UDim2.new(0.9, 0, 0.2, 0)
ActionBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
ActionBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ActionBtn.Text = "ESCANEAR E ENTRAR"
ActionBtn.TextColor3 = Color3.white
ActionBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // SISTEMA DE LEITURA (OCR) //

-- 1. Tenta achar o poder na sua tela
local function AutoDetectPower()
    local foundPower = 0
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, v in ipairs(pGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                local txt = v.Text:upper():gsub(",", "") -- Tira virgula
                -- Procura padrão "PODER 123" ou apenas números grandes no canto
                if txt:match("PODER") then
                    local num = tonumber(txt:match("%d+"))
                    if num and num > foundPower then foundPower = num end
                end
            end
        end
    end
    
    -- Se achou, atualiza a caixa
    if foundPower > 0 then
        PowerInput.Text = tostring(foundPower)
        StatusLog.Text = "✅ Poder detectado: " .. foundPower
    else
        StatusLog.Text = "⚠️ Não li seu poder. Digite manualmente!"
    end
end

-- 2. Varre o mundo procurando placas de "Poder X"
local function FindBestPortalByText()
    local myPower = tonumber(PowerInput.Text) or 0
    if myPower == 0 then
        StatusLog.Text = "❌ Digite seu poder primeiro!"
        return nil
    end

    StatusLog.Text = "🔍 Lendo placas no mapa..."
    
    local bestPortalPart = nil
    local bestReq = -1
    local foundCount = 0
    
    -- Olha todas as GUIs do mundo
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Procura TextLabels em Billboards ou Surfaces (placas flutuantes)
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
            local txt = obj.Text:lower():gsub(",", "") -- "Poder 1,400" vira "poder 1400"
            
            -- Filtro de Texto: Tem que ter "poder" e um número
            if txt:match("poder") then
                local req = tonumber(txt:match("%d+"))
                
                if req then
                    foundCount = foundCount + 1
                    
                    -- Achar a parte física desse texto
                    -- Geralmente o texto tá dentro de um BillboardGui, que tá dentro de uma Part
                    local parent = obj.Parent
                    local part = nil
                    
                    -- Sobe a hierarquia até achar uma Part ou Model
                    if parent:IsA("BillboardGui") or parent:IsA("SurfaceGui") then
                        part = parent.Adornee or parent.Parent
                    end
                    
                    if part and (part:IsA("BasePart") or part:IsA("Model")) then
                        -- Lógica de Escolha
                        if req <= myPower then
                            if req > bestReq then
                                bestReq = req
                                bestPortalPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    if foundCount == 0 then
        StatusLog.Text = "❌ Não achei nenhuma placa escrita 'Poder' no mapa."
        return nil
    elseif bestPortalPart then
        StatusLog.Text = "🎯 Alvo: Portal de Poder " .. bestReq
        return bestPortalPart
    else
        StatusLog.Text = "⚠️ Achei " .. foundCount .. " portais, mas todos são fortes demais!"
        return nil
    end
end

-- // TELEPORTE E ENTRADA //
local function TeleportAndEnter()
    local target = FindBestPortalByText()
    
    if target then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            
            -- Pega a posição certa
            local targetCFrame
            if target:IsA("Model") then
                if target.PrimaryPart then targetCFrame = target.PrimaryPart.CFrame
                else targetCFrame = target:GetPivot() end
            else
                targetCFrame = target.CFrame
            end
            
            -- 1. TELEPORTA
            StatusLog.Text = "⚡ Teleportando..."
            -- Teleporta um pouco na frente pra não bugar dentro da parede
            char.HumanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 2) 
            
            task.wait(0.5)
            
            -- 2. ENTRA (TOUCH INTEREST)
            StatusLog.Text = "🌀 Entrando (Toque)..."
            
            -- Se for modelo, tenta tocar em todas as partes
            if target:IsA("Model") then
                for _, part in ipairs(target:GetChildren()) do
                    if part:IsA("BasePart") then
                        firetouchinterest(char.HumanoidRootPart, part, 0)
                        firetouchinterest(char.HumanoidRootPart, part, 1)
                    end
                end
            else
                -- Se for parte única
                firetouchinterest(char.HumanoidRootPart, target, 0)
                firetouchinterest(char.HumanoidRootPart, target, 1)
            end
            
            -- 3. PROXIMITY PROMPT (Caso tenha botão E)
            for _, pp in ipairs(target:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then
                    fireproximityprompt(pp)
                end
            end
        end
    end
end

-- // BOTÕES //
ActionBtn.MouseButton1Click:Connect(TeleportAndEnter)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tenta detectar poder ao abrir
task.wait(1)
AutoDetectPower()