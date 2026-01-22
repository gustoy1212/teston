--[[
    🎯 SAO PORTAL SELECTOR v9 (LISTA VISUAL)
    
    SOLUÇÃO DEFINITIVA:
    - Lista todos os "PortalModel" encontrados.
    - Mostra o texto/poder de cada um.
    - Você clica -> Ele teleporta e entra.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // UI SETUP //
if CoreGui:FindFirstChild("PortalSelectorUI") then CoreGui.PortalSelectorUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "PortalSelectorUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎯 SELETOR DE PORTAIS"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBlack
Title.BackgroundTransparency = 1

local RefreshBtn = Instance.new("TextButton", MainFrame)
RefreshBtn.Size = UDim2.new(0.9, 0, 0.1, 0)
RefreshBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
RefreshBtn.Text = "🔄 ATUALIZAR LISTA"
RefreshBtn.TextColor3 = Color3.white
RefreshBtn.Font = Enum.Font.GothamBold

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(0.9, 0, 0.65, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.22, 0)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0,0,0,0)

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 5)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.TextColor3 = Color3.white

-- // FUNÇÃO DE ENTRADA //
local function TeleportAndEnter(portalModel)
    local trigger = portalModel:FindFirstChild("ProximityPart")
    
    if not trigger then
        -- Se não achar ProximityPart, tenta achar qualquer parte
        trigger = portalModel.PrimaryPart or portalModel:FindFirstChild("HumanoidRootPart") or portalModel:FindFirstChildWhichIsA("BasePart")
    end
    
    if trigger then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- 1. TELEPORTA
            char.HumanoidRootPart.CFrame = trigger.CFrame * CFrame.new(0, 2, 0)
            
            -- 2. TENTA ENTRAR (SPAM)
            task.wait(0.2)
            firetouchinterest(char.HumanoidRootPart, trigger, 0)
            firetouchinterest(char.HumanoidRootPart, trigger, 1)
            
            -- Procura ProximityPrompt (Tecla E)
            local foundPrompt = false
            for _, pp in ipairs(trigger:GetChildren()) do
                if pp:IsA("ProximityPrompt") then
                    fireproximityprompt(pp)
                    foundPrompt = true
                end
            end
            
            -- Se não tava no trigger, procura no modelo todo
            if not foundPrompt then
                for _, pp in ipairs(portalModel:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") then fireproximityprompt(pp) end
                end
            end
            
            print("Tentando entrar em: " .. portalModel.Name)
        end
    else
        warn("Portal sem parte física para teleportar!")
    end
end

-- // SCANNER VISUAL //
local function RefreshList()
    -- Limpa lista antiga
    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    
    local found = 0
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- PROCURA EXATAMENTE PELO NOME DO SEU LOG
        if obj.Name == "PortalModel" then
            found = found + 1
            
            -- Tenta ler o poder
            local powerText = "???"
            local req = 0
            
            for _, gui in ipairs(obj:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible then
                    local txt = gui.Text:gsub(",", "") -- Remove vírgula
                    local num = tonumber(txt:match("%d+"))
                    
                    if num and num > 10 then -- Filtro básico
                        req = num
                        powerText = tostring(req)
                        -- Se tiver a palavra "Poder", é certeza
                        if gui.Text:lower():match("poder") then break end
                    end
                end
            end
            
            -- CRIA O BOTÃO NA LISTA
            local btn = Instance.new("TextButton", Scroll)
            btn.Size = UDim2.new(1, 0, 0, 40)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.Text = "🌀 Portal | Poder: " .. powerText
            btn.TextColor3 = Color3.white
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            
            -- Corzinha baseada na dificuldade
            if req > 0 then
                btn.TextColor3 = Color3.fromRGB(255, 200, 50) -- Dourado se tiver número
            end
            
            -- Ação do Clique
            btn.MouseButton1Click:Connect(function()
                TeleportAndEnter(obj)
            end)
        end
    end
    
    if found == 0 then
        local lbl = Instance.new("TextLabel", Scroll)
        lbl.Size = UDim2.new(1, 0, 0, 30)
        lbl.Text = "Nenhum 'PortalModel' encontrado."
        lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
        lbl.BackgroundTransparency = 1
    end
end

RefreshBtn.MouseButton1Click:Connect(RefreshList)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)