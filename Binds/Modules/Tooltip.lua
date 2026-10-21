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
			table.insert(lines, { category = category, text = table.concat(keys, ", ") })
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
	Binds:On("BindingsChanged", self, "OnBindingsChanged")
end

-- Re-render the visible tooltip so filter and binding changes show up on the next update.
local function RefreshVisibleTooltip()
	if GameTooltip:IsShown() and GameTooltip.RefreshData then
		GameTooltip:RefreshData()
	end
end

function Tooltip:OnModifierChanged()
	if Binds.db and Binds.db.modifierFilter.enabled then
		RefreshVisibleTooltip()
	end
end

function Tooltip:OnBindingsChanged()
	RefreshVisibleTooltip()
end
