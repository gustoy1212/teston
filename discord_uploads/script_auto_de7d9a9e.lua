-- [[ SOLO LEVELING: NECROMANCER V6 (INFINITE RANGE) ]] --
-- Alcance Infinito + Wallhack de Botões + Auto Arise

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 320, 0, 220)
Frame.Position = UDim2.new(0.5, -160, 0.15, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Ciano Neon
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Text = "📡 NECROMANCER (GLOBAL RANGE)"
Title.Size = UDim2.new(1, 0, 0.2, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local Status = Instance.new("TextLabel", Frame)
Status.Text = "DICA: Ative o Imã do outro script para garantir!"
Status.Position = UDim2.new(0, 0, 0.85, 0)
Status.Size = UDim2.new(1, 0, 0.15, 0)
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- CONFIG
local AriseEnabled = false
local DestroyEnabled = false

-- [[ FUNÇÃO: EXTENSOR DE ALCANCE ]] --
local function BoostPrompts()
    -- Varre o mapa inteiro procurando prompts
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- HACK: Define o alcance para INFINITO
            prompt.MaxActivationDistance = 9e9 -- 9 bilhões de studs
            prompt.RequiresLineOfSight = false -- Pega através da parede
            prompt.HoldDuration = 0 -- Instante
        end
    end
end

-- [[ FUNÇÃO: ATIVADOR GLOBAL ]] --
local function ActivateGlobal(action)
    local count = 0
    
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local txt = prompt.ActionText:upper()
            local obj = prompt.ObjectText:upper()
            
            -- Verifica se é o botão certo
            -- Adicionei mais variações de nome para garantir
            local isArise = (txt:find("LEVANTAR") or txt:find("ARISE") or txt:find("ERGA") or txt:find("E"))
            local isDestroy = (txt:find("DESTRUIR") or txt:find("EXTRACT") or txt:find("R"))

            if (action == "levantar" and isArise) or (action == "destruir" and isDestroy) then
                
                -- Antes de ativar, garante que o alcance está infinito
                prompt.MaxActivationDistance = 9e9
                prompt.RequiresLineOfSight = false
                
                -- Tenta disparar
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                    count = count + 1
                else
                    -- Fallback: Teleporta a câmera ou o rootpart rapidinho
                    -- (Só usado se seu executor não suportar fireproximityprompt)
                    prompt:InputHoldBegin()
                    task.wait()
                    prompt:InputHoldEnd()
                end
            end
        end
    end
    return count
end

-- [[ LOOP ]] --
spawn(function()
    while true do
        -- Aplica o boost de alcance periodicamente (para prompts novos)
        if AriseEnabled or DestroyEnabled then
            BoostPrompts()
        end
        
        if AriseEnabled then
            local n = ActivateGlobal("levantar")
            if n > 0 then Status.Text = "Levantando: " .. n .. " sombras (Global)" end
        end
        
        if DestroyEnabled then
            local n = ActivateGlobal("destruir")
            if n > 0 then Status.Text = "Destruindo: " .. n .. " corpos (Global)" end
        end
        
        task.wait(0.2) -- Mais rápido agora
    end
end)

-- [[ BOTÕES ]] --
local BtnArise = Instance.new("TextButton", Frame)
BtnArise.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnArise.Position = UDim2.new(0.05, 0, 0.25, 0)
BtnArise.Text = "AUTO LEVANTAR (MAPA TODO)"
BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnArise.TextColor3 = Color3.new(1,1,1)
BtnArise.Font = Enum.Font.GothamBold

BtnArise.MouseButton1Click:Connect(function()
    AriseEnabled = not AriseEnabled
    if AriseEnabled then
        BtnArise.Text = "ESCANEANDO MAPA..."
        BtnArise.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    else
        BtnArise.Text = "AUTO LEVANTAR (MAPA TODO)"
        BtnArise.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)

local BtnDestroy = Instance.new("TextButton", Frame)
BtnDestroy.Size = UDim2.new(0.9, 0, 0.3, 0)
BtnDestroy.Position = UDim2.new(0.05, 0, 0.6, 0)
BtnDestroy.Text = "AUTO DESTRUIR (MAPA TODO)"
BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BtnDestroy.TextColor3 = Color3.new(1,1,1)
BtnDestroy.Font = Enum.Font.GothamBold

BtnDestroy.MouseButton1Click:Connect(function()
    DestroyEnabled = not DestroyEnabled
    if DestroyEnabled then
        BtnDestroy.Text = "ESCANEANDO MAPA..."
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    else
        BtnDestroy.Text = "AUTO DESTRUIR (MAPA TODO)"
        BtnDestroy.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end)