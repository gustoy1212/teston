--[[
    💎 SAO AUTO LOOT (INSTANT CLAIM)
    
    ALVOS CONFIRMADOS:
    - ClaimAvailableChests (RemoteFunction)
    - OpenChest (RemoteFunction)
    
    OBJETIVO: Pegar todos os baús instantaneamente ao matar o Boss.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

getgenv().AutoLoot = true

-- Caçador de Remotes
local function FindRemote(name)
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == name then return d end
    end
    return nil
end

local ClaimRemote = FindRemote("ClaimAvailableChests")
local OpenRemote = FindRemote("OpenChest")

if not ClaimRemote and not OpenRemote then
    warn("⚠️ Remotes de Loot não encontrados!")
else
    print("💎 AUTO LOOT ATIVADO! Mate o Boss e relaxe.")
end

spawn(function()
    while getgenv().AutoLoot do
        task.wait(0.5) -- Verifica a cada meio segundo
        
        -- TENTA PEGAR TUDO DE UMA VEZ
        if ClaimRemote then
            pcall(function()
                if ClaimRemote:IsA("RemoteFunction") then
                    ClaimRemote:InvokeServer()
                else
                    ClaimRemote:FireServer()
                end
            end)
        end
        
        -- SE TIVER QUE ABRIR UM POR UM (BACKUP)
        if OpenRemote then
            -- Aqui precisaríamos saber o ID do baú, então o ClaimAvailableChests é melhor.
            -- Mas deixo preparado caso o Claim falhe.
        end
    end
end)