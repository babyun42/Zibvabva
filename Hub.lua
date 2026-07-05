local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("UniversalScriptHub") then
    CoreGui.UniversalScriptHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalScriptHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local guiTransparency = 0.067 
local isDarkMode = false
local isMinimized = false

local function roundCorners(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local themeElements = {
    Cards = {},
    Titles = {},
    Subtexts = {},
    Buttons = {},
    Lines = {}
}

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundTransparency = guiTransparency
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
roundCorners(MainFrame, 12)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundTransparency = guiTransparency
TopBar.Parent = MainFrame
roundCorners(TopBar, 12)

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 10)
TopBarFix.Position = UDim2.new(0, 0, 1, -10)
TopBarFix.BorderSizePixel = 0
TopBarFix.BackgroundTransparency = guiTransparency
TopBarFix.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 300, 1, 0)
TitleLabel.Position = UDim2.new(0, 25, 0, 0)
TitleLabel.Text = "Welcome, " .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. "!"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BackgroundTransparency = 1
TitleLabel.Parent = TopBar
table.insert(themeElements.Titles, TitleLabel)

local WindowControls = Instance.new("Frame")
WindowControls.Size = UDim2.new(0, 120, 1, 0)
WindowControls.Position = UDim2.new(1, -120, 0, 0)
WindowControls.BackgroundTransparency = 1
WindowControls.Parent = TopBar

local function createWindowBtn(text, posX, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.BackgroundTransparency = 1
    btn.Parent = WindowControls
    table.insert(themeElements.Subtexts, btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local ThemeBtn = createWindowBtn("🌙", 0, function()
    isDarkMode = not isDarkMode
    UpdateTheme()
end)

local unminimizedSize = UDim2.new(0, 850, 0, 480)

local MinimizeBtn = createWindowBtn("-", 40, function()
    isMinimized = not isMinimized
    
    if isMinimized then
        unminimizedSize = MainFrame.Size 
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 350, 0, 45)
        }):Play()
        TweenService:Create(TopBarFix, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = unminimizedSize
        }):Play()
        TweenService:Create(TopBarFix, TweenInfo.new(0.3), {BackgroundTransparency = guiTransparency}):Play()
    end
end)

local CloseBtn = createWindowBtn("x", 80, function()
    local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    tw:Play()
    tw.Completed:Wait()
    ScreenGui:Destroy()
end)

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -45)
ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local ButtonsRow = Instance.new("Frame")
ButtonsRow.Size = UDim2.new(1, -50, 0, 90)
ButtonsRow.Position = UDim2.new(0, 25, 0, 20)
ButtonsRow.BackgroundTransparency = 1
ButtonsRow.Parent = ContentFrame

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 15)
rowLayout.Parent = ButtonsRow

local function createBigButton(title, sub, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 256, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(26, 92, 198)
    btn.Text = ""
    btn.Parent = ButtonsRow
    roundCorners(btn, 16)
    
    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, 0, 0, 30)
    tLabel.Position = UDim2.new(0, 0, 0, 20)
    tLabel.Text = title
    tLabel.RichText = true
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextSize = 16
    tLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tLabel.BackgroundTransparency = 1
    tLabel.Parent = btn
    
    local sLabel = Instance.new("TextLabel")
    sLabel.Size = UDim2.new(1, 0, 0, 20)
    sLabel.Position = UDim2.new(0, 0, 0, 45)
    sLabel.Text = sub
    sLabel.RichText = true 
    sLabel.Font = Enum.Font.Gotham
    sLabel.TextSize = 11
    sLabel.TextColor3 = Color3.fromRGB(210, 225, 255)
    sLabel.BackgroundTransparency = 1
    sLabel.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- Основная кнопка
createBigButton("UNIVERSAL SCRIPT", "My Universal Script - The main hub", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/babyun42/Zibvabva/refs/heads/main/Univeral.lua"))()
    end)
end)

createBigButton("<s>OTHER HUBS</s>", "Explore Community Hubs", function() end)
createBigButton("<s>OTHER SCRIPTS</s>", "Discover Utility Scripts", function() end)

local DividerLine = Instance.new("Frame")
DividerLine.Size = UDim2.new(1, -50, 0, 1)
DividerLine.Position = UDim2.new(0, 25, 0, 125)
DividerLine.BorderSizePixel = 0
DividerLine.Parent = ContentFrame
table.insert(themeElements.Lines, DividerLine)

local SectionTitle = Instance.new("TextLabel")
SectionTitle.Size = UDim2.new(1, -50, 0, 30)
SectionTitle.Position = UDim2.new(0, 25, 0, 140)
SectionTitle.Text = "ABOUT Zibvabva HUB"
SectionTitle.Font = Enum.Font.GothamBold
SectionTitle.TextSize = 14
SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
SectionTitle.BackgroundTransparency = 1
SectionTitle.Parent = ContentFrame
table.insert(themeElements.Titles, SectionTitle)

local CardsContainer = Instance.new("Frame")
CardsContainer.Size = UDim2.new(1, -50, 0, 240)
CardsContainer.Position = UDim2.new(0, 25, 0, 175)
CardsContainer.BackgroundTransparency = 1
CardsContainer.Parent = ContentFrame

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.Padding = UDim.new(0, 15)
cardsLayout.Parent = CardsContainer

local function createCard(title, sizeX, contentText)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, sizeX, 1, 0)
    card.BackgroundTransparency = guiTransparency
    card.Parent = CardsContainer
    roundCorners(card, 16)
    table.insert(themeElements.Cards, card)
    
    local cTitle = Instance.new("TextLabel")
    cTitle.Size = UDim2.new(1, -20, 0, 30)
    cTitle.Position = UDim2.new(0, 15, 0, 10)
    cTitle.Text = title
    cTitle.Font = Enum.Font.GothamBold
    cTitle.TextSize = 15
    cTitle.TextXAlignment = Enum.TextXAlignment.Left
    cTitle.BackgroundTransparency = 1
    cTitle.Parent = card
    table.insert(themeElements.Titles, cTitle)
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -30, 1, -50)
    desc.Position = UDim2.new(0, 15, 0, 45)
    desc.Text = contentText
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 12
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.LineHeight = 1.3
    desc.BackgroundTransparency = 1
    desc.Parent = card
    table.insert(themeElements.Subtexts, desc)
    
    return card
end

local card2 = createCard("Hub Info", 190, "• Cloud Configuration\n• Modern Material 3 UI\n• Execution Protection\n• Regular Script Sync\n• Direct Load Injection\n• Clean Script Framework")

local exploitName = (identifyexecutor and select(1, identifyexecutor())) or (getexecutorname and getexecutorname()) or "Unknown"
local platformName = UserInputService:GetPlatform() == Enum.Platform.Android and "Android Mobile" or "PC (Windows)"
local card3 = createCard("Executor Info", 210, "CURRENT EXECUTOR:\n• " .. exploitName .. "\n\nCURRENT SYSTEM:\n• " .. platformName .. "\n\nSTATUS:\n• Active")
local card4 = createCard("About Me", 170, "")

local GithubBtn = Instance.new("TextButton")
GithubBtn.Size = UDim2.new(1, -30, 0, 20)
GithubBtn.Position = UDim2.new(0, 15, 0, 40)
GithubBtn.BackgroundTransparency = 1
GithubBtn.Text = "🐙 My GitHub (Click)"
GithubBtn.Font = Enum.Font.Gotham
GithubBtn.TextSize = 12
GithubBtn.TextXAlignment = Enum.TextXAlignment.Left
GithubBtn.Parent = card4
table.insert(themeElements.Subtexts, GithubBtn)

GithubBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard("https://github.com/babyun42") 
        GithubBtn.Text = "✅ Copied to clipboard!"
        task.wait(1.5)
        GithubBtn.Text = "🐙 My GitHub (Click)"
    else
        GithubBtn.Text = "❌ Error: Executor unsupported"
        task.wait(1.5)
        GithubBtn.Text = "🐙 My GitHub (Click)"
    end
end)

local dragging, dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if resizing then return end 
        
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)


function UpdateTheme()
    local Colors = {
        MainBG = isDarkMode and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(240, 244, 248),
        TopBG = isDarkMode and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(220, 225, 230),
        CardBG = isDarkMode and Color3.fromRGB(40, 40, 45) or Color3.fromRGB(255, 255, 255),
        TextPrimary = isDarkMode and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(28, 27, 31),
        TextSecondary = isDarkMode and Color3.fromRGB(160, 160, 165) or Color3.fromRGB(90, 90, 90),
        LineColor = isDarkMode and Color3.fromRGB(50, 50, 55) or Color3.fromRGB(210, 215, 220)
    }

    ThemeBtn.Text = isDarkMode and "🌙" or "☀"

    TweenService:Create(MainFrame, TweenInfo.new(0.3), {BackgroundColor3 = Colors.MainBG}):Play()
    TweenService:Create(TopBar, TweenInfo.new(0.3), {BackgroundColor3 = Colors.TopBG}):Play()
    TweenService:Create(TopBarFix, TweenInfo.new(0.3), {BackgroundColor3 = Colors.TopBG}):Play()

    for _, card in ipairs(themeElements.Cards) do
        TweenService:Create(card, TweenInfo.new(0.3), {BackgroundColor3 = Colors.CardBG}):Play()
    end
    for _, line in ipairs(themeElements.Lines) do
        TweenService:Create(line, TweenInfo.new(0.3), {BackgroundColor3 = Colors.LineColor}):Play()
    end
    for _, text in ipairs(themeElements.Titles) do
        text.TextColor3 = Colors.TextPrimary
    end
    for _, sub in ipairs(themeElements.Subtexts) do
        sub.TextColor3 = Colors.TextSecondary
    end
end

UpdateTheme()

local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = unminimizedSize
})
openTween:Play()
