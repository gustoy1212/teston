--[[
    script modificado pra vc mano
    tenta usar ai e me fala, ajeitei aquela parada dele ficar travando nas parede
    e tbm pra ele nao ficar correndo atras de bixo la na pqp kkkk
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().Farming = true -- variavel pra desligar se precisar

-- config basica, mexe aqui se quiser mudar algo
local CONFIG = {
    DistAtaque = 6,         -- distancia pra bater
    DistCostas = 5,         -- distancia pra ficar nas costas (backstab)
    DistCorrer = 12,        -- se tiver longe ele corre
    RaioBusca = 300,        -- diminui aqui se ele tiver indo muito longe (era 3000, baixei pra 300 pra ele nao viajar)
    
    -- vida
    VidaBaixa = 25,  -- % pra fugir
    VidaCheia = 90, -- % pra voltar
    
    -- anti bug
    TempoTravado = 2.5 -- se ficar 2.5s parado tentando andar, ele troca de alvo
}

-- variaveis de controle (n precisa mexer)
local Estado = {
    Rodando = false,
    Correndo = false,
    Fugindo = false,
    AlvoAtual = nil,
    PosicaoAntiga = Vector3.new(0,0,0), -- pra checar se ta andando msm
    TempoParado = 0 -- contador de tempo travado
}

local ListaIgnorados = {} -- lista pros mobs bugados/parede invisivel

-- interfacezinha basica so pra controlar
if CoreGui:FindFirstChild("PainelFarm") then CoreGui.PainelFarm:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PainelFarm"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 130)
Frame.Position = UDim2.new(0.5, -125, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Active = true
Frame.Draggable = true

local LabelStatus = Instance.new("TextLabel", Frame)
LabelStatus.Size = UDim2.new(1, 0, 0, 30)
LabelStatus.Text = "status: esperando..."
LabelStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
LabelStatus.BackgroundTransparency = 1

local Botao = Instance.new("TextButton", Frame)
Botao.Size = UDim2.new(0.9, 0, 0.4, 0)
Botao.Position = UDim2.new(0.05, 0, 0.5, 0)
Botao.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
Botao.Text = "LIGAR FARM"
Botao.TextColor3 = Color3.fromRGB(255, 255, 255)

local Fechar = Instance.new("TextButton", Frame)
Fechar.Size = UDim2.new(0, 30, 0, 30)
Fechar.Position = UDim2.new(1, -30, 0, 0)
Fechar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Fechar.Text = "X"
Fechar.TextColor3 = Color3.fromRGB(255, 255, 255)

-- funcoes de ajuda

-- controla o sprint (ctrl)
local function ControlaSprint(ligar)
    if ligar and not Estado.Correndo then
        Estado.Correndo = true
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    elseif not ligar and Estado.Correndo then
        Estado.Correndo = false
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

local function Mover(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function Parar()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- ataque simulando toque na tela (melhor q click normal)
local function Atacar()
    local gui = LocalPlayer:WaitForChild("PlayerGui")
    -- tenta achar o botao mobile msm se tiver no pc
    if gui:FindFirstChild("DeviceGui") and gui.DeviceGui:FindFirstChild("Mobile") then
        local btn = gui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local x, y = pos.X + size.X/2, pos.Y + size.Y/2
            
            VirtualInputManager:SendTouchEvent(999, 0, x, y, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, x, y, 0, false, game, 1)
        end
    end
end

local function PegaArma()
    local char = LocalPlayer.Character
    if not char then return end
    if char:FindFirstChildOfClass("Tool") then return end -- ja ta com arma
    
    local mochila = LocalPlayer:FindFirstChild("Backpack")
    if mochila then
        local arma = mochila:FindFirstChildOfClass("Tool")
        if arma then char.Humanoid:EquipTool(arma) end
    end
end

-- botoes da ui
Fechar.MouseButton1Click:Connect(function()
    getgenv().Farming = false
    ControlaSprint(false)
    Parar()
    ScreenGui:Destroy()
end)

Botao.MouseButton1Click:Connect(function()
    Estado.Rodando = not Estado.Rodando
    if Estado.Rodando then
        Botao.Text = "PAUSAR"
        Botao.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ListaIgnorados = {} -- limpa a lista negra quando reinicia
    else
        Botao.Text = "VOLTAR"
        Botao.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        ControlaSprint(false)
        Parar()
        Estado.AlvoAtual = nil
    end
end)

-- loop principal (o cerebro do negocio)
spawn(function()
    while getgenv().Farming do
        task.wait(0.1)
        
        if Estado.Rodando then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            local raiz = char.HumanoidRootPart
            local hum = char.Humanoid
            local vidaAtual = (hum.Health / hum.MaxHealth) * 100

            if hum.Health <= 0 then
                LabelStatus.Text = "morreu kkk esperando..."
                Estado.AlvoAtual = nil
                Estado.Fugindo = false
                task.wait(4)
                return
            end

            PegaArma()

            -- logica de fugir se tiver morrendo
            if vidaAtual < CONFIG.VidaBaixa then Estado.Fugindo = true end
            
            if Estado.Fugindo then
                if vidaAtual >= CONFIG.VidaCheia then
                    Estado.Fugindo = false 
                    LabelStatus.Text = "vida cheia, voltando..."
                else
                    LabelStatus.Text = "fugindo pra curar..."
                    -- corre pra longe do mob mais perto
                    ControlaSprint(true)
                    -- logica simples de fuga: corre pra tras
                    if Estado.AlvoAtual then
                         local dir = (raiz.Position - Estado.AlvoAtual.HumanoidRootPart.Position).Unit
                         Mover(raiz.Position + (dir * 30))
                    else
                        -- se n tem alvo so para
                        Parar()
                    end
                end

            else
                -- SISTEMA ANTI PAREDE / TRAVAMENTO
                -- checa se a gente ta tentando andar mas n sai do lugar
                if Estado.AlvoAtual then
                    local distAndada = (raiz.Position - Estado.PosicaoAntiga).Magnitude
                    if distAndada < 0.5 then -- se moveu menos de 0.5 studs
                        Estado.TempoParado = Estado.TempoParado + 0.1
                    else
                        Estado.TempoParado = 0 -- ta andando de boa
                    end
                    Estado.PosicaoAntiga = raiz.Position
                    
                    -- se ficar travado mto tempo, ignora esse mob
                    if Estado.TempoParado > CONFIG.TempoTravado then
                        LabelStatus.Text = "travou na parede? trocando..."
                        table.insert(ListaIgnorados, Estado.AlvoAtual) -- adiciona na lista negra
                        Estado.AlvoAtual = nil
                        Estado.TempoParado = 0
                        Parar()
                        task.wait(0.2)
                    end
                end

                -- COMBATE
                if Estado.AlvoAtual then
                    local tHum = Estado.AlvoAtual:FindFirstChild("Humanoid")
                    local tRaiz = Estado.AlvoAtual:FindFirstChild("HumanoidRootPart")
                    
                    -- verifica se o bixo ainda existe e ta vivo
                    if not tHum or tHum.Health <= 0 or not tRaiz or not Estado.AlvoAtual.Parent then
                        Estado.AlvoAtual = nil
                        ControlaSprint(false)
                        Parar()
                    else
                        local dist = (raiz.Position - tRaiz.Position).Magnitude
                        
                        -- vai ate o bixo
                        if dist > CONFIG.DistCorrer then
                            ControlaSprint(true)
                            Mover(tRaiz.Position)
                        elseif dist > CONFIG.DistAtaque then
                            ControlaSprint(false)
                            Mover(tRaiz.Position)
                        else
                            -- chegou perto, tenta ir pras costas
                            local posCostas = tRaiz.CFrame * CFrame.new(0, 0, CONFIG.DistCostas)
                            if (raiz.Position - posCostas.Position).Magnitude > 2 then
                                ControlaSprint(true) 
                                Mover(posCostas.Position)
                            else
                                ControlaSprint(false)
                                Parar()
                                -- olha pro bixo
                                raiz.CFrame = CFrame.new(raiz.Position, Vector3.new(tRaiz.Position.X, raiz.Position.Y, tRaiz.Position.Z))
                            end
                            Atacar()
                        end
                    end
                    
                else
                    -- PROCURAR ALVO
                    LabelStatus.Text = "procurando bixo..."
                    local pastaMobs = Workspace:FindFirstChild("Mobs")
                    
                    if pastaMobs then
                        local melhorAlvo = nil
                        local menorDist = CONFIG.RaioBusca -- usa o raio maximo da config
                        
                        for _, mob in ipairs(pastaMobs:GetChildren()) do
                            -- so pega se nao tiver na lista de ignorados (bugados)
                            if not table.find(ListaIgnorados, mob) then
                                local mHum = mob:FindFirstChild("Humanoid")
                                local mRaiz = mob:FindFirstChild("HumanoidRootPart")
                                
                                if mHum and mRaiz and mHum.Health > 0 then
                                    local dist = (raiz.Position - mRaiz.Position).Magnitude
                                    
                                    -- logica simples: pega o mais perto e ja era
                                    -- tirei a prioridade de raros pq tava bugando mto longe
                                    if dist < menorDist then
                                        menorDist = dist
                                        melhorAlvo = mob
                                    end
                                end
                            end
                        end
                        
                        if melhorAlvo then 
                            Estado.AlvoAtual = melhorAlvo 
                            LabelStatus.Text = "alvo: " .. melhorAlvo.Name
                        else 
                            ControlaSprint(false) 
                            Parar() 
                            LabelStatus.Text = "nenhum bixo perto..."
                        end
                    end
                end
            end
        end
    end
end)