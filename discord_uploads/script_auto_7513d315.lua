--[[
    FORCE PROXIMITY ACTIVATOR
    Objetivo: Ativar qualquer [G] ou [E] num raio de 10 studs.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function ForceInteract()
    local char = LocalPlayer.Character
    if not char then return end
    local myPos = char.PrimaryPart.Position
    
    local found = false
    
    -- Varre o Workspace inteiro procurando ProximityPrompts
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            -- Checa se o prompt tem um Pai físico (Parte ou Modelo)
            local parent = v.Parent
            local promptPos = nil
            
            if parent:IsA("BasePart") then
                promptPos = parent.Position
            elseif parent:IsA("Model") and parent.PrimaryPart then
                promptPos = parent.PrimaryPart.Position
            end
            
            -- Se achou a posição e está perto (10 studs)
            if promptPos and (promptPos - myPos).Magnitude <= 12 then
                -- TENTA DISPARAR
                print("Tentando ativar: " .. v.Name .. " em " .. parent.Name)
                fireproximityprompt(v)
                found = true
            end
        end
    end
    
    if found then
        -- Cria um aviso na tela
        local sg = Instance.new("ScreenGui", game.CoreGui)
        local tl = Instance.new("TextLabel", sg)
        tl.Size = UDim2.new(0, 400, 0, 100)
        tl.Position = UDim2.new(0.5, -200, 0.2, 0)
        tl.Text = "✅ PROMPT ATIVADO! (Veja se a janela abriu)"
        tl.TextScaled = true
        tl.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(3)
        sg:Destroy()
    else
        warn("Nenhum prompt perto!")
    end
end

ForceInteract()