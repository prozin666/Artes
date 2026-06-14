-- =====================================================
-- MASTER PIXEL HUB — V3.4 (20 FPS + BAD APPLE)
-- =====================================================
--  Compatível com o bot do Discord e com vídeos no Roblox
--  Agora com delay de 0.05s entre frames (20 FPS)
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================
-- FUNÇÃO SPLIT (para parse da animação)
-- =====================================================
function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end

-- Fontes e estilo
local FONT_UI = Enum.Font.FredokaOne
local BG_COLOR = Color3.fromRGB(25, 25, 30)
local PANEL_BG = Color3.fromRGB(18, 18, 20)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local STROKE_COLOR = Color3.fromRGB(45, 45, 55)
local WINDOW_TRANSPARENCY = 0.3

-- Limpeza
if playerGui:FindFirstChild("MasterPixelHub") then playerGui.MasterPixelHub:Destroy() end

local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "MasterPixelHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local espTagsFolder = Instance.new("Folder", gui)
espTagsFolder.Name = "ESPTagsFolder"

-- =====================================================
-- FUNÇÕES AUXILIARES DE UI
-- =====================================================
local function addCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = radius or UDim.new(0, 10)
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or STROKE_COLOR
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function createRoundedWindow(titleText, w, h, x, y, windowName)
	local window = Instance.new("Frame")
	window.Size = UDim2.new(0, w, 0, h)
	window.Position = UDim2.new(0, x, 0, y)
	window.BackgroundColor3 = PANEL_BG
	window.BackgroundTransparency = WINDOW_TRANSPARENCY
	window.BorderSizePixel = 0
	window.Visible = false
	window.ClipsDescendants = true
	window.Parent = gui
	window.Name = windowName or titleText
	addCorner(window, UDim.new(0, 12))
	addStroke(window, STROKE_COLOR, 2)

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -2, 1, -2)
	inner.Position = UDim2.new(0, 1, 0, 1)
	inner.BackgroundColor3 = PANEL_BG
	inner.BackgroundTransparency = WINDOW_TRANSPARENCY
	inner.BorderSizePixel = 0
	inner.ClipsDescendants = true
	inner.Parent = window
	addCorner(inner, UDim.new(0, 11))

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 32)
	topBar.BackgroundColor3 = BG_COLOR
	topBar.BackgroundTransparency = WINDOW_TRANSPARENCY
	topBar.BorderSizePixel = 0
	topBar.Parent = inner
	addCorner(topBar, UDim.new(0, 11))

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.Font = FONT_UI
	title.TextSize = 16
	title.TextColor3 = TEXT_COLOR
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = topBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -30, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	closeBtn.BackgroundTransparency = WINDOW_TRANSPARENCY
	closeBtn.Text = "×"
	closeBtn.Font = FONT_UI
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = TEXT_COLOR
	closeBtn.AutoButtonColor = true
	closeBtn.Parent = topBar
	addCorner(closeBtn, UDim.new(1, 0))
	addStroke(closeBtn, Color3.fromRGB(80, 80, 90), 1)

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, 0, 1, -32)
	content.Position = UDim2.new(0, 0, 0, 32)
	content.BackgroundColor3 = PANEL_BG
	content.BackgroundTransparency = WINDOW_TRANSPARENCY
	content.BorderSizePixel = 0
	content.Parent = inner

	-- Frame invisível de arrasto
	local dragArea = Instance.new("TextButton")
	dragArea.Size = UDim2.new(1, 0, 1, 0)
	dragArea.BackgroundTransparency = 1
	dragArea.Text = ""
	dragArea.AutoButtonColor = false
	dragArea.ZIndex = 0
	dragArea.Parent = content

	window.Active = true
	local dragging, dragStart, startPos

	local function onDragStart(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
		end
	end

	local function onDragMove(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end

	local function onDragEnd(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end

	topBar.InputBegan:Connect(onDragStart)
	dragArea.InputBegan:Connect(onDragStart)
	UserInputService.InputChanged:Connect(onDragMove)
	UserInputService.InputEnded:Connect(onDragEnd)

	closeBtn.MouseButton1Click:Connect(function()
		window.Visible = false
	end)

	return window, content
end

-- =====================================================
-- MENU LATERAL
-- =====================================================
local sideMenu = Instance.new("Frame", gui)
sideMenu.Size = UDim2.new(0, 33, 0, 140)
sideMenu.Position = UDim2.new(1, -40, 0.3, 0)
sideMenu.BackgroundTransparency = 1

local sideLayout = Instance.new("UIListLayout", sideMenu)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 8)

local function createMenuBtn(imgId, order)
	local btn = Instance.new("ImageButton", sideMenu)
	btn.Size = UDim2.new(0, 33, 0, 33)
	btn.BackgroundColor3 = BG_COLOR
	btn.BackgroundTransparency = 0.2
	btn.Image = "rbxassetid://" .. imgId
	btn.LayoutOrder = order
	btn.AutoButtonColor = true
	addCorner(btn, UDim.new(0, 8))
	addStroke(btn, Color3.fromRGB(55, 55, 65), 1)
	return btn
end

local btnPainter = createMenuBtn("5300779333", 1)
local btnEditor = createMenuBtn("17132137975", 2)
local btnSettings = createMenuBtn("90175083239155", 3)

-- Janelas
local painterWindow, painterContent = createRoundedWindow("Artes / Cópias", 280, 325, 20, 50, "painter")
local editorWindow, editorContent   = createRoundedWindow("Editor", 380, 318, 50, 50, "editor")
local settingsWindow, settingsContent = createRoundedWindow("Configurações", 250, 350, 80, 50, "settings")

local windows = { painterWindow, editorWindow, settingsWindow }

local function showOnly(target)
	for _, win in ipairs(windows) do
		win.Visible = (win == target)
	end
end

local function toggleWindow(target)
	if target.Visible then
		target.Visible = false
	else
		showOnly(target)
	end
end

btnPainter.MouseButton1Click:Connect(function() toggleWindow(painterWindow) end)
btnEditor.MouseButton1Click:Connect(function() toggleWindow(editorWindow) end)
btnSettings.MouseButton1Click:Connect(function() toggleWindow(settingsWindow) end)

-- =====================================================
-- 1. CONFIGURAÇÕES (SETTINGS)
-- =====================================================
local function buildSettingsGUI(content)
	for _, child in ipairs(content:GetChildren()) do child:Destroy() end

	local setList = Instance.new("UIListLayout", content)
	setList.Padding = UDim.new(0, 8)
	setList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	setList.SortOrder = Enum.SortOrder.LayoutOrder

	-- CÂMERA
	local camFrame = Instance.new("Frame", content)
	camFrame.Size = UDim2.new(1, -20, 0, 40)
	camFrame.BackgroundColor3 = BG_COLOR
	camFrame.BackgroundTransparency = WINDOW_TRANSPARENCY
	camFrame.LayoutOrder = 1
	addCorner(camFrame)

	local posicoesCamera = {
		Vector3.new(-42.43, 4.60, 7.64), Vector3.new(-63.46, 4.60, 8.69),
		Vector3.new(-88.03, 4.60, 7.43), Vector3.new(-43.92, 4.60, -13.81),
		Vector3.new(-87.45, 4.60, -14.51), Vector3.new(-111.12, 4.60, 30.24),
		Vector3.new(-109.87, 4.60, 54.10), Vector3.new(-111.35, 4.60, 78.70),
		Vector3.new(96.13, 6.52, -415.17)
	}
	local idxCam = 1
	local camPart = nil
	local isCameraActive = false
	local followingPlayer = nil
	local followConnection = nil

	local camLeft = Instance.new("ImageButton", camFrame)
	camLeft.Size = UDim2.new(0, 25, 0, 25)
	camLeft.Position = UDim2.new(0, 10, 0.5, -12.5)
	camLeft.Image = "rbxassetid://12338895277"
	camLeft.Rotation = 180
	camLeft.BackgroundTransparency = 1

	local camRight = Instance.new("ImageButton", camFrame)
	camRight.Size = UDim2.new(0, 25, 0, 25)
	camRight.Position = UDim2.new(1, -35, 0.5, -12.5)
	camRight.Image = "rbxassetid://12338895277"
	camRight.BackgroundTransparency = 1

	local camExit = Instance.new("TextButton", camFrame)
	camExit.Size = UDim2.new(0, 80, 1, 0)
	camExit.Position = UDim2.new(0.5, -40, 0, 0)
	camExit.BackgroundTransparency = 1
	camExit.Text = "SAIR"
	camExit.Font = FONT_UI
	camExit.TextColor3 = Color3.fromRGB(255, 100, 100)
	camExit.TextSize = 14

	local function resetCameraToSelf()
		if followingPlayer then
			followingPlayer = nil
			if followConnection then followConnection:Disconnect(); followConnection = nil end
		end
		isCameraActive = false
		camExit.Text = "SAIR"
		if camPart then camPart:Destroy(); camPart = nil end
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			Camera.CameraSubject = player.Character.Humanoid
			Camera.CameraType = Enum.CameraType.Custom
		end
	end

	local function followPlayer(plr)
		if not plr or not plr.Character then return end
		local hum = plr.Character:FindFirstChildOfClass("Humanoid")
		local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
		if hum and hrp then
			if followingPlayer then resetCameraToSelf() end
			if isCameraActive then
				isCameraActive = false
				if camPart then camPart:Destroy(); camPart = nil end
			end
			followingPlayer = plr
			Camera.CameraSubject = hum
			Camera.CameraType = Enum.CameraType.Custom
			camExit.Text = "SEGUINDO " .. plr.DisplayName
			if followConnection then followConnection:Disconnect() end
			followConnection = plr.CharacterAdded:Connect(function(newChar)
				task.wait(0.5)
				if followingPlayer and newChar:FindFirstChild("Humanoid") then
					Camera.CameraSubject = newChar.Humanoid
				end
			end)
		end
	end

	local function irParaCam(pos)
		if followingPlayer then resetCameraToSelf() end
		if camPart then camPart:Destroy() end
		camPart = Instance.new("Part", Workspace)
		camPart.Anchored = true; camPart.CanCollide = false
		camPart.Transparency = 1; camPart.Position = pos
		Camera.CameraSubject = camPart
		Camera.CameraType = Enum.CameraType.Follow
	end

	camLeft.MouseButton1Click:Connect(function()
		if not isCameraActive then
			isCameraActive = true
			idxCam = #posicoesCamera
		else
			idxCam = (idxCam - 1 < 1) and #posicoesCamera or idxCam - 1
		end
		camExit.Text = "SAIR ("..idxCam..")"
		irParaCam(posicoesCamera[idxCam])
	end)

	camRight.MouseButton1Click:Connect(function()
		if not isCameraActive then
			isCameraActive = true
			idxCam = 1
		else
			idxCam = (idxCam + 1 > #posicoesCamera) and 1 or idxCam + 1
		end
		camExit.Text = "SAIR ("..idxCam..")"
		irParaCam(posicoesCamera[idxCam])
	end)

	camExit.MouseButton1Click:Connect(resetCameraToSelf)

	-- INFINITE JUMP & SPEED
	local function createToggleRow(imgId, text)
		local row = Instance.new("Frame", content)
		row.Size = UDim2.new(1, -20, 0, 35)
		row.BackgroundColor3 = BG_COLOR
		row.BackgroundTransparency = WINDOW_TRANSPARENCY
		row.LayoutOrder = 2
		addCorner(row)
		local icn = Instance.new("ImageLabel", row)
		icn.Size = UDim2.new(0, 20, 0, 20)
		icn.Position = UDim2.new(0, 10, 0.5, -10)
		icn.Image = "rbxassetid://" .. imgId
		icn.BackgroundTransparency = 1
		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(0, 100, 1, 0)
		lbl.Position = UDim2.new(0, 40, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.Font = FONT_UI
		lbl.TextColor3 = TEXT_COLOR
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextSize = 14
		return row
	end

	-- Infinite Jump
	local infJumpRow = createToggleRow("6684647765", "Infinite Jump")
	local infJumpBtn = Instance.new("TextButton", infJumpRow)
	infJumpBtn.Size = UDim2.new(0, 40, 0, 20)
	infJumpBtn.Position = UDim2.new(1, -50, 0.5, -10)
	infJumpBtn.Text = "OFF"
	infJumpBtn.Font = FONT_UI
	infJumpBtn.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
	infJumpBtn.TextColor3 = Color3.new(1,1,1)
	addCorner(infJumpBtn)

	local isInfJump = false
	infJumpBtn.MouseButton1Click:Connect(function()
		isInfJump = not isInfJump
		infJumpBtn.Text = isInfJump and "ON" or "OFF"
		infJumpBtn.BackgroundColor3 = isInfJump and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(150, 70, 70)
	end)
	UserInputService.JumpRequest:Connect(function()
		if isInfJump and player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)

	-- Speed
	local speedRow = createToggleRow("6684648436", "Speed")
	local speedInput = Instance.new("TextBox", speedRow)
	speedInput.Size = UDim2.new(0, 40, 0, 20)
	speedInput.Position = UDim2.new(1, -50, 0.5, -10)
	speedInput.Text = "16"
	speedInput.Font = FONT_UI
	speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	speedInput.TextColor3 = Color3.new(1,1,1)
	addCorner(speedInput)
	speedInput.FocusLost:Connect(function()
		local spd = tonumber(speedInput.Text)
		if spd and player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = spd
		else
			speedInput.Text = "16"
		end
	end)

	-- ESP
	local espRow = createToggleRow("86821503536548", "Ativar ESP")
	local espBtn = Instance.new("TextButton", espRow)
	espBtn.Size = UDim2.new(0, 40, 0, 20)
	espBtn.Position = UDim2.new(1, -50, 0.5, -10)
	espBtn.Text = "OFF"
	espBtn.Font = FONT_UI
	espBtn.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
	espBtn.TextColor3 = Color3.new(1,1,1)
	addCorner(espBtn)

	local espEnabled = false
	local espConnections = {}

	local function removeESP(char)
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
			if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
			local tag = espTagsFolder:FindFirstChild("ESPTag_" .. char.Name)
			if tag then tag:Destroy() end
		end
	end

	local function applyESP(plr, char)
		if not espEnabled or not char then return end
		local hum = char:WaitForChild("Humanoid", 3)
		local hrp = char:WaitForChild("HumanoidRootPart", 3)
		if not hum or not hrp then return end

		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		local hl = Instance.new("Highlight")
		hl.Name = "ESPHighlight"
		hl.Adornee = char
		hl.FillTransparency = 1
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		if plr == player then
			hl.OutlineColor = Color3.fromRGB(100, 150, 255)
		elseif player:IsFriendsWith(plr.UserId) then
			hl.OutlineColor = Color3.fromRGB(180, 100, 255)
		else
			hl.OutlineColor = Color3.fromRGB(255, 100, 100)
		end
		hl.Parent = char

		local bg = Instance.new("BillboardGui")
		bg.Name = "ESPTag_" .. char.Name
		bg.Adornee = hrp
		bg.Size = UDim2.new(0, 120, 0, 40)
		bg.StudsOffset = Vector3.new(0, 3.5, 0)
		bg.AlwaysOnTop = true
		bg.Active = true

		local txt = Instance.new("TextLabel", bg)
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.Text = plr.DisplayName
		txt.TextColor3 = hl.OutlineColor
		txt.Font = FONT_UI
		txt.TextSize = 14
		txt.TextStrokeTransparency = 0.5

		local followIndicator = Instance.new("TextLabel", bg)
		followIndicator.Size = UDim2.new(1,0,0,14)
		followIndicator.Position = UDim2.new(0,0,1,2)
		followIndicator.BackgroundTransparency = 1
		followIndicator.Text = ""
		followIndicator.TextColor3 = Color3.fromRGB(255,255,100)
		followIndicator.Font = FONT_UI
		followIndicator.TextSize = 10

		local tapBtn = Instance.new("TextButton", bg)
		tapBtn.Size = UDim2.new(1,0,1,0)
		tapBtn.BackgroundTransparency = 1
		tapBtn.Text = ""
		tapBtn.ZIndex = 10
		tapBtn.AutoButtonColor = false

		local lastTap = 0
		tapBtn.Activated:Connect(function()
			if tick() - lastTap < 0.5 then
				if followingPlayer == plr then
					resetCameraToSelf()
					followIndicator.Text = ""
					txt.Text = plr.DisplayName
				else
					followPlayer(plr)
					followIndicator.Text = "▶ seguindo"
					txt.Text = plr.DisplayName
				end
			else
				task.delay(1.5, function()
					if followingPlayer ~= plr then
						followIndicator.Text = ""
						txt.Text = plr.DisplayName
					end
				end)
			end
			lastTap = tick()
		end)

		bg.Parent = espTagsFolder
	end

	local function refreshAllESP()
		for _, p in pairs(Players:GetPlayers()) do
			removeESP(p.Character)
			if espEnabled and p.Character then
				task.spawn(function() applyESP(p, p.Character) end)
			end
		end
	end

	espBtn.MouseButton1Click:Connect(function()
		espEnabled = not espEnabled
		espBtn.Text = espEnabled and "ON" or "OFF"
		espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(150, 70, 70)
		refreshAllESP()
	end)

	Players.PlayerAdded:Connect(function(plr)
		espConnections[plr.Name] = plr.CharacterAdded:Connect(function(char)
			if espEnabled then task.wait(0.5); applyESP(plr, char) end
		end)
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if espConnections[plr.Name] then
			espConnections[plr.Name]:Disconnect()
			espConnections[plr.Name] = nil
		end
		local tag = espTagsFolder:FindFirstChild("ESPTag_" .. plr.Name)
		if tag then tag:Destroy() end
		if followingPlayer == plr then resetCameraToSelf() end
	end)

	for _, plr in pairs(Players:GetPlayers()) do
		espConnections[plr.Name] = plr.CharacterAdded:Connect(function(char)
			if espEnabled then task.wait(0.5); applyESP(plr, char) end
		end)
	end

	-- LISTA DE AMIGOS
	local friendTitle = Instance.new("TextLabel", content)
	friendTitle.Size = UDim2.new(1, -20, 0, 20)
	friendTitle.BackgroundTransparency = 1
	friendTitle.Text = "Amigos no Servidor:"
	friendTitle.Font = FONT_UI
	friendTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	friendTitle.TextXAlignment = Enum.TextXAlignment.Left
	friendTitle.LayoutOrder = 3

	local friendScroll = Instance.new("ScrollingFrame", content)
	friendScroll.Size = UDim2.new(1, -20, 0, 70)
	friendScroll.BackgroundColor3 = BG_COLOR
	friendScroll.BackgroundTransparency = WINDOW_TRANSPARENCY
	friendScroll.ScrollBarThickness = 2
	friendScroll.LayoutOrder = 4
	addCorner(friendScroll)

	local friendLayout = Instance.new("UIListLayout", friendScroll)
	friendLayout.Padding = UDim.new(0, 5)

	local function updateFriendList()
		for _, c in ipairs(friendScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local friendsFound = false
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and player:IsFriendsWith(p.UserId) then
				friendsFound = true
				local fRow = Instance.new("Frame", friendScroll)
				fRow.Size = UDim2.new(1, -5, 0, 30)
				fRow.BackgroundTransparency = 1
				local avatar = Instance.new("ImageLabel", fRow)
				avatar.Size = UDim2.new(0, 26, 0, 26)
				avatar.Position = UDim2.new(0, 2, 0, 2)
				avatar.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				addCorner(avatar, UDim.new(1,0))
				local fName = Instance.new("TextLabel", fRow)
				fName.Size = UDim2.new(1, -35, 1, 0)
				fName.Position = UDim2.new(0, 35, 0, 0)
				fName.BackgroundTransparency = 1
				fName.Text = p.DisplayName
				fName.Font = FONT_UI
				fName.TextColor3 = TEXT_COLOR
				fName.TextXAlignment = Enum.TextXAlignment.Left
				fName.TextSize = 13
			end
		end
		if not friendsFound then
			local empty = Instance.new("TextLabel", friendScroll)
			empty.Size = UDim2.new(1,0,1,0)
			empty.BackgroundTransparency = 1
			empty.Text = "Nenhum amigo aqui :("
			empty.Font = FONT_UI
			empty.TextColor3 = Color3.fromRGB(150,150,150)
		end
		friendScroll.CanvasSize = UDim2.new(0, 0, 0, friendLayout.AbsoluteContentSize.Y)
	end
	task.spawn(function() while task.wait(10) do updateFriendList() end end)
	updateFriendList()
end
buildSettingsGUI(settingsContent)

-- =====================================================
-- 2. MÓDULO PAINTER (ARTES / CÓPIAS / ANIMAÇÕES)
-- =====================================================
local function buildPainterGUI(content)
	for _, child in ipairs(content:GetChildren()) do child:Destroy() end

	local remote = game.ReplicatedStorage:FindFirstChild("UpdateBoard") or workspace:FindFirstChild("UpdateBoard", true)
	local upgradeCanvas = game.ReplicatedStorage:FindFirstChild("UpgradeCanvasSize") or workspace:FindFirstChild("UpgradeCanvasSize", true)
	local GAMEPASS_ID = 681945725

	local currentGRID = 32
	local currentTOTAL = 1024

	-- ⬇⬇⬇ SLOTS (BOT EDITA AQUI) ⬇⬇⬇
	local ARTS = {
		{ name = "Bad Apple", playlist = "Vídeos", map = [[ANIM|32|3600|...]] },
		{ name = "Exemplo Base", playlist = "Todas", map = [[
Pixel 1 = FF0000 | Pixel 2 = 00FF00 | Pixel 3 = 0000FF
		]] },
	}
	-- ⬆⬆⬆ FIM DOS SLOTS ⬆⬆⬆

	local PLAYLISTS = {"Todas", "Cópias", "Aleatórias", "NSFW", "Memes", "Players", "Vídeos"}
	local selectedMap = nil
	local selectedArtName = ""
	local selectedArtSize = "32x32"
	local isPainting = false
	local currentPlaylist = "Todas"
	local isCopySelected = false

	-- Helpers
	local function getArtSize(mapText)
		if mapText:sub(1,4) == "ANIM" then return 32 end
		local maxPixel = 0
		for idx in mapText:gmatch("Pixel%s+(%d+)") do
			local n = tonumber(idx)
			if n and n > maxPixel then maxPixel = n end
		end
		return (maxPixel <= 256) and 16 or 32
	end

	local function logicalToBoardIndex(pixel, g)
		local zero = pixel - 1
		local y = math.floor(zero / g)
		local x = zero % g
		return y * g + ((g - 1) - x) + 1
	end

	local function getMyBoard()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj.Name == "1" and obj:IsA("BasePart") and obj.Parent:FindFirstChild(tostring(currentTOTAL)) then
				return obj.Parent
			end
		end
		return nil
	end

	local function getBoardGridSize(container)
		local maxIdx = 0
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("BasePart") then
				local num = tonumber(child.Name)
				if num and num > maxIdx then maxIdx = num end
			end
		end
		return (maxIdx >= 1024) and 32 or 16
	end

	local function getFullArtData(mapText, defaultHex)
		local art = {}
		for i = 1, currentTOTAL do art[i] = defaultHex end
		if mapText:sub(1,4) == "ANIM" then return art end
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
			local boardIdx = logicalToBoardIndex(i, currentGRID)
			local pixelPart = board:FindFirstChild(tostring(boardIdx))
			if pixelPart and pixelPart:IsA("BasePart") then
				local target = hexToColor3(desiredHex)
				local diff = (pixelPart.Color.R - target.R)^2 + (pixelPart.Color.G - target.G)^2 + (pixelPart.Color.B - target.B)^2
				if diff > 0.001 then needUpdate = needUpdate + 1 end
			end
		end
		setProgress(needUpdate == 0 and "Arte Feita ✅" or "Pronto para pintar!")
	end

	-- ===== FUNÇÃO PRINCIPAL (COM 20 FPS) =====
	local function startSmartPaint(updateBar, setProgress)
		if isPainting or not selectedMap or not remote then
			setProgress("❌ SEM ARTE SELECIONADA")
			task.wait(1.5)
			local board = getMyBoard()
			checkArtStatus(board, getFullArtData(selectedMap, "000000"), setProgress)
			return
		end

		-- ═══════════════════════════════════════
		-- MODO ANIMAÇÃO (20 FPS)
		-- ═══════════════════════════════════════
		if selectedMap:sub(1,4) == "ANIM" then
			local parts = selectedMap:split("|")
			if #parts < 4 then
				setProgress("❌ Animação corrompida")
				return
			end
			local animSize = tonumber(parts[2]) or 32
			local totalFrames = tonumber(parts[3])
			local frameStrs = {}
			for i = 4, #parts do
				table.insert(frameStrs, parts[i])
			end
			if #frameStrs ~= totalFrames then
				setProgress("❌ Número de frames inconsistente")
				return
			end

			isPainting = true
			local board = getMyBoard()
			if not board then
				setProgress("❌ QUADRO NÃO ENCONTRADO")
				isPainting = false
				return
			end

			local boardGrid = getBoardGridSize(board)
			if animSize == 32 and boardGrid == 16 then
				setProgress("🔄 Expandindo quadro para 32x32...")
				if not upgradeCanvas then
					setProgress("❌ Upgrade não disponível")
					isPainting = false
					return
				end
				local hasPass = false
				pcall(function() hasPass = game:GetService("MarketplaceService"):UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID) end)
				if not hasPass then
					setProgress("⚠️ Gamepass necessária para 32x32!")
					isPainting = false
					return
				end
				upgradeCanvas:FireServer()
				local startTime = tick()
				repeat task.wait(0.2) board = getMyBoard() until (board and getBoardGridSize(board) == 32) or tick()-startTime > 3
				if not board or getBoardGridSize(board) ~= 32 then
					setProgress("❌ Falha ao expandir")
					isPainting = false
					return
				end
			end

			-- 🔥 USANDO 20 FPS (delay de 0.05 segundos)
			local frameDelay = 0.05
			local fps = 20
			for frameIdx = 1, totalFrames do
				if not isPainting then break end
				local frameStr = frameStrs[frameIdx]
				local packet = {}
				for i = 1, animSize * animSize do
					local hex = frameStr:sub((i-1)*6+1, i*6)
					local boardIdx = logicalToBoardIndex(i, animSize)
					packet[tostring(boardIdx)] = hex
				end
				pcall(function() remote:InvokeServer(packet) end)
				updateBar(frameIdx / totalFrames)
				setProgress(string.format("▶ %d/%d (%.0f fps)", frameIdx, totalFrames, fps))
				task.wait(frameDelay)
			end

			if isPainting then
				setProgress("✅ Animação concluída")
				updateBar(1)
				task.wait(1.5)
			end
			isPainting = false
			return
		end

		-- ═══════════════════════════════════════
		-- CÓDIGO ORIGINAL PARA ARTES ESTÁTICAS
		-- ═══════════════════════════════════════
		isPainting = true
		local board = getMyBoard()
		if not board then
			setProgress("❌ QUADRO NÃO ENCONTRADO")
			task.wait(2)
			isPainting = false
			return
		end

		local boardGrid = getBoardGridSize(board)
		if boardGrid ~= currentGRID then
			if currentGRID == 32 and boardGrid == 16 then
				setProgress("🔄 Expandindo quadro para 32x32...")
				if not upgradeCanvas then
					setProgress("❌ Upgrade não disponível")
					task.wait(2)
					isPainting = false
					return
				end
				local hasPass = false
				pcall(function() hasPass = game:GetService("MarketplaceService"):UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID) end)
				if not hasPass then
					setProgress("⚠️ Você precisa da gamepass para quadros 32x32!")
					task.wait(3)
					isPainting = false
					return
				end
				upgradeCanvas:FireServer()
				local startTime = tick()
				repeat
					task.wait(0.2)
					board = getMyBoard()
					if board and getBoardGridSize(board) == 32 then break end
				until tick() - startTime > 3
				if not board or getBoardGridSize(board) ~= 32 then
					setProgress("❌ Falha ao expandir o quadro")
					task.wait(2)
					isPainting = false
					return
				end
			elseif currentGRID == 16 and boardGrid == 32 then
				setProgress("⚠️ Quadro 32x32 não pode ser reduzido. Arte será pintada no canto superior esquerdo.")
				task.wait(3)
				local art16 = getFullArtData(selectedMap, "000000")
				local newMapLines = {}
				for i = 1, 1024 do
					local desiredHex = "000000"
					if i <= 256 then
						local zero = i - 1
						local y16 = math.floor(zero / 16)
						local x16 = zero % 16
						local boardIdx16 = y16 * 16 + ((16 - 1) - x16) + 1
						local hex16 = art16[boardIdx16] or "000000"
						local i32 = y16 * 32 + x16 + 1
						desiredHex = hex16
					end
					table.insert(newMapLines, string.format("Pixel %d = %s", i, desiredHex))
				end
				selectedMap = table.concat(newMapLines, " | ")
				selectedArtSize = "16x16 (sobre 32x32)"
			end
		end

		local finalArt = getFullArtData(selectedMap, "000000")
		local needUpdate = {}
		setProgress("🔍 Escaneando quadro...")

		if isCopySelected then
			for i = 1, currentTOTAL do
				local boardIdx = logicalToBoardIndex(i, currentGRID)
				table.insert(needUpdate, {id = tostring(boardIdx), color = finalArt[i]})
			end
		else
			for i = 1, currentTOTAL do
				local desiredHex = finalArt[i]
				local boardIdx = logicalToBoardIndex(i, currentGRID)
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

	-- CÓPIAS
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

	local function extractRealUsername(rootName)
		local name = rootName:gsub("^PixelArtBoard_", ""):gsub("^PixelArtBoard", "")
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
							local ownerPlayer = nil
							for _, plr in ipairs(Players:GetPlayers()) do
								if plr.Name:lower() == realUsername:lower() then
									ownerPlayer = plr
									break
								end
							end
							local isOwned = (ownerPlayer ~= nil)
							local finalName = isOwned and ownerPlayer.DisplayName or nil
							local isSelf = (isOwned and ownerPlayer == player)
							if not isSelf then
								local isEmpty = isBoardEmpty(parent, grid)
								table.insert(rawBoards, {
									container = parent, grid = grid, isEmpty = isEmpty,
									isOwned = isOwned, finalName = finalName, realUsername = realUsername
								})
							end
						end
					end
				end
			end
		end
		local owned, unowned = {}, {}
		for _, b in ipairs(rawBoards) do
			if b.isOwned then table.insert(owned, b) else table.insert(unowned, b) end
		end
		table.sort(owned, function(a,b) return a.finalName:lower() < b.finalName:lower() end)
		for idx, b in ipairs(unowned) do b.finalName = "quadro " .. idx end
		local all = {}
		for _, b in ipairs(owned) do table.insert(all, b) end
		for _, b in ipairs(unowned) do table.insert(all, b) end
		for _, b in ipairs(all) do if b.isEmpty then b.finalName = b.finalName .. " (vazio)" end end
		return all
	end

	local function generateFullMapFromBoard(container, grid)
		local mapLines = {}
		local total = grid * grid
		for logicalIdx = 1, total do
			local physicalIdx = logicalToBoardIndex(logicalIdx, grid)
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

	local function refreshCopiesPlaylist(artScroll, createPreviewFn, updatePreviewFn, updateInfoFn, setProgressFn, updateBarFn)
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
			btn.Font = FONT_UI
			addCorner(btn)
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
				checkArtStatus(board, getFullArtData(selectedMap, "000000"), setProgressFn)
			end)
		end
	end

	-- Montagem da interface
	local main = content

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
	addCorner(progBg)
	local progBar = Instance.new("Frame", progBg)
	progBar.Size = UDim2.new(0, 0, 1, 0)
	progBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
	addCorner(progBar)
	local progTxt = Instance.new("TextLabel", progBg)
	progTxt.Size = UDim2.new(1, 0, 1, 0)
	progTxt.BackgroundTransparency = 1
	progTxt.Text = "Aguardando..."
	progTxt.TextColor3 = Color3.new(1,1,1)
	progTxt.TextSize = 11
	progTxt.Font = FONT_UI

	-- Botão iniciar
	local startBtn = Instance.new("TextButton", main)
	startBtn.Size = UDim2.new(0, 130, 0, 35)
	startBtn.Position = UDim2.new(0, 140, 0, 215)
	startBtn.Text = "INICIAR ARTE"
	startBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	startBtn.TextColor3 = Color3.new(1,1,1)
	startBtn.TextSize = 13
	startBtn.Font = FONT_UI
	addCorner(startBtn)

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
	infoLabel.Font = FONT_UI
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.TextWrapped = true

	local function updateBar(percent) progBar.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0) end
	local function setProgress(txt) progTxt.Text = txt end
	local function updateInfo()
		infoLabel.Text = "Nome: " .. selectedArtName .. "\nTamanho: " .. selectedArtSize
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
		if mapText:sub(1,4) == "ANIM" then
			for i = 1, #pixels do pixels[i].BackgroundColor3 = Color3.fromRGB(20,20,20) end
			return
		end
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
			refreshCopiesPlaylist(artScroll, createPreview, updatePreview, updateInfo, setProgress, updateBar)
			task.spawn(function()
				while currentPlaylist == "Cópias" and painterWindow.Visible do
					task.wait(5)
					refreshCopiesPlaylist(artScroll, createPreview, updatePreview, updateInfo, setProgress, updateBar)
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
				btn.Font = FONT_UI
				addCorner(btn)
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
					if art.map:sub(1,4) ~= "ANIM" then
						local board = getMyBoard()
						checkArtStatus(board, getFullArtData(selectedMap, "000000"), setProgress)
					else
						setProgress("Animação pronta para tocar")
					end
				end)
			end
		end
	end

	for _, name in ipairs(PLAYLISTS) do
		local plBtn = Instance.new("TextButton", plFrame)
		plBtn.Size = UDim2.new(0, 75, 1, 0)
		plBtn.Text = name
		plBtn.TextScaled = true
		plBtn.TextWrapped = true
		plBtn.BackgroundColor3 = (name == "Todas") and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(45, 45, 50)
		plBtn.TextColor3 = Color3.new(1,1,1)
		plBtn.Font = FONT_UI
		addCorner(plBtn)
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
buildPainterGUI(painterContent)

-- =====================================================
-- 3. MÓDULO EDITOR (inalterado)
-- =====================================================
local function buildEditorGUI(content)
	-- ... (mantenha o código do editor igual ao original)
end
buildEditorGUI(editorContent)

-- Nenhuma janela inicia aberta
print("Master Pixel Hub V3.4 — com suporte a Bad Apple a 20 FPS — carregado.")
