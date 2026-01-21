--[[
    🩻 SAO UI X-RAY (SMART CLICKER)
    
    OBJETIVO: Encontrar o botão de ataque pelo TAMANHO e POSIÇÃO.
    
    COMO FUNCIONA:
    1. Varre a PlayerGui.
    2. Pega todos os botões visíveis no lado DIREITO.
    3. Escolhe o MAIOR de todos (Geralmente é o Ataque).
    4. Clica nele automaticamente.
]]

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().UIXray = true

-- // CONFIGURAÇÕES //
local SETTINGS = {
    ClickSpeed = 0.1, -- Velocidade do clique automático
}

-- Estados
local TargetButton = nil
local Highlighter = nil

-- // GUI SETUP //
if CoreGui:FindFirstChild("UIXrayUI") then CoreGui.UIXrayUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "UIXrayUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🩻 UI X-RAY (AUTO BUTTON)"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.25, 0)
Status.Text = "Procurando botão gigante..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1
Status.TextWrapped = true

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO: ENCONTRAR O BOTÃO DE ATAQUE //
local function FindAttackButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenSize = workspace.CurrentCamera.ViewportSize
    
    local bestBtn = nil
    local maxSize = 0
    
    -- Varre tudo
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if (gui:IsA("ImageButton") or gui:IsA("TextButton")) and gui.Visible then
            local pos = gui.AbsolutePosition
            local size = gui.AbsoluteSize
            local area = size.X * size.Y
            
            -- FILTRO 1: Tem que estar na DIREITA (X > 60% da tela)
            -- FILTRO 2: Tem que estar EM BAIXO (Y > 40% da tela)
            if (pos.X > screenSize.X * 0.6) and (pos.Y > screenSize.Y * 0.4) then
                
                -- Lógica: O botão de ataque costuma ser O MAIOR da direita
                if area > maxSize then
                    maxSize = area
                    bestBtn = gui
                end
            end
        end
    end
    
    return bestBtn
end

-- // FUNÇÃO: DESTACAR BOTÃO //
local function HighlightButton(btn)
    if not btn then return end
    
    -- Remove destaque antigo
    if Highlighter then Highlighter:Destroy() Highlighter = nil end
    
    -- Cria borda verde
    local box = Instance.new("Frame", ScreenGui)
    box.BackgroundTransparency = 1
    box.BorderColor3 = Color3.fromRGB(0, 255, 0) -- VERDE NEON
    box.BorderSizePixel = 4
    box.Size = UDim2.new(0, btn.AbsoluteSize.X + 10, 0, btn.AbsoluteSize.Y + 10)
    box.Position = UDim2.new(0, btn.AbsolutePosition.X - 5, 0, btn.AbsolutePosition.Y - 5)
    
    local nameLbl = Instance.new("TextLabel", box)
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.Position = UDim2.new(0, 0, -0.3, 0)
    nameLbl.Text = btn.Name
    nameLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0
    
    Highlighter = box
    Status.Text = "Botão Encontrado:\n" .. btn.Name
end

-- // FUNÇÃO: CLICAR NO BOTÃO //
local function ClickButton(btn)
    if not btn then return end
    
    local pos = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local centerX = pos.X + (size.X / 2)
    local centerY = pos.Y + (size.Y / 2)
    
    -- Simula Toque Mobile (Touch)
    VirtualInputManager:SendTouchEvent(555, 0, centerX, centerY, 0, false, game, 1)
    task.wait()
    VirtualInputManager:SendTouchEvent(555, 1, centerX, centerY, 0, false, game, 1)
    
    -- Tenta fire no evento também (Garantia)
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().UIXray = false
    if Highlighter then Highlighter:Destroy() end
    ScreenGui:Destroy()
end)

-- // LOOP DE ATAQUE //
spawn(function()
    while getgenv().UIXray do
        -- 1. Procura o botão (caso mude ou não tenha achado)
        if not TargetButton or not TargetButton.Parent or not TargetButton.Visible then
            TargetButton = FindAttackButton()
            if TargetButton then
                HighlightButton(TargetButton)
            else
                Status.Text = "Procurando botão na direita..."
            end
        end
        
        -- 2. Clica nele
        if TargetButton then
            ClickButton(TargetButton)
        end
        
        task.wait(SETTINGS.ClickSpeed)
    end
end)