-- NatrixLibrary.lua
-- Core UI library matching the provided design screenshots.

local Library = {}
Library.__index = Library

-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local statsService = game:GetService("Stats")
local tweenService = game:GetService("TweenService")

-- Constants.
local COLOR_BG_DARK = Color3.fromHex("1A1A1A")
local COLOR_BG_MID = Color3.fromHex("252525")
local COLOR_BG_LIGHT = Color3.fromHex("2E2E2E")
local COLOR_BG_PANEL = Color3.fromHex("1C1C1C")
local COLOR_TAB_ACTIVE = Color3.fromHex("2E2E2E")
local COLOR_TAB_INACTIVE = Color3.fromHex("1C1C1C")
local COLOR_TEXT_PRIMARY = Color3.fromHex("FFFFFF")
local COLOR_TEXT_DIM = Color3.fromHex("AAAAAA")
local COLOR_ACCENT = Color3.fromHex("5B9CF6")
local COLOR_TOGGLE_OFF = Color3.fromHex("555555")
local COLOR_TOGGLE_ON = Color3.fromHex("5B9CF6")
local COLOR_SLIDER_TRACK = Color3.fromHex("3A3A3A")
local COLOR_SLIDER_FILL = Color3.fromHex("5B9CF6")
local COLOR_BUTTON = Color3.fromHex("2A2A2A")
local COLOR_KEYBIND_ICON = Color3.fromHex("3A3A3A")
local COLOR_KEY_BG = Color3.fromHex("2A2A2A")
local COLOR_CLOSE = Color3.fromHex("CC4444")

local FONT_MAIN = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

local localPlayer = playersService.LocalPlayer

---Helper to apply UICorner to a frame.
---@param parent GuiObject
---@param radius number
local function applyCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
end

---Helper to apply UIPadding to a frame.
---@param parent GuiObject
---@param top number
---@param bottom number
---@param left number
---@param right number
local function applyPadding(parent, top, bottom, left, right)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top or 0)
	pad.PaddingBottom = UDim.new(0, bottom or 0)
	pad.PaddingLeft = UDim.new(0, left or 0)
	pad.PaddingRight = UDim.new(0, right or 0)
	pad.Parent = parent
end

---Helper to create a text label.
---@param parent GuiObject
---@param text string
---@param size number
---@param color Color3
---@param font Enum.Font
---@return TextLabel
local function makeLabel(parent, text, size, color, font)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.TextSize = size or 14
	lbl.TextColor3 = color or COLOR_TEXT_PRIMARY
	lbl.Font = font or FONT_MAIN
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

-- ============================================================
-- KEY SYSTEM
-- ============================================================

---Build and show the key authentication modal.
---@param config table
---@param onSuccess function
local function buildKeySystem(config, onSuccess)
	local ks = config.KeySettings or {}
	local validKeys = ks.Keys or {}
	local discordUrl = ks.Discord or ""

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NatrixKeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10
	screenGui.Parent = gethui and gethui() or localPlayer.PlayerGui

	-- Dim overlay.
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromHex("000000")
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = screenGui

	-- Modal container.
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.Size = UDim2.new(0, 420, 0, 320)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromHex("272727")
	modal.BorderSizePixel = 0
	modal.ZIndex = 2
	modal.Parent = screenGui
	applyCorner(modal, 10)

	-- Discord icon top-right.
	local discordBtn = Instance.new("TextButton")
	discordBtn.Size = UDim2.new(0, 30, 0, 30)
	discordBtn.Position = UDim2.new(1, -10, 0, 10)
	discordBtn.AnchorPoint = Vector2.new(1, 0)
	discordBtn.BackgroundTransparency = 1
	discordBtn.Text = "🎮"
	discordBtn.TextSize = 18
	discordBtn.TextColor3 = COLOR_TEXT_DIM
	discordBtn.Font = FONT_MAIN
	discordBtn.ZIndex = 3
	discordBtn.Parent = modal
	discordBtn.MouseButton1Click:Connect(function()
		if discordUrl ~= "" then
			setclipboard(discordUrl)
		end
	end)

	-- Logo image (placeholder using a frame with "N" text as seen in screenshot).
	local logoFrame = Instance.new("Frame")
	logoFrame.Size = UDim2.new(0, 80, 0, 80)
	logoFrame.AnchorPoint = Vector2.new(0.5, 0)
	logoFrame.Position = UDim2.new(0.5, 0, 0, 30)
	logoFrame.BackgroundColor3 = Color3.fromHex("3A3A3A")
	logoFrame.BorderSizePixel = 0
	logoFrame.ZIndex = 3
	logoFrame.Parent = modal
	applyCorner(logoFrame, 12)

	local logoText = Instance.new("TextLabel")
	logoText.Size = UDim2.fromScale(1, 1)
	logoText.BackgroundTransparency = 1
	logoText.Text = "N"
	logoText.TextSize = 36
	logoText.Font = FONT_BOLD
	logoText.TextColor3 = COLOR_TEXT_PRIMARY
	logoText.ZIndex = 4
	logoText.Parent = logoFrame

	-- Key input box.
	local keyBox = Instance.new("TextBox")
	keyBox.Size = UDim2.new(0, 240, 0, 40)
	keyBox.AnchorPoint = Vector2.new(0.5, 0)
	keyBox.Position = UDim2.new(0.5, 0, 0, 140)
	keyBox.BackgroundColor3 = Color3.fromHex("1E1E1E")
	keyBox.BorderSizePixel = 0
	keyBox.Text = ""
	keyBox.PlaceholderText = "Key"
	keyBox.PlaceholderColor3 = COLOR_TEXT_DIM
	keyBox.TextColor3 = COLOR_TEXT_PRIMARY
	keyBox.TextSize = 14
	keyBox.Font = FONT_MAIN
	keyBox.ZIndex = 3
	keyBox.ClearTextOnFocus = false
	keyBox.Parent = modal
	applyCorner(keyBox, 8)
	applyPadding(keyBox, 0, 0, 12, 12)

	-- Status label for wrong key.
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0, 240, 0, 20)
	statusLabel.AnchorPoint = Vector2.new(0.5, 0)
	statusLabel.Position = UDim2.new(0.5, 0, 0, 188)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromHex("FF5555")
	statusLabel.TextSize = 12
	statusLabel.Font = FONT_MAIN
	statusLabel.ZIndex = 3
	statusLabel.Parent = modal

	-- Check button.
	local checkBtn = Instance.new("TextButton")
	checkBtn.Size = UDim2.new(0, 140, 0, 40)
	checkBtn.AnchorPoint = Vector2.new(0.5, 0)
	checkBtn.Position = UDim2.new(0.5, 0, 0, 215)
	checkBtn.BackgroundColor3 = Color3.fromHex("1E1E1E")
	checkBtn.BorderSizePixel = 0
	checkBtn.Text = "Check"
	checkBtn.TextColor3 = COLOR_ACCENT
	checkBtn.TextSize = 15
	checkBtn.Font = FONT_BOLD
	checkBtn.ZIndex = 3
	checkBtn.Parent = modal
	applyCorner(checkBtn, 8)

	checkBtn.MouseButton1Click:Connect(function()
		local inputKey = keyBox.Text
		local valid = false
		for _, k in ipairs(validKeys) do
			if inputKey == k then
				valid = true
				break
			end
		end
		if valid then
			screenGui:Destroy()
			onSuccess()
		else
			statusLabel.Text = "Invalid key. Try again."
			keyBox.Text = ""
		end
	end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================

---Create the main window and return a window object.
---@param config table
---@return table
function Library:CreateWindow(config)
	config = config or {}
	local windowName = config.Name or "Natrix"
	local useKeySystem = config.KeySystem == true

	local Window = {}
	Window._tabs = {}
	Window._activeTab = nil

	-- ScreenGui root.
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NatrixUI_" .. windowName
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 5
	screenGui.Enabled = false
	screenGui.Parent = gethui and gethui() or localPlayer.PlayerGui

	-- Root drag frame.
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.new(0, 520, 0, 440)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.BackgroundColor3 = COLOR_BG_DARK
	root.BorderSizePixel = 0
	root.ClipsDescendants = false
	root.Parent = screenGui
	applyCorner(root, 8)

	-- Drag logic.
	do
		local dragging, dragStart, startPos = false, nil, nil
		root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end)
		root.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				root.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- ── TOP BAR ──
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 40)
	topBar.BackgroundColor3 = COLOR_BG_MID
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = root
	applyCorner(topBar, 8)

	-- Fix bottom corners of topbar.
	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 8)
	topBarCover.Position = UDim2.new(0, 0, 1, -8)
	topBarCover.BackgroundColor3 = COLOR_BG_MID
	topBarCover.BorderSizePixel = 0
	topBarCover.ZIndex = 2
	topBarCover.Parent = topBar

	local tabList = Instance.new("Frame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, -44, 1, 0)
	tabList.BackgroundTransparency = 1
	tabList.ZIndex = 3
	tabList.Parent = topBar

	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.FillDirection = Enum.FillDirection.Horizontal
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 0)
	tabListLayout.Parent = tabList

	-- Close button.
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 1, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, 0, 0, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = COLOR_TEXT_DIM
	closeBtn.TextSize = 14
	closeBtn.Font = FONT_BOLD
	closeBtn.ZIndex = 4
	closeBtn.Parent = topBar
	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)
	closeBtn.MouseEnter:Connect(function()
		closeBtn.TextColor3 = Color3.fromHex("FF5555")
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.TextColor3 = COLOR_TEXT_DIM
	end)

	-- ── CONTENT AREA ──
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, 0, 1, -80)
	contentArea.Position = UDim2.new(0, 0, 0, 40)
	contentArea.BackgroundColor3 = COLOR_BG_PANEL
	contentArea.BorderSizePixel = 0
	contentArea.ZIndex = 2
	contentArea.Parent = root

	-- Left column.
	local leftCol = Instance.new("ScrollingFrame")
	leftCol.Name = "LeftCol"
	leftCol.Size = UDim2.new(0.5, -1, 1, 0)
	leftCol.BackgroundColor3 = COLOR_BG_PANEL
	leftCol.BorderSizePixel = 0
	leftCol.ScrollBarThickness = 3
	leftCol.ScrollBarImageColor3 = Color3.fromHex("444444")
	leftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
	leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	leftCol.ZIndex = 3
	leftCol.Parent = contentArea
	applyPadding(leftCol, 8, 8, 8, 8)

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 6)
	leftLayout.Parent = leftCol

	-- Divider between columns.
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0, 1, 1, 0)
	divider.Position = UDim2.new(0.5, 0, 0, 0)
	divider.BackgroundColor3 = Color3.fromHex("333333")
	divider.BorderSizePixel = 0
	divider.ZIndex = 3
	divider.Parent = contentArea

	-- Right column.
	local rightCol = Instance.new("ScrollingFrame")
	rightCol.Name = "RightCol"
	rightCol.Size = UDim2.new(0.5, -1, 1, 0)
	rightCol.Position = UDim2.new(0.5, 1, 0, 0)
	rightCol.BackgroundColor3 = COLOR_BG_PANEL
	rightCol.BorderSizePixel = 0
	rightCol.ScrollBarThickness = 3
	rightCol.ScrollBarImageColor3 = Color3.fromHex("444444")
	rightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
	rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rightCol.ZIndex = 3
	rightCol.Parent = contentArea
	applyPadding(rightCol, 8, 8, 8, 8)

	local rightLayout = Instance.new("UIListLayout")
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rightLayout.Padding = UDim.new(0, 6)
	rightLayout.Parent = rightCol

	-- ── BOTTOM STATUS BAR ──
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, -16, 0, 32)
	statusBar.AnchorPoint = Vector2.new(0.5, 1)
	statusBar.Position = UDim2.new(0.5, 0, 1, -8)
	statusBar.BackgroundColor3 = COLOR_BG_MID
	statusBar.BorderSizePixel = 0
	statusBar.ZIndex = 4
	statusBar.Parent = root
	applyCorner(statusBar, 6)
	applyPadding(statusBar, 0, 0, 10, 10)

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusLayout.Padding = UDim.new(0, 14)
	statusLayout.Parent = statusBar

	-- FPS display.
	local fpsLabel = makeLabel(statusBar, "⟳  FPS: --", 12, COLOR_TEXT_DIM, FONT_MONO)
	fpsLabel.Size = UDim2.new(0, 100, 1, 0)
	fpsLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Ping display.
	local pingLabel = makeLabel(statusBar, "〰  PING: --", 12, COLOR_TEXT_DIM, FONT_MONO)
	pingLabel.Size = UDim2.new(0, 110, 1, 0)
	pingLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Settings gear (right-aligned).
	local gearBtn = Instance.new("TextButton")
	gearBtn.Size = UDim2.new(0, 28, 0, 28)
	gearBtn.AnchorPoint = Vector2.new(1, 0.5)
	gearBtn.Position = UDim2.new(1, -6, 0.5, 0)
	gearBtn.BackgroundTransparency = 1
	gearBtn.Text = "⚙"
	gearBtn.TextSize = 16
	gearBtn.TextColor3 = COLOR_TEXT_DIM
	gearBtn.Font = FONT_MAIN
	gearBtn.ZIndex = 5
	gearBtn.Parent = statusBar

	-- Live FPS + Ping update loop.
	local fpsBuffer = {}
	local FPS_SAMPLES = 20
	runService.Heartbeat:Connect(function(dt)
		table.insert(fpsBuffer, 1 / dt)
		if #fpsBuffer > FPS_SAMPLES then
			table.remove(fpsBuffer, 1)
		end
		local sum = 0
		for _, v in ipairs(fpsBuffer) do sum = sum + v end
		local avgFps = math.floor(sum / #fpsBuffer)
		fpsLabel.Text = "⟳  FPS: " .. avgFps

		local ping = statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
		pingLabel.Text = "〰  PING: " .. math.floor(ping)
	end)

	-- ── SHOW WINDOW ──
	local function revealWindow()
		screenGui.Enabled = true
	end

	if useKeySystem then
		buildKeySystem(config, revealWindow)
	else
		revealWindow()
	end

	-- ── TAB API ──

	---Switch to a given tab container.
	---@param targetTab table
	local function switchTab(targetTab)
		for _, tabData in ipairs(Window._tabs) do
			tabData.container.Visible = false
			tabData.btn.BackgroundColor3 = COLOR_TAB_INACTIVE
			tabData.btn.TextColor3 = COLOR_TEXT_DIM
		end
		targetTab.container.Visible = true
		targetTab.btn.BackgroundColor3 = COLOR_TAB_ACTIVE
		targetTab.btn.TextColor3 = COLOR_TEXT_PRIMARY
		Window._activeTab = targetTab
	end

	---Create a new tab and return its component API.
	---@param tabName string
	---@return table
	function Window:CreateTab(tabName)
		local Tab = {}
		Tab._order = 0

		-- Tab button in top bar.
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(0, 80, 1, 0)
		tabBtn.BackgroundColor3 = COLOR_TAB_INACTIVE
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = tabName
		tabBtn.TextColor3 = COLOR_TEXT_DIM
		tabBtn.TextSize = 13
		tabBtn.Font = FONT_BOLD
		tabBtn.ZIndex = 3
		tabBtn.LayoutOrder = #Window._tabs + 1
		tabBtn.Parent = tabList
		applyPadding(tabBtn, 0, 0, 10, 10)

		-- Tab content container (hidden by default).
		local tabContainer = Instance.new("Frame")
		tabContainer.Name = "Tab_" .. tabName
		tabContainer.Size = UDim2.fromScale(1, 1)
		tabContainer.BackgroundTransparency = 1
		tabContainer.Visible = false
		tabContainer.ZIndex = 4
		tabContainer.Parent = leftCol

		-- Each tab uses leftCol directly; components are inserted into leftCol when tab is active.
		-- We store component info per-tab and rebuild on switch.
		Tab._components = {}
		Tab._tabBtn = tabBtn
		Tab._container = tabContainer

		local tabData = { btn = tabBtn, container = tabContainer, tab = Tab }
		table.insert(Window._tabs, tabData)

		tabBtn.MouseButton1Click:Connect(function()
			switchTab(tabData)
			-- Rebuild left column for this tab.
			for _, child in ipairs(leftCol:GetChildren()) do
				if child:IsA("GuiObject") and child.Name ~= "" then
					child.Visible = false
				end
			end
			for _, comp in ipairs(Tab._components) do
				comp.Visible = true
			end
		end)

		-- Auto-select first tab.
		if #Window._tabs == 1 then
			switchTab(tabData)
		end

		-- ── COMPONENT HELPERS ──

		---Create a row frame inside the left column.
		---@return Frame
		local function makeRow()
			Tab._order = Tab._order + 1
			local row = Instance.new("Frame")
			row.Name = "Row_" .. Tab._order
			row.Size = UDim2.new(1, 0, 0, 36)
			row.BackgroundColor3 = COLOR_BG_LIGHT
			row.BorderSizePixel = 0
			row.ZIndex = 5
			row.LayoutOrder = Tab._order
			row.Parent = leftCol
			applyCorner(row, 5)

			-- Hide if not active tab.
			if Window._activeTab ~= tabData then
				row.Visible = false
			end

			table.insert(Tab._components, row)
			return row
		end

		-- ── TOGGLE ──

		---Create a toggle switch.
		---@param label string
		---@param defaultState boolean
		---@param callback function
		function Tab:CreateToggle(label, defaultState, callback)
			local state = defaultState == true
			local row = makeRow()

			local lbl = makeLabel(row, label, 13, COLOR_TEXT_PRIMARY, FONT_MAIN)
			lbl.Size = UDim2.new(1, -70, 1, 0)
			lbl.Position = UDim2.new(0, 10, 0, 0)

			-- Toggle track.
			local track = Instance.new("Frame")
			track.Size = UDim2.new(0, 44, 0, 22)
			track.AnchorPoint = Vector2.new(1, 0.5)
			track.Position = UDim2.new(1, -10, 0.5, 0)
			track.BackgroundColor3 = state and COLOR_TOGGLE_ON or COLOR_TOGGLE_OFF
			track.BorderSizePixel = 0
			track.ZIndex = 6
			track.Parent = row
			applyCorner(track, 11)

			-- Toggle knob.
			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 16, 0, 16)
			knob.AnchorPoint = Vector2.new(0, 0.5)
			knob.Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			knob.BackgroundColor3 = COLOR_TEXT_PRIMARY
			knob.BorderSizePixel = 0
			knob.ZIndex = 7
			knob.Parent = track
			applyCorner(knob, 8)

			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

			local clickArea = Instance.new("TextButton")
			clickArea.Size = UDim2.fromScale(1, 1)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.ZIndex = 8
			clickArea.Parent = track

			clickArea.MouseButton1Click:Connect(function()
				state = not state
				local trackColor = state and COLOR_TOGGLE_ON or COLOR_TOGGLE_OFF
				local knobPos = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
				tweenService:Create(track, tweenInfo, { BackgroundColor3 = trackColor }):Play()
				tweenService:Create(knob, tweenInfo, { Position = knobPos }):Play()
				if callback then
					task.spawn(callback, state)
				end
			end)
		end

		-- ── KEYBIND BUTTON ──

		---Create a keybind action button.
		---@param label string
		---@param defaultKey string
		---@param callback function
		function Tab:CreateKeybindButton(label, defaultKey, callback)
			local currentKey = defaultKey or "None"
			local listening = false
			local row = makeRow()

			local lbl = makeLabel(row, label, 13, COLOR_TEXT_PRIMARY, FONT_MAIN)
			lbl.Size = UDim2.new(0.45, 0, 1, 0)
			lbl.Position = UDim2.new(0, 10, 0, 0)

			-- Keybind icon.
			local keybindIcon = Instance.new("TextButton")
			keybindIcon.Size = UDim2.new(0, 28, 0, 22)
			keybindIcon.AnchorPoint = Vector2.new(1, 0.5)
			keybindIcon.Position = UDim2.new(1, -70, 0.5, 0)
			keybindIcon.BackgroundColor3 = COLOR_KEYBIND_ICON
			keybindIcon.BorderSizePixel = 0
			keybindIcon.Text = "⌨"
			keybindIcon.TextSize = 13
			keybindIcon.TextColor3 = COLOR_TEXT_DIM
			keybindIcon.Font = FONT_MAIN
			keybindIcon.ZIndex = 6
			keybindIcon.Parent = row
			applyCorner(keybindIcon, 4)

			keybindIcon.MouseButton1Click:Connect(function()
				listening = true
				keybindIcon.Text = "..."
				local conn
				conn = userInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						currentKey = input.KeyCode.Name
						keybindIcon.Text = "⌨"
						listening = false
						conn:Disconnect()
					end
				end)
			end)

			-- Apply button.
			local applyBtn = Instance.new("TextButton")
			applyBtn.Size = UDim2.new(0, 52, 0, 24)
			applyBtn.AnchorPoint = Vector2.new(1, 0.5)
			applyBtn.Position = UDim2.new(1, -10, 0.5, 0)
			applyBtn.BackgroundColor3 = COLOR_BUTTON
			applyBtn.BorderSizePixel = 0
			applyBtn.Text = "Apply"
			applyBtn.TextColor3 = COLOR_TEXT_PRIMARY
			applyBtn.TextSize = 12
			applyBtn.Font = FONT_MAIN
			applyBtn.ZIndex = 6
			applyBtn.Parent = row
			applyCorner(applyBtn, 5)

			applyBtn.MouseButton1Click:Connect(function()
				if callback then
					task.spawn(callback, currentKey)
				end
			end)

			-- Listen for keybind globally when assigned.
			userInputService.InputBegan:Connect(function(input, gpe)
				if gpe then return end
				if not listening and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode.Name == currentKey then
						if callback then
							task.spawn(callback, currentKey)
						end
					end
				end
			end)
		end

		-- ── SLIDER ──

		---Create a slider.
		---@param label string
		---@param min number
		---@param max number
		---@param defaultVal number
		---@param callback function
		function Tab:CreateSlider(label, min, max, defaultVal, callback)
			min = min or 0
			max = max or 100
			defaultVal = math.clamp(defaultVal or min, min, max)
			local currentVal = defaultVal
			local row = makeRow()

			local lbl = makeLabel(row, label, 13, COLOR_TEXT_PRIMARY, FONT_MAIN)
			lbl.Size = UDim2.new(0.38, 0, 1, 0)
			lbl.Position = UDim2.new(0, 10, 0, 0)

			-- Slider track background.
			local trackBg = Instance.new("Frame")
			trackBg.Name = "SliderTrack"
			trackBg.Size = UDim2.new(0, 110, 0, 8)
			trackBg.AnchorPoint = Vector2.new(1, 0.5)
			trackBg.Position = UDim2.new(1, -36, 0.5, 0)
			trackBg.BackgroundColor3 = COLOR_SLIDER_TRACK
			trackBg.BorderSizePixel = 0
			trackBg.ZIndex = 6
			trackBg.Parent = row
			applyCorner(trackBg, 4)

			-- Slider fill.
			local fill = Instance.new("Frame")
			fill.Name = "Fill"
			fill.Size = UDim2.new((currentVal - min) / (max - min), 0, 1, 0)
			fill.BackgroundColor3 = COLOR_SLIDER_FILL
			fill.BorderSizePixel = 0
			fill.ZIndex = 7
			fill.Parent = trackBg
			applyCorner(fill, 4)

			-- Knob.
			local sliderKnob = Instance.new("Frame")
			sliderKnob.Size = UDim2.new(0, 12, 0, 12)
			sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			sliderKnob.Position = UDim2.new((currentVal - min) / (max - min), 0, 0.5, 0)
			sliderKnob.BackgroundColor3 = COLOR_TEXT_PRIMARY
			sliderKnob.BorderSizePixel = 0
			sliderKnob.ZIndex = 8
			sliderKnob.Parent = trackBg
			applyCorner(sliderKnob, 6)

			-- Value display.
			local valLabel = makeLabel(row, tostring(currentVal), 12, COLOR_TEXT_DIM, FONT_MONO)
			valLabel.Size = UDim2.new(0, 28, 1, 0)
			valLabel.AnchorPoint = Vector2.new(1, 0)
			valLabel.Position = UDim2.new(1, -4, 0, 0)
			valLabel.TextXAlignment = Enum.TextXAlignment.Right

			-- Drag input.
			local draggingSlider = false
			local inputFrame = Instance.new("TextButton")
			inputFrame.Size = UDim2.new(1, 0, 1, 8)
			inputFrame.AnchorPoint = Vector2.new(0, 0.5)
			inputFrame.Position = UDim2.new(0, 0, 0.5, 0)
			inputFrame.BackgroundTransparency = 1
			inputFrame.Text = ""
			inputFrame.ZIndex = 9
			inputFrame.Parent = trackBg

			local function updateSlider(inputX)
				local absPos = trackBg.AbsolutePosition.X
				local absSize = trackBg.AbsoluteSize.X
				local ratio = math.clamp((inputX - absPos) / absSize, 0, 1)
				currentVal = math.floor(min + ratio * (max - min))
				fill.Size = UDim2.new(ratio, 0, 1, 0)
				sliderKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
				valLabel.Text = tostring(currentVal)
				if callback then
					task.spawn(callback, currentVal)
				end
			end

			inputFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					draggingSlider = true
					updateSlider(input.Position.X)
				end
			end)
			inputFrame.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					draggingSlider = false
				end
			end)
			userInputService.InputChanged:Connect(function(input)
				if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
					updateSlider(input.Position.X)
				end
			end)
		end

		return Tab
	end

	return Window
end

return Library
