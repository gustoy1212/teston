--[[ 
    RED TEAM TOOL: ASSET PROBE
    Objetivo: Identificar o ID da textura da missão próxima
]]

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local found = false

print("--- INICIANDO SONDA DE ASSETS ---")

-- Varre tudo num raio de 15 studs
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") then
        -- Tenta achar o dono da GUI (Adornee ou Parent)
        local targetPart = obj.Adornee or obj.Parent
        
        if targetPart and targetPart:IsA("BasePart") then
            local dist = (targetPart.Position - root.Position).Magnitude
            
            if dist < 15 then -- Só pega o que estiver MUITO perto (15 studs)
                found = true
                print("\n[ALVO ENCONTRADO]: " .. targetPart:GetFullName())
                
                -- Procura a imagem dentro da GUI
                local img = obj:FindFirstChildWhichIsA("ImageLabel")
                if img then
                    print(" > NOME DA GUI: " .. obj.Name)
                    print(" > ID DA IMAGEM: " .. img.Image)
                    print(" > COR (RGB): " .. tostring(img.ImageColor3))
                    
                    -- Cria um alerta visual na tela pra confirmar que leu esse cara
                    local h = Instance.new("Highlight")
                    h.Parent = targetPart.Parent -- Tenta destacar o modelo
                    h.FillColor = Color3.new(0, 1, 0) -- Verde
                    h.DestroyOnRemove = true
                    game.Debris:AddItem(h, 2) -- Some depois de 2 segundos
                else
                    print(" > GUI encontrada, mas sem ImageLabel dentro.")
                end
            end
        end
    end
end

if not found then
    print("Nenhum NPC com missão encontrado perto de você. Chegue mais perto!")
end
print("---------------------------------")
