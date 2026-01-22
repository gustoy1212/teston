--[[
    🐗 JAVALI GIGANTE (HITBOX EXPANDER)
    Rodar este script junto com o seu Farm Normal.
    
    O QUE ELE FAZ:
    Aumenta o tamanho da área de colisão dos monstros. 
    Assim, seu boneco acerta o hit mesmo estando longe (parece Kill Aura, mas é Hitbox).
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local SETTINGS = {
    HitboxSize = 25,     -- Tamanho do monstro (25 é bem grande)
    Transparency = 0.7,  -- Transparência pra não atrapalhar a visão
    TargetFolder = "Mobs" -- Nome da pasta que vimos nos seus logs
}

-- Função que deixa o bicho gigante
local function ExpandHitbox(mob)
    local root = mob:FindFirstChild("HumanoidRootPart")
    local hum = mob:FindFirstChild("Humanoid")
    
    if root and hum and hum.Health > 0 then
        -- Desativa colisão pra vc não travar nele, mas mantém o tamanho pro hit
        root.CanCollide = false 
        root.Size = Vector3.new(SETTINGS.HitboxSize, SETTINGS.HitboxSize, SETTINGS.HitboxSize)
        root.Transparency = SETTINGS.Transparency
        root.Color = Color3.fromRGB(255, 0, 0) -- Fica vermelho pra vc ver que funcionou
    end
end

-- Loop Infinito (Super Rápido)
RunService.RenderStepped:Connect(function()
    local folder = Workspace:FindFirstChild(SETTINGS.TargetFolder)
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            ExpandHitbox(mob)
        end
    end
end)