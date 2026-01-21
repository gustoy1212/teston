--[[
    🕵️‍♂️ SAO UI DETECTOR (FINGERPRINT)
    
    OBJETIVO: Descobrir o NOME EXATO do botão de ataque.
    
    COMO USAR:
    1. Ative o script.
    2. Clique no botão de ataque na sua tela.
    3. Copie/Anote o nome que aparecer.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("UIDetectorUI") then CoreGui.UIDetectorUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "UIDetectorUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 50)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🕵️‍♂️ DETETIVE DE BOTÃO"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, -20, 0.6, 0)
InfoLabel.Position = UDim2.new(0, 10, 0.15, 0)
InfoLabel.Text = "Toque no botão de ataque para ver o nome dele aqui..."
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextWrapped = true
InfoLabel.TextSize = 14
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.2, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.8, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // LÓGICA DE DETECÇÃO //
local Connection = nil

local function StartDetection()
    Connection = UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            
            local mousePos = UserInputService:GetMouseLocation()
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local foundObjects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
            
            for _, obj in ipairs(foundObjects) do
                -- Só queremos botões visíveis
                if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
                    
                    local report = "✅ BOTÃO ENCONTRADO!\n"
                    report = report .. "NOME: " .. obj.Name .. "\n"
                    report = report .. "PAI: " .. obj.Parent.Name .. "\n"
                    report = report .. "CAMINHO COMPLETO:\n" .. obj:GetFullName()
                    
                    InfoLabel.Text = report
                    
                    -- Destaca o botão pra confirmar
                    local hl = Instance.new("Frame", obj)
                    hl.Name = "DetectorHighlight"
                    hl.Size = UDim2.new(1, 0, 1, 0)
                    hl.BackgroundTransparency = 0.5
                    hl.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    hl.BorderSizePixel = 0
                    game.Debris:AddItem(hl, 0.5) -- Some depois de 0.5s
                    
                    break -- Pega o primeiro botão que achar (o que está por cima)
                end
            end
        end
    end)
end

StartDetection()

CloseBtn.MouseButton1Click:Connect(function()
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)