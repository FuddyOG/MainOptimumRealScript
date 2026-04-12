--// Loader

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

--// THEME SAVING LOGIC (Fix for UI Themes not applying)
local ChosenTheme = "Default"
pcall(function()
    if isfile and isfile("Optimum_Theme.txt") then
        ChosenTheme = readfile("Optimum_Theme.txt")
    end
end)

--// SETTINGS & VARIABLES
local WalkSpeed = 16
local JumpPower = 50
local SpeedOn = false
local JumpOn = false
local NoclipOn = false 

local FlyOn = false
local FlySpeed = 60
local bV, bG -- BodyMovers for Fly

local AimOn = false
local AimSmooth = 0.15
local AimFOV = 120
local AimTeamCheck = false
local AimWallCheck = false
local ShowFOV = false

local ESPBox = false
local ESPName = false
local ESPTracer = false
local ESPHealth = false
local ESPTeamCheck = false
local ESPColor = Color3.fromRGB(255, 0, 0)
local FullBright = false

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

--// DRAWING OBJECTS (FOR FOV AND CROSSHAIR)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 100
FOVCircle.Radius = AimFOV
FOVCircle.Filled = false
FOVCircle.Visible = false

local CrosshairL = Drawing.new("Line")
local CrosshairR = Drawing.new("Line")
local CrosshairT = Drawing.new("Line")
local CrosshairB = Drawing.new("Line")

local ESPObjects = {}
local RenderLoop
local HeartbeatLoop
local SteppedLoop 
_G.OptimumStatsRunning = true -- Clean thread killer for Unload

--// ======================================================
--// CUSTOM FPS / PING UI CREATION
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

-- Dragging Logic for the Stats UI
local dragging
local dragInput
local dragStart
local startPos

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

local Window = Rayfield:CreateWindow({
    Name = "[Free] Optimum | Version  0.0.7 [Mobile Fixed & Updated]",
    LoadingTitle = "Optimum System",
    LoadingSubtitle = "by BN",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Optimum",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink", 
        RememberJoins = true 
    },
    KeySystem = false,
    Theme = ChosenTheme 
})

--// TABS (Fixed Sprite Sheet Bug by using Native Lucide Icons)
local PlayerTab = Window:CreateTab("Player", "user")
local LegitTab = Window:CreateTab("Legit", "crosshair")
local VisualTab = Window:CreateTab("Visuals", "eye")
local HitboxTab = Window:CreateTab("Hitbox", "box")
local PerformanceTab = Window:CreateTab("Performance", "activity")
local MiscTab = Window:CreateTab("Misc", "settings")

--// ======================================================
--// FLY LOGIC MANAGER
--// ======================================================

local function ManageFly(state)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    
    local hrp = char.HumanoidRootPart
    local hum = char.Humanoid
    
    if state then
        if bV then bV:Destroy() end
        if bG then bG:Destroy() end
        
        bV = Instance.new("BodyVelocity")
        bV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bV.Velocity = Vector3.zero
        bV.Parent = hrp
        
        bG = Instance.new("BodyGyro")
        bG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bG.P = 10000
        bG.CFrame = hrp.CFrame
        bG.Parent = hrp
        
        hum.PlatformStand = true
    else
        if bV then bV:Destroy() bV = nil end
        if bG then bG:Destroy() bG = nil end
        hum.PlatformStand = false
    end
end

--// ======================================================
--// PLAYER TAB
--// ======================================================

PlayerTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "Toggle_SpeedHack", 
    Callback = function(Value)
        SpeedOn = Value
        if not Value and LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = 16 
        end
    end
})

PlayerTab:CreateSlider({
    Name = "WalkSpeed Power",
    Range = {16, 300},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "Slider_WalkSpeed",
    Callback = function(Value)
        WalkSpeed = Value
    end
})

PlayerTab:CreateDivider()

PlayerTab:CreateToggle({
    Name = "Jump Power",
    CurrentValue = false,
    Flag = "Toggle_JumpPower",
    Callback = function(Value)
        JumpOn = Value
        if not Value and LP.Character and LP.Character:FindFirstChild("Humanoid") then
            local hum = LP.Character.Humanoid
            if hum.UseJumpPower then
                hum.JumpPower = 50
            else
                hum.JumpHeight = 7.2
            end
        end
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power Amount",
    Range = {50, 500},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "Slider_JumpPower",
    Callback = function(Value)
        JumpPower = Value
    end
})

PlayerTab:CreateDivider()

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Toggle_Noclip",
    Callback = function(Value)
        NoclipOn = Value
    end
})

PlayerTab:CreateDivider()

PlayerTab:CreateToggle({
    Name = "Enable Fly (Mobile & PC Supported)",
    CurrentValue = false,
    Flag = "Toggle_Fly",
    Callback = function(Value)
        FlyOn = Value
        ManageFly(Value)
    end
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 60,
    Flag = "Slider_FlySpeed",
    Callback = function(Value)
        FlySpeed = Value
    end
})

PlayerTab:CreateSlider({
    Name = "Screen Field of View",
    Range = {70, 120},
    Increment = 1,
    Suffix = "FOV",
    CurrentValue = 70,
    Flag = "Slider_FOV",
    Callback = function(Value)
        Camera.FieldOfView = Value
    end
})

--// ======================================================
--// LEGIT TAB (AIM ASSIST)
--// ======================================================

LegitTab:CreateToggle({
    Name = "Aim Assist",
    CurrentValue = false,
    Flag = "Toggle_AimAssist",
    Callback = function(Value)
        AimOn = Value
    end
})

LegitTab:CreateToggle({
    Name = "Aim Team Check",
    CurrentValue = false,
    Flag = "Toggle_AimTeamCheck",
    Callback = function(Value)
        AimTeamCheck = Value
    end
})

LegitTab:CreateToggle({
    Name = "Aim Wall Check",
    CurrentValue = false,
    Flag = "Toggle_AimWallCheck",
    Callback = function(Value)
        AimWallCheck = Value
    end
})

LegitTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "Toggle_ShowFOV",
    Callback = function(Value)
        ShowFOV = Value
    end
})

LegitTab:CreateSlider({
    Name = "Aim FOV Radius",
    Range = {10, 800},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 120,
    Flag = "Slider_AimFOV",
    Callback = function(Value)
        AimFOV = Value
    end
})

LegitTab:CreateSlider({
    Name = "Aim Smoothing",
    Range = {1, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 15,
    Flag = "Slider_AimSmooth",
    Callback = function(Value)
        AimSmooth = Value / 100
    end
})

--// ======================================================
--// VISUALS TAB (ESP & CROSSHAIR)
--// ======================================================

VisualTab:CreateSection("ESP Settings")

VisualTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Flag = "Toggle_ESPBox",
    Callback = function(Value)
        ESPBox = Value
    end
})

VisualTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = false,
    Flag = "Toggle_ESPName",
    Callback = function(Value)
        ESPName = Value
    end
})

VisualTab:CreateToggle({
    Name = "Health ESP",
    CurrentValue = false,
    Flag = "Toggle_ESPHealth",
    Callback = function(Value)
        ESPHealth = Value
    end
})

VisualTab:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = false,
    Flag = "Toggle_ESPTracer",
    Callback = function(Value)
        ESPTracer = Value
    end
})

VisualTab:CreateToggle({
    Name = "ESP Team Check",
    CurrentValue = false,
    Flag = "Toggle_ESPTeamCheck",
    Callback = function(Value)
        ESPTeamCheck = Value
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Color_ESPColor",
    Callback = function(Value)
        ESPColor = Value
    end
})

VisualTab:CreateSection("World Visuals")

VisualTab:CreateToggle({
    Name = "Perfect Full Brightness",
    CurrentValue = false,
    Flag = "Toggle_FullBright",
    Callback = function(Value)
        FullBright = Value
        if not Value then
            -- Fallback (Game usually handles restoring defaults)
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
    end
})

VisualTab:CreateSection("Crosshair Settings")

VisualTab:CreateToggle({
    Name = "Custom Crosshair",
    CurrentValue = false,
    Flag = "Toggle_CrosshairVisible",
    Callback = function(Value)
        CrosshairVisible = Value
    end
})

VisualTab:CreateToggle({
    Name = "Rainbow Crosshair",
    CurrentValue = false,
    Flag = "Toggle_CrosshairRainbow",
    Callback = function(Value)
        CrosshairRainbow = Value
    end
})

VisualTab:CreateToggle({
    Name = "Rotate Crosshair",
    CurrentValue = false,
    Flag = "Toggle_CrosshairRotation",
    Callback = function(Value)
        CrosshairRotation = Value
    end
})

VisualTab:CreateSlider({
    Name = "Rotation Speed",
    Range = {10, 360},
    Increment = 1,
    Suffix = "Deg/s",
    CurrentValue = 90,
    Flag = "Slider_CrosshairRotSpeed",
    Callback = function(Value)
        CrosshairRotSpeed = Value
    end
})

VisualTab:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "Color_CrosshairColor",
    Callback = function(Value)
        CrosshairColor = Value
    end
})

VisualTab:CreateSlider({
    Name = "Crosshair Size",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag = "Slider_CrosshairSize",
    Callback = function(Value)
        CrosshairSize = Value
    end
})

VisualTab:CreateSlider({
    Name = "Crosshair Thickness",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Flag = "Slider_CrosshairThickness",
    Callback = function(Value)
        CrosshairThickness = Value
    end
})

--// ======================================================
--// HITBOX TAB
--// ======================================================

HitboxTab:CreateToggle({
    Name = "Enable Hitbox Expander",
    CurrentValue = false,
    Flag = "Toggle_HitboxOn",
    Callback = function(Value)
        HitboxOn = Value
    end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 5,
    Flag = "Slider_HitboxSize",
    Callback = function(Value)
        HitboxSize = Value
    end
})

HitboxTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Color_HitboxColor",
    Callback = function(Value)
        HitboxColor = Value
    end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "Slider_HitboxTrans",
    Callback = function(Value)
        HitboxTransparency = Value / 100
    end
})

--// ======================================================
--// PERFORMANCE TAB (NEW)
--// ======================================================

PerformanceTab:CreateSection("Monitoring")

PerformanceTab:CreateToggle({
    Name = "Show FPS / Ping Tracker UI",
    CurrentValue = false,
    Flag = "Toggle_ShowStatsUI",
    Callback = function(Value)
        StatsVisible = Value
        StatsGui.Enabled = Value
    end
})

PerformanceTab:CreateSection("Optimization")

PerformanceTab:CreateButton({
    Name = "FPS Boost (Removes Graphics & Textures)",
    Callback = function()
        Rayfield:Notify({
            Title = "Boosting FPS...",
            Content = "Deleting heavy textures, decals, and particles.",
            Duration = 3,
            Image = "zap",
        })
        
        -- Clean up world models
        local function CleanPart(child)
            if child:IsA("BasePart") then
                child.Material = Enum.Material.SmoothPlastic
                child.Reflectance = 0
                child.CastShadow = false
            elseif child:IsA("Decal") or child:IsA("Texture") then
                if child.Name ~= "Face" then -- Keep faces so characters don't look completely cursed
                    child:Destroy()
                end
            elseif child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Sparkles") then
                child.Enabled = false
            end
        end

        for _, v in pairs(workspace:GetDescendants()) do
            CleanPart(v)
        end
        
        -- Ensure any newly added parts get optimized too
        workspace.DescendantAdded:Connect(CleanPart)

        -- Clear lighting effects
        Lighting.GlobalShadows = false
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        
        pcall(function()
            sethiddenproperty(Lighting, "Technology", 2) -- Forces Compatibility Mode if exploit supports it
        end)
    end,
})

--// ======================================================
--// MISC TAB (CONFIG, THEMES, SERVER HOP & UNLOAD)
--// ======================================================

MiscTab:CreateSection("Configuration")

MiscTab:CreateButton({
    Name = "Save Config Forcefully",
    Callback = function()
        Rayfield:Notify({
            Title = "Config Auto-Saved",
            Content = "All UI elements automatically sync to your device folder instantly.",
            Duration = 3,
            Image = "save",
        })
    end,
})

MiscTab:CreateSection("Utility")

MiscTab:CreateButton({
    Name = "Server Hop (Find Empty Server)",
    Callback = function()
        Rayfield:Notify({
            Title = "Server Hopping...",
            Content = "Looking for a new public server.",
            Duration = 3,
            Image = "globe",
        })
        
        local PlaceId = game.PlaceId
        local success, result = pcall(function()
            -- Ask Roblox API for server list
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        
        if success and result and result.data then
            local hopped = false
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LP)
                    hopped = true
                    break
                end
            end
            if not hopped then
                Rayfield:Notify({
                    Title = "Failed",
                    Content = "Could not find a valid server to join.",
                    Duration = 3,
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to fetch server list.",
                Duration = 3,
            })
        end
    end,
})

MiscTab:CreateSection("UI Customization")

MiscTab:CreateDropdown({
    Name = "UI Theme",
    Options = {"Default", "Ocean", "Light", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Serenity"},
    CurrentOption = {ChosenTheme},
    MultipleOptions = false,
    Flag = "Dropdown_Theme",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        pcall(function()
            if writefile then
                writefile("Optimum_Theme.txt", selected)
            end
        end)
        Rayfield:Notify({
            Title = "Theme Selected",
            Content = selected .. " theme saved! Re-execute the script to apply changes permanently.",
            Duration = 5,
            Image = "palette",
        })
    end,
})

MiscTab:CreateSection("System")

MiscTab:CreateButton({
    Name = "Unload UI (Destroy Script)",
    Callback = function()
        -- Safely disconnect active loops
        pcall(function() if RenderLoop then RenderLoop:Disconnect() end end)
        pcall(function() if HeartbeatLoop then HeartbeatLoop:Disconnect() end end)
        pcall(function() if SteppedLoop then SteppedLoop:Disconnect() end end)
        
        -- Stop Stats Thread
        _G.OptimumStatsRunning = false 
        
        -- Safely clean up drawings (Wrapped in pcall to prevent errors if already destroyed)
        pcall(function() FOVCircle:Remove() end)
        pcall(function() CrosshairL:Remove() end)
        pcall(function() CrosshairR:Remove() end)
        pcall(function() CrosshairT:Remove() end)
        pcall(function() CrosshairB:Remove() end)
        
        -- Destroy ESP
        for _, esp in pairs(ESPObjects) do
            for _, obj in pairs(esp) do
                pcall(function() obj:Remove() end)
            end
        end
        ESPObjects = {}
        
        -- Destroy Stats UI
        if StatsGui then
            pcall(function() StatsGui:Destroy() end)
        end
        
        -- Disable BodyMovers and Reset WalkSpeed
        ManageFly(false)
        pcall(function()
            if LP.Character and LP.Character:FindFirstChild("Humanoid") then
                LP.Character.Humanoid.WalkSpeed = 16
                LP.Character.Humanoid.JumpPower = 50
            end
        end)

        -- Safely Destroy Rayfield instance
        pcall(function()
            Rayfield:Destroy()
        end)
    end,
})

--// ======================================================
--// UTILITY FUNCTIONS
--// ======================================================

local function GetVisible(part)
    local cast = Camera:GetPartsObscuringTarget({Camera.CFrame.Position, part.Position}, {LP.Character, part.Parent})
    return #cast == 0
end

local function GetClosestPlayer()
    local target = nil
    local dist = AimFOV
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            if AimTeamCheck and p.Team == LP.Team then continue end
            if AimWallCheck and not GetVisible(p.Character.Head) then continue end
            
            local pos, screenVis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if screenVis then
                local mouseDist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if mouseDist < dist then
                    dist = mouseDist
                    target = p
                end
            end
        end
    end
    return target
end

--// ======================================================
--// ESP SYSTEM LOGIC
--// ======================================================

local function CreateESP(p)
    local drawings = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        health = Drawing.new("Text"),
        tracer = Drawing.new("Line")
    }
    
    drawings.box.Filled = false
    drawings.box.Thickness = 1
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Size = 14
    drawings.health.Center = true
    drawings.health.Outline = true
    drawings.health.Size = 14
    
    ESPObjects[p] = drawings
end

local function RemoveESP(p)
    if ESPObjects[p] then
        for _, obj in pairs(ESPObjects[p]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[p] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LP then CreateESP(p) end end

--// ======================================================
--// CORE LOOP (RENDER STEPPED)
--// ======================================================

local lastFrameTick = tick()
local frameCount = 0

RenderLoop = RunService.RenderStepped:Connect(function(dt)
    --// Calculate FPS properly for the UI
    if StatsVisible then
        frameCount = frameCount + 1
        if tick() - lastFrameTick >= 1 then
            FPSLabel.Text = "FPS: " .. frameCount
            frameCount = 0
            lastFrameTick = tick()
        end
    end

    --// Player Logic (Speed & Jump)
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

    --// Perfected FullBright Logic
    if FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end

    --// FOV Circle Logic
    FOVCircle.Visible = ShowFOV
    FOVCircle.Radius = AimFOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)

    --// Aim Assist Logic
    if AimOn then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local aimPos = target.Character.Head.Position
            local lookCF = CFrame.new(Camera.CFrame.Position, aimPos)
            Camera.CFrame = Camera.CFrame:Lerp(lookCF, AimSmooth)
        end
    end

    --// Crosshair Logic
    if CrosshairVisible then
        local cx = Camera.ViewportSize.X / 2
        local cy = Camera.ViewportSize.Y / 2
        
        local activeColor = CrosshairColor
        if CrosshairRainbow then
            activeColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
        end

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
        CrosshairL.Visible = false
        CrosshairR.Visible = false
        CrosshairT.Visible = false
        CrosshairB.Visible = false
    end

    --// ESP Render Logic
    for player, esp in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            local canShow = onScreen
            if ESPTeamCheck and player.Team == LP.Team then canShow = false end
            
            if canShow and hum.Health > 0 then
                local sizeX = 2000 / pos.Z
                local sizeY = 3000 / pos.Z

                esp.box.Visible = ESPBox
                esp.box.Size = Vector2.new(sizeX, sizeY)
                esp.box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                esp.box.Color = ESPColor

                esp.name.Visible = ESPName
                esp.name.Text = player.Name
                esp.name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 15)
                esp.name.Color = Color3.fromRGB(255, 255, 255)

                esp.health.Visible = ESPHealth
                esp.health.Text = "HP: " .. math.floor(hum.Health)
                esp.health.Position = Vector2.new(pos.X, pos.Y + sizeY/2 + 5)
                esp.health.Color = Color3.fromRGB(0, 255, 0)

                esp.tracer.Visible = ESPTracer
                esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                esp.tracer.To = Vector2.new(pos.X, pos.Y + sizeY/2)
                esp.tracer.Color = ESPColor
            else
                esp.box.Visible = false
                esp.name.Visible = false
                esp.health.Visible = false
                esp.tracer.Visible = false
            end
        else
            esp.box.Visible = false
            esp.name.Visible = false
            esp.health.Visible = false
            esp.tracer.Visible = false
        end
    end
end)

--// ======================================================
--// SLOWER LOOP (HEARTBEAT & STATS)
--// ======================================================

task.spawn(function()
    while _G.OptimumStatsRunning do
        task.wait(1)
        if StatsVisible then
            pcall(function()
                -- Grabbing Ping securely from Roblox performance stats
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                PingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
            end)
        end
    end
end)

HeartbeatLoop = RunService.Heartbeat:Connect(function()
    --// Hitbox Expander
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
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

    --// Camera-Relative Fly Logic
    if FlyOn and bV and bG and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        local moveDir = hum.MoveDirection
        
        if moveDir.Magnitude > 0 then
            local pitch = Camera.CFrame.LookVector.Y
            local flyVelocity = Vector3.new(moveDir.X, pitch, moveDir.Z).Unit * FlySpeed
            bV.Velocity = flyVelocity
        else
            bV.Velocity = Vector3.zero
        end
        bG.CFrame = Camera.CFrame
    end
end)

--// ======================================================
--// NOCLIP LOGIC (STEPPED)
--// ======================================================

SteppedLoop = RunService.Stepped:Connect(function()
    if NoclipOn and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

--// INITIAL LOAD
Rayfield:LoadConfiguration()
