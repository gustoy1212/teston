--[[
    AUTOFARM & SURVIVAL SYSTEM
    Desenvolvido para estudo de automação e lógica de NPCs.
    
    Estrutura do Script:
    1. Definição de Serviços e Variáveis
    2. Interface Gráfica (UI)
    3. Funções Utilitárias (Leitura de Mobs, Movimento)
    4. Loop Principal (Heartbeat/Logica de Estado)
    
    Dica: Leia os comentários para entender como o script "pensa".
]]

-- // 1. SERVIÇOS E VARIÁVEIS GLOBAIS //
-- Usamos GetService para garantir que o serviço carregou antes de usar
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Usado para simular toques/teclas
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Variável global para controlar o loop (útil se você executar o script várias vezes)
getgenv().FlashStepSurvival = true

-- // CONFIGURAÇÕES (SETTINGS) //
-- Aqui ficam as constantes para fácil ajuste sem mexer na lógica
local SETTINGS = {
    -- Combate
    AttackDist = 6,         -- Distância para começar a bater
    BehindDist = 5,         -- Distância para ficar atrás do mob (backstab)
    SprintDist = 12,        -- Distância mínima para ativar o correr
    SearchRange = 3000,     -- Raio de busca de inimigos
    
    -- Sobrevivência (Gerenciamento de HP)
    LowHealthPercent = 25,  -- % de vida para fugir
    FullHealthPercent = 90, -- % de vida para voltar a lutar
    DefaultSafetyDist = 45, -- Distância segura padrão caso não ache config no mob
}

-- Variáveis de Estado (Controlam o fluxo lógico)
local State = {
    IsRunning = false,
    IsSprinting = false,
    IsInEmergency = false,
    CurrentTarget = nil
}

-- // 2. INTERFACE GRÁFICA (GUI) //
-- Removemos a UI antiga para não duplicar se re-executar
if CoreGui:FindFirstChild("DevScriptUI") then 
    CoreGui.DevScriptUI:Destroy() 
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DevScriptUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.Position = UDim2.new(0.5, -150, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Tema Dark clean
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true -- Permite arrastar a janela

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "AUTOFARM CONTROLLER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0.2, 0)
StatusLabel.Text = "Status: Aguardando..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSans

local HealthLabel = Instance.new("TextLabel", MainFrame)
HealthLabel.Size = UDim2.new(1, 0, 0, 30)
HealthLabel.Position = UDim2.new(0, 0, 0.35, 0)
HealthLabel.Text = "HP: 100%"
HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HealthLabel.BackgroundTransparency = 1
HealthLabel.Font = Enum.Font.Code -- Fonte monoespaçada para números

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
ToggleBtn.Text = "INICIAR SCRIPT"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = true

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

-- // 3. FUNÇÕES LÓGICAS //

-- Função que analisa o objeto do mob para extrair dados
-- Isso é útil pois alguns jogos guardam configs dentro do modelo do NPC
local function GetMobData(mob)
    local safeRange = SETTINGS.DefaultSafetyDist
    local isPriority = false -- Flag para mobs raros
    
    if mob:FindFirstChild("Config") then
        -- Tenta ler o range de detecção para fugir na distância exata
        if mob.Config:FindFirstChild("DetectionRange") then
            safeRange = mob.Config.DetectionRange.Value + 10 -- +10 de margem
        elseif mob.Config:FindFirstChild("AttackRange") then
            safeRange = mob.Config.AttackRange.Value + 15
        end
        
        -- Verifica se o mob tem drops raros (Rarity >= 2)
        if mob.Config:FindFirstChild("MaxDrops") then
            for _, item in pairs(mob.Config.MaxDrops:GetChildren()) do
                if item:FindFirstChild("Rarity") and item.Rarity.Value >= 2 then
                    isPriority = true
                end
            end
        end
    end
    return safeRange, isPriority
end

-- Controle de Sprint (Ctrl Esquerdo)
local function ToggleSprint(enable)
    if enable and not State.IsSprinting then
        State.IsSprinting = true
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    elseif not enable and State.IsSprinting then
        State.IsSprinting = false
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

-- Wrapper simples para movimentação do Humanoid
local function MoveToPosition(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:MoveTo(pos)
    end
end

local function StopMovement()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        -- Move para a própria posição atual cancela o pathfinding anterior
        char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
    end
end

-- Simulação de Ataque (Touch Event)
-- Usamos touch event pois costuma burlar melhor alguns anticheats do que Click simples
local function PerformAttack()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Tenta achar o botão mobile, se existir
    if playerGui:FindFirstChild("DeviceGui") and playerGui.DeviceGui:FindFirstChild("Mobile") then
        local btn = playerGui.DeviceGui.Mobile:FindFirstChild("MobileAttackButton")
        if btn then
            -- Método 1: FireSignal (se o executor suportar)
            if firesignal then
                pcall(function() firesignal(btn.MouseButton1Click) end)
                pcall(function() firesignal(btn.Activated) end)
            end
            
            -- Método 2: VirtualInput (Universal)
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            local cx, cy = pos.X + size.X/2, pos.Y + size.Y/2
            
            -- Simula toque (fase started e ended)
            VirtualInputManager:SendTouchEvent(999, 0, cx, cy, 0, false, game, 1)
            VirtualInputManager:SendTouchEvent(999, 1, cx, cy, 0, false, game, 1)
        end
    end
end

local function EnsureToolEquipped()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Se já tem ferramenta na mão, retorna
    if char:FindFirstChildOfClass("Tool") then return end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool then char.Humanoid:EquipTool(tool) end
    end
end

-- // EVENTOS DA UI //
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().FlashStepSurvival = false -- Mata o loop
    ToggleSprint(false)
    StopMovement()
    ScreenGui:Destroy()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    State.IsRunning = not State.IsRunning
    
    if State.IsRunning then
        ToggleBtn.Text = "PAUSAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Vermelho
        State.IsInEmergency = false
    else
        ToggleBtn.Text = "CONTINUAR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180) -- Azul
        ToggleSprint(false)
        StopMovement()
        State.CurrentTarget = nil
        StatusLabel.Text = "Status: Pausado pelo usuário"
    end
end)

-- // 4. LOOP PRINCIPAL (MAIN THREAD) //
-- Usamos spawn para não travar o script principal, mas task.spawn seria mais moderno
spawn(function()
    while getgenv().FlashStepSurvival do
        task.wait(0.1) -- Delay para não sobrecarregar a CPU (otimização)
        
        if State.IsRunning then
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then 
                -- Se o personagem não carregou, pula o frame
                return 
            end
            
            local myRoot = char.HumanoidRootPart
            local hum = char.Humanoid
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            
            -- Atualiza UI de Vida
            HealthLabel.Text = "HP: " .. math.floor(hpPercent) .. "%"
            HealthLabel.TextColor3 = (hpPercent <= 30) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)

            -- Verifica morte
            if hum.Health <= 0 then
                StatusLabel.Text = "Status: Morto (Aguardando Respawn)"
                State.CurrentTarget = nil
                State.IsInEmergency = false
                task.wait(4)
                return
            end

            EnsureToolEquipped()

            -- === LÓGICA DE EMERGÊNCIA (Fuga) ===
            if hpPercent < SETTINGS.LowHealthPercent then State.IsInEmergency = true end
            
            if State.IsInEmergency then
                if hpPercent >= SETTINGS.FullHealthPercent then
                    State.IsInEmergency = false 
                    StatusLabel.Text = "Status: Vida recuperada. Voltando!"
                else
                    StatusLabel.Text = "Status: CRÍTICO! Buscando local seguro..."
                    
                    -- Busca mob mais próximo para calcular vetor de fuga
                    local mobsFolder = Workspace:FindFirstChild("Mobs")
                    local dangerMob, closestDist = nil, 9999
                    
                    if mobsFolder then
                        for _, mob in ipairs(mobsFolder:GetChildren()) do
                            if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                local dist = (myRoot.Position - mob.HumanoidRootPart.Position).Magnitude
                                if dist < closestDist then 
                                    closestDist = dist 
                                    dangerMob = mob 
                                end
                            end
                        end
                    end
                    
                    ToggleSprint(true)
                    
                    if dangerMob then
                        local safeDist, _ = GetMobData(dangerMob)
                        
                        -- Se estiver dentro da área de perigo, corre na direção oposta
                        if closestDist < safeDist then
                            local direction = (myRoot.Position - dangerMob.HumanoidRootPart.Position).Unit
                            MoveToPosition(myRoot.Position + (direction * 25))
                        else
                            StopMovement()
                            StatusLabel.Text = "Status: Recuperando HP (Seguro)"
                            ToggleSprint(false) 
                        end
                    else
                         StopMovement() -- Nenhuma ameaça detectada
                    end
                end

            -- === LÓGICA DE COMBATE (State Machine) ===
            else
                if State.CurrentTarget then
                    -- Validação do alvo (ainda existe? está vivo?)
                    local tHum = State.CurrentTarget:FindFirstChild("Humanoid")
                    local tRoot = State.CurrentTarget:FindFirstChild("HumanoidRootPart")
                    
                    if not tHum or tHum.Health <= 0 or not tRoot or not State.CurrentTarget.Parent then
                        State.CurrentTarget = nil -- Alvo morreu ou sumiu, limpa variavel
                        ToggleSprint(false)
                        StopMovement()
                    else
                        -- Cálculo de Distância
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        
                        if dist > SETTINGS.SprintDist then
                            -- Longe demais: Corre até lá
                            ToggleSprint(true)
                            MoveToPosition(tRoot.Position)
                        elseif dist > SETTINGS.AttackDist then
                            -- Perto: Anda até lá
                            ToggleSprint(false)
                            MoveToPosition(tRoot.Position)
                        else
                            -- Alcance de Ataque: Lógica de Posicionamento (Backstab)
                            -- CFrame math para pegar a posição "atrás" do mob
                            local backPos = tRoot.CFrame * CFrame.new(0, 0, SETTINGS.BehindDist)
                            
                            if (myRoot.Position - backPos.Position).Magnitude > 2 then
                                ToggleSprint(true) 
                                MoveToPosition(backPos.Position)
                            else
                                -- Já está posicionado, para e ataca
                                ToggleSprint(false)
                                StopMovement()
                                -- Olha para o inimigo (LookAt)
                                myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(tRoot.Position.X, myRoot.Position.Y, tRoot.Position.Z))
                            end
                            PerformAttack()
                        end
                    end
                    
                else
                    -- BUSCA DE ALVOS (Targeting)
                    StatusLabel.Text = "Status: Escaneando área..."
                    local mobsFolder = Workspace:FindFirstChild("Mobs")
                    
                    if mobsFolder then
                        local bestTarget = nil
                        local minDistance = SETTINGS.SearchRange
                        
                        for _, mob in ipairs(mobsFolder:GetChildren()) do
                            local mHum = mob:FindFirstChild("Humanoid")
                            local mRoot = mob:FindFirstChild("HumanoidRootPart")
                            
                            if mHum and mRoot and mHum.Health > 0 then
                                local dist = (myRoot.Position - mRoot.Position).Magnitude
                                local _, isRare = GetMobData(mob)
                                
                                -- Prioridade para mobs raros (ignora a distancia do mais próximo se achar um raro)
                                if isRare and dist < SETTINGS.SearchRange then
                                    bestTarget = mob
                                    StatusLabel.Text = "Status: RARO ENCONTRADO!"
                                    break 
                                elseif dist < minDistance then
                                    minDistance = dist
                                    bestTarget = mob
                                end
                            end
                        end
                        
                        if bestTarget then 
                            State.CurrentTarget = bestTarget 
                        else 
                            ToggleSprint(false) 
                            StopMovement() 
                        end
                    end
                end
            end
        end
    end
end)