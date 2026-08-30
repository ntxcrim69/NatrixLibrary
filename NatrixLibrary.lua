--[[
    Custom Roblox Remote UI Library Wrapper
    Fully customizable dark UI with dynamic tabs, controls, and optional key system.
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

function Library:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Main Interface"
    local useKeySystem = (config.KeySystem == true)
    local keySettings = config.KeySettings or { Keys = {}, Discord = "" }

    -- Parent GUI Protection
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomUI_" .. math.random(10000, 99999)
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
        MainFrame = nil,
        TabHolder = nil,
        PageHolder = nil
    }
    setmetatable(windowObj, Library)

    -- Base Screen Frame (Overall container)
    local outerContainer = Instance.new("Frame")
    outerContainer.Name = "OuterContainer"
    outerContainer.Size = UDim2.new(0, 520, 0, 420)
    outerContainer.Position = UDim2.new(0.5, -260, 0.5, -210)
    outerContainer.BackgroundTransparency = 1
    outerContainer.Parent = screenGui

    -- Make Frame Draggable
    local dragging, dragInput, dragStart, startPos
    outerContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = outerContainer.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    outerContainer.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            outerContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- 1. Main UI Layout Setup
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 0, 360)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = not useKeySystem
    mainFrame.Parent = outerContainer
    createCorner(mainFrame, 6)
    windowObj.MainFrame = mainFrame

    -- Top Navigation Bar Frame
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    topBar.Parent = mainFrame
    createCorner(topBar, 6)

    local tabListContainer = Instance.new("Frame")
    tabListContainer.Name = "TabList"
    tabListContainer.Size = UDim2.new(1, -40, 1, 0)
    tabListContainer.BackgroundTransparency = 1
    tabListContainer.Parent = topBar
    createPadding(tabListContainer, 4, 4, 6, 6)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabListContainer

    windowObj.TabHolder = tabListContainer

    -- Close Button (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 16
    closeBtn.Parent = topBar
    createCorner(closeBtn, 4)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Main Split Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -12, 1, -48)
    contentArea.Position = UDim2.new(0, 6, 0, 42)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    local pageHolder = Instance.new("Frame")
    pageHolder.Name = "PageHolder"
    pageHolder.Size = UDim2.new(1, 0, 1, 0)
    pageHolder.BackgroundTransparency = 1
    pageHolder.Parent = contentArea
    windowObj.PageHolder = pageHolder

    -- Bottom Status Bar Frame
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 36)
    bottomBar.Position = UDim2.new(0, 0, 0, 370)
    bottomBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bottomBar.Visible = not useKeySystem
    bottomBar.Parent = outerContainer
    createCorner(bottomBar, 6)
    createPadding(bottomBar, 4, 4, 6, 6)

    -- FPS Indicator Tag
    local fpsTag = Instance.new("Frame")
    fpsTag.Size = UDim2.new(0, 95, 1, 0)
    fpsTag.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    fpsTag.Parent = bottomBar
    createCorner(fpsTag, 4)

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "⚡ FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    fpsLabel.Font = Enum.Font.SourceSansBold
    fpsLabel.TextSize = 14
    fpsLabel.Parent = fpsTag

    -- PING Indicator Tag
    local pingTag = Instance.new("Frame")
    pingTag.Size = UDim2.new(0, 105, 1, 0)
    pingTag.Position = UDim2.new(0, 103, 0, 0)
    pingTag.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    pingTag.Parent = bottomBar
    createCorner(pingTag, 4)

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, 0, 1, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "📡 PING: --"
    pingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    pingLabel.Font = Enum.Font.SourceSansBold
    pingLabel.TextSize = 14
    pingLabel.Parent = pingTag

    -- Settings Gear Icon (Right aligned)
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(0, 28, 0, 28)
    settingsBtn.Position = UDim2.new(1, -28, 0, 0)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    settingsBtn.Text = "⚙"
    settingsBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    settingsBtn.Font = Enum.Font.SourceSansBold
    settingsBtn.TextSize = 16
    settingsBtn.Parent = bottomBar
    createCorner(settingsBtn, 4)

    -- Live Stats Logic Loops
    local frameCount = 0
    local lastTick = tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        if tick() - lastTick >= 1 then
            fpsLabel.Text = "⚡ FPS: " .. tostring(frameCount)
            frameCount = 0
            lastTick = tick()
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            local pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            pingLabel.Text = "📡 PING: " .. tostring(pingVal)
        end
    end)

    -- 2. Key System Handling (If enabled)
    if useKeySystem then
        local keyModal = Instance.new("Frame")
        keyModal.Name = "KeyModal"
        keyModal.Size = UDim2.new(0, 380, 0, 260)
        keyModal.Position = UDim2.new(0.5, -190, 0.5, -130)
        keyModal.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
        keyModal.BorderSizePixel = 0
        keyModal.Parent = outerContainer
        createCorner(keyModal, 8)

        -- Discord Icon Top Right
        local discordBtn = Instance.new("TextButton")
        discordBtn.Size = UDim2.new(0, 30, 0, 30)
        discordBtn.Position = UDim2.new(1, -36, 0, 6)
        discordBtn.BackgroundTransparency = 1
        discordBtn.Text = "💬"
        discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        discordBtn.TextSize = 20
        discordBtn.Parent = keyModal

        discordBtn.MouseButton1Click:Connect(function()
            if setclipboard and keySettings.Discord then
                setclipboard(keySettings.Discord)
            end
        end)

        -- Center Geometric Logo
        local logoLabel = Instance.new("ImageLabel")
        logoLabel.Size = UDim2.new(0, 64, 0, 64)
        logoLabel.Position = UDim2.new(0.5, -32, 0.12, 0)
        logoLabel.BackgroundTransparency = 1
        logoLabel.Image = "rbxassetid://6031097225"
        logoLabel.Parent = keyModal

        -- Dark Key TextBox
        local keyInput = Instance.new("TextBox")
        keyInput.Size = UDim2.new(0, 260, 0, 36)
        keyInput.Position = UDim2.new(0.5, -130, 0.48, 0)
        keyInput.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        keyInput.PlaceholderText = "Key"
        keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
        keyInput.Text = ""
        keyInput.Font = Enum.Font.SourceSans
        keyInput.TextSize = 16
        keyInput.Parent = keyModal
        createCorner(keyInput, 6)

        -- Rounded "Check" Button
        local checkBtn = Instance.new("TextButton")
        checkBtn.Size = UDim2.new(0, 100, 0, 32)
        checkBtn.Position = UDim2.new(0.5, -50, 0.72, 0)
        checkBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkBtn.Text = "Check"
        checkBtn.Font = Enum.Font.SourceSansBold
        checkBtn.TextSize = 16
        checkBtn.Parent = keyModal
        createCorner(checkBtn, 6)

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
                keyModal:Destroy()
                mainFrame.Visible = true
                bottomBar.Visible = true
            else
                keyInput.Text = ""
                keyInput.PlaceholderText = "Invalid Key!"
                task.wait(1.5)
                keyInput.PlaceholderText = "Key"
            end
        end)
    end

    return windowObj
end

-- Dynamic Tab Creation
function Library:CreateTab(tabName)
    local window = self

    -- Tab Button in Top Bar
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "_Btn"
    tabBtn.Size = UDim2.new(0, 60, 1, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = 14
    tabBtn.Parent = window.TabHolder
    createCorner(tabBtn, 4)

    -- Content Split Canvas Page
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = tabName .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    pageFrame.Parent = window.PageHolder

    -- Left Column Container (Controls)
    local leftColumn = Instance.new("ScrollingFrame")
    leftColumn.Name = "LeftColumn"
    leftColumn.Size = UDim2.new(0.49, 0, 1, 0)
    leftColumn.Position = UDim2.new(0, 0, 0, 0)
    leftColumn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    leftColumn.BorderSizePixel = 0
    leftColumn.ScrollBarThickness = 2
    leftColumn.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    leftColumn.Parent = pageFrame
    createCorner(leftColumn, 6)
    createPadding(leftColumn, 6, 6, 6, 6)

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 6)
    leftLayout.Parent = leftColumn

    -- Right Column Container (Sub-Panels)
    local rightColumn = Instance.new("Frame")
    rightColumn.Name = "RightColumn"
    rightColumn.Size = UDim2.new(0.49, 0, 1, 0)
    rightColumn.Position = UDim2.new(0.51, 0, 0, 0)
    rightColumn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    rightColumn.BorderSizePixel = 0
    rightColumn.Parent = pageFrame
    createCorner(rightColumn, 6)

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
            t.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            t.Button.TextColor3 = Color3.fromRGB(140, 140, 140)
        end
        pageFrame.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        window.ActiveTab = tabObj
    end

    tabBtn.MouseButton1Click:Connect(selectTab)

    -- Activate first created tab automatically
    if #window.Tabs == 1 then
        selectTab()
    end

    return tabObj
end

-- Component Method: CreateToggle
function Tab:CreateToggle(label, defaultState, callback)
    callback = callback or function() end
    local state = defaultState or false

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 32)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    toggleFrame.Parent = self.LeftColumn
    createCorner(toggleFrame, 4)
    createPadding(toggleFrame, 0, 0, 8, 8)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.6, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = toggleFrame

    -- Outer Pill Track
    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 36, 0, 16)
    switchTrack.Position = UDim2.new(1, -36, 0.5, -8)
    switchTrack.BackgroundColor3 = state and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(40, 40, 40)
    switchTrack.Parent = toggleFrame
    createCorner(switchTrack, 8)

    -- Inner Indicator Knob
    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 12, 0, 12)
    switchKnob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    switchKnob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    switchKnob.Parent = switchTrack
    createCorner(switchKnob, 6)

    local interactBtn = Instance.new("TextButton")
    interactBtn.Size = UDim2.new(1, 0, 1, 0)
    interactBtn.BackgroundTransparency = 1
    interactBtn.Text = ""
    interactBtn.Parent = toggleFrame

    interactBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(switchTrack, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(140, 140, 140) or Color3.fromRGB(40, 40, 40)
        }):Play()
        TweenService:Create(switchKnob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        }):Play()
        task.spawn(callback, state)
    end)
end

-- Component Method: CreateKeybindButton
function Tab:CreateKeybindButton(label, defaultKey, callback)
    callback = callback or function() end
    local currentKey = defaultKey or Enum.KeyCode.E

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.new(1, 0, 0, 32)
    containerFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    containerFrame.Parent = self.LeftColumn
    createCorner(containerFrame, 4)
    createPadding(containerFrame, 0, 0, 8, 8)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.4, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = containerFrame

    -- Keybind Selector Box
    local keybindBtn = Instance.new("TextButton")
    keybindBtn.Size = UDim2.new(0, 30, 0, 20)
    keybindBtn.Position = UDim2.new(1, -80, 0.5, -10)
    keybindBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    keybindBtn.Text = "⌨️"
    keybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    keybindBtn.Font = Enum.Font.SourceSans
    keybindBtn.TextSize = 12
    keybindBtn.Parent = containerFrame
    createCorner(keybindBtn, 4)

    -- Apply Action Button
    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0, 44, 0, 20)
    applyBtn.Position = UDim2.new(1, -44, 0.5, -10)
    applyBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    applyBtn.Text = "Apply"
    applyBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    applyBtn.Font = Enum.Font.SourceSans
    applyBtn.TextSize = 12
    applyBtn.Parent = containerFrame
    createCorner(applyBtn, 4)

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
    sliderFrame.Size = UDim2.new(1, 0, 0, 32)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    sliderFrame.Parent = self.LeftColumn
    createCorner(sliderFrame, 4)
    createPadding(sliderFrame, 0, 0, 8, 8)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.35, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = sliderFrame

    -- Slider Track Bar
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 110, 0, 14)
    track.Position = UDim2.new(1, -140, 0.5, -7)
    track.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    track.Parent = sliderFrame
    createCorner(track, 4)

    local initialPercent = (defaultVal - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    fill.Parent = track
    createCorner(fill, 4)

    -- Dynamic Value Label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 24, 1, 0)
    valueLabel.Position = UDim2.new(1, -24, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultVal)
    valueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    valueLabel.Font = Enum.Font.SourceSans
    valueLabel.TextSize = 13
    valueLabel.Parent = sliderFrame

    -- Dragging Interaction Logic
    local dragging = false
    local function updateValue(input)
        local mousePos = input.Position.X
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local percent = math.clamp((mousePos - trackPos) / trackSize, 0, 1)
        local val = math.floor(min + (max - min) * percent)
        fill.Size = UDim2.new(percent, 0, 1, 0)
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
