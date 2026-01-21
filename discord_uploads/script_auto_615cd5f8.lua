--[[
    🪄 SAO WIZARD v1 (REMOTE KILL)
    
    ESTRATÉGIA:
    - Não move o player.
    - Não move o mob.
    - Não move a espada.
    - Tenta disparar o evento de DANO diretamente no servidor.
    
    ALVO: Workspace.Mobs
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOWizard = true

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOWizardUI") then CoreGui.SAOWizardUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOWizardUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 40) -- Roxo Mago
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🪄 SAO WIZARD (REMOTE)"
Title.TextColor3 = Color3.fromRGB(255, 0, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Status: Aguardando..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextWrapped = true

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
ToggleBtn.Text = "LIGAR MAGIA (KILL ALL)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // LÓGICA DE DETECÇÃO DE REMOTE //
local function GetDamageRemote(tool)
    if not tool then return nil end
    
    -- 1. Procura Remotes dentro da ferramenta
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            -- Palavras comuns em RPGs
            if name:find("damage") or name:find("hit") or name:find("attack") or name:find("combat") or name:find("slash") or name:find("remote") then
                return obj
            end
        end
    end
    return nil
end

-- // LÓGICA DE DISPARO //
local IsRunning = false

local function CastSpell()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        Status.Text = "⚠️ EQUIPE A ESPADA!"
        return
    end
    
    local remote = GetDamageRemote(tool)
    if not remote then
        Status.Text = "❌ Não achei Remote na Espada!"
        -- Tenta buscar na ReplicatedStorage (alguns jogos guardam lá)
        -- Mas geralmente é dentro da Tool
        return
    end
    
    local folder = Workspace:FindFirstChild("Mobs")
    if not folder then return end
    
    local hitCount = 0
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and hum.Health > 0 and root then
            -- TENTA VÁRIOS ARGUMENTOS (BRUTE FORCE)
            -- Diferentes jogos pedem coisas diferentes
            
            -- Opção 1: Envia o Humanoide
            remote:FireServer(hum)
            
            -- Opção 2: Envia o Modelo do bicho
            remote:FireServer(mob)
            
            -- Opção 3: Envia a RootPart
            remote:FireServer(root)
            
            -- Opção 4: Argumentos padrão de RPG (Dano)
            remote:FireServer(hum, 100)
            
            hitCount = hitCount + 1
        end
    end
    
    Status.Text = "🔥 DISPARANDO EM: " .. hitCount .. " ALVOS\nRemote: " .. remote.Name
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOWizard = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        -- Loop de Disparo
        spawn(function()
            while IsRunning and getgenv().SAOWizard do
                CastSpell()
                task.wait(0.1) -- Velocidade do disparo (Cuidado pra não crashar)
            end
        end)
    else
        ToggleBtn.Text = "LIGAR MAGIA (KILL ALL)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
    end
end)