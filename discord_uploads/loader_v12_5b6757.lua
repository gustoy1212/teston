--[[
    ⚔️ SWORD ONLINE V40 - FINAL SMOOTH & FPS MAX ⚔️
    - Visual: Glass UI (Seu Template)
    - Fix Movimento: Adicionado "Throttle" para parar de travar.
    - Potato Mode: Apaga Lighting + Câmera + Partículas (Baseado no Log).
    - Fix Anti-AFK: Loop preventivo adicionado.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ChatService = game:GetService("Chat")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- 🔐 0. SISTEMA DE KEY (SEU, INTACTO)
-- ==============================================================================
local URL_WHITELIST = "https://raw.githubusercontent.com/gustoy1212/teston/main/discord_uploads/script_auto_8426a598.lua"

-- ==============================================================================
-- 1. CONFIGURAÇÃO VISUAL & VARIÁVEIS
-- ==============================================================================
local LOGO_ID = "82943656320265"
local MY_LOGO = "rbxthumb://type=Asset&id=" .. LOGO_ID .. "&w=420&h=420"

-- Globais de Controle
getgenv().Farming = false
getgenv().AutoRun = false
getgenv().ShowHitbox = false
getgenv().AntiAfk = false
getgenv().CombatMode = "Frontal" 
getgenv().NaturalMotion = false 
getgenv().DeviceMode = "Mobile"
getgenv().WallCheck = true 
getgenv().SpeedRun = false
getgenv().PotatoMode = false

-- Variável para o Texto do Berg (HUD)
local BergLabel = nil 
-- Variável para o Guardião
local GuardianModel = nil

-- Função Draggable Lisa
local function MakeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
end

local function LoadGlassUI()
    if CoreGui:FindFirstChild("SwordOnlineUI") then CoreGui.SwordOnlineUI:Destroy() end
    local ScreenGui = Instance.new("ScreenGui"); pcall(function() ScreenGui.Parent = CoreGui end); if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end; ScreenGui.Name = "SwordOnlineUI"; ScreenGui.ResetOnSpawn = false 

    local Theme = {Background=Color3.fromRGB(18,18,22), Transparency=0.10, Sidebar=Color3.fromRGB(25,25,30), Accent=Color3.fromRGB(0,255,180), Text=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(160,160,160)}
    local function AddCorner(i,r) local c=Instance.new("UICorner",i) c.CornerRadius=UDim.new(0,r) c.Parent=i end
    local function AddStroke(i,c,t) local s=Instance.new("UIStroke",i) s.Color=c s.Thickness=t s.Parent=i end

    local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.BackgroundColor3=Theme.Background; MainFrame.BackgroundTransparency=Theme.Transparency; MainFrame.Position=UDim2.new(0.5,-225,0.3,0); MainFrame.Size=UDim2.new(0,450,0,360); MakeDraggable(MainFrame); AddCorner(MainFrame,16); AddStroke(MainFrame,Color3.fromRGB(60,60,60),1)
    local Sidebar = Instance.new("Frame", MainFrame); Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.BackgroundTransparency=0.5; Sidebar.Size=UDim2.new(0,130,1,0); AddCorner(Sidebar,16)
    local SideFix = Instance.new("Frame", Sidebar); SideFix.BackgroundColor3=Theme.Sidebar; SideFix.BackgroundTransparency=0.5; SideFix.BorderSizePixel=0; SideFix.Size=UDim2.new(0,20,1,0); SideFix.Position=UDim2.new(1,-10,0,0); SideFix.ZIndex=0
    local Title = Instance.new("TextLabel", Sidebar); Title.Text="SWORD\nONLINE"; Title.Size=UDim2.new(1,0,0,60); Title.BackgroundTransparency=1; Title.TextColor3=Theme.Accent; Title.Font=Enum.Font.GothamBlack; Title.TextSize=22; Title.LineHeight=0.9
    local TabContainer = Instance.new("Frame", Sidebar); TabContainer.BackgroundTransparency=1; TabContainer.Position=UDim2.new(0,10,0,80); TabContainer.Size=UDim2.new(1,-20,1,-100); local TabList=Instance.new("UIListLayout",TabContainer); TabList.Padding=UDim.new(0,10); TabList.SortOrder=Enum.SortOrder.LayoutOrder
    local MiniBtn = Instance.new("TextButton", Sidebar); MiniBtn.Text="Minimizar"; MiniBtn.BackgroundColor3=Color3.fromRGB(255,60,60); MiniBtn.BackgroundTransparency=0.8; MiniBtn.Size=UDim2.new(1,-20,0,30); MiniBtn.Position=UDim2.new(0,10,1,-40); MiniBtn.Font=Enum.Font.GothamBold; MiniBtn.TextColor3=Theme.Text; MiniBtn.TextSize=12; AddCorner(MiniBtn,8)
    local Content = Instance.new("Frame", MainFrame); Content.BackgroundTransparency=1; Content.Position=UDim2.new(0,140,0,10); Content.Size=UDim2.new(1,-150,1,-20)
    local OpenBtn = Instance.new("ImageButton", ScreenGui); OpenBtn.BackgroundColor3=Color3.new(1,1,1); OpenBtn.BackgroundTransparency=1; OpenBtn.Size=UDim2.new(0,70,0,70); OpenBtn.Position=UDim2.new(0,20,0.5,0); OpenBtn.Image=MY_LOGO; OpenBtn.Visible=false; OpenBtn.ScaleType=Enum.ScaleType.Fit; MakeDraggable(OpenBtn)
    MiniBtn.MouseButton1Click:Connect(function() MainFrame.Visible=false; OpenBtn.Visible=true end); OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible=true; OpenBtn.Visible=false end)

    BergLabel = Instance.new("TextLabel", ScreenGui)
    BergLabel.Size = UDim2.new(1, 0, 0, 50)
    BergLabel.Position = UDim2.new(0, 0, 0.15, 0) 
    BergLabel.BackgroundTransparency = 1
    BergLabel.Font = Enum.Font.GothamBlack
    BergLabel.TextSize = 24
    BergLabel.TextStrokeTransparency = 0.5
    BergLabel.TextStrokeColor3 = Color3.new(0,0,0)
    BergLabel.Text = ""
    BergLabel.Visible = false

    local Tabs={}; local Pages={} 
    local function CreateTab(n) local b=Instance.new("TextButton",TabContainer); b.BackgroundColor3=Theme.Background; b.BackgroundTransparency=1; b.Size=UDim2.new(1,0,0,35); b.Text=n; b.Font=Enum.Font.GothamBold; b.TextColor3=Theme.TextDim; b.TextSize=14; b.TextXAlignment=Enum.TextXAlignment.Left; AddCorner(b,8); local p=Instance.new("UIPadding",b); p.PaddingLeft=UDim.new(0,10)
    local g=Instance.new("ScrollingFrame",Content); g.Size=UDim2.new(1,0,1,0); g.BackgroundTransparency=1; g.BorderSizePixel=0; g.ScrollBarThickness=2; g.Visible=false; local l=Instance.new("UIListLayout",g); l.Padding=UDim.new(0,8); l.SortOrder=Enum.SortOrder.LayoutOrder
    b.MouseButton1Click:Connect(function() for _,v in pairs(Tabs) do TweenService:Create(v,TweenInfo.new(0.2),{BackgroundTransparency=1,TextColor3=Theme.TextDim}):Play() end; for _,v in pairs(Pages) do v.Visible=false end; TweenService:Create(b,TweenInfo.new(0.2),{BackgroundTransparency=0.8,TextColor3=Theme.Accent}):Play(); g.Visible=true end)
    table.insert(Tabs,b); table.insert(Pages,g); return g end

    local function CreateToggle(p,t,c) local f=Instance.new("Frame",p); f.BackgroundColor3=Color3.fromRGB(30,30,35); f.BackgroundTransparency=0.4; f.Size=UDim2.new(1,-5,0,45); AddCorner(f,10)
    local l=Instance.new("TextLabel",f); l.Text=t; l.Font=Enum.Font.GothamMedium; l.TextColor3=Theme.Text; l.TextSize=14; l.Size=UDim2.new(0.7,0,1,0); l.Position=UDim2.new(0,15,0,0); l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left
    local s=Instance.new("TextButton",f); s.Text=""; s.BackgroundColor3=Color3.fromRGB(50,50,55); s.Size=UDim2.new(0,44,0,24); s.Position=UDim2.new(1,-55,0.5,-12); AddCorner(s,12)
    local d=Instance.new("Frame",s); d.BackgroundColor3=Color3.fromRGB(200,200,200); d.Size=UDim2.new(0,18,0,18); d.Position=UDim2.new(0,3,0.5,-9); AddCorner(d,9)
    local st=false; s.MouseButton1Click:Connect(function() st=not st; TweenService:Create(s,TweenInfo.new(0.2),{BackgroundColor3=st and Theme.Accent or Color3.fromRGB(50,50,55)}):Play(); TweenService:Create(d,TweenInfo.new(0.2),{Position=st and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play(); c(st) end) end

    local function CreateButton(p,t,c) local b=Instance.new("TextButton",p); b.BackgroundColor3=Color3.fromRGB(40,40,45); b.BackgroundTransparency=0.4; b.Size=UDim2.new(1,-5,0,40); b.Text=t; b.TextColor3=Theme.Text; b.Font=Enum.Font.GothamBold; b.TextSize=14; AddCorner(b,8); b.MouseButton1Click:Connect(c) end
    local function CreateSection(p,t) local l=Instance.new("TextLabel",p); l.Text=t; l.Size=UDim2.new(1,0,0,25); l.BackgroundTransparency=1; l.TextColor3=Theme.TextDim; l.Font=Enum.Font.Gotham; l.TextSize=12 end

    -- ==============================================================================
    -- 4. LÓGICA DO FARM (IA V40)
    -- ==============================================================================

    local CONFIG = {
        DistanciaBater = 12, 
        RaioBusca = 100000,
        VidaBaixa = 25, VidaCheia = 90, DistSeguranca = 60,
        HitboxSize = 25
    }

    local SKILL_LIST = {"Sharp Nail", "Sharp Nail II", "Reaver", "Stinger", "Linear", "Avalanche", "Cyclone", "Gale Slicer", "Starburst Stream", "Rapid Bite"}
    local Estado = {
        AlvoAtual=nil, Fugindo=false, CooldownSkill=0, 
        UltimaPos=Vector3.new(), StuckCount=0, StuckTime=0,
        NextMoveTime=0, CurrentOffset=Vector3.new(0,0,5)
    }
    local Ignored = {}

    -- [[ FEATURE 1: GUARDIÃO SOMBRA ]]
    local function SpawnGuardian()
        if GuardianModel then return end 
        local char = LocalPlayer.Character
        if not char then return end
        
        char.Archivable = true
        local ghost = char:Clone()
        ghost.Name = "NightmareWatcher"
        ghost.Parent = Workspace
        GuardianModel = ghost

        local hum = ghost:FindFirstChild("Humanoid")
        if hum then 
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
        
        for _, obj in pairs(ghost:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Clothing") or obj:IsA("Decal") then obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Color = Color3.fromRGB(0, 0, 0)
                obj.Material = Enum.Material.Neon
                obj.Transparency = 0.3
                obj.CanCollide = false
                obj.Anchored = true
            end
        end
        ghost:ScaleTo(1) 
        
        -- Aura Vermelha
        local root = ghost:FindFirstChild("HumanoidRootPart")
        if root then
            local light = Instance.new("PointLight", root)
            light.Color = Color3.fromRGB(255, 0, 0); light.Range = 10; light.Brightness = 1
        end

        local dialogues = {"Te tirei daquela confusão, " .. LocalPlayer.Name .. ".", "Graças à minha IA, você não morreu.", "Recupera essa vida logo.", "Eu programei esse desvio perfeitamente.", "Ninguém mexe com o usuário do meu script."}

        task.spawn(function()
            local lastChat = 0
            while GuardianModel and GuardianModel.Parent and Estado.Fugindo do
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and ghost.PrimaryPart then
                    local targetCF = myRoot.CFrame * CFrame.new(4, 0, 2) 
                    local newCF = ghost.PrimaryPart.CFrame:Lerp(CFrame.new(targetCF.Position, myRoot.Position), 0.1)
                    ghost:PivotTo(newCF)

                    if tick() - lastChat > 5 then
                        local msg = dialogues[math.random(1, #dialogues)]
                        ChatService:Chat(ghost.Head, msg, Enum.ChatColor.Red)
                        lastChat = tick()
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end

    local function RemoveGuardian()
        if GuardianModel then
            ChatService:Chat(GuardianModel.Head, "Minha missão acabou. Voltando ao código...", Enum.ChatColor.Green)
            task.wait(1.5)
            if GuardianModel then GuardianModel:Destroy() end
            GuardianModel = nil
        end
    end

    -- [[ FEATURE 2: MODO BATATA APOCALIPSE (FIXED) ]]
    local function TogglePotato(bool)
        getgenv().PotatoMode = bool
        if bool then
            -- Limpeza de Lighting (Sombras e Efeitos)
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then
                    v:Destroy()
                end
            end

            -- Função de Varredura Total
            local function NukeVisuals(parent)
                for _, v in pairs(parent:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.Material = Enum.Material.SmoothPlastic
                        v.Reflectance = 0
                        v.CastShadow = false
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") then
                        v.Enabled = false
                    elseif v:IsA("MeshPart") then
                        v.TextureID = "" -- Remove Textura
                        v.Material = Enum.Material.SmoothPlastic
                    elseif v:IsA("SpecialMesh") then
                        v.TextureId = ""
                    end
                    
                    if #v:GetChildren() > 0 then NukeVisuals(v) end
                end
            end
            
            NukeVisuals(Workspace)
            -- Limpa Câmera também (HBGuis do seu log)
            NukeVisuals(Workspace.CurrentCamera)
        end
    end

    local function UpdateBergStatus(text, color)
        if not BergLabel then return end
        if text then BergLabel.Text = text; BergLabel.TextColor3 = color; BergLabel.Visible = true else BergLabel.Visible = false end
    end

    local function IsMobValido(mob)
        if not mob or not mob.Parent then return false end
        if table.find(Ignored, mob) then return false end
        if not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 then return false end
        if Players:GetPlayerFromCharacter(mob) then return false end
        if mob:FindFirstChild("Config") or mob.Name:match("Mob%d+") or mob.Parent.Name == "Mobs" or mob.Parent.Name == "ClientMonsters" then return true end
        return false
    end

    local function ExpandirHitbox(mob)
        pcall(function()
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
            if root then
                if root.Size.X ~= CONFIG.HitboxSize then
                    root.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
                    root.CanCollide = false 
                    if getgenv().ShowHitbox then root.Transparency = 0.7; root.Color = Color3.fromRGB(255, 0, 0); root.Material = Enum.Material.ForceField else root.Transparency = 1 end
                end
            end
        end)
    end

    local function Attack(target)
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end 
        if getgenv().DeviceMode == "PC" then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            if math.random(1, 10) == 1 then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) task.wait() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game) end
        elseif getgenv().DeviceMode == "Mobile" then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local mobileBtn = playerGui:FindFirstChild("MobileAttackButton", true)
                if mobileBtn then
                    local pos = mobileBtn.AbsolutePosition; local size = mobileBtn.AbsoluteSize; local x, y = pos.X + size.X/2, pos.Y + size.Y/2
                    VirtualInputManager:SendTouchEvent(999, 0, x, y, 0, false, game, 1); VirtualInputManager:SendTouchEvent(999, 1, x, y, 0, false, game, 1)
                else
                    local cam = Workspace.CurrentCamera
                    VirtualInputManager:SendTouchEvent(999, 0, cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 1); VirtualInputManager:SendTouchEvent(999, 1, cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 1)
                end
            end
        end
    end

    local function Skills()
        if tick() - Estado.CooldownSkill < 0.2 then return end
        local remote = ReplicatedStorage:FindFirstChild("UseSwordSkill", true)
        if remote then task.spawn(function() for i=1, 2 do remote:InvokeServer(SKILL_LIST[math.random(1, #SKILL_LIST)]) end end) Estado.CooldownSkill = tick() end
    end

    -- [[ FEATURE 3: MOVE TO SUAVE ]]
    local function MoveTo(targetPos)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then return end
        local finalPos = targetPos

        if getgenv().WallCheck then
            local origin = root.Position
            local lookDir = (targetPos - origin).Unit
            local params = RaycastParams.new(); params.FilterDescendantsInstances = {char, Workspace:FindFirstChild("Mobs"), Workspace:FindFirstChild("ClientMonsters")}; params.FilterType = Enum.RaycastFilterType.Exclude
            local frontRay = Workspace:Raycast(origin, lookDir * 5, params)
            if frontRay then
                local rightDir = (CFrame.lookAt(Vector3.zero, lookDir) * CFrame.Angles(0, math.rad(-45), 0)).LookVector
                local rightRay = Workspace:Raycast(origin, rightDir * 6, params)
                local leftDir = (CFrame.lookAt(Vector3.zero, lookDir) * CFrame.Angles(0, math.rad(45), 0)).LookVector
                local leftRay = Workspace:Raycast(origin, leftDir * 6, params)
                if not rightRay then finalPos = origin + (rightDir * 8)
                elseif not leftRay then finalPos = origin + (leftDir * 8)
                else char.Humanoid.Jump = true end
            end
        end

        if (root.Position - Estado.UltimaPos).Magnitude < 0.5 then
            if tick() - Estado.StuckTime > 2.5 then
                if Estado.AlvoAtual then table.insert(Ignored, Estado.AlvoAtual); Estado.AlvoAtual = nil end
                char.Humanoid.Jump = true
                finalPos = root.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10))
                Estado.StuckTime = tick() 
            end
        else
            Estado.StuckTime = tick()
            Estado.UltimaPos = root.Position
        end

        char.Humanoid:MoveTo(finalPos)
    end

    local function GetFleeDirection(myPos)
        local avgPos = Vector3.zero
        local count = 0
        local radius = 80 
        local function Scan(folder)
            if not folder then return end
            for _, mob in ipairs(folder:GetChildren()) do
                if IsMobValido(mob) then
                    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                    if root and (root.Position - myPos).Magnitude < radius then
                        avgPos = avgPos + root.Position
                        count = count + 1
                    end
                end
            end
        end
        Scan(Workspace:FindFirstChild("Mobs"))
        Scan(Workspace:FindFirstChild("ClientMonsters"))
        if count > 0 then avgPos = avgPos / count return (myPos - avgPos).Unit, true else return Vector3.new(1,0,0), false end
    end

    local function GetClosest()
        local char = LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local best, minDist = nil, CONFIG.RaioBusca
        local function Scan(folder)
            if not folder then return end
            for _, mob in ipairs(folder:GetChildren()) do
                if IsMobValido(mob) and not table.find(Ignored, mob) then
                    local mRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                    if mRoot then
                        local dist = (root.Position - mRoot.Position).Magnitude
                        if dist < minDist then minDist = dist best = mob end
                    end
                end
            end
        end
        Scan(Workspace:FindFirstChild("Mobs"))
        Scan(Workspace:FindFirstChild("ClientMonsters"))
        return best
    end

    local function EquipWeapon()
        local char = LocalPlayer.Character
        if not char then return end
        local pack = LocalPlayer:FindFirstChild("Backpack")
        if pack then
            local tool = pack:FindFirstChildOfClass("Tool")
            if tool then char.Humanoid:EquipTool(tool) end
        end
    end

    -- LOOP FARM PRINCIPAL (THROTTLED - SMOOTH)
    task.spawn(function()
        while true do
            task.wait(0.1) -- CORREÇÃO DO TRAVAMENTO: 0.1s de delay
            if getgenv().Farming then
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChild("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not hum or not root then return end

                    if hum.Health <= 0 then Estado.AlvoAtual = nil task.wait(4) return end
                    local tool = char:FindFirstChildOfClass("Tool"); if not tool then EquipWeapon() end

                    if (hum.Health / hum.MaxHealth) * 100 < CONFIG.VidaBaixa then 
                        Estado.Fugindo = true 
                        SpawnGuardian()
                    end
                    if (hum.Health / hum.MaxHealth) * 100 >= CONFIG.VidaCheia then 
                        Estado.Fugindo = false 
                        UpdateBergStatus(nil)
                        RemoveGuardian()
                    end

                    if Estado.Fugindo then
                        local fleeDir, isInDanger = GetFleeDirection(root.Position)
                        if isInDanger then
                            UpdateBergStatus("Corre berg, o bixo vindo!", Color3.fromRGB(255, 50, 50))
                            MoveTo(root.Position + (fleeDir * 40))
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                        else
                            UpdateBergStatus("ufaaa agr so esperar a vida encher...", Color3.fromRGB(50, 255, 100))
                            hum:MoveTo(root.Position) 
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                        end
                    else
                        if Estado.AlvoAtual then
                            local aHum = Estado.AlvoAtual:FindFirstChild("Humanoid")
                            if not aHum or aHum.Health <= 0 or not Estado.AlvoAtual.Parent then Estado.AlvoAtual = nil end
                        end

                        local potentialTarget = GetClosest()
                        if not Estado.AlvoAtual then Estado.AlvoAtual = potentialTarget
                        elseif potentialTarget and potentialTarget ~= Estado.AlvoAtual then
                            local tRoot = potentialTarget:FindFirstChild("HumanoidRootPart")
                            local aRoot = Estado.AlvoAtual:FindFirstChild("HumanoidRootPart")
                            if tRoot and aRoot then
                                local distT = (root.Position - tRoot.Position).Magnitude
                                local distA = (root.Position - aRoot.Position).Magnitude
                                if distT < distA - 10 then Estado.AlvoAtual = potentialTarget end
                            end
                        end

                        if Estado.AlvoAtual then
                            local mRoot = Estado.AlvoAtual:FindFirstChild("HumanoidRootPart")
                            if mRoot then
                                root.CFrame = CFrame.new(root.Position, Vector3.new(mRoot.Position.X, root.Position.Y, mRoot.Position.Z))
                                local dist = (root.Position - mRoot.Position).Magnitude
                                local targetPos = mRoot.Position
                                
                                if getgenv().NaturalMotion then
                                    if tick() > Estado.NextMoveTime then
                                        local choice = math.random(1, 4)
                                        if choice == 1 then Estado.CurrentOffset = Vector3.new(math.random(-3,3), 0, -4)
                                        elseif choice == 2 then Estado.CurrentOffset = Vector3.new(math.random(-5,5), 0, -12)
                                        else Estado.CurrentOffset = Vector3.new(math.random(-10,10), 0, -8) end
                                        Estado.NextMoveTime = tick() + (math.random(5, 12) / 10)
                                    end
                                    targetPos = (mRoot.CFrame * CFrame.new(Estado.CurrentOffset)).Position
                                else
                                    if getgenv().CombatMode == "Back" then targetPos = (mRoot.CFrame * CFrame.new(0, 0, 3)).Position 
                                    else targetPos = (mRoot.CFrame * CFrame.new(0, 0, -3)).Position end
                                end

                                if getgenv().NaturalMotion then MoveTo(targetPos)
                                else
                                    if dist > CONFIG.DistanciaBater then MoveTo(targetPos)
                                    elseif dist > 3 then MoveTo(targetPos) 
                                    else hum:MoveTo(root.Position) end
                                end

                                if dist <= CONFIG.DistanciaBater then
                                    if getgenv().CombatMode == "Jump" then hum.Jump = true end
                                    Attack(Estado.AlvoAtual)
                                    Skills()
                                end

                                if getgenv().AutoRun and dist > 15 then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                                else VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end
                            end
                        else
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                        end
                    end
                end)
            end
        end
    end)

    task.spawn(function() while true do task.wait() if getgenv().SpeedRun and LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 40 end end end)
    task.spawn(function() while true do task.wait(2) pcall(function() local function Apply(f) if f then for _, m in ipairs(f:GetChildren()) do if IsMobValido(m) then ExpandirHitbox(m) end end end end Apply(Workspace:FindFirstChild("Mobs")) Apply(Workspace:FindFirstChild("ClientMonsters")) end) end end)
    
    -- [[ FIX ANTI-AFK: Loop de Prevenção + Evento de Segurança ]]
    LocalPlayer.Idled:Connect(function()
        if getgenv().AntiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(60) -- Clica a cada 60 segundos para resetar o timer do Roblox
            if getgenv().AntiAfk then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end
    end)

    task.spawn(function() while true do task.wait(10) Ignored = {} end end)

    local PageFarm = CreateTab("Farm")
    local PageCombat = CreateTab("Settings")
    local PageMisc = CreateTab("Misc")
    local PageCred = CreateTab("Info")

    CreateSection(PageFarm, "PRINCIPAL")
    CreateToggle(PageFarm, "⚔️ Auto Farm", function(state) getgenv().Farming = state if state then StartFarmLogic() end end)
    CreateSection(PageFarm, "MOVIMENTO")
    CreateToggle(PageFarm, "🏃 Auto Run (Ctrl)", function(state) getgenv().AutoRun = state end)
    CreateToggle(PageFarm, "🧱 Anti-Parede (Smart)", function(state) getgenv().WallCheck = state end)

    CreateSection(PageCombat, "DISPOSITIVO")
    local DevBtn = Instance.new("TextButton", PageCombat); DevBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); DevBtn.BackgroundTransparency = 0.4; DevBtn.Size = UDim2.new(1, -5, 0, 45); DevBtn.Text = ""; AddCorner(DevBtn, 10)
    local DevTitle = Instance.new("TextLabel", DevBtn); DevTitle.Text = "Modo Ataque"; DevTitle.Size = UDim2.new(0.5, 0, 1, 0); DevTitle.Position = UDim2.new(0, 15, 0, 0); DevTitle.BackgroundTransparency = 1; DevTitle.TextColor3 = Theme.Text; DevTitle.Font = Enum.Font.GothamMedium; DevTitle.TextXAlignment = Enum.TextXAlignment.Left
    local DevVal = Instance.new("TextLabel", DevBtn); DevVal.Text = "Mobile (Touch)"; DevVal.Size = UDim2.new(0.4, 0, 1, 0); DevVal.Position = UDim2.new(0.55, 0, 0, 0); DevVal.BackgroundTransparency = 1; DevVal.TextColor3 = Theme.Accent; DevVal.Font = Enum.Font.GothamBold; DevVal.TextXAlignment = Enum.TextXAlignment.Right
    DevBtn.MouseButton1Click:Connect(function() if getgenv().DeviceMode == "PC" then getgenv().DeviceMode = "Mobile" DevVal.Text = "Mobile (Touch)" else getgenv().DeviceMode = "PC" DevVal.Text = "PC / Emu" end end)

    CreateSection(PageCombat, "ESTILO DE LUTA")
    local ModeBtn = Instance.new("TextButton", PageCombat); ModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); ModeBtn.BackgroundTransparency = 0.4; ModeBtn.Size = UDim2.new(1, -5, 0, 45); ModeBtn.Text = ""; AddCorner(ModeBtn, 10)
    local ModeTitle = Instance.new("TextLabel", ModeBtn); ModeTitle.Text = "Posicionamento"; ModeTitle.Size = UDim2.new(0.5, 0, 1, 0); ModeTitle.Position = UDim2.new(0, 15, 0, 0); ModeTitle.BackgroundTransparency = 1; ModeTitle.TextColor3 = Theme.Text; ModeTitle.Font = Enum.Font.GothamMedium; ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
    local ModeVal = Instance.new("TextLabel", ModeBtn); ModeVal.Text = "Frontal"; ModeVal.Size = UDim2.new(0.4, 0, 1, 0); ModeVal.Position = UDim2.new(0.55, 0, 0, 0); ModeVal.BackgroundTransparency = 1; ModeVal.TextColor3 = Theme.Accent; ModeVal.Font = Enum.Font.GothamBold; ModeVal.TextXAlignment = Enum.TextXAlignment.Right
    ModeBtn.MouseButton1Click:Connect(function() if getgenv().CombatMode == "Frontal" then getgenv().CombatMode = "Back"; ModeVal.Text = "Costas" elseif getgenv().CombatMode == "Back" then getgenv().CombatMode = "Jump"; ModeVal.Text = "Pulo" else getgenv().CombatMode = "Frontal"; ModeVal.Text = "Frontal" end end)

    CreateToggle(PageCombat, "🧠 Movimento Natural", function(state) getgenv().NaturalMotion = state end)
    CreateSection(PageCombat, "VISUAL")
    CreateToggle(PageCombat, "🎯 Mostrar Hitbox", function(state) getgenv().ShowHitbox = state end)

    CreateSection(PageMisc, "EXTRA")
    CreateToggle(PageMisc, "⚡ Velocidade (40)", function(state) getgenv().SpeedRun = state end)
    CreateToggle(PageMisc, "🛡️ Anti-AFK", function(state) getgenv().AntiAfk = state end)
    CreateToggle(PageMisc, "🔥 Modo Batata (FPS)", function(state) TogglePotato(state) end)
    CreateButton(PageMisc, "🔄 Reentrar no Server", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)

    local Info = Instance.new("TextLabel", PageCred)
    Info.Text = "SWORD ONLINE \n\n[SEGURANÇA ATIVA]\nSe sua vida cair abaixo de 25%, o Guardião aparecerá para te proteger enquanto você foge.\n\nATUALIZAÇÃO\nredomendo desativar movimento manuel, se ficar bugado,mouse travando etc vai em settings e muda de moblie para pc / emu\n\nDev: Gustoy"
    Info.Size = UDim2.new(1, -10, 1, -10); Info.Position = UDim2.new(0, 5, 0, 5); Info.BackgroundTransparency = 1; Info.TextColor3 = Theme.TextDim; Info.Font = Enum.Font.GothamMedium; Info.TextSize = 14; Info.TextWrapped = true; Info.TextYAlignment = Enum.TextYAlignment.Top

    Tabs[1].BackgroundTransparency = 0.8; Tabs[1].TextColor3 = Theme.Accent; Pages[1].Visible = true
    game.StarterGui:SetCore("SendNotification", {Title="Sword Online"; Text="Carregado!"; Duration=3;})
end

-- ==============================================================================
-- 🔐 TELA DE LOGIN (MANTIDA)
-- ==============================================================================
if CoreGui:FindFirstChild("AuthSystem") then CoreGui.AuthSystem:Destroy() end
local ScreenGuiKey = Instance.new("ScreenGui", CoreGui); ScreenGuiKey.Name = "AuthSystem"
local FrameKey = Instance.new("Frame", ScreenGuiKey); FrameKey.Size = UDim2.new(0, 320, 0, 180); FrameKey.Position = UDim2.new(0.5, -160, 0.4, 0); FrameKey.BackgroundColor3 = Color3.fromRGB(15, 15, 20); FrameKey.BorderColor3 = Color3.fromRGB(0, 100, 255); FrameKey.BorderSizePixel = 0; FrameKey.Active = true; FrameKey.Draggable = true
local CornerKey = Instance.new("UICorner", FrameKey); CornerKey.CornerRadius = UDim.new(0, 10)
local TitleKey = Instance.new("TextLabel", FrameKey); TitleKey.Size = UDim2.new(1, 0, 0, 40); TitleKey.Text = "🔐 SWORD ONLINE LOGIN"; TitleKey.TextColor3 = Color3.fromRGB(0, 160, 255); TitleKey.Font = Enum.Font.GothamBlack; TitleKey.BackgroundTransparency = 1
local KeyBox = Instance.new("TextBox", FrameKey); KeyBox.Size = UDim2.new(0.8, 0, 0.2, 0); KeyBox.Position = UDim2.new(0.1, 0, 0.35, 0); KeyBox.PlaceholderText = "Cole a Key aqui..."; KeyBox.Text = ""; KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35); KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255); KeyBox.Font = Enum.Font.Code
local CornerBox = Instance.new("UICorner", KeyBox); CornerBox.CornerRadius = UDim.new(0, 6)
local StatusKey = Instance.new("TextLabel", FrameKey); StatusKey.Size = UDim2.new(1, 0, 0, 20); StatusKey.Position = UDim2.new(0, 0, 0.85, 0); StatusKey.Text = "Aguardando..."; StatusKey.TextColor3 = Color3.fromRGB(100, 100, 100); StatusKey.BackgroundTransparency = 1
local BtnKey = Instance.new("TextButton", FrameKey); BtnKey.Size = UDim2.new(0.8, 0, 0.25, 0); BtnKey.Position = UDim2.new(0.1, 0, 0.6, 0); BtnKey.BackgroundColor3 = Color3.fromRGB(0, 100, 180); BtnKey.Text = "VERIFICAR & ENTRAR"; BtnKey.TextColor3 = Color3.fromRGB(255, 255, 255); BtnKey.Font = Enum.Font.GothamBold
local CornerBtnKey = Instance.new("UICorner", BtnKey); CornerBtnKey.CornerRadius = UDim.new(0, 6)

BtnKey.MouseButton1Click:Connect(function()
    StatusKey.Text = "Conectando..."
    StatusKey.TextColor3 = Color3.fromRGB(255, 255, 0)
    local keyDigitada = KeyBox.Text
    local sucesso, resultado = pcall(function() return game:HttpGet(URL_WHITELIST) end)
    if not sucesso then StatusKey.Text = "Erro Conexão!"; StatusKey.TextColor3 = Color3.fromRGB(255, 0, 0); return end
    local listaKeys = loadstring(resultado)()
    local idDono = listaKeys[keyDigitada]
    if not idDono then StatusKey.Text = "❌ Key Invalida!"; StatusKey.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif idDono ~= LocalPlayer.UserId then StatusKey.Text = "⚠️ ID Errado!"; StatusKey.TextColor3 = Color3.fromRGB(255, 100, 0)
    else StatusKey.Text = "✅ Acesso Liberado!"; StatusKey.TextColor3 = Color3.fromRGB(0, 255, 0); task.wait(1); ScreenGuiKey:Destroy(); LoadGlassUI() end
end)
