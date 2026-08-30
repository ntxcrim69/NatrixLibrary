--[[
    Premium Roblox UI Library Wrapper - "Natrix Pro"
    Advanced modern GUI with strokes, dynamic easing, gap layouts, and web assets.
]]

local Library = {}
Library.__index = Library

local Tab = {}
Tab.__index = Tab

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Design System Constants
local Theme = {
    Background = Color3.fromRGB(12, 12, 14),
    Surface = Color3.fromRGB(18, 18, 22),
    SurfaceElevated = Color3.fromRGB(24, 24, 28),
    Stroke = Color3.fromRGB(38, 38, 44),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(140, 140, 150),
    Danger = Color3.fromRGB(239, 68, 68)
}

-- Helper Functions
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function createPadding(parent, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 4)
    padding.PaddingBottom = UDim.new(0, bottom or 4)
    padding.PaddingLeft = UDim.new(0, left or 8)
    padding.PaddingRight = UDim.new(0, right or 8)
    padding.Parent = parent
    return padding
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Stroke
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function animate(object, properties, duration)
    local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

-- External Image Fetcher for Executors
local function FetchExternalImage(url, fileName)
    local success, asset = pcall(function()
        if isfile and writefile and getcustomasset then
            if not isfile(fileName) then
                local imgData = game:HttpGet(url)
                writefile(fileName, imgData)
            end
            return getcustomasset(fileName)
        end
        return ""
    end)
    return success and asset or ""
end

function Library:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Natrix Interface"
    local useKeySystem = (config.KeySystem == true)
    local keySettings = config.KeySettings or { Keys = {}, Discord = "" }

    -- Parent GUI Protection
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NatrixUI_" .. math.random(10000, 99999)
    screenGui.ResetOnSpawn = false
    
    local parentObj = (gethui and gethui()) or (syn and syn.protect_gui and CoreGui) or CoreGui
    pcall(function() screenGui.Parent = parentObj end)
    if not screenGui.Parent then
        screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local windowObj = {
        Gui = screenGui,
        Tabs = {},
        ActiveTab = nil,
        TabHolder = nil,
        PageHolder = nil
    }
    setmetatable(windowObj, Library)

    -- Master Container
    local outerContainer = Instance.new("Frame")
    outerContainer.Name = "OuterContainer"
    outerContainer.Size = UDim2.new(0, 600, 0, 480)
    outerContainer.Position = UDim2.new(0.5, -300, 0.5, -240)
    outerContainer.BackgroundTransparency = 1
    outerContainer.Parent = screenGui

    -- Main UI Layout Setup (Visible after key system)
    local mainApp = Instance.new("Frame")
    mainApp.Name = "MainApp"
    mainApp.Size = UDim2.new(1, 0, 1, 0)
    mainApp.BackgroundTransparency = 1
    mainApp.Visible = not useKeySystem
    mainApp.Parent = outerContainer

    -- 1. Top Navigation Bar (Separated for the gap)
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = Theme.Background
    topBar.BorderSizePixel = 0
    topBar.Parent = mainApp
    createCorner(topBar, 8)
    createStroke(topBar, Theme.Stroke)

    -- Strict TopBar Dragging Logic
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = outerContainer.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            outerContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local tabListContainer = Instance.new("Frame")
    tabListContainer.Name = "TabList"
    tabListContainer.Size = UDim2.new(1, -50, 1, 0)
    tabListContainer.BackgroundTransparency = 1
    tabListContainer.Parent = topBar
    createPadding(tabListContainer, 6, 6, 8, 8)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabListContainer

    windowObj.TabHolder = tabListContainer

    -- Strict X Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = Theme.Surface
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.Parent = topBar
    createCorner(closeBtn, 6)
    createStroke(closeBtn, Theme.Stroke)

    closeBtn.MouseEnter:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Accent}) end)
    closeBtn.MouseLeave:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.SubText}) end)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- 2. The Upper Gap & Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    -- Note the position leaves a distinct 10px gap below the top bar
    contentArea.Size = UDim2.new(1, 0, 1, -110) 
    contentArea.Position = UDim2.new(0, 0, 0, 54) 
    contentArea.BackgroundColor3 = Theme.Background
    contentArea.BorderSizePixel = 0
    contentArea.Parent = mainApp
    createCorner(contentArea, 8)
    createStroke(contentArea, Theme.Stroke)
    windowObj.PageHolder = contentArea

    -- 3. Bottom Status Bar (Separated with gap)
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 46)
    bottomBar.Position = UDim2.new(0, 0, 1, -46)
    bottomBar.BackgroundColor3 = Theme.Background
    bottomBar.Parent = mainApp
    createCorner(bottomBar, 8)
    createStroke(bottomBar, Theme.Stroke)
    createPadding(bottomBar, 6, 6, 8, 8)

    -- Status Tag Helper
    local function createStatusTag(parent, iconUrl, labelText, xOffset, width)
        local tag = Instance.new("Frame")
        tag.Size = UDim2.new(0, width, 1, 0)
        tag.Position = UDim2.new(0, xOffset, 0, 0)
        tag.BackgroundColor3 = Theme.Surface
        tag.Parent = parent
        createCorner(tag, 6)
        createStroke(tag, Theme.Stroke)

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 10, 0.5, -8)
        icon.BackgroundTransparency = 1
        icon.Image = FetchExternalImage(iconUrl, labelText .. "_icon.png")
        icon.Parent = tag

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -34, 1, 0)
        label.Position = UDim2.new(0, 32, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText .. ": --"
        label.TextColor3 = Theme.SubText
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = tag

        return label
    end

    -- Create custom icon tags using your URLs
    local fpsLabel = createStatusTag(bottomBar, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/speed.png?raw=true", "FPS", 0, 105)
    local pingLabel = createStatusTag(bottomBar, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/network.png?raw=true", "PING", 113, 115)

    -- Settings Gear Icon (Right aligned)
    local settingsBtn = Instance.new("ImageButton")
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(1, -32, 0.5, -16)
    settingsBtn.BackgroundColor3 = Theme.Surface
    settingsBtn.Image = FetchExternalImage("https://github.com/ntxcrim69/NatrixLibrary/blob/main/gear.png?raw=true", "gear_icon.png")
    settingsBtn.ImageColor3 = Theme.SubText
    settingsBtn.Parent = bottomBar
    createCorner(settingsBtn, 6)
    createStroke(settingsBtn, Theme.Stroke)

    settingsBtn.MouseEnter:Connect(function() animate(settingsBtn, {BackgroundColor3 = Theme.SurfaceElevated, ImageColor3 = Theme.Accent}) end)
    settingsBtn.MouseLeave:Connect(function() animate(settingsBtn, {BackgroundColor3 = Theme.Surface, ImageColor3 = Theme.SubText}) end)

    -- Live Stats Logic Loops
    local frameCount = 0
    local lastTick = tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        if tick() - lastTick >= 1 then
            fpsLabel.Text = "FPS: " .. tostring(frameCount)
            frameCount = 0
            lastTick = tick()
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            local success, pingVal = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if success then
                pingLabel.Text = "PING: " .. tostring(pingVal)
            end
        end
    end)

    -- 4. Key System Overlay (If enabled)
    if useKeySystem then
        local keyModal = Instance.new("Frame")
        keyModal.Name = "KeyModal"
        keyModal.Size = UDim2.new(0, 440, 0, 320)
        keyModal.Position = UDim2.new(0.5, -220, 0.5, -160)
        keyModal.BackgroundColor3 = Theme.Background
        keyModal.BorderSizePixel = 0
        keyModal.Parent = outerContainer
        createCorner(keyModal, 10)
        createStroke(keyModal, Theme.Stroke)

        -- Draggable Modal
        local kDragging, kDragInput, kDragStart, kStartPos
        keyModal.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                kDragging = true
                kDragStart = input.Position
                kStartPos = outerContainer.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then kDragging = false end end)
            end
        end)
        keyModal.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then kDragInput = input end end)
        UserInputService.InputChanged:Connect(function(input)
            if input == kDragInput and kDragging then
                local delta = input.Position - kDragStart
                outerContainer.Position = UDim2.new(kStartPos.X.Scale, kStartPos.X.Offset + delta.X, kStartPos.Y.Scale, kStartPos.Y.Offset + delta.Y)
            end
        end)

        -- Discord Icon
        local discordBtn = Instance.new("ImageButton")
        discordBtn.Size = UDim2.new(0, 24, 0, 24)
        discordBtn.Position = UDim2.new(1, -36, 0, 12)
        discordBtn.BackgroundTransparency = 1
        discordBtn.Image = FetchExternalImage("https://github.com/ntxcrim69/NatrixLibrary/blob/main/discord.png?raw=true", "NatrixDiscord.png")
        discordBtn.Parent = keyModal
        
        discordBtn.MouseEnter:Connect(function() animate(discordBtn, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -37, 0, 11)}) end)
        discordBtn.MouseLeave:Connect(function() animate(discordBtn, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -36, 0, 12)}) end)
        discordBtn.MouseButton1Click:Connect(function() if setclipboard and keySettings.Discord then setclipboard(keySettings.Discord) end end)

        -- Center Main Logo
        local logoLabel = Instance.new("ImageLabel")
        logoLabel.Size = UDim2.new(0, 100, 0, 100)
        logoLabel.Position = UDim2.new(0.5, -50, 0.1, 0)
        logoLabel.BackgroundTransparency = 1
        logoLabel.Image = FetchExternalImage("https://github.com/ntxcrim69/NatrixLibrary/blob/main/Natrixlogo.png?raw=true", "NatrixLogo.png")
        logoLabel.ScaleType = Enum.ScaleType.Fit
        logoLabel.Parent = keyModal

        -- Dark Key TextBox
        local keyInput = Instance.new("TextBox")
        keyInput.Size = UDim2.new(0, 300, 0, 46)
        keyInput.Position = UDim2.new(0.5, -150, 0.52, 0)
        keyInput.BackgroundColor3 = Theme.Surface
        keyInput.TextColor3 = Theme.Accent
        keyInput.PlaceholderText = "Enter Authentication Key"
        keyInput.PlaceholderColor3 = Theme.SubText
        keyInput.Text = ""
        keyInput.Font = Enum.Font.GothamMedium
        keyInput.TextSize = 13
        keyInput.Parent = keyModal
        createCorner(keyInput, 8)
        createStroke(keyInput, Theme.Stroke)

        -- Verify Button
        local checkBtn = Instance.new("TextButton")
        checkBtn.Size = UDim2.new(0, 140, 0, 42)
        checkBtn.Position = UDim2.new(0.5, -70, 0.72, 0)
        checkBtn.BackgroundColor3 = Theme.Surface
        checkBtn.TextColor3 = Theme.Accent
        checkBtn.Text = "Authenticate"
        checkBtn.Font = Enum.Font.GothamBold
        checkBtn.TextSize = 13
        checkBtn.Parent = keyModal
        createCorner(checkBtn, 8)
        createStroke(checkBtn, Theme.Stroke)

        checkBtn.MouseEnter:Connect(function() animate(checkBtn, {BackgroundColor3 = Theme.SurfaceElevated}) end)
        checkBtn.MouseLeave:Connect(function() animate(checkBtn, {BackgroundColor3 = Theme.Surface}) end)

        checkBtn.MouseButton1Click:Connect(function()
            local entered = keyInput.Text
            local verified = false
            if type(keySettings.Keys) == "table" then
                for _, validKey in ipairs(keySettings.Keys) do
                    if entered == validKey then
                        verified = true
                        break
                    end
                end
            end

            if verified then
                -- Smooth fade out
                local outTween = TweenService:Create(keyModal, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -220, 0.45, -160), GroupTransparency = 1})
                outTween:Play()
                outTween.Completed:Wait()
                keyModal:Destroy()
                
                -- Fade in app
                mainApp.Visible = true
                mainApp.GroupTransparency = 1
                TweenService:Create(mainApp, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
            else
                keyInput.Text = ""
                keyInput.PlaceholderText = "Invalid Key!"
                local errTween = animate(keyInput, {BackgroundColor3 = Theme.Danger})
                task.wait(1)
                animate(keyInput, {BackgroundColor3 = Theme.Surface})
                keyInput.PlaceholderText = "Enter Authentication Key"
            end
        end)
    end

    return windowObj
end

-- Dynamic Tab Creation
function Library:CreateTab(tabName)
    local window = self

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "_Btn"
    tabBtn.Size = UDim2.new(0, 80, 1, 0)
    tabBtn.BackgroundColor3 = Theme.Surface
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Theme.SubText
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 13
    tabBtn.Parent = window.TabHolder
    createCorner(tabBtn, 6)

    -- Split Canvas (Left/Right gap)
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = tabName .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    pageFrame.Parent = window.PageHolder

    local leftColumn = Instance.new("ScrollingFrame")
    leftColumn.Name = "LeftColumn"
    leftColumn.Size = UDim2.new(0.49, -4, 1, 0)
    leftColumn.Position = UDim2.new(0, 8, 0, 8)
    leftColumn.Size = UDim2.new(0.5, -12, 1, -16)
    leftColumn.BackgroundTransparency = 1
    leftColumn.BorderSizePixel = 0
    leftColumn.ScrollBarThickness = 2
    leftColumn.ScrollBarImageColor3 = Theme.Stroke
    leftColumn.Parent = pageFrame
    createPadding(leftColumn, 2, 2, 2, 2)

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 6)
    leftLayout.Parent = leftColumn

    local rightColumn = Instance.new("ScrollingFrame")
    rightColumn.Name = "RightColumn"
    rightColumn.Size = UDim2.new(0.5, -12, 1, -16)
    rightColumn.Position = UDim2.new(0.5, 4, 0, 8)
    rightColumn.BackgroundTransparency = 1
    rightColumn.BorderSizePixel = 0
    rightColumn.ScrollBarThickness = 2
    rightColumn.ScrollBarImageColor3 = Theme.Stroke
    rightColumn.Parent = pageFrame
    createPadding(rightColumn, 2, 2, 2, 2)
    
    local rightLayout = Instance.new("UIListLayout")
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Padding = UDim.new(0, 6)
    rightLayout.Parent = rightColumn

    local tabObj = {
        Button = tabBtn,
        Page = pageFrame,
        LeftColumn = leftColumn,
        RightColumn = rightColumn
    }
    setmetatable(tabObj, Tab)
    table.insert(window.Tabs, tabObj)

    -- Tab Switch Logic
    local function selectTab()
        for _, t in ipairs(window.Tabs) do
            t.Page.Visible = false
            animate(t.Button, {TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(0, 80, 1, 0)})
        end
        pageFrame.Visible = true
        animate(tabBtn, {TextColor3 = Theme.Accent, BackgroundTransparency = 0, Size = UDim2.new(0, 90, 1, 0)})
        window.ActiveTab = tabObj
    end

    tabBtn.MouseButton1Click:Connect(selectTab)
    if #window.Tabs == 1 then selectTab() end

    return tabObj
end

-- Component Method: CreateToggle
function Tab:CreateToggle(label, defaultState, callback)
    callback = callback or function() end
    local state = defaultState or false

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 42)
    toggleFrame.BackgroundColor3 = Theme.Surface
    toggleFrame.Parent = self.LeftColumn
    createCorner(toggleFrame, 6)
    createStroke(toggleFrame, Theme.Stroke)
    createPadding(toggleFrame, 0, 0, 4, 12)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.6, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = toggleFrame

    -- Outer Pill Track
    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 40, 0, 20)
    switchTrack.Position = UDim2.new(1, -44, 0.5, -10)
    switchTrack.BackgroundColor3 = state and Theme.Accent or Theme.Background
    switchTrack.Parent = toggleFrame
    createCorner(switchTrack, 20)
    local trackStroke = createStroke(switchTrack, Theme.Stroke)

    -- Inner Indicator Knob
    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 14, 0, 14)
    switchKnob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    switchKnob.BackgroundColor3 = state and Theme.Background or Theme.SubText
    switchKnob.Parent = switchTrack
    createCorner(switchKnob, 14)

    local interactBtn = Instance.new("TextButton")
    interactBtn.Size = UDim2.new(1, 0, 1, 0)
    interactBtn.BackgroundTransparency = 1
    interactBtn.Text = ""
    interactBtn.Parent = toggleFrame

    interactBtn.MouseButton1Click:Connect(function()
        state = not state
        trackStroke.Color = state and Theme.Accent or Theme.Stroke
        animate(switchTrack, {BackgroundColor3 = state and Theme.Accent or Theme.Background})
        animate(switchKnob, {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = state and Theme.Background or Theme.SubText
        })
        task.spawn(callback, state)
    end)
end

-- Component Method: CreateKeybindButton
function Tab:CreateKeybindButton(label, defaultKey, callback)
    callback = callback or function() end
    local currentKey = defaultKey or Enum.KeyCode.E

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.new(1, 0, 0, 42)
    containerFrame.BackgroundColor3 = Theme.Surface
    containerFrame.Parent = self.LeftColumn
    createCorner(containerFrame, 6)
    createStroke(containerFrame, Theme.Stroke)
    createPadding(containerFrame, 0, 0, 4, 12)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.4, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = containerFrame

    local keybindBtn = Instance.new("TextButton")
    keybindBtn.Size = UDim2.new(0, 40, 0, 24)
    keybindBtn.Position = UDim2.new(1, -100, 0.5, -12)
    keybindBtn.BackgroundColor3 = Theme.Background
    keybindBtn.Text = currentKey.Name
    keybindBtn.TextColor3 = Theme.SubText
    keybindBtn.Font = Enum.Font.Gotham
    keybindBtn.TextSize = 11
    keybindBtn.Parent = containerFrame
    createCorner(keybindBtn, 6)
    createStroke(keybindBtn, Theme.Stroke)

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 52, 0, 24)
    applyBtn.Position = UDim2.new(1, -52, 0.5, -12)
    applyBtn.BackgroundColor3 = Theme.SurfaceElevated
    applyBtn.Text = "Apply"
    applyBtn.TextColor3 = Theme.Accent
    applyBtn.Font = Enum.Font.GothamMedium
    applyBtn.TextSize = 11
    applyBtn.Parent = containerFrame
    createCorner(applyBtn, 6)
    createStroke(applyBtn, Theme.Stroke)

    applyBtn.MouseEnter:Connect(function() animate(applyBtn, {BackgroundColor3 = Theme.Stroke}) end)
    applyBtn.MouseLeave:Connect(function() animate(applyBtn, {BackgroundColor3 = Theme.SurfaceElevated}) end)

    local binding = false
    keybindBtn.MouseButton1Click:Connect(function()
        binding = true
        keybindBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                keybindBtn.Text = currentKey.Name
                binding = false
                connection:Disconnect()
            end
        end)
    end)

    applyBtn.MouseButton1Click:Connect(function()
        task.spawn(callback, currentKey)
    end)
end

-- Component Method: CreateSlider
function Tab:CreateSlider(label, min, max, defaultVal, callback)
    callback = callback or function() end
    min = min or 0
    max = max or 100
    defaultVal = math.clamp(defaultVal or min, min, max)

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 46)
    sliderFrame.BackgroundColor3 = Theme.Surface
    sliderFrame.Parent = self.LeftColumn
    createCorner(sliderFrame, 6)
    createStroke(sliderFrame, Theme.Stroke)
    createPadding(sliderFrame, 0, 0, 4, 12)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.35, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = sliderFrame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 120, 0, 10)
    track.Position = UDim2.new(1, -155, 0.5, -5)
    track.BackgroundColor3 = Theme.Background
    track.Parent = sliderFrame
    createCorner(track, 10)
    createStroke(track, Theme.Stroke)

    local initialPercent = (defaultVal - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.Parent = track
    createCorner(fill, 10)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 26, 1, 0)
    valueLabel.Position = UDim2.new(1, -26, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultVal)
    valueLabel.TextColor3 = Theme.SubText
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 12
    valueLabel.Parent = sliderFrame

    local dragging = false
    local function updateValue(input)
        local mousePos = input.Position.X
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local percent = math.clamp((mousePos - trackPos) / trackSize, 0, 1)
        local val = math.floor(min + (max - min) * percent)
        animate(fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
        valueLabel.Text = tostring(val)
        task.spawn(callback, val)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
end

return Library
