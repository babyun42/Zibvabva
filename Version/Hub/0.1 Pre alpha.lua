local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robojini/Tuturial_UI_Library/main/UI_Template_1"))()

local Window = Library.CreateLib("Zibvabva | 0.1 alpha", "RJTheme1")

local Tab = Window:NewTab("Universal Script")

local Section = Tab:NewSection("main")

Section:NewSlider("WalkSpeed", "WalkSpeed", 300, 16, function(s)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)
Section:NewSlider("JumpPower", "JumpPower", 400, 50, function(J)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = J
end)

Section:NewButton("fly v3", "by denker and xneo", function()
loadstring(game:HttpGet('https://pastebin.com/raw/WXe57F7i'))()
end)

Section:NewButton("noclip", "by hiroshiph338", function()

local GuiName = "Noclip_" .. tostring(math.random(1000, 9999))
local ButtonName = "Button_" .. tostring(math.random(1000, 9999))
local FrameName = "Frame_" .. tostring(math.random(1000, 9999))


local function antiDetect()
    pcall(function()
        if getgenv then
            getgenv().SecureScript = true
        end
    end)
end

local function antiPatch()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local backup = mt.__namecall
        mt.__namecall = newcclosure(function(...)
            return backup(...)
        end)
        setreadonly(mt, true)
    end)
end

antiDetect()
antiPatch()

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local NoclipButton = Instance.new("TextButton")
local CreditsButton = Instance.new("TextButton")
local CreditsLabel = Instance.new("TextLabel")

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = GuiName
ScreenGui.ResetOnSpawn = false

MainFrame.Name = FrameName
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Noclip"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = MainFrame
MinimizeButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 0)
MinimizeButton.TextSize = 20

CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextSize = 20

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 30)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "Status: Off"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 16

NoclipButton.Name = ButtonName
NoclipButton.Parent = MainFrame
NoclipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NoclipButton.Position = UDim2.new(0.1, 0, 0.4, 0)
NoclipButton.Size = UDim2.new(0.8, 0, 0, 30)
NoclipButton.Font = Enum.Font.SourceSansBold
NoclipButton.Text = "Noclip"
NoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipButton.TextSize = 18

CreditsButton.Name = "CreditsButton"
CreditsButton.Parent = MainFrame
CreditsButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CreditsButton.Position = UDim2.new(0.1, 0, 0.7, 0)
CreditsButton.Size = UDim2.new(0.8, 0, 0, 30)
CreditsButton.Font = Enum.Font.SourceSansBold
CreditsButton.Text = "Credits"
CreditsButton.TextColor3 = Color3.fromRGB(255, 255, 0)
CreditsButton.TextSize = 18

CreditsLabel.Name = "CreditsLabel"
CreditsLabel.Parent = MainFrame
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Position = UDim2.new(0, 0, 1, -20)
CreditsLabel.Size = UDim2.new(1, 0, 0, 20)
CreditsLabel.Font = Enum.Font.SourceSansItalic
CreditsLabel.Text = ""
CreditsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
CreditsLabel.TextSize = 14
CreditsLabel.Visible = false


local noclipEnabled = false
local showingCredits = false
local connection


local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    StatusLabel.Text = noclipEnabled and "Status: On" or "Status: Off"

    if noclipEnabled then
        connection = game:GetService("RunService").Stepped:Connect(function()
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if connection then
            connection:Disconnect()
        end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function minimizeGui()
    if MainFrame.Size == UDim2.new(0, 250, 0, 150) then
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 30), "Out", "Sine", 0.3, true)
        for _, v in ipairs(MainFrame:GetChildren()) do
            if v ~= Title and v ~= MinimizeButton and v ~= CloseButton then
                v.Visible = false
            end
        end
    else
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 150), "Out", "Sine", 0.3, true)
        for _, v in ipairs(MainFrame:GetChildren()) do
            v.Visible = true
        end
    end
end


NoclipButton.MouseButton1Click:Connect(toggleNoclip)
MinimizeButton.MouseButton1Click:Connect(minimizeGui)
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

CreditsButton.MouseButton1Click:Connect(function()
    showingCredits = not showingCredits

    local fadeOut = TweenService:Create(CreditsButton, TweenInfo.new(0.2), {TextTransparency = 1})
    local fadeIn = TweenService:Create(CreditsButton, TweenInfo.new(0.2), {TextTransparency = 0})

    fadeOut:Play()
    fadeOut.Completed:Wait()

    CreditsButton.Text = showingCredits and "Made By HiroshiPh338" or "Credits"
    CreditsButton.TextColor3 = showingCredits and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 255, 0)

    fadeIn:Play()
end)

local function hoverEffect(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)
end

hoverEffect(NoclipButton)
hoverEffect(CreditsButton)

ScreenGui.Enabled = false
task.wait(0.1)
ScreenGui.Enabled = true
end)

Section:NewButton("esp", "by -", function()
	loadstring(game:HttpGet(('https://raw.githubusercontent.com/cool83birdcarfly02six/UNIVERSALESPLTX/main/README.md'),true))()
end)

Section:NewButton("silent aim", "by -", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Averiias/Universal-SilentAim/main/main.lua"))()
end)

Section:NewButton("fling(touch)", "by -", function()

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Frame_2 = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local TextLabel = Instance.new("TextLabel")
local TextButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local UICorner_3 = Instance.new("UICorner")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
print("sub to DuplexScripts")

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.388539821, 0, 0.427821517, 0)
Frame.Size = UDim2.new(0, 158, 0, 110)
Frame.ClipsDescendants = true
Frame.Visible = false

UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 6)

Frame_2.Parent = Frame
Frame_2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame_2.BorderSizePixel = 0
Frame_2.Size = UDim2.new(0, 158, 0, 25)

UICorner_2.Parent = Frame_2
UICorner_2.CornerRadius = UDim.new(0, 6)

TextLabel.Parent = Frame_2
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderSizePixel = 0
TextLabel.Position = UDim2.new(0.112792775, 0, -0.0151660154, 0)
TextLabel.Size = UDim2.new(0, 121, 0, 26)
TextLabel.Font = Enum.Font.Sarpanch
TextLabel.Text = "Touch Fling"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 25.000

TextButton.Parent = Frame
TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.113924049, 0, 0.418181807, 0)
TextButton.Size = UDim2.new(0, 121, 0, 37)
TextButton.Font = Enum.Font.SourceSansItalic
TextButton.Text = "OFF"
TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
TextButton.TextSize = 20.000
UICorner_3.Parent = TextButton
UICorner_3.CornerRadius = UDim.new(0, 4)

CloseButton.Parent = Frame
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.85, 0, 0.05, 0)
CloseButton.Size = UDim2.new(0, 15, 0, 15)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14.000
local UICorner_4 = Instance.new("UICorner")
UICorner_4.Parent = CloseButton
UICorner_4.CornerRadius = UDim.new(1, 0)

local function showFrame()
    Frame.Visible = true
    Frame.Size = UDim2.new(0, 0, 0, 0)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(Frame, tweenInfo, {
        Size = UDim2.new(0, 158, 0, 110),
        Position = UDim2.new(0.388539821, 0, 0.427821517, 0)
    })
    tween:Play()
end

local function hideFrame(callback)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local tween = game:GetService("TweenService"):Create(Frame, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        Frame.Visible = false
        if callback then callback() end
    end)
end

showFrame()

CloseButton.MouseButton1Click:Connect(function()
    hideFrame(function()
        ScreenGui:Destroy()
    end)
end)

local function IIMAWH_fake_script() -- TextButton.LocalScript 
	local script = Instance.new('LocalScript', TextButton)

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	
	local toggleButton = script.Parent
	local hiddenfling = false
	local flingThread 
	if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
		local detection = Instance.new("Decal")
		detection.Name = "juisdfj0i32i0eidsuf0iok"
		detection.Parent = ReplicatedStorage
	end
	
	local function fling()
		local lp = Players.LocalPlayer
		local c, hrp, vel, movel = nil, nil, nil, 0.1
	
		while hiddenfling do
			RunService.Heartbeat:Wait()
			c = lp.Character
			hrp = c and c:FindFirstChild("HumanoidRootPart")
	
			if hrp then
				vel = hrp.Velocity
				hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
				RunService.RenderStepped:Wait()
				hrp.Velocity = vel
				RunService.Stepped:Wait()
				hrp.Velocity = vel + Vector3.new(0, movel, 0)
				movel = -movel
			end
		end
	end
	
	toggleButton.MouseButton1Click:Connect(function()
		hiddenfling = not hiddenfling
		toggleButton.Text = hiddenfling and "ON" or "OFF"
	
		if hiddenfling then
			flingThread = coroutine.create(fling)
			coroutine.resume(flingThread)
		else
			hiddenfling = false
		end
	end)
	
end
coroutine.wrap(IIMAWH_fake_script)()
local function QCJQJL_fake_script() -- Frame.LocalScript 
	local script = Instance.new('LocalScript', Frame)

	script.Parent.Active = true
	script.Parent.Draggable = true
end
coroutine.wrap(QCJQJL_fake_script)()
end)

Section:NewButton("fling(all)", "by -", function()
	loadstring(game:HttpGet("https://pastebin.com/raw/zqyDSUWX"))()
end)

Section:NewButton("fling(player)", "by hellohellohell012321", function()
pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hellohellohell012321/KAWAII-FREAKY-FLING/main/kawaii_freaky_fling.lua",true))()
end)
end)

Section:NewButton("shader", "by -", function()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua'))()
end)

Section:NewButton("invisible", "by -", function()
	loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
end)

local Tab = Window:NewTab("Games")

local Section = Tab:NewSection("Game Hub")

Section:NewButton("wisl`i Universal Project", "by ", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/WislUniversal/script/refs/heads/main/Universal.lua", true))()
end)

Section:NewButton("(troll)natural disaster survival", "aura, by hellohellohell012321", function()
pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hellohellohell012321/KAWAII-AURA/main/kawaii_aura.lua", true))()
end)
end)

Section:NewButton("(troll)natural disaster survival", "bring parts, by arceusxscripts", function()


local Gui = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Box = Instance.new("TextBox")
local UICorner_2 = Instance.new("UICorner")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local Label = Instance.new("TextLabel")
local UICorner_3 = Instance.new("UICorner")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local Button = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
local CloseButton = Instance.new("TextButton")
local UICorner_5 = Instance.new("UICorner")



Gui.Name = "Gui"
Gui.Parent = gethui()
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Gui
Main.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.335954279, 0, 0.542361975, 0)
Main.Size = UDim2.new(0.240350261, 0, 0.166880623, 0)
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true

UICorner.Parent = Main
UICorner.CornerRadius = UDim.new(0.05, 0)

Box.Name = "Box"
Box.Parent = Main
Box.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
Box.BorderSizePixel = 0
Box.Position = UDim2.new(0.0980926454, 0, 0.218712583, 0)
Box.Size = UDim2.new(0.801089942, 0, 0.364963502, 0)
Box.FontFace = Font.new("rbxasset://fonts/families/SourceSansSemibold.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Box.PlaceholderText = "Player here"
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(255, 255, 255)
Box.TextScaled = true
Box.TextSize = 31.000
Box.TextWrapped = true

UICorner_2.Parent = Box
UICorner_2.CornerRadius = UDim.new(0.2, 0)

UITextSizeConstraint.Parent = Box
UITextSizeConstraint.MaxTextSize = 31

Label.Name = "Label"
Label.Parent = Main
Label.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
Label.BorderSizePixel = 0
Label.Size = UDim2.new(1, 0, 0.160583943, 0)
Label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Label.Text = "Bring Parts | t.me/arceusxscripts"
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextScaled = true
Label.TextSize = 14.000
Label.TextWrapped = true

UICorner_3.Parent = Label
UICorner_3.CornerRadius = UDim.new(0.1, 0)

UITextSizeConstraint_2.Parent = Label
UITextSizeConstraint_2.MaxTextSize = 21

Button.Name = "Button"
Button.Parent = Main
Button.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0.183284417, 0, 0.656760991, 0)
Button.Size = UDim2.new(0.629427791, 0, 0.277372271, 0)
Button.Font = Enum.Font.Nunito
Button.Text = "Off"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.TextSize = 28.000
Button.TextWrapped = true

UICorner_4.Parent = Button
UICorner_4.CornerRadius = UDim.new(0.2, 0)

UITextSizeConstraint_3.Parent = Button
UITextSizeConstraint_3.MaxTextSize = 28

CloseButton.Name = "CloseButton"
CloseButton.Parent = Main
CloseButton.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.9, 0, 0.03, 0)
CloseButton.Size = UDim2.new(0.08, 0, 0.12, 0)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true

UICorner_5.Parent = CloseButton
UICorner_5.CornerRadius = UDim.new(0.3, 0)


local TweenService = game:GetService("TweenService")

local function animateGui(visible)
    if visible then
        Main.Size = UDim2.new(0, 0, 0, 0)
        Main.Visible = true
        local tween = TweenService:Create(
            Main,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.240350261, 0, 0.166880623, 0)}
        )
        tween:Play()
    else
        local tween = TweenService:Create(
            Main,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        tween:Play()
        tween.Completed:Wait()
        Main.Visible = false
    end
end

-- Обработчик закрытия
CloseButton.MouseButton1Click:Connect(function()
    animateGui(false)
    wait(0.3)
    Gui:Destroy()
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local character
local humanoidRootPart

mainStatus = true
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
		mainStatus = not mainStatus
		animateGui(mainStatus)
	end
end)


animateGui(true)

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

if not getgenv().Network then
	getgenv().Network = {
		BaseParts = {},
		Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
	}

	Network.RetainPart = function(Part)
		if Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
			table.insert(Network.BaseParts, Part)
			Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
			Part.CanCollide = false
		end
	end

	local function EnablePartControl()
		LocalPlayer.ReplicationFocus = Workspace
		RunService.Heartbeat:Connect(function()
			sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
			for _, Part in pairs(Network.BaseParts) do
				if Part:IsDescendantOf(Workspace) then
					Part.Velocity = Network.Velocity
				end
			end
		end)
	end

	EnablePartControl()
end

local function ForcePart(v)
	if v:IsA("BasePart") and not v.Anchored and not v.Parent:FindFirstChildOfClass("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
		for _, x in ipairs(v:GetChildren()) do
			if x:IsA("BodyMover") or x:IsA("RocketPropulsion") then
				x:Destroy()
			end
		end
		if v:FindFirstChild("Attachment") then
			v:FindFirstChild("Attachment"):Destroy()
		end
		if v:FindFirstChild("AlignPosition") then
			v:FindFirstChild("AlignPosition"):Destroy()
		end
		if v:FindFirstChild("Torque") then
			v:FindFirstChild("Torque"):Destroy()
		end
		v.CanCollide = false
		local Torque = Instance.new("Torque", v)
		Torque.Torque = Vector3.new(100000, 100000, 100000)
		local AlignPosition = Instance.new("AlignPosition", v)
		local Attachment2 = Instance.new("Attachment", v)
		Torque.Attachment0 = Attachment2
		AlignPosition.MaxForce = math.huge
		AlignPosition.MaxVelocity = math.huge
		AlignPosition.Responsiveness = 200
		AlignPosition.Attachment0 = Attachment2
		AlignPosition.Attachment1 = Attachment1
	end
end

local blackHoleActive = false
local DescendantAddedConnection

local function toggleBlackHole()
	blackHoleActive = not blackHoleActive
	if blackHoleActive then
		Button.Text = "On"
		for _, v in ipairs(Workspace:GetDescendants()) do
			ForcePart(v)
		end

		DescendantAddedConnection = Workspace.DescendantAdded:Connect(function(v)
			if blackHoleActive then
				ForcePart(v)
			end
		end)

		spawn(function()
			while blackHoleActive and RunService.RenderStepped:Wait() do
				Attachment1.WorldCFrame = humanoidRootPart.CFrame
			end
		end)
	else
		Button.Text = "Off"
		if DescendantAddedConnection then
			DescendantAddedConnection:Disconnect()
		end
	end
end

local function getPlayer(name)
	local lowerName = string.lower(name)
	for _, p in pairs(Players:GetPlayers()) do
		local lowerPlayer = string.lower(p.Name)
		if string.find(lowerPlayer, lowerName) then
			return p
		elseif string.find(string.lower(p.DisplayName), lowerName) then
			return p
		end
	end
end

local player = nil

local function VDOYZQL_fake_script() -- Box.Script 
	local script = Instance.new('Script', Box)

	script.Parent.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			player = getPlayer(Box.Text)
			if player then
				Box.Text = player.Name
				print("Player found:", player.Name)
			else
				print("Player not found")
			end
		end
	end)
end
coroutine.wrap(VDOYZQL_fake_script)()
local function JUBNQKI_fake_script() -- Button.Script 
	local script = Instance.new('Script', Button)

	script.Parent.MouseButton1Click:Connect(function()
		if player then
			character = player.Character or player.CharacterAdded:Wait()
			humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			toggleBlackHole()
		else
			print("Player is not selected")
		end
	end)
end
coroutine.wrap(JUBNQKI_fake_script)()
end)

Section:NewButton("Cursed Islands", "by -", function()
loadstring(game:HttpGet("https://pastefy.app/U8AcaO9B/raw?part="))()
end)

Section:NewButton("Lucky Block", "by venyx", function()
loadstring(game:HttpGet("https://pastebin.com/raw/JbWJ7R7i", true))()
end)

Section:NewButton("Blox Strick", "by -", function()
loadstring(game:HttpGet("https://rawscripts.net/raw/BETA-BloxStrike-Expectional-Dev-Aimbot-ESP-Visuals-Skinchanger-UNDETECTED-75224"))()
end)

Section:NewButton("Blind Shot", "by Deity , Abstract", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/lattereal/blindshot/refs/heads/main/yes.lua"))()
end)

Section:NewButton("Npc or Die", "by sigmatik323", function()
loadstring(game:HttpGet("https://rawscripts.net/raw/MAP-NPC-or-DIE!-ESP-AimBot-AutoFarm-money-AutoFarm-Obby-59844"))()
end)

Section:NewButton("Murder VS Sheriff Duels", "by Zephyr", function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheRealAvrwm/Zephyr-V2/refs/heads/main/ZephyrV2", true))()
end)

Section:NewButton("Seeker vs Hider", "by -", function()
loadstring(game:HttpGet("https://pastefy.app/ixEuvQVd/raw"))()
end)

local Tab = Window:NewTab("Settings")

local Section = Tab:NewSection("Settings")

Section:NewKeybind("HideGUI", "HIDE GUI", Enum.KeyCode.CapsLock, function()
    Library:ToggleUI()
end)