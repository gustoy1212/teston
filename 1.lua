--[[
    🧬 ZOMBIE AUTOPSY v2.0 (Fixed & GUI)
    
    Correções:
    - Ignora a Arma/Ferramenta do Player.
    - Mostra o resultado na TELA (GUI) em vez do Console.
    - Highlight dura para sempre.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZombieAutopsyGUI"
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🧬 AUTÓPSIA DE ZUMBI"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ScanBtn.Text = "ESCANEAR AGORA (Encoste no Zumbi)"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

local ResultsScroll = Instance.new("ScrollingFrame", MainFrame)
ResultsScroll.Size = UDim2.new(0.9, 0, 0.6, 0)
ResultsScroll.Position = UDim2.new(0.05, 0, 0.3, 0)
ResultsScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ResultsScroll.CanvasSize = UDim2.new(0, 0, 2, 0)

local ResultsText = Instance.new("TextLabel", ResultsScroll)
ResultsText.Size = UDim2.new(1, 0, 1, 0)
ResultsText.BackgroundTransparency = 1
ResultsText.TextColor3 = Color3.fromRGB(0, 255, 0)
ResultsText.TextXAlignment = Enum.TextXAlignment.Left
ResultsText.TextYAlignment = Enum.TextYAlignment.Top
ResultsText.Text = "Aguardando scan..."
ResultsText.Font = Enum.Font.Code
ResultsText.TextSize = 12

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.1, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.9, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR / LIMPAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // LÓGICA DE SCAN //
local lastHighlight = nil

local function ScanClosest()
    local char = LocalPlayer.Character
    if not char then return end
    
    local myPos = char.PrimaryPart.Position
    local closest = nil
    local minDist = 10 -- Tem que estar perto (10 studs)
    
    -- Limpa highlight antigo
    if lastHighlight then lastHighlight:Destroy() end
    ResultsText.Text = "Procurando..."
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            -- FILTRO DE OURO: Não pode ser eu, nem minha ferramenta, nem acessório
            if not obj:IsDescendantOf(char) and obj ~= char then
                
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                
                if root then
                    local dist = (root.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    
    if closest then
        -- Pinta o alvo
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(0, 255, 255)
        hl.Parent = closest
        lastHighlight = hl
        
        -- Gera Relatório
        local report = "ALVO: " .. closest.Name .. "\n"
        report = report .. "CAMINHO: " .. closest:GetFullName() .. "\n"
        report = report .. "----------------------\n"
        report = report .. "COMPONENTES (Children):\n"
        
        for _, child in ipairs(closest:GetChildren()) do
            local extra = ""
            if child:IsA("ValueBase") then extra = " = " .. tostring(child.Value) end
            if child:IsA("Humanoid") then extra = " (HP: " .. child.Health .. "/" .. child.MaxHealth .. ")" end
            
            report = report .. "• [" .. child.ClassName .. "] " .. child.Name .. extra .. "\n"
        end
        
        -- Checa Atributos
        local attrs = closest:GetAttributes()
        if next(attrs) then
            report = report .. "\nATRIBUTOS:\n"
            for n, v in pairs(attrs) do
                report = report .. "• " .. n .. ": " .. tostring(v) .. "\n"
            end
        end
        
        ResultsText.Text = report
    else
        ResultsText.Text = "❌ Nada encontrado.\nChegue mais perto do Zumbi\ne saia de perto de outros players."
    end
end

ScanBtn.MouseButton1Click:Connect(ScanClosest)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
