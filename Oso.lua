-- ======================
-- PIXEL PAINTER PRO (V5.5) – DISPLAY NAMES CORRIGIDO (SEM PREFIXO "Canvas")
-- ======================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentGRID = 32
local currentTOTAL = 1024

-- ⬇⬇⬇ SLOTS (BOT EDITA AQUI) ⬇⬇⬇
local ARTS = {
	-- Exemplo
	{ name = "Exemplo Base (32x32)", playlist = "Todas", map = "Pixel 1 = FF0000 | Pixel 2 = 00FF00 ..." },
	-- Adicione seus slots aqui
}
-- ⬆⬆⬆ FIM DOS SLOTS ⬆⬆⬆

local PLAYLISTS = {"Todas", "Cópias", "Aleatórias", "NSFW", "Memes", "Players"}

local selectedMap = nil
local selectedArtName = ""
local selectedArtSize = "32x32"
local isPainting = false
local currentPlaylist = "Todas"
local isCopySelected = false

local remote = game.ReplicatedStorage:FindFirstChild("UpdateBoard") or workspace:FindFirstChild("UpdateBoard", true)

-- ====================== UTILITÁRIOS ======================
local function getArtSize(mapText)
	local maxPixel = 0
	for idx in mapText:gmatch("Pixel%s+(%d+)") do
		local n = tonumber(idx)
		if n and n > maxPixel then maxPixel = n end
	end
	return (maxPixel <= 256) and 16 or 32
end

local function logicalToBoardIndex(pixel)
	local zero = pixel - 1
	local y = math.floor(zero / currentGRID)
	local x = zero % currentGRID
	return y * currentGRID + ((currentGRID - 1) - x) + 1
end

local function getMyBoard()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "1" and obj:IsA("BasePart") and obj.Parent:FindFirstChild(tostring(currentTOTAL)) then
			return obj.Parent
		end
	end
	return nil
end

local function getFullArtData(mapText, defaultHex)
	local art = {}
	for i = 1, currentTOTAL do art[i] = defaultHex end
	for idx, hex in mapText:gmatch("Pixel%s+(%d+)[^=]*=%s*([A-Fa-f0-9]+)") do
		local n = tonumber(idx)
		if n and n >= 1 and n <= currentTOTAL then art[n] = hex:upper() end
	end
	return art
end

local function hexToColor3(hex)
	local r = tonumber(hex:sub(1,2),16) or 255
	local g = tonumber(hex:sub(3,4),16) or 255
	local b = tonumber(hex:sub(5,6),16) or 255
	return Color3.fromRGB(r, g, b)
end

local function checkArtStatus(board, fullArtData, setProgress)
	if not board or not fullArtData then setProgress("Aguardando..."); return end
	local needUpdate = 0
	for i = 1, currentTOTAL do
		local desiredHex = fullArtData[i]
		local boardIdx = logicalToBoardIndex(i)
		local pixelPart = board:FindFirstChild(tostring(boardIdx))
		if pixelPart and pixelPart:IsA("BasePart") then
			local target = hexToColor3(desiredHex)
			local diff = (pixelPart.Color.R - target.R)^2 + (pixelPart.Color.G - target.G)^2 + (pixelPart.Color.B - target.B)^2
			if diff > 0.001 then needUpdate = needUpdate + 1 end
		end
	end
	setProgress(needUpdate == 0 and "Arte Feita ✅" or "Pronto para pintar!")
end

-- ====================== PINTURA ======================
local function startSmartPaint(updateBar, setProgress)
	if isPainting or not selectedMap or not remote then
		setProgress("❌ SEM ARTE SELECIONADA")
		task.wait(1.5)
		local board = getMyBoard()
		checkArtStatus(board, getFullArtData(selectedMap, "000000"), setProgress)
		return
	end

	isPainting = true
	local board = getMyBoard()
	local finalArt = getFullArtData(selectedMap, "000000")
	local needUpdate = {}
	setProgress("🔍 Escaneando quadro...")

	if board then
		if isCopySelected then
			for i = 1, currentTOTAL do
				local boardIdx = logicalToBoardIndex(i)
				table.insert(needUpdate, {id = tostring(boardIdx), color = finalArt[i]})
			end
		else
			for i = 1, currentTOTAL do
				local desiredHex = finalArt[i]
				local boardIdx = logicalToBoardIndex(i)
				local pixelPart = board:FindFirstChild(tostring(boardIdx))
				if pixelPart and pixelPart:IsA("BasePart") then
					local targetColor = hexToColor3(desiredHex)
					local diff = (pixelPart.Color.R - targetColor.R)^2 +
								 (pixelPart.Color.G - targetColor.G)^2 +
								 (pixelPart.Color.B - targetColor.B)^2
					if diff > 0.001 then
						table.insert(needUpdate, {id = tostring(boardIdx), color = desiredHex})
					end
				end
			end
		end
	else
		setProgress("❌ QUADRO NÃO ENCONTRADO")
		task.wait(2)
		checkArtStatus(board, finalArt, setProgress)
		isPainting = false
		return
	end

	local total = #needUpdate
	if total == 0 then
		setProgress("Arte Feita ✅")
		updateBar(1)
		task.wait(1.5)
		isPainting = false
		return
	end

	local packet = {}
	for i, data in ipairs(needUpdate) do
		packet[data.id] = data.color
		updateBar(i / total)
		setProgress((isCopySelected and "Clonando... " or "Arte Carregando... ") .. math.floor(i/total*100) .. "%")
		if #packet >= 64 or i == total then
			pcall(function() remote:InvokeServer(packet) end)
			packet = {}
			task.wait(0.04)
		end
	end

	setProgress("Arte Feita ✅")
	updateBar(1)
	task.wait(1.5)
	isPainting = false
end

-- ====================== SISTEMA DE CÓPIAS (CORRIGIDO) ======================
local function isBoardEmpty(container, grid)
	local total = grid * grid
	for i = 1, total do
		local pixelPart = container:FindFirstChild(tostring(i))
		if pixelPart and pixelPart:IsA("BasePart") then
			local cor = pixelPart.Color
			if cor.R > 0.05 or cor.G > 0.05 or cor.B > 0.05 then return false end
		end
	end
	return true
end

-- Extrai o username real do nome do root (remove prefixos "PixelArtBoard_" e "Canvas")
local function extractRealUsername(rootName)
	-- Remove prefixo "PixelArtBoard_"
	local name = rootName:gsub("^PixelArtBoard_", ""):gsub("^PixelArtBoard", "")
	-- Remove prefixo "Canvas" se existir (caso o jogo adicione)
	name = name:gsub("^Canvas", "")
	return name
end

local function scanOtherBoards()
	local rawBoards = {}
	local scannedParents = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "1" then
			local parent = obj.Parent
			if parent and not scannedParents[parent] then
				scannedParents[parent] = true
				local has256 = parent:FindFirstChild("256")
				local has1024 = parent:FindFirstChild("1024")
				if has256 or has1024 then
					local grid = has1024 and 32 or 16
					local root = parent.Parent
					if root then
						local rootName = root.Name
						local realUsername = extractRealUsername(rootName)
						
						-- Tenta encontrar um jogador online com esse username
						local ownerPlayer = nil
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr.Name:lower() == realUsername:lower() then
								ownerPlayer = plr
								break
							end
						end
						
						local isOwned = (ownerPlayer ~= nil)
						local finalName = nil
						
						if isOwned then
							-- Quadro com dono online: usa DisplayName
							finalName = ownerPlayer.DisplayName
						else
							-- Quadro sem dono: o nome será definido depois como "quadro X"
							finalName = nil
						end
						
						-- Ignora o próprio quadro do jogador
						local isSelf = (isOwned and ownerPlayer == player)
						
						if not isSelf then
							local isEmpty = isBoardEmpty(parent, grid)
							table.insert(rawBoards, {
								container = parent,
								grid = grid,
								isEmpty = isEmpty,
								isOwned = isOwned,
								finalName = finalName,
								realUsername = realUsername
							})
						end
					end
				end
			end
		end
	end

	-- Separa com dono e sem dono
	local ownedBoards = {}
	local unownedBoards = {}
	for _, b in ipairs(rawBoards) do
		if b.isOwned then
			table.insert(ownedBoards, b)
		else
			table.insert(unownedBoards, b)
		end
	end

	-- Ordena os com dono pelo DisplayName (alfabético)
	table.sort(ownedBoards, function(a,b) return a.finalName:lower() < b.finalName:lower() end)
	
	-- Ordena os sem dono pela ordem de descoberta (já estão em alguma ordem)
	-- Renomeia como "quadro 1", "quadro 2", ...
	for idx, b in ipairs(unownedBoards) do
		b.finalName = "quadro " .. idx
	end

	-- Junta: primeiro com dono, depois sem dono
	local allBoards = {}
	for _, b in ipairs(ownedBoards) do table.insert(allBoards, b) end
	for _, b in ipairs(unownedBoards) do table.insert(allBoards, b) end

	-- Adiciona "(vazio)" se necessário
	for _, b in ipairs(allBoards) do
		if b.isEmpty then
			b.finalName = b.finalName .. " (vazio)"
		end
	end

	return allBoards
end

local function generateFullMapFromBoard(container, grid)
	local mapLines = {}
	local total = grid * grid
	for logicalIdx = 1, total do
		local physicalIdx = logicalToBoardIndex(logicalIdx)
		local pixelPart = container:FindFirstChild(tostring(physicalIdx))
		local hex = "000000"
		if pixelPart and pixelPart:IsA("BasePart") then
			local c = pixelPart.Color
			hex = string.format("%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
		end
		mapLines[#mapLines+1] = string.format("Pixel %d = %s", logicalIdx, hex)
	end
	return table.concat(mapLines, " | ")
end

local function refreshCopiesPlaylist(artScroll, createPreviewFn, updatePreviewFn, updateInfoFn, setProgressFn, updateBarFn, checkStatusFn)
	for _, child in ipairs(artScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local copies = scanOtherBoards()
	for _, copy in ipairs(copies) do
		local btn = Instance.new("TextButton", artScroll)
		btn.Size = UDim2.new(1, -5, 0, 25)
		btn.Text = copy.finalName
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.TextSize = 10
		Instance.new("UICorner", btn)

		btn.MouseButton1Click:Connect(function()
			local dynamicMap = generateFullMapFromBoard(copy.container, copy.grid)
			selectedMap = dynamicMap
			selectedArtName = "Cópia de " .. copy.finalName
			currentGRID = copy.grid
			currentTOTAL = copy.grid * copy.grid
			selectedArtSize = currentGRID .. "x" .. currentGRID
			isCopySelected = true

			createPreviewFn(currentGRID)
			updatePreviewFn(dynamicMap)
			updateInfoFn()

			for _, b in ipairs(artScroll:GetChildren()) do
				if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(45, 45, 50) end
			end
			btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)

			updateBarFn(0)
			local board = getMyBoard()
			local fullArt = getFullArtData(selectedMap, "000000")
			checkStatusFn(board, fullArt, setProgressFn)
		end)
	end
end

-- ====================== INTERFACE ======================
local function createGUI()
	if playerGui:FindFirstChild("PixelPainterHUD") then playerGui.PixelPainterHUD:Destroy() end

	local gui = Instance.new("ScreenGui", playerGui)
	gui.Name = "PixelPainterHUD"
	gui.ResetOnSpawn = false

	local toggle = Instance.new("TextButton", gui)
	toggle.Size = UDim2.new(0, 40, 0, 40)
	toggle.Position = UDim2.new(1, -50, 0, 20)
	toggle.Text = "🎨"
	toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	toggle.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", toggle)

	local main = Instance.new("Frame", gui)
	main.Size = UDim2.new(0, 280, 0, 325)
	main.AnchorPoint = Vector2.new(1, 0.5)
	main.Position = UDim2.new(1, -10, 0.5, 0)
	main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	main.BackgroundTransparency = 0.15
	main.Visible = false
	main.Active = true
	main.Draggable = true
	Instance.new("UICorner", main)

	toggle.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

	-- Playlists
	local plFrame = Instance.new("ScrollingFrame", main)
	plFrame.Size = UDim2.new(1, -20, 0, 30)
	plFrame.Position = UDim2.new(0, 10, 0, 10)
	plFrame.BackgroundTransparency = 1
	plFrame.ScrollBarThickness = 0
	plFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	plFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	plFrame.ScrollingDirection = Enum.ScrollingDirection.X

	local plLayout = Instance.new("UIListLayout", plFrame)
	plLayout.FillDirection = Enum.FillDirection.Horizontal
	plLayout.Padding = UDim.new(0, 5)

	-- Scroll de artes
	local artScroll = Instance.new("ScrollingFrame", main)
	artScroll.Size = UDim2.new(0, 120, 0, 200)
	artScroll.Position = UDim2.new(0, 10, 0, 50)
	artScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	artScroll.BackgroundTransparency = 0.3
	artScroll.ScrollBarThickness = 2
	artScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	artScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	artScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	Instance.new("UIListLayout", artScroll).Padding = UDim.new(0, 2)

	-- Preview
	local previewFrame = Instance.new("Frame", main)
	previewFrame.Size = UDim2.new(0, 130, 0, 130)
	previewFrame.Position = UDim2.new(0, 140, 0, 50)
	previewFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	previewFrame.BackgroundTransparency = 0.2
	local previewGrid = Instance.new("UIGridLayout", previewFrame)
	previewGrid.CellPadding = UDim2.new(0, 0, 0, 0)
	local pixels = {}

	-- Barra
	local progBg = Instance.new("Frame", main)
	progBg.Size = UDim2.new(0, 130, 0, 15)
	progBg.Position = UDim2.new(0, 140, 0, 190)
	progBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Instance.new("UICorner", progBg)
	local progBar = Instance.new("Frame", progBg)
	progBar.Size = UDim2.new(0, 0, 1, 0)
	progBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
	Instance.new("UICorner", progBar)
	local progTxt = Instance.new("TextLabel", progBg)
	progTxt.Size = UDim2.new(1, 0, 1, 0)
	progTxt.BackgroundTransparency = 1
	progTxt.Text = "Aguardando..."
	progTxt.TextColor3 = Color3.new(1,1,1)
	progTxt.TextSize = 11
	progTxt.Font = Enum.Font.GothamSemibold

	-- Botão iniciar
	local startBtn = Instance.new("TextButton", main)
	startBtn.Size = UDim2.new(0, 130, 0, 35)
	startBtn.Position = UDim2.new(0, 140, 0, 215)
	startBtn.Text = "INICIAR ARTE"
	startBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	startBtn.TextColor3 = Color3.new(1,1,1)
	startBtn.TextSize = 13
	Instance.new("UICorner", startBtn)

	-- Info
	local infoFrame = Instance.new("Frame", main)
	infoFrame.Size = UDim2.new(0, 130, 0, 75)
	infoFrame.Position = UDim2.new(0, 140, 0, 255)
	infoFrame.BackgroundTransparency = 1
	local infoLabel = Instance.new("TextLabel", infoFrame)
	infoLabel.Size = UDim2.new(1, 0, 1, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	infoLabel.TextSize = 12.5
	infoLabel.Font = Enum.Font.GothamMedium
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.TextWrapped = true

	local function updateBar(percent) progBar.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0) end
	local function setProgress(txt) progTxt.Text = txt end
	local function updateInfo()
		local dataHoje = os.date("%d/%m/%Y")
		infoLabel.Text = "Nome: " .. selectedArtName .. "\nAdicionada em: " .. dataHoje .. "\nTamanho: " .. selectedArtSize
	end

	local function createPreview(size)
		for _, child in ipairs(previewFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
		pixels = {}
		previewGrid.CellSize = (size == 16) and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 4, 0, 4)
		local total = size * size
		for i = 1, total do
			local p = Instance.new("Frame", previewFrame)
			p.BorderSizePixel = 0
			p.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			pixels[i] = p
		end
	end

	local function updatePreview(mapText)
		local fullArt = getFullArtData(mapText, "000000")
		for i = 1, #pixels do
			pixels[i].BackgroundColor3 = fullArt[i] and Color3.fromHex(fullArt[i]) or Color3.fromRGB(0,0,0)
		end
	end

	startBtn.MouseButton1Click:Connect(function()
		startSmartPaint(updateBar, setProgress)
	end)

	local function loadArts()
		if currentPlaylist == "Cópias" then
			refreshCopiesPlaylist(artScroll, createPreview, updatePreview, updateInfo, setProgress, updateBar, checkArtStatus)
			task.spawn(function()
				while currentPlaylist == "Cópias" and main.Visible do
					task.wait(5)
					refreshCopiesPlaylist(artScroll, createPreview, updatePreview, updateInfo, setProgress, updateBar, checkArtStatus)
				end
			end)
			return
		end

		isCopySelected = false
		for _, c in ipairs(artScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

		for _, art in ipairs(ARTS) do
			if currentPlaylist == "Todas" or art.playlist == currentPlaylist then
				local btn = Instance.new("TextButton", artScroll)
				btn.Size = UDim2.new(1, -5, 0, 25)
				btn.Text = art.name
				btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
				btn.TextColor3 = Color3.new(1,1,1)
				btn.TextSize = 10
				Instance.new("UICorner", btn)

				btn.MouseButton1Click:Connect(function()
					selectedMap = art.map
					selectedArtName = art.name
					isCopySelected = false
					local artGrid = getArtSize(art.map)
					currentGRID = artGrid
					currentTOTAL = artGrid * artGrid
					selectedArtSize = artGrid .. "x" .. artGrid
					createPreview(artGrid)
					updatePreview(art.map)
					updateInfo()
					for _, b in ipairs(artScroll:GetChildren()) do
						if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(45, 45, 50) end
					end
					btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
					updateBar(0)
					local board = getMyBoard()
					checkArtStatus(board, getFullArtData(selectedMap, "000000"), setProgress)
				end)
			end
		end
	end

	-- Criar botões das playlists
	for _, name in ipairs(PLAYLISTS) do
		local plBtn = Instance.new("TextButton", plFrame)
		plBtn.Size = UDim2.new(0, 75, 1, 0)
		plBtn.Text = name
		plBtn.TextScaled = true
		plBtn.TextWrapped = true
		plBtn.BackgroundColor3 = (name == "Todas") and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 50)
		plBtn.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", plBtn)
		local constraint = Instance.new("UITextSizeConstraint", plBtn)
		constraint.MaxTextSize = 11

		plBtn.MouseButton1Click:Connect(function()
			currentPlaylist = name
			for _, b in ipairs(plFrame:GetChildren()) do
				if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(45, 45, 50) end
			end
			plBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
			loadArts()
		end)
	end

	loadArts()
end

createGUI()
