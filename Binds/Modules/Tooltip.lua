local _, ns = ...
local Binds = ns.Binds
local L = ns.L

-- Adds the bindings section to spell, item and macro tooltips. Only reads data from the Scanner.
local Tooltip = Binds:RegisterModule("Tooltip")

local CATEGORIES = {
	{ key = "keyboard", label = "CATEGORY_KEYBOARD", icon = "keyboard" },
	{ key = "mouse", label = "CATEGORY_MOUSE", icon = "mouse" },
	{ key = "click", label = "CATEGORY_CLICK", icon = "mouse-pointer-click" },
}

-- White Lucide-based icons, tinted per category. The 32px version stays sharp at tooltip font size.
local function Icon(name, color)
	return Binds:Texture(name .. "_weiss_32x32", 0, color) .. " "
end

local function ModifierFilterPasses(filter)
	if not filter.enabled then
		return true
	end
	-- OR: any selected modifier shows the section. No selection means the filter is effectively off.
	if not (filter.shift or filter.ctrl or filter.alt) then
		return true
	end
	return (filter.shift and IsShiftKeyDown())
		or (filter.ctrl and IsControlKeyDown())
		or (filter.alt and IsAltKeyDown())
		or false
end

local function SafeUnit(unit)
	if unit == nil or (issecretvalue and issecretvalue(unit)) then
		return nil
	end
	return unit
end

-- "friend", "dead" (friendly, dead, in the player's group), "enemy" or nil for everything else.
local function UnitState(unit)
	if not UnitExists(unit) then
		return nil
	end
	if UnitIsFriend("player", unit) then
		local dead = UnitIsDeadOrGhost(unit) and (UnitInParty(unit) or UnitInRaid(unit))
		return dead and "dead" or "friend"
	end
	return UnitCanAttack("player", unit) and "enemy" or nil
end

-- Spell icon in front of the name, unless the icons are switched off.
local function SpellIcon(spellID, itemID)
	local clickSpells = Binds:GetModule("ClickSpells")
	if Binds.db.clicks.icons and clickSpells then
		if itemID then
			local texture = clickSpells:ItemTexture(itemID)
			return texture and ("|T%s:0|t "):format(tostring(texture)) or ""
		end
		return clickSpells:IconString(spellID)
	end
	return ""
end

-- Unit tooltips (player frames, nameplates, world): the click casts usable on that unit. Friends list their click
-- casts, dead group members the resurrection, enemies the second spells of the click casts.
function Tooltip:AddUnitSection(tooltip, unit)
	local db = Binds.db
	if not (tooltip and db and db.showInTooltip and db.unitClickCasts and db.categories.click) then
		return
	end
	-- Same modifier filter as the other tooltips decides whether anything is shown at all.
	if not ModifierFilterPasses(db.modifierFilter) then
		return
	end
	if tooltip.bindsUnitSectionAdded then
		return
	end
	if not unit and tooltip.GetUnit then
		local _, token = tooltip:GetUnit()
		unit = SafeUnit(token)
	end
	unit = SafeUnit(unit) or "mouseover"
	local ok, state = pcall(UnitState, unit)
	if not ok or not state or (issecretvalue and issecretvalue(state)) then
		return
	end

	local scanner = Binds:GetModule("Scanner")
	local clickSpells = Binds:GetModule("ClickSpells")
	local casts, anyLabel = {}, nil
	if state == "dead" then
		local rez, rezName = clickSpells:GetResurrection(UnitAffectingCombat and UnitAffectingCombat("player"))
		if rez and rezName then
			casts = { { name = rezName, spellID = rez.kind == "spell" and rez.id or nil, itemID = rez.kind == "item" and rez.id or nil } }
			anyLabel = L.CLICK_ANY
		else
			state = "friend"
		end
	end
	if state == "friend" then
		casts = scanner and scanner:GetFriendlyClickCasts() or {}
		for _, cast in ipairs(scanner and scanner:GetSecondCasts("friend") or {}) do
			table.insert(casts, cast)
		end
	elseif state == "enemy" then
		casts = scanner and scanner:GetSecondCasts("enemy") or {}
	end
	if #casts == 0 then
		return
	end

	tooltip.bindsUnitSectionAdded = true
	tooltip:AddLine(" ")
	Binds:AddTooltipHeader(tooltip)
	local color = Binds.categoryColors.click
	local light = Binds.categoryLightColors.click
	local icon = Icon("mouse-pointer-click", color)
	for _, cast in ipairs(casts) do
		tooltip:AddDoubleLine(icon .. SpellIcon(cast.spellID, cast.itemID) .. cast.name, anyLabel or cast.binding,
			color.r, color.g, color.b, light.r, light.g, light.b)
	end
	tooltip:Show()
end

-- Click casts with a second spell show both icons behind the binding; without icons the other spell's name stands in.
local function PairText(key, pair, id)
	local clickSpells = Binds:GetModule("ClickSpells")
	if not Binds.db.clicks.icons then
		return key .. " (" .. (clickSpells:Name(pair.first == id and pair.second or pair.first) or "") .. ")"
	end
	return key .. " " .. clickSpells:PairString(pair.first, pair.second)
end

local function ClickTexts(category, entry, keys, id)
	if category.key ~= "click" or not entry.clickPairs then
		return table.concat(keys, ", ")
	end
	local texts = {}
	for _, key in ipairs(keys) do
		local pair = entry.clickPairs[key]
		table.insert(texts, pair and PairText(key, pair, id) or key)
	end
	return table.concat(texts, ", ")
end

function Tooltip:AddSection(tooltip, kind, id)
	if not (tooltip and kind and id) then
		return
	end
	local db = Binds.db
	if not db or not db.showInTooltip or not ModifierFilterPasses(db.modifierFilter) then
		return
	end
	-- Tooltips may be refreshed several times without being cleared; never add the block twice.
	if tooltip.bindsSectionAdded then
		return
	end

	local scanner = Binds:GetModule("Scanner")
	local entry = scanner and scanner:Get(kind, id)
	if not entry then
		return
	end

	local lines = {}
	for _, category in ipairs(CATEGORIES) do
		local keys = entry[category.key]
		if keys and #keys > 0 and db.categories[category.key] then
			table.insert(lines, { category = category, text = ClickTexts(category, entry, keys, id) })
		end
	end
	-- No hits: no section at all (open point in the scope doc, default recommendation).
	if #lines == 0 then
		return
	end

	tooltip.bindsSectionAdded = true
	tooltip:AddLine(" ")
	Binds:AddTooltipHeader(tooltip)
	for _, line in ipairs(lines) do
		local color = Binds.categoryColors[line.category.key]
		local light = Binds.categoryLightColors[line.category.key]
		tooltip:AddDoubleLine(Icon(line.category.icon, color) .. L[line.category.label], line.text,
			color.r, color.g, color.b, light.r, light.g, light.b)
	end
	tooltip:Show()
end

----------------------------------------------------------------------
-- Hooks
----------------------------------------------------------------------

local function ItemIdFromLink(link)
	return link and tonumber(link:match("item:(%d+)"))
end

local function HookRetail()
	local types = Enum.TooltipDataType
	TooltipDataProcessor.AddTooltipPostCall(types.Spell, function(tooltip, data)
		Tooltip:AddSection(tooltip, "spell", data and data.id)
	end)
	TooltipDataProcessor.AddTooltipPostCall(types.Item, function(tooltip, data)
		Tooltip:AddSection(tooltip, "item", data and data.id)
	end)
	if types.Unit then
		TooltipDataProcessor.AddTooltipPostCall(types.Unit, function(tooltip)
			Tooltip:AddUnitSection(tooltip)
		end)
	end
	if types.Macro then
		TooltipDataProcessor.AddTooltipPostCall(types.Macro, function(tooltip, data)
			Tooltip:AddSection(tooltip, "macro", data and data.id)
		end)
	end
end

local function HookLegacy(tooltip)
	tooltip:HookScript("OnTooltipSetSpell", function(self)
		local _, spellId = self:GetSpell()
		Tooltip:AddSection(self, "spell", spellId)
	end)
	tooltip:HookScript("OnTooltipSetItem", function(self)
		local _, link = self:GetItem()
		Tooltip:AddSection(self, "item", ItemIdFromLink(link))
	end)
	tooltip:HookScript("OnTooltipSetUnit", function(self)
		Tooltip:AddUnitSection(self)
	end)
	-- Macros have no own tooltip script in older clients; they only appear via action buttons.
	hooksecurefunc(tooltip, "SetAction", function(self, slot)
		local actionType, id = GetActionInfo(slot)
		if actionType == "macro" then
			Tooltip:AddSection(self, "macro", id)
		end
	end)
end

local function HookTooltip(tooltip)
	tooltip:HookScript("OnTooltipCleared", function(self)
		self.bindsSectionAdded = nil
		self.bindsUnitSectionAdded = nil
	end)
	if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
		HookLegacy(tooltip)
	end
end

function Tooltip:OnInitialize()
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
		-- Retail post-calls are global for all tooltips, so register them once.
		HookRetail()
	end
	HookTooltip(GameTooltip)
	if ItemRefTooltip then
		HookTooltip(ItemRefTooltip)
	end
	Binds:RegisterModuleEvent(self, "MODIFIER_STATE_CHANGED", "OnModifierChanged")
end

-- Re-render the visible tooltip so a changed modifier filter shows up right away. Calling RefreshData from addon
-- code taints it, and Blizzard then fails on protected ("secret") tooltip data. Unit tooltips refresh themselves
-- anyway, and nothing is refreshed in combat, so those cases are skipped.
local function RefreshVisibleTooltip()
	if not (GameTooltip:IsShown() and GameTooltip.RefreshData) or InCombatLockdown() then
		return
	end
	local _, unit = GameTooltip:GetUnit()
	if unit ~= nil or (issecretvalue and issecretvalue(unit)) then
		return
	end
	GameTooltip:RefreshData()
end

function Tooltip:OnModifierChanged()
	if Binds.db and Binds.db.modifierFilter.enabled then
		RefreshVisibleTooltip()
	end
end
