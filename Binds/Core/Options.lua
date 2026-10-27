local _, ns = ...
local Binds = ns.Binds
local L = ns.L

-- Plain Blizzard widgets instead of AceConfig: the addon must run without library dependencies.
-- Layout: "Binds" is an overview page, all settings live in the "General" subcategory.

local LOGO = "Interface\\AddOns\\Binds\\Media\\Binds_Icon_und_Schrift_128x128"
local PADDING = 16
local SECTION_GAP = 22

----------------------------------------------------------------------
-- Widgets
----------------------------------------------------------------------

local function CreatePanel(name)
	local panel = CreateFrame("Frame")
	panel.name = name
	panel.refreshers = {}
	panel:Hide()
	panel:SetScript("OnShow", function(self)
		for _, refresh in ipairs(self.refreshers) do
			refresh()
		end
	end)
	return panel
end

-- Pages can be taller than the settings window, so their widgets sit on a scrolling content frame. The content shares
-- the page's refreshers; `last` (set by the page) is the lowest widget and decides the scroll height.
local function CreateScrollContent(page)
	local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, -4)
	scroll:SetPoint("BOTTOMRIGHT", -28, 4)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 800)
	content.refreshers = page.refreshers
	scroll:SetScrollChild(content)
	scroll:SetScript("OnSizeChanged", function(_, width)
		if width and width > 1 then
			content:SetWidth(width)
		end
	end)
	page:HookScript("OnShow", function()
		content:SetWidth(math.max(scroll:GetWidth(), 1))
		C_Timer.After(0.05, function()
			local top, bottom = content:GetTop(), content.last and content.last:GetBottom()
			if top and bottom then
				content:SetHeight(math.max(top - bottom + PADDING, 1))
			end
		end)
	end)
	return content
end

local function Refresh(panel)
	for _, refresh in ipairs(panel.refreshers) do
		refresh()
	end
end

local function CreateHeader(panel, title, subtitle)
	local text = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	text:SetPoint("TOPLEFT", PADDING, -PADDING)
	text:SetText(Binds:Colorize(title, "primary"))

	local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	sub:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -6)
	sub:SetPoint("RIGHT", -PADDING, 0)
	sub:SetJustifyH("LEFT")
	sub:SetText(subtitle or "")
	return sub
end

-- Section title with a thin rule, so groups read as blocks instead of a loose checkbox list.
local function CreateSection(panel, anchor, title)
	local text = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -SECTION_GAP)
	text:SetText(Binds:Colorize(title, "accent"))

	local line = Binds:CreateDivider(panel)
	line:SetPoint("LEFT", text, "RIGHT", 8, 0)
	line:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
	return text
end

-- Returns the checkbox and the lowest region below it, so the next widget can anchor there.
local function CreateCheckbox(panel, anchor, label, description, getter, setter, indent)
	local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	check:SetSize(26, 26)
	check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", indent or 0, -8)

	-- Own label because the template's text field is named differently across clients.
	local text = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("LEFT", check, "RIGHT", 4, 1)
	text:SetText(label)
	check.label = text

	local bottom = check
	if description then
		local desc = check:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		desc:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
		desc:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
		desc:SetJustifyH("LEFT")
		desc:SetText(description)
		bottom = desc
	end

	check:SetScript("OnClick", function(self)
		setter(self:GetChecked() and true or false)
		Binds:Fire("SettingsChanged")
		Refresh(panel)
	end)
	table.insert(panel.refreshers, function()
		check:SetChecked(getter())
	end)
	-- Anchor following widgets to the left edge of the checkbox, not to the indented description.
	local anchorFrame = CreateFrame("Frame", nil, panel)
	anchorFrame:SetSize(1, 1)
	anchorFrame:SetPoint("TOPLEFT", check, "LEFT", -(indent or 0), 0)
	anchorFrame:SetPoint("BOTTOM", bottom, "BOTTOM")
	return check, anchorFrame
end

local function SetCheckboxEnabled(check, enabled)
	if enabled then
		check:Enable()
		check.label:SetFontObject("GameFontHighlight")
	else
		check:Disable()
		check.label:SetFontObject("GameFontDisable")
	end
end

----------------------------------------------------------------------
-- Main page: overview
----------------------------------------------------------------------

-- Icon and color in the category list, like other addons show there. Plain title stays for headers and chat.
local mainPanel = CreatePanel(Binds:Texture("Binds_Icon_dunkel_32x32", 0) .. " " .. Binds:Colorize(Binds.title, "primary"))

do
	local logo = mainPanel:CreateTexture(nil, "ARTWORK")
	logo:SetSize(128, 128)
	logo:SetPoint("TOPLEFT", PADDING, -PADDING)
	logo:SetTexture(LOGO)

	local info = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	info:SetPoint("LEFT", logo, "RIGHT", PADDING, 0)
	info:SetJustifyH("LEFT")
	local muted = Binds.colors.neutralDark.hex
	info:SetText(("|cff%s%s:|r %s\n|cff%s%s:|r %s"):format(muted, L.VERSION, Binds.version, muted, L.AUTHOR, Binds.author))

	local intro = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	intro:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -PADDING)
	intro:SetPoint("RIGHT", -PADDING, 0)
	intro:SetJustifyH("LEFT")
	intro:SetSpacing(3)
	intro:SetText(L.OVERVIEW_TEXT)

	local hint = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -12)
	hint:SetText(L.OVERVIEW_HINT)
end

----------------------------------------------------------------------
-- Subcategory: General
----------------------------------------------------------------------

local generalPanel = CreatePanel(L.CATEGORY_GENERAL)
-- Legacy interface options nest a panel under its parent by name.
generalPanel.parent = mainPanel.name

do
	local panel = CreateScrollContent(generalPanel)
	local header = CreateHeader(panel, L.CATEGORY_GENERAL, L.GENERAL_SUBTITLE)

	-- Tooltip
	local tooltipSection = CreateSection(panel, header, L.SECTION_TOOLTIP)

	local _, afterShow = CreateCheckbox(panel, tooltipSection, L.OPT_SHOW_TOOLTIP, L.OPT_SHOW_TOOLTIP_DESC,
		function() return Binds.db.showInTooltip end,
		function(value) Binds.db.showInTooltip = value end)

	-- One switch per category, indented under the main switch and only shown while it is on.
	local categoryChecks, afterCategories = {}, afterShow
	for _, category in ipairs({
		{ key = "keyboard", icon = "keyboard", label = "CATEGORY_KEYBOARD" },
		{ key = "mouse", icon = "mouse", label = "CATEGORY_MOUSE" },
		{ key = "click", icon = "mouse-pointer-click", label = "CATEGORY_CLICK" },
	}) do
		local color = Binds.categoryColors[category.key]
		local label = Binds:Texture(category.icon .. "_weiss_32x32", 0, color) .. " " .. Binds:Colorize(L[category.label], category.key)
		local check
		check, afterCategories = CreateCheckbox(panel, afterCategories, label, L["OPT_CATEGORY_" .. category.key:upper() .. "_DESC"],
			function() return Binds.db.categories[category.key] end,
			function(value) Binds.db.categories[category.key] = value end, 30)
		table.insert(categoryChecks, check)
	end

	local unitCheck
	unitCheck, afterCategories = CreateCheckbox(panel, afterCategories, L.OPT_UNIT_CLICKCASTS, L.OPT_UNIT_CLICKCASTS_DESC,
		function() return Binds.db.unitClickCasts end,
		function(value) Binds.db.unitClickCasts = value end, 30)
	table.insert(categoryChecks, unitCheck)

	local iconsCheck
	iconsCheck, afterCategories = CreateCheckbox(panel, afterCategories, L.OPT_CLICK_ICONS, L.OPT_CLICK_ICONS_DESC,
		function() return Binds.db.clicks.icons end,
		function(value) Binds.db.clicks.icons = value end, 30)
	table.insert(categoryChecks, iconsCheck)

	local filterCheck, afterFilter = CreateCheckbox(panel, afterCategories, L.OPT_MODIFIER_FILTER, L.OPT_MODIFIER_FILTER_DESC,
		function() return Binds.db.modifierFilter.enabled end,
		function(value) Binds.db.modifierFilter.enabled = value end)

	-- Hidden category switches must not leave a gap, so the filter moves up to the main switch.
	table.insert(panel.refreshers, function()
		local shown = Binds.db.showInTooltip
		for _, check in ipairs(categoryChecks) do
			check:SetShown(shown)
		end
		filterCheck:ClearAllPoints()
		filterCheck:SetPoint("TOPLEFT", shown and afterCategories or afterShow, "BOTTOMLEFT", 0, -8)
	end)

	local modifierChecks, previous = {}, nil
	for _, key in ipairs({ "shift", "ctrl", "alt" }) do
		local check
		if previous then
			check = CreateCheckbox(panel, afterFilter, L["OPT_MODIFIER_" .. key:upper()], nil,
				function() return Binds.db.modifierFilter[key] end,
				function(value) Binds.db.modifierFilter[key] = value end)
			check:ClearAllPoints()
			check:SetPoint("LEFT", previous, "RIGHT", 110, 0)
		else
			check = CreateCheckbox(panel, afterFilter, L["OPT_MODIFIER_" .. key:upper()], nil,
				function() return Binds.db.modifierFilter[key] end,
				function(value) Binds.db.modifierFilter[key] = value end, 30)
		end
		table.insert(modifierChecks, check)
		previous = check
	end

	-- Modifier choices only matter while the filter is on; greying them out makes that visible.
	table.insert(panel.refreshers, function()
		for _, check in ipairs(modifierChecks) do
			SetCheckboxEnabled(check, Binds.db.modifierFilter.enabled)
		end
	end)

	-- Click casting
	local clickSection = CreateSection(panel, modifierChecks[1], L.SECTION_CLICKCAST)
	clickSection:ClearAllPoints()
	clickSection:SetPoint("TOPLEFT", modifierChecks[1], "BOTTOMLEFT", -30, -SECTION_GAP)

	local _, afterMouseover = CreateCheckbox(panel, clickSection, L.OPT_MOUSEOVER, L.OPT_MOUSEOVER_DESC .. " " .. L.OPT_MOUSEOVER_PAGE,
		function() return Binds.db.mouseoverCasts end,
		function(value) Binds.db.mouseoverCasts = value end)

	-- Minimap
	local minimapSection = CreateSection(panel, afterMouseover, L.SECTION_MINIMAP)

	local _, afterMinimap = CreateCheckbox(panel, minimapSection, L.OPT_MINIMAP, L.OPT_MINIMAP_DESC,
		function() return not Binds.db.minimap.hide end,
		function(value)
			local broker = Binds:GetModule("Broker")
			if broker then
				broker:SetMinimapButtonShown(value)
			end
		end)

	-- Developer
	local developerSection = CreateSection(panel, afterMinimap, L.SECTION_DEVELOPER)

	local _, afterDebug = CreateCheckbox(panel, developerSection, L.OPT_DEBUG, L.OPT_DEBUG_DESC,
		function() return Binds.db.debug end,
		function(value) Binds.db.debug = value end)
	panel.last = afterDebug
end

----------------------------------------------------------------------
-- Subcategory: Click casting
----------------------------------------------------------------------

-- Own page next to General; it is only registered while mouseover casts are on.
local clickPanel = CreatePanel(L.CATEGORY_CLICK)
clickPanel.parent = mainPanel.name

local ROW_HEIGHT = 30

-- Choice list for the second spell. Plain frames instead of a dropdown template: those differ between clients.
local PICK_ROWS, PICK_ROW_HEIGHT, PICK_WIDTH = 10, 24, 270
local picker

local function ChooseSecond(entry)
	local clickSpells = Binds:GetModule("ClickSpells")
	local ok, inactive = clickSpells:SetSecond(picker.first, entry.spellID)
	picker.catcher:Hide()
	if not ok then
		Binds:Print(L.SECOND_ERR_UNKNOWN)
		return
	end
	if inactive then
		Binds:Print(L.SECOND_WARN_SAME)
	end
	Binds:Fire("SettingsChanged")
	Refresh(clickPanel)
end

local function FillPicker()
	local entries = picker.entries
	local maxOffset = math.max(#entries - PICK_ROWS, 0)
	picker.offset = math.min(math.max(picker.offset, 0), maxOffset)
	for index, row in ipairs(picker.rows) do
		local entry = entries[picker.offset + index]
		row.entry = entry
		if entry then
			row.icon:SetTexture(entry.texture)
			row.icon:SetDesaturated(entry.conflict and true or false)
			row.label:SetText(entry.conflict and ("|cff" .. Binds.colors.neutralDark.hex .. entry.name .. "|r") or entry.name)
			row:Show()
		else
			row:Hide()
		end
	end
	picker:SetHeight(math.min(#entries, PICK_ROWS) * PICK_ROW_HEIGHT + 8)
end

local function GetPicker()
	if picker then
		return picker
	end
	-- Full-screen catcher behind the list: a click anywhere else closes it.
	local catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetFrameStrata("FULLSCREEN")
	catcher:SetAllPoints(UIParent)
	catcher:RegisterForClicks("AnyUp")
	catcher:SetScript("OnClick", function(self)
		self:Hide()
	end)
	catcher:Hide()

	picker = CreateFrame("Frame", nil, catcher)
	picker.catcher = catcher
	picker:SetFrameStrata("FULLSCREEN_DIALOG")
	picker:SetWidth(PICK_WIDTH)
	picker:EnableMouse(true)
	picker:EnableMouseWheel(true)
	picker.rows, picker.offset, picker.entries = {}, 0, {}

	local border = picker:CreateTexture(nil, "BACKGROUND")
	border:SetAllPoints()
	border:SetColorTexture(Binds.colors.primary.r, Binds.colors.primary.g, Binds.colors.primary.b, 0.9)
	local fill = picker:CreateTexture(nil, "BORDER")
	fill:SetPoint("TOPLEFT", 1, -1)
	fill:SetPoint("BOTTOMRIGHT", -1, 1)
	fill:SetColorTexture(0.05, 0.04, 0.03, 0.97)

	for index = 1, PICK_ROWS do
		local row = CreateFrame("Button", nil, picker)
		row:SetHeight(PICK_ROW_HEIGHT)
		row:SetPoint("TOPLEFT", 4, -4 - (index - 1) * PICK_ROW_HEIGHT)
		row:SetPoint("RIGHT", -4, 0)
		local highlight = row:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetColorTexture(Binds.colors.taupe.r, Binds.colors.taupe.g, Binds.colors.taupe.b, 0.6)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(PICK_ROW_HEIGHT - 4, PICK_ROW_HEIGHT - 4)
		row.icon:SetPoint("LEFT", 2, 0)
		row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.label:SetPoint("RIGHT", -4, 0)
		row.label:SetJustifyH("LEFT")
		row:SetScript("OnClick", function(self)
			if self.entry then
				ChooseSecond(self.entry)
			end
		end)
		picker.rows[index] = row
	end

	picker:SetScript("OnMouseWheel", function(self, delta)
		self.offset = self.offset - delta
		FillPicker()
	end)
	return picker
end

local function OpenPicker(slot)
	local clickSpells = Binds:GetModule("ClickSpells")
	local first = slot.row.spellID
	local frame = GetPicker()
	frame.first = first
	frame.offset = 0
	frame.entries = {}
	-- First entry empties the slot, but only while there is something to empty.
	if clickSpells:GetStoredSecond(first) then
		table.insert(frame.entries, { name = "|cff" .. Binds.colors.neutralDark.hex .. L.SECOND_CLEAR .. "|r" })
	end
	for _, candidate in ipairs(clickSpells:GetCandidates(first)) do
		-- Spells of the same kind do not work as a pair; they are only offered when asked for.
		if Binds.db.clicks.showAll or not candidate.conflict then
			table.insert(frame.entries, {
				spellID = candidate.spellID, name = candidate.name, conflict = candidate.conflict,
				texture = clickSpells:GetTexture(candidate.spellID),
			})
		end
	end
	if #frame.entries == 0 then
		Binds:Print(L.SECOND_PICK_NONE)
		return
	end
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -2)
	FillPicker()
	frame.catcher:Show()
end

-- Click opens the list, right-click clears the slot.
local function UseSlot(slot, button)
	if button == "RightButton" then
		Binds:GetModule("ClickSpells"):SetSecond(slot.row.spellID, nil)
		Binds:Fire("SettingsChanged")
		Refresh(clickPanel)
	else
		OpenPicker(slot)
	end
end

local function CreateSlot(row)
	local slot = CreateFrame("Button", nil, row)
	slot:SetHeight(ROW_HEIGHT - 6)
	slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	slot.row = row

	local border = slot:CreateTexture(nil, "BACKGROUND")
	border:SetAllPoints()
	border:SetColorTexture(Binds.colors.taupe.r, Binds.colors.taupe.g, Binds.colors.taupe.b, 0.8)
	local fill = slot:CreateTexture(nil, "BORDER")
	fill:SetPoint("TOPLEFT", 1, -1)
	fill:SetPoint("BOTTOMRIGHT", -1, 1)
	fill:SetColorTexture(0.06, 0.05, 0.04, 0.9)

	slot.icon = slot:CreateTexture(nil, "ARTWORK")
	slot.icon:SetSize(ROW_HEIGHT - 10, ROW_HEIGHT - 10)
	slot.icon:SetPoint("LEFT", 3, 0)
	slot.label = slot:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	slot.label:SetPoint("LEFT", slot.icon, "RIGHT", 6, 0)
	slot.label:SetPoint("RIGHT", -6, 0)
	slot.label:SetJustifyH("LEFT")

	slot:SetScript("OnClick", UseSlot)
	slot:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SECOND_SLOT_TITLE, 1, 1, 1)
		GameTooltip:AddLine(L.SECOND_SLOT_HINT, nil, nil, nil, true)
		if self.inactive then
			GameTooltip:AddLine(L.SECOND_WARN_SAME, 1, 0.82, 0, true)
		end
		GameTooltip:Show()
	end)
	slot:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return slot
end

local function CreateRow(list, index)
	local row = CreateFrame("Frame", nil, list)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", list, "RIGHT")

	local light = Binds.categoryLightColors.click
	row.binding = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.binding:SetPoint("LEFT", 6, 0)
	row.binding:SetWidth(150)
	row.binding:SetJustifyH("LEFT")
	row.binding:SetTextColor(light.r, light.g, light.b)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_HEIGHT - 10, ROW_HEIGHT - 10)
	row.icon:SetPoint("LEFT", 164, 0)
	row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.name:SetWidth(120)
	row.name:SetJustifyH("LEFT")

	row.arrow = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	row.arrow:SetPoint("LEFT", 322, 0)
	row.arrow:SetText("/")

	-- Warning badge for a pair of the same kind: drawn here, tooltip carries the reason.
	row.warn = CreateFrame("Frame", nil, row)
	row.warn:SetSize(ROW_HEIGHT - 12, ROW_HEIGHT - 12)
	row.warn:SetPoint("RIGHT", -6, 0)
	row.warn:EnableMouse(true)
	local warnBackground = row.warn:CreateTexture(nil, "BACKGROUND")
	warnBackground:SetAllPoints()
	warnBackground:SetColorTexture(1, 0.82, 0, 1)
	local warnMark = row.warn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	warnMark:SetPoint("CENTER", 0, 0)
	warnMark:SetText("!")
	warnMark:SetTextColor(0.1, 0.07, 0.03)
	row.warn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.SECOND_WARN_TITLE, 1, 0.82, 0)
		GameTooltip:AddLine(L.SECOND_WARN_SAME, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	row.warn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row.warn:Hide()

	row.slot = CreateSlot(row)
	row.slot:SetPoint("LEFT", 340, 0)
	row.slot:SetPoint("RIGHT", row.warn, "LEFT", -6, 0)
	row.none = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	row.none:SetPoint("LEFT", 340, 0)
	row.none:SetText(L.SECOND_NONE)
	return row
end

do
	local panel = clickPanel
	local header = CreateHeader(panel, L.CATEGORY_CLICK, L.CLICK_SUBTITLE)
	local subtitle = L.CLICK_SUBTITLE
	panel:SetScript("OnHide", function()
		if picker then
			picker.catcher:Hide()
		end
	end)

	-- Unit frames
	local frameSection = CreateSection(panel, header, L.SECTION_UNITFRAMES)
	local _, afterFrames = CreateCheckbox(panel, frameSection, L.OPT_UNITFRAMES, L.OPT_UNITFRAMES_DESC,
		function() return Binds.db.clicks.unitFrames end,
		function(value) Binds.db.clicks.unitFrames = value end)

	-- Second spell
	local secondSection = CreateSection(panel, afterFrames, L.SECTION_SECOND)
	local _, afterSecondCheck = CreateCheckbox(panel, secondSection, L.OPT_SECOND, L.OPT_SECOND_DESC,
		function() return Binds.db.clicks.second end,
		function(value) Binds.db.clicks.second = value end)
	local _, afterSecond = CreateCheckbox(panel, afterSecondCheck, L.OPT_SECOND_ALL, L.OPT_SECOND_ALL_DESC,
		function() return Binds.db.clicks.showAll end,
		function(value) Binds.db.clicks.showAll = value end, 30)

	local list = CreateFrame("Frame", nil, panel)
	list:SetPoint("TOPLEFT", afterSecond, "BOTTOMLEFT", 30, -8)
	list:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)
	list:SetHeight(ROW_HEIGHT)
	-- Following sections anchor here, so they sit at the left edge and follow the list height.
	local listBottom = CreateFrame("Frame", nil, panel)
	listBottom:SetSize(1, 1)
	listBottom:SetPoint("TOPLEFT", list, "BOTTOMLEFT", -30, 0)

	local empty = list:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	empty:SetPoint("TOPLEFT", 6, -8)
	empty:SetText(L.SECOND_EMPTY_LIST)

	local rows = {}
	table.insert(panel.refreshers, function()
		local scanner = Binds:GetModule("Scanner")
		local clickSpells = Binds:GetModule("ClickSpells")
		local clicks = scanner and scanner:GetModifierSpellClicks() or {}
		local enabled = Binds.db.clicks.second
		for index, click in ipairs(clicks) do
			local row = rows[index]
			if not row then
				row = CreateRow(list, index)
				rows[index] = row
			end
			row.spellID = click.spellID
			row.binding:SetText(click.binding)
			row.icon:SetTexture(clickSpells:GetTexture(click.spellID))
			row.name:SetText(clickSpells:Name(click.spellID) or "?")

			-- Spells that act on neither friends nor enemies have no counterpart.
			local pairable = clickSpells:Orientation(click.spellID) ~= nil
			row.slot:SetShown(pairable)
			row.none:SetShown(not pairable)
			local second = clickSpells:GetStoredSecond(click.spellID)
			local inactive = second and clickSpells:Conflicts(click.spellID, second)
			row.slot.inactive = inactive
			row.slot.icon:SetTexture(second and clickSpells:GetTexture(second) or nil)
			row.slot.icon:SetDesaturated(inactive and true or false)
			row.slot.label:SetText(second and (clickSpells:Name(second) or "?") or L.SECOND_EMPTY)
			row.warn:SetShown(inactive and true or false)
			row.slot.label:SetFontObject((second and not inactive) and "GameFontHighlight" or "GameFontDisable")
			row.slot:SetEnabled(enabled)
			row:SetAlpha(enabled and 1 or 0.5)
			row:Show()
		end
		for index = #clicks + 1, #rows do
			rows[index]:Hide()
		end
		empty:SetShown(#clicks == 0)
		list:SetHeight(math.max(#clicks, 1) * ROW_HEIGHT)
	end)

	-- Resurrection
	local resSection = CreateSection(panel, listBottom, L.SECTION_RESURRECT)
	resSection:ClearAllPoints()
	resSection:SetPoint("TOPLEFT", listBottom, "BOTTOMLEFT", 0, -SECTION_GAP)
	local resCheck, afterRes = CreateCheckbox(panel, resSection, L.OPT_RESURRECT, L.OPT_RESURRECT_DESC,
		function() return Binds.db.clicks.resurrect end,
		function(value) Binds.db.clicks.resurrect = value end)

	-- Two checkboxes act as a radio pair: the getter follows the stored mode, so a click always ends up selected.
	local normalCheck, afterNormal = CreateCheckbox(panel, afterRes, "", nil,
		function() return Binds.db.clicks.resurrectMode ~= "combat" end,
		function() Binds.db.clicks.resurrectMode = "normal" end, 30)
	local combatCheck = CreateCheckbox(panel, afterNormal, "", nil,
		function() return Binds.db.clicks.resurrectMode == "combat" end,
		function() Binds.db.clicks.resurrectMode = "combat" end, 30)

	local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	note:SetJustifyH("LEFT")
	note:SetPoint("RIGHT", panel, "RIGHT", -PADDING, 0)

	table.insert(panel.refreshers, function()
		local clickSpells = Binds:GetModule("ClickSpells")
		local normal, combat = clickSpells:GetAvailableResurrections()
		local both = normal and combat
		resCheck:SetShown((normal or combat) ~= nil)
		normalCheck:SetShown(both and true or false)
		combatCheck:SetShown(both and true or false)
		if both then
			normalCheck.label:SetText(L.RESURRECT_NORMAL .. " |cff" .. Binds.colors.neutralDark.hex .. "(" .. (clickSpells:Name(normal) or "?") .. ")|r")
			combatCheck.label:SetText(L.RESURRECT_COMBAT .. " |cff" .. Binds.colors.neutralDark.hex .. "(" .. (clickSpells:Name(combat) or "?") .. ")|r")
		end
		note:ClearAllPoints()
		if not (normal or combat) then
			note:SetPoint("TOPLEFT", resSection, "BOTTOMLEFT", 0, -8)
			note:SetText(L.RESURRECT_UNAVAILABLE)
		elseif not both then
			note:SetPoint("TOPLEFT", afterRes, "BOTTOMLEFT", 30, -4)
			note:SetText(L.RESURRECT_ONLY:format(clickSpells:Name(normal or combat) or "?"))
		else
			note:SetText("")
		end
	end)

	-- Everything on this page rides on the mouseover module; say so when it is off.
	table.insert(panel.refreshers, function()
		local off = not Binds.db.mouseoverCasts
		header:SetText(off and (subtitle .. "\n|cff" .. Binds.colors.primary.hex .. L.CLICK_DISABLED .. "|r") or subtitle)
	end)
end

----------------------------------------------------------------------
-- Registration
----------------------------------------------------------------------

function Binds:OpenOptions()
	if InCombatLockdown() then
		-- Opening the settings frame in combat can taint protected panels.
		self:Print(L.COMBAT_LOCKED)
		return
	end
	if self.settingsCategory and Settings and Settings.OpenToCategory then
		local target = self.settingsSubcategory or self.settingsCategory
		Settings.OpenToCategory(target:GetID())
	elseif InterfaceOptionsFrame_OpenToCategory then
		-- Called twice: the legacy frame ignores the first call when it was never opened.
		InterfaceOptionsFrame_OpenToCategory(generalPanel)
		InterfaceOptionsFrame_OpenToCategory(generalPanel)
	end
end

local Options = Binds:RegisterModule("Options")

-- Same level as General, directly below the Binds category.
local function RegisterClickPage(category)
	Binds.settingsClickCategory = Settings.RegisterCanvasLayoutSubcategory(category, clickPanel, clickPanel.name)
end

function Options:OnInitialize()
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
		Binds.settingsCategory = category
		if Settings.RegisterCanvasLayoutSubcategory then
			Binds.settingsSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, generalPanel, generalPanel.name)
			-- Settings categories cannot be removed at runtime, so the page exists from login on while the option is on.
			if Binds.db.mouseoverCasts then
				RegisterClickPage(category)
			end
		end
		Settings.RegisterAddOnCategory(category)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(mainPanel)
		InterfaceOptions_AddCategory(generalPanel)
		if Binds.db.mouseoverCasts then
			InterfaceOptions_AddCategory(clickPanel)
		end
	end
end
