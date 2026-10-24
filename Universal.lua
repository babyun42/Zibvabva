--=====================================================================
--  Zibvabva — Material You edition
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

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/babyun42/Zibvabva/refs/heads/main/MaterialYouUI.lua?v=3"))()

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

local function purgeAllZibvabvaHighlights()
    -- по всем игрокам
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Highlight") and obj.Name == "ZibvabvaHighlight" then
                    obj.Enabled = false
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
    -- страховка: по всему Workspace
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Name == "ZibvabvaHighlight" then
                obj.Enabled = false
                pcall(function() obj:Destroy() end)
            end
        end
    end)
    -- и по CoreGui/PlayerGui (на случай если кто-то куда-то положил)
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Name == "ZibvabvaHighlight" then
                obj.Enabled = false
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

local flySpeed = 35
local isFlying = false
local isNoclip = false
local spinbotEnabled = false
local spinbotSpeed = 20
local InfiniteJumpEnabled = false
local clickTpEnabled = false
local infZoomEnabled = false
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

--=====================================================================
--  FLIGHT (Синхронизация с UI + полет по камере)
--=====================================================================
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.P = 9e4
bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)

-- Объявляем заранее, чтобы функция setFlightState могла её обновлять
local flyToggle

local function onFlyStep()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"))

    if not char or not hum or not torso or not isFlying then return end

    -- Поворот тела за камерой
    bodyGyro.CFrame = Camera.CFrame

    -- Движение (полет туда, куда смотрит камера)
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

    -- СИНХРОНИЗАЦИЯ С ГУИ (обновляет тумблер в интерфейсе)
    if flyToggle then
        pcall(function() flyToggle:Set(state, true) end)
    end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return end

    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")

    if isFlying then
        if torso then
            bodyGyro.Parent = torso
            bodyVelocity.Parent = torso
        end

        hum.PlatformStand = true
        hum:ChangeState(Enum.HumanoidStateType.Swimming)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

        if char:FindFirstChild("Animate") then
            char.Animate.Disabled = true
        end
        for _, v in pairs(hum:GetPlayingAnimationTracks()) do
            v:AdjustSpeed(0)
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        if not flyConnection then
            flyConnection = RunService.RenderStepped:Connect(onFlyStep)
        end
    else
        bodyGyro.Parent = nil
        bodyVelocity.Parent = nil

        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)

        if char:FindFirstChild("Animate") then
            char.Animate.Disabled = false
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end

        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    if isUnloaded then return end -- Если скрипт выгружен, ничего не делаем

    -- Сбрасываем тумблер полета при смерти
    if isFlying then
        isFlying = false
        if flyToggle then
            pcall(function() flyToggle:Set(false, true) end)
        end
    end

    -- Ждем загрузки и применяем настройки
    task.wait(0.5)
    if isUnloaded then return end -- Проверяем еще раз после ожидания

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = currentWalkSpeed
        hum.JumpPower = currentJumpPower
        hum.PlatformStand = false
    end
    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = false
    end
end))

--=====================================================================
--  NOCLIP
--=====================================================================
local noclipToggle -- объявляем заранее

local function setNoclipState(state)
        if isUnloaded then return end
    isNoclip = state

    -- СИНХРОНИЗАЦИЯ С GUI
    if noclipToggle then
        pcall(function() noclipToggle:Set(state, true) end)
    end

    if isNoclip then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
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
        for _, p in ipairs(invisibleParts) do
            p.Transparency = 0.5
        end
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
    else
        if invisibleConnection then
            invisibleConnection:Disconnect()
            invisibleConnection = nil
        end
        for _, p in ipairs(invisibleParts) do
            if p and p.Parent then
                p.Transparency = 0
            end
        end
        if hum then
            hum.CameraOffset = Vector3.zero
        end
    end
end

--=====================================================================
--  SPINBOT
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

--=====================================================================
--  INFINITE JUMP
--=====================================================================
track(UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

--=====================================================================
--  ANTI-AFK
--=====================================================================
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
local HitboxConfig = {
    Enabled = false,
    Size = 15,
    Color = Color3.fromRGB(150, 150, 150),
    Transparency = 0.7,
}

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
--  ESP
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

    ESPCache[plr] = {
        Box = box,
        BoxStroke = boxStroke,
        Tracer = tracer,
        NameTag = nameTag,
        HBOutline = hbOutline,
        HB = hb,
        HeadDot = headDot,
    }
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
    if hum and hum.Health <= 0 then
        return false, 0, 0, 0, 0
    end
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
                    cf * CFrame.new(-s.X/2, -s.Y/2, -s.Z/2),
                    cf * CFrame.new( s.X/2, -s.Y/2, -s.Z/2),
                    cf * CFrame.new(-s.X/2,  s.Y/2, -s.Z/2),
                    cf * CFrame.new( s.X/2,  s.Y/2, -s.Z/2),
                    cf * CFrame.new(-s.X/2, -s.Y/2,  s.Z/2),
                    cf * CFrame.new( s.X/2, -s.Y/2,  s.Z/2),
                    cf * CFrame.new(-s.X/2,  s.Y/2,  s.Z/2),
                    cf * CFrame.new( s.X/2,  s.Y/2,  s.Z/2),
                }
                for _, cornerCf in ipairs(corners) do
                    local sp = Camera:WorldToViewportPoint(cornerCf.Position)
                    if sp.Z > 0 then
                        any = true
                        minX = math.min(minX, sp.X)
                        minY = math.min(minY, sp.Y)
                        maxX = math.max(maxX, sp.X)
                        maxY = math.max(maxY, sp.Y)
                    end
                end
            end
        end
    end
    if not any then
        return false, 0, 0, 0, 0
    end
    local w, h = maxX - minX, maxY - minY
    if w > h * 2 or h > 800 or w > 800 then
        return false, 0, 0, 0, 0
    end
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

local function getInvertedColor(c)
    return Color3.new(1 - c.R, 1 - c.G, 1 - c.B)
end

GetTarget = function()
    local current, maxDist = nil, Config.FOV_Radius
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Config.TargetPart) then
            if Config.TeamCheck and plr.Team == LocalPlayer.Team then
                continue
            end
            local part = plr.Character[Config.TargetPart]
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < maxDist then
                    current = part
                    maxDist = d
                end
            end
        end
    end
    return current
end

track(RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local rainbow = Color3.fromHSV(tick() % 5 / 5, 1, 1)

    if not Config.ESP_Enabled then
        hideAllESP()
    end

    local activeTarget = nil
    if Config.Aimbot_Enabled and IsLocking then
        activeTarget = GetTarget()
    end
    local activeTargetPlayer = activeTarget and Players:GetPlayerFromCharacter(activeTarget.Parent) or nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not ESPCache[plr] then
                createESP(plr)
            end
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
                    else
                        v.Box.Visible = false
                    end

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
                    else
                        v.Tracer.Visible = false
                    end

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
                    else
                        v.HeadDot.Visible = false
                    end

                    if Config.HealthBar_Enabled then
                        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local hpc = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hp)
                        if Config.HealthBarPosition == "Right" then
                            v.HBOutline.Size = UDim2.new(0, 4, 1, 0)
                            v.HBOutline.Position = UDim2.new(1, 3, 0, 0)
                            v.HB.Size = UDim2.new(1, 0, hp, 0)
                            v.HB.Position = UDim2.new(0, 0, 1, 0)
                            v.HB.AnchorPoint = Vector2.new(0, 1)
                        elseif Config.HealthBarPosition == "Left" then
                            v.HBOutline.Size = UDim2.new(0, 4, 1, 0)
                            v.HBOutline.Position = UDim2.new(0, -7, 0, 0)
                            v.HB.Size = UDim2.new(1, 0, hp, 0)
                            v.HB.Position = UDim2.new(0, 0, 1, 0)
                            v.HB.AnchorPoint = Vector2.new(0, 1)
                        else
                            v.HBOutline.Size = UDim2.new(1, 0, 0, 4)
                            v.HBOutline.Position = UDim2.new(0, 0, 0, -7)
                            v.HB.Size = UDim2.new(hp, 0, 1, 0)
                            v.HB.Position = UDim2.new(0, 0, 0, 0)
                            v.HB.AnchorPoint = Vector2.new(0, 0)
                        end
                        v.HB.BackgroundColor3 = hpc
                        v.HBOutline.Visible = true
                    else
                        v.HBOutline.Visible = false
                    end
                else
                    v.Box.Visible = false
                    v.Tracer.Visible = false
                    v.NameTag.Visible = false
                    v.HeadDot.Visible = false
                    v.HBOutline.Visible = false
                end
            elseif v then
                v.Box.Visible = false
                v.Tracer.Visible = false
                v.NameTag.Visible = false
                v.HeadDot.Visible = false
                v.HBOutline.Visible = false
            end
        end
    end
end))

track(Players.PlayerRemoving:Connect(removeESP))

--=====================================================================
--  HIGHLIGHT ESP (самодостаточная версия)
--=====================================================================
local HIGHLIGHT_NAME = "ZibvabvaHighlight"
local highlightWasActive = false

-- Полная очистка: Character'ы игроков + Workspace
local function purgeAllZibvabvaHighlights()
    -- по Character'ам всех игроков
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
    -- и по всему workspace (страховка)
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

-- ГЛАВНЫЙ цикл: чистит всё, как только ESP/Highlight выключился
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
        -- как только что-то выключилось — один раз сносим всё
        if highlightWasActive then
            highlightWasActive = false
            purgeAllZibvabvaHighlights()
        end
    end
end))

-- если игрок вышел — Highlight уйдёт с его Character'ом автоматически,
-- но на всякий случай тоже пробуем снять
track(Players.PlayerRemoving:Connect(function(plr)
    local char = plr.Character
    if char then
        local h = char:FindFirstChild(HIGHLIGHT_NAME)
        if h then pcall(function() h:Destroy() end) end
    end
end))

-- убираем Highlight у выходящих игроков
track(Players.PlayerRemoving:Connect(removeHighlightFor))
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
        if Config.FOV_Rainbow then
            FOVStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else
            FOVStroke.Color = Config.FOV_Color
        end
    else
        FOVCircle.Visible = false
    end

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
local triggerbotHolding = false   -- сейчас ли держим ЛКМ от бота
local triggerbotLastShot = 0

-- Проверка: смотрит ли мышь на игрока
local function isMouseOnPlayer()
    local target = Mouse.Target
    if not target then return nil end

    local parent = target.Parent
    if not parent then return nil end

    -- Прямой Humanoid (R6: голова/торс/руки/ноги — все дети character)
    local hum = parent:FindFirstChildOfClass("Humanoid")
    if hum then return hum, parent end

    -- R15 / accessory / tool — проверяем родителей
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

-- Виртуальный клик мышью (глобальные функции в большинстве executor'ов)
local function botMouse1Press()
    if mouse1press then
        pcall(mouse1press)
    elseif mousemoverel then
        -- fallback — но реальный клик не сделать; пропускаем
    end
end

local function botMouse1Release()
    if mouse1release then
        pcall(mouse1release)
    end
end

track(RunService.RenderStepped:Connect(function()
    if isUnloaded then return end
    if not triggerbotEnabled then
        if triggerbotHolding then
            botMouse1Release()
            triggerbotHolding = false
        end
        return
    end

    local hum, char = isMouseOnPlayer()

    -- если на игрока не смотрим — отпускаем
    if not hum or not char then
        if triggerbotHolding then
            botMouse1Release()
            triggerbotHolding = false
        end
        return
    end

    -- свой персонаж — не стреляем
    if char == LocalPlayer.Character then
        if triggerbotHolding then
            botMouse1Release()
            triggerbotHolding = false
        end
        return
    end

    -- мёртвый — не стреляем
    if hum.Health <= 0 then
        if triggerbotHolding then
            botMouse1Release()
            triggerbotHolding = false
        end
        return
    end

    -- team check (если нужно)
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and Config.TeamCheck and plr.Team == LocalPlayer.Team then
        if triggerbotHolding then
            botMouse1Release()
            triggerbotHolding = false
        end
        return
    end

    -- всё ок — жмём ЛКМ
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
--  FLING
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

local function SkidFling(TargetPlayer)
    local Player = Players.LocalPlayer
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    local Root = Hum and Hum.RootPart
    if not Char or not Hum or not Root then return end
    local TChar = TargetPlayer.Character
    if not TChar then return end
    local THum = TChar:FindFirstChildOfClass("Humanoid")
    local TRoot = THum and THum.RootPart
    if not THum or not TRoot then return end

    local origFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity", Root)
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local function FPos(base, pos, ang)
        Root.CFrame = CFrame.new(base.Position) * pos * ang
        Char:SetPrimaryPartCFrame(CFrame.new(base.Position) * pos * ang)
        Root.Velocity = Vector3.new(9e7, 9e8, 9e7)
        Root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local t0 = tick()
    local ang = 0
    repeat
        if not flingAllActive or not TargetPlayer.Parent or not TChar.Parent then break end
        if THum.Sit or Hum.Health <= 0 then break end
        ang = ang + 100
        FPos(TRoot, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(ang), 0, 0))
        task.wait()
        FPos(TRoot, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(ang), 0, 0))
        task.wait()
    until TRoot.Velocity.Magnitude > 500 or tick() > t0 + 2

    BV:Destroy()
    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.FallenPartsDestroyHeight = origFPDH
end

local function flingAllLoop()
    while flingAllActive and not isUnloaded do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                coroutine.wrap(function()
                    pcall(function() SkidFling(plr) end)
                end)()
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
end

local function toggleAntiFling(state)
    antiFlingEnabled = state
    if antiFlingEnabled then
        if not antiFlingConnection then
            antiFlingConnection = RunService.Stepped:Connect(function()
                for i = 1, #playerPartsCache do
                    if playerPartsCache[i] then
                        playerPartsCache[i].CanCollide = false
                    end
                end
            end)
        end
    else
        if antiFlingConnection then
            antiFlingConnection:Disconnect()
            antiFlingConnection = nil
        end
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
                        if p:IsA("BasePart") then
                            table.insert(c, p)
                        end
                    end
                end
            end
            playerPartsCache = c
        end
    end
end)

--=====================================================================
--  FREECAM + Infinite Zoom + Wheel
--=====================================================================
local function ToggleFreecam(state)
    freecamActive = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if freecamActive then
        if hrp then hrp.Anchored = true end
        freecamCamPos = Camera.CFrame.Position
        local x, y = Camera.CFrame:ToEulerAnglesYXZ()
        freecamRotX = x
        freecamRotY = y
        Camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        freecamFOV = Config.Camera_FOV
        Camera.FieldOfView = freecamFOV
    else
        if hrp then hrp.Anchored = false end
        Camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Camera.FieldOfView = Config.Camera_FOV
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
    local cz = LocalPlayer.CameraMaxZoomDistance or 4000
    if s > 0 then
        LocalPlayer.CameraMaxZoomDistance = math.max(cz - WHEEL_STEP, 10)
    else
        local nz = cz + WHEEL_STEP
        if not infZoomEnabled then
            nz = math.min(nz, 1000)
        else
            if nz > 1000 and currentMaxZoom < 1000 then
                currentMaxZoom = 1000
            end
            if nz > currentMaxZoom then
                currentMaxZoom = nz
            end
            local zd = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
            if zd >= LocalPlayer.CameraMaxZoomDistance - 5 then
                currentMaxZoom = math.max(currentMaxZoom * 1.5, nz)
            end
        end
        LocalPlayer.CameraMaxZoomDistance = nz
    end
end))

--=====================================================================
--  LIGHTING / GAMMA / SHADOWS
--=====================================================================
local gammaEffect = Lighting:FindFirstChild("GammaCorrection") or Instance.new("ColorCorrectionEffect")
gammaEffect.Name = "GammaCorrection"
gammaEffect.Parent = Lighting

local function setGamma(v)
    gammaEffect.Brightness = math.clamp(v, -1, 1)
end
local function setShadowsDisabled(s)
    Lighting.GlobalShadows = not s
end

--=====================================================================
--  NAMETAG
--=====================================================================
local nameTagText = "[GOD]"
local nameTagColor = Color3.fromRGB(255, 215, 0)
local nameTagApplied = false

local function applyNameTag()
    nameTagApplied = true
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.DisplayName = nameTagText .. " " .. LocalPlayer.Name
        end
    end
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    if not nameTagApplied then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.DisplayName = nameTagText .. " " .. LocalPlayer.Name
    end
end))

local function patchPlayerList()
    if not nameTagApplied then return end
    local list = CoreGui:FindFirstChild("PlayerList")
    if not list then return end
    for _, o in ipairs(list:GetDescendants()) do
        if o:IsA("TextLabel") or o:IsA("TextButton") then
            local t = o.Text
            if (t == LocalPlayer.Name or t == LocalPlayer.DisplayName) and not t:find(nameTagText, 1, true) then
                o.Text = nameTagText .. " " .. t
                o.TextColor3 = nameTagColor
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
    for _, sample in ipairs(s:GetChildren()) do
        if sample.Name == "sample" then
            local nl = sample:FindFirstChild("name")
            if nl and nl:IsA("TextLabel") and nl.Text:find(LocalPlayer.Name, 1, true) then
                if not nl.Text:find(nameTagText, 1, true) then
                    nl.Text = nameTagText .. " " .. nl.Text
                    nl.TextColor3 = nameTagColor
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

    -- 1. ПРИНУДИТЕЛЬНО СБРАСЫВАЕМ СКОРОСТЬ И ПРЫЖОК
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
    end
    currentWalkSpeed = 16
    currentJumpPower = 50

    -- 2. СБРАСЫВАЕМ ВСЕ ФУНКЦИИ (чтобы бинды не срабатывали)
    Config.ESP_Enabled = false
    Config.Aimbot_Enabled = false
    Config.Highlight_Enabled = false
    HitboxConfig.Enabled = false
    ResetHitboxes()

    ToggleInvisible(false)
    setFlightState(false)
    setNoclipState(false)
    toggleAntiAFK(false)
    toggleAntiFling(false)
    if freecamActive then ToggleFreecam(false) end

    infZoomEnabled = false
    pcall(function() LocalPlayer.CameraMaxZoomDistance = originalMaxZoom end)
    spinbotEnabled = false
    InfiniteJumpEnabled = false
    clickTpEnabled = false
    flingActive = false
    flingAllActive = false

    if Camera then Camera.FieldOfView = 70 end
    setGamma(0)
    pcall(function() Lighting.GlobalShadows = originalGlobalShadows end)

    -- 3. УДАЛЯЕМ ВСЕ ХАЙЛАЙТЫ И ESP
    purgeAllZibvabvaHighlights()
    for p in pairs(ESPCache) do
        removeESP(p)
    end
    pcall(function() ESPContainer:Destroy() end)
    pcall(function() FOVGui:Destroy() end)

    -- 4. УНИЧТОЖАЕМ ОКНО (это отключит все UI-бинды)
    if Window then
        pcall(function() Window:Destroy() end)
    end

    -- 5. ОТКЛЮЧАЕМ ВСЕ КОННЕКТЫ (кастомные бинды)
    untrackAll()

    if GENV.__Zibvabva_Unload == unloadScript then
        GENV.__Zibvabva_Unload = nil
    end
end

GENV.__Zibvabva_Unload = unloadScript

--=====================================================================
--  FLASHBACK
--=====================================================================
local FB = {
    frames      = {},
    maxFrames   = 6000,       -- ~100 sec at 60 fps
    speed       = 0.5,          -- frames per frame when reverting
    toggleActive = false,     -- UI toggle
    keybindActive = false,    -- held key
    lastInput   = false,
    canRevert   = true,
    accum       = 0,
}

local function fbGetHrp(c)
    return c:FindFirstChild("HumanoidRootPart")
        or c.RootPart
        or c.PrimaryPart
        or c:FindFirstChild("Torso")
        or c:FindFirstChild("UpperTorso")
        or c:FindFirstChildWhichIsA("BasePart")
end

local function fbIsActive()
    return FB.toggleActive or FB.keybindActive
end

local function fbAdvance(char, hrp, hum, allowInput)
    if #FB.frames > FB.maxFrames then
        table.remove(FB.frames, 1)
    end
    if allowInput and not FB.canRevert then
        FB.canRevert = true
    end
    if FB.lastInput then
        hum.PlatformStand = false
        FB.lastInput = false
    end
    table.insert(FB.frames, {
        hrp.CFrame,
        hrp.Velocity,
        hum:GetState(),
        hum.PlatformStand,
        char:FindFirstChildOfClass("Tool"),
    })
end

local function fbRevert(char, hrp, hum)
    local num = #FB.frames
    if num == 0 or not FB.canRevert then
        FB.canRevert = false
        fbAdvance(char, hrp, hum)
        return
    end

    FB.accum = FB.accum + FB.speed
    local steps = math.floor(FB.accum)
    if steps < 1 then return end
    FB.accum = FB.accum - steps

    for _ = 1, steps do
        if num <= 0 then break end
        table.remove(FB.frames, num)
        num = num - 1
    end

    if num <= 0 then
        FB.accum = 0
        return
    end

    FB.lastInput = true
    local lastFrame = FB.frames[num]
    table.remove(FB.frames, num)
    if not lastFrame then return end

    hrp.CFrame       = lastFrame[1]
    hrp.Velocity     = -lastFrame[2]
    hum:ChangeState(lastFrame[3])
    hum.PlatformStand = lastFrame[4]

    local currentTool = char:FindFirstChildOfClass("Tool")
    if lastFrame[5] then
        if not currentTool then
            hum:EquipTool(lastFrame[5])
        end
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

    if fbIsActive() then
        fbRevert(char, hrp, hum)
    else
        fbAdvance(char, hrp, hum, true)
        FB.accum = 0
    end
end))

--=====================================================================
--  UI — WINDOW
--=====================================================================
Window = UI:CreateWindow({
    Title = "Zibvabva",
    Subtitle = "babyun42",
    Version = "v1.0",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.CapsLock,
    LogoShape = "Flower",
    Intro = true,
    OnUnload = unloadScript,
})

--=====================================================================
--  TAB: PLAYER
--=====================================================================
local PlayerTab = Window:AddTab({ Name = "Player", Shape = "Circle" })

local mov = PlayerTab:AddSection("Movement")
mov:AddSlider({
    Name = "WalkSpeed", Description = "Character walk speed",
    Min = 16, Max = 300, Default = 16, Increment = 1,
    Callback = function(v)
        currentWalkSpeed = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end,
})
mov:AddSlider({
    Name = "JumpPower", Description = "Character jump power",
    Min = 50, Max = 400, Default = 50, Increment = 1,
    Callback = function(v)
        currentJumpPower = v
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v end
    end,
})
mov:AddToggle({
    Name = "Infinite Jump",
    Description = "Mid-air jumping",
    Default = false,
    Callback = function(v) InfiniteJumpEnabled = v end,
})

local pactions = PlayerTab:AddSection("Player Actions")

local flightFolder = pactions:AddFolder({ Name = "Flight", Description = "Toggle flight mode" })
flyToggle = flightFolder:AddToggle({
    Name = "Enable Fly",
    Default = false,
    Callback = function(v)
        if isFlying ~= v then
            setFlightState(v)
        end
    end
})
flightFolder:AddSlider({
    Name = "Fly Speed",
    Min = 20, Max = 300, Default = 35, Increment = 1,
    Callback = function(v)
        flySpeed = v
    end
})
flightFolder:AddKeybind({
    Name = "Fly Keybind",
    Default = Enum.KeyCode.F, -- Обязательно Enum.KeyCode!
    OnPress = function()
        setFlightState(not isFlying)
    end,
})

local noclipFolder = pactions:AddFolder({ Name = "Noclip", Description = "Walk through walls" })
noclipToggle = noclipFolder:AddToggle({
    Name = "Enable Noclip",
    Default = false,
    Callback = function(v)
        if isNoclip ~= v then setNoclipState(v) end
    end
})
noclipFolder:AddKeybind({
    Name = "Noclip Keybind",
    Default = Enum.KeyCode.X,
    Callback = function(k) end,
    OnPress = function()
        setNoclipState(not isNoclip)
    end,
})

local tpFolder = pactions:AddFolder({ Name = "Click Teleport", Description = "Teleport to mouse cursor" })
tpFolder:AddToggle({
    Name = "Enable Teleport",
    Default = false,
    Callback = function(v) clickTpEnabled = v end,
})
tpFolder:AddKeybind({
    Name = "Teleport Keybind",
    Default = Enum.KeyCode.E,
    OnPress = function()
        if not clickTpEnabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and Mouse.Hit then
            if hum and hum.Sit then
                hum.Sit = false
                task.wait(0.1)
            end
            hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.5, 0))
        end
    end,
})

local spinFolder = pactions:AddFolder({ Name = "Spinbot", Description = "Rapid rotation" })
spinFolder:AddToggle({
    Name = "Enable Spinbot",
    Default = false,
    Callback = function(v) spinbotEnabled = v end,
})
spinFolder:AddSlider({
    Name = "Spin Speed",
    Min = 1, Max = 100, Default = 20, Increment = 1,
    Callback = function(v) spinbotSpeed = v end,
})

local invisFolder = pactions:AddFolder({ Name = "Invisibility", Description = "Client-side invisibility" })
local invisToggle
invisToggle = invisFolder:AddToggle({
    Name = "Invisible",
    Default = false,
    Callback = function(v) if IsInvisible ~= v then ToggleInvisible(v) end end,
})
invisFolder:AddSlider({
    Name = "Teleport Distance",
    Min = 50000, Max = 1000000, Default = 200000, Increment = 10000,
    Callback = function(v) invisibleDistance = v end,
})
invisFolder:AddKeybind({
    Name = "Invisibility Keybind",
    Default = Enum.KeyCode.M,
    OnPress = function()
        local nv = not IsInvisible
        ToggleInvisible(nv)
        if invisToggle then invisToggle:Set(nv, true) end
    end,
})

local fbFolder = pactions:AddFolder({ Name = "Flashback", Description = "Records your actions and repeats them" })
local fbToggle
fbToggle = fbFolder:AddToggle({
    Name = "Flashback",
    Description = "All actions play in reverse",
    Default = false,
    Callback = function(v)
        FB.toggleActive = v
        if not v then FB.accum = 0 end
    end,
})

local fbKey = Enum.KeyCode.R
local fbKeybindObj
fbKeybindObj = fbFolder:AddKeybind({
    Name = "Hold to Flashback",
    Description = "Hold key — actions reverse. Release — resume.",
    Default = Enum.KeyCode.R,
    Callback = function(k)
        if k then
            fbKey = k
            FB.keybindActive = false
        end
    end,
    OnPress = function()
        FB.keybindActive = true
    end,
})

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == fbKey then
        FB.keybindActive = false
        FB.accum = 0
    end
end))

fbFolder:AddSlider({
    Name = "Speed",
    Description = "Frames reverted per frame (0.5 = normal, 5 = fast)",
    Min = 0.25, Max = 5, Default = 0.5, Increment = 0.25,
    Callback = function(v)
        FB.speed = v
        FB.accum = 0
    end,
})

fbFolder:AddButton({
    Name = "Reset",
    Description = "Clear recorded frames and turn off",
    ButtonText = "Reset",
    Callback = function()
        FB.frames = {}
        FB.toggleActive = false
        FB.keybindActive = false
        FB.accum = 0
        FB.canRevert = true
        if fbToggle then
            pcall(function() fbToggle:Set(false, true) end)
        end
    end,
})

local other = PlayerTab:AddSection("Other")
other:AddToggle({
    Name = "Enable Anti-AFK",
    Description = "Prevents AFK kick",
    Default = true,
    Callback = function(v) toggleAntiAFK(v) end,
})
toggleAntiAFK(true)

--=====================================================================
--  TAB: VISUALS
--=====================================================================
local VisualsTab = Window:AddTab({ Name = "Visuals", Shape = "Diamond" })

local espSection = VisualsTab:AddSection("ESP")

-- предзаполняем все ключи, чтобы linter не ругался
local espToggles = {
    Enabled = nil,
    Boxes = nil,
    Tracers = nil,
    HeadDot = nil,
    HealthBar = nil,
    NameTag = nil,
}
local espPreview = nil
local hpPosDropdown = nil

local function syncToggle(key, value)
    local KEY_MAP = {
        boxes = "Boxes",
        tracers = "Tracers",
        headDot = "HeadDot",
        healthBar = "HealthBar",
        nameTag = "NameTag",
    }
    local normKey = KEY_MAP[key] or key

    local tgl = espToggles[normKey]
    if tgl then
        pcall(function() tgl:Set(value, true) end)
    end

    if normKey == "Enabled" then
        Config.ESP_Enabled = value
    elseif normKey == "Boxes" then
        Config.Boxes_Enabled = value
    elseif normKey == "Tracers" then
        Config.Tracers_Enabled = value
    elseif normKey == "HeadDot" then
        Config.HeadDot_Enabled = value
    elseif normKey == "HealthBar" then
        Config.HealthBar_Enabled = value
    elseif normKey == "NameTag" then
        Config.NameTag_Enabled = value
    end
end

espPreview = espSection:AddESPPreview({
    Enabled = Config.ESP_Enabled,
    Boxes = Config.Boxes_Enabled,
    Tracers = Config.Tracers_Enabled,
    HeadDot = Config.HeadDot_Enabled,
    HealthBar = Config.HealthBar_Enabled,
    NameTag = Config.NameTag_Enabled,
    Rainbow = Config.RainbowBoxes,
    BoxColor = Config.BoxColor,
    TracerColor = Config.TracerColor,
    NameColor = Config.NameColor,
    HealthPercent = 0.75,
    HealthPosition = Config.HealthBarPosition,
    NameText = "Player",

    OnToggle = function(key, value)
        syncToggle(key, value)
    end,
    OnHealthPos = function(pos)
        Config.HealthBarPosition = pos
        Config.HealthBar_Enabled = true
        if espPreview then espPreview:SetHealthBar(true) end
        if hpPosDropdown then
            pcall(function() hpPosDropdown:Set(pos, true) end)
        end
        if espToggles.HealthBar then
            pcall(function() espToggles.HealthBar:Set(true, true) end)
        end
    end,
})

espToggles.Enabled = espSection:AddToggle({
    Name = "Enable ESP",
    Default = false,
    Callback = function(v)
        Config.ESP_Enabled = v
        espPreview:SetEnabled(v)

        -- при выключении ESP гасим Highlight
        if not v then
            Config.Highlight_Enabled = false
            if highlightToggle then
                pcall(function() highlightToggle:Set(false, true) end)
            end
            -- чистим прямо сейчас, не ждём RenderStepped
            if purgeAllZibvabvaHighlights then
                pcall(purgeAllZibvabvaHighlights)
            end
        end
    end,
})

local espFolder = espSection:AddFolder({ Name = "ESP Settings", Description = "Master + features" })

espToggles.Boxes = espFolder:AddToggle({
    Name = "Boxes",
    Default = true,
    Callback = function(v)
        Config.Boxes_Enabled = v
        espPreview:SetBoxes(v)
    end,
})
espFolder:AddToggle({
    Name = "Highlight Players",
    Default = true,
    Callback = function(v)
        Config.Highlight_Enabled = v
        if not v and purgeAllZibvabvaHighlights then
            pcall(purgeAllZibvabvaHighlights)
        end
    end,
})
espToggles.Tracers = espFolder:AddToggle({
    Name = "Tracers",
    Default = false,
    Callback = function(v)
        Config.Tracers_Enabled = v
        espPreview:SetTracers(v)
    end,
})
espToggles.HeadDot = espFolder:AddToggle({
    Name = "Head Dot",
    Default = true,
    Callback = function(v)
        Config.HeadDot_Enabled = v
        espPreview:SetHeadDot(v)
    end,
})
espToggles.HealthBar = espFolder:AddToggle({
    Name = "Health Bar",
    Default = true,
    Callback = function(v)
        Config.HealthBar_Enabled = v
        espPreview:SetHealthBar(v)
    end,
})
espToggles.NameTag = espFolder:AddToggle({
    Name = "Name Tag",
    Default = true,
    Callback = function(v)
        Config.NameTag_Enabled = v
        espPreview:SetNameTag(v)
    end,
})
espFolder:AddToggle({
    Name = "Use Display Name",
    Default = false,
    Callback = function(v) Config.UseDisplayName = v end,
})

local espcFolder = espSection:AddFolder({ Name = "ESP Customization", Description = "Colors and display" })

hpPosDropdown = espcFolder:AddDropdown({
    Name = "Health Bar Position",
    Options = { "Right", "Left", "Top" },
    Default = "Right",
    Callback = function(v)
        Config.HealthBarPosition = v
        espPreview:SetHealthPosition(v)
    end,
})
espcFolder:AddColorpicker({
    Name = "Box Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Config.BoxColor = c
        espPreview:SetBoxColor(c)
    end,
})
espcFolder:AddColorpicker({
    Name = "Highlight Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Config.Highlight_Color = c
    end,
})
espcFolder:AddColorpicker({
    Name = "Tracer Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Config.TracerColor = c
        espPreview:SetTracerColor(c)
    end,
})
espcFolder:AddColorpicker({
    Name = "Name Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        Config.NameColor = c
        espPreview:SetNameColor(c)
    end,
})
espcFolder:AddColorpicker({
    Name = "Target Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(c) Config.TargetColor = c end,
})
espcFolder:AddToggle({
    Name = "Target Invert Color",
    Default = false,
    Callback = function(v) Config.UseTargetInvert = v end,
})
espcFolder:AddToggle({
    Name = "Rainbow Highlight",
    Default = false,
    Callback = function(v)
        Config.Highlight_Rainbow = v
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Names",
    Default = false,
    Callback = function(v)
        Config.RainbowNames = v
        espPreview:SetRainbow(v or Config.RainbowBoxes or Config.RainbowTracers)
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Boxes & Heads",
    Default = false,
    Callback = function(v)
        Config.RainbowBoxes = v
        espPreview:SetRainbow(v or Config.RainbowNames or Config.RainbowTracers)
    end,
})
espcFolder:AddToggle({
    Name = "Rainbow Tracers",
    Default = false,
    Callback = function(v)
        Config.RainbowTracers = v
        espPreview:SetRainbow(v or Config.RainbowNames or Config.RainbowBoxes)
    end,
})

local ntSection = VisualsTab:AddSection("Name Tag")
local ntFolder = ntSection:AddFolder({ Name = "Tag Settings", Description = "Prefix text & color" })
ntFolder:AddInput({
    Name = "Tag Text",
    Placeholder = "[GOD]",
    Default = nameTagText,
    Callback = function(t) nameTagText = t end,
})
ntFolder:AddDropdown({
    Name = "Tag Color",
    Options = { "Yellow", "Red", "Green", "Blue", "Pink", "Orange", "Purple", "White", "Cyan" },
    Default = "Yellow",
    Callback = function(v)
        local map = {
            Yellow = Color3.fromRGB(255, 215, 0),
            Red = Color3.fromRGB(255, 0, 0),
            Green = Color3.fromRGB(0, 255, 0),
            Blue = Color3.fromRGB(0, 150, 255),
            Pink = Color3.fromRGB(255, 0, 255),
            Orange = Color3.fromRGB(255, 140, 0),
            Purple = Color3.fromRGB(128, 0, 255),
            White = Color3.fromRGB(255, 255, 255),
            Cyan = Color3.fromRGB(0, 255, 255),
        }
        nameTagColor = map[v] or nameTagColor
    end,
})
ntFolder:AddButton({
    Name = "Apply NameTag",
    Description = "Apply prefix to your name",
    ButtonText = "Apply",
    Callback = function() applyNameTag() end,
})

local shaderSection = VisualsTab:AddSection("Shaders")
local shaderFolder = shaderSection:AddFolder({ Name = "Shader Library", Description = "External graphics packs" })
shaderFolder:AddButton({
    Name = "HDR Graphics",
    Description = "Load HDR pack",
    ButtonText = "Load",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SyntaxScript/HDR-Graphics/main/main.lua"))()
        end)
    end,
})
shaderFolder:AddButton({
    Name = "PShade Ultimate",
    Description = "Load PShade pack",
    ButtonText = "Load",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/back.json"))()
        end)
    end,
})

local toolsSection = VisualsTab:AddSection("Tools")
local toolsFolder = toolsSection:AddFolder({ Name = "Explorer", Description = "Debug tools" })
toolsFolder:AddButton({
    Name = "Dex Explorer",
    Description = "Open Dex++ explorer",
    ButtonText = "Open",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
        end)
    end,
})

local camSection = VisualsTab:AddSection("Camera & Overlay")
local camFolder = camSection:AddFolder({ Name = "Camera", Description = "Freecam & FOV" })
local freecamToggle
freecamToggle = camFolder:AddToggle({
    Name = "Freecam",
    Default = false,
    Callback = function(v)
        if freecamActive ~= v then ToggleFreecam(v) end
    end,
})
camFolder:AddKeybind({
    Name = "Freecam Keybind",
    Default = Enum.KeyCode.P,
    OnPress = function()
        local nv = not freecamActive
        ToggleFreecam(nv)
        if freecamToggle then freecamToggle:Set(nv, true) end
    end,
})
camFolder:AddSlider({
    Name = "Freecam Speed",
    Description = "Movement speed in freecam mode",
    Min = 10, Max = 500, Default = 50, Increment = 5,
    Callback = function(v)
        freecamSpeed = v
    end,
})
camFolder:AddSlider({
    Name = "Camera FOV",
    Min = 30, Max = 120, Default = 70, Increment = 1,
    Callback = function(v)
        Config.Camera_FOV = v
        if freecamActive then
            freecamFOV = v
            Camera.FieldOfView = v
        end
    end,
})
camFolder:AddToggle({
    Name = "Infinite Zoom",
    Default = false,
    Callback = function(v)
        infZoomEnabled = v
        if v then
            currentMaxZoom = LocalPlayer.CameraMaxZoomDistance
        else
            LocalPlayer.CameraMaxZoomDistance = originalMaxZoom
            currentMaxZoom = originalMaxZoom
        end
    end,
})

local ovFolder = camSection:AddFolder({ Name = "Overlay", Description = "Gamma & shadows" })
ovFolder:AddSlider({
    Name = "Gamma",
    Min = -1, Max = 1, Default = 0, Increment = 0.1,
    Callback = function(v) setGamma(v) end,
})
ovFolder:AddToggle({
    Name = "Disable World Shadows",
    Default = false,
    Callback = function(v) setShadowsDisabled(v) end,
})

--=====================================================================
--  TAB: COMBAT
--=====================================================================
local CombatTab = Window:AddTab({ Name = "Combat", Shape = "Burst" })

local aimSection = CombatTab:AddSection("Aim Bot")
local aimFolder = aimSection:AddFolder({ Name = "Aim Bot Settings", Description = "Configure aimbot" })
aimFolder:AddToggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(v) Config.Aimbot_Enabled = v end,
})
aimFolder:AddDropdown({
    Name = "Activation Key",
    Options = { "RightClick", "LeftClick", "E", "Q", "C", "F", "LeftShift", "LeftAlt" },
    Default = "RightClick",
    Callback = function(v) Config.AimKey = v end,
})
aimFolder:AddDropdown({
    Name = "Aimbot Method",
    Options = { "Camera", "Mouse" },
    Default = "Mouse",
    Callback = function(v) Config.AimMethod = v end,
})
aimFolder:AddDropdown({
    Name = "Target Part",
    Options = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head",
    Callback = function(v) Config.TargetPart = v end,
})
aimFolder:AddToggle({
    Name = "Show FOV Circle",
    Default = true,
    Callback = function(v) Config.FOV_Visible = v end,
})
aimFolder:AddSlider({
    Name = "FOV Size",
    Min = 10, Max = 600, Default = 100, Increment = 1,
    Callback = function(v) Config.FOV_Radius = v end,
})
aimFolder:AddColorpicker({
    Name = "FOV Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) Config.FOV_Color = c end,
})
aimFolder:AddToggle({
    Name = "Rainbow FOV Circle",
    Default = false,
    Callback = function(v) Config.FOV_Rainbow = v end,
})

local tbSection = CombatTab:AddSection("Trigger Bot")

local tbFolder = tbSection:AddFolder({ Name = "Trigger Bot Settings", Description = "Configure Trigger Bot" })

local tbToggle
tbToggle = tbFolder:AddToggle({
    Name = "Enable Trigger Bot",
    Description = "Auto-fire when crosshair is on an enemy",
    Default = false,
    Callback = function(v)
        triggerbotEnabled = v
    end,
})

tbFolder:AddKeybind({
    Name = "Toggle Keybind",
    Description = "Hotkey to enable/disable",
    Default = Enum.KeyCode.G,
    Callback = function(k)
        -- вызывается ТОЛЬКО когда пользователь переназначил клавишу
        if k then
            triggerbotKey = k
        end
    end,
    OnPress = function()
        -- вызывается КАЖДЫЙ раз при нажатии клавиши
        triggerbotEnabled = not triggerbotEnabled
        -- синхронизируем UI-тумблер (silent = true, чтобы не было рекурсии)
        if tbToggle then
            pcall(function() tbToggle:Set(triggerbotEnabled, true) end)
        end
        -- уведомление (опционально)
        Window:Notify({
            Title = "Trigger Bot",
            Text = triggerbotEnabled and "Enabled" or "Disabled",
            Duration = 1.5,
        })
    end,
})

tbFolder:AddSlider({
    Name = "Delay",
    Description = "Seconds between shots (0 = fastest)",
    Min = 0, Max = 1, Default = 0, Increment = 0.01,
    Callback = function(v)
        triggerbotDelay = v
    end,
})

local flingSection = CombatTab:AddSection("Fling")
local TargetPlayer = nil

local function findTarget(str)
    if not str or str == "" then return nil end
    str = string.lower(str)

    local exact, prefix, partial
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local n  = string.lower(plr.Name)
            local dn = string.lower(plr.DisplayName)

            if n == str or dn == str then
                return plr                                  -- точное совпадение — сразу
            elseif not prefix and (n:sub(1, #str) == str or dn:sub(1, #str) == str) then
                prefix = plr                                -- начинается с —
            elseif not partial and (n:find(str, 1, true) or dn:find(str, 1, true)) then
                partial = plr                               -- содержится внутри
            end
        end
    end

    return exact or prefix or partial
end

local flingTargetFolder = flingSection:AddFolder({ Name = "Target Player", Description = "Choose target" })

-- Live-поиск: ищет уже при 1 символе
flingTargetFolder:AddInput({
    Name = "Player Name",
    Placeholder = "Type to search...",
    Live = true,
    Callback = function(t)
        if not t or t == "" then
            TargetPlayer = nil
            return
        end
        local found = findTarget(t)
        if found then
            TargetPlayer = found
        end
        -- если не нашёл — оставляем прошлую цель (чтобы не мигало при наборе)
    end,
})

-- Статус текущей цели
local targetStatusLabel = flingTargetFolder:AddLabel("Target: none")

-- Fling target (toggle) — циклично флингает выбранного игрока
local flingTargetActive = false

local function flingTargetLoop()
    while flingTargetActive and not isUnloaded do
        if TargetPlayer and TargetPlayer.Parent and TargetPlayer.Character then
            local ok = pcall(function()
                -- одноразовый SkidFling с флагом, что мы активны
                flingAllActive = true
                local done = false
                task.spawn(function()
                    SkidFling(TargetPlayer)
                    done = true
                end)
                local t0 = tick()
                while not done and tick() - t0 < 3 and flingTargetActive do
                    task.wait(0.1)
                end
                flingAllActive = false
            end)
        end
        task.wait(0.35)
    end
end

local flingTargetToggle
flingTargetToggle = flingTargetFolder:AddToggle({
    Name = "Fling Target",
    Description = "Continuously fling the selected player",
    Default = false,
    Callback = function(v)
        flingTargetActive = v
        if v then
            if not TargetPlayer then
                Window:Notify({ Title = "Error", Text = "Pick a target first" })
                task.defer(function()
                    if flingTargetToggle then
                        pcall(function() flingTargetToggle:Set(false, true) end)
                    end
                end)
                flingTargetActive = false
                return
            end
            task.spawn(flingTargetLoop)
        end
    end,
})

-- Авто-обновление статуса цели + авто-отключение если цель пропала
task.spawn(function()
    while not isUnloaded do
        task.wait(0.5)
        if targetStatusLabel and targetStatusLabel.SetText then
            local txt
            if TargetPlayer and TargetPlayer.Parent then
                txt = "Target: @" .. TargetPlayer.Name
            else
                txt = "Target: none"
            end
            pcall(function() targetStatusLabel:SetText(txt) end)
        end
        if flingTargetActive and (not TargetPlayer or not TargetPlayer.Parent) then
            flingTargetActive = false
            if flingTargetToggle then
                pcall(function() flingTargetToggle:Set(false, true) end)
            end
        end
    end
end)

local flingActionsFolder = flingSection:AddFolder({ Name = "Fling Actions", Description = "Mass fling & protection" })
flingActionsFolder:AddToggle({
    Name = "Touch Fling",
    Default = false,
    Callback = function(v)
        flingActive = v
        if v then task.spawn(flingLoop) end
    end,
})
flingActionsFolder:AddToggle({
    Name = "Fling All",
    Default = false,
    Callback = function(v)
        flingAllActive = v
        if v then task.spawn(flingAllLoop) end
    end,
})
flingActionsFolder:AddToggle({
    Name = "Anti-Fling",
    Default = false,
    Callback = function(v) toggleAntiFling(v) end,
})

local hbSection = CombatTab:AddSection("Hitbox")
hbSection:AddToggle({
    Name = "Enable Hitboxes",
    Default = false,
    Callback = function(v)
        HitboxConfig.Enabled = v
        if not v then ResetHitboxes() end
    end,
})
local hbFolder = hbSection:AddFolder({ Name = "Hitbox Settings", Description = "Size & appearance" })
hbFolder:AddSlider({
    Name = "Hitbox Size",
    Min = 2, Max = 100, Default = 15, Increment = 1,
    Callback = function(v) HitboxConfig.Size = v end,
})
hbFolder:AddSlider({
    Name = "Transparency",
    Min = 0, Max = 1, Default = 0.7, Increment = 0.1,
    Callback = function(v) HitboxConfig.Transparency = v end,
})
hbFolder:AddColorpicker({
    Name = "Hitbox Color",
    Default = Color3.fromRGB(150, 150, 150),
    Callback = function(c) HitboxConfig.Color = c end,
})

--=====================================================================
--  TAB: SETTINGS
--=====================================================================
local SettingsTab = Window:AddTab({ Name = "Settings", Shape = "Flower" })

local ifc = SettingsTab:AddSection("Settings")

local function getThemeSeed()
    if Window.ThemeName == "Custom" and Window.CustomThemeColor then
        return Window.CustomThemeColor
    end
    local preset = UI.Themes[Window.ThemeName]
    if preset and preset.seed then
        return preset.seed
    end
    return Window.Colors.primary
end

local themePicker = ifc:AddColorpicker({
    Name = "Custom Theme Color",
    Description = "Pick any color — dark/light auto-detects by brightness",
    Default = getThemeSeed(),   -- стартуем с цвета текущей темы
    Callback = function(c)
        Window:SetThemeFromColor(c)
    end,
})

-- Обновляем swatch при каждой смене темы
local function syncPickerSwatch()
    if themePicker and themePicker.Set then
        pcall(function()
            themePicker:Set(getThemeSeed(), true)  -- silent: не вызываем Callback
        end)
    end
end

Window:OnTheme(syncPickerSwatch)
-- применяем сразу после создания (на случай если тема уже сменилась)
task.defer(syncPickerSwatch)

ifc:AddKeybind({
    Name = "Toggle UI Keybind",
    Description = "Show/Hide interface",
    Default = Enum.KeyCode.CapsLock,
    Callback = function(k)
        if k then Window:SetToggleKey(k) end
    end,
})
ifc:AddButton({
    Name = "Unload Script",
    Description = "Completely disable script",
    ButtonText = "Unload",
    Callback = function() Window:Close() end,
})

task.delay(4, function()
    Window:Notify({ Title = "System42", Text = "Thank you for using ZIbvabva" })
end)
