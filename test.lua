--[[ 
    RED TEAM TOOL: MISSION SPY (COLETOR DE DADOS)
    Objetivo: Descobrir nome do Portal e dos Mobs para criar o Auto-Farm.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyTool"
if getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui() else ScreenGui.Parent = CoreGui end

local Frame = Instance.new("ScrollingFrame")
Frame.Size = UDim2.new(0, 350, 0, 300)
Frame.Position = UDim2.new(0.5, -175, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.Parent = ScreenGui

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 0, 1000)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
TextLabel.TextXAlignment = Enum.TextXAlignment.Left
TextLabel.TextYAlignment = Enum.TextYAlignment.Top
TextLabel.Font = Enum.Font.Code
TextLabel.TextSize = 14
TextLabel.Parent = Frame

local logText = "=== RELATÓRIO DE ESPIONAGEM ===\n\n"

local function log(str)
    logText = logText .. str .. "\n"
    TextLabel.Text = logText
end

-- 1. PROCURA O PORTAL / OBJETIVO
log("[1] PROCURANDO OBJETIVOS/PORTAIS:")
local foundObj = false
for _, obj in pairs(workspace:GetChildren()) do
    -- Procura coisas suspeitas que não são o mapa normal
    if obj:IsA("Model") or obj:IsA("Part") then
        local name = obj.Name:lower()
        if name:find("portal") or name:find("quest") or name:find("miss") or name:find("target") or name:find("arrow") then
            log(">> ACHEI POSSÍVEL ALVO: " .. obj.Name .. " (" .. obj.ClassName .. ")")
            foundObj = true
        end
    end
end
if not foundObj then log(">> Nenhum objeto com nome óbvio encontrado.") end

-- 2. PROCURA MOBS (INIMIGOS)
log("\n[2] PROCURANDO MOBS PRÓXIMOS:")
local myPos = Players.LocalPlayer.Character.HumanoidRootPart.Position

for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") and obj.Parent ~= Players.LocalPlayer.Character then
        local model = obj.Parent
        local root = model:FindFirstChild("HumanoidRootPart")
        
        if root and (root.Position - myPos).Magnitude < 50 then
            -- Verifica se não é outro player
            if not Players:GetPlayerFromCharacter(model) then
                log(">> MOB DETECTADO: " .. model.Name)
                log("   - Pai (Pasta): " .. (model.Parent and model.Parent.Name or "Workspace"))
                log("   - Vida: " .. obj.Health .. "/" .. obj.MaxHealth)
            end
        end
    end
end

-- 3. PROCURA SETAS GUI (GUI Arrows)
log("\n[3] GUI (SETAS NA TELA):")
for _, gui in pairs(Players.LocalPlayer.PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Enabled then
        if gui.Name ~= "SpyTool" and gui.Name ~= "Delta" then
             log(">> GUI Ativa: " .. gui.Name)
        end
    end
end
