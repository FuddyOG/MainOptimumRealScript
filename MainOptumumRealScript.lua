local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

--// STATE VARIABLES
local WalkSpeed = 16
local JumpPower = 50
local SpeedOn = false
local JumpOn = false
local NoclipOn = false 
local ThirdPersonOn = false

local FlyOn = false
local FlySpeed = 60
local bV, bG

local AimOn = false
local AimMode = "Toggle" -- Toggle or Hold
local AimTargetPart = "Head"
local AimSmooth = 0.15
local AimFOV = 120
local AimTeamCheck = false
local AimWallCheck = false
local AimBotSupport = false

local AutoShootOn = false
local AutoShootDelay = 0.1
local lastAutoShoot = tick()

local MouseLockOn = false
local isUiOpen = true -- Obsidian UI starts open by default

local ShowFOV = false
local FillFOV = false
local FOVColor = Color3.fromRGB(255, 255, 255)
local FOVTransparency = 0.5

local MasterESP = false
local ESPBox = false
local ESPBoxFill = false
local ESPBoxFillColor = Color3.fromRGB(255, 0, 0)
local ESPBoxFillTrans = 0.5
local ESPName = false
local ESPTracer = false
local ESPHealth = false
local ESPDistance = false
local ESPTeamCheck = false
local ESPColor = Color3.fromRGB(255, 0, 0)
local FullBright = false
local NoFog = false
local StretchResOn = false

local CrosshairVisible = false
local CrosshairColor = Color3.fromRGB(0, 255, 0)
local CrosshairSize = 10
local CrosshairThickness = 2
local CrosshairRainbow = false
local CrosshairRotation = false
local CrosshairRotSpeed = 90
local CurrentCrosshairRot = 0

local HitboxOn = false
local HitboxSize = 5
local HitboxColor = Color3.fromRGB(255, 0, 0)
local HitboxTransparency = 0.5

local StatsVisible = false
local fpsBuffer = {} -- For smoothing FPS

local AntiFlingOn = false
local AntiVoidOn = false
local AntiVoidPart = nil

--// STRETCH RES LOGIC
getgenv().Resolution = {
    [".gg/scripters"] = 0.65
}

--// DRAWING OBJECTS
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 100
FOVCircle.Radius = AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = false

local FOVFillCircle = Drawing.new("Circle")
FOVFillCircle.Thickness = 0
FOVFillCircle.NumSides = 100
FOVFillCircle.Radius = AimFOV
FOVFillCircle.Filled = true
FOVFillCircle.Visible = false

local CrosshairL = Drawing.new("Line")
local CrosshairR = Drawing.new("Line")
local CrosshairT = Drawing.new("Line")
local CrosshairB = Drawing.new("Line")

local ESPObjects = {}
local BotESPObjects = {}
local RenderLoop
local HeartbeatLoop
local SteppedLoop 
_G.OptimumStatsRunning = true

--// ======================================================
--// CUSTOM FPS / PING UI (REALTIME)
--// ======================================================
local parentGui = (pcall(function() return CoreGui end) and CoreGui) or LP.PlayerGui

local StatsGui = Instance.new("ScreenGui")
StatsGui.Name = "OptimumStatsUI"
StatsGui.ResetOnSpawn = false
StatsGui.Enabled = false
StatsGui.Parent = parentGui

local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0, 160, 0, 60)
StatsFrame.Position = UDim2.new(0.5, -80, 0, 20)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatsFrame.BackgroundTransparency = 0.25
StatsFrame.BorderSizePixel = 0
StatsFrame.Active = true
StatsFrame.Parent = StatsGui

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 10)
StatsCorner.Parent = StatsFrame

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, 0, 0.5, 0)
FPSLabel.Position = UDim2.new(0, 0, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 16
FPSLabel.Text = "FPS: 0"
FPSLabel.Parent = StatsFrame

local PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(1, 0, 0.5, 0)
PingLabel.Position = UDim2.new(0, 0, 0.5, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextSize = 16
PingLabel.Text = "Ping: 0ms"
PingLabel.Parent = StatsFrame

local dragging, dragInput, dragStart, startPos
local function updateInput(input)
    local delta = input.Position - dragStart
    StatsFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

StatsFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = StatsFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

StatsFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

--// ======================================================
--// WINDOW CONFIGURATION
--// ======================================================

local Window = Library:CreateWindow({
    Title = "[Updated] Kalmin",
    Footer = "version: v0.0.1",
    Icon = 126925031200401,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Info = Window:AddTab("Info", "info"),
    UpdateLog = Window:AddTab("Update Log", "scroll"),
    Player = Window:AddTab("Player", "user"),
    Legit = Window:AddTab("Legit", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Hitbox = Window:AddTab("Hitbox", "box"),
    Performance = Window:AddTab("Performance", "activity"),
    Misc = Window:AddTab("Misc", "component"),
    Settings = Window:AddTab("Settings", "settings"),
}

--// ======================================================
--// INFO & UPDATE LOG TAB
--// ======================================================

local InfoGroup = Tabs.Info:AddLeftGroupbox("Player & Script Info")
local execName = identifyexecutor and identifyexecutor() or "Unknown Executor"

InfoGroup:AddLabel("Player Name: " .. LP.Name)
InfoGroup:AddLabel("Account Age: " .. LP.AccountAge .. " Days")
InfoGroup:AddLabel("Executor: " .. execName)
InfoGroup:AddLabel("Script Version: v0.0.1")
InfoGroup:AddDivider()

InfoGroup:AddButton({
    Text = "Copy YouTube Link",
    Func = function()
        setclipboard("https://www.youtube.com/channel/UCj_-Y0AkXIHnr4AiaJV8d9g")
        Library:Notify({ Title = "Copied!", Description = "YouTube Link copied to clipboard.", Time = 3 })
    end
})

InfoGroup:AddButton({
    Text = "Copy Discord Link",
    Func = function()
        setclipboard("https://discord.gg/DdjVT2aMwx")
        Library:Notify({ Title = "Copied!", Description = "Discord Link copied to clipboard.", Time = 3 })
    end
})

local UpdateGroup = Tabs.UpdateLog:AddLeftGroupbox("Latest Updates")
UpdateGroup:AddLabel("- Release [Beta]", true)

--// ======================================================
--// FLY LOGIC MANAGER (REWRITTEN: x1000 BETTER)
--// ======================================================

local function ManageFly(state)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    
    local hrp = char.HumanoidRootPart
    local hum = char.Humanoid
    
    if state then
        if bV then bV:Destroy() end
        if bG then bG:Destroy() end
        if hrp:FindFirstChild("FlyAttachment") then hrp.FlyAttachment:Destroy() end
        
        local attachment = Instance.new("Attachment", hrp)
        attachment.Name = "FlyAttachment"
        
        bV = Instance.new("LinearVelocity", hrp)
        bV.Attachment0 = attachment
        bV.MaxForce = math.huge
        bV.VectorVelocity = Vector3.zero
        bV.RelativeTo = Enum.ActuatorRelativeTo.World
        
        bG = Instance.new("AlignOrientation", hrp)
        bG.Mode = Enum.OrientationAlignmentMode.OneAttachment
        bG.Attachment0 = attachment
        bG.MaxTorque = math.huge
        bG.Responsiveness = 200
        bG.CFrame = hrp.CFrame
        
        hum.PlatformStand = true
    else
        if bV then bV:Destroy() bV = nil end
        if bG then bG:Destroy() bG = nil end
        if hrp:FindFirstChild("FlyAttachment") then hrp.FlyAttachment:Destroy() end
        hum.PlatformStand = false
    end
end

--// ======================================================
--// UI CREATION & LOGIC BINDING
--// ======================================================

--// PLAYER TAB
local MovementBox = Tabs.Player:AddLeftGroupbox("Movement")
local CameraBox = Tabs.Player:AddRightGroupbox("Camera")

MovementBox:AddToggle("Toggle_SpeedHack", { Text = "Speed Hack", Default = false })
Toggles.Toggle_SpeedHack:OnChanged(function()
    SpeedOn = Toggles.Toggle_SpeedHack.Value
    if not SpeedOn and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = 16 
    end
end)

MovementBox:AddSlider("Slider_WalkSpeed", { Text = "WalkSpeed Power", Default = 16, Min = 16, Max = 300, Rounding = 0, Suffix = " Speed" })
Options.Slider_WalkSpeed:OnChanged(function() WalkSpeed = Options.Slider_WalkSpeed.Value end)

MovementBox:AddDivider()

MovementBox:AddToggle("Toggle_JumpPower", { Text = "Jump Power", Default = false })
Toggles.Toggle_JumpPower:OnChanged(function()
    JumpOn = Toggles.Toggle_JumpPower.Value
    if not JumpOn and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
    end
end)

MovementBox:AddSlider("Slider_JumpPower", { Text = "Jump Power Amount", Default = 50, Min = 50, Max = 500, Rounding = 0, Suffix = " Power" })
Options.Slider_JumpPower:OnChanged(function() JumpPower = Options.Slider_JumpPower.Value end)

MovementBox:AddDivider()

MovementBox:AddToggle("Toggle_Noclip", { Text = "Noclip", Default = false })
Toggles.Toggle_Noclip:OnChanged(function() NoclipOn = Toggles.Toggle_Noclip.Value end)

MovementBox:AddDivider()

MovementBox:AddToggle("Toggle_Fly", { Text = "Enable Fly", Default = false })
Toggles.Toggle_Fly:OnChanged(function()
    FlyOn = Toggles.Toggle_Fly.Value
    ManageFly(FlyOn)
end)

MovementBox:AddSlider("Slider_FlySpeed", { Text = "Fly Speed", Default = 60, Min = 10, Max = 300, Rounding = 0, Suffix = " Studs" })
Options.Slider_FlySpeed:OnChanged(function() FlySpeed = Options.Slider_FlySpeed.Value end)

CameraBox:AddSlider("Slider_FOV", { Text = "Screen Field of View", Default = 70, Min = 10, Max = 120, Rounding = 0, Suffix = " FOV" })
Options.Slider_FOV:OnChanged(function() Camera.FieldOfView = Options.Slider_FOV.Value end)

CameraBox:AddToggle("Toggle_ThirdPerson", { Text = "Enable Third Person", Default = false })
Toggles.Toggle_ThirdPerson:OnChanged(function()
    ThirdPersonOn = Toggles.Toggle_ThirdPerson.Value
    if ThirdPersonOn then
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 128
        LP.CameraMinZoomDistance = 0.5
        task.wait(0.1)
        Camera.CFrame = Camera.CFrame * CFrame.new(0,0,10)
    else
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 128 -- Fixed Bug: Returns to normal limits
        LP.CameraMinZoomDistance = 0.5
    end
end)

-- Hook to fix the character reset third-person bug
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if ThirdPersonOn then
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 128
        LP.CameraMinZoomDistance = 0.5
        Camera.CFrame = Camera.CFrame * CFrame.new(0,0,10)
    else
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 128
        LP.CameraMinZoomDistance = 0.5
    end
end)

--// LEGIT TAB
local AimBox = Tabs.Legit:AddLeftGroupbox("Aim Assist")
local LockBox = Tabs.Legit:AddRightGroupbox("Mouse Lock & AutoShoot")
local AimSettingsBox = Tabs.Legit:AddLeftGroupbox("Settings")

AimBox:AddToggle("Toggle_AimAssist", { Text = "Enable Aim Assist", Default = false })
Toggles.Toggle_AimAssist:OnChanged(function() AimOn = Toggles.Toggle_AimAssist.Value end)

AimBox:AddDropdown("Dropdown_AimMode", { Values = { "Toggle", "Hold" }, Default = 1, Multi = false, Text = "Aim Assist Mode" })
Options.Dropdown_AimMode:OnChanged(function() AimMode = Options.Dropdown_AimMode.Value end)

AimBox:AddLabel("Hold Keybind"):AddKeyPicker("Key_AimHold", { Default = "MB2", SyncToggleState = false, Mode = "Hold", Text = "Aim Hold Key", NoUI = false })

AimBox:AddDropdown("Dropdown_TargetPart", { Values = { "Head", "HumanoidRootPart" }, Default = 1, Multi = false, Text = "Target Part" })
Options.Dropdown_TargetPart:OnChanged(function() AimTargetPart = Options.Dropdown_TargetPart.Value end)

AimBox:AddToggle("Toggle_AimTeamCheck", { Text = "Aim Team Check", Default = false })
Toggles.Toggle_AimTeamCheck:OnChanged(function() AimTeamCheck = Toggles.Toggle_AimTeamCheck.Value end)

AimBox:AddToggle("Toggle_AimWallCheck", { Text = "Aim Wall Check", Default = false })
Toggles.Toggle_AimWallCheck:OnChanged(function() AimWallCheck = Toggles.Toggle_AimWallCheck.Value end)

AimBox:AddToggle("Toggle_BotSupport", { Text = "Bot / NPC Support (Experimental)", Default = false })
Toggles.Toggle_BotSupport:OnChanged(function() AimBotSupport = Toggles.Toggle_BotSupport.Value end)

LockBox:AddToggle("Toggle_MouseLock", { Text = "Enable Mouse Lock", Default = false })
Toggles.Toggle_MouseLock:OnChanged(function() MouseLockOn = Toggles.Toggle_MouseLock.Value end)

LockBox:AddToggle("Toggle_AutoShoot", { Text = "Enable AutoShoot", Default = false })
Toggles.Toggle_AutoShoot:OnChanged(function() AutoShootOn = Toggles.Toggle_AutoShoot.Value end)

LockBox:AddSlider("Slider_AutoShootDelay", { Text = "AutoShoot Delay", Default = 100, Min = 0, Max = 1000, Rounding = 0, Suffix = " ms" })
Options.Slider_AutoShootDelay:OnChanged(function() AutoShootDelay = Options.Slider_AutoShootDelay.Value / 1000 end)

AimSettingsBox:AddToggle("Toggle_ShowFOV", { Text = "Show FOV Circle", Default = false })
Toggles.Toggle_ShowFOV:OnChanged(function() ShowFOV = Toggles.Toggle_ShowFOV.Value end)

AimSettingsBox:AddLabel("FOV Color"):AddColorPicker("Color_FOV", { Default = Color3.fromRGB(255, 255, 255), Title = "FOV Color" })
Options.Color_FOV:OnChanged(function() FOVColor = Options.Color_FOV.Value end)

AimSettingsBox:AddToggle("Toggle_FillFOV", { Text = "Fill FOV Area", Default = false })
Toggles.Toggle_FillFOV:OnChanged(function() FillFOV = Toggles.Toggle_FillFOV.Value end)

AimSettingsBox:AddSlider("Slider_FillTrans", { Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
Options.Slider_FillTrans:OnChanged(function() FOVTransparency = Options.Slider_FillTrans.Value / 100 end)

AimSettingsBox:AddSlider("Slider_AimFOV", { Text = "Aim FOV Radius", Default = 120, Min = 10, Max = 800, Rounding = 0, Suffix = " px" })
Options.Slider_AimFOV:OnChanged(function() AimFOV = Options.Slider_AimFOV.Value end)

AimSettingsBox:AddSlider("Slider_AimSmooth", { Text = "Aim Smoothing", Default = 15, Min = 1, Max = 100, Rounding = 0, Suffix = "%" })
Options.Slider_AimSmooth:OnChanged(function() AimSmooth = Options.Slider_AimSmooth.Value / 100 end)

--// VISUALS TAB
local ESPMasterBox = Tabs.Visuals:AddLeftGroupbox("ESP Master Settings")
local ESPBoxGrp = Tabs.Visuals:AddLeftGroupbox("ESP Elements")
local WorldBoxGrp = Tabs.Visuals:AddRightGroupbox("World & Crosshair")

ESPMasterBox:AddToggle("Toggle_MasterESP", { Text = "Enable Master ESP", Default = false })
Toggles.Toggle_MasterESP:OnChanged(function() MasterESP = Toggles.Toggle_MasterESP.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPBox", { Text = "Box ESP", Default = false })
Toggles.Toggle_ESPBox:OnChanged(function() ESPBox = Toggles.Toggle_ESPBox.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPBoxFill", { Text = "Box Fill", Default = false })
Toggles.Toggle_ESPBoxFill:OnChanged(function() ESPBoxFill = Toggles.Toggle_ESPBoxFill.Value end)

ESPBoxGrp:AddLabel("Box Fill Color"):AddColorPicker("Color_ESPBoxFill", { Default = Color3.fromRGB(255, 0, 0), Title = "Fill Color" })
Options.Color_ESPBoxFill:OnChanged(function() ESPBoxFillColor = Options.Color_ESPBoxFill.Value end)

ESPBoxGrp:AddSlider("Slider_BoxFillTrans", { Text = "Box Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
Options.Slider_BoxFillTrans:OnChanged(function() ESPBoxFillTrans = Options.Slider_BoxFillTrans.Value / 100 end)

ESPBoxGrp:AddToggle("Toggle_ESPName", { Text = "Name ESP", Default = false })
Toggles.Toggle_ESPName:OnChanged(function() ESPName = Toggles.Toggle_ESPName.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPHealth", { Text = "Health ESP", Default = false })
Toggles.Toggle_ESPHealth:OnChanged(function() ESPHealth = Toggles.Toggle_ESPHealth.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPDist", { Text = "Distance ESP", Default = false })
Toggles.Toggle_ESPDist:OnChanged(function() ESPDistance = Toggles.Toggle_ESPDist.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPTracer", { Text = "Tracer ESP", Default = false })
Toggles.Toggle_ESPTracer:OnChanged(function() ESPTracer = Toggles.Toggle_ESPTracer.Value end)

ESPBoxGrp:AddToggle("Toggle_ESPTeamCheck", { Text = "ESP Team Check", Default = false })
Toggles.Toggle_ESPTeamCheck:OnChanged(function() ESPTeamCheck = Toggles.Toggle_ESPTeamCheck.Value end)

ESPBoxGrp:AddLabel("Main ESP Color"):AddColorPicker("Color_ESPColor", { Default = Color3.fromRGB(255, 0, 0), Title = "ESP Color" })
Options.Color_ESPColor:OnChanged(function() ESPColor = Options.Color_ESPColor.Value end)

WorldBoxGrp:AddToggle("Toggle_FullBright", { Text = "Perfect Full Brightness", Default = false })
Toggles.Toggle_FullBright:OnChanged(function()
    FullBright = Toggles.Toggle_FullBright.Value
    if not FullBright then
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
end)

WorldBoxGrp:AddToggle("Toggle_NoFog", { Text = "No Fog", Default = false })
Toggles.Toggle_NoFog:OnChanged(function()
    NoFog = Toggles.Toggle_NoFog.Value
    if not NoFog then Lighting.FogEnd = 100000 end
end)

WorldBoxGrp:AddToggle("Toggle_StretchRes", { Text = "Stretch Resolution", Default = false })
Toggles.Toggle_StretchRes:OnChanged(function() StretchResOn = Toggles.Toggle_StretchRes.Value end)

WorldBoxGrp:AddSlider("Slider_StretchAmt", { Text = "Stretch Amount", Default = 0.65, Min = 0.1, Max = 2, Rounding = 2 })
Options.Slider_StretchAmt:OnChanged(function() getgenv().Resolution[".gg/scripters"] = Options.Slider_StretchAmt.Value end)

WorldBoxGrp:AddDivider()

WorldBoxGrp:AddToggle("Toggle_CrosshairVisible", { Text = "Custom Crosshair", Default = false })
Toggles.Toggle_CrosshairVisible:OnChanged(function() CrosshairVisible = Toggles.Toggle_CrosshairVisible.Value end)

WorldBoxGrp:AddToggle("Toggle_CrosshairRainbow", { Text = "Rainbow Crosshair", Default = false })
Toggles.Toggle_CrosshairRainbow:OnChanged(function() CrosshairRainbow = Toggles.Toggle_CrosshairRainbow.Value end)

WorldBoxGrp:AddToggle("Toggle_CrosshairRotation", { Text = "Rotate Crosshair", Default = false })
Toggles.Toggle_CrosshairRotation:OnChanged(function() CrosshairRotation = Toggles.Toggle_CrosshairRotation.Value end)

WorldBoxGrp:AddSlider("Slider_CrosshairRotSpeed", { Text = "Rotation Speed", Default = 90, Min = 10, Max = 360, Rounding = 0, Suffix = " Deg/s" })
Options.Slider_CrosshairRotSpeed:OnChanged(function() CrosshairRotSpeed = Options.Slider_CrosshairRotSpeed.Value end)

WorldBoxGrp:AddSlider("Slider_CrosshairSize", { Text = "Crosshair Size", Default = 10, Min = 5, Max = 50, Rounding = 0 })
Options.Slider_CrosshairSize:OnChanged(function() CrosshairSize = Options.Slider_CrosshairSize.Value end)

WorldBoxGrp:AddSlider("Slider_CrosshairThickness", { Text = "Crosshair Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0 })
Options.Slider_CrosshairThickness:OnChanged(function() CrosshairThickness = Options.Slider_CrosshairThickness.Value end)

WorldBoxGrp:AddLabel("Crosshair Color"):AddColorPicker("Color_CrosshairColor", { Default = Color3.fromRGB(0, 255, 0), Title = "Crosshair Color" })
Options.Color_CrosshairColor:OnChanged(function() CrosshairColor = Options.Color_CrosshairColor.Value end)

--// HITBOX TAB
local HitboxGrp = Tabs.Hitbox:AddLeftGroupbox("Expander")

HitboxGrp:AddToggle("Toggle_HitboxOn", { Text = "Enable Hitbox Expander", Default = false })
Toggles.Toggle_HitboxOn:OnChanged(function() HitboxOn = Toggles.Toggle_HitboxOn.Value end)

HitboxGrp:AddSlider("Slider_HitboxSize", { Text = "Hitbox Size", Default = 5, Min = 2, Max = 50, Rounding = 0, Suffix = " Studs" })
Options.Slider_HitboxSize:OnChanged(function() HitboxSize = Options.Slider_HitboxSize.Value end)

HitboxGrp:AddSlider("Slider_HitboxTrans", { Text = "Hitbox Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
Options.Slider_HitboxTrans:OnChanged(function() HitboxTransparency = Options.Slider_HitboxTrans.Value / 100 end)

HitboxGrp:AddLabel("Hitbox Color"):AddColorPicker("Color_HitboxColor", { Default = Color3.fromRGB(255, 0, 0), Title = "Hitbox Color" })
Options.Color_HitboxColor:OnChanged(function() HitboxColor = Options.Color_HitboxColor.Value end)

--// PERFORMANCE TAB
local PerfGrp = Tabs.Performance:AddLeftGroupbox("Optimization & Tracking")

PerfGrp:AddToggle("Toggle_ShowStatsUI", { Text = "Show FPS / Ping Tracker UI", Default = false })
Toggles.Toggle_ShowStatsUI:OnChanged(function()
    StatsVisible = Toggles.Toggle_ShowStatsUI.Value
    StatsGui.Enabled = StatsVisible
end)

PerfGrp:AddDivider()
PerfGrp:AddButton({
    Text = "FPS Boost",
    Func = function()
        Library:Notify({ Title = "Boosting FPS...", Description = "Deleting heavy textures, decals, and particles.", Time = 3 })
        local function CleanPart(child)
            if child:IsA("BasePart") then
                child.Material = Enum.Material.SmoothPlastic
                child.Reflectance = 0
                child.CastShadow = false
            elseif child:IsA("Decal") or child:IsA("Texture") then
                if child.Name ~= "Face" then child:Destroy() end
            elseif child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Sparkles") then
                child.Enabled = false
            end
        end
        for _, v in pairs(workspace:GetDescendants()) do CleanPart(v) end
        workspace.DescendantAdded:Connect(CleanPart)
        Lighting.GlobalShadows = false
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)
    end
})

--// MISC TAB (NAMETAG INTEGRATION)
local NametagGrp = Tabs.Misc:AddLeftGroupbox("Nametag Spoofer")

NametagGrp:AddToggle("Toggle_Nametag", { Text = "Enable Custom Nametag", Default = false })
NametagGrp:AddInput("Input_Nametag", { Default = "[VIP]", Numeric = false, Finished = false, Text = "Tag Text", Placeholder = "Enter Name..." })
NametagGrp:AddLabel("Nametag Color"):AddColorPicker("Color_Nametag", { Default = Color3.fromRGB(255, 215, 0), Title = "Tag Color" })

-- Hooked logic functions for nametag
local function tagChar(char)
    if not Toggles.Toggle_Nametag.Value then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.DisplayName = Options.Input_Nametag.Value .. " " .. LP.Name
    end
end

if LP.Character then task.spawn(tagChar, LP.Character) end
LP.CharacterAdded:Connect(tagChar)

local function patchList()
    if not Toggles.Toggle_Nametag.Value then return end
    local list = CoreGui:FindFirstChild("PlayerList")
    if not list then return end
    for _, obj in ipairs(list:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = obj.Text
            if txt == LP.Name or txt == LP.DisplayName then
                if not txt:find(Options.Input_Nametag.Value, 1, true) then
                    obj.Text = Options.Input_Nametag.Value .. " " .. txt
                    obj.TextColor3 = Options.Color_Nametag.Value
                end
            end
        end
    end
end

local function patchBoard()
    if not Toggles.Toggle_Nametag.Value then return end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local mg = pg:FindFirstChild("MainGui")
    if not mg then return end
    local m = mg:FindFirstChild("main")
    if not m then return end
    local t = m:FindFirstChild("tos")
    if not t then return end
    local s = t:FindFirstChild("scroll")
    if not s then return end

    for _, sample in ipairs(s:GetChildren()) do
        if sample.Name == "sample" then
            local nl = sample:FindFirstChild("name")
            if nl and nl:IsA("TextLabel") and nl.Text:find(LP.Name, 1, true) then
                if not nl.Text:find(Options.Input_Nametag.Value, 1, true) then
                    nl.Text = Options.Input_Nametag.Value .. " " .. nl.Text
                    nl.TextColor3 = Options.Color_Nametag.Value
                end
            end
        end
    end
end

local UtilityGrp = Tabs.Misc:AddRightGroupbox("Utilities & Protections")
UtilityGrp:AddButton({
    Text = "Reset UI Toggles",
    Func = function()
        for i, toggle in pairs(Toggles) do
            toggle:SetValue(false)
        end
        Library:Notify({ Title = "Reset", Description = "All toggles have been reset to default.", Time = 3 })
    end
})

UtilityGrp:AddButton({
    Text = "Give Btools",
    Tooltip = "Gives standard building tools.",
    Func = function()
        local tools = {"Hammer", "Clone", "Grab"}
        for i, v in pairs(tools) do
            local tool = Instance.new("HopperBin")
            tool.BinType = Enum.BinType[v]
            tool.Parent = LP.Backpack
        end
        Library:Notify({ Title = "Success", Description = "Btools added to backpack.", Time = 3 })
    end
})
UtilityGrp:AddLabel("Can cause bans in anti-cheat games if you enable this!", { Risky = true })
UtilityGrp:AddDivider()

UtilityGrp:AddToggle("Toggle_AntiFling", { Text = "Anti-Fling", Default = false })
Toggles.Toggle_AntiFling:OnChanged(function() AntiFlingOn = Toggles.Toggle_AntiFling.Value end)

UtilityGrp:AddToggle("Toggle_AntiVoid", { Text = "Anti-Void", Default = false })
Toggles.Toggle_AntiVoid:OnChanged(function()
    AntiVoidOn = Toggles.Toggle_AntiVoid.Value
    if AntiVoidOn then
        if not AntiVoidPart then
            AntiVoidPart = Instance.new("Part")
            AntiVoidPart.Size = Vector3.new(20000, 2, 20000)
            AntiVoidPart.Position = Vector3.new(0, workspace.FallenPartsDestroyHeight + 25, 0)
            AntiVoidPart.Anchored = true
            AntiVoidPart.Transparency = 0.6
            AntiVoidPart.BrickColor = BrickColor.new("Bright blue")
            AntiVoidPart.Material = Enum.Material.Neon
            AntiVoidPart.Parent = workspace
        end
    else
        if AntiVoidPart then AntiVoidPart:Destroy() AntiVoidPart = nil end
    end
end)

--// SETTINGS TAB
local UtilSetGrp = Tabs.Settings:AddLeftGroupbox("Utility")
local MenuSetGrp = Tabs.Settings:AddLeftGroupbox("Menu")

UtilSetGrp:AddToggle("Toggle_CustomCursor", { Text = "Enable UI Custom Cursor", Default = true })
Toggles.Toggle_CustomCursor:OnChanged(function()
    Library.ShowCustomCursor = Toggles.Toggle_CustomCursor.Value
    -- Force disable game cursor when custom is active
    if Library.ShowCustomCursor then
        UIS.MouseIconEnabled = false 
    else
        UIS.MouseIconEnabled = true
    end
end)

UtilSetGrp:AddButton({
    Text = "Server Hop (Best Match)",
    Func = function()
        Library:Notify({ Title = "Server Hopping...", Description = "Looking for the best populated server.", Time = 3 })
        local PlaceId = game.PlaceId
        local success, result = pcall(function()
            -- Descending sort pulls the fullest servers first
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
        end)
        
        if success and result and result.data then
            local hopped = false
            for _, server in ipairs(result.data) do
                -- Prevent joining full servers or the same server
                if server.playing < server.maxPlayers and server.playing > 0 and server.id ~= game.JobId then
                    Library:Notify({ Title = "Server Found", Description = "Teleporting to server with " .. server.playing .. " players.", Time = 3 })
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LP)
                    hopped = true
                    break
                end
            end
            if not hopped then Library:Notify({ Title = "Failed", Description = "Could not find a valid better server to join.", Time = 3 }) end
        else
            Library:Notify({ Title = "Error", Description = "Failed to fetch server list.", Time = 3 })
        end
    end
})

UtilSetGrp:AddButton({ Text = "Unload UI", Func = function() Library:Unload() end })

MenuSetGrp:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

-- UI Visiblity Tracking for Mouse Lock
UIS.InputBegan:Connect(function(input, gpe)
    if type(Options.MenuKeybind.Value) == "string" and input.KeyCode.Name == Options.MenuKeybind.Value then
        isUiOpen = not isUiOpen
    end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Optimum")
SaveManager:SetFolder("Optimum/" .. game.PlaceId)
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()


--// ======================================================
--// UTILITY FUNCTIONS
--// ======================================================

local function GetVisible(part)
    local cast = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, part.Position}, {LP.Character, part.Parent})
    return #cast == 0
end

local function GetValidTargets()
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            if p.Character.Humanoid.Health > 0 then
                table.insert(targets, {Character = p.Character, Name = p.Name, Team = p.Team})
            end
        end
    end
    
    if AimBotSupport then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") then
                if obj ~= LP.Character and not Players:GetPlayerFromCharacter(obj) and obj.Humanoid.Health > 0 then
                    table.insert(targets, {Character = obj, Name = obj.Name, Team = nil})
                end
            end
        end
    end
    return targets
end

local function GetClosestTarget()
    local target = nil
    local dist = AimFOV
    
    for _, entity in pairs(GetValidTargets()) do
        local part = entity.Character:FindFirstChild(AimTargetPart)
        if part then
            if AimTeamCheck and entity.Team and entity.Team == LP.Team then continue end
            if AimWallCheck and not GetVisible(part) then continue end
            
            local pos, screenVis = Camera:WorldToViewportPoint(part.Position)
            if screenVis then
                local mouseDist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mouseDist < dist then
                    dist = mouseDist
                    target = entity.Character
                end
            end
        end
    end
    return target
end

--// ======================================================
--// ESP SYSTEM LOGIC
--// ======================================================

local function SetupDrawings()
    local drawings = {
        box = Drawing.new("Square"),
        boxFill = Drawing.new("Square"),
        name = Drawing.new("Text"),
        health = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        tracer = Drawing.new("Line")
    }
    
    drawings.box.Filled = false
    drawings.box.Thickness = 1
    drawings.boxFill.Filled = true
    drawings.boxFill.Thickness = 0
    
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Size = 14
    
    drawings.health.Center = true
    drawings.health.Outline = true
    drawings.health.Size = 14
    
    drawings.dist.Center = true
    drawings.dist.Outline = true
    drawings.dist.Size = 14
    
    return drawings
end

local function CreateESP(p)
    if not ESPObjects[p] then
        ESPObjects[p] = SetupDrawings()
    end
end

local function RemoveESP(p)
    if ESPObjects[p] then
        for _, obj in pairs(ESPObjects[p]) do pcall(function() obj:Remove() end) end
        ESPObjects[p] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end

--// ======================================================
--// CORE LOOP (RENDER STEPPED)
--// ======================================================

RenderLoop = RunService.RenderStepped:Connect(function(dt)
    -- FPS TRACKING (SMOOTH REALTIME)
    if StatsVisible then
        table.insert(fpsBuffer, math.floor(1 / dt))
        if #fpsBuffer > 15 then table.remove(fpsBuffer, 1) end
        local avgFPS = 0
        for _, v in ipairs(fpsBuffer) do avgFPS = avgFPS + v end
        FPSLabel.Text = "FPS: " .. math.floor(avgFPS / #fpsBuffer)
    end
    
    -- NAMETAG PATCHES
    patchList()
    patchBoard()

    if StretchResOn then
        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1)
    end

    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        if SpeedOn then hum.WalkSpeed = WalkSpeed end
        if JumpOn then
            if hum.UseJumpPower then 
                hum.JumpPower = JumpPower 
            else 
                hum.JumpHeight = JumpPower/3 
            end
        end
    end

    if FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end
    
    if NoFog then
        Lighting.FogEnd = 100000
    end

    FOVCircle.Visible = ShowFOV
    FOVCircle.Radius = AimFOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = FOVColor

    FOVFillCircle.Visible = FillFOV
    FOVFillCircle.Radius = AimFOV
    FOVFillCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVFillCircle.Color = FOVColor
    FOVFillCircle.Transparency = 1 - FOVTransparency

    -- AIM LOGIC
    local shouldAim = false
    if AimOn then
        if AimMode == "Toggle" then
            shouldAim = true
        elseif AimMode == "Hold" and Options.Key_AimHold:GetState() then
            shouldAim = true
        end
    end

    local currentLock = nil

    if shouldAim or MouseLockOn then
        local targetChar = GetClosestTarget()
        if targetChar and targetChar:FindFirstChild(AimTargetPart) then
            currentLock = targetChar
            local aimPos = targetChar[AimTargetPart].Position
            
            if shouldAim then
                local lookCF = CFrame.new(Camera.CFrame.Position, aimPos)
                Camera.CFrame = Camera.CFrame:Lerp(lookCF, AimSmooth)
            end
            
            -- Only lock mouse if UI is closed
            if MouseLockOn and not isUiOpen then
                local vector, onScreen = Camera:WorldToScreenPoint(aimPos)
                if onScreen then
                    mousemoverel((vector.X - Mouse.X) * AimSmooth, (vector.Y - Mouse.Y) * AimSmooth)
                end
            end
        end
    end

    -- HEAVILY IMPROVED AUTOSHOOT LOGIC
    if AutoShootOn and currentLock and (tick() - lastAutoShoot > AutoShootDelay) then
        mouse1press()
        task.wait(0.01) -- Quick hardware register
        mouse1release()
        lastAutoShoot = tick()
    end

    -- CROSSHAIR LOGIC
    if CrosshairVisible then
        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2
        
        local activeColor = CrosshairColor
        if CrosshairRainbow then activeColor = Color3.fromHSV((tick() % 5) / 5, 1, 1) end
        if CrosshairRotation then
            CurrentCrosshairRot = CurrentCrosshairRot + math.rad(CrosshairRotSpeed * dt)
        else
            CurrentCrosshairRot = 0
        end

        local function UpdateCrosshairLine(line, angleOffset)
            local angle = CurrentCrosshairRot + angleOffset
            local dir = Vector2.new(math.cos(angle), math.sin(angle))
            line.From = Vector2.new(cx, cy) + (dir * 2)
            line.To = Vector2.new(cx, cy) + (dir * CrosshairSize)
            line.Color = activeColor
            line.Thickness = CrosshairThickness
            line.Visible = true
        end

        UpdateCrosshairLine(CrosshairR, 0)
        UpdateCrosshairLine(CrosshairB, math.pi / 2)
        UpdateCrosshairLine(CrosshairL, math.pi)
        UpdateCrosshairLine(CrosshairT, math.pi * 1.5)
    else
        CrosshairL.Visible = false; CrosshairR.Visible = false; CrosshairT.Visible = false; CrosshairB.Visible = false
    end

    -- ESP MASTER LOGIC
    if MasterESP then
        -- Handle Bot/NPC ESP dynamically
        if AimBotSupport then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid") and obj ~= LP.Character and not Players:GetPlayerFromCharacter(obj) then
                    if not BotESPObjects[obj] then BotESPObjects[obj] = SetupDrawings() end
                end
            end
        else
            for obj, esp in pairs(BotESPObjects) do
                for _, d in pairs(esp) do pcall(function() d:Remove() end) end
            end
            BotESPObjects = {}
        end

        local function RenderESP(char, esp, team)
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                local canShow = onScreen
                if ESPTeamCheck and team and team == LP.Team then canShow = false end
                
                if canShow and hum.Health > 0 then
                    local sizeX = 2000 / pos.Z
                    local sizeY = 3000 / pos.Z
                    local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)

                    esp.box.Visible = ESPBox
                    esp.box.Size = Vector2.new(sizeX, sizeY)
                    esp.box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                    esp.box.Color = ESPColor
                    
                    esp.boxFill.Visible = ESPBoxFill
                    esp.boxFill.Size = Vector2.new(sizeX, sizeY)
                    esp.boxFill.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                    esp.boxFill.Color = ESPBoxFillColor
                    esp.boxFill.Transparency = 1 - ESPBoxFillTrans

                    esp.name.Visible = ESPName
                    esp.name.Text = char.Name
                    esp.name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 15)
                    esp.name.Color = Color3.fromRGB(255, 255, 255)

                    esp.health.Visible = ESPHealth
                    esp.health.Text = "HP: " .. math.floor(hum.Health)
                    esp.health.Position = Vector2.new(pos.X, pos.Y + sizeY/2 + 5)
                    esp.health.Color = Color3.fromRGB(0, 255, 0)
                    
                    esp.dist.Visible = ESPDistance
                    esp.dist.Text = "[" .. dist .. "s]"
                    esp.dist.Position = Vector2.new(pos.X, pos.Y + sizeY/2 + (ESPHealth and 20 or 5))
                    esp.dist.Color = Color3.fromRGB(255, 255, 255)

                    esp.tracer.Visible = ESPTracer
                    esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.tracer.To = Vector2.new(pos.X, pos.Y + sizeY/2)
                    esp.tracer.Color = ESPColor
                else
                    esp.box.Visible = false; esp.boxFill.Visible = false; esp.name.Visible = false; esp.health.Visible = false; esp.dist.Visible = false; esp.tracer.Visible = false
                end
            else
                esp.box.Visible = false; esp.boxFill.Visible = false; esp.name.Visible = false; esp.health.Visible = false; esp.dist.Visible = false; esp.tracer.Visible = false
            end
        end

        for player, esp in pairs(ESPObjects) do RenderESP(player.Character, esp, player.Team) end
        for botChar, esp in pairs(BotESPObjects) do
            if botChar.Parent then RenderESP(botChar, esp, nil) else
                for _, d in pairs(esp) do pcall(function() d:Remove() end) end
                BotESPObjects[botChar] = nil
            end
        end
    else
        for _, esp in pairs(ESPObjects) do
            esp.box.Visible = false; esp.boxFill.Visible = false; esp.name.Visible = false; esp.health.Visible = false; esp.dist.Visible = false; esp.tracer.Visible = false
        end
        for _, esp in pairs(BotESPObjects) do
            esp.box.Visible = false; esp.boxFill.Visible = false; esp.name.Visible = false; esp.health.Visible = false; esp.dist.Visible = false; esp.tracer.Visible = false
        end
    end
end)

--// ======================================================
--// SLOWER LOOP (HEARTBEAT & STATS)
--// ======================================================

task.spawn(function()
    while _G.OptimumStatsRunning do
        task.wait(0.5)
        if StatsVisible then
            pcall(function()
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                PingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
            end)
        end
    end
end)

HeartbeatLoop = RunService.Heartbeat:Connect(function()
    for _, entity in pairs(GetValidTargets()) do
        local hrp = entity.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if HitboxOn then
                hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                hrp.Transparency = HitboxTransparency
                hrp.Color = HitboxColor
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            else
                if hrp.Transparency ~= 1 then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end

    if FlyOn and bV and bG and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        local moveDir = hum.MoveDirection
        
        if moveDir.Magnitude > 0 then
            local pitch = Camera.CFrame.LookVector.Y
            if moveDir.Magnitude == 0 then pitch = 0 end 
            
            local velocityDir = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then velocityDir = velocityDir + Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then velocityDir = velocityDir - Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then velocityDir = velocityDir - Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then velocityDir = velocityDir + Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then velocityDir = velocityDir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then velocityDir = velocityDir - Vector3.new(0, 1, 0) end
            
            if velocityDir.Magnitude > 0 then
                bV.VectorVelocity = velocityDir.Unit * FlySpeed
            else
                bV.VectorVelocity = Vector3.zero
            end
        else
            bV.VectorVelocity = Vector3.zero
        end
        bG.CFrame = Camera.CFrame
    end

    -- DYNAMIC ANTI-VOID SAFETY NET
    if AntiVoidOn and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        local fallHeight = workspace.FallenPartsDestroyHeight + 50
        if hrp.Position.Y < fallHeight then
            hrp.Velocity = Vector3.zero
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 250, 0) -- Teleport safely back into the sky
            Library:Notify({ Title = "Anti-Void Triggered", Description = "Saved you from falling into the void!", Time = 2 })
        end
    end
end)

SteppedLoop = RunService.Stepped:Connect(function()
    if LP.Character then
        if NoclipOn then
            for _, part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end

    if AntiFlingOn then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

--// ======================================================
--// CLEAN & SAFE UNLOAD HANDLER
--// ======================================================

Library:OnUnload(function()
    pcall(function() if RenderLoop then RenderLoop:Disconnect() end end)
    pcall(function() if HeartbeatLoop then HeartbeatLoop:Disconnect() end end)
    pcall(function() if SteppedLoop then SteppedLoop:Disconnect() end end)
    
    _G.OptimumStatsRunning = false 
    
    pcall(function() FOVCircle:Remove() end)
    pcall(function() FOVFillCircle:Remove() end)
    pcall(function() CrosshairL:Remove() end)
    pcall(function() CrosshairR:Remove() end)
    pcall(function() CrosshairT:Remove() end)
    pcall(function() CrosshairB:Remove() end)
    
    for _, esp in pairs(ESPObjects) do for _, obj in pairs(esp) do pcall(function() obj:Remove() end) end end
    for _, esp in pairs(BotESPObjects) do for _, obj in pairs(esp) do pcall(function() obj:Remove() end) end end
    ESPObjects = {}
    BotESPObjects = {}
    
    if StatsGui then pcall(function() StatsGui:Destroy() end) end
    if AntiVoidPart then pcall(function() AntiVoidPart:Destroy() end) end
    
    ManageFly(false)

    -- Return the entire game to exact normal state
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = 16
            LP.Character.Humanoid.JumpPower = 50
        end
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 400
        LP.CameraMinZoomDistance = 0.5
        Camera.FieldOfView = 70
        UIS.MouseIconEnabled = true
        
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = 100000 
        Lighting.Brightness = 1
    end)
end)
