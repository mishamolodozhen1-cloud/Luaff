-- Rake Hub-Beta [DELTA X + TRAP OUTLINE FIX + 100% FLY/NOCLIP + DAY/NIGHT TIMER + 410 DMG 1-HIT]
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = Workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local WIDTH = isMobile and 280 or 350
local HEIGHT = isMobile and 350 or 460
local TEXT_SM = isMobile and 11 or 13
local TEXT_MD = isMobile and 12 or 14
local TEXT_LG = isMobile and 14 or 18
local ELEMENT_H = isMobile and 32 or 36
local SLIDER_H = isMobile and 44 or 50

local Settings = {
    NightVision = false, NoFog = false,
    FastSprint = false,
    WalkSpeedEnabled = false, WalkSpeed = 24, -- Регулировка 20 - 60
    SpeedBypass = false,
    JumpPowerEnabled = false, JumpPower = 40,
    FlyEnabled = false, FlySpeed = 35,
    NoJerk = false, Noclip = false, InfiniteStamina = false,
    KeepItems = false, InstaKillRake = false,
    StunReach = false, StunNoCD = false, StunNoFail = false,
    ObjectControl = false,
    UnlockZoom = false, ThirdPersonDist = 18,
    FOVEnabled = false, FOV = 75,
    DisableEffects = false, Freecam = false, RakePathfind = false,
    ShowTimer = true,
    EspTextSize = isMobile and 8 or 9,
    BoxHandleAdornments = false,
    EspRake = false, EspPlayers = false,
    EspRustyTraps = false, EspRakeTraps = false,
    EspLocations = false, EspScrap = false,
    EspFlareGun = false, EspSupplyDrop = false
}

-- Сохранение оригинального освещения для возврата красок
local SavedLighting = {
    Captured = false,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows,
    Effects = {}
}

local function CaptureOriginalLighting()
    if SavedLighting.Captured then return end
    SavedLighting.Captured = true
    SavedLighting.Ambient = Lighting.Ambient
    SavedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    SavedLighting.Brightness = Lighting.Brightness
    SavedLighting.ClockTime = Lighting.ClockTime
    SavedLighting.FogStart = Lighting.FogStart
    SavedLighting.FogEnd = Lighting.FogEnd
    SavedLighting.FogColor = Lighting.FogColor
    SavedLighting.GlobalShadows = Lighting.GlobalShadows
    SavedLighting.Effects = {}
    for _, eff in ipairs(Lighting:GetChildren()) do
        if eff:IsA("PostEffect") then SavedLighting.Effects[eff] = eff.Enabled
        elseif eff:IsA("Atmosphere") then SavedLighting.Effects[eff] = eff.Density end
    end
end

local function RestoreOriginalLighting()
    if not SavedLighting.Captured then return end
    Lighting.Ambient = SavedLighting.Ambient
    Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient
    Lighting.Brightness = SavedLighting.Brightness
    Lighting.ClockTime = SavedLighting.ClockTime
    Lighting.FogStart = SavedLighting.FogStart
    Lighting.FogEnd = SavedLighting.FogEnd
    Lighting.FogColor = SavedLighting.FogColor
    Lighting.GlobalShadows = SavedLighting.GlobalShadows
    for obj, val in pairs(SavedLighting.Effects) do
        if obj and obj.Parent then
            if obj:IsA("PostEffect") then obj.Enabled = val
            elseif obj:IsA("Atmosphere") then obj.Density = val end
        end
    end
    SavedLighting.Captured = false
end

local LanguagesList = {
    "Русский (Russian)", "English", "Español (Spanish)", "Deutsch (German)",
    "Français (French)", "Português (Portuguese)", "Türkçe (Turkish)",
    "Українська (Ukrainian)", "Polski (Polish)", "Italiano (Italian)"
}

local EspCache, Connections, CharConnections, SavedTools, PathNodes, StaminaTables = {}, {}, {}, {}, {}, {}
local RegisteredLocations = {}
local MutedSounds = {}
local FileName = "RakeHubBeta_SavedName.txt"
local isMenuOpen = false
local scriptRunning = true
local FreecamState = {Active = false, CFrame = CFrame.new(), Angles = Vector2.new(), Speed = 45}
local DraggedObject, DragDistance = nil, 15
local FlyPosition = nil

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
    local ok, res = pcall(function()
        if isfile and readfile and isfile(FileName) then
            local n = readfile(FileName)
            if n and string.gsub(n, "%s+", "") ~= "" then return n end
        end
        return nil
    end)
    return ok and res or nil
end

local function SaveName(name)
    pcall(function() if writefile then writefile(FileName, tostring(name)) end end)
end

local GuiParent = nil
pcall(function() if gethui then GuiParent = gethui() end end)
if not GuiParent then pcall(function() GuiParent = CoreGui end) end
if not GuiParent then GuiParent = LocalPlayer:WaitForChild("PlayerGui") end

for _, old in ipairs(GuiParent:GetChildren()) do
    if old.Name == "RakeHub_Beta_UI" then pcall(function() old:Destroy() end) end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakeHub_Beta_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = GuiParent

local function AddCornerAndStroke(inst, radius, strokeCol, strokeTrans)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, radius or 6)
    if strokeCol then
        local s = Instance.new("UIStroke", inst)
        s.Color = strokeCol
        s.Transparency = strokeTrans or 0
        return s
    end
end

-- ============================================================================
-- ТАЙМЕР ДНЯ И НОЧИ НАВЕРХУ ЭКРАНА
-- ============================================================================
local TimerFrame = Instance.new("Frame", ScreenGui)
TimerFrame.Size = UDim2.new(0, 190, 0, 32)
TimerFrame.Position = UDim2.new(0.5, -95, 0, 10)
TimerFrame.BackgroundColor3 = Colors.Background
TimerFrame.BackgroundTransparency = 0.15
TimerFrame.Visible = Settings.ShowTimer
AddCornerAndStroke(TimerFrame, 8, Colors.Stroke)

local TimerLabel = Instance.new("TextLabel", TimerFrame)
TimerLabel.Size = UDim2.new(1, 0, 1, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.RichText = true
TimerLabel.Text = "ВРЕМЯ: <font color='#D23741'>--:--</font>"
TimerLabel.TextColor3 = Colors.TextWhite
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = TEXT_SM

local function FormatSeconds(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    return string.format("%02d:%02d", math.floor(sec / 60), sec % 60)
end

local function UpdateDayNightTimer()
    if not TimerFrame.Visible then return end
    -- Попытка считать точный серверный таймер из ReplicatedStorage / Workspace
    local timerVal = ReplicatedStorage:FindFirstChild("Timer", true) or ReplicatedStorage:FindFirstChild("TimeLeft", true) or Workspace:FindFirstChild("Timer", true)
    local nightVal = ReplicatedStorage:FindFirstChild("Night", true) or ReplicatedStorage:FindFirstChild("IsNight", true)
    local clock = Lighting.ClockTime
    local isNight = (nightVal and nightVal:IsA("BoolValue") and nightVal.Value) or (clock >= 18 or clock < 6)

    if timerVal and (timerVal:IsA("IntValue") or timerVal:IsA("NumberValue")) then
        local phaseText = isNight and "<font color='#FF4545'>НОЧЬ</font>" or "<font color='#55FF88'>ДЕНЬ</font>"
        TimerLabel.Text = phaseText .. " | " .. FormatSeconds(timerVal.Value)
    elseif timerVal and timerVal:IsA("StringValue") and timerVal.Value ~= "" then
        local phaseText = isNight and "<font color='#FF4545'>НОЧЬ</font>" or "<font color='#55FF88'>ДЕНЬ</font>"
        TimerLabel.Text = phaseText .. " | " .. timerVal.Value
    else
        -- Расчет игрового времени и оставшегося времени до смены фазы по ClockTime
        local h = math.floor(clock)
        local m = math.floor((clock - h) * 60)
        local gameTimeStr = string.format("%02d:%02d", h, m)
        local hoursLeft = isNight and ((clock >= 18) and (24 - clock + 6) or (6 - clock)) or (18 - clock)
        local approxSec = math.floor(hoursLeft * 30) -- ~30 сек на 1 игровой час в The Rake
        local phaseText = isNight and "<font color='#FF4545'>НОЧЬ</font>" or "<font color='#55FF88'>ДЕНЬ</font>"
        TimerLabel.Text = phaseText .. " (" .. gameTimeStr .. ") ~" .. FormatSeconds(approxSec)
    end
end

local function ClearPathNodes()
    for _, node in ipairs(PathNodes) do if node and node.Parent then node:Destroy() end end
    table.clear(PathNodes)
end

local function ClearCharConnections()
    for _, conn in ipairs(CharConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(CharConnections)
end

local function RestoreCollisions()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head") then
            part.CanCollide = true
        end
    end
end

local function RestoreMutedSounds()
    for snd, vol in pairs(MutedSounds) do
        if snd and snd.Parent then pcall(function() snd.Volume = vol end) end
    end
    table.clear(MutedSounds)
end

local function DestroyScript()
    scriptRunning = false
    ClearCharConnections()
    pcall(function() RunService:UnbindFromRenderStep("RakeHub_CamAndNoclip") end)
    for _, conn in ipairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect()
        elseif type(conn) == "thread" then pcall(task.cancel, conn) end
    end
    for _, data in pairs(EspCache) do
        for _, v in ipairs(data.Elements) do pcall(function() v:Destroy() end) end
    end
    EspCache = {}
    RegisteredLocations = {}
    ClearPathNodes()
    RestoreOriginalLighting()
    RestoreCollisions()
    RestoreMutedSounds()
    Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = 70
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    LocalPlayer.CameraMaxZoomDistance = 0.5
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.CameraOffset = Vector3.zero end
    end
    if ScreenGui then ScreenGui:Destroy() end
end

-- Мобильная кнопка меню
local MobileToggleBtn = Instance.new("TextButton", ScreenGui)
MobileToggleBtn.Size = UDim2.new(0, 46, 0, 46)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -23)
MobileToggleBtn.BackgroundColor3 = Colors.Panel
MobileToggleBtn.Text = "RH"
MobileToggleBtn.TextColor3 = Colors.TextWhite
MobileToggleBtn.Font = Enum.Font.GothamBlack
MobileToggleBtn.TextSize = 18
MobileToggleBtn.Visible = false
AddCornerAndStroke(MobileToggleBtn, 12, Colors.Stroke)

-- Экранные кнопки для Полета и Freecam
local FreecamMobileFrame = Instance.new("Frame", ScreenGui)
FreecamMobileFrame.Size = UDim2.new(0, 130, 0, 130)
FreecamMobileFrame.Position = UDim2.new(0, 25, 1, -165)
FreecamMobileFrame.BackgroundTransparency = 0.4
FreecamMobileFrame.BackgroundColor3 = Colors.Background
FreecamMobileFrame.Visible = false
AddCornerAndStroke(FreecamMobileFrame, 12, Colors.Stroke)

local MobileMoveVec = Vector3.zero
local function CreateFCBtn(txt, pos, dir)
    local b = Instance.new("TextButton", FreecamMobileFrame)
    b.Size = UDim2.new(0, 36, 0, 36); b.Position = pos
    b.BackgroundColor3 = Colors.Panel; b.Text = txt
    b.TextColor3 = Colors.TextWhite; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    AddCornerAndStroke(b, 6)
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

local function MakeDraggable(dragHandle, targetFrame)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = targetFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end
MakeDraggable(MobileToggleBtn, MobileToggleBtn)
MakeDraggable(TimerFrame, TimerFrame)

-- Экраны загрузки, языка, имени и меню
local LoadFrame = Instance.new("Frame", ScreenGui)
LoadFrame.Size = UDim2.new(0, WIDTH, 0, 100)
LoadFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -50)
LoadFrame.BackgroundColor3 = Colors.Background
LoadFrame.ClipsDescendants = true
AddCornerAndStroke(LoadFrame, 8, Colors.Stroke)

local LoadTitle = Instance.new("TextLabel", LoadFrame)
LoadTitle.Size = UDim2.new(1, 0, 0, 30); LoadTitle.Position = UDim2.new(0, 0, 0, 15)
LoadTitle.BackgroundTransparency = 1; LoadTitle.RichText = true
LoadTitle.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
LoadTitle.TextColor3 = Colors.TextWhite; LoadTitle.Font = Enum.Font.GothamBlack; LoadTitle.TextSize = TEXT_LG

local PercentText = Instance.new("TextLabel", LoadFrame)
PercentText.Size = UDim2.new(1, 0, 0, 20); PercentText.Position = UDim2.new(0, 0, 0, 42)
PercentText.BackgroundTransparency = 1; PercentText.Text = "Инициализация... 0%"
PercentText.TextColor3 = Colors.TextGray; PercentText.Font = Enum.Font.GothamMedium; PercentText.TextSize = TEXT_SM

local LoadBarBg = Instance.new("Frame", LoadFrame)
LoadBarBg.Size = UDim2.new(0.86, 0, 0, 4); LoadBarBg.Position = UDim2.new(0.07, 0, 0.75, 0)
LoadBarBg.BackgroundColor3 = Colors.Panel
AddCornerAndStroke(LoadBarBg, 8)

local LoadBar = Instance.new("Frame", LoadBarBg)
LoadBar.Size = UDim2.new(0, 0, 1, 0); LoadBar.BackgroundColor3 = Colors.Accent
AddCornerAndStroke(LoadBar, 8)

local LangFrame = Instance.new("Frame", ScreenGui)
LangFrame.Size = UDim2.new(0, WIDTH, 0, 260)
LangFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -130)
LangFrame.BackgroundColor3 = Colors.Background
LangFrame.Visible = false; LangFrame.ClipsDescendants = true
AddCornerAndStroke(LangFrame, 8, Colors.Stroke)

local LangTitle = Instance.new("TextLabel", LangFrame)
LangTitle.Size = UDim2.new(1, 0, 0, 25); LangTitle.Position = UDim2.new(0, 0, 0, 10)
LangTitle.BackgroundTransparency = 1; LangTitle.Text = "ВЫБЕРИТЕ ЯЗЫК"
LangTitle.TextColor3 = Colors.TextWhite; LangTitle.Font = Enum.Font.GothamBold; LangTitle.TextSize = TEXT_MD

local LangContainer = Instance.new("ScrollingFrame", LangFrame)
LangContainer.Size = UDim2.new(0.86, 0, 0, 155); LangContainer.Position = UDim2.new(0.07, 0, 0, 42)
LangContainer.BackgroundTransparency = 1; LangContainer.ScrollBarThickness = 3
local LangListLayout = Instance.new("UIListLayout", LangContainer)
LangListLayout.Padding = UDim.new(0, 4)

local LangConfirmBtn = Instance.new("TextButton", LangFrame)
LangConfirmBtn.Size = UDim2.new(0.86, 0, 0, 34); LangConfirmBtn.Position = UDim2.new(0.07, 0, 0, 210)
LangConfirmBtn.BackgroundColor3 = Colors.Accent; LangConfirmBtn.Text = "ПОДТВЕРДИТЬ"
LangConfirmBtn.TextColor3 = Colors.TextWhite; LangConfirmBtn.Font = Enum.Font.GothamBold; LangConfirmBtn.TextSize = TEXT_SM
AddCornerAndStroke(LangConfirmBtn, 6)

local SelectedLangBtn = nil
for _, langName in ipairs(LanguagesList) do
    local Btn = Instance.new("TextButton", LangContainer)
    Btn.Size = UDim2.new(1, 0, 0, 26); Btn.BackgroundColor3 = Colors.Panel
    Btn.Text = langName; Btn.TextColor3 = Colors.TextGray; Btn.Font = Enum.Font.GothamMedium; Btn.TextSize = TEXT_SM
    AddCornerAndStroke(Btn, 4, Colors.Stroke, 0.5)
    Btn.MouseButton1Click:Connect(function()
        if SelectedLangBtn then SelectedLangBtn.BackgroundColor3 = Colors.Panel; SelectedLangBtn.TextColor3 = Colors.TextGray end
        SelectedLangBtn = Btn; Btn.BackgroundColor3 = Colors.Accent; Btn.TextColor3 = Colors.TextWhite
    end)
end
LangContainer.CanvasSize = UDim2.new(0, 0, 0, #LanguagesList * 30 + 10)

local NameFrame = Instance.new("Frame", ScreenGui)
NameFrame.Size = UDim2.new(0, WIDTH, 0, 190)
NameFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -95)
NameFrame.BackgroundColor3 = Colors.Background
NameFrame.Visible = false; NameFrame.ClipsDescendants = true
AddCornerAndStroke(NameFrame, 8, Colors.Stroke)

local AskLabel = Instance.new("TextLabel", NameFrame)
AskLabel.Size = UDim2.new(1, 0, 0, 20); AskLabel.Position = UDim2.new(0, 0, 0, 28)
AskLabel.BackgroundTransparency = 1; AskLabel.Text = "Введите ваше имя"
AskLabel.TextColor3 = Colors.TextWhite; AskLabel.Font = Enum.Font.GothamBold; AskLabel.TextSize = TEXT_MD

local NameInput = Instance.new("TextBox", NameFrame)
NameInput.Size = UDim2.new(0.86, 0, 0, 36); NameInput.Position = UDim2.new(0.07, 0, 0, 65)
NameInput.BackgroundColor3 = Colors.Panel; NameInput.PlaceholderText = "Имя пользователя..."
NameInput.PlaceholderColor3 = Colors.TextGray; NameInput.Text = ""
NameInput.TextColor3 = Colors.TextWhite; NameInput.Font = Enum.Font.GothamMedium; NameInput.TextSize = TEXT_MD
AddCornerAndStroke(NameInput, 6, Colors.Stroke)

local SubmitBtn = Instance.new("TextButton", NameFrame)
SubmitBtn.Size = UDim2.new(0.86, 0, 0, 34); SubmitBtn.Position = UDim2.new(0.07, 0, 0, 120)
SubmitBtn.BackgroundColor3 = Colors.Accent; SubmitBtn.Text = "ВОЙТИ"
SubmitBtn.TextColor3 = Colors.TextWhite; SubmitBtn.Font = Enum.Font.GothamBold; SubmitBtn.TextSize = TEXT_MD
AddCornerAndStroke(SubmitBtn, 6)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
MainFrame.Position = UDim2.new(0.5, -(WIDTH/2), 0.5, -(HEIGHT/2))
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.Active = true; MainFrame.Visible = false; MainFrame.ClipsDescendants = true
AddCornerAndStroke(MainFrame, 8, Colors.Stroke)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40); TopBar.BackgroundColor3 = Colors.Panel; TopBar.Active = true
AddCornerAndStroke(TopBar, 8)
MakeDraggable(TopBar, MainFrame)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -40, 1, 0); Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1; Title.RichText = true
Title.Text = "RAKE HUB <font color='#D23741'>BETA</font>"
Title.TextColor3 = Colors.TextWhite; Title.TextSize = TEXT_MD; Title.Font = Enum.Font.GothamBlack
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton", TopBar)
CloseButton.Size = UDim2.new(0, 40, 0, 40); CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundTransparency = 1; CloseButton.Text = "X"
CloseButton.TextColor3 = Colors.TextGray; CloseButton.TextSize = 16; CloseButton.Font = Enum.Font.GothamBold
CloseButton.MouseButton1Click:Connect(DestroyScript)

local Container = Instance.new("ScrollingFrame", MainFrame)
Container.Size = UDim2.new(1, -16, 1, -52); Container.Position = UDim2.new(0, 8, 0, 44)
Container.BackgroundTransparency = 1; Container.ScrollBarThickness = 3
Container.ScrollBarImageColor3 = Colors.Stroke
local UIListLayout = Instance.new("UIListLayout", Container)
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function UpdateCanvas()
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 14)
end

local function CreateSection(titleText)
    local Wrapper = Instance.new("Frame", Container)
    Wrapper.Size = UDim2.new(1, 0, 0, 22); Wrapper.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Wrapper)
    Label.Size = UDim2.new(1, -12, 1, 0); Label.Position = UDim2.new(0, 6, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = string.upper(titleText)
    Label.TextColor3 = Colors.Accent; Label.TextSize = TEXT_SM; Label.Font = Enum.Font.GothamBlack
    Label.TextXAlignment = Enum.TextXAlignment.Left
    UpdateCanvas()
end

local function CreateElement(text, callback, isAction, customColor, defaultOn)
    local Wrapper = Instance.new("Frame", Container)
    Wrapper.Size = UDim2.new(1, 0, 0, ELEMENT_H); Wrapper.BackgroundTransparency = 1

    local Element = Instance.new("TextButton", Wrapper)
    Element.Size = UDim2.new(1, 0, 1, 0); Element.BackgroundColor3 = Colors.Panel
    Element.Text = ""; Element.AutoButtonColor = false
    AddCornerAndStroke(Element, 6, Colors.Stroke)

    local Label = Instance.new("TextLabel", Element)
    Label.Size = isAction and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -46, 1, 0)
    Label.Position = isAction and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1; Label.Text = text
    Label.TextColor3 = (isAction or defaultOn) and (customColor or Colors.TextWhite) or Colors.TextGray
    Label.TextSize = TEXT_SM; Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = isAction and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

    if not isAction then
        local activeColor = customColor or Colors.Accent
        local SwitchBg = Instance.new("Frame", Element)
        SwitchBg.Size = UDim2.new(0, 34, 0, 18); SwitchBg.Position = UDim2.new(1, -42, 0.5, -9)
        SwitchBg.BackgroundColor3 = defaultOn and activeColor or Colors.Background
        local SwitchStroke = AddCornerAndStroke(SwitchBg, 10, defaultOn and activeColor or Colors.Stroke)

        local Knob = Instance.new("Frame", SwitchBg)
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.Position = defaultOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        Knob.BackgroundColor3 = defaultOn and Colors.TextWhite or Colors.TextGray
        AddCornerAndStroke(Knob, 10)

        local Enabled = defaultOn or false
        Element.MouseButton1Click:Connect(function()
            Enabled = not Enabled
            TweenService:Create(Knob, TweenInfo.new(0.25), {
                Position = Enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Enabled and Colors.TextWhite or Colors.TextGray
            }):Play()
            TweenService:Create(SwitchBg, TweenInfo.new(0.25), {BackgroundColor3 = Enabled and activeColor or Colors.Background}):Play()
            TweenService:Create(SwitchStroke, TweenInfo.new(0.25), {Color = Enabled and activeColor or Colors.Stroke}):Play()
            TweenService:Create(Label, TweenInfo.new(0.25), {TextColor3 = Enabled and Colors.TextWhite or Colors.TextGray}):Play()
            callback(Enabled)
        end)
    else
        Element.MouseButton1Click:Connect(callback)
    end
    UpdateCanvas()
end

local function CreateSlider(text, minVal, maxVal, defaultVal, decimals, callback)
    local Wrapper = Instance.new("Frame", Container)
    Wrapper.Size = UDim2.new(1, 0, 0, SLIDER_H); Wrapper.BackgroundTransparency = 1

    local Element = Instance.new("Frame", Wrapper)
    Element.Size = UDim2.new(1, 0, 1, 0); Element.BackgroundColor3 = Colors.Panel
    AddCornerAndStroke(Element, 6, Colors.Stroke)

    local Label = Instance.new("TextLabel", Element)
    Label.Size = UDim2.new(1, -24, 0, 20); Label.Position = UDim2.new(0, 12, 0, 5)
    Label.BackgroundTransparency = 1; Label.Text = text .. ": " .. tostring(defaultVal)
    Label.TextColor3 = Colors.TextWhite; Label.TextSize = TEXT_SM; Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local SliderBg = Instance.new("Frame", Element)
    SliderBg.Size = UDim2.new(1, -24, 0, 6); SliderBg.Position = UDim2.new(0, 12, 0, 30)
    SliderBg.BackgroundColor3 = Colors.Background
    AddCornerAndStroke(SliderBg, 8, Colors.Stroke)

    local Fill = Instance.new("Frame", SliderBg)
    Fill.Size = UDim2.new(math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0)
    Fill.BackgroundColor3 = Colors.Accent
    AddCornerAndStroke(Fill, 8)

    local sliding = false
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        local mult = 10 ^ (decimals or 0)
        local val = math.floor((minVal + (maxVal - minVal) * pos) * mult + 0.5) / mult
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Label.Text = text .. ": " .. tostring(val)
        callback(val)
    end
    SliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true; UpdateSlider(inp)
        end
    end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(inp)
        end
    end))
    UpdateCanvas()
end

-- ============================================================================
-- ЯДРО ESP (ИСПРАВЛЕНА ОБВОДКА КАПКАНОВ — ЛИМИТ 31 HIGHLIGHT БОЛЬШЕ НЕ ЗАБИВАЕТСЯ!)
-- ============================================================================

local CachedRake = nil
local function GetRake()
    if CachedRake and CachedRake.Parent then return CachedRake end
    local r = Workspace:FindFirstChild("Rake") or Workspace:FindFirstChild("Monster")
    if r and r:IsA("Model") then CachedRake = r; return r end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local n = string.lower(obj.Name)
            if string.find(n, "rake") or string.find(n, "monster") or obj:FindFirstChild("Monster") then
                CachedRake = obj; return obj
            end
        end
    end
    return nil
end

local function GetEntityHealth(model)
    if not model then return nil, nil end
    local hum = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Monster")
    if hum and hum:IsA("Humanoid") then return math.floor(hum.Health), math.floor(hum.MaxHealth) end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Humanoid") then return math.floor(child.Health), math.floor(child.MaxHealth)
        elseif (child:IsA("NumberValue") or child:IsA("IntValue")) and string.lower(child.Name) == "health" then
            local m = model:FindFirstChild("MaxHealth")
            return math.floor(child.Value), m and math.floor(m.Value) or 1000
        end
    end
    return nil, nil
end

local function GetObjectRoot(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChild("HitBox") or obj:FindFirstChild("Scrap") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function CreateEspElements(object, color, titleText, espType, extraValueObj)
    if not object or EspCache[object] then return end
    local rootPart = GetObjectRoot(object)
    if not rootPart then return end
    local elements = {}

    local isTrap = (espType == "EspRustyTraps" or espType == "EspRakeTraps")
    local isScrap = (espType == "EspScrap")

    -- Для металла всегда используем BoxHandleAdornment, чтобы не забивать лимит 31 Highlight в Roblox!
    -- Для капканов ставим и Highlight (привязанный напрямую к объекту), и 3D-обводку BoxHandleAdornment, чтобы капкан было видно 100% всегда!
    if Settings.BoxHandleAdornments or isScrap or isTrap then
        local Box = Instance.new("BoxHandleAdornment", ScreenGui)
        Box.Name = "RakeHubESP_Box"
        Box.Adornee = rootPart
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Size = (object:IsA("Model") and object:GetExtentsSize() or rootPart.Size) + Vector3.new(0.2, 0.2, 0.2)
        Box.Color3 = color
        Box.Transparency = isTrap and 0.35 or 0.55
        table.insert(elements, Box)
    end

    if (not Settings.BoxHandleAdornments and not isScrap and espType ~= "EspLocations") or isTrap then
        local Highlight = Instance.new("Highlight")
        Highlight.Name = "RakeHubESP_HL"
        Highlight.FillColor = color
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = isTrap and 0.35 or 0.55
        Highlight.OutlineTransparency = 0
        Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        Highlight.Adornee = object
        Highlight.Parent = object -- Прямой родитель гарантирует отрисовку контура на моделях и MeshPart капканов
        table.insert(elements, Highlight)
    end

    local Billboard = Instance.new("BillboardGui", ScreenGui)
    Billboard.Name = "RakeHubESP_BB"; Billboard.AlwaysOnTop = true; Billboard.MaxDistance = 2500
    Billboard.Size = UDim2.new(0, 150, 0, 30); Billboard.StudsOffset = Vector3.new(0, 2.5, 0); Billboard.Adornee = rootPart

    local Label = Instance.new("TextLabel", Billboard)
    Label.Size = UDim2.new(1, 0, 1, 0); Label.BackgroundTransparency = 1; Label.Text = titleText
    Label.TextColor3 = color; Label.TextStrokeTransparency = 0.15; Label.TextStrokeColor3 = Color3.new(0, 0, 0)
    Label.TextSize = Settings.EspTextSize; Label.Font = Enum.Font.GothamBold
    table.insert(elements, Billboard)

    EspCache[object] = {
        Elements = elements,
        Type = espType,
        Title = titleText,
        Label = Label,
        Root = rootPart,
        ValueObj = extraValueObj,
        UsedBox = Settings.BoxHandleAdornments
    }
end

local function TryAddRealScrapESP(obj)
    if not Settings.EspScrap or not obj or not obj.Parent then return false end
    if obj:IsA("BasePart") and string.lower(obj.Name) == "scrap" and obj.Transparency < 0.9 and obj.Size.Magnitude < 12 then
        local parentModel = (obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
        local pts = parentModel:FindFirstChild("PointsVal") or parentModel:FindFirstChild("Points") or parentModel:FindFirstChild("LevelVal") or obj:FindFirstChild("PointsVal")
        CreateEspElements(obj, Color3.fromRGB(170, 215, 255), "ЖЕЛЕЗО (ЛОМ)", "EspScrap", pts)
        return true
    end
    return false
end

local ExactLocations = {
    ["shop"] = "МАГАЗИН (SHOP)",
    ["tower"] = "ВЫШКА (TOWER)",
    ["observationtower"] = "ВЫШКА (TOWER)",
    ["safehouse"] = "УБЕЖИЩЕ (SAFE HOUSE)",
    ["cabin"] = "УБЕЖИЩЕ (SAFE HOUSE)",
    ["powerstation"] = "ЭЛЕКТРОСТАНЦИЯ (POWER)",
    ["power"] = "ЭЛЕКТРОСТАНЦИЯ (POWER)"
}

local function CheckObjectForESP(obj)
    if not obj or not obj.Parent then return end
    if TryAddRealScrapESP(obj) then return end

    local n = string.lower(obj.Name)
    local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""

    -- Ящик с припасами
    if Settings.EspSupplyDrop then
        if string.find(parentName, "supply") or string.find(n, "supplycrate") or string.find(n, "supplydrop") or parentName == "supplycrates" or obj:FindFirstChild("GUILock") then
            local crateModel = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
            CreateEspElements(crateModel, Color3.fromRGB(255, 215, 50), "ЯЩИК С ПРИПАСАМИ", "EspSupplyDrop")
            return
        end
    end

    -- Капканы и ловушки (находит саму модель или меш капкана и вешает на неё яркую обводку)
    if Settings.EspRakeTraps or Settings.EspRustyTraps then
        local isTrap = (string.find(n, "trap") or string.find(n, "beartrap") or obj:FindFirstChild("Open") or obj:FindFirstChild("Armed") or obj:FindFirstChild("HitBox"))
        if isTrap and not string.find(n, "scrap") and not string.find(n, "spawn") and not string.find(n, "folder") and not obj:IsA("Folder") then
            local trapModel = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace and not string.find(string.lower(obj.Parent.Name), "debris") and not string.find(string.lower(obj.Parent.Name), "traps")) and obj.Parent or obj
            local root = GetObjectRoot(trapModel)
            if root then
                local tn = string.lower(trapModel.Name)
                if (string.find(tn, "rake") or string.find(n, "rake")) and Settings.EspRakeTraps then
                    CreateEspElements(trapModel, Color3.fromRGB(255, 40, 110), "ЛОВУШКА С РЕЙКОМ", "EspRakeTraps")
                elseif not string.find(tn, "rake") and not string.find(n, "rake") and Settings.EspRustyTraps then
                    CreateEspElements(trapModel, Color3.fromRGB(255, 140, 20), "КАПКАН", "EspRustyTraps")
                end
                return
            end
        end
    end

    -- Ракетница
    if Settings.EspFlareGun then
        if (n == "flaregun" or n == "flaregunpickup" or string.find(n, "flare gun")) and not string.find(n, "note") then
            local flareTarget = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
            CreateEspElements(flareTarget, Color3.fromRGB(255, 90, 40), "РАКЕТНИЦА", "EspFlareGun")
            return
        end
    end

    -- Локации
    if Settings.EspLocations and (obj:IsA("Model") or parentName == "locationpoints") then
        local cleanName = string.gsub(n, "%s+", "")
        for key, label in pairs(ExactLocations) do
            if string.find(cleanName, key) then
                if not RegisteredLocations[label] or not RegisteredLocations[label].Parent then
                    RegisteredLocations[label] = obj
                    CreateEspElements(obj, Color3.fromRGB(65, 220, 130), label, "EspLocations")
                end
                return
            end
        end
    end
end

local function ScanRakeFolders()
    if not Settings.EspLocations then table.clear(RegisteredLocations) end
    local filterFolder = Workspace:FindFirstChild("Filter")
    local debrisFolder = Workspace:FindFirstChild("Debris")
    if filterFolder then
        for _, v in ipairs(filterFolder:GetDescendants()) do
            if not scriptRunning then return end
            CheckObjectForESP(v)
        end
    end
    if debrisFolder then
        for _, v in ipairs(debrisFolder:GetDescendants()) do
            if not scriptRunning then return end
            CheckObjectForESP(v)
        end
    end
    for _, v in ipairs(Workspace:GetChildren()) do
        if not scriptRunning then return end
        CheckObjectForESP(v)
    end
end

table.insert(Connections, Workspace.DescendantAdded:Connect(function(obj)
    if scriptRunning then
        task.delay(0.15, function() CheckObjectForESP(obj) end)
    end
end))

-- ============================================================================
-- ОТКЛЮЧЕНИЕ СТРАХА, СЕРДЦЕБИЕНИЯ, ТРЯСКИ И ЗАСТАВОК
-- ============================================================================
local FearSoundKeywords = {"heartbeat", "heart", "panic", "scare", "jumpscare", "static", "chase", "terror", "fear", "breathing", "shock"}

local function MuteFearSound(snd)
    if not snd:IsA("Sound") then return end
    local n = string.lower(snd.Name)
    for _, kw in ipairs(FearSoundKeywords) do
        if string.find(n, kw) then
            if MutedSounds[snd] == nil then MutedSounds[snd] = snd.Volume end
            snd.Volume = 0
            snd.Playing = false
            return
        end
    end
end

local function StripFearAndHeartbeat()
    if not Settings.DisableEffects then return end
    -- 1. Отключаем размытие и цветокоррекцию падения/испуга
    for _, eff in ipairs(Lighting:GetChildren()) do
        if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") or eff:IsA("DepthOfFieldEffect") then
            eff.Enabled = false
        end
    end
    for _, eff in ipairs(Camera:GetChildren()) do
        if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") then
            eff.Enabled = false
        end
        MuteFearSound(eff)
    end
    -- 2. Глушим сердцебиение и звуки страха во всех сервисах
    for _, snd in ipairs(SoundService:GetDescendants()) do MuteFearSound(snd) end
    for _, snd in ipairs(Workspace:GetChildren()) do MuteFearSound(snd) end
    if LocalPlayer.Character then
        for _, snd in ipairs(LocalPlayer.Character:GetDescendants()) do MuteFearSound(snd) end
    end
    -- 3. Скрываем полноэкранные заставки страха, статики и крови
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetDescendants()) do
            MuteFearSound(gui)
            local n = string.lower(gui.Name)
            if string.find(n, "static") or string.find(n, "jumpscare") or string.find(n, "scare") or string.find(n, "vignette") or string.find(n, "blood") or string.find(n, "splash") or string.find(n, "hurt") or string.find(n, "panic") then
                if gui:IsA("ScreenGui") then gui.Enabled = false
                elseif gui:IsA("GuiObject") then gui.Visible = false end
            end
        end
    end
end

-- ============================================================================
-- МГНОВЕННОЕ УБИЙСТВО РЕЙКА ЗА 1 УДАР (410+ ХП BURST DAMAGE)
-- ============================================================================
local LastBurstTime = 0

local function Deal410BurstDamageToRake(tool)
    local rake = GetRake()
    if not rake then return end
    local rHum = rake:FindFirstChildOfClass("Humanoid") or rake:FindFirstChild("Monster")
    local rRoot = GetObjectRoot(rake)
    if not rHum or not rRoot or rHum.Health <= 0 then return end

    -- 1. Если есть сетевое владение (NetworkOwnership), мгновенно снимаем 410+ ХП
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

    -- 2. Мульти-удар за 1 взмах (25 мгновенных регистраций попадания по всем частям Рейка = >410 ХП за 1 удар!)
    local char = LocalPlayer.Character
    if not char then return end
    local activeTool = tool or char:FindFirstChildOfClass("Tool")
    if not activeTool then return end

    local handle = activeTool:FindFirstChild("Handle") or activeTool:FindFirstChildWhichIsA("BasePart")
    local rakeParts = {}
    for _, p in ipairs(rake:GetChildren()) do
        if p:IsA("BasePart") then table.insert(rakeParts, p) end
    end

    if handle and firetouchinterest and #rakeParts > 0 then
        for i = 1, 25 do
            for _, rp in ipairs(rakeParts) do
                pcall(function()
                    firetouchinterest(handle, rp, 0)
                    firetouchinterest(handle, rp, 1)
                end)
            end
        end
    end

    -- Если в оружии есть RemoteEvent урона, отправляем пакеты на 410+ урона
    for _, rem in ipairs(activeTool:GetDescendants()) do
        if rem:IsA("RemoteEvent") then
            for i = 1, 18 do
                pcall(function() rem:FireServer(rake, rHum, rRoot.Position) end)
                pcall(function() rem:FireServer(rRoot) end)
                pcall(function() rem:FireServer("Hit", rake, 410) end)
            end
        end
    end
end

local function CacheStaminaTables()
    table.clear(StaminaTables)
    if not getgc then return end
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" and (rawget(v, "Stamina") ~= nil or rawget(v, "stamina") ~= nil or rawget(v, "StunCooldown") ~= nil) then
                table.insert(StaminaTables, v)
            end
        end
    end)
end

local function GetTargetSpeed()
    if Settings.SpeedBypass then return 60 end
    if Settings.FastSprint then return 28 end
    if Settings.WalkSpeedEnabled then return Settings.WalkSpeed end
    return nil
end

-- Привязка к персонажу и перехват удара оружия для 1-Hit Kill (410 HP)
local function BindCharacter(char)
    ClearCharConnections()
    FlyPosition = nil
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    table.insert(CharConnections, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        local target = GetTargetSpeed()
        if target then
            local safeEngineSpd = math.min(target, 30.2)
            if hum.WalkSpeed ~= safeEngineSpd then hum.WalkSpeed = safeEngineSpd end
        elseif Settings.NoJerk and hum.WalkSpeed < 16 then
            hum.WalkSpeed = 16
        end
    end))

    -- Как только игрок берет оружие и бьет (Activated), наносим 410+ урона за 1 удар
    table.insert(CharConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            table.insert(CharConnections, child.Activated:Connect(function()
                if Settings.InstaKillRake then
                    Deal410BurstDamageToRake(child)
                end
            end))
        end
    end))
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            table.insert(CharConnections, child.Activated:Connect(function()
                if Settings.InstaKillRake then
                    Deal410BurstDamageToRake(child)
                end
            end))
        end
    end
end
if LocalPlayer.Character then task.spawn(BindCharacter, LocalPlayer.Character) end

table.insert(Connections, LocalPlayer.CharacterRemoving:Connect(function(char)
    ClearCharConnections()
    FlyPosition = nil
    if not Settings.KeepItems then return end
    for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then tool.Parent = LocalPlayer.Backpack end end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then table.insert(SavedTools, tool); tool.Parent = nil end
    end
end))

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(BindCharacter, char)
    task.delay(1.5, function() if Settings.InfiniteStamina then CacheStaminaTables() end end)
    if not Settings.KeepItems or #SavedTools == 0 then return end
    local bp = LocalPlayer:WaitForChild("Backpack", 5)
    if bp then for _, t in ipairs(SavedTools) do pcall(function() t.Parent = bp end) end end
    table.clear(SavedTools)
end))

local function PatchTools()
    local char = LocalPlayer.Character
    if not char then return end
    for _, container in ipairs({char, LocalPlayer.Backpack}) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = string.lower(tool.Name)
                if string.find(n, "stun") or string.find(n, "stick") or string.find(n, "baton") or string.find(n, "axe") or string.find(n, "knife") then
                    local handle = tool:FindFirstChild("Handle")
                    if handle and (Settings.StunReach or Settings.InstaKillRake) then
                        handle.Size = Vector3.new(30, 30, 30)
                        handle.Massless = true
                        handle.CanCollide = false
                        handle.Transparency = 0.85
                    end
                    if Settings.StunNoCD then tool:SetAttribute("Cooldown", 0) end
                end
            end
        end
    end
end

-- ============================================================================
-- 100% РАБОЧИЙ NOCLIP, ПОЛЕТ (CFRAME ANCHOR) И СКОРОСТЬ 20-60
-- ============================================================================

-- Noclip: выполняется в Stepped перед физикой движка каждый кадр
table.insert(Connections, RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    local char = LocalPlayer.Character
    if char and (Settings.Noclip or Settings.FlyEnabled) then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Settings.ObjectControl and DraggedObject and DraggedObject.Parent then
        local mp = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
        DraggedObject.AssemblyLinearVelocity = ((ray.Origin + ray.Direction * DragDistance) - DraggedObject.Position) * 12
    end
end))

-- Приоритетный хук рендера: убирает тряску камеры (CameraOffset = 0), держит 3-е лицо и Noclip
pcall(function()
    RunService:BindToRenderStep("RakeHub_CamAndNoclip", Enum.RenderPriority.Camera.Value + 5, function()
        if not scriptRunning then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        -- Отключение тряски камеры и покачивания от страха
        if Settings.DisableEffects and hum then
            hum.CameraOffset = Vector3.zero
        end

        -- Удержание Noclip
        if char and (Settings.Noclip or Settings.FlyEnabled) then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        -- Железный вид от 3-го лица
        if Settings.UnlockZoom then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPersonDist
            LocalPlayer.CameraMinZoomDistance = Settings.ThirdPersonDist
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.LocalTransparencyModifier = 0
                    end
                end
            end
        end
    end)
end)

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
        -- 1. СКОРОСТЬ ОТ 20 ДО 60 (до 30.2 через WalkSpeed, от 30.2 до 60 дотягивает через CFrame без сброса)
        local targetSpd = GetTargetSpeed()
        if not Settings.FlyEnabled and not Settings.Freecam then
            if targetSpd then
                local baseSpd = math.min(targetSpd, 30.2)
                hum.WalkSpeed = baseSpd
                if targetSpd > 30.2 and hum.MoveDirection.Magnitude > 0 then
                    local extraSpd = targetSpd - baseSpd
                    myRoot.CFrame = myRoot.CFrame + (hum.MoveDirection * extraSpd * dt)
                end
            elseif Settings.NoJerk and hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
        end

        -- 2. ВЫСОТА ПРЫЖКА
        if Settings.JumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = math.clamp(Settings.JumpPower, 35, 80)
        end

        -- 3. 100% РАБОЧИЙ ПОЛЕТ (CFrame фиксация координаты + джойстик телефона + кнопки UP/DN + анти-падение)
        if Settings.FlyEnabled and not Settings.Freecam then
            if isMobile and not FreecamMobileFrame.Visible then FreecamMobileFrame.Visible = true end
            if not FlyPosition then FlyPosition = myRoot.Position end

            local camCF = Camera.CFrame
            local moveVec = Vector3.zero
            local md = hum.MoveDirection

            -- Направление от стандартного джойстика телефона / WASD по взгляду камеры
            if md.Magnitude > 0 then
                local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                if flatLook.Magnitude > 0.01 and flatRight.Magnitude > 0.01 then
                    local fDot = flatLook.Unit:Dot(md)
                    local rDot = flatRight.Unit:Dot(md)
                    moveVec = moveVec + (camCF.LookVector * fDot) + (camCF.RightVector * rDot)
                else
                    moveVec = moveVec + md
                end
            end

            -- Направление от экранных кнопок W/A/S/D/UP/DN и клавиш Space/Ctrl
            if MobileMoveVec.Z ~= 0 or MobileMoveVec.X ~= 0 then
                moveVec = moveVec + (camCF.LookVector * -MobileMoveVec.Z) + (camCF.RightVector * MobileMoveVec.X)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileMoveVec.Y > 0 then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or MobileMoveVec.Y < 0 then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end

            if moveVec.Magnitude > 0 then
                FlyPosition = FlyPosition + (moveVec.Unit * Settings.FlySpeed * dt)
            end

            -- Жестко удерживаем персонажа в точке FlyPosition и гасим гравитацию в 0
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
            local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
            if flatLook.Magnitude > 0.01 then
                myRoot.CFrame = CFrame.new(FlyPosition, FlyPosition + flatLook.Unit)
            else
                myRoot.CFrame = CFrame.new(FlyPosition)
            end
        else
            FlyPosition = nil
            if not Settings.Freecam and FreecamMobileFrame.Visible then FreecamMobileFrame.Visible = false end
        end
    else
        FlyPosition = nil
    end

    -- Автоматический 410+ урон по Рейку при сближении
    if Settings.InstaKillRake and tick() - LastBurstTime > 0.15 then
        LastBurstTime = tick()
        Deal410BurstDamageToRake(nil)
    end
end))

-- Фоновый цикл обновления ESP, Таймера и анти-страха
local bgThread = task.spawn(function()
    while scriptRunning do
        pcall(UpdateDayNightTimer)
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
            local invalidScrap = (data.Type == "EspScrap" and (not obj:IsA("BasePart") or obj.Transparency >= 0.9))
            if not obj or not obj.Parent or not Settings[data.Type] or data.UsedBox ~= Settings.BoxHandleAdornments or invalidScrap then
                for _, v in ipairs(data.Elements) do pcall(function() v:Destroy() end) end
                EspCache[obj] = nil
            else
                data.Label.TextSize = Settings.EspTextSize
                if data.Root and data.Root.Parent and myRoot then
                    local dist = math.floor((data.Root.Position - myRoot.Position).Magnitude)
                    local statsText = string.format("[%d м]", dist)
                    if data.Type == "EspRake" or data.Type == "EspPlayers" then
                        local hp, maxHp = GetEntityHealth(obj)
                        if hp and maxHp then statsText = string.format("HP: %d/%d | %d м", hp, maxHp, dist) end
                    elseif data.Type == "EspScrap" and data.ValueObj and (data.ValueObj:IsA("IntValue") or data.ValueObj:IsA("NumberValue")) then
                        statsText = string.format("Уровень/Очки: %s | %d м", tostring(data.ValueObj.Value), dist)
                    end
                    data.Label.Text = data.Title .. "\n" .. statsText
                end
            end
        end
        if Settings.RakePathfind then
            ClearPathNodes()
            local rake = GetRake()
            local rRoot = rake and GetObjectRoot(rake)
            if rRoot then
                local vel = rRoot.AssemblyLinearVelocity
                local tPos = rRoot.Position + (vel.Magnitude > 1 and vel.Unit * 35 or rRoot.CFrame.LookVector * 35)
                local dist = (tPos - rRoot.Position).Magnitude
                local b = Instance.new("Part", Workspace)
                b.Anchored = true; b.CanCollide = false; b.Material = Enum.Material.Neon
                b.Color = Color3.fromRGB(255, 60, 0); b.Transparency = 0.25
                b.Size = Vector3.new(0.25, 0.25, dist); b.CFrame = CFrame.lookAt((rRoot.Position + tPos) / 2, tPos)
                table.insert(PathNodes, b)
            end
        end
        if Settings.DisableEffects then pcall(StripFearAndHeartbeat) end
        pcall(PatchTools)
        task.wait(0.25)
    end
end)
table.insert(Connections, bgThread)

local scanLoop = task.spawn(function()
    while scriptRunning do
        if Settings.EspScrap or Settings.EspSupplyDrop or Settings.EspRustyTraps or Settings.EspRakeTraps or Settings.EspFlareGun or Settings.EspLocations then
            pcall(ScanRakeFolders)
        end
        task.wait(2)
    end
end)
table.insert(Connections, scanLoop)

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if Settings.Freecam and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or isMobile then
            FreecamState.Angles = Vector2.new(
                math.clamp(FreecamState.Angles.X - input.Delta.Y * 0.005, -math.pi/2.1, math.pi/2.1),
                FreecamState.Angles.Y - input.Delta.X * 0.005
            )
        end
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    if not scriptRunning then return end
    if Settings.Freecam then
        if not FreecamState.Active then
            FreecamState.Active = true; FreecamState.CFrame = Camera.CFrame
            local rx, ry = Camera.CFrame:ToEulerAnglesYXZ()
            FreecamState.Angles = Vector2.new(rx, ry)
            Camera.CameraType = Enum.CameraType.Scriptable
            if isMobile then FreecamMobileFrame.Visible = true end
        end
        local moveInput = MobileMoveVec
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveInput = moveInput + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveInput = moveInput + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveInput = moveInput + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveInput = moveInput + Vector3.new(1, 0, 0) end
        local rotCF = CFrame.fromEulerAnglesYXZ(FreecamState.Angles.X, FreecamState.Angles.Y, 0)
        FreecamState.CFrame = CFrame.new(FreecamState.CFrame.Position + rotCF:VectorToWorldSpace(moveInput) * FreecamState.Speed * dt) * rotCF
        Camera.CFrame = FreecamState.CFrame
    elseif FreecamState.Active then
        FreecamState.Active = false; Camera.CameraType = Enum.CameraType.Custom
        if not Settings.FlyEnabled then FreecamMobileFrame.Visible = false end
    end

    if Settings.FOVEnabled then Camera.FieldOfView = Settings.FOV end

    if Settings.NightVision or Settings.NoFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        for _, eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("Atmosphere") then eff.Density = 0 end
        end
        if Settings.NightVision then
            Lighting.Ambient = Color3.fromRGB(210, 210, 210)
            Lighting.OutdoorAmbient = Color3.fromRGB(210, 210, 210)
            Lighting.Brightness = 2.5
            Lighting.GlobalShadows = false
        end
    end
end))

-- ============================================================================
-- ПОСТРОЕНИЕ ЭЛЕМЕНТОВ ИНТЕРФЕЙСА И ЗАПУСК
-- ============================================================================

CreateSection("Таймер и Интерфейс")
CreateElement("Таймер Дня и Ночи сверху экрана", function(s)
    Settings.ShowTimer = s
    TimerFrame.Visible = s
end, false, Colors.Accent, true)

CreateSection("Передвижение и Физика")
CreateElement("Быстрый бег (Стандарт 28)", function(s)
    Settings.FastSprint = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end, false, Color3.fromRGB(65, 185, 120))
CreateElement("Speed Bypass (Бета) (Скорость 60)", function(s) Settings.SpeedBypass = s end, false)
CreateElement("Активировать Свою Скорость (20 - 60)", function(s)
    Settings.WalkSpeedEnabled = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end, false)
CreateSlider("Скорость (20 - 60)", 20, 60, 24, 1, function(v) Settings.WalkSpeed = v end)
CreateElement("Активировать Высоту прыжка", function(s) Settings.JumpPowerEnabled = s end, false)
CreateSlider("Высота прыжка", 35, 100, 40, 0, function(v) Settings.JumpPower = v end)
CreateElement("Полет (100% CFrame Fly)", function(s)
    Settings.FlyEnabled = s
    if not s then
        FlyPosition = nil
        if not Settings.Noclip then RestoreCollisions() end
    end
end, false)
CreateSlider("Скорость полета", 10, 100, 35, 0, function(v) Settings.FlySpeed = v end)
CreateElement("Бесконечная выносливость", function(s) Settings.InfiniteStamina = s; if s then CacheStaminaTables() end end, false)
CreateElement("Без рывков (No Jerk)", function(s) Settings.NoJerk = s end, false)
CreateElement("Noclip (100% Сквозь стены)", function(s)
    Settings.Noclip = s
    if not s and not Settings.FlyEnabled then RestoreCollisions() end
end, false)

CreateSection("Бой и Предметы")
CreateElement("Убийство Рейка за 1 удар (410+ ХП)", function(s) Settings.InstaKillRake = s end, false, Color3.fromRGB(255, 45, 45))
CreateElement("Сохранение предмета при возрождении", function(s) Settings.KeepItems = s end, false)
CreateElement("Дальность удара электрошокером", function(s) Settings.StunReach = s end, false)
CreateElement("Сокращение перезарядки шокера", function(s) Settings.StunNoCD = s end, false)
CreateElement("Без сбоев электрошокера (Эксп.)", function(s) Settings.StunNoFail = s end, false)
CreateElement("Управление объектами (Без привязки)", function(s) Settings.ObjectControl = s end, false)

CreateSection("ESP и Подсветка")
CreateSlider("Размер текста ESP", 6, 18, Settings.EspTextSize, 0, function(v) Settings.EspTextSize = v end)
CreateElement("Украшения для ручек ящиков (3D Box)", function(s) Settings.BoxHandleAdornments = s end, false)
CreateElement("ESP Рейк (Монстр)", function(s) Settings.EspRake = s end, false, Color3.fromRGB(255, 35, 35))
CreateElement("Rake Pathfind (Прогнозирует маршрут)", function(s) Settings.RakePathfind = s; if not s then ClearPathNodes() end end, false)
CreateElement("ESP Игроки", function(s) Settings.EspPlayers = s end, false)
CreateElement("ESP Капканы (Текст + Яркая Обводка)", function(s) Settings.EspRustyTraps = s; if s then task.spawn(ScanRakeFolders) end end, false)
CreateElement("ESP Ловушки с рейком (С обводкой)", function(s) Settings.EspRakeTraps = s; if s then task.spawn(ScanRakeFolders) end end, false)
CreateElement("ESP Места (Вышка, Магазин, Убежище, Свет)", function(s)
    Settings.EspLocations = s
    if not s then table.clear(RegisteredLocations) end
    if s then task.spawn(ScanRakeFolders) end
end, false)
CreateElement("ESP Железо (Только реальный лом)", function(s) Settings.EspScrap = s; if s then task.spawn(ScanRakeFolders) end end, false)
CreateElement("ESP Ракетница", function(s) Settings.EspFlareGun = s; if s then task.spawn(ScanRakeFolders) end end, false)
CreateElement("ESP Ящик с припасами", function(s) Settings.EspSupplyDrop = s; if s then task.spawn(ScanRakeFolders) end end, false)

CreateSection("Камера и Визуал")
CreateElement("Бесплатная камера (ПК + Мобильная)", function(s) Settings.Freecam = s end, false)
CreateElement("Вид от 3-го лица (Разблокировать зум)", function(s)
    Settings.UnlockZoom = s
    if not s then
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end, false)
CreateSlider("Дистанция 3-го лица", 6, 120, 18, 0, function(v) Settings.ThirdPersonDist = v end)
CreateElement("Изменить Поле зрения (FOV)", function(s) Settings.FOVEnabled = s end, false)
CreateSlider("Поле зрения (FOV)", 1, 120, 75, 0, function(v) Settings.FOV = v end)
CreateElement("Отключить страх, сердцебиение и тряску", function(s)
    Settings.DisableEffects = s
    if not s then
        RestoreMutedSounds()
        if SavedLighting.Captured then
            for obj, val in pairs(SavedLighting.Effects) do
                if obj and obj.Parent and obj:IsA("PostEffect") then obj.Enabled = val end
            end
        end
    end
end, false)
CreateElement("Ночное зрение и Без тумана", function(s)
    if s then
        CaptureOriginalLighting()
        Settings.NightVision = true
        Settings.NoFog = true
    else
        Settings.NightVision = false
        Settings.NoFog = false
        RestoreOriginalLighting()
    end
end, false)

CreateSection("Система")
CreateElement("Удалить Скрипт", DestroyScript, true, Color3.fromRGB(255, 65, 65))

local function ShowMain()
    MobileToggleBtn.Visible = true
    isMenuOpen = true
    MainFrame.Visible = true
end

MobileToggleBtn.MouseButton1Click:Connect(function()
    isMenuOpen = not isMenuOpen
    MainFrame.Visible = isMenuOpen
end)

local langStep = 0
LangConfirmBtn.MouseButton1Click:Connect(function()
    if langStep == 0 then
        langStep = 1
        LangConfirmBtn.Text = "ТОЧНО? НАЖМИТЕ ЕЩЁ РАЗ"
        LangConfirmBtn.BackgroundColor3 = Colors.ConfirmWarning
    else
        LangFrame:Destroy()
        NameFrame.Visible = true
    end
end)

SubmitBtn.MouseButton1Click:Connect(function()
    local n = NameInput.Text ~= "" and NameInput.Text or LocalPlayer.DisplayName
    SaveName(n)
    NameFrame:Destroy()
    ShowMain()
end)

task.spawn(function()
    TweenService:Create(LoadBar, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    for i = 10, 100, 15 do
        PercentText.Text = "Загрузка скриптов... " .. i .. "%"
        task.wait(0.05)
    end
    LoadFrame:Destroy()
    if GetSavedName() then
        ShowMain()
    else
        LangFrame.Visible = true
    end
end)
