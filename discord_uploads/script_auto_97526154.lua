-- [[ HITBOX EXPANDER V1 ]] --
-- Aumenta a área de colisão dos seus ataques e dos inimigos (para farmar)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SizeMultiplier = 15 -- Tamanho da Hitbox (50 é gigante)

RunService.RenderStepped:Connect(function()
    -- Procura por Hitboxes no Workspace (baseado no seu log)
    for _, obj in pairs(Workspace:GetDescendants()) do
        -- O log mostrou: Workspace.MouseFilter.EffectsGeneral.Effects.Hitboxes
        if obj.Name == "Hitbox" or obj.Name == "KnifeLocker" then
            if obj:IsA("BasePart") then
                obj.Size = Vector3.new(SizeMultiplier, SizeMultiplier, SizeMultiplier)
                obj.Transparency = 0.7 -- Deixa visível pra você ver funcionando
                obj.Color = Color3.fromRGB(255, 0, 0)
                obj.CanCollide = false
            end
        end
        
        -- Opcional: Aumentar a hitbox dos monstros para acertar eles fácil
        if obj.Name == "HumanoidRootPart" and obj.Parent ~= Players.LocalPlayer.Character then
            obj.Size = Vector3.new(SizeMultiplier/2, SizeMultiplier/2, SizeMultiplier/2)
            obj.Transparency = 0.5
            obj.BrickColor = BrickColor.new("Really red")
        end
    end
end)