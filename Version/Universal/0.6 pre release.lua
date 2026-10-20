local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local syn = syn or {}

--=====================================================================
-- GLOBAL INSTANCE GUARD
--=====================================================================
if _G.__ZibvabvaHub_Unload then
    pcall(_G.__ZibvabvaHub_Unload)
end

local __TrackedConnections = {}
local function trackConn(conn)
    table.insert(__TrackedConnections, conn)
    return conn
end

local function disconnectTracked()
    for i = #__TrackedConnections, 1, -1 do
        pcall(function() __TrackedConnections[i]:Disconnect() end)
        __TrackedConnections[i] = nil
    end
    __TrackedConnections = {}
end

--=====================================================================
-- CONFIG
--=====================================================================
local Config = {
    Camera_FOV = 70,

    ESP_Enabled = false,
    Boxes_Enabled = true,
    Tracers_Enabled = false,
    HealthBar_Enabled = true,
    HeadDot_Enabled = true,
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
}

local freecamActive = false
local isFlying = false
local flySpeed = 60
local connection = nil

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 999999
bodyVelocity.Velocity = Vector3.new(0, 0, 0)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 999999
bodyGyro.P = 15000
bodyGyro.D = 100

local GetTarget

local infZoomEnabled = false
local originalMaxZoom = player.CameraMaxZoomDistance or 4000
local currentMaxZoom = originalMaxZoom

local IsInvisible = false
local invisibleDistance = 200000
local invisibleConnection = nil
local invisibleParts = {}
local InvisibleToggleRef = nil

local function SetupInvisibleCharacter()
    local char = LocalPlayer.Character
    if not char then return end
    invisibleParts = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA('BasePart') and part.Transparency == 0 then
            table.insert(invisibleParts, part)
        end
    end
end

local function ToggleInvisible(state)
    if IsInvisible == state and invisibleConnection ~= nil then
        return
    end

    IsInvisible = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local rp = char and char:FindFirstChild("HumanoidRootPart")

    if IsInvisible then
        SetupInvisibleCharacter()
        for _, part in pairs(invisibleParts) do
            if part then part.Transparency = 0.5 end
        end
        if not invisibleConnection then
            invisibleConnection = RunService.Heartbeat:Connect(function()
                if IsInvisible and rp and hum then
                    local currentCFrame = rp.CFrame
                    local originalCamOffset = hum.CameraOffset
                    local newCFrame = currentCFrame * CFrame.new(0, -invisibleDistance, 0)
                    local offsetPosition = newCFrame:ToObjectSpace(CFrame.new(currentCFrame.Position)).Position

                    rp.CFrame = newCFrame
                    hum.CameraOffset = offsetPosition

                    RunService.RenderStepped:Wait()

                    rp.CFrame = currentCFrame
                    hum.CameraOffset = originalCamOffset
                end
            end)
        end
    else
        if invisibleConnection then
            invisibleConnection:Disconnect()
            invisibleConnection = nil
        end
        for _, part in pairs(invisibleParts) do
            if part and part.Parent then part.Transparency = 0 end
        end
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end

    if InvisibleToggleRef then
        InvisibleToggleRef:Set(IsInvisible)
    end
end

trackConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
    if IsInvisible then ToggleInvisible(false) end
end))

local function onRenderStep()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not rootPart or not humanoid or not isFlying then return end

    bodyGyro.CFrame = camera.CFrame

    local moveDirection = Vector3.new(
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 0.6 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 0.6 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
    )

    if moveDirection.Magnitude > 0 then
        bodyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(moveDirection.Unit * flySpeed)
    else
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end

local function setFlightState(state)
    isFlying = state
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if isFlying then
        if rootPart and humanoid then
            bodyVelocity.Parent = rootPart
            bodyGyro.Parent = rootPart
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        if not connection then
            connection = RunService.RenderStepped:Connect(onRenderStep)
        end
    else
        bodyVelocity.Parent = nil
        bodyGyro.Parent = nil
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
end

local isNoclip = false
local noclipConnection = nil

local function setNoclipState(state)
    isNoclip = state
    if isNoclip then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = player.Character
                if not char then return end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

local currentFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70

trackConn(RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if cam and not freecamActive then
        if math.abs(cam.FieldOfView - Config.Camera_FOV) > 0.01 then
            cam.FieldOfView = Config.Camera_FOV
        end
    end
end))

trackConn(player.CharacterAdded:Connect(function(newCharacter)
    if isFlying then setFlightState(false) end
    if isNoclip then setNoclipState(false) end
    task.wait(0.5)
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = currentFOV
    end
end))

--=====================================================================
-- PARENT / UI HELPERS
--=====================================================================
local function getParent()
    if gethui then return gethui() end
    local ok, res = pcall(function() return CoreGui:GetChildren() end)
    if ok then return CoreGui end
    return player:WaitForChild("PlayerGui")
end

local parentGui = getParent()
pcall(function()
    local old = parentGui:FindFirstChild("PerfOverlay")
    if old then old:Destroy() end
end)

local function getScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local minSide = math.min(viewport.X, viewport.Y)
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return math.clamp(minSide / 900, 0.85, 1.2)
    else
        return math.clamp(minSide / 1080, 0.95, 1.3)
    end
end

local perfGui = Instance.new("ScreenGui")
perfGui.Name = "PerfOverlay"
perfGui.ResetOnSpawn = false
perfGui.IgnoreGuiInset = true
perfGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
perfGui.DisplayOrder = 999999
perfGui.Enabled = false

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(perfGui) end
end)
perfGui.Parent = parentGui

local perfFrame = Instance.new("Frame")
perfFrame.Name = "Container"
perfFrame.AnchorPoint = Vector2.new(1, 0)
perfFrame.Position = UDim2.new(1, -22, 0, 30)
perfFrame.Size = UDim2.fromOffset(160, 100)
perfFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
perfFrame.BackgroundTransparency = 0.3
perfFrame.BorderSizePixel = 0
perfFrame.Active = true
perfFrame.Parent = perfGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = perfFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
stroke.Thickness = 1
stroke.Parent = perfFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = perfFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 3)
layout.Parent = perfFrame

local function makeRow(name, color, order)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Text = name .. ": --"
    lbl.LayoutOrder = order
    lbl.Parent = perfFrame
    return lbl
end

local pingLbl = makeRow("PING", Color3.fromRGB(120, 220, 140), 1)
local msLbl   = makeRow("MS",   Color3.fromRGB(120, 200, 255), 2)
local fpsLbl  = makeRow("FPS",  Color3.fromRGB(255, 200, 100), 3)
local timeLbl = makeRow("TIME", Color3.fromRGB(220, 220, 220), 4)

local uiScale = Instance.new("UIScale")
uiScale.Parent = perfFrame

local function applyScale() uiScale.Scale = getScale() end
applyScale()
trackConn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))

local dragging, dragInput, dragStart, startPos
perfFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = perfFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
perfFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
trackConn(UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        perfFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

local startTime = tick()
local frameCount = 0
local fps = 0
local lastUpdate = tick()

local function formatTime(sec)
    sec = math.floor(sec)
    local h, m, s = math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) else return string.format("%02d:%02d", m, s) end
end

local function getPing()
    local ok, val = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and val then return math.floor(val) end
    return 0
end

local function colorByPing(p)
    if p < 80 then return Color3.fromRGB(120, 220, 140)
    elseif p < 180 then return Color3.fromRGB(255, 220, 120)
    else return Color3.fromRGB(255, 110, 110) end
end

local function colorByFPS(f)
    if f >= 50 then return Color3.fromRGB(120, 220, 140)
    elseif f >= 30 then return Color3.fromRGB(255, 220, 120)
    else return Color3.fromRGB(255, 110, 110) end
end

trackConn(RunService.RenderStepped:Connect(function()
    if not perfGui or not perfGui.Enabled then return end
    frameCount += 1
    local now = tick()
    if now - lastUpdate >= 0.5 then
        fps = math.floor(frameCount / (now - lastUpdate) + 0.5)
        frameCount = 0
        lastUpdate = now

        local ping = getPing()
        pingLbl.Text = "PING: " .. ping .. " ms"
        pingLbl.TextColor3 = colorByPing(ping)
        msLbl.Text = "MS:   " .. string.format("%.1f", 1000 / math.max(fps, 1))
        msLbl.TextColor3 = colorByPing(ping)
        fpsLbl.Text = "FPS:  " .. fps
        fpsLbl.TextColor3 = colorByFPS(fps)
        timeLbl.Text = "TIME: " .. formatTime(now - startTime)
    end
end))

--=====================================================================
-- ESP & FOV SYSTEM
--=====================================================================
local ESPContainer = Instance.new("ScreenGui")
ESPContainer.Name = "ZibvabvaESP"
ESPContainer.ResetOnSpawn = false
ESPContainer.IgnoreGuiInset = true
ESPContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ESPContainer.Parent = parentGui end)

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "ZibvabvaFOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
pcall(function() FOVGui.Parent = parentGui end)

local FOFCircleFrame = Instance.new("Frame")
FOFCircleFrame.BackgroundTransparency = 1
FOFCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOFCircleFrame.Visible = false
FOFCircleFrame.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Config.FOV_Color
FOVStroke.Parent = FOFCircleFrame

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOFCircleFrame

local ESPCache = {}

local function createESP(player)
    if ESPCache[player] then return end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.Visible = false
    box.Parent = ESPContainer

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Color = Config.BoxColor
    boxStroke.Parent = box

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.Parent = ESPContainer

    local nameTag = Instance.new("TextLabel")
    nameTag.BackgroundTransparency = 1
    nameTag.Size = UDim2.new(0, 200, 0, 20)
    nameTag.AnchorPoint = Vector2.new(0.5, 1)
    nameTag.TextSize = 14
    nameTag.Font = Enum.Font.SourceSansBold
    nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameTag.TextStrokeTransparency = 0
    nameTag.Visible = false
    nameTag.Parent = ESPContainer

    local healthBarOutline = Instance.new("Frame")
    healthBarOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBarOutline.BackgroundTransparency = 0.3
    healthBarOutline.BorderSizePixel = 0
    healthBarOutline.Visible = false
    healthBarOutline.Parent = box

    local healthBarOutlineCorner = Instance.new("UICorner")
    healthBarOutlineCorner.CornerRadius = UDim.new(0, 2)
    healthBarOutlineCorner.Parent = healthBarOutline

    local healthBar = Instance.new("Frame")
    healthBar.BorderSizePixel = 0
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.Parent = healthBarOutline

    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 2)
    healthBarCorner.Parent = healthBar

    local headDot = Instance.new("Frame")
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Visible = false
    headDot.Parent = ESPContainer
    local headCorner = Instance.new("UICorner")
    headCorner.CornerRadius = UDim.new(1, 0)
    headCorner.Parent = headDot

    ESPCache[player] = {
        Box = box, BoxStroke = boxStroke, Tracer = tracer, NameTag = nameTag,
        HealthBarOutline = healthBarOutline, HealthBar = healthBar,
        HeadDot = headDot
    }
end

local function removeESP(player)
    if ESPCache[player] then
        for _, object in pairs(ESPCache[player]) do
            pcall(function() object:Destroy() end)
        end
        ESPCache[player] = nil
    end
end

local function hideAllESP()
    for _, visuals in pairs(ESPCache) do
        if visuals then
            visuals.Box.Visible = false
            visuals.Tracer.Visible = false
            visuals.NameTag.Visible = false
            visuals.HeadDot.Visible = false
            visuals.HealthBarOutline.Visible = false
        end
    end
end

local function getInvertedColor(color)
    return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
end

local IsLocking = false

GetTarget = function()
    local Camera = workspace.CurrentCamera
    local CurrentTarget = nil
    local MaxDist = Config.FOV_Radius
    local MousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Config.TargetPart) then
            if Config.TeamCheck and p.Team == LocalPlayer.Team then continue end

            local Part = p.Character[Config.TargetPart]
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)

            if OnScreen then
                local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                if Dist < MaxDist then
                    CurrentTarget = Part
                    MaxDist = Dist
                end
            end
        end
    end
    return CurrentTarget
end

local function getBoundingBox2D(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return false, 0, 0, 0, 0
    end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOnScreen = false

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local isAccessory = part:FindFirstAncestorOfClass("Accessory") ~= nil
            local isTool = part:FindFirstAncestorOfClass("Tool") ~= nil

            local tooFar = false
            if rootPart and (part.Position - rootPart.Position).Magnitude > 4.5 then
                tooFar = true
            end

            if not isAccessory and not isTool and not tooFar then
                local cf = part.CFrame
                local size = part.Size
                local corners = {
                    cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                }

                for _, cornerCf in ipairs(corners) do
                    local screenPos, onScreen = camera:WorldToViewportPoint(cornerCf.Position)
                    if screenPos.Z > 0 then
                        anyOnScreen = true
                        minX = math.min(minX, screenPos.X)
                        minY = math.min(minY, screenPos.Y)
                        maxX = math.max(maxX, screenPos.X)
                        maxY = math.max(maxY, screenPos.Y)
                    end
                end
            end
        end
    end

    if not anyOnScreen or minX == math.huge then
        return false, 0, 0, 0, 0
    end

    local width = maxX - minX
    local height = maxY - minY
    if width > height * 2 or height > 800 or width > 800 then
        return false, 0, 0, 0, 0
    end

    return true, minX, minY, width, height
end

trackConn(RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    local myCharacter = LocalPlayer.Character
    local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)

    if not Config.ESP_Enabled then
        hideAllESP()
    end

    local activeTargetPart = (Config.Aimbot_Enabled and IsLocking) and GetTarget() or nil
    local activeTargetPlayer = activeTargetPart and Players:GetPlayerFromCharacter(activeTargetPart.Parent) or nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPCache[player] then createESP(player) end

            local visuals = ESPCache[player]
            local targetCharacter = player.Character
            local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
            local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")

            if Config.ESP_Enabled and myRootPart and targetRootPart and targetHumanoid and targetHead then
                local onScreen, boxX, boxY, sizeX, sizeY = getBoundingBox2D(targetCharacter)
                local headScreenPos, headOnScreen = camera:WorldToViewportPoint(targetHead.Position)
                local myScreenPos = camera:WorldToViewportPoint(myRootPart.Position)

                if onScreen and sizeX > 0 and sizeY > 0 and headScreenPos.Z > 0 then
                    local distance = (camera.CFrame.Position - targetRootPart.Position).Magnitude
                    local isTargeted = (player == activeTargetPlayer)

                    local baseBoxColor = Config.RainbowBoxes and rainbowColor or Config.BoxColor
                    local activeBoxColor = baseBoxColor
                    if isTargeted then
                        activeBoxColor = Config.UseTargetInvert and getInvertedColor(baseBoxColor) or Config.TargetColor
                    end

                    local baseNameColor = Config.RainbowNames and rainbowColor or Config.NameColor
                    local activeNameColor = baseNameColor
                    if isTargeted then
                        activeNameColor = Config.UseTargetInvert and getInvertedColor(baseNameColor) or Config.TargetColor
                    end

                    if Config.Boxes_Enabled then
                        visuals.Box.Size = UDim2.fromOffset(sizeX, sizeY)
                        visuals.Box.Position = UDim2.fromOffset(boxX, boxY)
                        visuals.BoxStroke.Color = activeBoxColor
                        visuals.Box.Visible = true
                    else
                        visuals.Box.Visible = false
                    end

                    if Config.Tracers_Enabled then
                        local trFrom = Vector2.new(myScreenPos.X, myScreenPos.Y)
                        local trTo = Vector2.new(boxX + sizeX/2, boxY + sizeY)
                        local trDist = (trTo - trFrom).Magnitude
                        visuals.Tracer.Size = UDim2.fromOffset(trDist, 1.5)
                        visuals.Tracer.Position = UDim2.fromOffset(trFrom.X, trFrom.Y)
                        visuals.Tracer.Rotation = math.deg(math.atan2(trTo.Y - trFrom.Y, trTo.X - trFrom.X))
                        visuals.Tracer.BackgroundColor3 = Config.RainbowTracers and rainbowColor or Config.TracerColor
                        visuals.Tracer.Visible = true
                    else
                        visuals.Tracer.Visible = false
                    end

                    visuals.NameTag.Text = Config.UseDisplayName and player.DisplayName or player.Name
                    visuals.NameTag.Position = UDim2.fromOffset(boxX + (sizeX / 2), boxY - 6)
                    visuals.NameTag.TextColor3 = activeNameColor
                    visuals.NameTag.Visible = true

                    if Config.HeadDot_Enabled and headOnScreen and headScreenPos.Z > 0 then
                        local dotSize = math.clamp(1000 / distance, 4, 12)
                        visuals.HeadDot.Position = UDim2.fromOffset(headScreenPos.X, headScreenPos.Y)
                        visuals.HeadDot.Size = UDim2.fromOffset(dotSize, dotSize)
                        visuals.HeadDot.BackgroundColor3 = activeBoxColor
                        visuals.HeadDot.Visible = true
                    else
                        visuals.HeadDot.Visible = false
                    end

                    if Config.HealthBar_Enabled then
                        local currentHealth = targetHumanoid.Health
                        local maxHealth = targetHumanoid.MaxHealth
                        local hpPercent = math.clamp(currentHealth / maxHealth, 0, 1)
                        local hpColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hpPercent)

                        if Config.HealthBarPosition == "Right" then
                            visuals.HealthBarOutline.Size = UDim2.new(0, 4, 1, 0)
                            visuals.HealthBarOutline.Position = UDim2.new(1, 3, 0, 0)
                            visuals.HealthBar.Size = UDim2.new(1, 0, hpPercent, 0)
                            visuals.HealthBar.Position = UDim2.new(0, 0, 1, 0)
                            visuals.HealthBar.AnchorPoint = Vector2.new(0, 1)
                        elseif Config.HealthBarPosition == "Left" then
                            visuals.HealthBarOutline.Size = UDim2.new(0, 4, 1, 0)
                            visuals.HealthBarOutline.Position = UDim2.new(0, -7, 0, 0)
                            visuals.HealthBar.Size = UDim2.new(1, 0, hpPercent, 0)
                            visuals.HealthBar.Position = UDim2.new(0, 0, 1, 0)
                            visuals.HealthBar.AnchorPoint = Vector2.new(0, 1)
                        elseif Config.HealthBarPosition == "Top" then
                            visuals.HealthBarOutline.Size = UDim2.new(1, 0, 0, 4)
                            visuals.HealthBarOutline.Position = UDim2.new(0, 0, 0, -7)
                            visuals.HealthBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                            visuals.HealthBar.Position = UDim2.new(0, 0, 0, 0)
                            visuals.HealthBar.AnchorPoint = Vector2.new(0, 0)
                        end

                        visuals.HealthBar.BackgroundColor3 = hpColor
                        visuals.HealthBarOutline.Visible = true
                    else
                        visuals.HealthBarOutline.Visible = false
                    end
                else
                    visuals.Box.Visible = false
                    visuals.Tracer.Visible = false
                    visuals.NameTag.Visible = false
                    visuals.HeadDot.Visible = false
                    visuals.HealthBarOutline.Visible = false
                end
            else
                if visuals then
                    visuals.Box.Visible = false
                    visuals.Tracer.Visible = false
                    visuals.NameTag.Visible = false
                    visuals.HeadDot.Visible = false
                    visuals.HealthBarOutline.Visible = false
                end
            end
        end
    end
end))

trackConn(Players.PlayerRemoving:Connect(removeESP))

--=====================================================================
-- FLING
--=====================================================================
local flingActive = false
local flingThread = nil

local function flingLoop()
    local lp = game.Players.LocalPlayer
    local movel = 0.1
    while flingActive do
        game:GetService("RunService").Heartbeat:Wait()
        local c = lp.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            game:GetService("RunService").RenderStepped:Wait()
            hrp.Velocity = vel
            game:GetService("RunService").Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local flingAllActive = false
local flingAllThread = nil

local function SkidFling(TargetPlayer)
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not Character or not Humanoid or not RootPart then return end

    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not THumanoid or not TRootPart then return end

    local originalFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local function FPos(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local BasePartToUse = TRootPart
    if THead and (TRootPart.Position - THead.Position).Magnitude > 5 then
        BasePartToUse = THead
    elseif not TRootPart and THead then
        BasePartToUse = THead
    elseif not TRootPart and not THead and Handle then
        BasePartToUse = Handle
    end

    if not BasePartToUse then
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.FallenPartsDestroyHeight = originalFPDH
        return
    end

    local TimeToWait = 2
    local Time = tick()
    local Angle = 0

    repeat
        if not flingAllActive or not TargetPlayer.Parent or not TCharacter.Parent then break end
        if not RootPart or not THumanoid then break end
        if THumanoid.Sit or Humanoid.Health <= 0 then break end

        if BasePartToUse.Velocity.Magnitude < 50 then
            Angle = Angle + 100
            FPos(BasePartToUse, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePartToUse.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePartToUse.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePartToUse.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePartToUse.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
            task.wait()
        else
            FPos(BasePartToUse, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
            task.wait()
            FPos(BasePartToUse, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
            task.wait()
        end
    until BasePartToUse.Velocity.Magnitude > 500 or BasePartToUse.Parent ~= TCharacter or TargetPlayer.Parent ~= Players or not TCharacter.Parent or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.FallenPartsDestroyHeight = originalFPDH
end

local function flingAllLoop()
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    while flingAllActive do
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= Player then
                coroutine.wrap(function() pcall(function() SkidFling(target) end) end)()
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
end

local antiFlingEnabled = false
local antiFlingConnection = nil
local playerPartsCache = {}

task.spawn(function()
    while task.wait(1) do
        if antiFlingEnabled then
            local newCache = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            table.insert(newCache, part)
                        end
                    end
                end
            end
            playerPartsCache = newCache
        end
    end
end)

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

--=====================================================================
-- NAMETAG
--=====================================================================
local nameTagText = "[GOD]"
local nameTagColor = Color3.fromRGB(255, 215, 0)
local nameTagApplied = false

local function applyNameTag()
    nameTagApplied = true
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.DisplayName = nameTagText .. " " .. player.Name
        end
    end
end

trackConn(player.CharacterAdded:Connect(function(char)
    if not nameTagApplied then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.DisplayName = nameTagText .. " " .. player.Name
    end
end))

local function patchPlayerList()
    if not nameTagApplied then return end
    local list = CoreGui:FindFirstChild("PlayerList")
    if not list then return end
    for _, obj in ipairs(list:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = obj.Text
            if txt == player.Name or txt == player.DisplayName then
                if not txt:find(nameTagText, 1, true) then
                    obj.Text = nameTagText .. " " .. txt
                    obj.TextColor3 = nameTagColor
                end
             end
        end
    end
end

local function patchScoreboard()
    if not nameTagApplied then return end
    local pg = player:FindFirstChild("PlayerGui")
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
            if nl and nl:IsA("TextLabel") and nl.Text:find(player.Name, 1, true) then
                if not nl.Text:find(nameTagText, 1, true) then
                     nl.Text = nameTagText .. " " .. nl.Text
                    nl.TextColor3 = nameTagColor
                end
            end
        end
    end
end

trackConn(RunService.RenderStepped:Connect(function()
    if nameTagApplied then
        patchPlayerList()
        patchScoreboard()
    end
end))

--=====================================================================
-- AIMBOT
--=====================================================================
local clickTpEnabled = false

trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = true
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsLocking = true
    elseif input.KeyCode.Name == Config.AimKey then
        IsLocking = true
    end
end))

trackConn(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = false
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
         IsLocking = false
    elseif input.KeyCode.Name == Config.AimKey then
        IsLocking = false
    end
end))

trackConn(RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    if Config.Aimbot_Enabled and Config.FOV_Visible then
        FOFCircleFrame.Visible = true
        local mousePos = UserInputService:GetMouseLocation()
        FOFCircleFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        FOFCircleFrame.Size = UDim2.fromOffset(Config.FOV_Radius * 2, Config.FOV_Radius * 2)

        if Config.FOV_Rainbow then
            FOVStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else
            FOVStroke.Color = Config.FOV_Color
        end
    else
        FOFCircleFrame.Visible = false
    end

    if Config.Aimbot_Enabled and IsLocking then
        local target = GetTarget()
        if target then
            if Config.AimMethod == "Camera" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            elseif Config.AimMethod == "Mouse" then
                local targetScreenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    if mousemoverel then
                        local deltaX = (targetScreenPos.X - mousePos.X) / 2
                        local deltaY = (targetScreenPos.Y - mousePos.Y) / 2
                        mousemoverel(deltaX, deltaY)
                    else
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                    end
                end
            end
        end
    end
end))

--=====================================================================
-- FREECAM
--=====================================================================
local freecamCamPos = Vector3.new()
local freecamRotX, freecamRotY = 0, 0
local freecamSpeed = 50
local freecamFOV = Config.Camera_FOV

local function ToggleFreecam(state)
    freecamActive = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if freecamActive then
        if hrp then hrp.Anchored = true end
        freecamCamPos = camera.CFrame.Position
        local x, y = camera.CFrame:ToEulerAnglesYXZ()
        freecamRotX, freecamRotY = x, y
        camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        freecamFOV = Config.Camera_FOV
        camera.FieldOfView = freecamFOV
    else
        if hrp then hrp.Anchored = false end
        camera.CameraType = Enum.CameraType.Custom
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default

        camera.FieldOfView = Config.Camera_FOV
    end
end

trackConn(RunService.RenderStepped:Connect(function(dt)
    if freecamActive then
        local mouseDelta = UserInputService:GetMouseDelta()
        freecamRotY = freecamRotY - mouseDelta.X * 0.003
        freecamRotX = math.clamp(freecamRotX - mouseDelta.Y * 0.003, -1.57, 1.57)

        local moveDir = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - ((UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )

        local camCFrame = CFrame.new(freecamCamPos) * CFrame.fromOrientation(freecamRotX, freecamRotY, 0)
        freecamCamPos = freecamCamPos + (camCFrame:VectorToWorldSpace(moveDir) * freecamSpeed * dt)

        camera.CFrame = CFrame.new(freecamCamPos) * CFrame.fromOrientation(freecamRotX, freecamRotY, 0)
        camera.FieldOfView = freecamFOV
    end
end))

--=====================================================================
-- UNIFIED MOUSE WHEEL HANDLER
--=====================================================================
local WHEEL_STEP = 15

trackConn(UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

    local scroll = input.Position.Z

    if freecamActive then
        freecamFOV = math.clamp(freecamFOV - scroll * 4, 15, 120)
        camera.FieldOfView = freecamFOV
        return
    end

    local currentZoom = player.CameraMaxZoomDistance or 4000

    if scroll > 0 then
        player.CameraMaxZoomDistance = math.max(currentZoom - WHEEL_STEP, 10)
    else
        local newZoom = currentZoom + WHEEL_STEP

        if not infZoomEnabled then
            newZoom = math.min(newZoom, 1000)
        else
            if newZoom > 1000 and currentMaxZoom < 1000 then
                currentMaxZoom = 1000
            end
            if newZoom > currentMaxZoom then
                currentMaxZoom = newZoom
            end
            local zoomDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
            if zoomDist >= player.CameraMaxZoomDistance - 5 then
                currentMaxZoom = math.max(currentMaxZoom * 1.5, newZoom)
            end
        end

        player.CameraMaxZoomDistance = newZoom
    end

    if infZoomEnabled and currentMaxZoom > player.CameraMaxZoomDistance then
        player.CameraMaxZoomDistance = currentMaxZoom
    end
end))

--=====================================================================
-- LIGHTING / GAMMA / SHADOWS
--=====================================================================
local Lighting = game:GetService("Lighting")
local originalGlobalShadows = Lighting.GlobalShadows

local gammaEffect = Lighting:FindFirstChild("GammaCorrection") or Instance.new("ColorCorrectionEffect")
gammaEffect.Name = "GammaCorrection"
gammaEffect.Parent = Lighting

local function setGamma(value)
    gammaEffect.Brightness = math.clamp(value, -1, 1)
end

local function setShadowsDisabled(state)
    Lighting.GlobalShadows = not state
end

--=====================================================================
-- HITBOX
--=====================================================================
local HitboxConfig = {
    Enabled = false,
    Size = 15,
    Color = Color3.fromRGB(150, 150, 150),
    Transparency = 0.7
}

trackConn(RunService.RenderStepped:Connect(function()
    if HitboxConfig.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
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
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = false
            end
        end
    end
end

--=====================================================================
-- INFINITE JUMP / SPINBOT / ANTI-AFK
--=====================================================================
local InfiniteJumpEnabled = false

trackConn(UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local spinbotEnabled = false
local spinbotSpeed = 20

trackConn(RunService.RenderStepped:Connect(function()
    if spinbotEnabled then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
        end
    end
end))

local afkConnection = nil

local function toggleAntiAFK(enable)
    if enable then
        if not afkConnection then
            afkConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end
    else
        if afkConnection then
            afkConnection:Disconnect()
            afkConnection = nil
        end
    end
end

--=====================================================================
-- UNLOAD
--=====================================================================
local isUnloaded = false
local Window = nil

local function unloadScript()
    if isUnloaded then return end
    isUnloaded = true

    Config.ESP_Enabled = false
    Config.Aimbot_Enabled = false
    HitboxConfig.Enabled = false
    ResetHitboxes()

    ToggleInvisible(false)
    infZoomEnabled = false
    pcall(function() player.CameraMaxZoomDistance = originalMaxZoom end)

    setFlightState(false)
    setNoclipState(false)
    spinbotEnabled = false
    InfiniteJumpEnabled = false
    clickTpEnabled = false
    toggleAntiAFK(false)
    toggleAntiFling(false)
    flingActive = false
    flingAllActive = false

    if freecamActive then ToggleFreecam(false) end

    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = 70
    end
    setGamma(0)
    pcall(function() Lighting.GlobalShadows = originalGlobalShadows end)

    for p, _ in pairs(ESPCache) do
        removeESP(p)
    end

    pcall(function() ESPContainer:Destroy() end)
    pcall(function() FOVGui:Destroy() end)

    if perfGui then
        perfGui.Enabled = false
        pcall(function() perfGui:Destroy() end)
    end

    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
    end)

    pcall(function()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end)

    disconnectTracked()

    if _G.__ZibvabvaHub_Unload == unloadScript then
        _G.__ZibvabvaHub_Unload = nil
    end
end

_G.__ZibvabvaHub_Unload = unloadScript

--=====================================================================
-- UI (WindUI)
--=====================================================================
local _version = "1.6.66"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()

--=====================================================================
-- FIX: force-open helper — only used for ESP Settings / ESP Customization
--=====================================================================
local SectionsToOpen = {}

local function registerSectionForOpening(sec)
    table.insert(SectionsToOpen, sec)
    return sec
end

local function forceOpenSection(sec)
    if not sec then return end
    pcall(function()
        if type(sec.SetCollapsed) == "function" then pcall(function() sec:SetCollapsed(false) end) end
        if type(sec.Collapse) == "function" then pcall(function() sec:Collapse(false) end) end
        if type(sec.SetOpen) == "function" then pcall(function() sec:SetOpen(true) end) end
        if type(sec.Open) == "function" then pcall(function() sec:Open() end) end
        if type(sec.Toggle) == "function" and sec.Collapsed == true then
            pcall(function() sec:Toggle() end)
        end
        if sec.Collapsed ~= nil then
            pcall(function() sec.Collapsed = false end)
        end
        if sec.collapsed ~= nil then
            pcall(function() sec.collapsed = false end)
        end
    end)
end

Window = WindUI:CreateWindow({
    Title = "Zibvabva",
    Icon = "sparkles",
    Author = "babyun42",
    Folder = "ZibvabvaConfigs",
    Size = UDim2.fromOffset(980, 560),
    Transparent = true,
    Theme = "Dark",
    KeySystem = false,
    OnClose = function()
    unloadScript()
    end
})

do
	Window:Tag({
		Title = "v0.6",
		Icon = "github",
		Color = Color3.fromHex("#1c1c1c"),
		Border = true,
	})
end

task.spawn(function()
    task.wait(0.5)
    local gui = parentGui:FindFirstChild("WindUI") or CoreGui:FindFirstChild("WindUI")
    if gui then
        gui.Destroying:Connect(unloadScript)
        gui.AncestryChanged:Connect(function(_, parent)
            if not parent then
                unloadScript()
            end
        end)
    end
end)

WindUI:Notify({
    Title = "Welcome",
    Content = "Thank you for using Zibvabva Hub!",
    Icon = "check",
    Duration = 7,
})

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- TAB 1: PLAYER
PlayerTab:Section({ Title = "Main Movement" })

PlayerTab:Slider({
    Title = "WalkSpeed",
    Desc = "Set character walk speed",
	IsTooltip = true,
	IsTextbox = false,
	Width = 200,
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Desc = "Set character jump power",
    IsTooltip = true,
	IsTextbox = false,
	Width = 200,
    Step = 1,
    Value = { Min = 50, Max = 400, Default = 50 },
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

PlayerTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows infinite mid-air jumps",
    Value = false,
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end
})

PlayerTab:Section({ Title = "Flight" })

local FlyToggle = PlayerTab:Toggle({
    Title = "Fly",
    Desc = "Toggle flight mode",
    Value = false,
    Callback = function(Value)
        if isFlying ~= Value then setFlightState(Value) end
    end
})

PlayerTab:Slider({
    Title = "Fly Speed",
    Desc = "Flight movement speed",
    IsTooltip = true,
	IsTextbox = false,
	Width = 200,
    Step = 1,
    Value = { Min = 20, Max = 300, Default = 60 },
    Callback = function(Value)
        flySpeed = Value
    end
})

PlayerTab:Keybind({
    Title = "Fly Keybind",
    Value = "F",
    Callback = function()
        isFlying = not isFlying
        FlyToggle:Set(isFlying)
        setFlightState(isFlying)
    end
})

PlayerTab:Section({ Title = "Noclip" })

local NoclipToggle = PlayerTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls",
    Value = false,
    Callback = function(Value)
        if isNoclip ~= Value then setNoclipState(Value) end
    end
})

PlayerTab:Keybind({
    Title = "Noclip Keybind",
    Value = "X",
    Callback = function()
        isNoclip = not isNoclip
        NoclipToggle:Set(isNoclip)
        setNoclipState(isNoclip)
    end
})

PlayerTab:Section({ Title = "Click Teleport" })

local TeleportSection = PlayerTab:Section({
    Title = "Teleport",
    Desc = "Teleports to mouse cursor position",
    Box = true,
    BoxBorder = true,
})

TeleportSection:Toggle({
    Title = "Enable Press Teleport",
    Desc = "Enable click teleporting",
    Value = false,
    Callback = function(Value)
        clickTpEnabled = Value
    end
})

TeleportSection:Keybind({
    Title = "Teleport Keybind",
    Desc = "Teleport hotkey",
    Value = "E",
    Callback = function()
        if clickTpEnabled then
           local character = LocalPlayer.Character
           local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
           local humanoid = character and character:FindFirstChildOfClass("Humanoid")
           if humanoidRootPart and Mouse.Hit then
               if humanoid and humanoid.Sit then
                   humanoid.Sit = false
                   task.wait(0.1)
               end
               humanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.5, 0))
           end
       end
    end
})

PlayerTab:Section({ Title = "Spinbot" })

local SpinbotSection = PlayerTab:Section({
    Title = "Spinbot",
    Desc = "Fast rotation around character axis",
    Box = true,
    BoxBorder = true,
})

SpinbotSection:Toggle({
    Title = "Enable Spinbot",
    Value = false,
    Callback = function(Value)
        spinbotEnabled = Value
    end
})

SpinbotSection:Slider({
    Title = "Spin Speed",
    Desc = "Character spin speed",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 20 },
    Callback = function(Value)
        spinbotSpeed = Value
    end
})

PlayerTab:Section({ Title = "Invisibility" })

local InvisibilitySection = PlayerTab:Section({
    Title = "Invisibility Settings",
    Desc = "Configure invisibility parameters",
    Box = true,
    BoxBorder = true,
})

InvisibleToggleRef = InvisibilitySection:Toggle({
    Title = "Invisible",
    Desc = "Toggle client-side invisibility trick",
    Value = false,
    Callback = function(Value)
        if IsInvisible ~= Value then
            ToggleInvisible(Value)
        end
    end
})

InvisibilitySection:Slider({
    Title = "Teleport Distance",
    Desc = "Distance to teleport down when invisible",
    Step = 10000,
    Value = { Min = 50000, Max = 1000000, Default = 200000 },
    Callback = function(Value)
        invisibleDistance = Value
    end
})

local lastInvisibleKeybind = 0

InvisibilitySection:Keybind({
    Title = "Invisibility Keybind",
    Value = "M",
    Callback = function()
        local now = tick()
        if now - lastInvisibleKeybind < 0.3 then return end
        lastInvisibleKeybind = now

        local newState = not IsInvisible

        if InvisibleToggleRef then
            pcall(function() InvisibleToggleRef:Set(newState) end)
        end

        if IsInvisible ~= newState then
            ToggleInvisible(newState)
        end
    end
})

PlayerTab:Section({ Title = "Other" })

PlayerTab:Toggle({
    Title = "Enable Anti-AFK",
    Desc = "Prevents AFK disconnection (Error 260)",
    Value = true,
    Callback = function(state)
        toggleAntiAFK(state)
    end
})

toggleAntiAFK(true)

-- TAB 2: VISUALS
VisualsTab:Section({ Title = "ESP" })

VisualsTab:Toggle({
    Title = "Enable ESP",
    Desc = "Master ESP toggle",
    Value = false,
    Callback = function(Value)
        Config.ESP_Enabled = Value
    end
})

--=====================================================================
-- ESP: only these two are force-opened by default
--=====================================================================
local ESPColumnsGroup = VisualsTab:Group({})

local ESPSSection = ESPColumnsGroup:Section({
    Title = "ESP Settings",
    Desc = "General ESP options",
    Box = true,
    BoxBorder = true,
})
registerSectionForOpening(ESPSSection)

ESPSSection:Toggle({
    Title = "Boxes",
    Desc = "Show box overlays",
    Value = true,
    Callback = function(Value)
        Config.Boxes_Enabled = Value
    end
})

ESPSSection:Toggle({
    Title = "Use Display Name",
    Desc = "Display DisplayName instead of Username",
    Value = false,
    Callback = function(Value)
        Config.UseDisplayName = Value
    end
})

ESPSSection:Toggle({
    Title = "Tracers",
    Desc = "Lines pointing to players",
    Value = false,
    Callback = function(Value)
        Config.Tracers_Enabled = Value
    end
})

ESPSSection:Toggle({
    Title = "Head Dot",
    Desc = "Dot on player head",
    Value = true,
    Callback = function(Value)
        Config.HeadDot_Enabled = Value
    end
})

ESPSSection:Toggle({
    Title = "Health Bar",
    Desc = "Health bar indicator",
    Value = true,
    Callback = function(Value)
        Config.HealthBar_Enabled = Value
    end
})

local ESPCSection = ESPColumnsGroup:Section({
    Title = "ESP Customization",
    Desc = "Basic ESP customization",
    Box = true,
    BoxBorder = true,
})
registerSectionForOpening(ESPCSection)

ESPCSection:Dropdown({
    Title = "Health Bar Position",
    Desc = "Where to render the health bar",
    Value = "Right",
    Values = {"Right", "Left", "Top"},
    Callback = function(Value)
        Config.HealthBarPosition = Value
    end
})

ESPCSection:Colorpicker({
    Title = "Name Color",
    Desc = "ESP name text color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        Config.NameColor = Value
    end
})

ESPCSection:Toggle({
    Title = "Rainbow Names",
    Desc = "Rainbow name color effect",
    Value = false,
    Callback = function(Value)
        Config.RainbowNames = Value
    end
})

ESPCSection:Colorpicker({
    Title = "Box Color",
    Desc = "ESP box color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        Config.BoxColor = Value
    end
})

ESPCSection:Colorpicker({
    Title = "Tracer Color",
    Desc = "Tracer line color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        Config.TracerColor = Value
    end
})

ESPCSection:Colorpicker({
    Title = "Target Color",
    Desc = "Color for target locked by aimbot",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        Config.TargetColor = Value
    end
})

ESPCSection:Toggle({
    Title = "Target Invert Color",
    Desc = "Use inverted contrast color for target",
    Value = false,
    Callback = function(Value)
        Config.UseTargetInvert = Value
    end
})

ESPCSection:Toggle({
    Title = "Rainbow Boxes & Heads",
    Value = false,
    Callback = function(Value)
        Config.RainbowBoxes = Value
    end
})

ESPCSection:Toggle({
    Title = "Rainbow Tracers",
    Value = false,
    Callback = function(Value)
        Config.RainbowTracers = Value
    end
})

VisualsTab:Section({ Title = "Name tag" })

VisualsTab:Input({
    Title = "Tag Text",
    Desc = "Prefix text before username",
    PlaceholderText = "[GOD]",
    ClearTextOnFocus = false,
    Callback = function(Text)
        nameTagText = Text
    end
})

VisualsTab:Dropdown({
    Title = "Tag Color",
    Desc = "Prefix color",
    Value = "Yellow",
    Values = {"Yellow", "Red", "Green", "Blue", "Pink", "Orange", "Purple", "White", "Cyan"},
    Callback = function(Value)
        local colorMap = {
            ["Yellow"] = Color3.fromRGB(255, 215, 0),
            ["Red"] = Color3.fromRGB(255, 0, 0),
            ["Green"] = Color3.fromRGB(0, 255, 0),
            ["Blue"] = Color3.fromRGB(0, 150, 255),
            ["Pink"] = Color3.fromRGB(255, 0, 255),
            ["Orange"] = Color3.fromRGB(255, 140, 0),
            ["Purple"] = Color3.fromRGB(128, 0, 255),
            ["White"] = Color3.fromRGB(255, 255, 255),
            ["Cyan"] = Color3.fromRGB(0, 255, 255)
        }
        nameTagColor = colorMap[Value] or Color3.fromRGB(255, 215, 0)
    end
})

VisualsTab:Button({
    Title = "Apply NameTag",
    Desc = "Click to apply nametag",
    Callback = function()
        applyNameTag()
    end
})

VisualsTab:Section({ Title = "Shaders" })

local ShadersSection = VisualsTab:Section({
    Title = "Shader Library",
    Desc = "External graphics / shader loaders",
    Box = true,
    BoxBorder = true,
})

ShadersSection:Button({
    Title = "HDR Graphics",
    Desc = "Load HDR / high dynamic range graphics",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SyntaxScript/HDR-Graphics/main/main.lua"))()
        end)
    end,
})

ShadersSection:Button({
    Title = "PShade Ultimate",
    Desc = "Load PShade ultimate shader pack",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/back.json"))()
        end)
    end,
})

VisualsTab:Section({ Title = "Tools" })

VisualsTab:Button({
    Title = "Dex Explorer",
    Desc = "Open Dex++ explorer tool",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
        end)
    end
})

VisualsTab:Section({ Title = "Overlay & Camera" })

local ColumnsGroup = VisualsTab:Group({})

local FreecamSection = ColumnsGroup:Section({
    Title = "Camera",
    Box = true,
    BoxBorder = true,
})

local FreecamControls = FreecamSection:Group({})

local FreecamToggle = FreecamControls:Toggle({
    Title = "Freecam",
    Callback = function(Value)
        if freecamActive ~= Value then
            ToggleFreecam(Value)
        end
    end,
})

FreecamControls:Keybind({
    Title = "Keybind",
    Value = "P",
    Callback = function(Keybind)
       local newState = not freecamActive
       FreecamToggle:Set(newState)
       ToggleFreecam(newState)
   end,
})

FreecamSection:Slider({
    Title = "Camera FOV",
    Step = 1,
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(Value)
        Config.Camera_FOV = Value
        if freecamActive then
            freecamFOV = Value
            camera.FieldOfView = Value
        end
    end
})

FreecamSection:Toggle({
    Title = "Infinite Zoom",
    Desc = "Allows zooming out infinitely with mouse wheel",
    Value = false,
    Callback = function(Value)
        infZoomEnabled = Value
        if infZoomEnabled then
            currentMaxZoom = player.CameraMaxZoomDistance
        else
            player.CameraMaxZoomDistance = originalMaxZoom
            currentMaxZoom = originalMaxZoom
        end
    end
})

local OverlaySection = ColumnsGroup:Section({
    Title = "Overlay",
    Box = true,
    BoxBorder = true,
})

OverlaySection:Toggle({
    Title = "Enable Overlay",
    Callback = function(Value)
       perfGui.Enabled = Value
   end,
})

OverlaySection:Space()

OverlaySection:Slider({
    Title = "Gamma",
    Step = 0.1,
    Value = { Min = -1, Max = 1, Default = 0 },
    Callback = function(Value)
        setGamma(Value)
    end
})

OverlaySection:Toggle({
    Title = "Disable World Shadows",
    Desc = "Removes all shadows from the world (Lighting.GlobalShadows = false)",
    Value = false,
    Callback = function(Value)
        setShadowsDisabled(Value)
    end
})

-- TAB 3: COMBAT
CombatTab:Section({ Title = "Aim Bot" })

CombatTab:Toggle({
    Title = "Enable Aimbot",
    Desc = "Enable auto-aiming",
    Value = false,
    Callback = function(Value)
        Config.Aimbot_Enabled = Value
    end
})

local AIMSection = CombatTab:Section({
    Title = "AIM Bot Settings",
    Desc = "Aimbot settings and customization",
    Box = true,
    BoxBorder = true,
})

AIMSection:Dropdown({
    Title = "Activation Key",
    Desc = "Aimbot trigger key",
    Value = "RightClick",
    Values = {"RightClick", "LeftClick", "E", "Q", "C", "F", "LeftShift", "LeftAlt"},
    Callback = function(Value)
        Config.AimKey = Value
    end
})

AIMSection:Dropdown({
    Title = "Aimbot Method",
    Desc = "Aiming method (Mouse is smoother)",
    Value = "Mouse",
    Values = {"Camera", "Mouse"},
    Callback = function(Value)
        Config.AimMethod = Value
    end
})

AIMSection:Dropdown({
    Title = "Target Part",
    Desc = "Body part target",
    Value = "Head",
    Values = {"Head", "HumanoidRootPart", "UpperTorso"},
    Callback = function(Value)
        Config.TargetPart = Value
    end
})

AIMSection:Toggle({
    Title = "Show FOV Circle",
    Desc = "Show FOV radius circle",
    Value = true,
    Callback = function(Value)
        Config.FOV_Visible = Value
    end
})

AIMSection:Slider({
    Title = "FOV Size",
    Desc = "Aimbot FOV circle size",
    Step = 1,
    Value = { Min = 10, Max = 600, Default = 100 },
    Callback = function(Value)
        Config.FOV_Radius = Value
    end
})

AIMSection:Colorpicker({
    Title = "FOV Color",
    Desc = "FOV circle color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        Config.FOV_Color = Value
    end
})

AIMSection:Toggle({
    Title = "Rainbow FOV Circle",
    Desc = "Animated rainbow color for FOV circle",
    Value = false,
    Callback = function(Value)
        Config.FOV_Rainbow = Value
    end
})

CombatTab:Section({ Title = "Fling" })

local TargetPlayer = nil

local function findTarget(str)
    if not str or str == "" then return nil end
    str = string.lower(str)

    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= game:GetService("Players").LocalPlayer then
            if string.find(string.lower(p.Name), str) or string.find(string.lower(p.DisplayName), str) then
                return p
            end
        end
    end
    return nil
end

--=====================================================================
-- FLING: Input + Button directly in a Group (side-by-side, no Section wrapper)
--=====================================================================
local FlingGroup = CombatTab:Group({})

FlingGroup:Input({
   Title = "Player Name",
   PlaceholderText = "Enter part of username and press Enter...",
   ClearTextOnFocus = false,
   Callback = function(Text)
       if not Text or string.gsub(Text, "%s+", "") == "" then return end

       TargetPlayer = findTarget(Text)

       if not TargetPlayer then
           WindUI:Notify({
               Title = "Error",
               Content = "Player not found!",
               Duration = 3,
           })
           return
       end

       WindUI:Notify({
           Title = "Target Found",
           Content = "Attacking: " .. TargetPlayer.DisplayName .. " (@" .. TargetPlayer.Name .. ")",
           Duration = 3,
       })
   end,
})

FlingGroup:Button({
   Title = "Fling Target",
   Desc = "Launch Touch Fling at target player",
   Callback = function()
       if not TargetPlayer then
           WindUI:Notify({
               Title = "Error",
               Content = "Search for a player above first!",
               Duration = 3,
           })
           return
       end

       local lp = game:GetService("Players").LocalPlayer
       local char = lp.Character
       local hrp = char and char:FindFirstChild("HumanoidRootPart")
       local hum = char and char:FindFirstChildOfClass("Humanoid")

       local tChar = TargetPlayer.Character
       local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")

       if hrp and hum and tHrp then

           local oldPos = hrp.CFrame

           local bAngularV = Instance.new("BodyAngularVelocity")
           bAngularV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
           bAngularV.AngularVelocity = Vector3.new(0, 99999, 0)
           bAngularV.Parent = hrp

           local bV = Instance.new("BodyVelocity")
           bV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
           bV.Velocity = Vector3.new(0, 0, 0)
           bV.Parent = hrp

           local parts = {}
           for _, v in ipairs(char:GetDescendants()) do
               if v:IsA("BasePart") then
                   parts[v] = v.CanCollide
                   v.CanCollide = false
               end
           end

           local startTime = tick()
           while tick() - startTime < 3 and tHrp.Parent and hum.Health > 0 do
               task.wait()
               if hrp and tHrp then
                   local randomOffset = Vector3.new(
                       math.random(-2, 2),
                       math.random(-1, 1),
                       math.random(-2, 2)
                   )
                   hrp.RotVelocity = Vector3.new(0, 50000, 0)
                   hrp.CFrame = tHrp.CFrame * CFrame.new(randomOffset)
               end
           end

           bAngularV:Destroy()
           bV:Destroy()
           if hrp then
               hrp.RotVelocity = Vector3.new(0, 0, 0)
               hrp.Velocity = Vector3.new(0, 0, 0)
               hrp.CFrame = oldPos
           end

           for part, oldCollide in pairs(parts) do
               if part and part.Parent then
                   part.CanCollide = oldCollide
               end
           end
       end
   end,
})

CombatTab:Toggle({
    Title = "Touch Fling",
    Desc = "Fling anyone on physical touch",
    Value = false,
    Callback = function(Value)
        flingActive = Value
        if flingActive then
            flingThread = coroutine.create(flingLoop)
            coroutine.resume(flingThread)
        else
            flingThread = nil
        end
    end
})

CombatTab:Toggle({
    Title = "Fling All",
    Desc = "Fling every player on server",
    Value = false,
    Callback = function(Value)
        flingAllActive = Value
        if flingAllActive then
            flingAllThread = coroutine.create(flingAllLoop)
            coroutine.resume(flingAllThread)
        else
            flingAllThread = nil
        end
    end
})

CombatTab:Toggle({
    Title = "Anti-Fling",
    Desc = "Protection against fling exploiters",
    Value = false,
    Callback = function(Value)
        toggleAntiFling(Value)
    end
})

CombatTab:Section({ Title = "Hitbox" })

CombatTab:Toggle({
    Title = "Enable Hitboxes",
    Desc = "Master hitbox expander toggle",
    Value = false,
    Callback = function(Value)
        HitboxConfig.Enabled = Value
        if not Value then
            ResetHitboxes()
        end
    end,
})

local HitboxSection = CombatTab:Section({
    Title = "Hitbox Settings",
    Desc = "Expand player hitboxes (HumanoidRootPart)",
    Box = true,
    BoxBorder = true,
})

HitboxSection:Slider({
    Title = "Hitbox Size",
    Step = 1,
    Value = { Min = 2, Max = 100, Default = 15 },
    Callback = function(Value)
        HitboxConfig.Size = Value
    end
})

HitboxSection:Slider({
    Title = "Transparency",
    Desc = "0 - Fully visible, 1 - Invisible",
    Step = 0.1,
    Value = { Min = 0, Max = 1, Default = 0.7 },
    Callback = function(Value)
        HitboxConfig.Transparency = Value
    end
})

HitboxSection:Colorpicker({
    Title = "Hitbox Color",
    Default = Color3.fromRGB(150, 150, 150),
    Callback = function(Color)
        HitboxConfig.Color = Color
    end
})

-- TAB 4: SETTINGS
SettingsTab:Section({ Title = "Interface Customization" })

SettingsTab:Dropdown({
    Title = "Select Theme",
    Desc = "Select UI color theme",
    Value = "Dark",
    Values = {"Dark", "Light"},
    Callback = function(Value)
        WindUI:SetTheme(Value)
    end
})

local isGuiVisible = true

SettingsTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Show/Hide interface hotkey",
    Value = "CapsLock",
    Callback = function()
        if Window.Toggle then
            Window:Toggle()
        else
            isGuiVisible = not isGuiVisible
            Window.Enabled = isGuiVisible
        end
    end
})

SettingsTab:Button({
    Title = "Unload Script",
    Desc = "Completely disable script and clean up all functions",
    Callback = function()
        unloadScript()
    end
})

PlayerTab:Select()

--=====================================================================
-- FORCE-OPEN only registered sections (ESP Settings + ESP Customization)
--=====================================================================
task.spawn(function()
    task.wait(0.8)
    for _, sec in ipairs(SectionsToOpen) do
        forceOpenSection(sec)
    end
    for _ = 1, 3 do
        task.wait(0.5)
        for _, sec in ipairs(SectionsToOpen) do
            forceOpenSection(sec)
        end
    end
end)
