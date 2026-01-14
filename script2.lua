--[[ 
    OMNI-SCANNER MOBILE VERSION (DELTA OPTIMIZED)
    Target: Quest NPCs (Yellow/Red)
    Feature: GUI Toggle + Anti-Crash Limit
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- CONFIGURAÇÕES
local MAX_HIGHLIGHTS = 30 -- Deixa 1 de sobra para o limite da engine
local currentHighlights = 0

local TARGET_COLORS = {
    Yellow = Color3.fromRGB(255, 255, 0),
    Red = Color3.fromRGB(255, 0, 0) 
}

-- INTERFACE GRÁFICA (GUI) PARA CELULAR
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OmniScannerGUI"
-- Tenta colocar no CoreGui (protegido), se falhar, vai no PlayerGui
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 150, 0, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0) -- Canto superior esquerdo
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "SCANNER: OFF"
ToggleBtn.Parent = ScreenGui
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 18

-- ARREDONDAR BORDAS DO BOTÃO
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = ToggleBtn

-- ESTADO
local isScanning = false
local scannedCache = {} -- Cache para não processar o mesmo NPC 2 vezes

local function isColorMatch(color1, targetColor)
    local rDiff = math.abs(color1.R - targetColor.R)
    local gDiff = math.abs(color1.G - targetColor.G)
    local bDiff = math.abs(color1.B - targetColor.B)
    return (rDiff + gDiff + bDiff) < 0.2
end

local function removeESP()
    for _, instance in pairs(workspace:GetDescendants()) do
        if instance.Name == "RedTeamESP" then
            instance:Destroy()
        end
    end
    currentHighlights = 0
    scannedCache = {}
end

local function applyESP(model, color)
    if currentHighlights >= MAX_HIGHLIGHTS then return end
    if model:FindFirstChild("RedTeamESP") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "RedTeamESP"
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model
    
    currentHighlights = currentHighlights + 1
end

local function scanObject(obj)
    if not isScanning then return end
    if scannedCache[obj] then return end -- Já verificado

    if obj:IsA("Model") and obj:FindFirstChild("Head") then
        scannedCache[obj] = true -- Marca como verificado
        local head = obj.Head
        
        for _, desc in pairs(head:GetDescendants()) do
            if desc:IsA("BillboardGui") then
                local imageLabel = desc:FindFirstChildWhichIsA("ImageLabel")
                if imageLabel then
                    local iconColor = imageLabel.ImageColor3
                    
                    if isColorMatch(iconColor, TARGET_COLORS.Red) then
                        applyESP(obj, TARGET_COLORS.Red)
                    elseif isColorMatch(iconColor, TARGET_COLORS.Yellow) then
                        applyESP(obj, TARGET_COLORS.Yellow)
                    end
                end
            end
        end
    end
end

-- LÓGICA DO BOTÃO
ToggleBtn.MouseButton1Click:Connect(function()
    isScanning = not isScanning
    
    if isScanning then
        ToggleBtn.Text = "SCANNER: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Verde
        
        -- Scan Inicial
        for _, object in pairs(workspace:GetDescendants()) do
            scanObject(object)
        end
    else
        ToggleBtn.Text = "SCANNER: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0) -- Vermelho
        removeESP()
    end
end)

-- AUTO-SCAN (Novos objetos)
workspace.DescendantAdded:Connect(function(descendant)
    if isScanning then
        task.delay(1, function() -- Delay para carregar propriedades
            scanObject(descendant)
        end)
    end
end)
