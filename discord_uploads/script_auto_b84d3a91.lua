--[[
    🕵️‍♂️ MOBILE DETECTIVE - TRIGGER SCANNER v2
    
    Feito para Delta/Mobile:
    - Logs na tela (ScrollingFrame).
    - Botão de Fechar Total (Limpa memória).
    - Visualizador de Gatilhos (ESP Vermelho).
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

-- Controle de Conexões (Para fechar limpo)
local Connections = {}
local EspBoxes = {}

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileScanner"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0) -- Bem no meio/topo pra ver fácil
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕵️ SCANNER DE GATILHOS"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- Botão FECHAR (Importante!)
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- Janela de Logs (Rolagem)
local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- // FUNÇÃO DE LOG NA TELA //
local function Log(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25) -- Altura da linha
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = ScrollFrame
    
    -- Auto Scroll pra baixo
    ScrollFrame.CanvasPosition = Vector2.new(0, 9999)
end

-- // FUNÇÃO LIMPEZA TOTAL //
local function CleanUp()
    for _, conn in pairs(Connections) do conn:Disconnect() end
    for _, box in pairs(EspBoxes) do box:Destroy() end
    ScreenGui:Destroy()
    print("🧹 Script fechado e limpo!")
end

CloseBtn.MouseButton1Click:Connect(CleanUp)

-- // 1. ESPIÃO DE TOQUE (TOUCH) //
local function SetupTouchSpy()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end
    
    Log("--- INICIANDO SCANNER ---", Color3.fromRGB(255, 255, 0))
    
    local touchConn = root.Touched:Connect(function(hit)
        -- Filtros básicos
        if hit:IsDescendantOf(char) then return end
        if hit.Name == "Baseplate" or hit.Name == "Terrain" then return end
        
        -- Se for parte invisível ou tiver nome suspeito
        if hit.Transparency > 0.5 or hit.Name:lower():match("trigger") or hit.Name:lower():match("sensor") or hit.Name:lower():match("door") then
            
            -- Cria ESP pra vc ver onde é
            if not EspBoxes[hit] then
                Log("🚨 GATILHO: " .. hit.Name, Color3.fromRGB(255, 50, 50))
                Log("📂 " .. hit:GetFullName(), Color3.fromRGB(150, 150, 150))
                
                local box = Instance.new("BoxHandleAdornment")
                box.Size = hit.Size + Vector3.new(0.5, 0.5, 0.5)
                box.Adornee = hit
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.4
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Parent = CoreGui
                
                table.insert(EspBoxes, box)
                Debris:AddItem(box, 10) -- Some visualmente em 10s
            end
        end
    end)
    table.insert(Connections, touchConn)
end

-- // 2. ESPIÃO DE REMOTE (BASIC HOOK) //
-- Tenta capturar o sinal de entrada na sala
local success, err = pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    if setreadonly then setreadonly(mt, false) end

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            -- Filtra spam
            if self.Name ~= "CharacterSoundEvent" and self.Name ~= "DefaultChatSystemChatEvents" and self.Name ~= "TouchInfo" then
                
                -- Se parecer com algo de Dungeon/Sala
                if self.Name:lower():match("room") or self.Name:lower():match("enter") or self.Name:lower():match("spawn") or self.Name:lower():match("trigger") then
                    Log("📡 REMOTE: " .. self.Name, Color3.fromRGB(0, 255, 255))
                    -- Log("Args: " .. tostring(args[1]), Color3.fromRGB(100, 200, 200))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    
    if setreadonly then setreadonly(mt, true) end
end)

if not success then
    Log("⚠️ Hook Remoto falhou (Executor fraco?)", Color3.fromRGB(255, 100, 0))
else
    Log("✅ Spy Remoto Ativado", Color3.fromRGB(0, 255, 0))
end

-- // INICIA //
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    SetupTouchSpy()
end)

if LocalPlayer.Character then
    SetupTouchSpy()
end