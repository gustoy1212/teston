-- Script de Debug para ver os argumentos (Spy Simples)
local remote = game:GetService("ReplicatedStorage").Remotes.PlayerClickAttack

-- Isso vai interceptar quando VOCÊ clica e mostrar o que está sendo enviado
local original = remote.FireServer
remote.FireServer = function(self, ...)
    local args = {...}
    print("ARGS DO ATAQUE:", unpack(args))
    
    -- Se um dos argumentos for um número baixo (ex: 10, 50), é o dano!
    -- Se forem apenas Instances (como o monstro), é Server-Sided.
    
    return original(self, ...)
end