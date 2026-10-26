-- Rake Hub-Beta [SMART ANTI-RUBBERBAND + ZERO-LAG + FULL EXPANSION]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local WIDTH = isMobile and 280 or 360
local HEIGHT = isMobile and 360 or 480
local TEXT_SM = isMobile and 11 or 13
local TEXT_MD = isMobile and 12 or 14
local TEXT_LG = isMobile and 14 or 18
local ELEMENT_H = isMobile and 32 or 38
local SLIDER_H = isMobile and 46 or 52

local Settings = {
    NightVision = false, NoFog = false,
    
    -- Movement & Physics (Smart Anti-Rubberband)
    FastSprint = false, -- Классический быстрый бег (28) без откатов
    WalkSpeedEnabled = false, WalkSpeed = 24,
    SpeedBypass = false, -- Импульсный обход лимита 30.2 без CFrame-откатов
    JumpPowerEnabled = false, JumpPower = 40,
    FlyEnabled = false, FlySpeed = 28,
    NoJerk = false,
    Noclip = false,
    InfiniteStamina = false,
    
    -- Combat & Items
    KeepItems = false,
    InstaKillRake = false,
    StunReach = false,
    StunNoCD = false,
    StunNoFail = false,
    ObjectControl = false,
    
    -- Visuals & Camera
    UnlockZoom = false,
    FOVEnabled = false, FOV = 75,
    DisableEffects = false,
    Freecam = false,
    RakePathfind = false,
    
    -- ESP
    EspTextSize = isMobile and 8 or 9,
    BoxHandleAdornments = false,
    EspRake = false,
    EspPlayers = false,
    EspRustyTraps = false,
    EspRakeTraps = false,
    EspLocations = false,
    EspScrap = false,
    EspFlareGun = false,
    EspSupplyDrop = false
}

local LocationKeywords = {
    ["shop"] = "Shop", ["store"] = "Shop", ["tower"] = "Tower",
    ["base"] = "Base", ["camp"] = "Base", ["safehouse"] = "Cabin", ["cabin"] = "Cabin",
    ["power"] = "Power Station", ["station"] = "Power Station"
}

local LanguagesList = {
    "Русский (Russian)", "English", "Español (Spanish)", "Deutsch (German)",
    "Français (French)", "Português (Portuguese)", "Türkçe (Turkish)",
    "Українська (Ukrainian)", "Polski (Polish)", "Italiano (Italian)",
    "中文 (Chinese)", "日本語 (Japanese)", "한국어 (Korean)", "العربية (Arabic)"
}

local EspCache = {}
local UIElements = {}
local Connections = {}
local CharConnections = {}
local SavedTools = {}
local PathNodes = {}
local StaminaTables = {}
local FileName = "RakeHubBeta_SavedName.txt"
local isMenuOpen = false
local scriptRunning = true
local SelectedLanguage = "Русский (Russian)"

local FreecamState = {
    Active = false,
    CFrame = CFrame.new(),
    Angles = Vector2.new(),
    Speed = 45
}

local DraggedObject = nil
local DragDistance = 15

local Colors = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(28, 28, 34),
    Stroke = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(210, 55, 65),
    ConfirmWarning = Color3.fromRGB(220, 130, 30),
    TextWhite = Color3.fromRGB(235, 235, 240),
    TextGray = Color3.fromRGB(130, 130, 140)
}

local function GetSavedName()
    if isfile and isfile(FileName) then
        local success, name = pcall(function() return readfile(FileName) end)
        if success and name and string.gsub(name, "%s+", "") ~= "" then return name end
    end
    return nil
end

local function SaveName(name)
    if writefile then pcall(function() writefile(FileName, name) end) end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakeHub_Beta_UI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function ClearPathNodes()
    for _, node in ipairs(PathNodes) do
        if node and node.Parent then node:Destroy() end
    end
    table.clear(PathNodes)
end

local function ClearCharConnections()
    for _, conn in ipairs(CharConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(CharConnections)
end

local function DestroyScript()
    scriptRunning = false
    ClearCharConnections()
    
    for _, conn in ipairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect()
        elseif type(conn) == "thread" then task.cancel(conn) end
    end
    
    for obj, data in pairs(EspCache) do
        for _, v in ipairs(data.Elements) do pcall(function() v:Destroy() end) end
    end
    EspCache = {}
    ClearPathNodes()
    
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true
    
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = 70
    LocalPlayer.CameraMaxZoomDistance = 12
    
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso") then
                part.CanCollide = true
            end
        end
    end
    
    if ScreenGui then ScreenGui:Destroy() end
end

-- Мобильная кнопка меню
local MobileToggleBtn = Instance.new("TextButton")
MobileToggleBtn.Size = UDim2.new(0, 46, 0, 46)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -23)
MobileToggleBtn.BackgroundColor3 = Colors.Panel
MobileToggleBtn.Text = "RH"
MobileToggleBtn.TextColor3 = Colors.TextWhite
MobileToggleBtn.Font = Enum.Font.GothamBlack
MobileToggleBtn.TextSize = 18
MobileToggleBtn.Visible = false
MobileToggleBtn.Parent = ScreenGui
Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MobileToggleBtn).Color = Colors.Stroke

-- Мобильный джойстик для Бесплатной Камеры и Полета
local FreecamMobileFrame = Instance.new("Frame")
FreecamMobileFrame.Size = UDim2.new(0, 130, 0, 130)
FreecamMobileFrame.Position = UDim2.new(0, 25, 1, -165)
FreecamMobileFrame.BackgroundTransparency = 0.5
FreecamMobileFrame.BackgroundColor3 = Colors.Background
FreecamMobileFrame.Visible = false
FreecamMobileFrame.Parent = ScreenGui
Instance.new("UICorner", FreecamMobileFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", FreecamMobileFrame).Color = Colors.Stroke

local MobileMoveVec = Vector3.zero
local function CreateFCBtn(txt, pos, dir)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 36, 0, 36)
    b.Position = pos
    b.BackgroundColor3 = Colors.Panel
    b.Text = txt
    b.TextColor3 = Colors.TextWhite
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = FreecamMobileFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            MobileMoveVec = MobileMoveVec + dir
        end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            MobileMoveVec = MobileMoveVec - dir
        end
    end)
end
CreateFCBtn("W", UDim2.new(0.5, -18, 0, 6), Vector3.new(0, 0, -1))
CreateFCBtn("S", UDim2.new(0.5, -18, 1, -42), Vector3.new(0, 0, 1))
CreateFCBtn("A", UDim2.new(0, 6, 0.5, -18), Vector3.new(-1, 0, 0))
CreateFCBtn("D", UDim2.new(1, -42, 0.5, -18), Vector3.new(1, 0, 0))
CreateFCBtn("UP", UDim2.new(1, -42, 0, 6), Vector3.new(0, 1, 0))
CreateFCBtn("DN", UDim2.new(0, 6, 1, -42), Vector3.new(0, -1, 0))

local rDragging, rDragInput, rDragStart, rStartPos
MobileToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rDragging = true; rDragStart = input.Position; rStartPos = MobileToggleBtn.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then rDragging = false end end)
        TweenService:Create(MobileToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 42, 0, 42)}):Play()
    end
end)
MobileToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TweenService:Create(MobileToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 46, 0, 46)}):Play()
    end
end)
MobileToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then rDragInput = input end
end)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == rDragInput and rDragging then
        local delta = input.Position - rDragStart
        MobileToggleBtn.Position = UDim2.new(rStartPos.X.Scale, rStartPos.X.Offset + delta.X, rStartPos.Y.Scale, rStartPos.Y.Offset + delta.Y)
    end
end))

-- Экран загрузки
local LoadFrame = Instance.new("Frame")
LoadFrame.Size = UDim2.new(0, WIDTH, 0, 100)
LoadFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -50)
LoadFrame.BackgroundColor3 = Colors.Background
LoadFrame.BorderSizePixel = 0
LoadFrame.ClipsDescendants = true
LoadFrame.Parent = ScreenGui
Instance.new("UICorner", LoadFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LoadFrame).Color = Colors.Stroke

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 30)
LoadTitle.Position = UDim2.new(0, 0, 0, 15)
LoadTitle.BackgroundTransparency = 1
LoadTitle.RichText = true
LoadTitle.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
LoadTitle.TextColor3 = Colors.TextWhite
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = TEXT_LG
LoadTitle.Parent = LoadFrame

local PercentText = Instance.new("TextLabel")
PercentText.Size = UDim2.new(1, 0, 0, 20)
PercentText.Position = UDim2.new(0, 0, 0, 42)
PercentText.BackgroundTransparency = 1
PercentText.Text = "Инициализация... 0%"
PercentText.TextColor3 = Colors.TextGray
PercentText.Font = Enum.Font.GothamMedium
PercentText.TextSize = TEXT_SM
PercentText.Parent = LoadFrame

local LoadBarBg = Instance.new("Frame")
LoadBarBg.Size = UDim2.new(0.86, 0, 0, 4)
LoadBarBg.Position = UDim2.new(0.07, 0, 0.75, 0)
LoadBarBg.BackgroundColor3 = Colors.Panel
LoadBarBg.BorderSizePixel = 0
LoadBarBg.Parent = LoadFrame
Instance.new("UICorner", LoadBarBg).CornerRadius = UDim.new(1, 0)

local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0, 0, 1, 0)
LoadBar.BackgroundColor3 = Colors.Accent
LoadBar.BorderSizePixel = 0
LoadBar.Parent = LoadBarBg
Instance.new("UICorner", LoadBar).CornerRadius = UDim.new(1, 0)

-- Окно выбора языка
local LangFrame = Instance.new("Frame")
LangFrame.Size = UDim2.new(0, WIDTH, 0, 290)
LangFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -145)
LangFrame.BackgroundColor3 = Colors.Background
LangFrame.BorderSizePixel = 0
LangFrame.Visible = false
LangFrame.ClipsDescendants = true
LangFrame.Parent = ScreenGui
Instance.new("UICorner", LangFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", LangFrame).Color = Colors.Stroke

local LangTitle = Instance.new("TextLabel")
LangTitle.Size = UDim2.new(1, 0, 0, 25)
LangTitle.Position = UDim2.new(0, 0, 0, 10)
LangTitle.BackgroundTransparency = 1
LangTitle.Text = "ВЫБЕРИТЕ ЯЗЫК"
LangTitle.TextColor3 = Colors.TextWhite
LangTitle.Font = Enum.Font.GothamBold
LangTitle.TextSize = TEXT_MD
LangTitle.Parent = LangFrame

local LangSearch = Instance.new("TextBox")
LangSearch.Size = UDim2.new(0.86, 0, 0, 30)
LangSearch.Position = UDim2.new(0.07, 0, 0, 40)
LangSearch.BackgroundColor3 = Colors.Panel
LangSearch.BorderSizePixel = 0
LangSearch.PlaceholderText = "Поиск языка..."
LangSearch.PlaceholderColor3 = Colors.TextGray
LangSearch.Text = ""
LangSearch.TextColor3 = Colors.TextWhite
LangSearch.Font = Enum.Font.GothamMedium
LangSearch.TextSize = TEXT_SM
LangSearch.Parent = LangFrame
Instance.new("UICorner", LangSearch).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", LangSearch).Color = Colors.Stroke

local LangContainer = Instance.new("ScrollingFrame")
LangContainer.Size = UDim2.new(0.86, 0, 0, 140)
LangContainer.Position = UDim2.new(0.07, 0, 0, 78)
LangContainer.BackgroundTransparency = 1
LangContainer.ScrollBarThickness = 3
LangContainer.ScrollBarImageColor3 = Colors.Stroke
LangContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
LangContainer.Parent = LangFrame

local LangListLayout = Instance.new("UIListLayout")
LangListLayout.Padding = UDim.new(0, 4)
LangListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
LangListLayout.Parent = LangContainer

local LangConfirmBtn = Instance.new("TextButton")
LangConfirmBtn.Size = UDim2.new(0.86, 0, 0, 34)
LangConfirmBtn.Position = UDim2.new(0.07, 0, 0, 238)
LangConfirmBtn.BackgroundColor3 = Colors.Accent
LangConfirmBtn.BorderSizePixel = 0
LangConfirmBtn.Text = "ПОДТВЕРДИТЬ"
LangConfirmBtn.TextColor3 = Colors.TextWhite
LangConfirmBtn.Font = Enum.Font.GothamBold
LangConfirmBtn.TextSize = TEXT_SM
LangConfirmBtn.Parent = LangFrame
Instance.new("UICorner", LangConfirmBtn).CornerRadius = UDim.new(0, 6)

local LangButtons = {}
local SelectedLangBtn = nil

for _, langName in ipairs(LanguagesList) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 26)
    Btn.BackgroundColor3 = Colors.Panel
    Btn.BorderSizePixel = 0
    Btn.Text = langName
    Btn.TextColor3 = Colors.TextGray
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = TEXT_SM
    Btn.Parent = LangContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", Btn)
    stroke.Color = Colors.Stroke
    stroke.Transparency = 0.5

    Btn.MouseButton1Click:Connect(function()
        SelectedLanguage = langName
        if SelectedLangBtn then
            TweenService:Create(SelectedLangBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Panel, TextColor3 = Colors.TextGray}):Play()
        end
        SelectedLangBtn = Btn
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent, TextColor3 = Colors.TextWhite}):Play()
    end)
    table.insert(LangButtons, Btn)
end
LangContainer.CanvasSize = UDim2.new(0, 0, 0, LangListLayout.AbsoluteContentSize.Y + 10)

LangSearch:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(LangSearch.Text)
    for _, btn in ipairs(LangButtons) do
        btn.Visible = (query == "" or string.find(string.lower(btn.Text), query) ~= nil)
    end
    LangContainer.CanvasSize = UDim2.new(0, 0, 0, LangListLayout.AbsoluteContentSize.Y + 10)
end)

-- Окно ввода имени
local NameFrame = Instance.new("Frame")
NameFrame.Size = UDim2.new(0, WIDTH, 0, 200)
NameFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -100)
NameFrame.BackgroundColor3 = Colors.Background
NameFrame.BorderSizePixel = 0
NameFrame.Visible = false
NameFrame.ClipsDescendants = true
NameFrame.Parent = ScreenGui
Instance.new("UICorner", NameFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", NameFrame).Color = Colors.Stroke

local AskLabel = Instance.new("TextLabel")
AskLabel.Size = UDim2.new(1, 0, 0, 20)
AskLabel.Position = UDim2.new(0, 0, 0, 35)
AskLabel.BackgroundTransparency = 1
AskLabel.Text = "Введите ваше имя"
AskLabel.TextColor3 = Colors.TextWhite
AskLabel.Font = Enum.Font.GothamBold
AskLabel.TextSize = TEXT_MD
AskLabel.Parent = NameFrame

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0.86, 0, 0, 36)
NameInput.Position = UDim2.new(0.07, 0, 0, 75)
NameInput.BackgroundColor3 = Colors.Panel
NameInput.BorderSizePixel = 0
NameInput.PlaceholderText = "Имя пользователя..."
NameInput.PlaceholderColor3 = Colors.TextGray
NameInput.Text = ""
NameInput.TextColor3 = Colors.TextWhite
NameInput.Font = Enum.Font.GothamMedium
NameInput.TextSize = TEXT_MD
NameInput.Parent = NameFrame
Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", NameInput).Color = Colors.Stroke

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(0.86, 0, 0, 34)
SubmitBtn.Position = UDim2.new(0.07, 0, 0, 130)
SubmitBtn.BackgroundColor3 = Colors.Accent
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Text = "ВОЙТИ"
SubmitBtn.TextColor3 = Colors.TextWhite
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = TEXT_MD
SubmitBtn.Parent = NameFrame
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

-- Главное меню
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
MainFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -(HEIGHT/2))
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Colors.Stroke

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Colors.Panel
TopBar.Active = true
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
Title.TextColor3 = Colors.TextWhite
Title.TextSize = TEXT_MD
Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Colors.TextGray
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar
CloseButton.MouseButton1Click:Connect(DestroyScript)

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 65, 65), TextSize = 18}):Play()
end)
CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Colors.TextGray, TextSize = 16}):Play()
end)

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -16, 1, -54)
Container.Position = UDim2.new(0, 8, 0, 46)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Colors.Stroke
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = Container

local function CreateSection(titleText)
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(1, 0, 0, 24)
    Wrapper.BackgroundTransparency = 1
    Wrapper.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -12, 1, 0)
    Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(titleText)
    Label.TextColor3 = Colors.Accent
    Label.TextSize = TEXT_SM
    Label.Font = Enum.Font.GothamBlack
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Wrapper

    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end

local function CreateElement(text, callback, isAction, customColor)
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(1, 0, 0, ELEMENT_H)
    Wrapper.BackgroundTransparency = 1
    Wrapper.Parent = Container

    local Element = Instance.new("TextButton")
    Element.Size = UDim2.new(1, 0, 1, 0)
    Element.Position = UDim2.new(0, -30, 0, 0)
    Element.BackgroundColor3 = Colors.Panel
    Element.BackgroundTransparency = 1
    Element.Text = ""
    Element.AutoButtonColor = false
    Element.Parent = Wrapper
    
    Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Element)
    Stroke.Color = Colors.Stroke
    Stroke.Transparency = 1

    local Label = Instance.new("TextLabel")
    Label.Size = isAction and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -46, 1, 0)
    Label.Position = isAction and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = isAction and (customColor or Colors.TextWhite) or Colors.TextGray
    Label.TextSize = TEXT_SM
    Label.Font = Enum.Font.GothamMedium
    Label.TextTransparency = 1
    Label.TextXAlignment = isAction and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    Label.Parent = Element
    
    local Knob, SwitchBg, SwitchStroke
    if not isAction then
        SwitchBg = Instance.new("Frame")
        SwitchBg.Size = UDim2.new(0, 34, 0, 18)
        SwitchBg.Position = UDim2.new(1, -42, 0.5, -9)
        SwitchBg.BackgroundColor3 = Colors.Background
        SwitchBg.BackgroundTransparency = 1
        SwitchBg.Parent = Element
        Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
        SwitchStroke = Instance.new("UIStroke", SwitchBg)
        SwitchStroke.Color = Colors.Stroke
        SwitchStroke.Transparency = 1

        Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.Position = UDim2.new(0, 3, 0.5, -6)
        Knob.BackgroundColor3 = Colors.TextGray
        Knob.BackgroundTransparency = 1
        Knob.Parent = SwitchBg
        Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

        local Enabled = false
        Element.MouseButton1Click:Connect(function()
            Enabled = not Enabled
            local activeColor = customColor or Colors.Accent
            TweenService:Create(Knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = Enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Enabled and Colors.TextWhite or Colors.TextGray
            }):Play()
            TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = Enabled and activeColor or Colors.Background}):Play()
            TweenService:Create(SwitchStroke, TweenInfo.new(0.3), {Color = Enabled and activeColor or Colors.Stroke}):Play()
            TweenService:Create(Label, TweenInfo.new(0.3), {TextColor3 = Enabled and Colors.TextWhite or Colors.TextGray}):Play()
            callback(Enabled)
        end)
    else
        Element.MouseButton1Click:Connect(function()
            TweenService:Create(Element, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(0.95, 0, 0, ELEMENT_H - 4)}):Play()
            task.wait(0.1)
            TweenService:Create(Element, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            callback()
        end)
    end

    table.insert(UIElements, {Element = Element, Stroke = Stroke, Label = Label, SwitchBg = SwitchBg, SwitchStroke = SwitchStroke, Knob = Knob})
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
    return Element
end

local function CreateSlider(text, minVal, maxVal, defaultVal, decimals, callback)
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(1, 0, 0, SLIDER_H)
    Wrapper.BackgroundTransparency = 1
    Wrapper.Parent = Container

    local Element = Instance.new("Frame")
    Element.Size = UDim2.new(1, 0, 1, 0)
    Element.Position = UDim2.new(0, -30, 0, 0)
    Element.BackgroundColor3 = Colors.Panel
    Element.BackgroundTransparency = 1
    Element.Parent = Wrapper
    Instance.new("UICorner", Element).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Element)
    Stroke.Color = Colors.Stroke
    Stroke.Transparency = 1

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 20)
    Label.Position = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. tostring(defaultVal)
    Label.TextColor3 = Colors.TextWhite
    Label.TextSize = TEXT_SM
    Label.Font = Enum.Font.GothamMedium
    Label.TextTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Element

    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -24, 0, 6)
    SliderBg.Position = UDim2.new(0, 12, 0, 32)
    SliderBg.BackgroundColor3 = Colors.Background
    SliderBg.BackgroundTransparency = 1
    SliderBg.Parent = Element
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
    local SliderStroke = Instance.new("UIStroke", SliderBg)
    SliderStroke.Color = Colors.Stroke
    SliderStroke.Transparency = 1

    local Fill = Instance.new("Frame")
    local initPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    Fill.Size = UDim2.new(initPct, 0, 1, 0)
    Fill.BackgroundColor3 = Colors.Accent
    Fill.BackgroundTransparency = 1
    Fill.Parent = SliderBg
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local sliding = false
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        local rawVal = minVal + (maxVal - minVal) * pos
        local mult = 10 ^ (decimals or 0)
        local val = math.floor(rawVal * mult + 0.5) / mult
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Label.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateSlider(input)
        end
    end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end))

    table.insert(UIElements, {Element = Element, Stroke = Stroke, Label = Label, SwitchBg = SliderBg, SwitchStroke = SliderStroke, Knob = Fill})
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end

local function ResetCascadeElements()
    for _, item in ipairs(UIElements) do
        item.Element.Position = UDim2.new(0, -35, 0, 0)
        item.Element.BackgroundTransparency = 1
        item.Stroke.Transparency = 1
        item.Label.TextTransparency = 1
        if item.SwitchBg then
            item.SwitchBg.BackgroundTransparency = 1
            item.Knob.BackgroundTransparency = 1
            item.SwitchStroke.Transparency = 1
        end
    end
end

local function PlayCascadeAnimation()
    for _, item in ipairs(UIElements) do
        TweenService:Create(item.Element, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(item.Stroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
        TweenService:Create(item.Label, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        if item.SwitchBg then
            TweenService:Create(item.SwitchBg, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
            TweenService:Create(item.Knob, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
            TweenService:Create(item.SwitchStroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
        end
    end
end

local function ToggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        MainFrame.Visible = true
        ResetCascadeElements()
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, HEIGHT)}):Play()
        task.delay(0.1, PlayCascadeAnimation)
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
        task.delay(0.35, function() if not isMenuOpen then MainFrame.Visible = false end end)
    end
end

local function ShowMain(name)
    MobileToggleBtn.Visible = true 
    isMenuOpen = true
    MainFrame.Size = UDim2.new(0, WIDTH, 0, 0)
    MainFrame.Visible = true
    ResetCascadeElements()
    TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, HEIGHT)}):Play()
    task.delay(0.1, PlayCascadeAnimation)
end

local function ShowNameFrame()
    NameFrame.Visible = true
    NameFrame.Size = UDim2.new(0, WIDTH, 0, 0)
    TweenService:Create(NameFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, 200)}):Play()
end

local langConfirmStep = 0
LangConfirmBtn.MouseButton1Click:Connect(function()
    if langConfirmStep == 0 then
        langConfirmStep = 1
        LangConfirmBtn.Text = "ТОЧНО? НАЖМИТЕ ЕЩЁ РАЗ"
        TweenService:Create(LangConfirmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Colors.ConfirmWarning}):Play()
    elseif langConfirmStep == 1 then
        TweenService:Create(LangConfirmBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.82, 0, 0, 30)}):Play()
        task.wait(0.1)
        TweenService:Create(LangFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
        task.wait(0.3)
        LangFrame:Destroy()
        ShowNameFrame()
    end
end)

local function OnNameSubmitted()
    local enteredName = NameInput.Text
    if enteredName == "" or string.gsub(enteredName, "%s+", "") == "" then enteredName = LocalPlayer.DisplayName end
    SaveName(enteredName)
    TweenService:Create(SubmitBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.82, 0, 0, 30)}):Play()
    task.wait(0.1)
    TweenService:Create(NameFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
    task.wait(0.3)
    NameFrame:Destroy()
    ShowMain(enteredName)
end
SubmitBtn.MouseButton1Click:Connect(OnNameSubmitted)
NameInput.FocusLost:Connect(function(enterPressed) if enterPressed then OnNameSubmitted() end end)

task.spawn(function()
    TweenService:Create(LoadBar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    for i = 1, 100, 7 do 
        PercentText.Text = "Загрузка скриптов... " .. i .. "%"
        task.wait(0.04) 
    end
    PercentText.Text = "Успешно! Запуск интерфейса."
    task.wait(0.3)
    TweenService:Create(LoadFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, WIDTH, 0, 0)}):Play()
    task.wait(0.3)
    LoadFrame:Destroy()

    local savedName = GetSavedName()
    if savedName then 
        ShowMain(savedName)
    else
        LangFrame.Visible = true
        LangFrame.Size = UDim2.new(0, WIDTH, 0, 0)
        TweenService:Create(LangFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WIDTH, 0, 290)}):Play()
    end
end)

MobileToggleBtn.MouseButton1Click:Connect(function() if not rDragging then ToggleMenu() end end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

-- ============================================================================
-- ЯДРО ФУНКЦИЙ: SMART ANTI-RUBBERBAND, ESP, INSTA-KILL И ОПТИМИЗАЦИЯ
-- ============================================================================

local CachedRake = nil
local function GetRake()
    if CachedRake and CachedRake.Parent then
        return CachedRake
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local n = string.lower(obj.Name)
            if string.find(n, "rake") or string.find(n, "monster") or obj:FindFirstChild("Monster") then
                if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Monster") then
                    CachedRake = obj
                    return obj
                end
            end
        end
    end
    return nil
end

local function GetEntityHealth(model)
    if not model then return nil, nil end
    local hum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Monster")
    if hum and hum:IsA("Humanoid") then
        return math.floor(hum.Health), math.floor(hum.MaxHealth)
    end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Humanoid") then
            return math.floor(child.Health), math.floor(child.MaxHealth)
        elseif (child:IsA("NumberValue") or child:IsA("IntValue")) and string.lower(child.Name) == "health" then
            local maxH = model:FindFirstChild("MaxHealth")
            return math.floor(child.Value), maxH and math.floor(maxH.Value) or 1000
        end
    end
    return nil, nil
end

local function GetObjectRoot(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function CreateEspElements(object, color, titleText, espType)
    if EspCache[object] then return end
    local rootPart = GetObjectRoot(object)
    if not rootPart then return end
    
    local elements = {}
    
    if Settings.BoxHandleAdornments then
        local Box = Instance.new("BoxHandleAdornment")
        Box.Name = "RakeHubESP_Box"
        Box.Adornee = rootPart
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Size = object:IsA("Model") and object:GetExtentsSize() or rootPart.Size
        Box.Color3 = color
        Box.Transparency = 0.55
        Box.Parent = ScreenGui
        table.insert(elements, Box)
    else
        local Highlight = Instance.new("Highlight")
        Highlight.Name = "RakeHubESP_HL"
        Highlight.FillColor = color
        Highlight.OutlineColor = color
        Highlight.FillTransparency = 0.65
        Highlight.OutlineTransparency = 0.1
        Highlight.Adornee = object
        Highlight.Parent = ScreenGui
        table.insert(elements, Highlight)
    end
    
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "RakeHubESP_BB"
    Billboard.AlwaysOnTop = true
    Billboard.MaxDistance = 1500
    Billboard.Size = UDim2.new(0, 140, 0, 28)
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.Adornee = rootPart
    Billboard.Parent = ScreenGui
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = titleText
    Label.TextColor3 = color
    Label.TextStrokeTransparency = 0.15
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.TextSize = Settings.EspTextSize
    Label.TextWrapped = false
    Label.Font = Enum.Font.GothamBold
    Label.Parent = Billboard
    table.insert(elements, Billboard)
    
    EspCache[object] = {
        Elements = elements,
        Type = espType,
        Title = titleText,
        Label = Label,
        Root = rootPart,
        UsedBox = Settings.BoxHandleAdornments
    }
end

-- Кэш таблиц выносливости (без фризов)
local function CacheStaminaTables()
    table.clear(StaminaTables)
    if not getgc then return end
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "Stamina") ~= nil or rawget(v, "stamina") ~= nil or rawget(v, "StunCooldown") ~= nil or rawget(v, "FailChance") ~= nil then
                    table.insert(StaminaTables, v)
                end
            end
        end
    end)
end

-- Умная привязка к Humanoid (мгновенно перехватывает сброс WalkSpeed игрой без откатов)
local function GetTargetSpeed()
    if Settings.SpeedBypass then return 30.2 end
    if Settings.FastSprint then return 28 end
    if Settings.WalkSpeedEnabled then return Settings.WalkSpeed end
    return nil
end

local function BindCharacter(char)
    ClearCharConnections()
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    table.insert(CharConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        local target = GetTargetSpeed()
        if target and hum.WalkSpeed ~= target then
            hum.WalkSpeed = target
        elseif Settings.NoJerk and hum.WalkSpeed < 16 then
            hum.WalkSpeed = 16
        end
    end))
end

if LocalPlayer.Character then task.spawn(BindCharacter, LocalPlayer.Character) end

table.insert(Connections, LocalPlayer.CharacterRemoving:Connect(function(char)
    ClearCharConnections()
    if not Settings.KeepItems then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then tool.Parent = LocalPlayer.Backpack end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(SavedTools, tool)
            tool.Parent = nil
        end
    end
end))

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(BindCharacter, char)
    task.delay(1.5, function()
        if Settings.InfiniteStamina or Settings.StunNoCD or Settings.StunNoFail then
            CacheStaminaTables()
        end
    end)
    if not Settings.KeepItems or #SavedTools == 0 then return end
    local backpack = LocalPlayer:WaitForChild("Backpack", 5)
    if backpack then
        for _, tool in ipairs(SavedTools) do
            if tool then pcall(function() tool.Parent = backpack end) end
        end
    end
    table.clear(SavedTools)
end))

-- Модификация электрошокера и оружия
local function PatchTools()
    local char = LocalPlayer.Character
    if not char then return end
    for _, container in ipairs({char, LocalPlayer.Backpack}) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = string.lower(tool.Name)
                if string.find(n, "stun") or string.find(n, "stick") or string.find(n, "baton") or string.find(n, "taser") then
                    local handle = tool:FindFirstChild("Handle")
                    if handle and Settings.StunReach then
                        handle.Size = Vector3.new(25, 25, 25)
                        handle.Massless = true
                        handle.CanCollide = false
                        handle.Transparency = 0.8
                    end
                    if Settings.StunNoCD then
                        tool:SetAttribute("Cooldown", 0)
                        for _, v in ipairs(tool:GetChildren()) do
                            if v:IsA("NumberValue") or v:IsA("IntValue") then
                                local vn = string.lower(v.Name)
                                if string.find(vn, "cool") or string.find(vn, "delay") or string.find(vn, "wait") then
                                    v.Value = 0
                                end
                            end
                        end
                    end
                    if Settings.StunNoFail then
                        for _, v in ipairs(tool:GetChildren()) do
                            if v:IsA("BoolValue") and (string.find(string.lower(v.Name), "fail") or string.find(string.lower(v.Name), "broken")) then
                                v.Value = false
                            end
                            if (v:IsA("NumberValue") or v:IsA("IntValue")) and (string.find(string.lower(v.Name), "battery") or string.find(string.lower(v.Name), "charge")) then
                                v.Value = 100
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Умное убийство / Авто-атака Рейка (Network Ownership + FireTouchInterest + Remote Activation)
local function ExecuteRakeKill()
    if not Settings.InstaKillRake then return end
    local rake = GetRake()
    if not rake then return end
    local rHum = rake:FindFirstChildOfClass("Humanoid") or rake:FindFirstChild("Monster")
    local rRoot = GetObjectRoot(rake)
    if not rHum or not rRoot or rHum.Health <= 0 then return end

    -- 1. Расширение радиуса симуляции и проверка владения физикой
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
        end
        if isnetworkowner == nil or isnetworkowner(rRoot) then
            rHum.Health = 0
            rake:BreakJoints()
        end
    end)

    -- 2. Если сервер держит NetworkOwnership, наносим урон через оружие игрока (firetouchinterest)
    local char = LocalPlayer.Character
    if char and firetouchinterest then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
            if handle then
                pcall(function()
                    tool:Activate()
                    firetouchinterest(handle, rRoot, 0)
                    firetouchinterest(handle, rRoot, 1)
                end)
            end
        end
    end
end

-- Проверка одного объекта для ESP
local function CheckObjectForESP(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool") then
        local n = string.lower(obj.Name)
        
        if Settings.EspRustyTraps and (string.find(n, "rusty") or string.find(n, "bear") or string.find(n, "trap")) and not string.find(n, "rake") and not string.find(n, "scrap") then
            CreateEspElements(obj, Color3.fromRGB(255, 140, 30), "РЖАВАЯ ЛОВУШКА", "EspRustyTraps")
        elseif Settings.EspRakeTraps and string.find(n, "trap") and string.find(n, "rake") then
            CreateEspElements(obj, Color3.fromRGB(255, 60, 120), "ЛОВУШКА С РЕЙКОМ", "EspRakeTraps")
        elseif Settings.EspFlareGun and (string.find(n, "flare gun") or string.find(n, "flaregun")) and not string.find(n, "note") then
            CreateEspElements(obj, Color3.fromRGB(255, 95, 40), "РАКЕТНИЦА", "EspFlareGun")
        elseif Settings.EspScrap and string.find(n, "scrap") then
            local root = GetObjectRoot(obj)
            if root and root.Size.Magnitude < 15 then
                CreateEspElements(obj, Color3.fromRGB(180, 185, 195), "ЛОМ", "EspScrap")
            end
        elseif Settings.EspSupplyDrop and (string.find(n, "supply") or string.find(n, "crate") or string.find(n, "airdrop")) and not string.find(n, "blood") then
            CreateEspElements(obj, Color3.fromRGB(255, 215, 50), "ЯЩИК С ПРИПАСАМИ", "EspSupplyDrop")
        elseif Settings.EspLocations and (obj:IsA("Model") or obj:IsA("Part")) then
            for key, label in pairs(LocationKeywords) do
                if string.find(n, key) then
                    CreateEspElements(obj, Color3.fromRGB(65, 210, 130), string.upper(label), "EspLocations")
                    break
                end
            end
        end
    end
end

local function SmoothScanWorkspace()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not scriptRunning then return end
        CheckObjectForESP(obj)
        count = count + 1
        if count % 250 == 0 then task.wait() end
    end
end

table.insert(Connections, Workspace.DescendantAdded:Connect(function(obj)
    if not scriptRunning then return end
    task.defer(function() CheckObjectForESP(obj) end)
end))

local function StripEffects()
    if not Settings.DisableEffects then return end
    for _, eff in ipairs(Lighting:GetChildren()) do
        if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") then eff.Enabled = false end
    end
    for _, eff in ipairs(Camera:GetChildren()) do
        if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") then eff.Enabled = false end
    end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetChildren()) do
            local n = string.lower(gui.Name)
            if string.find(n, "static") or string.find(n, "jumpscare") or string.find(n, "scare") or string.find(n, "vignette") or string.find(n, "blood") then
                if gui:IsA("ScreenGui") then gui.Enabled = false
                elseif gui:IsA("GuiObject") then gui.Visible = false end
            end
        end
    end
end

-- Управление объектами без привязки
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not Settings.ObjectControl then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local unitRay = Camera:ScreenPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local res = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)
        if res and res.Instance and not res.Instance.Anchored then
            DraggedObject = res.Instance
            DragDistance = (res.Position - Camera.CFrame.Position).Magnitude
        end
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        DraggedObject = nil
    end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(input, gp)
    if not Settings.Freecam then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or isMobile then
            local delta = input.Delta
            FreecamState.Angles = Vector2.new(
                math.clamp(FreecamState.Angles.X - delta.Y * 0.005, -math.pi/2.1, math.pi/2.1),
                FreecamState.Angles.Y - delta.X * 0.005
            )
        end
    end
end))

local function UpdateRakePath()
    ClearPathNodes()
    if not Settings.RakePathfind then return end
    local rake = GetRake()
    local char = LocalPlayer.Character
    if not rake or not char then return end
    
    local rakeRoot = GetObjectRoot(rake)
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not rakeRoot or not myRoot then return end

    local vel = rakeRoot.AssemblyLinearVelocity
    local targetPos = rakeRoot.Position + (vel.Magnitude > 1 and vel.Unit * 35 or rakeRoot.CFrame.LookVector * 35)
    local dist = (targetPos - rakeRoot.Position).Magnitude
    local beamPart = Instance.new("Part")
    beamPart.Name = "RakeHub_PathNode"
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Material = Enum.Material.Neon
    beamPart.Color = Color3.fromRGB(255, 60, 0)
    beamPart.Transparency = 0.25
    beamPart.Size = Vector3.new(0.25, 0.25, dist)
    beamPart.CFrame = CFrame.lookAt((rakeRoot.Position + targetPos) / 2, targetPos)
    beamPart.Parent = Workspace
    table.insert(PathNodes, beamPart)
end

-- УМНЫЙ NOCLIP БЕЗ ОТКАТА (Отключает коллизию тела + защита от провала под пол и серверного флага)
local TouchingWall = false
table.insert(Connections, RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    local char = LocalPlayer.Character
    if char and (Settings.Noclip or Settings.FlyEnabled) then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        -- Проверка стены перед игроком: плавно снижаем скорость внутри стены, чтобы серверный Raycast не откатил назад
        if root and hum and Settings.Noclip and not Settings.FlyEnabled and hum.MoveDirection.Magnitude > 0 then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local hit = Workspace:Raycast(root.Position, hum.MoveDirection * 2.5, rayParams)
            TouchingWall = (hit ~= nil and hit.Instance.CanCollide)
        else
            TouchingWall = false
        end
    else
        TouchingWall = false
    end

    if Settings.ObjectControl and DraggedObject and DraggedObject.Parent then
        local mousePos = UserInputService:GetMouseLocation()
        local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local targetPos = unitRay.Origin + unitRay.Direction * DragDistance
        DraggedObject.AssemblyLinearVelocity = (targetPos - DraggedObject.Position) * 12
        DraggedObject.AssemblyAngularVelocity = Vector3.zero
    end
end))

-- БЕЗОПАСНЫЙ ПОЛЕТ, СКОРОСТЬ И ПРЫЖОК БЕЗ СЕРВЕРНЫХ ТЕЛЕПОРТОВ (Heartbeat)
local pulseTimer = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    if not scriptRunning then return end
    
    local myChar = LocalPlayer.Character
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if Settings.InfiniteStamina then
        for _, tbl in ipairs(StaminaTables) do
            if rawget(tbl, "Stamina") then tbl.Stamina = 100 end
            if rawget(tbl, "stamina") then tbl.stamina = 100 end
            if rawget(tbl, "Exhausted") ~= nil then tbl.Exhausted = false end
        end
    end

    if hum and myRoot then
        -- 1. Умная скорость без откатов (Server-Safe WalkSpeed + Velocity Pulse)
        local targetSpd = GetTargetSpeed()
        if TouchingWall then
            -- Внутри стены ограничиваем скорость до 20, чтобы сервер не откатил назад
            hum.WalkSpeed = 20
        elseif targetSpd then
            hum.WalkSpeed = targetSpd
        elseif Settings.NoJerk and hum.WalkSpeed < 16 then
            hum.WalkSpeed = 16
        end

        -- Импульсный Speed Bypass (разгоняет через физическую инерцию в окнах между проверками сервера)
        if Settings.SpeedBypass and not TouchingWall and not Settings.FlyEnabled and hum.MoveDirection.Magnitude > 0 then
            pulseTimer = pulseTimer + dt
            local curVel = myRoot.AssemblyLinearVelocity
            -- Плавное физическое ускорение до порога 35 стадов/с (выше 36 сервер The Rake кидает назад)
            local boostSpd = (pulseTimer % 0.4 < 0.25) and 34.5 or 30.2
            myRoot.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * boostSpd, curVel.Y, hum.MoveDirection.Z * boostSpd)
        end

        -- 2. Безопасный прыжок (ограничение вертикального импульса, чтобы не срабатывал анти-флай сервера)
        if Settings.JumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = math.clamp(Settings.JumpPower, 35, 68)
        end

        -- 3. Умный Полет без BodyVelocity и без PlatformStand (Не триггерит серверный античит!)
        if Settings.FlyEnabled and not Settings.Freecam then
            if isMobile and not FreecamMobileFrame.Visible then
                FreecamMobileFrame.Visible = true
            end
            hum.PlatformStand = false -- PlatformStand = true вызывает мгновенный откат на сервере!
            
            local moveDir = hum.MoveDirection
            local yVel = 0.8 -- Компенсация гравитации при зависании в воздухе
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileMoveVec.Y > 0 then
                yVel = math.min(Settings.FlySpeed * 0.75, 24)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or MobileMoveVec.Y < 0 then
                yVel = -math.min(Settings.FlySpeed * 0.75, 24)
            end

            -- Безопасная горизонтальная скорость полета (до 30 стадов/с сервер не телепортирует назад)
            local safeFlySpd = math.min(Settings.FlySpeed, 30.2)
            myRoot.AssemblyLinearVelocity = Vector3.new(moveDir.X * safeFlySpd, yVel, moveDir.Z * safeFlySpd)
        elseif not Settings.Freecam and FreecamMobileFrame.Visible then
            FreecamMobileFrame.Visible = false
        end
    end

    if Settings.InstaKillRake then
        ExecuteRakeKill()
    end
end))

-- Фоновый поток обновления ESP и инструментов
local bgThread = task.spawn(function()
    while scriptRunning do
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if Settings.EspRake then
            local rake = GetRake()
            if rake then CreateEspElements(rake, Color3.fromRGB(255, 35, 35), "THE RAKE", "EspRake") end
        end

        if Settings.EspPlayers then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    CreateEspElements(p.Character, Color3.fromRGB(100, 200, 255), p.DisplayName, "EspPlayers")
                end
            end
        end

        for obj, data in pairs(EspCache) do
            if not obj or not obj.Parent or not Settings[data.Type] or data.UsedBox ~= Settings.BoxHandleAdornments then
                for _, v in ipairs(data.Elements) do if v then pcall(function() v:Destroy() end) end end
                EspCache[obj] = nil
            else
                data.Label.TextSize = Settings.EspTextSize
                local root = data.Root
                if root and root.Parent and myRoot then
                    local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                    local statsText = string.format("[%d м]", dist)
                    
                    if data.Type == "EspRake" or data.Type == "EspPlayers" then
                        local hp, maxHp = GetEntityHealth(obj)
                        if hp and maxHp then
                            statsText = string.format("HP: %d/%d | %d м", hp, maxHp, dist)
                        end
                    elseif data.Type == "EspScrap" then
                        local val = obj:FindFirstChild("Points") or obj:FindFirstChild("Value") or obj:FindFirstChild("Level")
                        if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
                            statsText = string.format("Очки: %s | %d м", tostring(val.Value), dist)
                        end
                    end
                    
                    data.Label.Text = data.Title .. "\n" .. statsText
                end
            end
        end

        if Settings.RakePathfind then pcall(UpdateRakePath) end
        if Settings.DisableEffects then pcall(StripEffects) end
        pcall(PatchTools)

        task.wait(0.25)
    end
end)
table.insert(Connections, bgThread)

local scanThread = task.spawn(function()
    while scriptRunning do
        if Settings.EspRustyTraps or Settings.EspRakeTraps or Settings.EspLocations or Settings.EspScrap or Settings.EspFlareGun or Settings.EspSupplyDrop then
            SmoothScanWorkspace()
        end
        task.wait(3)
    end
end)
table.insert(Connections, scanThread)

-- Цикл камеры (Freecam без Anchored, чтобы сервер не откатывал персонажа)
table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    if not scriptRunning then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root then
        if Settings.Freecam then
            if not FreecamState.Active then
                FreecamState.Active = true
                FreecamState.CFrame = Camera.CFrame
                local rx, ry, _ = Camera.CFrame:ToEulerAnglesYXZ()
                FreecamState.Angles = Vector2.new(rx, ry)
                Camera.CameraType = Enum.CameraType.Scriptable
                if isMobile then FreecamMobileFrame.Visible = true end
            end
            
            local moveInput = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveInput = moveInput + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveInput = moveInput + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveInput = moveInput + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveInput = moveInput + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveInput = moveInput + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveInput = moveInput + Vector3.new(0, -1, 0) end
            
            moveInput = moveInput + MobileMoveVec
            local rotCFrame = CFrame.fromEulerAnglesYXZ(FreecamState.Angles.X, FreecamState.Angles.Y, 0)
            local worldMove = rotCFrame:VectorToWorldSpace(moveInput)
            FreecamState.CFrame = CFrame.new(FreecamState.CFrame.Position + worldMove * FreecamState.Speed * dt) * rotCFrame
            Camera.CFrame = FreecamState.CFrame
        elseif FreecamState.Active then
            FreecamState.Active = false
            Camera.CameraType = Enum.CameraType.Custom
            if not Settings.FlyEnabled then FreecamMobileFrame.Visible = false end
        end
    end

    if Settings.UnlockZoom then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 500
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
    if Settings.FOVEnabled then
        Camera.FieldOfView = Settings.FOV
    end

    if Settings.NoFog or Settings.NightVision then
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
    end
    if Settings.NightVision then
        Lighting.Ambient = Color3.fromRGB(220, 220, 220)
        Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    end
end))

-- ============================================================================
-- ПОСТРОЕНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА
-- ============================================================================

CreateSection("Передвижение и Физика")
CreateElement("Быстрый бег (Стандарт 28)", function(s)
    Settings.FastSprint = s
    if not s and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end, false, Color3.fromRGB(65, 185, 120))
CreateElement("Speed Bypass (Бета) (Без отката)", function(s) Settings.SpeedBypass = s end, false)
CreateElement("Активировать Свою Скорость", function(s)
    Settings.WalkSpeedEnabled = s
    if not s and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end, false)
CreateSlider("Скорость", 14, 30.2, 24, 1, function(v) Settings.WalkSpeed = v end)
CreateElement("Активировать Высоту прыжка", function(s) Settings.JumpPowerEnabled = s end, false)
CreateSlider("Высота прыжка", 35, 100, 40, 0, function(v) Settings.JumpPower = v end)
CreateElement("Полет (Умный Fly без отката)", function(s) Settings.FlyEnabled = s end, false)
CreateSlider("Скорость полета", 10, 100, 28, 0, function(v) Settings.FlySpeed = v end)
CreateElement("Бесконечная выносливость", function(s)
    Settings.InfiniteStamina = s
    if s then CacheStaminaTables() end
end, false)
CreateElement("Без рывков (No Jerk)", function(s) Settings.NoJerk = s end, false)
CreateElement("Noclip (Сквозь стены без отката)", function(s)
    Settings.Noclip = s
    if not s and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso") then
                part.CanCollide = true
            end
        end
    end
end, false)

CreateSection("Бой и Предметы")
CreateElement("Рейк мгновенного убийства / Авто-урон", function(s) Settings.InstaKillRake = s end, false, Color3.fromRGB(255, 45, 45))
CreateElement("Сохранение предмета при возрождении", function(s) Settings.KeepItems = s end, false)
CreateElement("Дальность удара электрошокером", function(s) Settings.StunReach = s end, false)
CreateElement("Сокращение перезарядки шокера", function(s) Settings.StunNoCD = s end, false)
CreateElement("Без сбоев электрошокера (Эксп.)", function(s) Settings.StunNoFail = s end, false)
CreateElement("Управление объектами (Без привязки)", function(s) Settings.ObjectControl = s end, false)

CreateSection("ESP и Подсветка")
CreateSlider("Размер текста ESP", 6, 18, Settings.EspTextSize, 0, function(v) Settings.EspTextSize = v end)
CreateElement("Украшения для ручек ящиков (3D Box)", function(s) Settings.BoxHandleAdornments = s end, false)
CreateElement("ESP Рейк (Монстр)", function(s) Settings.EspRake = s end, false, Color3.fromRGB(255, 35, 35))
CreateElement("Rake Pathfind (Прогнозирует маршрут)", function(s)
    Settings.RakePathfind = s
    if not s then ClearPathNodes() end
end, false, Color3.fromRGB(255, 80, 30))
CreateElement("ESP Игроки", function(s) Settings.EspPlayers = s end, false)
CreateElement("ESP Ржавые ловушки", function(s)
    Settings.EspRustyTraps = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)
CreateElement("ESP Ловушки с рейком", function(s)
    Settings.EspRakeTraps = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)
CreateElement("ESP Места (Локации)", function(s)
    Settings.EspLocations = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)
CreateElement("ESP Обломки (Лом)", function(s)
    Settings.EspScrap = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)
CreateElement("ESP Ракетница", function(s)
    Settings.EspFlareGun = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)
CreateElement("ESP Ящик с припасами", function(s)
    Settings.EspSupplyDrop = s
    if s then task.spawn(SmoothScanWorkspace) end
end, false)

CreateSection("Камера и Визуал")
CreateElement("Бесплатная камера (ПК + Мобильная)", function(s) Settings.Freecam = s end, false)
CreateElement("Разблокировать зум (3-е лицо)", function(s) Settings.UnlockZoom = s end, false)
CreateElement("Изменить Поле зрения (FOV)", function(s) Settings.FOVEnabled = s end, false)
CreateSlider("Поле зрения (FOV)", 1, 120, 75, 0, function(v) Settings.FOV = v end)
CreateElement("Отключить пугающие эффекты и тряску", function(s) Settings.DisableEffects = s end, false)
CreateElement("Ночное зрение и Без тумана", function(s)
    Settings.NightVision = s
    Settings.NoFog = s
end, false)

CreateSection("Система")
CreateElement("Удалить Скрипт", DestroyScript, true, Color3.fromRGB(255, 65, 65))
