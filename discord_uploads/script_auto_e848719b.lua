--[[
    SCRIPT PREMIUM V6 - FIRST HIT SKILL
    - Prioridade Total para Skills (Usa antes de bater)
    - Anti-Desperdício (Guarda skill se o mob tiver morrendo)
    - Sistema de Whitelist e Anti-Parede mantidos
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==================================================================
-- ⚠️ LINK DA WHITELIST (MANTENHA O SEU AQUI)
-- ==================================================================
local URL_WHITELIST = "https://raw.githubusercontent.com/gustoy1212/teston/main/discord_uploads/script_auto_8426a598.lua"

-- ==================================================================
-- 👇 CÓDIGO DO FARM OTIMIZADO V6 👇
-- ==================================================================

local function IniciarFarmSecreto()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "FARM V6 LIGADO";
        Text = "Modo Agressivo: Skill First!";
        Duration = 5;
    })
    
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = game:GetService("VirtualInputManager") 
    
    getgenv().Farming = true 

    -- CONFIGURAÇÕES
    local CONFIG = {
        DistAtaque = 7,         
        DistCostas = 5,
        DistCorrer = 14,
        RaioBusca = 5000, 
        VidaBaixa = 25,  
        VidaCheia = 90, 
        DistSeguranca = 50,
        TempoTravado = 2.5,
        UsarSkills = true,
        PuparSkillEmVidaBaixa = 15 -- Se o mob tiver menos de 15% de vida, guarda a skill pro proximo
    }

    -- LISTA DE SKILLS (Reunidas da sua log)
    local SKILL_LIST = {
        "Sharp Nail", "Sharp Nail II", "Sharp Nail III", "Reaver", 
        "Stinger", "Linear", "Streak", "Quadruple Pain",           
        "Avalanche", "Backslash", "Cascade", "Cyclone",            
        "Gale Slicer", "Starburst Stream", "Starburst",            
        "Fading Edge", "Rapid Bite", "Canine",                     
        "Embracer", "Senda Suigetsu"                               
    }

    local Estado = {
        Rodando = false, Correndo = false, Fugindo = false,
        AlvoAtual = nil, PosicaoAntiga = Vector3.new(0,0,0), TempoParado = 0,
        CooldownSkill = 0 
    }

    local ListaIgnorados = {} 

    -- GUI Setup
    if CoreGui:FindFirstChild("PainelFarm") then CoreGui.PainelFarm:Destroy() end
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "PainelFarm"

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 250, 0, 150)
    Frame.Position = UDim2.new(0.5, -125, 0.2, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Frame.Active = true
    Frame.Draggable = true

    local LabelStatus = Instance.new("TextLabel", Frame)
    LabelStatus.Size = UDim2.new(1, 0, 0, 30)
    LabelStatus.Text = "status: esperando..."
    LabelStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    LabelStatus.BackgroundTransparency = 1

    local Botao = Instance.new("TextButton", Frame)
    Botao.Size = UDim2.new(0.9, 0, 0.3, 0)
    Botao.Position = UDim2.new(0.05, 0, 0.4, 0)
    Botao.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    Botao.Text = "LIGAR FARM"
    Botao.TextColor3 = Color3.fromRGB(255, 255, 255)

    local Fechar = Instance.new("TextButton", Frame)
    Fechar.Size = UDim2.new(0, 30, 0, 30)
    Fechar.Position = UDim2.new(1, -30, 0, 0)
    Fechar.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    Fechar.Text = "X"
    Fechar.TextColor3 = Color3.fromRGB(255, 255, 255)

    -- === NOVA LÓGICA DE COMBATE ===

    local function UsarSkillImediatamente(mobAlvo)
        if not CONFIG.UsarSkills then return end
        
        -- Verificação Inteligente: O mob ta morrendo? Se sim, guarda a skill.
        if mobAlvo and mobAlvo:FindFirstChild("Humanoid") then
            local hp = mobAlvo.Humanoid.Health
            local maxHp = mobAlvo.Humanoid.MaxHealth
            local porcentagem = (hp / maxHp) * 100
            
            if porcentagem < CONFIG.PuparSkillEmVidaBaixa then 
                return -- Não gasta skill em bixo quase morto
            end
        end

        -- Controle de Cooldown Global do Script (evita crashar o jogo mandando 1000 remotes)
        if tick() - Estado.CooldownSkill < 1.0 then return end 
        
        local remoteSkill = ReplicatedStorage:FindFirstChild("UseSwordSkill")
        if remoteSkill then
            -- Dispara em thread separada pra não travar o movimento
            task.spawn(function()
                for _, skillName in ipairs(SKILL_LIST) do
                    -- Tenta disparar a skill. O jogo filtra qual vc tem equipada.
                    remoteSkill:InvokeServer(skillName)
                end
            end)
            Estado.CooldownSkill = tick()
        end
    end

    local function AtaqueBasicoClicando()
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

    -- Movimentação e Inputs
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

    -- Eventos GUI
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
                    LabelStatus.Text = "morreu... esperando respawn"
                    Estado.AlvoAtual = nil
                    Estado.Fugindo = false
                    task.wait(4)
                    return
                end
                PegaArma()

                -- 1. Fuga
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
                    -- 2. Anti Bug (Parede)
                    if Estado.AlvoAtual then
                        local distAndada = (raiz.Position - Estado.PosicaoAntiga).Magnitude
                        if distAndada < 0.5 then Estado.TempoParado = Estado.TempoParado + 0.1 else Estado.TempoParado = 0 end
                        Estado.PosicaoAntiga = raiz.Position
                        if Estado.TempoParado > CONFIG.TempoTravado then
                            LabelStatus.Text = "travado? trocando alvo..."
                            table.insert(ListaIgnorados, Estado.AlvoAtual)
                            Estado.AlvoAtual = nil
                            Estado.TempoParado = 0
                            Parar()
                            task.wait(0.2)
                        end
                    end
                    
                    -- 3. COMBATE OTIMIZADO (V6)
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
                                -- CHEGOU NO ALCANCE DO ATAQUE!
                                -- Posicionamento (Costas)
                                local posCostas = tRaiz.CFrame * CFrame.new(0, 0, CONFIG.DistCostas)
                                if (raiz.Position - posCostas.Position).Magnitude > 2 then
                                    ControlaSprint(true) 
                                    Mover(posCostas.Position)
                                else
                                    ControlaSprint(false) 
                                    Parar()
                                    raiz.CFrame = CFrame.new(raiz.Position, Vector3.new(tRaiz.Position.X, raiz.Position.Y, tRaiz.Position.Z))
                                end
                                
                                -- !!! AQUI ESTA A MAGICA DO V6 !!!
                                -- 1º: Tenta soltar skill IMEDIATAMENTE antes de qualquer clique
                                UsarSkillImediatamente(Estado.AlvoAtual)
                                
                                -- 2º: Clica freneticamente (se a skill tiver em CD, o clique mata)
                                AtaqueBasicoClicando()
                            end
                        end
                    else
                        -- 4. Busca
                        LabelStatus.Text = "buscando vitima..."
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
end

-- ==================================================================
-- 🔐 SISTEMA DE LOGIN (MANTIDO)
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

Btn.MouseButton1Click:Connect(function()
    Status.Text = "Conectando..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local keyDigitada = KeyBox.Text
    
    local sucesso, resultado = pcall(function()
        return game:HttpGet(URL_WHITELIST)
    end)
    
    if not sucesso then
        Status.Text = "Erro Conexão!"
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    local listaKeys = loadstring(resultado)()
    local idDono = listaKeys[keyDigitada]
    
    if not idDono then
        Status.Text = "❌ Key Invalida!"
        Status.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif idDono ~= LocalPlayer.UserId then
        Status.Text = "⚠️ ID Errado!"
        Status.TextColor3 = Color3.fromRGB(255, 100, 0)
    else
        Status.Text = "✅ Acesso Liberado!"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(1)
        ScreenGui:Destroy() 
        IniciarFarmSecreto()
    end
end)