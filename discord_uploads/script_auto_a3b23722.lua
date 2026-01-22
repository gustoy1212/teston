-- [[ SOLO LEVELING: NECROMANCER V5 (CORRIGIDO) ]] --
-- Corrigido para ler "LEVANTAR-SE" e usar ProximityPrompt

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(100, 50, 255)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "🔮 AUTO LEVANTAR-SE"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(150, 100, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", Frame)
Status.Text = "Aguardando..."
Status.Position = UDim2.new(0, 0, 0.85, 0)
Status.Size = UDim2.new(1, 0, 0.15, 0)
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- CONFIG
local AriseEnabled = false   -- Levantar
local DestroyEnabled = false -- Destruir

-- [[ FUNÇÃO 1: TENTAR TUDO (PROMPT + GUI + REMOTE) ]] --
local function InteractWithDead(action)
    local count = 0
    
    -- 1. PROXIMITY PROMPTS (A aposta principal para E/R)
    -- Isso funciona globalmente se o jogo não checar distância no servidor
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local txt = prompt.ActionText:upper()
            local name = prompt.ObjectText:upper()
            
            -- Verifica se é o botão certo
            if (action == "levantar" and (txt:find("LEVANTAR") or txt:find("ARISE"))) or
               (action == "destruir" and (txt:find("DESTRUIR") or txt:find("EXTRACT"))) then
                
                -- Tenta disparar o prompt
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                    count = count + 1
                else
                    -- Fallback para executores fracos: teleporta e ativa
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root and prompt.Parent then
                        -- Teleporta rapidinho se precisar de distância
                        -- root.CFrame = prompt.Parent.CFrame 
                        prompt:InputHoldBegin()
                        task.wait()
                        prompt:InputHoldEnd()
                    end
                end
            end
        end
    end

    -- 2. BILLBOARD GUI (Botões Flutuantes Visuais)
    -- Procura o texto exato da sua imagem
    local targetText = (action == "levantar") and "LEVANTAR" or "DESTRUIR"
    
    for _, desc in pairs(Workspace:GetDescendants()) do
        if (desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextLabel")) and desc.Visible then
            local text = ""
            if desc:IsA("TextButton") or desc:IsA("TextLabel") then text = desc.Text:upper() end
            
            if text:find(targetText) then
                -- Se achou o texto, tenta clicar no pai (botão) ou no próprio
                local button = desc
                if not button:IsA("TextButton") and not button:IsA("ImageButton") then
                    button = desc:FindFirstAncestorWhichIsA("TextButton") or desc:FindFirstAncestorWhichIsA("ImageButton")
                end
                
                if button then
                    -- Simula clique
                    for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                        conn:Fire()
                    end
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- [[ LOOP AUTOMÁTICO ]] --
spawn(function()
    while true do
        if AriseEnabled then
            local n = InteractWithDead("levantar")
            if n > 0 then Status.Text = "Tentando Levantar: " .. n .. " sobras" end
        end
        
        if DestroyEnabled then
            local n = InteractWithDead("destruir")
            if n > 0 then Status.Text = "Tentando Destruir: " .. n .. " corpos" end
        end
        
        task.wait(0.5)
    end
end)

-- [[ BOTÕES ]] --
local BtnArise = Instance.new("TextButton", Frame)
BtnArise.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnArise.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnArise.Text = "AUTO LEVANTAR (SOMBRAS)"
BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnArise.TextColor3 = Color3.new(1,1,1)
BtnArise.Font = Enum.Font.GothamBold

BtnArise.MouseButton1Click:Connect(function()
    AriseEnabled = not AriseEnabled
    if AriseEnabled then
        BtnArise.Text = "PROCURANDO 'LEVANTAR'..."
        BtnArise.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
    else
        BtnArise.Text = "AUTO LEVANTAR (SOMBRAS)"
        BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local BtnDestroy = Instance.new("TextButton", Frame)
BtnDestroy.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnDestroy.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnDestroy.Text = "AUTO DESTRUIR ($$$)"
BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnDestroy.TextColor3 = Color3.new(1,1,1)
BtnDestroy.Font = Enum.Font.GothamBold

BtnDestroy.MouseButton1Click:Connect(function()
    DestroyEnabled = not DestroyEnabled
    if DestroyEnabled then
        BtnDestroy.Text = "PROCURANDO 'DESTRUIR'..."
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    else
        BtnDestroy.Text = "AUTO DESTRUIR ($$$)"
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)