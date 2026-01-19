--[[
    🕵️‍♂️ THE DETECTIVE - TRIGGER SCANNER
    
    INSTRUÇÕES:
    1. Injete o script.
    2. Abra o Console do Roblox (Aperte F9).
    3. Ande MANUALMENTE até a porta e passe por ela.
    4. Veja o que apareceu no F9 (Nome de Part ou RemoteEvent).
    5. Me mande o nome aqui!
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- // GUI SETUP //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TriggerScanner"
if pcall(function() ScreenGui.Parent = CoreGui end) then ScreenGui.Parent = CoreGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 200)
MainFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.5
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🕵️‍♂️ SCANNER LIGADO (F9 para ver Logs)"
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.Code
Title.TextSize = 18
Title.BackgroundTransparency = 1

local LogDisplay = Instance.new("TextLabel", MainFrame)
LogDisplay.Size = UDim2.new(1, -20, 1, -40)
LogDisplay.Position = UDim2.new(0, 10, 0, 35)
LogDisplay.Text = "Ande até a porta...\nEsperando interação..."
LogDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
LogDisplay.TextXAlignment = Enum.TextXAlignment.Left
LogDisplay.TextYAlignment = Enum.TextYAlignment.Top
LogDisplay.BackgroundTransparency = 1
LogDisplay.Font = Enum.Font.Code

-- // 1. TOUCH SPY (Espião de Toque) //
local function SetupTouchSpy()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    print("--- INICIANDO ESPIÃO DE TOQUE ---")
    
    root.Touched:Connect(function(hit)
        -- Filtra chão e partes do próprio corpo
        if not hit:IsDescendantOf(char) and hit.Name ~= "Baseplate" and hit.Name ~= "Terrain" then
            
            -- Se for invisível ou tiver nome suspeito, destaca!
            if hit.Transparency > 0.5 or hit.Name:lower():match("trigger") or hit.Name:lower():match("door") or hit.Name:lower():match("sensor") then
                warn("🚨 TOQUE SUSPEITO: " .. hit.GetFullName())
                LogDisplay.Text = "TOCOU: " .. hit.Name .. "\nCaminho: " .. hit.GetFullName()
                
                -- Pinta pra você ver onde tá o gatilho
                local highlight = Instance.new("BoxHandleAdornment")
                highlight.Size = hit.Size
                highlight.Adornee = hit
                highlight.Color3 = Color3.fromRGB(255, 0, 0)
                highlight.Transparency = 0.5
                highlight.AlwaysOnTop = true
                highlight.ZIndex = 10
                highlight.Parent = CoreGui
                game.Debris:AddItem(highlight, 5) -- Some depois de 5s
            else
                print("Tocou: " .. hit.Name)
            end
        end
    end)
end

-- // 2. REMOTE SPY SIMPLES //
-- (Nota: Alguns executores podem bloquear isso, mas vale tentar)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        -- Filtra remotes de movimento padrão pra não spammar
        if self.Name ~= "CharacterSoundEvent" and self.Name ~= "DefaultChatSystemChatEvents" then
            print("📡 REMOTE DISPARADO: " .. self.Name)
            print("   Arguments: ", unpack(args))
            warn("📡 REMOTE: " .. self.GetFullName())
            
            if self.Name:lower():match("room") or self.Name:lower():match("dungeon") or self.Name:lower():match("door") or self.Name:lower():match("enter") then
                LogDisplay.Text = "REMOTE: " .. self.Name .. "\nCheque o F9!"
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end

-- // REINICIA SPY AO RENASCER //
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    SetupTouchSpy()
end)

SetupTouchSpy()