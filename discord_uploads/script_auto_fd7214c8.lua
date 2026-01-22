-- [[ CHAOS MODE: CAMERA SHAKER ]] --
-- Tenta ativar efeitos visuais de câmera repetidamente

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Camera")

local SpammedRemotes = {
    "Earthquake",
    "BadTrip",   -- Esse deve ser divertido
    "Vibration",
    "RoughDriving"
}

getgenv().SpamActive = true -- Para parar, mude para false

task.spawn(function()
    while getgenv().SpamActive do
        for _, name in pairs(SpammedRemotes) do
            local remote = Remotes:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                -- Dispara o evento pro servidor (alguns jogos replicam pra todos)
                remote:FireServer(100, 100) -- Tentando força máxima
                remote:FireServer() -- Tentando sem argumentos
            end
        end
        task.wait(0.1) -- Velocidade do spam
    end
end)