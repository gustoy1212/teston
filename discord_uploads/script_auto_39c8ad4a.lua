-- [[ OMNI-BLACKBOX: NETWORK & LOOT ANALYZER ]] --
-- Focado em Engenharia Reversa de Baús e Drops

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- UI SETUP
local ScreenName = "OmniBlackBox"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "⬛ OMNI-BLACKBOX (LOOT SPY)"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 0, 0)

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Aguardando..."
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1

-- VARIÁVEIS
local IsRecording = false
local CapturedLogs = {}
local StartTime = 0

-- FILTROS (Ignorar lixo para não travar o Delta)
local Ignored = {
    "CharacterSound", "Animation", "TouchInterest", "Move", "Camera", "Chat", "Bubble"
}

local function FormatTable(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            result = result .. tostring(k) .. "={...}, "
        else
            result = result .. tostring(k) .. "=" .. tostring(v) .. ", "
        end
    end
    return result .. "}"
end

local function Log(type, name, path, args)
    if not IsRecording then return end
    
    -- Filtro de Lixo
    for _, ignore in pairs(Ignored) do
        if name:find(ignore) or path:find(ignore) then return end
    end
    
    local timestamp = string.format("%.2f", tick() - StartTime)
    local argsStr = FormatTable(args)
    local entry = string.format("[%s] [%s] %s\n   Path: %s\n   Args: %s\n", timestamp, type, name, path, argsStr)
    
    table.insert(CapturedLogs, entry)
    Status.Text = "Capturados: " .. #CapturedLogs
end

-- 1. MONITORAR ENVIOS (CLIENT -> SERVER)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if IsRecording and (method == "FireServer" or method == "InvokeServer") then
        pcall(function()
            Log("OUT (Envio)", self.Name, self:GetFullName(), args)
        end)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- 2. MONITORAR RECEBIMENTOS (SERVER -> CLIENT) - ONDE ESTÁ O LOOT!
-- Varre todos os Remotes do jogo e conecta neles
local function HookRemotes(parent)
    for _, v in pairs(parent:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                if IsRecording then
                    Log("IN (Recebido)", v.Name, v:GetFullName(), {...})
                end
            end)
        end
    end
end

-- Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, 0, 0.3, 0)
BtnContainer.Position = UDim2.new(0, 0, 0.65, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, x, color, func)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.3, 0, 0.8, 0)
    btn.Position = UDim2.new(x, 0, 0.1, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(func)
end

CreateBtn("🔴 GRAVAR", 0.02, Color3.fromRGB(200, 0, 0), function()
    IsRecording = not IsRecording
    if IsRecording then
        StartTime = tick()
        CapturedLogs = {}
        Status.Text = "GRAVANDO... (Abra o Baú!)"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        -- Tenta conectar nos remotes para ouvir o servidor
        pcall(function() HookRemotes(ReplicatedStorage) end)
        pcall(function() HookRemotes(game:GetService("Workspace")) end)
    else
        Status.Text = "PAUSADO"
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

CreateBtn("💾 SALVAR", 0.35, Color3.fromRGB(0, 100, 200), function()
    if #CapturedLogs == 0 then return end
    local content = table.concat(CapturedLogs, "\n--------------------------------------------------\n")
    local fname = "blackbox_loot_" .. os.date("%H%M") .. ".txt"
    writefile(fname, content)
    Status.Text = "Salvo: " .. fname
    game.StarterGui:SetCore("SendNotification", {Title="LOG SALVO", Text=fname})
end)

CreateBtn("🗑️ LIMPAR", 0.68, Color3.fromRGB(100, 100, 100), function()
    CapturedLogs = {}
    Status.Text = "Limpo"
end)