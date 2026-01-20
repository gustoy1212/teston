--[[
    📱 QUEST REPEATER v4 (MOBILE TOUCH EDITION)
    
    CORREÇÃO PARA CELULAR:
    - Em vez de mouse, usa Simulação de Toque (TouchTap).
    - Mira exatamente no texto "Repeat Quest".
    - Desenha uma caixa verde quando acha o botão.
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().QuestRepeaterMobile = true

-- // GUI VISUAL //
if CoreGui:FindFirstChild("QuestRepeaterV4") then CoreGui.QuestRepeaterV4:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "QuestRepeaterV4"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 80)
MainFrame.Position = UDim2.new(0.6, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 50, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "📱 AUTO REPEAT (TOUCH)"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.4, 0)
Status.Text = "Procurando..."
Status.TextColor3 = Color3.fromRGB(200, 255, 200)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Caixa de Mira (Visual Debug)
local TargetBox = Instance.new("Frame", ScreenGui)
TargetBox.Size = UDim2.new(0, 0, 0, 0)
TargetBox.Position = UDim2.new(0, 0, 0, 0)
TargetBox.BackgroundTransparency = 1
TargetBox.BorderColor3 = Color3.fromRGB(0, 255, 0)
TargetBox.BorderSizePixel = 3
TargetBox.Visible = false

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().QuestRepeaterMobile = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO DE TOQUE (MOBILE) //
local function TapAt(obj)
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    local centerX = pos.X + size.X/2
    local centerY = pos.Y + size.Y/2 + 58 -- Ajuste para barra superior do mobile
    
    -- Visual: Mostra onde vai clicar
    TargetBox.Position = UDim2.new(0, pos.X, 0, pos.Y + 58)
    TargetBox.Size = UDim2.new(0, size.X, 0, size.Y)
    TargetBox.Visible = true
    
    -- AÇÃO: Simula um toque de dedo
    -- (TouchStart -> Wait -> TouchEnd)
    VirtualInputManager:SendTouchEvent(123, 0, centerX, centerY, 0, false, game, 1) -- Touch Start
    task.wait(0.1)
    VirtualInputManager:SendTouchEvent(123, 1, centerX, centerY, 0, false, game, 1) -- Touch End
    
    -- Fallback: Tenta clicar com mouse também, vai que...
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    
    task.wait(0.5)
    TargetBox.Visible = false
end

-- // EQUIPAR //
local function EquipWeapon()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- // LOOP PRINCIPAL //
spawn(function()
    while getgenv().QuestRepeaterMobile do
        task.wait(1) -- Checa a cada segundo
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local found = false
        
        -- 1. PROCURA "Repeat Quest"
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                -- Remove espaços extras e põe minúsculo
                local txt = obj.Text:lower():gsub("%s+", "")
                
                -- Se achar "repeat" ou "repeatquest"
                if txt:find("repeat") then
                    Status.Text = "👆 TOCANDO..."
                    
                    -- Se for Texto dentro de Botão, clica no Botão
                    if obj.Parent and (obj.Parent:IsA("TextButton") or obj.Parent:IsA("ImageButton")) then
                        TapAt(obj.Parent)
                    else
                        -- Se não, clica no texto mesmo
                        TapAt(obj)
                    end
                    
                    found = true
                    break
                end
            end
        end
        
        -- 2. RE-EQUIPAR
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not char:FindFirstChildOfClass("Tool") then
                Status.Text = "👊 ARMA..."
                EquipWeapon()
            elseif not found then
                Status.Text = "Procurando..."
            end
        end
    end
end)