--[[
	Material You UI  —  библиотека GUI для Roblox (Luau)

	Возможности:
	  • Окно: шапка, вкладки (сайдбар), перетаскивание, свернуть/развернуть/закрыть
	  • Элементы: Section, Toggle, Button, Slider (змейка), Dropdown, Keybind, Input, Folder, Label, ESP Preview
	  • Темы: Dark, Light, Ocean, Rose, Forest, Sunset, Lavender
	  • Вступительная анимация: прокрутка фигур -> свап -> окно
	  • ESP Preview: интерактивный R6 манекен с ghost-режимом и клик-тумблерами
	  • Все фигуры рисуются из Frame + UICorner (никаких ассетов не нужно)

	Использование: см. example.lua
]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local UI = {}
local Window = {}
Window.__index = Window
local Container = {}
Container.__index = Container

local FULL = UDim.new(1, 0)
local Quint, Quart, Back, Cubic = Enum.EasingStyle.Quint, Enum.EasingStyle.Quart, Enum.EasingStyle.Back, Enum.EasingStyle.Cubic
local Out, In, InOut = Enum.EasingDirection.Out, Enum.EasingDirection.In, Enum.EasingDirection.InOut

-- ============================================================
--  Утилиты
-- ============================================================

local function tween(inst, time, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Quint, dir or Out), props)
	tw:Play()
	return tw
end

local function apply(inst, props, animate, time)
	if animate then
		tween(inst, time or 0.2, props)
	else
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
end

local function new(class, props)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			o[k] = v
		end
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(parent, r)
	return new("UICorner", {
		CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r),
		Parent = parent,
	})
end

local function pad(parent, l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = parent,
	})
end

local function text(props)
	local d = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	}
	for k, v in pairs(props) do
		d[k] = v
	end
	return new("TextLabel", d)
end

local function hsv(h, s, v)
	return Color3.fromHSV(h % 1, math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

local function shuffled(list)
	local t = table.clone(list)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

-- ============================================================
--  Темы
-- ============================================================

local function buildScheme(theme)
	local h = theme.seed:ToHSV()
	if theme.dark then
		return {
			background = hsv(h, .30, .08),
			surface = hsv(h, .30, .10),
			surfaceContainer = hsv(h, .28, .14),
			surfaceContainerHigh = hsv(h, .26, .18),
			surfaceContainerHighest = hsv(h, .24, .22),
			primary = hsv(h, .38, .98),
			onPrimary = hsv(h, .80, .28),
			primaryContainer = hsv(h, .65, .42),
			onPrimaryContainer = hsv(h, .12, 1),
			secondaryContainer = hsv(h, .40, .32),
			onSecondaryContainer = hsv(h, .14, .96),
			tertiary = hsv(h + .10, .40, .98),
			onSurface = hsv(h, .06, .92),
			onSurfaceVariant = hsv(h, .12, .76),
			outline = hsv(h, .12, .55),
			outlineVariant = hsv(h, .16, .30),
			inverseSurface = hsv(h, .08, .90),
			inverseOnSurface = hsv(h, .25, .16),
		}
	else
		return {
			background = hsv(h, .04, .99),
			surface = hsv(h, .04, .985),
			surfaceContainer = hsv(h, .07, .955),
			surfaceContainerHigh = hsv(h, .09, .93),
			surfaceContainerHighest = hsv(h, .11, .905),
			primary = hsv(h, .64, .62),
			onPrimary = hsv(0, 0, 1),
			primaryContainer = hsv(h, .22, .99),
			onPrimaryContainer = hsv(h, .92, .30),
			secondaryContainer = hsv(h, .16, .96),
			onSecondaryContainer = hsv(h, .75, .30),
			tertiary = hsv(h + .10, .55, .75),
			onSurface = hsv(h, .12, .12),
			onSurfaceVariant = hsv(h, .14, .36),
			outline = hsv(h, .10, .48),
			outlineVariant = hsv(h, .12, .78),
			inverseSurface = hsv(h, .15, .20),
			inverseOnSurface = hsv(h, .05, .96),
		}
	end
end

UI.Themes = {
	Dark = { seed = Color3.fromHSV(.52, 1, 1), dark = true },
	Light = { seed = Color3.fromHSV(.60, 1, 1), dark = false },
	Ocean = { seed = Color3.fromHSV(.58, 1, 1), dark = true },
	Rose = { seed = Color3.fromHSV(.93, 1, 1), dark = true },
	Forest = { seed = Color3.fromHSV(.33, 1, 1), dark = true },
	Sunset = { seed = Color3.fromHSV(.07, 1, 1), dark = true },
	Lavender = { seed = Color3.fromHSV(.73, 1, 1), dark = false },
}
UI.ThemeOrder = { "Dark", "Light", "Ocean", "Rose", "Forest", "Sunset", "Lavender" }

-- ============================================================
--  Сохранение выбранной темы
-- ============================================================
local THEME_FILE = "MaterialYouUI_theme.txt"

local function isFsAvailable()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
end

local function loadSavedTheme()
	if not isFsAvailable() then return nil end
	local ok, data = pcall(function()
		if isfile(THEME_FILE) then
			return readfile(THEME_FILE)
		end
	end)
	if ok and data and data ~= "" then
		return (data:gsub("%s+", ""))
	end
	return nil
end

local function saveThemeName(name)
	if not isFsAvailable() then return end
	pcall(function() writefile(THEME_FILE, name) end)
end

function UI:AddTheme(name, seedColor, isDark)
	if not UI.Themes[name] then
		table.insert(UI.ThemeOrder, name)
	end
	UI.Themes[name] = { seed = seedColor, dark = isDark ~= false }
end

-- ============================================================
--  Фигуры Material You
-- ============================================================

local function P(cx, cy, w, h, rot, c)
	return { cx, cy, w, h, rot or 0, c or 0 }
end

local function Cl(cx, cy, w, h, part)
	part.clip = { cx, cy, w, h }
	return part
end

local function ring(n, ringR, lobeD, centerD, rotOff)
	local s = { P(.5, .5, centerD, centerD, 0, .5) }
	for i = 0, n - 1 do
		local a = math.rad(i * 360 / n + (rotOff or 0))
		s[#s + 1] = P(.5 + math.cos(a) * ringR, .5 + math.sin(a) * ringR, lobeD, lobeD, 0, .5)
	end
	return s
end

local function petals(n, w, h)
	local s = {}
	for i = 0, n - 1 do
		s[#s + 1] = P(.5, .5, w, h, i * 180 / n, .5)
	end
	return s
end

local function stars(n, size, c)
	local s = {}
	for i = 0, n - 1 do
		s[#s + 1] = P(.5, .5, size, size, i * 90 / n, c)
	end
	return s
end

local function triangleSpec()
	local s, N = {}, 34
	local top, bot, hw = .12, .88, .44
	for i = 0, N - 1 do
		local yc = top + (bot - top) * (i + .5) / N
		local w = math.max(2 * hw * (yc - top) / (bot - top), .07)
		s[#s + 1] = P(.5, yc, w, (bot - top) / N + .012, 0, .5)
	end
	return s
end

local function boomSpec()
	local s = {}
	for i = 0, 5 do
		s[#s + 1] = P(.5, .5, .98, .08, i * 30, .5)
	end
	s[#s + 1] = P(.5, .5, .36, .36, 0, .5)
	return s
end

local function pixelCircle()
	local s, n, S = {}, 9, .92
	for r = 0, n - 1 do
		local dy = (r + .5) - n / 2
		local half = math.sqrt(math.max((n / 2) ^ 2 - dy * dy, 0))
		local cells = math.max(1, 2 * math.floor(half - .5) + 1)
		local cell = S / n
		s[#s + 1] = P(.5, (1 - S) / 2 + (r + .5) * cell, cells * cell, cell + .006, 0, 0)
	end
	return s
end

local function pixelTriangle()
	local s, n, S = {}, 6, .88
	for c = 0, n - 1 do
		local cell = S / n
		s[#s + 1] = P((1 - S) / 2 + (c + .5) * cell, .5, cell + .006, S * (n - c) / n, 0, 0)
	end
	return s
end

local ShapeSpecs, ShapeOrder = {}, {}
local function reg(name, spec)
	if not ShapeSpecs[name] then
		table.insert(ShapeOrder, name)
	end
	ShapeSpecs[name] = spec
end

reg("Circle", { P(.5, .5, .94, .94, 0, .5) })
reg("Square", { P(.5, .5, .86, .86, 0, .28) })
reg("Slanted", { P(.5, .5, .8, .86, 10, .22) })
reg("Arch", { P(.5, .5, .84, .9, 0, .5), P(.5, .74, .84, .42, 0, .14) })
reg("Semicircle", { Cl(.5, .5, .96, .48, P(.5, .74, .96, .96, 0, .5)) })
reg("Oval", { P(.5, .5, .9, .64, -35, .5) })
reg("Pill", { P(.5, .5, .98, .5, -40, .5) })
reg("Triangle", triangleSpec())
reg("Fan", { Cl(.5, .5, .88, .88, P(.06, .94, 1.76, 1.76, 0, .5)) })
reg("Diamond", { P(.5, .5, .62, .62, 45, .16) })
reg("Gem", stars(2, .72, .3))
reg("Burst", stars(3, .70, 0))
reg("Soft burst", stars(3, .70, .16))
reg("Sunny", stars(4, .64, .24))
reg("Very sunny", stars(6, .62, .3))
reg("Boom", boomSpec())
reg("Soft boom", petals(8, .96, .22))
reg("Flower", petals(4, .96, .42))
reg("4-leaf clover", ring(4, .24, .5, .44, 45))
reg("8-leaf clover", ring(8, .3, .34, .56, 0))
reg("6-sided cookie", ring(6, .33, .32, .64, 0))
reg("9-sided cookie", ring(9, .36, .24, .72, 0))
reg("12-sided cookie", ring(12, .38, .2, .76, 0))
reg("Puffy", ring(10, .3, .3, .6, 0))
reg("Heart", { P(.31, .36, .5, .5, 0, .5), P(.69, .36, .5, .5, 0, .5), P(.5, .52, .48, .48, 45, .1) })
reg("Pixel circle", pixelCircle())
reg("Pixel triangle", pixelTriangle())
reg("Bun", { P(.5, .3, .96, .46, 0, .32), P(.5, .72, .96, .46, 0, .32) })

function UI:RegisterShape(name, spec)
	reg(name, spec)
end

UI.ShapeNames = ShapeOrder

local function makeShape(parent, name, color)
	local spec = ShapeSpecs[name] or ShapeSpecs.Circle
	local root = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	local parts = {}
	local function make(container, p)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(p[1], p[2]),
			Size = UDim2.fromScale(p[3], p[4]),
			Rotation = p[5] or 0,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
		if (p[6] or 0) > 0 then
			corner(f, UDim.new(p[6], 0))
		end
		parts[#parts + 1] = f
	end
	for _, p in ipairs(spec) do
		if p.clip then
			local cl = p.clip
			local holder = new("Frame", {
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(cl[1], cl[2]),
				Size = UDim2.fromScale(cl[3], cl[4]),
				Parent = root,
			})
			make(holder, {
				(p[1] - (cl[1] - cl[3] / 2)) / cl[3],
				(p[2] - (cl[2] - cl[4] / 2)) / cl[4],
				p[3] / cl[3],
				p[4] / cl[4],
				p[5],
				p[6],
			})
		else
			make(root, p)
		end
	end
	local obj = { Root = root, Parts = parts, Name = name }
	function obj.SetColor(_, c, t)
		for _, f in ipairs(parts) do
			if t then
				tween(f, t, { BackgroundColor3 = c })
			else
				f.BackgroundColor3 = c
			end
		end
	end
	function obj.Destroy()
		root:Destroy()
	end
	return obj
end

function UI:CreateShape(parent, name, color)
	return makeShape(parent, name, color or Color3.new(1, 1, 1))
end

-- ============================================================
--  Общие мелочи
-- ============================================================

local function isShown(obj)
	local p = obj
	while p and p:IsA("GuiObject") do
		if not p.Visible then
			return false
		end
		p = p.Parent
	end
	return true
end

UI.RippleOffset = Vector2.zero

-- ============================================================
--  Click sound — общий Sound для всех кликов
-- ============================================================
UI.SoundEnabled = true
UI.SoundVolume  = 0.35
-- можно заменить на свой rbxassetid://...
UI.ClickSoundId = "rbxassetid://6895079853"

local clickSound = new("Sound", {
	Name = "MaterialUIClick",
	SoundId = UI.ClickSoundId,
	Volume = UI.SoundVolume,
	PlaybackSpeed = 1,
	Parent = SoundService,
})

function UI:SetClickSound(id, volume)
	if id then UI.ClickSoundId = id; clickSound.SoundId = id end
	if volume then UI.SoundVolume = volume; clickSound.Volume = volume end
end

local function playClick(pitch)
	if not UI.SoundEnabled then return end
	local s = clickSound:Clone()
	s.PlaybackSpeed = pitch or 1
	s.Volume = UI.SoundVolume
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	task.delay(1, function() if s.Parent then s:Destroy() end end)
end

-- helper: подключает клик к любой кнопке
local function hookClick(btn)
	btn.MouseButton1Down:Connect(function()
		playClick(1)
	end)
end

local function pointerIn(host)
	local size = host.AbsoluteSize
	local rel = UserInputService:GetMouseLocation() - host.AbsolutePosition + UI.RippleOffset
	local inset = GuiService:GetGuiInset().Y
	if UI._shiftY == nil and inset > 0 then
		local a = rel.Y >= 0 and rel.Y <= size.Y
		local b = (rel.Y - inset) >= 0 and (rel.Y - inset) <= size.Y
		if a and not b then
			UI._shiftY = 0
		elseif b and not a then
			UI._shiftY = inset
		end
	end
	local y = rel.Y - (UI._shiftY or 0)
	return Vector2.new(math.clamp(rel.X, 0, size.X), math.clamp(y, 0, size.Y))
end

local function ripple(host, color)
	local p = pointerIn(host)
	local size = host.AbsoluteSize
	local dx = math.max(p.X, size.X - p.X)
	local dy = math.max(p.Y, size.Y - p.Y)
	local r = math.sqrt(dx * dx + dy * dy)
	local c = new("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = .82,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(0, 0),
		Parent = host,
	})
	corner(c, FULL)
	tween(c, .5, { Size = UDim2.fromOffset(r * 2, r * 2) })
	local t = tween(c, .65, { BackgroundTransparency = 1 })
	t.Completed:Once(function()
		c:Destroy()
	end)
end

local function chevron(win, parent, role)
	local h = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(.5, .5),
		Size = UDim2.fromOffset(14, 14),
		Parent = parent,
	})
	for _, d in ipairs({ { -3.5, 45 }, { 3.5, -45 } }) do
		local bar = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.new(.5, d[1], .5, 1),
			Size = UDim2.fromOffset(9, 2),
			Rotation = d[2],
			BorderSizePixel = 0,
			Parent = h,
		})
		corner(bar, FULL)
		win:Bind(bar, "BackgroundColor3", role)
	end
	return h
end

local function keyName(k)
	return k and k.Name or "None"
end

-- ============================================================
--  Window: привязка к теме
-- ============================================================

function Window:Bind(inst, prop, role)
	table.insert(self._binds, { inst, prop, role })
	inst[prop] = self.Colors[role]
	return inst
end

function Window:OnTheme(fn)
	table.insert(self._listeners, fn)
end

function Window:Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._conns, c)
	return c
end

function Window:Animate(fn)
	table.insert(self._anims, fn)
end

function Window:_refresh(animate)
	local C = self.Colors
	local binds = self._binds
	for i = #binds, 1, -1 do
		local b = binds[i]
		if b[1].Parent == nil then
			table.remove(binds, i)
		elseif animate then
			tween(b[1], .3, { [b[2]] = C[b[3]] })
		else
			b[1][b[2]] = C[b[3]]
		end
	end
	for _, fn in ipairs(self._listeners) do
		fn(animate)
	end
end

function Window:SetTheme(name)
	local t = UI.Themes[name]
	if not t then return end
	self.ThemeName = name
	self.Colors = buildScheme(t)
	self:_refresh(true)
	saveThemeName(name)
end

function Window:SetToggleKey(key)
	self.ToggleKey = key
end

function Window:_closePopup()
	if self._popupClose then
		self._popupClose()
		self._popupClose = nil
	end
end

-- ============================================================
--  Container
-- ============================================================

local function newContainer(win, frame, rowRole)
	return setmetatable({
		win = win,
		frame = frame,
		_order = 0,
		rowRole = rowRole or "surfaceContainerHigh",
	}, Container)
end

function Container:_next()
	self._order += 1
	return self._order
end

local function makeRow(self, o, rightW, height, forceTop)
	local win = self.win
	local row = new("CanvasGroup", {
		Name = o.Name or "Row",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 64),
		LayoutOrder = self:_next(),
		Parent = self.frame,
	})
	corner(row, 16)
	win:Bind(row, "BackgroundColor3", self.rowRole)

	local layer = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = row,
	})
	win:Bind(layer, "BackgroundColor3", "onSurface")

	local hit = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = row,
	})
	hit.MouseEnter:Connect(function()
		tween(layer, .15, { BackgroundTransparency = .975 })
	end)
	hit.MouseLeave:Connect(function()
		tween(layer, .2, { BackgroundTransparency = 1 })
	end)

	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local top = hasDesc or forceTop == true
	local titleW = UDim2.new(1, -((rightW or 0) + 36), 0, top and 20 or 22)
	local title = text({
		Text = o.Name or "",
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = titleW,
		Position = top and UDim2.fromOffset(16, 12) or UDim2.new(0, 16, 0, 0),
		Parent = row,
	})
	if not top then
		title.Size = UDim2.new(1, -((rightW or 0) + 36), 1, 0)
	end
	win:Bind(title, "TextColor3", "onSurface")

	local desc
	if hasDesc then
		desc = text({
			Text = o.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12.5,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -((rightW or 0) + 36), 0, 16),
			Position = UDim2.fromOffset(16, 34),
			Parent = row,
		})
		win:Bind(desc, "TextColor3", "onSurfaceVariant")
	end
	return row, hit, title, desc
end

function Container:AddSection(title)
	local win = self.win
	local sec = new("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = self:_next(),
		Parent = self.frame,
	})
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sec })
	local hdr = text({
		Text = title or "Section",
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 0,
		Parent = sec,
	})
	pad(hdr, 4, 0, 0, 0)
	win:Bind(hdr, "TextColor3", "onSurface")
	return newContainer(win, sec, self.rowRole)
end

function Container:AddLabel(str)
	local win = self.win
	local l = text({
		Text = str or "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = self:_next(),
		Parent = self.frame,
	})
	pad(l, 4, 2, 4, 2)
	win:Bind(l, "TextColor3", "onSurfaceVariant")
	return {
		Label = l,
		SetText = function(_, t)
			l.Text = t
		end,
	}
end

function Container:AddToggle(o)
	local win = self.win
	local row, hit = makeRow(self, o, 52)
	local state = o.Default == true

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(52, 32),
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(track, FULL)
	local stroke = new("UIStroke", { Thickness = 2, Parent = track })
	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(thumb, FULL)

	local function render(animate)
		local C = win.Colors
		apply(track, { BackgroundColor3 = state and C.primary or C.surfaceContainerHighest }, animate)
		apply(stroke, { Color = state and C.primary or C.outline }, animate)
		apply(thumb, {
			BackgroundColor3 = state and C.onPrimary or C.outline,
			Size = state and UDim2.fromOffset(24, 24) or UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, state and 36 or 16, .5, 0),
		}, animate)
	end
	render(false)
	win:OnTheme(render)

	local obj = { Row = row }
	function obj.Set(_, v, silent)
		state = v and true or false
		render(true)
		if not silent and o.Callback then
			task.spawn(o.Callback, state)
		end
	end
	function obj.Get()
		return state
	end

	hit.MouseButton1Down:Connect(function()
		ripple(row, win.Colors.onSurface)
	end)
	hit.MouseButton1Click:Connect(function()
		obj:Set(not state)
	end)
	hookClick(hit)
	if o.Default and o.Callback and o.CallOnInit then
		task.spawn(o.Callback, state)
	end
	return obj
end

function Container:AddButton(o)
	local win = self.win
	local label = o.ButtonText or "Run"
	local chipW = math.max(64, #label * 9 + 28)
	local row, hit = makeRow(self, o, chipW)

	local chip = new("Frame", {
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(chipW, 36),
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(chip, FULL)
	win:Bind(chip, "BackgroundColor3", "secondaryContainer")
	local t = text({
		Text = label,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = chip,
	})
	win:Bind(t, "TextColor3", "onSecondaryContainer")

	hit.MouseButton1Down:Connect(function()
		ripple(row, win.Colors.onSurface)
		tween(chip, .1, { Size = UDim2.fromOffset(chipW - 6, 32) })
	end)
	local function release()
		tween(chip, .25, { Size = UDim2.fromOffset(chipW, 36) }, Back)
	end
	hit.MouseButton1Up:Connect(release)
	hit.MouseLeave:Connect(release)
	hit.MouseButton1Click:Connect(function()
		if o.Callback then
			task.spawn(o.Callback)
		end
	end)
	hookClick(hit)
	return { Row = row }
end

-- Слайдер-«змейка»
function Container:AddSlider(o)
	local win = self.win
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local row = makeRow(self, o, 90, hasDesc and 96 or 78, true)
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local value = math.clamp(o.Default or min, min, max)

	local TRACK_H = 5
	local DOT = 5
	local STEP = 3
	local WAVE = o.WaveLength or 26
	local AMP_IDLE, AMP_DRAG = o.WaveAmplitude or 3, (o.WaveAmplitude or 3) * 1.5
	local SPEED = o.WaveSpeed or 7
	local GAP = 14
	local MID = 16

	local valLbl = text({
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(80, 20),
		Parent = row,
	})
	win:Bind(valLbl, "TextColor3", "primary")

	local area = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -8),
		Size = UDim2.new(1, -32, 0, 32),
		Parent = row,
	})

	local rail = new("Frame", {
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, 0, 0, MID),
		Size = UDim2.fromOffset(0, TRACK_H),
		BorderSizePixel = 0,
		Parent = area,
	})
	corner(rail, FULL)
	win:Bind(rail, "BackgroundColor3", "secondaryContainer")

	local stop = new("Frame", {
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -4, 0, MID),
		Size = UDim2.fromOffset(4, 4),
		BorderSizePixel = 0,
		Parent = area,
	})
	corner(stop, FULL)
	win:Bind(stop, "BackgroundColor3", "primary")

	local wave = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = area,
	})
	local dots, shownDots = {}, 0
	local function dotAt(i)
		local d = dots[i]
		if not d then
			d = new("Frame", {
				AnchorPoint = Vector2.new(.5, .5),
				Size = UDim2.fromOffset(DOT, DOT),
				BackgroundColor3 = win.Colors.primary,
				BorderSizePixel = 0,
				Visible = false,
				Parent = wave,
			})
			corner(d, FULL)
			dots[i] = d
		end
		return d
	end
	win:OnTheme(function()
		for _, d in ipairs(dots) do
			d.BackgroundColor3 = win.Colors.primary
		end
	end)

	local handle = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.new(0, 0, 0, MID),
		Size = UDim2.fromOffset(18, 18),
		BorderSizePixel = 0,
		Parent = area,
	})
	corner(handle, FULL)
	win:Bind(handle, "BackgroundColor3", "primary")
	local ring = new("UIStroke", { Thickness = 4, Parent = handle })
	win:Bind(ring, "Color", self.rowRole)

		local bubble = new("Frame", {
		AnchorPoint = Vector2.new(.5, 1),
		Position = UDim2.new(0, 0, 0, -6),
		Size = UDim2.fromOffset(56, 26),
		BackgroundColor3 = Color3.fromRGB(235, 232, 240),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Visible = false,
		Parent = area,
	})
	corner(bubble, 13)
	local bubbleLbl = text({
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		TextColor3 = Color3.fromRGB(28, 27, 32),
		Parent = bubble,
	})

	local function fmt(v)
		return tostring(math.floor(v * 1000 + .5) / 1000)
	end
	local frac = (max == min) and 0 or (value - min) / (max - min)
	local shown, phase, amp = frac, 0, AMP_IDLE
	local dragging = false

	local obj = { Row = row }
	local function setValue(v, fire)
		v = math.floor((v - min) / inc + .5) * inc + min
		v = math.clamp(v, min, max)
		local changed = v ~= value
		value = v
		frac = (max == min) and 0 or (v - min) / (max - min)
		valLbl.Text = fmt(v) .. (o.Suffix or "")
		bubbleLbl.Text = fmt(v)
		if fire and changed and o.Callback then
			task.spawn(o.Callback, v)
		end
	end
	setValue(value, false)
	shown = frac

	function obj.Set(_, v)
		setValue(v, true)
	end
	function obj.Get()
		return value
	end

	win:Animate(function(dt)
		if not isShown(area) then
			return
		end
		local W = area.AbsoluteSize.X
		if W <= 0 then
			return
		end
		shown += (frac - shown) * (1 - math.exp(-dt * 16))
		if math.abs(frac - shown) < .0005 then
			shown = frac
		end
		amp += ((dragging and AMP_DRAG or AMP_IDLE) - amp) * (1 - math.exp(-dt * 10))
		phase = (phase + dt * SPEED * (dragging and 1.8 or 1)) % (math.pi * 2)

		local headX = shown * W
		handle.Position = UDim2.new(0, headX, 0, MID)
		rail.Size = UDim2.fromOffset(math.max(W - headX - GAP, 0), TRACK_H)
		stop.Visible = (W - headX) > 26
		bubble.Position = UDim2.new(0, math.clamp(headX, math.min(26, W / 2), math.max(W - 26, W / 2)), 0, -4)

		local len = math.max(headX - GAP * .5, 0)
		local n = len > 0 and (math.floor(len / STEP) + 1) or 0
		local k = (math.pi * 2) / WAVE
		for i = 1, n do
			local x = (i - 1) * STEP
			local t = math.clamp((len - x) / 18, 0, 1)
			t = t * t * (3 - 2 * t)
			local d = dotAt(i)
			d.Position = UDim2.fromOffset(x + DOT / 2, MID + amp * t * math.sin(x * k - phase))
			if i > shownDots then
				d.Visible = true
			end
		end
		for i = n + 1, shownDots do
			dots[i].Visible = false
		end
		shownDots = n
	end)

	local function fromInput(pos)
		local W = math.max(area.AbsoluteSize.X, 1)
		local rel = math.clamp((pos.X - area.AbsolutePosition.X) / W, 0, 1)
		setValue(min + (max - min) * rel, true)
	end
	local function release()
		dragging = false
				bubble.Visible = false
		tween(handle, .25, { Size = UDim2.fromOffset(18, 18) }, Back)
	end
	area.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		    playClick(1.1)
			dragging = true
						bubble.Visible = true
			tween(handle, .2, { Size = UDim2.fromOffset(22, 22) }, Back)
			fromInput(i.Position)
		end
	end)
	win:Connect(UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			fromInput(i.Position)
		end
	end)
	win:Connect(UserInputService.InputEnded, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			release()
		end
	end)
	return obj
end

function Container:AddDropdown(o)
	local win = self.win
	local row = makeRow(self, o, 150)
	local options = o.Options or {}
	local value = o.Default or options[1]

	local btn = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(140, 40),
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(btn, FULL)
	win:Bind(btn, "BackgroundColor3", "surfaceContainer")
	local valueLbl = text({
		Text = tostring(value or ""),
		TextSize = 14,
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn,
	})
	win:Bind(valueLbl, "TextColor3", "onSurface")
	local chev = chevron(win, btn, "onSurfaceVariant")
	chev.Position = UDim2.new(1, -22, .5, 0)

	local obj = { Row = row }
	function obj.Set(_, v, silent)
		value = v
		valueLbl.Text = tostring(v)
		if not silent and o.Callback then
			task.spawn(o.Callback, v)
		end
	end
	function obj.Get()
		return value
	end
	function obj.SetOptions(_, list)
		options = list
	end

	local function open()
		win:_closePopup()
		local overlay = win.Overlay
		overlay.Visible = true
		local catcher = new("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 60,
			Parent = overlay,
		})
		local itemH = 44
		local listH = math.min(#options * itemH + 16, 248)
		local w = math.max(btn.AbsoluteSize.X, 170)
		local pos = btn.AbsolutePosition - overlay.AbsolutePosition
		local x = pos.X + btn.AbsoluteSize.X - w
		local y = pos.Y + btn.AbsoluteSize.Y + 6
		if y + listH > overlay.AbsoluteSize.Y - 8 then
			y = pos.Y - listH - 6
		end
		local popup = new("CanvasGroup", {
			Position = UDim2.fromOffset(x, y + 8),
			Size = UDim2.fromOffset(w, listH),
			GroupTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 61,
			Parent = overlay,
		})
		corner(popup, 18)
		win:Bind(popup, "BackgroundColor3", "surfaceContainerHighest")
		local st = new("UIStroke", { Thickness = 1, Parent = popup })
		win:Bind(st, "Color", "outlineVariant")
		local sc = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			Parent = popup,
		})
		pad(sc, 8, 8, 8, 8)
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sc })
		for i, opt in ipairs(options) do
			local sel = opt == value
			local it = new("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				BackgroundTransparency = sel and 0 or 1,
				Size = UDim2.new(1, 0, 0, itemH - 2),
				LayoutOrder = i,
				Parent = sc,
			})
			corner(it, 12)
			win:Bind(it, "BackgroundColor3", sel and "secondaryContainer" or "onSurface")
			local tl = text({
				Text = tostring(opt),
				TextSize = 14,
				Size = UDim2.new(1, -32, 1, 0),
				Position = UDim2.fromOffset(16, 0),
				Parent = it,
			})
			win:Bind(tl, "TextColor3", sel and "onSecondaryContainer" or "onSurface")
			if not sel then
				it.MouseEnter:Connect(function()
					tween(it, .12, { BackgroundTransparency = .965 })
				end)
				it.MouseLeave:Connect(function()
					tween(it, .15, { BackgroundTransparency = 1 })
				end)
			end
			it.MouseButton1Click:Connect(function()
				obj:Set(opt)
				win:_closePopup()
			end)
		end
		tween(popup, .22, { GroupTransparency = 0, Position = UDim2.fromOffset(x, y) })
		tween(chev, .2, { Rotation = 180 })

		local closed = false
		local function close()
			if closed then
				return
			end
			closed = true
			tween(chev, .2, { Rotation = 0 })
			local tw = tween(popup, .15, { GroupTransparency = 1 })
			catcher:Destroy()
			overlay.Active = false
			tw.Completed:Once(function()
				popup:Destroy()
				if not win._popupClose then
					overlay.Visible = false
				end
			end)
		end
		win._popupClose = close
		catcher.MouseButton1Click:Connect(function()
			win:_closePopup()
		end)
	end
	btn.MouseButton1Click:Connect(function()
		playClick(0.95)
		open()
	end)
	return obj
end

function Container:AddKeybind(o)
	local win = self.win
	local row = makeRow(self, o, 120)
	local key = o.Default
	local listening = false

	local btn = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(104, 40),
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(btn, FULL)
	local lbl = text({
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = btn,
	})

	local function render(animate)
		local C = win.Colors
		lbl.Text = listening and "..." or keyName(key)
		apply(btn, { BackgroundColor3 = listening and C.primary or C.surfaceContainer }, animate)
		apply(lbl, { TextColor3 = listening and C.onPrimary or C.onSurface }, animate)
	end
	render(false)
	win:OnTheme(render)

	local obj = { Row = row }
	function obj.Get()
		return key
	end
	function obj.Set(_, k, silent)
		key = k
		render(true)
		if not silent and o.Callback then
			task.spawn(o.Callback, k)
		end
	end

	btn.MouseButton1Click:Connect(function()
		playClick(1.05)
		listening = true
		win._listening = true
		render(true)
	end)
	win:Connect(UserInputService.InputBegan, function(input, gp)
		if listening then
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			listening = false
			win._listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				render(true)
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				obj:Set(nil)
			else
				obj:Set(input.KeyCode)
			end
		elseif not gp and key and input.KeyCode == key and o.OnPress then
			task.spawn(o.OnPress)
		end
	end)
	return obj
end

-- ============================================================
--  INPUT
-- ============================================================
function Container:AddInput(o)
	local win = self.win
	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local rowH = hasDesc and 96 or 76
	local row, hit, title = makeRow(self, o, 0, rowH, true)

	local box = new("Frame", {
		Size = UDim2.new(1, -32, 0, 34),
		Position = UDim2.new(0, 16, 1, -8),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = win.Colors.surfaceContainer,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(box, 12)
	local boxStroke = new("UIStroke", { Thickness = 1, Parent = box })
	win:Bind(boxStroke, "Color", "outlineVariant")

	local tb = new("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.Gotham,
		Text = o.Default or "",
		PlaceholderText = o.Placeholder or "Type...",
		TextSize = 13,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = box,
	})
	win:Bind(tb, "TextColor3", "onSurface")
	win:Bind(tb, "PlaceholderColor3", "onSurfaceVariant")

	local focused = false
	tb.Focused:Connect(function()
		focused = true
		tween(boxStroke, .2, { Color = win.Colors.primary })
	end)
	tb.FocusLost:Connect(function(enter)
		focused = false
		tween(boxStroke, .2, { Color = win.Colors.outlineVariant })
		if enter and o.Callback then
			task.spawn(o.Callback, tb.Text)
		end
	end)

	win:OnTheme(function(animate)
		if not focused then
			apply(boxStroke, { Color = win.Colors.outlineVariant }, animate)
		end
	end)

	local obj = { Row = row, TextBox = tb }
	function obj.Get()
		return tb.Text
	end
	function obj.Set(_, v)
		tb.Text = v
	end
	return obj
end

-- ============================================================
--  Color Picker
-- ============================================================
function Container:AddColorpicker(o)
	local win = self.win
	local row = makeRow(self, o, 60)
	local color = o.Default or Color3.fromRGB(208, 188, 255)

	local swatch = new("Frame", {
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(48, 28),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(swatch, 12)
	local swatchStroke = new("UIStroke", { Thickness = 1, Parent = swatch })
	win:Bind(swatchStroke, "Color", "outlineVariant")

	local btn = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		Size = UDim2.fromOffset(48, 28),
		Parent = row,
	})

	local obj = { Row = row }
	local h, s, v = color:ToHSV()

	function obj.Set(_, c, silent)
		color = c
		swatch.BackgroundColor3 = c
		h, s, v = c:ToHSV()
		if not silent and o.Callback then
			task.spawn(o.Callback, c)
		end
	end
	function obj.Get()
		return color
	end

	local function open()
		win:_closePopup()
		local overlay = win.Overlay
		overlay.Visible = true
		local catcher = new("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 60,
			Parent = overlay,
		})
		local pos = btn.AbsolutePosition - overlay.AbsolutePosition
		local w = 240
		local popup = new("CanvasGroup", {
			Position = UDim2.fromOffset(pos.X + btn.AbsoluteSize.X - w, pos.Y + btn.AbsoluteSize.Y + 6),
			Size = UDim2.fromOffset(w, 110),
			GroupTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 61,
			Parent = overlay,
		})
		corner(popup, 18)
		win:Bind(popup, "BackgroundColor3", "surfaceContainerHighest")
		local ps = new("UIStroke", { Thickness = 1, Parent = popup })
		win:Bind(ps, "Color", "outlineVariant")
		pad(popup, 14, 14, 14, 14)

		local hTrack = new("Frame", {
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = popup,
		})
		corner(hTrack, FULL)
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			}),
			Parent = hTrack,
		})
		local hThumb = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = hTrack,
		})
		corner(hThumb, FULL)
		local hThumbStroke = new("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255, 255, 255), Parent = hThumb })
		win:Bind(hThumbStroke, "Color", "onSurface")

		local hexBox = new("Frame", {
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.new(1, 0, 0, 34),
			BorderSizePixel = 0,
			Parent = popup,
		})
		corner(hexBox, 12)
		win:Bind(hexBox, "BackgroundColor3", "surfaceContainer")
		local hexStroke = new("UIStroke", { Thickness = 1, Parent = hexBox })
		win:Bind(hexStroke, "Color", "outlineVariant")
		local hexInput = new("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Font = Enum.Font.Code,
			Text = string.format("#%02X%02X%02X",
				math.floor(color.R * 255 + .5),
				math.floor(color.G * 255 + .5),
				math.floor(color.B * 255 + .5)),
			TextSize = 13,
			ClearTextOnFocus = false,
			Parent = hexBox,
		})
		win:Bind(hexInput, "TextColor3", "onSurface")

		local function applyColor(c, silent)
			color = c
			swatch.BackgroundColor3 = c
			hThumb.Position = UDim2.new(select(1, c:ToHSV()), 0, .5, 0)
			hexInput.Text = string.format("#%02X%02X%02X",
				math.floor(c.R * 255 + .5),
				math.floor(c.G * 255 + .5),
				math.floor(c.B * 255 + .5))
			if not silent and o.Callback then
				task.spawn(o.Callback, c)
			end
		end

		hThumb.Position = UDim2.new(select(1, color:ToHSV()), 0, .5, 0)

		local draggingH = false
		local function updateHue(i)
			local rel = math.clamp((i.Position.X - hTrack.AbsolutePosition.X) / math.max(hTrack.AbsoluteSize.X, 1), 0, 1)
			local _, ss, vv = color:ToHSV()
			applyColor(Color3.fromHSV(rel, ss > 0 and ss or 1, vv > 0 and vv or 1))
		end
		hTrack.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				draggingH = true
				updateHue(i)
			end
		end)
		win:Connect(UserInputService.InputChanged, function(i)
			if draggingH and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				updateHue(i)
			end
		end)
		win:Connect(UserInputService.InputEnded, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				draggingH = false
			end
		end)

		hexInput.FocusLost:Connect(function()
			local s2 = hexInput.Text:gsub("#", ""):gsub("%s", "")
			if #s2 == 6 then
				local r2 = tonumber(s2:sub(1, 2), 16)
				local g2 = tonumber(s2:sub(3, 4), 16)
				local b2 = tonumber(s2:sub(5, 6), 16)
				if r2 and g2 and b2 then
					applyColor(Color3.fromRGB(r2, g2, b2))
				end
			end
		end)

		tween(popup, .22, { GroupTransparency = 0 })

		local closed = false
		local function close()
			if closed then return end
			closed = true
			local tw = tween(popup, .15, { GroupTransparency = 1 })
			catcher:Destroy()
			overlay.Active = false
			tw.Completed:Once(function()
				popup:Destroy()
				if not win._popupClose then
					overlay.Visible = false
				end
			end)
		end
		win._popupClose = close
		catcher.MouseButton1Click:Connect(function()
			win:_closePopup()
		end)
	end
	btn.MouseButton1Click:Connect(open)

	return obj
end

-- ============================================================
--  Folder
-- ============================================================
function Container:AddFolder(o)
	local win = self.win
	local HEADER = 64
	local card = new("CanvasGroup", {
		Name = o.Name or "Folder",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, HEADER),
		LayoutOrder = self:_next(),
		Parent = self.frame,
	})
	corner(card, 16)
	win:Bind(card, "BackgroundColor3", self.rowRole)

	-- FIX: hover-слой теперь лежит на ВСЕЙ карточке, а не внутри header
	local cardLayer = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = card,
	})
	corner(cardLayer, 16)
	win:Bind(cardLayer, "BackgroundColor3", "onSurface")

	local header = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER),
		Parent = card,
	})

	-- ховер запускаем от header, но меняем прозрачность cardLayer
	header.MouseEnter:Connect(function()
		tween(cardLayer, .15, { BackgroundTransparency = .975 })
	end)
	header.MouseLeave:Connect(function()
		tween(cardLayer, .2, { BackgroundTransparency = 1 })
	end)

	local hasDesc = o.Description ~= nil and o.Description ~= ""
	local title = text({
		Text = o.Name or "Folder",
		TextSize = 15,
		Size = UDim2.new(1, -72, 0, hasDesc and 20 or HEADER),
		Position = UDim2.fromOffset(16, hasDesc and 12 or 0),
		Parent = header,
	})
	win:Bind(title, "TextColor3", "onSurface")
	if hasDesc then
		local d = text({
			Text = o.Description,
			Font = Enum.Font.Gotham,
			TextSize = 12.5,
			Size = UDim2.new(1, -72, 0, 16),
			Position = UDim2.fromOffset(16, 34),
			Parent = header,
		})
		win:Bind(d, "TextColor3", "onSurfaceVariant")
	end
	local chev = chevron(win, header, "onSurfaceVariant")
	chev.AnchorPoint = Vector2.new(.5, .5)
	chev.Position = UDim2.new(1, -28, .5, 0)

	local content = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		Parent = card,
	})
	local list = new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	pad(content, 8, 0, 8, 0)

	local c = newContainer(win, content, "surfaceContainerHighest")
	c.Card = card

	local open = false
	local tw
	local function contentH()
		return list.AbsoluteContentSize.Y + 8
	end
	local function targetH()
		return HEADER + (open and contentH() or 0)
	end

	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		content.Size = UDim2.new(1, 0, 0, contentH())
		if open then
			if tw then
				tw:Cancel()
				tw = nil
			end
			card.Size = UDim2.new(1, 0, 0, targetH())
		end
	end)

	function c.SetOpen(_, v, instant)
		open = v and true or false
		if tw then
			tw:Cancel()
			tw = nil
		end
		if open then
			content.Visible = true
		end
		local h = targetH()
		if instant then
			card.Size = UDim2.new(1, 0, 0, h)
			chev.Rotation = open and 180 or 0
			content.Visible = open
			return
		end
		tween(chev, .25, { Rotation = open and 180 or 0 })
		local mine = tween(card, .35, { Size = UDim2.new(1, 0, 0, h) })
		tw = mine
		if not open then
			mine.Completed:Once(function()
				if tw == mine and not open then
					content.Visible = false
				end
			end)
		end
	end
	function c.IsOpen()
		return open
	end

	header.MouseButton1Down:Connect(function()
		ripple(card, win.Colors.onSurface)
	end)
	header.MouseButton1Click:Connect(function()
		playClick(0.9)
		c:SetOpen(not open)
	end)
	if o.Open then
		c:SetOpen(true, true)
	end
	return c
end

-- ============================================================
--  ESP Preview — интерактивный R6 манекен с ghost-режимом
-- ============================================================
function Container:AddESPPreview(o)
	o = o or {}
	local win = self.win

	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 280),
		BackgroundTransparency = 1,
		LayoutOrder = self:_next(),
		Parent = self.frame,
	})

	text({
		Text = "LIVE PREVIEW",
		Font = Enum.Font.GothamBold, TextSize = 11,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(2, 0),
		Parent = holder,
	})
	win:Bind(holder:GetChildren()[#holder:GetChildren()], "TextColor3", "primary")

	text({
		Text = "Click any feature to toggle it on/off",
		Font = Enum.Font.Gotham, TextSize = 11,
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(2, 14),
		Parent = holder,
	})
	win:Bind(holder:GetChildren()[#holder:GetChildren()], "TextColor3", "onSurfaceVariant")

	local viewFrame = new("Frame", {
		Size = UDim2.new(1, 0, 1, -34),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	})

	local vpf = new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 1, Parent = viewFrame,
	})

	-- === R6 манекен ===
	local model = new("Model", { Name = "Mannequin", Parent = vpf })
	local bodyColor = win.Colors.onSurfaceVariant
	local bodyParts = {}

	local function makePart(name, size, pos)
		local p = new("Part", {
			Name = name, Size = size, CFrame = CFrame.new(pos),
			Anchored = true, CanCollide = false,
			Material = Enum.Material.SmoothPlastic,
			Color = bodyColor,
			TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
			LeftSurface = Enum.SurfaceType.Smooth, RightSurface = Enum.SurfaceType.Smooth,
			FrontSurface = Enum.SurfaceType.Smooth, BackSurface = Enum.SurfaceType.Smooth,
			Parent = model,
		})
		table.insert(bodyParts, p)
		return p
	end

	local head = makePart("Head", Vector3.new(1, 1, 1), Vector3.new(0, 4.5, 0))
	new("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25), Parent = head })
	makePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
	makePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0))
	makePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0))
	makePart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0))
	makePart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0))

	local cam = new("Camera", { FieldOfView = 30, Parent = vpf })
	vpf.CurrentCamera = cam
	cam.CFrame = CFrame.new(Vector3.new(0, 2.5, 16), Vector3.new(0, 2.5, 0))

	-- === Оверлеи ===
	local nameTag = text({
		Text = "Player", Font = Enum.Font.GothamBold, TextSize = 12,
		Size = UDim2.fromOffset(120, 16), AnchorPoint = Vector2.new(0.5, 1),
		TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center,
		Visible = true, ZIndex = 5,
		Parent = viewFrame,
	})

	local boxFrame = new("Frame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Visible = true, ZIndex = 3, Parent = viewFrame,
	})
	corner(boxFrame, 4)
	local boxStroke = new("UIStroke", { Thickness = 1.5, Color = Color3.new(1,1,1), Parent = boxFrame })

	local headDot = new("Frame", {
		Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
		Visible = true, ZIndex = 4, Parent = viewFrame,
	})
	corner(headDot, FULL)

	local hbOutline = new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Visible = true, ZIndex = 4, Parent = viewFrame,
	})
	corner(hbOutline, 2)
	local hbFill = new("Frame", {
		Size = UDim2.new(1, 0, 0.75, 0),
		Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(80, 220, 100),
		BorderSizePixel = 0, Parent = hbOutline,
	})
	corner(hbFill, 2)

	local tracer = new("Frame", {
		Size = UDim2.fromOffset(2, 100), AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Visible = true, ZIndex = 3, Parent = viewFrame,
	})

	-- === Hit-zones ===
	local function hitZone(z)
		return new("TextButton", {
			Text = "", AutoButtonColor = false,
			BackgroundTransparency = 1, BorderSizePixel = 0,
			ZIndex = z, Parent = viewFrame,
		})
	end

	local masterHit = hitZone(2)
	local boxHitTop    = hitZone(10)
	local boxHitLeft   = hitZone(10)
	local boxHitRight  = hitZone(10)
	local boxHitBottom = hitZone(10)
	local tracerHit  = hitZone(11)
	local headDotHit = hitZone(12)
	local nameTagHit = hitZone(12)
	-- HP picker должен быть ВЫШЕ nameTag, чтобы клик по верхней стороне ловился
	local hpLeftHit  = hitZone(14)
	local hpRightHit = hitZone(14)
	local hpTopHit   = hitZone(14)

	-- === State ===
	local state = {
		enabled   = o.Enabled  == true,
		boxes     = o.Boxes    ~= false,
		tracers   = o.Tracers  == true,
		headDot   = o.HeadDot  ~= false,
		healthBar = o.HealthBar ~= false,
		nameTag   = o.NameTag  ~= false,
		rainbow   = o.Rainbow  == true,
		boxColor    = o.BoxColor    or Color3.fromRGB(255, 255, 255),
		tracerColor = o.TracerColor or Color3.fromRGB(255, 255, 255),
		nameColor   = o.NameColor   or Color3.fromRGB(255, 255, 255),
		healthPct   = o.HealthPercent or 0.75,
		healthPos   = o.HealthPosition or "Right",
		nameText    = o.NameText or "Player",
	}

	local hover = { boxes = false, tracers = false, headDot = false, healthBar = false, nameTag = false }

	local function isOn(key) return state.enabled and state[key] end

	-- FIX: в OnToggle уходят ключи в PascalCase, как ждёт главный скрипт
	local KEY_MAP = {
		boxes = "Boxes", tracers = "Tracers",
		headDot = "HeadDot", healthBar = "HealthBar", nameTag = "NameTag",
	}
	local function toggleKey(key)
		if not state.enabled then
			state.enabled = true
			if o.OnToggle then o.OnToggle("Enabled", true) end
		end
		state[key] = not state[key]
		if o.OnToggle then o.OnToggle(KEY_MAP[key] or key, state[key]) end
	end

	masterHit.MouseButton1Click:Connect(function()
		playClick(1)
		state.enabled = not state.enabled
		if o.OnToggle then o.OnToggle("Enabled", state.enabled) end
	end)

	local function bindBoxToggle(z)
	    z.MouseButton1Click:Connect(function()
			playClick(1)
			toggleKey("boxes")
		end)
		z.MouseButton1Click:Connect(function() toggleKey("boxes") end)
		z.MouseEnter:Connect(function() hover.boxes = true end)
		z.MouseLeave:Connect(function() hover.boxes = false end)
	end
	bindBoxToggle(boxHitTop)
	bindBoxToggle(boxHitLeft)
	bindBoxToggle(boxHitRight)
	bindBoxToggle(boxHitBottom)

    tracerHit.MouseButton1Click:Connect(function() playClick(1); toggleKey("tracers") end)
	tracerHit.MouseEnter:Connect(function() hover.tracers = true end)
	tracerHit.MouseLeave:Connect(function() hover.tracers = false end)

	headDotHit.MouseButton1Click:Connect(function() playClick(1); toggleKey("headDot") end)
	headDotHit.MouseEnter:Connect(function() hover.headDot = true end)
	headDotHit.MouseLeave:Connect(function() hover.headDot = false end)

	nameTagHit.MouseButton1Click:Connect(function() playClick(1); toggleKey("nameTag") end)
	nameTagHit.MouseEnter:Connect(function() hover.nameTag = true end)
	nameTagHit.MouseLeave:Connect(function() hover.nameTag = false end)

	local function clickHP(zone)
		if state.healthPos ~= zone then
			state.healthPos = zone
			state.healthBar = true
			if not state.enabled then
				state.enabled = true
				if o.OnToggle then o.OnToggle("Enabled", true) end
			end
			if o.OnHealthPos then o.OnHealthPos(zone) end
			if o.OnToggle then o.OnToggle("HealthBar", true) end
		else
			toggleKey("healthBar")
		end
	end
	hpLeftHit.MouseButton1Click:Connect(function() playClick(1); clickHP("Left") end)
	hpRightHit.MouseButton1Click:Connect(function() playClick(1); clickHP("Right") end)
	hpTopHit.MouseButton1Click:Connect(function() playClick(1); clickHP("Top") end)

	for _, z in ipairs({ hpLeftHit, hpRightHit, hpTopHit }) do
		z.MouseEnter:Connect(function() hover.healthBar = true end)
		z.MouseLeave:Connect(function() hover.healthBar = false end)
	end

	-- === Render loop ===
	win:Animate(function()
		if not isShown(viewFrame) then return end
		local W = viewFrame.AbsoluteSize.X
		local H = viewFrame.AbsoluteSize.Y
		if W < 20 or H < 20 then return end

		local cx       = W * 0.5
		local modelTop = H * 0.16
		local modelBot = H * 0.86
		local modelH   = modelBot - modelTop
		local modelW   = modelH * 0.50

		local boxLeft = cx - modelW / 2 - 3
		local boxTop  = modelTop - 4
		local boxW    = modelW + 6
		local boxH    = (modelBot - modelTop) + 8

		local rainbowCol = Color3.fromHSV(tick() % 5 / 5, 1, 1)
		local boxCol    = state.rainbow and rainbowCol or state.boxColor
		local tracerCol = state.rainbow and rainbowCol or state.tracerColor
		local nameCol   = state.rainbow and rainbowCol or state.nameColor

		-- Box
		boxFrame.Position = UDim2.fromOffset(boxLeft, boxTop)
		boxFrame.Size     = UDim2.fromOffset(boxW, boxH)
		boxStroke.Color   = boxCol
		local boxOn = isOn("boxes")
		boxStroke.Transparency = boxOn and 0 or (hover.boxes and 0.45 or 0.75)
		boxStroke.Thickness    = boxOn and 1.5 or 1

		-- Name tag
		nameTag.Position   = UDim2.fromOffset(boxLeft + boxW / 2, boxTop - 4)
		nameTag.Text       = state.nameText
		nameTag.TextColor3 = nameCol
		local ntOn = isOn("nameTag")
		nameTag.TextTransparency = ntOn and 0 or (hover.nameTag and 0.45 or 0.75)

		-- Head dot
		local headCY = modelTop + modelH * 0.08
		headDot.Position = UDim2.fromOffset(cx, headCY)
		headDot.BackgroundColor3 = boxCol
		local hdOn = isOn("headDot")
		headDot.BackgroundTransparency = hdOn and 0 or (hover.headDot and 0.45 or 0.75)
		headDot.Size = UDim2.fromOffset(hdOn and 8 or 7, hdOn and 8 or 7)

		-- HP bar
		local hp = math.clamp(state.healthPct, 0, 1)
		hbFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hp)

		if state.healthPos == "Right" then
			hbOutline.AnchorPoint = Vector2.new(0, 0)
			hbOutline.Position = UDim2.fromOffset(boxLeft + boxW + 3, boxTop)
			hbOutline.Size = UDim2.fromOffset(4, boxH)
			hbFill.Size = UDim2.new(1, 0, hp, 0)
			hbFill.Position = UDim2.new(0, 0, 1, 0)
			hbFill.AnchorPoint = Vector2.new(0, 1)
		elseif state.healthPos == "Left" then
			hbOutline.AnchorPoint = Vector2.new(1, 0)
			hbOutline.Position = UDim2.fromOffset(boxLeft - 3, boxTop)
			hbOutline.Size = UDim2.fromOffset(4, boxH)
			hbFill.Size = UDim2.new(1, 0, hp, 0)
			hbFill.Position = UDim2.new(0, 0, 1, 0)
			hbFill.AnchorPoint = Vector2.new(0, 1)
		else
			hbOutline.AnchorPoint = Vector2.new(0, 1)
			hbOutline.Position = UDim2.fromOffset(boxLeft, boxTop - 3)
			hbOutline.Size = UDim2.fromOffset(boxW, 4)
			hbFill.Size = UDim2.new(hp, 0, 1, 0)
			hbFill.Position = UDim2.new(0, 0, 0, 0)
			hbFill.AnchorPoint = Vector2.new(0, 0)
		end

		local hpOn = isOn("healthBar")
		local hpAlpha = hpOn and 0 or (hover.healthBar and 0.45 or 0.75)
		hbOutline.BackgroundTransparency = math.max(hpAlpha, 0.3)
		hbFill.BackgroundTransparency = hpAlpha

		-- Tracer
		local tracerX = boxLeft + boxW + 14
		tracer.Position = UDim2.fromOffset(tracerX, boxTop)
		tracer.Size     = UDim2.fromOffset(2, boxH)
		tracer.BackgroundColor3 = tracerCol
		local trOn = isOn("tracers")
		tracer.BackgroundTransparency = trOn and 0 or (hover.tracers and 0.45 or 0.75)

		-- Hit-zones positions
		local BW = 8

		masterHit.Position = UDim2.fromOffset(boxLeft + BW, boxTop + BW)
		masterHit.Size     = UDim2.fromOffset(boxW - 2*BW, boxH - 2*BW)

		boxHitTop.Position    = UDim2.fromOffset(boxLeft, boxTop)
		boxHitTop.Size        = UDim2.fromOffset(boxW, BW)
		boxHitBottom.Position = UDim2.fromOffset(boxLeft, boxTop + boxH - BW)
		boxHitBottom.Size     = UDim2.fromOffset(boxW, BW)
		boxHitLeft.Position   = UDim2.fromOffset(boxLeft, boxTop)
		boxHitLeft.Size       = UDim2.fromOffset(BW, boxH)
		boxHitRight.Position  = UDim2.fromOffset(boxLeft + boxW - BW, boxTop)
		boxHitRight.Size      = UDim2.fromOffset(BW, boxH)

		local HP_W = 8
		hpLeftHit.Position  = UDim2.fromOffset(boxLeft - HP_W - 1, boxTop)
		hpLeftHit.Size      = UDim2.fromOffset(HP_W, boxH)
		hpRightHit.Position = UDim2.fromOffset(boxLeft + boxW + 1, boxTop)
		hpRightHit.Size     = UDim2.fromOffset(HP_W, boxH)
		hpTopHit.Position   = UDim2.fromOffset(boxLeft, boxTop - HP_W - 1)
		hpTopHit.Size       = UDim2.fromOffset(boxW, HP_W)

		tracerHit.Position = UDim2.fromOffset(tracerX - 4, boxTop)
		tracerHit.Size     = UDim2.fromOffset(10, boxH)

		headDotHit.Position = UDim2.fromOffset(cx - 12, headCY - 12)
		headDotHit.Size     = UDim2.fromOffset(24, 24)

		nameTagHit.Position = UDim2.fromOffset(boxLeft + boxW/2 - 50, boxTop - 22)
		nameTagHit.Size     = UDim2.fromOffset(100, 18)
	end)

	-- Тема
	win:OnTheme(function(animate)
		local col = win.Colors.onSurfaceVariant
		for _, p in ipairs(bodyParts) do
			if animate then tween(p, .3, { Color = col }) else p.Color = col end
		end
	end)

	-- API
	local api = {}
	function api:SetEnabled(v)        state.enabled = v end
	function api:SetBoxes(v)          state.boxes = v end
	function api:SetTracers(v)        state.tracers = v end
	function api:SetHeadDot(v)        state.headDot = v end
	function api:SetHealthBar(v)      state.healthBar = v end
	function api:SetNameTag(v)        state.nameTag = v end
	function api:SetRainbow(v)        state.rainbow = v end
	function api:SetBoxColor(c)       state.boxColor = c end
	function api:SetTracerColor(c)    state.tracerColor = c end
	function api:SetNameColor(c)      state.nameColor = c end
	function api:SetHealthPercent(p)  state.healthPct = p end
	function api:SetHealthPosition(p) state.healthPos = p end
	function api:SetNameText(t)       state.nameText = t end
	function api:SetBodyColor(c)
		for _, p in ipairs(bodyParts) do p.Color = c end
	end
	return api
end

-- ============================================================
--  Window controls
-- ============================================================

local function iconButton(win, parent, kind, order, fn)
	local b = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(36, 36),
		LayoutOrder = order,
		Parent = parent,
	})
	corner(b, FULL)
	win:Bind(b, "BackgroundColor3", "onSurface")
	b.MouseEnter:Connect(function()
		tween(b, .15, { BackgroundTransparency = .965 })
	end)
	b.MouseLeave:Connect(function()
		tween(b, .2, { BackgroundTransparency = 1 })
	end)
	local function bar(w, rot)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(.5, .5),
			Size = UDim2.fromOffset(w, 2),
			Rotation = rot or 0,
			BorderSizePixel = 0,
			Parent = b,
		})
		corner(f, FULL)
		win:Bind(f, "BackgroundColor3", "onSurfaceVariant")
	end
	if kind == "min" then
		bar(14)
	elseif kind == "max" then
		local sq = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(.5, .5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Parent = b,
		})
		corner(sq, 3)
		local st = new("UIStroke", { Thickness = 2, Parent = sq })
		win:Bind(st, "Color", "onSurfaceVariant")
	else
		bar(16, 45)
		bar(16, -45)
	end
	b.MouseButton1Click:Connect(fn)
	return b
end

function Window:Toggle(v)
	if not self._ready or self.Destroyed then
		return
	end
	if v == nil then
		v = not self.Visible
	end
	self.Visible = v
	self:_closePopup()
	if v then
		self.Main.Visible = true
		self._scale.Scale = .92
		self.Main.GroupTransparency = 1
		tween(self._scale, .35, { Scale = 1 }, Back)
		tween(self.Main, .2, { GroupTransparency = 0 })
	else
		tween(self._scale, .2, { Scale = .92 })
		local t = tween(self.Main, .2, { GroupTransparency = 1 })
		t.Completed:Once(function()
			if not self.Visible then
				self.Main.Visible = false
			end
		end)
	end
end

function Window:Maximize()
	self._maximized = not self._maximized
	local target = self.BaseSize
	if self._maximized then
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		target = UDim2.fromOffset(vp.X - 80, vp.Y - 80)
	end
	tween(self.Main, .45, { Size = target, Position = UDim2.fromScale(.5, .5) })
end

function Window:Close()
	if self.Destroyed then
		return
	end
	self:_closePopup()
	tween(self._scale, .2, { Scale = .9 })
	local t = tween(self.Main, .2, { GroupTransparency = 1 })
	t.Completed:Once(function()
		self:Destroy()
	end)
end

function Window:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, c in ipairs(self._conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	if self.OnUnload then
		task.spawn(self.OnUnload)
	end
	self.Gui:Destroy()
end

function Window:Notify(o)
	if type(o) == "string" then
		o = { Text = o }
	end
	if self.Destroyed or not self.Toasts then
		return
	end
	local win = self
	self._toastId = (self._toastId or 0) + 1

	local slot = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._toastId,
		Parent = self.Toasts,
	})
	local toast = new("CanvasGroup", {
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(70, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		Parent = slot,
	})
	corner(toast, 18)
	win:Bind(toast, "BackgroundColor3", "inverseSurface")
	pad(toast, 14, 12, 16, 12)

	local iconBox = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(24, 24),
		Parent = toast,
	})
	local icon = makeShape(iconBox, o.Shape or win.LogoShape, win.Colors.primaryContainer)
	for _, part in ipairs(icon.Parts) do
		win:Bind(part, "BackgroundColor3", "primaryContainer")
	end

	local stack = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -36, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = toast,
	})
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = stack })
	if o.Title then
		local t = text({
			Text = o.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = 1,
			Parent = stack,
		})
		win:Bind(t, "TextColor3", "inverseOnSurface")
	end
	local body = text({
		Text = o.Text or "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, o.Title and 18 or 24),
		LayoutOrder = 2,
		Parent = stack,
	})
	win:Bind(body, "TextColor3", "inverseOnSurface")

	local gone = false
	local function dismiss()
		if gone then
			return
		end
		gone = true
		tween(toast, .28, { Position = UDim2.fromOffset(70, 0), GroupTransparency = 1 }, Quint, In)
		task.delay(.32, function()
			slot:Destroy()
		end)
	end
	toast.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			playClick(0.85)
			dismiss()
		end
	end)

	tween(toast, .45, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
	task.delay(o.Duration or 3.5, dismiss)
end

function Window:_select(tab)
	if self._current == tab then
		return
	end
	self:_closePopup()
	local prev = self._current
	self._current = tab
	if prev then
		prev.Page.Visible = false
		prev.render(true)
	end
	tab.Page.Visible = true
	tab.Page.GroupTransparency = 1
	tab.Page.Position = UDim2.fromOffset(0, 14)
	tween(tab.Page, .35, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
	tab.render(true)
end

function Window:AddTab(o)
	if type(o) == "string" then
		o = { Name = o }
	end
	local win = self

	local btn = new("CanvasGroup", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = #self._tabs + 1,
		Parent = self.Sidebar,
	})
	corner(btn, FULL)
	win:Bind(btn, "BackgroundColor3", "secondaryContainer")
	local hit = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = btn,
	})

	local iconHolder = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 11),
		Size = UDim2.fromOffset(22, 22),
		Parent = btn,
	})
	local imgIcon, shapeIcon
	if o.Icon then
		imgIcon = new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = o.Icon,
			Size = UDim2.fromScale(1, 1),
			Parent = iconHolder,
		})
	else
		shapeIcon = makeShape(iconHolder, o.Shape or "Circle", win.Colors.onSurfaceVariant)
	end
	local lbl = text({
		Text = o.Name or "Tab",
		TextSize = 14,
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.fromOffset(50, 0),
		Parent = btn,
	})

	local page = new("CanvasGroup", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self.Content,
	})
	local scroller = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		Parent = page,
	})
	win:Bind(scroller, "ScrollBarImageColor3", "outline")
	pad(scroller, 20, 20, 20, 20)
	new("UIListLayout", { Padding = UDim.new(0, 20), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })

	local tab = newContainer(win, scroller, "surfaceContainerHigh")
	tab.Name = o.Name
	tab.Page = page
	tab.Button = btn

	tab.render = function(animate)
		local C = win.Colors
		local sel = win._current == tab
		local col = sel and C.onSecondaryContainer or C.onSurfaceVariant
		apply(btn, { BackgroundTransparency = sel and 0 or 1 }, animate)
		apply(lbl, { TextColor3 = col }, animate)
		if imgIcon then
			apply(imgIcon, { ImageColor3 = col }, animate)
		elseif shapeIcon then
			shapeIcon:SetColor(col, animate and .2 or nil)
		end
	end
	tab.render(false)
	win:OnTheme(tab.render)

	hit.MouseEnter:Connect(function()
		if win._current ~= tab then
			tween(btn, .15, { BackgroundTransparency = .82 })
		end
	end)
	hit.MouseLeave:Connect(function()
		if win._current ~= tab then
			tween(btn, .2, { BackgroundTransparency = 1 })
		end
	end)
	hit.MouseButton1Down:Connect(function()
		ripple(btn, win.Colors.onSecondaryContainer)
	end)
	hit.MouseButton1Click:Connect(function()
		playClick(1)
		win:_select(tab)
	end)

	tab.Select = function()
		win:_select(tab)
	end
	table.insert(self._tabs, tab)
	if not self._current then
		self._current = tab
		page.Visible = true
		page.GroupTransparency = 0
		tab.render(false)
	end
	return tab
end

-- ============================================================
--  Intro
-- ============================================================

local function playIntro(win, onDone)
	local gui, C = win.Gui, win.Colors
	local PITCH, VIEW_W, VIEW_H = 100, 460, 130
	local names = shuffled(ShapeOrder)
	local N = #names

	local scrim = new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	tween(scrim, .4, { BackgroundTransparency = .5 })

	local card = new("CanvasGroup", {
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(VIEW_W, 300),
		BackgroundColor3 = C.surfaceContainer,
		GroupTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(card, 36)
	local sc = new("UIScale", { Scale = .85, Parent = card })
	tween(card, .35, { GroupTransparency = 0 })
	tween(sc, .55, { Scale = 1 }, Back)

	local view = new("CanvasGroup", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.fromOffset(VIEW_W, VIEW_H),
		Parent = card,
	})
	local strip = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.fromOffset(N * PITCH, VIEW_H),
		Parent = view,
	})
	local items = {}
	for i, name in ipairs(names) do
		local x = (i - 1) * PITCH + PITCH / 2
		local holder = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromOffset(x, VIEW_H / 2),
			Size = UDim2.fromOffset(40, 40),
			Parent = strip,
		})
		items[i] = { Holder = holder, Shape = makeShape(holder, name, C.outline), X = x }
	end

	local nameLbl = text({
		Text = "",
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 172),
		Parent = card,
	})
	nameLbl.TextColor3 = C.onSurface
	local status = text({
		Text = win.IntroText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 204),
		Parent = card,
	})
	status.TextColor3 = C.onSurfaceVariant

		-- ===== Snake loading bar =====
	local TRACK_W, TRACK_H = 280, 10
	local track = new("Frame", {
		AnchorPoint = Vector2.new(.5, 0),
		Position = UDim2.new(.5, 0, 0, 248),
		Size = UDim2.fromOffset(TRACK_W, TRACK_H),
		BackgroundColor3 = C.secondaryContainer,
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(track, FULL)

	-- Дорожка-подложка в самом центре (виден только хвост)
	local rail = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = C.outline,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(rail, FULL)

	-- Контейнер для точек змеи
	local waveHolder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	})

	local DOT   = 6        -- диаметр точки
	local STEP  = 3        -- шаг между точками
	local WAVE  = 22       -- длина волны в px
	local AMP   = 4        -- амплитуда
	local SPD   = 6        -- скорость фазы (рад/с)

	local waveDots = {}
	local function waveDot(i)
		local d = waveDots[i]
		if not d then
			d = new("Frame", {
				AnchorPoint = Vector2.new(.5, .5),
				Size = UDim2.fromOffset(DOT, DOT),
				BackgroundColor3 = C.primary,
				BorderSizePixel = 0,
				Visible = false,
				Parent = waveHolder,
			})
			corner(d, FULL)
			waveDots[i] = d
		end
		return d
	end

	local swaps = win.IntroSwaps
	local totalTime = 2.6 + (swaps + 1) * .75
	local startTime = tick()
	local phase = 0
	local shownDots = 0

	local barConn = RunService.RenderStepped:Connect(function(dt)
		local elapsed = tick() - startTime
		local progress = math.clamp(elapsed / totalTime, 0, 1)
		phase = (phase + dt * SPD) % (math.pi * 2)

		-- Плавный ease-in-out прогресс
		local p = progress < 0.5
			and (2 * progress * progress)
			or (1 - (-2 * progress + 2) ^ 2 / 2)

		local headX = p * TRACK_W
		local n = headX > 0 and (math.floor(headX / STEP) + 1) or 0
		local k = (math.pi * 2) / WAVE

		for i = 1, n do
			local x = (i - 1) * STEP
			-- Затухание волны у самой головы
			local t = math.clamp((headX - x) / 16, 0, 1)
			t = t * t * (3 - 2 * t)
			local d = waveDot(i)
			d.Position = UDim2.fromOffset(x + DOT / 2, TRACK_H / 2 + AMP * t * math.sin(x * k - phase))
			if i > shownDots then
				d.Visible = true
			end
		end
		for i = n + 1, shownDots do
			waveDots[i].Visible = false
		end
		shownDots = n
	end)
	table.insert(win._conns, barConn)

	local target = math.random(12, N - 3)
	local finalX = VIEW_W / 2 - items[target].X
	local cx0 = VIEW_W / 2

	local conn = RunService.RenderStepped:Connect(function()
		local sx = strip.Position.X.Offset
		for _, it in ipairs(items) do
			local d = math.abs(sx + it.X - cx0)
			if d < VIEW_W / 2 + PITCH then
				local f = math.clamp(1 - d / (PITCH * 1.1), 0, 1)
				f = f * f * (3 - 2 * f)
				local s = 40 + 60 * f
				it.Holder.Size = UDim2.fromOffset(s, s)
				it.Shape:SetColor(C.outline:Lerp(C.primary, f))
			end
		end
	end)
	table.insert(win._conns, conn)

	task.wait(.35)
	local scroll = tween(strip, 2.5, { Position = UDim2.fromOffset(finalX, 0) }, Cubic, InOut)
	scroll.Completed:Wait()
	conn:Disconnect()
	if win.Destroyed then
		return
	end

	local stageY = 28 + VIEW_H / 2
	local function spawnActor(name, color)
		local h = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromOffset(VIEW_W / 2, stageY),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = 2,
			Parent = card,
		})
		return { Holder = h, Shape = makeShape(h, name, color) }
	end
	local function setName(n)
		nameLbl.Text = n
		nameLbl.TextTransparency = 1
		tween(nameLbl, .3, { TextTransparency = 0 })
	end

	local actor = spawnActor(names[target], C.primary)
	actor.Holder.Size = UDim2.fromOffset(100, 100)
	setName(names[target])
	tween(view, .35, { GroupTransparency = 1 })

	local palette = { C.tertiary, C.primary, C.onPrimaryContainer, C.tertiary }
	local function morphTo(name, color)
		local old = actor
		tween(old.Holder, .32, { Size = UDim2.fromOffset(0, 0), Rotation = 140 }, Back, In)
		task.delay(.34, function()
			old.Holder:Destroy()
		end)
		local nw = spawnActor(name, color)
		nw.Holder.Rotation = -140
		task.delay(.14, function()
			if nw.Holder.Parent then
				tween(nw.Holder, .6, { Size = UDim2.fromOffset(100, 100), Rotation = 0 }, Back, Out)
			end
		end)
		actor = nw
		setName(name)
	end

	local pool = shuffled(ShapeOrder)
	for i = 1, swaps do
		task.wait(.75)
		if win.Destroyed then
			return
		end
		local nm = pool[i]
		if nm == actor.Shape.Name then
			nm = pool[#pool]
		end
		morphTo(nm, palette[(i - 1) % #palette + 1])
	end
	task.wait(.75)
	if win.Destroyed then
		return
	end
	morphTo(win.LogoShape, C.primary)
	status.Text = "Ready"
	task.wait(.8)
	if win.Destroyed then
		return
	end

	if barConn then barConn:Disconnect() end
	tween(sc, .4, { Scale = 1.08 })
	tween(card, .35, { GroupTransparency = 1 })
	local t = tween(scrim, .4, { BackgroundTransparency = 1 })
	t.Completed:Wait()
	card:Destroy()
	scrim:Destroy()
	onDone()
end

-- ============================================================
--  CreateWindow
-- ============================================================

function UI:CreateWindow(o)
	o = o or {}
	local win = setmetatable({}, Window)
	win._binds, win._listeners, win._conns, win._tabs = {}, {}, {}, {}
	win._anims = {}
	win.Visible = true
	win.ToggleKey = o.ToggleKey or Enum.KeyCode.RightShift
	win.OnUnload = o.OnUnload
	win.LogoShape = o.LogoShape or "Flower"
	win.IntroText = o.IntroText or "Loading interface..."
	win.IntroSwaps = o.IntroSwaps or 3
		-- NEW: сначала пробуем загрузить сохранённую тему, потом опцию, потом Dark
	local savedTheme = loadSavedTheme()
	local initialTheme = (savedTheme and UI.Themes[savedTheme] and savedTheme)
		or (o.Theme and UI.Themes[o.Theme] and o.Theme)
		or "Dark"
	win.ThemeName = initialTheme
	win.Colors = buildScheme(UI.Themes[win.ThemeName])
	local C = win.Colors

	local gui = new("ScreenGui", {
		Name = o.Name or "MaterialYouUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	win.Gui = gui

	win.Toasts = new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 100,
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Parent = win.Toasts,
	})

	local size = o.Size or Vector2.new(880, 560)
	win.BaseSize = UDim2.fromOffset(size.X, size.Y)

	local main = new("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = win.BaseSize,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	corner(main, 28)
	win:Bind(main, "BackgroundColor3", "surface")
	local mainStroke = new("UIStroke", { Thickness = 1, Parent = main })
	win:Bind(mainStroke, "Color", "outlineVariant")
	win.Main = main
	win._scale = new("UIScale", { Scale = .92, Parent = main })

	local header = new("Frame", {
		BackgroundTransparency = 1,
		Active = true,
		Size = UDim2.new(1, 0, 0, 64),
		Parent = main,
	})
	local left = new("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = header,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = left,
	})
	pad(left, 20, 0, 0, 0)

	local logoHolder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		LayoutOrder = 1,
		Parent = left,
	})
	local logo = makeShape(logoHolder, win.LogoShape, C.primary)
	win:OnTheme(function(a)
		logo:SetColor(win.Colors.primary, a and .25 or nil)
	end)

	local stack = new("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		LayoutOrder = 2,
		Parent = left,
	})
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = stack })
	local t1 = text({
		Text = o.Title or "Material You",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = 1,
		Parent = stack,
	})
	win:Bind(t1, "TextColor3", "onSurface")
	if o.Subtitle then
		local t2 = text({
			Text = o.Subtitle,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			AutomaticSize = Enum.AutomaticSize.XY,
			LayoutOrder = 2,
			Parent = stack,
		})
		win:Bind(t2, "TextColor3", "onSurfaceVariant")
	end
	if o.Version then
		local chip = new("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 26),
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = left,
		})
		corner(chip, FULL)
		win:Bind(chip, "BackgroundColor3", "surfaceContainer")
		pad(chip, 12, 0, 12, 0)
		local v = text({
			Text = o.Version,
			TextSize = 12,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = chip,
		})
		win:Bind(v, "TextColor3", "onSurface")
	end

	local controls = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -16, .5, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 36),
		Parent = header,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = controls,
	})
	iconButton(win, controls, "min", 1, function()
		win:Toggle(false)
	end)
	iconButton(win, controls, "max", 2, function()
		win:Maximize()
	end)
	iconButton(win, controls, "close", 3, function()
		win:Close()
	end)

	local dragging, dragStart, startPos = false, nil, nil
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, main.Position
		end
	end)
	win:Connect(UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	win:Connect(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local sidebar = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(0, 200, 1, -88),
		Parent = main,
	})
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })
	win.Sidebar = sidebar

	local content = new("Frame", {
		Position = UDim2.fromOffset(232, 72),
		Size = UDim2.new(1, -248, 1, -88),
		BorderSizePixel = 0,
		Parent = main,
	})
	corner(content, 24)
	win:Bind(content, "BackgroundColor3", "surfaceContainer")
	win.Content = content

	win.Overlay = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Visible = false,
		Parent = main,
	})

	win:Connect(UserInputService.InputBegan, function(input)
		if win._listening or not win._ready then
			return
		end
		if input.KeyCode == win.ToggleKey and not UserInputService:GetFocusedTextBox() then
			win:Toggle()
		end
	end)

	local acc = 0
	win:Connect(RunService.RenderStepped, function(dt)
		acc += dt
		if acc < 1 / 45 then
			return
		end
		local step = acc
		acc = 0
		if not win._ready or not win.Visible or not main.Visible then
			return
		end
		for _, fn in ipairs(win._anims) do
			fn(step)
		end
	end)

	local function open()
		win._ready = true
		main.Visible = true
		win.Visible = true
		tween(win._scale, .45, { Scale = 1 }, Back)
		tween(main, .25, { GroupTransparency = 0 })
	end

	if o.Intro == false then
		open()
	else
		task.spawn(function()
			local okIntro, err = pcall(playIntro, win, open)
			if not okIntro then
				warn("[MaterialYouUI] intro error: " .. tostring(err))
				if not win.Destroyed then
					open()
				end
			end
		end)
	end

	return win
end

return UI
