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
    TargetPart = "Head",
    AimKey = "RightClick",
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

local function onRenderStep()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")

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
    local humanoid = character and character:FindFirstChild("Humanoid")

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
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
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
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
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
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local currentFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70

RunService.RenderStepped:Connect(function()
    if not freecamActive and Config.ESP_Enabled ~= nil then
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = Config.Camera_FOV
        end
    end
end)

player.CharacterAdded:Connect(function(newCharacter)
    if isFlying then setFlightState(false) end
    if isNoclip then setNoclipState(false) end

    task.wait(0.5)
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = currentFOV
    end
end)

local function getParent()
    if gethui then return gethui() end
    local ok = pcall(function() return CoreGui:GetChildren() end)
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
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)

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
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        perfFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

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

RunService.RenderStepped:Connect(function()
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
end)

local ESPCache = {}

local function createESP(player)
    if ESPCache[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1.5

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 16
    nameTag.Center = true
    nameTag.Outline = true

    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Visible = false
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    healthBarOutline.Thickness = 1
    healthBarOutline.Filled = true

    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Thickness = 1
    healthBar.Filled = true

    local headDot = Drawing.new("Circle")
    headDot.Visible = false
    headDot.Thickness = 1
    headDot.Filled = false

    ESPCache[player] = {
        Box = box, Tracer = tracer, NameTag = nameTag,
        HealthBarOutline = healthBarOutline, HealthBar = healthBar,
        HeadDot = headDot
    }
end

local function removeESP(player)
    if ESPCache[player] then
        for _, object in pairs(ESPCache[player]) do
            object.Visible = false
            object:Remove()
        end
        ESPCache[player] = nil
    end
end

local function getInvertedColor(color)
    return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
end

local IsLocking = false

RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    local myCharacter = LocalPlayer.Character
    local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)

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
                local targetScreenPos, targetOnScreen = Camera:WorldToViewportPoint(targetRootPart.Position)
                local headScreenPos, headOnScreen = Camera:WorldToViewportPoint(targetHead.Position)
                local myScreenPos, myOnScreen = Camera:WorldToViewportPoint(myRootPart.Position)

                if targetOnScreen then
                    local distance = (Camera.CFrame.Position - targetRootPart.Position).Magnitude
                    local sizeX = 2000 / distance
                    local sizeY = 3000 / distance

                    local boxX = targetScreenPos.X - (sizeX / 2)
                    local boxY = targetScreenPos.Y - (sizeY / 2)

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
                        visuals.Box.Size = Vector2.new(sizeX, sizeY)
                        visuals.Box.Position = Vector2.new(boxX, boxY)
                        visuals.Box.Color = activeBoxColor
                        visuals.Box.Visible = true
                    else
                        visuals.Box.Visible = false
                    end

                    if Config.Tracers_Enabled then
                        visuals.Tracer.From = Vector2.new(myScreenPos.X, myScreenPos.Y)
                        visuals.Tracer.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                        visuals.Tracer.Color = Config.RainbowTracers and rainbowColor or Config.TracerColor
                        visuals.Tracer.Visible = true
                    else
                        visuals.Tracer.Visible = false
                    end

                    visuals.NameTag.Text = Config.UseDisplayName and player.DisplayName or player.Name
                    visuals.NameTag.Position = Vector2.new(targetScreenPos.X, boxY - 20)
                    visuals.NameTag.Color = activeNameColor
                    visuals.NameTag.Visible = true

                    if Config.HeadDot_Enabled and headOnScreen then
                        visuals.HeadDot.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                        visuals.HeadDot.Radius = math.clamp(1000 / distance, 1, 15)
                        visuals.HeadDot.Color = activeBoxColor
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
                            visuals.HealthBarOutline.Size = Vector2.new(4, sizeY)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX + sizeX + 3, boxY)
                            visuals.HealthBar.Size = Vector2.new(2, sizeY * hpPercent)
                            visuals.HealthBar.Position = Vector2.new(boxX + sizeX + 4, boxY + (sizeY * (1 - hpPercent)))
                        elseif Config.HealthBarPosition == "Left" then
                            visuals.HealthBarOutline.Size = Vector2.new(4, sizeY)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX - 7, boxY)
                            visuals.HealthBar.Size = Vector2.new(2, sizeY * hpPercent)
                            visuals.HealthBar.Position = Vector2.new(boxX - 6, boxY + (sizeY * (1 - hpPercent)))
                        elseif Config.HealthBarPosition == "Top" then
                            visuals.HealthBarOutline.Size = Vector2.new(sizeX, 4)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX, boxY - 7)
                            visuals.HealthBar.Size = Vector2.new(sizeX * hpPercent, 2)
                            visuals.HealthBar.Position = Vector2.new(boxX, boxY - 6)
                        end

                        visuals.HealthBar.Color = hpColor
                        visuals.HealthBarOutline.Visible = true
                        visuals.HealthBar.Visible = true
                    else
                        visuals.HealthBarOutline.Visible = false
                        visuals.HealthBar.Visible = false
                    end
                else
                    for _, object in pairs(visuals) do object.Visible = false end
                end
            else
                if visuals then
                    for _, object in pairs(visuals) do object.Visible = false end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)

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

player.CharacterAdded:Connect(function(char)
    if not nameTagApplied then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.DisplayName = nameTagText .. " " .. player.Name
    end
end)

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

RunService.RenderStepped:Connect(function()
    if nameTagApplied then
        patchPlayerList()
        patchScoreboard()
    end
end)

local clickTpEnabled = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false

function GetTarget()
    local Camera = workspace.CurrentCamera
    local CurrentTarget = nil
    local MaxDist = Config.FOV_Radius
    local Mouse = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Config.TargetPart) then
            if Config.TeamCheck and p.Team == LocalPlayer.Team then continue end

            local Part = p.Character[Config.TargetPart]
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)

            if OnScreen then
                local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Mouse).Magnitude
                if Dist < MaxDist then
                    CurrentTarget = Part
                    MaxDist = Dist
                end
            end
        end
    end
    return CurrentTarget
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = true
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsLocking = true
    elseif input.KeyCode.Name == Config.AimKey then
        IsLocking = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if Config.AimKey == "RightClick" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsLocking = false
    elseif Config.AimKey == "LeftClick" and input.UserInputType == Enum.UserInputType.MouseButton1 then
         IsLocking = false
    elseif input.KeyCode.Name == Config.AimKey then
        IsLocking = false
    end
end)

RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    if Config.Aimbot_Enabled and Config.FOV_Visible then
        FOVCircle.Visible = true
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOV_Radius
        FOVCircle.Color = Config.FOV_Color
    else
        FOVCircle.Visible = false
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
end)

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = Workspace.CurrentCamera
	if newCamera then Camera = newCamera end
end)

local FFlagUserShowGuiHideToggles = pcall(function() return UserSettings():IsUserFeatureEnabled("UserShowGuiHideToggles") end)

local FREECAM_ENABLED_ATTRIBUTE_NAME = "FreecamEnabled"
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300
local PITCH_LIMIT = rad(90)
local VEL_STIFFNESS, PAN_STIFFNESS, FOV_STIFFNESS = 1.5, 1.0, 4.0

local Spring = {}
Spring.__index = Spring
function Spring.new(freq, pos)
	local self = setmetatable({}, Spring)
	self.f, self.p, self.v = freq, pos, pos*0
	return self
end
function Spring:Update(dt, goal)
	local f = self.f*2*pi
	local p0, v0 = self.p, self.v
	local offset = goal - p0
	local decay = exp(-f*dt)
	local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
	local v1 = (f*dt*(offset*f - v0) + v0)*decay
	self.p, self.v = p1, v1
	return p1
end
function Spring:Reset(pos)
	self.p, self.v = pos, pos*0
end

local cameraPos, cameraRot, cameraFov = Vector3.new(), Vector2.new(), 0
local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

local Input = {} do
	local gamepad = { ButtonX = 0, ButtonY = 0, DPadDown = 0, DPadUp = 0, ButtonL2 = 0, ButtonR2 = 0, Thumbstick1 = Vector2.new(), Thumbstick2 = Vector2.new() }
	local keyboard = { W = 0, A = 0, S = 0, D = 0, E = 0, Q = 0, U = 0, H = 0, J = 0, K = 0, I = 0, Y = 0, Up = 0, Down = 0 }
	local mouse = { Delta = Vector2.new(), MouseWheel = 0 }

	local NAV_GAMEPAD_SPEED, NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1), Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED, PAN_GAMEPAD_SPEED = Vector2.new(1, 1)*(pi/64), Vector2.new(1, 1)*(pi/8)
	local FOV_WHEEL_SPEED, FOV_GAMEPAD_SPEED = 1.0, 0.25
	local NAV_ADJ_SPEED, NAV_SHIFT_MUL, navSpeed = 0.75, 0.25, 1

	function Input.Vel(dt)
		navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)
		local kGamepad = Vector3.new(sign(gamepad.Thumbstick1.X)*clamp((abs(gamepad.Thumbstick1.X)-0.15)/(1-0.15), 0, 1), gamepad.ButtonR2 - gamepad.ButtonL2, -sign(gamepad.Thumbstick1.Y)*clamp((abs(gamepad.Thumbstick1.Y)-0.15)/(1-0.15), 0, 1))*NAV_GAMEPAD_SPEED
		local kKeyboard = Vector3.new(keyboard.D - keyboard.A + keyboard.K - keyboard.H, keyboard.E - keyboard.Q + keyboard.I - keyboard.Y, keyboard.S - keyboard.W + keyboard.J - keyboard.U)*NAV_KEYBOARD_SPEED
		local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kGamepad = Vector2.new(sign(gamepad.Thumbstick2.Y)*clamp((abs(gamepad.Thumbstick2.Y)-0.15)/(1-0.15), 0, 1), -sign(gamepad.Thumbstick2.X)*clamp((abs(gamepad.Thumbstick2.X)-0.15)/(1-0.15), 0, 1))*PAN_GAMEPAD_SPEED
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kGamepad + kMouse
	end

	function Input.Fov(dt)
		return (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED + mouse.MouseWheel*FOV_WHEEL_SPEED
	end

	local function Keypress(action, state, input) keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0 return Enum.ContextActionResult.Sink end
	local function MousePan(action, state, input) local delta = input.Delta mouse.Delta = Vector2.new(-delta.y, -delta.x) return Enum.ContextActionResult.Sink end
	local function MouseWheel(action, state, input) mouse[input.UserInputType.Name] = -input.Position.z return Enum.ContextActionResult.Sink end

	function Input.StartCapture()
		ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY, Enum.KeyCode.W, Enum.KeyCode.U, Enum.KeyCode.A, Enum.KeyCode.H, Enum.KeyCode.S, Enum.KeyCode.J, Enum.KeyCode.D, Enum.KeyCode.K, Enum.KeyCode.E, Enum.KeyCode.I, Enum.KeyCode.Q, Enum.KeyCode.Y, Enum.KeyCode.Up, Enum.KeyCode.Down)
		ContextActionService:BindActionAtPriority("FreecamMousePan", MousePan, false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
		ContextActionService:BindActionAtPriority("FreecamMouseWheel", MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
	end

	function Input.StopCapture()
		navSpeed = 1
		for k in pairs(gamepad) do gamepad[k] = gamepad[k]*0 end
		for k in pairs(keyboard) do keyboard[k] = keyboard[k]*0 end
		for k in pairs(mouse) do mouse[k] = mouse[k]*0 end
		ContextActionService:UnbindAction("FreecamKeyboard")
		ContextActionService:UnbindAction("FreecamMousePan")
		ContextActionService:UnbindAction("FreecamMouseWheel")
	end
end

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))
	local fov = fovSpring:Update(dt, Input.Fov(dt))
	local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))
	cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 100)
	cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
	cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))
	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
	cameraPos, Camera.CFrame, Camera.Focus, Camera.FieldOfView = cameraCFrame.p, cameraCFrame, cameraCFrame, cameraFov
end

local PlayerState = {} do
	local mouseBehavior, mouseIconEnabled, cameraType, cameraFocus, cameraCFrame, cameraFieldOfView
	local screenGuis, coreGuis, setCores = {}, {Backpack = true, Chat = true, Health = true, PlayerList = true}, {BadgesNotificationsActive = true, PointsNotificationsActive = true}

	function PlayerState.Push()
		for name in pairs(coreGuis) do coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name]) StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false) end
		for name in pairs(setCores) do pcall(function() setCores[name] = StarterGui:GetCore(name) StarterGui:SetCore(name, false) end) end
		local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playergui then for _, gui in pairs(playergui:GetChildren()) do if gui:IsA("ScreenGui") and gui.Enabled then table.insert(screenGuis, gui) gui.Enabled = false end end end
		cameraFieldOfView, Camera.FieldOfView = Camera.FieldOfView, 70
		cameraType, Camera.CameraType = Camera.CameraType, Enum.CameraType.Custom
		cameraCFrame, cameraFocus, mouseIconEnabled = Camera.CFrame, Camera.Focus, UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = false
		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		for name, isEnabled in pairs(coreGuis) do StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled) end
		for name, isEnabled in pairs(setCores) do pcall(function() StarterGui:SetCore(name, isEnabled) end) end
		for _, gui in pairs(screenGuis) do if gui.Parent then gui.Enabled = true end end
		Camera.FieldOfView, cameraFieldOfView = cameraFieldOfView, nil
		Camera.CameraType, cameraType = cameraType, nil
		Camera.CFrame, cameraCFrame = cameraCFrame, nil
		Camera.Focus, cameraFocus = cameraFocus, nil
		UserInputService.MouseIconEnabled, mouseIconEnabled = mouseIconEnabled, nil
		UserInputService.MouseBehavior, mouseBehavior = mouseBehavior, nil
		table.clear(screenGuis)
	end
end

local function StartFreecam()
	if freecamActive then return end
	freecamActive = true
	if FFlagUserShowGuiHideToggles and pcall(function() return script and script.SetAttribute end) then script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, true) end
	local cameraCFrame = Camera.CFrame
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos, cameraFov = cameraCFrame.p, Camera.FieldOfView
	velSpring:Reset(Vector3.new()) panSpring:Reset(Vector2.new()) fovSpring:Reset(0)
	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
end

local function StopFreecam()
	if not freecamActive then return end
	freecamActive = false
	if FFlagUserShowGuiHideToggles and pcall(function() return script and script.SetAttribute end) then script:SetAttribute(FREECAM_ENABLED_ATTRIBUTE_NAME, false) end
	Input.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
end

local function ToggleFreecam(state)
	if state then StartFreecam() else StopFreecam() end
end

local Lighting = game:GetService("Lighting")
local gammaEffect = Lighting:FindFirstChild("GammaCorrection") or Instance.new("ColorCorrectionEffect")
gammaEffect.Name = "GammaCorrection"
gammaEffect.Parent = Lighting

local function setGamma(value)
    gammaEffect.Brightness = math.clamp(value, -1, 1)
end

local HitboxConfig = {
    Enabled = false,
    Size = 15,
    Color = Color3.fromRGB(150, 150, 150),
    Transparency = 0.7
}

RunService.RenderStepped:Connect(function()
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
end)

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

local InfiniteJumpEnabled = false

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local spinbotEnabled = false
local spinbotSpeed = 20

RunService.RenderStepped:Connect(function()
    if spinbotEnabled then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
        end
    end
end)

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

--========================================================
-- UI INTERFACE
--========================================================
local isUnloaded = false
local Window = nil

local function unloadScript()
    if isUnloaded then return end
    isUnloaded = true

    Config.ESP_Enabled = false
    Config.Aimbot_Enabled = false
    HitboxConfig.Enabled = false
    ResetHitboxes()

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

    for p, _ in pairs(ESPCache) do
        removeESP(p)
    end

    if FOVCircle then
        FOVCircle.Visible = false
        pcall(function() FOVCircle:Remove() end)
    end

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
end

local _version = "1.6.66"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()

Window = WindUI:CreateWindow({
    Title = "Zibvabva | 0.5 alpha",
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

--========================================================
-- TAB 1: PLAYER
--========================================================
PlayerTab:Section({ Title = "Main Movement" })

PlayerTab:Slider({
    Title = "WalkSpeed",
    Desc = "Set character walk speed",
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

PlayerTab:Section({ Title = "Other" })

local AntiAfkToggle = PlayerTab:Toggle({
    Title = "Enable Anti-AFK",
    Desc = "Prevents AFK disconnection (Error 260)",
    Value = true,
    Callback = function(state)
        toggleAntiAFK(state)
    end
})

toggleAntiAFK(true)

--========================================================
-- TAB 2: VISUALS
--========================================================
VisualsTab:Section({ Title = "ESP" })

VisualsTab:Toggle({
    Title = "Enable ESP",
    Desc = "Master ESP toggle",
    Value = false,
    Callback = function(Value)
        Config.ESP_Enabled = Value
    end
})

local ESPSSection = VisualsTab:Section({
    Title = "ESP Settings",
    Desc = "General ESP options",
    Box = true,
    BoxBorder = true,
})

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

local ESPCSection = VisualsTab:Section({
    Title = "ESP Customization",
    Desc = "Basic ESP customization",
    Box = true,
    BoxBorder = true,
})

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
    Title = "Rainbow Names",
    Desc = "Rainbow name color effect",
    Value = false,
    Callback = function(Value)
        Config.RainbowNames = Value
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
   end,
})

FreecamSection:Slider({
    Title = "Camera FOV",
    Step = 1,
    Value = { Min = 30, Max = 120, Default = 70 },
    Callback = function(Value)
        Config.Camera_FOV = Value
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

--========================================================
-- TAB 3: COMBAT
--========================================================
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

CombatTab:Input({
   Title = "Target Player Name",
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

CombatTab:Button({
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

--========================================================
-- TAB 4: SETTINGS
--========================================================
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
