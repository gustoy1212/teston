--[[
    📋 SAO PORTAL COPIER (CLIPBOARD SAFE)
    
    OBJETIVO: Copiar os caminhos dos portais sem travar o jogo.
    MÉTODO: Filtro rigoroso + Caixa de Texto editável na tela.
]]

local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- // GUI SETUP //
if CoreGui:FindFirstChild("PortalCopyUI") then CoreGui.PortalCopyUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PortalCopyUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📋 COPIADOR DE PORTAIS"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- A Caixa Mágica (Onde o texto vai ficar)
local ResultBox = Instance.new("TextBox", MainFrame)
ResultBox.Size = UDim2.new(0.9, 0, 0.65, 0)
ResultBox.Position = UDim2.new(0.05, 0, 0.12, 0)
ResultBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ResultBox.TextColor3 = Color3.fromRGB(200, 200, 200)
ResultBox.Font = Enum.Font.Code
ResultBox.TextSize = 12
ResultBox.TextXAlignment = Enum.TextXAlignment.Left
ResultBox.TextYAlignment = Enum.TextYAlignment.Top
ResultBox.TextWrapped = true
ResultBox.ClearTextOnFocus = false
ResultBox.MultiLine = true
ResultBox.Text = "Clique em ESCANEAR para buscar os portais..."

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
ScanBtn.Text = "ESCANEAR PORTAIS"
ScanBtn.TextColor3 = Color3.white
ScanBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
CloseBtn.TextColor3 = Color3.white

-- // LÓGICA DE SCAN //
ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text = "VARRENDO... (NÃO MEXA)"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    ResultBox.Text = "Varrendo..."
    
    local paths = {}
    local count = 0
    
    -- Varre devagar para não crashar
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if count % 200 == 0 then task.wait() end -- Pausa anti-crash
        count = count + 1
        
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            -- FILTRO ESTRITO (Só pega o que importa)
            if name:match("portal") or name:match("gate") or name:match("dungeon") or name:match("rank") then
                -- Verifica se tem alguma info de nível dentro pra confirmar que é portal
                local isPortal = false
                if name:match("rank") then isPortal = true end -- Se tem "rank" no nome, é quase certeza
                
                -- Salva o caminho
                table.insert(paths, "NOME: " .. obj.Name .. " | PATH: " .. obj:GetFullName())
            end
        end
    end
    
    -- Finaliza
    local finalString = table.concat(paths, "\n\n")
    
    if finalString == "" then
        finalString = "Nenhum portal encontrado com os nomes: Portal, Gate, Dungeon, Rank."
    end
    
    ResultBox.Text = finalString
    
    -- Tenta copiar automático
    pcall(function() setclipboard(finalString) end)
    
    ScanBtn.Text = "PRONTO! TENTE DAR CTRL+V"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)