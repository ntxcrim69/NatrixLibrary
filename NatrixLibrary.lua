--[[
    Library Wrapper - "Natrix Pro" (Updated Seamless Theme)
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
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Configuration File Persistence System
local ConfigFileName = "NatrixPro_Config.json"
local Config = {
    FPSCounterEnabled = false,
    ToggleKey = "RightShift",
    ThemeName = "Black Hole",
    BackgroundImageId = "rbxassetid://134736124666311",
    BackgroundTransparency = 0.1
}

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
        end
    end
end

LoadConfig()

local ThemeOptions = {
    ["Black Hole"] = "rbxassetid://134736124666311",
    ["Dark Theme"] = ""
}

if not ThemeOptions[Config.ThemeName] then
    Config.ThemeName = "Black Hole"
end
Config.BackgroundImageId = ThemeOptions[Config.ThemeName]

-- Sleek Dark Design System Constants
local Theme = {
    Background = Color3.fromRGB(10, 10, 10),
    Surface = Color3.fromRGB(18, 18, 18),
    SurfaceElevated = Color3.fromRGB(28, 28, 28),
    Stroke = Color3.fromRGB(40, 40, 40),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(160, 160, 160),
    Danger = Color3.fromRGB(255, 55, 55)
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

-- External Image Fetcher
local imageCache = {}
local function FetchExternalImage(url, fileName, fallbackAssetId)
    if imageCache[fileName] and imageCache[fileName] ~= "" then 
        return imageCache[fileName] 
    end
    
    local success, asset = pcall(function()
        if isfile and writefile and getcustomasset then
            if isfile(fileName) and readfile then
                local content = readfile(fileName)
                if #content == 0 or content:find("404") or content:find("400") then
                    if delfile then pcall(delfile, fileName) end
                end
            end
            
            if not isfile(fileName) then
                local imgData = game:HttpGet(url)
                if imgData and #imgData > 0 and not imgData:find("404") and not imgData:find("400") then
                    writefile(fileName, imgData)
                else
                    return ""
                end
            end
            return getcustomasset(fileName)
        end
        return ""
    end)
    
    local result = (success and asset and asset ~= "") and asset or (fallbackAssetId or "")
    if result ~= "" then
        imageCache[fileName] = result
    end
    return result
end

-- Status Tag Creator
local function createStatusTag(parent, iconUrl, fileName, labelText, xOffset, width, fallbackAssetId)
    local baseZIndex = parent.ZIndex or 1

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, xOffset + 12, 0.5, -8)
    icon.BackgroundTransparency = 1
    
    local loadedImg = FetchExternalImage(iconUrl, fileName, fallbackAssetId)
    icon.Image = (loadedImg ~= "") and loadedImg or (fallbackAssetId or "")
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
    local useKeySystem = (config.KeySystem == true)
    local keySettings = config.KeySettings or { Keys = {}, Discord = "" }

    -- ScreenGui Parent Protection
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

    local windowObj = {
        Gui = screenGui,
        Tabs = {},
        ActiveTab = nil,
        TabHolder = nil,
        PageHolder = nil,
        Elements = {}
    }
    setmetatable(windowObj, Library)

    function windowObj:GetElementTransparency()
        local isDarkTheme = (Config.ThemeName == "Dark Theme") or (Config.BackgroundImageId == "")
        return isDarkTheme and 0 or 0.45
    end

    function windowObj:RegisterElement(element, customTransparency)
        table.insert(windowObj.Elements, {
            Instance = element,
            CustomTransparency = customTransparency
        })
        element.BackgroundTransparency = customTransparency or windowObj:GetElementTransparency()
    end

    -- Master Outer Container
    local outerContainer = Instance.new("Frame")
    outerContainer.Name = "OuterContainer"
    outerContainer.Size = UDim2.new(0, 620, 0, 480)
    outerContainer.Position = UDim2.new(0.5, -310, 0.5, -240)
    outerContainer.BackgroundColor3 = Theme.Background
    outerContainer.BackgroundTransparency = 0
    outerContainer.ClipsDescendants = true
    outerContainer.ZIndex = 1
    outerContainer.Parent = screenGui
    createCorner(outerContainer, 8)
    createStroke(outerContainer, Theme.Stroke)

    -- Master Seamless Background Image
    local masterBackground = Instance.new("ImageLabel")
    masterBackground.Name = "MasterBackgroundImage"
    masterBackground.Size = UDim2.new(1, 0, 1, 0)
    masterBackground.Position = UDim2.new(0, 0, 0, 0)
    masterBackground.BackgroundTransparency = 1
    masterBackground.Image = Config.BackgroundImageId
    masterBackground.ImageTransparency = Config.BackgroundTransparency
    masterBackground.ScaleType = Enum.ScaleType.Crop
    masterBackground.ZIndex = 1
    masterBackground.Parent = outerContainer
    createCorner(masterBackground, 8)

    -- Dark Vignette Overlay for Depth
    local darkOverlay = Instance.new("Frame")
    darkOverlay.Name = "DarkOverlay"
    darkOverlay.Size = UDim2.new(1, 0, 1, 0)
    darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    darkOverlay.BackgroundTransparency = 0.35
    darkOverlay.ZIndex = 1
    darkOverlay.Parent = outerContainer
    createCorner(darkOverlay, 8)

    local currentToggleKey = Enum.KeyCode[Config.ToggleKey] or Enum.KeyCode.RightShift

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == currentToggleKey then
            outerContainer.Visible = not outerContainer.Visible
        end
    end)

    -- Top Middle HUD Overlay
    local topMiddleHud = Instance.new("Frame")
    topMiddleHud.Name = "TopMiddleHud"
    topMiddleHud.Size = UDim2.new(0, 230, 0, 32)
    topMiddleHud.Position = UDim2.new(0.5, -115, 0, 10)
    topMiddleHud.BackgroundColor3 = Theme.Surface
    topMiddleHud.BackgroundTransparency = 0.2
    topMiddleHud.Visible = Config.FPSCounterEnabled
    topMiddleHud.ZIndex = 50
    topMiddleHud.Parent = screenGui
    createCorner(topMiddleHud, 6)
    createStroke(topMiddleHud, Theme.Stroke)

    local hudFps = createStatusTag(topMiddleHud, "https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/speed.png", "FPS_icon.png", "FPS", 0, 115, "rbxassetid://10747373176")
    
    local hudDivider = Instance.new("Frame")
    hudDivider.Size = UDim2.new(0, 1, 0.6, 0)
    hudDivider.Position = UDim2.new(0.5, 0, 0.2, 0)
    hudDivider.BackgroundColor3 = Theme.Stroke
    hudDivider.BorderSizePixel = 0
    hudDivider.ZIndex = 51
    hudDivider.Parent = topMiddleHud

    local hudPing = createStatusTag(topMiddleHud, "https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/network.png", "PING_icon.png", "PING", 115, 115, "rbxassetid://10734934585")

    -- Main UI Layout Setup
    local mainApp = Instance.new("Frame")
    mainApp.Name = "MainApp"
    mainApp.Size = UDim2.new(1, 0, 1, 0)
    mainApp.BackgroundTransparency = 1
    mainApp.Visible = not useKeySystem
    mainApp.ZIndex = 2
    mainApp.Parent = outerContainer

    local function updateTheme()
        local isDarkTheme = (Config.ThemeName == "Dark Theme") or (Config.BackgroundImageId == "")
        masterBackground.Image = Config.BackgroundImageId
        masterBackground.ImageTransparency = isDarkTheme and 1 or Config.BackgroundTransparency
        darkOverlay.BackgroundTransparency = isDarkTheme and 0 or 0.35

        local elemTransparency = windowObj:GetElementTransparency()
        for _, elemData in ipairs(windowObj.Elements) do
            if elemData.Instance and elemData.Instance.Parent then
                elemData.Instance.BackgroundTransparency = elemData.CustomTransparency or elemTransparency
            end
        end
    end

    -- 1. Top Navigation Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.BackgroundTransparency = 1
    topBar.ZIndex = 3
    topBar.Parent = mainApp

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
    tabListContainer.ZIndex = 4
    tabListContainer.Parent = topBar
    createPadding(tabListContainer, 6, 6, 12, 8)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabListContainer

    windowObj.TabHolder = tabListContainer

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = Theme.Surface
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.SubText
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.ZIndex = 5
    closeBtn.Parent = topBar
    createCorner(closeBtn, 4)
    createStroke(closeBtn, Theme.Stroke)
    windowObj:RegisterElement(closeBtn)

    closeBtn.MouseEnter:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Accent, BackgroundTransparency = 0}) end)
    closeBtn.MouseLeave:Connect(function() animate(closeBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.SubText, BackgroundTransparency = windowObj:GetElementTransparency()}) end)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- Top Divider Line
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.Position = UDim2.new(0, 0, 0, 44)
    topDivider.BackgroundColor3 = Theme.Stroke
    topDivider.BorderSizePixel = 0
    topDivider.ZIndex = 4
    topDivider.Parent = mainApp

    -- 2. Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -90) 
    contentArea.Position = UDim2.new(0, 0, 0, 45) 
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = 3
    contentArea.Parent = mainApp

    windowObj.PageHolder = contentArea

    -- 3. Settings Menu Overlay
    local settingsMenu = Instance.new("Frame")
    settingsMenu.Name = "SettingsMenu"
    settingsMenu.Size = UDim2.new(1, 0, 1, 0)
    settingsMenu.BackgroundColor3 = Theme.Background
    settingsMenu.BackgroundTransparency = 0.1
    settingsMenu.Visible = false
    settingsMenu.ZIndex = 20
    settingsMenu.Parent = contentArea
    createCorner(settingsMenu, 6)

    -- Settings Item 1: FPS Counter
    local settingsToggleFrame = Instance.new("Frame")
    settingsToggleFrame.Size = UDim2.new(1, -24, 0, 42)
    settingsToggleFrame.Position = UDim2.new(0, 12, 0, 16)
    settingsToggleFrame.BackgroundColor3 = Theme.Surface
    settingsToggleFrame.ZIndex = 21
    settingsToggleFrame.Parent = settingsMenu
    createCorner(settingsToggleFrame, 6)
    createStroke(settingsToggleFrame, Theme.Stroke)
    createPadding(settingsToggleFrame, 0, 0, 4, 12)
    windowObj:RegisterElement(settingsToggleFrame)

    local stText = Instance.new("TextLabel")
    stText.Size = UDim2.new(0.6, 0, 1, 0)
    stText.BackgroundTransparency = 1
    stText.Text = "FPS & Ping Counter"
    stText.TextColor3 = Theme.Text
    stText.Font = Enum.Font.GothamMedium
    stText.TextSize = 13
    stText.TextXAlignment = Enum.TextXAlignment.Left
    stText.ZIndex = 22
    stText.Parent = settingsToggleFrame

    local stTrack = Instance.new("Frame")
    stTrack.Size = UDim2.new(0, 40, 0, 20)
    stTrack.Position = UDim2.new(1, -44, 0.5, -10)
    stTrack.BackgroundColor3 = Config.FPSCounterEnabled and Theme.Accent or Theme.Background
    stTrack.BackgroundTransparency = 0
    stTrack.ZIndex = 22
    stTrack.Parent = settingsToggleFrame
    createCorner(stTrack, 20)
    local stTrackStroke = createStroke(stTrack, Config.FPSCounterEnabled and Theme.Accent or Theme.Stroke)

    local stKnob = Instance.new("Frame")
    stKnob.Size = UDim2.new(0, 14, 0, 14)
    stKnob.Position = Config.FPSCounterEnabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    stKnob.BackgroundColor3 = Config.FPSCounterEnabled and Theme.Background or Theme.SubText
    stKnob.ZIndex = 23
    stKnob.Parent = stTrack
    createCorner(stKnob, 14)

    local stBtn = Instance.new("TextButton")
    stBtn.Size = UDim2.new(1, 0, 1, 0)
    stBtn.BackgroundTransparency = 1
    stBtn.Text = ""
    stBtn.ZIndex = 24
    stBtn.Parent = settingsToggleFrame

    stBtn.MouseButton1Click:Connect(function()
        Config.FPSCounterEnabled = not Config.FPSCounterEnabled
        topMiddleHud.Visible = Config.FPSCounterEnabled
        stTrackStroke.Color = Config.FPSCounterEnabled and Theme.Accent or Theme.Stroke
        animate(stTrack, {
            BackgroundColor3 = Config.FPSCounterEnabled and Theme.Accent or Theme.Background,
            BackgroundTransparency = 0
        })
        animate(stKnob, {
            Position = Config.FPSCounterEnabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = Config.FPSCounterEnabled and Theme.Background or Theme.SubText
        })
        SaveConfig()
    end)

    -- Settings Item 2: Theme Selector
    local themeFrame = Instance.new("Frame")
    themeFrame.Size = UDim2.new(1, -24, 0, 42)
    themeFrame.Position = UDim2.new(0, 12, 0, 68)
    themeFrame.BackgroundColor3 = Theme.Surface
    themeFrame.ZIndex = 21
    themeFrame.Parent = settingsMenu
    createCorner(themeFrame, 6)
    createStroke(themeFrame, Theme.Stroke)
    createPadding(themeFrame, 0, 0, 4, 12)
    windowObj:RegisterElement(themeFrame)

    local themeText = Instance.new("TextLabel")
    themeText.Size = UDim2.new(0.38, 0, 1, 0)
    themeText.BackgroundTransparency = 1
    themeText.Text = "Theme"
    themeText.TextColor3 = Theme.Text
    themeText.Font = Enum.Font.GothamMedium
    themeText.TextSize = 13
    themeText.TextXAlignment = Enum.TextXAlignment.Left
    themeText.ZIndex = 22
    themeText.Parent = themeFrame

    local themeButton = Instance.new("TextButton")
    themeButton.Size = UDim2.new(0, 150, 0, 26)
    themeButton.Position = UDim2.new(1, -150, 0.5, -13)
    themeButton.BackgroundColor3 = Theme.Background
    themeButton.Text = Config.ThemeName .. "  v"
    themeButton.TextColor3 = Theme.SubText
    themeButton.Font = Enum.Font.Gotham
    themeButton.TextSize = 11
    themeButton.ZIndex = 24
    themeButton.Parent = themeFrame
    createCorner(themeButton, 4)
    createStroke(themeButton, Theme.Stroke)
    windowObj:RegisterElement(themeButton)

    local themeList = Instance.new("Frame")
    themeList.Size = UDim2.new(0, 150, 0, 60)
    themeList.Position = UDim2.new(1, -150, 1, 4)
    themeList.BackgroundColor3 = Theme.SurfaceElevated
    themeList.BackgroundTransparency = 0
    themeList.Visible = false
    themeList.ZIndex = 30
    themeList.Parent = themeFrame
    createCorner(themeList, 6)
    createStroke(themeList, Theme.Stroke)
    createPadding(themeList, 4, 4, 4, 4)

    local themeLayout = Instance.new("UIListLayout")
    themeLayout.Padding = UDim.new(0, 2)
    themeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    themeLayout.Parent = themeList

    for themeName, imageId in pairs(ThemeOptions) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, 0, 0, 24)
        option.BackgroundColor3 = Theme.SurfaceElevated
        option.BackgroundTransparency = 0
        option.Text = themeName
        option.TextColor3 = Theme.Text
        option.Font = Enum.Font.Gotham
        option.TextSize = 11
        option.ZIndex = 31
        option.Parent = themeList
        option.MouseButton1Click:Connect(function()
            Config.ThemeName = themeName
            Config.BackgroundImageId = imageId
            updateTheme()
            themeButton.Text = themeName .. "  v"
            themeList.Visible = false
            SaveConfig()
        end)
    end

    themeButton.MouseButton1Click:Connect(function()
        themeList.Visible = not themeList.Visible
    end)

    -- Close Settings Button
    local closeSettingsBtn = Instance.new("TextButton")
    closeSettingsBtn.Size = UDim2.new(0, 100, 0, 30)
    closeSettingsBtn.Position = UDim2.new(0.5, -50, 1, -45)
    closeSettingsBtn.BackgroundColor3 = Theme.Surface
    closeSettingsBtn.Text = "Back"
    closeSettingsBtn.TextColor3 = Theme.Accent
    closeSettingsBtn.Font = Enum.Font.GothamBold
    closeSettingsBtn.TextSize = 12
    closeSettingsBtn.ZIndex = 21
    closeSettingsBtn.Parent = settingsMenu
    createCorner(closeSettingsBtn, 6)
    createStroke(closeSettingsBtn, Theme.Stroke)
    windowObj:RegisterElement(closeSettingsBtn)

    closeSettingsBtn.MouseButton1Click:Connect(function()
        settingsMenu.Visible = false
    end)

    -- Bottom Divider Line
    local bottomDivider = Instance.new("Frame")
    bottomDivider.Size = UDim2.new(1, 0, 0, 1)
    bottomDivider.Position = UDim2.new(0, 0, 1, -45)
    bottomDivider.BackgroundColor3 = Theme.Stroke
    bottomDivider.BorderSizePixel = 0
    bottomDivider.ZIndex = 4
    bottomDivider.Parent = mainApp

    -- 4. Bottom Status Bar
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, 0, 44)
    bottomBar.Position = UDim2.new(0, 0, 1, -44)
    bottomBar.BackgroundTransparency = 1
    bottomBar.ZIndex = 3
    bottomBar.Parent = mainApp

    local bottomContent = Instance.new("Frame")
    bottomContent.Name = "BottomContent"
    bottomContent.Size = UDim2.new(1, 0, 1, 0)
    bottomContent.BackgroundTransparency = 1
    bottomContent.ZIndex = 4
    bottomContent.Parent = bottomBar
    createPadding(bottomContent, 6, 6, 12, 12)

    local fpsWrapper = Instance.new("Frame")
    fpsWrapper.Size = UDim2.new(0, 105, 1, 0)
    fpsWrapper.BackgroundColor3 = Theme.Surface
    fpsWrapper.ZIndex = 5
    fpsWrapper.Parent = bottomContent
    createCorner(fpsWrapper, 6)
    createStroke(fpsWrapper, Theme.Stroke)
    windowObj:RegisterElement(fpsWrapper)
    
    local pingWrapper = Instance.new("Frame")
    pingWrapper.Size = UDim2.new(0, 115, 1, 0)
    pingWrapper.Position = UDim2.new(0, 113, 0, 0)
    pingWrapper.BackgroundColor3 = Theme.Surface
    pingWrapper.ZIndex = 5
    pingWrapper.Parent = bottomContent
    createCorner(pingWrapper, 6)
    createStroke(pingWrapper, Theme.Stroke)
    windowObj:RegisterElement(pingWrapper)

    local fpsLabel = createStatusTag(fpsWrapper, "https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/speed.png", "FPS_icon.png", "FPS", 0, 105, "rbxassetid://10747373176")
    local pingLabel = createStatusTag(pingWrapper, "https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/network.png", "PING_icon.png", "PING", 0, 115, "rbxassetid://10734934585")

    -- Settings Button
    local settingsBtn = Instance.new("ImageButton")
    settingsBtn.Name = "SettingsBtn"
    settingsBtn.Size = UDim2.new(0, 30, 0, 30)
    settingsBtn.Position = UDim2.new(1, -30, 0.5, -15)
    settingsBtn.BackgroundColor3 = Theme.Surface
    settingsBtn.AutoButtonColor = false
    settingsBtn.ZIndex = 5
    settingsBtn.Parent = bottomContent
    createCorner(settingsBtn, 6)
    createStroke(settingsBtn, Theme.Stroke)
    windowObj:RegisterElement(settingsBtn)

    local settingsIcon = Instance.new("ImageLabel")
    settingsIcon.Name = "SettingsIcon"
    settingsIcon.Size = UDim2.new(0, 16, 0, 16)
    settingsIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
    settingsIcon.BackgroundTransparency = 1

    local fetchedSettings = FetchExternalImage("https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/settings.png", "Settings_icon.png", "rbxassetid://10734950309")
    settingsIcon.Image = (fetchedSettings ~= "") and fetchedSettings or "rbxassetid://10734950309"
    settingsIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    settingsIcon.ZIndex = 6
    settingsIcon.Parent = settingsBtn

    settingsBtn.MouseEnter:Connect(function() 
        animate(settingsBtn, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0}) 
        animate(settingsIcon, {ImageColor3 = Theme.Background})
    end)
    settingsBtn.MouseLeave:Connect(function() 
        animate(settingsBtn, {BackgroundColor3 = Theme.Surface, BackgroundTransparency = windowObj:GetElementTransparency()}) 
        animate(settingsIcon, {ImageColor3 = Color3.fromRGB(255, 255, 255)})
    end)
    settingsBtn.MouseButton1Click:Connect(function()
        settingsMenu.Visible = not settingsMenu.Visible
    end)

    updateTheme()

    -- Live Stats Calculation
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
            local success, result = pcall(function()
                return LocalPlayer:GetNetworkPing()
            end)
            
            if success and result then
                pingVal = math.floor(result * 1000)
            else
                pcall(function()
                    pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
            end
            
            local currentPing = tostring(pingVal)
            pingLabel.Text = "PING: " .. currentPing
            hudPing.Text = "PING: " .. currentPing
        end
    end)

    -- 5. Key System Overlay
    if useKeySystem then
        local keyModal = Instance.new("CanvasGroup")
        keyModal.Name = "KeyModal"
        keyModal.Size = UDim2.new(0, 440, 0, 320)
        keyModal.Position = UDim2.new(0.5, -220, 0.5, -160)
        keyModal.BackgroundColor3 = Theme.Background
        keyModal.BackgroundTransparency = 0
        keyModal.BorderSizePixel = 0
        keyModal.ZIndex = 100
        keyModal.Parent = outerContainer
        createCorner(keyModal, 8)
        createStroke(keyModal, Theme.Stroke)

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

        local discordBtn = Instance.new("ImageButton")
        discordBtn.Size = UDim2.new(0, 24, 0, 24)
        discordBtn.Position = UDim2.new(1, -36, 0, 12)
        discordBtn.BackgroundTransparency = 1
        local fetchedDiscord = FetchExternalImage("https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/discord.png", "NatrixDiscord.png", "rbxassetid://10709768652")
        discordBtn.Image = (fetchedDiscord ~= "") and fetchedDiscord or "rbxassetid://10709768652"
        discordBtn.ZIndex = 101
        discordBtn.Parent = keyModal
        
        discordBtn.MouseEnter:Connect(function() animate(discordBtn, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -37, 0, 11)}) end)
        discordBtn.MouseLeave:Connect(function() animate(discordBtn, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -36, 0, 12)}) end)
        discordBtn.MouseButton1Click:Connect(function() if setclipboard and keySettings.Discord then setclipboard(keySettings.Discord) end end)

        local logoLabel = Instance.new("ImageLabel")
        logoLabel.Size = UDim2.new(0, 100, 0, 100)
        logoLabel.Position = UDim2.new(0.5, -50, 0.1, 0)
        logoLabel.BackgroundTransparency = 1
        local fetchedLogo = FetchExternalImage("https://raw.githubusercontent.com/ntxcrim69/NatrixLibrary/main/Natrixlogo.png", "NatrixLogo.png", "rbxassetid://10734950309")
        logoLabel.Image = (fetchedLogo ~= "") and fetchedLogo or "rbxassetid://10734950309"
        logoLabel.ScaleType = Enum.ScaleType.Fit
        logoLabel.ZIndex = 101
        logoLabel.Parent = keyModal

        local keyInput = Instance.new("TextBox")
        keyInput.Size = UDim2.new(0, 300, 0, 46)
        keyInput.Position = UDim2.new(0.5, -150, 0.52, 0)
        keyInput.BackgroundColor3 = Theme.Surface
        keyInput.BackgroundTransparency = 0
        keyInput.TextColor3 = Theme.Accent
        keyInput.PlaceholderText = "Enter Authentication Key"
        keyInput.PlaceholderColor3 = Theme.SubText
        keyInput.Text = ""
        keyInput.Font = Enum.Font.GothamMedium
        keyInput.TextSize = 13
        keyInput.ZIndex = 101
        keyInput.Parent = keyModal
        createCorner(keyInput, 6)
        createStroke(keyInput, Theme.Stroke)

        local checkBtn = Instance.new("TextButton")
        checkBtn.Size = UDim2.new(0, 140, 0, 42)
        checkBtn.Position = UDim2.new(0.5, -70, 0.72, 0)
        checkBtn.BackgroundColor3 = Theme.Surface
        checkBtn.BackgroundTransparency = 0
        checkBtn.TextColor3 = Theme.Accent
        checkBtn.Text = "Authenticate"
        checkBtn.Font = Enum.Font.GothamBold
        checkBtn.TextSize = 13
        checkBtn.ZIndex = 101
        checkBtn.Parent = keyModal
        createCorner(checkBtn, 6)
        createStroke(checkBtn, Theme.Stroke)

        checkBtn.MouseEnter:Connect(function() animate(checkBtn, {BackgroundColor3 = Theme.SurfaceElevated, BackgroundTransparency = 0}) end)
        checkBtn.MouseLeave:Connect(function() animate(checkBtn, {BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0}) end)

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
                local outTween = TweenService:Create(keyModal, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -220, 0.45, -160), GroupTransparency = 1})
                outTween:Play()
                outTween.Completed:Wait()
                keyModal:Destroy()
                
                mainApp.Visible = true
                mainApp.GroupTransparency = 1
                TweenService:Create(mainApp, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
            else
                keyInput.Text = ""
                keyInput.PlaceholderText = "Invalid Key!"
                local errTween = animate(keyInput, {BackgroundColor3 = Theme.Danger, BackgroundTransparency = 0})
                task.wait(1)
                animate(keyInput, {BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0})
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
    tabBtn.Size = UDim2.new(0, 80, 1, -8)
    tabBtn.Position = UDim2.new(0, 0, 0, 4)
    tabBtn.BackgroundColor3 = Theme.Surface
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Theme.SubText
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 13
    tabBtn.ZIndex = 5
    tabBtn.Parent = window.TabHolder
    createCorner(tabBtn, 4)

    local pageFrame = Instance.new("Frame")
    pageFrame.Name = tabName .. "_Page"
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.Visible = false
    pageFrame.ZIndex = 4
    pageFrame.Parent = window.PageHolder

    local container = Instance.new("ScrollingFrame")
    container.Name = "Container"
    container.Size = UDim2.new(1, -16, 1, -16)
    container.Position = UDim2.new(0, 8, 0, 8)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 0
    container.ZIndex = 5
    container.Parent = pageFrame
    createPadding(container, 4, 4, 4, 4)

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = container

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    local tabObj = {
        Button = tabBtn,
        Page = pageFrame,
        Container = container,
        Window = window
    }
    setmetatable(tabObj, Tab)
    table.insert(window.Tabs, tabObj)

    local function selectTab()
        for _, t in ipairs(window.Tabs) do
            t.Page.Visible = false
            animate(t.Button, {TextColor3 = Theme.SubText, BackgroundTransparency = 1, Size = UDim2.new(0, 80, 1, -8)})
        end
        pageFrame.Visible = true
        animate(tabBtn, {TextColor3 = Theme.Accent, BackgroundTransparency = 0.5, Size = UDim2.new(0, 90, 1, -8)})
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
    local window = self.Window

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 42)
    toggleFrame.BackgroundColor3 = Theme.Surface
    toggleFrame.ZIndex = 6
    toggleFrame.Parent = self.Container
    createCorner(toggleFrame, 6)
    createStroke(toggleFrame, Theme.Stroke)
    createPadding(toggleFrame, 0, 0, 4, 12)
    window:RegisterElement(toggleFrame)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.6, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 7
    textLabel.Parent = toggleFrame

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 40, 0, 20)
    switchTrack.Position = UDim2.new(1, -44, 0.5, -10)
    switchTrack.BackgroundColor3 = state and Theme.Accent or Theme.Background
    switchTrack.BackgroundTransparency = 0
    switchTrack.ZIndex = 7
    switchTrack.Parent = toggleFrame
    createCorner(switchTrack, 20)
    local trackStroke = createStroke(switchTrack, Theme.Stroke)

    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 14, 0, 14)
    switchKnob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    switchKnob.BackgroundColor3 = state and Theme.Background or Theme.SubText
    switchKnob.ZIndex = 8
    switchKnob.Parent = switchTrack
    createCorner(switchKnob, 14)

    local interactBtn = Instance.new("TextButton")
    interactBtn.Size = UDim2.new(1, 0, 1, 0)
    interactBtn.BackgroundTransparency = 1
    interactBtn.Text = ""
    interactBtn.ZIndex = 9
    interactBtn.Parent = toggleFrame

    interactBtn.MouseButton1Click:Connect(function()
        state = not state
        trackStroke.Color = state and Theme.Accent or Theme.Stroke
        animate(switchTrack, {
            BackgroundColor3 = state and Theme.Accent or Theme.Background,
            BackgroundTransparency = 0
        })
        animate(switchKnob, {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = state and Theme.Background or Theme.SubText
        })
        task.spawn(callback, state)
    end)
end

-- Component Method: CreateButton
function Tab:CreateButton(label, buttonText, defaultKey, callback)
    if type(defaultKey) == "function" then
        callback = defaultKey
        defaultKey = nil
    end
    callback = callback or function() end
    buttonText = buttonText or "Button"
    local currentKey = defaultKey
    local window = self.Window

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.new(1, 0, 0, 42)
    containerFrame.BackgroundColor3 = Theme.Surface
    containerFrame.ZIndex = 6
    containerFrame.Parent = self.Container
    createCorner(containerFrame, 6)
    createStroke(containerFrame, Theme.Stroke)
    createPadding(containerFrame, 0, 0, 4, 12)
    window:RegisterElement(containerFrame)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.4, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 7
    textLabel.Parent = containerFrame

    local actionBtnWidth = currentKey and 100 or 110
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(0, actionBtnWidth, 0, 24)
    actionBtn.Position = UDim2.new(1, -actionBtnWidth, 0.5, -12)
    actionBtn.BackgroundColor3 = Theme.SurfaceElevated
    actionBtn.Text = buttonText
    actionBtn.TextColor3 = Theme.Accent
    actionBtn.Font = Enum.Font.GothamMedium
    actionBtn.TextSize = 11
    actionBtn.ZIndex = 7
    actionBtn.Parent = containerFrame
    createCorner(actionBtn, 4)
    createStroke(actionBtn, Theme.Stroke)
    window:RegisterElement(actionBtn)

    actionBtn.MouseEnter:Connect(function() animate(actionBtn, {BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0}) end)
    actionBtn.MouseLeave:Connect(function() animate(actionBtn, {BackgroundColor3 = Theme.SurfaceElevated, BackgroundTransparency = window:GetElementTransparency()}) end)

    actionBtn.MouseButton1Click:Connect(function()
        task.spawn(callback, currentKey)
    end)

    if currentKey then
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(0, 40, 0, 24)
        keybindBtn.Position = UDim2.new(1, -(actionBtnWidth + 46), 0.5, -12)
        keybindBtn.BackgroundColor3 = Theme.Background
        keybindBtn.Text = currentKey.Name
        keybindBtn.TextColor3 = Theme.SubText
        keybindBtn.Font = Enum.Font.Gotham
        keybindBtn.TextSize = 11
        keybindBtn.ZIndex = 7
        keybindBtn.Parent = containerFrame
        createCorner(keybindBtn, 4)
        createStroke(keybindBtn, Theme.Stroke)
        window:RegisterElement(keybindBtn)

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

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                if not binding then
                    task.spawn(callback, currentKey)
                end
            end
        end)
    end
end

-- Component Method: CreateSlider
function Tab:CreateSlider(label, min, max, defaultVal, callback)
    callback = callback or function() end
    min = min or 0
    max = max or 100
    defaultVal = math.clamp(defaultVal or min, min, max)
    local window = self.Window

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 46)
    sliderFrame.BackgroundColor3 = Theme.Surface
    sliderFrame.ZIndex = 6
    sliderFrame.Parent = self.Container
    createCorner(sliderFrame, 6)
    createStroke(sliderFrame, Theme.Stroke)
    createPadding(sliderFrame, 0, 0, 4, 12)
    window:RegisterElement(sliderFrame)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.35, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 7
    textLabel.Parent = sliderFrame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 120, 0, 10)
    track.Position = UDim2.new(1, -155, 0.5, -5)
    track.BackgroundColor3 = Theme.Background
    track.ZIndex = 7
    track.Parent = sliderFrame
    createCorner(track, 10)
    createStroke(track, Theme.Stroke)
    window:RegisterElement(track)

    local initialPercent = (defaultVal - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BackgroundTransparency = 0
    fill.ZIndex = 8
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
    valueLabel.ZIndex = 7
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
