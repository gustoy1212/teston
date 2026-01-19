--[[
    🧬 ZOMBIE AUTOPSY (Raio-X de Estrutura)
    
    O que faz: 
    - Pega o modelo mais próximo de você.
    - Lista TODOS os objetos dentro dele (Filhos).
    - Revela onde fica a Vida e o RootPart.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function AnalyzeClosest()
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char.PrimaryPart.Position
    
    local closest = nil
    local minDist = 15 -- Raio curto (tem que estar perto)
    
    -- Varre o Workspace procurando Modelos
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
                end
            end
        end
    end
    
    -- RELATÓRIO DA AUTÓPSIA
    if closest then
        print("------------------------------------------------")
        print("🧟 ALVO ENCONTRADO: " .. closest.Name)
        print("📂 Localização: " .. closest:GetFullName())
        print("------------------------------------------------")
        print("🔍 LISTA DE ÓRGÃOS (Children):")
        
        for _, child in ipairs(closest:GetChildren()) do
            local valor = "N/A"
            if child:IsA("ValueBase") then valor = tostring(child.Value) end
            if child:IsA("Attribute") then valor = "Atributo" end
            
            print("   > [" .. child.ClassName .. "] " .. child.Name .. " | Valor: " .. valor)
            
            -- Se achar vida, avisa
            if string.find(string.lower(child.Name), "health") or string.find(string.lower(child.Name), "hp") then
                warn("   [!!!] POSSÍVEL VIDA ENCONTRADA AQUI ^^")
            end
        end
        print("------------------------------------------------")
        
        -- Checa Atributos (Sistema Moderno)
        local attrs = closest:GetAttributes()
        if next(attrs) then
            print("✨ ATRIBUTOS ENCONTRADOS:")
            for name, val in pairs(attrs) do
                print("   > " .. name .. ": " .. tostring(val))
            end
        else
            print("⚠️ Nenhum atributo encontrado.")
        end
        
        -- Marca ele pra você saber quem foi analisado
        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(0, 255, 255) -- Ciano
        hl.Parent = closest
        game.Debris:AddItem(hl, 3)
    else
        warn("❌ Nenhum zumbi perto! Chegue mais perto.")
    end
end

AnalyzeClosest()
