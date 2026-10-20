--[[
	Zibvabva Hub — Material You версия.
	Быстрая загрузка: никаких интро/внешних библиотек, интерфейс собирается за один проход
	и подключается к экрану одним Parent. Скрипты (HttpGet) грузятся только по нажатию кнопки.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local NAME = "UniversalScriptHub"
local VERSION = "0.4 beta"
local SCRIPT_URL = "https://raw.githubusercontent.com/babyun42/Zibvabva/refs/heads/main/Univeral.lua"
local GITHUB_URL = "https://github.com/babyun42"
local WIDTH, HEIGHT = 850, 420
local MIN_WIDTH, MIN_HEIGHT = 420, 64

-- ---------------------------------------------------------------------------
-- Куда класть интерфейс + удаление старой копии
-- ---------------------------------------------------------------------------
local function hostGui()
	local ok, ui = pcall(function()
		return (gethui and gethui()) or CoreGui
	end)
	return ok and ui or LocalPlayer:WaitForChild("PlayerGui")
end

for _, place in ipairs({ CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
	pcall(function()
		local old = place and place:FindFirstChild(NAME)
		if old then
			old:Destroy()
		end
	end)
end
pcall(function()
	local old = hostGui():FindFirstChild(NAME)
	if old then
		old:Destroy()
	end
end)

-- ---------------------------------------------------------------------------
-- Цветовые схемы Material 3 (seed — синий)
-- ---------------------------------------------------------------------------
local function hex(h)
	return Color3.fromRGB(math.floor(h / 65536) % 256, math.floor(h / 256) % 256, h % 256)
end

local SCHEMES = {
	light = {
		surface = hex(0xF9F9FF),
		surfaceContainer = hex(0xEDEDF4),
		surfaceContainerHigh = hex(0xE7E8EE),
		onSurface = hex(0x191C20),
		onSurfaceVariant = hex(0x43474E),
		outlineVariant = hex(0xC3C6CF),
		primary = hex(0x415F91),
		onPrimary = hex(0xFFFFFF),
		primaryContainer = hex(0xD6E3FF),
		onPrimaryContainer = hex(0x001B3E),
		secondaryContainer = hex(0xDBE2F9),
		onSecondaryContainer = hex(0x141B2C),
		inverseSurface = hex(0x2E3036),
		inverseOnSurface = hex(0xF0F0F7),
	},
	dark = {
		surface = hex(0x111318),
		surfaceContainer = hex(0x1D2024),
		surfaceContainerHigh = hex(0x282A2F),
		onSurface = hex(0xE2E2E9),
		onSurfaceVariant = hex(0xC4C6D0),
		outlineVariant = hex(0x44474E),
		primary = hex(0xAAC7FF),
		onPrimary = hex(0x0A305F),
		primaryContainer = hex(0x284777),
		onPrimaryContainer = hex(0xD6E3FF),
		secondaryContainer = hex(0x3E4759),
		onSecondaryContainer = hex(0xDBE2F9),
		inverseSurface = hex(0xE2E2E9),
		inverseOnSurface = hex(0x2E3036),
	},
}

local isDark = false
local C = SCHEMES.light
local bindings = {}

local function bind(inst, prop, role)
	bindings[#bindings + 1] = { inst, prop, role }
	inst[prop] = C[role]
end

local function refresh(animate)
	C = isDark and SCHEMES.dark or SCHEMES.light
	local info = TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, b in ipairs(bindings) do
		if animate then
			TweenService:Create(b[1], info, { [b[2]] = C[b[3]] }):Play()
		else
			b[1][b[2]] = C[b[3]]
		end
	end
end

-- ---------------------------------------------------------------------------
-- Мелкие помощники
-- ---------------------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(inst, r)
	return new("UICorner", { CornerRadius = r == "full" and UDim.new(.5, 0) or UDim.new(0, r) }, inst)
end

local function tween(inst, t, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function label(parent, p, role)
	p.BackgroundTransparency = p.BackgroundTransparency or 1
	p.Font = p.Font or Enum.Font.Gotham
	p.TextSize = p.TextSize or 14
	p.TextXAlignment = p.TextXAlignment or Enum.TextXAlignment.Left
	p.Text = p.Text or ""
	local l = new("TextLabel", p, parent)
	if role then
		bind(l, "TextColor3", role)
	end
	return l
end

local function button(parent, p)
	p.Text = ""
	p.AutoButtonColor = false
	return new("TextButton", p, parent)
end

-- слой состояния (hover / нажатие) поверх кнопки
local function stateLayer(btn, role, radius)
	local o = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, btn)
	bind(o, "BackgroundColor3", role)
	corner(o, radius)
	local inside = false
	btn.MouseEnter:Connect(function()
		inside = true
		tween(o, .15, { BackgroundTransparency = .92 })
	end)
	btn.MouseLeave:Connect(function()
		inside = false
		tween(o, .2, { BackgroundTransparency = 1 })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(o, .1, { BackgroundTransparency = .84 })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(o, .15, { BackgroundTransparency = inside and .92 or 1 })
	end)
	return o
end

-- ---------------------------------------------------------------------------
-- Окно
-- ---------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)

local wrap = new("Frame", {
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	BackgroundTransparency = 1,
}, gui)

-- масштаб под маленькие экраны (телефон)
local fit = new("UIScale", {}, wrap)
local cam = workspace.CurrentCamera
local function updateFit()
	if cam then
		local v = cam.ViewportSize
		fit.Scale = math.clamp(math.min((v.X - 24) / WIDTH, (v.Y - 24) / HEIGHT), .5, 1)
	end
end
updateFit()
if cam then
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit)
end

local main = new("Frame", {
	AnchorPoint = Vector2.new(.5, 0),
	Position = UDim2.fromScale(.5, 0),
	Size = UDim2.fromScale(1, 1),
	ClipsDescendants = true,
}, wrap)
bind(main, "BackgroundColor3", "surface")
corner(main, 28)
local mainStroke = new("UIStroke", { Thickness = 1 }, main)
bind(mainStroke, "Color", "outlineVariant")
local pop = new("UIScale", { Scale = .001 }, main)

-- ---- шапка ----------------------------------------------------------------
local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64) }, main)

-- логотип: «печенье» из двух повёрнутых скруглённых квадратов
local logo = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(24, 14),
	Size = UDim2.fromOffset(36, 36),
}, header)
for _, rot in ipairs({ 0, 45 }) do
	local sq = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(25, 25),
		Rotation = rot,
	}, logo)
	bind(sq, "BackgroundColor3", "primary")
	corner(sq, 8)
end
local logoDot = new("Frame", {
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(9, 9),
}, logo)
bind(logoDot, "BackgroundColor3", "onPrimary")
corner(logoDot, "full")

label(header, {
	Text = "Welcome, " .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. "!",
	Font = Enum.Font.GothamMedium,
	TextSize = 18,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(74, 11),
	Size = UDim2.new(1, -250, 0, 24),
}, "onSurface")
label(header, {
	Text = "Zibvabva Hub  •  Universal Script",
	TextSize = 12,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(74, 35),
	Size = UDim2.new(1, -250, 0, 16),
}, "onSurfaceVariant")

-- чип версии
local chip = label(header, {
	Text = VERSION,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	BackgroundTransparency = 0,
	TextXAlignment = Enum.TextXAlignment.Center,
	AnchorPoint = Vector2.new(1, .5),
	Position = UDim2.new(1, -150, .5, 0),
	Size = UDim2.fromOffset(0, 26),
	AutomaticSize = Enum.AutomaticSize.X,
}, "onSecondaryContainer")
bind(chip, "BackgroundColor3", "secondaryContainer")
corner(chip, 8)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, chip)

-- кнопки окна: при наведении подсветка случайной Material-формы
local controls = new("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, .5),
	Position = UDim2.new(1, -16, .5, 0),
	Size = UDim2.fromOffset(124, 40),
}, header)

local HOVER_SHAPES = {
	{ r = 16, rot = 0, s = 32 },
	{ r = 10, rot = 0, s = 30 },
	{ r = 9, rot = 45, s = 25 },
	{ r = 12, rot = 20, s = 28 },
	{ r = 14, rot = -15, s = 30 },
}

local function iconButton(x, build, callback)
	local b = button(controls, { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(40, 40) })
	local o = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
	}, b)
	bind(o, "BackgroundColor3", "onSurface")
	local oc = corner(o, 16)
	local inside = false
	b.MouseEnter:Connect(function()
		inside = true
		local s = HOVER_SHAPES[math.random(#HOVER_SHAPES)]
		oc.CornerRadius = UDim.new(0, s.r)
		o.Size = UDim2.fromOffset(s.s - 6, s.s - 6)
		o.Rotation = s.rot - 40
		tween(o, .3, { Size = UDim2.fromOffset(s.s, s.s), Rotation = s.rot, BackgroundTransparency = .88 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		inside = false
		tween(o, .2, { BackgroundTransparency = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		tween(o, .1, { BackgroundTransparency = .8 })
	end)
	b.MouseButton1Up:Connect(function()
		tween(o, .15, { BackgroundTransparency = inside and .88 or 1 })
	end)
	b.MouseButton1Click:Connect(callback)
	return b, build(b)
end

local function bar(parent, w, rot)
	local f = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(w, 2),
		Rotation = rot,
	}, parent)
	bind(f, "BackgroundColor3", "onSurfaceVariant")
	corner(f, "full")
end

local isMinimized = false
local content -- создаётся ниже
local snackbar, showSnack -- создаются ниже

local _, themeIcon = iconButton(0, function(b)
	return label(b, {
		Text = "☀",
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
	}, "onSurfaceVariant")
end, function()
	isDark = not isDark
	refresh(true)
	-- иконка показывает, какая тема включена
end)

local function updateThemeIcon()
	themeIcon.Text = isDark and "🌙" or "☀"
end
updateThemeIcon()
-- перепривязываем клик темы так, чтобы он ещё обновлял иконку
do
	local b = themeIcon.Parent
	b.MouseButton1Click:Connect(updateThemeIcon)
end

iconButton(40, function(b)
	bar(b, 12, 0)
end, function()
	isMinimized = not isMinimized
	if isMinimized then
		chip.Visible = false
		tween(main, .35, { Size = UDim2.fromOffset(MIN_WIDTH, MIN_HEIGHT) })
		task.delay(.2, function()
			if isMinimized then
				content.Visible = false
			end
		end)
	else
		content.Visible = true
		chip.Visible = true
		tween(main, .4, { Size = UDim2.fromScale(1, 1) })
	end
end)

local conns = {}
local closing = false
local function closeHub()
	if closing then
		return
	end
	closing = true
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	-- сначала чуть «набухает», затем схлопывается в точку и исчезает
	tween(pop, .35, { Scale = .001 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.delay(.37, function()
		gui:Destroy()
	end)
end

iconButton(80, function(b)
	bar(b, 14, 45)
	bar(b, 14, -45)
end, closeHub)

-- ---- содержимое -------------------------------------------------------------
content = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 64),
	Size = UDim2.new(1, 0, 1, -64),
}, main)

local row = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(24, 8),
	Size = UDim2.new(1, -48, 0, 96),
}, content)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, row)

local function bigButton(o)
	local fg = o.primary and "onPrimary" or "onSecondaryContainer"
	local b = button(row, {
		Size = UDim2.new(1 / 3, -8, 1, 0),
		LayoutOrder = o.order,
	})
	bind(b, "BackgroundColor3", o.primary and "primary" or "secondaryContainer")
	corner(b, 24)

	-- декоративная фигура-«печенье» в углу: рисуется непрозрачной в CanvasGroup,
	-- а прозрачность задаётся группе целиком (нет тёмного шва в месте наложения)
	-- и фигура целиком лежит внутри скруглённого угла
	local deco = new("CanvasGroup", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.new(1, -44, 1, -40),
		Size = UDim2.fromOffset(64, 64),
		GroupTransparency = .86,
	}, b)
	for _, rot in ipairs({ 0, 45 }) do
		local d = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(.5, .5),
			Size = UDim2.fromOffset(38, 38),
			Rotation = rot,
		}, deco)
		bind(d, "BackgroundColor3", fg)
		corner(d, 12)
	end

	stateLayer(b, fg, 24)
	local t = label(b, {
		Text = o.title,
		RichText = true,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.new(1, -40, 0, 22),
	}, fg)
	local s = label(b, {
		Text = o.sub,
		RichText = true,
		TextSize = 11,
		Position = UDim2.fromOffset(20, 46),
		Size = UDim2.new(1, -40, 0, 30),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, fg)
	if not o.primary then
		t.TextTransparency = .35
		s.TextTransparency = .4
	end
	b.MouseButton1Click:Connect(function()
		o.callback(b, s)
	end)
	return b
end

local loading = false
bigButton({
	order = 1,
	primary = true,
	title = "UNIVERSAL SCRIPT",
	sub = "My Universal Script - The main hub",
	callback = function(_, sub)
		if loading then
			return
		end
		loading = true
		local old = sub.Text
		sub.Text = "Loading..."
		task.spawn(function()
			local ok = pcall(function()
				loadstring(game:HttpGet(SCRIPT_URL))()
			end)
			sub.Text = old
			loading = false
			showSnack(ok and "Script loaded" or "Failed to load script")
		end)
	end,
})
bigButton({
	order = 2,
	title = "<s>OTHER HUBS</s>",
	sub = "Explore Community Hubs",
	callback = function()
		showSnack("Coming soon")
	end,
})
bigButton({
	order = 3,
	title = "<s>OTHER SCRIPTS</s>",
	sub = "Discover Utility Scripts",
	callback = function()
		showSnack("Coming soon")
	end,
})

label(content, {
	Text = "ABOUT ZIBVABVA HUB",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	Position = UDim2.fromOffset(30, 122),
	Size = UDim2.new(1, -60, 0, 20),
}, "primary")

local cards = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(24, 148),
	Size = UDim2.new(1, -48, 0, 184),
}, content)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, cards)

local function card(title, order)
	local f = new("Frame", { Size = UDim2.new(1 / 3, -8, 1, 0), LayoutOrder = order }, cards)
	bind(f, "BackgroundColor3", "surfaceContainerHigh")
	corner(f, 20)
	label(f, {
		Text = title,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		Position = UDim2.fromOffset(18, 14),
		Size = UDim2.new(1, -36, 0, 22),
	}, "onSurface")
	local body = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 46),
		Size = UDim2.new(1, -36, 1, -58),
	}, f)
	return body
end

-- Hub Info
local info = card("Hub Info", 1)
label(info, {
	Text = "• Cloud Configuration\n• Modern Material 3 UI\n• Execution Protection\n• Regular Script Sync\n• Direct Load Injection\n• Clean Script Framework",
	TextSize = 12,
	LineHeight = 1.35,
	TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.fromScale(1, 1),
}, "onSurfaceVariant")

-- Executor Info
local exploitName = "Unknown"
pcall(function()
	exploitName = (identifyexecutor and select(1, identifyexecutor())) or (getexecutorname and getexecutorname()) or "Unknown"
end)
local platformName = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and "Mobile" or "PC"

local ex = card("Executor Info", 2)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, ex)
local function pair(cap, val, order)
	label(ex, { Text = cap, TextSize = 11, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = order * 2 - 1 }, "onSurfaceVariant")
	label(ex, {
		Text = val,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order * 2,
	}, "onSurface")
end
pair("CURRENT EXECUTOR", exploitName, 1)
pair("CURRENT SYSTEM", platformName, 2)
pair("STATUS", "Active", 3)

-- About Me
local about = card("About Me", 3)
local gh = button(about, { Size = UDim2.new(1, 0, 0, 40) })
bind(gh, "BackgroundColor3", "secondaryContainer")
corner(gh, "full")
stateLayer(gh, "onSecondaryContainer", 20)
local ghText = label(gh, {
	Text = "My GitHub",
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromScale(1, 1),
}, "onSecondaryContainer")
label(about, {
	Text = "Click the button to copy the link to your clipboard.",
	TextSize = 11,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromOffset(4, 52),
	Size = UDim2.new(1, -8, 0, 40),
}, "onSurfaceVariant")

local ghBusy = false
gh.MouseButton1Click:Connect(function()
	if ghBusy then
		return
	end
	ghBusy = true
	if setclipboard then
		setclipboard(GITHUB_URL)
		ghText.Text = "✅ Copied!"
	else
		ghText.Text = "❌ Executor unsupported"
	end
	task.delay(1.5, function()
		ghText.Text = "🐙 My GitHub"
		ghBusy = false
	end)
end)

-- ---- snackbar ---------------------------------------------------------------
snackbar = new("Frame", {
	AnchorPoint = Vector2.new(.5, 1),
	Position = UDim2.new(.5, 0, 1, 70),
	Size = UDim2.fromOffset(300, 48),
	ZIndex = 20,
}, main)
bind(snackbar, "BackgroundColor3", "primaryContainer")
corner(snackbar, 12)
local snackText = label(snackbar, {
	TextSize = 13,
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(1, -36, 1, 0),
	ZIndex = 21,
}, "onPrimaryContainer")
local snackToken = 0
showSnack = function(msg)
	snackToken += 1
	local mine = snackToken
	snackText.Text = msg
	tween(snackbar, .35, { Position = UDim2.new(.5, 0, 1, -20) }, Enum.EasingStyle.Back)
	task.delay(2.4, function()
		if mine == snackToken then
			tween(snackbar, .25, { Position = UDim2.new(.5, 0, 1, 70) })
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Перетаскивание за шапку
-- ---------------------------------------------------------------------------
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = wrap.Position
	end
end)
conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		wrap.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
conns[#conns + 1] = UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ---------------------------------------------------------------------------
-- Запуск
-- ---------------------------------------------------------------------------
refresh(false)

local ok = pcall(function()
	gui.Parent = hostGui()
end)
if not ok then
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

tween(pop, .55, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- появление «бульком»
