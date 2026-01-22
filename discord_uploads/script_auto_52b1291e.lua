--[[
    🚀 SAO DUNGEON SKIPPER v1 (INSTANT WIN TEST)
    
    ALVOS DESCOBERTOS: 
    - CompletedDungeon
    - ClearedDungeon
    
    OBJETIVO: Tentar finalizar a dungeon instantaneamente sem lutar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FUNÇÃO PARA ENCONTRAR OS REMOTES //
-- Como não sabemos a pasta exata, vamos caçar eles pelo nome
local function FindRemote(name)
    for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
        if descendant.Name == name and (descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction")) then
            return descendant
        end
    end
    return nil
end

-- // TENTATIVA DE INSTANT WIN //
local function InstantWin()
    print("🚀 TENTANDO VENCER DUNGEON...")
    
    local remote1 = FindRemote("CompletedDungeon")
    local remote2 = FindRemote("ClearedDungeon")
    local remote3 = FindRemote("FinishDungeon") -- Um chute comum
    
    if remote1 then
        print("🔥 Disparando: CompletedDungeon")
        if remote1:IsA("RemoteEvent") then remote1:FireServer() else remote1:InvokeServer() end
    end
    
    if remote2 then
        print("🔥 Disparando: ClearedDungeon")
        if remote2:IsA("RemoteEvent") then remote2:FireServer() else remote2:InvokeServer() end
    end
    
    if remote3 then
        print("🔥 Disparando: FinishDungeon")
        if remote3:IsA("RemoteEvent") then remote3:FireServer() else remote3:InvokeServer() end
    end
end

InstantWin()