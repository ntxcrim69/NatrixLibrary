--[[
    Natrix Pro UI Library - Complete Loader & Script Example
    Matches the Visuals tab elements shown in your interface screenshot.
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
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Configuration File Persistence System
local ConfigFileName = "NatrixPro_Config.json"
local Config = {
    FPSCounterEnabled = false,
    ToggleKey = "RightShift",
    Theme = "Default (Dark)"
}

-- Theme Definitions
local Themes = {
    ["Default (Dark)"] = {
        Background = Color3.fromRGB(12, 12, 14),
        Surface = Color3.fromRGB(18, 18, 22),
        SurfaceElevated = Color3.fromRGB(24, 24, 28),
        Stroke = Color3.fromRGB(38, 38, 44),
        Accent = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(140, 140, 150),
        Danger = Color3.fromRGB(239, 68, 68)
    },
    ["Midnight Blue"] = {
        Background = Color3.fromRGB(10, 12, 18),
        Surface = Color3.fromRGB(15, 20, 30),
        SurfaceElevated = Color3.fromRGB(22, 28, 42),
        Stroke = Color3.fromRGB(30, 40, 60),
        Accent = Color3.fromRGB(59, 130, 246),
        Text = Color3.fromRGB(240, 244, 255),
        SubText = Color3.fromRGB(130, 150, 180),
        Danger = Color3.fromRGB(239, 68, 68)
    },
    ["Crimson Red"] = {
        Background = Color3.fromRGB(14, 11, 11),
        Surface = Color3.fromRGB(22, 16, 16),
        SurfaceElevated = Color3.fromRGB(32, 22, 22),
        Stroke = Color3.fromRGB(50, 32, 32),
        Accent = Color3.fromRGB(239, 68, 68),
        Text = Color3.fromRGB(255, 240, 240),
        SubText = Color3.fromRGB(170, 130, 130),
        Danger = Color3.fromRGB(239, 68, 68)
    },
    ["Emerald"] = {
        Background = Color3.fromRGB(11, 14, 12),
        Surface = Color3.fromRGB(16, 22, 18),
        SurfaceElevated = Color3.fromRGB(22, 32, 26),
        Stroke = Color3.fromRGB(32, 50, 38),
        Accent = Color3.fromRGB(16, 185, 129),
        Text = Color3.fromRGB(240, 255, 245),
        SubText = Color3.fromRGB(130, 160, 140),
        Danger = Color3.fromRGB(239, 68, 68)
    }
}

local Theme = {}
local function LoadTheme(themeName)
    local tData = Themes[themeName] or Themes["Default (Dark)"]
    for k, v in pairs(tData) do
        Theme[k] = v
    end
end

LoadTheme(Config.Theme)

local function SaveConfig()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if success and writefile then
        writefile(ConfigFileName, encoded)
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFileName) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                Config[k] = v
            end
            if Config.Theme then
                LoadTheme(Config.Theme)
            end
        end
    end
end

LoadConfig()

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

local imageCache = {}
local function FetchExternalImage(url, fileName)
    if imageCache[fileName] then return imageCache[fileName] end
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
    local result = success and asset or ""
    if result ~= "" then imageCache[fileName] = result end
    return result
end

local function createStatusTag(parent, iconUrl, fileName, labelText, xOffset, width)
    local baseZIndex = parent.ZIndex or 1

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, xOffset + 12, 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.Image = FetchExternalImage(iconUrl, fileName)
    icon.ZIndex = baseZIndex + 1
    icon.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, width - 36, 1, 0)
    label.Position = UDim2.new(0, xOffset + 36, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": --"
    label.TextColor3 = Theme.SubText
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = baseZIndex + 1
    label.Parent = parent

    return label
end

function Library:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "Natrix Interface"
    local useKeySystem = (config.KeySystem == true)
    local keySettings = config.KeySettings or { Keys = {}, Discord = "" }

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NatrixUI_" .. math.random(10000, 99999)
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global 
    
    local parentObj = (gethui and gethui()) or (syn and syn.protect_gui and CoreGui) or CoreGui
    pcall(function() screenGui.Parent = parentObj end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local windowObj = { Gui = screenGui, Tabs = {}, ActiveTab = nil, TabHolder = nil, PageHolder = nil }
    setmetatable(windowObj, Library)

    local outerContainer = Instance.new("Frame")
    outerContainer.Name = "OuterContainer"
    outerContainer.Size = UDim2.new(0, 600, 0, 480)
    outerContainer.Position = UDim2.new(0.5, -300, 0.5, -240)
    outerContainer.BackgroundTransparency = 1
    outerContainer.ZIndex = 1
    outerContainer.Parent = screenGui

    local currentToggleKey = Enum.KeyCode[Config.ToggleKey] or Enum.KeyCode.RightShift

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == currentToggleKey then
            outerContainer.Visible = not outerContainer.Visible
        end
    end)

    local topMiddleHud = Instance.new("Frame")
    topMiddleHud.Name = "TopMiddleHud"
    topMiddleHud.Size = UDim2.new(0, 230, 0, 32)
    topMiddleHud.Position = UDim2.new(0.5, -115, 0, 10)
    topMiddleHud.BackgroundColor3 = Theme.Surface
    topMiddleHud.Visible = Config.FPSCounterEnabled
    topMiddleHud.ZIndex = 50
    topMiddleHud.Parent = screenGui
    createCorner(topMiddleHud, 6)
    createStroke(topMiddleHud, Theme.Stroke)

    local hudDragging, hudDragInput, hudDragStart, hudStartPos
    topMiddleHud.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hudDragging = true
            hudDragStart = input.Position
            hudStartPos = topMiddleHud.AbsolutePosition
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then hudDragging = false end end)
        end
    end)
    topMiddleHud.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then hudDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == hudDragInput and hudDragging then
            local delta = input.Position - hudDragStart
            topMiddleHud.Position = UDim2.new(0, hudStartPos.X + delta.X, 0, hudStartPos.Y + delta.Y)
        end
    end)

    local hudFps = createStatusTag(topMiddleHud, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/speed.png?raw=true", "FPS_icon.png", "FPS", 0, 115)
    
    local hudDivider = Instance.new("Frame")
    hudDivider.Size = UDim2.new(0, 1, 0.6, 0)
    hudDivider.Position = UDim2.new(0.5, 0, 0.2, 0)
    hudDivider.BackgroundColor3 = Theme.Stroke
    hudDivider.BorderSizePixel = 0
    hudDivider.ZIndex = 51
    hudDivider.Parent = topMiddleHud

    local hudPing = createStatusTag(topMiddleHud, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/network.png?raw=true", "PING_icon.png", "PING", 115, 115)

    local mainApp = Instance.new("CanvasGroup")
    mainApp.Name = "MainApp"
    mainApp.Size = UDim2.new(1, 0, 1, 0)
    mainApp.BackgroundTransparency = 1
    mainApp.Visible = not useKeySystem
    mainApp.ZIndex = 2
    mainApp.Parent = outerContainer

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundColor3 = Theme.Background
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 2
    topBar.Parent = mainApp
    createCorner(topBar, 8)
    createStroke(topBar, Theme.Stroke)

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
    tabListContainer.ZIndex = 2
    tabListContainer.Parent = topBar
    createPadding(tabListContainer, 6, 6, 8, 8)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabListContainer

    windowObj.TabHolder = tabListContainer

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = Theme.Surface
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.ZIndex = 3
    closeBtn.Parent = topBar
    createCorner(closeBtn, 6)
    createStroke(closeBtn, Theme.Stroke)

    closeBtn.MouseEnter:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Accent}) end)
    closeBtn.MouseLeave:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.SubText}) end)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -110) 
    contentArea.Position = UDim2.new(0, 0, 0, 54) 
    contentArea.BackgroundColor3 = Theme.Background
    contentArea.BorderSizePixel = 0
    contentArea.ZIndex = 2
    contentArea.Parent = mainApp
    createCorner(contentArea, 8)
    createStroke(contentArea, Theme.Stroke)
    windowObj.PageHolder = contentArea

    local settingsMenu = Instance.new("Frame")
    settingsMenu.Name = "SettingsMenu"
    settingsMenu.Size = UDim2.new(1, 0, 1, 0)
    settingsMenu.BackgroundColor3 = Theme.Background
    settingsMenu.Visible = false
    settingsMenu.ZIndex = 10
    settingsMenu.Parent = contentArea
    createCorner(settingsMenu, 8)

    local settingsToggleFrame = Instance.new("Frame")
    settingsToggleFrame.Size = UDim2.new(1, -24, 0, 42)
    settingsToggleFrame.Position = UDim2.new(0, 12, 0, 16)
    settingsToggleFrame.BackgroundColor3 = Theme.Surface
    settingsToggleFrame.ZIndex = 11
    settingsToggleFrame.Parent = settingsMenu
    createCorner(settingsToggleFrame, 6)
    createStroke(settingsToggleFrame, Theme.Stroke)
    createPadding(settingsToggleFrame, 0, 0, 4, 12)

    local stText = Instance.new("TextLabel")
    stText.Size = UDim2.new(0.6, 0, 1, 0)
    stText.BackgroundTransparency = 1
    stText.Text = "FPS & Ping Counter"
    stText.TextColor3 = Theme.Text
    stText.Font = Enum.Font.GothamMedium
    stText.TextSize = 13
    stText.TextXAlignment = Enum.TextXAlignment.Left
    stText.ZIndex = 12
    stText.Parent = settingsToggleFrame

    local stTrack = Instance.new("Frame")
    stTrack.Size = UDim2.new(0, 40, 0, 20)
    stTrack.Position = UDim2.new(1, -44, 0.5, -10)
    stTrack.BackgroundColor3 = Config.FPSCounterEnabled and Theme.Accent or Theme.Background
    stTrack.ZIndex = 12
    stTrack.Parent = settingsToggleFrame
    createCorner(stTrack, 20)
    local stTrackStroke = createStroke(stTrack, Config.FPSCounterEnabled and Theme.Accent or Theme.Stroke)

    local stKnob = Instance.new("Frame")
    stKnob.Size = UDim2.new(0, 14, 0, 14)
    stKnob.Position = Config.FPSCounterEnabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    stKnob.BackgroundColor3 = Config.FPSCounterEnabled and Theme.Background or Theme.SubText
    stKnob.ZIndex = 13
    stKnob.Parent = stTrack
    createCorner(stKnob, 14)

    local stBtn = Instance.new("TextButton")
    stBtn.Size = UDim2.new(1, 0, 1, 0)
    stBtn.BackgroundTransparency = 1
    stBtn.Text = ""
    stBtn.ZIndex = 14
    stBtn.Parent = settingsToggleFrame

    stBtn.MouseButton1Click:Connect(function()
        Config.FPSCounterEnabled = not Config.FPSCounterEnabled
        topMiddleHud.Visible = Config.FPSCounterEnabled
        stTrackStroke.Color = Config.FPSCounterEnabled and Theme.Accent or Theme.Stroke
        animate(stTrack, {BackgroundColor3 = Config.FPSCounterEnabled and Theme.Accent or Theme.Background})
        animate(stKnob, {
            Position = Config.FPSCounterEnabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Config.FPSCounterEnabled and Theme.Background or Theme.SubText
        })
        SaveConfig()
    end)

    local settingsKeybindFrame = Instance.new("Frame")
    settingsKeybindFrame.Size = UDim2.new(1, -24, 0, 42)
    settingsKeybindFrame.Position = UDim2.new(0, 12, 0, 68)
    settingsKeybindFrame.BackgroundColor3 = Theme.Surface
    settingsKeybindFrame.ZIndex = 11
    settingsKeybindFrame.Parent = settingsMenu
    createCorner(settingsKeybindFrame, 6)
    createStroke(settingsKeybindFrame, Theme.Stroke)
    createPadding(settingsKeybindFrame, 0, 0, 4, 12)

    local skText = Instance.new("TextLabel")
    skText.Size = UDim2.new(0.6, 0, 1, 0)
    skText.BackgroundTransparency = 1
    skText.Text = "Menu Toggle Key"
    skText.TextColor3 = Theme.Text
    skText.Font = Enum.Font.GothamMedium
    skText.TextSize = 13
    skText.TextXAlignment = Enum.TextXAlignment.Left
    skText.ZIndex = 12
    skText.Parent = settingsKeybindFrame

    local skBtn = Instance.new("TextButton")
    skBtn.Size = UDim2.new(0, 65, 0, 24)
    skBtn.Position = UDim2.new(1, -65, 0.5, -12)
    skBtn.BackgroundColor3 = Theme.Background
    skBtn.Text = currentToggleKey.Name
    skBtn.TextColor3 = Theme.SubText
    skBtn.Font = Enum.Font.Gotham
    skBtn.TextSize = 11
    skBtn.ZIndex = 12
    skBtn.Parent = settingsKeybindFrame
    createCorner(skBtn, 6)
    createStroke(skBtn, Theme.Stroke)

    local skBinding = false
    skBtn.MouseButton1Click:Connect(function()
        if skBinding then return end
        skBinding = true
        skBtn.Text = "..."
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentToggleKey = input.KeyCode
                Config.ToggleKey = currentToggleKey.Name
                skBtn.Text = currentToggleKey.Name
                skBinding = false
                SaveConfig()
                connection:Disconnect()
            end
        end)
    end)

    local settingsThemeFrame = Instance.new("Frame")
    settingsThemeFrame.Size = UDim2.new(1, -24, 0, 42)
    settingsThemeFrame.Position = UDim2.new(0, 12, 0, 120)
    settingsThemeFrame.BackgroundColor3 = Theme.Surface
    settingsThemeFrame.ZIndex = 11
    settingsThemeFrame.Parent = settingsMenu
    createCorner(settingsThemeFrame, 6)
    createStroke(settingsThemeFrame, Theme.Stroke)
    createPadding(settingsThemeFrame, 0, 0, 4, 12)

    local stmText = Instance.new("TextLabel")
    stmText.Size = UDim2.new(0.5, 0, 1, 0)
    stmText.BackgroundTransparency = 1
    stmText.Text = "UI Theme"
    stmText.TextColor3 = Theme.Text
    stmText.Font = Enum.Font.GothamMedium
    stmText.TextSize = 13
    stmText.TextXAlignment = Enum.TextXAlignment.Left
    stmText.ZIndex = 12
    stmText.Parent = settingsThemeFrame

    local themeNames = {"Default (Dark)", "Midnight Blue", "Crimson Red", "Emerald"}
    local currentThemeIndex = 1
    for i, name in ipairs(themeNames) do
        if name == Config.Theme then currentThemeIndex = i break end
    end

    local stmBtn = Instance.new("TextButton")
    stmBtn.Size = UDim2.new(0, 115, 0, 24)
    stmBtn.Position = UDim2.new(1, -115, 0.5, -12)
    stmBtn.BackgroundColor3 = Theme.Background
    stmBtn.Text = themeNames[currentThemeIndex]
    stmBtn.TextColor3 = Theme.Accent
    stmBtn.Font = Enum.Font.Gotham
    stmBtn.TextSize = 11
    stmBtn.ZIndex = 12
    stmBtn.Parent = settingsThemeFrame
    createCorner(stmBtn, 6)
    createStroke(stmBtn, Theme.Stroke)

    stmBtn.MouseButton1Click:Connect(function()
        currentThemeIndex = currentThemeIndex % #themeNames + 1
        local selectedThemeName = themeNames[currentThemeIndex]
        stmBtn.Text = selectedThemeName
        Config.Theme = selectedThemeName
        LoadTheme(selectedThemeName)
        SaveConfig()

        topBar.BackgroundColor3 = Theme.Background
        contentArea.BackgroundColor3 = Theme.Background
        bottomBar.BackgroundColor3 = Theme.Background
        settingsMenu.BackgroundColor3 = Theme.Background
        topMiddleHud.BackgroundColor3 = Theme.Surface
        closeBtn.BackgroundColor3 = Theme.Surface
        closeBtn.TextColor3 = Theme.SubText
        settingsToggleFrame.BackgroundColor3 = Theme.Surface
        stText.TextColor3 = Theme.Text
        settingsKeybindFrame.BackgroundColor3 = Theme.Surface
        skText.TextColor3 = Theme.Text
        skBtn.BackgroundColor3 = Theme.Background
        skBtn.TextColor3 = Theme.SubText
        settingsThemeFrame.BackgroundColor3 = Theme.Surface
        stmText.TextColor3 = Theme.Text
        stmBtn.BackgroundColor3 = Theme.Background
        stmBtn.TextColor3 = Theme.Accent
    end)

    local closeSettingsBtn = Instance.new("TextButton")
    closeSettingsBtn.Size = UDim2.new(0, 100, 0, 30)
    closeSettingsBtn.Position = UDim2.new(0.5, -50, 0, 178)
    closeSettingsBtn.BackgroundColor3 = Theme.Surface
    closeSettingsBtn.Text = "Back"
    closeSettingsBtn.TextColor3 = Theme.Accent
    closeSettingsBtn.Font = Enum.Font.GothamBold
    closeSettingsBtn.TextSize = 12
    closeSettingsBtn.ZIndex = 11
    closeSettingsBtn.Parent = settingsMenu
    createCorner(closeSettingsBtn, 6)
    createStroke(closeSettingsBtn, Theme.Stroke)

    closeSettingsBtn.MouseButton1Click:Connect(function()
        settingsMenu.Visible = false
    end)

    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 46)
    bottomBar.Position = UDim2.new(0, 0, 1, -46)
    bottomBar.BackgroundColor3 = Theme.Background
    bottomBar.ZIndex = 2
    bottomBar.Parent = mainApp
    createCorner(bottomBar, 8)
    createStroke(bottomBar, Theme.Stroke)
    createPadding(bottomBar, 6, 6, 8, 8)

    local fpsWrapper = Instance.new("Frame")
    fpsWrapper.Size = UDim2.new(0, 105, 1, 0)
    fpsWrapper.BackgroundColor3 = Theme.Surface
    fpsWrapper.ZIndex = 3
    fpsWrapper.Parent = bottomBar
    createCorner(fpsWrapper, 6)
    createStroke(fpsWrapper, Theme.Stroke)
    
    local pingWrapper = Instance.new("Frame")
    pingWrapper.Size = UDim2.new(0, 115, 1, 0)
    pingWrapper.Position = UDim2.new(0, 113, 0, 0)
    pingWrapper.BackgroundColor3 = Theme.Surface
    pingWrapper.ZIndex = 3
    pingWrapper.Parent = bottomBar
    createCorner(pingWrapper, 6)
    createStroke(pingWrapper, Theme.Stroke)

    local fpsLabel = createStatusTag(fpsWrapper, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/speed.png?raw=true", "FPS_icon.png", "FPS", 0, 105)
    local pingLabel = createStatusTag(pingWrapper, "https://github.com/ntxcrim69/NatrixLibrary/blob/main/network.png?raw=true", "PING_icon.png", "PING", 0, 115)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(0, 32, 0, 32)
    settingsBtn.Position = UDim2.new(1, -32, 0.5, -16)
    settingsBtn.BackgroundColor3 = Theme.Surface
    settingsBtn.Text = "⚙"
    settingsBtn.TextColor3 = Theme.SubText
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.TextSize = 18
    settingsBtn.ZIndex = 3
    settingsBtn.Parent = bottomBar
    createCorner(settingsBtn, 6)
    createStroke(settingsBtn, Theme.Stroke)

    settingsBtn.MouseEnter:Connect(function() animate(settingsBtn, {BackgroundColor3 = Theme.SurfaceElevated, TextColor3 = Theme.Accent}) end)
    settingsBtn.MouseLeave:Connect(function() animate(settingsBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.SubText}) end)
    settingsBtn.MouseButton1Click:Connect(function() settingsMenu.Visible = not settingsMenu.Visible end)

    local frames = 0
    local lastUpdate = os.clock()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastUpdate >= 1 then
            local currentFPS = tostring(frames)
            fpsLabel.Text = "FPS: " .. currentFPS
            hudFps.Text = "FPS: " .. currentFPS
            frames = 0
            lastUpdate = now
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            local pingVal = 0
            local success, result = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if success and result then
                pingVal = math.floor(result * 1000)
            else
                pcall(function() pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            end
            local currentPing = tostring(pingVal)
            pingLabel.Text = "PING: " .. currentPing
            hudPing.Text = "PING: " .. currentPing
        end
    end)

    return windowObj
end

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
    tabBtn.ZIndex = 3
    tabBtn.Parent = window.TabHolder
    createCorner(tabBtn, 6)

    local pageFrame = Instance.new("Frame")
    pageFrame.Name = tabName .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    pageFrame.ZIndex = 3
    pageFrame.Parent = window.PageHolder

    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Size = UDim2.new(1, -16, 1, -16)
    container.Position = UDim2.new(0, 8, 0, 8)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 2
    container.ScrollBarImageColor3 = Theme.Stroke
    container.ZIndex = 4
    container.Parent = pageFrame
    createPadding(container, 2, 2, 2, 2)

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = container

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local tabObj = { Button = tabBtn, Page = pageFrame, Container = container }
    setmetatable(tabObj, Tab)
    table.insert(window.Tabs, tabObj)

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

function Tab:CreateToggle(label, defaultState, callback)
    callback = callback or function() end
    local state = defaultState or false

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 42)
    toggleFrame.BackgroundColor3 = Theme.Surface
    toggleFrame.ZIndex = 5
    toggleFrame.Parent = self.Container
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
    textLabel.ZIndex = 6
    textLabel.Parent = toggleFrame

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 40, 0, 20)
    switchTrack.Position = UDim2.new(1, -44, 0.5, -10)
    switchTrack.BackgroundColor3 = state and Theme.Accent or Theme.Background
    switchTrack.ZIndex = 6
    switchTrack.Parent = toggleFrame
    createCorner(switchTrack, 20)
    local trackStroke = createStroke(switchTrack, Theme.Stroke)

    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 14, 0, 14)
    switchKnob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    switchKnob.BackgroundColor3 = state and Theme.Background or Theme.SubText
    switchKnob.ZIndex = 7
    switchKnob.Parent = switchTrack
    createCorner(switchKnob, 14)

    local interactBtn = Instance.new("TextButton")
    interactBtn.Size = UDim2.new(1, 0, 1, 0)
    interactBtn.BackgroundTransparency = 1
    interactBtn.Text = ""
    interactBtn.ZIndex = 8
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

function Tab:CreateButton(label, buttonText, defaultKey, callback)
    if type(defaultKey) == "function" then
        callback = defaultKey
        defaultKey = nil
    end
    callback = callback or function() end
    buttonText = buttonText or "Button"
    local currentKey = defaultKey

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.new(1, 0, 0, 42)
    containerFrame.BackgroundColor3 = Theme.Surface
    containerFrame.ZIndex = 5
    containerFrame.Parent = self.Container
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
    textLabel.ZIndex = 6
    textLabel.Parent = containerFrame

    local actionBtnWidth = currentKey and 100 or 110
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(0, actionBtnWidth, 0, 24)
    actionBtn.Position = UDim2.new(1, -actionBtnWidth, 0.5, -12)
    actionBtn.BackgroundColor3 = Theme.Surface
    actionBtn.Text = buttonText
    actionBtn.TextColor3 = Theme.Accent
    actionBtn.Font = Enum.Font.GothamMedium
    actionBtn.TextSize = 11
    actionBtn.ZIndex = 6
    actionBtn.Parent = containerFrame
    createCorner(actionBtn, 6)
    createStroke(actionBtn, Theme.Stroke)

    actionBtn.MouseEnter:Connect(function() animate(actionBtn, {BackgroundColor3 = Theme.SurfaceElevated}) end)
    actionBtn.MouseLeave:Connect(function() animate(actionBtn, {BackgroundColor3 = Theme.Surface}) end)

    actionBtn.MouseButton1Click:Connect(function()
        task.spawn(callback, currentKey)
    end)

    if currentKey then
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(0, 40, 0, 24)
        keybindBtn.Position = UDim2.new(1, -(actionBtnWidth + 46), 0.5, -12)
        keybindBtn.BackgroundColor3 = Theme.Surface
        keybindBtn.Text = currentKey.Name
        keybindBtn.TextColor3 = Theme.SubText
        keybindBtn.Font = Enum.Font.Gotham
        keybindBtn.TextSize = 11
        keybindBtn.ZIndex = 6
        keybindBtn.Parent = containerFrame
        createCorner(keybindBtn, 6)
        createStroke(keybindBtn, Theme.Stroke)

        local binding = false
        keybindBtn.MouseButton1Click:Connect(function()
            if binding then return end
            binding = true
            keybindBtn.Text = "..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        keybindBtn.Text = currentKey.Name
                        binding = false
                        connection:Disconnect()
                    else
                        currentKey = input.KeyCode
                        keybindBtn.Text = currentKey.Name
                        binding = false
                        connection:Disconnect()
                    end
                end
            end)
        end)
    end
end

-- ==========================================
-- Example Initialization matching screenshot
-- ==========================================

local Window = Library:CreateWindow({
    Name = "Natrix Interface",
    KeySystem = false
})

local VisualsTab = Window:CreateTab("Visuals")
local TeleportsTab = Window:CreateTab("Teleports")
local AutoTab = Window:CreateTab("Auto")
local CombatTab = Window:CreateTab("Combat")

VisualsTab:CreateToggle("ESP Tokens", false, function(state)
    print("ESP Tokens:", state)
end)

VisualsTab:CreateToggle("ESP Abandoned Eggs", false, function(state)
    print("ESP Abandoned Eggs:", state)
end)

VisualsTab:CreateToggle("ESP Shrooms", false, function(state)
    print("ESP Shrooms:", state)
end)

VisualsTab:CreateToggle("No Fog", false, function(state)
    print("No Fog:", state)
end)

VisualsTab:CreateButton("FPS Boost", "Run", nil, function()
    print("FPS Boost executed!")
end)
