--[[
    🕵️‍♂️ NPC X-RAY SCANNER (SAFE MODE)
    
    OBJETIVO:
    - Encontrar o RemoteEvent escondido dentro do NPC de Quest.
    - Mostrar o caminho exato (Path) para você colocar no seu script.
    
    COMO USAR:
    1. Chegue PERTO do NPC de missão.
    2. Clique em "ESCANEAR PROXIMO".
    3. O script vai listar todos os Remotes dentro dele.
    4. Aperte F9 (Console) para copiar o caminho.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("XRayScanner") then CoreGui.XRayScanner:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XRayScanner"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja Spy
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

-- TÍTULO
local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕵️‍♂️ X-RAY SCANNER (No Hook)"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.Code
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.WHITE

-- LISTA DE RESULTADOS
local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(0.95, 0, 0.65, 0)
ScrollFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 5)

-- BOTÃO DE AÇÃO
local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
ScanBtn.Text = "🔍 ESCANEAR NPC MAIS PRÓXIMO"
ScanBtn.TextColor3 = Color3.BLACK
ScanBtn.Font = Enum.Font.GothamBold

-- // FUNÇÕES //

local function CreateLog(name, className, path)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.Parent = ScrollFrame

    local lblName = Instance.new("TextLabel", frame)
    lblName.Size = UDim2.new(1, -5, 0, 20)
    lblName.Position = UDim2.new(0, 5, 0, 0)
    lblName.Text = "Nome: " .. name .. " [" .. className .. "]"
    lblName.TextColor3 = Color3.fromRGB(0, 255, 255)
    lblName.TextXAlignment = Enum.TextXAlignment.Left
    lblName.BackgroundTransparency = 1
    lblName.Font = Enum.Font.GothamBold

    local lblPath = Instance.new("TextBox", frame) -- TextBox pra poder copiar
    lblPath.Size = UDim2.new(1, -10, 0, 20)
    lblPath.Position = UDim2.new(0, 5, 0, 25)
    lblPath.Text = path
    lblPath.TextColor3 = Color3.fromRGB(150, 150, 150)
    lblPath.TextXAlignment = Enum.TextXAlignment.Left
    lblPath.BackgroundTransparency = 1
    lblPath.ClearTextOnFocus = false
    lblPath.Font = Enum.Font.Code
    lblPath.TextEditable = false
end

local function GetPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return path
end

local function Scan()
    -- Limpa lista antiga
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end

    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char.PrimaryPart.Position

    -- Acha NPC mais perto
    local closestNPC = nil
    local minDist = 15 -- Só escaneia se estiver a 15 studs

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
            if v.PrimaryPart then
                local dist = (v.PrimaryPart.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestNPC = v
                end
            end
        end
    end

    if closestNPC then
        ScanBtn.Text = "ALVO: " .. closestNPC.Name
        print("--- ESCANEANDO NPC: " .. closestNPC.Name .. " ---")
        
        local found = false
        for _, child in pairs(closestNPC:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") then
                local fullPath = GetPath(child)
                CreateLog(child.Name, child.ClassName, fullPath)
                print("ACHEI: " .. fullPath)
                found = true
            end
        end
        
        if not found then
            CreateLog("Nada encontrado", "Info", "Esse NPC não tem Remotes visíveis.")
        end
    else
        ScanBtn.Text = "NENHUM NPC PRÓXIMO!"
        task.wait(1)
        ScanBtn.Text = "🔍 ESCANEAR NPC MAIS PRÓXIMO"
    end
end

ScanBtn.MouseButton1Click:Connect(Scan)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)