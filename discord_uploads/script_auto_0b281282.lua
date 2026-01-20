--[[
    ☢️ QUEST REPEATER v5 (SHOTGUN & FORCE)
    
    ESTRATÉGIA FINAL:
    1. "Shotgun Click": Clica em 5 alturas diferentes para compensar a barra do celular.
    2. "Force Fire": Tenta ativar o sinal interno do botão (sem toque físico).
    3. Auto Equip: Mantido (Tecla 1).
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().QuestRepeaterV5 = true

-- // GUI VISUAL //
if CoreGui:FindFirstChild("QuestRepeaterV5") then CoreGui.QuestRepeaterV5:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "QuestRepeaterV5"
-- Garante que desenha por cima de tudo
ScreenGui.DisplayOrder = 999 

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 80)
MainFrame.Position = UDim2.new(0.6, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "☢️ REPEAT V5 (FORCE)"
Title.TextColor3 = Color3.fromRGB(255, 100, 100)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0.4, 0)
Status.Text = "Procurando..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Caixa de Mira (Para você ver onde ele tá clicando)
local DebugBox = Instance.new("Frame", ScreenGui)
DebugBox.BackgroundTransparency = 1
DebugBox.BorderColor3 = Color3.fromRGB(0, 255, 0) -- Verde = Achou
DebugBox.BorderSizePixel = 3
DebugBox.Visible = false

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().QuestRepeaterV5 = false
    ScreenGui:Destroy()
end)

-- // FUNÇÃO TIRO DE ESCOPETA //
local function ShotgunClick(obj)
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    local centerX = pos.X + size.X/2
    
    -- Tenta pegar o tamanho da barra superior (Inset)
    local insetY = GuiService:GetGuiInset().Y -- Geralmente 36 ou 58 no mobile
    
    -- Desenha a caixa onde o jogo DIZ que o botão está
    DebugBox.Position = UDim2.new(0, pos.X, 0, pos.Y)
    DebugBox.Size = UDim2.new(0, size.X, 0, size.Y)
    DebugBox.Visible = true
    
    Status.Text = "🔥 DISPARANDO CLIQUES..."
    
    -- TENTATIVA 1: Force Signal (Sem mouse)
    -- Se o executor suportar, isso clica instantaneamente
    if firesignal then
        pcall(function() firesignal(obj.MouseButton1Click) end)
        pcall(function() firesignal(obj.Activated) end)
        if obj.Parent and (obj.Parent:IsA("TextButton") or obj.Parent:IsA("ImageButton")) then
            pcall(function() firesignal(obj.Parent.MouseButton1Click) end)
            pcall(function() firesignal(obj.Parent.Activated) end)
        end
    end

    -- TENTATIVA 2: Chuva de Toques (Vários Y diferentes)
    local yPositions = {
        pos.Y + size.Y/2,           -- Centro exato (Original)
        pos.Y + size.Y/2 + insetY,  -- Centro + Barra Superior (Correção PC)
        pos.Y + size.Y/2 + 58,      -- Centro + Barra Mobile (Correção Celular)
        pos.Y + size.Y/2 + 100,     -- Mais pra baixo (Garantia)
    }
    
    for _, y in ipairs(yPositions) do
        VirtualInputManager:SendTouchEvent(1234, 0, centerX, y, 0, false, game, 1) -- Press
        task.wait()
        VirtualInputManager:SendTouchEvent(1234, 1, centerX, y, 0, false, game, 1) -- Release
    end
    
    task.wait(0.5)
    DebugBox.Visible = false
end

-- // EQUIPAR //
local function EquipWeapon()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- // LOOP SCANNER //
spawn(function()
    while getgenv().QuestRepeaterV5 do
        task.wait(1)
        
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local found = false
        
        -- Busca profunda por texto
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                -- Limpa o texto pra facilitar a busca
                local txt = obj.Text:lower():gsub(" ", "")
                
                if txt:find("repeat") then
                    -- Se achou o texto "Repeat"
                    
                    -- Se o texto estiver dentro de um botão, foca no botão
                    if obj.Parent and (obj.Parent:IsA("TextButton") or obj.Parent:IsA("ImageButton")) then
                        ShotgunClick(obj.Parent)
                    else
                        ShotgunClick(obj)
                    end
                    
                    found = true
                    break
                end
            end
        end
        
        -- Lógica de Equipar
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            if not char:FindFirstChildOfClass("Tool") then
                Status.Text = "👊 ARMA..."
                EquipWeapon()
            elseif not found then
                Status.Text = "Vigiando..."
            end
        end
    end
end)