--[[
    📉 SAO PORTAL FINDER (LITE / ANTI-CRASH)
    
    OBJETIVO: Achar APENAS portais e imprimir no F9 sem travar o jogo.
    MÉTODO: Processamento lento (com pausas) para não estourar a memória.
]]

local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- UI Simples
if CoreGui:FindFirstChild("LiteScanUI") then CoreGui.LiteScanUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LiteScanUI"

local Btn = Instance.new("TextButton", ScreenGui)
Btn.Size = UDim2.new(0, 200, 0, 50)
Btn.Position = UDim2.new(0.5, -100, 0.1, 0)
Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
Btn.Text = "SCAN LEVE (OLHAR F9)"
Btn.TextColor3 = Color3.white
Btn.Font = Enum.Font.GothamBold

-- Função Segura
local function SafeScan()
    print("=== INICIANDO SCAN LEVE ===")
    Btn.Text = "ESCANEANDO..."
    Btn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
    
    local count = 0
    
    -- Varre devagar
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Pausa a cada 500 objetos checados para o jogo respirar
        if count % 500 == 0 then task.wait() end
        count = count + 1
        
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            
            -- Só aceita nomes de portal
            if name:match("portal") or name:match("gate") or name:match("dungeon") or name:match("rank") then
                
                -- Se achar, imprime na hora
                print(">> ACHEI: " .. obj.Name)
                print("   PATH: " .. obj:GetFullName())
                
                -- Cria um visual box simples (sem texto pra não pesar)
                local hl = Instance.new("Highlight")
                hl.Adornee = obj
                hl.FillColor = Color3.fromRGB(0, 255, 0)
                hl.OutlineColor = Color3.white
                hl.Parent = CoreGui
                
                -- Tenta achar nível
                for _, t in ipairs(obj:GetChildren()) do
                    if t:IsA("BillboardGui") or t:IsA("SurfaceGui") then
                        print("   GUI ENCONTRADA: " .. t.Name)
                    end
                end
            end
        end
    end
    
    print("=== FIM DO SCAN ===")
    Btn.Text = "PRONTO (VER F9)"
    Btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
end

Btn.MouseButton1Click:Connect(SafeScan)