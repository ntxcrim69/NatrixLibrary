--[[
    Script: Natrix Pro - Unified & Professional UI & Frontend
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ============================================================
-- UI LIBRARY DEFINITION
-- ============================================================
local Library = {}
Library.__index = Library

local Tab = {}
Tab.__index = Tab

-- Configuration File Persistence System
local ConfigFileName = "NatrixPro_Config.json"
local Config = {
    FPSCounterEnabled = false,
    ToggleKey = "RightShift",
    ThemeName = "Black Hole",
    BackgroundImageId = "rbxassetid://134736124666311",
    BackgroundTransparency = 0
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

-- Design System Constants
local Theme = {
    Background = Color3.fromRGB(5, 5, 5),
    Surface = Color3.fromRGB(12, 12, 12),
    SurfaceElevated = Color3.fromRGB(18, 18, 18),
    Stroke = Color3.fromRGB(45, 45, 45),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(160, 160, 160),
    Danger = Color3.fromRGB(255, 55, 55)
}

-- UI Helper Functions
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 4)
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

-- External Image Fetcher with Fallback
local imageCache = {}
local function FetchExternalImage(url, fileName, fallbackAssetId)
    if imageCache[fileName] and imageCache[fileName] ~= "" then 
        return imageCache[fileName] 
    end
    
    local success, asset = pcall(function()
        if isfile and writefile and getcustomasset then
            if not isfile(fileName) then
                local imgData = game:HttpGet(url)
                if imgData and #imgData > 0 and not imgData:find("404") then
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

local function createStatusTag(parent, iconUrl, fileName, labelText, xOffset, width, fallbackAssetId)
    local baseZIndex = parent.ZIndex or 1

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, xOffset + 12, 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.Image = FetchExternalImage(iconUrl, fileName, fallbackAssetId)
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
        return isDarkTheme and 0 or 0.25
    end

    function windowObj:RegisterElement(element, customTransparency)
        table.insert(windowObj.Elements, {
            Instance = element,
            CustomTransparency = customTransparency
        })
        element.BackgroundTransparency = customTransparency or windowObj:GetElementTransparency()
    end

    local outerContainer = Instance.new("Frame")
    outerContainer.Name = "OuterContainer"
    outerContainer.Size = UDim2.new(0, 600, 0, 480)
    outerContainer.Position = UDim2.new(0.5, -300, 0.5, -240)
    outerContainer.BackgroundTransparency = 1
    outerContainer.ZIndex = 1
    outerContainer.Parent = screenGui

    local currentToggleKey = Enum.KeyCode[Config.ToggleKey] or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
    createCorner(topMiddleHud, 4)
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

    local mainApp = Instance.new("CanvasGroup")
    mainApp.Name = "MainApp"
    mainApp.Size = UDim2.new(1, 0, 1, 0)
    mainApp.BackgroundTransparency = 1
    mainApp.GroupTransparency = 0
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
    createCorner(topBar, 4)
    createStroke(topBar, Theme.Stroke)

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
    createCorner(closeBtn, 4)
    createStroke(closeBtn, Theme.Stroke)
    windowObj:RegisterElement(closeBtn)

    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, 0, 1, -110) 
    contentArea.Position = UDim2.new(0, 0, 0, 54) 
    contentArea.BackgroundColor3 = Theme.Background
    contentArea.BorderSizePixel = 0
    contentArea.ZIndex = 2
    contentArea.Parent = mainApp
    createCorner(contentArea, 4)
    createStroke(contentArea, Theme.Stroke)

    windowObj.PageHolder = contentArea

    -- FPS & Ping Loop
    local frames = 0
    local lastUpdate = os.clock()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastUpdate >= 1 then
            local currentFPS = tostring(frames)
            hudFps.Text = "FPS: " .. currentFPS
            frames = 0
            lastUpdate = now
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
    createCorner(tabBtn, 4)

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
    container.ScrollBarThickness = 0
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
    local window = self.Window

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 42)
    toggleFrame.BackgroundColor3 = Theme.Surface
    toggleFrame.ZIndex = 5
    toggleFrame.Parent = self.Container
    createCorner(toggleFrame, 4)
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
        animate(switchKnob, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = state and Theme.Background or Theme.SubText})
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
    local window = self.Window

    local containerFrame = Instance.new("Frame")
    containerFrame.Size = UDim2.new(1, 0, 0, 42)
    containerFrame.BackgroundColor3 = Theme.Surface
    containerFrame.ZIndex = 5
    containerFrame.Parent = self.Container
    createCorner(containerFrame, 4)
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
    textLabel.ZIndex = 6
    textLabel.Parent = containerFrame

    local actionBtn = Instance.new("TextButton")
    actionBtn.Size = UDim2.new(0, 110, 0, 24)
    actionBtn.Position = UDim2.new(1, -110, 0.5, -12)
    actionBtn.BackgroundColor3 = Theme.SurfaceElevated
    actionBtn.Text = buttonText
    actionBtn.TextColor3 = Theme.Accent
    actionBtn.Font = Enum.Font.GothamMedium
    actionBtn.TextSize = 11
    actionBtn.ZIndex = 6
    actionBtn.Parent = containerFrame
    createCorner(actionBtn, 4)
    createStroke(actionBtn, Theme.Stroke)
    window:RegisterElement(actionBtn)

    actionBtn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
end

function Tab:CreateSlider(label, min, max, defaultVal, callback)
    callback = callback or function() end
    min = min or 0
    max = max or 100
    defaultVal = math.clamp(defaultVal or min, min, max)
    local window = self.Window

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 46)
    sliderFrame.BackgroundColor3 = Theme.Surface
    sliderFrame.ZIndex = 5
    sliderFrame.Parent = self.Container
    createCorner(sliderFrame, 4)
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
    textLabel.ZIndex = 6
    textLabel.Parent = sliderFrame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 120, 0, 10)
    track.Position = UDim2.new(1, -155, 0.5, -5)
    track.BackgroundColor3 = Theme.Background
    track.ZIndex = 6
    track.Parent = sliderFrame
    createCorner(track, 10)
    createStroke(track, Theme.Stroke)
    window:RegisterElement(track)

    local initialPercent = (defaultVal - min) / (max - min)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.ZIndex = 7
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
    valueLabel.ZIndex = 6
    valueLabel.Parent = sliderFrame

    local dragging = false
    local function updateValue(input)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
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

function Tab:CreateDropdown(label, options, defaultOption, callback)
    callback = callback or function() end
    options = options or {}
    local selected = defaultOption or options[1] or ""
    local window = self.Window

    local dropFrame = Instance.new("Frame")
    dropFrame.Size = UDim2.new(1, 0, 0, 42)
    dropFrame.BackgroundColor3 = Theme.Surface
    dropFrame.ZIndex = 5
    dropFrame.Parent = self.Container
    createCorner(dropFrame, 4)
    createStroke(dropFrame, Theme.Stroke)
    createPadding(dropFrame, 0, 0, 4, 12)
    window:RegisterElement(dropFrame)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.45, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Theme.Text
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 6
    textLabel.Parent = dropFrame

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 150, 0, 26)
    pill.Position = UDim2.new(1, -150, 0.5, -13)
    pill.BackgroundColor3 = Theme.Background
    pill.Text = selected
    pill.TextColor3 = Theme.SubText
    pill.Font = Enum.Font.Gotham
    pill.TextSize = 11
    pill.ZIndex = 6
    pill.Parent = dropFrame
    createCorner(pill, 4)
    createStroke(pill, Theme.Stroke)
    window:RegisterElement(pill)

    pill.MouseButton1Click:Connect(function()
        -- Simple toggle rotation for options
        local currentIndex = table.find(options, selected) or 1
        currentIndex = currentIndex % #options + 1
        selected = options[currentIndex]
        pill.Text = selected
        task.spawn(callback, selected)
    end)

    return { SetSelected = function(_, v) selected = v pill.Text = v end, GetSelected = function() return selected end }
end

-- CRITICAL FIX: Ensure Library is returned correctly
return Library

-- ============================================================
-- FRONTEND IMPLEMENTATION
-- ============================================================
local Window = Library:CreateWindow({
    Name = "Natrix Pro",
    KeySystem = false
})

local VisualsTab   = Window:CreateTab("Visuals")
local TeleportsTab = Window:CreateTab("Teleports")
local AutoTab      = Window:CreateTab("Auto")
local CombatTab    = Window:CreateTab("Combat")

-- Core States & Variables
local SAFE_ZONE_AIR_POS   = Vector3.new(-1654, 285, -1012)
local SAFE_ZONE_WATER_POS = Vector3.new(-1654, 55, -1012)

local isUnderwaterMode  = false
local airPlatform       = nil
local waterPlatform     = nil
local autoReturnEnabled = false

local activeEspCategories = {}
local currentEspElements  = {}
local lastEspScan         = 0

local function createPlatform(position, color)
    local part = Instance.new("Part")
    part.Size         = Vector3.new(40, 1, 40)
    part.Position     = position - Vector3.new(0, 4, 0)
    part.Anchored     = true
    part.Transparency = 0.5
    part.Color        = color
    part.CanCollide   = true
    part.Parent       = workspace
    return part
end

local function teleportTo(position)
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then rootPart.CFrame = CFrame.new(position) end
end

-- UI Component Bindings
VisualsTab:CreateToggle("No Fog", false, function(enabled)
    if enabled then
        Lighting.FogStart = 0
        Lighting.FogEnd   = 9e9
    else
        Lighting.FogStart = 0
        Lighting.FogEnd   = 100000
    end
end)

TeleportsTab:CreateButton("Safe Zone", "Teleport", Enum.KeyCode.L, function()
    if airPlatform then airPlatform:Destroy() airPlatform = nil end
    isUnderwaterMode = false
    airPlatform = createPlatform(SAFE_ZONE_AIR_POS, Color3.fromRGB(0, 191, 255))
    teleportTo(SAFE_ZONE_AIR_POS)
end)

TeleportsTab:CreateButton("Safe Zone (Underwater)", "Teleport", Enum.KeyCode.U, function()
    if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
    isUnderwaterMode = true
    waterPlatform = createPlatform(SAFE_ZONE_WATER_POS, Color3.fromRGB(0, 255, 128))
    teleportTo(SAFE_ZONE_WATER_POS)
end)

AutoTab:CreateToggle("Auto Return to Safe Zone", false, function(state)
    autoReturnEnabled = state
end)

CombatTab:CreateDropdown("Hitbox Mode", {"OFF", "Rage Legit", "Rage"}, "OFF", function(selected)
    print("Hitbox mode set to: " .. selected)
end)
