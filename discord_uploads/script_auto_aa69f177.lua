--[[
    📜 QUEST SPY LITE (ANTI-KICK / MOBILE SAFE)
    
    SEGURANÇA:
    - Este script usa "Lista Branca" (Whitelist).
    - Ele IGNORA movimento, sons, ataques e animações.
    - Ele SÓ registra se o nome do evento tiver: "Quest", "Mission", "Npc", "Accept".
    
    Isso evita sobrecarregar o Delta e tomar kick.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
if CoreGui:FindFirstChild("QuestSpyLite") then CoreGui.QuestSpyLite:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuestSpyLite"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 350, 0, 150) -- Pequeno pra não atrapalhar
MainFrame.Position = UDim2.new(0.5, -175, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Text = "🕵️ SPY LITE (Só Missões)"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 40, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold

local LogLabel = Instance.new("TextLabel", MainFrame)
LogLabel.Size = UDim2.new(0.9, 0, 0.6, 0)
LogLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
LogLabel.Text = "Aguardando você aceitar a missão..."
LogLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
LogLabel.BackgroundTransparency = 1
LogLabel.TextWrapped = true
LogLabel.Font = Enum.Font.Code
LogLabel.TextYAlignment = Enum.TextYAlignment.Top

-- // HOOK SEGURO (WHITELIST ONLY) //
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Só olha se for Disparo de Servidor
    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name:lower()
        
        -- FILTRO DE SEGURANÇA: Só deixa passar se tiver essas palavras
        -- Isso impede o jogo de crashar com spams de movimento
        if name:find("quest") or name:find("miss") or name:find("accept") or name:find("npc") or name:find("interact") or name:find("dialog") then
            
            -- Achou! Mostra na tela
            local argsText = ""
            for _, v in pairs(args) do argsText = argsText .. tostring(v) .. ", " end
            
            LogLabel.Text = "📡 REMOTE ACHADO!\nNome: " .. self.Name .. "\nArgs: " .. argsText
            LogLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
            
            -- Imprime no console (F9) por segurança também
            warn(">>> REMOTE QUEST: " .. self.Name)
            warn(">>> ARGS: " .. argsText)
        end
    end
    
    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end

-- // FECHAR E LIMPAR HOOK //
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    -- Nota: O hook continua rodando até vc reconectar, mas sem a GUI ele não lagga.
    -- O ideal no mobile é fechar o jogo e abrir de novo se quiser parar o hook 100%.
end)