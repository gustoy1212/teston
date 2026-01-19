--// CONFIGURAÇÕES
local Settings = {
	ScanFrequency = 1, -- Verifica novos monstros a cada X segundos
	ShowPlayers = false, -- Coloque true se quiser ver players também
	BoxColor = Color3.fromRGB(255, 0, 0), -- Cor da caixa do monstro
	HitboxColor = Color3.fromRGB(0, 255, 0), -- Cor da Hitbox (RootPart)
	TextSize = 14
}

--// SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// PASTA PARA GUARDAR OS VISUAIS
if CoreGui:FindFirstChild("GameScanner") then
	CoreGui.GameScanner:Destroy()
end

local Folder = Instance.new("Folder")
Folder.Name = "GameScanner"
Folder.Parent = CoreGui

--// FUNÇÃO: CRIAR VISUALIZAÇÃO
local function CreateESP(model)
	if model == LocalPlayer.Character then return end -- Ignora você mesmo
	if model:FindFirstChild("HasESP") then return end -- Já tem ESP

	local humanoid = model:FindFirstChild("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart")

	if humanoid and rootPart then
		-- Marca que já foi scaneado
		local tag = Instance.new("BoolValue", model)
		tag.Name = "HasESP"

		-- 1. HIGHLIGHT (Brilho através da parede)
		local highlight = Instance.new("Highlight")
		highlight.Adornee = model
		highlight.FillColor = Settings.BoxColor
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.new(1,1,1)
		highlight.Parent = Folder

		-- 2. HITBOX REAL (Wireframe na RootPart)
		local box = Instance.new("BoxHandleAdornment")
		box.Adornee = rootPart
		box.Size = rootPart.Size + Vector3.new(0.1, 0.1, 0.1)
		box.AlwaysOnTop = true
		box.ZIndex = 5
		box.Transparency = 0.6
		box.Color3 = Settings.HitboxColor
		box.Parent = Folder

		-- 3. TEXTO DE INFORMAÇÃO (HP, Distância, Status)
		local bgui = Instance.new("BillboardGui")
		bgui.Adornee = rootPart
		bgui.Size = UDim2.new(0, 200, 0, 50)
		bgui.StudsOffset = Vector3.new(0, 3, 0)
		bgui.AlwaysOnTop = true
		bgui.Parent = Folder

		local label = Instance.new("TextLabel", bgui)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.TextSize = Settings.TextSize
		label.Font = Enum.Font.Code

		-- 4. DETECTOR DE ATAQUE (Baseado em animação)
		local statusText = "Ocioso"
		local animConn
		animConn = humanoid.AnimationPlayed:Connect(function(track)
			statusText = "ATACANDO/ANIMANDO!"
			label.TextColor3 = Color3.fromRGB(255, 50, 50) -- Fica vermelho
			task.wait(1) -- Fica vermelho por 1 seg
			statusText = "Ocioso"
			label.TextColor3 = Color3.new(1, 1, 1)
		end)

		-- LOOP DE ATUALIZAÇÃO DESSE MONSTRO
		local updateLoop
		updateLoop = RunService.RenderStepped:Connect(function()
			if not model.Parent or humanoid.Health <= 0 then
				-- Limpeza se o monstro morrer
				highlight:Destroy()
				box:Destroy()
				bgui:Destroy()
				if animConn then animConn:Disconnect() end
				updateLoop:Disconnect()
				return
			end

			local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) 
				and (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude 
				or 0
			
			-- Atualiza o texto
			label.Text = string.format(
				"[%s]\nHP: %d/%d\nDist: %d studs\nStatus: %s",
				model.Name,
				math.floor(humanoid.Health),
				math.floor(humanoid.MaxHealth),
				math.floor(dist),
				statusText
			)
		end)
	end
end

--// SCANNER LOOP
-- Procura monstros em todo o mapa
task.spawn(function()
	while true do
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
				if not Settings.ShowPlayers and Players:GetPlayerFromCharacter(obj) then
					-- É player e a config diz pra ignorar
				else
					CreateESP(obj)
				end
			end
		end
		task.wait(Settings.ScanFrequency)
	end
end)

print("Sistema de SCAN e ESP iniciado! Verificando monstros...")
