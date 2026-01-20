--[[
    🤖 AUTO QUEST REPEATER v2 (SCREEN SCANNER)
    
    CORREÇÃO DE CLIQUE:
    - Escaneia TODOS os textos na tela (Labels e Buttons).
    - Procura por "Repeat Quest".
    - Clica no elemento pai (o botão de fundo) se achar o texto.
    
    FUNCIONALIDADES:
    - Auto Click no "Repeat Quest".
    - Auto Equip (Tecla 1).
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().QuestRepeaterV2 = true

-- // GUI VISUAL //
if CoreGui:FindFirstChild("QuestRepeaterV2") then CoreGui.QuestRepeaterV2:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "QuestRepeaterV2"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.7, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🤖 REPEATER v2 (ON)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Procurando Texto..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().QuestRepeaterV2 = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO DE CLIQUE PRECISO //
local function ClickAt(obj)
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    local center = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
    
    -- Clica no centro do objeto achado
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
end

-- // FUNÇÃO EQUIPAR //
local function EquipWeapon()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- // LOOP INTELIGENTE //
spawn(function()
    while getgenv().QuestRepeaterV2 do
        task.wait(1) -- Verifica a cada 1 segundo (não precisa ser instantâneo)
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local foundQuest = false
        
        -- 1. ESCANEIA TUDO NA TELA
        for _, obj in ipairs(playerGui:GetDescendants()) do
            -- Procura TextLabels ou TextButtons visíveis
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                
                -- Verifica se o texto contém "Repeat" (Maiúsculo ou minúsculo)
                if obj.Text:lower():match("repeat") then
                    
                    Status.Text = "✅ CLICK: " .. obj.Text
                    
                    -- Se for um Label (texto), clica no PAI dele (o botão de fundo)
                    if obj:IsA("TextLabel") and obj.Parent and (obj.Parent:IsA("TextButton") or obj.Parent:IsA("ImageButton") or obj.Parent:IsA("Frame")) then
                        ClickAt(obj.Parent)
                    else
                        -- Se já for um botão, clica nele mesmo
                        ClickAt(obj)
                    end
                    
                    foundQuest = true
                    break -- Clicou, sai do loop
                end
            end
        end
        
        -- 2. LÓGICA DE EQUIPAR (Só se clicou na missão ou mão vazia)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not char:FindFirstChildOfClass("Tool") then
                Status.Text = "👊 RE-EQUIPANDO..."
                EquipWeapon()
            elseif not foundQuest then
                Status.Text = "Vigiando..."
            end
        end
    end
end)