--[[
    🪄 SAO WIZARD v2 (CUSTOM EQUIP FIX)
    
    CORREÇÃO:
    - Removeu a verificação de "Tool".
    - Agora escaneia o CHARACTER inteiro procurando o Remote de Dano.
    - Suporta sistemas de "Apertar Q" para equipar.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().SAOWizardV2 = true

-- // GUI SETUP //
if CoreGui:FindFirstChild("SAOWizardV2UI") then CoreGui.SAOWizardV2UI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SAOWizardV2UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 50)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🪄 WIZARD v2 (NO-TOOL)"
Title.TextColor3 = Color3.fromRGB(255, 50, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", MainFrame)
Status.Size = UDim2.new(1, 0, 0, 50)
Status.Position = UDim2.new(0, 0, 0.2, 0)
Status.Text = "Aperte Q e ligue..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextWrapped = true
Status.TextSize = 12

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 180)
ToggleBtn.Text = "LIGAR MAGIA (KILL)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold

-- // SCANNER DE REMOTE (GLOBAL) //
local function FindCombatRemotes()
    local remotes = {}
    local char = LocalPlayer.Character
    if not char then return {} end
    
    -- Procura no personagem inteiro (incluindo scripts e pastas internas)
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            -- Palavras-chave de combate
            if name:find("damage") or name:find("hit") or name:find("attack") or name:find("combat") or name:find("skill") or name:find("use") then
                table.insert(remotes, obj)
            end
        end
    end
    return remotes
end

-- // DISPARO //
local IsRunning = false

local function CastSpell()
    local combatRemotes = FindCombatRemotes()
    
    if #combatRemotes == 0 then
        Status.Text = "❌ Não achei Remotes no Personagem!\nVerifique se equipou (Q)."
        return
    end
    
    local folder = Workspace:FindFirstChild("Mobs")
    if not folder then return end
    
    local hitCount = 0
    
    for _, mob in ipairs(folder:GetChildren()) do
        local hum = mob:FindFirstChild("Humanoid")
        local root = mob:FindFirstChild("HumanoidRootPart")
        
        if hum and hum.Health > 0 and root then
            -- Dispara TODOS os remotes suspeitos contra o bicho
            for _, remote in ipairs(combatRemotes) do
                -- Tenta diferentes argumentos pra ver qual cola
                pcall(function() remote:FireServer(hum) end)
                pcall(function() remote:FireServer(mob) end)
                pcall(function() remote:FireServer(root) end)
                pcall(function() remote:FireServer(hum, 100) end)
            end
            hitCount = hitCount + 1
        end
    end
    
    Status.Text = "🔥 ATACANDO " .. hitCount .. " ALVOS\nUsando " .. #combatRemotes .. " Remotes"
end

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().SAOWizardV2 = false
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    IsRunning = not IsRunning
    if IsRunning then
        ToggleBtn.Text = "PARAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        spawn(function()
            while IsRunning and getgenv().SAOWizardV2 do
                CastSpell()
                task.wait(0.2) -- Um pouco mais lento pra não travar o jogo
            end
        end)
    else
        ToggleBtn.Text = "LIGAR MAGIA (KILL)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 180)
    end
end)