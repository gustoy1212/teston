--[[
    🛡️ SAO ANTI-AFK (24/7 GUARD)
    
    OBJETIVO: Impedir o Erro 278 (Kick por Inatividade).
    COMO: Intercepta o sinal de "Idle" e simula atividade.
    USO: Rode junto com qualquer outro script.
]]

local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

getgenv().AntiAfkActive = true

-- // GUI VISUAL (Pra você saber que está ligado) //
if CoreGui:FindFirstChild("AntiAfkUI") then CoreGui.AntiAfkUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AntiAfkUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 50)
MainFrame.Position = UDim2.new(0.02, 0, 0.88, 0) -- Canto inferior esquerdo
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
MainFrame.BorderSizePixel = 1
MainFrame.Active = true
MainFrame.Draggable = true

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🛡️ ANTI-AFK: LIGADO"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14

-- // A MÁGICA //
local Connection = Players.LocalPlayer.Idled:Connect(function()
    if getgenv().AntiAfkActive then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new()) -- Simula clique com botão direito
        
        -- Feedback Visual
        StatusLabel.Text = "⛔ RESETOU O TEMPO!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(2)
        StatusLabel.Text = "🛡️ ANTI-AFK: LIGADO"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

-- Botãozinho pra fechar se quiser
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -20, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(50,0,0)
CloseBtn.TextColor3 = Color3.white

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().AntiAfkActive = false
    if Connection then Connection:Disconnect() end
    ScreenGui:Destroy()
end)