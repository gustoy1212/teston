-- [[ SOLO LEVELING: GOD HUB V15 (UI DESTROYER) ]] --
-- Foco: Clicar nos botões da tela (Bypass 100%) e Aura Física

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game.CoreGui end
ScreenGui.Name = "GodHubV15"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 350)
MainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "🖱️ GOD HUB V15 (UI CLICKER)"
Title.Size = UDim2.new(1, -30, 0.12, 0)
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(0.95, 0, 0.85, 0)
Container.Position = UDim2.new(0.025, 0, 0.12, 0)
Container.BackgroundTransparency = 1
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 5)

-- FUNÇÃO UI
local function AddToggle(text, color, callback)
    local btn = Instance.new("TextButton", Container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = text .. " [OFF]"
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = color
            btn.TextColor3 = Color3.new(1,1,1)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        callback(enabled)
    end)
end

-- ========================================== --
-- [[ 1. UI AUTO CLICKER (RECOMPENSAS) ]] --
-- ========================================== --
-- Varre os caminhos exatos achados na Log 3

AddToggle("💰 AUTO UI LOOT (TELA)", Color3.fromRGB(0, 255, 100), function(state)
    spawn(function()
        while state do
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if gui then
                -- Lista de Janelas achadas na log
                local Targets = {
                    gui:FindFirstChild("OnlineRewardPanel"),    --
                    gui:FindFirstChild("TowerRankPanel"),       --
                    gui:FindFirstChild("RaidsPanel"),           --
                    gui:FindFirstChild("TipsPanel"),            --
                    gui:FindFirstChild("TowerWavePanel"),       --
                    gui:FindFirstChild("RaidsFightPanel")       --
                }

                for _, panel in pairs(Targets) do
                    if panel then
                        -- Procura qualquer botão dentro desses painéis
                        for _, obj in pairs(panel:GetDescendants()) do
                            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                                if obj.Visible then
                                    -- Filtra botões de "Fechar" para não fechar a janela
                                    local name = obj.Name:lower()
                                    local text = (obj:IsA("TextButton") and obj.Text:lower()) or ""
                                    
                                    if not name:find("close") and not name:find("exit") and not name:find("fechar") then
                                        -- Clica no botão
                                        for _, conn in pairs(getconnections(obj.MouseButton1Click)) do
                                            conn:Fire()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(1) -- Verifica a cada 1 segundo
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 2. SWORD AURA V2 (TOUCH INTEREST) ]] --
-- ========================================== --
-- Baseado na confirmação de que itens são físicos

AddToggle("⚔️ SWORD AURA (KILL)", Color3.fromRGB(255, 50, 0), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        
        while state do
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            -- Procura Handles ou partes com TouchInterest
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChild("HitBox"))
            
            if handle and EnemyFolder then
                tool:Activate()
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    local hum = enemy:FindFirstChild("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        if (root.Position - char.HumanoidRootPart.Position).Magnitude < 30 then
                            -- O SEGREDO: Simula que a arma tocou no inimigo
                            if firetouchinterest then
                                firetouchinterest(handle, root, 0) 
                                firetouchinterest(handle, root, 1)
                            else
                                -- Fallback: Teleporta a arma
                                handle.CFrame = root.CFrame
                            end
                        end
                    end
                end
            end
            task.wait() 
            if not ScreenGui.Parent then break end
        end
    end)
end)

-- ========================================== --
-- [[ 3. IMÃ (SUPORTE) ]] --
-- ========================================== --

AddToggle("🧲 IMÃ DE MONSTROS", Color3.fromRGB(150, 150, 150), function(state)
    spawn(function()
        local EnemyFolder = Workspace:FindFirstChild("Enemys")
        while state do
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot and EnemyFolder then
                for _, enemy in pairs(EnemyFolder:GetChildren()) do
                    local root = enemy:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size = Vector3.new(40,40,40)
                        root.CanCollide = false
                        root.CFrame = myRoot.CFrame * CFrame.new(0,0,-5)
                        root.Velocity = Vector3.new(0,0,0)
                        for _, p in pairs(enemy:GetDescendants()) do
                            if p:IsA("BasePart") then p.Transparency = 1 end
                            if p:IsA("BillboardGui") then p.Enabled = false end
                        end
                    end
                end
            end
            task.wait(0.1)
            if not ScreenGui.Parent then break end
        end
    end)
end)