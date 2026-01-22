-- [[ OMNI-SCANNER: DUNGEON CRAWLER EDITION ]] --
-- Focado em capturar a lógica de Mobs, Bosses, Baús e Itens

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. UI SETUP (Minimalista para não atrapalhar a visão)
local ScreenName = "OmniDungeonScan"
if CoreGui:FindFirstChild(ScreenName) then CoreGui[ScreenName]:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ScreenName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Position = UDim2.new(0.5, -200, 0.1, 0) -- Fica no topo para não atrapalhar
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 170, 0) -- Laranja Lendário
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
Title.Text = "🗡️ DUNGEON SCANNER"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.Code
Title.TextSize = 14

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.15, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Aguardando início..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12

-- Container Botões
local BtnContainer = Instance.new("Frame", MainFrame)
BtnContainer.Size = UDim2.new(1, -10, 0.25, 0)
BtnContainer.Position = UDim2.new(0, 5, 0.70, 0)
BtnContainer.BackgroundTransparency = 1

local function CreateBtn(text, pos, color, callback)
    local btn = Instance.new("TextButton", BtnContainer)
    btn.Size = UDim2.new(0.32, 0, 1, 0)
    btn.Position = UDim2.new((pos-1)*0.34, 0, 0, 0)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- LÓGICA DO SISTEMA
local LogHistory = {}
local IsScanning = false
local Connection = nil

-- Filtro do que é LIXO (O que vamos ignorar)
local function IsGarbage(obj)
    local name = obj.Name:lower()
    local class = obj.ClassName
    
    -- Ignora efeitos visuais puros
    if class == "Beam" or class == "Trail" or class == "ParticleEmitter" or class == "SpotLight" or class == "PointLight" then return true end
    if class == "Sound" or class == "Weld" or class == "Snap" or class == "Motor6D" then return true end
    
    -- Ignora partes de cenário que não são interativas
    if (class == "MeshPart" or class == "Part" or class == "WedgePart") and not obj:FindFirstChild("ProximityPrompt") and not obj:FindFirstChild("TouchInterest") then
        -- Mas deixa passar se tiver nome suspeito de item
        if not (name:find("handle") or name:find("drop") or name:find("box")) then
            return true 
        end
    end
    
    -- Ignora nomes comuns de lixo
    if name:find("debris") or name:find("bullet") or name:find("smoke") or name:find("blood") or name:find("raycast") then return true end
    
    return false
end

-- Classificador (Tenta descobrir o que é)
local function GetTag(obj)
    if obj:FindFirstChild("Humanoid") then return "[MOB/NPC]" end
    if obj:IsA("Tool") then return "[ITEM/TOOL]" end
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then return "[REMOTE]" end
    if obj:FindFirstChild("ProximityPrompt") then return "[INTERAGIR]" end
    if obj.Name:lower():find("chest") or obj.Name:lower():find("bau") or obj.Name:lower():find("box") then return "[BAÚ]" end
    return "[NEW]"
end

local function AddLog(obj)
    if IsGarbage(obj) then return end -- Filtra o lixo
    
    local tag = GetTag(obj)
    local timestamp = os.date("%X")
    local path = obj:GetFullName()
    
    -- Formatação bonita para o log
    local logLine = string.format("%s %s -> %s (%s)", timestamp, tag, obj.Name, path)
    
    table.insert(LogHistory, logLine)
    StatusLabel.Text = "Itens capturados: " .. #LogHistory
end

-- Iniciar Scan
local function ToggleScan()
    IsScanning = not IsScanning
    if IsScanning then
        LogHistory = {} -- Limpa o histórico antigo
        StatusLabel.Text = "🟢 GRAVANDO SESSÃO..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        
        -- Monitora Workspace (Mobs, Drops, Baús)
        Connection = Workspace.DescendantAdded:Connect(function(descendant)
            task.wait() -- Espera carregar propriedades
            pcall(function() AddLog(descendant) end)
        end)
        
        -- Adiciona log inicial
        table.insert(LogHistory, "--- INÍCIO DA SESSÃO: " .. os.date("%c") .. " ---")
        
    else
        StatusLabel.Text = "🔴 PAUSADO"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        if Connection then Connection:Disconnect() end
    end
end

-- Salvar Log
local function SaveLog()
    if #LogHistory == 0 then return end
    
    local content = table.concat(LogHistory, "\n")
    local filename = "dungeon_log_" .. os.date("%H%M") .. ".txt"
    
    local success, err = pcall(function()
        writefile(filename, content)
    end)
    
    if success then
        StatusLabel.Text = "✅ Salvo: " .. filename
        game.StarterGui:SetCore("SendNotification", {
            Title = "LOG SALVO!";
            Text = "Arquivo: " .. filename;
            Duration = 5;
        })
    else
        StatusLabel.Text = "❌ Erro ao salvar"
        warn(err)
    end
end

-- Limpar
local function Clear()
    LogHistory = {}
    StatusLabel.Text = "🗑️ Memória Limpa"
end

-- Botoes
CreateBtn("GRAVAR (ON/OFF) 🔴", 1, Color3.fromRGB(200, 50, 50), ToggleScan)
CreateBtn("SALVAR LOG 💾", 2, Color3.fromRGB(50, 150, 200), SaveLog)
CreateBtn("LIMPAR 🗑️", 3, Color3.fromRGB(100, 100, 100), Clear)