--[[ 
    RED TEAM TOOL: GOLDEN HUNTER (FINAL VERSION)
    Alvo Confirmado: ID 134433042638721 (Amarela)
    Estratégia: Busca exata de ID de textura com alcance global.
]]

local Players = game:GetService("Players")

-- ================= CONFIGURAÇÃO DE ALVOS =================
local IDS = {
    -- ID DA AZUL (COMUM) - Capturado no seu print
    ["74232140704943"] = "BLUE",

    -- ID DA AMARELA (RARA) - Confirmado em 2 prints seus
    ["134433042638721"] = "YELLOW",
    
    -- ID DA VERMELHA (LENDÁRIA) - Substitua quando descobrir
    ["ID_DA_VERMELHA_AQUI"] = "RED" 
}
-- =========================================================

local function cleanID(str)
    -- Limpa o link (rbxassetid://...) e pega só os números
    return tostring(str):match("%d+") or "NIL"
end

local function applyESP(model, color, text)
    if model:FindFirstChild("RedTeamESP") then return end

    -- 1. Highlight (Brilho através da parede)
    local h = Instance.new("Highlight")
    h.Name = "RedTeamESP"
    h.Adornee = model
    h.FillColor = color
    h.OutlineColor = Color3.new(0,0,0)
    
    -- Configuração de Visibilidade
    if color == Color3.fromRGB(255, 215, 0) or color == Color3.fromRGB(255, 0, 0) then
        h.FillTransparency = 0.2 -- Bem visível para Raras/Lendárias
        h.OutlineTransparency = 0
    else
        h.FillTransparency = 0.8 -- Quase invisível para Azuis (para não poluir)
        h.OutlineTransparency = 0.5
    end
    
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = model

    -- 2. Placa de Texto (Info)
    local bg = Instance.new("BillboardGui")
    bg.Name = "RedTeamInfo"
    bg.Adornee = model:FindFirstChild("Head") or model.PrimaryPart
    bg.Size = UDim2.new(0, 200, 0, 70)
    bg.StudsOffset = Vector3.new(0, 6, 0) -- Bem alto
    bg.AlwaysOnTop = true
    bg.Parent = h

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0 -- Borda preta
    tl.TextColor3 = color
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 18
    tl.Text = text
    tl.Parent = bg
end

local function scanImage(imgObject, model)
    local rawID = imgObject.Image
    local id = cleanID(rawID)
    
    if IDS[id] == "YELLOW" then
        -- É A RARA!
        applyESP(model, Color3.fromRGB(255, 215, 0), "★ RARA ★")
        return true
        
    elseif IDS[id] == "RED" then
        -- É A LENDÁRIA (Se você tiver colocado o ID)
        applyESP(model, Color3.fromRGB(255, 0, 0), "!!! LENDÁRIA !!!")
        return true
        
    elseif IDS[id] == "BLUE" then
        -- É AZUL (Marca discreto)
        applyESP(model, Color3.fromRGB(0, 100, 255), "Comum")
        return true
        
    elseif id ~= "NIL" and id ~= "0" then
        -- ID DESCONHECIDO (Provavelmente a VERMELHA que ainda não temos o número)
        applyESP(model, Color3.fromRGB(255, 0, 0), "!!! NOVO ID !!!\n" .. id)
        return true
    end
    return false
end

-- SCANNER LOOP INFINITO (RANGE MÁXIMO)
task.spawn(function()
    while task.wait(1) do -- Verifica a cada 1 segundo
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Procura o container "Quest Simbol"
            if obj.Name == "Quest Simbol" then
                local parent = obj.Parent
                local model = parent and parent.Parent
                
                if model and model:IsA("Model") and not model:FindFirstChild("RedTeamESP") then
                    -- Revira o Quest Simbol procurando a imagem com o ID
                    local found = false
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            if scanImage(child, model) then 
                                found = true 
                                break 
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Notificação de Sucesso
game.StarterGui:SetCore("SendNotification", {
    Title = "Golden Hunter Ativo";
    Text = "Filtrando ID 134433042638721...";
    Duration = 5;
})
