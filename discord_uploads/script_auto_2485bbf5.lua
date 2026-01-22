--[[
    🕵️‍♂️ LOOT DECODER v1 (LUCK ANALYZER)
    
    OBJETIVO: Descobrir como o jogo decide o item do baú.
    
    COMO USAR:
    1. Ative quando os baús aparecerem.
    2. Abra um baú manualmente.
    3. Mande a print do que aparecer no Log.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("LootSpyUI") then CoreGui.LootSpyUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LootSpyUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🕵️‍♂️ DETETIVE DE BAÚ"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local LogScroll = Instance.new("ScrollingFrame", MainFrame)
LogScroll.Size = UDim2.new(0.95, 0, 0.75, 0)
LogScroll.Position = UDim2.new(0.025, 0, 0.12, 0)
LogScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.12, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.88, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // FUNÇÃO DE LOG //
local function AddLog(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextWrapped = true
    label.Parent = LogScroll
    LogScroll.CanvasPosition = Vector2.new(0, 9999)
end

-- // ESPIÃO DE REMOTES (HOOK) //
-- Tenta interceptar o sinal que sai do seu cliente
local success, err = pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" or method == "InvokeServer" then
            -- Procura palavras chave de loot
            local name = self.Name:lower()
            if name:match("chest") or name:match("reward") or name:match("open") or name:match("loot") or name:match("claim") then
                
                local argText = ""
                for i, v in ipairs(args) do
                    argText = argText .. tostring(v) .. ", "
                end
                
                AddLog("📡 ENVIOU: " .. self.Name, Color3.fromRGB(0, 255, 255))
                AddLog("   DADOS: " .. argText, Color3.fromRGB(200, 200, 200))
                print("LOOT SPY: ", self.Name, unpack(args))
            end
        end

        return old(self, ...)
    end)
end)

if not success then
    AddLog("⚠️ SEU EXECUTOR NÃO SUPORTA HOOK!", Color3.fromRGB(255, 0, 0))
    AddLog("Tente usar um executor melhor ou PC.", Color3.fromRGB(255, 100, 100))
else
    AddLog("✅ ESCUTA ATIVA! Abra um baú...", Color3.fromRGB(0, 255, 0))
end


CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)