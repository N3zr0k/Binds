local _, ns = ...
local Binds = ns.Binds

-- Collects bindings per action. Results are cached in memory only and rebuilt lazily after relevant events.
local Scanner = Binds:RegisterModule("Scanner")

-- Kinds used as lookup keys: "spell", "item", "macro". Their IDs overlap, so they are kept apart.
local cache
local dirty = true

-- Page, form and vehicle switches change which key fires which spell, so they invalidate too.
local REFRESH_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"UPDATE_BINDINGS",
	"UPDATE_MACROS",
	"ACTIONBAR_SLOT_CHANGED",
	"ACTIONBAR_PAGE_CHANGED",
	"UPDATE_BONUS_ACTIONBAR",
	"UPDATE_SHAPESHIFT_FORM",
	"UPDATE_SHAPESHIFT_FORMS",
	"UPDATE_STEALTH",
	"UPDATE_OVERRIDE_ACTIONBAR",
	"UPDATE_EXTRA_ACTIONBAR",
	"UPDATE_POSSESS_BAR",
	"UPDATE_VEHICLE_ACTIONBAR",
	"CLICKBINDINGS_SET_HIGHLIGHTS_SHOWN",
}

-- Retail can hand out secret values that must not be compared or converted; treat them as missing.
local function Clean(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

local function Either(namespace, name)
	return namespace and namespace[name] or _G[name]
end

local GetActionBarPage = Either(C_ActionBar, "GetActionBarPage")
local GetBonusBarOffset = Either(C_ActionBar, "GetBonusBarOffset")
local GetActionSpell = C_ActionBar and C_ActionBar.GetSpell
local GetItemInfoInstant = Either(C_Item, "GetItemInfoInstant")

----------------------------------------------------------------------
-- Key classification and formatting
----------------------------------------------------------------------

-- Blizzard writes modifiers in several spellings (C-, CTRL-, META-); normalize before display.
local MODIFIER_ALIASES = {
	C = "CTRL", CTRL = "CTRL", CONTROL = "CTRL",
	A = "ALT", ALT = "ALT",
	S = "SHIFT", SHIFT = "SHIFT",
	M = "META", META = "META", CMD = "META",
}

-- Fixed display order, regardless of how the client orders them.
local MODIFIER_ORDER = { "CTRL", "ALT", "SHIFT", "META" }

-- Splits "CTRL-SHIFT-BUTTON4" into its modifiers and the base key. Only leading prefixes count, so "CTRL--" stays the minus key.
function Scanner:ParseKey(key)
	local modifiers, base = {}, key
	while true do
		local prefix, rest = base:match("^([^-]+)%-(.+)$")
		local modifier = prefix and MODIFIER_ALIASES[prefix:upper()]
		if not modifier then
			break
		end
		modifiers[modifier] = true
		base = rest
	end
	return modifiers, base
end

-- Mouse buttons with modifiers stay in the mouse category (requirement).
function Scanner:Classify(key)
	local _, base = self:ParseKey(key)
	base = base:upper()
	if base:match("^BUTTON%d+$") or base == "MOUSEWHEELUP" or base == "MOUSEWHEELDOWN" then
		return "mouse"
	end
	if base:match("^PAD") then
		-- Gamepad bindings are hidden in version 1.
		return nil
	end
	return "keyboard"
end

local function JoinModifiers(modifiers, text)
	local parts = {}
	for _, modifier in ipairs(MODIFIER_ORDER) do
		if modifiers[modifier] then
			table.insert(parts, _G[modifier .. "_KEY_TEXT"] or modifier)
		end
	end
	table.insert(parts, text)
	return table.concat(parts, " + ")
end

-- Builds "SHIFT + 1" from Blizzard's localized key names.
function Scanner:FormatKey(key)
	local modifiers, base = self:ParseKey(key)
	local text = GetBindingText and GetBindingText(base, "KEY_") or base
	if not text or text == "" then
		text = base
	end
	return JoinModifiers(modifiers, text)
end

----------------------------------------------------------------------
-- Entries
----------------------------------------------------------------------

local function Add(result, kind, id, category, text)
	id = tonumber(id)
	if not (kind and id and category and text) then
		return
	end
	result[kind] = result[kind] or {}
	local entry = result[kind][id]
	if not entry then
		entry = { keyboard = {}, mouse = {}, click = {}, seen = {} }
		result[kind][id] = entry
	end
	-- Same key reached through two sources is one binding; different keys stay separate.
	local token = category .. ":" .. text
	if not entry.seen[token] then
		entry.seen[token] = true
		table.insert(entry[category], text)
	end
end
Scanner.Add = Add

-- Adds both keys of a binding command; a command without keys adds nothing.
local function AddKeys(result, kind, id, key1, key2)
	for _, key in ipairs({ Clean(key1), Clean(key2) }) do
		if key ~= "" then
			local category = Scanner:Classify(key)
			if category then
				Add(result, kind, id, category, Scanner:FormatKey(key))
			end
		end
	end
end

----------------------------------------------------------------------
-- Macros and action slots
----------------------------------------------------------------------

local function MacroSpellID(macroID)
	if not (macroID and GetMacroSpell) then
		return nil
	end
	return tonumber(Clean((GetMacroSpell(macroID))))
end

local function MacroItemID(macroID)
	if not (macroID and GetMacroItem) then
		return nil
	end
	local itemName, itemLink = GetMacroItem(macroID)
	itemName, itemLink = Clean(itemName), Clean(itemLink)
	local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
	if itemID then
		return itemID
	end
	-- Some clients return only the name for item macros.
	if itemName and GetItemInfoInstant then
		return tonumber((GetItemInfoInstant(itemName)))
	end
	return nil
end

-- One action resolves to spell, item and/or macro, so a macro tooltip and its spell tooltip both show the key.
local function AddAction(result, actionType, actionID, slot, key1, key2)
	local spellID
	if slot and GetActionSpell then
		spellID = Clean(GetActionSpell(slot))
	end
	if actionType == "spell" then
		spellID = spellID or actionID
	elseif actionType == "item" then
		AddKeys(result, "item", actionID, key1, key2)
	elseif actionType == "macro" then
		spellID = spellID or MacroSpellID(actionID)
		AddKeys(result, "item", MacroItemID(actionID), key1, key2)
		AddKeys(result, "macro", actionID, key1, key2)
	end
	AddKeys(result, "spell", spellID, key1, key2)
end

----------------------------------------------------------------------
-- Action bars
----------------------------------------------------------------------

local BUTTONS_PER_BAR = 12

-- Fallback slot offsets for MULTIACTIONBAR1-8 when the button frame is not available.
local MULTI_BAR_OFFSETS = { 60, 48, 24, 36, 144, 156, 168, 180 }
local MULTI_BAR_FRAMES = {
	"MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft",
	"MultiBar5", "MultiBar6", "MultiBar7", "MultiBar8",
}

-- Only the action bar commands are queried, not every binding in the game.
local COMMANDS = {}
for button = 1, BUTTONS_PER_BAR do
	table.insert(COMMANDS, "ACTIONBUTTON" .. button)
end
for bar = 1, #MULTI_BAR_OFFSETS do
	for button = 1, BUTTONS_PER_BAR do
		table.insert(COMMANDS, "MULTIACTIONBAR" .. bar .. "BUTTON" .. button)
	end
end
table.insert(COMMANDS, "EXTRAACTIONBUTTON1")

-- The button's own action slot beats any calculation: it already accounts for pages, Edit Mode and new bars.
local function SlotFromFrame(frameName)
	local button = _G[frameName]
	if not button then
		return nil
	end
	local slot = button.action
	if slot == nil and button.GetAttribute then
		slot = button:GetAttribute("action")
	end
	slot = tonumber(Clean(slot))
	return slot and slot > 0 and slot or nil
end

local function SlotFromCommand(command)
	local button = tonumber(command:match("^ACTIONBUTTON(%d+)$"))
	if button then
		local slot = SlotFromFrame("ActionButton" .. button)
		if slot then
			return slot
		end
		-- Bonus bars (forms, stealth) take precedence over the page.
		local bonus = tonumber(Clean(GetBonusBarOffset and GetBonusBarOffset())) or 0
		if bonus > 0 then
			return BUTTONS_PER_BAR * (6 + bonus - 1) + button
		end
		local page = tonumber(Clean(GetActionBarPage and GetActionBarPage())) or 1
		return (math.max(page, 1) - 1) * BUTTONS_PER_BAR + button
	end

	local bar, number = command:match("^MULTIACTIONBAR(%d+)BUTTON(%d+)$")
	bar, number = tonumber(bar), tonumber(number)
	if bar and number then
		local frameName = MULTI_BAR_FRAMES[bar]
		return (frameName and SlotFromFrame(frameName .. "Button" .. number))
			or (MULTI_BAR_OFFSETS[bar] and MULTI_BAR_OFFSETS[bar] + number)
	end

	local extra = command:match("^EXTRAACTIONBUTTON(%d+)$")
	if extra then
		return SlotFromFrame("ExtraActionButton" .. extra)
	end
	return nil
end

function Scanner:CollectActionBars(result)
	for _, command in ipairs(COMMANDS) do
		local key1, key2 = GetBindingKey(command)
		if Clean(key1) or Clean(key2) then
			local slot = SlotFromCommand(command)
			if slot then
				local actionType, actionID = GetActionInfo(slot)
				AddAction(result, Clean(actionType), tonumber(Clean(actionID)), slot, key1, key2)
			end
		end
	end
end

-- The stance bar has no action slots; its spell comes from the form info.
function Scanner:CollectStanceBar(result)
	if not (GetNumShapeshiftForms and GetShapeshiftFormInfo) then
		return
	end
	for index = 1, tonumber(Clean(GetNumShapeshiftForms())) or 0 do
		local _, _, _, spellID = GetShapeshiftFormInfo(index)
		local key1, key2 = GetBindingKey("SHAPESHIFTBUTTON" .. index)
		AddKeys(result, "spell", Clean(spellID), key1, key2)
	end
end

-- Macros bound directly via "MACRO <name>", also those without a spell or item.
local ACCOUNT_MACRO_COUNT = MAX_ACCOUNT_MACROS or 120

function Scanner:CollectMacros(result)
	if not (GetNumMacros and GetMacroInfo) then
		return
	end
	local numAccount, numCharacter = GetNumMacros()
	local ids = {}
	for id = 1, tonumber(numAccount) or 0 do
		table.insert(ids, id)
	end
	-- Character macros start after the account slots.
	for id = 1, tonumber(numCharacter) or 0 do
		table.insert(ids, ACCOUNT_MACRO_COUNT + id)
	end
	for _, macroID in ipairs(ids) do
		local name = Clean((GetMacroInfo(macroID)))
		if name then
			local key1, key2 = GetBindingKey("MACRO " .. name)
			if Clean(key1) or Clean(key2) then
				AddAction(result, "macro", macroID, nil, key1, key2)
			end
		end
	end
end

----------------------------------------------------------------------
-- Cache
----------------------------------------------------------------------

function Scanner:Rebuild()
	local result = {}
	-- A failing source (missing API in one client) must not hide the others.
	for _, collect in ipairs({ "CollectActionBars", "CollectStanceBar", "CollectMacros", "CollectClickBindings" }) do
		local ok, err = pcall(self[collect], self, result)
		if not ok then
			Binds:Debug("%s failed: %s", collect, tostring(err))
		end
	end
	cache = result
	dirty = false
end

function Scanner:Get(kind, id)
	if dirty or not cache then
		self:Rebuild()
	end
	return cache[kind] and cache[kind][id]
end

-- Full cache, for diagnostics only.
function Scanner:GetAll()
	if dirty or not cache then
		self:Rebuild()
	end
	return cache
end

-- Form or page switches fire several events at once; tell listeners only once per burst.
local notifyPending = false

function Scanner:Invalidate()
	dirty = true
	if notifyPending then
		return
	end
	if C_Timer and C_Timer.After then
		notifyPending = true
		C_Timer.After(0.1, function()
			notifyPending = false
			Binds:Fire("BindingsChanged")
		end)
	else
		Binds:Fire("BindingsChanged")
	end
end

function Scanner:IsClickCastingAvailable()
	return C_ClickBindings ~= nil and C_ClickBindings.GetProfileInfo ~= nil
end

local GetSpellName = (C_Spell and C_Spell.GetSpellName) or function(spellId)
	return (GetSpellInfo(spellId))
end

-- Click bindings report frame button names ("LeftButton"); map them to binding keys for Blizzard's localized names.
local CLICK_BUTTON_KEYS = {
	LeftButton = "BUTTON1",
	RightButton = "BUTTON2",
	MiddleButton = "BUTTON3",
	Button4 = "BUTTON4",
	Button5 = "BUTTON5",
}

-- Fallbacks in case Enum.ClickBindingType / ClickBindingInteraction are missing in a client.
local TYPE = (Enum and Enum.ClickBindingType) or { Spell = 1, Macro = 2, Interaction = 3 }
local INTERACTION = (Enum and Enum.ClickBindingInteraction) or { Target = 1, OpenContextMenu = 2 }

-- Modifiers come as a "SHIFT-CTRL" style string where available, older clients only give a bitmask.
local function ClickModifiers(raw)
	local modifiers = {}
	raw = Clean(raw)
	if not raw or raw == 0 then
		return modifiers
	end
	if C_ClickBindings.GetStringFromModifiers then
		for part in tostring(C_ClickBindings.GetStringFromModifiers(raw) or ""):gmatch("[^%-]+") do
			local modifier = MODIFIER_ALIASES[part:upper()]
			if modifier then
				modifiers[modifier] = true
			end
		end
	elseif bit and bit.band then
		local mask = tonumber(raw) or 0
		modifiers.SHIFT = bit.band(mask, 1) ~= 0 or nil
		modifiers.CTRL = bit.band(mask, 2) ~= 0 or nil
		modifiers.ALT = bit.band(mask, 4) ~= 0 or nil
	end
	return modifiers
end

local function ClickBindingText(info)
	local button = Clean(info.button)
	local key = CLICK_BUTTON_KEYS[button]
	local text = key and GetBindingText and GetBindingText(key, "KEY_") or button or "?"
	return JoinModifiers(ClickModifiers(info.modifiers), text)
end

local function ClickActionName(info)
	local id = info.actionID
	if info.type == TYPE.Interaction then
		if id == INTERACTION.Target then
			return ns.L.CLICK_ACTION_TARGET
		elseif id == INTERACTION.OpenContextMenu then
			return ns.L.CLICK_ACTION_MENU
		end
	elseif info.type == TYPE.Macro then
		local name = id and GetMacroInfo and GetMacroInfo(id)
		if name then
			return name
		end
	elseif id then
		local name = GetSpellName(id)
		if name then
			return name
		end
	end
	-- Unknown action types stay visible instead of disappearing silently.
	return ns.L.CLICK_ACTION_UNKNOWN
end

-- Flat list for the broker tooltip: { binding = "SHIFT + Left Mouse Button", name = "Flash Heal" }.
function Scanner:GetClickCasts()
	local casts = {}
	if not self:IsClickCastingAvailable() then
		return casts
	end
	for _, info in ipairs(C_ClickBindings.GetProfileInfo() or {}) do
		table.insert(casts, { binding = ClickBindingText(info), name = ClickActionName(info) })
	end
	return casts
end

-- Binding keys in WoW's canonical modifier order, for the optional world mouseover module.
local KEY_MODIFIER_ORDER = { "ALT", "CTRL", "SHIFT", "META" }

-- Raw entries { key = "SHIFT-BUTTON2", type = <ClickBindingType>, actionID = n }; only entries with a modifier.
function Scanner:GetClickCastKeys()
	local entries = {}
	if not self:IsClickCastingAvailable() then
		return entries
	end
	for _, info in ipairs(C_ClickBindings.GetProfileInfo() or {}) do
		local base = CLICK_BUTTON_KEYS[Clean(info.button)]
		local modifiers = ClickModifiers(info.modifiers)
		local prefix = {}
		for _, modifier in ipairs(KEY_MODIFIER_ORDER) do
			if modifiers[modifier] then
				table.insert(prefix, modifier)
			end
		end
		-- Plain clicks stay untouched: they are camera and targeting in the world.
		if base and #prefix > 0 then
			table.insert(entries, {
				key = table.concat(prefix, "-") .. "-" .. base,
				type = Clean(info.type),
				actionID = Clean(info.actionID),
			})
		end
	end
	return entries
end

-- Only spell click casts belong to a spell tooltip; target/menu interactions have no tooltip of their own.
function Scanner:CollectClickBindings(result)
	if not self:IsClickCastingAvailable() then
		return
	end
	for _, info in ipairs(C_ClickBindings.GetProfileInfo() or {}) do
		if Clean(info.type) == TYPE.Spell then
			Add(result, "spell", Clean(info.actionID), "click", ClickBindingText(info))
		end
	end
end

function Scanner:OnInitialize()
	for _, event in ipairs(REFRESH_EVENTS) do
		Binds:RegisterModuleEvent(self, event, "Invalidate")
	end
	-- Saving the click casting profile fires no event, so watch the save call itself.
	if C_ClickBindings and C_ClickBindings.SetProfileByInfo then
		hooksecurefunc(C_ClickBindings, "SetProfileByInfo", function()
			self:Invalidate()
		end)
	end
end
