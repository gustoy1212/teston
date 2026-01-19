--[[
    📜 QUEST SPY - REMOTE LOGGER v1
    
    OBJETIVO:
    - Capturar o sinal de "Aceitar Missão".
    - Mostra Nome do Remote + Argumentos.
    
    FILTRO INTELIGENTE:
    - Ignora barulhos de andar, chat e emoticons.
    - Foca em: Quest, Mission, Npc, Talk, Interact, Grimoire.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("QuestSpy") then CoreGui.QuestSpy:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuestSpy"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 250)
MainFrame.Position = UDim2.new(0.5, -225, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "📜 QUEST SPY (Injete e Aceite a Missão)"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.Code
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- // LOG FUNCTION //
local function Log(remoteName, args, color)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 45) -- Altura fixa
    frame.BackgroundTransparency = 1
    frame.Parent = ScrollFrame
    
    local lblName = Instance.new("TextLabel", frame)
    lblName.Size = UDim2.new(1, 0, 0, 20)
    lblName.Text = "📡 " .. remoteName
    lblName.TextColor3 = color or Color3.fromRGB(0, 255, 255)
    lblName.Font = Enum.Font.GothamBold
    lblName.TextXAlignment = Enum.TextXAlignment.Left
    lblName.BackgroundTransparency = 1
    
    -- Formata Argumentos
    local argsText = ""
    for i, v in pairs(args) do
        argsText = argsText .. tostring(v) .. ", "
    end
    
    local lblArgs = Instance.new("TextLabel", frame)
    lblArgs.Size = UDim2.new(1, 0, 0, 20)
    lblArgs.Position = UDim2.new(0, 15, 0, 20)
    lblArgs.Text = "ARGS: " .. argsText
    lblArgs.TextColor3 = Color3.fromRGB(200, 200, 200)
    lblArgs.Font = Enum.Font.Code
    lblArgs.TextXAlignment = Enum.TextXAlignment.Left
    lblArgs.BackgroundTransparency = 1
    
    ScrollFrame.CanvasPosition = Vector2.new(0, 9999)
end

-- // REMOTE SPY (HOOK) //
local IgnoreList = {
    "CharacterSoundEvent",
    "DefaultChatSystemChatEvents",
    "ClientInput",
    "TouchInfo",
    "UpdateMouse",
    "MoveRel",
    "Cmd"
}

local function IsIgnored(name)
    for _, v in pairs(IgnoreList) do
        if name == v then return true end
    end
    return false
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        if not IsIgnored(self.Name) then
            -- Destaca coisas importantes
            if self.Name:lower():match("quest") or self.Name:lower():match("mission") or self.Name:lower():match("accept") or self.Name:lower():match("talk") then
                Log(self.Name, args, Color3.fromRGB(255, 255, 0)) -- Amarelo (Provável Alvo)
            elseif self.Name:lower():match("grimoire") or self.Name:lower():match("skill") then
                -- Log(self.Name, args, Color3.fromRGB(0, 100, 255)) -- Azul (Combate - Opcional)
            else
                Log(self.Name, args, Color3.fromRGB(255, 255, 255)) -- Branco (Genérico)
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end

-- // FECHAR //
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)