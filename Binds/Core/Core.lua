local ADDON_NAME, ns = ...

-- Global so external addons can register modules (see documentation/API.md).
local Binds = CreateFrame("Frame", "BindsCoreFrame")
_G.Binds = Binds
ns.Binds = Binds

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

Binds.name = ADDON_NAME
-- The TOC title carries icon and color for the addon list; strip both so the name can be styled freely here.
local function PlainText(text)
	text = text:gsub("|T.-|t", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local rawTitle = GetMetadata(ADDON_NAME, "Title")
Binds.title = rawTitle and PlainText(rawTitle) ~= "" and PlainText(rawTitle) or ADDON_NAME
Binds.version = GetMetadata(ADDON_NAME, "Version") or "?"
Binds.author = GetMetadata(ADDON_NAME, "Author") or "?"

-- Retail and the Forever client share one TOC, so features are detected, not version-checked.
-- Forever runs on a modern client build, so the interface number alone cannot tell it apart; the project ID can.
Binds.isRetail = WOW_PROJECT_ID ~= nil and WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

----------------------------------------------------------------------
-- Locale
----------------------------------------------------------------------

do
	local locales = ns.Locales or {}
	local fallback = locales.enUS or {}
	local current = locales[GetLocale()] or {}
	-- Missing keys fall back to enUS, then to the key itself, so a gap never errors in a tooltip.
	ns.L = setmetatable({}, {
		__index = function(_, key)
			return current[key] or fallback[key] or key
		end,
	})
end

----------------------------------------------------------------------
-- Colors (brand palette, see documentation/assets/Farbschema.md)
----------------------------------------------------------------------

local function HexToRGB(hex)
	hex = hex:gsub("#", "")
	return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local palette = {
	primary = "CBB9A5",
	accent = "E6D2B9",
	neutralLight = "F0EAE6",
	neutralDark = "ADA09A",
	taupe = "72645C",
}

Binds.colors = {}
for key, hex in pairs(palette) do
	local r, g, b = HexToRGB(hex)
	Binds.colors[key] = { r = r, g = g, b = b, hex = hex }
end

local function MakeColor(hex)
	local r, g, b = HexToRGB(hex)
	return { r = r, g = g, b = b, hex = hex }
end

-- Mixes a color toward white; used for the binding text next to its category label.
local function Lighten(color, amount)
	local function mix(c)
		return c + (1 - c) * amount
	end
	local r, g, b = mix(color.r), mix(color.g), mix(color.b)
	return { r = r, g = g, b = b, hex = ("%02X%02X%02X"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5) }
end

-- Category colors are separate from the brand palette: they must stay distinguishable at a glance.
Binds.categoryColors = {
	keyboard = MakeColor("66BBFF"),
	mouse = MakeColor("FFB454"),
	click = MakeColor("D6A4FF"),
}

Binds.categoryLightColors = {}
for key, color in pairs(Binds.categoryColors) do
	Binds.categoryLightColors[key] = Lighten(color, 0.6)
end

-- Inline texture for tooltips and font strings. Size 0 follows the font height.
local MEDIA = "Interface\\AddOns\\Binds\\Media\\"

function Binds:Texture(file, size, color)
	size = size or 0
	if color then
		local r, g, b = math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255)
		return ("|T%s%s:%d:%d:0:0:32:32:0:32:0:32:%d:%d:%d|t"):format(MEDIA, file, size, size, r, g, b)
	end
	return ("|T%s%s:%d:%d|t"):format(MEDIA, file, size, size)
end

-- Thin divider line as used in the options sections. A 1-unit line on a sub-pixel position renders
-- two pixels thick, so it is sized in physical pixels and snapped to the grid.
function Binds:CreateDivider(parent, layer)
	local line = parent:CreateTexture(nil, layer or "ARTWORK")
	local color = self.colors.neutralDark
	line:SetColorTexture(color.r, color.g, color.b, 0.35)
	if PixelUtil and PixelUtil.SetHeight then
		PixelUtil.SetHeight(line, 1)
	else
		line:SetHeight(1)
	end
	if line.SetSnapToPixelGrid then
		line:SetSnapToPixelGrid(true)
		line:SetTexelSnappingBias(0)
	end
	return line
end

-- "Binds" header line for tooltips: icon, name and a divider up to the right edge, like the option sections.
-- One divider per tooltip, hidden again when the tooltip is cleared or hidden.
function Binds:AddTooltipHeader(tooltip)
	tooltip:AddLine(self:Texture("Binds_Icon_dunkel_32x32", 0) .. " " .. self:Colorize(self.title, "primary"))
	local name = tooltip.GetName and tooltip:GetName()
	local text = name and _G[name .. "TextLeft" .. tooltip:NumLines()]
	if not text then
		return
	end
	local line = tooltip.bindsHeaderLine
	if not line then
		line = self:CreateDivider(tooltip)
		tooltip.bindsHeaderLine = line
		local function hide()
			line:Hide()
		end
		tooltip:HookScript("OnHide", hide)
		if tooltip:HasScript("OnTooltipCleared") then
			tooltip:HookScript("OnTooltipCleared", hide)
		end
	end
	line:ClearAllPoints()
	-- Anchored to the text's right edge instead of measuring it: in Retail the tooltip's text width is a
	-- secret value, and any arithmetic on it taints the tooltip. Tooltip lines are sized to their text.
	line:SetPoint("LEFT", text, "RIGHT", 8, 0)
	line:SetPoint("RIGHT", tooltip, "RIGHT", -10, 0)
	line:Show()
end

function Binds:Colorize(text, colorKey)
	local color = self.colors[colorKey] or self.categoryColors[colorKey]
	if not color then
		return text
	end
	return "|cff" .. color.hex .. text .. "|r"
end

----------------------------------------------------------------------
-- Output
----------------------------------------------------------------------

function Binds:Print(...)
	print(self:Colorize(self.title, "primary") .. ":", ...)
end

-- BugLab applies the style to every source of the addon, so it is set once on the root logger.
local function LoggerStyle()
	local c = Binds.colors
	return {
		name = Binds.title,
		nameColor = c.primary.hex,
		colors = { c.primary.hex, c.accent.hex, c.neutralLight.hex, c.neutralDark.hex },
	}
end

-- BugLab is optional; without it debug lines go to the chat frame.
function Binds:GetLogger(module)
	if not (BugLab and BugLab.GetLogger) then
		return nil
	end
	if not self.loggerStyled then
		BugLab:GetLogger(ADDON_NAME, LoggerStyle())
		self.loggerStyled = true
	end
	return BugLab:GetLogger(module and (ADDON_NAME .. ":" .. module) or ADDON_NAME)
end

-- Format-style like string.format, matching BugLab's logger signature.
function Binds:Debug(fmt, ...)
	if not (self.db and self.db.debug) then
		return
	end
	local log = self:GetLogger()
	if log then
		log:Debug(fmt, ...)
	else
		print(self:Colorize(self.title, "taupe") .. " [debug]: " .. fmt:format(...))
	end
end

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------

Binds.defaults = {
	showInTooltip = true,
	-- Unit tooltips list the click casts usable on that friendly unit.
	unitClickCasts = true,
	-- Optional: Blizzard click casts with a modifier also act as mouseover casts on units in the world.
	mouseoverCasts = false,
	-- Extras for click casts; they ride on the mouseover module and only take effect while mouseoverCasts is on.
	clicks = {
		-- Spell icons next to click casts in tooltips.
		icons = true,
		-- Counterpart spell per click cast: heal <-> damage, keyed by the first spell ID.
		second = false,
		secondSpells = {},
		-- The choice list also offers spells of the same kind (greyed out, inactive).
		showAll = false,
		-- Resurrection on dead group members, "normal" or "combat" variant, whatever click is used.
		resurrect = false,
		-- Carry second spell and resurrection over to Blizzard's unit frames.
		unitFrames = true,
		resurrectMode = "normal",
	},
	-- Which category rows the tooltip section shows.
	categories = {
		keyboard = true,
		mouse = true,
		click = true,
	},
	modifierFilter = {
		enabled = false,
		shift = true,
		ctrl = false,
		alt = false,
	},
	minimap = { hide = false },
	debug = false,
}

local function ApplyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			ApplyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
	return target
end

-- Settings are always account-wide; detected bindings are never persisted, only read live from the game.
function Binds:LoadSettings()
	BindsDB = ApplyDefaults(BindsDB or {}, self.defaults)
	self.db = BindsDB
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

local eventHandlers = {}

-- Several modules may listen to the same event; one frame keeps registration cheap.
function Binds:RegisterModuleEvent(module, event, method)
	eventHandlers[event] = eventHandlers[event] or {}
	table.insert(eventHandlers[event], { module = module, method = method or event })
	-- Some events do not exist in every client; registering them must not break loading.
	pcall(self.RegisterEvent, self, event)
end

Binds:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON_NAME then
			self:UnregisterEvent("ADDON_LOADED")
			self:OnInitialize()
		end
		return
	end
	if event == "PLAYER_LOGIN" then
		self:OnEnable()
	end
	local handlers = eventHandlers[event]
	if handlers then
		for _, entry in ipairs(handlers) do
			local handler = entry.module[entry.method]
			if handler then
				handler(entry.module, event, ...)
			end
		end
	end
end)
Binds:RegisterEvent("ADDON_LOADED")
Binds:RegisterEvent("PLAYER_LOGIN")

----------------------------------------------------------------------
-- Internal messages (module to module)
----------------------------------------------------------------------

local messageHandlers = {}

function Binds:On(message, module, method)
	messageHandlers[message] = messageHandlers[message] or {}
	table.insert(messageHandlers[message], { module = module, method = method or message })
end

function Binds:Fire(message, ...)
	local handlers = messageHandlers[message]
	if not handlers then
		return
	end
	for _, entry in ipairs(handlers) do
		local handler = entry.module[entry.method]
		if handler then
			handler(entry.module, message, ...)
		end
	end
end

----------------------------------------------------------------------
-- Modules
----------------------------------------------------------------------

Binds.modules = {}
local moduleOrder = {}
local initialized, enabled = false, false

-- Internal and external modules use the same entry point (pattern as in Scrap/DBM).
function Binds:RegisterModule(name, module)
	assert(type(name) == "string", "RegisterModule: name must be a string")
	assert(not self.modules[name], "RegisterModule: module '" .. name .. "' already exists")
	module = module or {}
	module.name = name
	module.core = self
	self.modules[name] = module
	table.insert(moduleOrder, name)

	-- External addons may load after Binds; catch them up to the current lifecycle state.
	if initialized and module.OnInitialize then
		module:OnInitialize()
	end
	if enabled and module.OnEnable then
		module:OnEnable()
	end
	return module
end

function Binds:GetModule(name)
	return self.modules[name]
end

function Binds:OnInitialize()
	self:LoadSettings()
	initialized = true
	for _, name in ipairs(moduleOrder) do
		local module = self.modules[name]
		if module.OnInitialize then
			module:OnInitialize()
		end
	end
end

function Binds:OnEnable()
	enabled = true
	for _, name in ipairs(moduleOrder) do
		local module = self.modules[name]
		if module.OnEnable then
			module:OnEnable()
		end
	end
	-- BugLab's announce line is independent of our debug toggle; it states the toggle itself.
	local log = self:GetLogger()
	if log and log.Announce then
		log:Announce({ version = self.version, debug = self.db.debug })
	end
end
