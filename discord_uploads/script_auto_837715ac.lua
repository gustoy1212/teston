--[[
    🖥️ UI DUMPER (Listar Botões)
    Objetivo: Mostrar o caminho de TUDO que é botão na sua tela agora.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

if CoreGui:FindFirstChild("UIDumper") then CoreGui.UIDumper:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UIDumper"
ScreenGui.Parent = CoreGui

local Scroll = Instance.new("ScrollingFrame", ScreenGui)
Scroll.Size = UDim2.new(0, 500, 0, 400)
Scroll.Position = UDim2.new(0.5, -250, 0.2, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIList = Instance.new("UIListLayout", Scroll)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Função pra pegar o caminho completo
local function GetPath(obj)
    local path = obj.Name
    local p = obj.Parent
    while p and p ~= game do
        path = p.Name .. "." .. path
        p = p.Parent
    end
    return path
end

-- Varre a GUI
for _, gui in pairs(PlayerGui:GetDescendants()) do
    if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
        local btn = Instance.new("TextBox", Scroll)
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.Text = "TEXTO: " .. (gui:IsA("TextButton") and gui.Text or "Image") .. " | NOME: " .. gui.Name
        btn.TextColor3 = Color3.fromRGB(0, 255, 255)
        btn.TextWrapped = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
        -- Quando clica na lista, copia o caminho
        btn.FocusLost:Connect(function()
            setclipboard(GetPath(gui))
            btn.Text = "COPIADO!"
            wait(1)
            btn.Text = "TEXTO: " .. (gui:IsA("TextButton") and gui.Text or "Image")
        end)
        
        -- Mostra o caminho também no console (F9)
        print("BOTÃO ACHADO: " .. GetPath(gui))
    end
end