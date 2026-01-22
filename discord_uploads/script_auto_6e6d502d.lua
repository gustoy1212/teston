-- SERVIÇOS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- 1. CRIAR A INTERFACE VISUAL (GUI)
local ScreenGui = Instance.new("ScreenGui")
if gethui then
    ScreenGui.Parent = gethui() -- Proteção moderna (se o Delta suportar)
else
    ScreenGui.Parent = CoreGui -- Fallback clássico
end
ScreenGui.Name = "SpyVisua_Log"

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Name = "Logs"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.2
MainFrame.Position = UDim2.new(0.5, -150, 0.1, 0) -- No meio, topo
MainFrame.Size = UDim2.new(0, 300, 0, 200) -- Tamanho da janela
MainFrame.CanvasSize = UDim2.new(0, 0, 10, 0) -- Espaço para scrollar
MainFrame.ScrollBarThickness = 8

local Title = Instance.new("TextLabel")
Title.Parent = ScreenGui
Title.Text = "LOG DE ATAQUES (Spy)"
Title.Position = UDim2.new(0.5, -150, 0.05, 0)
Title.Size = UDim2.new(0, 300, 0, 20)
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.BackgroundTransparency = 1

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Função para escrever na tela
function LogToScreen(text)
    local Label = Instance.new("TextLabel")
    Label.Parent = MainFrame
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = " > " .. text
    Label.TextScaled = true
    
    -- Auto-scroll para baixo
    MainFrame.CanvasPosition = Vector2.new(0, 9999)
end

LogToScreen("Iniciado! Ataque para ver logs...")

-- 2. O HOOK (O Espião)
local remoteAlvo = ReplicatedStorage.Remotes.PlayerClickAttack -- O alvo principal

local original
original = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    -- Verifica se é o evento de ataque
    if self == remoteAlvo and method == "FireServer" then
        
        -- Transforma os argumentos em texto para ler
        local logText = ""
        for i, v in pairs(args) do
            logText = logText .. "[" .. typeof(v) .. "] " .. tostring(v) .. " | "
        end
        
        -- Manda para a tela
        LogToScreen(logText)
    end

    return original(self, ...)
end)