--[[ 
    RED TEAM TOOL: QUEST HUNTER v3 (Final)
    Alvo: Decals com ID 419749791
    Método: Filtragem por Cor (Color3)
]]

local TARGET_ID = "419749791" -- O ID que você capturou

-- Configuração de Cores (Margem de erro para cores não exatas)
local COLORS = {
    Yellow = {R=1, G=1, B=0},       -- Amarelo
    Red = {R=1, G=0, B=0},          -- Vermelho
    Blue = {R=0, G=0, B=1}          -- Azul (Apenas para debug se precisar)
}

local function isColorClose(c1, target)
    -- Verifica se a cor é parecida (margem de 20%)
    return (math.abs(c1.R - target.R) < 0.2) and 
           (math.abs(c1.G - target.G) < 0.2) and 
           (math.abs(c1.B - target.B) < 0.2)
end

local function applyHighlight(model, color, name)
    if model:FindFirstChild("QuestESP") then return end

    local h = Instance.new("Highlight")
    h.Name = "QuestESP"
    h.Adornee = model
    h.FillColor = color
    h.OutlineColor = Color3.new(1,1,1)
    h.FillTransparency = 0.3
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Vê através da parede
    h.Parent = model
    
    -- Aviso no console/chat local
    print(">>> ALVO LOCALIZADO: " .. name)
end

local function scanDecal(decal)
    -- Verifica se é o ID correto (contém o número 419749791)
    if string.find(tostring(decal.Texture), TARGET_ID) then
        local color = decal.Color3
        local parent = decal.Parent
        
        -- Se o pai for uma Part, queremos destacar o Modelo do NPC (o avô)
        local modelToHighlight = parent
        if parent.Parent and parent.Parent:IsA("Model") then
            modelToHighlight = parent.Parent
        end

        -- LÓGICA DE DETECÇÃO DE RARIDADE
        if isColorClose(color, Color3.new(1, 0, 0)) then
            -- É VERMELHO (LENDÁRIO)
            applyHighlight(modelToHighlight, Color3.new(1, 0, 0), "MISSÃO LENDÁRIA")
            
        elseif isColorClose(color, Color3.new(1, 1, 0)) or isColorClose(color, Color3.fromRGB(255, 255, 0)) then
            -- É AMARELO (RARA)
            applyHighlight(modelToHighlight, Color3.new(1, 1, 0), "MISSÃO RARA")
            
        elseif isColorClose(color, Color3.new(0, 0, 1)) or isColorClose(color, Color3.fromRGB(0, 0, 255)) then
            -- É AZUL (COMUM) - Descomente a linha abaixo se quiser ver as azuis também para testar
            -- applyHighlight(modelToHighlight, Color3.new(0, 0, 1), "Missão Comum")
        end
    end
end

-- Varredura Inicial
for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Decal") then
        scanDecal(v)
    end
end

-- Monitoramento em Tempo Real (Novos spawns)
workspace.DescendantAdded:Connect(function(v)
    task.wait(1) -- Espera carregar a textura
    if v:IsA("Decal") then
        scanDecal(v)
    end
end)

-- Interface simples para confirmar que rodou
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title = "Quest Hunter Ativado";
    Text = "Procurando Missões Raras e Lendárias...";
    Duration = 5;
})
