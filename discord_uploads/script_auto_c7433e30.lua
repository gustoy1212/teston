--[[
    🎠 SAO PORTAL CAROUSEL (MOBILE FRIENDLY)
    
    SOLUÇÃO PARA EMULADOR:
    - Não gera listas gigantes.
    - Mostra um resultado por vez.
    - Copia textos curtos que não travam o clipboard.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // UI SETUP //
if CoreGui:FindFirstChild("PortalCarousel") then CoreGui.PortalCarousel:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PortalCarousel"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 200)
MainFrame.Position = UDim2.new(0.5, -175, 0.1, 0) -- Bem no topo pra não atrapalhar
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎠 CARROSSEL DE PORTAIS"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

-- Mostrador de Caminho
local PathBox = Instance.new("TextBox", MainFrame)
PathBox.Size = UDim2.new(0.9, 0, 0.3, 0)
PathBox.Position = UDim2.new(0.05, 0, 0.2, 0)
PathBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
PathBox.TextColor3 = Color3.fromRGB(255, 255, 0)
PathBox.Text = "Clique em VARRER para começar..."
PathBox.TextWrapped = true
PathBox.MultiLine = true
PathBox.ClearTextOnFocus = false
PathBox.Font = Enum.Font.Code
PathBox.TextSize = 12

-- Botões de Navegação
local PrevBtn = Instance.new("TextButton", MainFrame)
PrevBtn.Size = UDim2.new(0.2, 0, 0.2, 0)
PrevBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
PrevBtn.Text = "< ANT"
PrevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PrevBtn.TextColor3 = Color3.white

local NextBtn = Instance.new("TextButton", MainFrame)
NextBtn.Size = UDim2.new(0.2, 0, 0.2, 0)
NextBtn.Position = UDim2.new(0.75, 0, 0.55, 0)
NextBtn.Text = "PROX >"
NextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NextBtn.TextColor3 = Color3.white

local CountLabel = Instance.new("TextLabel", MainFrame)
CountLabel.Size = UDim2.new(0.5, 0, 0.2, 0)
CountLabel.Position = UDim2.new(0.25, 0, 0.55, 0)
CountLabel.Text = "0 / 0"
CountLabel.TextColor3 = Color3.white
CountLabel.BackgroundTransparency = 1

-- Botões de Ação
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
ScanBtn.Text = "VARRER MAPA"
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ScanBtn.TextColor3 = Color3.white
ScanBtn.Font = Enum.Font.GothamBold

local CopyBtn = Instance.new("TextButton", MainFrame)
CopyBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
CopyBtn.Position = UDim2.new(0.55, 0, 0.8, 0)
CopyBtn.Text = "COPIAR CAMINHO"
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
CopyBtn.TextColor3 = Color3.white
CopyBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // LÓGICA //
local FoundPortals = {}
local CurrentIndex = 1
local CurrentHighlight = nil

local function UpdateVisual(obj)
    -- Remove visual antigo
    if CurrentHighlight then CurrentHighlight:Destroy() end
    
    -- Cria novo visual (ESP)
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 0)
    hl.OutlineColor = Color3.white
    hl.Parent = CoreGui
    CurrentHighlight = hl
    
    -- Move a câmera pra olhar (Opcional, ajuda a achar)
    -- Workspace.CurrentCamera.CameraSubject = obj
end

local function UpdateUI()
    if #FoundPortals == 0 then
        PathBox.Text = "Nenhum portal encontrado."
        CountLabel.Text = "0 / 0"
        return
    end
    
    local entry = FoundPortals[CurrentIndex]
    PathBox.Text = entry.Path
    CountLabel.Text = CurrentIndex .. " / " .. #FoundPortals
    
    UpdateVisual(entry.Obj)
end

ScanBtn.MouseButton1Click:Connect(function()
    FoundPortals = {}
    CurrentIndex = 1
    if CurrentHighlight then CurrentHighlight:Destroy() end
    ScanBtn.Text = "VARRENDO..."
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- FILTRO: Só pega o que interessa
            if n:match("portal") or n:match("gate") or n:match("dungeon") or n:match("rank") then
                
                -- Salva na lista
                table.insert(FoundPortals, {
                    Name = obj.Name,
                    Path = obj:GetFullName(),
                    Obj = obj
                })
            end
        end
    end
    
    ScanBtn.Text = "VARRER MAPA"
    UpdateUI()
end)

NextBtn.MouseButton1Click:Connect(function()
    if CurrentIndex < #FoundPortals then
        CurrentIndex = CurrentIndex + 1
        UpdateUI()
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if CurrentIndex > 1 then
        CurrentIndex = CurrentIndex - 1
        UpdateUI()
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    if #FoundPortals > 0 then
        local txt = FoundPortals[CurrentIndex].Path
        -- Tenta copiar
        pcall(function() setclipboard(txt) end)
        -- Mostra visualmente que copiou
        CopyBtn.Text = "COPIADO!"
        PathBox.Text = "COPIADO: " .. txt
        task.wait(1)
        CopyBtn.Text = "COPIAR CAMINHO"
        PathBox.Text = txt
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    if CurrentHighlight then CurrentHighlight:Destroy() end
    ScreenGui:Destroy()
end)