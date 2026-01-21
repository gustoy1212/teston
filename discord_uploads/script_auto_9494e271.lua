--[[
    🔬 BIO-SCANNER v1 (ANALISADOR DE PERSONAGEM)
    
    OBJETIVO: Identificar como o ataque funciona (Tool, Animation ou Script).
    USO: Equipe a espada, ataque o ar e clique em ESCANEAR.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("BioScannerUI") then CoreGui.BioScannerUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "BioScannerUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🔬 BIO-SCANNER v1"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local ResultsBox = Instance.new("ScrollingFrame", MainFrame)
ResultsBox.Size = UDim2.new(0.9, 0, 0.7, 0)
ResultsBox.Position = UDim2.new(0.05, 0, 0.1, 0)
ResultsBox.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
ResultsBox.CanvasSize = UDim2.new(0, 0, 5, 0) -- Espaço pra rolar

local ResultsText = Instance.new("TextLabel", ResultsBox)
ResultsText.Size = UDim2.new(1, -10, 1, 0)
ResultsText.Position = UDim2.new(0, 5, 0, 0)
ResultsText.BackgroundTransparency = 1
ResultsText.TextColor3 = Color3.fromRGB(0, 255, 0)
ResultsText.TextXAlignment = Enum.TextXAlignment.Left
ResultsText.TextYAlignment = Enum.TextYAlignment.Top
ResultsText.Font = Enum.Font.Code
ResultsText.TextSize = 12
ResultsText.Text = "Instruções:\n1. Equipe a Espada (Q).\n2. Comece a atacar o ar.\n3. Clique em ESCANEAR."

local ScanBtn = Instance.new("TextButton", MainFrame)
ScanBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
ScanBtn.Position = UDim2.new(0.05, 0, 0.82, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
ScanBtn.Text = "ESCANEAR AGORA"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- // LÓGICA DE SCAN //
ScanBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then ResultsText.Text = "Erro: Personagem não encontrado!" return end
    
    local hum = char:FindFirstChild("Humanoid")
    local report = "=== RELATÓRIO DO PERSONAGEM ===\n"
    
    -- 1. VERIFICA O QUE TEM NA MÃO (EQUIPAMENTO)
    report = report .. "\n[1] EQUIPAMENTO:\n"
    local foundTool = false
    
    -- Procura Tool Padrão
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        foundTool = true
        report = report .. "• TIPO: Tool (Padrão Roblox)\n"
        report = report .. "• NOME: " .. tool.Name .. "\n"
        if tool:FindFirstChild("Handle") then
            report = report .. "• TEM HANDLE: Sim\n"
        else
            report = report .. "• TEM HANDLE: Não (Custom)\n"
        end
        
        -- Procura Scripts dentro da Tool
        for _, obj in ipairs(tool:GetChildren()) do
            if obj:IsA("LocalScript") or obj:IsA("Script") then
                report = report .. "  -> SCRIPT: " .. obj.Name .. "\n"
            end
        end
    else
        report = report .. "• Tool padrão: NÃO ENCONTRADA.\n(Provavelmente é um Model soldado)\n"
        
        -- Procura Modelos estranhos no char
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Animate" then
                report = report .. "• MODELO SUSPEITO: " .. obj.Name .. "\n"
            end
        end
    end

    -- 2. VERIFICA ANIMAÇÕES TOCANDO (O SEGREDO)
    report = report .. "\n[2] ANIMAÇÕES ATIVAS:\n"
    if hum then
        local tracks = hum:GetPlayingAnimationTracks()
        if #tracks > 0 then
            for _, track in ipairs(tracks) do
                -- Filtra animações inúteis (idle, run, walk)
                local name = track.Animation.AnimationId
                report = report .. "• ID: " .. name .. "\n"
                report = report .. "  Speed: " .. track.Speed .. " | Time: " .. math.floor(track.TimePosition*10)/10 .. "\n"
            end
        else
            report = report .. "Nenhuma animação rodando.\n(DICA: Ataque ENQUANTO clica em escanear!)\n"
        end
    end
    
    -- 3. VERIFICA SCRIPTS NO PERSONAGEM
    report = report .. "\n[3] SCRIPTS LOCAIS:\n"
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("LocalScript") then
            report = report .. "• " .. obj.Name .. "\n"
        end
    end
    
    ResultsText.Text = report
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)