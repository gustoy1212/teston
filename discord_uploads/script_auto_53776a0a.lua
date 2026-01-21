--[[
    🕵️‍♂️ SAO BLACK BOX (REMOTE SPY)
    
    OBJETIVO: Descobrir qual "Sinal" (RemoteEvent) o jogo envia quando dá dano.
    
    COMO USAR:
    1. Ative o Script.
    2. Ataque um monstro MANUALMENTE (botão do jogo).
    3. Olhe o log para ver o nome do Remote.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("BlackBoxUI") then CoreGui.BlackBoxUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BlackBoxUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "🕵️‍♂️ CAIXA PRETA (REMOTE SPY)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.Code
Title.BackgroundTransparency = 1

local LogScroll = Instance.new("ScrollingFrame", MainFrame)
LogScroll.Size = UDim2.new(1, -10, 0.75, 0)
LogScroll.Position = UDim2.new(0, 5, 0.1, 0)
LogScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
ClearBtn.Position = UDim2.new(0.05, 0, 0.88, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ClearBtn.Text = "LIMPAR LOG / REINICIAR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÃO DE LOG //
local function AddLog(remoteName, args)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 40) -- Altura pra caber argumentos
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextWrapped = true
    
    local argText = ""
    for i, v in ipairs(args) do
        argText = argText .. tostring(v) .. ", "
    end
    
    label.Text = "📡 " .. remoteName .. "\n   ARGS: " .. argText
    label.Parent = LogScroll
    LogScroll.CanvasPosition = Vector2.new(0, 9999)
end

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end)

-- // HOOK (O ESPIÃO) //
-- Nota: Isso pode não funcionar em executores muito básicos, mas na maioria mobile funciona.
local success, err = pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" then
            -- FILTRO: Ignora remotes inúteis de sistema
            if self.Name ~= "Metric" and self.Name ~= "Log" and self.Name ~= "Update" and not self.Name:match("Analytics") then
                AddLog(self.Name, args)
                -- Imprime no console também pra garantir
                print("SPY: " .. self.Name, unpack(args))
            end
        end

        return old(self, ...)
    end)
end)

if not success then
    local label = Instance.new("TextLabel", LogScroll)
    label.Size = UDim2.new(1, 0, 0, 100)
    label.Text = "⚠️ SEU EXECUTOR NÃO SUPORTA 'HOOK'.\nInfelizmente não consigo ler os remotes."
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.BackgroundTransparency = 1
    label.TextWrapped = true
end