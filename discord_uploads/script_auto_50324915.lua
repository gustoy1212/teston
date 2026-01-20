--[[
    🤖 QUEST REPEATER v3 (VISUAL CLICKER)
    
    SOLUÇÃO "CLICAR NA LETRA":
    - Procura qualquer texto que tenha "Repeat" ou "Repetir".
    - Desenha uma BOLINHA VERMELHA onde vai clicar (Debug Visual).
    - Clica 3 vezes seguidas no centro do texto.
    
    Tecla [1] continua funcionando para equipar a arma.
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().QuestRepeaterV3 = true

-- // GUI DE CONTROLE //
if CoreGui:FindFirstChild("QuestRepeaterV3") then CoreGui.QuestRepeaterV3:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "QuestRepeaterV3"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.7, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🤖 CLICKER v3 (VISUAL)"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Procurando 'Repeat'..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Bolinha Vermelha (Mira)
local Dot = Instance.new("Frame", ScreenGui)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.BorderSizePixel = 0
Dot.Visible = false
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().QuestRepeaterV3 = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO DE CLIQUE //
local function ClickOnGui(guiObject)
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    
    -- Calcula o centro exato
    local centerX = pos.X + size.X/2
    local centerY = pos.Y + size.Y/2 + 36 -- (+36 compensa a barra superior do Roblox as vezes)
    
    -- MOSTRA A BOLINHA (MIRA)
    Dot.Position = UDim2.new(0, pos.X + size.X/2 - 5, 0, pos.Y + size.Y/2 - 5)
    Dot.Visible = true
    
    -- CLICA 3 VEZES (BRUTE FORCE)
    for i = 1, 3 do
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
        task.wait(0.05)
    end
    
    task.wait(0.5)
    Dot.Visible = false
end

-- // EQUIPAR ARMA //
local function EquipWeapon()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- // LOOP VIGIA //
spawn(function()
    while getgenv().QuestRepeaterV3 do
        task.wait(0.5)
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local found = false
        
        -- 1. PROCURA TEXTO NA TELA
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                local txt = obj.Text:lower()
                
                -- Procura palavras chave
                if txt:find("repeat") or txt:find("repetir") then
                    Status.Text = "🛑 CLICANDO EM: " .. obj.Text
                    ClickOnGui(obj) -- Clica direto no texto
                    found = true
                    break
                end
            end
        end
        
        -- 2. RE-EQUIPA SE PRECISAR
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not char:FindFirstChildOfClass("Tool") then
                Status.Text = "👊 PEGANDO ARMA..."
                EquipWeapon()
            elseif not found then
                Status.Text = "Vigiando..."
            end
        end
    end
end)