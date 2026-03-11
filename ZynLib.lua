-- =====================
-- ZYN HUB LIBRARY v1.0
-- =====================

local Library = {}

-- Services
local Services = {
    Tween = game:GetService("TweenService"),
    Teleport = game:GetService("TeleportService"),
    Players = game:GetService("Players"),
    Input = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Stats = game:GetService("Stats"),
    Http = game:GetService("HttpService"),
    Sound = game:GetService("SoundService"),
    Debris = game:GetService("Debris")
}

local LocalPlayer = Services.Players.LocalPlayer

-- =====================
-- UTILITIES
-- =====================
local function makeTextGlow(textElement, color1, color2, duration, delay)
    color1   = color1   or Color3.fromRGB(140, 140, 255)
    color2   = color2   or Color3.fromRGB(100, 60, 200)
    duration = duration or 1.2
    delay    = delay    or 0
    task.spawn(function()
        if delay > 0 then task.wait(delay) end
        while textElement.Parent do
            Services.Tween:Create(textElement, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextColor3 = color2
            }):Play()
            task.wait(duration)
            Services.Tween:Create(textElement, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                TextColor3 = color1
            }):Play()
            task.wait(duration)
        end
    end)
end

local function addTextGradient(textElement, color1, color2, rotation)
    rotation = rotation or 45
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation
    gradient.Parent = textElement
    task.spawn(function()
        while textElement.Parent and gradient.Parent do
            for rot = rotation, rotation + 360, 2 do
                if not gradient.Parent then break end
                gradient.Rotation = rot
                task.wait(0.03)
            end
        end
    end)
    return gradient
end

-- =====================
-- CONFIG SYSTEM
-- =====================
local ConfigSystem = {}
ConfigSystem.ConfigFile = "ZynHub_Config.json"
ConfigSystem.DefaultConfig = {
    toggles = {},
    keybinds = {},
    notifSound = "None",
    guiScale = 15
}

function ConfigSystem:Load()
    if isfile and isfile(self.ConfigFile) then
        local ok, result = pcall(function()
            return Services.Http:JSONDecode(readfile(self.ConfigFile))
        end)
        if ok and result then return result end
    end
    return table.clone(self.DefaultConfig)
end

function ConfigSystem:Save(config)
    if not writefile then return false end
    pcall(function()
        writefile(self.ConfigFile, Services.Http:JSONEncode(config))
    end)
end

function ConfigSystem:UpdateSetting(config, key, value)
    config[key] = value
    self:Save(config)
end

ConfigSystem.CurrentConfig = ConfigSystem:Load()

-- Initialize default settings
if not ConfigSystem.CurrentConfig.toggles then
    ConfigSystem.CurrentConfig.toggles = {}
end
if not ConfigSystem.CurrentConfig.keybinds then
    ConfigSystem.CurrentConfig.keybinds = {}
end
if ConfigSystem.CurrentConfig.toggles["Enable Notification"] == nil then
    ConfigSystem.CurrentConfig.toggles["Enable Notification"] = true
end
if ConfigSystem.CurrentConfig.toggles["Show Menu on Start"] == nil then
    ConfigSystem.CurrentConfig.toggles["Show Menu on Start"] = false
end
if ConfigSystem.CurrentConfig.toggles["Auto Hide Quick Panel"] == nil then
    ConfigSystem.CurrentConfig.toggles["Auto Hide Quick Panel"] = false
end
if ConfigSystem.CurrentConfig.notifSound == nil then
    ConfigSystem.CurrentConfig.notifSound = "None"
end

ConfigSystem:Save(ConfigSystem.CurrentConfig)

-- =====================
-- SOUND SYSTEM
-- =====================
local SOUND_OPTIONS = {"None", "Professional", "Window", "Discord", "WhatsApp", "Mod Mate", "Cool"}
local SOUND_IDS = {
    ["None"]           = 0,
    ["Professional"]   = 112486094040833,
    ["Window"]         = 112540874905920,
    ["Discord"]        = 135272730546427,
    ["WhatsApp"]       = 97272458359894,
    ["Mod Mate"]       = 137402801272072,
    ["Cool"]           = 84046526988747,
    ["Warn"]           = 124951621656853,
    ["HighValueAlert"] = 123611924519936,
}

local notifEnabled = ConfigSystem.CurrentConfig.toggles["Enable Notification"] ~= false
local notifSound = ConfigSystem.CurrentConfig.notifSound or "None"

local function playNotifSound(overrideSound)
    local soundName = overrideSound or notifSound
    if soundName == "None" then return end
    local soundId = SOUND_IDS[soundName]
    if not soundId or soundId == 0 then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. tostring(soundId)
        s.Volume = 0.5
        s.Parent = Services.Sound
        s:Play()
        Services.Debris:AddItem(s, 5)
    end)
end

-- =====================
-- COLOR THEME
-- =====================
local Colors = {
    Background = Color3.fromRGB(10, 10, 12),
    TextActive = Color3.fromRGB(210, 210, 225),
    TextDim = Color3.fromRGB(80, 80, 90),
    AccentViolet = Color3.fromRGB(76, 76, 252),
    TitleGradient = {
        C1 = Color3.fromRGB(70, 70, 180),
        C2 = Color3.fromRGB(183, 50, 250)
    }
}

-- =====================
-- NOTIFICATION SYSTEM
-- =====================
local activeNotifications = {}
local NOTIF_HEIGHT = 56
local NOTIF_SPACING = 10
local MAX_NOTIFS = 3

local NotifColors = {
    Bar = {
        Default = Color3.fromRGB(180, 180, 200),
        Failed  = Color3.fromRGB(220, 40,  40),
        Success = Color3.fromRGB(40,  200, 100),
        White   = Color3.fromRGB(255, 255, 255),
        Blue    = Color3.fromRGB(60,  160, 255),
        Violet  = Color3.fromRGB(70,  70,  180),
    },
    Text = {
        Default = Color3.fromRGB(255, 255, 255),
        Failed  = Color3.fromRGB(255, 80,  80),
        Success = Color3.fromRGB(80,  220, 120),
        Violet  = Color3.fromRGB(70,  70,  180),
    },
}

local function updateNotificationPositions()
    for i, notifData in ipairs(activeNotifications) do
        local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
        Services.Tween:Create(notifData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, newYPos)
        }):Play()
    end
end

local function removeNotification(notifData)
    for i, data in ipairs(activeNotifications) do
        if data == notifData then table.remove(activeNotifications, i) break end
    end
    updateNotificationPositions()
end

local function showNotification(opts)
    if not notifEnabled then return end
    
    if type(opts) == "string" then
        opts = {message = opts}
    end
    
    playNotifSound(opts.SystemSound)
    
    opts = opts or {}
    local message  = opts.Message or opts.message or ""
    local subtext  = opts.Subtext or opts.subtext or nil
    local barColor = NotifColors.Bar[opts.BarColor or opts.barColor or "Default"] or NotifColors.Bar.Default
    local txtColor = NotifColors.Text[opts.TextColor or opts.textColor or "Default"] or NotifColors.Text.Default
    local subColor = NotifColors.Text[opts.SubtextColor or opts.subtextColor or "Default"] or NotifColors.Text.Default

    if #activeNotifications >= MAX_NOTIFS then
        local oldest = activeNotifications[1]
        if oldest.barTween then oldest.barTween:Cancel() end
        table.remove(activeNotifications, 1)
        updateNotificationPositions()
        Services.Tween:Create(oldest.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -260, 0, oldest.frame.Position.Y.Offset)
        }):Play()
        task.delay(0.3, function() oldest.frame:Destroy() end)
    end

    local notifGui = game:GetService("CoreGui"):FindFirstChild("ZynNotifGui")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "ZynNotifGui"
        notifGui.ResetOnSpawn = false
        notifGui.Parent = game:GetService("CoreGui")
    end

    local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
    local frameHeight = subtext and 57 or NOTIF_HEIGHT

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 250, 0, frameHeight)
    notif.Position = UDim2.new(0, -260, 0, startYPos)
    notif.BackgroundColor3 = Colors.Background
    notif.BorderSizePixel = 0
    notif.Parent = notifGui

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = UDim.new(0, 8)
    nCorner.Parent = notif

    local nStroke = Instance.new("UIStroke")
    nStroke.Thickness = 1
    nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    nStroke.Color = Color3.fromRGB(40, 40, 52)
    nStroke.Parent = notif

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(0, 4, 0, 4)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(100, 100, 115)
    closeButton.TextSize = 11
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = notif

    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(220, 220, 235) end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Color3.fromRGB(100, 100, 115) end)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -36, 0, subtext and 26 or frameHeight - 6)
    textLabel.Position = UDim2.new(0, 30, 0, subtext and 8 or 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = txtColor
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true
    textLabel.Parent = notif

    if subtext then
        local subLabel = Instance.new("TextLabel")
        subLabel.Size = UDim2.new(1, -36, 0, 18)
        subLabel.Position = UDim2.new(0, 30, 0, 28)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = subtext
        subLabel.TextColor3 = subColor
        subLabel.TextSize = 10
        subLabel.Font = Enum.Font.Gotham
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
        subLabel.TextYAlignment = Enum.TextYAlignment.Center
        subLabel.TextWrapped = true
        subLabel.Parent = notif
    end

    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, 0, 0, 3)
    barContainer.Position = UDim2.new(0, 0, 1, -3)
    barContainer.BackgroundTransparency = 1
    barContainer.ClipsDescendants = true
    barContainer.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = barColor
    progressBar.BorderSizePixel = 0
    progressBar.Parent = barContainer

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = progressBar

    local notifData = { frame = notif, progressBar = progressBar, barTween = nil }
    table.insert(activeNotifications, notifData)

    Services.Tween:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 10, 0, startYPos)
    }):Play()

    local barTween = Services.Tween:Create(progressBar, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    notifData.barTween = barTween
    barTween:Play()

    local function dismiss()
        if notifData.barTween then notifData.barTween:Cancel() end
        if notif.Parent then
            Services.Tween:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, -260, 0, notif.Position.Y.Offset)
            }):Play()
            task.delay(0.3, function() if notif.Parent then notif:Destroy() end end)
            removeNotification(notifData)
        end
    end

    closeButton.MouseButton1Click:Connect(dismiss)
    task.delay(2, dismiss)
end

-- =====================
-- GUI SCALE CONSTANTS
-- =====================
local GUI_SCALE_MIN = 1
local GUI_SCALE_MAX = 100
local GUI_SCALE_DEFAULT = 15
local MAIN_BASE_W, MAIN_BASE_H = 185, 290
local MENU_BASE_W, MENU_BASE_H = 450, 350
local MAIN_MINIMIZED_H = 38

local currentScale = ConfigSystem.CurrentConfig.guiScale or GUI_SCALE_DEFAULT

-- Default positions
local MAIN_DEFAULT_POS   = UDim2.new(0.75, -92,  0.5, -145)
local MENU_DEFAULT_POS   = UDim2.new(0,    85,   0,    115)
local CREDIT_DEFAULT_POS = UDim2.new(0.5, -140, 0.5, -315)

-- Dropdown base sizes
local DROPDOWN_BASE_W = 130
local DROPDOWN_BASE_ITEM_H = 26

-- =====================
-- SCREEN GUI SETUP
-- =====================
local gui = game.CoreGui:FindFirstChild("ZynHub")
if gui then gui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZynHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

-- =====================
-- STATE VARIABLES
-- =====================
local toggleTriggers = {}
local boundKeys = {}
local listeningPill = nil
local guiLocked = ConfigSystem.CurrentConfig.toggles["Lock Gui"] == true
local isMinimized = false
local activeDropdown = nil

-- Load saved keybinds
if ConfigSystem.CurrentConfig.keybinds then
    for actionName, keyName in pairs(ConfigSystem.CurrentConfig.keybinds) do
        local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
        if ok and kc then boundKeys[actionName] = kc end
    end
end

-- =====================
-- CREDIT FRAME (Title Bar)
-- =====================
local creditFrame = Instance.new("Frame")
creditFrame.Size = UDim2.new(0, 280, 0, 52)
creditFrame.Position = CREDIT_DEFAULT_POS
creditFrame.BackgroundColor3 = Colors.Background
creditFrame.BorderSizePixel = 0
creditFrame.Active = true
creditFrame.Draggable = true
creditFrame.Parent = screenGui

local creditCorner = Instance.new("UICorner")
creditCorner.CornerRadius = UDim.new(0, 8)
creditCorner.Parent = creditFrame

local creditStroke = Instance.new("UIStroke")
creditStroke.Thickness = 1
creditStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
creditStroke.Color = Color3.fromRGB(255, 255, 255)
creditStroke.Parent = creditFrame

local creditStrokeGrad = Instance.new("UIGradient")
creditStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
creditStrokeGrad.Parent = creditStroke
Services.Tween:Create(creditStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local resetScaleCredit = Instance.new("TextButton")
resetScaleCredit.Size = UDim2.new(0, 52, 0, 16)
resetScaleCredit.Position = UDim2.new(1, -57, 0, 5)
resetScaleCredit.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
resetScaleCredit.BorderSizePixel = 0
resetScaleCredit.Text = "Rst Scale"
resetScaleCredit.TextColor3 = Color3.fromRGB(150, 150, 165)
resetScaleCredit.TextSize = 8
resetScaleCredit.Font = Enum.Font.GothamBold
resetScaleCredit.ZIndex = 3
resetScaleCredit.Parent = creditFrame

local resetScaleCreditCorner = Instance.new("UICorner")
resetScaleCreditCorner.CornerRadius = UDim.new(0, 6)
resetScaleCreditCorner.Parent = resetScaleCredit

local resetScaleCreditStroke = Instance.new("UIStroke")
resetScaleCreditStroke.Thickness = 1
resetScaleCreditStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
resetScaleCreditStroke.Color = Color3.fromRGB(70, 70, 85)
resetScaleCreditStroke.Parent = resetScaleCredit

local creditLogo = Instance.new("ImageLabel")
creditLogo.Size = UDim2.new(0, 36, 0, 36)
creditLogo.Position = UDim2.new(0, 8, 0.5, -18)
creditLogo.BackgroundTransparency = 1
creditLogo.Image = "rbxassetid://98023595162924"
creditLogo.ImageColor3 = Color3.fromRGB(210, 210, 220)
creditLogo.Parent = creditFrame

local creditTitle = Instance.new("TextLabel")
creditTitle.Size = UDim2.new(1, -58, 0, 26)
creditTitle.Position = UDim2.new(0, 52, 0, 8)
creditTitle.BackgroundTransparency = 1
creditTitle.Text = "ZYN HUB | .GG/ZYNHUB"
creditTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
creditTitle.TextSize = 15
creditTitle.Font = Enum.Font.GothamBold
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.Parent = creditFrame

local creditSub = Instance.new("TextLabel")
creditSub.Size = UDim2.new(1, -58, 0, 16)
creditSub.Position = UDim2.new(0, 52, 0, 30)
creditSub.BackgroundTransparency = 1
creditSub.Text = "Made By: Michal, Shadow"
creditSub.TextColor3 = Color3.fromRGB(80, 80, 90)
creditSub.TextSize = 9
creditSub.Font = Enum.Font.Gotham
creditSub.TextXAlignment = Enum.TextXAlignment.Left
creditSub.Parent = creditFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 16)
fpsLabel.Position = UDim2.new(1, -105, 1, -20)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Fps: 0, Ping: 0"
fpsLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
fpsLabel.TextSize = 9
fpsLabel.Font = Enum.Font.Gotham
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = creditFrame

-- FPS/Ping counter
local frames = 0
local last = tick()
Services.RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        local fps = frames
        frames = 0
        last = now
        local ok, rawPing = pcall(function()
            return Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        local ping = ok and math.floor(rawPing + 0.5) or 0
        fpsLabel.Text = "Fps: " .. fps .. ", Ping: " .. ping
    end
end)

-- =====================
-- MAIN FRAME (Quick Panel)
-- =====================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, MAIN_BASE_W, 0, MAIN_BASE_H)
mainFrame.Position = MAIN_DEFAULT_POS
mainFrame.BackgroundColor3 = Colors.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 9)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Parent = mainFrame

local mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
mainStrokeGrad.Parent = mainStroke
Services.Tween:Create(mainStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

local mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1, -20, 0, 32)
mainTitle.Position = UDim2.new(0, 10, 0, 5)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = "Quick Panel"
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.TextSize = 14
mainTitle.Font = Enum.Font.GothamBold
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 24, 0, 20)
minimizeBtn.Position = UDim2.new(1, -30, 0, 9)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = Color3.fromRGB(130, 130, 145)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.Gotham
minimizeBtn.ZIndex = 3
minimizeBtn.Parent = mainFrame

minimizeBtn.MouseEnter:Connect(function() minimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 235) end)
minimizeBtn.MouseLeave:Connect(function() minimizeBtn.TextColor3 = Color3.fromRGB(130, 130, 145) end)

local mainDivider = Instance.new("Frame")
mainDivider.Size = UDim2.new(1, -20, 0, 1)
mainDivider.Position = UDim2.new(0, 10, 0, 37)
mainDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
mainDivider.BorderSizePixel = 0
mainDivider.Parent = mainFrame

local mainSubtitle = Instance.new("TextLabel")
mainSubtitle.Size = UDim2.new(1, -20, 0, 18)
mainSubtitle.Position = UDim2.new(0, 10, 0, 43)
mainSubtitle.BackgroundTransparency = 1
mainSubtitle.Text = "Actions"
mainSubtitle.TextColor3 = Color3.fromRGB(80, 80, 90)
mainSubtitle.TextSize = 10
mainSubtitle.Font = Enum.Font.GothamBold
mainSubtitle.TextXAlignment = Enum.TextXAlignment.Left
mainSubtitle.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -65)
scrollFrame.Position = UDim2.new(0, 0, 0, 65)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 0
scrollFrame.ScrollBarImageTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 10)
scrollPadding.PaddingRight = UDim.new(0, 10)
scrollPadding.PaddingTop = UDim.new(0, 4)
scrollPadding.PaddingBottom = UDim.new(0, 8)
scrollPadding.Parent = scrollFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 6)
scrollLayout.Parent = scrollFrame

-- =====================
-- MENU FRAME (Main Hub)
-- =====================
local SIDEBAR_W = 110

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, MENU_BASE_W, 0, MENU_BASE_H)
menuFrame.Position = MENU_DEFAULT_POS
menuFrame.BackgroundColor3 = Colors.Background
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Active = true
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 9)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Thickness = 1
menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuStroke.Color = Color3.fromRGB(255, 255, 255)
menuStroke.Parent = menuFrame

local menuStrokeGrad = Instance.new("UIGradient")
menuStrokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 80, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 80, 90))
}
menuStrokeGrad.Parent = menuStroke
Services.Tween:Create(menuStrokeGrad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

-- Header
local menuTitle = Instance.new("TextLabel")
menuTitle.Size = UDim2.new(1, -40, 0, 30)
menuTitle.Position = UDim2.new(0, 14, 0, 4)
menuTitle.BackgroundTransparency = 1
menuTitle.Text = "Zyn Hub"
menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
menuTitle.TextSize = 14
menuTitle.Font = Enum.Font.GothamBold
menuTitle.TextXAlignment = Enum.TextXAlignment.Left
menuTitle.Parent = menuFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 2)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(100, 100, 115)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.Gotham
closeBtn.ZIndex = 3
closeBtn.Parent = menuFrame

closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(220, 220, 235) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(100, 100, 115) end)

local menuDivider = Instance.new("Frame")
menuDivider.Size = UDim2.new(1, -20, 0, 1)
menuDivider.Position = UDim2.new(0, 10, 0, 34)
menuDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
menuDivider.BorderSizePixel = 0
menuDivider.Parent = menuFrame

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -50)
sidebar.Position = UDim2.new(0, 0, 0, 44)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.Parent = menuFrame

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 8)
sidebarLayout.Parent = sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingLeft   = UDim.new(0, 8)
sidebarPadding.PaddingRight  = UDim.new(0, 8)
sidebarPadding.PaddingTop    = UDim.new(0, 4)
sidebarPadding.PaddingBottom = UDim.new(0, 4)
sidebarPadding.Parent = sidebar

-- Vertical divider
local sidebarDivider = Instance.new("Frame")
sidebarDivider.Size = UDim2.new(0, 1, 1, -44)
sidebarDivider.Position = UDim2.new(0, SIDEBAR_W, 0, 44)
sidebarDivider.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = menuFrame

-- Content area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -50)
contentArea.Position = UDim2.new(0, SIDEBAR_W + 1, 0, 44)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = menuFrame

-- Custom drag for menuFrame
do
    local dragging, dragStart, startPos = false, nil, nil
    menuFrame.InputBegan:Connect(function(input)
        if guiLocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = menuFrame.Position
        end
    end)
    local function stopDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end
    menuFrame.InputEnded:Connect(stopDrag)
    Services.Input.InputEnded:Connect(stopDrag)
    Services.Input.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            menuFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =====================
-- TABS SETUP
-- =====================
local tabNames = {"Features", "Misc", "Keybind", "Server", "Settings", "Credits"}
local tabBtns = {}
local tabContents = {}

local TAB_ICONS = {
    Features = "135805130474024",
    Misc     = "125410749395920",
    Keybind  = "104212259155690",
    Server   = "95694928894687",
    Settings = "124992078994960",
    Credits  = "124139034664556",
}

local function setActiveTab(name)
    for _, t in pairs(tabBtns) do
        if t.name == name then
            Services.Tween:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 42)}):Play()
            Services.Tween:Create(t.stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 70, 180)}):Play()
            t.label.TextColor3 = Color3.fromRGB(210, 210, 225)
            t.icon.ImageColor3 = Color3.fromRGB(180, 140, 255)
            t.accent.Visible = true
        else
            Services.Tween:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            Services.Tween:Create(t.stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(25, 25, 32)}):Play()
            t.label.TextColor3 = Color3.fromRGB(90, 90, 105)
            t.icon.ImageColor3 = Color3.fromRGB(70, 70, 85)
            t.accent.Visible = false
        end
    end
    for n, f in pairs(tabContents) do
        f.Visible = (n == name)
    end
end

for i, name in ipairs(tabNames) do
    local tabBtn = Instance.new("Frame")
    tabBtn.Size = UDim2.new(1, 0, 0, 26)
    tabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tabBtn.BorderSizePixel = 0
    tabBtn.LayoutOrder = i
    tabBtn.Parent = sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 7)
    btnCorner.Parent = tabBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Color = Color3.fromRGB(25, 25, 32)
    btnStroke.Parent = tabBtn

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 18)
    accent.Position = UDim2.new(0, 0, 0.5, -9)
    accent.BackgroundColor3 = Color3.fromRGB(120, 70, 220)
    accent.BorderSizePixel = 0
    accent.Visible = false
    accent.ZIndex = 3
    accent.Parent = tabBtn

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accent

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, 10, 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. (TAB_ICONS[name] or "0")
    icon.ImageColor3 = Color3.fromRGB(70, 70, 85)
    icon.ZIndex = 3
    icon.Parent = tabBtn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -34, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(90, 90, 105)
    label.TextSize = 9
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = tabBtn

    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 4
    clickDetector.Parent = tabBtn

    tabBtns[i] = {name = name, btn = tabBtn, stroke = btnStroke, label = label, icon = icon, accent = accent}

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.Position = UDim2.new(0, 0, 0, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 0
    contentScroll.ScrollBarImageTransparency = 1
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.Visible = false
    contentScroll.ZIndex = 3
    contentScroll.Parent = contentArea

    local cPadding = Instance.new("UIPadding")
    cPadding.PaddingLeft   = UDim.new(0, 10)
    cPadding.PaddingRight  = UDim.new(0, 10)
    cPadding.PaddingTop    = UDim.new(0, 8)
    cPadding.PaddingBottom = UDim.new(0, 8)
    cPadding.Parent = contentScroll

    local cLayout = Instance.new("UIListLayout")
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Padding = UDim.new(0, 8)
    cLayout.Parent = contentScroll

    tabContents[name] = contentScroll
    clickDetector.MouseButton1Click:Connect(function() setActiveTab(name) end)
end

-- =====================
-- DROPDOWN SYSTEM
-- =====================
local function closeActiveDropdown()
    if activeDropdown then
        activeDropdown:Destroy()
        activeDropdown = nil
    end
end

Services.Input.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if activeDropdown then
            task.defer(function()
                closeActiveDropdown()
            end)
        end
    end
end)

local function makeDropdownRow(labelText, options, savedValue, parent, order, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Color = Color3.fromRGB(30, 30, 38)
    rowStroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0, 80, 0, 22)
    dropBtn.Position = UDim2.new(1, -86, 0.5, -11)
    dropBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    dropBtn.BorderSizePixel = 0
    dropBtn.Text = savedValue
    dropBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    dropBtn.TextSize = 10
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.ZIndex = 4
    dropBtn.Parent = row

    local dropBtnCorner = Instance.new("UICorner")
    dropBtnCorner.CornerRadius = UDim.new(0, 6)
    dropBtnCorner.Parent = dropBtn

    local dropBtnStroke = Instance.new("UIStroke")
    dropBtnStroke.Thickness = 1
    dropBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dropBtnStroke.Color = Color3.fromRGB(50, 50, 65)
    dropBtnStroke.Parent = dropBtn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 14, 1, 0)
    arrow.Position = UDim2.new(1, -16, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = Color3.fromRGB(120, 120, 140)
    arrow.TextSize = 10
    arrow.Font = Enum.Font.Gotham
    arrow.ZIndex = 5
    arrow.Parent = dropBtn

    dropBtn.MouseEnter:Connect(function()
        Services.Tween:Create(dropBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 28, 38)}):Play()
        Services.Tween:Create(dropBtnStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(120, 120, 150)}):Play()
    end)
    dropBtn.MouseLeave:Connect(function()
        Services.Tween:Create(dropBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
        Services.Tween:Create(dropBtnStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(50, 50, 65)}):Play()
    end)

    dropBtn.MouseButton1Click:Connect(function()
        if activeDropdown then
            closeActiveDropdown()
            return
        end

        local ratio = math.max(1, currentScale / GUI_SCALE_DEFAULT)
        local ddW   = math.floor(DROPDOWN_BASE_W * ratio)
        local itemH = math.floor(DROPDOWN_BASE_ITEM_H * ratio)
        local maxVisible = math.min(#options, 4)
        local ddH = itemH * maxVisible + 8

        local absPos = dropBtn.AbsolutePosition
        local absSize = dropBtn.AbsoluteSize

        local popup = Instance.new("Frame")
        popup.Size = UDim2.new(0, ddW, 0, ddH)
        popup.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
        popup.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        popup.BorderSizePixel = 0
        popup.ZIndex = 200
        popup.Parent = screenGui

        local popupCorner = Instance.new("UICorner")
        popupCorner.CornerRadius = UDim.new(0, 7)
        popupCorner.Parent = popup

        local popupStroke = Instance.new("UIStroke")
        popupStroke.Thickness = 1
        popupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        popupStroke.Color = Color3.fromRGB(55, 55, 70)
        popupStroke.Parent = popup

        local popupScroll = Instance.new("ScrollingFrame")
        popupScroll.Size = UDim2.new(1, -8, 1, -8)
        popupScroll.Position = UDim2.new(0, 4, 0, 4)
        popupScroll.BackgroundTransparency = 1
        popupScroll.BorderSizePixel = 0
        popupScroll.ScrollBarThickness = 0
        popupScroll.ScrollBarImageTransparency = 1
        popupScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        popupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        popupScroll.ZIndex = 201
        popupScroll.Parent = popup

        local popupLayout = Instance.new("UIListLayout")
        popupLayout.SortOrder = Enum.SortOrder.LayoutOrder
        popupLayout.Padding = UDim.new(0, 2)
        popupLayout.Parent = popupScroll

        for idx, opt in ipairs(options) do
            local isSelected = (opt == dropBtn.Text)

            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, itemH - 2)
            item.BackgroundColor3 = isSelected and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(20, 20, 26)
            item.BorderSizePixel = 0
            item.Text = opt
            item.TextColor3 = isSelected and Color3.fromRGB(180, 180, 255) or Color3.fromRGB(160, 160, 175)
            item.TextSize = 10
            item.Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham
            item.LayoutOrder = idx
            item.ZIndex = 202
            item.Parent = popupScroll

            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 5)
            itemCorner.Parent = item

            item.MouseEnter:Connect(function()
                if not isSelected then
                    Services.Tween:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
                    item.TextColor3 = Color3.fromRGB(210, 210, 225)
                end
            end)
            item.MouseLeave:Connect(function()
                if not isSelected then
                    Services.Tween:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20, 20, 26)}):Play()
                    item.TextColor3 = Color3.fromRGB(160, 160, 175)
                end
            end)

            item.MouseButton1Click:Connect(function()
                dropBtn.Text = opt
                notifSound = opt
                ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "notifSound", opt)
                if onChange then onChange(opt) end
                closeActiveDropdown()
            end)
        end

        activeDropdown = popup
        popup.BackgroundTransparency = 1
        Services.Tween:Create(popup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        }):Play()
    end)

    return dropBtn
end

PART 3 - Tab Contents, Components & Library Export
-- =====================
-- GUI SCALE FUNCTION
-- =====================
local sliderFill, sliderThumb -- Forward declare untuk scale slider

local function applyGuiScale(scale, silent)
    currentScale = math.clamp(scale, GUI_SCALE_MIN, GUI_SCALE_MAX)
    local ratio = currentScale / GUI_SCALE_DEFAULT
    local newMainW = math.floor(MAIN_BASE_W * ratio)
    local newMainH = math.floor(MAIN_BASE_H * ratio)
    local newMenuW = math.floor(MENU_BASE_W * ratio)
    local newMenuH = math.floor(MENU_BASE_H * ratio)

    local mainCX = mainFrame.AbsolutePosition.X + mainFrame.AbsoluteSize.X / 2
    local mainCY = mainFrame.AbsolutePosition.Y + mainFrame.AbsoluteSize.Y / 2
    local menuCX = menuFrame.AbsolutePosition.X + menuFrame.AbsoluteSize.X / 2
    local menuCY = menuFrame.AbsolutePosition.Y + menuFrame.AbsoluteSize.Y / 2

    if not ConfigSystem.CurrentConfig.toggles["Disable Main Scale"] then
        Services.Tween:Create(mainFrame, TweenInfo.new(0.05), {
            Size     = UDim2.new(0, newMainW, 0, isMinimized and MAIN_MINIMIZED_H or newMainH),
            Position = UDim2.new(0, mainCX - newMainW / 2, 0, mainCY - (isMinimized and MAIN_MINIMIZED_H or newMainH) / 2)
        }):Play()
    end
    
    if not ConfigSystem.CurrentConfig.toggles["Disable Menu Scale"] then
        Services.Tween:Create(menuFrame, TweenInfo.new(0.05), {
            Size     = UDim2.new(0, newMenuW, 0, newMenuH),
            Position = UDim2.new(0, menuCX - newMenuW / 2, 0, menuCY - newMenuH / 2)
        }):Play()
    end

    if not silent then
        ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "guiScale", currentScale)
    end
end

-- =====================
-- SHARED FACTORIES
-- =====================
local function makeSectionLabel(text, parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = parent
end

local function makeIosToggle(labelText, parent, order, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Color = Color3.fromRGB(30, 30, 38)
    rowStroke.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 34, 0, 18)
    track.Position = UDim2.new(1, -44, 0.5, -9)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 12, 0, 12)
    circle.Position = UDim2.new(0, 3, 0.5, -6)
    circle.BackgroundColor3 = Color3.fromRGB(130, 130, 145)
    circle.BorderSizePixel = 0
    circle.Parent = track

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = row

    local isOn = false
    local function applyState(state, silent)
        isOn = state
        if isOn then
            Services.Tween:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Colors.AccentViolet}):Play()
            Services.Tween:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 19, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            lbl.TextColor3 = Color3.fromRGB(210, 210, 225)
        else
            Services.Tween:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
            Services.Tween:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = Color3.fromRGB(130, 130, 145)}):Play()
            lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        end
        if not silent and labelText ~= "Hop Server" then
            ConfigSystem.CurrentConfig.toggles[labelText] = isOn
            ConfigSystem:Save(ConfigSystem.CurrentConfig)
        end
        if onToggle and not silent then onToggle(isOn) end
    end

    local savedState = ConfigSystem.CurrentConfig.toggles[labelText]
    if savedState ~= nil then
        applyState(savedState, true)
        if onToggle then onToggle(isOn) end
    end

    btn.MouseButton1Click:Connect(function() applyState(not isOn, false) end)
    return { applyState = applyState, Get = function() return isOn end }
end

local function makeCardBtn(labelText, iconId, parent, order, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 34)
    card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    card.BackgroundTransparency = 0.17
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = card

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(50, 50, 62)
    cs.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(1, -28, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. tostring(iconId)
    icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    icon.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = card

    btn.MouseEnter:Connect(function()
        Services.Tween:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 120, 140)}):Play()
        lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
        icon.ImageColor3 = Color3.fromRGB(220, 220, 235)
    end)
    btn.MouseLeave:Connect(function()
        Services.Tween:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 62)}):Play()
        lbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    end)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
end

-- =====================
-- KEYBIND SYSTEM
-- =====================
local function keyName(kc)
    local names = {
        LeftBracket = "[", RightBracket = "]",
        Semicolon = ";", Quote = "'",
        Comma = ",", Period = ".", Slash = "/",
        BackSlash = "\\", Minus = "-", Equals = "=",
        BackQuote = "`"
    }
    return names[kc.Name] or kc.Name
end

Services.Input.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if listeningPill then
        local data = listeningPill
        listeningPill = nil
        if input.KeyCode == Enum.KeyCode.Escape then
            boundKeys[data.actionName] = nil
            data.pill.Text = "None"
            data.pill.TextColor3 = Color3.fromRGB(90, 90, 105)
        else
            boundKeys[data.actionName] = input.KeyCode
            data.pill.Text = keyName(input.KeyCode)
            data.pill.TextColor3 = Color3.fromRGB(200, 200, 215)
        end
        local keybindsToSave = {}
        for action, kc in pairs(boundKeys) do keybindsToSave[action] = kc.Name end
        ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "keybinds", keybindsToSave)
        Services.Tween:Create(data.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
        Services.Tween:Create(data.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
        Services.Tween:Create(data.rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
        return
    end
    for actionName, kc in pairs(boundKeys) do
        if kc and input.KeyCode == kc then
            if toggleTriggers[actionName] then toggleTriggers[actionName]() end
        end
    end
end)

local kbPills = {}
local function makeKeybindRow(actionName, parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    row.BackgroundTransparency = 0.17
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rowStroke.Color = Color3.fromRGB(40, 40, 52)
    rowStroke.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -80, 1, 0)
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = actionName
    nameLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local keyPill = Instance.new("TextButton")
    keyPill.Size = UDim2.new(0, 60, 0, 22)
    keyPill.Position = UDim2.new(1, -66, 0.5, -11)
    keyPill.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    keyPill.BorderSizePixel = 0
    keyPill.Text = boundKeys[actionName] and keyName(boundKeys[actionName]) or "None"
    keyPill.TextColor3 = boundKeys[actionName] and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(90, 90, 105)
    keyPill.TextSize = 9
    keyPill.Font = Enum.Font.GothamBold
    keyPill.ZIndex = 4
    keyPill.Parent = row

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 6)
    pillCorner.Parent = keyPill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Thickness = 1
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Color = Color3.fromRGB(45, 45, 58)
    pillStroke.Parent = keyPill

    table.insert(kbPills, { pill = keyPill, pillStroke = pillStroke })

    keyPill.MouseButton1Click:Connect(function()
        if listeningPill and listeningPill.pill == keyPill then
            listeningPill = nil
            keyPill.Text = boundKeys[actionName] and keyName(boundKeys[actionName]) or "None"
            keyPill.TextColor3 = boundKeys[actionName] and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(90, 90, 105)
            Services.Tween:Create(keyPill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
            Services.Tween:Create(pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
            Services.Tween:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
            return
        end
        if listeningPill then
            local prev = listeningPill
            listeningPill = nil
            prev.pill.Text = boundKeys[prev.actionName] and keyName(boundKeys[prev.actionName]) or "None"
            prev.pill.TextColor3 = boundKeys[prev.actionName] and Color3.fromRGB(200, 200, 215) or Color3.fromRGB(90, 90, 105)
            Services.Tween:Create(prev.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
            Services.Tween:Create(prev.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
            Services.Tween:Create(prev.rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(40, 40, 52)}):Play()
        end
        listeningPill = { pill = keyPill, pillStroke = pillStroke, rowStroke = rowStroke, actionName = actionName }
        keyPill.Text = "..."
        keyPill.TextColor3 = Color3.fromRGB(210, 210, 225)
        Services.Tween:Create(keyPill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
        Services.Tween:Create(pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(150, 150, 170)}):Play()
        Services.Tween:Create(rowStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(120, 120, 140)}):Play()
    end)
end

-- =====================
-- KEYBIND TAB
-- =====================
local kbScroll = tabContents["Keybind"]

local kbHeaderRow = Instance.new("Frame")
kbHeaderRow.Size = UDim2.new(1, 0, 0, 18)
kbHeaderRow.BackgroundTransparency = 1
kbHeaderRow.LayoutOrder = 1
kbHeaderRow.Parent = kbScroll

local kbSectionLbl = Instance.new("TextLabel")
kbSectionLbl.Size = UDim2.new(1, -60, 1, 0)
kbSectionLbl.BackgroundTransparency = 1
kbSectionLbl.Text = "Quick Panel"
kbSectionLbl.TextColor3 = Color3.fromRGB(210, 210, 220)
kbSectionLbl.TextSize = 10
kbSectionLbl.Font = Enum.Font.GothamBold
kbSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
kbSectionLbl.Parent = kbHeaderRow

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 44, 0, 16)
resetBtn.Position = UDim2.new(1, -44, 0.5, -8)
resetBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
resetBtn.BorderSizePixel = 0
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.fromRGB(150, 150, 165)
resetBtn.TextSize = 9
resetBtn.Font = Enum.Font.GothamBold
resetBtn.ZIndex = 4
resetBtn.Parent = kbHeaderRow

local resetKbCorner = Instance.new("UICorner")
resetKbCorner.CornerRadius = UDim.new(0, 6)
resetKbCorner.Parent = resetBtn

local resetKbStroke = Instance.new("UIStroke")
resetKbStroke.Thickness = 1
resetKbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
resetKbStroke.Color = Color3.fromRGB(50, 50, 62)
resetKbStroke.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function()
    boundKeys = {}
    ConfigSystem:UpdateSetting(ConfigSystem.CurrentConfig, "keybinds", {})
    for _, pillData in ipairs(kbPills) do
        pillData.pill.Text = "None"
        pillData.pill.TextColor3 = Color3.fromRGB(90, 90, 105)
        Services.Tween:Create(pillData.pill, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
        Services.Tween:Create(pillData.pillStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(45, 45, 58)}):Play()
    end
    showNotification({ message = "Keybinds Reset", barColor = "Default", textColor = "Default" })
end)

-- =====================
-- SERVER TAB
-- =====================
local srvScroll = tabContents["Server"]
makeSectionLabel("Server", srvScroll, 0)

local hopActive = false
makeIosToggle("Hop Server", srvScroll, 1, function(state)
    hopActive = state
    if state then
        task.spawn(function()
            while hopActive do
                local placeId = game.PlaceId
                local ok, result = pcall(function()
                    return Services.Http:JSONDecode(
                        game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
                    )
                end)
                if ok and result and result.data then
                    local found = false
                    for _, server in ipairs(result.data) do
                        if server.id ~= game.JobId and server.playing < server.maxPlayers then
                            pcall(function() Services.Teleport:TeleportToPlaceInstance(placeId, server.id, LocalPlayer) end)
                            found = true
                            break
                        end
                    end
                    if not found then task.wait(3) end
                else
                    task.wait(3)
                end
            end
        end)
    end
end)

makeCardBtn("Rejoin", "97462463002118", srvScroll, 2, function()
    pcall(function() Services.Teleport:Teleport(game.PlaceId, LocalPlayer) end)
end)

makeCardBtn("Copy Job ID", "97462463002118", srvScroll, 3, function()
    pcall(function() setclipboard(game.JobId) end)
    showNotification({ message = "Job ID Copied!", barColor = "Default", textColor = "Default" })
end)

local inputCard = Instance.new("Frame")
inputCard.Size = UDim2.new(1, 0, 0, 34)
inputCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inputCard.BackgroundTransparency = 0.17
inputCard.BorderSizePixel = 0
inputCard.LayoutOrder = 4
inputCard.Parent = srvScroll

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputCard

local inputStroke = Instance.new("UIStroke")
inputStroke.Thickness = 1
inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputStroke.Color = Color3.fromRGB(50, 50, 62)
inputStroke.Parent = inputCard

local jobInput = Instance.new("TextBox")
jobInput.Size = UDim2.new(1, -16, 1, -8)
jobInput.Position = UDim2.new(0, 8, 0, 4)
jobInput.BackgroundTransparency = 1
jobInput.Text = ""
jobInput.PlaceholderText = "Input Job ID"
jobInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 85)
jobInput.TextColor3 = Color3.fromRGB(180, 180, 195)
jobInput.TextSize = 10
jobInput.Font = Enum.Font.Gotham
jobInput.TextXAlignment = Enum.TextXAlignment.Left
jobInput.ClearTextOnFocus = false
jobInput.ZIndex = 4
jobInput.Parent = inputCard

jobInput.Focused:Connect(function()
    Services.Tween:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(150, 150, 170)}):Play()
end)
jobInput.FocusLost:Connect(function()
    Services.Tween:Create(inputStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 62)}):Play()
end)

makeCardBtn("Join Server", "97462463002118", srvScroll, 5, function()
    local jobId = jobInput.Text
    if jobId ~= "" then
        local ok = pcall(function()
            Services.Teleport:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)
        if not ok then
            jobInput.Text = ""
            jobInput.PlaceholderText = "Invalid Job ID"
        end
    end
end)

-- =====================
-- SETTINGS TAB
-- =====================
local settScroll = tabContents["Settings"]
makeSectionLabel("Settings", settScroll, 1)

makeIosToggle("Lock Gui", settScroll, 2, function(state)
    guiLocked = state
    mainFrame.Draggable   = not state
    creditFrame.Draggable = not state
end)

makeIosToggle("Enable Notification", settScroll, 3, function(state)
    notifEnabled = state
end)

makeIosToggle("Show Menu on Start", settScroll, 4, function(state) end)
makeIosToggle("Auto Hide Quick Panel", settScroll, 5, function(state) end)
makeIosToggle("Disable Server Full Error", settScroll, 6, function(state)
    if state then
        task.spawn(function()
            for i = 1, 30 do
                pcall(function()
                    local pg = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
                    if pg then pg:Destroy() end
                end)
                task.wait(0.01)
            end
        end)
    end
end)

makeIosToggle("Disable Main Scale", settScroll, 7, function(state) end)
makeIosToggle("Disable Menu Scale", settScroll, 8, function(state) end)
makeIosToggle("Gui Transparency", settScroll, 9, function(state)
    mainFrame.BackgroundTransparency   = state and 0.12 or 0
    menuFrame.BackgroundTransparency   = state and 0.12 or 0
    creditFrame.BackgroundTransparency = state and 0.12 or 0
end)

makeDropdownRow("Notif Sound", SOUND_OPTIONS, notifSound, settScroll, 10, function(val)
    notifSound = val
end)

makeCardBtn("Reset Gui Position", "97462463002118", settScroll, 11, function()
    mainFrame.Position   = MAIN_DEFAULT_POS
    menuFrame.Position   = MENU_DEFAULT_POS
    creditFrame.Position = CREDIT_DEFAULT_POS
    showNotification({ message = "Gui Position Reset", barColor = "Default", textColor = "Default" })
end)

-- Gui Scale slider
local scaleRow = Instance.new("Frame")
scaleRow.Size = UDim2.new(1, 0, 0, 28)
scaleRow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scaleRow.BackgroundTransparency = 0.17
scaleRow.BorderSizePixel = 0
scaleRow.LayoutOrder = 12
scaleRow.Parent = settScroll

local scaleRowCorner = Instance.new("UICorner")
scaleRowCorner.CornerRadius = UDim.new(0, 6)
scaleRowCorner.Parent = scaleRow

local scaleRowStroke = Instance.new("UIStroke")
scaleRowStroke.Thickness = 1
scaleRowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
scaleRowStroke.Color = Color3.fromRGB(40, 40, 52)
scaleRowStroke.Parent = scaleRow

local scaleLbl = Instance.new("TextLabel")
scaleLbl.Size = UDim2.new(0, 55, 1, 0)
scaleLbl.Position = UDim2.new(0, 8, 0, 0)
scaleLbl.BackgroundTransparency = 1
scaleLbl.Text = "Gui Scale"
scaleLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
scaleLbl.TextSize = 10
scaleLbl.Font = Enum.Font.Gotham
scaleLbl.TextXAlignment = Enum.TextXAlignment.Left
scaleLbl.Parent = scaleRow

local initPct = math.floor(((currentScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)) * 100 + 0.5)

local scaleValLbl = Instance.new("TextLabel")
scaleValLbl.Size = UDim2.new(0, 30, 1, 0)
scaleValLbl.Position = UDim2.new(1, -34, 0, 0)
scaleValLbl.BackgroundTransparency = 1
scaleValLbl.Text = initPct .. "%"
scaleValLbl.TextColor3 = Color3.fromRGB(140, 140, 255)
scaleValLbl.TextSize = 10
scaleValLbl.Font = Enum.Font.GothamBold
scaleValLbl.TextXAlignment = Enum.TextXAlignment.Right
scaleValLbl.Parent = scaleRow

local scaleValBox = Instance.new("TextBox")
scaleValBox.Size = UDim2.new(0, 30, 1, 0)
scaleValBox.Position = UDim2.new(1, -34, 0, 0)
scaleValBox.BackgroundTransparency = 1
scaleValBox.Text = ""
scaleValBox.PlaceholderText = ""
scaleValBox.TextColor3 = Color3.fromRGB(140, 140, 255)
scaleValBox.TextSize = 10
scaleValBox.Font = Enum.Font.GothamBold
scaleValBox.TextXAlignment = Enum.TextXAlignment.Right
scaleValBox.ClearTextOnFocus = true
scaleValBox.Visible = false
scaleValBox.ZIndex = 6
scaleValBox.Parent = scaleRow

local scaleValBtn = Instance.new("TextButton")
scaleValBtn.Size = UDim2.new(0, 30, 1, 0)
scaleValBtn.Position = UDim2.new(1, -34, 0, 0)
scaleValBtn.BackgroundTransparency = 1
scaleValBtn.Text = ""
scaleValBtn.ZIndex = 7
scaleValBtn.Parent = scaleRow

scaleValBtn.MouseButton1Click:Connect(function()
    scaleValLbl.Visible = false
    scaleValBox.Visible = true
    scaleValBox.Text = tostring(math.floor(((currentScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)) * 100 + 0.5))
    scaleValBox:CaptureFocus()
end)

scaleValBox.FocusLost:Connect(function(enterPressed)
    local input = tonumber(scaleValBox.Text)
    if input then
        input = math.clamp(math.floor(input + 0.5), 0, 100)
        local newScale = math.floor(GUI_SCALE_MIN + (input / 100) * (GUI_SCALE_MAX - GUI_SCALE_MIN) + 0.5)
        local snappedDelta = (newScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
        if sliderFill and sliderFill.Parent then
            Services.Tween:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(snappedDelta, 0, 1, 0)}):Play()
        end
        if sliderThumb and sliderThumb.Parent then
            Services.Tween:Create(sliderThumb, TweenInfo.new(0.15), {Position = UDim2.new(snappedDelta, -5.5, 0.5, -5.5)}):Play()
        end
        scaleValLbl.Text = math.floor(snappedDelta * 100 + 0.5) .. "%"
        applyGuiScale(newScale)
    end
    scaleValBox.Visible = false
    scaleValLbl.Visible = true
end)

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -106, 0, 5)
sliderBg.Position = UDim2.new(0, 68, 0.5, -2)
sliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = scaleRow

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(1, 0)
sliderBgCorner.Parent = sliderBg

local initDelta = (currentScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)

sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(initDelta, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(1, 0)
sliderFillCorner.Parent = sliderFill

sliderThumb = Instance.new("Frame")
sliderThumb.Size = UDim2.new(0, 11, 0, 11)
sliderThumb.Position = UDim2.new(initDelta, -5.5, 0.5, -5.5)
sliderThumb.BackgroundColor3 = Color3.fromRGB(180, 180, 255)
sliderThumb.BorderSizePixel = 0
sliderThumb.ZIndex = 2
sliderThumb.Parent = sliderBg

local sliderThumbCorner = Instance.new("UICorner")
sliderThumbCorner.CornerRadius = UDim.new(1, 0)
sliderThumbCorner.Parent = sliderThumb

local sliderClickDetector = Instance.new("TextButton")
sliderClickDetector.Size = UDim2.new(1, 0, 1, 0)
sliderClickDetector.BackgroundTransparency = 1
sliderClickDetector.Text = ""
sliderClickDetector.ZIndex = 5
sliderClickDetector.Parent = scaleRow

local scaleDragging = false
local scaleMoveConn, scaleReleaseConn

sliderClickDetector.InputBegan:Connect(function(input)
    if scaleDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local isTouch = (input.UserInputType == Enum.UserInputType.Touch)
        scaleDragging = true
        local function updateScale()
            local inputPos = isTouch and input.Position.X or Services.Input:GetMouseLocation().X
            local delta = math.clamp((inputPos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local newScale = math.floor(GUI_SCALE_MIN + delta * (GUI_SCALE_MAX - GUI_SCALE_MIN) + 0.5)
            local snappedDelta = (newScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
            Services.Tween:Create(sliderFill, TweenInfo.new(0.05), {Size = UDim2.new(snappedDelta, 0, 1, 0)}):Play()
            Services.Tween:Create(sliderThumb, TweenInfo.new(0.05), {Position = UDim2.new(snappedDelta, -5.5, 0.5, -5.5)}):Play()
            scaleValLbl.Text = math.floor(snappedDelta * 100 + 0.5) .. "%"
            applyGuiScale(newScale)
        end
        updateScale()
        scaleMoveConn = Services.RunService.RenderStepped:Connect(updateScale)
        scaleReleaseConn = Services.Input.InputEnded:Connect(function(endInput)
            if endInput == input then
                if scaleMoveConn then scaleMoveConn:Disconnect() end
                if scaleReleaseConn then scaleReleaseConn:Disconnect() end
                scaleDragging = false
            end
        end)
    end
end)

local function doResetScale()
    local defDelta = (GUI_SCALE_DEFAULT - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
    Services.Tween:Create(sliderFill, TweenInfo.new(0.15), {Size = UDim2.new(defDelta, 0, 1, 0)}):Play()
    Services.Tween:Create(sliderThumb, TweenInfo.new(0.15), {Position = UDim2.new(defDelta, -5.5, 0.5, -5.5)}):Play()
    scaleValLbl.Text = math.floor(defDelta * 100 + 0.5) .. "%"
    applyGuiScale(GUI_SCALE_DEFAULT)
end

resetScaleCredit.MouseButton1Click:Connect(doResetScale)

-- =====================
-- CREDITS TAB
-- =====================
local credScroll = tabContents["Credits"]
makeSectionLabel("Credits", credScroll, 1)

local versionCard = Instance.new("Frame")
versionCard.Size = UDim2.new(1, 0, 0, 48)
versionCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
versionCard.BackgroundTransparency = 0.17
versionCard.BorderSizePixel = 0
versionCard.LayoutOrder = 2
versionCard.Parent = credScroll

local vcCorner = Instance.new("UICorner")
vcCorner.CornerRadius = UDim.new(0, 6)
vcCorner.Parent = versionCard

local vcStroke = Instance.new("UIStroke")
vcStroke.Thickness = 1
vcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
vcStroke.Color = Color3.fromRGB(50, 50, 62)
vcStroke.Parent = versionCard

local vcTitle = Instance.new("TextLabel")
vcTitle.Size = UDim2.new(1, 0, 0, 24)
vcTitle.Position = UDim2.new(0, 0, 0, 6)
vcTitle.BackgroundTransparency = 1
vcTitle.Text = "Version 1.0"
vcTitle.TextColor3 = Color3.fromRGB(210, 210, 220)
vcTitle.TextSize = 13
vcTitle.Font = Enum.Font.GothamBold
vcTitle.TextXAlignment = Enum.TextXAlignment.Center
vcTitle.Parent = versionCard

local vcSub = Instance.new("TextLabel")
vcSub.Size = UDim2.new(1, -16, 0, 16)
vcSub.Position = UDim2.new(0, 10, 0, 28)
vcSub.BackgroundTransparency = 1
vcSub.Text = "Version 1.0 • Upcoming 1.1"
vcSub.TextColor3 = Color3.fromRGB(80, 80, 95)
vcSub.TextSize = 9
vcSub.Font = Enum.Font.Gotham
vcSub.TextXAlignment = Enum.TextXAlignment.Left
vcSub.Parent = versionCard

local madeCard = Instance.new("Frame")
madeCard.Size = UDim2.new(1, 0, 0, 48)
madeCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
madeCard.BackgroundTransparency = 0.17
madeCard.BorderSizePixel = 0
madeCard.LayoutOrder = 3
madeCard.Parent = credScroll

local madeCorner = Instance.new("UICorner")
madeCorner.CornerRadius = UDim.new(0, 6)
madeCorner.Parent = madeCard

local madeStroke = Instance.new("UIStroke")
madeStroke.Thickness = 1
madeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
madeStroke.Color = Color3.fromRGB(50, 50, 62)
madeStroke.Parent = madeCard

local madeTitle = Instance.new("TextLabel")
madeTitle.Size = UDim2.new(1, 0, 0, 22)
madeTitle.Position = UDim2.new(0, 0, 0, 6)
madeTitle.BackgroundTransparency = 1
madeTitle.Text = "Made By @michal @sh4dow"
madeTitle.TextColor3 = Color3.fromRGB(210, 210, 220)
madeTitle.TextSize = 11
madeTitle.Font = Enum.Font.GothamBold
madeTitle.TextXAlignment = Enum.TextXAlignment.Center
madeTitle.Parent = madeCard

local madeSubRow = Instance.new("Frame")
madeSubRow.Size = UDim2.new(1, -16, 0, 16)
madeSubRow.Position = UDim2.new(0, 10, 0, 28)
madeSubRow.BackgroundTransparency = 1
madeSubRow.Parent = madeCard

local madeSubText = Instance.new("TextLabel")
madeSubText.Size = UDim2.new(1, -20, 1, 0)
madeSubText.BackgroundTransparency = 1
madeSubText.Text = "Thank you for using our hub"
madeSubText.TextColor3 = Color3.fromRGB(80, 80, 95)
madeSubText.TextSize = 9
madeSubText.Font = Enum.Font.Gotham
madeSubText.TextXAlignment = Enum.TextXAlignment.Left
madeSubText.Parent = madeSubRow

local madeSubIcon = Instance.new("ImageLabel")
madeSubIcon.Size = UDim2.new(0, 14, 0, 14)
madeSubIcon.Position = UDim2.new(1, -14, 0.5, -7)
madeSubIcon.BackgroundTransparency = 1
madeSubIcon.Image = "rbxassetid://100961616085482"
madeSubIcon.ImageColor3 = Color3.fromRGB(160, 160, 175)
madeSubIcon.Parent = madeSubRow

makeCardBtn("Join our Community!", "97462463002118", credScroll, 4, function()
    setclipboard("https://discord.gg/cSGgvrS78")
    showNotification({ message = "Discord Copied!", barColor = "Blue", textColor = "Default" })
end)

makeSectionLabel("Utility", credScroll, 5)

makeIosToggle("Anti Afk", credScroll, 6, function(state)
    if state then
        task.spawn(function()
            local VirtualUser = game:GetService("VirtualUser")
            Services.Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end)
    end
end)

-- =====================
-- QUICK PANEL CLASSES
-- =====================
local QuickPanel = {}
QuickPanel.__index = QuickPanel

function QuickPanel:New()
    local self = setmetatable({}, QuickPanel)
    self.layoutOrder = 100
    return self
end

function QuickPanel:AddToggle(opts)
    self.layoutOrder = self.layoutOrder + 1
    local order = self.layoutOrder
    local labelText = opts.Title or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = scrollFrame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 7)
    cc.Parent = container

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(35, 35, 42)
    cs.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(160, 160, 175)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 48, 0, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    pill.BorderSizePixel = 0
    pill.Text = "OFF"
    pill.TextColor3 = Color3.fromRGB(90, 90, 100)
    pill.TextSize = 10
    pill.Font = Enum.Font.GothamBold
    pill.ZIndex = 2
    pill.Parent = container

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Thickness = 1
    pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pillStroke.Color = Color3.fromRGB(50, 50, 60)
    pillStroke.Parent = pill

    local isOn = false
    local function applyState(state, silent)
        isOn = state
        if isOn then
            Services.Tween:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 240, 250)}):Play()
            pill.TextColor3 = Color3.fromRGB(10, 10, 12)
            pill.Text = "ON"
            pillStroke.Color = Color3.fromRGB(200, 200, 215)
            label.TextColor3 = Color3.fromRGB(220, 220, 235)
            Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 120, 140)}):Play()
        else
            Services.Tween:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
            pill.TextColor3 = Color3.fromRGB(90, 90, 100)
            pill.Text = "OFF"
            pillStroke.Color = Color3.fromRGB(50, 50, 60)
            label.TextColor3 = Color3.fromRGB(160, 160, 175)
            Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(35, 35, 42)}):Play()
        end
        if not silent then
            ConfigSystem.CurrentConfig.toggles[labelText] = isOn
            ConfigSystem:Save(ConfigSystem.CurrentConfig)
        end
        if callback and not silent then callback(isOn) end
    end

    local savedState = ConfigSystem.CurrentConfig.toggles[labelText]
    if savedState ~= nil then
        applyState(savedState, true)
        if callback then callback(isOn) end
    elseif default then
        applyState(default, true)
        if callback then callback(isOn) end
    end

    pill.MouseButton1Click:Connect(function() applyState(not isOn, false) end)
    toggleTriggers[labelText] = function() applyState(not isOn, false) end
    
    -- Auto create keybind row
    makeKeybindRow(labelText, kbScroll, #kbScroll:GetChildren() + 1)
    
    return {
        Set = function(_, val) applyState(val, false) end,
        Get = function(_) return isOn end
    }
end

function QuickPanel:AddButton(opts)
    self.layoutOrder = self.layoutOrder + 1
    local order = self.layoutOrder
    local labelText = opts.Title or "Button"
    local callback = opts.Callback
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = scrollFrame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 7)
    cc.Parent = container

    local cs = Instance.new("UIStroke")
    cs.Thickness = 1
    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cs.Color = Color3.fromRGB(35, 35, 42)
    cs.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(160, 160, 175)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(1, -28, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://77565720409665"
    icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    icon.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = container

    btn.MouseEnter:Connect(function()
        Services.Tween:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 36)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 100, 120)}):Play()
        label.TextColor3 = Color3.fromRGB(220, 220, 235)
        icon.ImageColor3 = Color3.fromRGB(220, 220, 235)
    end)
    btn.MouseLeave:Connect(function()
        Services.Tween:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(16, 16, 20)}):Play()
        Services.Tween:Create(cs, TweenInfo.new(0.2), {Color = Color3.fromRGB(35, 35, 42)}):Play()
        label.TextColor3 = Color3.fromRGB(160, 160, 175)
        icon.ImageColor3 = Color3.fromRGB(160, 160, 175)
    end)
    
    local function fire() if callback then callback() end end
    btn.MouseButton1Click:Connect(fire)
    toggleTriggers[labelText] = fire
    
    -- Auto create keybind row
    makeKeybindRow(labelText, kbScroll, #kbScroll:GetChildren() + 1)
end

function QuickPanel:Notify(opts)
    showNotification(opts)
end

-- =====================
-- MAINHUB CLASSES
-- =====================
local MainHub = {}
MainHub.__index = MainHub

function MainHub:New()
    local self = setmetatable({}, MainHub)
    self.layoutOrders = {
        Features = 100,
        Misc = 100
    }
    return self
end

function MainHub:AddToggle(opts)
    local tab = opts.Tab or "Features"
    if tab ~= "Features" and tab ~= "Misc" then
        warn("Invalid Tab: " .. tab .. ". Only 'Features' and 'Misc' are allowed.")
        return
    end
    
    local scroll = tabContents[tab]
    if not scroll then return end
    
    self.layoutOrders[tab] = self.layoutOrders[tab] + 1
    local order = self.layoutOrders[tab]
    
    return makeIosToggle(opts.Title or "Toggle", scroll, order, opts.Callback)
end

function MainHub:AddButton(opts)
    local tab = opts.Tab or "Features"
    if tab ~= "Features" and tab ~= "Misc" then
        warn("Invalid Tab: " .. tab .. ". Only 'Features' and 'Misc' are allowed.")
        return
    end
    
    local scroll = tabContents[tab]
    if not scroll then return end
    
    self.layoutOrders[tab] = self.layoutOrders[tab] + 1
    local order = self.layoutOrders[tab]
    
    makeCardBtn(opts.Title or "Button", "97462463002118", scroll, order, opts.Callback)
end

function MainHub:AddSection(opts)
    local tab = opts.Tab or "Features"
    if tab ~= "Features" and tab ~= "Misc" then
        warn("Invalid Tab: " .. tab .. ". Only 'Features' and 'Misc' are allowed.")
        return
    end
    
    local scroll = tabContents[tab]
    if not scroll then return end
    
    self.layoutOrders[tab] = self.layoutOrders[tab] + 1
    local order = self.layoutOrders[tab]
    
    makeSectionLabel(opts.Title or "Section", scroll, order)
end

function MainHub:Notify(opts)
    showNotification(opts)
end

-- =====================
-- MINIMIZE LOGIC
-- =====================
local minimizeTween = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local fullMainW = math.floor(MAIN_BASE_W * (currentScale / GUI_SCALE_DEFAULT))
local fullMainH = math.floor(MAIN_BASE_H * (currentScale / GUI_SCALE_DEFAULT))

local function doMinimize()
    fullMainW = math.floor(MAIN_BASE_W * (currentScale / GUI_SCALE_DEFAULT))
    fullMainH = math.floor(MAIN_BASE_H * (currentScale / GUI_SCALE_DEFAULT))
    Services.Tween:Create(mainFrame, minimizeTween, {
        Size = UDim2.new(0, fullMainW, 0, MAIN_MINIMIZED_H)
    }):Play()
    minimizeBtn.Text = "+"
    mainDivider.Visible  = false
    mainSubtitle.Visible = false
    scrollFrame.Visible  = false
    isMinimized = true
end

local function doRestore()
    Services.Tween:Create(mainFrame, minimizeTween, {
        Size = UDim2.new(0, fullMainW, 0, fullMainH)
    }):Play()
    minimizeBtn.Text = "–"
    mainDivider.Visible  = true
    mainSubtitle.Visible = true
    scrollFrame.Visible  = true
    isMinimized = false
end

minimizeBtn.MouseButton1Click:Connect(function()
    if not isMinimized then doMinimize() else doRestore() end
end)

if ConfigSystem.CurrentConfig.toggles["Auto Hide Quick Panel"] == true then
    doMinimize()
end

-- =====================
-- MENU VISIBILITY LOGIC
-- =====================
local menuOpen = false
if ConfigSystem.CurrentConfig.toggles["Show Menu on Start"] == true then
    menuOpen = true
    menuFrame.Visible = true
end

closeBtn.MouseButton1Click:Connect(function()
    menuOpen = false
    menuFrame.Visible = false
end)

-- =====================
-- STARTUP
-- =====================
setActiveTab("Features")

addTextGradient(mainTitle,   Colors.TitleGradient.C1, Colors.TitleGradient.C2, 45)
addTextGradient(menuTitle,   Colors.TitleGradient.C1, Colors.TitleGradient.C2, 45)
addTextGradient(creditTitle, Colors.TitleGradient.C1, Colors.TitleGradient.C2, 45)

makeTextGlow(mainTitle,   Colors.TitleGradient.C1, Colors.TitleGradient.C2, 1.2, 0)
makeTextGlow(menuTitle,   Colors.TitleGradient.C1, Colors.TitleGradient.C2, 1.2, 0.4)
makeTextGlow(creditTitle, Colors.TitleGradient.C1, Colors.TitleGradient.C2, 1.2, 0.8)

if guiLocked then
    mainFrame.Draggable   = false
    creditFrame.Draggable = false
end

task.defer(function()
    if ConfigSystem.CurrentConfig.guiScale then
        applyGuiScale(ConfigSystem.CurrentConfig.guiScale, true)
        local savedDelta = (ConfigSystem.CurrentConfig.guiScale - GUI_SCALE_MIN) / (GUI_SCALE_MAX - GUI_SCALE_MIN)
        sliderFill.Size = UDim2.new(savedDelta, 0, 1, 0)
        sliderThumb.Position = UDim2.new(savedDelta, -5.5, 0.5, -5.5)
        scaleValLbl.Text = math.floor(savedDelta * 100 + 0.5) .. "%"
    end
end)

-- =====================
-- LIBRARY EXPORT
-- =====================
Library.QuickPanel = QuickPanel
Library.MainHub = MainHub

return Library
