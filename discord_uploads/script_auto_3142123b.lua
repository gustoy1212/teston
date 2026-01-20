--[[
    👑 AUTO QUEST MASTER v3
    
    FUNCIONALIDADES:
    - Teleporta para o NPC (Bypassa distância).
    - Auto Interage (G).
    - Auto Aceita (Clica no botão "Aceitar" sozinho).
    
    COMO USAR:
    - Mude o _G.TargetNPC para o nome do NPC que você quer.
]]

_G.TargetNPC = "Johnny" -- COLOQUE O NOME EXATO DO NPC AQUI
_G.AutoQuest = true     -- true para ligar, false para desligar

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Palavras-chave para o botão de aceitar (O script procura por isso)
local AcceptKeywords = {"Aceitar", "Accept", "Confirmar", "Confirm", "Yes", "Sim", "Start", "Começar"}

-- Função: Clica em botões de GUI
local function ClickButton(btn)
    local pos = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local center = Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
    
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
    print("✅ Botão clicado: " .. btn.Text)
end

-- Função: Procura o botão de aceitar na tela
local function TryAcceptGui()
    local gui = LocalPlayer:WaitForChild("PlayerGui")
    for _, v in pairs(gui:GetDescendants()) do
        if v:IsA("TextButton") and v.Visible then
            for _, keyword in pairs(AcceptKeywords) do
                if v.Text:lower():find(keyword:lower()) then
                    -- Achou um botão com texto "Aceitar" ou similar
                    ClickButton(v)
                    return true
                end
            end
        end
    end
    return false
end

-- Loop Principal
task.spawn(function()
    while _G.AutoQuest do
        task.wait(1) -- Intervalo de checagem
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        
        -- 1. Encontrar NPC e Prompt
        local targetPrompt = nil
        local targetPart = nil
        
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local parent = v.Parent
                -- Verifica se o Prompt pertence ao NPC escolhido
                if parent.Name == _G.TargetNPC or (parent.Parent and parent.Parent.Name == _G.TargetNPC) then
                    targetPrompt = v
                    -- Acha a parte física pra teleportar
                    if parent:IsA("BasePart") then
                        targetPart = parent
                    elseif parent:IsA("Model") then
                        targetPart = parent.PrimaryPart
                    end
                    break -- Achou, para de procurar
                end
            end
        end
        
        -- 2. Executar Ação
        if targetPrompt and targetPart then
            local dist = (char.HumanoidRootPart.Position - targetPart.Position).Magnitude
            
            -- Se estiver longe, teleporta (Segurança: Vai e volta rápido seria o ideal, mas aqui vamos só ir)
            if dist > 8 then
                char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
                task.wait(0.2) -- Espera carregar
            end
            
            -- Dispara o G
            fireproximityprompt(targetPrompt)
            task.wait(0.5) -- Espera a GUI abrir
            
            -- Tenta clicar no Aceitar
            if TryAcceptGui() then
                -- Se aceitou, espera um pouco mais pra não spammar
                task.wait(2)
            end
        else
            -- Se não achou o NPC, avisa no console (F9)
            -- print("NPC " .. _G.TargetNPC .. " não encontrado ou sem Prompt.")
        end
    end
end)