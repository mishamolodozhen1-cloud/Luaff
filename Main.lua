-- Rake Hub-Beta [DELTA X + FULL ANTICHEAT BYPASS + GODMODE + 60 SPEED / FLY / NOCLIP FIX + INSTAKILL]
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
    GodMode = false,
    FastSprint = false,
    WalkSpeedEnabled = false, WalkSpeed = 24,
    SpeedBypass = false,
    JumpPowerEnabled = false, JumpPower = 40,
    FlyEnabled = false, FlySpeed = 28,
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
local OriginalPartProps = {}
local FileName = "RakeHubBeta_SavedName.txt"
local isMenuOpen = false
local scriptRunning = true
local FreecamState = {Active = false, CFrame = CFrame.new(), Angles = Vector2.new(), Speed = 45}
local DraggedObject, DragDistance = nil, 15
local FlyAttachment, FlyLinearVel, FlyAlignOrient = nil, nil, nil
local LastSafePosition = nil
local BypassTick = 0

local Colors = {
    Background = Color3.fromRGB(18, 18, 22),
    Panel = Color3.fromRGB(28, 28, 34),
    Stroke = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(210, 55, 65),
    ConfirmWarning = Color3.fromRGB(220, 130, 30),
    TextWhite = Color3.fromRGB(235, 235, 240),
    TextGray = Color3.fromRGB(130, 130, 140)
}

-- ============================================================================
-- ПЕРЕХВАТ АНТИЧИТА И УРОНА ЧЕРЕЗ METATABLE HOOK (DELTA X)
-- ============================================================================
pcall(function()
    local mt = getrawmetatable and getrawmetatable(game)
    if mt and hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if not scriptRunning then return oldNamecall(self, ...) end
            local method = getnamecallmethod()
            local args = {...}
            if method == "FireServer" or method == "InvokeServer" then
                local remName = string.lower(tostring(self.Name))
                -- Блокируем репорты античита и урон от падения / капканов
                if string.find(remName, "ban") or string.find(remName, "kick") or string.find(remName, "cheat") or string.find(remName, "exploit") or string.find(remName, "detect") or string.find(remName, "log") or string.find(remName, "flag") then
                    return nil
                end
                if (Settings.GodMode or Settings.JumpPowerEnabled or Settings.FlyEnabled or Settings.Noclip) then
                    if string.find(remName, "fall") or string.find(remName, "fdamage") or string.find(remName, "damage") or string.find(remName, "hurt") or string.find(remName, "hit") then
                        -- Если это НЕ наш собственный удар оружием по Рейку, блокируем входящий/падение урон
                        if not ( self:IsDescendantOf(LocalPlayer.Character or Instance.new("Folder")) or self:IsDescendantOf(LocalPlayer.Backpack) ) then
                            if args[1] ~= "Hit" and typeof(args[1]) ~= "Instance" then
                                return nil
                            end
                        end
                    end
                    if #args > 0 and type(args[1]) == "number" and args[1] > 0 and (string.find(remName, "fall") or string.find(remName, "dmg") or string.find(remName, "health")) then
                        return nil
                    end
                end
                if Settings.StunNoFail and (string.find(remName, "fail") or string.find(remName, "shock") or string.find(remName, "self")) then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

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
        local h = math.floor(clock)
        local m = math.floor((clock - h) * 60)
        local gameTimeStr = string.format("%02d:%02d", h, m)
        local hoursLeft = isNight and ((clock >= 18) and (24 - clock + 6) or (6 - clock)) or (18 - clock)
        local approxSec = math.floor(hoursLeft * 30)
        local phaseText = isNight and "<font color='#FF4545'>НОЧЬ</font>" or "<font color='#55FF88'>ДЕНЬ</font>"
        TimerLabel.Text = phaseText .. " (" .. gameTimeStr .. ") ~" .. FormatSeconds(approxSec)
    end
end

local function CleanupFlyConstraints()
    if FlyLinearVel then pcall(function() FlyLinearVel:Destroy() end); FlyLinearVel = nil end
    if FlyAlignOrient then pcall(function() FlyAlignOrient:Destroy() end); FlyAlignOrient = nil end
    if FlyAttachment then pcall(function() FlyAttachment:Destroy() end); FlyAttachment = nil end
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

local function RestoreCollisionsAndTouch()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if OriginalPartProps[part] then
                part.CanCollide = OriginalPartProps[part].CanCollide
                part.CanTouch = OriginalPartProps[part].CanTouch
                part.CanQuery = OriginalPartProps[part].CanQuery
            elseif part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head" then
                part.CanCollide = true
                part.CanTouch = true
            end
        end
    end
end

local function RestoreMutedSounds()
    for snd, vol in pairs(MutedSounds) do
        if snd and snd.Parent then
            pcall(function()
                snd.Volume = vol
                snd.PlaybackSpeed = 1
            end)
        end
    end
    table.clear(MutedSounds)
end

local function DestroyScript()
    scriptRunning = false
    ClearCharConnections()
    CleanupFlyConstraints()
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
    RestoreCollisionsAndTouch()
    RestoreMutedSounds()
    Camera.CameraType = Enum.CameraType.Custom; Camera.FieldOfView = 70
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    LocalPlayer.CameraMaxZoomDistance = 0.5
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.CameraOffset = Vector3.zero; hum.PlatformStand = false end
    end
    if ScreenGui then ScreenGui:Destroy() end
end

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
-- ЯДРО ESP И ПОИСК РЕЙКА
-- ============================================================================
local CachedRake = nil
local function GetRake()
    if CachedRake and CachedRake.Parent then return CachedRake end
    local r = Workspace:FindFirstChild("Rake") or Workspace:FindFirstChild("Monster") or Workspace:FindFirstChild("TheRake")
    if r and r:IsA("Model") then CachedRake = r; return r end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            local n = string.lower(obj.Name)
            if string.find(n, "rake") or string.find(n, "monster") or obj:FindFirstChild("Monster") or obj:FindFirstChild("NPC") then
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
        return obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("HitBox") or obj:FindFirstChild("Scrap") or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
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
        Highlight.Parent = object
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

    if Settings.EspSupplyDrop then
        if string.find(parentName, "supply") or string.find(n, "supplycrate") or string.find(n, "supplydrop") or parentName == "supplycrates" or obj:FindFirstChild("GUILock") then
            local crateModel = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
            CreateEspElements(crateModel, Color3.fromRGB(255, 215, 50), "ЯЩИК С ПРИПАСАМИ", "EspSupplyDrop")
            return
        end
    end

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

    if Settings.EspFlareGun then
        if (n == "flaregun" or n == "flaregunpickup" or string.find(n, "flare gun")) and not string.find(n, "note") then
            local flareTarget = (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent ~= Workspace) and obj.Parent or obj
            CreateEspElements(flareTarget, Color3.fromRGB(255, 90, 40), "РАКЕТНИЦА", "EspFlareGun")
            return
        end
    end

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
-- ИСПРАВЛЕНИЕ №5: ПОЛНОЕ ОТКЛЮЧЕНИЕ СЕРДЦЕБИЕНИЯ, ТРЯСКИ КАМЕРЫ, ЭФФЕКТОВ СТРАХА
-- ============================================================================
local FearKeywords = {
    "heartbeat", "heart", "panic", "scare", "jumpscare", "static", "chase",
    "terror", "fear", "breathing", "breath", "shock", "tension", "blood",
    "vignette", "hurt", "horror", "scream", "whisper", "ambience", "creep"
}

local function IsFearObject(name)
    local n = string.lower(tostring(name))
    for _, kw in ipairs(FearKeywords) do
        if string.find(n, kw) then return true end
    end
    return false
end

local function MuteFearSound(snd)
    if not snd or not snd:IsA("Sound") then return end
    if IsFearObject(snd.Name) or (snd.Parent and IsFearObject(snd.Parent.Name)) then
        if MutedSounds[snd] == nil then MutedSounds[snd] = snd.Volume end
        snd.Volume = 0
        snd.PlaybackSpeed = 0
        snd.Playing = false
        pcall(function() snd:Stop() end)
    end
end

local function StripFearAndHeartbeat()
    if not Settings.DisableEffects then return end

    -- 1. Очистка эффектов в Lighting и Camera
    for _, container in ipairs({Lighting, Camera}) do
        for _, eff in ipairs(container:GetDescendants()) do
            if eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") or eff:IsA("DepthOfFieldEffect") or eff:IsA("SunRaysEffect") then
                if not Settings.NightVision or eff:IsA("BlurEffect") or IsFearObject(eff.Name) then
                    eff.Enabled = false
                end
            elseif eff:IsA("Sound") then
                MuteFearSound(eff)
            end
        end
    end

    -- 2. Глушим все звуки сердцебиения и погони во всех сервисах (SoundService, Workspace, ReplicatedStorage, PlayerGui, Character)
    for _, service in ipairs({SoundService, Workspace, ReplicatedStorage}) do
        for _, desc in ipairs(service:GetDescendants()) do
            if desc:IsA("Sound") then MuteFearSound(desc) end
        end
    end
    if LocalPlayer.Character then
        for _, desc in ipairs(LocalPlayer.Character:GetDescendants()) do
            if desc:IsA("Sound") then MuteFearSound(desc) end
        end
    end

    -- 3. Отключаем GUI скримеров, красного экрана, статики и виньетки
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("Sound") then
                MuteFearSound(gui)
            elseif (gui:IsA("ScreenGui") or gui:IsA("GuiObject")) and gui ~= ScreenGui and not gui:IsDescendantOf(ScreenGui) then
                if IsFearObject(gui.Name) then
                    if gui:IsA("ScreenGui") then gui.Enabled = false
                    elseif gui:IsA("GuiObject") then gui.Visible = false; gui.BackgroundTransparency = 1 end
                    if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then gui.ImageTransparency = 1 end
                end
            end
        end
    end
end

-- Мгновенный перехват новых звуков сердцебиения при их появлении
for _, srv in ipairs({Workspace, SoundService, LocalPlayer:WaitForChild("PlayerGui", 5) or Workspace}) do
    table.insert(Connections, srv.DescendantAdded:Connect(function(desc)
        if scriptRunning and Settings.DisableEffects then
            if desc:IsA("Sound") then
                task.defer(function() MuteFearSound(desc) end)
            elseif desc:IsA("BlurEffect") or desc:IsA("ColorCorrectionEffect") then
                task.defer(function() desc.Enabled = false end)
            end
        end
    end))
end

-- ============================================================================
-- ИСПРАВЛЕНИЕ №6: МГНОВЕННОЕ УБИЙСТВО РЕЙКА (МУЛЬТИ-УДАР + ЭКВИП + СЕРВЕРНЫЙ ПАКЕТ)
-- ============================================================================
local LastBurstTime = 0

local function Deal410BurstDamageToRake(passedTool)
    local rake = GetRake()
    if not rake then return end
    local rHum = rake:FindFirstChildOfClass("Humanoid") or rake:FindFirstChild("Monster")
    local rRoot = GetObjectRoot(rake)
    if not rHum or not rRoot or rHum.Health <= 0 then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local myHum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not myRoot or not myHum then return end

    -- 1. Принудительный захват NetworkOwnership, если Рейк в радиусе симуляции
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(LocalPlayer, "SimulationRadius", 10000)
            sethiddenproperty(LocalPlayer, "MaxSimulationRadius", 10000)
        end
        if isnetworkowner and isnetworkowner(rRoot) then
            rHum.Health = 0
            rHum:ChangeState(Enum.HumanoidStateType.Dead)
        end
    end)

    -- 2. Ищем оружие в руках или в рюкзаке (StunStick, UV, Axe, Knife, Crowbar и т.д.)
    local activeTool = passedTool or char:FindFirstChildOfClass("Tool")
    if not activeTool and (rRoot.Position - myRoot.Position).Magnitude <= 45 then
        for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") then
                local tn = string.lower(t.Name)
                if string.find(tn, "stun") or string.find(tn, "stick") or string.find(tn, "baton") or string.find(tn, "crowbar") or string.find(tn, "axe") or string.find(tn, "knife") or t:FindFirstChildOfClass("RemoteEvent") or t:FindFirstChild("Event", true) then
                    activeTool = t
                    pcall(function() myHum:EquipTool(t) end)
                    break
                end
            end
        end
    end
    if not activeTool then return end

    local handle = activeTool:FindFirstChild("Handle") or activeTool:FindFirstChild("HitBox") or activeTool:FindFirstChildWhichIsA("BasePart")
    local rakeParts = {}
    for _, p in ipairs(rake:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(rakeParts, p) end
    end

    -- 3. Активируем тул и пробиваем касание + все его серверные RemoteEvent/RemoteFunction
    pcall(function() activeTool:Activate() end)

    if handle and firetouchinterest and #rakeParts > 0 then
        for _ = 1, 30 do
            for _, rp in ipairs(rakeParts) do
                pcall(function()
                    firetouchinterest(handle, rp, 0)
                    firetouchinterest(handle, rp, 1)
                end)
            end
        end
    end

    for _, rem in ipairs(activeTool:GetDescendants()) do
        if rem:IsA("RemoteEvent") then
            for _ = 1, 25 do
                pcall(function() rem:FireServer() end)
                pcall(function() rem:FireServer(rake) end)
                pcall(function() rem:FireServer(rHum) end)
                pcall(function() rem:FireServer(rRoot) end)
                pcall(function() rem:FireServer(rake, rHum, rRoot.Position) end)
                pcall(function() rem:FireServer(rHum, 1000) end)
                pcall(function() rem:FireServer("Hit", rake, rHum) end)
            end
        elseif rem:IsA("RemoteFunction") then
            for _ = 1, 10 do
                task.spawn(function()
                    pcall(function() rem:InvokeServer(rake, rHum) end)
                    pcall(function() rem:InvokeServer(rRoot) end)
                end)
            end
        end
    end
end

local function CacheStaminaTables()
    table.clear(StaminaTables)
    if not getgc then return end
    pcall(function()
        for _, v in ipairs(getgc(true)) do
            if type(v) == "table" and (rawget(v, "Stamina") ~= nil or rawget(v, "stamina") ~= nil or rawget(v, "StunCooldown") ~= nil or rawget(v, "Sprint") ~= nil) then
                table.insert(StaminaTables, v)
            end
        end
    end)
end

local function GetTargetSpeed()
    if Settings.SpeedBypass then return 58 end
    if Settings.FastSprint then return 28 end
    if Settings.WalkSpeedEnabled then return Settings.WalkSpeed end
    return nil
end

local function BindCharacter(char)
    ClearCharConnections()
    CleanupFlyConstraints()
    table.clear(OriginalPartProps)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not hum or not root then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            OriginalPartProps[part] = {
                CanCollide = part.CanCollide,
                CanTouch = part.CanTouch,
                CanQuery = part.CanQuery
            }
        end
    end

    -- Защита от падения и урона состояниями
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    table.insert(CharConnections, hum.HealthChanged:Connect(function(hp)
        if Settings.GodMode and hp < hum.MaxHealth and hp > 0 then
            hum.Health = hum.MaxHealth
        end
    end))

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
    CleanupFlyConstraints()
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
                if string.find(n, "stun") or string.find(n, "stick") or string.find(n, "baton") or string.find(n, "axe") or string.find(n, "knife") or string.find(n, "crowbar") then
                    local handle = tool:FindFirstChild("Handle")
                    if handle and (Settings.StunReach or Settings.InstaKillRake) then
                        handle.Size = Vector3.new(35, 35, 35)
                        handle.Massless = true
                        handle.CanCollide = false
                        handle.Transparency = 0.85
                    end
                    if Settings.StunNoCD then
                        tool:SetAttribute("Cooldown", 0)
                        for _, val in ipairs(tool:GetDescendants()) do
                            if (val:IsA("NumberValue") or val:IsA("IntValue")) and (string.find(string.lower(val.Name), "cool") or string.find(string.lower(val.Name), "delay")) then
                                val.Value = 0
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ИСПРАВЛЕНИЯ №1, №2, №3, №4, №7:
-- SPEED 60 БЕЗ ОТКАТА, FLY БЕЗ КИЛЛА АНТИЧИТОМ, JUMP 100 БЕЗ УРОНА, NOCLIP И GODMODE
-- ============================================================================

-- 1. PreSimulation / Stepped: Безопасный Noclip + отключение CanTouch для GodMode
table.insert(Connections, RunService.Stepped:Connect(function()
    if not scriptRunning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if Settings.Noclip or Settings.FlyEnabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                -- Отключаем серверные триггеры стен и капканов при проходе сквозь объекты
                part.CanTouch = false
                part.CanQuery = false
            end
        end
    elseif Settings.GodMode then
        -- В режиме Бессмертия отключаем CanTouch на всех частях тела, чтобы хитбокс лап Рейка и капканов не регистрировал TouchEnded/Touched
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end

    -- Защита от урона при падении после прыжка 100 (гасим скорость падения перед землей + подменяем состояние)
    if (Settings.JumpPowerEnabled or Settings.GodMode or Settings.FlyEnabled) and root and hum then
        if root.AssemblyLinearVelocity.Y < -55 then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local hit = Workspace:Raycast(root.Position, Vector3.new(0, -14, 0), rayParams)
            if hit then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -15, root.AssemblyLinearVelocity.Z)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end

    if Settings.ObjectControl and DraggedObject and DraggedObject.Parent then
        local mp = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
        DraggedObject.AssemblyLinearVelocity = ((ray.Origin + ray.Direction * DragDistance) - DraggedObject.Position) * 12
    end
end))

pcall(function()
    RunService:BindToRenderStep("RakeHub_CamAndNoclip", Enum.RenderPriority.Camera.Value + 5, function()
        if not scriptRunning then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if Settings.DisableEffects and hum then
            hum.CameraOffset = Vector3.zero
        end

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
    BypassTick = BypassTick + dt
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
        -- ====================================================================
        -- 7. БЕССМЕРТИЕ (GODMODE): УДЕРЖАНИЕ ХП + АВТО-УКЛОНЕНИЕ ОТ АТАКИ РЕЙКА
        -- ====================================================================
        if Settings.GodMode then
            if hum.Health > 0 and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

            -- Если Рейк подходит вплотную (< 11 студов) для удара, делаем мгновенный микро-рывок от его вектора атаки, чтобы серверный Raycast/Magnitude удар промахнулся
            local rake = GetRake()
            local rRoot = rake and GetObjectRoot(rake)
            if rRoot then
                local diff = (myRoot.Position - rRoot.Position)
                local flatDiff = Vector3.new(diff.X, 0, diff.Z)
                local dist = flatDiff.Magnitude
                if dist < 11.5 and dist > 0.05 then
                    local escapeDir = flatDiff.Unit
                    local safeStep = escapeDir * (13 - dist)
                    myRoot.AssemblyLinearVelocity = Vector3.new(escapeDir.X * 29, myRoot.AssemblyLinearVelocity.Y, escapeDir.Z * 29)
                    myRoot.CFrame = myRoot.CFrame + Vector3.new(safeStep.X * 0.45, 0, safeStep.Z * 0.45)
                end
            end
        end

        -- ====================================================================
        -- 1 & 4. СКОРОСТЬ ДО 60 И NOCLIP БЕЗ РЕЗИНОВОГО ОТКАТА СЕРВЕРА
        -- ====================================================================
        -- Античит The Rake Remastered откатывает назад, если:
        -- а) меняют CFrame напрямую при большом расстоянии за кадр
        -- б) горизонтальная скорость превышает лимит непрерывно без микро-пауз синхронизации
        local targetSpd = GetTargetSpeed()
        if not Settings.FlyEnabled and not Settings.Freecam then
            CleanupFlyConstraints()
            if Settings.Noclip and hum.MoveDirection.Magnitude > 0 then
                -- При Noclip двигаем через мягкий физический вектор + микро-шаг CFrame, чтобы проходить сквозь стены без резинового отката
                local noclipSpd = math.min(targetSpd or 26, 29.5)
                hum.WalkSpeed = noclipSpd
                local horizVel = hum.MoveDirection * noclipSpd
                myRoot.AssemblyLinearVelocity = Vector3.new(horizVel.X, 0, horizVel.Z)
                myRoot.CFrame = myRoot.CFrame + (hum.MoveDirection * (noclipSpd * 0.18 * dt))
            elseif targetSpd then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    -- Пульсирующий обход античита для скорости 28..60:
                    -- 4 кадра даем импульс скорости, каждый 5-й кадр сбрасываем до легитных 24, чтобы серверный чекер засчитал валидный тик
                    local cycle = math.floor(BypassTick * 30) % 5
                    local effectiveSpd = targetSpd
                    if targetSpd > 30 then
                        effectiveSpd = (cycle == 0) and 24 or math.min(targetSpd, 46)
                    end
                    hum.WalkSpeed = math.min(targetSpd, 28)
                    local curY = myRoot.AssemblyLinearVelocity.Y
                    myRoot.AssemblyLinearVelocity = Vector3.new(moveDir.X * effectiveSpd, curY, moveDir.Z * effectiveSpd)
                else
                    hum.WalkSpeed = 16
                end
            elseif Settings.NoJerk and hum.WalkSpeed < 16 then
                hum.WalkSpeed = 16
            end
        end

        -- ====================================================================
        -- 3. ВЫСОТА ПРЫЖКА (БЕЗ ОТКАТА И БЕЗ УРОНА ПРИ ПАДЕНИИ)
        -- ====================================================================
        if Settings.JumpPowerEnabled and not Settings.FlyEnabled then
            hum.UseJumpPower = true
            -- Серверный античит флагает мгновенную вертикальную скорость > 68, поэтому ограничиваем стартовый рывок и поддерживаем подъем плавно
            local clampedJP = math.clamp(Settings.JumpPower, 35, 65)
            hum.JumpPower = clampedJP
            if hum:GetState() == Enum.HumanoidStateType.Jumping and Settings.JumpPower > 60 then
                local curVel = myRoot.AssemblyLinearVelocity
                if curVel.Y > 10 and curVel.Y < 58 then
                    myRoot.AssemblyLinearVelocity = Vector3.new(curVel.X, math.min(curVel.Y + (Settings.JumpPower - 55) * 0.35, 62), curVel.Z)
                end
            end
        end

        -- ====================================================================
        -- 2. ПОЛЕТ (100% BYPASS АНТИЧИТА — БЕЗ ПРЕДУПРЕЖДЕНИЯ И БЕЗ СМЕРТИ!)
        -- ====================================================================
        -- Почему античит убивал за старый Fly:
        -- 1) Персонаж висел в состоянии Freefall > 3 секунд
        -- 2) Прямая перезапись myRoot.CFrame вызывала десинхрон позиции
        -- Решение: используем физический LinearVelocity + принудительно ставим состояние Climbing/Running каждый кадр + ограничиваем скорость до безопасного порога сервера!
        if Settings.FlyEnabled and not Settings.Freecam then
            if isMobile and not FreecamMobileFrame.Visible then FreecamMobileFrame.Visible = true end

            if not FlyAttachment or FlyAttachment.Parent ~= myRoot then
                CleanupFlyConstraints()
                FlyAttachment = Instance.new("Attachment", myRoot)
                FlyAttachment.Name = "RH_Att"

                FlyLinearVel = Instance.new("LinearVelocity", myRoot)
                FlyLinearVel.Name = "RH_LV"
                FlyLinearVel.Attachment0 = FlyAttachment
                FlyLinearVel.MaxForce = math.huge
                FlyLinearVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
                FlyLinearVel.VectorVelocity = Vector3.zero

                FlyAlignOrient = Instance.new("AlignOrientation", myRoot)
                FlyAlignOrient.Name = "RH_AO"
                FlyAlignOrient.Attachment0 = FlyAttachment
                FlyAlignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
                FlyAlignOrient.MaxTorque = math.huge
                FlyAlignOrient.Responsiveness = 50
            end

            -- Обман серверного чекера времени в воздухе (AirTime Check): ставим состояние Climbing/Running
            hum.PlatformStand = false
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Climbing)
            else
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end

            local camCF = Camera.CFrame
            local moveVec = Vector3.zero
            local md = hum.MoveDirection

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

            if MobileMoveVec.Z ~= 0 or MobileMoveVec.X ~= 0 then
                moveVec = moveVec + (camCF.LookVector * -MobileMoveVec.Z) + (camCF.RightVector * MobileMoveVec.X)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileMoveVec.Y > 0 then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or MobileMoveVec.Y < 0 then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end

            -- Безопасная скорость полета для античита Rake Remastered (пульсация до 34 студ/с и микро-просадка по Y против AirCheck)
            local safeFlySpd = math.min(Settings.FlySpeed, 34)
            local hoverPulse = math.sin(BypassTick * 14) * 0.6
            if moveVec.Magnitude > 0 then
                local vel = moveVec.Unit * safeFlySpd
                -- Ограничиваем вертикальный подъем до 24, чтобы античит не кикал за High Vertical Velocity
                vel = Vector3.new(vel.X, math.clamp(vel.Y, -28, 22), vel.Z)
                FlyLinearVel.VectorVelocity = vel
            else
                FlyLinearVel.VectorVelocity = Vector3.new(0, hoverPulse, 0)
            end

            local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
            if flatLook.Magnitude > 0.01 then
                FlyAlignOrient.CFrame = CFrame.lookAt(myRoot.Position, myRoot.Position + flatLook.Unit)
            end
        else
            CleanupFlyConstraints()
            if not Settings.Freecam and FreecamMobileFrame.Visible then FreecamMobileFrame.Visible = false end
        end
    else
        CleanupFlyConstraints()
    end

    if Settings.InstaKillRake and tick() - LastBurstTime > 0.12 then
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
                b.Anchored = true; b.CanCollide = false; b.CanTouch = false; b.CanQuery = false
                b.Material = Enum.Material.Neon
                b.Color = Color3.fromRGB(255, 60, 0); b.Transparency = 0.25
                b.Size = Vector3.new(0.25, 0.25, dist); b.CFrame = CFrame.lookAt((rRoot.Position + tPos) / 2, tPos)
                table.insert(PathNodes, b)
            end
        end
        if Settings.DisableEffects then pcall(StripFearAndHeartbeat) end
        pcall(PatchTools)
        task.wait(0.2)
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

CreateSection("Таймер и Защита")
CreateElement("Таймер Дня и Ночи сверху экрана", function(s)
    Settings.ShowTimer = s
    TimerFrame.Visible = s
end, false, Colors.Accent, true)
CreateElement("Бессмертие (GodMode + Уклонение от Рейка)", function(s)
    Settings.GodMode = s
    if not s and not Settings.Noclip and not Settings.FlyEnabled then
        RestoreCollisionsAndTouch()
    end
end, false, Color3.fromRGB(50, 220, 100))

CreateSection("Передвижение и Физика")
CreateElement("Быстрый бег (Стандарт 28)", function(s)
    Settings.FastSprint = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end, false, Color3.fromRGB(65, 185, 120))
CreateElement("Speed Bypass (Скорость до 60 без отката)", function(s) Settings.SpeedBypass = s end, false)
CreateElement("Активировать Свою Скорость (20 - 60)", function(s)
    Settings.WalkSpeedEnabled = s
    if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
end, false)
CreateSlider("Скорость (20 - 60)", 20, 60, 24, 1, function(v) Settings.WalkSpeed = v end)
CreateElement("Активировать Высоту прыжка (Без урона)", function(s) Settings.JumpPowerEnabled = s end, false)
CreateSlider("Высота прыжка", 35, 100, 40, 0, function(v) Settings.JumpPower = v end)
CreateElement("Полет (Anti-Cheat Bypass Fly)", function(s)
    Settings.FlyEnabled = s
    if not s then
        CleanupFlyConstraints()
        if not Settings.Noclip and not Settings.GodMode then RestoreCollisionsAndTouch() end
    end
end, false)
CreateSlider("Скорость полета (Безопасно до 34)", 10, 60, 28, 0, function(v) Settings.FlySpeed = v end)
CreateElement("Бесконечная выносливость", function(s) Settings.InfiniteStamina = s; if s then CacheStaminaTables() end end, false)
CreateElement("Без рывков (No Jerk)", function(s) Settings.NoJerk = s end, false)
CreateElement("Noclip (Сквозь стены без отката)", function(s)
    Settings.Noclip = s
    if not s and not Settings.FlyEnabled and not Settings.GodMode then RestoreCollisionsAndTouch() end
end, false)

CreateSection("Бой и Предметы")
CreateElement("Убийство Рейка за 1 удар (Нужно оружие)", function(s) Settings.InstaKillRake = s end, false, Color3.fromRGB(255, 45, 45))
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
    if s then
        pcall(StripFearAndHeartbeat)
    else
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
