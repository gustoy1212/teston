--[[
    script v4 - o retorno do range alto
    aumentei o raio de busca pra 5000 pra ele nao ficar parado na base
    mas mantive o sistema de fuga inteligente e o anti-parede
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager") 
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

getgenv().Farming = true 

local CONFIG = {
    DistAtaque = 6,
    DistCostas = 5,
    DistCorrer = 12,
    
    -- AUMENTEI AQUI PRA ELE NAO FICAR PARADO
    RaioBusca = 5000, -- tava 300, botei 5k pra ele enxergar longe
    
    -- vida
    VidaBaixa = 25,  
    VidaCheia = 90, 
    DistSeguranca = 50, -- distancia pra se sentir seguro
    
    -- anti bug
    TempoTravado = 2.5 
}

local Estado = {
    Rodando = false,
    Correndo = false,
    Fugindo = false,
    AlvoAtual = nil,
    PosicaoAntiga = Vector3.new(0,0,0), 
    TempoParado = 0 
}

local ListaIgnorados = {} 

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

local function Atacar()
    local gui = LocalPlayer:WaitForChild("PlayerGui")
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
    if char:FindFirstChildOfClass("Tool") then return end
    
    local mochila = LocalPlayer:FindFirstChild("Backpack")
    if mochila then
        local arma = mochila:FindFirstChildOfClass("Tool")
        if arma then char.Humanoid:EquipTool(arma) end
    end
end

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
        ListaIgnorados = {}
    else
        Botao.Text = "VOLTAR"
        Botao.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        ControlaSprint(false)
        Parar()
        Estado.AlvoAtual = nil
    end
end)

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

            -- LOGICA DE FUGA (CHECK GERAL)
            if vidaAtual < CONFIG.VidaBaixa then Estado.Fugindo = true end
            
            if Estado.Fugindo then
                if vidaAtual >= CONFIG.VidaCheia then
                    Estado.Fugindo = false 
                    LabelStatus.Text = "vida cheia, voltando..."
                else
                    -- Procura ameaças num raio curto pra fugir
                    local perigoMaisPerto = nil
                    local distPerigo = 9999
                    local pastaMobs = Workspace:FindFirstChild("Mobs")
                    
                    if pastaMobs then
                        for _, mob in ipairs(pastaMobs:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRaiz = mob:FindFirstChild("HumanoidRootPart")
                            if mHum and mRaiz and mHum.Health > 0 then
                                local dist = (raiz.Position - mRaiz.Position).Magnitude
                                if dist < distPerigo then
                                    distPerigo = dist
                                    perigoMaisPerto = mob
                                end
                            end
                        end
                    end

                    if perigoMaisPerto and distPerigo < CONFIG.DistSeguranca then
                        LabelStatus.Text = "fugindo de: " .. perigoMaisPerto.Name
                        ControlaSprint(true)
                        local dir = (raiz.Position - perigoMaisPerto.HumanoidRootPart.Position).Unit
                        Mover(raiz.Position + (dir * 40))
                    else
                        LabelStatus.Text = "seguro... recuperando..."
                        ControlaSprint(false)
                        Parar()
                    end
                end

            else
                -- ANTI PAREDE
                if Estado.AlvoAtual then
                    local distAndada = (raiz.Position - Estado.PosicaoAntiga).Magnitude
                    if distAndada < 0.5 then
                        Estado.TempoParado = Estado.TempoParado + 0.1
                    else
                        Estado.TempoParado = 0
                    end
                    Estado.PosicaoAntiga = raiz.Position
                    
                    if Estado.TempoParado > CONFIG.TempoTravado then
                        LabelStatus.Text = "bugou parede... trocando"
                        table.insert(ListaIgnorados, Estado.AlvoAtual)
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
                    
                    if not tHum or tHum.Health <= 0 or not tRaiz or not Estado.AlvoAtual.Parent then
                        Estado.AlvoAtual = nil
                        ControlaSprint(false)
                        Parar()
                    else
                        local dist = (raiz.Position - tRaiz.Position).Magnitude
                        
                        if dist > CONFIG.DistCorrer then
                            ControlaSprint(true)
                            Mover(tRaiz.Position)
                        elseif dist > CONFIG.DistAtaque then
                            ControlaSprint(false)
                            Mover(tRaiz.Position)
                        else
                            local posCostas = tRaiz.CFrame * CFrame.new(0, 0, CONFIG.DistCostas)
                            if (raiz.Position - posCostas.Position).Magnitude > 2 then
                                ControlaSprint(true) 
                                Mover(posCostas.Position)
                            else
                                ControlaSprint(false)
                                Parar()
                                raiz.CFrame = CFrame.new(raiz.Position, Vector3.new(tRaiz.Position.X, raiz.Position.Y, tRaiz.Position.Z))
                            end
                            Atacar()
                        end
                    end
                    
                else
                    -- BUSCA (COM RANGE ALTO)
                    LabelStatus.Text = "escaneando mapa..."
                    local pastaMobs = Workspace:FindFirstChild("Mobs")
                    
                    if pastaMobs then
                        local melhorAlvo = nil
                        local menorDist = CONFIG.RaioBusca 
                        
                        for _, mob in ipairs(pastaMobs:GetChildren()) do
                            if not table.find(ListaIgnorados, mob) then
                                local mHum = mob:FindFirstChild("Humanoid")
                                local mRaiz = mob:FindFirstChild("HumanoidRootPart")
                                
                                if mHum and mRaiz and mHum.Health > 0 then
                                    local dist = (raiz.Position - mRaiz.Position).Magnitude
                                    if dist < menorDist then
                                        menorDist = dist
                                        melhorAlvo = mob
                                    end
                                end
                            end
                        end
                        
                        if melhorAlvo then 
                            Estado.AlvoAtual = melhorAlvo 
                        else 
                            ControlaSprint(false) 
                            Parar() 
                            LabelStatus.Text = "sem mobs no mapa..."
                        end
                    end
                end
            end
        end
    end
end)