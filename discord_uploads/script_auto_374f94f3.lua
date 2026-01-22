--[[
    📜 SAO REMOTE LISTER (SAFE SCAN)
    
    OBJETIVO: Encontrar o "Carteiro" (RemoteEvent) que entrega os itens.
    MÉTODO: Varredura passiva (não quebra o jogo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- // GUI SETUP //
if CoreGui:FindFirstChild("RemoteListUI") then CoreGui.RemoteListUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "RemoteListUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📜 LISTA DE COMANDOS (REMOTES)"
Title.TextColor3 = Color3.fromRGB(100, 100, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local LogScroll = Instance.new("ScrollingFrame", MainFrame)
LogScroll.Size = UDim2.new(0.95, 0, 0.75, 0)
LogScroll.Position = UDim2.new(0.025, 0, 0.12, 0)
LogScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.CanvasSize = UDim2.new(0,0,0,0)

local LogLayout = Instance.new("UIListLayout", LogScroll)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(1, 0, 0.12, 0)
CloseBtn.Position = UDim2.new(0, 0, 0.88, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "FECHAR"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // FUNÇÃO DE LOG //
local function AddLog(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.Parent = LogScroll
    LogScroll.CanvasPosition = Vector2.new(0, 9999)
end

-- // SCANNER //
local function ScanRemotes()
    AddLog("🔍 INICIANDO VARREDURA...", Color3.fromRGB(255, 255, 0))
    local count = 0
    
    -- Função recursiva para olhar dentro de pastas
    local function Dig(folder)
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                local color = Color3.fromRGB(200, 200, 200) -- Cinza (Comum)
                
                -- Destaca nomes interessantes
                if name:match("chest") or name:match("bau") or name:match("reward") or name:match("loot") then
                    color = Color3.fromRGB(0, 255, 255) -- Ciano (Importante)
                    AddLog("💎 " .. obj.Name .. " ("..obj.ClassName..")", color)
                    AddLog("   Path: " .. obj:GetFullName(), Color3.fromRGB(100, 100, 100))
                elseif name:match("dungeon") or name:match("boss") or name:match("finish") then
                    color = Color3.fromRGB(255, 150, 0) -- Laranja (Dungeon)
                    AddLog("🔥 " .. obj.Name, color)
                end
                
                count = count + 1
            elseif obj:IsA("Folder") then
                Dig(obj) -- Olha dentro da pasta
            end
        end
    end
    
    Dig(ReplicatedStorage)
    
    if count == 0 then
        AddLog("⚠️ Nenhum Remote encontrado no ReplicatedStorage.", Color3.fromRGB(255, 0, 0))
    else
        AddLog("✅ Fim da varredura. " .. count .. " remotes achados.", Color3.fromRGB(0, 255, 0))
    end
end

-- Roda o scan ao abrir
ScanRemotes()

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)