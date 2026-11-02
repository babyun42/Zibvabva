--=====================================================================
--  Zibvabva — Material You edition (Multi-Fling Update)
--=====================================================================
local function getGlobalEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and env then return env end
    end
    return _G
end
local GENV = getGlobalEnv()

local KILL_NAMES = {
    "MaterialYouUI",
    "MaterialLoader",
    "ZibvabvaESP",
    "ZibvabvaFOV",
}

local function getAllGuiParents()
    local list = {}
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then table.insert(list, h) end
    end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then table.insert(list, cg) end
    local ok3, pg = pcall(function()
        return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end)
    if ok3 and pg then table.insert(list, pg) end
    return list
end

local function purgeOrphanGuis()
    for _, parent in ipairs(getAllGuiParents()) do
        for _, name in ipairs(KILL_NAMES) do
            local g = parent:FindFirstChild(name)
            if g then
                pcall(function() g:Destroy() end)
            end
        end
    end
end

if GENV.__Zibvabva_Unload then
    pcall(GENV.__Zibvabva_Unload)
end

purgeOrphanGuis()

local function placeholderUnload()
    purgeOrphanGuis()
end
GENV.__Zibvabva_Unload = placeholderUnload

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/babyun42/Zibvabva/refs/heads/main/MaterialYouUI.lua?v=5"))()

--=====================================================================
--  SERVICES
--=====================================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local Stats             = game:GetService("Stats")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()
local currentWalkSpeed  = 16
local currentJumpPower  = 50

--=====================================================================
--  CONNECTION TRACKER
--=====================================================================
local __conns = {}
local function track(conn)
    table.insert(__conns, conn)
    return conn
end
local function untrackAll()
    for i = #__conns, 1, -1 do
        pcall(function() __conns[i]:Disconnect() end)
        __conns[i] = nil
    end
end

local isUnloaded = false
local Window = nil
local unloadScript

--=====================================================================
--  CONFIG
--=====================================================================
local Config = {
    Camera_FOV = 70,
    ESP_Enabled = false,
    Boxes_Enabled = true,
    Tracers_Enabled = false,
    HealthBar_Enabled = true,
    HeadDot_Enabled = true,
    NameTag_Enabled = true,
    UseDisplayName = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    TargetColor = Color3.fromRGB(255, 0, 0),
    UseTargetInvert = false,
    RainbowNames = false,
    RainbowBoxes = false,
    RainbowTracers = false,
    HealthBarPosition = "Right",
    Aimbot_Enabled = false,
    AimMethod = "Mouse",
    FOV_Visible = true,
    FOV_Radius = 100,
    FOV_Color = Color3.fromRGB(255, 255, 255),
    FOV_Rainbow = false,
    TargetPart = "Head",
    AimKey = "RightClick",
    TeamCheck = false,
    Highlight_Enabled = true,
    Highlight_Color = Color3.fromRGB(255, 255, 255),
    Highlight_Rainbow = false,
}

local flySpeed = 35
local isFlying = false
local isNoclip = false
local spinbotEnabled = false
local spinbotSpeed = 20
local InfiniteJumpEnabled = false
local clickTpEnabled = false
local infZoomEnabled = false
local altZoomDesired = false
local altZoomEnabled = false
local freecamActive = false
local invisibleDistance = 200000
local IsInvisible = false
local flingActive = false
local flingAllActive = false
local antiFlingEnabled = false

local originalMaxZoom = LocalPlayer.CameraMaxZoomDistance or 4000
local currentMaxZoom = originalMaxZoom
local originalGlobalShadows = Lighting.GlobalShadows

local invisibleParts = {}
local invisibleConnection = nil
local noclipConnection = nil
local flyConnection = nil
local playerPartsCache = {}
local antiFlingConnection = nil
local freecamCamPos = Vector3.new()
local freecamRotX = 0
local freecamRotY = 0
local freecamFOV = 70
local freecamSpeed = 50

local IsLocking = false
local GetTarget
local flyToggle
local camAltZoomToggle
local highlightToggle

--=====================================================================
--  NEW FLING LOGIC (From KILASIK)
--=====================================================================
local SelectedTargets = {}
local FlingActive = false
local OldPos = nil
local FPDH = workspace.FallenPartsDestroyHeight
local LastFlingNotify = 0

local function SkidFling(TargetPlayer)
    if isUnloaded then return end
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            OldPos = RootPart.CFrame
        end

        if THumanoid and THumanoid.Sit then
            return
        end

        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end

        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid and FlingActive then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not FlingActive
        end

        workspace.FallenPartsDestroyHeight = 0/0

        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid

        -- Reset character position
        if OldPos and RootPart then
            repeat
                RootPart.CFrame = OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
                task.wait()
            until (RootPart.Position - OldPos.p).Magnitude < 25 or isUnloaded
            workspace.FallenPartsDestroyHeight = FPDH
        end
    end
end

local function StartMultiFling()
    if FlingActive then return end
    local count = 0
    for _ in pairs(SelectedTargets) do count = count + 1 end
    if count == 0 then
        if Window then Window:Notify({ Title = "Error", Text = "No targets selected!" }) end
        return
    end

    FlingActive = true
    flingAllActive = true -- для совместимости со старой логикой
    if Window then Window:Notify({ Title = "Fling", Text = "Flinging " .. count .. " target(s)..." }) end

    task.spawn(function()
        while FlingActive and not isUnloaded do
            local validTargets = {}
            for name, player in pairs(SelectedTargets) do
                if player and player.Parent and player.Character then
                    validTargets[name] = player
                else
                    SelectedTargets[name] = nil
                end
            end

            for _, player in pairs(validTargets) do
                if FlingActive and not isUnloaded then
                    pcall(SkidFling, player)
                    task.wait(0.1)
                else
                    break
                end
            end
            task.wait(0.5)
        end
    end)
end

local function StopMultiFling()
    if not FlingActive then return end
    FlingActive = false
    flingAllActive = false
    if Window then Window:Notify({ Title = "Fling", Text = "Stopped" }) end
end

--=====================================================================
--  FLIGHT
--=====================================================================
local function onFlyStep()
    if freecamActive then return end
    if UserInputService:GetFocusedTextBox() then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"))

    if not char or not hum or not torso or not isFlying then return end

    local bg = torso:FindFirstChild("ZibBodyGyro")
    if bg then bg.CFrame = Camera.CFrame end

    local speedMultiplier = flySpeed / 35
    local f = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
    local r = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
    local u = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)

    local moveDir = (Camera.CFrame.LookVector * f) + (Camera.CFrame.RightVector * r) + (Vector3.new(0, 1, 0) * u)

    if moveDir.Magnitude > 0 then
        char:TranslateBy(moveDir.Unit * speedMultiplier)
    end
end

local function setFlightState(state)
    if isUnloaded then return end
    isFlying = state
    if flyToggle then pcall(function() flyToggle:Set(state, true) end) end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return end

    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")

    if isFlying then
        if torso then
            local oldBg = torso:FindFirstChild("ZibBodyGyro")
            local oldBv = torso:FindFirstChild("ZibBodyVelocity")
            if oldBg then oldBg:Destroy() end
            if oldBv then oldBv:Destroy() end

            local bg = Instance.new("BodyGyro")
            bg.Name = "ZibBodyGyro"
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.Parent = torso

            local bv = Instance.new("BodyVelocity")
            bv.Name = "ZibBodyVelocity"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = torso
        end

        hum.PlatformStand = true
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

        if char:FindFirstChild("Animate") then char.Animate.Disabled = true end
        for _, v in pairs(hum:GetPlayingAnimationTracks()) do v:AdjustSpeed(0) end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end

        if not flyConnection then
            flyConnection = RunService.RenderStepped:Connect(onFlyStep)
        end
        Window:Notify({ Title = "Flight", Text = "Enabled" })
    else
        if torso then
            local bg = torso:FindFirstChild("ZibBodyGyro")
            local bv = torso:FindFirstChild("ZibBodyVelocity")
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
        end

        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)

        if char:FindFirstChild("Animate") then char.Animate.Disabled = false end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
        end

        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        Window:Notify({ Title = "Flight", Text = "Disabled" })
    end
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    if isUnloaded then return end
    if isFlying then
        isFlying = false
        if flyToggle then pcall(function() flyToggle:Set(false, true) end) end
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    end

    task.wait(0.5)
    if isUnloaded then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum.WalkSpeed = currentWalkSpeed or 16
        hum.JumpPower = currentJumpPower or 50
    end
    if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
end))

--=====================================================================
--  NOCLIP
--=====================================================================
local noclipToggle
local function setNoclipState(state)
    if isUnloaded then return end
    isNoclip = state
    if noclipToggle then pcall(function() noclipToggle:Set(state, true) end) end

    if isNoclip then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        end
        Window:Notify({ Title = "Noclip", Text = "Enabled" })
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        Window:Notify({ Title = "Noclip", Text = "Disabled" })
    end
end

--=====================================================================
--  INVISIBILITY
--=====================================================================
local function setupInvisibleParts()
    local char = LocalPlayer.Character
    if not char then return end
    invisibleParts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency == 0 then
            table.insert(invisibleParts, p)
        end
    end
end

local function ToggleInvisible(state)
    if IsInvisible == state and invisibleConnection ~= nil then return end
    IsInvisible = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local rp = char and char:FindFirstChild("HumanoidRootPart")
    if IsInvisible then
        setupInvisibleParts()
        for _, p in ipairs(invisibleParts) do p.Transparency = 0.5 end
        if not invisibleConnection then
            invisibleConnection = RunService.Heartbeat:Connect(function()
                if IsInvisible and rp and hum then
                    local cur = rp.CFrame
                    local orig = hum.CameraOffset
                    local low = cur * CFrame.new(0, -invisibleDistance, 0)
                    local off = low:ToObjectSpace(CFrame.new(cur.Position)).Position
                    rp.CFrame = low
                    hum.CameraOffset = off
                    RunService.RenderStepped:Wait()
                    rp.CFrame = cur
                    hum.CameraOffset = orig
                end
            end)
        end
        Window:Notify({ Title = "Invisibility", Text = "Enabled" })
    else
        if invisibleConnection then
            invisibleConnection:Disconnect()
            invisibleConnection = nil
        end
        for _, p in ipairs(invisibleParts) do
            if p and p.Parent then p.Transparency = 0 end
        end
        if hum then hum.CameraOffset = Vector3.zero end
        Window:Notify({ Title = "Invisibility", Text = "Disabled" })
    end
end

--=====================================================================
--  SPINBOT / INFINITE JUMP / ANTI-AFK
--=====================================================================
track(RunService.RenderStepped:Connect(function()
    if spinbotEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
        end
    end
end))

track(UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

local afkConn
local function toggleAntiAFK(state)
    if state then
        if not afkConn then
            afkConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end
    else
        if afkConn then
            afkConn:Disconnect()
            afkConn = nil
        end
    end
end

--=====================================================================
--  HITBOX
--=====================================================================
local HitboxConfig = { Enabled = false, Size = 15, Color = Color3.fromRGB(150, 150, 150), Transparency = 0.7 }

track(RunService.RenderStepped:Connect(function()
    if HitboxConfig.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(HitboxConfig.Size, HitboxConfig.Size, HitboxConfig.Size)
                    hrp.Transparency = HitboxConfig.Transparency
                    hrp.Color = HitboxConfig.Color
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                end
            end
        end
    end
end))

local function ResetHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = false
            end
        end
    end
end

--=====================================================================
--  ESP & HIGHLIGHT
--=====================================================================
local function getParentGui()
    if gethui then return gethui() end
    local ok = pcall(function() return CoreGui:GetChildren() end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ESPContainer = Instance.new("ScreenGui")
ESPContainer.Name = "ZibvabvaESP"
ESPContainer.ResetOnSpawn = false
ESPContainer.IgnoreGuiInset = true
ESPContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPContainer.Parent = getParentGui()

local ESPCache = {}
local function createESP(plr)
    if ESPCache[plr] then return end
    local box = Instance.new("Frame", ESPContainer)
    box.BackgroundTransparency = 1
    box.Visible = false
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Thickness = 1.5
    boxStroke.Color = Config.BoxColor

    local tracer = Instance.new("Frame", ESPContainer)
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.Visible = false

    local nameTag = Instance.new("TextLabel", ESPContainer)
    nameTag.BackgroundTransparency = 1
    nameTag.Size = UDim2.new(0, 200, 0, 20)
    nameTag.AnchorPoint = Vector2.new(0.5, 1)
    nameTag.TextSize = 14
    nameTag.Font = Enum.Font.SourceSansBold
    nameTag.TextStrokeTransparency = 0
    nameTag.Visible = false

    local hbOutline = Instance.new("Frame", box)
    hbOutline.BackgroundColor3 = Color3.new(0, 0, 0)
    hbOutline.BackgroundTransparency = 0.3
    hbOutline.BorderSizePixel = 0
    hbOutline.Visible = false
    local hbOutlineCorner = Instance.new("UICorner", hbOutline)
    hbOutlineCorner.CornerRadius = UDim.new(0, 2)

    local hb = Instance.new("Frame", hbOutline)
    hb.BorderSizePixel = 0
    hb.AnchorPoint = Vector2.new(0, 1)
    hb.Position = UDim2.new(0, 0, 1, 0)
    local hbCorner = Instance.new("UICorner", hb)
    hbCorner.CornerRadius = UDim.new(0, 2)

    local headDot = Instance.new("Frame", ESPContainer)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Visible = false
    local headDotCorner = Instance.new("UICorner", headDot)
    headDotCorner.CornerRadius = UDim.new(1, 0)

    ESPCache[plr] = { Box = box, BoxStroke = boxStroke, Tracer = tracer, NameTag = nameTag, HBOutline = hbOutline, HB = hb, HeadDot = headDot }
end

local function removeESP(plr)
    if ESPCache[plr] then
        for _, o in pairs(ESPCache[plr]) do
            pcall(function() o:Destroy() end)
        end
        ESPCache[plr] = nil
    end
end

local function getBoundingBox2D(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false, 0, 0, 0, 0 end
    local root = char:FindFirstChild("HumanoidRootPart")
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local isAcc = part:FindFirstAncestorOfClass("Accessory") ~= nil
            local isTool = part:FindFirstAncestorOfClass("Tool") ~= nil
            local tooFar = root and (part.Position - root.Position).Magnitude > 4.5
            if not isAcc and not isTool and not tooFar then
                local cf = part.CFrame
                local s = part.Size
                local corners = {
                    cf * CFrame.new(-s.X/2, -s.Y/2, -s.Z/2), cf * CFrame.new( s.X/2, -s.Y/2, -s.Z/2),
                    cf * CFrame.new(-s.X/2,  s.Y/2, -s.Z/2), cf * CFrame.new( s.X/2,  s.Y/2, -s.Z/2),
                    cf * CFrame.new(-s.X/2, -s.Y/2,  s.Z/2), cf * CFrame.new( s.X/2, -s.Y/2,  s.Z/2),
                    cf * CFrame.new(-s.X/2,  s.Y/2,  s.Z/2), cf * CFrame.new( s.X/2,  s.Y/2,  s.Z/2),
                }
                for _, cornerCf in ipairs(corners) do
                    local sp = Camera:WorldToViewportPoint(cornerCf.Position)
                    if sp.Z > 0 then
                        any = true
                        minX = math.min(minX, sp.X); minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X); maxY = math.max(maxY, sp.Y)
                    end
                end
            end
        end
    end
    if not any then return false, 0, 0, 0, 0 end
    local w, h = maxX - minX, maxY - minY
    if w > h * 2 or h > 800 or w > 800 then return false, 0, 0, 0, 0 end
    return true, minX, minY, w, h
end

local function hideAllESP()
    for _, v in pairs(ESPCache) do
        v.Box.Visible = false
        v.Tracer.Visible = false
        v.NameTag.Visible = false
        v.HeadDot.Visible = false
        v.HBOutline.Visible = false
    end
end

local function getInvertedColor(c) return Color3.new(1 - c.R, 1 - c.G, 1 - c.B) end

GetTarget = function()
    local current, maxDist = nil, Config.FOV_Radius
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Config.TargetPart) then
            if Config.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            local part = plr.Character[Config.TargetPart]
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < maxDist then current = part; maxDist = d end
            end
        end
    end
    return current
end

track(RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local rainbow = Color3.fromHSV(tick() % 5 / 5, 1, 1)

    if not Config.ESP_Enabled then hideAllESP() end

    local activeTarget = nil
    if Config.Aimbot_Enabled and IsLocking then activeTarget = GetTarget() end
    local activeTargetPlayer = activeTarget and Players:GetPlayerFromCharacter(activeTarget.Parent) or nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not ESPCache[plr] then createESP(plr) end
            local v = ESPCache[plr]
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if Config.ESP_Enabled and myRoot and root and hum and head then
                local onScreen, bx, by, sw, sh = getBoundingBox2D(char)
                local headSP, headOn = Camera:WorldToViewportPoint(head.Position)
                local mySP = Camera:WorldToViewportPoint(myRoot.Position)

                if onScreen and sw > 0 and sh > 0 and headSP.Z > 0 then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    local targeted = (plr == activeTargetPlayer)

                    local baseBox = Config.RainbowBoxes and rainbow or Config.BoxColor
                    local boxCol = targeted and (Config.UseTargetInvert and getInvertedColor(baseBox) or Config.TargetColor) or baseBox
                    local baseName = Config.RainbowNames and rainbow or Config.NameColor
                    local nameCol = targeted and (Config.UseTargetInvert and getInvertedColor(baseName) or Config.TargetColor) or baseName

                    if Config.Boxes_Enabled then
                        v.Box.Size = UDim2.fromOffset(sw, sh)
                        v.Box.Position = UDim2.fromOffset(bx, by)
                        v.BoxStroke.Color = boxCol
                        v.Box.Visible = true
                    else v.Box.Visible = false end

                    if Config.Tracers_Enabled then
                        local vp = Camera.ViewportSize
                        local from = Vector2.new(vp.X * 0.5, vp.Y)
                        local to = Vector2.new(bx + sw / 2, by + sh)
                        local dx = to.X - from.X
                        local dy = to.Y - from.Y
                        local midX = (from.X + to.X) * 0.5
                        local midY = (from.Y + to.Y) * 0.5
                        local d = math.sqrt(dx * dx + dy * dy)
                        local angle = math.deg(math.atan2(dy, dx))

                        v.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
                        v.Tracer.Size = UDim2.fromOffset(d, 2)
                        v.Tracer.Position = UDim2.fromOffset(midX, midY)
                        v.Tracer.Rotation = angle
                        v.Tracer.BackgroundColor3 = Config.RainbowTracers and rainbow or Config.TracerColor
                        v.Tracer.Visible = true
                    else v.Tracer.Visible = false end

                    v.NameTag.Text = Config.UseDisplayName and plr.DisplayName or plr.Name
                    v.NameTag.Position = UDim2.fromOffset(bx + sw / 2, by - 6)
                    v.NameTag.TextColor3 = nameCol
                    v.NameTag.Visible = Config.NameTag_Enabled

                    if Config.HeadDot_Enabled and headOn and headSP.Z > 0 then
                        local ds = math.clamp(1000 / dist, 4, 12)
                        v.HeadDot.Position = UDim2.fromOffset(headSP.X, headSP.Y)
                        v.HeadDot.Size = UDim2.fromOffset(ds, ds)
                        v.HeadDot.BackgroundColor3 = boxCol
                        v.HeadDot.Visible = true
                    else v.HeadDot.Visible = false end

                    if Config.HealthBar_Enabled then
                        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local hpc = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hp)
                        if Config.HealthBarPosition == "Right" then
                            v.HBOutline.Size = UDim2.new(0, 4, 1, 0); v.HBOutline.Position = UDim2.new(1, 3, 0, 0)
                            v.HB.Size = UDim2.new(1, 0, hp, 0); v.HB.Position = UDim2.new(0, 0, 1, 0); v.HB.AnchorPoint = Vector2.new(0, 1)
                        elseif Config.HealthBarPosition == "Left" then
                            v.HBOutline.Size = UDim2.new(0, 4, 1, 0); v.HBOutline.Position = UDim2.new(0, -7, 0, 0)
                            v.HB.Size = UDim2.new(1, 0, hp, 0); v.HB.Position = UDim2.new(0, 0, 1, 0); v.HB.AnchorPoint = Vector2.new(0, 1)
                        else
                            v.HBOutline.Size = UDim2.new(1, 0, 0, 4); v.HBOutline.Position = UDim2.new(0, 0, 0, -7)
                            v.HB.Size = UDim2.new(hp, 0, 1, 0); v.HB.Position = UDim2.new(0, 0, 0, 0); v.HB.AnchorPoint = Vector2.new(0, 0)
                        end
                        v.HB.BackgroundColor3 = hpc
                        v.HBOutline.Visible = true
                    else v.HBOutline.Visible = false end
                else
                    v.Box.Visible = false; v.Tracer.Visible = false; v.NameTag.Visible = false; v.HeadDot.Visible = false; v.HBOutline.Visible = false
                end
            elseif v then
                v.Box.Visible = false; v.Tracer.Visible = false; v.NameTag.Visible = false; v.HeadDot.Visible = false; v.HBOutline.Visible = false
            end
        end
    end
end))

track(Players.PlayerRemoving:Connect(removeESP))

--=====================================================================
--  HIGHLIGHT ESP
--=====================================================================
local HIGHLIGHT_NAME = "ZibvabvaHighlight"
local highlightWasActive = false

local function purgeAllZibvabvaHighlights()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Highlight") and obj.Name == HIGHLIGHT_NAME then
                    obj.Enabled = false
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Name == HIGHLIGHT_NAME then
                obj.Enabled = false
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

local function ensureHighlight(plr)
    local char = plr.Character
    if not char then return nil end
    local h = char:FindFirstChild(HIGHLIGHT_NAME)
    if h and h:IsA("Highlight") then return h end
    h = Instance.new("Highlight")
    h.Name = HIGHLIGHT_NAME
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.OutlineTransparency = 1
    h.FillTransparency = 0.55
    h.Parent = char
    return h
end

track(RunService.RenderStepped:Connect(function()
    if isUnloaded then return end
    local active = Config.ESP_Enabled and Config.Highlight_Enabled
    local rainbowCol = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    local targetCol = Config.Highlight_Rainbow and rainbowCol or Config.Highlight_Color

    if active then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local h = ensureHighlight(plr)
                if h then
                    h.Enabled = true
                    h.FillColor = targetCol
                end
            end
        end
        highlightWasActive = true
    else
        if highlightWasActive then
            highlightWasActive = false
            purgeAllZibvabvaHighlights()
        end
    end
end))

track(Players.PlayerRemoving:Connect(function(plr)
    local char = plr.Character
    if char then
        local h = char:FindFirstChild(HIGHLIGHT_NAME)
        if h then pcall(function() h:Destroy() end) end
    end
end))

--=====================================================================
--  AIMBOT
--=====================================================================
local FOVGui = Instance.new("ScreenGui", getParentGui())
FOVGui.Name = "ZibvabvaFOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true

local FOVCircle = Instance.new("Frame", FOVGui)
FOVCircle.BackgroundTransparency = 1
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Visible = false
local FOVCircleCorner = Instance.new("UICorner", FOVCircle)
FOVCircleCorner.CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVCircle)
FOVStroke.Thickness = 1.5
FOVStroke.Color = Config.FOV_Color

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = true
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsLocking = true
    elseif input.KeyCode and input.KeyCode.Name == Config.AimKey then
        IsLocking = true
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = false
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsLocking = false
    elseif input.KeyCode and input.KeyCode.Name == Config.AimKey then
        IsLocking = false
    end
end))

track(RunService.RenderStepped:Connect(function()
    if Config.Aimbot_Enabled and Config.FOV_Visible then
        FOVCircle.Visible = true
        local mp = UserInputService:GetMouseLocation()
        FOVCircle.Position = UDim2.fromOffset(mp.X, mp.Y)
        FOVCircle.Size = UDim2.fromOffset(Config.FOV_Radius * 2, Config.FOV_Radius * 2)
        if Config.FOV_Rainbow then FOVStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else FOVStroke.Color = Config.FOV_Color end
    else FOVCircle.Visible = false end

    if Config.Aimbot_Enabled and IsLocking then
        local t = GetTarget()
        if t then
            if Config.AimMethod == "Camera" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
            else
                local sp, on = Camera:WorldToViewportPoint(t.Position)
                if on then
                    if mousemoverel then
                        local mp = UserInputService:GetMouseLocation()
                        mousemoverel((sp.X - mp.X) / 2, (sp.Y - mp.Y) / 2)
                    else
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
                    end
                end
            end
        end
    end
end))

--=====================================================================
--  TRIGGER BOT
--=====================================================================
local triggerbotEnabled = false
local triggerbotKey = Enum.KeyCode.G
local triggerbotDelay = 0
local triggerbotHolding = false
local triggerbotLastShot = 0

local function isMouseOnPlayer()
    local target = Mouse.Target
    if not target then return nil end
    local parent = target.Parent
    if not parent then return nil end
    local hum = parent:FindFirstChildOfClass("Humanoid")
    if hum then return hum, parent end
    local grandparent = parent.Parent
    if grandparent then
        local ghum = grandparent:FindFirstChildOfClass("Humanoid")
        if ghum then return ghum, grandparent end
        local ggp = grandparent.Parent
        if ggp then
            local gghum = ggp:FindFirstChildOfClass("Humanoid")
            if gghum then return gghum, ggp end
        end
    end
    return nil
end

local function botMouse1Press()
    if mouse1press then pcall(mouse1press) end
end

local function botMouse1Release()
    if mouse1release then pcall(mouse1release) end
end

track(RunService.RenderStepped:Connect(function()
    if isUnloaded or not triggerbotEnabled then
        if triggerbotHolding then botMouse1Release(); triggerbotHolding = false end
        return
    end
    local hum, char = isMouseOnPlayer()
    if not hum or not char or char == LocalPlayer.Character or hum.Health <= 0 then
        if triggerbotHolding then botMouse1Release(); triggerbotHolding = false end
        return
    end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and Config.TeamCheck and plr.Team == LocalPlayer.Team then
        if triggerbotHolding then botMouse1Release(); triggerbotHolding = false end
        return
    end
    local now = tick()
    if now - triggerbotLastShot >= triggerbotDelay then
        if not triggerbotHolding then
            botMouse1Press()
            triggerbotHolding = true
            triggerbotLastShot = now
        end
    end
end))

--=====================================================================
--  ALTERNATIVE ZOOM
--=====================================================================
local AZ_BASE_DISTANCE = 12
local AZ_MIN_DISTANCE  = 0.5
local AZ_MAX_DISTANCE  = 1e6
local AZ_FP_ENTER      = 0.7
local AZ_FP_EXIT       = 1.2
local AZ_WHEEL_STEP    = 1.2
local AZ_PINCH_SENS    = 1
local AZ_SMOOTHNESS    = 12

local az_minLog, az_maxLog
local az_targetLog, az_currentLog
local az_inFirstPerson = false
local az_origMin, az_origMax, az_origMode
local az_wheelConn, az_pinchConn

local function az_addZoom(deltaLog)
    az_targetLog = math.clamp(az_targetLog + deltaLog, az_minLog, az_maxLog)
end

local function az_setFirstPerson(on)
    if az_inFirstPerson == on then return end
    az_inFirstPerson = on
    LocalPlayer.CameraMode = on and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
end

local function az_renderStep(dt)
    local cam = workspace.CurrentCamera
    if not cam or not altZoomEnabled or isUnloaded or freecamActive then return end

    az_currentLog += (az_targetLog - az_currentLog) * (1 - math.exp(-AZ_SMOOTHNESS * dt))
    local distance = math.exp(az_currentLog)
    local targetDistance = math.exp(az_targetLog)

    if not az_inFirstPerson and distance <= AZ_FP_ENTER then az_setFirstPerson(true)
    elseif az_inFirstPerson and targetDistance >= AZ_FP_EXIT then az_setFirstPerson(false) end

    if az_inFirstPerson then return end

    if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
    end

    local rotation = cam.CFrame.Rotation
    cam.CFrame = CFrame.new(cam.Focus.Position) * rotation * CFrame.new(0, 0, distance)
end

local function az_start()
    if altZoomEnabled then return end
    altZoomEnabled = true

    pcall(function() RunService:UnbindFromRenderStep("ZibvabvaAltZoom") end)
    if az_wheelConn then az_wheelConn:Disconnect(); az_wheelConn = nil end
    if az_pinchConn then az_pinchConn:Disconnect(); az_pinchConn = nil end

    az_origMin = LocalPlayer.CameraMinZoomDistance
    az_origMax = LocalPlayer.CameraMaxZoomDistance
    az_origMode = LocalPlayer.CameraMode

    LocalPlayer.CameraMinZoomDistance = AZ_BASE_DISTANCE
    LocalPlayer.CameraMaxZoomDistance = AZ_BASE_DISTANCE

    az_minLog, az_maxLog = math.log(AZ_MIN_DISTANCE), math.log(AZ_MAX_DISTANCE)
    az_targetLog = math.log(AZ_BASE_DISTANCE)
    az_currentLog = az_targetLog
    az_inFirstPerson = false

    RunService:BindToRenderStep("ZibvabvaAltZoom", Enum.RenderPriority.Camera.Value + 1, az_renderStep)

    az_wheelConn = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed or not altZoomEnabled or freecamActive then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            az_addZoom(-input.Position.Z * math.log(AZ_WHEEL_STEP))
        end
    end)
    track(az_wheelConn)

    local lastScale = 1
    az_pinchConn = UserInputService.TouchPinch:Connect(function(_, scale, _, state, gameProcessed)
        if gameProcessed or not altZoomEnabled or freecamActive then return end
        if state == Enum.UserInputState.Begin then lastScale = 1
        elseif state == Enum.UserInputState.Change then
            az_addZoom(-math.log(scale / lastScale) * AZ_PINCH_SENS)
            lastScale = scale
        end
    end)
    track(az_pinchConn)
end

local function az_stop(keepCamera)
    if not altZoomEnabled then return end
    altZoomEnabled = false

    pcall(function() RunService:UnbindFromRenderStep("ZibvabvaAltZoom") end)
    if az_wheelConn then az_wheelConn:Disconnect(); az_wheelConn = nil end
    if az_pinchConn then az_pinchConn:Disconnect(); az_pinchConn = nil end

    if not keepCamera and not freecamActive then
        LocalPlayer.CameraMinZoomDistance = az_origMin or 0.5
        LocalPlayer.CameraMaxZoomDistance = az_origMax or 4000
        LocalPlayer.CameraMode = az_origMode or Enum.CameraMode.Classic
        az_origMin, az_origMax, az_origMode = nil, nil, nil
    end
end

--=====================================================================
--  OLD FLING (Touch Fling)
--=====================================================================
local function flingLoop()
    local movel = 0.1
    while flingActive and not isUnloaded do
        RunService.Heartbeat:Wait()
        local c = LocalPlayer.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local function toggleAntiFling(state)
    antiFlingEnabled = state
    if antiFlingEnabled then
        if not antiFlingConnection then
            antiFlingConnection = RunService.Stepped:Connect(function()
                for i = 1, #playerPartsCache do
                    if playerPartsCache[i] then playerPartsCache[i].CanCollide = false end
                end
            end)
        end
    else
        if antiFlingConnection then antiFlingConnection:Disconnect(); antiFlingConnection = nil end
        table.clear(playerPartsCache)
    end
end

task.spawn(function()
    while task.wait(1) do
        if isUnloaded then break end
        if antiFlingEnabled then
            local c = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    for _, p in ipairs(plr.Character:GetChildren()) do
                        if p:IsA("BasePart") then table.insert(c, p) end
                    end
                end
            end
            playerPartsCache = c
        end
    end
end)

--=====================================================================
--  FREECAM
--=====================================================================
local savedFreecamMode = nil

local function ToggleFreecam(state)
    if freecamActive == state then return end
    freecamActive = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if freecamActive then
        if hrp then hrp.Anchored = true end
        if altZoomEnabled then az_stop(true) end

        savedFreecamMode = LocalPlayer.CameraMode
        LocalPlayer.CameraMode = Enum.CameraMode.Classic

        freecamCamPos = Camera.CFrame.Position
        local x, y = Camera.CFrame:ToEulerAnglesYXZ()
        freecamRotX, freecamRotY = x, y

        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        freecamFOV = Config.Camera_FOV
        Camera.FieldOfView = freecamFOV
        Window:Notify({ Title = "Freecam", Text = "Enabled" })
    else
        if hrp then hrp.Anchored = false end
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Camera.FieldOfView = Config.Camera_FOV

        if altZoomDesired then
            az_stop(true)
            task.spawn(function()
                task.wait(0.5)
                if not freecamActive and altZoomDesired then
                    if camAltZoomToggle then
                        pcall(function() camAltZoomToggle:Set(false, false) end)
                        task.wait(0.1)
                        pcall(function() camAltZoomToggle:Set(true, false) end)
                    else
                        az_start()
                    end
                end
            end)
        else
            LocalPlayer.CameraMode = savedFreecamMode or Enum.CameraMode.Classic
            LocalPlayer.CameraMinZoomDistance = az_origMin or 0.5
            LocalPlayer.CameraMaxZoomDistance = az_origMax or 4000
        end
        Window:Notify({ Title = "Freecam", Text = "Disabled" })
    end
end

track(RunService.RenderStepped:Connect(function(dt)
    if freecamActive then
        local md = UserInputService:GetMouseDelta()
        freecamRotY = freecamRotY - md.X * 0.003
        freecamRotX = math.clamp(freecamRotX - md.Y * 0.003, -1.57, 1.57)
        local dir = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - ((UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )
        local cf = CFrame.new(freecamCamPos) * CFrame.fromOrientation(freecamRotX, freecamRotY, 0)
        freecamCamPos = freecamCamPos + cf:VectorToWorldSpace(dir) * freecamSpeed * dt
        Camera.CFrame = CFrame.new(freecamCamPos) * CFrame.fromOrientation(freecamRotX, freecamRotY, 0)
        Camera.FieldOfView = freecamFOV
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not freecamActive and Camera then
        if math.abs(Camera.FieldOfView - Config.Camera_FOV) > 0.01 then
            Camera.FieldOfView = Config.Camera_FOV
        end
    end
end))

local WHEEL_STEP = 15
track(UserInputService.InputChanged:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    local s = input.Position.Z

    if freecamActive then
        freecamFOV = math.clamp(freecamFOV - s * 4, 15, 120)
        Camera.FieldOfView = freecamFOV
        return
    end
    if altZoomEnabled then return end

    local cz = LocalPlayer.CameraMaxZoomDistance or 4000
    if s > 0 then
        LocalPlayer.CameraMaxZoomDistance = math.max(cz - WHEEL_STEP, 10)
    else
        if infZoomEnabled then
        else
            LocalPlayer.CameraMaxZoomDistance = math.min(cz + WHEEL_STEP, 1000)
        end
    end
end))

--=====================================================================
--  LIGHTING / GAMMA / SHADOWS
--=====================================================================
local gammaEffect = Lighting:FindFirstChild("GammaCorrection") or Instance.new("ColorCorrectionEffect")
gammaEffect.Name = "GammaCorrection"
gammaEffect.Parent = Lighting

local function setGamma(v) gammaEffect.Brightness = math.clamp(v, -1, 1) end
local function setShadowsDisabled(s) Lighting.GlobalShadows = not s end

--=====================================================================
--  NAMETAG
--=====================================================================
local appliedNameTagText = "[GOD]"
local appliedNameTagColor = Color3.fromRGB(255, 215, 0)
local nameTagApplied = false

local draftTagText = "[GOD]"
local draftTagColor = Color3.fromRGB(255, 215, 0)

local function applyNameTag()
    appliedNameTagText = draftTagText
    appliedNameTagColor = draftTagColor
    nameTagApplied = true

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if appliedNameTagText == "" or not appliedNameTagText then
                hum.DisplayName = LocalPlayer.Name
            else
                hum.DisplayName = appliedNameTagText .. " " .. LocalPlayer.Name
            end
        end
    end
    Window:Notify({ Title = "Name Tag", Text = "Applied" })
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    if not nameTagApplied then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if appliedNameTagText == "" or not appliedNameTagText then
            hum.DisplayName = LocalPlayer.Name
        else
            hum.DisplayName = appliedNameTagText .. " " .. LocalPlayer.Name
        end
    end
end))

local function patchPlayerList()
    if not nameTagApplied then return end
    local list = CoreGui:FindFirstChild("PlayerList")
    if not list then return end

    local n = LocalPlayer.Name
    local dn = LocalPlayer.DisplayName

    for _, o in ipairs(list:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") then
            local t = o.Text
            local targetName = nil

            if string.sub(t, -#dn) == dn then
                targetName = dn
            elseif string.sub(t, -#n) == n then
                targetName = n
            end

            if targetName then
                local prefix = (appliedNameTagText ~= "" and appliedNameTagText .. " ") or ""
                local newText = prefix .. targetName

                if o.Text ~= newText then o.Text = newText end
                if o.TextColor3 ~= appliedNameTagColor then o.TextColor3 = appliedNameTagColor end
            end
        end
    end
end

local function patchScoreboard()
    if not nameTagApplied then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGui")
    local m = mg and mg:FindFirstChild("main")
    local t = m and m:FindFirstChild("tos")
    local s = t and t:FindFirstChild("scroll")
    if not s then return end

    local n = LocalPlayer.Name
    local dn = LocalPlayer.DisplayName

    for _, sample in ipairs(s:GetChildren()) do
        if sample.Name == "sample" then
            local nl = sample:FindFirstChild("name")
            if nl and nl:IsA("TextLabel") then
                local txt = nl.Text
                local targetName = nil

                if string.sub(txt, -#dn) == dn then
                    targetName = dn
                elseif string.sub(txt, -#n) == n then
                    targetName = n
                end

                if targetName then
                    local prefix = (appliedNameTagText ~= "" and appliedNameTagText .. " ") or ""
                    local newText = prefix .. targetName

                    if nl.Text ~= newText then nl.Text = newText end
                    if nl.TextColor3 ~= appliedNameTagColor then nl.TextColor3 = appliedNameTagColor end
                end
            end
        end
    end
end

track(RunService.RenderStepped:Connect(function()
    if nameTagApplied then
        patchPlayerList()
        patchScoreboard()
    end
end))

--=====================================================================
--  UNLOAD
--=====================================================================
unloadScript = function()
    if isUnloaded then return end
    isUnloaded = true

    if isFlying then
        isFlying = false
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
            local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
            if torso then
                local bg = torso:FindFirstChild("ZibBodyGyro")
                local bv = torso:FindFirstChild("ZibBodyVelocity")
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
            end
            if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
        end
    end

    Config.ESP_Enabled = false
    Config.Aimbot_Enabled = false
    Config.Highlight_Enabled = false
    HitboxConfig.Enabled = false
    ResetHitboxes()

    if altZoomEnabled then az_stop() end
    ToggleInvisible(false)
    setFlightState(false)
    setNoclipState(false)
    toggleAntiAFK(false)
    toggleAntiFling(false)
    if freecamActive then ToggleFreecam(false) end

    -- STOP FLING
    StopMultiFling()
    flingActive = false
    workspace.FallenPartsDestroyHeight = FPDH

    infZoomEnabled = false
    pcall(function() LocalPlayer.CameraMaxZoomDistance = originalMaxZoom end)
    spinbotEnabled = false
    InfiniteJumpEnabled = false
    clickTpEnabled = false

    if Camera then Camera.FieldOfView = 70 end
    setGamma(0)
    pcall(function() Lighting.GlobalShadows = originalGlobalShadows end)

    purgeAllZibvabvaHighlights()
    for p in pairs(ESPCache) do removeESP(p) end
    pcall(function() ESPContainer:Destroy() end)
    pcall(function() FOVGui:Destroy() end)

    if Window then pcall(function() Window:Destroy() end) end
    untrackAll()

    if GENV.__Zibvabva_Unload == unloadScript then GENV.__Zibvabva_Unload = nil end
end

GENV.__Zibvabva_Unload = unloadScript

--=====================================================================
--  FLASHBACK
--=====================================================================
local FB = { frames = {}, maxFrames = 6000, speed = 0.5, toggleActive = false, keybindActive = false, lastInput = false, canRevert = true, accum = 0 }

local function fbGetHrp(c)
    return c:FindFirstChild("HumanoidRootPart") or c.RootPart or c.PrimaryPart or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart")
end

local function fbIsActive() return FB.toggleActive or FB.keybindActive end

local function fbAdvance(char, hrp, hum, allowInput)
    if #FB.frames > FB.maxFrames then table.remove(FB.frames, 1) end
    if allowInput and not FB.canRevert then FB.canRevert = true end
    if FB.lastInput then hum.PlatformStand = false; FB.lastInput = false end
    table.insert(FB.frames, { hrp.CFrame, hrp.Velocity, hum:GetState(), hum.PlatformStand, char:FindFirstChildOfClass("Tool") })
end

local function fbRevert(char, hrp, hum)
    local num = #FB.frames
    if num == 0 or not FB.canRevert then FB.canRevert = false; fbAdvance(char, hrp, hum); return end

    FB.accum = FB.accum + FB.speed
    local steps = math.floor(FB.accum)
    if steps < 1 then return end
    FB.accum = FB.accum - steps

    for _ = 1, steps do
        if num <= 0 then break end
        table.remove(FB.frames, num)
        num = num - 1
    end

    if num <= 0 then FB.accum = 0; return end

    FB.lastInput = true
    local lastFrame = FB.frames[num]
    table.remove(FB.frames, num)
    if not lastFrame then return end

    hrp.CFrame = lastFrame[1]
    hrp.Velocity = -lastFrame[2]
    hum:ChangeState(lastFrame[3])
    hum.PlatformStand = lastFrame[4]

    local currentTool = char:FindFirstChildOfClass("Tool")
    if lastFrame[5] then
        if not currentTool then hum:EquipTool(lastFrame[5]) end
    else
        hum:UnequipTools()
    end
end

track(RunService.RenderStepped:Connect(function()
    if isUnloaded then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = fbGetHrp(char)
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end

    if fbIsActive() then fbRevert(char, hrp, hum)
    else fbAdvance(char, hrp, hum, true); FB.accum = 0 end
end))

--=====================================================================
--  JERK OFF (TOOL) + BANG
--=====================================================================
local jerkToolState = { active = false, tool = nil, humConn = nil, charConn = nil }
local bangState = { track = nil, active = false, followConn = nil, diedConn = nil }
local bangRefreshRunning = true
local bangToggleEnabled = false
local bangToggle  -- forward decl, UI ниже

local function StopJerkTool()
    jerkToolState.active = false
    local oldTool = jerkToolState.tool
    jerkToolState.tool = nil
    if oldTool then pcall(function() oldTool:Destroy() end) end
    if jerkToolState.humConn then
        pcall(function() jerkToolState.humConn:Disconnect() end)
        jerkToolState.humConn = nil
    end
    if jerkToolState.charConn then
        pcall(function() jerkToolState.charConn:Disconnect() end)
        jerkToolState.charConn = nil
    end
end

local function CreateJerkTool()
    if isUnloaded or not jerkToolState.active then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not hum or not backpack then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end

    if jerkToolState.tool and jerkToolState.tool.Parent then return true end

    local oldTool = jerkToolState.tool
    jerkToolState.tool = nil
    if oldTool then pcall(function() oldTool:Destroy() end) end
    if jerkToolState.humConn then
        pcall(function() jerkToolState.humConn:Disconnect() end)
        jerkToolState.humConn = nil
    end

    local tool = Instance.new("Tool")
    tool.Name = "Jerk Off"
    tool.ToolTip = "jorking it"
    tool.RequiresHandle = false
    tool.Parent = backpack
    jerkToolState.tool = tool

    local isR15 = hum.RigType == Enum.HumanoidRigType.R15
    local animId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
    local speed  = isR15 and 0.7 or 0.65
    local stopAt = isR15 and 0.7 or 0.65

    local track, equipped = nil, false

    tool.Equipped:Connect(function() equipped = true end)
    tool.Unequipped:Connect(function()
        equipped = false
        if track then pcall(function() track:Stop() end) track = nil end
    end)

    jerkToolState.humConn = hum.Died:Connect(function()
        jerkToolState.tool = nil
    end)

    task.spawn(function()
        while jerkToolState.active and not isUnloaded and jerkToolState.tool == tool do
            if equipped and hum.Parent and animator.Parent then
                if not track then
                    local anim = Instance.new("Animation")
                    anim.AnimationId = animId
                    track = animator:LoadAnimation(anim)
                end
                pcall(function()
                    track:Play()
                    track:AdjustSpeed(speed)
                    track.TimePosition = 0.6
                end)
                task.wait(0.1)
                local guard = 0
                while track and track.TimePosition < stopAt and guard < 20
                      and jerkToolState.active and jerkToolState.tool == tool do
                    task.wait(0.1)
                    guard = guard + 1
                end
                if track then pcall(function() track:Stop() end) track = nil end
            else
                task.wait(0.1)
            end
        end
        if track then pcall(function() track:Stop() end) end
    end)

    return true
end

local function SpawnJerkToolRetry()
    if not jerkToolState.active or isUnloaded then return end
    task.spawn(function()
        local attempts = 0
        while jerkToolState.active and not isUnloaded and attempts < 40 do
            if CreateJerkTool() then
                if Window then Window:Notify({ Title = "Jerk", Text = "Enabled" }) end
                return
            end
            attempts = attempts + 1
            task.wait(0.25)
        end
    end)
end

local function StartJerkTool()
    if isUnloaded then return end
    if jerkToolState.active and jerkToolState.tool and jerkToolState.tool.Parent then return end
    jerkToolState.active = true

    if not jerkToolState.charConn then
        jerkToolState.charConn = LocalPlayer.CharacterAdded:Connect(function()
            if jerkToolState.active and not isUnloaded then
                task.wait(1)
                if not CreateJerkTool() then SpawnJerkToolRetry() end
            end
        end)
    end

    if CreateJerkTool() then
        if Window then Window:Notify({ Title = "Jerk", Text = "Enabled" }) end
    else
        if Window then Window:Notify({ Title = "Jerk", Text = "Waiting for character..." }) end
        SpawnJerkToolRetry()
    end
end

local function StopBang()
    bangState.active = false
    if bangState.track      then pcall(function() bangState.track:Stop() end)          bangState.track = nil end
    if bangState.followConn then pcall(function() bangState.followConn:Disconnect() end) bangState.followConn = nil end
    if bangState.diedConn   then pcall(function() bangState.diedConn:Disconnect() end)   bangState.diedConn = nil end
end

local function StartBang(targetPlayer)
    StopBang()
    if isUnloaded then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then
        if Window then Window:Notify({ Title = "Bang", Text = "Character not ready" }) end
        return
    end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end

    local isR15 = hum.RigType == Enum.HumanoidRigType.R15
    local anim = Instance.new("Animation")
    anim.AnimationId = isR15 and "rbxassetid://5918726674" or "rbxassetid://148840371"
    local track = animator:LoadAnimation(anim)
    pcall(function()
        track:Play(0.1, 1, 1)
        track:AdjustSpeed(3)
    end)

    bangState.track  = track
    bangState.active = true

    bangState.diedConn = hum.Died:Connect(function()
        StopBang()
        bangToggleEnabled = false
        if bangToggle then pcall(function() bangToggle:Set(false, true) end) end
    end)

    if targetPlayer and targetPlayer.Character then
        local offset = CFrame.new(0, 0, 1.1)
        bangState.followConn = RunService.Stepped:Connect(function()
            if not bangState.active or isUnloaded then return end
            pcall(function()
                local tChar = targetPlayer.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if tRoot and myRoot then
                    myRoot.CFrame = tRoot.CFrame * offset
                end
            end)
        end)
    end
end

table.insert(__conns, {
    Disconnect = function()
        StopJerkTool()
        StopBang()
        bangRefreshRunning = false
    end
})

--=====================================================================
--  UI — WINDOW
--=====================================================================
Window = UI:CreateWindow({
    Title = "Zibvabva",
    Subtitle = "babyun42",
    Version = "v1.1",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.CapsLock,
    LogoShape = "Flower",
    Intro = true,
    OnUnload = unloadScript,
})

local function notifySlider(title, value)
    if Window then Window:Notify({ Title = title, Text = "Set to " .. tostring(value), Duration = 2 }) end
end

--=====================================================================
--  TAB: PLAYER
--=====================================================================
do
local PlayerTab = Window:AddTab({ Name = "Player", Shape = "Circle" })

local mov = PlayerTab:AddSection("Movement")
local wsDebounce, jpDebounce
mov:AddSlider({
    Name = "WalkSpeed", Description = "Character walk speed",
    Min = 16, Max = 300, Default = 16, Increment = 1,
    Callback = function(v)
        currentWalkSpeed = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("WalkSpeed", v) end)
    end,
})
mov:AddSlider({
    Name = "JumpPower", Description = "Character jump power",
    Min = 50, Max = 400, Default = 50, Increment = 1,
    Callback = function(v)
        currentJumpPower = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v end
        if jpDebounce then task.cancel(jpDebounce) end
        jpDebounce = task.delay(0.5, function() notifySlider("JumpPower", v) end)
    end,
})
mov:AddToggle({
    Name = "Infinite Jump", Description = "Mid-air jumping", Default = false,
    Callback = function(v)
        InfiniteJumpEnabled = v
        Window:Notify({ Title = "Infinite Jump", Text = v and "Enabled" or "Disabled" })
    end,
})

local pactions = PlayerTab:AddSection("Player Actions")

local flightFolder = pactions:AddFolder({ Name = "Flight", Description = "Toggle flight mode" })
flyToggle = flightFolder:AddToggle({
    Name = "Enable Fly", Description = "Toggle flight mode", Default = false,
    Callback = function(v) if isFlying ~= v then setFlightState(v) end end
})
flightFolder:AddSlider({
    Name = "Fly Speed", Description = "Flight movement speed",
    Min = 20, Max = 300, Default = 35, Increment = 1,
    Callback = function(v)
        flySpeed = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Fly Speed", v) end)
    end
})
flightFolder:AddKeybind({
    Name = "Fly Keybind", Description = "Hotkey to toggle fly",
    Default = Enum.KeyCode.F,
    Callback = function(k) if k then Window:Notify({ Title = "Keybind", Text = "Fly set to " .. k.Name }) end end,
    OnPress = function() setFlightState(not isFlying) end,
})

local noclipFolder = pactions:AddFolder({ Name = "Noclip", Description = "Walk through walls" })
noclipToggle = noclipFolder:AddToggle({
    Name = "Enable Noclip", Description = "Walk through walls", Default = false,
    Callback = function(v) if isNoclip ~= v then setNoclipState(v) end end
})
noclipFolder:AddKeybind({
    Name = "Noclip Keybind", Description = "Hotkey to toggle noclip",
    Default = Enum.KeyCode.X,
    Callback = function(k) if k then Window:Notify({ Title = "Keybind", Text = "Noclip set to " .. k.Name }) end end,
    OnPress = function() setNoclipState(not isNoclip) end,
})

local tpFolder = pactions:AddFolder({ Name = "Click Teleport", Description = "Teleport to mouse cursor" })
tpFolder:AddToggle({
    Name = "Enable Teleport", Description = "Teleport to mouse cursor", Default = false,
    Callback = function(v)
        clickTpEnabled = v
        Window:Notify({ Title = "Click TP", Text = v and "Enabled" or "Disabled" })
    end,
})
tpFolder:AddKeybind({
    Name = "Teleport Keybind", Description = "Teleport hotkey",
    Default = Enum.KeyCode.E,
    Callback = function(k) if k then Window:Notify({ Title = "Keybind", Text = "Teleport set to " .. k.Name }) end end,
    OnPress = function()
        if not clickTpEnabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and Mouse.Hit then
            if hum and hum.Sit then hum.Sit = false; task.wait(0.1) end
            hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.5, 0))
        end
    end,
})

local spinFolder = pactions:AddFolder({ Name = "Spinbot", Description = "Rapid rotation" })
spinFolder:AddToggle({
    Name = "Enable Spinbot", Description = "Rapid rotation", Default = false,
    Callback = function(v)
        spinbotEnabled = v
        Window:Notify({ Title = "Spinbot", Text = v and "Enabled" or "Disabled" })
    end,
})
spinFolder:AddSlider({
    Name = "Spin Speed", Description = "Character spin speed",
    Min = 1, Max = 100, Default = 20, Increment = 1,
    Callback = function(v)
        spinbotSpeed = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Spin Speed", v) end)
    end,
})

local invisFolder = pactions:AddFolder({ Name = "Invisibility", Description = "Client-side invisibility" })
local invisToggle
invisToggle = invisFolder:AddToggle({
    Name = "Invisible", Description = "Client-side invisibility", Default = false,
    Callback = function(v) if IsInvisible ~= v then ToggleInvisible(v) end end,
})
invisFolder:AddSlider({
    Name = "Teleport Distance", Description = "Distance to teleport down when invisible",
    Min = 50000, Max = 1000000, Default = 200000, Increment = 10000,
    Callback = function(v)
        invisibleDistance = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Invisibility Distance", v) end)
    end,
})
invisFolder:AddKeybind({
    Name = "Invisibility Keybind", Description = "Hotkey to toggle invisibility",
    Default = Enum.KeyCode.M,
    Callback = function(k) if k then Window:Notify({ Title = "Keybind", Text = "Invisibility set to " .. k.Name }) end end,
    OnPress = function()
        local nv = not IsInvisible
        ToggleInvisible(nv)
        if invisToggle then invisToggle:Set(nv, true) end
    end,
})

local fbFolder = pactions:AddFolder({ Name = "Flashback", Description = "Records your actions and repeats them" })
local fbToggle
fbToggle = fbFolder:AddToggle({
    Name = "Flashback", Description = "All actions play in reverse", Default = false,
    Callback = function(v)
        FB.toggleActive = v
        if not v then FB.accum = 0 end
        Window:Notify({ Title = "Flashback", Text = v and "Enabled" or "Disabled" })
    end,
})

local fbKey = Enum.KeyCode.R
fbFolder:AddKeybind({
    Name = "Hold to Flashback", Description = "Hold key — actions reverse. Release — resume.",
    Default = Enum.KeyCode.R,
    Callback = function(k) if k then fbKey = k Window:Notify({ Title = "Keybind", Text = "Flashback set to " .. k.Name }) end end,
    OnPress = function() FB.keybindActive = true end,
})

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == fbKey then
        FB.keybindActive = false
        FB.accum = 0
    end
end))

fbFolder:AddSlider({
    Name = "Speed", Description = "Frames reverted per frame (0.5 = normal, 5 = fast)",
    Min = 0.25, Max = 5, Default = 0.5, Increment = 0.25,
    Callback = function(v)
        FB.speed = v
        FB.accum = 0
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Flashback Speed", v) end)
    end,
})

fbFolder:AddButton({
    Name = "Reset", Description = "Clear recorded frames and turn off", ButtonText = "Reset",
    Callback = function()
        FB.frames = {}
        FB.toggleActive = false
        FB.keybindActive = false
        FB.accum = 0
        FB.canRevert = true
        if fbToggle then pcall(function() fbToggle:Set(false, true) end) end
        Window:Notify({ Title = "Flashback", Text = "Frames cleared & disabled" })
    end,
})

local other = PlayerTab:AddSection("Other")
other:AddToggle({
    Name = "Enable Anti-AFK", Description = "Prevents AFK kick", Default = true,
    Callback = function(v)
        toggleAntiAFK(v)
        Window:Notify({ Title = "Anti-AFK", Text = v and "Enabled" or "Disabled" })
    end,
})
toggleAntiAFK(true)
end
--=====================================================================
--  TAB: VISUALS
--=====================================================================
do
local VisualsTab = Window:AddTab({ Name = "Visuals", Shape = "Diamond" })

local espSection = VisualsTab:AddSection("ESP")
local espToggles = { Enabled = nil, Boxes = nil, Tracers = nil, HeadDot = nil, HealthBar = nil, NameTag = nil }
local espPreview = nil
local hpPosDropdown = nil

local function syncToggle(key, value)
    local KEY_MAP = { boxes = "Boxes", tracers = "Tracers", headDot = "HeadDot", healthBar = "HealthBar", nameTag = "NameTag", highlight = "Highlight" }
    local normKey = KEY_MAP[key] or key
    local tgl = espToggles[normKey]
    if tgl then pcall(function() tgl:Set(value, true) end) end

    if normKey == "Enabled" then Config.ESP_Enabled = value
    elseif normKey == "Boxes" then Config.Boxes_Enabled = value
    elseif normKey == "Tracers" then Config.Tracers_Enabled = value
    elseif normKey == "HeadDot" then Config.HeadDot_Enabled = value
    elseif normKey == "HealthBar" then Config.HealthBar_Enabled = value
    elseif normKey == "NameTag" then Config.NameTag_Enabled = value
    elseif normKey == "Highlight" then
        Config.Highlight_Enabled = value
        if highlightToggle then pcall(function() highlightToggle:Set(value, true) end) end
    end
end

espPreview = espSection:AddESPPreview({
    Enabled = Config.ESP_Enabled, Boxes = Config.Boxes_Enabled, Tracers = Config.Tracers_Enabled,
    HeadDot = Config.HeadDot_Enabled, HealthBar = Config.HealthBar_Enabled, NameTag = Config.NameTag_Enabled,
    Highlight = Config.Highlight_Enabled,
    Rainbow = Config.RainbowBoxes, BoxColor = Config.BoxColor, TracerColor = Config.TracerColor, NameColor = Config.NameColor,
    HealthPercent = 0.75, HealthPosition = Config.HealthBarPosition, NameText = "Player",
    OnToggle = function(key, value) syncToggle(key, value) end,
    OnHealthPos = function(pos)
        Config.HealthBarPosition = pos
        Config.HealthBar_Enabled = true
        if espPreview then espPreview:SetHealthBar(true) end
        if hpPosDropdown then pcall(function() hpPosDropdown:Set(pos, true) end) end
        if espToggles.HealthBar then pcall(function() espToggles.HealthBar:Set(true, true) end) end
    end,
})

espToggles.Enabled = espSection:AddToggle({
    Name = "Enable ESP", Description = "Master toggle for ESP", Default = false,
    Callback = function(v)
        Config.ESP_Enabled = v
        espPreview:SetEnabled(v)
        Window:Notify({ Title = "ESP", Text = v and "Enabled" or "Disabled" })
    end,
})

local espFolder = espSection:AddFolder({ Name = "ESP Settings", Description = "Master + features" })
espToggles.Boxes = espFolder:AddToggle({
    Name = "Boxes", Description = "Draw 2D boxes around players", Default = true,
    Callback = function(v)
        Config.Boxes_Enabled = v
        espPreview:SetBoxes(v)
        Window:Notify({ Title = "ESP Boxes", Text = v and "Enabled" or "Disabled" })
    end,
})
highlightToggle = espFolder:AddToggle({
    Name = "Highlight Players", Description = "Glow around the whole body", Default = true,
    Callback = function(v)
        Config.Highlight_Enabled = v
        if espPreview then espPreview:SetHighlight(v) end
        if not v and purgeAllZibvabvaHighlights then pcall(purgeAllZibvabvaHighlights) end
        Window:Notify({ Title = "ESP Highlight", Text = v and "Enabled" or "Disabled" })
    end,
})
espToggles.Tracers = espFolder:AddToggle({
    Name = "Tracers", Description = "Lines from bottom to player", Default = false,
    Callback = function(v)
        Config.Tracers_Enabled = v
        espPreview:SetTracers(v)
        Window:Notify({ Title = "ESP Tracers", Text = v and "Enabled" or "Disabled" })
    end,
})
espToggles.HeadDot = espFolder:AddToggle({
    Name = "Head Dot", Description = "Dot on player head", Default = true,
    Callback = function(v)
        Config.HeadDot_Enabled = v
        espPreview:SetHeadDot(v)
        Window:Notify({ Title = "ESP Head Dot", Text = v and "Enabled" or "Disabled" })
    end,
})
espToggles.HealthBar = espFolder:AddToggle({
    Name = "Health Bar", Description = "Show player health", Default = true,
    Callback = function(v)
        Config.HealthBar_Enabled = v
        espPreview:SetHealthBar(v)
        Window:Notify({ Title = "ESP Health Bar", Text = v and "Enabled" or "Disabled" })
    end,
})
espToggles.NameTag = espFolder:AddToggle({
    Name = "Name Tag", Description = "Show player names", Default = true,
    Callback = function(v)
        Config.NameTag_Enabled = v
        espPreview:SetNameTag(v)
        Window:Notify({ Title = "ESP Name Tag", Text = v and "Enabled" or "Disabled" })
    end,
})
espFolder:AddToggle({
    Name = "Use Display Name", Description = "Show DisplayName instead of Username", Default = false,
    Callback = function(v)
        Config.UseDisplayName = v
        Window:Notify({ Title = "ESP Names", Text = "Using " .. (v and "DisplayName" or "Username") })
    end,
})

local espcFolder = espSection:AddFolder({ Name = "ESP Customization", Description = "Colors and display" })
hpPosDropdown = espcFolder:AddDropdown({
    Name = "Health Bar Position", Description = "Where to render the health bar",
    Options = { "Right", "Left", "Top" }, Default = "Right",
    Callback = function(v)
        Config.HealthBarPosition = v
        espPreview:SetHealthPosition(v)
        Window:Notify({ Title = "ESP Health Bar", Text = "Moved to " .. v })
    end,
})
espcFolder:AddColorpicker({
    Name = "Box Color", Description = "ESP box color", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.BoxColor = c; espPreview:SetBoxColor(c) end,
})
espcFolder:AddColorpicker({
    Name = "Highlight Color", Description = "Color of the highlight glow", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.Highlight_Color = c end,
})
espcFolder:AddColorpicker({
    Name = "Tracer Color", Description = "ESP tracer line color", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.TracerColor = c; espPreview:SetTracerColor(c) end,
})
espcFolder:AddColorpicker({
    Name = "Name Color", Description = "ESP name text color", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.NameColor = c; espPreview:SetNameColor(c) end,
})
espcFolder:AddColorpicker({
    Name = "Target Color", Description = "Color for target locked by aimbot", Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c) Config.TargetColor = c end,
})
espcFolder:AddToggle({
    Name = "Target Invert Color", Description = "Use inverted contrast color for target", Default = false,
    Callback = function(v)
        Config.UseTargetInvert = v
        Window:Notify({ Title = "ESP Target Invert", Text = v and "Enabled" or "Disabled" })
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Highlight", Description = "Animated rainbow glow", Default = false,
    Callback = function(v)
        Config.Highlight_Rainbow = v
        Window:Notify({ Title = "Rainbow Highlight", Text = v and "Enabled" or "Disabled" })
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Names", Description = "Rainbow name color effect", Default = false,
    Callback = function(v)
        Config.RainbowNames = v
        espPreview:SetRainbow(v or Config.RainbowBoxes or Config.RainbowTracers)
        Window:Notify({ Title = "Rainbow Names", Text = v and "Enabled" or "Disabled" })
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Boxes & Heads", Description = "Rainbow boxes and head dots", Default = false,
    Callback = function(v)
        Config.RainbowBoxes = v
        espPreview:SetRainbow(v or Config.RainbowNames or Config.RainbowTracers)
        Window:Notify({ Title = "Rainbow Boxes", Text = v and "Enabled" or "Disabled" })
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Tracers", Description = "Rainbow tracer lines", Default = false,
    Callback = function(v)
        Config.RainbowTracers = v
        espPreview:SetRainbow(v or Config.RainbowNames or Config.RainbowBoxes)
        Window:Notify({ Title = "Rainbow Tracers", Text = v and "Enabled" or "Disabled" })
    end,
})

local ntSection = VisualsTab:AddSection("Name Tag")
local ntFolder = ntSection:AddFolder({ Name = "Tag Settings", Description = "Prefix text & color" })
local tagInputObj = ntFolder:AddInput({
    Name = "Tag Text", Description = "Prefix text before username (leave empty for none)", Placeholder = "[GOD]", Default = draftTagText,
    Callback = function(t) draftTagText = t end,
})
ntFolder:AddColorpicker({
    Name = "Tag Color", Description = "Prefix color",
    Default = draftTagColor,
    Callback = function(c) draftTagColor = c end,
})
ntFolder:AddButton({
    Name = "Apply NameTag", Description = "Apply prefix to your name", ButtonText = "Apply",
    Callback = function()
        if tagInputObj then
            local ok, text = pcall(function() return tagInputObj:Get() end)
            if ok and text then draftTagText = text end
        end
        applyNameTag()
    end,
})

local shaderSection = VisualsTab:AddSection("Shaders")
local shaderFolder = shaderSection:AddFolder({ Name = "Shader Library", Description = "External graphics packs" })
shaderFolder:AddButton({
    Name = "HDR Graphics", Description = "Load HDR pack", ButtonText = "Load",
    Callback = function()
        Window:Notify({ Title = "Shaders", Text = "Loading HDR Graphics..." })
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/SyntaxScript/HDR-Graphics/main/main.lua"))() end)
    end,
})
shaderFolder:AddButton({
    Name = "PShade Ultimate", Description = "Load PShade pack", ButtonText = "Load",
    Callback = function()
        Window:Notify({ Title = "Shaders", Text = "Loading PShade Ultimate..." })
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/back.json"))() end)
    end,
})

local toolsSection = VisualsTab:AddSection("Tools")
local toolsFolder = toolsSection:AddFolder({ Name = "Explorer", Description = "Debug tools" })
toolsFolder:AddButton({
    Name = "Dex Explorer", Description = "Open Dex++ explorer", ButtonText = "Open",
    Callback = function()
        Window:Notify({ Title = "Tools", Text = "Loading Dex Explorer..." })
        pcall(function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end)
    end,
})

local camSection = VisualsTab:AddSection("Camera & Overlay")
local camFolder = camSection:AddFolder({ Name = "Camera", Description = "Freecam & FOV" })
camFolder:AddToggle({
    Name = "Infinite Zoom", Description = "Standard zoom, no limits", Default = false,
    Callback = function(v)
        infZoomEnabled = v
        if v then currentMaxZoom = LocalPlayer.CameraMaxZoomDistance
        else LocalPlayer.CameraMaxZoomDistance = originalMaxZoom; currentMaxZoom = originalMaxZoom end
        Window:Notify({ Title = "Infinite Zoom", Text = v and "Enabled" or "Disabled" })
    end,
})
camAltZoomToggle = camFolder:AddToggle({
    Name = "Alternative Zoom", Description = "Infinite zoom with true first-person", Default = false,
    Callback = function(v)
        altZoomDesired = v
        if not freecamActive then
            if v then az_start() else az_stop() end
        end
        Window:Notify({ Title = "Alt Zoom", Text = v and "Enabled" or "Disabled" })
    end,
})
local freecamToggle
freecamToggle = camFolder:AddToggle({
    Name = "Freecam", Description = "Free roaming camera", Default = false,
    Callback = function(v) if freecamActive ~= v then ToggleFreecam(v) end end,
})
camFolder:AddKeybind({
    Name = "Freecam Keybind", Description = "Hotkey to toggle freecam", Default = Enum.KeyCode.P,
    Callback = function(k) if k then Window:Notify({ Title = "Keybind", Text = "Freecam set to " .. k.Name }) end end,
    OnPress = function()
        local nv = not freecamActive
        ToggleFreecam(nv)
        if freecamToggle then freecamToggle:Set(nv, true) end
    end,
})
camFolder:AddSlider({
    Name = "Freecam Speed", Description = "Movement speed in freecam mode",
    Min = 10, Max = 500, Default = 50, Increment = 5,
    Callback = function(v)
        freecamSpeed = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Freecam Speed", v) end)
    end,
})
camFolder:AddSlider({
    Name = "Camera FOV", Description = "Field of view",
    Min = 30, Max = 120, Default = 70, Increment = 1,
    Callback = function(v)
        Config.Camera_FOV = v
        if freecamActive then freecamFOV = v; Camera.FieldOfView = v end
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Camera FOV", v) end)
    end,
})

local ovFolder = camSection:AddFolder({ Name = "Overlay", Description = "Gamma & shadows" })
ovFolder:AddSlider({
    Name = "Gamma", Description = "Adjust screen brightness",
    Min = -1, Max = 1, Default = 0, Increment = 0.1,
    Callback = function(v)
        setGamma(v)
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Gamma", v) end)
    end,
})
ovFolder:AddToggle({
    Name = "Disable World Shadows", Description = "Removes all world shadows", Default = false,
    Callback = function(v)
        setShadowsDisabled(v)
        Window:Notify({ Title = "World Shadows", Text = v and "Disabled" or "Enabled" })
    end,
})
end

--=====================================================================
--  TAB: COMBAT
--=====================================================================
do
local CombatTab = Window:AddTab({ Name = "Combat", Shape = "Burst" })

local aimSection = CombatTab:AddSection("Aim Bot")
local aimFolder = aimSection:AddFolder({ Name = "Aim Bot Settings", Description = "Configure aimbot" })
aimFolder:AddToggle({
    Name = "Enable Aimbot", Description = "Auto-aim at target", Default = false,
    Callback = function(v)
        Config.Aimbot_Enabled = v
        Window:Notify({ Title = "Aimbot", Text = v and "Enabled" or "Disabled" })
    end,
})
aimFolder:AddDropdown({
    Name = "Activation Key", Description = "Aimbot trigger key",
    Options = { "RightClick", "LeftClick", "E", "Q", "C", "F", "LeftShift", "LeftAlt" }, Default = "RightClick",
    Callback = function(v) Config.AimKey = v Window:Notify({ Title = "Aimbot Key", Text = "Set to " .. v }) end,
})
aimFolder:AddDropdown({
    Name = "Aimbot Method", Description = "Aiming method (Mouse is smoother)",
    Options = { "Camera", "Mouse" }, Default = "Mouse",
    Callback = function(v) Config.AimMethod = v Window:Notify({ Title = "Aimbot Method", Text = "Set to " .. v }) end,
})
aimFolder:AddDropdown({
    Name = "Target Part", Description = "Body part target",
    Options = { "Head", "HumanoidRootPart", "UpperTorso" }, Default = "Head",
    Callback = function(v) Config.TargetPart = v Window:Notify({ Title = "Target Part", Text = "Set to " .. v }) end,
})
aimFolder:AddToggle({
    Name = "Show FOV Circle", Description = "Show FOV radius circle", Default = true,
    Callback = function(v) Config.FOV_Visible = v Window:Notify({ Title = "Aimbot FOV", Text = v and "Shown" or "Hidden" }) end,
})
aimFolder:AddSlider({
    Name = "FOV Size", Description = "Aimbot FOV circle size",
    Min = 10, Max = 600, Default = 100, Increment = 1,
    Callback = function(v)
        Config.FOV_Radius = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Aimbot FOV Size", v) end)
    end,
})
aimFolder:AddColorpicker({
    Name = "FOV Color", Description = "FOV circle color", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.FOV_Color = c end,
})
aimFolder:AddToggle({
    Name = "Rainbow FOV Circle", Description = "Animated rainbow color for FOV circle", Default = false,
    Callback = function(v) Config.FOV_Rainbow = v Window:Notify({ Title = "Rainbow FOV", Text = v and "Enabled" or "Disabled" }) end,
})

local tbSection = CombatTab:AddSection("Trigger Bot")
local tbFolder = tbSection:AddFolder({ Name = "Trigger Bot Settings", Description = "Configure Trigger Bot" })
local tbToggle
tbToggle = tbFolder:AddToggle({
    Name = "Enable Trigger Bot", Description = "Auto-fire when crosshair is on an enemy", Default = false,
    Callback = function(v)
        triggerbotEnabled = v
        Window:Notify({ Title = "Trigger Bot", Text = v and "Enabled" or "Disabled" })
    end,
})
tbFolder:AddKeybind({
    Name = "Toggle Keybind", Description = "Hotkey to enable/disable",
    Default = Enum.KeyCode.G,
    Callback = function(k) if k then triggerbotKey = k Window:Notify({ Title = "Keybind", Text = "Trigger Bot set to " .. k.Name }) end end,
    OnPress = function()
        triggerbotEnabled = not triggerbotEnabled
        if tbToggle then pcall(function() tbToggle:Set(triggerbotEnabled, true) end) end
        Window:Notify({ Title = "Trigger Bot", Text = triggerbotEnabled and "Enabled" or "Disabled" })
    end,
})
tbFolder:AddSlider({
    Name = "Delay", Description = "Seconds between shots (0 = fastest)",
    Min = 0, Max = 1, Default = 0, Increment = 0.01,
    Callback = function(v)
        triggerbotDelay = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Trigger Bot Delay", v) end)
    end,
})

local flingSection = CombatTab:AddSection("Fling")

local flingplayersFolder = flingSection:AddFolder({ Name = "Fling Players", Description = "Allows you to throw back all players" })

local flingTargetsDropdown
flingTargetsDropdown = flingplayersFolder:AddMultiDropdown({
    Name = "Target Players",
    Description = "Select 1+ players to fling",
    Options = {},
    Callback = function(selectedTable)
        SelectedTargets = {}
        for name, isSelected in pairs(selectedTable) do
            if isSelected then
                local plr = Players:FindFirstChild(name)
                if plr then SelectedTargets[name] = plr end
            end
        end
    end
})

local function RefreshFlingDropdown()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            -- Передаем Name для логики и DisplayName для визуала
            table.insert(list, {
                value = plr.Name,
                display = plr.DisplayName .. " (@" .. plr.Name .. ")"
            })
        end
    end
    if flingTargetsDropdown then
        flingTargetsDropdown:SetOptions(list)
    end
end

RefreshFlingDropdown()
track(Players.PlayerAdded:Connect(function() task.wait(1) RefreshFlingDropdown() end))
track(Players.PlayerRemoving:Connect(function(plr)
    if flingTargetsDropdown then
        local selected = flingTargetsDropdown:Get()
        if selected[plr.Name] then
            selected[plr.Name] = nil
            flingTargetsDropdown:Set(selected, true) -- silent
            SelectedTargets[plr.Name] = nil
        end
        RefreshFlingDropdown()
    end
end))

local selectAllToggle
selectAllToggle = flingplayersFolder:AddToggle({
    Name = "Select All Players",
    Description = "Automatically selects everyone in the server",
    Default = false,
    Callback = function(v)
        local newSelected = {}
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    newSelected[plr.Name] = true
                end
            end
        end
        if flingTargetsDropdown then
            flingTargetsDropdown:Set(newSelected)
        end
    end
})

-- Авто-отключение Select All, если ты изменишь выбор вручную
local isUpdatingFromSelectAll = false
local oldCallback = flingTargetsDropdown.Callback
flingTargetsDropdown.Callback = function(selectedTable)
    -- Вызываем оригинальный callback (обновление SelectedTargets)
    if oldCallback then oldCallback(selectedTable) end

    -- Проверяем, все ли выбраны
    if not isUpdatingFromSelectAll then
        local allCount = #Players:GetPlayers() - 1
        local selCount = 0
        for _, isSel in pairs(selectedTable) do if isSel then selCount = selCount + 1 end end

        if selectAllToggle then
            pcall(function() selectAllToggle:Set(selCount == allCount and allCount > 0, true) end)
        end
    end
end

local multiFlingToggle
multiFlingToggle = flingplayersFolder:AddToggle({
    Name = "Start Multi-Fling", Description = "Flings all selected targets", Default = false,
    Callback = function(v)
        if v then
            StartMultiFling()
            if not FlingActive then
                task.defer(function() pcall(function() multiFlingToggle:Set(false, true) end) end)
            end
        else
            StopMultiFling()
        end
    end
})

-- Старые функции (Touch / Anti)
local flingActionsFolder = flingSection:AddFolder({ Name = "Other Actions", Description = "Mass fling & protection" })
flingActionsFolder:AddToggle({
    Name = "Touch Fling", Description = "Fling anyone who touches you", Default = false,
    Callback = function(v)
        flingActive = v
        if v then task.spawn(flingLoop) end
        Window:Notify({ Title = "Touch Fling", Text = v and "Enabled" or "Disabled" })
    end,
})
flingActionsFolder:AddToggle({
    Name = "Anti-Fling", Description = "Protection against fling exploits", Default = false,
    Callback = function(v)
        toggleAntiFling(v)
        Window:Notify({ Title = "Anti-Fling", Text = v and "Enabled" or "Disabled" })
    end,
})

local hbSection = CombatTab:AddSection("Hitbox")
hbSection:AddToggle({
    Name = "Enable Hitboxes", Description = "Expand player hitboxes", Default = false,
    Callback = function(v)
        HitboxConfig.Enabled = v
        if not v then ResetHitboxes() end
        Window:Notify({ Title = "Hitboxes", Text = v and "Enabled" or "Disabled" })
    end,
})
local hbFolder = hbSection:AddFolder({ Name = "Hitbox Settings", Description = "Size & appearance" })
hbFolder:AddSlider({
    Name = "Hitbox Size", Description = "Size of the hitbox",
    Min = 2, Max = 100, Default = 15, Increment = 1,
    Callback = function(v)
        HitboxConfig.Size = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Hitbox Size", v) end)
    end,
})
hbFolder:AddSlider({
    Name = "Transparency", Description = "0 - Visible, 1 - Invisible",
    Min = 0, Max = 1, Default = 0.7, Increment = 0.1,
    Callback = function(v)
        HitboxConfig.Transparency = v
        if wsDebounce then task.cancel(wsDebounce) end
        wsDebounce = task.delay(0.5, function() notifySlider("Hitbox Transparency", v) end)
    end,
})
hbFolder:AddColorpicker({
    Name = "Hitbox Color", Description = "Color of the expanded hitbox", Default = Color3.fromRGB(150, 150, 150),
    Callback = function(c) HitboxConfig.Color = c end,
})
end


--=====================================================================
--  TAB: TROLL
--=====================================================================
do
local TrollTab = Window:AddTab({ Name = "Troll", Shape = "Ghost-ish" })
local trollSection = TrollTab:AddSection("Troll Actions")

trollSection:AddToggle({
    Name = "Jerk Off (Tool)",
    Description = "IY-style: equips a tool that plays the animation",
    Default = false,
    Callback = function(v)
        if v then StartJerkTool() else StopJerkTool() end
    end,
})

local bangSection = TrollTab:AddSection("Bang")

local bangDropdown
bangDropdown = bangSection:AddMultiDropdown({
    Name = "Target Player",
    Description = "Выбери ровно одного (или Self)",
    Options = { { value = "Self", display = "Self" } },
    Single = true, -- <<< Включаем режим одиночного выбора
    Callback = function(selectedTable)
        local chosen = nil
        for k, isSel in pairs(selectedTable or {}) do
            if isSel then chosen = k; break end
        end

        if not chosen then
            if bangToggleEnabled then
                bangToggleEnabled = false
                if bangToggle then pcall(function() bangToggle:Set(false, true) end) end
            end
            StopBang()
            return
        end

        if bangToggleEnabled then
            if chosen == "Self" then
                StartBang(nil)
            else
                local p = Players:FindFirstChild(chosen)
                if p then
                    StartBang(p)
                else
                    if Window then Window:Notify({ Title = "Bang", Text = "Target not found" }) end
                    bangToggleEnabled = false
                    if bangToggle then pcall(function() bangToggle:Set(false, true) end) end
                    StopBang()
                end
            end
        end
    end,
})

local function RefreshBangDropdown()
    local list = { { value = "Self", display = "Self" } }
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, {
                value = plr.Name,
                display = plr.DisplayName .. " (@" .. plr.Name .. ")",
            })
        end
    end
    if bangDropdown and bangDropdown.SetOptions then
        local prev = (bangDropdown.Get and bangDropdown:Get()) or {}
        pcall(function() bangDropdown:SetOptions(list) end)

        -- Восстановить выбор, если ключ ещё валиден
        local valid, hasAny = {}, false
        for k, v in pairs(prev) do
            if v then
                local ok = (k == "Self")
                if not ok then
                    for _, item in ipairs(list) do
                        if item.value == k then ok = true break end
                    end
                end
                if ok then valid[k] = true; hasAny = true end
            end
        end
        if hasAny then
            pcall(function() bangDropdown:Set(valid) end)
        end
    end
end

RefreshBangDropdown()

task.spawn(function()
    while bangRefreshRunning and not isUnloaded do
        task.wait(3)
        pcall(RefreshBangDropdown)
    end
end)

track(Players.PlayerRemoving:Connect(function(plr)
    local sel = (bangDropdown and bangDropdown.Get and bangDropdown:Get()) or {}
    if sel[plr.Name] then
        pcall(function() bangDropdown:Set({}) end)
        if bangToggleEnabled then
            bangToggleEnabled = false
            if bangToggle then pcall(function() bangToggle:Set(false, true) end) end
        end
        StopBang()
    end
end))

bangToggle = bangSection:AddToggle({
    Name = "Bang",
    Description = "Воспроизвести анимацию на выбранной цели",
    Default = false,
    Callback = function(v)
        bangToggleEnabled = v
        if v then
            local sel = (bangDropdown and bangDropdown.Get and bangDropdown:Get()) or {}
            local chosen = nil
            for k, isSel in pairs(sel) do
                if isSel then chosen = k; break end
            end

            if not chosen then
                if Window then Window:Notify({ Title = "Bang", Text = "Сначала выбери цель" }) end
                bangToggleEnabled = false
                pcall(function() bangToggle:Set(false, true) end)
                return
            end

            if chosen == "Self" then
                StartBang(nil)
            else
                local targetPlayer = Players:FindFirstChild(chosen)
                if targetPlayer then
                    StartBang(targetPlayer)
                else
                    if Window then Window:Notify({ Title = "Bang", Text = "Target not found" }) end
                    bangToggleEnabled = false
                    pcall(function() bangToggle:Set(false, true) end)
                end
            end
        else
            StopBang()
        end
    end,
})
end

--=====================================================================
--  TAB: SETTINGS
--=====================================================================
do
local SettingsTab = Window:AddTab({ Name = "Settings", Shape = "Flower" })

local ifc = SettingsTab:AddSection("Settings")

local function getThemeSeed()
    if Window.ThemeName == "Custom" and Window.CustomThemeColor then
        return Window.CustomThemeColor
    end
    local preset = UI.Themes[Window.ThemeName]
    if preset and preset.seed then return preset.seed end
    return Window.Colors.primary
end

local themePicker = ifc:AddColorpicker({
    Name = "Custom Theme Color", Description = "Pick any color — dark/light auto-detects by brightness",
    Default = getThemeSeed(),
    Callback = function(c)
        Window:SetThemeFromColor(c)
        Window:Notify({ Title = "Theme", Text = "Color updated" })
    end,
})

local function syncPickerSwatch()
    if themePicker and themePicker.Set then
        pcall(function() themePicker:Set(getThemeSeed(), true) end)
    end
end

Window:OnTheme(syncPickerSwatch)
task.defer(syncPickerSwatch)

ifc:AddKeybind({
    Name = "Toggle UI Keybind", Description = "Show/Hide interface",
    Default = Enum.KeyCode.CapsLock,
    Callback = function(k)
        if k then
            Window:SetToggleKey(k)
            Window:Notify({ Title = "Keybind", Text = "UI toggle set to " .. k.Name })
        end
    end,
})
ifc:AddButton({
    Name = "Unload Script", Description = "Completely disable script",
    ButtonText = "Unload",
    Callback = function() Window:Close() end,
})

task.delay(4, function()
    Window:Notify({ Title = "System42", Text = "Thank you for using Zibvabva" })
end)
end
