-- [[ OMNI-SPY: COMBAT EDITION ]] --
-- Focado em descobrir os Argumentos de Ataque (Remote Spy)

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- UI SETUP
local ScreenName = "OmniSpyCombat"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 50) -- Roxo Hacker
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 0, 60)
Title.Text = "🕵️ OMNI-SPY: CAPTURADOR DE ATAQUES"
Title.TextColor3 = Color3.fromRGB(255, 100, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 16

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.15, 0)
Status.BackgroundTransparency = 1
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.TextSize = 14

-- Log Area
local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.55, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.25, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 0, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 5)

-- Lógica do Espião
local SpyEnabled = false
local CapturedRemotes = {}
local OriginalNamecall
local IgnoredRemotes = { -- Lista de coisas inúteis para filtrar
    "CharacterSoundEvent", "Sound", "Animation", "Touch", "Move", "Camera"
}

-- Formata a tabela de argumentos para texto legível
local function FormatArgs(args)
    local result = ""
    for i, v in pairs(args) do
        local valType = typeof(v)
        local valStr = tostring(v)
        
        if valType == "Instance" then
            valStr = v:GetFullName()
        elseif valType == "string" then
            valStr = '"' .. v .. '"'
        elseif valType == "table" then
            valStr = "{...}" -- Simplifica tabelas internas
        end
        
        result = result .. "\n   Arg["..i.."] ("..valType.."): " .. valStr
    end
    return result
end

-- Hook (O Grampo Telefônico)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if SpyEnabled and (method == "FireServer" or method == "InvokeServer") then
        local remoteName = self.Name
        
        -- Filtro Básico
        local isIgnored = false
        for _, ignore in pairs(IgnoredRemotes) do
            if remoteName:find(ignore) then isIgnored = true break end
        end
        
        if not isIgnored then
            -- Grava o Remote!
            local logEntry = "📡 REMOTE: " .. remoteName .. " | Path: " .. self:GetFullName()
            logEntry = logEntry .. FormatArgs(args)
            logEntry = logEntry .. "\n--------------------------------------------------"
            
            table.insert(CapturedRemotes, logEntry)
            
            -- Visual
            Status.Text = "Capturado: " .. remoteName
            local lbl = Instance.new("TextLabel", Scroll)
            lbl.Size = UDim2.new(1, 0, 0, 40)
            lbl.BackgroundTransparency = 1
            lbl.Text = remoteName
            lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
            lbl.TextSize = 12
        end
    end
    
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.85, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, pos, color, func)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.3, 0, 0.8, 0)
    btn.Position = UDim2.new(pos, 0, 0.1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(func)
end

CreateBtn("LIGAR ESPIÃO 👁️", 0.02, Color3.fromRGB(0, 150, 0), function()
    SpyEnabled = not SpyEnabled
    if SpyEnabled then 
        Status.Text = "🟢 GRAVANDO... (Bata em algo!)" 
        CapturedRemotes = {} -- Limpa anterior
    else 
        Status.Text = "🔴 PAUSADO" 
    end
end)

CreateBtn("SALVAR LOG 💾", 0.35, Color3.fromRGB(0, 100, 200), function()
    if #CapturedRemotes == 0 then return end
    local content = table.concat(CapturedRemotes, "\n")
    local fname = "combat_spy_" .. os.date("%H%M") .. ".txt"
    writefile(fname, content)
    Status.Text = "Salvo em: " .. fname
    game.StarterGui:SetCore("SendNotification", {Title="LOG SALVO", Text=fname, Duration=5})
end)

CreateBtn("LIMPAR 🗑️", 0.68, Color3.fromRGB(150, 50, 50), function()
    CapturedRemotes = {}
    for _,v in pairs(Scroll:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
    Status.Text = "Limpo."
end)