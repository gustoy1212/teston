-- Configuração
local Remotes = game:GetService("ReplicatedStorage").Remotes
local AttackEvent = Remotes.PlayerClickAttack --  Baseado no seu log
local TargetRemote = Remotes.PlayerClickAttackSkill --  Alternativa

-- Ativa o modo "Metralhadora"
local isRunning = true

spawn(function()
    while isRunning do
        -- Tenta disparar o ataque básico insanamente rápido
        -- Nota: Alguns jogos kickam se for rápido demais, ajuste o wait()
        pcall(function()
            AttackEvent:FireServer() 
        end)
        task.wait() -- Sem delay (o mais rápido possível) ou coloque 0.1 para segurança
    end
end)