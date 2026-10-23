local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("Zibvabva | 0.2 alpha", "RJTheme1")

local Tab = Window:NewTab("Universal Script")
local Section = Tab:NewSection("Main")

Section:NewSlider("WalkSpeed", "WalkSpeed", 300, 16, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)
Section:NewSlider("JumpPower", "JumpPower", 400, 50, function(J)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = J
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isFlying = false
local flySpeed = 60
local connection = nil

local isNoclip = false
local noclipConnection = nil

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

local Section = Tab:NewSection("Flight Settings")

Section:NewToggle("Enable Fly", "Toggle smooth flight mode on or off", function(state)
    if isFlying ~= state then
        setFlightState(state)
    end
end)

Section:NewSlider("Fly Speed", "Adjust your movement speed in the air", 300, 20, function(value)
    flySpeed = value
end)

Section:NewKeybind("Fly Keybind", "Key to quickly toggle flight mode", Enum.KeyCode.F, function()
    setFlightState(not isFlying)
end)

local Section = Tab:NewSection("Noclip Settings")

Section:NewToggle("Enable Noclip", "Walk or fly through any solid structures", function(state)
    if isNoclip ~= state then
        setNoclipState(state)
    end
end)

Section:NewKeybind("Noclip Keybind", "Key to quickly toggle noclip mode", Enum.KeyCode.X, function()
    setNoclipState(not isNoclip)
end)

player.CharacterAdded:Connect(function(newCharacter)
    if isFlying then
        setFlightState(false)
    end
    if isNoclip then
        setNoclipState(false)
    end
end)

local espEnabled = {
    Name = false,
    Health = false,
    Distance = false,
    Box = false,
    Glow = false,
    Tracer = false,
    TeamColor = false,
    HideTeam = false
}
local espColor = Color3.fromRGB(0, 170, 255)
local espObjects = {}
local espConnections = {}

local function clearESP()
    for _, obj in pairs(espObjects) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    espObjects = {}
    for _, conn in pairs(espConnections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    espConnections = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character then
            for _, child in pairs(plr.Character:GetDescendants()) do
                if child:IsA("BillboardGui") and child.Name == "ESP_Billboard" then child:Destroy() end
                if child:IsA("Highlight") and child.Name == "ESP_Glow" then child:Destroy() end
                if child:IsA("BoxHandleAdornment") and child.Name == "ESP_Box" then child:Destroy() end
            end
            if plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                for _, child in pairs(root:GetChildren()) do
                    if child:IsA("Beam") and child.Name == "ESP_Tracer" then child:Destroy() end
                    if child:IsA("Attachment") and child.Name == "TracerAttach" then child:Destroy() end
                end
            end
        end
    end
    local lp = game.Players.LocalPlayer
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local root = lp.Character.HumanoidRootPart
        for _, child in pairs(root:GetChildren()) do
            if child:IsA("Attachment") and child.Name == "TracerAttach_Local" then child:Destroy() end
            if child:IsA("Beam") and child.Name == "ESP_Tracer" then child:Destroy() end
        end
    end
end

local function updateESP()
    clearESP()
    local anyOn = espEnabled.Name or espEnabled.Health or espEnabled.Distance or espEnabled.Box or espEnabled.Glow or espEnabled.Tracer
    if not anyOn then return end

    local lp = game.Players.LocalPlayer
    local localChar = lp.Character
    if not localChar then return end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    if espEnabled.Tracer then
        local attachLocal = Instance.new("Attachment")
        attachLocal.Name = "TracerAttach_Local"
        attachLocal.Parent = localRoot
        attachLocal.CFrame = CFrame.new(0, -1, 0)
        table.insert(espObjects, attachLocal)
    end

    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr == lp then continue end
        local char = plr.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then continue end

        if espEnabled.HideTeam and plr.Team == lp.Team then
            continue
        end

        local color = espColor
        if espEnabled.TeamColor then
            color = plr.TeamColor.Color
        end

        if espEnabled.Name or espEnabled.Health or espEnabled.Distance then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.Size = UDim2.new(0, 200, 0, 40)
            billboard.Adornee = root
            billboard.AlwaysOnTop = true
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.Parent = root

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.Font = Enum.Font.Code
            label.TextColor3 = color
            label.TextStrokeTransparency = 0.5
            label.Parent = billboard

            local function updateLabel()
                local dist = (localRoot.Position - root.Position).Magnitude
                local text = ""
                if espEnabled.Name then
                    text = plr.Name
                end
                if espEnabled.Health then
                    if text ~= "" then text = text .. " | " end
                    text = text .. math.floor(hum.Health) .. " HP"
                end
                if espEnabled.Distance then
                    if text ~= "" then text = text .. " | " end
                    text = text .. math.floor(dist) .. "m"
                end
                label.Text = text
                label.TextColor3 = color
            end
            updateLabel()
            local conn = game:GetService("RunService").RenderStepped:Connect(updateLabel)
            table.insert(espConnections, conn)
            table.insert(espObjects, billboard)
        end

        if espEnabled.Box then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESP_Box"
            box.Size = root.Size * 1.5
            box.Adornee = root
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Color3 = color
            box.Transparency = 0.3
            box.Parent = root
            table.insert(espObjects, box)
        end

        if espEnabled.Glow then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESP_Glow"
                    hl.Adornee = part
                    hl.FillColor = color
                    hl.OutlineColor = color
                    hl.FillTransparency = 0.4
                    hl.Parent = part
                    table.insert(espObjects, hl)
                end
            end
        end

        if espEnabled.Tracer then
            local attachTarget = root:FindFirstChild("TracerAttach")
            if not attachTarget then
                attachTarget = Instance.new("Attachment")
                attachTarget.Name = "TracerAttach"
                attachTarget.Parent = root
                attachTarget.CFrame = CFrame.new(0, 0, 0)
                table.insert(espObjects, attachTarget)
            end
            local beam = Instance.new("Beam")
            beam.Name = "ESP_Tracer"
            beam.Parent = localRoot
            beam.Attachment0 = localRoot:FindFirstChild("TracerAttach_Local")
            beam.Attachment1 = attachTarget
            beam.Color = ColorSequence.new(color, color)
            beam.FaceCamera = true
            beam.LightInfluence = 0
            beam.Transparency = NumberSequence.new(0.1)
            beam.Width0 = 0.08
            beam.Width1 = 0.08
            table.insert(espObjects, beam)
        end
    end
end

local function rebuildESP()
    local anyOn = espEnabled.Name or espEnabled.Health or espEnabled.Distance or espEnabled.Box or espEnabled.Glow or espEnabled.Tracer
    if anyOn then
        updateESP()
    else
        clearESP()
    end
end


local function setupEventHandlers()
    game.Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            rebuildESP()
        end)
    end)

    game.Players.PlayerRemoving:Connect(function()
        rebuildESP()
    end)

    local lp = game.Players.LocalPlayer
    lp.CharacterAdded:Connect(function()
        rebuildESP()
    end)
end

setupEventHandlers()

local Section = Tab:NewSection("ESP Settings")

Section:NewDropdown("ESP Preset", "Choose ESP mode", {
    "Off",
    "Info (Name+Health+Distance)",
    "Box",
    "Glow",
    "Tracers",
    "All"
}, function(selected)
    if selected == "Off" then
        espEnabled.Name = false
        espEnabled.Health = false
        espEnabled.Distance = false
        espEnabled.Box = false
        espEnabled.Glow = false
        espEnabled.Tracer = false
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    elseif selected == "Info (Name+Health+Distance)" then
        espEnabled.Name = true
        espEnabled.Health = true
        espEnabled.Distance = true
        espEnabled.Box = false
        espEnabled.Glow = false
        espEnabled.Tracer = false
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    elseif selected == "Box" then
        espEnabled.Name = false
        espEnabled.Health = false
        espEnabled.Distance = false
        espEnabled.Box = true
        espEnabled.Glow = false
        espEnabled.Tracer = false
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    elseif selected == "Glow" then
        espEnabled.Name = false
        espEnabled.Health = false
        espEnabled.Distance = false
        espEnabled.Box = false
        espEnabled.Glow = true
        espEnabled.Tracer = false
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    elseif selected == "Tracers" then
        espEnabled.Name = false
        espEnabled.Health = false
        espEnabled.Distance = false
        espEnabled.Box = false
        espEnabled.Glow = false
        espEnabled.Tracer = true
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    elseif selected == "All" then
        espEnabled.Name = true
        espEnabled.Health = true
        espEnabled.Distance = true
        espEnabled.Box = true
        espEnabled.Glow = true
        espEnabled.Tracer = true
        espEnabled.TeamColor = false
        espEnabled.HideTeam = false
    end
    rebuildESP()
end)

Section:NewDropdown("ESP Color", "Select ESP color", {
    "White",
    "Red",
    "Green",
    "Blue",
    "Yellow",
    "Orange",
    "Purple",
    "Pink",
    "Cyan"
}, function(selected)
    local colorMap = {
        ["White"] = Color3.new(1,1,1),
        ["Red"] = Color3.new(1,0,0),
        ["Green"] = Color3.new(0,1,0),
        ["Blue"] = Color3.new(0,0,1),
        ["Yellow"] = Color3.new(1,1,0),
        ["Orange"] = Color3.new(1,0.5,0),
        ["Purple"] = Color3.new(0.5,0,1),
        ["Pink"] = Color3.new(1,0,1),
        ["Cyan"] = Color3.new(0,1,1)
    }
    espColor = colorMap[selected] or Color3.new(0, 170, 255)
    rebuildESP()
end)

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

local Section = Tab:NewSection("Fling Settings")

Section:NewToggle("Touch Fling", "Fling players on touch", function(state)
    flingActive = state
    if flingActive then
        flingThread = coroutine.create(flingLoop)
        coroutine.resume(flingThread)
    else
        flingThread = nil
    end
end)

local flingAllActive = false
local flingAllThread = nil
local flingAllPlayers = {} 

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
                coroutine.wrap(function()
                    pcall(function()
                        SkidFling(target)
                    end)
                end)()
                task.wait(0.2) 
            end
        end
        task.wait(1) 
    end
end

Section:NewToggle("Fling All", "Fling all players continuously", function(state)
    flingAllActive = state
    if flingAllActive then
        flingAllThread = coroutine.create(flingAllLoop)
        coroutine.resume(flingAllThread)
    else
        flingAllThread = nil
    end
end)