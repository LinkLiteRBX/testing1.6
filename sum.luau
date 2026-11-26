loadstring(game:HttpGet("https://raw.githubusercontent.com/LinkLiteRBX/testing/refs/heads/main/test.lua"))()
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")
local VirtualUser      = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Connections = {}
local WaveGuiName = "Wave1.5"
local function destroyIfExists(parent, name)
	pcall(function()
		local obj = parent:FindFirstChild(name)
		if obj then obj:Destroy() end
	end)
end
local function cleanupWaveGui(parent)
	destroyIfExists(parent, WaveGuiName)
	destroyIfExists(parent, "Wave1.5Esp")
end
cleanupWaveGui(CoreGui)
local State = {
	Sliders = {
		Prediction = 0.007, Smoothness = 2.50,
		SilentPrediction = 0.007, SilentFovRadius = 150,
		FlySpeed = 10.00, FlyMultiplier = 1.00, TweenTpSpeed = 110.00, FovRadius = 150,
		SpinSpeed = 10.00,
	},
	Toggles = {
		Noclip = false, Fly = false,
		NameEsp = false, BoxOutline = false, Box3D = false, Tracers = false, FriendEsp = false,
		EspTeamCheck = false, Skeleton = false, Distance = false, HealthBars = false, ShowItems = false, Box3DCorners = false,
		NoFog = false, DisableShadows = false, LowGfx = false, Maxzoom = false,
		FovCircle = false, SilentFovCircle = false, AdaptiveAim = false,
		TeamCheck = true, FriendCheck = false, WallCheck = false, DeadCheck = true, StickyAim = false, TargetUI = false,
		Camlock = false, Silent = false, AntiAfk = false, InfJump = false, AntiSeat = false,
		AutoPickup = false, Spinbot = false, BoxCorners = false,
		UIBlur = false, UIShadow = true, ArrayList = true, AutoLoad = false,
	},
	Keybinds = { CamLockToggle = nil, SilentToggle = nil, FlyToggle = nil, TweenClickTpToggle = nil, MenuToggle = "Insert" },
	AimPart = "UpperTorso", SilentMethod = "Raycast", EspUpdateRate = "Auto", FlyType = "CFrame", TpMode = "Tween",
	Theme = "None", ArrayPosition = "Btm Left", Preset = "Daydream",
}
local FriendChecks = {}
do
	local friendCache = setmetatable({}, { __mode = "k" })
	local friendPending = setmetatable({}, { __mode = "k" })
	local function refreshFriend(player)
		if not player or player == LocalPlayer or friendCache[player] ~= nil or friendPending[player] then return end
		friendPending[player] = true
		task.spawn(function()
			local ok, result = pcall(function()
				return LocalPlayer:IsFriendsWith(player.UserId)
			end)
			if player.Parent == Players then friendCache[player] = ok and result == true or false end
			friendPending[player] = nil
		end)
	end
	local function isFriend(player)
		if friendCache[player] == nil then refreshFriend(player) end
		return friendCache[player] == true
	end
	local function passesFriendCheck(player)
		if not State.Toggles.FriendCheck then return true end
		if not player or player == LocalPlayer then return false end
		if friendCache[player] == nil then
			refreshFriend(player)
			return false
		end
		return friendCache[player] ~= true
	end
	FriendChecks.cache = friendCache
	FriendChecks.refresh = refreshFriend
	FriendChecks.isFriend = isFriend
	FriendChecks.passes = passesFriendCheck
end
local SliderConfig = {
	Prediction = { Min = 0, Max = 0.10, Decimals = 3 }, Smoothness = { Min = 1, Max = 10, Decimals = 2 },
	SilentPrediction = { Min = 0, Max = 0.10, Decimals = 3 },
	SilentFovRadius = { Min = 50, Max = 500, Decimals = 0 }, FovRadius = { Min = 50, Max = 500, Decimals = 0 },
	FlySpeed = { Min = 1, Max = 50, Decimals = 2 }, FlyMultiplier = { Min = 0.25, Max = 10, Decimals = 2 },
	TweenTpSpeed = { Min = 5, Max = 250, Decimals = 0 }, SpinSpeed = { Min = 1, Max = 100, Decimals = 0 },
}
local SiteRoot = "https://shimmering-babka-52d2f9.netlify.app"
local SiteAssets = {
	logo = "logo.png",
}
local function resolveRequest()
	if type(request) == "function" then return request end
	if type(http_request) == "function" then return http_request end
	if syn and type(syn.request) == "function" then return syn.request end
	return nil
end
local function getSiteAsset(name)
	if type(getcustomasset) ~= "function" then return nil end
	local filename = SiteAssets[name]
	if not filename then return nil end
	local path = "wave15_filled_" .. filename
	if type(isfile) == "function" then
		local ok, exists = pcall(isfile, path)
		if ok and exists then
			local success, asset = pcall(getcustomasset, path)
			if success and type(asset) == "string" and asset ~= "" then return asset end
		end
	end
	if type(writefile) ~= "function" then return nil end
	local url = SiteRoot .. "/assets/" .. filename
	local body
	local requester = resolveRequest()
	if requester then
		local ok, response = pcall(requester, {Url = url, Method = "GET"})
		if ok and response and response.Success ~= false and (not response.StatusCode or response.StatusCode < 400) then
			body = response.Body
		end
	end
	if not body then
		pcall(function() body = game:HttpGet(url) end)
	end
	if type(body) ~= "string" or #body == 0 then return nil end
	if not pcall(writefile, path, body) then return nil end
	local success, asset = pcall(getcustomasset, path)
	if success and type(asset) == "string" and asset ~= "" then return asset end
	return nil
end
local function resolveDecalTexture(assetId)
	local function normalize(reference)
		if type(reference) ~= "string" or reference == "" then return nil end
		if reference:find("rbxassetid://", 1, true) then return reference end
		local imageId = reference:match("[?&]id=(%d+)") or reference:match("/asset/(%d+)")
		if imageId then return "rbxassetid://" .. imageId end
		return reference
	end
	local function readTexture(root)
		if root and root:IsA("Decal") and root.Texture ~= "" then return normalize(root.Texture) end
		if root then
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("Decal") and d.Texture ~= "" then return normalize(d.Texture) end
			end
		end
		return nil
	end
	local requester = resolveRequest()
	local body
	if requester then
		local ok, response = pcall(requester, {Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. tostring(assetId), Method = "GET"})
		if ok and type(response) == "table" and response.Success ~= false and (not response.StatusCode or response.StatusCode < 400) then
			body = response.Body
		end
	end
	if type(body) == "string" then
		local ref = body:match('<Content%s+name="Texture".-<url>(.-)</url>') or body:match("<url>(.-)</url>")
		local texture = normalize(ref)
		if texture then return texture end
	end
	local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(assetId)) end)
	if ok and type(objects) == "table" then
		for _, object in ipairs(objects) do
			local texture = readTexture(object)
			if texture then
				for _, loaded in ipairs(objects) do pcall(function() loaded:Destroy() end) end
				return texture
			end
		end
		for _, object in ipairs(objects) do pcall(function() object:Destroy() end) end
	end
	local insertOk, model = pcall(function() return game:GetService("InsertService"):LoadAsset(tonumber(assetId)) end)
	if insertOk and model then
		local texture = readTexture(model)
		pcall(function() model:Destroy() end)
		if texture then return texture end
	end
	return nil
end
local Themes = {
	dark = {
		Background = Color3.fromRGB(22,22,26), Panel = Color3.fromRGB(28,28,33), Body = Color3.fromRGB(24,24,29),
		Border = Color3.fromRGB(86,86,96), Rule = Color3.fromRGB(126,126,138), Highlight = Color3.fromRGB(40,40,48),
		Text = Color3.fromRGB(210,210,215), Subtext = Color3.fromRGB(130,130,140),
		Checkbox = Color3.fromRGB(42,42,50), CheckboxHover = Color3.fromRGB(58,58,68), CheckboxBorder = Color3.fromRGB(92,92,104),
		Track = Color3.fromRGB(40,40,50), Fill = Color3.fromRGB(100,170,255), Knob = Color3.fromRGB(180,220,255), KnobOff = Color3.fromRGB(196,196,205),
		Scroll = Color3.fromRGB(70,70,90), BlurBranch = Color3.fromRGB(82,82,92), BlurPill = Color3.fromRGB(72,78,92),
	},
	light = {
		Background = Color3.fromRGB(255,255,255), Panel = Color3.fromRGB(255,255,255), Body = Color3.fromRGB(248,249,251),
		Border = Color3.fromRGB(154,158,168), Rule = Color3.fromRGB(62,64,70), Highlight = Color3.fromRGB(228,230,235),
		Text = Color3.fromRGB(34,35,40), Subtext = Color3.fromRGB(88,90,98),
		Checkbox = Color3.fromRGB(184,188,198), CheckboxHover = Color3.fromRGB(168,173,185), CheckboxBorder = Color3.fromRGB(144,149,161),
		Track = Color3.fromRGB(176,180,191), Fill = Color3.fromRGB(100,170,255), Knob = Color3.fromRGB(242,248,255), KnobOff = Color3.fromRGB(220,223,230),
		Scroll = Color3.fromRGB(145,150,163), BlurBranch = Color3.fromRGB(248,249,252), BlurPill = Color3.fromRGB(242,245,250),
	},
}
Themes.dark.Highlight    = Color3.fromRGB(255,255,255)
Themes.light.Highlight   = Color3.fromRGB(0,0,0)
Themes.dark.Track        = Color3.fromRGB(51,51,56)
Themes.dark.SliderFill   = Color3.fromRGB(255,255,255)
Themes.dark.ToggleOff    = Color3.fromRGB(245,245,247)
Themes.dark.ToggleKnobOn = Color3.fromRGB(255,255,255)
Themes.light.SliderFill   = Color3.fromRGB(40,42,48)
Themes.light.ToggleOff    = Color3.fromRGB(255,255,255)
Themes.light.ToggleKnobOn = Color3.fromRGB(255,255,255)
Themes.dark.Chevron  = Color3.fromRGB(190,192,200)
Themes.light.Chevron = Color3.fromRGB(96,101,112)
Themes.dark.Logo  = Color3.fromRGB(255,255,255)
Themes.light.Logo = Color3.fromRGB(25,25,30)
local buildTheme
local PresetNames = { "None", "Dracula", "Chocolate", "Nord", "Ocean", "Rose", "Light" }
local PresetSet = {}
for _, n in ipairs(PresetNames) do PresetSet[n] = true end
local BackdropSet = { None = true, Daydream = true }
do
local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local BaseThemes = {}
for mode, t in pairs(Themes) do
	local copy = {}
	for k, v in pairs(t) do copy[k] = v end
	BaseThemes[mode] = copy
end
local Presets = {
	Dracula = {
		dark  = { Accent = C(189,147,249), Track = C(62,64,82),  Background = C(30,31,41) },
		light = { Accent = C(124,77,200),  Track = C(190,186,208) },
	},
	Chocolate = {
		dark  = { Accent = C(210,150,100), Track = C(62,48,42),  Background = C(28,22,20) },
		light = { Accent = C(120,72,40),   Track = C(205,190,178) },
	},
	Nord = {
		dark  = { Accent = C(136,192,208), Track = C(59,66,82),  Background = C(36,40,50) },
		light = { Accent = C(62,110,140),  Track = C(190,200,212) },
	},
	Ocean = {
		dark  = { Accent = C(56,189,200),  Track = C(34,56,68),  Background = C(16,26,34) },
		light = { Accent = C(20,110,150),  Track = C(176,200,210) },
	},
	Rose = {
		dark  = { Accent = C(240,120,150), Track = C(66,44,52),  Background = C(30,20,24) },
		light = { Accent = C(190,60,100),  Track = C(215,190,198) },
	},
}
local BackdropPalettes = {
	Daydream = { Accent = C(232,160,148), Track = C(54,42,70) },
}
buildTheme = function(mode)
	local t, base = Themes[mode], BaseThemes[mode]
	for k, v in pairs(base) do t[k] = v end
	local p
	if mode == "dark" and BackdropPalettes[State.Preset] then
		p = BackdropPalettes[State.Preset]
	else
		p = Presets[State.Theme] and Presets[State.Theme][mode]
	end
	if not p then return end
	local a = p.Accent
	t.SliderFill = a
	t.Logo = a
	t.Track = p.Track
	t.Border = base.Border:Lerp(a, 0.30)
	t.Rule = base.Rule:Lerp(a, 0.40)
	t.Scroll = base.Scroll:Lerp(a, 0.40)
	t.Chevron = base.Chevron:Lerp(a, 0.45)
	t.CheckboxBorder = base.CheckboxBorder:Lerp(a, 0.30)
	t.Checkbox = base.Checkbox:Lerp(a, 0.10)
	t.CheckboxHover = base.CheckboxHover:Lerp(a, 0.15)
	if p.Background then
		t.Background = p.Background
	elseif mode == "light" then
		t.Background = base.Background:Lerp(a, 0.04)
	end
end
end
buildTheme("dark")
buildTheme("light")
local currentThemeName = "dark"
local Theme = Themes.dark
local themedObjects  = {}
local themedSliders  = {}
local themedKeybinds = {}
local themedBranches = {}
local themedToggles  = {}
local keybindSyncs   = {}
local choiceSyncs    = {}
local arrayListLabels = {}
local ToggleCallbacks = {}
local TemporarilyDisabledToggles = {
	TargetUI = true,
}
local DisabledToggleTextColor = Color3.fromRGB(235, 76, 76)
local refreshArrayList
local function registerThemed(obj, prop, role)
	local entry = { obj = obj, prop = prop, role = role }
	table.insert(themedObjects, entry)
	return entry
end
local function unregisterThemed(entry)
	local i = table.find(themedObjects, entry)
	if i then table.remove(themedObjects, i) end
end
local objectNameCounter = 0
local function nextObjectName()
	objectNameCounter += 1
	return string.format("x%02da", objectNameCounter)
end
local function make(className, props)
	local obj = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v
		elseif k ~= "Name" then obj[k] = v end
	end
	obj.Name = nextObjectName()
	if parent then obj.Parent = parent end
	return obj
end
local function tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local dropdownHovered = {}
local function isOverDropdown()
	return next(dropdownHovered) ~= nil
end
local activeDropdownClose
local function closeDropdown()
	local close = activeDropdownClose
	activeDropdownClose = nil
	if close then pcall(close) end
end
local keybindClickBlockUntil = 0
local function inputBlocked()
	return os.clock() < keybindClickBlockUntil
end
local function inputToKeyName(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local name = input.KeyCode.Name
		if name == "Unknown" then return nil end
		return name
	end
	local n = input.UserInputType.Name:match("^MouseButton(%d)$")
	if n then return "Mouse" .. n end
	return nil
end
local KeyAbbrev = {
	Mouse1="M1", Mouse2="M2", Mouse3="M3", Mouse4="M4", Mouse5="M5", Backspace="Bsp", Space="Spc", Return="Ent", Enter="Ent", Escape="Esc",
	Delete="Del", Insert="Ins", Tab="Tab", Home="Hom", End="End", PageUp="PgU", PageDown="PgD", CapsLock="Cap",
	LeftShift="Shf", RightShift="Shf", LeftControl="Ctl", RightControl="Ctl", LeftAlt="Alt", RightAlt="Alt",
	Up="Up", Down="Dn", Left="Lft", Right="Rgt",
}
local function shortKeyName(name)
	if not name or name == "" then return "Set" end
	if KeyAbbrev[name] then return KeyAbbrev[name] end
	if #name <= 3 or name:match("^F%d+$") then return name end
	return name:sub(1, 3)
end
local function formatValue(sliderName, value)
	local config = SliderConfig[sliderName]
	local decimals = config and config.Decimals or 2
	local n = tonumber(value) or (config and config.Min) or 0
	return string.format("%." .. tostring(decimals) .. "f", n)
end
local function valueToAlpha(sliderName, value)
	local config = SliderConfig[sliderName]
	local n = tonumber(value) or (config and config.Min) or 0
	if not config then return math.clamp(n, 0, 1) end
	return math.clamp((n - config.Min) / (config.Max - config.Min), 0, 1)
end
local function alphaToValue(sliderName, alpha)
	local config = SliderConfig[sliderName]
	if not config then return math.clamp(alpha, 0, 1) end
	return tonumber(formatValue(sliderName, config.Min + (config.Max - config.Min) * alpha))
end
local themeDuration = 0.40
local themeTweens = {}
local function themeValue(obj, property, value, animate)
	if not obj or not obj.Parent then return end
	local old = themeTweens[obj] and themeTweens[obj][property]
	if old then pcall(function() old:Cancel() end) end
	if animate and typeof(value) == "Color3" then
		local ok, effect = pcall(function()
			return TweenService:Create(obj, TweenInfo.new(themeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {[property] = value})
		end)
		if ok and effect then
			themeTweens[obj] = themeTweens[obj] or {}
			themeTweens[obj][property] = effect
			effect:Play()
			return
		end
	end
	pcall(function() obj[property] = value end)
end
local function applyTheme(themeName, animate)
	currentThemeName = themeName
	Theme = Themes[themeName]
	for _, e in ipairs(themedObjects) do themeValue(e.obj, e.prop, Theme[e.role], animate) end
	for _, sd in ipairs(themedSliders) do
		themeValue(sd.track, "BackgroundColor3", Theme.Track, animate)
		themeValue(sd.fill, "BackgroundColor3", Theme.SliderFill, animate)
		themeValue(sd.cap, "BackgroundColor3", Theme.SliderFill, animate)
		themeValue(sd.valueLabel, "TextColor3", Theme.Text, animate)
	end
	for _, kb in ipairs(themedKeybinds) do
		themeValue(kb, "BackgroundColor3", Theme.Checkbox, animate)
		themeValue(kb, "BorderColor3", Theme.CheckboxBorder, animate)
		themeValue(kb, "TextColor3", Theme.Text, animate)
	end
	for _, br in ipairs(themedBranches) do
		themeValue(br.button, "BackgroundColor3", Theme.Highlight, animate)
		themeValue(br.icon, "TextColor3", Theme.Text, animate)
		themeValue(br.label, "TextColor3", Theme.Text, animate)
	end
	for _, tg in ipairs(themedToggles) do
		local on = State.Toggles[tg.stateName]
		themeValue(tg.track, "BackgroundColor3", on and Theme.SliderFill or Theme.Track, animate)
		themeValue(tg.knob, "BackgroundColor3", on and Theme.Track or Theme.SliderFill, animate)
		if not animate and tg.update then pcall(tg.update) end
	end
	if refreshArrayList then refreshArrayList() end
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = WaveGuiName
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 1000
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
local MainWidth, MainHeight = 460, 525
local HeaderHeight, BottomHeight, BodyPadding = 38, 24, 8
local PanelWidth = MainWidth - BodyPadding * 2
local SideHeight = MainHeight - HeaderHeight - BottomHeight - 12
local RowHeight, SliderRowHeight = 22, 32
local RowGap, SectionGap = 4, 5
local EspBottomGap = 0
local RuleNudge = 0
local ToggleWidth, ToggleHeight = 30, 16
local ControlTransparency = 0.15
local DropdownWidth, DropdownHeaderHeight, DropdownOptionHeight = 90, 18, 18
local MaxDropdownOptions = 8
local Main = make("Frame", {
	Parent = ScreenGui, Size = UDim2.fromOffset(MainWidth, MainHeight),
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = false, Active = true,
})
registerThemed(Main, "BackgroundColor3", "Background")
make("UICorner", { Parent = Main, CornerRadius = UDim.new(0, 4) })
local MainStroke = make("UIStroke", { Parent = Main, Color = Theme.Border, Thickness = 1 })
registerThemed(MainStroke, "Color", "Border")
local ShadowObj
local ShadowOnTransparency = 0.46
pcall(function()
	local shadow = Instance.new("UIShadow")
	shadow.Name = nextObjectName()
	shadow.Color = Color3.fromRGB(0, 0, 0)
	shadow.Transparency = State.Toggles.UIShadow and ShadowOnTransparency or 1
	shadow.BlurRadius = UDim.new(0, 16)
	shadow.Offset = UDim2.fromOffset(0, 5)
	shadow.Spread = UDim2.fromOffset(5, 5)
	shadow.ZIndex = 0
	shadow.Parent = Main
	ShadowObj = shadow
end)
local setBackdropPreset
do
	local PresetSiteRoot = "https://bright-halva-7d5837.netlify.app"
	local PresetFiles = { Daydream = "daydream_ui.jpg" }
	local PresetCacheTag = "v1"
	local ImageBleed = 0
	local TintTransparency = 0.40
	local EdgeShadow = 40
	local group = make("CanvasGroup", {
		Parent = Main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 0, GroupTransparency = 1, Visible = false, Active = false,
	})
	make("UICorner", { Parent = group, CornerRadius = UDim.new(0, 4) })
	local image = make("ImageLabel", {
		Parent = group, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, ImageBleed * 2, 1, ImageBleed * 2), BackgroundTransparency = 1, Image = "",
		ScaleType = Enum.ScaleType.Crop, ZIndex = 1,
	})
	local tint = make("Frame", {
		Parent = group, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Body,
		BackgroundTransparency = TintTransparency, BorderSizePixel = 0, ZIndex = 2,
	})
	registerThemed(tint, "BackgroundColor3", "Body")
	local sheen = make("Frame", {
		Parent = group, Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 3,
	})
	make("UIGradient", {
		Parent = sheen, Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(1, 1) }),
	})
	local function edge(size, anchor, position, rotation, vertical)
		local frame = make("Frame", {
			Parent = group, AnchorPoint = anchor, Position = position, BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 4,
			Size = vertical and UDim2.new(1, 0, 0, size) or UDim2.new(0, size, 1, 0),
		})
		make("UIGradient", {
			Parent = frame, Rotation = rotation,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }),
		})
	end
	edge(EdgeShadow, Vector2.new(0, 0), UDim2.fromScale(0, 0), 90, true)
	edge(EdgeShadow, Vector2.new(0, 1), UDim2.fromScale(0, 1), 270, true)
	edge(EdgeShadow, Vector2.new(0, 0), UDim2.fromScale(0, 0), 0, false)
	edge(EdgeShadow, Vector2.new(1, 0), UDim2.fromScale(1, 0), 180, false)
	local assetCache = {}
	local function loadAsset(name)
		if assetCache[name] then return assetCache[name] end
		local filename = PresetFiles[name]
		if not filename or type(getcustomasset) ~= "function" then return nil end
		local path = "wave16_preset_" .. PresetCacheTag .. "_" .. filename
		local function register()
			local ok, asset = pcall(getcustomasset, path)
			if ok and type(asset) == "string" and asset ~= "" then
				assetCache[name] = asset
				return asset
			end
		end
		if type(isfile) == "function" then
			local ok, exists = pcall(isfile, path)
			if ok and exists then
				local asset = register()
				if asset then return asset end
			end
		end
		if type(writefile) ~= "function" then return nil end
		local url = PresetSiteRoot .. "/assets/" .. filename
		local body
		local requester = resolveRequest()
		if requester then
			local ok, response = pcall(requester, { Url = url, Method = "GET" })
			if ok and type(response) == "table" and response.Success ~= false
				and (not response.StatusCode or response.StatusCode < 400) then
				body = response.Body
			end
		end
		if not body then pcall(function() body = game:HttpGet(url) end) end
		if type(body) ~= "string" or #body < 1000 or body:sub(1, 3) ~= "\255\216\255" then return nil end
		if not pcall(writefile, path, body) then return nil end
		return register()
	end
	local token = 0
	local fadeTween
	local function fadeTo(value, duration)
		if fadeTween then fadeTween:Cancel() end
		fadeTween = TweenService:Create(group, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			GroupTransparency = value,
		})
		fadeTween:Play()
		return fadeTween
	end
	setBackdropPreset = function(name)
		if not BackdropSet[name] then name = "None" end
		State.Preset = name
		buildTheme("dark")
		buildTheme("light")
		applyTheme(currentThemeName, true)
		for _, sync in ipairs(choiceSyncs) do pcall(sync) end
		token += 1
		local mine = token
		tween(tint, 0.4, { BackgroundTransparency = TintTransparency })
		if name == "None" then
			local effect = fadeTo(1, 0.25)
			effect.Completed:Connect(function(status)
				if status == Enum.PlaybackState.Completed and mine == token then group.Visible = false end
			end)
			return
		end
		task.spawn(function()
			local asset = loadAsset(name)
			if mine ~= token then return end
			if not asset then
				warn("[Wave] Preset image couldn't be loaded (needs writefile + getcustomasset, and the site must be reachable).")
				fadeTo(1, 0.2)
				return
			end
			if group.Visible and group.GroupTransparency < 0.95 and image.Image ~= asset then
				fadeTo(1, 0.15).Completed:Wait()
				if mine ~= token then return end
			end
			image.ImageTransparency = 0
			image.Image = asset
			group.Visible = true
			fadeTo(0, 0.35)
		end)
	end
end
local unloadingUI = false
local BlurController = (function()
	local BlurRenderName = "Wave1.5 Blur Render"
	local BlurEffectName = "Wave1.5 Blur"
	local BlurPartSize = 0.01
	local BlurPartTransparency = 1 - 1e-7
	local BlurInset = Vector2.new(8, 8)
	local effect
	local blurParts, blurMeshes = {}, {}
	local enabled = false
	local cameraConn
	local function sweepWorld()
		pcall(function() RunService:UnbindFromRenderStep(BlurRenderName) end)
		for _, o in ipairs(Lighting:GetChildren()) do
			if o:GetAttribute("WaveBlur15") or o.Name == BlurEffectName then pcall(function() o:Destroy() end) end
		end
		for _, parent in ipairs({workspace, workspace.CurrentCamera}) do
			if parent then
				for _, o in ipairs(parent:GetChildren()) do
					if o:GetAttribute("WaveBlur15") then pcall(function() o:Destroy() end) end
				end
			end
		end
	end
	local function hideAll()
		for _, p in ipairs(blurParts) do p.Transparency = 1 end
		if effect then effect.Enabled = false end
	end
	local function intersect(planePos, normal, origin, dir)
		local denom = normal:Dot(dir)
		if math.abs(denom) < 0.00001 then return nil end
		return origin + dir * (-normal:Dot(origin - planePos) / denom)
	end
	local function updateGeometry()
		if not enabled or not effect then return end
		local camera = workspace.CurrentCamera
		if not camera or not Main.Parent or not Main.Visible then hideAll() return end
		for _, p in ipairs(blurParts) do if p.Parent ~= workspace then p.Parent = workspace end end
		local viewport = camera.ViewportSize
		local size = Main.AbsoluteSize
		local pos, anchor = Main.Position, Main.AnchorPoint
		local px = pos.X.Scale * viewport.X + pos.X.Offset - anchor.X * size.X
		local py = pos.Y.Scale * viewport.Y + pos.Y.Offset - anchor.Y * size.Y
		local c0 = Vector2.new(px, py) + BlurInset
		local c1 = Vector2.new(px + size.X, py + size.Y) - BlurInset
		if c1.X <= c0.X or c1.Y <= c0.Y then hideAll() return end
		local r0 = camera:ViewportPointToRay(c0.X, c0.Y, 1)
		local r1 = camera:ViewportPointToRay(c1.X, c1.Y, 1)
		local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
		local normal = camera.CFrame.LookVector
		local w0 = intersect(planeOrigin, normal, r0.Origin, r0.Direction)
		local w1 = intersect(planeOrigin, normal, r1.Origin, r1.Direction)
		if not w0 or not w1 then hideAll() return end
		local l0 = camera.CFrame:PointToObjectSpace(w0)
		local l1 = camera.CFrame:PointToObjectSpace(w1)
		local ext = l1 - l0
		local center = (l0 + l1) / 2
		for i, part in ipairs(blurParts) do
			part.CFrame = camera.CFrame
			local mesh = blurMeshes[i]
			mesh.Offset = center + Vector3.new(0, 0, (i - 1) * 0.002)
			mesh.Scale = Vector3.new(math.abs(ext.X) / BlurPartSize, math.abs(ext.Y) / BlurPartSize, 0.05)
			part.Transparency = BlurPartTransparency
		end
		effect.Enabled = true
		effect.FocusDistance = 0.25 - camera.NearPlaneZ
	end
	local function glassTween(obj, transparency)
		if not obj or not obj.Parent or not obj:IsA("GuiObject") then return end
		TweenService:Create(obj, TweenInfo.new(themeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = transparency }):Play()
	end
	local function applyGlass()
		for _, e in ipairs(themedObjects) do
			if e.prop == "BackgroundColor3" then
				if e.role == "Background" then
					glassTween(e.obj, enabled and 0.08 or 0)
				elseif e.role == "Panel" then
					glassTween(e.obj, enabled and 0.08 or 0)
				end
			end
		end
	end
	local function Enable()
		if enabled then return end
		sweepWorld()
		effect = Instance.new("DepthOfFieldEffect")
		effect.Name = BlurEffectName
		effect:SetAttribute("WaveBlur15", true)
		effect.FarIntensity = 0
		effect.NearIntensity = 1
		effect.FocusDistance = 0.25
		effect.InFocusRadius = 0
		effect.Parent = Lighting
		blurParts, blurMeshes = {}, {}
		for i = 1, 2 do
			local part = Instance.new("Part")
			part.Name = nextObjectName()
			part.Size = Vector3.new(BlurPartSize, BlurPartSize, BlurPartSize)
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
			part.Material = Enum.Material.Glass
			part.Transparency = BlurPartTransparency
			part:SetAttribute("WaveBlur15", true)
			part.Parent = workspace
			local mesh = Instance.new("BlockMesh")
			mesh.Parent = part
			blurParts[i], blurMeshes[i] = part, mesh
		end
		enabled = true
		RunService:BindToRenderStep(BlurRenderName, Enum.RenderPriority.Last.Value, updateGeometry)
		cameraConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.defer(updateGeometry) end)
		applyGlass()
		updateGeometry()
	end
	local function Disable(skipGlass)
		if not enabled and not effect and not cameraConn and #blurParts == 0 then return end
		enabled = false
		pcall(function() RunService:UnbindFromRenderStep(BlurRenderName) end)
		if cameraConn then cameraConn:Disconnect() cameraConn = nil end
		if effect then
			pcall(function() effect.Enabled = false end)
			pcall(function() effect:Destroy() end)
			effect = nil
		end
		for _, p in ipairs(blurParts) do pcall(function() p:Destroy() end) end
		blurParts, blurMeshes = {}, {}
		sweepWorld()
		if not skipGlass and not unloadingUI then applyGlass() end
	end
	local function Fix()
		Disable()
		sweepWorld()
		if State.Toggles.UIBlur and State.Preset == "None" then
			task.delay(0.15, function()
				if State.Toggles.UIBlur and State.Preset == "None" and not enabled and ScreenGui.Parent then Enable() end
			end)
		end
	end
	ScreenGui.AncestryChanged:Connect(function(_, parent)
		if parent then return end
		Disable(true)
	end)
	sweepWorld()
	applyGlass()
	return {
		UpdateAll = updateGeometry,
		RefreshGlass = function() applyGlass() updateGeometry() end,
		Enable = Enable,
		Disable = Disable,
		Fix = Fix,
		Destroy = function() Disable(true) end,
		IsEnabled = function() return enabled end,
	}
end)()
local function syncBlur()
	local want = State.Toggles.UIBlur and State.Preset == "None"
	if want and not BlurController.IsEnabled() then
		BlurController.Enable()
	elseif not want and BlurController.IsEnabled() then
		BlurController.Disable()
	end
end
ToggleCallbacks.UIBlur = function() syncBlur() end
table.insert(choiceSyncs, syncBlur)
ToggleCallbacks.UIShadow = function(on)
	if ShadowObj then
		pcall(function()
			TweenService:Create(ShadowObj, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Transparency = on and ShadowOnTransparency or 1 }):Play()
		end)
	end
end
local Header, syncLogoVisibility, syncBlurButton
do
Header = make("Frame", {
	Parent = Main, Size = UDim2.new(1, 0, 0, HeaderHeight),
	BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
})
local hSep = make("Frame", {
	Parent = Main, Size = UDim2.new(1, -12, 0, 1), Position = UDim2.fromOffset(6, HeaderHeight - 1),
	BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 12,
})
registerThemed(hSep, "BackgroundColor3", "Border")
local LogoHolder = make("Frame", {
	Parent = Header, Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(9, 7),
	BackgroundTransparency = 1, BorderSizePixel = 0,
})
local HeaderLogoImage = make("ImageLabel", {
	Parent = LogoHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Image = "", ScaleType = Enum.ScaleType.Fit, Visible = true,
})
registerThemed(HeaderLogoImage, "ImageColor3", "Logo")
local SiteLogoAsset = nil
local logoFadeId = 0
syncLogoVisibility = function(animate)
	logoFadeId += 1
	local currentId = logoFadeId
	HeaderLogoImage.Visible = true
	if SiteLogoAsset then HeaderLogoImage.Image = SiteLogoAsset end
	local function applyColor()
		HeaderLogoImage.ImageColor3 = Theme.Logo
	end
	if animate then
		TweenService:Create(HeaderLogoImage, TweenInfo.new(themeDuration * 0.5), {ImageTransparency = 1}):Play()
		task.delay(themeDuration * 0.5, function()
			if currentId ~= logoFadeId or not HeaderLogoImage.Parent then return end
			applyColor()
			TweenService:Create(HeaderLogoImage, TweenInfo.new(themeDuration * 0.5), {ImageTransparency = 0}):Play()
		end)
	else
		HeaderLogoImage.ImageTransparency = 0
		applyColor()
	end
end
task.spawn(function()
	SiteLogoAsset = getSiteAsset("logo")
	if HeaderLogoImage and HeaderLogoImage.Parent then syncLogoVisibility() end
end)
syncBlurButton = function(animate) syncLogoVisibility(animate) end
end
local Body = make("Frame", {
	Parent = Main, Size = UDim2.new(1, 0, 1, -(HeaderHeight + BottomHeight)),
	Position = UDim2.fromOffset(0, HeaderHeight), BackgroundTransparency = 1, BorderSizePixel = 0,
})
local SharedPanel = make("Frame", {
	Parent = Body, Size = UDim2.fromOffset(PanelWidth, SideHeight), Position = UDim2.fromOffset(BodyPadding, 6),
	BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false,
})
local SettingsPage = make("Frame", {
	Parent = Body, Size = UDim2.fromOffset(PanelWidth, SideHeight), Position = UDim2.fromOffset(BodyPadding, 6),
	BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false, Visible = false,
})
local BottomStrip = make("Frame", {
	Parent = Main, Size = UDim2.new(1, 0, 0, BottomHeight), Position = UDim2.new(0, 0, 1, -BottomHeight),
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 9,
})
local BottomLine = make("Frame", {
	Parent = BottomStrip, Size = UDim2.new(1, -12, 0, 1), Position = UDim2.fromOffset(6, 0),
	BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
})
registerThemed(BottomLine, "BackgroundColor3", "Border")
local BottomVersion = make("TextLabel", {
	Parent = BottomStrip, Size = UDim2.fromOffset(72, BottomHeight - 1), AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -9, 0, 1), BackgroundTransparency = 1, Text = "1.6.1",
	TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right,
})
registerThemed(BottomVersion, "TextColor3", "Text")
local setSettingsPage
do
local SettingsIconAssetId = 76349806024559
local SettingsOpen = false
local SettingsBtn = make("TextButton", {
	Parent = BottomStrip, Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 3, 0.5, 1), BackgroundColor3 = Theme.Highlight, BackgroundTransparency = 1,
	BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 10,
})
local SettingsIcon = make("ImageLabel", {
	Parent = SettingsBtn, Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Image = "",
	ImageColor3 = Theme.Logo, ScaleType = Enum.ScaleType.Fit, ZIndex = 11,
})
registerThemed(SettingsIcon, "ImageColor3", "Logo")
if type(SettingsIconAssetId) == "string" and SettingsIconAssetId ~= "" then
	SettingsIcon.Image = SettingsIconAssetId
elseif type(SettingsIconAssetId) == "number" and SettingsIconAssetId ~= 0 then
	SettingsIcon.Image = "rbxthumb://type=Asset&id=" .. SettingsIconAssetId .. "&w=150&h=150"
	task.spawn(function()
		local resolved = resolveDecalTexture(SettingsIconAssetId)
		if resolved and resolved ~= "" and SettingsIcon.Parent then SettingsIcon.Image = resolved end
	end)
end
local SettingsHoverDelay = 0.3
local SettingsTickAngle = 25
local settingsHoverToken = 0
local settingsTicked = false
local settingsClickedWhileHover = false
local settingsRotateTween
local function rotateSettingsIcon(angle, duration)
	if settingsRotateTween then settingsRotateTween:Cancel() end
	settingsRotateTween = TweenService:Create(SettingsIcon, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = angle })
	settingsRotateTween:Play()
end
SettingsBtn.MouseEnter:Connect(function()
	settingsHoverToken += 1
	local token = settingsHoverToken
	task.delay(SettingsHoverDelay, function()
		if token ~= settingsHoverToken or settingsTicked or settingsClickedWhileHover or not SettingsIcon.Parent then return end
		settingsTicked = true
		rotateSettingsIcon(SettingsTickAngle, 0.14)
	end)
end)
SettingsBtn.MouseLeave:Connect(function()
	settingsHoverToken += 1
	settingsClickedWhileHover = false
	if settingsTicked then
		settingsTicked = false
		rotateSettingsIcon(0, 0.18)
	end
end)
setSettingsPage = function(state)
	SettingsOpen = state
	closeDropdown()
	SharedPanel.Visible = not state
	SettingsPage.Visible = state
end
SettingsBtn.MouseButton1Click:Connect(function()
	if inputBlocked() then return end
	settingsHoverToken += 1
	settingsClickedWhileHover = true
	if settingsTicked then
		settingsTicked = false
		rotateSettingsIcon(0, 0.12)
	end
	setSettingsPage(not SettingsOpen)
end)
end
local ArrayListFrame
local ArrayCornerNames
local applyArrayPosition
do
local ArrayFrameWidth, ArrayFrameHeight = 240, 236
local ArrayRowHeight, ArrayRowGap = 18, 2
local ArrayMargin = 8
ArrayListFrame = make("Frame", {
	Parent = ScreenGui, Size = UDim2.fromOffset(ArrayFrameWidth, ArrayFrameHeight), AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(-28, 8), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 14,
})
local ArrayListNames = {
	Camlock = "Camlock", Silent = "Silent Aim", Fly = "Fly", Noclip = "Noclip", Maxzoom = "Maxzoom",
	AntiAfk = "Anti AFK", InfJump = "Inf Jump", AntiSeat = "Anti-Seat", AutoPickup = "Auto Pickup", Spinbot = "Spinbot",
}
local EspToggles = { "NameEsp","Tracers","FriendEsp","Skeleton","BoxOutline","BoxCorners","Box3D","Box3DCorners","HealthBars","Distance","ShowItems" }
ArrayCornerNames = { "Btm Right", "Btm Left", "Top Right", "Top Left" }
local ArrayCorners = {
	["Btm Right"] = { left = false, top = false, bottom = true },
	["Btm Left"] = { left = true, top = false, bottom = true },
	["Top Right"] = { left = false, top = true, bottom = false },
	["Top Left"] = { left = true, top = true, bottom = false },
}
local arrayLabelActive = {}
local arrayLabelTweens = {}
local arrayPositionTween
local function arrayLabelWidth(name)
	local measured = TextService:GetTextSize(name, 13, Enum.Font.GothamMedium, Vector2.new(1000, ArrayRowHeight))
	return math.ceil(measured.X) + 10
end
local function tweenArrayLabel(label, properties, duration, onComplete)
	local old = arrayLabelTweens[label]
	if old then pcall(function() old:Cancel() end) end
	local effect = TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
	arrayLabelTweens[label] = effect
	effect.Completed:Connect(function(status)
		if arrayLabelTweens[label] == effect then
			arrayLabelTweens[label] = nil
			if status == Enum.PlaybackState.Completed and onComplete then onComplete() end
		end
	end)
	effect:Play()
	return effect
end
local function arrayListItems()
	local items = {}
	for _, key in ipairs({ "Camlock", "Silent" }) do
		if State.Toggles[key] then items[#items + 1] = { key = key, name = ArrayListNames[key] } end
	end
	for _, key in ipairs(EspToggles) do
		if State.Toggles[key] then items[#items + 1] = { key = "ESP", name = "ESP" } break end
	end
	for _, key in ipairs({ "Fly", "Noclip", "Maxzoom", "AntiAfk", "InfJump", "AntiSeat", "AutoPickup", "Spinbot" }) do
		if State.Toggles[key] then items[#items + 1] = { key = key, name = ArrayListNames[key] } end
	end
	table.sort(items, function(a, b)
		local widthA, widthB = arrayLabelWidth(a.name), arrayLabelWidth(b.name)
		if widthA == widthB then return a.name < b.name end
		return widthA < widthB
	end)
	return items
end
refreshArrayList = function()
	local items = arrayListItems()
	local active = {}
	local corner = ArrayCorners[State.ArrayPosition] or ArrayCorners["Btm Left"]
	local totalHeight = #items * ArrayRowHeight + math.max(0, #items - 1) * ArrayRowGap
	local firstY = corner.bottom and math.max(0, ArrayFrameHeight - totalHeight) or 0
	for index, item in ipairs(items) do
		active[item.key] = true
		local label = arrayListLabels[item.key]
		local width = arrayLabelWidth(item.name)
		local targetX = corner.left and 0 or ArrayFrameWidth - width
		local targetY = firstY + (index - 1) * (ArrayRowHeight + ArrayRowGap)
		if not label then
			label = make("TextLabel", {
				Parent = ArrayListFrame, Size = UDim2.fromOffset(0, 0), Position = UDim2.fromOffset(corner.left and -14 or ArrayFrameWidth + 14, targetY + 4),
				BackgroundColor3 = Theme.Background, BackgroundTransparency = 1, BorderSizePixel = 0,
				Text = item.name, TextColor3 = Theme.Text, TextTransparency = 1, TextSize = 13, Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14,
			})
			local stroke = make("UIStroke", { Parent = label, Color = Theme.Border, Thickness = 1.1, Transparency = 0.28 })
			registerThemed(stroke, "Color", "Border")
			registerThemed(label, "BackgroundColor3", "Background")
			registerThemed(label, "TextColor3", "Text")
			make("UIPadding", { Parent = label, PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) })
			arrayListLabels[item.key] = label
		end
		if label.Text ~= item.name then
			label.TextTransparency = 1
			label.Text = item.name
		end
		if not arrayLabelActive[item.key] then
			label.Visible = true
			label.Position = UDim2.fromOffset(corner.left and -14 or ArrayFrameWidth + 14, targetY + 4)
			label.Size = UDim2.fromOffset(0, ArrayRowHeight)
			label.BackgroundTransparency = 1
			label.TextTransparency = 1
		end
		arrayLabelActive[item.key] = true
		tweenArrayLabel(label, {
			Position = UDim2.fromOffset(targetX, targetY),
			Size = UDim2.fromOffset(width, ArrayRowHeight),
			BackgroundTransparency = 0.18,
			TextTransparency = 0,
		}, 0.24)
	end
	for key, label in pairs(arrayListLabels) do
		if not active[key] and arrayLabelActive[key] then
			arrayLabelActive[key] = false
			local exitX = corner.left and -16 or ArrayFrameWidth + 16
			tweenArrayLabel(label, {
				Position = UDim2.fromOffset(exitX, label.Position.Y.Offset + 3),
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}, 0.17, function()
				if not arrayLabelActive[key] then label.Visible = false end
			end)
		end
	end
end
refreshArrayList()
applyArrayPosition = function()
	local corner = ArrayCorners[State.ArrayPosition] or ArrayCorners["Btm Left"]
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local x = corner.left and ArrayMargin or math.max(ArrayMargin, viewport.X - ArrayFrameWidth - ArrayMargin)
	local y = corner.top and ArrayMargin or math.max(ArrayMargin, viewport.Y - ArrayFrameHeight - ArrayMargin)
	if arrayPositionTween then pcall(function() arrayPositionTween:Cancel() end) end
	arrayPositionTween = TweenService:Create(ArrayListFrame, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(x, y),
	})
	arrayPositionTween:Play()
	if refreshArrayList then refreshArrayList() end
end
local arrayViewportConnection
local function bindArrayViewport()
	if arrayViewportConnection then
		arrayViewportConnection:Disconnect()
		arrayViewportConnection = nil
	end
	local camera = workspace.CurrentCamera
	if camera then
		arrayViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyArrayPosition)
		table.insert(Connections, arrayViewportConnection)
	end
end
bindArrayViewport()
table.insert(Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindArrayViewport()
	applyArrayPosition()
end))
ToggleCallbacks.ArrayList = function(on)
	ArrayListFrame.Visible = on
	if on then refreshArrayList() end
end
end
local ColumnGap, ColumnPadding = 8, 7
local AvailableColumnWidth = PanelWidth - ColumnPadding * 2 - ColumnGap
local LeftColumnWidth = math.floor(AvailableColumnWidth * 0.5)
local RightColumnWidth = AvailableColumnWidth - LeftColumnWidth
local ScrollOut = 9
local function makeSimpleColumn(xOffset, width, side)
	local isLeft = side == "left"
	local holder = make("Frame", {
		Parent = SharedPanel, Size = UDim2.fromOffset(width, SideHeight), Position = UDim2.fromOffset(xOffset, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false, ZIndex = 4,
	})
	local scroll = make("ScrollingFrame", {
		Parent = holder, Size = UDim2.new(1, ScrollOut, 1, 0), Position = UDim2.fromOffset(isLeft and -ScrollOut or 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Scroll,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.None,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", ZIndex = 4,
	})
	pcall(function()
		scroll.VerticalScrollBarPosition = isLeft and Enum.VerticalScrollBarPosition.Left or Enum.VerticalScrollBarPosition.Right
	end)
	registerThemed(scroll, "ScrollBarImageColor3", "Scroll")
	local content = make("Frame", {
		Parent = scroll, Size = UDim2.new(1, -(8 + ScrollOut), 0, 0),
		Position = UDim2.fromOffset(isLeft and (4 + ScrollOut) or 4, 6),
		BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4,
	})
	local layout = make("UIListLayout", { Parent = content, Padding = UDim.new(0, SectionGap), SortOrder = Enum.SortOrder.LayoutOrder })
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
	end)
	return holder, scroll, content
end
local LeftContent = select(3, makeSimpleColumn(ColumnPadding, LeftColumnWidth, "left"))
local RightContent = select(3, makeSimpleColumn(ColumnPadding + LeftColumnWidth + ColumnGap, RightColumnWidth, "right"))
local function makeControlLabel(parent, text, xOffset, rightReserve, fixedTextColor)
	local lbl = make("TextLabel", {
		Parent = parent, Size = UDim2.new(1, -(xOffset + rightReserve), 1, 0), Position = UDim2.fromOffset(xOffset, 0),
		BackgroundTransparency = 1, Text = text, TextColor3 = fixedTextColor or Theme.Text, TextSize = 11,
		Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
	})
	if not fixedTextColor then registerThemed(lbl, "TextColor3", "Text") end
	return lbl
end
local function makeToggleSwitch(parent, initialStateName)
	local stateName = initialStateName
	local KnobSize, Pad = 7, 4
	local enabled = State.Toggles[stateName] == true
	local track = make("TextButton", {
		Parent = parent, Size = UDim2.fromOffset(ToggleWidth, ToggleHeight), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -5, 0.5, 0),
		BackgroundColor3 = enabled and Theme.SliderFill or Theme.Track,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	})
	make("UICorner", { Parent = track, CornerRadius = UDim.new(1, 0) })
	local function knobPos(on)
		return on and UDim2.new(1, -(KnobSize + Pad), 0.5, 0) or UDim2.new(0, Pad, 0.5, 0)
	end
	local knob = make("Frame", {
		Parent = track, Size = UDim2.fromOffset(KnobSize, KnobSize), AnchorPoint = Vector2.new(0, 0.5),
		Position = knobPos(enabled),
		BackgroundColor3 = enabled and Theme.Track or Theme.SliderFill, BorderSizePixel = 0, ZIndex = track.ZIndex + 2,
	})
	make("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })
	local activeTweens = {}
	local function stopTweens()
		for _, t in ipairs(activeTweens) do t:Cancel() end
		table.clear(activeTweens)
	end
	local function play(object, duration, style, props)
		local t = TweenService:Create(object, TweenInfo.new(duration, style, Enum.EasingDirection.Out), props)
		table.insert(activeTweens, t)
		t:Play()
	end
	local function updateInstant()
		stopTweens()
		local on = State.Toggles[stateName] == true
		track.BackgroundColor3 = on and Theme.SliderFill or Theme.Track
		knob.BackgroundColor3 = on and Theme.Track or Theme.SliderFill
		knob.Position = knobPos(on)
	end
	local function animate()
		stopTweens()
		local on = State.Toggles[stateName] == true
		play(track, 0.16, Enum.EasingStyle.Sine, { BackgroundColor3 = on and Theme.SliderFill or Theme.Track })
		play(knob, 0.16, Enum.EasingStyle.Sine, { BackgroundColor3 = on and Theme.Track or Theme.SliderFill })
		play(knob, 0.2, Enum.EasingStyle.Quint, { Position = knobPos(on) })
	end
	local lastActivation = 0
	local function activateToggle()
		if inputBlocked() then return end
		if TemporarilyDisabledToggles[stateName] then
			State.Toggles[stateName] = false
			updateInstant()
			return
		end
		local now = os.clock()
		if now - lastActivation < 0.05 then return end
		lastActivation = now
		State.Toggles[stateName] = not State.Toggles[stateName]
		animate()
		local callback = ToggleCallbacks[stateName]
		if callback then pcall(callback, State.Toggles[stateName]) end
		if refreshArrayList then refreshArrayList() end
	end
	track.MouseButton1Click:Connect(activateToggle)
	local entry = { track = track, knob = knob, stateName = stateName, update = updateInstant, animate = animate }
	table.insert(themedToggles, entry)
	local function rebind(newStateName)
		stateName = newStateName
		entry.stateName = newStateName
		animate()
	end
	return track, activateToggle, rebind
end
local waitingForKey = nil
local function makeKeybindBox(parent, initialStateName, opts)
	opts = opts or {}
	local stateName = initialStateName
	local Box = make("TextButton", {
		Parent = parent, Size = UDim2.fromOffset(38, 18), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -5, 0.5, 0), BackgroundColor3 = Theme.Checkbox, BorderColor3 = Theme.CheckboxBorder,
		BackgroundTransparency = ControlTransparency, BorderSizePixel = 0, Text = shortKeyName(State.Keybinds[stateName]), TextColor3 = Theme.Text,
		TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
	})
	local ClearBind = make("TextButton", {
		Parent = parent, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -46, 0.5, 0), BackgroundColor3 = Theme.Highlight, BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = "X", TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
	})
	registerThemed(ClearBind, "TextColor3", "Text")
	registerThemed(ClearBind, "BackgroundColor3", "Highlight")
	make("UICorner", { Parent = ClearBind, CornerRadius = UDim.new(1, 0) })
	local function syncClear()
		ClearBind.Visible = not opts.NoClear and Box.Text ~= "Set" and Box.Text ~= ""
	end
	Box:GetPropertyChangedSignal("Text"):Connect(syncClear)
	syncClear()
	ClearBind.MouseEnter:Connect(function()
		tween(ClearBind, 0.1, { BackgroundTransparency = 0.82 })
	end)
	ClearBind.MouseLeave:Connect(function() tween(ClearBind, 0.1, { BackgroundTransparency = 1 }) end)
	ClearBind.MouseButton1Click:Connect(function()
		if inputBlocked() then return end
		State.Keybinds[stateName] = nil
		Box.Text = "Set"
		if waitingForKey and waitingForKey.Box == Box then waitingForKey = nil end
		if opts.OnChange then pcall(opts.OnChange) end
	end)
	table.insert(themedKeybinds, Box)
	table.insert(keybindSyncs, function()
		if waitingForKey and waitingForKey.Box == Box then waitingForKey = nil end
		Box.Text = shortKeyName(State.Keybinds[stateName])
	end)
	Box.MouseEnter:Connect(function() tween(Box, 0.08, { BackgroundColor3 = Theme.CheckboxHover }) end)
	Box.MouseLeave:Connect(function() tween(Box, 0.08, { BackgroundColor3 = Theme.Checkbox }) end)
	Box.MouseButton1Click:Connect(function()
		if inputBlocked() then return end
		if waitingForKey and waitingForKey.Box ~= Box then
			waitingForKey.Box.Text = shortKeyName(State.Keybinds[waitingForKey.Name])
		end
		waitingForKey = { Name = stateName, Box = Box, Opts = opts }
		Box.Text = ""
	end)
	local function rebind(newStateName)
		if waitingForKey and waitingForKey.Box == Box then waitingForKey = nil end
		stateName = newStateName
		Box.Text = shortKeyName(State.Keybinds[stateName])
	end
	return Box, rebind
end
local activeSlider = nil
local SliderTrackHeight = 5
local function makeSliderControl(parent, initialSliderName, xOffset, yOffset, width)
	local sliderName = initialSliderName
	local sliderWidth, trackX, trackY = width or 42, xOffset or 0, yOffset or 0
	local alpha = valueToAlpha(sliderName, State.Sliders[sliderName])
	local Track = make("TextButton", {
		Parent = parent, Size = UDim2.fromOffset(sliderWidth, SliderTrackHeight), Position = UDim2.fromOffset(trackX, trackY),
		BackgroundColor3 = Theme.Track, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	})
	make("UICorner", { Parent = Track, CornerRadius = UDim.new(1, 0) })
	local Fill = make("Frame", {
		Parent = Track, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.SliderFill, BorderSizePixel = 0,
	})
	make("UICorner", { Parent = Fill, CornerRadius = UDim.new(1, 0) })
	local Cap = make("Frame", {
		Parent = Track, Size = UDim2.fromOffset(0, SliderTrackHeight), BackgroundColor3 = Theme.SliderFill,
		BorderSizePixel = 0, Visible = false,
	})
	local ValueLabel = make("TextLabel", {
		Parent = parent, Size = UDim2.fromOffset(34, 14), Position = UDim2.fromOffset(trackX, math.max(0, trackY - 13)),
		BackgroundTransparency = 1, Text = formatValue(sliderName, State.Sliders[sliderName]), TextColor3 = Theme.Text,
		TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local sliderEntry = { track = Track, fill = Fill, cap = Cap, valueLabel = ValueLabel }
	table.insert(themedSliders, sliderEntry)
	local function layout()
		local w, h = Track.AbsoluteSize.X, Track.AbsoluteSize.Y
		if w <= 0 then w, h = sliderWidth, SliderTrackHeight end
		local px = math.floor(w * alpha + 0.5)
		Fill.Size = UDim2.new(0, px, 1, 0)
		local capW = math.min(h / 2, px)
		Cap.Visible = px > 0 and px < w - 1
		Cap.Position = UDim2.fromOffset(px - capW, 0)
		Cap.Size = UDim2.fromOffset(capW, h)
	end
	Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	local driver = Instance.new("NumberValue")
	driver.Value = alpha
	driver.Parent = Track
	local driverTween
	driver.Changed:Connect(function(v)
		alpha = v
		ValueLabel.Text = formatValue(sliderName, alphaToValue(sliderName, v))
		layout()
	end)
	sliderEntry.sync = function()
		if driverTween then driverTween:Cancel() driverTween = nil end
		local target = valueToAlpha(sliderName, State.Sliders[sliderName])
		driver.Value = target
		alpha = target
		ValueLabel.Text = formatValue(sliderName, State.Sliders[sliderName])
		layout()
	end
	local function setFromX(mouseX)
		if driverTween then driverTween:Cancel() driverTween = nil end
		alpha = math.clamp((mouseX - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		local value = alphaToValue(sliderName, alpha)
		State.Sliders[sliderName] = value
		ValueLabel.Text = formatValue(sliderName, value)
		layout()
	end
	local GrabArea = make("TextButton", {
		Parent = parent, Size = UDim2.fromOffset(sliderWidth + 12, 18), Position = UDim2.fromOffset(trackX - 6, trackY - 6),
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 4,
	})
	local function syncGrab()
		GrabArea.Size = UDim2.fromOffset(math.max(Track.AbsoluteSize.X, sliderWidth) + 12, 18)
	end
	Track:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncGrab)
	syncGrab()
	local function beginSlider(input)
		if inputBlocked() then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider = { Set = setFromX }
			setFromX(input.Position.X)
		end
	end
	GrabArea.InputBegan:Connect(beginSlider)
	Track.InputBegan:Connect(beginSlider)
	local function rebind(newSliderName)
		if driverTween then driverTween:Cancel() driverTween = nil end
		driver.Value = alpha
		sliderName = newSliderName
		local target = valueToAlpha(sliderName, State.Sliders[sliderName])
		local t = TweenService:Create(driver, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Value = target })
		driverTween = t
		t.Completed:Connect(function(status)
			if status == Enum.PlaybackState.Completed and driverTween == t then
				driverTween = nil
				ValueLabel.Text = formatValue(sliderName, State.Sliders[sliderName])
			end
		end)
		t:Play()
	end
	return Track, ValueLabel, rebind
end
local AimPartLabels = { "Root", "Head", "Upper Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local AimPartValues = {
	Root="HumanoidRootPart", Head="Head", ["Upper Torso"]="UpperTorso", ["Left Arm"]="LeftArm", ["Right Arm"]="RightArm",
	["Left Leg"]="LeftLeg", ["Right Leg"]="RightLeg",
}
local AimPartDisplay = {
	HumanoidRootPart="Root", Head="Head", UpperTorso="Upper Torso", LeftArm="Left Arm", RightArm="Right Arm",
	LeftLeg="Left Leg", RightLeg="Right Leg",
}
local AimPartAliases = {
	HumanoidRootPart={"HumanoidRootPart","Torso"}, Head={"Head"}, UpperTorso={"UpperTorso","Torso"},
	LeftArm={"LeftUpperArm","LeftLowerArm","LeftHand","Left Arm"}, RightArm={"RightUpperArm","RightLowerArm","RightHand","Right Arm"},
	LeftLeg={"LeftUpperLeg","LeftLowerLeg","LeftFoot","Left Leg"}, RightLeg={"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"},
}
local SilentMethodLabels = { "Raycast", "FPOR", "FPORWWL", "FPORWIL", "Mouse" }
local SilentMethodValues = {
	Raycast = "Raycast", FPOR = "FindPartOnRay", FPORWWL = "FindPartOnRayWithWhitelist",
	FPORWIL = "FindPartOnRayWithIgnoreList", Mouse = "Mouse.Hit/Target",
}
local SilentMethodDisplay = {}
for short, full in pairs(SilentMethodValues) do SilentMethodDisplay[full] = short end
local ChevronAssetId = 79521530937277
local ChevronImage = "rbxthumb://type=Asset&id=" .. ChevronAssetId .. "&w=150&h=150"
local chevronLabels = {}
task.spawn(function()
	local resolved = resolveDecalTexture(ChevronAssetId)
	if resolved and resolved ~= "" then
		ChevronImage = resolved
		for _, c in ipairs(chevronLabels) do
			if c.Parent then c.Image = resolved end
		end
	end
end)
local function makeSimpleRowBase(parent, height)
	return make("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, height or RowHeight), BackgroundTransparency = 1, BorderSizePixel = 0 })
end
local function makeSimpleHoverOverlay(parent)
	local hover = make("Frame", {
		Parent = parent, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Highlight,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0,
	})
	registerThemed(hover, "BackgroundColor3", "Highlight")
	return hover
end
local function hookHover(row, hover, amount)
	row.MouseEnter:Connect(function()
		if isOverDropdown() then return end
		tween(hover, 0.08, { BackgroundTransparency = amount })
	end)
	row.MouseLeave:Connect(function() tween(hover, 0.08, { BackgroundTransparency = 1 }) end)
end
local function makeSimpleSection(parent, title, startOpen, bottomGap)
	local open = startOpen and true or false
	local headerHeight = 24
	local leftInset = 6
	local titleSize = 10
	local wrapper = make("Frame", {
		Parent = parent, Size = UDim2.new(1, 0, 0, headerHeight), BackgroundTransparency = 1,
		BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.None,
	})
	make("UIListLayout", { Parent = wrapper, Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	local header = make("TextButton", {
		Parent = wrapper, Size = UDim2.new(1, 0, 0, headerHeight), BackgroundColor3 = Theme.Highlight,
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	})
	registerThemed(header, "BackgroundColor3", "Highlight")
	local label = make("TextLabel", {
		Parent = header, Size = UDim2.fromOffset(90, headerHeight), Position = UDim2.fromOffset(leftInset, 0),
		BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Text, TextSize = titleSize,
		Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
	})
	registerThemed(label, "TextColor3", "Text")
	local collapseCircle = make("Frame", {
		Parent = header, Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -3, 0.5, 0), BackgroundColor3 = Theme.Highlight,
		BackgroundTransparency = 1, BorderSizePixel = 0,
	})
	registerThemed(collapseCircle, "BackgroundColor3", "Highlight")
	make("UICorner", { Parent = collapseCircle, CornerRadius = UDim.new(1, 0) })
	local collapse = make("TextLabel", {
		Parent = header, Size = UDim2.fromOffset(16, headerHeight), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1, Text = open and "−" or "+",
		TextColor3 = Theme.Subtext, TextSize = 16, Font = Enum.Font.Gotham,
	})
	registerThemed(collapse, "TextColor3", "Subtext")
	local rule = make("Frame", {
		Parent = header, Size = UDim2.fromOffset(40, 1),
		Position = UDim2.fromOffset(leftInset + 50, headerHeight / 2 + RuleNudge),
		BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.38, BorderSizePixel = 0,
	})
	registerThemed(rule, "BackgroundColor3", "Rule")
	make("UIGradient", {
		Parent = rule,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	})
	local function updateRule()
		local ruleX = math.floor(leftInset + label.TextBounds.X + 8)
		local width = math.max(18, math.floor(header.AbsoluteSize.X - ruleX - 24))
		rule.Position = UDim2.fromOffset(ruleX, headerHeight / 2 + RuleNudge)
		rule.Size = UDim2.fromOffset(width, 1)
	end
	label:GetPropertyChangedSignal("TextBounds"):Connect(updateRule)
	header:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateRule)
	table.insert(themedBranches, { button = header, icon = collapse, label = label })
	local bodyFrame = make("Frame", {
		Parent = wrapper, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
	})
	local body = make("Frame", {
		Parent = bodyFrame, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, RowGap),
		BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y,
	})
	local bodyLayout = make("UIListLayout", {
		Parent = body, Padding = UDim.new(0, RowGap), SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local openness = Instance.new("NumberValue")
	openness.Value = open and 1 or 0
	openness.Parent = header
	local function update()
		local full = bodyLayout.AbsoluteContentSize.Y + RowGap
		local targetHeight = math.floor(full * openness.Value + 0.5)
		local extra = math.floor((bottomGap or 0) * openness.Value + 0.5)
		bodyFrame.Size = UDim2.new(1, 0, 0, targetHeight)
		wrapper.Size = UDim2.new(1, 0, 0, headerHeight + targetHeight + extra)
		updateRule()
	end
	openness.Changed:Connect(update)
	local openTween
	bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	header.MouseEnter:Connect(function()
		if isOverDropdown() then return end
		tween(collapseCircle, 0.08, { BackgroundTransparency = 0.82 })
		tween(collapse, 0.08, { TextColor3 = Theme.Text })
		tween(rule, 0.08, { BackgroundTransparency = 0.20 })
	end)
	header.MouseLeave:Connect(function()
		tween(collapseCircle, 0.08, { BackgroundTransparency = 1 })
		tween(collapse, 0.08, { TextColor3 = Theme.Subtext })
		tween(rule, 0.08, { BackgroundTransparency = 0.38 })
	end)
	header.MouseButton1Click:Connect(function()
		if inputBlocked() then return end
		closeDropdown()
		open = not open
		collapse.Text = open and "−" or "+"
		if openTween then openTween:Cancel() end
		openTween = TweenService:Create(openness, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Value = open and 1 or 0 })
		openTween:Play()
	end)
	update()
	return body, wrapper
end
local function makeSimpleToggleRow(parent, textValue, stateName)
	local disabled = TemporarilyDisabledToggles[stateName] == true
	if disabled then State.Toggles[stateName] = false end
	local row = make("TextButton", {
		Parent = parent, Size = UDim2.new(1, 0, 0, RowHeight), BackgroundTransparency = 1,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	})
	local hover = makeSimpleHoverOverlay(row)
	makeControlLabel(row, textValue, 8, 34, disabled and DisabledToggleTextColor or nil)
	local track, activateToggle, rebind = makeToggleSwitch(row, stateName)
	hookHover(row, hover, 0.86)
	row.MouseButton1Click:Connect(activateToggle)
	return row, rebind
end
local function makeSimpleKeybindRow(parent, textValue, stateName, opts)
	local row = makeSimpleRowBase(parent, RowHeight)
	makeControlLabel(row, textValue, 8, 42)
	local _, rebind = makeKeybindBox(row, stateName, opts)
	return row, rebind
end
local function makeSimpleSliderRow(parent, textValue, sliderName)
	local row = makeSimpleRowBase(parent, SliderRowHeight)
	local labelX = 8
	local nameLabel = makeControlLabel(row, textValue, labelX, 34)
	nameLabel.Size = UDim2.new(1, -(labelX + 34), 0, 13)
	nameLabel.Position = UDim2.fromOffset(labelX, 5)
	local sliderX, sliderY = labelX, 22
	local track, valueLabel, rebind = makeSliderControl(row, sliderName, sliderX, sliderY, 64)
	valueLabel.Position = UDim2.fromOffset(labelX + nameLabel.TextBounds.X + 7, 5)
	valueLabel.Size = UDim2.fromOffset(48, 13)
	track.Size = UDim2.fromOffset(math.max(48, row.AbsoluteSize.X - sliderX - 12), SliderTrackHeight)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		track.Size = UDim2.fromOffset(math.max(48, row.AbsoluteSize.X - sliderX - 12), SliderTrackHeight)
		valueLabel.Position = UDim2.fromOffset(labelX + nameLabel.TextBounds.X + 7, 5)
	end)
	nameLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		valueLabel.Position = UDim2.fromOffset(labelX + nameLabel.TextBounds.X + 7, 5)
	end)
	return row, rebind
end
local function makeSimpleChoiceRow(parent, textValue, options, getValue, setValue)
	local collapsedH = DropdownHeaderHeight
	local expandedH = math.min(#options, MaxDropdownOptions) * DropdownOptionHeight
	local rowPad = RowHeight - collapsedH
	local row = makeSimpleRowBase(parent, RowHeight)
	local label = makeControlLabel(row, textValue, 8, DropdownWidth + 14)
	label.Size = UDim2.new(1, -(8 + DropdownWidth + 14), 0, RowHeight)
	local shell = make("Frame", {
		Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, rowPad / 2),
		Size = UDim2.fromOffset(DropdownWidth, collapsedH), BackgroundColor3 = Theme.Checkbox,
		BackgroundTransparency = ControlTransparency, BorderSizePixel = 0, ZIndex = 2,
	})
	registerThemed(shell, "BackgroundColor3", "Checkbox")
	local header = make("TextButton", {
		Parent = shell, Size = UDim2.new(1, 0, 0, collapsedH), BackgroundColor3 = Theme.Highlight,
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 3,
	})
	registerThemed(header, "BackgroundColor3", "Highlight")
	local selectedLabel = make("TextLabel", {
		Parent = header, Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 1, Text = getValue(),
		TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4,
	})
	registerThemed(selectedLabel, "TextColor3", "Text")
	make("UIPadding", { Parent = selectedLabel, PaddingLeft = UDim.new(0, 7) })
	local chevron = make("ImageLabel", {
		Parent = header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Image = ChevronImage,
		ImageColor3 = Theme.Chevron, ScaleType = Enum.ScaleType.Fit, ZIndex = 4,
	})
	registerThemed(chevron, "ImageColor3", "Chevron")
	table.insert(chevronLabels, chevron)
	table.insert(choiceSyncs, function() selectedLabel.Text = getValue() end)
	header.MouseEnter:Connect(function() tween(header, 0.1, { BackgroundTransparency = 0.88 }) end)
	header.MouseLeave:Connect(function() tween(header, 0.1, { BackgroundTransparency = 1 }) end)
	local popup = make("ScrollingFrame", {
		Parent = Main, Size = UDim2.fromOffset(DropdownWidth, 0), Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Checkbox, BackgroundTransparency = 0.04, BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false, ZIndex = 100, Active = true,
		CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 0, ScrollBarImageColor3 = Theme.Scroll,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.None,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
	})
	registerThemed(popup, "BackgroundColor3", "Checkbox")
	registerThemed(popup, "ScrollBarImageColor3", "Scroll")
	local hovered = {}
	local function trackHover(obj, isPopupPart)
		obj.MouseEnter:Connect(function()
			hovered[obj] = true
			if isPopupPart then dropdownHovered[obj] = true end
		end)
		obj.MouseLeave:Connect(function()
			hovered[obj] = nil
			if isPopupPart then dropdownHovered[obj] = nil end
		end)
	end
	local function isHovering()
		return next(hovered) ~= nil
	end
	trackHover(shell)
	trackHover(header)
	trackHover(popup, true)
	local isOpen = false
	local openTween, chevronTween, outsideConn, followConn, myClose
	local setOpen
	local optionButtons, optionEntries = {}, {}
	local function optionRestTransparency(index)
		return options[index] == getValue() and 0.5 or 1
	end
	local function buildOptions()
		for _, o in ipairs(optionButtons) do
			dropdownHovered[o] = nil
			hovered[o] = nil
			for _, entry in ipairs(optionEntries[o] or {}) do unregisterThemed(entry) end
			optionEntries[o] = nil
			themeTweens[o] = nil
			o:Destroy()
		end
		table.clear(optionButtons)
		expandedH = math.min(#options, MaxDropdownOptions) * DropdownOptionHeight
		popup.CanvasSize = UDim2.fromOffset(0, #options * DropdownOptionHeight)
		popup.ScrollBarThickness = #options > MaxDropdownOptions and 2 or 0
		for index, optionText in ipairs(options) do
			local option = make("TextButton", {
				Parent = popup, Position = UDim2.fromOffset(0, (index - 1) * DropdownOptionHeight),
				Size = UDim2.new(1, 0, 0, DropdownOptionHeight), BackgroundColor3 = Theme.CheckboxHover,
				BackgroundTransparency = 1, BorderSizePixel = 0, Text = optionText, TextColor3 = Theme.Text,
				TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false, ZIndex = 101,
			})
			optionEntries[option] = {
				registerThemed(option, "BackgroundColor3", "CheckboxHover"),
				registerThemed(option, "TextColor3", "Text"),
			}
			trackHover(option, true)
			make("UIPadding", { Parent = option, PaddingLeft = UDim.new(0, 7) })
			option.MouseEnter:Connect(function() tween(option, 0.08, { BackgroundTransparency = 0.25 }) end)
			option.MouseLeave:Connect(function() tween(option, 0.08, { BackgroundTransparency = optionRestTransparency(index) }) end)
			option.MouseButton1Click:Connect(function()
				if inputBlocked() then return end
				setValue(optionText)
				selectedLabel.Text = getValue()
				setOpen(false)
			end)
			optionButtons[index] = option
		end
	end
	local progress = Instance.new("NumberValue")
	progress.Parent = shell
	progress.Changed:Connect(function(p)
		popup.Size = UDim2.fromOffset(DropdownWidth, math.floor(expandedH * p + 0.5))
	end)
	local function syncPopup()
		local p, m = shell.AbsolutePosition, Main.AbsolutePosition
		popup.Position = UDim2.fromOffset(p.X - m.X, p.Y - m.Y + collapsedH)
	end
	setOpen = function(state)
		if isOpen == state then return end
		isOpen = state
		if openTween then openTween:Cancel() openTween = nil end
		if chevronTween then chevronTween:Cancel() chevronTween = nil end
		if outsideConn then outsideConn:Disconnect() outsideConn = nil end
		if followConn then followConn:Disconnect() followConn = nil end
		if state then
			closeDropdown()
			myClose = function() setOpen(false) end
			activeDropdownClose = myClose
			for index, option in ipairs(optionButtons) do
				option.BackgroundTransparency = optionRestTransparency(index)
			end
			popup.CanvasPosition = Vector2.new(0, 0)
			syncPopup()
			popup.Visible = true
			outsideConn = UserInputService.InputBegan:Connect(function(input)
				if input.KeyCode == Enum.KeyCode.Escape then setOpen(false) return end
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				if isHovering() then return end
				setOpen(false)
			end)
			followConn = RunService.RenderStepped:Connect(function()
				if not shell.Parent or not Main.Visible then setOpen(false) return end
				local pp, ps = SharedPanel.AbsolutePosition, SharedPanel.AbsoluteSize
				local sp = shell.AbsolutePosition
				if sp.Y < pp.Y or sp.Y + collapsedH > pp.Y + ps.Y then setOpen(false) return end
				syncPopup()
			end)
		elseif activeDropdownClose == myClose then
			activeDropdownClose = nil
		end
		chevronTween = TweenService:Create(chevron, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = state and 180 or 0,
		})
		chevronTween:Play()
		local t = TweenService:Create(progress, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Value = state and 1 or 0,
		})
		openTween = t
		t.Completed:Connect(function(status)
			if status == Enum.PlaybackState.Completed and not isOpen then
				popup.Visible = false
				dropdownHovered[popup] = nil
				for _, o in ipairs(optionButtons) do dropdownHovered[o] = nil; hovered[o] = nil end
				hovered[popup] = nil
			end
		end)
		t:Play()
	end
	header.MouseButton1Click:Connect(function()
		if inputBlocked() then return end
		if #options == 0 then return end
		setOpen(not isOpen)
	end)
	buildOptions()
	local function rebuild(newOptions)
		if newOptions then options = newOptions end
		if isOpen then setOpen(false) end
		buildOptions()
		selectedLabel.Text = getValue()
	end
	return row, nil, rebuild
end
local function makeSimpleCycleRow(parent, textValue, options, getValue, setValue)
	local row = makeSimpleRowBase(parent, RowHeight)
	local ArrowSize, ValueWidth, Margin = 16, 66, 5
	makeControlLabel(row, textValue, 8, ArrowSize * 2 + ValueWidth + Margin + 8)
	local function arrow(glyph, rightOffset)
		local btn = make("TextButton", {
			Parent = row, Size = UDim2.fromOffset(ArrowSize, ArrowSize), AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -rightOffset, 0.5, 0), BackgroundColor3 = Theme.Highlight,
			BackgroundTransparency = 1, BorderSizePixel = 0, Text = glyph, TextColor3 = Theme.Text,
			TextSize = 12, Font = Enum.Font.GothamMedium, AutoButtonColor = false,
		})
		registerThemed(btn, "TextColor3", "Text")
		registerThemed(btn, "BackgroundColor3", "Highlight")
		make("UICorner", { Parent = btn, CornerRadius = UDim.new(1, 0) })
		btn.MouseEnter:Connect(function()
			tween(btn, 0.1, { BackgroundTransparency = 0.82 })
		end)
		btn.MouseLeave:Connect(function() tween(btn, 0.1, { BackgroundTransparency = 1 }) end)
		return btn
	end
	local rightArrow = arrow(">", Margin)
	local valueClip = make("Frame", {
		Parent = row, Size = UDim2.fromOffset(ValueWidth, ArrowSize), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(Margin + ArrowSize), 0.5, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ClipsDescendants = true,
	})
	local function makeValueLabel(text, x)
		local lbl = make("TextLabel", {
			Parent = valueClip, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(x, 0),
			BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, TextSize = 10,
			Font = Enum.Font.GothamMedium,
		})
		local entry = registerThemed(lbl, "TextColor3", "Text")
		return lbl, entry
	end
	local leftArrow = arrow("<", Margin + ArrowSize + ValueWidth)
	local current, currentEntry = makeValueLabel(getValue(), 0)
	table.insert(choiceSyncs, function() current.Text = getValue() end)
	local function step(direction)
		if inputBlocked() then return end
		local index = table.find(options, getValue()) or 1
		index = ((index - 1 + direction) % #options) + 1
		setValue(options[index])
		local outgoing, outgoingEntry = current, currentEntry
		current, currentEntry = makeValueLabel(getValue(), -direction * ValueWidth)
		local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(current, info, { Position = UDim2.fromOffset(0, 0) }):Play()
		local out = TweenService:Create(outgoing, info, { Position = UDim2.fromOffset(direction * ValueWidth, 0) })
		out.Completed:Connect(function()
			local i = table.find(themedObjects, outgoingEntry)
			if i then table.remove(themedObjects, i) end
			themeTweens[outgoing] = nil
			outgoing:Destroy()
		end)
		out:Play()
	end
	leftArrow.MouseButton1Click:Connect(function() step(-1) end)
	rightArrow.MouseButton1Click:Connect(function() step(1) end)
	return row
end
local function makeSimpleTextBoxRow(parent, placeholder)
	local row = makeSimpleRowBase(parent, RowHeight)
	local box = make("TextBox", {
		Parent = row, Size = UDim2.new(1, -10, 0, 18), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Theme.Checkbox, BackgroundTransparency = ControlTransparency,
		BorderSizePixel = 0, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Theme.Subtext,
		TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ClipsDescendants = true,
	})
	registerThemed(box, "BackgroundColor3", "Checkbox")
	registerThemed(box, "TextColor3", "Text")
	registerThemed(box, "PlaceholderColor3", "Subtext")
	make("UIPadding", { Parent = box, PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) })
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = box.Text:gsub("[^%w _%-]", ""):sub(1, 24)
		if cleaned ~= box.Text then box.Text = cleaned end
	end)
	return row, box
end
local function makeSimpleButtonRow(parent, buttons)
	local row = makeSimpleRowBase(parent, RowHeight)
	local holder = make("Frame", {
		Parent = row, Size = UDim2.new(1, -10, 0, 18), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
	})
	make("UIListLayout", {
		Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local n = #buttons
	for i, def in ipairs(buttons) do
		local btn = make("TextButton", {
			Parent = holder, Size = UDim2.new(1 / n, -(4 * (n - 1)) / n, 1, 0), BackgroundColor3 = Theme.Checkbox,
			BackgroundTransparency = ControlTransparency, BorderSizePixel = 0, Text = def[1], TextColor3 = Theme.Text,
			TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, LayoutOrder = i,
		})
		registerThemed(btn, "BackgroundColor3", "Checkbox")
		registerThemed(btn, "TextColor3", "Text")
		btn.MouseEnter:Connect(function() tween(btn, 0.1, { BackgroundTransparency = math.max(0, ControlTransparency - 0.1) }) end)
		btn.MouseLeave:Connect(function() tween(btn, 0.1, { BackgroundTransparency = ControlTransparency }) end)
		btn.MouseButton1Down:Connect(function() tween(btn, 0.05, { BackgroundTransparency = 0 }) end)
		btn.MouseButton1Up:Connect(function() tween(btn, 0.1, { BackgroundTransparency = math.max(0, ControlTransparency - 0.1) }) end)
		local token = 0
		btn.MouseButton1Click:Connect(function()
			if inputBlocked() then return end
			local ok, msg = pcall(def[2])
			local shown = ok and msg or (not ok and "Error")
			if type(shown) == "string" and btn.Parent then
				token += 1
				local mine = token
				btn.Text = shown
				task.delay(1, function()
					if mine == token and btn.Parent then btn.Text = def[1] end
				end)
			end
		end)
	end
	return row
end
local function makeRevealWrapper(parent, height, shouldShow)
	local open = shouldShow() and true or false
	local wrapper = make("Frame", {
		Parent = parent, Size = UDim2.new(1, 0, 0, open and height or 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ClipsDescendants = true, Visible = open,
	})
	local openness = Instance.new("NumberValue")
	openness.Value = open and 1 or 0
	openness.Parent = wrapper
	openness.Changed:Connect(function(v)
		wrapper.Size = UDim2.new(1, 0, 0, math.floor(height * v + 0.5))
	end)
	local openTween
	table.insert(choiceSyncs, function()
		local want = shouldShow() and true or false
		if want == open then return end
		open = want
		if openTween then openTween:Cancel() end
		if want then wrapper.Visible = true end
		openTween = TweenService:Create(openness, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Value = want and 1 or 0 })
		openTween.Completed:Connect(function(status)
			if status == Enum.PlaybackState.Completed and not open then wrapper.Visible = false end
		end)
		openTween:Play()
	end)
	return wrapper
end
local setCombatType, tpSpeedRow
do
local CombatRoot = makeSimpleSection(LeftContent, "Combat", true)
State.CombatType = "Camlock"
makeSimpleCycleRow(CombatRoot, "Type", { "Camlock", "Silent Aim" },
	function() return State.CombatType end,
	function(v)
		State.CombatType = v
		closeDropdown()
		if setCombatType then setCombatType(v) end
	end)
local CombatBlock = make("Frame", {
	Parent = CombatRoot, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
})
local combatLayout = make("UIListLayout", { Parent = CombatBlock, Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })
combatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	CombatBlock.Size = UDim2.new(1, 0, 0, math.max(0, combatLayout.AbsoluteContentSize.Y - RowGap))
end)
local combatOrder = 0
local function addCombatItem(build, startOpen)
	combatOrder += 1
	local wrapper = make("Frame", {
		Parent = CombatBlock, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = combatOrder,
	})
	local row, rebind = build(wrapper)
	local openness = Instance.new("NumberValue")
	openness.Value = startOpen and 1 or 0
	openness.Parent = wrapper
	local function update()
		wrapper.Size = UDim2.new(1, 0, 0, math.floor((row.Size.Y.Offset + RowGap) * openness.Value + 0.5))
	end
	openness.Changed:Connect(update)
	row:GetPropertyChangedSignal("Size"):Connect(update)
	update()
	local openTween
	local function setOpen(state)
		if openTween then openTween:Cancel() end
		openTween = TweenService:Create(openness, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Value = state and 1 or 0,
		})
		openTween:Play()
	end
	return { Row = row, Rebind = rebind, SetOpen = setOpen }
end
local ctToggle     = addCombatItem(function(p) return makeSimpleToggleRow(p, "Toggle", "Camlock") end, true)
local ctKeybind    = addCombatItem(function(p) return makeSimpleKeybindRow(p, "Keybind", "CamLockToggle") end, true)
local ctPrediction = addCombatItem(function(p) return makeSimpleSliderRow(p, "Prediction", "Prediction") end, true)
local ctSmoothness = addCombatItem(function(p) return makeSimpleSliderRow(p, "Smoothness", "Smoothness") end, true)
local ctShowFov    = addCombatItem(function(p) return makeSimpleToggleRow(p, "Show Fov", "FovCircle") end, true)
local ctFov        = addCombatItem(function(p) return makeSimpleSliderRow(p, "Fov", "FovRadius") end, true)
setCombatType = function(v)
	local cam = v == "Camlock"
	ctToggle.Rebind(cam and "Camlock" or "Silent")
	ctKeybind.Rebind(cam and "CamLockToggle" or "SilentToggle")
	ctPrediction.Rebind(cam and "Prediction" or "SilentPrediction")
	ctShowFov.Rebind(cam and "FovCircle" or "SilentFovCircle")
	ctFov.Rebind(cam and "FovRadius" or "SilentFovRadius")
	ctSmoothness.SetOpen(cam)
end
makeSimpleChoiceRow(CombatRoot, "Aim Part", AimPartLabels,
	function() return AimPartDisplay[State.AimPart] or "Upper Torso" end,
	function(name) State.AimPart = AimPartValues[name] or "HumanoidRootPart" end)
makeSimpleToggleRow(CombatRoot, "Adaptive Aim", "AdaptiveAim")
makeSimpleToggleRow(CombatRoot, "Sticky Aim", "StickyAim")
makeSimpleToggleRow(CombatRoot, "Team Check", "TeamCheck")
makeSimpleToggleRow(CombatRoot, "Friend Check", "FriendCheck")
makeSimpleToggleRow(CombatRoot, "Wall Check", "WallCheck")
makeSimpleToggleRow(CombatRoot, "Dead Check", "DeadCheck")
makeSimpleToggleRow(CombatRoot, "Target UI", "TargetUI")
local function makeAnimatedBlock(parent)
	local block = make("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0 })
	local layout = make("UIListLayout", { Parent = block, Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		block.Size = UDim2.new(1, 0, 0, math.max(0, layout.AbsoluteContentSize.Y - RowGap))
	end)
	local order = 0
	return function(build, startOpen)
		order += 1
		local wrapper = make("Frame", {
			Parent = block, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = order,
		})
		local row, rebind = build(wrapper)
		local openness = Instance.new("NumberValue")
		openness.Value = startOpen and 1 or 0
		openness.Parent = wrapper
		local function update()
			wrapper.Size = UDim2.new(1, 0, 0, math.floor((row.Size.Y.Offset + RowGap) * openness.Value + 0.5))
		end
		openness.Changed:Connect(update)
		row:GetPropertyChangedSignal("Size"):Connect(update)
		update()
		local openTween
		local function setOpen(state)
			if openTween then openTween:Cancel() end
			openTween = TweenService:Create(openness, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Value = state and 1 or 0 })
			openTween:Play()
		end
		return { Row = row, Rebind = rebind, SetOpen = setOpen }
	end
end
local MovementSection = makeSimpleSection(LeftContent, "Movement", true)
makeSimpleChoiceRow(MovementSection, "Click Tp", { "Tween", "Instant" },
	function() return State.TpMode end,
	function(value)
		State.TpMode = value
		if tpSpeedRow then tpSpeedRow.SetOpen(value == "Tween") end
	end)
local TpBlock = makeAnimatedBlock(MovementSection)
TpBlock(function(p) return makeSimpleKeybindRow(p, "Keybind", "TweenClickTpToggle") end, true)
tpSpeedRow = TpBlock(function(p) return makeSimpleSliderRow(p, "Tween Speed", "TweenTpSpeed") end, State.TpMode == "Tween")
makeSimpleChoiceRow(MovementSection, "Fly type", { "CFrame", "Tween" },
	function() return State.FlyType end,
	function(v) State.FlyType = v end)
makeSimpleToggleRow(MovementSection, "Fly", "Fly")
makeSimpleKeybindRow(MovementSection, "Fly Toggle", "FlyToggle")
makeSimpleSliderRow(MovementSection, "Speed", "FlySpeed")
makeSimpleSliderRow(MovementSection, "Fly Multiplier", "FlyMultiplier")
local WorldSection = makeSimpleSection(LeftContent, "World", true)
makeSimpleToggleRow(WorldSection, "No Fog", "NoFog")
makeSimpleToggleRow(WorldSection, "Disable Shadows", "DisableShadows")
makeSimpleToggleRow(WorldSection, "Remove Textures", "LowGfx")
local EspRoot = makeSimpleSection(RightContent, "Esp", true, EspBottomGap)
makeSimpleChoiceRow(EspRoot, "Update rate", { "Auto", "60", "120", "144", "160", "180", "200", "240" },
	function() return State.EspUpdateRate end,
	function(v) State.EspUpdateRate = v end)
makeSimpleToggleRow(EspRoot, "Display", "NameEsp")
makeSimpleToggleRow(EspRoot, "Tracers", "Tracers")
makeSimpleToggleRow(EspRoot, "Skeleton", "Skeleton")
makeSimpleToggleRow(EspRoot, "Distance", "Distance")
makeSimpleToggleRow(EspRoot, "Item", "ShowItems")
local BoxEspSection = makeSimpleSection(EspRoot, "Box Esp", false)
makeSimpleToggleRow(BoxEspSection, "2D Box", "BoxOutline")
makeSimpleToggleRow(BoxEspSection, "2D Corners", "BoxCorners")
makeSimpleToggleRow(BoxEspSection, "3D Box", "Box3D")
makeSimpleToggleRow(BoxEspSection, "3D Corners", "Box3DCorners")
makeSimpleToggleRow(BoxEspSection, "Healthbar", "HealthBars")
local IndicatorsSection = makeSimpleSection(EspRoot, "Indicators", false)
makeSimpleToggleRow(IndicatorsSection, "Friend Indicator", "FriendEsp")
makeSimpleToggleRow(IndicatorsSection, "Team Check", "EspTeamCheck")
local PlayerSection = makeSimpleSection(RightContent, "Player", true)
makeSimpleToggleRow(PlayerSection, "Noclip", "Noclip")
makeSimpleToggleRow(PlayerSection, "Maxzoom", "Maxzoom")
makeSimpleToggleRow(PlayerSection, "Spinbot", "Spinbot")
makeSimpleSliderRow(PlayerSection, "Spin Speed", "SpinSpeed")
local MiscSection = makeSimpleSection(RightContent, "Misc", false)
makeSimpleToggleRow(MiscSection, "Inf Jump", "InfJump")
makeSimpleToggleRow(MiscSection, "Anti-Seat", "AntiSeat")
makeSimpleToggleRow(MiscSection, "Anti AFK", "AntiAfk")
makeSimpleToggleRow(MiscSection, "Auto Pickup", "AutoPickup")
end
local setThemePreset
do
local SettingsScroll = make("ScrollingFrame", {
	Parent = SettingsPage, Size = UDim2.new(1, ScrollOut, 1, 0), Position = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Scroll, ScrollingDirection = Enum.ScrollingDirection.Y,
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
	MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
	BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png", ZIndex = 4,
})
pcall(function() SettingsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right end)
registerThemed(SettingsScroll, "ScrollBarImageColor3", "Scroll")
local function makeSettingsColumn(xOffset, width)
	local col = make("Frame", {
		Parent = SettingsScroll, Size = UDim2.new(0, width - 8, 0, 0), Position = UDim2.fromOffset(xOffset + 4, 6),
		BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4,
	})
	local layout = make("UIListLayout", { Parent = col, Padding = UDim.new(0, SectionGap), SortOrder = Enum.SortOrder.LayoutOrder })
	return col, layout
end
local SettingsLeft, SettingsLeftLayout = makeSettingsColumn(ColumnPadding, LeftColumnWidth)
local SettingsRight, SettingsRightLayout = makeSettingsColumn(ColumnPadding + LeftColumnWidth + ColumnGap, RightColumnWidth)
local function syncSettingsCanvas()
	local h = math.max(SettingsLeftLayout.AbsoluteContentSize.Y, SettingsRightLayout.AbsoluteContentSize.Y)
	SettingsScroll.CanvasSize = UDim2.fromOffset(0, h + 12)
end
SettingsLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncSettingsCanvas)
SettingsRightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncSettingsCanvas)
syncSettingsCanvas()
setThemePreset = function(name)
	if not PresetSet[name] then name = "None" end
	State.Theme = name
	if name ~= "None" and State.Preset ~= "None" and setBackdropPreset then setBackdropPreset("None") end
	buildTheme("dark")
	buildTheme("light")
	applyTheme(name == "Light" and "light" or "dark", true)
	BlurController.RefreshGlass()
	syncBlurButton(true)
	for _, sync in ipairs(choiceSyncs) do pcall(sync) end
end
local ConfigNames = { "Not ready" }
local ActiveConfig = nil
local ConfigNameBox
local function loadConfig(_name)
	return false
end
local function saveConfig()
	return "Not ready"
end
local function deleteConfig()
	return "Not ready"
end
local function cancelConfig()
	if ConfigNameBox then ConfigNameBox.Text = "" end
	return "Cleared"
end
local function resetSettings()
	return "Not ready"
end
local function unloadUI()
	if unloadingUI then return end
	unloadingUI = true
	Main.Visible = false
	ScreenGui.Enabled = false
	closeDropdown()
	waitingForKey = nil
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Connections)
	pcall(function() BlurController.Destroy() end)
	pcall(function() ScreenGui.Parent = nil end)
	task.spawn(function()
		local destroyed = 0
		local function destroyGuiTree(parent)
			for _, child in ipairs(parent:GetChildren()) do
				destroyGuiTree(child)
				if child.Parent then pcall(function() child:Destroy() end) end
				destroyed += 1
				if destroyed % 24 == 0 then task.wait() end
			end
		end
		destroyGuiTree(ScreenGui)
		pcall(function() ScreenGui:Destroy() end)
	end)
end
local AppearanceSection = makeSimpleSection(SettingsLeft, "Appearance", true)
makeSimpleChoiceRow(AppearanceSection, "Presets", { "None", "Daydream" },
	function() return State.Preset end,
	function(v)
		if v ~= "None" and State.Theme ~= "None" then setThemePreset("None") end
		setBackdropPreset(v)
	end)
makeSimpleChoiceRow(AppearanceSection, "Theme", PresetNames,
	function() return State.Theme end,
	function(v) setThemePreset(v) end)
makeSimpleToggleRow(makeRevealWrapper(AppearanceSection, RowHeight, function() return State.Preset == "None" end), "Background Blur", "UIBlur")
makeSimpleToggleRow(AppearanceSection, "UI Shadow", "UIShadow")
local ConfigSection = makeSimpleSection(SettingsRight, "Config", true)
ConfigNameBox = select(2, makeSimpleTextBoxRow(ConfigSection, "Config name"))
rebuildConfigDropdown = select(3, makeSimpleChoiceRow(ConfigSection, "Saved", ConfigNames,
	function() return ActiveConfig or "Not ready" end,
	function(name) loadConfig(name) end))
makeSimpleButtonRow(ConfigSection, { { "Save", saveConfig }, { "Delete", deleteConfig }, { "Cancel", cancelConfig } })
makeSimpleToggleRow(ConfigSection, "Auto Load Last", "AutoLoad")
local SettingsMisc = makeSimpleSection(SettingsRight, "Misc", true)
makeSimpleKeybindRow(SettingsMisc, "Menu Key", "MenuToggle", { NoClear = true, KeyboardOnly = true })
makeSimpleToggleRow(SettingsMisc, "Array List", "ArrayList")
makeSimpleChoiceRow(SettingsMisc, "Position", ArrayCornerNames,
	function() return State.ArrayPosition end,
	function(v) State.ArrayPosition = v applyArrayPosition() end)
makeSimpleButtonRow(SettingsMisc, { { "Reset Settings", resetSettings } })
makeSimpleButtonRow(makeRevealWrapper(SettingsMisc, RowHeight, function() return State.Preset == "None" end),
	{ { "Fix Blur", function() BlurController.Fix() return "Fixed" end } })
makeSimpleButtonRow(SettingsMisc, { { "Unload UI", unloadUI } })
end
local heldInputNames = {}
local function isTweenTpBindHeld()
	local bind = State.Keybinds.TweenClickTpToggle
	if not bind or bind == "" or bind == "..." then return false end
	return heldInputNames[bind] == true
end
local camLockActive   = false
local camLockedTarget = nil
local FovVisuals = {
	Cam = { Circle = Drawing.new("Circle"), X = nil, Y = nil, Radius = nil, Visible = false },
	Silent = { Circle = Drawing.new("Circle"), X = nil, Y = nil, Radius = nil, Visible = false },
}
for _, visual in pairs(FovVisuals) do
	local circle = visual.Circle
	circle.Visible = false
	circle.Color = Color3.fromRGB(255, 255, 255)
	circle.Thickness = 1
	circle.Transparency = 1
	circle.Filled = false
	circle.NumSides = 40
	circle.ZIndex = 8
end
local function updateFovVisual(visual, center, radius, visible)
	local circle = visual.Circle
	if not visible then
		if visual.Visible then
			circle.Visible = false
			visual.Visible = false
		end
		return
	end
	local safeRadius = math.max(1, tonumber(radius) or 150)
	local x, y = center.X, center.Y
	if visual.X ~= x or visual.Y ~= y then
		circle.Position = center
		visual.X, visual.Y = x, y
	end
	if visual.Radius ~= safeRadius then
		circle.Radius = safeRadius
		visual.Radius = safeRadius
	end
	if not visual.Visible then
		circle.Visible = true
		visual.Visible = true
	end
end
local camReacquireAfter = 0
local mouseReacquireAfter = 0
	local workspaceModels = {}
	local lastWorkspaceSearch = -math.huge
	local function isValidEspModel(model)
		return model and model:IsA("Model") and model:IsDescendantOf(workspace) and model:FindFirstChildWhichIsA("BasePart", true) ~= nil
	end
	local function updateWorkspaceModels()
		if os.clock() - lastWorkspaceSearch < 2 then return end
		lastWorkspaceSearch = os.clock()
		local names = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then names[string.lower(player.Name)] = player end
		end
		local best = {}
		for _, object in ipairs(workspace:GetChildren()) do
			if object:IsA("Model") then
				local player = names[string.lower(object.Name)]
				if player and isValidEspModel(object) then best[player] = object end
			end
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = player.Character
				if isValidEspModel(character) then
					workspaceModels[player] = character
				elseif best[player] then
					workspaceModels[player] = best[player]
				elseif not isValidEspModel(workspaceModels[player]) then
					workspaceModels[player] = nil
				end
			end
		end
	end
	local espResolvedModels = setmetatable({}, { __mode = "k" })
	local function getEspCharacter(player)
		if not player then return nil end
		local current = player.Character
		if isValidEspModel(current) then
			espResolvedModels[player] = current
			return current
		end
		updateWorkspaceModels()
		local fallback = workspaceModels[player]
		if isValidEspModel(fallback) and (not current or not current:IsDescendantOf(workspace)) then
			espResolvedModels[player] = fallback
			return fallback
		end
		espResolvedModels[player] = nil
		return nil
	end
	local function getEspModelBounds(char)
		if not char or not char:IsA("Model") then return nil end
		local origin = char:FindFirstChild("HumanoidRootPart", true) or char:FindFirstChild("Root", true) or char.PrimaryPart
		local low = Vector3.new(math.huge, math.huge, math.huge)
		local high = Vector3.new(-math.huge, -math.huge, -math.huge)
		local count = 0
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and not part:FindFirstAncestorWhichIsA("Accessory") and not part:FindFirstAncestorWhichIsA("Tool") then
				if not origin or (part.Position - origin.Position).Magnitude < 30 then
					local half = part.Size * 0.5
					local cf = part.CFrame
					local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
					local ext = Vector3.new(math.abs(r.X)*half.X + math.abs(u.X)*half.Y + math.abs(l.X)*half.Z, math.abs(r.Y)*half.X + math.abs(u.Y)*half.Y + math.abs(l.Y)*half.Z, math.abs(r.Z)*half.X + math.abs(u.Z)*half.Y + math.abs(l.Z)*half.Z)
					low = low:Min(part.Position - ext)
					high = high:Max(part.Position + ext)
					count += 1
				end
			end
		end
		if count == 0 then return nil end
		return CFrame.new((low + high) * 0.5), high - low
	end
local function getModelTargetData(player)
	local model = getEspCharacter(player)
	if not model then return nil end
	local cf, size = getEspModelBounds(model)
	if not cf then return nil end
	local anchor = cf.Position
	local motionPart, minDist = nil, math.huge
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") and not item:FindFirstAncestorWhichIsA("Accessory") and not item:FindFirstAncestorWhichIsA("Tool") then
			local dist = (item.Position - anchor).Magnitude
			if dist < minDist then motionPart, minDist = item, dist end
		end
	end
	return model, cf, size, motionPart
end
local modelPositionVisible
local function getModelAimPosition(player, selection, adaptive, reference)
	local model, cf, size, part = getModelTargetData(player)
	if not model then return nil end
	local half = size.Y * 0.5
	local offsets = {
		HumanoidRootPart = Vector3.new(0, 0, 0),
		Head = Vector3.new(0, half * 0.72, 0),
		UpperTorso = Vector3.new(0, half * 0.35, 0),
		LeftArm = Vector3.new(-size.X * 0.35, half * 0.15, 0),
		RightArm = Vector3.new(size.X * 0.35, half * 0.15, 0),
		LeftLeg = Vector3.new(-size.X * 0.18, -half * 0.5, 0),
		RightLeg = Vector3.new(size.X * 0.18, -half * 0.5, 0),
	}
	local chosen = cf:PointToWorldSpace(offsets[selection] or Vector3.zero)
	local camera = workspace.CurrentCamera or Camera
	if adaptive and camera and reference then
		if modelPositionVisible and modelPositionVisible(chosen, model) then
			return chosen, model, part
		end
		local candidates = {}
		for name, offset in pairs(offsets) do
			if name ~= selection then
				local candidate = cf:PointToWorldSpace(offset)
				local screen, shown = camera:WorldToViewportPoint(candidate)
				if shown and screen.Z > 0 then
					local distance = (Vector2.new(screen.X, screen.Y) - reference).Magnitude
					table.insert(candidates, { Position = candidate, Distance = distance })
				end
			end
		end
		table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
		for _, candidate in ipairs(candidates) do
			if modelPositionVisible and modelPositionVisible(candidate.Position, model) then
				chosen = candidate.Position
				break
			end
		end
	end
	return chosen, model, part
end
local function getStandardCombatModel(player)
	local model = player and player.Character
	if model and model:IsA("Model") and model:IsDescendantOf(workspace) then
		return model
	end
	return nil
end
local function getStandardCombatPart(model, selection)
	if not model then return nil end
	local aliases = AimPartAliases[selection] or {selection}
	for _, name in ipairs(aliases) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			return part
		end
	end
	return nil
end
local function getStandardAdaptivePart(model, selection, reference)
	if not model then return nil end
	local camera = workspace.CurrentCamera or Camera
	if not camera then return getStandardCombatPart(model, selection) end
	local selected = getStandardCombatPart(model, selection)
	if selected and modelPositionVisible and modelPositionVisible(selected.Position, model) then
		return selected
	end
	local choices = {"HumanoidRootPart", "Head", "UpperTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
	local candidates, seen = {}, {}
	for _, choice in ipairs(choices) do
		local part = getStandardCombatPart(model, choice)
		if part and part ~= selected and not seen[part] then
			seen[part] = true
			local screen, onScreen = camera:WorldToViewportPoint(part.Position)
			if onScreen and screen.Z > 0 then
				local distance = reference
					and (Vector2.new(screen.X, screen.Y) - reference).Magnitude
					or (part.Position - camera.CFrame.Position).Magnitude
				table.insert(candidates, { Part = part, Distance = distance })
			end
		end
	end
	table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
	for _, candidate in ipairs(candidates) do
		if modelPositionVisible and modelPositionVisible(candidate.Part.Position, model) then
			return candidate.Part
		end
	end
	return selected or (candidates[1] and candidates[1].Part) or getStandardCombatPart(model, "HumanoidRootPart")
end
local function getCombatAimPosition(player, selection, adaptive, reference)
	local model = getStandardCombatModel(player)
	if model then
		local part
		if adaptive and reference then
			part = getStandardAdaptivePart(model, selection, reference)
		else
			part = getStandardCombatPart(model, selection)
		end
		if part then
			local workspaceModel = getEspCharacter(player)
			local valid = true
			if workspaceModel and workspaceModel ~= model then
				local bounds, size = getEspModelBounds(workspaceModel)
				if bounds then
					local limit = math.max(size.Magnitude * 1.5, 12)
					valid = (part.Position - bounds.Position).Magnitude <= limit
				end
			end
			if valid then
				local root = getStandardCombatPart(model, "HumanoidRootPart")
				return part.Position, model, root or part
			end
		end
	end
	return getModelAimPosition(player, selection, adaptive, reference)
end
local visibilityRaycastParams = RaycastParams.new()
visibilityRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
local visibilityFilteredCharacter
modelPositionVisible = function(position, model)
	local camera = workspace.CurrentCamera or Camera
	if not position or not camera then return false end
	local character = LocalPlayer.Character
	if visibilityFilteredCharacter ~= character then
		visibilityFilteredCharacter = character
		visibilityRaycastParams.FilterDescendantsInstances = character and {character} or {}
	end
	local origin = camera.CFrame.Position
	local direction = position - origin
	if direction.Magnitude < 0.01 then return true end
	local result = workspace:Raycast(origin, direction, visibilityRaycastParams)
	return result == nil or (model ~= nil and result.Instance:IsDescendantOf(model))
end
local function modelPassesWallCheck(position, model)
	return not State.Toggles.WallCheck or modelPositionVisible(position, model)
end
local function camIsValidTarget(plr)
	if not plr or plr == LocalPlayer then return false end
	local model = getStandardCombatModel(plr) or getEspCharacter(plr)
	if not model then return false end
	if State.Toggles.TeamCheck and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then return false end
	if not FriendChecks.passes(plr) then return false end
	if State.Toggles.DeadCheck then
		local hum = model:FindFirstChildWhichIsA("Humanoid", true)
		if hum and hum.Health <= 0 then return false end
	end
	return true
end
local function camPlayerCanRemainLocked(plr)
	if not plr or plr == LocalPlayer or plr.Parent ~= Players then return false end
	if State.Toggles.TeamCheck and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then return false end
	if not FriendChecks.passes(plr) then return false end
	return true
end
Players.PlayerRemoving:Connect(function(plr)
	if camLockedTarget == plr then camLockedTarget = nil end
	workspaceModels[plr] = nil
	espResolvedModels[plr] = nil
end)
local CamLockRenderName = "Wave1.6 CamLock Render"
local function updateCamLockFrame(deltaTime)
	local camera = workspace.CurrentCamera
	Camera = camera
	if not camera then return end
	local camFov = FovVisuals.Cam
	local center = camera.ViewportSize / 2
	local fovRadius = State.Sliders.FovRadius
	local showCamFov = State.Toggles.FovCircle and State.Toggles.Camlock
	if showCamFov or camFov.Visible then
		updateFovVisual(camFov, center, fovRadius, showCamFov)
	end
	if not camLockActive then return end
	if camLockedTarget ~= nil and not camIsValidTarget(camLockedTarget) then
		if State.Toggles.StickyAim and camPlayerCanRemainLocked(camLockedTarget) then
			return
		end
		camLockedTarget = nil
		camReacquireAfter = os.clock()
	end
	if camLockedTarget == nil and os.clock() >= camReacquireAfter then
		local bestTarget, bestDistance = nil, fovRadius
		for _, player in ipairs(Players:GetPlayers()) do
			if player == LocalPlayer or not camIsValidTarget(player) then continue end
			local aimPosition, targetModel = getCombatAimPosition(
				player, State.AimPart, State.Toggles.AdaptiveAim, center
			)
			if aimPosition and modelPassesWallCheck(aimPosition, targetModel) then
				local screenPosition, onScreen = camera:WorldToViewportPoint(aimPosition)
				if onScreen and screenPosition.Z > 0 then
					local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
					if distance < bestDistance then
						bestDistance = distance
						bestTarget = player
					end
				end
			end
		end
		camLockedTarget = bestTarget
	end
	if not camLockedTarget or not camIsValidTarget(camLockedTarget) then return end
	local position, model, motionPart = getCombatAimPosition(
		camLockedTarget, State.AimPart, State.Toggles.AdaptiveAim, center
	)
	if not position then return end
	if not modelPassesWallCheck(position, model) then
		if not State.Toggles.StickyAim then
			camLockedTarget = nil
			camReacquireAfter = os.clock()
		end
		return
	end
	local velocity = motionPart and motionPart.AssemblyLinearVelocity or Vector3.zero
	local aimPosition = position + velocity * (tonumber(State.Sliders.Prediction) or 0)
	local currentCFrame = camera.CFrame
	local smoothness = math.max(tonumber(State.Sliders.Smoothness) or 1, 1)
	local perFrameAlpha = math.clamp(1 / smoothness, 0, 1)
	local frameDelta = math.clamp(tonumber(deltaTime) or (1 / 60), 0, 1 / 15)
	local alpha = 1 - math.pow(1 - perFrameAlpha, frameDelta * 60)
	if (aimPosition - currentCFrame.Position).Magnitude > 0.001 then
		local targetCFrame = CFrame.lookAt(currentCFrame.Position, aimPosition, currentCFrame.UpVector)
		camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
	end
end
pcall(function() RunService:UnbindFromRenderStep(CamLockRenderName) end)
RunService:BindToRenderStep(
	CamLockRenderName,
	Enum.RenderPriority.Camera.Value + 1,
	updateCamLockFrame
)
ScreenGui.AncestryChanged:Connect(function(_, parent)
	if parent then return end
	pcall(function() RunService:UnbindFromRenderStep(CamLockRenderName) end)
end)
_G.WaveLite_CamLock_Toggle = function(forceState)
	local desired
	if type(forceState) == "boolean" then
		desired = forceState
	else
		desired = not State.Toggles.Camlock
	end
	State.Toggles.Camlock = desired
	camLockActive = desired
	if desired then
		if State.Toggles.Silent and _G.WaveLite_Silent_Toggle then
			_G.WaveLite_Silent_Toggle(false)
		end
	end
	if not desired then
		camLockedTarget = nil
	end
	if refreshToggleVisual then
		refreshToggleVisual("Camlock")
	end
end
function __WaveLiteSetupSilent()
	local silent = {enabled=false, active=true, tool=nil, toolConnection=nil, connections={}, shotUntil=0, lastFire=0, target=nil, cache=nil, targetAt=0, redirected=0, observed=0, hooked=false, updating=false, mouse=LocalPlayer:GetMouse(), player=nil, lastMethod=nil, lastReject=nil, useACS=false}
	local gameSpecificACS = game.PlaceId == 12673840215
	local acsBridgeFolder, acsTargetValue, acsEnabledValue, acsActiveValue, acsPredictionValue, acsReadyValue, acsErrorValue
	local acsStartupError
	if type(_G.WaveLiteSilentHookContext)=="table" then
		_G.WaveLiteSilentHookContext.active = false
		_G.WaveLiteSilentHookContext.enabled = false
	end
	_G.WaveLiteSilentHookContext = silent
	local function connect(signal, fn)
		local c=signal:Connect(fn)
		table.insert(silent.connections,c)
		return c
	end
	local function currentTool()
		local c=LocalPlayer.Character
		return c and c:FindFirstChildOfClass("Tool") or nil
	end
	local function setTool()
		local tool=currentTool()
		if tool==silent.tool then return end
		if silent.toolConnection then silent.toolConnection:Disconnect(); silent.toolConnection=nil end
		silent.tool=tool
		silent.target=nil
		silent.cache=nil
		silent.shotUntil=0
	end
	local function goodTarget(player)
		if not player or player==LocalPlayer or not player.Parent then return false end
		if State.Toggles.TeamCheck and LocalPlayer.Team~=nil and player.Team==LocalPlayer.Team then return false end
		if not FriendChecks.passes(player) then return false end
		local character=getStandardCombatModel(player) or getEspCharacter(player)
		if not character then return false end
		if State.Toggles.DeadCheck then
			local hum=character:FindFirstChildWhichIsA("Humanoid",true)
			if hum and hum.Health<=0 then return false end
		end
		return true
	end
	local function silentAdaptivePart(player, mouse)
		return getCombatAimPosition(player, State.AimPart, true, mouse)
	end
	local function candidate(player, mouse)
		if not goodTarget(player) then return nil end
		local position,model,part
		if State.Toggles.AdaptiveAim then
			position,model,part=silentAdaptivePart(player,mouse)
		else
			position,model,part=getCombatAimPosition(player,State.AimPart,false,mouse)
		end
		if not position or not model then return nil end
		if not modelPassesWallCheck(position,model) then return nil end
		local camera=workspace.CurrentCamera
		if not camera then return nil end
		local projected=camera:WorldToViewportPoint(position)
		if projected.Z<=0 then return nil end
		local dist=(Vector2.new(projected.X,projected.Y)-mouse).Magnitude
		return {player=player,position=position,part=part,model=model,dist=dist}
	end
	local function silentPlayerCanRemainTargeted(player)
		if not player or player == LocalPlayer or player.Parent ~= Players then return false end
		if State.Toggles.TeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then return false end
		if not FriendChecks.passes(player) then return false end
		return true
	end
	local function selectTarget()
		if silent.updating then return end
		silent.updating=true
		local ok=pcall(function()
			setTool()
			if not silent.enabled then silent.target=nil;silent.cache=nil;silent.player=nil;return end
			local mouse=UserInputService:GetMouseLocation()
			local radius=tonumber(State.Sliders.SilentFovRadius) or 150
			local retained=nil
			local sticky=State.Toggles.StickyAim == true
			local currentPlayer=silent.player
			if currentPlayer then
				if not silentPlayerCanRemainTargeted(currentPlayer) then
					silent.player=nil
					silent.cache=nil
					currentPlayer=nil
				else
					local previous=candidate(currentPlayer,mouse)
					if previous and (sticky or previous.dist<=radius) then
						retained=previous
					elseif sticky then
						silent.cache=nil
						return
					else
						silent.player=nil
						silent.cache=nil
					end
				end
			end
			if not retained then
				local closest=radius
				for _,player in ipairs(Players:GetPlayers()) do
					local hit=candidate(player,mouse)
					if hit and hit.dist<=radius and (not retained or hit.dist<closest) then
						closest=hit.dist
						retained=hit
					end
				end
			end
			if retained then
				local velocity=retained.part and retained.part.AssemblyLinearVelocity or Vector3.zero
				local predicted=retained.position + velocity*(tonumber(State.Sliders.SilentPrediction) or 0)
				local part=retained.part
				if part and (not part.Parent or not part:IsA("BasePart") or not part:IsDescendantOf(retained.model)) then part=nil end
				if not part then part=retained.model:FindFirstChildWhichIsA("BasePart",true) end
				silent.cache={part=part,position=predicted,model=retained.model,player=retained.player,stamp=os.clock()}
				silent.player=retained.player
			else
				silent.cache=nil
				silent.player=nil
			end
		end)
		silent.updating=false
		if not ok then silent.cache=nil end
	end
	local function canRedirect()
		if not silent.active or not silent.enabled or silent.updating then return nil end
		local cache=silent.cache
		if not cache or not cache.part or not cache.part.Parent or os.clock()-cache.stamp>0.2 then return nil end
		if type(checkcaller)=="function" then
			local ok,own=pcall(checkcaller)
			if ok and own then return nil end
		end
		return cache
	end
	local function validateOriginalArguments(method,args)
		if method=="Raycast" then
			return typeof(args[1])=="Vector3" and typeof(args[2])=="Vector3" and typeof(args[3])=="RaycastParams"
		end
		if method=="FindPartOnRay" or method=="findPartOnRay" then
			return typeof(args[1])=="Ray"
		end
		if method=="FindPartOnRayWithIgnoreList" or method=="FindPartOnRayWithWhitelist" then
			return typeof(args[1])=="Ray" and type(args[2])=="table"
		end
		return false
	end
	local function getOriginalDirection(origin,position)
		local diff=position-origin
		if diff.Magnitude<=0.001 then return nil end
		return diff.Unit*1000
	end
	local function startGameSpecificACS()
		if not gameSpecificACS then return end
		if type(run_on_actor)~="function" or type(hookfunction)~="function" or type(getsenv)~="function" then
			acsStartupError="Executor is missing run_on_actor, hookfunction, or getsenv"
			return
		end
		task.spawn(function()
			local playerScripts=LocalPlayer:FindFirstChild("PlayerScripts") or LocalPlayer:WaitForChild("PlayerScripts",10)
			if not playerScripts then acsStartupError="PlayerScripts was not available";return end
			if not silent.active or not ScreenGui.Parent then return end
			local previous=playerScripts:FindFirstChild("Wave16SilentACSBridge")
			if previous then pcall(function() previous:Destroy() end) end
			local folder=Instance.new("Folder")
			folder.Name="Wave16SilentACSBridge"
			local function makeValue(className,name,value)
				local object=Instance.new(className)
				object.Name=name
				object.Value=value
				object.Parent=folder
				return object
			end
			acsTargetValue=makeValue("ObjectValue","Target",nil)
			acsEnabledValue=makeValue("BoolValue","Enabled",false)
			acsActiveValue=makeValue("BoolValue","Active",true)
			acsPredictionValue=makeValue("NumberValue","Prediction",tonumber(State.Sliders.SilentPrediction) or 0)
			acsReadyValue=makeValue("BoolValue","Ready",false)
			acsErrorValue=makeValue("StringValue","Error","")
			folder.Parent=playerScripts
			acsBridgeFolder=folder
			local payload = [==[
local actor,targetValue,enabledValue,activeValue,predictionValue,readyValue,errorValue = ...
local clone = type(clonefunction)=="function" and clonefunction or function(fn) return fn end
local wrap = type(newcclosure)=="function" and newcclosure or function(fn) return fn end
local RunService = game:GetService("RunService")
local activeState
local function readValue(object,default)
    if not object or not object.Parent then return default end
    local ok,value=pcall(function() return object.Value end)
    if ok then return value end
    return default
end
activeState = readValue(activeValue,false)==true
local enabledState = readValue(enabledValue,false)==true
local targetState = readValue(targetValue,nil)
local predictionState = tonumber(readValue(predictionValue,0)) or 0
local activeBullets = setmetatable({}, {__mode="k"})
local heartbeatConnection
local hooked = setmetatable({}, {__mode="k"})
local function watchValue(object,callback)
    if not object or not object.Parent then return end
    object:GetPropertyChangedSignal("Value"):Connect(function()
        local ok,value=pcall(function() return object.Value end)
        if ok then callback(value) end
    end)
end
watchValue(activeValue,function(value)
    activeState=value==true
    if not activeState then
        for bullet in pairs(activeBullets) do activeBullets[bullet]=nil end
        if heartbeatConnection then heartbeatConnection:Disconnect();heartbeatConnection=nil end
    end
end)
watchValue(enabledValue,function(value)
    enabledState=value==true
    if not enabledState then
        for bullet in pairs(activeBullets) do activeBullets[bullet]=nil end
    end
end)
watchValue(targetValue,function(value) targetState=value end)
watchValue(predictionValue,function(value) predictionState=tonumber(value) or 0 end)
local function active()
    return activeState
end
local function setReady(value)
    pcall(function() if readyValue and readyValue.Parent then readyValue.Value=value end end)
end
local function setError(value)
    pcall(function() if errorValue and errorValue.Parent then errorValue.Value=tostring(value or "") end end)
end
local function findThrowRayCast()
    if not actor or not actor.Parent then return nil end
    local scriptObject=actor:FindFirstChildOfClass("LocalScript")
    if not scriptObject then scriptObject=actor:FindFirstChildWhichIsA("LocalScript",true) end
    if not scriptObject then setError("ACS LocalScript not found");return nil end
    local ok,environment=pcall(getsenv,scriptObject)
    if not ok or type(environment)~="table" then setError("Could not read ACS LocalScript environment");return nil end
    local fn=rawget(environment,"ThrowRayCast")
    if type(fn)~="function" then setError("ThrowRayCast not found in ACS LocalScript");return nil end
    return scriptObject,fn
end
local function install(fn)
    if hooked[fn] then setReady(true);return true end
    local original
    local callback=function(...)
        local args=table.pack(...)
        local bullet=args[2]
        local target=targetState
        if activeState and enabledState and typeof(bullet)=="Instance" and bullet:IsA("BasePart") and bullet.Parent
            and typeof(target)=="Instance" and target:IsA("BasePart") and target.Parent then
            activeBullets[bullet]=target
        end
        return original(table.unpack(args,1,args.n))
    end
    local hookOk,previous=pcall(function() return hookfunction(fn,wrap(callback)) end)
    if not hookOk or type(previous)~="function" then setReady(false);setError(previous);return false end
    local cloneOk,copy=pcall(clone,previous)
    original=(cloneOk and type(copy)=="function") and copy or previous
    hooked[fn]=true
    setError("")
    setReady(true)
    return true
end
heartbeatConnection=RunService.Heartbeat:Connect(function()
    if not activeState or not enabledState then return end
    for bullet,target in pairs(activeBullets) do
        if not bullet.Parent or not target or not target.Parent then
            activeBullets[bullet]=nil
        else
            local position=target.Position
            if predictionState~=0 then
                position=position+(target.AssemblyLinearVelocity or Vector3.zero)*predictionState
            end
            bullet.Position=position
        end
    end
end)
task.spawn(function()
    while active() do
        local ok,scriptObject,fn=pcall(findThrowRayCast)
        if ok and type(fn)=="function" then
            local installedOk=pcall(install,fn)
            if not installedOk then setReady(false) end
        else
            setReady(false)
        end
        task.wait(0.5)
    end
    setReady(false)
end)
]==]
			local actor
			for attempt=1,100 do
				if not silent.active or not ScreenGui.Parent then return end
				actor=nil
				if type(get_actors)=="function" then
					local ok,actors=pcall(get_actors)
					if ok and type(actors)=="table" then
						for _,candidate in ipairs(actors) do
							if candidate.Parent==playerScripts then actor=candidate;break end
						end
					end
				end
				if not actor then actor=playerScripts:FindFirstChildOfClass("Actor") end
				if actor and (actor:FindFirstChildOfClass("LocalScript") or actor:FindFirstChildWhichIsA("LocalScript",true)) then break end
				task.wait(0.05)
			end
			if not actor then
				acsReadyValue.Value=false
				acsErrorValue.Value="ACS Actor was not found under PlayerScripts"
				return
			end
			local ok,err=pcall(run_on_actor,actor,payload,actor,acsTargetValue,acsEnabledValue,acsActiveValue,acsPredictionValue,acsReadyValue,acsErrorValue)
			if not ok then
				acsReadyValue.Value=false
				warn("[Wave] ACS route injection failed: "..tostring(err))
			end
		end)
	end
	startGameSpecificACS()
	local baseNamecall
	if type(hookmetamethod)=="function" and type(getnamecallmethod)=="function" then
		local callback=function(self,...)
			if not silent.active or not silent.enabled or self~=workspace or silent.useACS then
				return baseNamecall(self,...)
			end
			local method=getnamecallmethod()
			if method~="Raycast" then return baseNamecall(self,...) end
			silent.observed += 1
			silent.lastMethod="Raycast"
			local cache=canRedirect()
			if not cache then
				silent.lastReject="No fresh target cache"
				return baseNamecall(self,...)
			end
			local args=table.pack(...)
			local origin,direction,raycastParams=args[1],args[2],args[3]
			if typeof(origin)~="Vector3" or typeof(direction)~="Vector3" or (raycastParams~=nil and typeof(raycastParams)~="RaycastParams") then
				silent.lastReject="Unexpected arguments for Raycast"
				return baseNamecall(self,table.unpack(args,1,args.n))
			end
			local newDirection=getOriginalDirection(origin,cache.position)
			if not newDirection then
				silent.lastReject="Target too close to ray origin"
				return baseNamecall(self,table.unpack(args,1,args.n))
			end
			args[2]=newDirection
			silent.redirected+=1
			silent.lastReject=nil
			return baseNamecall(self,table.unpack(args,1,args.n))
		end
		local closure=type(newcclosure)=="function" and newcclosure(callback) or callback
		local ok,previous=pcall(function() return hookmetamethod(game,"__namecall",closure) end)
		if ok and type(previous)=="function" then
			baseNamecall=previous
			silent.hooked=true
		end
	end
	local oldIndex
	if type(hookmetamethod)=="function" then
		local callback=function(self,key)
			if not silent.active or not silent.enabled or self~=silent.mouse or silent.useACS or State.SilentMethod~="Mouse.Hit/Target" then return oldIndex(self,key) end
			if key~="Hit" and key~="hit" and key~="Target" and key~="target" then return oldIndex(self,key) end
			local cache=canRedirect()
			if not cache then return oldIndex(self,key) end
			silent.redirected+=1
			if key=="Target" or key=="target" then return cache.part end
			return CFrame.new(cache.position)
		end
		local closure=type(newcclosure)=="function" and newcclosure(callback) or callback
		pcall(function()oldIndex=hookmetamethod(game,"__index",closure)end)
	end
	_G.WaveLite_Silent_Toggle=function(on)
		if type(on)=="boolean" then silent.enabled=on else silent.enabled=not silent.enabled end
		State.Toggles.Silent=silent.enabled
		if silent.enabled and State.Toggles.Camlock then
			State.Toggles.Camlock=false
			camLockActive=false
			camLockedTarget=nil
			if refreshToggleVisual then refreshToggleVisual("Camlock") end
		end
		if not silent.enabled then silent.cache=nil;silent.player=nil end
		if refreshToggleVisual then refreshToggleVisual("Silent") end
	end
	connect(LocalPlayer.CharacterAdded,function()
		silent.tool=nil
		silent.cache=nil
		silent.player=nil
		silent.shotUntil=0
	end)
	connect(Players.PlayerRemoving,function(player)
		if silent.player==player then silent.player=nil;silent.cache=nil end
	end)
	local lastTarget=0
	local bridgeInitialized=false
	local lastBridgeTarget,lastBridgeActive,lastBridgeEnabled,lastBridgePrediction=nil,nil,nil,nil
	local render=connect(RunService.RenderStepped,function()
		local now=os.clock()
		if silent.enabled and now-lastTarget>=0.05 then
			lastTarget=now
			selectTarget()
		end
		if acsBridgeFolder and acsBridgeFolder.Parent then
			local ready=false
			if acsReadyValue and acsReadyValue.Parent then pcall(function() ready=acsReadyValue.Value==true end) end
			silent.useACS=gameSpecificACS and ready
			local targetPart=silent.cache and silent.cache.part
			if not (targetPart and targetPart.Parent) then targetPart=nil end
			local enabledNow=silent.active and silent.enabled and ready
			local predictionNow=tonumber(State.Sliders.SilentPrediction) or 0
			if not bridgeInitialized or targetPart~=lastBridgeTarget then
				if acsTargetValue and acsTargetValue.Parent then pcall(function() acsTargetValue.Value=targetPart end) end
				lastBridgeTarget=targetPart
			end
			if not bridgeInitialized or silent.active~=lastBridgeActive then
				if acsActiveValue and acsActiveValue.Parent then pcall(function() acsActiveValue.Value=silent.active end) end
				lastBridgeActive=silent.active
			end
			if not bridgeInitialized or enabledNow~=lastBridgeEnabled then
				if acsEnabledValue and acsEnabledValue.Parent then pcall(function() acsEnabledValue.Value=enabledNow end) end
				lastBridgeEnabled=enabledNow
			end
			if not bridgeInitialized or predictionNow~=lastBridgePrediction then
				if acsPredictionValue and acsPredictionValue.Parent then pcall(function() acsPredictionValue.Value=predictionNow end) end
				lastBridgePrediction=predictionNow
			end
			bridgeInitialized=true
		end
		local camera=workspace.CurrentCamera
		local silentFov = FovVisuals.Silent
		local showSilentFov = silent.enabled and State.Toggles.SilentFovCircle
		if camera and (showSilentFov or silentFov.Visible) then
			updateFovVisual(silentFov, UserInputService:GetMouseLocation(),
				State.Sliders.SilentFovRadius, showSilentFov)
		end
	end)
	_G.WaveLiteSilentStatus=function()
		return {
			HookReady=silent.hooked,
			Enabled=silent.enabled,
			ACSRouteReady=silent.useACS,
			ACSRouteError=(acsErrorValue and acsErrorValue.Parent and acsErrorValue.Value) or acsStartupError,
			Method=State.SilentMethod,
			LastMethod=silent.lastMethod,
			Observed=silent.observed,
			Redirected=silent.redirected,
			LastReject=silent.lastReject,
			Target=silent.player and silent.player.Name or nil,
		}
	end
	connect(ScreenGui.AncestryChanged,function(_,parent)
		if parent then return end
		silent.active=false
		silent.enabled=false
		if acsActiveValue and acsActiveValue.Parent then pcall(function() acsActiveValue.Value=false end) end
		if acsEnabledValue and acsEnabledValue.Parent then pcall(function() acsEnabledValue.Value=false end) end
		if acsTargetValue and acsTargetValue.Parent then pcall(function() acsTargetValue.Value=nil end) end
		if acsBridgeFolder and acsBridgeFolder.Parent then
			local folderToDestroy=acsBridgeFolder
			task.delay(1,function() pcall(function() folderToDestroy:Destroy() end) end)
		end
		if silent.toolConnection then silent.toolConnection:Disconnect() end
		for _,c in ipairs(silent.connections) do pcall(function()c:Disconnect()end) end
		if _G.WaveLiteSilentHookContext==silent then _G.WaveLiteSilentHookContext=nil end
		_G.WaveLiteSilentStatus=nil
	end)
end
__WaveLiteSetupSilent()
__WaveLiteSetupSilent = nil
ScreenGui.AncestryChanged:Connect(function(_, parent)
	if parent then return end
	for _, visual in pairs(FovVisuals) do
		if visual.Connection then
			pcall(function() visual.Connection:Disconnect() end)
			visual.Connection = nil
		end
		pcall(function() visual.Circle:Remove() end)
	end
end)
local function getMoveCharacter()
	return LocalPlayer.Character
end
local function getMoveRoot()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end
local function getMoveHumanoid()
	local character = LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end
function __WaveLiteSetupMovementTools()
	local noclipConnection = nil
	local noclipExtraConnections = {}
	local noclipPartConnections = {}
	local noclipSavedCollisions = {}
	local PhysicsService = game:GetService("PhysicsService")
	local NoclipGroup = "Wave15Ghost"
	local noclipGroupReady = false
	local noclipGroupAttempted = false
	local function disconnectNoclipConnection(connection)
		if connection then
			pcall(function() connection:Disconnect() end)
		end
	end
	local function disconnectNoclipRuntimeConnections()
		disconnectNoclipConnection(noclipConnection)
		noclipConnection = nil
		for _, connection in ipairs(noclipExtraConnections) do
			disconnectNoclipConnection(connection)
		end
		table.clear(noclipExtraConnections)
	end
	local function disconnectNoclipPartConnections()
		for part, connections in pairs(noclipPartConnections) do
			for _, connection in ipairs(connections) do
				disconnectNoclipConnection(connection)
			end
			noclipPartConnections[part] = nil
		end
	end
	local function prepareNoclipCollisionGroup()
		if noclipGroupAttempted then
			return noclipGroupReady
		end
		noclipGroupAttempted = true
		local ok = pcall(function()
			local groups = PhysicsService:GetRegisteredCollisionGroups()
			local found = false
			for _, groupInfo in ipairs(groups) do
				local groupName = groupInfo.name or groupInfo.Name
				if groupName == NoclipGroup then
					found = true
					break
				end
			end
			if not found then
				PhysicsService:RegisterCollisionGroup(NoclipGroup)
			end
			groups = PhysicsService:GetRegisteredCollisionGroups()
			for _, groupInfo in ipairs(groups) do
				local groupName = groupInfo.name or groupInfo.Name
				if type(groupName) == "string" then
					PhysicsService:CollisionGroupSetCollidable(NoclipGroup, groupName, false)
				end
			end
			PhysicsService:CollisionGroupSetCollidable(NoclipGroup, NoclipGroup, false)
		end)
		noclipGroupReady = ok
		return noclipGroupReady
	end
	local function saveNoclipPartState(part)
		if not part or not part:IsA("BasePart") then return end
		if noclipSavedCollisions[part] ~= nil then return end
		noclipSavedCollisions[part] = {
			CanCollide = part.CanCollide,
			CollisionGroup = part.CollisionGroup,
		}
	end
	local function forceNoclipPart(part)
		if not part or not part:IsA("BasePart") or not part.Parent then return end
		saveNoclipPartState(part)
		pcall(function()
			if part.CanCollide then
				part.CanCollide = false
			end
		end)
		if noclipGroupReady then
			pcall(function()
				if part.CollisionGroup ~= NoclipGroup then
					part.CollisionGroup = NoclipGroup
				end
			end)
		end
	end
	local function bindNoclipPart(part)
		if not part or not part:IsA("BasePart") then return end
		forceNoclipPart(part)
		if noclipPartConnections[part] then return end
		local connections = {}
		table.insert(connections, part:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if State.Toggles.Noclip and part.Parent and part.CanCollide then
				pcall(function() part.CanCollide = false end)
			end
		end))
		if noclipGroupReady then
			table.insert(connections, part:GetPropertyChangedSignal("CollisionGroup"):Connect(function()
				if State.Toggles.Noclip and part.Parent and part.CollisionGroup ~= NoclipGroup then
					pcall(function() part.CollisionGroup = NoclipGroup end)
				end
			end))
		end
		noclipPartConnections[part] = connections
	end
	local function forceCharacterNoclip(character)
		if not character then return end
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				bindNoclipPart(descendant)
			end
		end
	end
	local function restoreCollisionState()
		for part, saved in pairs(noclipSavedCollisions) do
			if part and part.Parent then
				pcall(function()
					part.CanCollide = saved.CanCollide
				end)
				pcall(function()
					if saved.CollisionGroup then
						part.CollisionGroup = saved.CollisionGroup
					end
				end)
			end
		end
		table.clear(noclipSavedCollisions)
	end
	local function stopNoclip()
		State.Toggles.Noclip = false
		disconnectNoclipRuntimeConnections()
		disconnectNoclipPartConnections()
		restoreCollisionState()
		refreshToggleVisual("Noclip")
	end
	local function startNoclip()
		if noclipConnection and State.Toggles.Noclip then return end
		disconnectNoclipRuntimeConnections()
		disconnectNoclipPartConnections()
		table.clear(noclipSavedCollisions)
		State.Toggles.Noclip = true
		refreshToggleVisual("Noclip")
		prepareNoclipCollisionGroup()
		local function attachCharacter(character)
			if not character then return end
			forceCharacterNoclip(character)
			table.insert(noclipExtraConnections, character.DescendantAdded:Connect(function(descendant)
				if State.Toggles.Noclip and descendant:IsA("BasePart") then
					task.defer(function()
						if State.Toggles.Noclip and descendant.Parent then
							bindNoclipPart(descendant)
						end
					end)
				end
			end))
		end
		attachCharacter(getMoveCharacter())
		local function enforceNoclip()
			if not State.Toggles.Noclip then return end
			forceCharacterNoclip(getMoveCharacter())
		end
		local physicsSignal = RunService.Stepped
		pcall(function()
			if RunService.PreSimulation then
				physicsSignal = RunService.PreSimulation
			end
		end)
		noclipConnection = physicsSignal:Connect(enforceNoclip)
		if physicsSignal ~= RunService.Stepped then
			table.insert(noclipExtraConnections, RunService.Stepped:Connect(enforceNoclip))
		end
	end
	_G.WaveLite_Noclip_Toggle = function(forceState)
		if forceState == false then
			stopNoclip()
		else
			startNoclip()
		end
	end
	local tweenClickConnection = nil
	local activeTweenTp = nil
	local activeToolTpTween = nil
	local function teleportToPosition(position)
		local root = getMoveRoot()
		local humanoid = getMoveHumanoid()
		if not root or not humanoid or not position or humanoid.Health <= 0 then return end
		if activeToolTpTween then
			pcall(function() activeToolTpTween:Cancel() end)
			activeToolTpTween = nil
		end
		local yOffset = math.max(3, humanoid.HipHeight + 2)
		local target = CFrame.new(position + Vector3.new(0, yOffset, 0)) * root.CFrame.Rotation
		local distance = (target.Position - root.Position).Magnitude
		local duration = math.clamp(distance / 5000, 0.02, 0.08)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		activeToolTpTween = TweenService:Create(
			root,
			TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ CFrame = target }
		)
		activeToolTpTween:Play()
	end
	local ArrivalHeight = 3
	local MaxTweenTpDistance = 2000
	local function cancelTweenTp()
		if activeTweenTp then
			pcall(function() activeTweenTp:Cancel() end)
			activeTweenTp = nil
		end
	end
	local function tweenTeleportToPosition(position)
		local root = getMoveRoot()
		local humanoid = getMoveHumanoid()
		if not root or not humanoid or not position then return end
		if humanoid.Health <= 0 then return end
		cancelTweenTp()
		local offsetDestination = position + Vector3.new(0, ArrivalHeight, 0)
		local distance = (offsetDestination - root.Position).Magnitude
		if distance <= 0.1 then return end
		if distance > MaxTweenTpDistance then
			warn("Destination is too far away.")
			return
		end
		local speed = math.max(5, tonumber(State.Sliders.TweenTpSpeed) or 110)
		local duration = distance / speed
		local targetCFrame = CFrame.new(offsetDestination) * root.CFrame.Rotation
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		activeTweenTp = TweenService:Create(
			root,
			TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ CFrame = targetCFrame }
		)
		activeTweenTp:Play()
		local completedConn
		completedConn = activeTweenTp.Completed:Connect(function()
			if completedConn then completedConn:Disconnect() completedConn = nil end
			activeTweenTp = nil
			if root and root.Parent then
				pcall(function()
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end)
	end
	local function stopTweenClickTp()
		if tweenClickConnection then
			pcall(function() tweenClickConnection:Disconnect() end)
			tweenClickConnection = nil
		end
		cancelTweenTp()
		local root = getMoveRoot()
		if root then
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end
	local function startTweenClickTp()
		if tweenClickConnection then return end
		tweenClickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if UserInputService:GetFocusedTextBox() then return end
			if not isTweenTpBindHeld() then return end
			local mouse = LocalPlayer:GetMouse()
			if not mouse or not mouse.Target then return end
			if State.TpMode == "Instant" then
				cancelTweenTp()
				teleportToPosition(mouse.Hit.Position)
			else
				if activeToolTpTween then
					pcall(function() activeToolTpTween:Cancel() end)
					activeToolTpTween = nil
				end
				tweenTeleportToPosition(mouse.Hit.Position)
			end
		end)
	end
	startTweenClickTp()
	LocalPlayer.CharacterAdded:Connect(function()
		cancelTweenTp()
		task.wait(0.25)
		if State.Toggles.Noclip then
			disconnectNoclipRuntimeConnections()
			disconnectNoclipPartConnections()
			table.clear(noclipSavedCollisions)
			startNoclip()
		end
	end)
end
__WaveLiteSetupMovementTools()
__WaveLiteSetupMovementTools = nil
function __WaveLiteSetupPlayerWorld()
	_G.WaveLite_PlayerWorld = _G.WaveLite_PlayerWorld or {}
	local P = _G.WaveLite_PlayerWorld
	P.saved = P.saved or {}
	P.fxSaved = P.fxSaved or {}
	P.lowSaved = setmetatable(P.lowSaved or {}, { __mode = "k" })
	local LightingSvc = game:GetService("Lighting")
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	local function root()
		local c = LocalPlayer.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end
	local function hum()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end
	local function isCharacterObject(obj)
		local model = obj:FindFirstAncestorOfClass("Model")
		if not model then return false end
		if model == LocalPlayer.Character then return true end
		return Players:GetPlayerFromCharacter(model) ~= nil
	end
	local function refreshToggle(name)
		pcall(function() refreshToggleVisual(name) end)
	end
	_G.WaveLite_Maxzoom_Toggle = function(on)
		State.Toggles.Maxzoom = on and true or false
		if on then
			P.saved.maxZoom = P.saved.maxZoom or LocalPlayer.CameraMaxZoomDistance
			pcall(function() LocalPlayer.CameraMaxZoomDistance = 100000 end)
			pcall(function() game:GetService("StarterPlayer").CameraMaxZoomDistance = 100000 end)
		else
			pcall(function() LocalPlayer.CameraMaxZoomDistance = P.saved.maxZoom or 400 end)
		end
		refreshToggle("Maxzoom")
	end
	_G.WaveLite_NoFog_Toggle = function(on)
		State.Toggles.NoFog = on and true or false
		if on then
			if P.fxSaved.fogEnd == nil then
				P.fxSaved.fogEnd = LightingSvc.FogEnd
				P.fxSaved.fogStart = LightingSvc.FogStart
				P.fxSaved.atmos = setmetatable({}, { __mode = "k" })
				for _, obj in ipairs(LightingSvc:GetDescendants()) do
					if (obj:IsA("Atmosphere") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect"))
						and not obj:GetAttribute("WaveBlur15") then
						P.fxSaved.atmos[obj] = obj:IsA("Atmosphere") and { Density = obj.Density, Haze = obj.Haze, Enabled = true } or { Enabled = obj.Enabled }
					end
				end
			end
			LightingSvc.FogStart = 100000
			LightingSvc.FogEnd = 100000
			for obj in pairs(P.fxSaved.atmos or {}) do
				pcall(function()
					if obj:IsA("Atmosphere") then obj.Density = 0; obj.Haze = 0 else obj.Enabled = false end
				end)
			end
		else
			pcall(function() LightingSvc.FogEnd = P.fxSaved.fogEnd or LightingSvc.FogEnd end)
			pcall(function() LightingSvc.FogStart = P.fxSaved.fogStart or LightingSvc.FogStart end)
			for obj, old in pairs(P.fxSaved.atmos or {}) do
				pcall(function()
					if obj:IsA("Atmosphere") then obj.Density = old.Density; obj.Haze = old.Haze else obj.Enabled = old.Enabled end
				end)
			end
			P.fxSaved = {}
		end
		refreshToggle("NoFog")
	end
	_G.WaveLite_DisableShadows_Toggle = function(on)
		State.Toggles.DisableShadows = on and true or false
		if on then
			if P.saved.globalShadows == nil then P.saved.globalShadows = LightingSvc.GlobalShadows end
			LightingSvc.GlobalShadows = false
		else
			if P.saved.globalShadows ~= nil then LightingSvc.GlobalShadows = P.saved.globalShadows end
		end
		refreshToggle("DisableShadows")
	end
	local function applyLowObj(obj, on)
		if obj:GetAttribute("WaveBlur15") then return end
		if obj:IsA("BasePart") then
			if on then
				if P.lowSaved[obj] == nil then P.lowSaved[obj] = { Material = obj.Material, Reflectance = obj.Reflectance, CastShadow = obj.CastShadow } end
				pcall(function() obj.Material = Enum.Material.SmoothPlastic; obj.Reflectance = 0; obj.CastShadow = false end)
			elseif P.lowSaved[obj] then
				local old = P.lowSaved[obj]
				pcall(function() obj.Material = old.Material; obj.Reflectance = old.Reflectance; obj.CastShadow = old.CastShadow end)
				P.lowSaved[obj] = nil
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			if on then
				if P.lowSaved[obj] == nil then P.lowSaved[obj] = { Transparency = obj.Transparency } end
				pcall(function() obj.Transparency = 1 end)
			elseif P.lowSaved[obj] then
				pcall(function() obj.Transparency = P.lowSaved[obj].Transparency end)
				P.lowSaved[obj] = nil
			end
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			if on then
				if P.lowSaved[obj] == nil then P.lowSaved[obj] = { Enabled = obj.Enabled } end
				pcall(function() obj.Enabled = false end)
			elseif P.lowSaved[obj] then
				pcall(function() obj.Enabled = P.lowSaved[obj].Enabled end)
				P.lowSaved[obj] = nil
			end
		end
	end
	_G.WaveLite_LowGfx_Toggle = function(on)
		State.Toggles.LowGfx = on and true or false
		for _, obj in ipairs(workspace:GetDescendants()) do
			if not isCharacterObject(obj) then applyLowObj(obj, on) end
		end
		refreshToggle("LowGfx")
	end
	LocalPlayer.CharacterAdded:Connect(function()
		if State.Toggles.Maxzoom then _G.WaveLite_Maxzoom_Toggle(true) end
	end)
end
__WaveLiteSetupPlayerWorld()
__WaveLiteSetupPlayerWorld = nil
function __WaveLiteSetupPlayerExtras()
	local antiAfkConnection, spinConnection, spinSavedAutoRotate = nil, nil, nil
_G.WaveLite_AntiAfk_Toggle = function(on)
	State.Toggles.AntiAfk = on == true
	if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
	if State.Toggles.AntiAfk then
		antiAfkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new(0,0), (workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or CFrame.new()) end)
		end)
	end
	if refreshToggleVisual then refreshToggleVisual("AntiAfk") end
end
_G.WaveLite_Spinbot_Toggle = function(on)
	State.Toggles.Spinbot = on == true
	if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
	local hum = getMoveHumanoid()
	if State.Toggles.Spinbot then
		if hum then spinSavedAutoRotate = hum.AutoRotate; hum.AutoRotate = false end
		spinConnection = RunService.Heartbeat:Connect(function(dt)
			local root, currentHum = getMoveRoot(), getMoveHumanoid(); if currentHum then currentHum.AutoRotate = false end
			if root then
				local spinRate = math.max(0, (tonumber(State.Sliders.SpinSpeed) or 10) * 80)
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinRate) * dt, 0)
			end
		end)
	elseif hum then hum.AutoRotate = spinSavedAutoRotate == nil and true or spinSavedAutoRotate; spinSavedAutoRotate = nil end
	if refreshToggleVisual then refreshToggleVisual("Spinbot") end
end
ScreenGui.AncestryChanged:Connect(function(_, parent)
	if parent then return end
	if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
	if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
end)
end
__WaveLiteSetupPlayerExtras()
__WaveLiteSetupPlayerExtras = nil
function __WaveLiteSetupMisc()
	local misc={
		connections={},jumpDown=false,lastPickup=0,lastJump=0,
		promptCooldown=setmetatable({},{__mode="k"}),
		pickupBuckets=setmetatable({},{__mode="k"}),
		itemParts=setmetatable({},{__mode="k"}),
	}
	local function listen(signal,fn)
		local c=signal:Connect(fn)
		table.insert(misc.connections,c)
		return c
	end
	local function currentHumanoid()
		local character=LocalPlayer.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end
	_G.WaveLite_InfJump_Toggle=function(on)
		State.Toggles.InfJump=on==true
		if refreshToggleVisual then refreshToggleVisual("InfJump") end
	end
	_G.WaveLite_AntiSeat_Toggle=function(on)
		State.Toggles.AntiSeat=on==true
		local hum=currentHumanoid()
		if State.Toggles.AntiSeat and hum then pcall(function() hum.Sit=false end) end
		if refreshToggleVisual then refreshToggleVisual("AntiSeat") end
	end
	_G.WaveLite_AutoPickup_Toggle=function(on)
		State.Toggles.AutoPickup=on==true
		if refreshToggleVisual then refreshToggleVisual("AutoPickup") end
	end
	listen(UserInputService.InputBegan,function(input,processed)
		if not processed and input.KeyCode==Enum.KeyCode.Space then misc.jumpDown=true end
	end)
	listen(UserInputService.InputEnded,function(input)
		if input.KeyCode==Enum.KeyCode.Space then misc.jumpDown=false end
	end)
	listen(UserInputService.JumpRequest,function()
		if not State.Toggles.InfJump then return end
		local hum=currentHumanoid()
		if hum and hum.Health>0 and not hum.Sit then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
	local function getGiverRemote()
		local remotes=game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local remote=remotes and remotes:FindFirstChild("GiverPressed")
		return remote and remote:IsA("RemoteEvent") and remote or nil
	end
	local function getGiverPart(model)
		if model.PrimaryPart then return model.PrimaryPart end
		return model:FindFirstChildWhichIsA("BasePart",true)
	end
	local function getPickupPart(item)
		local parent=item.Parent
		if parent and parent:IsA("Attachment") then parent=parent.Parent end
		if parent and parent:IsA("BasePart") then return parent end
		if parent and parent:IsA("Model") then
			local part=parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart",true)
			if part then return part end
		end
		return item:FindFirstAncestorWhichIsA("BasePart")
	end
	local function registerPickup(item)
		if misc.itemParts[item] then return end
		local kind
		if item:IsA("ProximityPrompt") then kind="prompt"
		elseif item:IsA("ClickDetector") then kind="click"
		elseif item:IsA("Model") and type(item:GetAttribute("ToolName"))=="string" then kind="giver" end
		if kind then
			local part=kind=="giver" and getGiverPart(item) or getPickupPart(item)
			if part and part:IsA("BasePart") then
				local bucket=misc.pickupBuckets[part]
				if not bucket then
					bucket={prompts={},clicks={},givers={}}
					misc.pickupBuckets[part]=bucket
				end
				if kind=="prompt" then bucket.prompts[item]=true
				elseif kind=="click" then bucket.clicks[item]=true
				else bucket.givers[item]=true end
				misc.itemParts[item]={part=part,kind=kind}
				return
			end
		end
		local ancestor=item:FindFirstAncestorOfClass("Model")
		while ancestor do
			if type(ancestor:GetAttribute("ToolName"))=="string" then
				registerPickup(ancestor)
				break
			end
			local parent=ancestor.Parent
			ancestor=parent and parent:FindFirstAncestorOfClass("Model")
		end
	end
	local function unregisterPickup(item)
		local entry=misc.itemParts[item]
		if entry then
			local bucket=misc.pickupBuckets[entry.part]
			if bucket then
				if entry.kind=="prompt" then bucket.prompts[item]=nil
				elseif entry.kind=="click" then bucket.clicks[item]=nil
				else bucket.givers[item]=nil end
				if not next(bucket.prompts) and not next(bucket.clicks) and not next(bucket.givers) then
					misc.pickupBuckets[entry.part]=nil
				end
			end
			misc.itemParts[item]=nil
		end
		if item:IsA("BasePart") then misc.pickupBuckets[item]=nil end
	end
	listen(workspace.DescendantAdded,registerPickup)
	listen(workspace.DescendantRemoving,unregisterPickup)
	task.spawn(function()
		local descendants=workspace:GetDescendants()
		for index,item in ipairs(descendants) do
			if not ScreenGui.Parent then break end
			registerPickup(item)
			if index%250==0 then task.wait() end
		end
	end)
	local overlapParams
	pcall(function()
		overlapParams=OverlapParams.new()
		overlapParams.FilterType=Enum.RaycastFilterType.Exclude
	end)
	local function scanNearby(root,now)
		if overlapParams then
			pcall(function()
				overlapParams.FilterDescendantsInstances=LocalPlayer.Character and {LocalPlayer.Character} or {}
			end)
		end
		local ok,nearbyParts=pcall(function()
			if overlapParams then return workspace:GetPartBoundsInRadius(root.Position,12,overlapParams) end
			return workspace:GetPartBoundsInRadius(root.Position,12)
		end)
		if not ok or type(nearbyParts)~="table" then return end
		local nearest,nearestDistanceSquared=nil,math.huge
		local fireClick=type(fireclickdetector)=="function"
		local backpack=LocalPlayer:FindFirstChildOfClass("Backpack")
		local character=LocalPlayer.Character
		local giverRemote
		for _,part in ipairs(nearbyParts) do
			local bucket=misc.pickupBuckets[part]
			if bucket then
				for prompt in pairs(bucket.prompts) do
					if prompt.Parent and prompt.Enabled then
						local action=(prompt.ActionText.." "..prompt.ObjectText):lower()
						if action:find("pick",1,true) or action:find("collect",1,true) or action:find("grab",1,true) or action:find("loot",1,true) then
							local promptParent=prompt.Parent
							local position=promptParent:IsA("Attachment") and promptParent.WorldPosition or part.Position
							local offset=root.Position-position
							local distanceSquared=offset:Dot(offset)
							local maxDistance=math.min(prompt.MaxActivationDistance,12)
							if distanceSquared<=maxDistance*maxDistance and distanceSquared<nearestDistanceSquared
								and now-(misc.promptCooldown[prompt] or 0)>1.5 then
								nearest,nearestDistanceSquared=prompt,distanceSquared
							end
						end
					end
				end
				if fireClick then
					for detector in pairs(bucket.clicks) do
						if detector.Parent and detector:IsDescendantOf(workspace) then
							local parent=detector.Parent
							local targetPart=parent:IsA("BasePart") and parent or (parent:IsA("Model") and (parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart",true)))
							if targetPart and not targetPart:FindFirstAncestorOfClass("Accessory") then
								local model=targetPart:FindFirstAncestorOfClass("Model")
								local belongsToPlayer=model and Players:GetPlayerFromCharacter(model)~=nil
								if not belongsToPlayer then
									local offset=root.Position-targetPart.Position
									local distanceSquared=offset:Dot(offset)
									local maxDistance=math.min(detector.MaxActivationDistance,12)
									if distanceSquared<=maxDistance*maxDistance and distanceSquared<nearestDistanceSquared
										and now-(misc.promptCooldown[detector] or 0)>2 then
										nearest,nearestDistanceSquared=detector,distanceSquared
									end
								end
							end
						end
					end
				end
				if next(bucket.givers) then
					if not giverRemote then giverRemote=getGiverRemote() end
					if giverRemote then
						for model in pairs(bucket.givers) do
							if model.Parent and model:IsDescendantOf(workspace) then
								local toolName=model:GetAttribute("ToolName")
								local giverPart=getGiverPart(model)
								if type(toolName)=="string" and toolName~="" and giverPart
									and not (backpack and backpack:FindFirstChild(toolName))
									and not (character and character:FindFirstChild(toolName)) then
										local offset=root.Position-giverPart.Position
										local distanceSquared=offset:Dot(offset)
										if distanceSquared<=144 and now-(misc.promptCooldown[model] or 0)>=1.5 then
											 misc.promptCooldown[model]=now
											 pcall(function() giverRemote:FireServer(model) end)
										end
									end
							end
						end
					end
				end
			end
		end
		if nearest then
			if nearest:IsA("ProximityPrompt") and type(fireproximityprompt)=="function" then
				misc.promptCooldown[nearest]=now
				pcall(fireproximityprompt,nearest)
			elseif nearest:IsA("ClickDetector") and type(fireclickdetector)=="function" then
				misc.promptCooldown[nearest]=now
				pcall(fireclickdetector,nearest)
			end
		end
	end
	listen(RunService.Heartbeat,function()
		local hum=currentHumanoid()
		local now=os.clock()
		if State.Toggles.InfJump and misc.jumpDown and hum and hum.Health>0 and not hum.Sit and now-misc.lastJump>=0.11 then
			misc.lastJump=now
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		if State.Toggles.AntiSeat and hum and hum.Sit then pcall(function() hum.Sit=false end) end
		if not State.Toggles.AutoPickup then return end
		if now-misc.lastPickup<0.6 then return end
		misc.lastPickup=now
		local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then scanNearby(root,now) end
	end)
	listen(ScreenGui.AncestryChanged,function(_,parent)
		if parent then return end
		for _,c in ipairs(misc.connections) do pcall(function()c:Disconnect()end) end
		_G.WaveLite_InfJump_Toggle=nil
		_G.WaveLite_AntiSeat_Toggle=nil
		_G.WaveLite_AutoPickup_Toggle=nil
	end)
end
__WaveLiteSetupMisc()
__WaveLiteSetupMisc = nil
function refreshToggleVisual(stateName)
	for _, tg in ipairs(themedToggles) do
		if tg.stateName == stateName then
			if tg.animate then
				pcall(tg.animate)
			elseif tg.update then
				pcall(tg.update)
			end
		end
	end
	if refreshArrayList then refreshArrayList() end
end
function __WaveLiteSetupFly()
	local flyActive = false
	local flyConnection = nil
	local flyTween = nil
	local flyTweenClock = 0
	local activeFlyType = nil
	local flyDiedConnection = nil
	local flyCharRemovingConnection = nil
	local flyLastMoveDirection = Vector3.new(0, 0, 1)
	local FlyDesync = 1.25
	local function disconnectFlyCharSignals()
		if flyDiedConnection then pcall(function() flyDiedConnection:Disconnect() end); flyDiedConnection = nil end
		if flyCharRemovingConnection then pcall(function() flyCharRemovingConnection:Disconnect() end); flyCharRemovingConnection = nil end
	end
	local function getFlySpeed()
		local modeMax = 50
		local speed = tonumber(State.Sliders.FlySpeed) or 25
		return math.clamp(speed, 1, modeMax)
	end
	local function hardResetFlyVelocity(rootPart)
		if not rootPart then return end
		pcall(function()
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	local function stopFly(skipState)
		if not flyActive and not flyConnection then
			if not skipState then
				State.Toggles.Fly = false
				refreshToggleVisual("Fly")
			end
			return
		end
		flyActive = false
		if flyConnection then pcall(function() flyConnection:Disconnect() end); flyConnection = nil end
		if flyTween then pcall(function() flyTween:Cancel() end); flyTween = nil end
		flyTweenClock = 0
		activeFlyType = nil
		disconnectFlyCharSignals()
		local humanoid = getMoveHumanoid()
		local rootPart = getMoveRoot()
		if humanoid then
			pcall(function()
				humanoid.PlatformStand = false
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = 16
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end)
		end
		hardResetFlyVelocity(rootPart)
		if not skipState then
			State.Toggles.Fly = false
			refreshToggleVisual("Fly")
		end
	end
	local function startFly()
		if flyActive then return end
		local rootPart = getMoveRoot()
		local humanoid = getMoveHumanoid()
		if not rootPart or not humanoid then
			State.Toggles.Fly = false
			refreshToggleVisual("Fly")
			return
		end
		flyActive = true
		State.Toggles.Fly = true
		refreshToggleVisual("Fly")
		hardResetFlyVelocity(rootPart)
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.AutoRotate = true
			humanoid.WalkSpeed = 0
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
		disconnectFlyCharSignals()
		flyDiedConnection = humanoid.Died:Connect(function()
			stopFly(false)
		end)
		flyCharRemovingConnection = LocalPlayer.CharacterRemoving:Connect(function(char)
			local oldRoot = char and char:FindFirstChild("HumanoidRootPart")
			hardResetFlyVelocity(oldRoot)
			if flyConnection then pcall(function() flyConnection:Disconnect() end); flyConnection = nil end
			if flyTween then pcall(function() flyTween:Cancel() end); flyTween = nil end
			flyTweenClock = 0
			activeFlyType = nil
			disconnectFlyCharSignals()
			flyActive = false
		end)
		flyConnection = RunService.Heartbeat:Connect(function(deltaTime)
			if not flyActive then return end
			local currentRoot = getMoveRoot()
			local currentHumanoid = getMoveHumanoid()
			local camera = workspace.CurrentCamera
			if not currentRoot or not currentHumanoid or not camera or currentHumanoid.Health <= 0 then
				stopFly(false)
				return
			end
			local speed = getFlySpeed() * math.max(0.01, tonumber(State.Sliders.FlyMultiplier) or 1)
			local cameraLook = camera.CFrame.LookVector
			local cameraRight = camera.CFrame.RightVector
			local moveDirection = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += cameraLook end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= cameraLook end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= cameraRight end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += cameraRight end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection -= Vector3.new(0, 1, 0) end
			local isMoving = moveDirection.Magnitude > 0
			if isMoving then
				moveDirection = moveDirection.Unit
				flyLastMoveDirection = moveDirection
			end
			local flyType = State.FlyType or "CFrame"
			if activeFlyType ~= flyType then
				if flyTween then
					pcall(function() flyTween:Cancel() end)
					flyTween = nil
				end
				flyTweenClock = 0
				activeFlyType = flyType
				hardResetFlyVelocity(currentRoot)
				pcall(function()
					if flyType == "Tween" then
						currentHumanoid.PlatformStand = true
						currentHumanoid.AutoRotate = false
					else
						currentHumanoid.PlatformStand = false
						currentHumanoid.AutoRotate = true
						currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
					end
				end)
			end
			if flyType == "Tween" then
				local duration = 0.06
				flyTweenClock += deltaTime or 0
				currentRoot.AssemblyLinearVelocity = Vector3.zero
				currentRoot.AssemblyAngularVelocity = Vector3.zero
				pcall(function()
					currentHumanoid.WalkSpeed = 0
					currentHumanoid.PlatformStand = true
					currentHumanoid.AutoRotate = false
				end)
				if not isMoving then
					if flyTween then
						pcall(function() flyTween:Cancel() end)
						flyTween = nil
					end
					flyTweenClock = 0
				elseif flyTweenClock >= duration then
					flyTweenClock -= duration
					if flyTween then pcall(function() flyTween:Cancel() end) end
					local equivalentStudsPerSecond = speed * 60
					local targetPosition =
						currentRoot.Position
						+ (moveDirection * equivalentStudsPerSecond * duration)
					local targetCFrame =
						CFrame.new(targetPosition)
						* currentRoot.CFrame.Rotation
					flyTween = TweenService:Create(
						currentRoot,
						TweenInfo.new(
							duration,
							Enum.EasingStyle.Linear,
							Enum.EasingDirection.Out
						),
						{ CFrame = targetCFrame }
					)
					flyTween:Play()
				end
			else
				if flyTween then
					pcall(function() flyTween:Cancel() end)
					flyTween = nil
				end
				flyTweenClock = 0
				local stepScale = math.clamp((deltaTime or 0) * 60, 0, 1.25)
				local targetPosition = currentRoot.Position + (moveDirection * speed * stepScale)
				local targetCFrame = isMoving
					and CFrame.lookAt(targetPosition, targetPosition + moveDirection)
					or CFrame.new(targetPosition) * CFrame.lookAt(Vector3.zero, flyLastMoveDirection).Rotation
				if isMoving then
					local desyncOffset = (moveDirection * FlyDesync) + Vector3.new(
						math.sin(time() * 3.2) * 0.18,
						math.cos(time() * 2.7) * 0.12,
						0
					)
					currentRoot.CFrame = targetCFrame + desyncOffset
					currentRoot.AssemblyLinearVelocity = moveDirection * speed * 0.65
				else
					currentRoot.CFrame = targetCFrame
					currentRoot.AssemblyLinearVelocity = Vector3.zero
				end
				currentRoot.AssemblyAngularVelocity = Vector3.zero
				pcall(function()
					currentHumanoid.WalkSpeed = 0
					currentHumanoid.PlatformStand = false
					currentHumanoid.AutoRotate = true
					currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
		end)
	end
	local function toggleFly(forceState)
		if typeof(forceState) == "boolean" then
			if forceState then startFly() else stopFly(false) end
			return
		end
		if flyActive then stopFly(false) else startFly() end
	end
	local function setFlySpeed(newSpeed)
		State.Sliders.FlySpeed = getFlySpeed()
		local num = tonumber(newSpeed)
		if num then
			local modeMax = 50
			State.Sliders.FlySpeed = math.clamp(num, 1, modeMax)
		end
	end
	_G.WaveLite_Fly_Start = startFly
	_G.WaveLite_Fly_Stop = function() stopFly(false) end
	_G.WaveLite_Fly_Toggle = toggleFly
	_G.WaveLite_Fly_SetSpeed = setFlySpeed
	_G.WaveLite_Fly_IsActive = function() return flyActive end
	LocalPlayer.CharacterAdded:Connect(function()
		local shouldRestart = State.Toggles.Fly == true
		if flyConnection then pcall(function() flyConnection:Disconnect() end); flyConnection = nil end
		if flyTween then pcall(function() flyTween:Cancel() end); flyTween = nil end
		flyTweenClock = 0
		activeFlyType = nil
		disconnectFlyCharSignals()
		flyActive = false
		flyLastMoveDirection = Vector3.new(0, 0, 1)
		task.wait(0.35)
		local root = getMoveRoot()
		hardResetFlyVelocity(root)
		if shouldRestart then
			startFly()
		else
			refreshToggleVisual("Fly")
		end
	end)
end
__WaveLiteSetupFly()
__WaveLiteSetupFly = nil
function __WaveLiteSetupEsp()
	local environment = _G
	pcall(function()
		if type(getgenv) == "function" then environment = getgenv() end
	end)
	if type(environment.Wave15EspDrawingCleanup) == "function" then
		pcall(environment.Wave15EspDrawingCleanup)
	end
	local renderName = "Wave1.5 ESP Drawing"
	local espObjects = {}
	local trackedPlayers = {}
	local running = false
	local updateAccumulator = 0
	local geometryOutlineThickness = 1.8
	local geometryThickness = 1
	local textFont = 1
	local friendColor = Color3.fromRGB(255, 255, 0)
	local boxEdges = {
		{1, 2}, {3, 4}, {5, 6}, {7, 8},
		{1, 3}, {2, 4}, {5, 7}, {6, 8},
		{1, 5}, {2, 6}, {3, 7}, {4, 8},
	}
	local skeletonConnections = {
		{"Head", "Torso"}, {"Torso", "HumanoidRootPart"},
		{"Torso", "Left Arm"}, {"Torso", "Right Arm"},
		{"Torso", "Left Leg"}, {"Torso", "Right Leg"},
		{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
		{"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"},
		{"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"},
		{"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"},
		{"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"},
		{"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"},
		{"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"},
	}
	local function createDrawing(className, zIndex)
		local ok, object = pcall(function()
			return Drawing.new(className)
		end)
		if not ok or not object then return nil end
		pcall(function()
			object.Visible = false
			object.ZIndex = zIndex or 1
		end)
		return object
	end
	local function setVisible(object, visible)
		if object then pcall(function() object.Visible = visible end) end
	end
	local function removeDrawing(object)
		if not object then return end
		pcall(function()
			if typeof(object) == "Instance" then
				object:Destroy()
			else
				object:Remove()
			end
		end)
	end
	local function makeLineArray(count, zIndex)
		local result = table.create(count)
		for index = 1, count do
			result[index] = createDrawing("Line", zIndex)
		end
		return result
	end
	local function ensureLineArray(drawings, key, count, zIndex, friendOn)
		local result = drawings[key]
		if not result then
			result = makeLineArray(count, zIndex)
			drawings[key] = result
			if friendOn then
				for _, drawing in ipairs(result) do
					pcall(function() drawing.ZIndex = 1000 end)
				end
			end
		end
		return result
	end
	local function makeText(size, centered)
		local object = createDrawing("Text", 4)
		if object then
			pcall(function()
				object.Text = ""
				object.Color = Color3.fromRGB(255, 255, 255)
				object.Size = size
				object.Font = textFont
				object.Center = centered
				object.Outline = true
				object.Transparency = 1
			end)
		end
		return object
	end
	local function makeSquare(zIndex)
		local object = createDrawing("Square", zIndex or 2)
		if object then
			pcall(function()
				object.Filled = false
				object.Thickness = geometryThickness
				object.Visible = false
			end)
		end
		return object
	end
	local function makeFilledSquare(zIndex)
		local object = createDrawing("Square", zIndex or 2)
		if object then
			pcall(function()
				object.Filled = true
				object.Thickness = 0
				object.Visible = false
				object.Transparency = 1
			end)
		end
		return object
	end
	local function hideEntry(object)
		if not object or not object.drawings then return end
		for _, value in pairs(object.drawings) do
			if type(value) == "table" then
				for _, drawing in ipairs(value) do setVisible(drawing, false) end
			else
				setVisible(value, false)
			end
		end
	end
	local drawingRemovalQueue = {}
	local drawingRemovalHead, drawingRemovalTail = 1, 0
	local drawingRemovalRunning = false
	local function queueDrawingRemoval(drawings)
		drawingRemovalTail += 1
		drawingRemovalQueue[drawingRemovalTail] = drawings
		if drawingRemovalRunning then return end
		drawingRemovalRunning = true
		task.defer(function()
			local removed = 0
			while drawingRemovalHead <= drawingRemovalTail do
				local current = drawingRemovalQueue[drawingRemovalHead]
				drawingRemovalQueue[drawingRemovalHead] = nil
				drawingRemovalHead += 1
				if current then
					for _, value in pairs(current) do
						if type(value) == "table" then
							for _, drawing in ipairs(value) do
								removeDrawing(drawing)
								removed += 1
								if removed % 24 == 0 then task.wait() end
							end
						else
							removeDrawing(value)
							removed += 1
							if removed % 24 == 0 then task.wait() end
						end
					end
				end
			end
			table.clear(drawingRemovalQueue)
			drawingRemovalHead, drawingRemovalTail = 1, 0
			drawingRemovalRunning = false
		end)
	end
	local function destroyEntry(player)
		local object = espObjects[player]
		if not object then return end
		hideEntry(object)
		espObjects[player] = nil
		FriendChecks.cache[player] = nil
		queueDrawingRemoval(object.drawings)
	end
	local function createEntry(player)
		local drawings = {
			name = makeText(15, true),
			distance = makeText(9, true),
			itemText = makeText(11, false),
			box2D = makeSquare(3),
			box2DOutline = makeSquare(2),
			tracer = createDrawing("Line", 3),
			tracerOutline = createDrawing("Line", 2),
			healthBorder = makeFilledSquare(2),
			healthTrack = makeFilledSquare(3),
			healthFill = makeFilledSquare(4),
		}
		if drawings.box2DOutline then
			drawings.box2DOutline.Color = Color3.fromRGB(0, 0, 0)
			drawings.box2DOutline.Thickness = geometryOutlineThickness
		end
		if drawings.tracer then
			drawings.tracer.Color = Color3.fromRGB(255, 255, 255)
			drawings.tracer.Thickness = geometryThickness
		end
		if drawings.tracerOutline then
			drawings.tracerOutline.Color = Color3.fromRGB(0, 0, 0)
			drawings.tracerOutline.Thickness = geometryOutlineThickness
		end
		local object = {
			character = nil,
			root = nil,
			skeletonPairs = nil,
			projectedPoints = table.create(8),
			projectedFront = table.create(8),
			drawings = drawings,
			friendLayer = nil,
		}
		espObjects[player] = object
		return object
	end
	local function getRoot(character)
		if not character then return nil end
		for _, name in ipairs({"HumanoidRootPart", "Root", "LowerTorso", "Torso", "UpperTorso", "Head"}) do
			local part = character:FindFirstChild(name, true)
			if part and part:IsA("BasePart") and not part:FindFirstAncestorWhichIsA("Accessory") then
				return part
			end
		end
		if character.PrimaryPart and character.PrimaryPart:IsA("BasePart") then
			return character.PrimaryPart
		end
		local humanoid = character:FindFirstChildWhichIsA("Humanoid", true)
		if humanoid and humanoid.RootPart and humanoid.RootPart:IsDescendantOf(character) then
			return humanoid.RootPart
		end
		return nil
	end
	local function getCharacterBounds(character)
		local ok, boundsCFrame, boundsSize = pcall(function()
			return character:GetBoundingBox()
		end)
		if not ok or not boundsCFrame or not boundsSize then return nil end
		if boundsSize.X <= 0.01 or boundsSize.Y <= 0.01 or boundsSize.Z <= 0.01 then return nil end
		return boundsCFrame, boundsSize
	end
	local function buildSkeletonPairs(character)
		local byName = {}
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and byName[part.Name] == nil then
				byName[part.Name] = part
			end
		end
		local result = table.create(#skeletonConnections)
		for index, names in ipairs(skeletonConnections) do
			local first = byName[names[1]]
			local second = byName[names[2]]
			if first and second then
				result[#result + 1] = {first, second}
			end
		end
		return result
	end
	local function getSkeletonPairs(object, character)
		if object.character ~= character then
			object.character = character
			object.root = nil
			object.skeletonPairs = nil
		end
		if not object.skeletonPairs then
			object.skeletonPairs = buildSkeletonPairs(character)
		end
		return object.skeletonPairs
	end
	local function setText(object, text, position, color, size, centered)
		if not object then return end
		pcall(function()
			object.Text = text or ""
			object.Position = position
			object.Color = color or Color3.fromRGB(255, 255, 255)
			object.Size = size
			object.Font = textFont
			object.Center = centered
			object.Outline = true
			object.Transparency = 1
			object.Visible = true
		end)
	end
	local function setLine(object, fromPoint, toPoint, color, thickness)
		if not object then return end
		pcall(function()
			object.From = fromPoint
			object.To = toPoint
			object.Color = color
			object.Thickness = thickness or geometryThickness
			object.Transparency = 1
			object.Visible = true
		end)
	end
	local function setSquare(object, position, size, color, filled, thickness)
		if not object then return end
		pcall(function()
			object.Position = position
			object.Size = size
			object.Color = color
			object.Filled = filled
			object.Thickness = thickness or 0
			object.Transparency = 1
			object.Visible = true
		end)
	end
	local function healthColor(ratio)
		ratio = math.clamp(ratio or 0, 0, 1)
		local stops = {
			{0.0, Color3.fromRGB(255, 0, 0)},
			{0.3, Color3.fromRGB(255, 255, 0)},
			{0.4, Color3.fromRGB(255, 255, 0)},
			{0.5, Color3.fromRGB(200, 255, 0)},
			{0.75, Color3.fromRGB(100, 255, 0)},
			{1.0, Color3.fromRGB(0, 255, 0)},
		}
		for index = 1, #stops - 1 do
			local first, second = stops[index], stops[index + 1]
			if ratio >= first[1] and ratio <= second[1] then
				local alpha = (ratio - first[1]) / math.max(second[1] - first[1], 0.0001)
				return first[2]:Lerp(second[2], alpha)
			end
		end
		return Color3.fromRGB(0, 255, 0)
	end
	local function projectBounds(object, boundsCFrame, boundsSize, camera)
		local half = boundsSize * 0.5
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local anyOnScreen = false
		local index = 0
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					index += 1
					local localCorner = Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
					local worldCorner = boundsCFrame:PointToWorldSpace(localCorner)
					local point, onScreen = camera:WorldToViewportPoint(worldCorner)
					local inFront = point.Z > 0.05
					object.projectedPoints[index] = Vector2.new(point.X, point.Y)
					object.projectedFront[index] = inFront
					if inFront then
						minX = math.min(minX, point.X)
						minY = math.min(minY, point.Y)
						maxX = math.max(maxX, point.X)
						maxY = math.max(maxY, point.Y)
						anyOnScreen = anyOnScreen or onScreen
					end
				end
			end
		end
		if index ~= 8 or minX == math.huge or not anyOnScreen then return nil end
		local width, height = maxX - minX, maxY - minY
		if width < 1 or height < 1 then return nil end
		for cornerIndex = 1, 8 do
			if not object.projectedFront[cornerIndex] then return nil end
		end
		return minX, minY, width, height
	end
	local function drawCornerLine(mainLines, outlineLines, index, x1, y1, x2, y2, color, outlinesEnabled, outlineColor)
		local fromPoint = Vector2.new(x1, y1)
		local toPoint = Vector2.new(x2, y2)
		if outlinesEnabled then
			setLine(outlineLines[index], fromPoint, toPoint, outlineColor or Color3.fromRGB(0, 0, 0), geometryOutlineThickness)
		else
			setVisible(outlineLines[index], false)
		end
		setLine(mainLines[index], fromPoint, toPoint, color, geometryThickness)
	end
	local function drawRectCorners(mainLines, outlineLines, x, y, width, height, color, outlinesEnabled, outlineColor)
		local length = math.min(width, height) * 0.25
		local cw = math.min(width, length)
		local ch = math.min(height, length)
		local right = x + width
		local bottom = y + height
		drawCornerLine(mainLines, outlineLines, 1, x, y, x + cw, y, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 2, x, y, x, y + ch, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 3, right - cw, y, right, y, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 4, right, y, right, y + ch, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 5, x, bottom, x + cw, bottom, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 6, x, bottom - ch, x, bottom, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 7, right - cw, bottom, right, bottom, color, outlinesEnabled, outlineColor)
		drawCornerLine(mainLines, outlineLines, 8, right, bottom - ch, right, bottom, color, outlinesEnabled, outlineColor)
	end
	local function draw3D(mainLines, outlineLines, object, color, outlinesEnabled, cornerOnly, outlineColor)
		local lineIndex = 0
		for _, edge in ipairs(boxEdges) do
			local firstIndex, secondIndex = edge[1], edge[2]
			if object.projectedFront[firstIndex] and object.projectedFront[secondIndex] then
				local first = object.projectedPoints[firstIndex]
				local second = object.projectedPoints[secondIndex]
				if cornerOnly then
					local delta = second - first
					local length = delta.Magnitude
					if length > 0 then
						local segmentLength = math.min(length * 0.2, 12)
						local direction = delta.Unit
						local startA, endA = first, first + direction * segmentLength
						local startB, endB = second - direction * segmentLength, second
						lineIndex += 1
						if outlinesEnabled then
							setLine(outlineLines[lineIndex], startA, endA, (outlineColor or Color3.fromRGB(0, 0, 0)), geometryOutlineThickness)
						else
							setVisible(outlineLines[lineIndex], false)
						end
						setLine(mainLines[lineIndex], startA, endA, color, geometryThickness)
						lineIndex += 1
						if outlinesEnabled then
							setLine(outlineLines[lineIndex], startB, endB, (outlineColor or Color3.fromRGB(0, 0, 0)), geometryOutlineThickness)
						else
							setVisible(outlineLines[lineIndex], false)
						end
						setLine(mainLines[lineIndex], startB, endB, color, geometryThickness)
					end
				else
					lineIndex += 1
					if outlinesEnabled then
						setLine(outlineLines[lineIndex], first, second, (outlineColor or Color3.fromRGB(0, 0, 0)), geometryOutlineThickness)
					else
						setVisible(outlineLines[lineIndex], false)
					end
					setLine(mainLines[lineIndex], first, second, color, geometryThickness)
				end
			end
		end
		for index = lineIndex + 1, #mainLines do
			setVisible(mainLines[index], false)
			setVisible(outlineLines[index], false)
		end
	end
	local function updateSkeleton(object, character, camera, color, outlinesEnabled, outlineColor, friendOn)
		local links = getSkeletonPairs(object, character)
		local mainLines = ensureLineArray(object.drawings, "skeleton", 24, 3, friendOn)
		local outlineLines = ensureLineArray(object.drawings, "skeletonOutline", 24, 2, friendOn)
		for index = 1, #links do
			local firstPart = links[index][1]
			local secondPart = links[index][2]
			local mainLine = mainLines[index]
			local outlineLine = outlineLines[index]
			if firstPart.Parent and secondPart.Parent then
				local a = camera:WorldToViewportPoint(firstPart.Position)
				local b = camera:WorldToViewportPoint(secondPart.Position)
				if a.Z > 0.05 and b.Z > 0.05 then
					local fromPoint = Vector2.new(a.X, a.Y)
					local toPoint = Vector2.new(b.X, b.Y)
					if outlinesEnabled then
						setLine(outlineLine, fromPoint, toPoint, (outlineColor or Color3.fromRGB(0, 0, 0)), geometryOutlineThickness)
					else
						setVisible(outlineLine, false)
					end
					setLine(mainLine, fromPoint, toPoint, color, geometryThickness)
				else
					setVisible(mainLine, false)
					setVisible(outlineLine, false)
				end
			else
				setVisible(mainLine, false)
				setVisible(outlineLine, false)
			end
		end
		for index = #links + 1, #mainLines do
			setVisible(mainLines[index], false)
			setVisible(outlineLines[index], false)
		end
	end
	local function anyEspOn()
		local toggles = State.Toggles
		return toggles.NameEsp or toggles.Tracers or toggles.Skeleton
			or toggles.BoxOutline or toggles.BoxCorners or toggles.Box3D
			or toggles.Box3DCorners or toggles.HealthBars or toggles.Distance or toggles.ShowItems
	end
	local function updateHealthBar(object, boxX, boxY, boxHeight, humanoid)
		local drawings = object.drawings
		local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		local barHeight = math.max(1, boxHeight)
		local border = math.clamp(barHeight * 0.01, 0.35, 0.85)
		local trackWidth = math.clamp(barHeight * 0.028, 0.6, 2.3)
		local outerWidth = trackWidth + border * 2
		local innerHeight = math.max(0, barHeight - border * 2)
		local fillHeight = innerHeight * ratio
		local outerX = boxX - outerWidth - 4
		local outerY = boxY
		local innerX = outerX + border
		local innerY = outerY + border
		setSquare(drawings.healthBorder, Vector2.new(outerX, outerY),
			Vector2.new(outerWidth, barHeight), Color3.fromRGB(0, 0, 0), true, 0)
		setSquare(drawings.healthTrack, Vector2.new(innerX, innerY),
			Vector2.new(trackWidth, innerHeight), Color3.fromRGB(24, 24, 24), true, 0)
		setSquare(drawings.healthFill, Vector2.new(innerX, innerY + innerHeight - fillHeight),
			Vector2.new(trackWidth, fillHeight), healthColor(ratio), true, 0)
	end
	local function setDrawingZIndex(drawing, zIndex)
		if drawing then pcall(function() drawing.ZIndex = zIndex end) end
	end
	local function setFriendLayer(object, friendOn)
		if object.friendLayer == friendOn then return end
		object.friendLayer = friendOn
		local drawings = object.drawings
		local high = friendOn and 1000 or nil
		setDrawingZIndex(drawings.name, high or 4)
		setDrawingZIndex(drawings.box2D, high or 3)
		setDrawingZIndex(drawings.box2DOutline, high or 2)
		setDrawingZIndex(drawings.tracer, high or 3)
		setDrawingZIndex(drawings.tracerOutline, high or 2)
		for key, value in pairs(drawings) do
			if type(value) == "table" then
				local base = key:find("Outline", 1, true) and 2 or 3
				for _, drawing in ipairs(value) do
					setDrawingZIndex(drawing, high or base)
				end
			end
		end
	end
	local function updateEntry(player, object, camera, localRoot, viewport)
		if State.Toggles.EspTeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
			hideEntry(object)
			return
		end
		local character = getEspCharacter(player)
		if not character then
			hideEntry(object)
			object.character = nil
			object.root = nil
			object.humanoid = nil
			object.skeletonPairs = nil
			return
		end
		local root = object.character == character and object.root or nil
		if not root or not root.Parent or not root:IsDescendantOf(character) then
			root = getRoot(character)
		end
		if not root then
			hideEntry(object)
			object.character = nil
			object.root = nil
			object.humanoid = nil
			object.skeletonPairs = nil
			return
		end
		if object.character ~= character or object.root ~= root then
			hideEntry(object)
			object.character = character
			object.root = root
			object.humanoid = nil
			object.skeletonPairs = nil
		end
		local humanoid = object.humanoid
		if not humanoid or not humanoid.Parent or not humanoid:IsDescendantOf(character) then
			humanoid = character:FindFirstChildOfClass("Humanoid")
				or character:FindFirstChildWhichIsA("Humanoid", true)
			object.humanoid = humanoid
		end
		if humanoid and humanoid.Health <= 0 then
			hideEntry(object)
			return
		end
		local boundsCFrame, boundsSize = getCharacterBounds(character)
		local friendOn = State.Toggles.FriendEsp and FriendChecks.isFriend(player)
		local white = Color3.fromRGB(255, 255, 255)
		local playerColor = friendOn and friendColor or white
		if not boundsCFrame or not boundsSize then
			hideEntry(object)
			return
		end
		local boxX, boxY, boxWidth, boxHeight = projectBounds(object, boundsCFrame, boundsSize, camera)
		if not boxX then
			hideEntry(object)
			return
		end
		local boxRight = boxX + boxWidth
		local boxBottom = boxY + boxHeight
		local centerX = boxX + boxWidth * 0.5
		local distance = localRoot and math.floor((localRoot.Position - root.Position).Magnitude + 0.5) or 0
		local outlineColor = friendOn and friendColor or Color3.fromRGB(0, 0, 0)
		local outlinesEnabled = true
		setFriendLayer(object, friendOn)
		if State.Toggles.NameEsp then
			local displayName = player.DisplayName
			if not displayName or displayName == "" then displayName = player.Name end
			setText(object.drawings.name, displayName,
				Vector2.new(centerX, boxY - 17), playerColor, 15, true)
		else
			setVisible(object.drawings.name, false)
		end
		if State.Toggles.BoxOutline then
			if outlinesEnabled then
				setSquare(object.drawings.box2DOutline, Vector2.new(boxX - 1, boxY - 1),
					Vector2.new(boxWidth + 2, boxHeight + 2), outlineColor, false, geometryOutlineThickness)
			else
				setVisible(object.drawings.box2DOutline, false)
			end
			setSquare(object.drawings.box2D, Vector2.new(boxX, boxY),
				Vector2.new(boxWidth, boxHeight), playerColor, false, geometryThickness)
		else
			setVisible(object.drawings.box2D, false)
			setVisible(object.drawings.box2DOutline, false)
		end
		if State.Toggles.BoxCorners then
			local mainLines = ensureLineArray(object.drawings, "box2DCorners", 8, 3, friendOn)
			local outlineLines = ensureLineArray(object.drawings, "box2DCornersOutline", 8, 2, friendOn)
			drawRectCorners(mainLines, outlineLines, boxX, boxY, boxWidth, boxHeight, playerColor, outlinesEnabled, outlineColor)
		else
			local mainLines = object.drawings.box2DCorners
			local outlineLines = object.drawings.box2DCornersOutline
			if mainLines then
				for index = 1, #mainLines do setVisible(mainLines[index], false) end
			end
			if outlineLines then
				for index = 1, #outlineLines do setVisible(outlineLines[index], false) end
			end
		end
		if State.Toggles.Box3D then
			local mainLines = ensureLineArray(object.drawings, "box3D", 12, 3, friendOn)
			local outlineLines = ensureLineArray(object.drawings, "box3DOutline", 12, 2, friendOn)
			draw3D(mainLines, outlineLines, object, playerColor, outlinesEnabled, false, outlineColor)
		else
			local mainLines = object.drawings.box3D
			local outlineLines = object.drawings.box3DOutline
			if mainLines then
				for index = 1, #mainLines do setVisible(mainLines[index], false) end
			end
			if outlineLines then
				for index = 1, #outlineLines do setVisible(outlineLines[index], false) end
			end
		end
		if State.Toggles.Box3DCorners then
			local mainLines = ensureLineArray(object.drawings, "box3DCorners", 24, 3, friendOn)
			local outlineLines = ensureLineArray(object.drawings, "box3DCornersOutline", 24, 2, friendOn)
			draw3D(mainLines, outlineLines, object, playerColor, outlinesEnabled, true, outlineColor)
		else
			local mainLines = object.drawings.box3DCorners
			local outlineLines = object.drawings.box3DCornersOutline
			if mainLines then
				for index = 1, #mainLines do setVisible(mainLines[index], false) end
			end
			if outlineLines then
				for index = 1, #outlineLines do setVisible(outlineLines[index], false) end
			end
		end
		if State.Toggles.Skeleton then
			updateSkeleton(object, character, camera, playerColor, outlinesEnabled, outlineColor, friendOn)
		else
			local mainLines = object.drawings.skeleton
			local outlineLines = object.drawings.skeletonOutline
			if mainLines then
				for index = 1, #mainLines do setVisible(mainLines[index], false) end
			end
			if outlineLines then
				for index = 1, #outlineLines do setVisible(outlineLines[index], false) end
			end
		end
		local rootPoint = camera:WorldToViewportPoint(root.Position)
		if State.Toggles.Tracers and rootPoint.Z > 0.05 then
			local fromPoint = Vector2.new(viewport.X * 0.5, viewport.Y - 2)
			local toPoint = Vector2.new(rootPoint.X, rootPoint.Y)
			if outlinesEnabled then
				setLine(object.drawings.tracerOutline, fromPoint, toPoint,
					outlineColor, geometryOutlineThickness)
			else
				setVisible(object.drawings.tracerOutline, false)
			end
			setLine(object.drawings.tracer, fromPoint, toPoint, playerColor, geometryThickness)
		else
			setVisible(object.drawings.tracer, false)
			setVisible(object.drawings.tracerOutline, false)
		end
		if State.Toggles.Distance then
			setText(object.drawings.distance, string.format("[%d]", distance),
				Vector2.new(centerX, boxBottom + 3), white, 9, true)
		else
			setVisible(object.drawings.distance, false)
		end
		local equippedTool = nil
		if State.Toggles.ShowItems then
			equippedTool = character:FindFirstChildWhichIsA("Tool")
		end
		local sideTextY = boxY + 2
		if State.Toggles.ShowItems and equippedTool then
			setText(object.drawings.itemText, equippedTool.Name,
				Vector2.new(boxRight + 7, sideTextY), white, 11, false)
			sideTextY += 14
		else
			setVisible(object.drawings.itemText, false)
		end
		if State.Toggles.HealthBars and humanoid then
			updateHealthBar(object, boxX, boxY, boxHeight, humanoid)
		else
			setVisible(object.drawings.healthBorder, false)
			setVisible(object.drawings.healthTrack, false)
			setVisible(object.drawings.healthFill, false)
		end
	end
	local function updateEspFrame(deltaTime, force)
		if not running then return end
		local selectedRate = State.EspUpdateRate or "Auto"
		local targetHz = tonumber(selectedRate)
		if not force and targetHz then
			local interval = 1 / targetHz
			updateAccumulator += math.max(deltaTime or 0, 0)
			if updateAccumulator + 0.000001 < interval then return end
			updateAccumulator %= interval
		else
			updateAccumulator = 0
		end
		local camera = workspace.CurrentCamera
		if not camera then
			for _, object in pairs(espObjects) do hideEntry(object) end
			return
		end
		Camera = camera
		if not anyEspOn() then
			for _, object in pairs(espObjects) do hideEntry(object) end
			return
		end
		local localCharacter = LocalPlayer.Character
		local localRoot = localCharacter and getRoot(localCharacter) or nil
		local viewport = camera.ViewportSize
		for index = 1, #trackedPlayers do
			local player = trackedPlayers[index]
			if player and player.Parent == Players then
				local object = espObjects[player] or createEntry(player)
				local ok = pcall(updateEntry, player, object, camera, localRoot, viewport)
				if not ok then hideEntry(object) end
			end
		end
	end
	local function clearAll()
		for player in pairs(espObjects) do destroyEntry(player) end
	end
	local function syncEspLoop()
		if anyEspOn() and not running then
			running = true
			updateAccumulator = 0
			pcall(function() RunService:UnbindFromRenderStep(renderName) end)
			RunService:BindToRenderStep(renderName, Enum.RenderPriority.Last.Value + 1, function(deltaTime)
				updateEspFrame(deltaTime, camLockActive)
			end)
			updateEspFrame(0, true)
		elseif not anyEspOn() and running then
			running = false
			pcall(function() RunService:UnbindFromRenderStep(renderName) end)
			updateAccumulator = 0
			clearAll()
		end
	end
	local function setEspToggle(key, value)
		State.Toggles[key] = value and true or false
		syncEspLoop()
		if running then updateEspFrame(0, true) end
	end
	_G.WaveLite_NameEsp_Toggle = function(on) setEspToggle("NameEsp", on) end
	_G.WaveLite_Tracers_Toggle = function(on) setEspToggle("Tracers", on) end
	_G.WaveLite_FriendEsp_Toggle = function(on) setEspToggle("FriendEsp", on) end
	_G.WaveLite_EspTeamCheck_Toggle = function(on) setEspToggle("EspTeamCheck", on) end
	_G.WaveLite_Skeleton_Toggle = function(on) setEspToggle("Skeleton", on) end
	_G.WaveLite_BoxOutline_Toggle = function(on) setEspToggle("BoxOutline", on) end
	_G.WaveLite_BoxCorners_Toggle = function(on) setEspToggle("BoxCorners", on) end
	_G.WaveLite_Box3D_Toggle = function(on) setEspToggle("Box3D", on) end
	_G.WaveLite_Box3DCorners_Toggle = function(on) setEspToggle("Box3DCorners", on) end
	_G.WaveLite_HealthBars_Toggle = function(on) setEspToggle("HealthBars", on) end
	_G.WaveLite_Distance_Toggle = function(on) setEspToggle("Distance", on) end
	_G.WaveLite_ShowItems_Toggle = function(on) setEspToggle("ShowItems", on) end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			trackedPlayers[#trackedPlayers + 1] = player
		end
	end
	local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer then
			trackedPlayers[#trackedPlayers + 1] = player
			FriendChecks.cache[player] = nil
		end
	end)
	local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		destroyEntry(player)
		for index = #trackedPlayers, 1, -1 do
			if trackedPlayers[index] == player then
				table.remove(trackedPlayers, index)
				break
			end
		end
	end)
	local cleanupStarted = false
	local function cleanupEsp()
		if cleanupStarted then return end
		cleanupStarted = true
		running = false
		pcall(function() RunService:UnbindFromRenderStep(renderName) end)
		pcall(function() playerAddedConnection:Disconnect() end)
		pcall(function() playerRemovingConnection:Disconnect() end)
		clearAll()
		table.clear(trackedPlayers)
		if environment.Wave15EspDrawingCleanup == cleanupEsp then
			environment.Wave15EspDrawingCleanup = nil
		end
	end
	environment.Wave15EspDrawingCleanup = cleanupEsp
	ScreenGui.AncestryChanged:Connect(function(_, parent)
		if not parent then cleanupEsp() end
	end)
end
__WaveLiteSetupEsp()
__WaveLiteSetupEsp = nil
local FeatureToggleCallbacks = {
	Camlock = "WaveLite_CamLock_Toggle", Silent = "WaveLite_Silent_Toggle",
	Fly = "WaveLite_Fly_Toggle", Noclip = "WaveLite_Noclip_Toggle",
	NameEsp = "WaveLite_NameEsp_Toggle", Tracers = "WaveLite_Tracers_Toggle",
	FriendEsp = "WaveLite_FriendEsp_Toggle", EspTeamCheck = "WaveLite_EspTeamCheck_Toggle",
	AutoPickup = "WaveLite_AutoPickup_Toggle",
	Skeleton = "WaveLite_Skeleton_Toggle",
	BoxOutline = "WaveLite_BoxOutline_Toggle",
	Box3D = "WaveLite_Box3D_Toggle", BoxCorners = "WaveLite_BoxCorners_Toggle",
	HealthBars = "WaveLite_HealthBars_Toggle", Box3DCorners = "WaveLite_Box3DCorners_Toggle", ShowItems = "WaveLite_ShowItems_Toggle",
	Distance = "WaveLite_Distance_Toggle", NoFog = "WaveLite_NoFog_Toggle",
	DisableShadows = "WaveLite_DisableShadows_Toggle", LowGfx = "WaveLite_LowGfx_Toggle",
	Maxzoom = "WaveLite_Maxzoom_Toggle", AntiAfk = "WaveLite_AntiAfk_Toggle",
	InfJump = "WaveLite_InfJump_Toggle", AntiSeat = "WaveLite_AntiSeat_Toggle",
	Spinbot = "WaveLite_Spinbot_Toggle",
}
for stateName, globalName in pairs(FeatureToggleCallbacks) do
	local callbackName = globalName
	ToggleCallbacks[stateName] = function(on)
		local callback = _G[callbackName]
		if type(callback) == "function" then callback(on) end
	end
end
local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
	if waitingForKey then return end
	closeDropdown()
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
	if activeSlider then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			activeSlider.Set(input.Position.X)
		end
		return
	end
	if dragging and dragStart and startPos then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
			local w, h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
			local nx = math.clamp(startPos.X.Offset + delta.X, -vp.X / 2 - w / 2 + 100, vp.X / 2 + w / 2 - 100)
			local ny = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y / 2 + h / 2, vp.Y / 2 + h / 2 - 40)
			Main.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
		end
	end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
	local endedName = inputToKeyName(input)
	if endedName then heldInputNames[endedName] = nil end
	if keybindClickBlockUntil == math.huge and input.UserInputType.Name:match("^MouseButton%d$") then
		keybindClickBlockUntil = os.clock() + 0.1
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider = nil
		dragging = false
	end
end))
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local keyName = inputToKeyName(input)
	if keyName then heldInputNames[keyName] = true end
	if waitingForKey then
		if input.KeyCode == Enum.KeyCode.Escape then
			waitingForKey.Box.Text = shortKeyName(State.Keybinds[waitingForKey.Name])
			waitingForKey = nil
			return
		end
		if not keyName then return end
		local opts = waitingForKey.Opts or {}
		if opts.KeyboardOnly and keyName:sub(1, 5) == "Mouse" then return end
		State.Keybinds[waitingForKey.Name] = keyName
		waitingForKey.Box.Text = shortKeyName(keyName)
		waitingForKey = nil
		if keyName:sub(1, 5) == "Mouse" then keybindClickBlockUntil = math.huge end
		if opts.OnChange then pcall(opts.OnChange) end
		return
	end
	if gameProcessed then return end
	if keyName == (State.Keybinds.MenuToggle or "Insert") then
		Main.Visible = not Main.Visible
		if not Main.Visible then closeDropdown() end
		pcall(function() BlurController.UpdateAll() end)
		return
	end
	if keyName and State.Keybinds.FlyToggle and keyName == State.Keybinds.FlyToggle and _G.WaveLite_Fly_Toggle then
		_G.WaveLite_Fly_Toggle()
	end
	if keyName and State.Keybinds.CamLockToggle and keyName == State.Keybinds.CamLockToggle and _G.WaveLite_CamLock_Toggle then
		_G.WaveLite_CamLock_Toggle()
	end
	if keyName and State.Keybinds.SilentToggle and keyName == State.Keybinds.SilentToggle and _G.WaveLite_Silent_Toggle then
		_G.WaveLite_Silent_Toggle()
	end
end))
applyTheme("dark")
syncLogoVisibility()
syncBlurButton()
applyArrayPosition()
refreshArrayList()
BlurController.RefreshGlass()
setThemePreset(State.Theme)
setBackdropPreset(State.Preset)
if setCombatType then setCombatType(State.CombatType) end
for _, sync in ipairs(keybindSyncs) do pcall(sync) end
for _, sync in ipairs(choiceSyncs) do pcall(sync) end
if refreshArrayList then refreshArrayList() end
