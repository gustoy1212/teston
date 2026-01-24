--[[
    SCRIPT PREMIUM - FARM & SECURITY
    Desenvolvido para venda.
    
    ESTRUTURA:
    1. Configuração de Segurança (Link da Whitelist)
    2. Interface de Login
    3. Código do Farm (Criptografado/Escondido na função)
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==================================================================
-- ⚠️ CONFIGURAÇÃO OBRIGATÓRIA (SÓ MEXA AQUI) ⚠️
-- Cola aqui o link RAW do seu arquivo whitelist.lua no GitHub
-- Aquele arquivo que tem: return { ["KEY-TAL"] = 12345 }
-- ==================================================================

local URL_WHITELIST = "https://raw.githubusercontent.com/gustoy1212/teston/main/discord_uploads/script_auto_8426a598.lua"

-- ==================================================================
-- 👇 AQUI COMEÇA O CÓDIGO DO FARM (PROTEGIDO) 👇
-- Ele ta dentro de uma função, so roda se a key for aprovada
-- ==================================================================

local function IniciarFarmSecreto()
    -- Notificação de Sucesso
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ACESSO PERMITIDO";
        Text = "Carregando Farm V4...";
        Duration = 5;
    })
    
    -- [[ INICIO DO SCRIPT DE FARM V4 ]] --
    
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = game:GetService("VirtualInputManager") 
    
    getgenv().Farming = true 

    local CONFIG = {
        DistAtaque = 6,
        DistCostas = 5,
        DistCorrer = 12,
        RaioBusca = 5000, -- Range alto pra nao ficar parado
        VidaBaixa = 25,  
        VidaCheia = 90, 
        DistSeguranca = 50,
        TempoTravado = 2.5 
    }

    local Estado = {
        Rodando = false, Correndo = false, Fugindo = false,
        AlvoAtual = nil, PosicaoAntiga = Vector3.new(0,0,0), TempoParado = 0 
    }

    local ListaIgnorados = {} 

    -- Limpa GUI antiga se existir
    if CoreGui:FindFirstChild("PainelFarm") then CoreGui.PainelFarm:Destroy() end

    -- Cria GUI do Farm
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

    -- Funcoes Auxiliares Internas
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
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:MoveTo(pos)
        end
    end
    local function Parar()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
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

    -- Eventos da GUI
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

    -- Loop Principal
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

                -- Fuga Inteligente
                if vidaAtual < CONFIG.VidaBaixa then Estado.Fugindo = true end
                
                if Estado.Fugindo then
                    if vidaAtual >= CONFIG.VidaCheia then
                        Estado.Fugindo = false 
                        LabelStatus.Text = "vida cheia, voltando..."
                    else
                        local perigoMaisPerto = nil
                        local distPerigo = 9999
                        local pastaMobs = Workspace:FindFirstChild("Mobs")
                        if pastaMobs then
                            for _, mob in ipairs(pastaMobs:GetChildren()) do
                                local mHum = mob:FindFirstChild("Humanoid")
                                local mRaiz = mob:FindFirstChild("HumanoidRootPart")
                                if mHum and mRaiz and mHum.Health > 0 then
                                    local dist = (raiz.Position - mRaiz.Position).Magnitude
                                    if dist < distPerigo then distPerigo = dist perigoMaisPerto = mob end
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
                    -- Anti Parede
                    if Estado.AlvoAtual then
                        local distAndada = (raiz.Position - Estado.PosicaoAntiga).Magnitude
                        if distAndada < 0.5 then Estado.TempoParado = Estado.TempoParado + 0.1 else Estado.TempoParado = 0 end
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
                    -- Combate
                    if Estado.AlvoAtual then
                        local tHum = Estado.AlvoAtual:FindFirstChild("Humanoid")
                        local tRaiz = Estado.AlvoAtual:FindFirstChild("HumanoidRootPart")
                        if not tHum or tHum.Health <= 0 or not tRaiz or not Estado.AlvoAtual.Parent then
                            Estado.AlvoAtual = nil
                            ControlaSprint(false)
                            Parar()
                        else
                            local dist = (raiz.Position - tRaiz.Position).Magnitude
                            if dist > CONFIG.DistCorrer then ControlaSprint(true) Mover(tRaiz.Position)
                            elseif dist > CONFIG.DistAtaque then ControlaSprint(false) Mover(tRaiz.Position)
                            else
                                local posCostas = tRaiz.CFrame * CFrame.new(0, 0, CONFIG.DistCostas)
                                if (raiz.Position - posCostas.Position).Magnitude > 2 then
                                    ControlaSprint(true) Mover(posCostas.Position)
                                else
                                    ControlaSprint(false) Parar()
                                    raiz.CFrame = CFrame.new(raiz.Position, Vector3.new(tRaiz.Position.X, raiz.Position.Y, tRaiz.Position.Z))
                                end
                                Atacar()
                            end
                        end
                    else
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
                                        if dist < menorDist then menorDist = dist melhorAlvo = mob end
                                    end
                                end
                            end
                            if melhorAlvo then Estado.AlvoAtual = melhorAlvo else ControlaSprint(false) Parar() LabelStatus.Text = "sem mobs..." end
                        end
                    end
                end
            end
        end
    end)
    -- [[ FIM DO SCRIPT DE FARM ]] --
end

-- ==================================================================
-- 🔐 SISTEMA DE LOGIN (INTERFACE)
-- Esse é o código que verifica a key antes de liberar o farm
-- ==================================================================

if CoreGui:FindFirstChild("AuthSystem") then CoreGui.AuthSystem:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AuthSystem"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 320, 0, 180)
Frame.Position = UDim2.new(0.5, -160, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Frame.BorderColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 2
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "🛡️ SISTEMA DE SEGURANÇA"
Title.TextColor3 = Color3.fromRGB(0, 160, 255)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local SubTitle = Instance.new("TextLabel", Frame)
SubTitle.Size = UDim2.new(1, 0, 0, 20)
SubTitle.Position = UDim2.new(0, 0, 0.2, 0)
SubTitle.Text = "Insira sua Key de acesso abaixo"
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
SubTitle.Font = Enum.Font.SourceSans
SubTitle.BackgroundTransparency = 1

local KeyBox = Instance.new("TextBox", Frame)
KeyBox.Size = UDim2.new(0.8, 0, 0.2, 0)
KeyBox.Position = UDim2.new(0.1, 0, 0.35, 0)
KeyBox.PlaceholderText = "Cole a Key aqui..."
KeyBox.Text = ""
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.Font = Enum.Font.Code

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0.85, 0)
Status.Text = "Aguardando..."
Status.TextColor3 = Color3.fromRGB(100, 100, 100)
Status.BackgroundTransparency = 1

local Btn = Instance.new("TextButton", Frame)
Btn.Size = UDim2.new(0.8, 0, 0.25, 0)
Btn.Position = UDim2.new(0.1, 0, 0.6, 0)
Btn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
Btn.Text = "VERIFICAR & ENTRAR"
Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Btn.Font = Enum.Font.GothamBold

-- Lógica de Verificação
Btn.MouseButton1Click:Connect(function()
    Status.Text = "Conectando ao servidor..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local keyDigitada = KeyBox.Text
    
    -- Tenta baixar a lista de chaves do GitHub
    local sucesso, resultado = pcall(function()
        return game:HttpGet(URL_WHITELIST)
    end)
    
    if not sucesso then
        Status.Text = "Erro de conexão (HTTP 404)"
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    -- Transforma o texto do GitHub em uma tabela Lua
    local listaKeys = loadstring(resultado)()
    
    if type(listaKeys) ~= "table" then
        Status.Text = "Erro na lista de keys (Formato inválido)"
        return
    end
    
    -- Verifica a Key e o ID
    local idDono = listaKeys[keyDigitada]
    
    if not idDono then
        Status.Text = "❌ Key Inexistente!"
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif idDono ~= LocalPlayer.UserId then
        Status.Text = "⚠️ Key pertence a outro usuário!"
        Status.TextColor3 = Color3.fromRGB(255, 100, 0)
    else
        Status.Text = "✅ Acesso Liberado!"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1)
        ScreenGui:Destroy() -- Some com a tela de login
        IniciarFarmSecreto() -- Inicia o script de verdade
    end
end)