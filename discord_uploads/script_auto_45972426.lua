--[[
    📱 SAO PROXIMITY SCANNER (DELTA/MOBILE)
    
    OBJETIVO: Descobrir o nome do Portal ficando perto dele.
    USO: Encoste no objeto e clique em ESCANEAR.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP (OTIMIZADO PARA MOBILE) //
if CoreGui:FindFirstChild("ProxScanUI") then CoreGui.ProxScanUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ProxScanUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0) -- Centralizado
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Laranja Scanner
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true -- Delta permite arrastar

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "📡 SCANNER DE PERTO"
Title.TextColor3 = Color3.fromRGB(255, 100, 0)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local ListScroll = Instance.new("ScrollingFrame", MainFrame)
ListScroll.Size = UDim2.new(0.9, 0, 0.65, 0)
ListScroll.Position = UDim2.new(0.05, 0, 0.15, 0)
ListScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ListScroll.CanvasSize = UDim2.new(0,0,0,0)

local UIList = Instance.new("UIListLayout", ListScroll)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
ScanBtn.Text = "ESCANEAR AQUI (RAIO 20m)"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
CloseBtn.TextColor3 = Color3.white

-- // VISUAIS //
local Highlights = {}

local function ClearList()
    for _, v in pairs(ListScroll:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    for _, h in pairs(Highlights) do h:Destroy() end
    Highlights = {}
end

local function AddItem(obj, dist)
    local lbl = Instance.new("TextLabel", ListScroll)
    lbl.Size = UDim2.new(1, 0, 0, 40)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.format("[%dm] %s\n(%s)", dist, obj.Name, obj.ClassName)
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextWrapped = true
    
    -- Highlight visual pra você saber quem é quem
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(255, 100, 0)
    hl.OutlineColor = Color3.white
    hl.FillTransparency = 0.5
    hl.Parent = CoreGui
    table.insert(Highlights, hl)
    
    -- Printa no console (F9) pra garantir
    print(">> FOUND: " .. obj:GetFullName())
end

-- // LÓGICA DE SCAN //
ScanBtn.MouseButton1Click:Connect(function()
    ClearList()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local myPos = char.HumanoidRootPart.Position
    local range = 20 -- Raio de 20 studs
    local found = 0
    
    -- Varre Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Só olha Modelos e Partes (ignora scripts, sons, etc)
        if (obj:IsA("Model") and obj.PrimaryPart) or (obj:IsA("BasePart") and not obj.Parent:IsA("Model")) then
            
            -- Calcula distância
            local pos = nil
            if obj:IsA("Model") then pos = obj.PrimaryPart.Position
            else pos = obj.Position end
            
            local dist = (myPos - pos).Magnitude
            
            if dist < range then
                -- Filtra coisas inúteis (chão, parede, partes do corpo)
                local name = obj.Name:lower()
                if not name:match("terrain") and not name:match("baseplate") and not obj:IsDescendantOf(char) then
                    AddItem(obj, math.floor(dist))
                    found = found + 1
                end
            end
        end
    end
    
    if found == 0 then
        local lbl = Instance.new("TextLabel", ListScroll)
        lbl.Size = UDim2.new(1, 0, 0, 30)
        lbl.Text = "Nada encontrado perto."
        lbl.TextColor3 = Color3.red
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ClearList()
    ScreenGui:Destroy()
end)