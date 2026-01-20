--[[
    🤖 AUTO QUEST & EQUIP v1
    
    BASEADO NA PRINT:
    - Detecta o botão "Repeat Quest".
    - Clica nele automaticamente.
    - Aperta a tecla [1] se você estiver sem arma.
    
    PERFEITO PARA FARM AFK.
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().QuestHelper = true

-- // GUI VISUAL //
if CoreGui:FindFirstChild("QuestHelperUI") then CoreGui.QuestHelperUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "QuestHelperUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 100)
MainFrame.Position = UDim2.new(0.7, 0, 0.2, 0) -- Fica na direita
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 30, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🤖 QUEST REPEATER (ON)"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.3, 0)
Status.Text = "Vigiando Tela..."
Status.TextColor3 = Color3.fromRGB(200, 255, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().QuestHelper = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO DE CLIQUE //
local function ClickButton(btn)
    -- Calcula o centro do botão para clicar certo
    local pos = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local center = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
    
    -- Simula clique do mouse/dedo
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
end

-- // FUNÇÃO DE EQUIPAR //
local function PressOne()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().QuestHelper do
        wait(0.5) -- Verifica a cada meio segundo (leve)
        
        -- 1. VERIFICA ARMA (PRIORIDADE)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            -- Se não tem ferramenta na mão, aperta 1
            if not char:FindFirstChildOfClass("Tool") then
                Status.Text = "👊 EQUIPANDO SOCO..."
                PressOne()
            end
        end
        
        -- 2. CAÇA O BOTÃO "REPEAT"
        local found = false
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        
        -- Varre a interface procurando o botão
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                -- Verifica se está visível
                if gui.Visible then
                    -- Verifica se tem texto "Repeat"
                    local text = ""
                    if gui:IsA("TextButton") then text = gui.Text end
                    if gui:FindFirstChild("TextLabel") then text = gui.TextLabel.Text end
                    
                    if text:lower():find("repeat") or text:lower():find("repetir") then
                        Status.Text = "✅ CLICK: REPEAT QUEST"
                        ClickButton(gui)
                        found = true
                        
                        -- Garante equipar de novo logo após clicar
                        wait(0.5)
                        PressOne()
                        break
                    end
                end
            end
        end
        
        if not found and Status.Text ~= "👊 EQUIPANDO SOCO..." then
            Status.Text = "Vigiando..."
        end
    end
end)